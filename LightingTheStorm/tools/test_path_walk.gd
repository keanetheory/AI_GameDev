# test_path_walk.gd - run: Godot --headless --path . --script res://tools/test_path_walk.gd
# Walks the player up the last stretch of the cut walkway, off its top end and all the way along the earth path
# through the forest to the city gate. Fails if the player drops below the path (no collision), gets stuck, or
# leaves the floor for long. The walkway itself is covered by tools/test_cliffwalk.gd.
extends SceneTree

var _lv: Node
var _p: CharacterBody3D
var _m: Node3D
var _f := 0
var _wps: Array[Vector3] = []
var _wp := 0
var _frames := 0
var _off := 0
var _lowest_gap := 0.0       # how far below the path the player has been (positive = below)
var _stuck_f := 0
var _last := Vector3.ZERO


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_p = _lv.get_node("Player")
	_m = _lv.get_node("Mainland")


func _begin() -> void:
	var y: Array = _m._gal_y
	var z: Array = _m._gal_z
	var x0: float = _m.GAL_X0
	var end_i: int = y.size() - 1
	# the last 40 m of the walkway, hugging the middle of the floor
	for k in range(end_i - 40, end_i + 1, 6):
		_wps.append(Vector3(x0 - k, y[k], z[k] + 3.0))
	var path: Array[Vector3] = _m._forest_points(_m._walk_end)
	for i in range(0, path.size(), 5):
		_wps.append(path[i])
	_wps.append(path[path.size() - 1])
	_p.global_position = Vector3(_wps[0].x, _wps[0].y + 1.0, _wps[0].z)
	_p.velocity = Vector3.ZERO
	print("-- walking %d waypoints: end of the walkway, then the earth path to the city gate" % _wps.size())


func _physics_process(_dt: float) -> bool:
	_f += 1
	if _wps.is_empty():
		if _m._gal_y.is_empty():
			return false
		_begin()
		return false
	if _f < 20:
		return false
	_frames += 1
	if not _p.is_on_floor():
		_off += 1
	var to: Vector3 = _wps[_wp]
	_lowest_gap = maxf(_lowest_gap, to.y - _p.global_position.y)
	var dv := Vector3(to.x - _p.global_position.x, 0.0, to.z - _p.global_position.z)
	if _p.global_position.distance_to(_last) < 0.02:
		_stuck_f += 1
	else:
		_stuck_f = 0
	_last = _p.global_position
	if dv.length() < 1.6 and _wp < _wps.size() - 1:
		_wp += 1
		return false
	var done := _wp == _wps.size() - 1 and dv.length() < 2.5
	var dropped := _lowest_gap > 2.5
	if done or dropped or _stuck_f > 90 or _frames > 6000:
		print("end: (%.1f, %.1f, %.1f) after %d frames; waypoint %d of %d; frames off the floor %d; lowest below path %.2f m" % [
			_p.global_position.x, _p.global_position.y, _p.global_position.z, _frames, _wp + 1, _wps.size(), _off, _lowest_gap])
		var ok := done and not dropped
		print("PASS  walked the whole path to the city gate without dropping through" if ok else "FAIL  %s" % ("dropped through the path" if dropped else "stuck or did not finish"))
		Input.action_release("move_forward")
		quit(0 if ok else 1)
		return false
	_p.rotation.y = atan2(-dv.x, -dv.z)
	Input.action_press("move_forward")
	return false
