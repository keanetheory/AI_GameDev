# test_game_state.gd - run: Godot --headless --path . --script res://tools/test_game_state.gd
# Checks the GameState autoload (scripts/core/game_state.gd) without loading the level:
#  1. the autoloads exist and the dialogue data parsed;
#  2. a scene entering the root binds a (fake) boat and rig and fires GAME_STARTED once, and Ted's door greeting plays;
#  3. the opening events walk the phase machine in order; repeats and out-of-order events never move it back;
#  4. the outcome resolves once per attempt;
#  5. the boat's signals become events, RETURN_DEPARTED waits for the burner, and the lighting rig is driven by phase;
#  6. restart() clears the attempt.
# Exit code 0 = all checks passed.
extends SceneTree

const FAKE_BOAT := "extends Node\nsignal docked(zone_id: String)\nsignal departed(zone_id: String)\nsignal hazard_hit\n"
const FAKE_RIG := "extends Node\nvar calls := []\nfunc set_phase(id: String, instant := false) -> void:\n\tcalls.append(id)\n"

var _fails := 0


func _initialize() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		_fails += 1


func _fake(source: String, group: String) -> Node:
	var s := GDScript.new()
	s.source_code = source
	s.reload()
	var n := Node.new()
	n.set_script(s)
	n.add_to_group(group)
	return n


func _run() -> void:
	await process_frame   # in script mode the autoloads' _ready has not run yet inside _initialize
	var gs: Node = root.get_node_or_null("GameState")
	var dl: Node = root.get_node_or_null("Dialogue")
	_check(gs != null and dl != null, "GameState and Dialogue autoloads exist")
	if gs == null or dl == null:
		quit(1)
		return
	_check(not dl.data.is_empty(), "dialogue data parsed (%d lines)" % dl.data.get("lines", []).size())
	gs.debug_log = false

	# 2. a scene enters the root: GAME_STARTED fires once and the fake boat and rig are bound
	var level := Node3D.new()
	level.name = "FakeLevel"
	var boat := _fake(FAKE_BOAT, "boat")
	var rig := _fake(FAKE_RIG, "lighting_rig")
	level.add_child(boat)
	level.add_child(rig)
	root.add_child(level)
	await process_frame
	await process_frame
	_check(gs.fired.has("GAME_STARTED"), "GAME_STARTED fired when the scene entered")
	_check(dl._played.has("TED_S1_01"), "Dialogue queued TED_S1_01 on GAME_STARTED")
	_check(rig.calls == ["ISLAND"], "rig was set to ISLAND on bind: %s" % [rig.calls])
	_check(not gs.emit_event("GAME_STARTED"), "a second GAME_STARTED is ignored")
	_check(gs.phase == gs.Phase.ARRIVAL_AND_COAL, "phase starts at ARRIVAL_AND_COAL")

	# 3. the opening events in order
	var steps := [
		["LIGHTHOUSE_ENTERED", gs.Phase.ARRIVAL_AND_COAL], ["BOILER_FED", gs.Phase.SHELTER_AND_GATE],
		["GATE_OPENED", gs.Phase.SHELTER_AND_GATE], ["DANIEL_IN_BASEMENT", gs.Phase.BEACON_DIAGNOSIS],
		["BEACON_STILL_DARK", gs.Phase.BEACON_DIAGNOSIS], ["BURNER_BRIEFING", gs.Phase.BOARDING],
		["BOAT_CAST_OFF", gs.Phase.OUTBOUND], ["SALTGATE_REACHED", gs.Phase.SALTGATE],
	]
	for s in steps:
		gs.emit_event(s[0])
		_check(gs.phase == s[1], "%s -> %s" % [s[0], gs.phase_name()])
	_check(rig.calls == ["ISLAND", "OUTBOUND"], "rig went to OUTBOUND once: %s" % [rig.calls])
	_check(not gs.emit_event("BOILER_FED") and gs.phase == gs.Phase.SALTGATE, "a repeated BOILER_FED neither fires nor moves the phase")
	_check(not gs.emit_event("NOT_AN_EVENT"), "an unknown event id is rejected")
	var first_pass: int = gs.event_log.size()
	gs.emit_event("OUTBOUND_COLLISION")
	gs.emit_event("OUTBOUND_COLLISION")
	_check(gs.event_log.size() == first_pass + 2, "OUTBOUND_COLLISION is repeatable")

	# 5. boat signals: leaving the Saltgate without the burner does not start RETURN
	boat.emit_signal("departed", "DOCK_PORT")
	_check(not gs.fired.has("RETURN_DEPARTED") and gs.phase == gs.Phase.SALTGATE, "leaving DOCK_PORT with no burner aboard does not emit RETURN_DEPARTED")
	gs.emit_event("BURNER_PICKED_UP")
	boat.emit_signal("departed", "DOCK_PORT")
	_check(gs.fired.has("RETURN_DEPARTED") and gs.phase == gs.Phase.RETURN, "with the burner aboard, leaving DOCK_PORT -> RETURN")
	_check(rig.calls.back() == "RETURN", "rig went to RETURN via GameState: %s" % [rig.calls])
	boat.emit_signal("docked", "DOCK_LIGHTHOUSE")
	_check(gs.phase == gs.Phase.FINAL_REPAIR, "docking at the lighthouse on the return -> FINAL_REPAIR (RETURN_ARRIVED)")
	gs.emit_event("BURNER_FITTED")
	_check(rig.calls.back() == "BEACON_RELIT", "BURNER_FITTED -> lighting BEACON_RELIT")

	# 4. the outcome resolves once
	_check(gs.emit_event("SHIP_WIN") and gs.outcome == gs.Outcome.WIN and gs.phase == gs.Phase.RESOLUTION, "SHIP_WIN -> RESOLUTION, outcome WIN")
	_check(not gs.emit_event("SHIP_FAIL") and gs.outcome == gs.Outcome.WIN, "a later SHIP_FAIL is ignored; the outcome resolves once")

	# 6. restart clears the attempt (no current scene here, so only the state is reset)
	var attempt_before: int = gs.attempt
	gs.restart()
	_check(gs.attempt == attempt_before + 1, "restart() bumps the attempt counter")
	_check(gs.phase == gs.Phase.ARRIVAL_AND_COAL and gs.outcome == gs.Outcome.NONE, "restart() resets phase and outcome")
	_check(gs.fired.is_empty() and gs.event_log.is_empty(), "restart() clears fired events and the log")
	_check(not gs.burner_aboard and not gs.burner_fitted, "restart() clears burner state")
	_check(dl._played.is_empty(), "restart() reset the dialogue's played lines")
	_check(not dl._playing and dl._queue.is_empty(), "restart() stopped the dialogue (a stale line is dropped)")

	# forward-only: after a restart an early BOAT_CAST_OFF is followed by BOILER_FED, which must not go back
	gs.emit_event("BOAT_CAST_OFF")
	gs.emit_event("BOILER_FED")
	_check(gs.phase == gs.Phase.OUTBOUND, "an earlier phase's event never moves the phase back")
	gs.emit_event("GAME_STARTED")
	_check(dl._played.has("TED_S1_01"), "after restart GAME_STARTED plays Ted's greeting again")

	gs.dump_log()
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(0 if _fails == 0 else 1)
