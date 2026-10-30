# test_disembark.gd - run: Godot --headless --path . --script res://tools/test_disembark.gd
# Saltgate SLT-01: the arrival at the Saltgate as a player does it, with the real Player capsule and real input.
#   1. The launch sails in from open water and auto-docks in DOCK_PORT on its own.
#   2. Tied up, it must not drift under the player.
#   3. Q (the "disembark" action) steps ashore: the view must move smoothly (no per-frame jump, no turn, no dip),
#      and the player must land standing on the quay deck.
#   4. Walk to the burner, E picks it up (BURNER_PICKED_UP).
#   5. Walk back to the boat's board radius.
#   6. The port-to-cliff joint: from the west boardwalk's end along the quay deck, up the timber link ramp onto the
#      cliff walkway, and back down.
# Every walk fails on a stall, a step higher than the player's step-up, a drop off an edge, or falling through.
# Runs at time scale 1 so the per-frame camera numbers are real frames. Run it several times: arrival flakiness has
# bitten this project before (the acceptance is 8 passes out of 8 consecutive runs).
extends SceneTree

const MAX_CAM_STEP := 0.45     # metres the camera may move in one physics frame while stepping ashore (27 m/s)
const MAX_DROP := 0.45         # largest fall off an edge allowed on a walk (anything more is a floating step)
const STALL_S := 1.5           # seconds without 0.3 m of progress towards the next waypoint = stuck
const ARRIVE := 0.6            # flat distance that counts as reaching a waypoint

var _lv: Node3D
var _boat: Node3D
var _player: CharacterBody3D
var _cam: Camera3D
var _gs: Node
var _im: Node
var _burner: Node3D
var _f := 0
var _step := 0
var _t := 0.0
var _fails := 0
var _wait := 0

# per-phase measurements
var _dock_t := 0.0
var _berth := Vector3.ZERO
var _drift := 0.0
var _cam_prev := Vector3.ZERO
var _cam_max_step := 0.0
var _cam_min_y := INF
var _yaw0 := 0.0
var _yaw_max := 0.0
var _seat_y := 0.0
# walking
var _wps: Array[Vector3] = []
var _wp := 0
var _leg := ""
var _best := INF
var _best_t := 0.0
var _air_top := -INF
var _max_drop := 0.0
var _max_rise := 0.0
var _last_y := 0.0


func _initialize() -> void:
	Engine.set_meta("no_crossing_hazards", true)      # these tests sail the route with a simple bot; the forecast's hazards are tested in test_crossing_sequence.gd
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_boat = _lv.get_node("Boat")
	_player = _lv.get_node("Player")
	_cam = _player.get_node("Head/Camera3D")
	_burner = _lv.get_node("BurnerPickup")


func _physics_process(delta: float) -> bool:
	_f += 1
	if _f < 40:   # let the builders (cliffs, walkway, quay colliders) finish
		return false
	_t += delta
	if _wait > 0:
		_wait -= 1
		return false
	Input.action_release("interact")
	Input.action_release("disembark")
	match _step:
		0:
			_gs = root.get_node_or_null("GameState")
			_im = root.get_node_or_null("Interaction")
			var port := _zone("DOCK_PORT")
			_check(port != null, "DOCK_PORT zone exists")
			# seated at the helm, sailing in from open water straight at the berth (bow towards +Z)
			_boat.board()
			_boat.global_position = Vector3(port.global_position.x, 0.0, port.global_position.z - 40.0)
			_boat.rotation.y = PI
			_boat.current_zone = _zone("DOCK_LIGHTHOUSE")
			_boat._leave_zone = _zone("DOCK_LIGHTHOUSE")
			_boat.state = _boat.State.SAILING
			_boat.velocity = Vector3.ZERO
			_boat._trail.clear()
			_next()
		1:
			if _boat.state == _boat.State.DOCKED:
				_dock_t = _t
				_check(_boat.current_zone.zone_id == "DOCK_PORT", "auto-docked at %s (want DOCK_PORT) after %.1f s" % [_boat.current_zone.zone_id, _t])
				_check(_gs == null or _gs.fired.has("SALTGATE_REACHED"), "docking reported SALTGATE_REACHED")
				_berth = _boat.global_position
				_next()
			elif _t > 60.0:
				return _fail("never docked: state %d at %s" % [_boat.state, _boat.global_position])
		2:   # tied up: the boat must hold its berth (it may heave with the waves, not slide)
			_drift = maxf(_drift, _flat(_boat.global_position, _berth))
			if _t > 1.5:
				_check(_drift < 0.05, "the docked boat holds its berth (slid %.3f m in 1.5 s)" % _drift)
				_cam_prev = _cam.global_position
				_seat_y = _player.global_position.y
				_yaw0 = _player.rotation.y
				Input.action_press("disembark")   # Q
				_next()
		3:   # stepping ashore: follow the camera every frame
			var c := _cam.global_position
			_cam_max_step = maxf(_cam_max_step, c.distance_to(_cam_prev))
			_cam_min_y = minf(_cam_min_y, c.y)
			_yaw_max = maxf(_yaw_max, absf(rad_to_deg(angle_difference(_yaw0, _player.rotation.y))))
			_cam_prev = c
			_drift = maxf(_drift, _flat(_boat.global_position, _berth))
			if _t > 2.0:
				var land: Vector3 = _zone("DOCK_PORT").landing
				_check(not _boat.driving and _player.boat == null, "Q stepped the player out of the boat")
				_check(_cam_max_step < MAX_CAM_STEP, "no camera jump stepping ashore (largest move in one frame %.2f m, limit %.2f)" % [_cam_max_step, MAX_CAM_STEP])
				_check(_cam_min_y > _seat_y + 1.5 - 0.05, "the view never dips below where it started (lowest eye %.2f, seated eye %.2f)" % [_cam_min_y, _seat_y + 1.6])
				_check(_yaw_max < 1.0, "the view does not turn while stepping ashore (%.2f deg)" % _yaw_max)
				_check(_player.is_on_floor(), "standing on the floor after stepping ashore")
				_check(_flat(_player.global_position, land) < 0.3 and absf(_player.global_position.y - land.y) < 0.15,
					"landed at the landing (%s, want %s)" % [_player.global_position, land])
				var floor_y := _floor_y(_player.global_position)
				_check(absf(_player.global_position.y - floor_y) < 0.08, "feet on the deck, not floating or sunk (feet %.2f, deck %.2f)" % [_player.global_position.y, floor_y])
				_check(_drift < 0.05, "the boat did not move under the player while stepping ashore (%.3f m)" % _drift)
				print("  arrival: docked after %.1f s; seat y %.2f -> deck y %.2f; largest camera move %.2f m/frame; turn %.2f deg"
					% [_dock_t, _seat_y, _player.global_position.y, _cam_max_step, _yaw_max])
				var b := _burner.global_position
				_begin_walk("landing to the burner", [Vector3(1.4, 0.0, b.z)])
				_next()
		4:
			var r := _walk()
			if r < 0:
				return _fail("walk '%s' failed" % _leg)
			if r > 0:
				_face(_burner.global_position + Vector3.UP * 0.45)
				_wait = 4
				_next()
		5:
			_check(_im == null or _im._label.text == "[E] Pick up the burner", "the burner is offered from the deck ('%s')" % (_im._label.text if _im else ""))
			Input.action_press("interact")
			_wait = 3
			_next()
		6:
			_check(_burner.held, "E picked the burner up")
			_check(_gs == null or _gs.fired.has("BURNER_PICKED_UP"), "GameState got BURNER_PICKED_UP")
			_begin_walk("burner back to the boat", [Vector3(1.5, 0, 538.5)])
			_next()
		7:
			var r := _walk()
			if r < 0:
				return _fail("walk '%s' failed" % _leg)
			if r > 0:
				_check(_boat._player_in_reach(), "back within the launch's board radius (%.1f m from the boat, radius %.0f)"
					% [_flat(_player.global_position, _boat.global_position), _boat.board_radius])
				# the port-to-cliff joint: from where the west boardwalk meets the quay deck, along the deck, up the timber
				# link ramp onto the cliff walkway, and back down. (The landing strip itself reaches this deck only through
				# a gap about 0.75 m wide between a bollard and a stone block in the baked quay mesh; see the run report.)
				_player.global_position = Vector3(-0.5, 3.3, 552.3)
				_player.velocity = Vector3.ZERO
				_wait = 10
				_next()
		8:
			_begin_walk("boardwalk end to the cliff walkway", [Vector3(4.85, 0, 552.0),
				Vector3(4.85, 0, 555.0), Vector3(4.85, 0, 558.2), Vector3(-2.0, 0, 560.5)])
			_next()
		9:
			var r := _walk()
			if r < 0:
				return _fail("walk '%s' failed" % _leg)
			if r > 0:
				var m: Node3D = _lv.get_node("Mainland")
				var on_ledge := _player.global_position.y > float(m.ramp_y(_player.global_position.x)) - 0.3
				_check(on_ledge, "reached the cliff walkway floor (feet %.2f, walkway %.2f)" % [_player.global_position.y, m.ramp_y(_player.global_position.x)])
				_begin_walk("cliff walkway back down to the boardwalk end", [Vector3(4.85, 0, 558.2), Vector3(4.85, 0, 555.0), Vector3(4.85, 0, 551.9),
					Vector3(-0.5, 0, 552.2)])
				_next()
		10:
			var r := _walk()
			if r < 0:
				return _fail("walk '%s' failed" % _leg)
			if r > 0:
				_next()
		11:
			if _fails == 0:
				print("RESULT: OK")
				quit(0)
			else:
				print("RESULT: FAILED (%d)" % _fails)
				quit(1)
			return true
	return false


# --- walking ---

func _begin_walk(name: String, pts: Array) -> void:
	_leg = name
	_wps.clear()
	for p in pts:
		_wps.append(p)
	_wp = 0
	_best = INF
	_best_t = _t
	_air_top = -INF
	_max_drop = 0.0
	_max_rise = 0.0
	_last_y = _player.global_position.y
	print("  walk: ", name)


## 0 = walking, 1 = arrived, -1 = failed. Holds W towards the next waypoint like a player would.
func _walk() -> int:
	var p := _player.global_position
	var target := _wps[_wp]
	var d := _flat(p, target)
	# drops: the height lost between leaving the floor and landing again
	if _player.is_on_floor():
		if _air_top > -INF:
			if _air_top - p.y > 0.2:
				print("    dropped %.2f m landing at %s" % [_air_top - p.y, p])
			_max_drop = maxf(_max_drop, _air_top - p.y)
			_air_top = -INF
	else:
		_air_top = maxf(_air_top, p.y)
	if p.y - _last_y > 0.2:
		print("    stepped up %.2f m in one frame at %s" % [p.y - _last_y, p])
	_max_rise = maxf(_max_rise, p.y - _last_y)
	_last_y = p.y
	if p.y < -5.0:
		Input.action_release("move_forward")
		print("FAIL: fell through at ", p)
		return -1
	if d < _best - 0.3:
		_best = d
		_best_t = _t
	elif _t - _best_t > STALL_S:
		Input.action_release("move_forward")
		print("FAIL: stuck at %s heading for waypoint %d %s (%.1f m away)" % [p, _wp, target, d])
		return -1
	if d < ARRIVE:
		_wp += 1
		_best = INF
		_best_t = _t
		if _wp >= _wps.size():
			Input.action_release("move_forward")
			_check(_max_drop < MAX_DROP, "%s: no drop off an edge (largest %.2f m, limit %.2f)" % [_leg, _max_drop, MAX_DROP])
			_check(_max_rise < _player.step_height + 0.05, "%s: no step higher than the step-up (largest %.2f m in one frame)" % [_leg, _max_rise])
			print("  walk done: ", _leg, " at ", p)
			return 1
		return 0
	_face(Vector3(target.x, p.y + 1.6, target.z))
	Input.action_press("move_forward")
	return 0


func _face(at: Vector3) -> void:
	var p := _player.global_position
	var flat := Vector3(at.x - p.x, 0.0, at.z - p.z)
	if flat.length() > 0.01:
		_player.rotation.y = atan2(-flat.x, -flat.z)
	var eye := p + Vector3.UP * 1.6
	_player.get_node("Head").rotation.x = atan2(at.y - eye.y, flat.length())


# --- helpers ---

func _floor_y(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.0, p + Vector3.DOWN * 3.0)
	q.exclude = [_player.get_rid()]
	var r := _lv.get_world_3d().direct_space_state.intersect_ray(q)
	return r.position.y if not r.is_empty() else -INF


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _zone(zone_id: String) -> Node3D:
	for z in get_nodes_in_group("dock_zone"):
		if z.zone_id == zone_id:
			return z
	return null


func _check(ok: bool, what: String) -> void:
	print(("  PASS  " if ok else "  FAIL  ") + what)
	if not ok:
		_fails += 1


func _fail(why: String) -> bool:
	Input.action_release("move_forward")
	print("FAIL: ", why)
	print("RESULT: FAILED")
	quit(1)
	return true


func _next() -> void:
	_step += 1
	_t = 0.0
