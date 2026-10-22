# test_interior_walk.gd - run: Godot --headless --path . --script res://tools/test_interior_walk.gd
# Walks the real player (its own physics, collision and step-up, driven by the move_forward action) through the
# lighthouse: E opens the main door from the porch, then the player follows the flood-fill route
# (tools/interior_reach.gd) to the dock window, down to Daniel in the basement, and up the tower to the lamp socket.
# A leg fails if the player makes no progress for 3 s or drops more than 1 m below the route.
# Exits 0 when every leg arrives, 1 otherwise.
extends SceneTree

const Reach := preload("res://tools/interior_reach.gd")
const Check := preload("res://tools/check_interior_reach.gd")
const TARGETS := ["G_window_view_marker", "ANCHOR_boiler_interaction", "ANCHOR_coal_pickup", "B1_daniel_marker", "ANCHOR_l1_mess", "ANCHOR_l1_quarters", "ANCHOR_l2_control", "ANCHOR_l2_instruments", "ANCHOR_lamp_stand", "Lantern_ted_marker"]

var _lv: Node
var _player: CharacterBody3D
var _door: Node3D
var _reach
var _f := 0
var _step := 0
var _wait := 0
var _failed := 0
var _leg := 0
var _path: Array[Vector3] = []
var _i := 0
var _stall := 0.0
var _best := -1
var _leg_time := 0.0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_player = _lv.get_node("Player")
	_door = _lv.get_node("LighthouseDoor")
	Engine.max_physics_steps_per_frame = 200
	Engine.time_scale = 8.0


func _physics_process(delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	Input.action_release("interact")
	match _step:
		0:   # stand in the porch facing the door and press E
			var out: Vector3 = _door.global_transform.basis.z
			_player.global_position = _door.middle() + out * 1.2 + Vector3.UP * 0.05
			_player.look_at(_player.global_position - out, Vector3.UP)
			_next(10)
		1:
			Input.action_press("interact")
			_next(60)
		2:
			_check(_door.is_open, "E opened the main door from the porch")
			var exclude: Array[RID] = [_player.get_rid()]
			_reach = Reach.new(_lv.get_world_3d().direct_space_state, exclude)
			_reach.build()
			_start_leg()
		3:
			_walk(delta)
		4:
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	return false


func _start_leg() -> void:
	if _leg >= TARGETS.size():
		_step = 4
		return
	var target: Vector3 = Check.markers(_lv)[TARGETS[_leg]]
	# the route finder's shortest path cuts inside a spiral, which a person does not; tools/test_spiral_down.gd walks the
	# basement spiral both ways like a person, so a leg that must come back up starts at the top of it
	if _player.global_position.y < Reach.LIGHTHOUSE.y and target.y > Reach.LIGHTHOUSE.y + 2.0:
		_player.global_position = _lv.get_node("InteriorRooms").anchors["spiral_top"] + Vector3(0, 0.1, 0)
		_player.velocity = Vector3.ZERO
	_path.clear()
	if _reach.flood(_player.global_position):
		var goal: Dictionary = _reach.nearest(target, true)
		if not goal.is_empty() and Vector2(goal["pos"].x - target.x, goal["pos"].z - target.z).length() < 0.8:
			_path = _reach.path_to(goal)   # every cell: cutting corners on stairs wedges the capsule against their sides
	if _path.is_empty():
		_check(false, "a route exists to %s" % TARGETS[_leg])
		_leg += 1
		_start_leg()
		return
	_i = 0
	_stall = 0.0
	_best = -1
	_leg_time = 0.0
	_step = 3


## Steer like a person: find the route point nearest the player (searching a little ahead of the last one), aim
## LOOKAHEAD points further on, and count progress along the route rather than distance to one point.
const LOOKAHEAD := 3

func _walk(delta: float) -> void:
	_leg_time += delta
	var p := _player.global_position
	var best_j := _i
	var best_d := INF
	for j in range(_i, mini(_i + 8, _path.size())):
		var q := _path[j]
		var d := Vector2(q.x - p.x, q.z - p.z).length() + absf(q.y - p.y) * 0.5
		if d < best_d:
			best_d = d
			best_j = j
	_i = best_j
	var last := _path[-1]
	if _i >= _path.size() - 2 and Vector2(last.x - p.x, last.z - p.z).length() < 0.3 and absf(last.y - p.y) < 0.5:
		Input.action_release("move_forward")
		_check(true, "walked to %s in %.0f s (%d route points), ended at local %s" % [TARGETS[_leg], _leg_time, _path.size(), p - Reach.LIGHTHOUSE])
		_leg += 1
		_start_leg()
		return
	if p.y < _path[_i].y - 1.0:
		Input.action_release("move_forward")
		_check(false, "%s: fell below the route at local %s (point %d of %d)" % [TARGETS[_leg], p - Reach.LIGHTHOUSE, _i, _path.size()])
		_leg = TARGETS.size()
		_step = 4
		return
	if _i > _best:
		_best = _i
		_stall = 0.0
	else:
		_stall += delta
	if _stall > 3.0:
		Input.action_release("move_forward")
		var hits := []
		for ci in _player.get_slide_collision_count():
			var col := _player.get_slide_collision(ci)
			hits.append("%s (normal %s)" % [(col.get_collider() as Node).get_parent().name + "/" + (col.get_collider() as Node).name, str(col.get_normal().snapped(Vector3(0.01, 0.01, 0.01)))])
		_check(false, "%s: stuck at local %s at route point %d of %d (local %s); touching %s" % [TARGETS[_leg], p - Reach.LIGHTHOUSE, _i, _path.size(), _path[_i] - Reach.LIGHTHOUSE, str(hits)])
		_leg = TARGETS.size()
		_step = 4
		return
	var t := _path[mini(_i + LOOKAHEAD, _path.size() - 1)]
	_player.look_at(Vector3(t.x, p.y, t.z), Vector3.UP)
	Input.action_press("move_forward")


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1
