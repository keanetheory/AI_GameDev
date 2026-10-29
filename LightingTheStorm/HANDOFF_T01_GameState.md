# HANDOFF - T01: central GameState autoload (phase machine, event bus, restart)

## 1. Task and goal

T01 asked for a GameState autoload holding the phase enum (ARRIVAL_AND_COAL to RESOLUTION), an `emit_event(id)` bus with a debug event log, a `restart()`, and wiring from GameState events to the DialogueLoader, the lighting rig's `set_phase()` and the boat's signals (Technical Strategy, "Core state contract").

Finding: the premise was out of date. `GameState` (`scripts/core/game_state.gd`) and the `Dialogue` autoload were already registered in `project.godot` and already implemented all of the above. This task was therefore a verify-and-close: check the implementation against the contract, run its tests, fix two small gaps, and write this note (`game_state.gd` already referred to it).

## 2. Files changed

- `scripts/dialogue/dialogue_loader.gd`: `_generation` counter. `reset_for_restart()` bumps it and sets `_playing = false`; `_play_queue()` returns after any `await` if the generation changed. A line mid-wait when the slice restarts is dropped instead of being spoken in the new attempt.
- `scripts/core/game_state.gd`: debug key F11 (inside the existing `debug_keys` gate) emits `BURNER_PICKED_UP`; header comment updated.
- `tools/test_game_state.gd`: one added check (after `restart()` the dialogue is not playing and its queue is empty).
- `things to work on next.md`: item 7 reworded (GameState now reports the events that exist; the trigger scenery is what is missing).
- This file (new).
- Not changed: `Level.tscn`, `project.godot`, `boat.gd`, `lighting_rig.gd`, `canon.py`, the GDD, any JSON.

## 3. How to run and test

Godot 4.3 (`project.godot` features: 4.3, Forward Plus). From the repo root:

```
Godot_v4.3-stable_win64_console.exe --headless --path LightingTheStorm --script res://tools/test_game_state.gd
Godot_v4.3-stable_win64_console.exe --headless --path LightingTheStorm --script res://tools/test_boat.gd
```

In the game: run `Level.tscn`. F9 restarts the slice, F10 prints the event log, F11 fires BURNER_PICKED_UP (debug only, needs `GameState.debug_keys`). F5-F8 are the lighting rig's own phase jumps.

For other agents (T02-T08): report what happened with `GameState.emit_event("EVENT_ID")` only. Never set `GameState.phase` and never call `Dialogue.trigger()` directly. Listen to `GameState.event_emitted(id, phase)`, `phase_changed(old, new)` and `restarted`. Unknown IDs are rejected (warning in debug builds). Every event except `OUTBOUND_NEAR_MISS` and `OUTBOUND_COLLISION` is one-shot per attempt; a repeat is logged and ignored. `IDLE_*` IDs are routed to `Dialogue.idle()` (nudge ladder) and are not logged as events.

## 4. Observed behaviour

Contract check, by reading `game_state.gd` and `AIAgentCrew/canon.py`:
- Phase enum order matches the Technical Strategy: ARRIVAL_AND_COAL, SHELTER_AND_GATE, BEACON_DIAGNOSIS, BOARDING, OUTBOUND, SALTGATE, RETURN, FINAL_REPAIR, RESOLUTION. OK.
- `EVENTS` holds the 32 `canon.py` OPENING_EVENTS in the same order, plus four proposed IDs (section 7). OK.
- One-shot per attempt via `fired`; only the two OUTBOUND_* events are repeatable. OK.
- Outcome resolves once (`outcome != NONE` rejects a later SHIP_WIN/SHIP_FAIL). OK.
- Phase moves forward only (`_advance_phase` ignores a target <= current). OK.
- Boat and rig are found by group ("boat", "lighting_rig") when a scene enters the root; `GAME_STARTED` fires then. `lighting_rig.gd` has `follow_boat_signals = false`, so GameState is the only thing driving it.
- `Level.tscn`: `DockZoneLighthouse` and `DockZoneLighthouseSouth` have no `zone_id` line, so they use the script default `DOCK_LIGHTHOUSE`; `DockZonePort` sets `DOCK_PORT`. These are the IDs GameState tests for. OK.
- The event log records the phase as it was before the event's own phase change (for example `BOILER_FED` is logged under ARRIVAL_AND_COAL). That is how the code is written; noted so nobody reads the log wrongly.

Headless runs (Godot 4.3.stable, Windows, run by me):
- `test_game_state.gd`: before and after my edits, `RESULT: OK (0 failed)`, exit code 0; the second run has one more PASS line (the new restart check). The stderr warnings are the test's own deliberate cases (unknown id, leaving DOCK_PORT with no burner, no scene to reload).
- `test_boat.gd`: exit code 0, but it ends with `TIMEOUT in step 10 ... hits=150` and does not exercise the full crossing. The handling checks pass (full speed 9.74 m/s, turn rate about 34.7 deg/s, W+S no change, a sea-stack hit recovers). But step 8 reports "outbound: docked at DOCK_LIGHTHOUSE after 23 s", meaning the boat re-docked at the lighthouse instead of reaching DOCK_PORT, and the return leg then keeps hitting something near (-31.9, 0.7, 21). The test script does not set a failing exit code on a timeout. This is not caused by GameState. The only uncommitted change in `boat.gd` is the `add_to_group("boat")` line (checked with `git diff`), and the `docked`/`departed`/`hazard_hit` signals were already committed. My guess, not verified: the test predates the two-berth harbour (two zones share the id DOCK_LIGHTHOUSE, and `boat.gd` skips zones by id when leaving), but I did not investigate further. Recorded as an open issue.

Not observed: any of this in the running game (see section 5).

## 5. Not verified

- I cannot run the Godot editor or play the level. The `restart()` path (`reload_current_scene()`, then the new scene entering the root, then re-binding and `GAME_STARTED`) is covered by the headless test only up to resetting state. The scene reload itself was not exercised, so player mouse capture, camera and boat reset after F9 need a play check.
- The dialogue stale-line fix is checked for state (not playing, queue empty after restart) but not for timing. I did not build a test that restarts mid-line and waits for the old timer to fire.
- `test_boat.gd` does not currently prove docking works end to end (section 4).
- F11 was not pressed in a running game.
- With `require_burner_for_return = true`, leaving the Saltgate does not enter RETURN until something fires `BURNER_PICKED_UP`. Until T06 lands, use F11 (or set the export to false) when QA-ing the return crossing.

## 6. Licences and provenance

None. No external assets were added.

## 7. Interface or contract changes proposed

These are in code, marked PROPOSED, and are not in `canon.py` or the Technical Strategy. I have not edited either. They need the Production and Canon orchestrators (or the creator) to accept or rename them.

New event IDs:
- `RETURN_ARRIVED`: emitted by GameState when the boat docks at DOCK_LIGHTHOUSE while the phase is RETURN. Moves the phase to FINAL_REPAIR. T11 (Arthur's arrival line) and the burner-fit task will want this.
- `BURNER_FITTED`: the burner is fitted to the beacon. Phase FINAL_REPAIR; lighting BEACON_RELIT.
- `SHIP_WIN`, `SHIP_FAIL`: the single outcome resolution. Phase RESOLUTION; second one in an attempt is ignored.

Phase boundaries (`PHASE_ON_EVENT`; the GDD lists phases and events but not where one ends and the next begins):
- BOILER_FED -> SHELTER_AND_GATE
- DANIEL_IN_BASEMENT -> BEACON_DIAGNOSIS (the Technical Strategy says Daniel reaching the basement completes SHELTER_AND_GATE)
- BURNER_BRIEFING -> BOARDING
- BOAT_CAST_OFF -> OUTBOUND
- SALTGATE_REACHED -> SALTGATE
- RETURN_DEPARTED -> RETURN
- RETURN_ARRIVED, LAMP_ROOM_REENTERED, BURNER_FITTED -> FINAL_REPAIR (LAMP_ROOM_REENTERED accepted 29 October 2026; the emitter is not built yet)
- SHIP_WIN, SHIP_FAIL -> RESOLUTION

Lighting mapping: ISLAND for the first four phases, OUTBOUND for OUTBOUND and SALTGATE, RETURN for RETURN and FINAL_REPAIR, BEACON_RELIT once the burner is fitted. Note that the rig stays on ISLAND during BOARDING and switches on cast-off, as before GameState.

Behaviour changes to existing contracts: the lighting rig no longer follows the boat itself (`follow_boat_signals = false`), and RETURN needs `BURNER_PICKED_UP` first (`require_burner_for_return`). Both are as found, not new in this task. Both are consistent with the Technical Strategy invariant that a pickup precedes the return.

`BOAT_CAST_OFF` is emitted whenever the boat leaves DOCK_LIGHTHOUSE. It is one-shot, so a second departure from the lighthouse in the same attempt is ignored as a repeat.

## 8. Open creator decisions

- Accept or rename the four proposed event IDs and the phase boundaries above, ideally before T02-T08 start (they all inherit them).
- Is `test_boat.gd` worth repairing now (it appears stale since the two-berth harbour) or left until the boat and QA tasks (T17, T20)?
- Fail reason line, retry/save model beyond "restart the slice", and deadline length remain open as before (Decisions to be made B3, B5, B4). Nothing here touches them.
- Bookkeeping I could not do (outside my write area): mark T01 as done pending the play check in `GoalOrientedAgent/state/backlog.json` (BACKLOG.md and HANDOFF.md are generated from it), and correct the stale evidence text "project.godot has no [autoload]" in T01, R10 and R15 (R14 and R15 should read partial once the creator has played it).
