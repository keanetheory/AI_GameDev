# test_spiral_down.gd - run: Godot --headless --path . --script res://tools/test_spiral_down.gd
# The spiral stair from the hall to the basement, walked the way a person walks a spiral: the real player body, its own
# step-up and collision, steered along the circle of the walking line (radius 0.85 round the newel) rather than along the
# flood fill's shortest path, which cuts inside the curve. Down from the hall pad to the basement lobby, then back up.
# Also checks the stairwell: nothing hangs across the opening (the ceiling joists stop at it) and the old switchback
# flights are gone. Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const WALK_R := 0.85
var _lv: Node
var _player: CharacterBody3D
var _rooms: Node
var _spiral_centre := Vector3.ZERO
var _front_deg := 0.0
var _f := 0
var _step := 0
var _wait := 0
var _failed := 0
var _dir := 1.0           # +1 follows the treads' increasing bearing (down), -1 against it (up)
var _t := 0.0
var _last_y := 0.0
var _stall := 0.0
var _probe := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_player = _lv.get_node("Player")
	_rooms = _lv.get_node("InteriorRooms")
	Engine.max_physics_steps_per_frame = 100
	Engine.time_scale = 4.0


func _physics_process(delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			var sp: Node = _rooms.get_node("SpiralDown")
			_check(sp != null and sp.get_child_count() > 20, "the spiral stair exists")
			_check(_lv.find_child("B1_stair_upper_00", true, false) == null and _lv.find_child("B1_switchback_landing", true, false) == null, "the old switchback flights are gone")
			var joists := 0
			for j in _rooms.find_children("B_Joist_*", "MeshInstance3D", true, false):
				# a joist whole across the opening would span u 0.8..3.6 at v 2.3..5.7
				var v := -(j as Node3D).position.z
				if v > 2.4 and v < 5.6:
					joists += 1
			_check(joists == 0, "no ceiling joist crosses the stairwell opening (%d whole joists inside it)" % joists)
			var c: Vector3 = _rooms.anchors["spiral_top"]
			_spiral_centre = _rooms.kit.world(2.2, 0.0, 4.0)
			_front_deg = rad_to_deg(atan2(0.9024, 0.4309))
			_player.global_position = _rooms.anchors["spiral_top"] + Vector3(0, 0.1, 0)
			_player.velocity = Vector3.ZERO
			_dir = 1.0
			_t = 0.0
			_stall = 0.0
			_last_y = _player.global_position.y
			_next(10)
		1:   # down
			_t += delta
			_steer()
			if _player.global_position.y < _rooms.anchors["spiral_foot"].y + 0.4:
				Input.action_release("move_forward")
				_check(true, "walked down the spiral in %.1f s, ended at y %.2f" % [_t, _player.global_position.y - 9.61])
				_dir = -1.0
				_t = 0.0
				_stall = 0.0
				# step off the stair's foot and come back to the first tread
				_player.global_position = _rooms.anchors["spiral_foot"] + Vector3(0, 0.1, 0)
				_player.velocity = Vector3.ZERO
				_next(20)
			elif _t > 40.0 or _progress_stalled(delta):
				Input.action_release("move_forward")
				_check(false, "walking down: stuck at y %.2f after %.1f s" % [_player.global_position.y - 9.61, _t])
				_step = 9
		2:   # up
			_t += delta
			_steer()
			if _player.global_position.y > _rooms.anchors["spiral_top"].y - 0.3:
				Input.action_release("move_forward")
				_check(true, "walked up the spiral in %.1f s, ended at y %.2f" % [_t, _player.global_position.y - 9.61])
				_probe = 0
				_step = 3
				_wait = 5
			elif _t > 60.0 or _progress_stalled(delta):
				Input.action_release("move_forward")
				_check(false, "walking up: stuck at y %.2f after %.1f s" % [_player.global_position.y - 9.61, _t])
				_step = 9
		3:   # nobody can fall into the hole round the stair: walk at its rail from the hall side, all the way round
			if _probe > 0:
				var fell: bool = _player.global_position.y < _rooms.anchors["spiral_top"].y - 0.4
				_check(not fell, "pushing at the stairwell rail from bearing %d: still on the floor (y %.2f)" % [(_probe - 1) * 45, _player.global_position.y - 9.61])
			if _probe >= 8:
				_step = 9
			else:
				var ang := deg_to_rad(_front_deg + 45.0 * _probe + 90.0 + 25.0)     # away from the entrance gap
				var out := Vector3(cos(ang), 0, sin(ang))
				_player.global_position = _spiral_centre + out * 2.0 + Vector3(0, _rooms.anchors["spiral_top"].y - _spiral_centre.y + 0.1, 0)
				_player.velocity = Vector3.ZERO
				_player.look_at(_player.global_position - out, Vector3.UP)
				Input.action_press("move_forward")
				_probe += 1
				_wait = 70
		9:
			Input.action_release("move_forward")
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	return false


func _progress_stalled(delta: float) -> bool:
	if absf(_player.global_position.y - _last_y) > 0.05:
		_last_y = _player.global_position.y
		_stall = 0.0
	else:
		_stall += delta
	return _stall > 4.0


## Aim at a point 28 degrees further round the walking circle (in the direction of travel), at the player's own height.
func _steer() -> void:
	var p := _player.global_position
	var rel := Vector2(p.x - _spiral_centre.x, p.z - _spiral_centre.z)
	var ang := rad_to_deg(atan2(rel.y, rel.x))
	var target_ang := deg_to_rad(ang + _dir * 28.0)
	var t := Vector3(_spiral_centre.x + WALK_R * cos(target_ang), p.y, _spiral_centre.z + WALK_R * sin(target_ang))
	if Vector2(t.x - p.x, t.z - p.z).length() > 0.01:
		_player.look_at(t, Vector3.UP)
	Input.action_press("move_forward")


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1
