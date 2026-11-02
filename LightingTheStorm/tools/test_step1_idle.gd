# test_step1_idle.gd - run: Godot --headless --path . --script res://tools/test_step1_idle.gd
# T64: Ted's step 1 nudges in the real level through the real GameState. From the knock (GAME_STARTED) a stall calls IDLE_STEP_1
# after idle_step1.first_nudge_s, then every next_nudge_s up to the six tiers; progress (in the door, the engine room, the coal)
# restarts the wait without restarting the ladder; BOILER_FED ends it. The dialogue loader climbs one tier per call, so each of
# TED_S1_I1..I6 is queued once, in order.
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
		_hush()
		seq._process(0.1)
		t += 0.1


## Time is stepped by hand, so a line queued by an event never finishes; the loader drops a nudge while a line plays, so
## let each queued line end before the next step (in play, Ted's lines end on their own).
func _hush() -> void:
	var dlg := root.get_node("Dialogue")
	dlg._queue.clear()
	dlg._playing = false


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var dlg := root.get_node("Dialogue")
	var seq: Node = gs.intro()
	_check(seq != null and seq.spec.has("idle_step1"), "the intro sequence carries the step 1 nudge settings")
	var idle: Dictionary = seq.spec["idle_step1"]
	var first := float(idle["first_nudge_s"])
	var next := float(idle["next_nudge_s"])
	var tiers := int(idle["tiers"])
	var lines: int = dlg._by_trigger.get("IDLE_STEP_1", []).size()
	_check(tiers == lines, "one tier per IDLE_STEP_1 line (%d tiers, %d lines)" % [tiers, lines])

	_step(seq, first + 5.0)
	_check(seq._idle_count == 0, "before the knock nothing nudges")
	gs.emit_event("GAME_STARTED")
	_step(seq, first - 1.0)
	_check(seq._idle_count == 0, "just short of %d s after the knock, no nudge yet" % first)
	_step(seq, 1.2)
	_check(seq._idle_count == 1, "a stall of %d s calls IDLE_STEP_1" % first)
	_check(int(dlg._idle_tier.get("IDLE_STEP_1", 0)) == 1, "and the loader is on tier 1")

	gs.emit_event("LIGHTHOUSE_ENTERED")
	_step(seq, first - 1.0)
	_check(seq._idle_count == 1, "progress (in the door) restarts the wait")
	_step(seq, 1.2)
	_check(seq._idle_count == 2, "a fresh stall nudges again, on the next tier, not tier 1 again")
	_check(int(dlg._idle_tier.get("IDLE_STEP_1", 0)) == 2, "the loader climbed to tier 2 (no line repeats)")

	gs.emit_event("ENGINE_ROOM_ENTERED")
	_step(seq, first + 0.2 + next * (tiers - 3) + 1.0)
	_check(seq._idle_count == tiers, "stalling on climbs every %d s up to all %d tiers (%d)" % [next, tiers, seq._idle_count])
	_check(seq._idle_in < 0.0, "and then stops")
	_step(seq, next * 3.0)
	_check(seq._idle_count == tiers, "no nudges past the last tier")

	seq._idle_in = 5.0
	gs.emit_event("BOILER_FED")
	_check(seq._idle_in < 0.0 and not dlg._idle_tier.has("IDLE_STEP_1"), "BOILER_FED ends the nudges and resets the ladder")
	_step(seq, first + next)
	_check(seq._idle_count == tiers, "nothing nudges after the boiler is fed")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
