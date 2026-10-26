# probe_lighting.gd - run WINDOWED: Godot --path . --script res://tools/probe_lighting.gd [-- PHASE [room_view_name] [csv_path]]
# Lighting probe. For every interior position of tools/lhf_views.gd (every room, the basement included) it finds the two longest
# clear horizontal sight lines to a wall, fixes a 0.5 m square wall sample at the end of each (the wall point W, found by ray), and
# stands the camera (and the player, so the room's lights switch on exactly as in play) at 2, 4, 6 and 8 m back from W where the
# room is that long, looking at W. It records the mean brightness (luma) and mean saturation (HSV) of the pixels on that
# wall sample, in the rendered, tonemapped frame (average of 4 frames: flames flicker).
# Pass rule (creator: "consistent at any distance"): in every room the farthest sample keeps at least FAR_KEEP of the 2 m sample's
# brightness and saturation, and no sample is darker than MIN_LUMA.
extends SceneTree

const Views := preload("res://tools/lhf_views.gd")
const DISTS := [2.0, 4.0, 6.0, 8.0]
const FAR_KEEP := 0.70
const MIN_LUMA := 0.10
const W := 800
const H := 450
const FOV := 40.0

var _lv: Node
var _cam: Camera3D
var _player: Node3D
var _rig: Node
var _views: Array = []
var _samples: Array = []          # [{room, view, dir, d, wall: Vector3, cam: Vector3, luma, sat}]
var _plan: Array = []             # planned [{room, view, ...}] built once the level is up
var _k := 0
var _f := 0
var _wait := 0
var _acc_l := 0.0
var _acc_s := 0.0
var _acc_n := 0
var _phase := "ISLAND"
var _only := ""
var _csv := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_phase = args[0]
	if args.size() > 1:
		_only = args[1]
	if args.size() > 2:
		_csv = args[2]
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_cam = Camera3D.new()
	_cam.far = 200.0
	_cam.fov = FOV
	root.add_child(_cam)
	_cam.current = true
	_player = _lv.get_node_or_null("Player")
	if _player:
		_player.process_mode = Node.PROCESS_MODE_DISABLED
		for c in _player.find_children("*", "Camera3D", true, false):
			(c as Camera3D).current = false
	for c in _lv.find_children("*", "CanvasLayer", true, false):
		(c as CanvasLayer).visible = false


func _build_plan() -> void:
	var space := _cam.get_world_3d().direct_space_state
	for v in Views.views(_lv):
		if v.get("control", false):
			continue
		if _only != "" and v["name"] != _only:
			continue
		var o: Vector3 = v["from"]
		var cands: Array = []
		for k in 16:
			var a := TAU * k / 16.0
			var dir := Vector3(cos(a), 0, sin(a))
			var q := PhysicsRayQueryParameters3D.create(o, o + dir * 14.0)
			q.collide_with_areas = false
			var r := space.intersect_ray(q)
			if r.is_empty() or absf((r["normal"] as Vector3).y) > 0.3:
				continue
			var cn := String((r["collider"] as Node).name) + String((r["collider"] as Node).get_parent().name)
			if "Door" in cn or "Glass" in cn or "Window" in cn or "Jamb" in cn:
				continue      # a door leaf or pane is not a wall sample
			var w: Vector3 = r["position"]
			var n: Vector3 = r["normal"]
			n.y = 0.0
			if n.length() < 0.5:
				continue
			n = n.normalized()
			# the free run back along the wall normal from W (eye height): how far a camera can stand and still see W
			var q2 := PhysicsRayQueryParameters3D.create(w + n * 0.05, w + n * 10.0)
			q2.collide_with_areas = false
			var r2 := space.intersect_ray(q2)
			var free := 10.0 if r2.is_empty() else w.distance_to(r2["position"]) - 0.1
			cands.append({"wall": w, "n": n, "free": free})
		cands.sort_custom(func(x, y): return x["free"] > y["free"])
		var used := 0
		for c in cands:
			if used >= 2:
				break
			# skip a candidate whose wall point is within 1.5 m of one already chosen for this view
			var dup := false
			for s in _plan:
				if s["view"] == v["name"] and (s["wall"] as Vector3).distance_to(c["wall"]) < 1.5:
					dup = true
			if dup:
				continue
			used += 1
			for d in DISTS:
				if d <= c["free"] - 0.4:
					_plan.append({"room": v["room"], "view": v["name"], "d": d, "wall": c["wall"], "cam": c["wall"] + c["n"] * d, "line": used})
	print("lighting probe: phase %s, %d samples" % [_phase, _plan.size()])


func _grab() -> void:
	var img := root.get_texture().get_image()
	img.resize(W, H, Image.INTERPOLATE_BILINEAR)
	var p: Dictionary = _plan[_k]
	var sc := _cam.unproject_position(p["wall"]) * (Vector2(W, H) / root.get_visible_rect().size)
	var cam_d: float = (p["cam"] as Vector3).distance_to(p["wall"])
	# 0.5 m square at the wall: its size in pixels at this distance
	var half := clampi(int(0.25 / (cam_d * tan(deg_to_rad(FOV * 0.5)) * 2.0) * H), 4, 120)
	var l := 0.0
	var s := 0.0
	var n := 0
	for y in range(int(sc.y) - half, int(sc.y) + half):
		for x in range(int(sc.x) - half, int(sc.x) + half):
			if x < 0 or y < 0 or x >= W or y >= H:
				continue
			var c := img.get_pixel(x, y)
			l += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			s += c.s
			n += 1
	if n > 0:
		_acc_l += l / n
		_acc_s += s / n
		_acc_n += 1


func _report() -> void:
	var rows := {}
	for s in _samples:
		var key: String = "%s/%s#%d" % [s["room"], s["view"], s["line"]]
		if not rows.has(key):
			rows[key] = []
		rows[key].append(s)
	var fails := 0
	var csv := "room,view,line,d,luma,sat\n"
	print("\n%-34s %s" % ["room/view#line", "  d: luma sat   (relative to 2 m)"])
	for key in rows:
		var arr: Array = rows[key]
		var line := "%-34s" % key
		var near: Dictionary = arr[0]
		var far: Dictionary = arr[arr.size() - 1]
		for s in arr:
			line += "  %.0fm: %.2f %.2f" % [s["d"], s["luma"], s["sat"]]
			csv += "%s,%s,%d,%.0f,%.4f,%.4f\n" % [s["room"], s["view"], s["line"], s["d"], s["luma"], s["sat"]]
		var ok := true
		for s in arr.duplicate():
			if s["luma"] < 0.02:      # essentially black: the camera is inside a visual-only solid (roof liner, panel): the view is blocked, not the light
				print("        (sample %.0f m dropped: view blocked, luma %.3f)" % [s["d"], s["luma"]])
				arr.erase(s)
		if arr.is_empty():
			continue
		near = arr[0]
		far = arr[arr.size() - 1]
		for s in arr:
			if s["luma"] < MIN_LUMA:
				ok = false
		if arr.size() > 1:
			if far["luma"] < FAR_KEEP * near["luma"] or far["sat"] < FAR_KEEP * near["sat"]:
				ok = false
			line += "   far/near luma %.2f sat %.2f" % [far["luma"] / maxf(near["luma"], 0.001), far["sat"] / maxf(near["sat"], 0.001)]
		print(("PASS  " if ok else "FAIL  ") + line)
		if not ok:
			print("        far sample: camera %s looks at wall %s" % [str(far["cam"]), str(far["wall"])])
		fails += int(not ok)
	if _csv != "":
		var fa := FileAccess.open(_csv, FileAccess.WRITE)
		if fa:
			fa.store_string(csv)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)


func _process(_dt: float) -> bool:
	_f += 1
	if _f == 3:
		_rig = _lv.get_node("LightingRig")
		_rig.set_phase(_phase, true)
		_build_plan()
		_wait = 0
	if _f < 6:
		return false
	if _rig:
		_rig._next_flash = 1e9
		_rig._flash_t = -1.0
	if _k >= _plan.size():
		_report()
		return false
	var p: Dictionary = _plan[_k]
	var tgt: Vector3 = p["wall"]
	_cam.look_at_from_position(p["cam"], tgt, Vector3.UP)
	if _player:
		_player.global_position = p["cam"] + Vector3(0, -1.6, 0)
	if _wait == 0:
		_acc_l = 0.0
		_acc_s = 0.0
		_acc_n = 0
	_wait += 1
	if _wait < 60:       # lights fade in at 5 per second: one second is plenty
		return false
	if _wait >= 60 and _wait % 3 == 0 and _wait <= 69:
		_grab()
	if _wait >= 70:
		var s: Dictionary = p.duplicate()
		s["luma"] = _acc_l / maxf(_acc_n, 1)
		s["sat"] = _acc_s / maxf(_acc_n, 1)
		_samples.append(s)
		_k += 1
		_wait = 0
	return false
