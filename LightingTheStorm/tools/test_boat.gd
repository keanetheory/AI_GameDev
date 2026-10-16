# test_boat.gd - run: Godot --headless --path . --script res://tools/test_boat.gd
# 1. Handling checks from AIAgentCrew/world_output/boat_spec.json (hazards switched off so they
#    can be done anywhere).
# 2. Hazards: sailing straight at a sea stack must register a hit and recover the boat.
# 3. The full crossing out and back, weaving around the sea stacks with A/D only, docking each
#    end and stepping ashore. The lighthouse berths are in the bay of the stone harbour (dock_harbour) on the island's west side
#    (bow out, towards -X), so the route leaves west and comes back round into the inlet.
extends SceneTree

# Harbour exit and approach waypoints. These are passed by flat distance only (the stack waypoints
# also count as passed once the boat is level with them in z).
const HARBOUR_EXIT: Array[Vector3] = [Vector3(-50, 0, 20.7), Vector3(-58, 0, 48)]
const HARBOUR_APPROACH: Array[Vector3] = [Vector3(-55, 0, 62), Vector3(-92, 0, 46), Vector3(-88, 0, 20.5), Vector3(-52, 0, 20.5)]

var _lv: Node
var _boat: Node3D
var _player: CharacterBody3D
var _f := 0
var _step := 0
var _t := 0.0
var _yaw0 := 0.0
var _hits := 0
var _wps: Array[Vector3] = []
var _wp := 0
var _stack_hit_pos := Vector3.ZERO
var _last_pos := Vector3.ZERO     # boat position last frame, for reporting where a hit happened


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_boat = _lv.get_node("Boat")
	_player = _lv.get_node("Player")
	Engine.max_physics_steps_per_frame = 2000
	Engine.time_scale = 40.0


func _physics_process(delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	_t += delta
	_last_pos = _boat.global_position
	match _step:
		0:
			print("start: state=", _boat.state, " at ", _boat.global_position, " zone=", _boat.current_zone.zone_id,
				" overlapping a hazard at the berth: ", _boat._hits_hazard(_boat.global_transform))
			_boat.hazard_mask = 0
			_player.global_position = _zone("DOCK_LIGHTHOUSE").landing
			_boat.board()
			_boat.cast_off()
			_next()
		1:   # sail clear of the dock zone and check we hold full speed
			_steer_to(Vector3(-60, 0, 150))
			if _boat.global_position.z > 150.0 and _t > 4.0:
				_release_all()
				print("check: speed = %.2f m/s (boat.speed = %.1f)" % [_boat.velocity.length(), _boat.speed])
				_yaw0 = _boat.rotation.y
				Input.action_press("move_left")
				_next()
		2:
			if _t > 5.0:
				var turned := rad_to_deg(angle_difference(_yaw0, _boat.rotation.y))
				Input.action_release("move_left")
				print("check: hold A 5 s -> turned %.1f deg (about %.1f deg/s, spec max 35)" % [turned, absf(turned) / 5.0])
				_next()
		3:
			if _t > 1.0:
				_yaw0 = _boat.rotation.y
				print("check: rudder after release = %.2f (want 0)" % _boat.rudder)
				_next()
		4:
			Input.action_press("move_forward")
			Input.action_press("move_back")
			if _t > 3.0:
				var drift := rad_to_deg(absf(angle_difference(_yaw0, _boat.rotation.y)))
				print("check: W+S 3 s -> speed %.2f, heading change %.2f deg (want full speed and 0)" % [_boat.velocity.length(), drift])
				_release_all()
				_next()
		5:   # hazards back on: sail straight at the first stack
			_boat.hazard_mask = 2
			_boat.hazard_hit.connect(func():
				_hits += 1
				if _step >= 8:
					print("  hit near ", _last_pos))
			_boat.global_position = Vector3(18, 0.15, 62)
			_boat.rotation.y = PI      # bow towards +Z
			_boat._leave_zone = _zone("DOCK_LIGHTHOUSE")   # we are leaving it, so no auto-dock
			_boat._trail.clear()
			_boat._stun = 0.0
			_boat.velocity = Vector3.ZERO
			_next()
		6:
			_steer_to(_node_pos("SeaStack1"))
			if _hits > 0:
				print("hazard: hit a sea stack at %s, recovered to %s, stunned %.1f s" % [_stack_hit_pos, _boat.global_position, _boat._stun])
				_release_all()
				_next()
			else:
				_stack_hit_pos = _boat.global_position
		7:   # after recovery: clear of the rock again
			if _t > 3.0:
				print("hazard: after recovery overlapping=", _boat._hits_hazard(_boat.global_transform), " stun=%.1f" % _boat._stun)
				# put it back at the berth for the crossing
				var berth := _zone("DOCK_LIGHTHOUSE")
				_boat.global_position = berth.global_position
				_boat.rotation.y = deg_to_rad(berth.berth_yaw_deg)
				_boat.state = _boat.State.DOCKED
				_boat.current_zone = _zone("DOCK_LIGHTHOUSE")
				_boat._leave_zone = null
				_boat.cast_off()
				_wps = HARBOUR_EXIT + _route_around_stacks(false)
				_wp = 0
				_hits = 0
				_next()
		8:   # outbound, weaving
			_follow_route(_zone_pos("DOCK_PORT"))
			if _boat.state == _boat.State.DOCKED:
				_release_all()
				print("outbound: docked at ", _boat.current_zone.zone_id, " after %.0f s with %d hits" % [_t, _hits])
				_boat.disembark()
				_next()
		9:
			if _t > 1.5:
				print("ashore: player ", _player.global_position, " on_floor=", _player.is_on_floor())
				_player.global_position = _zone("DOCK_PORT").landing
				_boat.board()
				_boat.cast_off()
				_wps = _route_around_stacks(true) + HARBOUR_APPROACH
				_wp = 0
				_hits = 0
				_next()
		10:  # return, weaving
			_follow_route(_zone_pos("DOCK_LIGHTHOUSE"))
			if _boat.state == _boat.State.DOCKED:
				_release_all()
				print("return: docked at ", _boat.current_zone.zone_id, " after %.0f s with %d hits" % [_t, _hits])
				_boat.disembark()
				_next()
		11:
			if _t > 1.5:
				print("ashore: player ", _player.global_position, " on_floor=", _player.is_on_floor())
				print("DONE")
				quit()
	if _t > 400.0:
		print("TIMEOUT in step ", _step, " state=", _boat.state, " at ", _boat.global_position, " hits=", _hits)
		quit()
	return false


func _next() -> void:
	_step += 1
	_t = 0.0


func _zone(zone_id: String) -> Node3D:
	for z in get_nodes_in_group("dock_zone"):
		if z.zone_id == zone_id:
			return z
	return null


func _zone_pos(zone_id: String) -> Vector3:
	return _zone(zone_id).global_position


func _node_pos(node_name: String) -> Vector3:
	return _lv.get_node("SeaRocks/" + node_name).global_position


## Waypoints that pass each stack on the side nearer the straight lane, 22 m clear of its centre.
func _route_around_stacks(returning: bool) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for stack in _lv.get_node("SeaRocks").get_children():
		var p: Vector3 = stack.global_position
		var side := 22.0 if p.x < 14.0 else -22.0
		pts.append(Vector3(p.x + side, 0.0, p.z))
	pts.sort_custom(func(a, b): return a.z > b.z if returning else a.z < b.z)
	return pts


func _follow_route(final_target: Vector3) -> void:
	var target := final_target
	if _wp < _wps.size():
		target = _wps[_wp]
		var flat := Vector2(_boat.global_position.x - target.x, _boat.global_position.z - target.z).length()
		var harbour := HARBOUR_EXIT.has(target) or HARBOUR_APPROACH.has(target)
		if flat < (12.0 if harbour else 8.0) or (not harbour and absf(_boat.global_position.z - target.z) < 6.0):
			_wp += 1
	_steer_to(target)


func _release_all() -> void:
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)


## Steer (A/D only) towards a point.
func _steer_to(target: Vector3) -> void:
	var to := target - _boat.global_position
	to.y = 0.0
	var ang := (-_boat.global_transform.basis.z).signed_angle_to(to, Vector3.UP)
	if ang > 0.04:
		Input.action_press("move_left")
		Input.action_release("move_right")
	elif ang < -0.04:
		Input.action_press("move_right")
		Input.action_release("move_left")
	else:
		_release_all()

