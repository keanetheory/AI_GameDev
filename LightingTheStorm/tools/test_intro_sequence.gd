# test_intro_sequence.gd - run: Godot --headless --path . --script res://tools/test_intro_sequence.gd
# The opening (creator, 30 Oct 2026) in the real level through the real GameState: Ted waits behind the shut front door; E at the
# door knocks (it does not open it); the game starts and Ted greets the player (the one Ted line spoken with the player outside);
# Ted opens the door; when the player steps in Ted walks up to the lamp room while he sends the player to the coal. Every other Ted
# line is held until the player is inside the building (a nudge is dropped), and Arthur's lines are not held.
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


func _step(intro: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		intro._process(0.1)
		if intro.ted:
			intro.ted._process(0.1)
		t += 0.1


func _held_ids(dlg: Node) -> Array:
	var out := []
	for h in dlg._held:
		out.append(h["line_id"])
	return out


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var intro: Node = gs.intro()
	var door: Node3D = _lv.get_node("LighthouseDoor")
	var player: CharacterBody3D = _lv.get_node("Player")
	var dlg: Node = root.get_node("Dialogue")
	_check(intro != null and intro.holds_start, "GameState creates the intro and waits for the knock")
	_check(not gs.fired.has("GAME_STARTED"), "the game has not started: no greeting while the player stands outside unseen")
	_check(door.knock_mode and door.prompt_text() == "Knock" and not door.is_open, "the shut front door offers 'Knock'")
	_step(intro, 0.2)
	_check(intro.ted != null, "Ted is in the lighthouse already")
	var out_v: Vector3 = door.global_transform.basis.z
	var rel: Vector3 = intro.ted.global_position - door.middle()
	_check(rel.dot(out_v) < -0.3 and rel.length() < 3.0, "behind the shut door, just inside (%.1f m in)" % -rel.dot(out_v))
	var fwd: Vector3 = -intro.ted.global_transform.basis.z
	_check(fwd.dot((door.middle() - intro.ted.global_position).normalized()) > 0.5, "facing the door")

	# E at the door knocks
	door.interact(player)
	_check(not door.is_open and not door.enabled and not door.knock_mode, "E knocks: the door stays shut and offers nothing more")
	_step(intro, 0.5)
	_check(not door.is_open and not gs.fired.has("GAME_STARTED"), "a moment after the knock the door is still shut and Ted has said nothing")
	_step(intro, 1.0)
	_check(door.is_open and door.enabled and door.prompt_text() == "Close the door", "Ted opens the door; it is an ordinary door again")
	_check(not gs.fired.has("GAME_STARTED") and not dlg._played.has("TED_S1_01"), "his greeting has not started yet: it waits for the door to be open")
	_step(intro, 0.6)
	_check(gs.fired.has("GAME_STARTED"), "GAME_STARTED fires once the door is open")
	_check(dlg._played.has("TED_S1_01") and not gs.player_inside_building(), "Ted's greeting is spoken, with the player still outside (the one exception)")
	# Ted must be out of the swing of the leaf
	await physics_frame
	await create_timer(0.9).timeout
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), intro.ted.global_position + Vector3(0, 0.95, 0))
	var ex: Array[RID] = [player.get_rid()]
	q.exclude = ex
	var hits := space.intersect_shape(q, 4)
	var leaf_hit := false
	for h in hits:
		if (h["collider"] as Node).get_parent() == door:
			leaf_hit = true
	_check(not leaf_hit, "Ted stands clear of the open door")

	# Ted's other lines wait for the player to be inside
	player.global_position = door.middle() + out_v * 1.5 + Vector3(0, 0.1, 0)
	_check(not gs.player_inside_building(), "the porch is outside the building")
	gs.emit_event("LIGHTHOUSE_ENTERED")
	_check(_held_ids(dlg).has("TED_S1_03") and not dlg._played.has("TED_S1_03"), "with the player still on the porch Ted's coal order is held, not spoken")
	gs.emit_event("SAILORS_INSIDE")
	_check(dlg._played.has("ARTHUR_S2_05") and _held_ids(dlg).has("TED_S2_04"), "Arthur's lines are not held, Ted's reply is")
	gs.idle("IDLE_STEP_1")
	_check(not _held_ids(dlg).has("TED_S1_I1") and not dlg._played.has("TED_S1_I1"), "a Ted nudge that cannot be heard is dropped, not saved")
	player.global_position = door.middle() - out_v * 1.5 + Vector3(0, 0.1, 0)
	_check(gs.player_inside_building(), "one step inside the door is inside")
	dlg._process(0.3)
	_check(dlg._played.has("TED_S1_03") and dlg._played.has("TED_S2_04") and dlg._held.is_empty(), "once the player is inside the held Ted lines are spoken")

	# the places
	var spots := {"the porch": [Vector3(1.9, 10.6, 1.4), false], "the dock": [Vector3(-27, 1.5, 18), false], "the plateau by the gate": [Vector3(-16, 9.9, 9), false],
		"the hall": [Vector3(0.4, 10.6, -1.9), true], "the basement": [Vector3(3.6, 7.9, -4.4), true], "the lamp room": [Vector3(7.15, 27.6, -5.85), true],
		"the island rocks": [Vector3(20, 9, 0), false]}
	for k in spots:
		player.global_position = spots[k][0]
		_check(gs.player_inside_building() == bool(spots[k][1]), "%s is %s the building" % [k, "inside" if spots[k][1] else "outside"])

	# Ted walks up to the lamp room
	_check(intro._walked and intro.ted.state == intro.ted.State.WALKING, "Ted walked off when the player stepped in")
	_step(intro, 0.2)
	_check(intro.ted._walking_anim, "with his walking clip playing")
	var guard := 0.0
	while intro.ted.state == intro.ted.State.WALKING and guard < 200.0:
		_step(intro, 1.0)
		guard += 1.0
	var tp: Vector3 = intro.ted.global_position
	_check(Vector2(tp.x - 8.6, tp.z + 6.9).length() < 0.5 and absf(tp.y - 27.51) < 0.2, "he arrives in the lamp room beside the arc lamp after %.0f s (%s)" % [guard, tp])
	var look: Vector3 = -intro.ted.global_transform.basis.z
	_check(look.dot((Vector3(8.5, tp.y, -4.9) - tp).normalized()) > 0.9 and not intro.ted._walking_anim, "and turns to the lamp and stands")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
