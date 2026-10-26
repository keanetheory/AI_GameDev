# probe_washout.gd - run WINDOWED: Godot --path . --script res://tools/probe_washout.gd [-- fill_value ...]
# Washed-out metric (creator, 2026-10-26: "I prefer the darker colours to show through"). Whole-frame statistics, bottom 20 % cropped (subtitles):
#   mean luma, mean HSV saturation, share of dark pixels (HSV value < 0.35). From the creator's two screenshots:
#   washed out (stairwell from the hall): luma 0.50 sat 0.38 dark 0.16;  good (basement from the stair): luma 0.33 sat 0.47 dark 0.37.
# Pass: sat >= 0.38 (the washed frame is 0.38 on the creator's image, with luma 0.50) and luma <= 0.46 in every interior view of lhf_views. Args set ToonLook.fill for a sweep.
extends SceneTree

const Views := preload("res://tools/lhf_views.gd")
const MIN_SAT := 0.38
const MAX_LUMA := 0.46
var _lv: Node
var _cam: Camera3D
var _player: Node3D
var _views: Array = []
var _fills: Array = []
var _fi := 0
var _k := 0
var _f := 0
var _wait := 0
var _fails := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		_fills.append(float(a))
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_cam = Camera3D.new()
	_cam.far = 200.0
	_cam.fov = 70.0
	root.add_child(_cam)
	_cam.current = true
	_player = _lv.get_node_or_null("Player")
	if _player:
		_player.process_mode = Node.PROCESS_MODE_DISABLED
		for c in _player.find_children("*", "Camera3D", true, false):
			(c as Camera3D).current = false
	for c in _lv.find_children("*", "CanvasLayer", true, false):
		(c as CanvasLayer).visible = false


func _stats() -> Array:
	var img := root.get_texture().get_image()
	img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	var n := 0
	var l := 0.0
	var s := 0.0
	var d := 0
	for y in range(0, 144):
		for x in 320:
			var c := img.get_pixel(x, y)
			l += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			s += c.s
			d += int(c.v < 0.35)
			n += 1
	return [l / n, s / n, float(d) / n]


func _process(_dt: float) -> bool:
	_f += 1
	if _f == 3:
		get_root().get_node("Level/LightingRig").set_phase("ISLAND", true)
		_views = Views.views(_lv).filter(func(v): return not v.get("control", false))
		if _fills.is_empty():
			_fills = [-1.0]
	if _f < 6:
		return false
	if _fi >= _fills.size():
		print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
		quit(1 if _fails > 0 else 0)
		return false
	if _k == 0 and _wait == 0 and _fills[_fi] >= 0.0:
		var tl := _lv.get_node("ToonLook")
		tl.fill = _fills[_fi]
		if OS.get_environment("FILL_TINT") != "":
			var ft := OS.get_environment("FILL_TINT").split_floats(",")
			tl.fill_tint = Color(ft[0], ft[1], ft[2])
		_lv.get_node("ToonLook").call("set_enabled", false)
		tl.set_enabled(true)
		print("--- ToonLook.fill = %.2f" % _fills[_fi])
	var v: Dictionary = _views[_k]
	_cam.look_at_from_position(v["from"], v["to"], Vector3.UP if absf((v["to"] - v["from"]).normalized().y) < 0.99 else Vector3.RIGHT)
	if _player:
		_player.global_position = (v["from"] as Vector3) + Vector3(0, -1.6, 0)
	_wait += 1
	if _wait < 70:
		return false
	var st := _stats()
	var ok: bool = st[1] >= (0.22 if v.get("grey_palette", false) else MIN_SAT) and st[0] <= MAX_LUMA
	print(("PASS  " if ok else "FAIL  ") + "%-20s luma %.2f sat %.2f dark %.2f" % [v["name"], st[0], st[1], st[2]])
	_fails += int(not ok)
	_wait = 0
	_k += 1
	if _k >= _views.size():
		_k = 0
		_fi += 1
	return false
