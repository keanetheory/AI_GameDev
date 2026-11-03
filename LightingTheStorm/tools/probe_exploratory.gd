# probe_exploratory.gd - QA-04 (Playtest QA), observe only: off-the-golden-path runs through the real level and GameState.
#   Godot --headless --path . --script res://tools/probe_exploratory.gd -- <mode> [fail]
# It drives test_slice_playthrough.gd (unchanged) and, at a hook, does what an awkward player would, then reports what the
# game did in lines starting "QA4". It never edits a game file. Modes:
#   restart=<EVENT>   restart (what F9 does in a debug build) 1 s after <EVENT>; restart=WIN_TEXT after the win text. Then
#                     checks the new attempt is clean and that the knock still starts the game.
#   gate_close        shut the gate 1.5 s after it is opened, while the sailors walk through it.
#   pause_beats       pause the tree for 1 s (game) on every story event; nothing may start, fire or move while paused.
#   win_outside       after the fit, go outside to "watch the ship" (the last goal); when do Ted's lines play?
#   poster_early      read the hall poster before the diagnosis, and again after it.
#   leave_midline     step outside for 2 s each time one of Ted's lines starts (the first four), then come back.
#   fail_inside       (with fail) step off the boat into the hall just after SHIP_FAIL: Ted's fail lines against the screen.
#   fall_jetty        fall into the sea at the lighthouse berth and at the Saltgate berth, then try to walk out.
#   boat_beach        just after casting off, aim the boat at the island and let it run; then steer away.
extends "res://tools/test_slice_playthrough.gd"

var _mode := ""
var _arg := ""
var _jobs: Array = []        # [due_t, Callable]
var _hijack := false
var _wired := false
var _lines_started: Array = []   # [t, id]
var _events: Array = []          # [t, id]
var _viol := 0
var _done := false
var _win_text_seen := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a != "fail":
			var kv := a.split("=")
			_mode = kv[0]
			_arg = kv[1] if kv.size() > 1 else ""
	super._initialize()


func _q(msg: String) -> void:
	print("QA4,%s,%.2f,%s" % [_mode + ("=" + _arg if _arg != "" else ""), _t, msg])


func _after(dt: float, c: Callable) -> void:
	_jobs.append([_t + dt, c])


## While hijacked the playthrough's own waits never return, so it cannot undo what this probe does.
func _until(cond: Callable, timeout_s: float, what: String) -> bool:
	while _hijack:
		await process_frame
	var r: bool = await super._until(cond, timeout_s, what)
	while _hijack:      # the hook fired while this wait was finishing: hold the playthrough here too
		await process_frame
	return r


func _until_time(seconds: float) -> void:
	while _hijack:
		await process_frame
	await super._until_time(seconds)


func _process(delta: float) -> bool:
	if not _wired and root.has_node("GameState"):
		_wire()
	var due := []
	for j in _jobs:
		if _t >= j[0]:
			due.append(j)
	for j in due:
		_jobs.erase(j)
		(j[1] as Callable).call()
	if _mode == "restart" and _arg == "WIN_TEXT" and not _hijack and not _win_text_seen and _gs != null:
		var scr: Node = _gs.outcome_screen()
		if scr != null and is_instance_valid(scr) and scr.showing:
			_win_text_seen = true
			_after(1.0, _do_restart)
	if _mode == "fall_jetty":
		_t += minf(delta, 0.5)
		if not _started and _t > 2.0:
			_started = true
			_fall_jetty()
		return false
	return super._process(delta)


func _wire() -> void:
	_wired = true
	var gs := root.get_node("GameState")
	var dlg := root.get_node("Dialogue")
	gs.event_emitted.connect(_on_event)
	dlg.line_started.connect(func(id: String, spk: String, _s: String, _d: String) -> void:
		_lines_started.append([_t, id])
		if root.get_tree().paused:
			_viol += 1
			_q("VIOLATION line %s started while the game was paused" % id)
		if _mode == "win_outside" or _mode == "fail_inside" or _mode == "poster_early":
			_q("line started %s (%s), player inside=%s" % [id, spk, gs.player_inside_building()])
		if _mode == "leave_midline" and spk == "TED" and _leave_count < 4 and not _hijack:
			_leave(id))


var _leave_count := 0


func _leave(id: String) -> void:
	_leave_count += 1
	var player: Node3D = _lv.get_node("Player")
	if player.get("boat") != null:
		return
	var back := player.global_position
	player.global_position = _outside_spot()
	_q("Ted started %s: the player steps outside" % id)
	_after(2.0, func() -> void:
		if is_instance_valid(player):
			player.global_position = back
			_q("back inside after %s" % id))


func _outside_spot() -> Vector3:
	var door: Node3D = _lv.get_node("LighthouseDoor")
	var z_in: Node3D = _zone("LIGHTHOUSE_ENTERED")
	var out_dir := Vector3(door.global_position.x - z_in.global_position.x, 0, door.global_position.z - z_in.global_position.z).normalized()
	return door.global_position + out_dir * 3.0 + Vector3(0, 0.2, 0)


func _on_event(id: String, _p: int) -> void:
	_events.append([_t, id])
	var gs := root.get_node("GameState")
	if root.get_tree().paused:
		_viol += 1
		_q("VIOLATION event %s fired while the game was paused" % id)
	match _mode:
		"restart":
			if id == _arg and not _hijack:
				_after(1.0, _do_restart)
		"gate_close":
			if id == "GATE_OPENED":
				_after(1.5, _close_gate)
			if id == "SAILORS_INSIDE":
				var gate: Node = get_first_node_in_group("gate")
				_q("SAILORS_INSIDE fired (gate open=%s)" % gate.is_open)
		"pause_beats":
			_after(0.0, _pause_once.bind(id))
		"win_outside":
			if id == "BURNER_FITTED":
				_after(0.5, func() -> void:
					var player: Node3D = _lv.get_node("Player")
					player.global_position = _outside_spot()
					_q("after the fit the player goes outside to watch the ship (inside=%s)" % gs.player_inside_building())
					var stand_a: Variant = _lv.get_node("InteriorRooms").anchors["lamp_stand"]
					var sy: float = (stand_a if stand_a is Vector3 else (stand_a as Node3D).global_position).y
					for rr in [2.5, 3.0, 3.3, 3.6, 4.0, 4.5]:
						_q("  a spot %.1f m from the tower axis at lamp-room height counts as inside: %s" % [rr, gs.inside_building(Vector3(8.5 + rr, sy + 0.5, -4.9))]))
			if id == "SHIP_WIN":
				_q("SHIP_WIN; Ted lines held: %s" % [_held_ids()])
		"poster_early":
			if id == "LIGHTHOUSE_ENTERED":
				_after(0.3, func() -> void:
					var ok: bool = gs.emit_event("POSTER_EXAMINED")
					_q("poster read before the diagnosis: POSTER_EXAMINED accepted=%s" % ok))
			if id == "BURNER_DIAGNOSED":
				_after(2.0, func() -> void:
					var ok: bool = gs.emit_event("POSTER_EXAMINED")
					_q("poster read again after BURNER_DIAGNOSED: POSTER_EXAMINED accepted=%s; TED_S0_13 played so far=%s" % [ok, root.get_node("Dialogue")._played.has("TED_S0_13")]))
		"fail_inside":
			if id == "SHIP_FAIL":
				_after(1.0, func() -> void:
					var player: Node3D = _lv.get_node("Player")
					var boat: Node3D = _lv.get_node("Boat")
					boat.driving = false
					player.stop_driving(Vector3(0.4, 10.6, -1.9))
					_q("off the boat and into the hall 1 s after SHIP_FAIL (inside=%s)" % gs.player_inside_building()))
				_watch_screen()
		"boat_beach":
			if id == "BOAT_CAST_OFF":
				_after(0.5, _beach)
		"saltgate_fall":       # step ashore at the Saltgate, walk off the quay into the sea (arg: early = before the burner)
			if id == "SALTGATE_REACHED":      # arg "burner": pick the burner up on the quay first
				_hijack = true
				_after(1.0, _saltgate_fall)
	if id == "SHIP_WIN" or id == "SHIP_FAIL":
		_q("%s at %.2f" % [id, _t])


func _held_ids() -> Array:
	return root.get_node("Dialogue")._held.map(func(h): return h["line_id"])


# --- restart ---------------------------------------------------------------------------------------------------------

func _do_restart() -> void:
	_hijack = true
	var gs := root.get_node("GameState")
	var carry := root.get_node("Carry")
	_q("restart in phase %s (holding=%s, playing=%s, queue=%d, held=%d)" % [gs.phase_name(), carry.is_holding(), root.get_node("Dialogue")._playing,
		root.get_node("Dialogue")._queue.size(), root.get_node("Dialogue")._held.size()])
	current_scene = _lv
	gs.restart()
	var n0 := _lines_started.size()
	_after(2.5, func() -> void:
		var lv2: Node = root.get_node_or_null("Level")
		var dlg := root.get_node("Dialogue")
		var problems := []
		if lv2 == null or lv2 == _lv:
			problems.append("level not reloaded")
		if gs.phase_name() != "ARRIVAL_AND_COAL":
			problems.append("phase %s" % gs.phase_name())
		var fired_now: Array = gs.fired.keys()
		if not fired_now.is_empty():
			problems.append("events already fired: %s" % [fired_now])
		if dlg._playing or not dlg._queue.is_empty() or not dlg._held.is_empty():
			problems.append("dialogue not clear (playing=%s queue=%d held=%d)" % [dlg._playing, dlg._queue.size(), dlg._held.size()])
		if _lines_started.size() > n0:
			problems.append("a line started after the restart before the knock: %s" % [_lines_started.slice(n0)])
		if carry.is_holding():
			problems.append("Carry still holding %s" % carry.held_kind)
		if root.get_tree().paused:
			problems.append("tree paused")
		if gs.deadline_progress() != -1.0:
			problems.append("deadline %.2f" % gs.deadline_progress())
		if gs.outcome != gs.Outcome.NONE:
			problems.append("outcome %d" % gs.outcome)
		var sub := root.get_node_or_null("Subtitles")
		if sub and sub.subtitle_label and sub.subtitle_label.visible and sub.subtitle_label.text != "":
			problems.append("an old subtitle is still on screen: '%s'" % sub.subtitle_label.text.left(40))
		var mx: Node = gs.get("_mixer")
		if mx != null and String(mx.get("music_track")) != "landed":
			problems.append("music %s" % mx.get("music_track"))
		if lv2:
			var door2: Node = lv2.get_node("LighthouseDoor")
			if not (door2.knock_mode and not door2.is_open):
				problems.append("door not shut and knockable")
		_q("after restart: %s" % ("clean" if problems.is_empty() else "PROBLEMS " + str(problems)))
		if lv2:
			var door2: Node = lv2.get_node("LighthouseDoor")
			door2.interact(lv2.get_node("Player"))
			_after(20.0, func() -> void:
				_q("the knock on the new attempt: GAME_STARTED=%s" % gs.fired.has("GAME_STARTED"))
				_finish()))


# --- gate --------------------------------------------------------------------------------------------------------------

func _close_gate() -> void:
	var gate: Node = get_first_node_in_group("gate")
	var seq: Node = root.get_node("GameState").sailors()
	gate.close()
	_q("gate shut while the sailors walk (stage %s; Arthur %s at %s, Daniel %s at %s)" % [seq.stage, seq.arthur.state, seq.arthur.global_position, seq.daniel.state, seq.daniel.global_position])
	for k in range(1, 10):
		_after(5.0 * k, func() -> void:
			if is_instance_valid(seq) and not root.get_node("GameState").fired.has("SAILORS_INSIDE"):
				_q("  +%d s: stage %s, Arthur %s %s, Daniel %s %s, gate open=%s" % [5 * k, seq.stage, seq.arthur.state, seq.arthur.global_position, seq.daniel.state, seq.daniel.global_position, gate.is_open]))


# --- pause ----------------------------------------------------------------------------------------------------------

func _pause_once(id: String) -> void:
	var gs := root.get_node("GameState")
	var dlg := root.get_node("Dialogue")
	var voice: AudioStreamPlayer = dlg._voice
	var prog: float = gs.deadline_progress()
	var vpos: float = voice.get_playback_position() if voice.playing else -1.0
	root.get_tree().paused = true
	_after(1.0, func() -> void:
		var prog2: float = gs.deadline_progress()
		var vpos2: float = voice.get_playback_position() if voice.playing else -1.0
		if absf(prog2 - prog) > 0.0001:
			_viol += 1
			_q("VIOLATION the deadline moved while paused after %s (%.4f -> %.4f)" % [id, prog, prog2])
		if vpos >= 0.0 and vpos2 >= 0.0 and absf(vpos2 - vpos) > 0.05:
			_viol += 1
			_q("VIOLATION the voice kept playing while paused after %s (%.2f -> %.2f)" % [id, vpos, vpos2])
		root.get_tree().paused = false)


# --- fail screen ----------------------------------------------------------------------------------------------------

func _watch_screen() -> void:
	var gs := root.get_node("GameState")
	var scr: Node = gs.outcome_screen()
	var dlg := root.get_node("Dialogue")
	var t0 := _t
	while is_instance_valid(scr) and not scr.showing and _t - t0 < 60.0:
		await process_frame
	_q("the Failed screen shows %.2f s after SHIP_FAIL+1; playing=%s, queue=%s, held=%s; lines started since SHIP_FAIL: %s" % [_t - t0,
		dlg._playing, dlg._queue.map(func(l): return l["line_id"]), _held_ids(), _lines_started.filter(func(r): return r[0] >= t0 - 1.0)])


# --- the sea ----------------------------------------------------------------------------------------------------------

func _fall_jetty() -> void:
	await _until_time(4.0)
	var player: CharacterBody3D = _lv.get_node("Player")
	for zid in ["DOCK_LIGHTHOUSE", "DOCK_PORT"]:
		var z := _dock(zid)
		if z == null:
			_q("no dock %s" % zid)
			continue
		var land: Vector3 = z.landing
		var water: Vector3 = z.entrance if z.entrance != Vector3.ZERO else z.global_position
		var side := (water - land)
		side.y = 0
		var drop := land + side.normalized() * 6.0
		drop.y = land.y + 0.5
		player.global_position = drop
		player.velocity = Vector3.ZERO
		await _until_time(5.0)
		var p1 := player.global_position
		_q("%s: dropped into the water at %s, landing %s; after 5 s at %s on_floor=%s" % [zid, drop, land, p1, player.is_on_floor()])
		# walk back towards the landing for 20 s, jumping now and then
		var to := land - player.global_position
		player.rotation.y = atan2(-to.x, -to.z)
		Input.action_press("move_forward")
		var t0 := _t
		var best := INF
		while _t - t0 < 20.0:
			var d := Vector2(player.global_position.x - land.x, player.global_position.z - land.z).length()
			best = minf(best, d)
			if fmod(_t - t0, 1.5) < 0.05:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
			var to2 := land - player.global_position
			player.rotation.y = atan2(-to2.x, -to2.z)
			await process_frame
		Input.action_release("move_forward")
		Input.action_release("jump")
		var p2 := player.global_position
		_q("%s: after 20 s walking at the landing: at %s (closest %.1f m, landing y %.2f), %s" % [zid, p2, best,
			land.y, "OUT" if best < 2.0 and p2.y > land.y - 0.6 else "STILL IN THE WATER / STUCK"])
	_finish()


func _beach() -> void:
	_hijack = true
	var boat: Node3D = _lv.get_node("Boat")
	var cross: Node = root.get_node("GameState").crossing()
	var target := Vector3(8.5, 0, -4.9)            # the lighthouse: straight at the island
	var to := target - boat.global_position
	boat.rotation.y = atan2(-to.x, -to.z)
	_q("aimed at the island from %s, state %s" % [boat.global_position, boat.state])
	var hits0: int = cross.get("outbound_hits") if cross and cross.get("outbound_hits") != null else -1
	var last := boat.global_position
	var moved := 0.0
	for k in 10:
		await super._until_time(2.0)
		moved += boat.global_position.distance_to(last)
		last = boat.global_position
		_q("  +%d s: boat %s state %s rudder %.2f, collisions so far %s" % [2 * (k + 1), boat.global_position, boat.state, boat.rudder, cross.get("hazard_hits") if cross else "?"])
	Input.action_press("move_left")
	await super._until_time(6.0)
	Input.action_release("move_left")
	var p_turn := boat.global_position
	await super._until_time(8.0)
	_q("steered left 6 s then straight 8 s: boat %s -> %s (%.1f m), state %s" % [p_turn, boat.global_position, p_turn.distance_to(boat.global_position), boat.state])
	_finish()


func _saltgate_fall() -> void:
	var gs := root.get_node("GameState")
	var player: CharacterBody3D = _lv.get_node("Player")
	var boat: Node3D = _lv.get_node("Boat")
	var carry := root.get_node("Carry")
	var z := _dock("DOCK_PORT")
	if boat.driving:
		boat.disembark()
	await super._until_time(1.5)
	player.global_position = z.landing + Vector3(0, 0.3, 0)
	player.velocity = Vector3.ZERO
	await super._until_time(1.0)
	if _arg == "burner":
		_lv.get_node("BurnerPickup").pick_up()
		await super._until_time(0.5)
	var spawn: Vector3 = player.get("_spawn")
	_q("ashore at the Saltgate landing %s (on_floor=%s, holding=%s, boat state %s at %s); the player's spawn is %s" % [player.global_position,
		player.is_on_floor(), carry.is_holding(), boat.state, boat.global_position, spawn])
	# walk straight out over the berth (towards the boat) and on, as a player who misses the boat would
	var to := boat.global_position - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	Engine.time_scale = 1.0      # real speed from here, so each frame is one or two physics steps
	Input.action_press("move_forward")
	var lowest := player.global_position.y
	var next_log := 0.0
	var t0 := _t
	var jumped_home := false
	var prev := player.global_position
	while _t - t0 < 12.0:
		lowest = minf(lowest, player.global_position.y)
		if player.global_position.distance_to(prev) > 50.0:
			jumped_home = true
			_q("  the player jumped %.0f m in one frame, from %s to %s (lowest y %.1f): the fell-out-of-the-world respawn" % [player.global_position.distance_to(prev), prev, player.global_position, lowest])
			break
		prev = player.global_position
		if _t >= next_log:
			next_log = _t + 0.5
			_q("    walking: %s on_floor=%s" % [player.global_position, player.is_on_floor()])
		await process_frame
	Input.action_release("move_forward")
	await super._until_time(1.0)
	var p := player.global_position
	_q("after walking off the quay: at %s, lowest y %.1f, %s; boat still at %s; holding=%s" % [p, lowest,
		"RESPAWNED AT THE START SPAWN ON THE LIGHTHOUSE ISLAND, %.0f m from the boat" % Vector2(p.x - boat.global_position.x, p.z - boat.global_position.z).length() if jumped_home or p.distance_to(spawn) < 3.0 else ("in the sea / on a floor (on_floor=%s)" % player.is_on_floor()),
		boat.global_position, carry.is_holding()])
	if carry.is_holding():
		# with the burner in hand on the island: can the lamp be reached and the burner fitted without the return crossing?
		var rooms: Node = _lv.get_node("InteriorRooms")
		var stand_a: Variant = rooms.anchors["lamp_stand"]
		var stand: Vector3 = stand_a if stand_a is Vector3 else (stand_a as Node3D).global_position
		player.global_position = stand + Vector3(0, 0.1, 0)
		await super._until_time(1.0)
		var socket: Node = rooms.refs["lamp_socket"]
		socket.interact(player)
		await super._until_time(6.0)
		_q("  carried to the lamp without sailing back: LAMP_ROOM_REENTERED=%s BURNER_FITTED=%s RETURN_DEPARTED=%s SHIP_WIN=%s phase %s, deadline %.2f" % [
			gs.fired.has("LAMP_ROOM_REENTERED"), gs.fired.has("BURNER_FITTED"), gs.fired.has("RETURN_DEPARTED"), gs.fired.has("SHIP_WIN"), gs.phase_name(), gs.deadline_progress()])
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	_q("SUMMARY violations=%d events=%d lines=%d held_at_end=%s" % [_viol, _events.size(), _lines_started.size(), _held_ids()])
	quit(0)


func _finalize() -> void:
	if not _done:
		_done = true
		_q("SUMMARY violations=%d events=%d lines=%d held_at_end=%s (the playthrough ran to its end)" % [_viol, _events.size(), _lines_started.size(), _held_ids() if root.has_node("Dialogue") else []])
