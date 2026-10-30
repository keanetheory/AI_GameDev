# test_diagnosis_sequence.gd - run: Godot --headless --path . --script res://tools/test_diagnosis_sequence.gd
# T05: the beacon diagnosis and the briefing in the real level through the real GameState. Once Arthur is in and Daniel is in the
# basement Ted calls the player up (BEACON_STILL_DARK) and appears in the lamp room; the player reaching the lamp room fires
# LAMP_ROOM_ENTERED, a few seconds later BURNER_DIAGNOSED (the cracked burner appears on the floor); back in the hall near Arthur
# BURNER_BRIEFING moves the game on to BOARDING; stalling nudges IDLE_STEP_3 until the boat casts off; and the player entering the
# lamp room carrying the replacement burner fires LAMP_ROOM_REENTERED. Each fires once, in order, and nothing fires out of turn.
extends SceneTree

var _lv: Node
var _fails := 0
var _f := 0
var _started := false


func _initialize() -> void:
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
		t += 0.1


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var seq: Node = gs.diagnosis()
	var player: CharacterBody3D = _lv.get_node("Player")
	_check(seq != null and not seq.spec.is_empty(), "GameState creates the diagnosis sequence when the level is ready")
	var broken := _lv.find_child("BrokenBurner", true, false) as Node3D
	_check(broken != null and not broken.visible, "the cracked burner is not on the lamp-room floor until Ted has taken it out")
	_check(seq.ted == null, "Ted is not in the lamp room yet")
	player.global_position = Vector3(7.15, 27.6, -5.85)
	_step(seq, 5.0)
	_check(not gs.fired.has("LAMP_ROOM_ENTERED") and not gs.fired.has("BEACON_STILL_DARK"), "walking into the lamp room early fires nothing: the diagnosis waits for the sailors")
	player.global_position = Vector3(7.0, 20.0, -4.0)

	gs.emit_event("SAILORS_INSIDE")
	_step(seq, 12.0)
	_check(not gs.fired.has("BEACON_STILL_DARK"), "Arthur in the hall is not enough: Daniel must be in the basement too")
	gs.emit_event("DANIEL_IN_BASEMENT")
	_step(seq, 6.0)
	_check(not gs.fired.has("BEACON_STILL_DARK"), "a few seconds after both are in, Ted has not shouted yet")
	_step(seq, 3.0)
	_check(gs.fired.has("BEACON_STILL_DARK"), "then BEACON_STILL_DARK fires: Ted calls the player up")
	_check(seq.ted != null and seq.ted.is_inside_tree(), "Ted is in the lamp room")
	var tp: Vector3 = seq.ted.global_position
	var to_lamp := Vector2(tp.x - 8.5, tp.z + 4.9).length()
	_check(to_lamp > 1.2 and to_lamp < 2.6 and absf(tp.y - 27.51) < 0.1, "standing beside the arc lamp on the lamp-room floor (%s)" % tp)
	var forward: Vector3 = -seq.ted.global_transform.basis.z
	_check(forward.dot((Vector3(8.5, tp.y, -4.9) - tp).normalized()) > 0.9, "and facing the lamp")
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), tp + Vector3(0, 0.95, 0))
	var ex: Array[RID] = [player.get_rid()]
	q.exclude = ex
	_check(space.intersect_shape(q, 1).is_empty(), "Ted's spot is clear of the lamp, the rails and the glass")
	_check(broken != null and not broken.visible and not gs.fired.has("LAMP_ROOM_ENTERED"), "still no burner on the floor, and the player has not come up")

	player.global_position = Vector3(8.0, 24.0, -3.0)
	_step(seq, 0.5)
	_check(not gs.fired.has("LAMP_ROOM_ENTERED"), "the spiral stairs below the lamp room do not count")
	player.global_position = Vector3(7.15, 27.6, -5.85)
	_step(seq, 0.2)
	_check(gs.fired.has("LAMP_ROOM_ENTERED"), "the player reaching the lamp room fires LAMP_ROOM_ENTERED")
	_check(not gs.fired.has("BURNER_DIAGNOSED"), "Ted takes a few seconds over the lamp")
	_step(seq, 5.2)
	_check(gs.fired.has("BURNER_DIAGNOSED") and broken.visible, "then BURNER_DIAGNOSED fires and the cracked burner lies on the floor")
	_check(not gs.fired.has("BURNER_BRIEFING"), "the briefing waits until the player is back in the hall")

	var hall: Vector3 = seq._hall_spot
	player.global_position = hall + Vector3(0.8, 0.05, 0.6)
	_step(seq, 0.3)
	_check(gs.fired.has("BURNER_BRIEFING") and gs.phase == gs.Phase.BOARDING, "back in the hall near Arthur: BURNER_BRIEFING, and the phase moves to BOARDING")
	_step(seq, 61.0)
	_check(seq._idle_count == 1, "if the player dawdles IDLE_STEP_3 is called after a minute")
	_step(seq, 62.0)
	_check(seq._idle_count == 3, "and twice more, 30 s apart, up to the three tiers (%d)" % seq._idle_count)
	gs.emit_event("BOAT_CAST_OFF")
	_check(seq._idle_in < 0.0, "casting off ends the nudges")

	gs.emit_event("BURNER_PICKED_UP")
	player.global_position = Vector3(7.15, 27.6, -5.85)
	_step(seq, 0.3)
	_check(not gs.fired.has("LAMP_ROOM_REENTERED"), "entering the lamp room empty-handed does not fire LAMP_ROOM_REENTERED")
	var carry: Node = root.get_node("Carry")
	carry.held = Node3D.new()
	carry.held_kind = "burner"
	_step(seq, 0.3)
	_check(gs.fired.has("LAMP_ROOM_REENTERED"), "entering the lamp room carrying the burner fires LAMP_ROOM_REENTERED")
	carry.held = null
	carry.held_kind = ""
	var counts := {}
	for e in gs.event_log:
		if e["note"] == "":
			counts[e["id"]] = counts.get(e["id"], 0) + 1
	var once := true
	for id in ["BEACON_STILL_DARK", "LAMP_ROOM_ENTERED", "BURNER_DIAGNOSED", "BURNER_BRIEFING", "LAMP_ROOM_REENTERED"]:
		once = once and counts.get(id, 0) == 1
	_check(once, "each event fired exactly once")
	var order_ok := true
	var last := -1
	for id in ["SAILORS_INSIDE", "DANIEL_IN_BASEMENT", "BEACON_STILL_DARK", "LAMP_ROOM_ENTERED", "BURNER_DIAGNOSED", "BURNER_BRIEFING", "BOAT_CAST_OFF", "BURNER_PICKED_UP", "LAMP_ROOM_REENTERED"]:
		var at := -1
		for i in gs.event_log.size():
			if gs.event_log[i]["id"] == id and gs.event_log[i]["note"] == "":
				at = i
		if at <= last:
			order_ok = false
		last = at
	_check(order_ok, "in the story's order")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
