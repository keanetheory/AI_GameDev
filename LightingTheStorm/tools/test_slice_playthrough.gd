# test_slice_playthrough.gd - run: Godot --headless --path . --script res://tools/test_slice_playthrough.gd [-- fail]
# T20: the whole Gate 1 slice, start to finish, in the real level at 8x speed through the real GameState and every director
# (intro, sailors, diagnosis, boarding, crossing, deadline, audio, outcome screen). A scripted player does what a person would:
# knocks, steps in, feeds the boiler, opens the gate, climbs to the lamp room, boards, sails (the boat is put on its route and the
# real auto-docking does the docking), picks up the burner, sails home along the forecast's safe lane, carries the burner to the
# lamp and fits it. It checks the phase machine, every event once and in the story's order, the dialogue that should have played,
# the ship and the deadline, and the ending.
#   (default)  the win: burner fitted in time, SHIP_WIN, the win card.
#   -- fail    the deadline runs out on the return crossing: SHIP_FAIL, the ship strikes the rock, the Failed screen, then Enter
#              restarts the slice and the new attempt starts clean.
# The scenario list is LightingTheStorm/QA_SCENARIOS.md.
extends SceneTree

const SPEED := 8.0

var _lv: Node
var _gs: Node
var _t := 0.0
var _fails := 0
var _started := false
var _phases: Array = []
var _fail_mode := false


func _initialize() -> void:
	_fail_mode = OS.get_cmdline_user_args().has("fail")
	Engine.time_scale = SPEED
	Engine.max_physics_steps_per_frame = 200
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(delta: float) -> bool:
	_t += minf(delta, 0.5)      # a slow frame (the level building at the start) must not use up a wait
	if not _started and _t > 1.0:
		_started = true
		_run()
	return false


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


## Wait (in game time) until cond is true; a timeout is a failure, reported with `what`.
func _until(cond: Callable, timeout_s: float, what: String) -> bool:
	var t0 := _t
	while _t - t0 < timeout_s:
		if cond.call():
			return true
		await process_frame
	_check(false, "timed out after %.0f s waiting for %s" % [timeout_s, what])
	return false


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _fired(id: String) -> bool:
	return _gs.fired.has(id)


func _zone(event: String) -> Node3D:
	for z in get_nodes_in_group("lhi_zone"):
		if z.event_id == event:
			return z
	return null


func _dock(zone_id: String) -> Node3D:
	for z in get_nodes_in_group("dock_zone"):
		if z.zone_id == zone_id:
			return z
	return null


func _order(ids: Array) -> bool:
	var last := -1
	for id in ids:
		var at := -1
		for i in _gs.event_log.size():
			if _gs.event_log[i]["id"] == id and _gs.event_log[i]["note"] == "":
				at = i
		if at <= last:
			print("     out of order or missing: %s" % id)
			return false
		last = at
	return true


func _played_trigger(dlg: Node, trig: String) -> bool:
	for l in dlg.data["lines"]:
		if l["trigger"] == trig and dlg._played.has(l["line_id"]):
			return true
	return false


# ---------------------------------------------------------------------------------------------------------------------

func _run() -> void:
	_gs = root.get_node("GameState")
	_gs.debug_log = false
	_gs.phase_changed.connect(func(_o: int, n: int) -> void: _phases.append(_gs.phase_name(n)))
	var player: CharacterBody3D = _lv.get_node("Player")
	var door: Node3D = _lv.get_node("LighthouseDoor")
	var boat: Node3D = _lv.get_node("Boat")
	var rooms: Node = _lv.get_node("InteriorRooms")
	var dlg: Node = root.get_node("Dialogue")
	print("--- scenario: %s ---" % ("FAIL on the return crossing, then restart" if _fail_mode else "WIN (golden path)"))

	# 1. the opening
	_check(_gs.phase_name() == "ARRIVAL_AND_COAL" and not _fired("GAME_STARTED"), "the game waits at the door: nothing has started")
	_check(door.knock_mode and not door.is_open, "the front door is shut and offers to be knocked")
	door.interact(player)
	await _until(func() -> bool: return _fired("GAME_STARTED"), 20.0, "GAME_STARTED after the knock")
	_check(door.is_open, "Ted opened the door before he greeted the player")
	_check(_gs.deadline_progress() == -1.0 and not _gs.deadline().ship.visible, "no ship and no deadline yet")

	# 2. in, to the basement, the coal
	var z1 := _zone("LIGHTHOUSE_ENTERED")
	player.global_position = z1.global_position - Vector3(0, 1.0, 0)
	await _frames(4)
	await _until(func() -> bool: return _fired("LIGHTHOUSE_ENTERED"), 5.0, "LIGHTHOUSE_ENTERED")
	_check(_gs.intro().ted.state == _gs.intro().ted.State.WALKING, "Ted walks up to the lamp room as he sends the player to the coal")
	var z2 := _zone("ENGINE_ROOM_ENTERED")
	player.global_position = z2.global_position - Vector3(0, 0.9, 0)
	await _frames(4)
	await _until(func() -> bool: return _fired("ENGINE_ROOM_ENTERED"), 5.0, "ENGINE_ROOM_ENTERED")
	var job: Node = rooms.refs["coal_job"]
	var hatch: Node = rooms.refs["firebox_hatch"]
	var carry: Node = root.get_node("Carry")
	for i in job.loads_needed:
		_check(job.take_shovelful(), "shovelful %d taken from the heap" % (i + 1))
		await _frames(2)
		hatch.interact(player)
		await _frames(2)
	await _until(func() -> bool: return _fired("BOILER_FED"), 5.0, "BOILER_FED")
	_check(_gs.phase_name() == "SHELTER_AND_GATE" and _fired("COAL_LOADED_FIRST") and _fired("COAL_LOADED_HALF"), "the boiler is fed: phase SHELTER_AND_GATE, first and half loads reported")
	_check(_gs.deadline().ship.visible, "the unplanned ship is on the horizon once the boiler is fed")

	# 3. the sailors and the gate
	await _until(func() -> bool: return _fired("SAILORS_MOORED"), 90.0, "SAILORS_MOORED (the rowboat berths)")
	var seq: Node = _gs.sailors()
	await _until(func() -> bool: return seq.stage == seq.Stage.AT_GATE and seq.arthur.state == seq.arthur.State.IDLE and seq.daniel.state == seq.daniel.State.IDLE, 120.0, "the sailors to wait at the gate")
	await _until(func() -> bool: return _fired("WINDOW_LOOKED"), 30.0, "WINDOW_LOOKED (the fallback)")
	var gate: Node = get_first_node_in_group("gate")
	player.global_position = gate.middle() + Vector3(0, 0.1, 3.0)
	await _frames(4)
	_check(_fired("GATE_APPROACHED"), "coming up to the gate: GATE_APPROACHED")
	gate.open()
	_check(_fired("GATE_OPENED"), "opening the gate: GATE_OPENED")
	await _until(func() -> bool: return _fired("SAILORS_INSIDE"), 90.0, "SAILORS_INSIDE")
	await _until(func() -> bool: return _fired("DANIEL_IN_BASEMENT"), 120.0, "DANIEL_IN_BASEMENT")
	_check(_gs.phase_name() == "BEACON_DIAGNOSIS", "both sailors in: phase BEACON_DIAGNOSIS")
	_check(dlg._played.has("ARTHUR_S2_06") and not dlg._played.has("DANIEL_OPT_02"), "Arthur said he would wait; Daniel has not spoken (the player is not in the basement)")

	# 4. the diagnosis and the briefing
	await _until(func() -> bool: return _fired("BEACON_STILL_DARK"), 30.0, "BEACON_STILL_DARK")
	var stand: Vector3 = (rooms.anchors["lamp_stand"] as Vector3) if rooms.anchors["lamp_stand"] is Vector3 else (rooms.anchors["lamp_stand"] as Node3D).global_position
	player.global_position = stand + Vector3(0, 0.1, 0)
	await _frames(4)
	await _until(func() -> bool: return _fired("LAMP_ROOM_ENTERED"), 5.0, "LAMP_ROOM_ENTERED")
	await _until(func() -> bool: return _fired("BURNER_DIAGNOSED"), 30.0, "BURNER_DIAGNOSED")
	var dg: Node = _gs.diagnosis()
	player.global_position = dg._hall_spot + Vector3(0.8, 0.05, 0.6)
	await _frames(4)
	await _until(func() -> bool: return _fired("BURNER_BRIEFING"), 10.0, "BURNER_BRIEFING")
	_check(_gs.phase_name() == "BOARDING", "briefed: phase BOARDING")

	# 5. Arthur boards; boarding; the outbound crossing
	var bs: Node = _gs.boarding()
	await _until(func() -> bool: return bs.stage == bs.Stage.ABOARD, 150.0, "Arthur to board the launch")
	player.global_position = boat.global_position + Vector3(-4.0, 1.0, 2.0)
	await _frames(4)
	await _until(func() -> bool: return _fired("BOARDING_THRESHOLD"), 10.0, "BOARDING_THRESHOLD")
	boat.board()
	boat.cast_off()
	await _until(func() -> bool: return _fired("BOAT_CAST_OFF"), 5.0, "BOAT_CAST_OFF")
	_check(_gs.phase_name() == "OUTBOUND", "cast off: phase OUTBOUND")
	await _until(func() -> bool: return _fired("SHIP_SIGHTED"), 30.0, "SHIP_SIGHTED")
	var port := _dock("DOCK_PORT")
	boat.global_position = Vector3(port.global_position.x, boat.global_position.y, port.global_position.z - 14.0)
	boat.rotation.y = PI
	boat._leave_zone = null
	boat._grace_zone = null
	await _until(func() -> bool: return _fired("SALTGATE_REACHED"), 30.0, "SALTGATE_REACHED (the launch docks itself)")
	_check(_gs.phase_name() == "SALTGATE", "at the quay: phase SALTGATE")
	_check(dlg._played.has("ARTHUR_DOCK_01"), "Arthur: 'Hands off now ...' as the launch auto-docks")

	# 6. the burner and the return
	var pickup: Node = _lv.get_node("BurnerPickup")
	pickup.pick_up()
	await _frames(2)
	_check(_fired("BURNER_PICKED_UP") and carry.is_holding() and carry.held_kind == "burner", "the burner is picked up and carried")
	boat.cast_off()
	await _until(func() -> bool: return _fired("RETURN_DEPARTED"), 5.0, "RETURN_DEPARTED")
	_check(_gs.phase_name() == "RETURN" and _gs.deadline().is_running(), "burner aboard, under way: phase RETURN and the hidden clock runs")
	var cross: Node = _gs.crossing()
	if _fail_mode:
		_check(_gs.deadline().ship.mode != _gs.deadline().ship.Mode.HIDDEN, "(fail scenario) the player now simply sails on and does nothing")
		await _until(func() -> bool: return _fired("SHIP_FAIL"), 400.0, "SHIP_FAIL when the deadline runs out")
		await _fail_ending(dlg)
		return
	# sail home along the safe lane, put on the route a few metres at a time
	var lanes := []
	for s in cross.loader.data["segments"]:
		lanes.append(String(s["safe_lane"]))
	var rm := 5.0
	while rm < 595.0:
		var idx := mini(int(rm / 120.0), 4)
		var frac := (rm - idx * 120.0) / 120.0
		var p: Vector2 = cross.world_point(rm, lanes[idx])
		if frac > 0.75 and idx < 4:
			p = p.lerp(cross.world_point(rm, lanes[idx + 1]), (frac - 0.75) / 0.25)
		boat.global_position = Vector3(p.x, boat.global_position.y, p.y)
		boat.rotation.y = 0.0
		await _until_time(0.55)
		rm += 5.0
	_check(cross.return_hits == 0, "the whole crossing sailed on the safe lane without a collision")
	_check(cross.calls_made == ["ARTHUR_RET_01", "ARTHUR_RET_02", "ARTHUR_RET_03", "ARTHUR_RET_04", "ARTHUR_RET_05"], "Arthur's five calls were made, in order")
	var berth := _dock("DOCK_LIGHTHOUSE")
	var ent: Vector3 = berth.entrance if berth.entrance != Vector3.ZERO else berth.global_position + Vector3(-12, 0, 0)
	var dirv := Vector3(berth.global_position.x - ent.x, 0.0, berth.global_position.z - ent.z).normalized()
	boat.global_position = Vector3(ent.x - dirv.x * 10.0, boat.global_position.y, ent.z - dirv.z * 10.0)
	boat.rotation.y = atan2(-dirv.x, -dirv.z)
	boat._leave_zone = null
	boat._grace_zone = null
	await _until(func() -> bool: return _fired("RETURN_ARRIVED"), 40.0, "RETURN_ARRIVED (the launch docks at the lighthouse)")
	_check(_gs.phase_name() == "FINAL_REPAIR", "home: phase FINAL_REPAIR")
	_check(dlg._played.has("ARTHUR_DOCK_01") and dlg._played.has("ARTHUR_S4_01"), "'Hands off now ...' then Arthur's 'go go go'")
	var progress_home: float = _gs.deadline_progress()
	_check(progress_home > 0.0 and progress_home < 0.8, "the deadline is well short of running out (%.0f%%)" % (progress_home * 100.0))

	# 7. up to the lamp with the burner and fit it
	boat.disembark()
	player.global_position = stand + Vector3(0, 0.1, 0)
	await _frames(4)
	await _until(func() -> bool: return _fired("LAMP_ROOM_REENTERED"), 5.0, "LAMP_ROOM_REENTERED (carrying the burner)")
	var socket: Node = rooms.refs["lamp_socket"]
	socket.interact(player)
	await _until(func() -> bool: return _fired("BURNER_FITTED"), 5.0, "BURNER_FITTED")
	_check(not carry.is_holding() and socket.fitted, "the burner is in the lamp for good and the player's hands are empty")
	await _until(func() -> bool: return _fired("SHIP_WIN"), 15.0, "SHIP_WIN")
	_check(_gs.outcome == _gs.Outcome.WIN and _gs.phase_name() == "RESOLUTION", "SHIP_WIN: the outcome is WIN, phase RESOLUTION")
	var frozen: float = _gs.deadline_progress()
	await _until_time(20.0)
	_check(_gs.deadline_progress() == frozen and not _fired("SHIP_FAIL"), "the clock is frozen: the ship can no longer be lost")
	var scr: Node = _gs.outcome_screen()
	await _until(func() -> bool: return scr.showing, 200.0, "the win card")
	_check(scr.kind == "WIN" and scr._title.text == "The light holds", "the win card shows once the saved ship is past the rock")
	await _until_time(1.0)
	player.global_position = Vector3(0.4, 10.6, -1.9)       # the hall: Ted's held lines are spoken now the player is inside
	await _until_time(2.0)
	_check(_held_has(dlg, "DANIEL_OPT_02"), "Daniel's arrival line has been waiting all along for the player to come down to him")
	player.global_position = Vector3(3.6, 7.9, -4.4)        # the basement, with Daniel
	await _until_time(2.0)
	_check(dlg._played.has("DANIEL_OPT_02"), "and is spoken the moment the player is in the basement with him")

	# the checks over the whole run
	var story := ["GAME_STARTED", "LIGHTHOUSE_ENTERED", "ENGINE_ROOM_ENTERED", "COAL_LOADED_FIRST", "COAL_LOADED_HALF", "BOILER_FED", "SAILORS_MOORED", "WINDOW_LOOKED",
		"GATE_APPROACHED", "GATE_OPENED", "SAILORS_INSIDE", "DANIEL_IN_BASEMENT", "BEACON_STILL_DARK", "LAMP_ROOM_ENTERED", "BURNER_DIAGNOSED", "BURNER_BRIEFING",
		"BOARDING_THRESHOLD", "BOAT_CAST_OFF", "SALTGATE_REACHED", "BURNER_PICKED_UP", "RETURN_DEPARTED", "RETURN_ARRIVED", "LAMP_ROOM_REENTERED", "BURNER_FITTED", "SHIP_WIN"]
	_check(_order(story), "all %d story events happened, once each, in the story's order" % story.size())
	var counts := {}
	for e in _gs.event_log:
		if e["note"] == "":
			counts[e["id"]] = counts.get(e["id"], 0) + 1
	var once := true
	for id in story:
		if counts.get(id, 0) != 1:
			once = false
			print("     %s fired %d times" % [id, counts.get(id, 0)])
	_check(once, "none fired twice")
	_check(_phases == ["SHELTER_AND_GATE", "BEACON_DIAGNOSIS", "BOARDING", "OUTBOUND", "SALTGATE", "RETURN", "FINAL_REPAIR", "RESOLUTION"], "the phases went forward one at a time: %s" % [_phases])
	_check(not _fired("SHIP_FAIL"), "no failure along the way")
	var missing := []
	for trig in story + ["SHIP_SIGHTED", "ARTHUR_RET_01", "ARTHUR_RET_05", "DOCKING_DIALOGUE"]:
		if trig == "RETURN_DEPARTED":
			continue      # the crossing crew's calls take over from here; no line of its own
		if not _played_trigger(dlg, trig):
			missing.append(trig)
	_check(missing.is_empty(), "every moment had its line spoken (nothing left unspoken: %s)" % [missing])
	_check(dlg._held.is_empty(), "no line is still held (%d: %s)" % [dlg._held.size(), dlg._held.map(func(h): return h["line_id"])])
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)


func _held_has(dlg: Node, id: String) -> bool:
	for h in dlg._held:
		if h["line_id"] == id:
			return true
	return false


func _until_time(seconds: float) -> void:
	var t0 := _t
	while _t - t0 < seconds:
		await process_frame


func _fail_ending(dlg: Node) -> void:
	var ship: Node3D = _gs.deadline().ship
	_check(_gs.outcome == _gs.Outcome.FAIL and _gs.phase_name() == "RESOLUTION", "the deadline ran out: outcome FAIL, phase RESOLUTION")
	await _until(func() -> bool: return ship.mode == ship.Mode.CRASHED, 60.0, "the ship to strike the rock")
	var scr: Node = _gs.outcome_screen()
	_check(not scr.showing, "the ship has struck; the Failed screen is still waiting for the silence")
	await _until(func() -> bool: return scr.showing, 60.0, "the Failed screen")
	_check(scr.kind == "FAIL" and scr._title.text == "Failed" and scr._reason.text.length() > 10, "the Failed screen shows with its reason line")
	_check(_played_trigger(dlg, "SHIP_FAIL") or dlg._held.size() > 0, "Ted's fail lines were queued (held while the player is on the boat, spoken once inside)")
	var attempt: int = _gs.attempt
	current_scene = _lv
	scr._t_shown = 5.0
	var e := InputEventKey.new()
	e.keycode = KEY_ENTER
	e.pressed = true
	scr._unhandled_input(e)
	_check(_gs.attempt == attempt + 1 and _gs.outcome == _gs.Outcome.NONE, "Enter restarts the slice: a new attempt with the state cleared")
	await _until_time(2.0)
	var lv2: Node = root.get_node_or_null("Level")
	_check(lv2 != null and lv2 != _lv, "the level was reloaded")
	if lv2:
		var door2: Node = lv2.get_node("LighthouseDoor")
		_check(door2.knock_mode and not door2.is_open and _gs.phase_name() == "ARRIVAL_AND_COAL" and not _gs.fired.has("GAME_STARTED"), "the new attempt starts at the shut door again, nothing fired")
		_check(_gs.deadline_progress() == -1.0 and _gs.crossing() != null and _gs.crossing().return_hits == 0, "with a fresh clock and a fresh sea")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
