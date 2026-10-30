# test_sailors_sequence.gd - run: Godot --headless --path . --script res://tools/test_sailors_sequence.gd
# T04: the shelter-and-gate beat in the real level, through the real GameState, with the real island gate, baked routes and rowboat,
# stepped by hand. BOILER_FED -> the rowboat rows in -> SAILORS_MOORED -> the sailors wait below the gate -> WINDOW_LOOKED (the
# window look, or the fallback) -> GATE_APPROACHED / GATE_OPENED when the player comes up and opens the gate -> Arthur into the
# hall (SAILORS_INSIDE) -> Daniel down to the basement (DANIEL_IN_BASEMENT, which moves the phase on). Each event fires once and in
# order; the gate being shut holds everyone back and nudges Ted; Daniel stays.
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


func _step(seq: Node, seconds: float, dt := 0.1) -> void:
	var t := 0.0
	while t < seconds:
		seq._process(dt)
		if seq.rowboat:
			seq.rowboat._process(dt)
		if seq.arthur:
			seq.arthur._process(dt)
		if seq.daniel:
			seq.daniel._process(dt)
		t += dt


func _held_ids(dlg: Node) -> Array:
	var out := []
	for h in dlg._held:
		out.append(h["line_id"])
	return out


func _in_basement_at(gs: Node, p: Vector3) -> bool:
	(_lv.get_node("Player") as Node3D).global_position = p
	return gs.player_in_basement()


func _order(gs: Node, ids: Array) -> bool:
	var last := -1
	for id in ids:
		var at := -1
		for i in gs.event_log.size():
			if gs.event_log[i]["id"] == id and gs.event_log[i]["note"] == "":
				at = i
		if at <= last:
			return false
		last = at
	return true


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var seq: Node = gs.sailors()
	_check(seq != null and not seq.spec.is_empty(), "GameState creates the sailors sequence when the level is ready")
	var gate: Node = get_first_node_in_group("gate")
	_check(gate != null and not gate.is_open, "the island gate starts shut")
	_check(seq.stage == seq.Stage.WAITING and seq.rowboat == null, "before the boiler is fed there is no rowboat")
	# the rowboat's path: nothing solid in its way (a 2.2 x 4.4 m box at water level, every metre), and the tower window sees it arrive
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 0.8, 4.4)
	var ex: Array[RID] = [(_lv.get_node("Player") as CharacterBody3D).get_rid()]
	var pts: Array = seq.spec["rowboat"]["path"]
	var blocked := 0
	var seen_from_window := 0
	var samples := 0
	var eye := Vector3(7.16, 24.9, -4.03)
	for k in range(pts.size() - 1):
		var a2 := Vector2(float(pts[k][0]), float(pts[k][1]))
		var b2 := Vector2(float(pts[k + 1][0]), float(pts[k + 1][1]))
		var n := int(a2.distance_to(b2))
		for m in n:
			var p2 := a2.lerp(b2, float(m) / float(n))
			var dir2 := (b2 - a2).normalized()
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = box
			q.transform = Transform3D(Basis(Vector3.UP, atan2(-dir2.x, -dir2.y)), Vector3(p2.x, 0.9, p2.y))
			q.exclude = ex
			if not space.intersect_shape(q, 1).is_empty():
				blocked += 1
			if m % 4 == 0:
				samples += 1
				var rq := PhysicsRayQueryParameters3D.create(eye, Vector3(p2.x, 1.2, p2.y))
				rq.exclude = ex
				var rh := space.intersect_ray(rq)
				var glassy: bool = rh.is_empty() or (rh["collider"] as Node).is_in_group("glass")
				if glassy or eye.distance_to(rh["position"]) > eye.distance_to(Vector3(p2.x, 1.2, p2.y)) - 1.5:
					seen_from_window += 1
	_check(blocked == 0, "the rowboat's path is clear of the harbour, jetties and rocks (%d blocked metres)" % blocked)
	print("     the tower landing window sees the rowboat on %d of %d sampled points of its row in (information)" % [seen_from_window, samples])
	gs.emit_event("BOILER_FED")
	_step(seq, 3.0)
	_check(seq.rowboat == null, "the rowboat does not appear at once (Ted's line plays first)")
	_step(seq, 3.0)
	_check(seq.rowboat != null and seq.stage == seq.Stage.ARRIVING and not gs.fired.has("SAILORS_MOORED"), "a few seconds after BOILER_FED the rowboat comes in at the harbour mouth")
	_check(seq.arthur.state == seq.arthur.State.SEATED and seq.daniel.state == seq.daniel.State.SEATED, "Arthur and Daniel ride in the rowboat")
	var start_x: float = seq.rowboat.global_position.x
	_step(seq, 10.0)
	_check(seq.rowboat.global_position.x > start_x + 10.0 and seq.arthur.global_position.distance_to(seq.rowboat.global_position) < 3.0, "it rows in and the sailors go with it")
	var guard := 0.0
	while not gs.fired.has("SAILORS_MOORED") and guard < 120.0:
		_step(seq, 1.0)
		guard += 1.0
	_check(gs.fired.has("SAILORS_MOORED"), "SAILORS_MOORED fires when the rowboat berths (%.0f s after BOILER_FED)" % (guard + 16.0))
	var berth: Vector2 = seq.rowboat.berth()
	_check(Vector2(seq.rowboat.global_position.x - berth.x, seq.rowboat.global_position.z - berth.y).length() < 0.2, "the rowboat is at the south berth (%.1f, %.1f)" % [berth.x, berth.y])
	_check(absf(seq.rowboat.global_position.z - 22.8) < 2.0 and seq.rowboat.global_position.z > 22.0, "and beside the south jetty, not in the launch's berth at z 18.2")
	_step(seq, 3.0)
	_check(seq.arthur.state == seq.arthur.State.WALKING and seq.arthur.get_parent() == _lv, "the sailors step ashore and walk up to the gate")
	_check(gs.fired.has("SAILORS_MOORED") and not gs.fired.has("WINDOW_LOOKED"), "the window moment has not fired yet (it waits for the player or the fallback)")
	_step(seq, 5.0)
	_check(not gs.fired.has("WINDOW_LOOKED") or true, "(fallback is %.0f s after mooring)" % float(seq.spec["window"]["fallback_s"]))
	_step(seq, 55.0)
	_check(seq.stage == seq.Stage.AT_GATE and seq.arthur.state == seq.arthur.State.IDLE and seq.daniel.state == seq.daniel.State.IDLE, "both wait on the stairs below the gate")
	var gm: Vector3 = gate.middle()
	var da := Vector2(seq.arthur.global_position.x - gm.x, seq.arthur.global_position.z - gm.z).length()
	var dd := Vector2(seq.daniel.global_position.x - gm.x, seq.daniel.global_position.z - gm.z).length()
	_check(da > 1.5 and da < 4.0 and dd > da, "Arthur waits about 2-3 m from the gate and Daniel behind him (%.1f m, %.1f m)" % [da, dd])
	_check(not gs.fired.has("SAILORS_INSIDE") and seq.arthur.global_position.y < gm.y + 1.0, "they do not go through the shut gate")
	_check(seq.window_looked, "the fallback fired WINDOW_LOOKED by itself %.0f s after mooring, so the story never waits on the player looking" % float(seq.spec["window"]["fallback_s"]))
	seq.window_looked = false
	gs.fired.erase("WINDOW_LOOKED")
	# the window look: the player at the tower landing window, looking out, after the sailors have moored
	var player: CharacterBody3D = _lv.get_node("Player")
	var w: Dictionary = seq.spec["window"]
	player.global_position = Vector3(float(w["spot"][0]), float(w["spot"][1]), float(w["spot"][2]))
	var cam: Camera3D = player.get_node_or_null("Camera3D") if player.get_node_or_null("Camera3D") else player.find_child("*", true, false) as Camera3D
	var cams := player.find_children("*", "Camera3D", true, false)
	if not cams.is_empty():
		cam = cams[0]
		cam.current = true
		cam.look_at(Vector3(float(w["look_toward"][0]), float(w["look_toward"][1]), float(w["look_toward"][2])))
	_step(seq, 0.2)
	_check(gs.fired.has("WINDOW_LOOKED") and seq.window_looked, "looking out of the tower window fires WINDOW_LOOKED (before the %.0f s fallback)" % float(w["fallback_s"]))
	player.global_position = Vector3(0, -500, 0)

	# the gate shut: Ted nudges (the director's idle counter; the lines themselves are tested with the dialogue loader)
	seq._idle_in = 0.05
	seq._idle_count = 0
	_step(seq, 0.2)
	_check(seq._idle_count == 1, "with the gate shut and nobody coming, IDLE_STEP_2 is called (nudge %d)" % seq._idle_count)

	# the player comes up and opens the gate
	player.global_position = gm + Vector3(0, 0.1, 3.0)
	await physics_frame
	await physics_frame
	await physics_frame
	_check(gs.fired.has("GATE_APPROACHED"), "the player coming up to the gate fires GATE_APPROACHED")
	gate.open()
	_check(gs.fired.has("GATE_OPENED"), "opening the gate fires GATE_OPENED")
	_step(seq, 2.0)
	_check(seq.arthur.state == seq.arthur.State.WALKING and seq.daniel.state == seq.daniel.State.IDLE, "Arthur goes first; Daniel waits a few seconds")
	_step(seq, 4.0)
	_check(seq.daniel.state == seq.daniel.State.WALKING, "then Daniel follows")
	guard = 0.0
	while not gs.fired.has("SAILORS_INSIDE") and guard < 120.0:
		_step(seq, 1.0)
		guard += 1.0
	_check(gs.fired.has("SAILORS_INSIDE"), "Arthur reaches the hall: SAILORS_INSIDE (%.0f s after the gate opens)" % guard)
	var door: Node3D = _lv.get_node("LighthouseDoor")
	_check(seq.arthur.global_position.distance_to(door.middle()) < 4.5 and seq.arthur.global_position.y > 10.0, "Arthur is in the hall by the door (%s)" % seq.arthur.global_position)
	var dlg: Node = root.get_node("Dialogue")
	_check(dlg._played.has("ARTHUR_S2_06"), "Arthur says he will wait here until Daniel has settled in (ARTHUR_S2_06, after Ted's reply)")
	_check(seq.arthur.global_position.distance_to(door.middle()) < 3.5 and seq.arthur.state == seq.arthur.State.IDLE, "and he waits there, just past the door")
	guard = 0.0
	while not gs.fired.has("DANIEL_IN_BASEMENT") and guard < 150.0:
		_step(seq, 1.0)
		guard += 1.0
	_check(gs.fired.has("DANIEL_IN_BASEMENT") and seq.daniel.global_position.y < 9.0, "Daniel reaches the basement: DANIEL_IN_BASEMENT (y %.1f)" % seq.daniel.global_position.y)
	_check(gs.phase == gs.Phase.BEACON_DIAGNOSIS, "DANIEL_IN_BASEMENT moves the game on to BEACON_DIAGNOSIS")
	# Daniel only speaks when he and the player are both in the basement
	_check(not gs.player_in_basement() and not dlg._played.has("DANIEL_OPT_02") and _held_ids(dlg).has("DANIEL_OPT_02"), "the player is upstairs: Daniel's arrival line is held, not spoken")
	gs.emit_event("BASEMENT_BANG")
	_check(_held_ids(dlg).has("DANIEL_OPT_06") and not dlg._played.has("DANIEL_OPT_06"), "and a basement bang upstairs gets no Daniel line either")
	player.global_position = Vector3(3.65, 7.9, -4.4)
	_check(gs.player_in_basement(), "the player is in the basement")
	dlg._process(0.3)
	_check(dlg._played.has("DANIEL_OPT_02") and dlg._played.has("DANIEL_OPT_06") and dlg._held.is_empty(), "once the player is down there with Daniel, his held lines are spoken")
	_check(not _in_basement_at(gs, Vector3(1.9, 10.6, 1.4)) and not _in_basement_at(gs, Vector3(-27.0, 1.5, 18.0)) and _in_basement_at(gs, Vector3(0.0, 7.9, -4.6)), "the basement test: the porch and the dock are not the basement; the boiler room is")

	_check(_order(gs, ["BOILER_FED", "SAILORS_MOORED", "WINDOW_LOOKED", "GATE_APPROACHED", "GATE_OPENED", "SAILORS_INSIDE", "DANIEL_IN_BASEMENT"]), "the events came in the story's order")
	var rest: Vector3 = seq.daniel.global_position
	_step(seq, 30.0)
	_check(seq.daniel.global_position == rest and seq.stage == seq.Stage.DONE, "Daniel stays in the basement")
	var counts := {}
	for e in gs.event_log:
		if e["note"] == "":
			counts[e["id"]] = counts.get(e["id"], 0) + 1
	var once := true
	for id in ["SAILORS_MOORED", "GATE_OPENED", "SAILORS_INSIDE", "DANIEL_IN_BASEMENT"]:   # (WINDOW_LOOKED was fired twice by the test itself, to try both the fallback and the look)
		once = once and counts.get(id, 0) == 1
	_check(once, "each story event fired exactly once")
	_check(counts.get("WINDOW_LOOKED", 0) == 2 and gs.fired.has("WINDOW_LOOKED"), "(WINDOW_LOOKED: the fallback, then the look, as the test arranged)")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
