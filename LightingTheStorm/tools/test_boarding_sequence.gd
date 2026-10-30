# test_boarding_sequence.gd - run: Godot --headless --path . --script res://tools/test_boarding_sequence.gd
# T11: Arthur as the only crossing companion, in the real level through the real GameState and the real launch. After the briefing
# he walks from the hall to the launch's berth and sits aboard; the boat will not cast off until he is aboard; BOARDING_THRESHOLD
# fires when the player comes up to the launch with him aboard; SHIP_SIGHTED follows casting off; he rides the boat; on the return
# (RETURN_ARRIVED) he shouts "go go go", steps ashore on the jetty and stays there.
extends SceneTree

var _lv: Node
var _fails := 0
var _f := 0
var _started := false


func _initialize() -> void:
	Engine.set_meta("skip_intro", true)
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _process(_d: float) -> bool:
	_f += 1
	if _f == 60 and not _started:
		_started = true
		_run()
	return false


func _step(seq: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		seq._process(0.1)
		if seq.arthur:
			seq.arthur._process(0.1)
		t += 0.1


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var seq: Node = gs.boarding()
	var boat: Node3D = _lv.get_node("Boat")
	var player: CharacterBody3D = _lv.get_node("Player")
	var dlg: Node = root.get_node("Dialogue")
	_check(seq != null and not seq.spec.is_empty(), "GameState creates the boarding sequence when the level is ready")
	_check(boat.cast_off_hold == "" and seq.arthur == null, "before the briefing Arthur is not involved and the boat is free")
	player.global_position = Vector3(0, -500, 0)
	gs.emit_event("BURNER_BRIEFING")
	_check(boat.cast_off_hold != "", "the briefing holds the boat until Arthur is aboard ('%s')" % boat.cast_off_hold)
	_step(seq, 2.0)
	_check(seq.arthur == null, "Arthur takes a moment before he leaves")
	_step(seq, 1.5)
	_check(seq.arthur != null and seq.arthur.state == seq.arthur.State.WALKING and seq.stage == seq.Stage.WALKING, "then he leaves the hall for the launch")
	boat.driving = true       # the player at the helm, still tied up
	boat.cast_off()
	_check(boat.state == boat.State.DOCKED and boat.driving, "the boat will not cast off without him (%s)" % boat.cast_off_hold)
	boat.driving = false
	var guard := 0.0
	while seq.stage == seq.Stage.WALKING and guard < 150.0:
		_step(seq, 1.0)
		guard += 1.0
	_check(seq.stage == seq.Stage.ABOARD and seq.arthur.state == seq.arthur.State.SEATED, "Arthur walks down to the dock and takes his seat (%.0f s)" % guard)
	_check(seq.arthur.get_parent() == boat.get_node("Rig") and boat.cast_off_hold == "", "aboard the launch, and the boat is free to cast off")
	var seat_local: Vector3 = seq.arthur.position
	_check(seat_local.distance_to(Vector3(0.0, 0.5, 0.2)) > 0.6 and seat_localish(seat_local), "beside the helm, not on the player's spot (%s)" % seat_local)

	_check(not gs.fired.has("BOARDING_THRESHOLD"), "the player is far away: no BOARDING_THRESHOLD yet")
	player.global_position = boat.global_position + Vector3(-5.0, 1.0, 2.0)
	_step(seq, 0.3)
	_check(gs.fired.has("BOARDING_THRESHOLD"), "the player coming up to the launch fires BOARDING_THRESHOLD")
	_check(dlg._played.has("ARTHUR_S3_01"), "Arthur says 'In you get' (ARTHUR_S3_01)")

	boat.driving = true
	boat.cast_off()
	_check(boat.state == boat.State.SAILING and gs.fired.has("BOAT_CAST_OFF"), "the launch casts off with Arthur aboard (BOAT_CAST_OFF)")
	_step(seq, 6.0)
	_check(not gs.fired.has("SHIP_SIGHTED"), "the ship is sighted a few seconds after casting off, not at once")
	_step(seq, 3.0)
	_check(gs.fired.has("SHIP_SIGHTED") and dlg._played.has("ARTHUR_S3_11"), "SHIP_SIGHTED fires: Arthur: 'There! Ship's lights ...'")
	var before: Vector3 = seq.arthur.global_position
	boat.global_position += Vector3(0, 0, 40.0)
	_check(seq.arthur.global_position.distance_to(before + Vector3(0, 0, 40.0)) < 0.5, "Arthur rides the boat")

	# the return
	boat.global_position -= Vector3(0, 0, 40.0)
	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	gs.emit_event("RETURN_ARRIVED")
	_check(dlg._played.has("ARTHUR_S4_01"), "on the return Arthur shouts 'Go, go, go - don't you wait for me!' (ARTHUR_S4_01)")
	_check(seq.arthur.state == seq.arthur.State.SEATED, "he is still in his seat for a moment")
	_step(seq, 2.2)
	_check(seq.stage == seq.Stage.ASHORE and seq.arthur.state == seq.arthur.State.WALKING and seq.arthur.get_parent() == _lv, "then he steps ashore onto the jetty")
	guard = 0.0
	while seq.arthur.state == seq.arthur.State.WALKING and guard < 60.0:
		_step(seq, 1.0)
		guard += 1.0
	var j: Array = seq.spec["jetty_spot"]
	var rest: Vector3 = seq.arthur.global_position
	_check(rest.distance_to(Vector3(float(j[0]), float(j[1]), float(j[2]))) < 0.1, "and stands on the jetty, leaving the player to climb (%s)" % rest)
	_step(seq, 30.0)
	_check(seq.arthur.global_position == rest, "he stays there")
	var counts := {}
	for e in gs.event_log:
		if e["note"] == "":
			counts[e["id"]] = counts.get(e["id"], 0) + 1
	_check(counts.get("BOARDING_THRESHOLD", 0) == 1 and counts.get("SHIP_SIGHTED", 0) == 1, "BOARDING_THRESHOLD and SHIP_SIGHTED each fired once")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)


func seat_localish(p: Vector3) -> bool:
	return p.y > 0.2 and p.y < 1.2 and absf(p.x) < 1.2 and absf(p.z - 0.2) < 1.6      # in the hull beside the helm, clear of the engine aft
