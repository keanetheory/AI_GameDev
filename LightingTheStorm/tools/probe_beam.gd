# probe_beam.gd - run WINDOWED: Godot --path . --script res://tools/probe_beam.gd [-- cam_x cam_y cam_z]
# Beam continuity probe: lights the lamp, freezes the sweep, turns the beam through 24 headings (15 degrees apart) and counts beam-coloured pixels in the frame
# (warm, bright, not sky) for each. A continuous beam shows in every heading (the creator, 2026-10-26: it "goes out" every few seconds).
# Exits 1 if any heading shows fewer than MIN_PIXELS beam pixels.
extends SceneTree

const MIN_PIXELS := 400
var _lv: Node
var _cam: Camera3D
var _f := 0
var _k := 0
var _wait := 0
var _fails := 0
var _from := Vector3(30, 6, 30)
var _to := Vector3(8.5, 29, -4.9)
var _beacon: Node


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() >= 3:
		_from = Vector3(float(a[0]), float(a[1]), float(a[2]))
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_cam = Camera3D.new()
	_cam.far = 3000.0
	_cam.fov = 70.0
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


func _process(_d: float) -> bool:
	_f += 1
	_cam.look_at_from_position(_from, _to, Vector3.UP)
	if _f == 3:
		_lv.get_node("LightingRig").set_phase("RETURN", true)
		_beacon = _lv.get_node("InteriorRooms").refs["lamp_beacon"]
		_beacon.lit = true
		_beacon.level = 1.0
		_beacon._apply(1.0)
		_beacon.sweep_deg_s = 0.0
	if _f < 20:
		return false
	var rig := _lv.get_node("LightingRig")
	rig._next_flash = 1e9
	rig._flash_t = -1.0
	if _k >= 24:
		print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
		quit(1 if _fails > 0 else 0)
		return false
	var pivot: Node3D = _beacon._beam_pivot
	pivot.rotation.y = deg_to_rad(15.0 * _k)
	_wait += 1
	if _wait < 6:
		return false
	_wait = 0
	var img := root.get_texture().get_image()
	img.resize(400, 225)
	var n := 0
	for y in 225:
		for x in 400:
			var c := img.get_pixel(x, y)
			if c.r > 0.55 and c.g > 0.45 and c.r > c.b + 0.12:
				n += 1
	var ok := n >= MIN_PIXELS
	if OS.get_environment("BEAM_SAVE") != "" and (_k * 15) % 90 == 0:
		root.get_texture().get_image().save_png("res://../GERFramework/shots/beam_h%d.png" % (15 * _k))
	print(("PASS  " if ok else "FAIL  ") + "heading %3d deg: %5d beam pixels" % [15 * _k, n])
	_fails += int(not ok)
	_k += 1
	return false
