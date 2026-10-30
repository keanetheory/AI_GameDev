# test_lamp_fit.gd - run: Godot --headless --path . --script res://tools/test_lamp_fit.gd
# The end of the crossing / retrieval / repair loop (backlog T32), through the real E key, in the lamp room:
#   1. the lamp is dark and the socket is empty at the start (the broken burner is on the floor, not in the lamp);
#   2. standing at the lamp with EMPTY hands, nothing is offered (there is nothing to fit);
#   3. holding the burner, facing the lamp, the prompt reads "[E] Fit the burner into the lamp";
#   4. E fits it: the burner is in the socket, the hands are empty, BURNER_FITTED fired once and GameState moved to
#      FINAL_REPAIR; nothing is offered afterwards (it cannot be taken back out);
#   5. the lamp comes up: lit, the lens glows, the beam and lights are on and the beam sweeps.
# Exits 0 when every check passes, 1 otherwise.
extends SceneTree

var _lv: Node
var _player: CharacterBody3D
var _burner: Node3D
var _gs: Node
var _carry: Node
var _im: Node
var _rooms: Node
var _socket: Node3D
var _beacon: Node3D
var _f := 0
var _step := 0
var _wait := 0
var _failed := 0
var _yaw0 := 0.0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_player = _lv.get_node("Player")
	_burner = _lv.get_node("BurnerPickup")
	_gs = root.get_node_or_null("GameState")
	_carry = root.get_node_or_null("Carry")
	_im = root.get_node_or_null("Interaction")
	_rooms = _lv.get_node_or_null("InteriorRooms")
	Engine.max_physics_steps_per_frame = 20


func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	Input.action_release("interact")
	match _step:
		0:
			_socket = _rooms.refs.get("lamp_socket") if _rooms else null
			_beacon = _rooms.refs.get("lamp_beacon") if _rooms else null
			_check(_socket != null and _beacon != null, "the lamp room has a burner socket and a beacon")
			if _socket == null:
				quit(1)
				return false
			_check(_socket.item == null, "the socket is empty at the start")
			_check(not _beacon.lit and _beacon.level == 0.0, "the lamp is dark at the start")
			_check(_beacon.get_node_or_null("LampModel") != null and _beacon._lens_mats.size() > 0, "the generated lamp model is in place (%d materials)" % _beacon._lens_mats.size())
			_check(not _beacon._lens_mats[0].emission_enabled and _beacon._lens_mats[0].albedo_color.v < 0.5 * _beacon._lens_mats[0].get_meta("base_albedo").v + 0.01, "the lamp is dark and cold at the start")
			_check(not _beacon.get_node("Glow").visible and not _beacon.get_node("BeamPivot").visible, "no lamp light or beam at the start")
			var closed_m := _beacon.get_node("LampModel") as Node3D
			var open_m := _beacon.get_node_or_null("LampModelOpen") as Node3D
			_check(open_m != null and closed_m.visible and not open_m.visible, "the closed lamp shows before the diagnosis; the open one is hidden")
			_beacon._on_event("BURNER_DIAGNOSED", 0)
			_check(open_m.visible and not closed_m.visible, "from the diagnosis the open lamp shows, its bay empty")
			_check(_lv.find_child("BrokenBurner", true, false) != null, "the broken burner is lying in the lamp room")
			_check(_lv.find_child("BrokenBurner", true, false).get_parent() != _socket, "the broken burner is not in the lamp's socket")
			# stand on the lamp-room floor 1.7 m from the lamp axis, empty-handed, looking at the socket
			var stand: Vector3 = (_lv.get_node("InteriorAnchors").anchors["lamp_stand"] as Node3D).global_position
			_stand_at(stand + Vector3(0, 0.05, 0), _socket.global_position)
			_next(8)
		1:
			_check(not _carry.is_holding(), "the hands are empty")
			_check(_im.focus != _socket, "empty-handed, the lamp socket is not offered (focus: %s)" % str(_im.focus))
			_burner.pick_up()
			_next(6)
		2:
			_check(_carry.is_holding() and _carry.held_kind == "burner", "the player is holding the burner")
			_check(_im.focus == _socket, "holding the burner at the lamp, the socket is offered (focus: %s)" % str(_im.focus))
			_check(_im._label.text == "[E] Fit the burner into the lamp", "prompt reads '%s'" % _im._label.text)
			Input.action_press("interact")
			_next(4)
		3:
			_check(_socket.item != null and _socket.item.get_parent() == _socket, "E put the burner in the socket")
			_check(not _carry.is_holding(), "the hands are empty again")
			_check(_gs.fired.has("BURNER_FITTED"), "BURNER_FITTED was reported")
			_check(_gs.burner_fitted, "GameState has burner_fitted")
			_check(_gs.phase_name() == "FINAL_REPAIR", "the phase is FINAL_REPAIR (%s)" % _gs.phase_name())
			_check(_beacon.lit, "the lamp is lit")
			_check(_beacon.get_node("LampModelOpen").visible, "the bay is still open as the burner is seated")
			_yaw0 = _beacon.get_node("BeamPivot").rotation.y
			_next(8)
		4:
			_check(_im.focus != _socket, "the fitted burner cannot be taken back out (focus: %s)" % str(_im.focus))
			_next(120)   # about 2 s at 60 physics frames a second
		5:
			_check(_beacon.get_node("LampModel").visible and not _beacon.get_node("LampModelOpen").visible, "the bay has closed again and the closed lamp shows")
			_check(_beacon.level > 0.3, "the lamp is coming up (%.2f)" % _beacon.level)
			_check(_beacon.get_node("Glow").light_energy > 0.0 and _beacon.get_node("Glow").visible, "the lamp's light is on")
			_check(_beacon.get_node("BeamPivot").visible and absf(_beacon.get_node("BeamPivot").rotation.y - _yaw0) > 0.01, "the beam is on and sweeping")

			_check(_beacon._lens_mats[0].emission_enabled and _beacon._lens_mats[0].emission_energy_multiplier > 0.05, "the lamp glows")   # mid-rise; the lens energy is 0.22 at full (it was 0.3, which blew the lens out to white)
			_next(260)
		6:
			_check(_beacon.level >= 0.999, "the lamp reached full (%.2f)" % _beacon.level)
			var fired := 0
			for e in _gs.event_log:
				if e["id"] == "BURNER_FITTED":
					fired += 1
			_check(fired == 1, "BURNER_FITTED was logged once (%d)" % fired)
			_check(_gs.fired.has("SHIP_WIN"), "SHIP_WIN was reported once the lamp was burning")
			_check(_gs.outcome == _gs.Outcome.WIN and _gs.phase_name() == "RESOLUTION", "the outcome is WIN and the phase RESOLUTION (%s)" % _gs.phase_name())
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	if _f > 3000:
		print("FAIL: TIMEOUT in step ", _step)
		quit(1)
	return false


func _stand_at(at: Vector3, look_at_point: Vector3) -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = at
	var flat := Vector3(look_at_point.x, at.y, look_at_point.z)
	if flat.distance_to(at) > 0.01:
		_player.look_at(flat, Vector3.UP)
	var eye := at + Vector3.UP * 1.6
	var d := Vector2(look_at_point.x - eye.x, look_at_point.z - eye.z).length()
	_player.get_node("Head").rotation.x = atan2(look_at_point.y - eye.y, maxf(d, 0.01))


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1
