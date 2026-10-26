# probe_rain_render.gd - run WINDOWED: Godot --path . --script res://tools/probe_rain_render.gd [-- PHASE [only_view_name]]
# Rain probe, ground truth on the GPU. At each interior position (tools/lhf_views.gd, plus extra spots) the camera turns through
# 8 headings x 5 pitches. The rain (and its splash specks) is drawn in solid unshaded magenta, the world is frozen, and magenta pixels
# in the frame are drops. A drop only counts as INDOORS when the pixel's sight ray hits a solid interior
# surface (not a glass pane, not nothing) within 9 m, because then the drop is in front of that surface, inside the room. Drops
# seen through windows and glass are outside and are ignored.
# A positive control stands outside the door: it must see rain or the probe is blind.
extends SceneTree

const Views := preload("res://tools/lhf_views.gd")
const NOISE_ALLOW := 4            # magenta (rain) pixels tolerated per direction
const YAWS := [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
const PITCHES := [-60.0, -25.0, 0.0, 25.0, 60.0]
const W := 800
const H := 450
const CELL := 10

var _lv: Node
var _cam: Camera3D
var _rain: Node3D
var _rig: Node
var _pos: Array = []
var _i := 0
var _d := 0
var _f := 0
var _wait := 0
var _state := 0
var _mask: PackedByteArray
var _fails := 0
var _phase := "ISLAND"
var _only := ""
var _debug := OS.get_environment("RAIN_DEBUG") == "1"
var _pos_worst := 0
var _pos_worst_dir := ""
var _summary: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_phase = args[0]
	if args.size() > 1:
		_only = args[1]
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_cam = Camera3D.new()
	_cam.far = 200.0
	_cam.fov = 80.0
	root.add_child(_cam)
	_cam.current = true
	var pl := _lv.get_node_or_null("Player")
	if pl:
		pl.global_position = Vector3(0, -500, 0)
		pl.process_mode = Node.PROCESS_MODE_DISABLED
		for c in pl.find_children("*", "Camera3D", true, false):
			(c as Camera3D).current = false
	for c in _lv.find_children("*", "CanvasLayer", true, false):
		(c as CanvasLayer).visible = false


func _snap() -> Image:
	return root.get_texture().get_image()


## 1 per CELL x CELL block whose sight ray ends on a solid interior surface within 9 m (an interior pixel), else 0.
func _make_mask() -> void:
	_mask = PackedByteArray()
	_mask.resize((W / CELL) * (H / CELL))
	var space := _cam.get_world_3d().direct_space_state
	var vp := Vector2(W, H)
	var full := root.get_visible_rect().size
	for cy in range(H / CELL):
		for cx in range(W / CELL):
			var inside := true
			# the cell counts only if the centre and all four corners end on a solid, non-glass surface: no cell that straddles a pane or an opening
			for off in [Vector2(0.5, 0.5), Vector2(0.05, 0.05), Vector2(0.95, 0.05), Vector2(0.05, 0.95), Vector2(0.95, 0.95)]:
				var sp := Vector2((cx + off.x) * CELL, (cy + off.y) * CELL) * (full / vp)
				var o := _cam.project_ray_origin(sp)
				var n := _cam.project_ray_normal(sp)
				var q := PhysicsRayQueryParameters3D.create(o, o + n * 9.0)
				q.collide_with_areas = false
				var r := space.intersect_ray(q)
				if r.is_empty() or (r["collider"] as Node).is_in_group("glass"):
					inside = false
					break
			_mask[cy * (W / CELL) + cx] = 1 if inside else 0
	# erode by one cell: a window frame, a glass edge or a doorway edge is never trusted, only the middle of solid surfaces
	var cw := W / CELL
	var chh := H / CELL
	var eroded := _mask.duplicate()
	for cy in chh:
		for cx in cw:
			if _mask[cy * cw + cx] == 0:
				continue
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var ny: int = cy + dy
					var nx: int = cx + dx
					if ny < 0 or nx < 0 or ny >= chh or nx >= cw or _mask[ny * cw + nx] == 0:
						eroded[cy * cw + cx] = 0
	_mask = eroded


func _count_masked(img: Image) -> int:
	var n := 0
	var fw := img.get_width()
	var fh := img.get_height()
	for yy in fh:
		var my := (yy * H / fh) / CELL
		for xx in fw:
			if _mask[my * (W / CELL) + (xx * W / fw) / CELL] == 0:
				continue
			var c := img.get_pixel(xx, yy)
			if c.r > 0.6 and c.b > 0.6 and c.g < 0.35:
				n += 1
				if _debug and n % 10 == 1:
					var sp := Vector2(xx + 0.5, yy + 0.5)
					var o := _cam.project_ray_origin(sp)
					var rr := _cam.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(o, o + _cam.project_ray_normal(sp) * 9.0))
					print("      drop px (%d,%d) ray hits %s at %.2f m" % [xx, yy, str((rr["collider"] as Node).get_path()) if not rr.is_empty() else "nothing", o.distance_to(rr["position"]) if not rr.is_empty() else -1.0])
	return n


func _aim() -> void:
	var p: Dictionary = _pos[_i]
	var d := _d
	var yaw := deg_to_rad(YAWS[d / PITCHES.size()])
	var pit := deg_to_rad(PITCHES[d % PITCHES.size()])
	var dir := Vector3(cos(pit) * cos(yaw), sin(pit), cos(pit) * sin(yaw))
	_cam.look_at_from_position(p["from"], p["from"] + dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT)


func _finish_position() -> void:
	var p: Dictionary = _pos[_i]
	var ok: bool = _pos_worst <= NOISE_ALLOW
	if p.get("control", false):
		ok = _pos_worst > 40
	print(("PASS  " if ok else "FAIL  ") + "%-18s worst direction: %4d indoor drop pixels %s" % [p["name"], _pos_worst, _pos_worst_dir])
	_fails += int(not ok)
	Engine.time_scale = 1.0
	_i += 1
	_d = 0
	_pos_worst = 0
	_pos_worst_dir = ""
	_state = 0


func _process(_dt: float) -> bool:
	_f += 1
	if _f == 3:
		_rig = _lv.get_node("LightingRig")
		_rig.set_phase(_phase, true)
		_rain = _lv.get_node("LightingRig/Rain")
		for pn in [_rain, _lv.get_node("LightingRig/RainSplash")]:      # solid magenta, no alpha, no fog: unmistakable in the frame
			var dmat := ((pn as GPUParticles3D).draw_pass_1 as PrimitiveMesh).material as ShaderMaterial
			dmat.set_shader_parameter("albedo", Color(1, 0, 1, 1))
		if OS.get_environment("RAIN_EXPERIMENT") == "no_volumes":      # triage only: the rain shader's volumes switched off
			for pn2 in [_rain, _lv.get_node("LightingRig/RainSplash")]:
				(((pn2 as GPUParticles3D).draw_pass_1 as PrimitiveMesh).material as ShaderMaterial).set_shader_parameter("vol_n", 0)
		for v in Views.views(_lv):
			if _only == "" or v["name"] == _only:
				_pos.append(v)
		print("phase %s  rain emitting=%s amount_ratio=%.2f  positions %d" % [_phase, str(_rain.emitting), _rain.amount_ratio, _pos.size()])
	if _f < 6:
		return false
	if _rig:
		_rig._next_flash = 1e9      # no lightning flashes in the comparison
		_rig._flash_t = -1.0
	if _i >= _pos.size():
		print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
		quit(1 if _fails > 0 else 0)
		return false
	match _state:
		0:      # new position: let the rain column refill round it
			_aim()
			Engine.time_scale = 1.0
			_rain.visible = true
			_wait = 75
			_state = 1
		1:
			_aim()
			_wait -= 1
			if _wait <= 0:
				Engine.time_scale = 0.0      # freeze the world (flames, light flicker, drops) so the two frames differ only by the rain being drawn
				_wait = 3
				_state = 6
		6:
			_aim()
			_wait -= 1
			if _wait <= 0:
				_state = 2
		2:
			_aim()
			_make_mask()
			_state = 3
		3:      # the image is the previous frame's, taken from the aimed camera
			var net := _count_masked(_snap())
			if net > _pos_worst:
				_pos_worst = net
				_pos_worst_dir = "(yaw %d pitch %d)" % [int(YAWS[_d / PITCHES.size()]), int(PITCHES[_d % PITCHES.size()])]
				if net > NOISE_ALLOW and not _pos[_i].get("control", false):
					_snap().save_png("res://../GERFramework/shots/rainprobe_%s.png" % _pos[_i]["name"])
			_d += 1
			if _d >= YAWS.size() * PITCHES.size():
				_finish_position()
			else:
				_state = 5
				_wait = 2
		5:
			_aim()
			_wait -= 1
			if _wait <= 0:
				_state = 2
	return false
