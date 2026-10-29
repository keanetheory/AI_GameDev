# test_ship_deadline.gd - run: Godot --headless --path . --script res://tools/test_ship_deadline.gd
# T07: the hidden ship deadline (scripts/core/ship_deadline.gd), driven through the real GameState autoload with a stand-in
# level (a node holding a "boat"), stepping the clock by hand. Checks: inactive before RETURN_DEPARTED, starts once, pauses
# with the P key, honours the debug time scale, expires into exactly one SHIP_FAIL and a crash, freezes when the burner is
# fitted and lets the ship through, and reports its progress to GameState (the sea reads it).
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


func _level() -> Node3D:
	var lv := Node3D.new()
	lv.name = "StandInLevel"
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


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var lv := _level()
	await process_frame
	await process_frame
	var dl: Node = gs.deadline()
	_check(dl != null and dl.ship != null, "GameState creates the deadline director and the passenger ship when the level is ready")
	if dl == null:
		quit(1)
		return
	_check(dl.length_s == 210.0, "placeholder deadline length is 3 min 30 s (%.0f s)" % dl.length_s)
	_check(not dl.ship.visible and gs.deadline_progress() == -1.0, "before boarding: the ship is hidden and the clock reads -1")
	gs.emit_event("BOAT_CAST_OFF")
	_check(dl.ship.visible and dl.ship.mode == dl.ship.Mode.HOLD, "at the boarding threshold / cast-off the ship appears at the horizon and holds")
	dl._process(30.0)
	_check(dl.state == dl.State.WAITING and gs.deadline_progress() == -1.0, "the clock is inactive before the return crossing: 30 s pass, still waiting")
	_check(dl.ship.travelled() == 0.0, "the ship holds at its starting lights until the clock starts")

	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	_check(dl.state == dl.State.RUNNING and is_equal_approx(gs.deadline_progress(), 0.0), "RETURN_DEPARTED starts the clock at 0")
	dl._process(105.0)
	_check(absf(gs.deadline_progress() - 0.5) < 0.001, "half the length gives progress 0.5 (%.3f)" % gs.deadline_progress())
	_check(absf(dl.ship.travelled() - 0.5 * dl.ship.commit_s()) < 0.5, "the ship is half way to the commit point (%.0f of %.0f m)" % [dl.ship.travelled(), dl.ship.commit_s()])

	# pause with the P key: the clock and the ship stop
	dl._unhandled_input(_key(KEY_P))
	_check(paused, "the P key pauses the game")
	var before: float = dl.elapsed
	dl._process(50.0)
	_check(dl.elapsed == before, "the clock does not advance while paused")
	dl._unhandled_input(_key(KEY_P))
	_check(not paused, "P again resumes")
	dl._process(10.0)
	_check(absf(dl.elapsed - (before + 10.0)) < 0.001, "the clock runs again after resuming")

	# debug time scale (Page Up steps it) and the penalty hook
	dl.time_scale = 1.0
	gs.debug_keys = true
	dl._unhandled_input(_key(KEY_PAGEUP))
	_check(dl.time_scale == 2.0, "Page Up doubles the debug time scale (%.2f)" % dl.time_scale)
	var e2: float = dl.elapsed
	dl._process(5.0)
	_check(absf(dl.elapsed - (e2 + 10.0)) < 0.001, "at scale 2, 5 s of play is 10 deadline seconds")
	dl.time_scale = 1.0
	var e3: float = dl.elapsed
	dl.add_penalty(8.0, "test")
	_check(absf(dl.elapsed - (e3 + 8.0)) < 0.001, "add_penalty() adds time (T19 will set the values)")

	# expiry: exactly one SHIP_FAIL, the ship commits, then crashes
	var impacts := [0]
	dl.ship.impact.connect(func() -> void: impacts[0] += 1)
	dl._process(500.0)
	_check(gs.outcome == gs.Outcome.FAIL and gs.fired.has("SHIP_FAIL"), "running out fires SHIP_FAIL and the outcome is FAIL")
	_check(is_equal_approx(gs.deadline_progress(), 1.0) and dl.state == dl.State.EXPIRED, "progress holds at 1.0 after expiry")
	_check(dl.ship.mode == dl.ship.Mode.COMMITTED, "the ship is committed to the rock")
	var fails := 0
	for e in gs.event_log:
		if e["id"] == "SHIP_FAIL" and e["note"] == "":
			fails += 1
	_check(fails == 1, "SHIP_FAIL was accepted exactly once (%d)" % fails)
	for i in 400:
		dl.ship._process(0.1)
	_check(dl.ship.mode == dl.ship.Mode.CRASHED and impacts[0] == 1, "the ship crashes (impact once)")
	gs.emit_event("SHIP_WIN")
	_check(gs.outcome == gs.Outcome.FAIL, "a later SHIP_WIN cannot change the outcome")

	# second attempt: the win path
	gs.restart()
	lv.queue_free()
	await process_frame
	var lv2 := _level()
	await process_frame
	await process_frame
	var dl2: Node = gs.deadline()
	_check(dl2 != null and dl2 != dl and dl2.state == dl2.State.WAITING, "a restart gives a fresh, waiting clock")
	gs.emit_event("BOAT_CAST_OFF")
	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	dl2._process(120.0)
	var frozen_at: float = gs.deadline_progress()
	gs.emit_event("BURNER_FITTED")
	_check(dl2.state == dl2.State.FROZEN and dl2.ship.mode == dl2.ship.Mode.AVOIDING, "BURNER_FITTED freezes the clock and the ship steers clear")
	dl2._process(1000.0)
	_check(gs.deadline_progress() == frozen_at and gs.outcome == gs.Outcome.NONE, "a frozen clock cannot run out: no SHIP_FAIL after the fit")
	for i in 6000:
		dl2.ship._process(0.1)
		if dl2.ship.mode == dl2.ship.Mode.PASSED:
			break
	_check(dl2.ship.mode == dl2.ship.Mode.PASSED and not dl2.ship.visible, "the ship reaches port safely and leaves the scene")
	gs.emit_event("SHIP_WIN")
	_check(gs.outcome == gs.Outcome.WIN, "SHIP_WIN resolves the outcome")
	gs.emit_event("SHIP_FAIL")
	_check(gs.outcome == gs.Outcome.WIN, "and a later SHIP_FAIL is ignored")
	dl2._unhandled_input(_key(KEY_P))
	_check(not paused, "pausing after the outcome is settled does nothing")
	lv2.queue_free()
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
