# test_debug_flags.gd - run it twice:
#   Godot --headless --path . --script res://tools/test_debug_flags.gd              (debug aids expected ON)
#   Godot --headless --path . --script res://tools/test_debug_flags.gd -- --no-debug-ui   (expected OFF)
# Checks that the debug aids follow scripts/core/debug_flags.gd (backlog T21):
#  - the flag itself,
#  - the lighting rig's F5-F8 phase jumps (the "Lighting: <phase>" label is not built in headless mode; check it by eye),
#  - GameState's F9 restart.
# Exit code 0 = all checks passed.
extends SceneTree

const DebugFlags := preload("res://scripts/core/debug_flags.gd")

var _fails := 0


func _initialize() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		_fails += 1


func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)


func _run() -> void:
	var want := not OS.get_cmdline_user_args().has("--no-debug-ui")
	print("expecting the debug aids to be %s" % ("ON" if want else "OFF"))
	_check(DebugFlags.allowed() == want, "DebugFlags.allowed() is %s" % want)
	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.debug_log = false
	var rig: Node = get_first_node_in_group("lighting_rig")
	_check(gs.debug_keys == want, "GameState.debug_keys is %s" % want)
	_check(rig != null and rig.debug_keys == want, "the lighting rig's debug_keys is %s" % want)
	if rig == null:
		quit(1)
		return
	var before: String = rig.phase
	_key(KEY_F8)   # BEACON_RELIT
	await process_frame
	await process_frame
	_check((rig.phase == "BEACON_RELIT") == want, "F8 %s the lighting phase (now %s, was %s)" % ["changes" if want else "does not change", rig.phase, before])
	var attempt: int = gs.attempt
	_key(KEY_F9)
	await process_frame
	await process_frame
	_check((gs.attempt == attempt + 1) == want, "F9 %s the slice (attempt %d -> %d)" % ["restarts" if want else "does not restart", attempt, gs.attempt])
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(0 if _fails == 0 else 1)
