# test_boardwalk.gd - run: Godot --headless --path . --script res://tools/test_boardwalk.gd
# Walks the player along each timber boardwalk, from the central quay to the west quay and to the east
# quay, and reports whether they stay on the planking (on_floor, no falling) the whole way.
extends SceneTree

var _lv: Node
var _p: CharacterBody3D
var _f := 0
var _leg := 0
var _legs := [
	{"name": "west", "node": "BoardwalkWest"},
	{"name": "east", "node": "BoardwalkEast"},
]
var _wps: PackedVector3Array
var _wp := 0
var _min_y := 99.0
var _off_floor := 0
var _frames := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_p = _lv.get_node("Player")
	_start_leg()


func _start_leg() -> void:
	var l: Dictionary = _legs[_leg]
	_wps = _lv.get_node(l["node"]).points
	_wp = 1
	_p.global_position = _wps[0] + Vector3(0.0, 0.5, 0.0)
	_p.velocity = Vector3.ZERO
	_min_y = 99.0
	_off_floor = 0
	_frames = 0
	_f = 0


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var l: Dictionary = _legs[_leg]
	var to: Vector3 = _wps[_wp]
	var d := Vector3(to.x - _p.global_position.x, 0, to.z - _p.global_position.z)
	if d.length() < 1.2 and _wp < _wps.size() - 1:
		_wp += 1
		return false
	_frames += 1
	_min_y = minf(_min_y, _p.global_position.y)
	if not _p.is_on_floor():
		_off_floor += 1
	var at_end := _wp == _wps.size() - 1 and d.length() < 1.0
	if at_end or _frames > 2400 or _p.global_position.y < 0.5:
		print("walk %s: ended at (%.1f, %.2f, %.1f) after %d frames; lowest y %.2f; frames off the floor %d; %s" % [
			l["name"], _p.global_position.x, _p.global_position.y, _p.global_position.z, _frames, _min_y, _off_floor,
			"REACHED THE OTHER QUAY" if at_end else "DID NOT REACH"])
		Input.action_release("move_forward")
		_leg += 1
		if _leg >= _legs.size():
			quit()
		else:
			_start_leg()
		return false
	_p.rotation.y = atan2(-d.x, -d.z)
	Input.action_press("move_forward")
	return false
