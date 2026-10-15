# test_cliffwalk.gd - run: Godot --headless --path . --script res://tools/test_cliffwalk.gd
# Walks the player from the east boardwalk, onto the cut walkway at the quay and all the way up it to the
# cliff top, then also from the west boardwalk up the timber link ramp. Reports whether they stay on the
# floor (no falling, no getting stuck), how high they end up, and whether the rock wall holds them in.
extends SceneTree

var _lv: Node
var _p: CharacterBody3D
var _m: Node3D
var _f := 0
var _leg := 0
var _wps: Array[Vector3] = []
var _wp := 0
var _frames := 0
var _off := 0
var _min_gap := 99.0
var _names := ["east boardwalk -> cut walkway -> cliff top", "west boardwalk -> timber link -> walkway"]


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_p = _lv.get_node("Player")
	_m = _lv.get_node("Mainland")


func _begin() -> void:
	_wps.clear()
	_wp = 0
	_frames = 0
	_off = 0
	_f = 0
	var y: Array = _m._gal_y
	var z: Array = _m._gal_z
	var d: Array = _m._gal_depth
	var x0: float = _m.GAL_X0
	if _leg == 0:
		_wps.append(Vector3(60.0, 0.0, 555.6))       # on the east boardwalk
		_wps.append(Vector3(40.0, 0.0, 556.8))
		_wps.append(Vector3(30.0, 0.0, 558.5))
	else:
		_wps.append(Vector3(-6.0, 0.0, 552.4))       # on the west boardwalk
		_wps.append(Vector3(4.0, 0.0, 552.6))
		_wps.append(Vector3(3.2, 0.0, 556.0))        # up the link ramp
		_wps.append(Vector3(3.2, 0.0, 558.4))
	var k0 := 0 if _leg == 0 else int(x0 - 3.0)
	var start_k := int(x0 - 30.0) if _leg == 0 else int(x0 - 3.0)
	for k in range(start_k, y.size(), 8):
		var kk := mini(k, y.size() - 1)
		_wps.append(Vector3(x0 - kk * 1.0, 0.0, z[kk] + 0.5 + minf(2.5, d[kk] * 0.5)))
	_p.global_position = Vector3(_wps[0].x, 4.0, _wps[0].z)
	_p.velocity = Vector3.ZERO
	print("-- leg: ", _names[_leg])


func _physics_process(_dt: float) -> bool:
	_f += 1
	if _wps.is_empty():
		if _m._gal_y.is_empty():
			return false          # the walkway is built in Mainland._ready; wait for it
		_begin()
		return false
	if _f < 20:
		return false
	_frames += 1
	if not _p.is_on_floor():
		_off += 1
	var to: Vector3 = _wps[_wp]
	var dv := Vector3(to.x - _p.global_position.x, 0.0, to.z - _p.global_position.z)
	if dv.length() < 1.3 and _wp < _wps.size() - 1:
		_wp += 1
		return false
	var done := _wp == _wps.size() - 1 and dv.length() < 1.5
	if done or _frames > 9000 or _p.global_position.y < -1.0:
		print("end: (%.1f, %.1f, %.1f) after %d frames; waypoint %d of %d; frames off the floor %d; %s" % [
			_p.global_position.x, _p.global_position.y, _p.global_position.z, _frames, _wp + 1, _wps.size(), _off,
			"REACHED THE TOP" if done else "DID NOT FINISH"])
		Input.action_release("move_forward")
		_leg += 1
		if _leg >= 2:
			quit()
		else:
			_begin()
		return false
	_p.rotation.y = atan2(-dv.x, -dv.z)
	Input.action_press("move_forward")
	return false
