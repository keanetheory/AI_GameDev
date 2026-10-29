# test_outcome_screen.gd - run: Godot --headless --path . --script res://tools/test_outcome_screen.gd
# T08: the end of an attempt (scripts/ui/outcome_screen.gd) through the real GameState, deadline, ship and audio mixer in a
# stand-in level, stepped by hand. FAIL: nothing shows while the ship runs on, Ted's fail lines are queued, the Failed screen
# appears only after the fail audio finishes, carries a reason line, ignores input during its grace time, restarts on Enter.
# WIN: the card appears only after the saved ship has cleared the rock; it never shows the wrong outcome; the outcome is final.
extends SceneTree

var _fails := 0
var _started := false


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _process(_d: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _level(tag: String) -> Node3D:
	var lv := Node3D.new()
	lv.name = "StandInLevel" + tag
	var boat := Node3D.new()
	boat.name = "Boat"
	boat.add_to_group("boat")
	lv.add_child(boat)
	root.add_child(lv)
	return lv


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


func _step(gs: Node, seconds: float, dt := 0.1) -> void:
	var t := 0.0
	var dl: Node = gs.deadline()
	var mx: Node = gs.audio()
	var os_: Node = gs.outcome_screen()
	while t < seconds:
		if dl and dl.ship:
			dl.ship._process(dt)
		if mx:
			mx.advance(dt)
		if os_:
			os_._process(dt)
		t += dt


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var lv := _level("A")
	await process_frame
	await process_frame
	var scr: Node = gs.outcome_screen()
	_check(scr != null and not scr.spec.is_empty(), "GameState creates the outcome screen when the level is ready")
	_check(not scr.showing and not scr._veil.visible, "nothing shows before an outcome")

	# ---- FAIL ----
	gs.emit_event("BOAT_CAST_OFF")
	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	var dl: Node = gs.deadline()
	dl._process(500.0)
	_check(gs.outcome == gs.Outcome.FAIL, "the deadline ran out: outcome FAIL")
	_step(gs, 8.0)
	_check(not scr.showing, "8 s on, the ship is still running onto the rock: no screen yet (the game does not cut away)")
	var guard_f := 0.0
	while dl.ship.mode != dl.ship.Mode.CRASHED and guard_f < 60.0:
		_step(gs, 1.0)
		guard_f += 1.0
	_check(dl.ship.mode == dl.ship.Mode.CRASHED and not scr.showing, "the ship has struck the rock; the audio is still playing out, no screen yet")
	var shown_kind := [""]
	scr.shown.connect(func(k: String) -> void: shown_kind[0] = k)
	guard_f = 0.0
	while not scr.showing and guard_f < 40.0:
		_step(gs, 1.0)
		guard_f += 1.0
	_check(scr.showing and scr.kind == "FAIL" and shown_kind[0] == "FAIL", "after the silence the Failed screen shows")
	_check(scr._title.text == "Failed" and scr._reason.text.length() > 10, "it says Failed and gives a reason line: \"%s\"" % scr._reason.text)
	_step(gs, 3.0)
	_check(scr._veil.color.a > 0.7 and scr._veil.get_node("Box").modulate.a > 0.99, "it has faded in over the dark scene")
	var attempt: int = gs.attempt
	scr._t_shown = 0.2
	scr._unhandled_input(_key(KEY_ENTER))
	_check(gs.attempt == attempt, "input during the grace time is ignored (a held key cannot skip the screen)")
	scr._t_shown = 5.0
	gs.emit_event("SHIP_WIN")
	_check(gs.outcome == gs.Outcome.FAIL, "a later SHIP_WIN cannot change the outcome")
	scr._unhandled_input(_key(KEY_ENTER))
	_check(gs.attempt == attempt + 1 and gs.outcome == gs.Outcome.NONE, "Enter restarts the slice (attempt %d, state cleared)" % gs.attempt)
	lv.queue_free()
	await process_frame

	# ---- WIN ----
	var lv2 := _level("B")
	await process_frame
	await process_frame
	var scr2: Node = gs.outcome_screen()
	_check(scr2 != null and scr2 != scr and not scr2.showing, "the new attempt has a fresh, hidden screen")
	gs.emit_event("BOAT_CAST_OFF")
	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	var dl2: Node = gs.deadline()
	dl2._process(100.0)
	gs.emit_event("BURNER_FITTED")
	gs.emit_event("SHIP_WIN")
	_check(gs.outcome == gs.Outcome.WIN and not scr2.showing, "burner fitted, SHIP_WIN: the ship is still on its way, no card yet")
	var guard := 0.0
	while not dl2.ship.cleared and guard < 600.0:
		_step(gs, 1.0)
		guard += 1.0
		_check_not_showing_early(scr2)
	_check(dl2.ship.cleared, "the saved ship clears the rock (%.0f s after the fit)" % guard)
	_check(not scr2.showing, "the card still waits a beat after the rock is cleared")
	_step(gs, 4.0)
	_check(scr2.showing and scr2.kind == "WIN" and scr2._title.text == "The light holds", "then the win card shows")
	scr2._t_shown = 5.0
	scr2._unhandled_input(_key(KEY_SPACE))
	_check(gs.attempt == 3, "Space on the win card also restarts")
	lv2.queue_free()
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)


var _early := false


func _check_not_showing_early(scr: Node) -> void:
	if scr.showing and not _early:
		_early = true
		_check(false, "the win card showed before the ship cleared the rock")
