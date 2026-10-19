# Development log

Append-only record of what the Goal-Oriented Agent changed, newest last.

## 2026-10-19 15:23 - T01 Create the central GameState autoload: phase machine, event bus, restart (score 10)

**Outcome:** partial  

T01's premise was out of date. `GameState` and `Dialogue` are already registered in `project.godot`, and `scripts/core/game_state.gd` already has the phase enum, `emit_event()`, the event log, `restart()` and the wiring to Dialogue, the lighting rig and the boat. I verified that against the contract and the headless test passes. I made two small fixes, wrote the missing handoff note, and reworded item 7 of the work list. Two things are not done. I couldn't update the agent bookkeeping, which is outside my write area. And `test_boat.gd` times out, which I traced to something other than GameState.

**Contract check (by reading `game_state.gd` and `canon.py`):** all of these match.
- The phase order is correct.
- The 32 canon event IDs match in order, plus four proposed IDs.
- Events are one-shot per attempt, except the two OUTBOUND ones.
- The outcome resolves once.
- The phase only moves forward.
- The lighthouse dock zones use the default `DOCK_LIGHTHOUSE`, and the port zone is `DOCK_PORT`.

**Fixes:**
- **Stale dialogue line on restart:** `dialogue_loader.gd` now has a generation counter. A line that is mid-wait when you restart is dropped instead of spoken in the new attempt.
- **Debug key F11:** it fires `BURNER_PICKED_UP`, inside the existing `debug_keys` gate. Without it, leaving the Saltgate never reaches RETURN until the pickup task (T06) exists.
- **Test:** I added one check to `test_game_state.gd` for the restart fix.

**Not done:**
- **Bookkeeping:** I did not touch `GoalOrientedAgent/BACKLOG.md` or `HANDOFF.md`. They sit outside my write area, and BACKLOG says it is generated from `state/backlog.json`. Marking T01 done and correcting the stale "no [autoload]" evidence needs to happen there.
- **`test_boat.gd`:** it exits 0 but ends with `TIMEOUT in step 10`, and its outbound leg re-docks at the lighthouse instead of reaching the Saltgate. So it does not currently prove docking works end to end.

**Files changed:**
- LightingTheStorm/scripts/dialogue/dialogue_loader.gd
- LightingTheStorm/scripts/core/game_state.gd
- LightingTheStorm/tools/test_game_state.gd
- LightingTheStorm/things to work on next.md
- LightingTheStorm/HANDOFF_T01_GameState.md

**Verified:**
- Read game_state.gd, dialogue_loader.gd, test_game_state.gd and the OPENING_EVENTS list in AIAgentCrew/canon.py. The phase order and event IDs match, and the four proposed IDs are the only additions.
- Ran `test_game_state.gd` headless on Godot 4.3 before and after my edits. Both runs print `RESULT: OK (0 failed)` with exit code 0, and the second has one extra PASS line.
- Ran `test_boat.gd` headless. The handling and hazard-recovery checks pass, but the crossing part times out in step 10. `git diff` shows the only uncommitted boat.gd change is the `add_to_group("boat")` line, so GameState is not the cause. I did not find the actual cause.
- Checked Level.tscn lines 95-150. The lighthouse dock zones use the default DOCK_LIGHTHOUSE and DockZonePort sets DOCK_PORT. I also checked that lighting_rig.gd has `follow_boat_signals = false`.
- Confirmed by `git diff` that project.godot's [autoload] section and boat.gd's group line are uncommitted working-copy changes.

**Creator still needs to check:**
- Open the project in Godot 4.3. Under Project Settings > Autoload, confirm Dialogue and GameState are listed, with no script errors in the Output panel.
- Run Level.tscn. Confirm the console shows `[GameState] #1 GAME_STARTED` and Ted's TED_S1_01 line. Press F10 to see the event log.
- Cast off from the lighthouse and dock at the Saltgate. Confirm BOAT_CAST_OFF is logged once and the phase goes to OUTBOUND. Then confirm SALTGATE_REACHED on docking.
- At the Saltgate, press F11, then cast off. Confirm RETURN_DEPARTED fires and the lighting changes to RETURN.
- Press F9 and confirm the level reloads cleanly. The player should be outside, the boat at the lighthouse dock, the mouse and camera working, the attempt counter up, and Ted's greeting played again. Press F9 while a line is still playing to check the stale line does not appear.
- Accept or rename the four proposed event IDs (RETURN_ARRIVED, BURNER_FITTED, SHIP_WIN, SHIP_FAIL) and the phase boundaries listed in HANDOFF_T01_GameState.md section 7.
- Decide whether to repair `tools/test_boat.gd` now (see the open issue below).

**Open issues:**
- `tools/test_boat.gd` finishes with `TIMEOUT in step 10 ... hits=150` yet exits 0, because it does not fail on a timeout. In step 8 the boat re-docks at DOCK_LIGHTHOUSE after 23 s instead of reaching DOCK_PORT, and the return leg then keeps hitting something near (-31.9, 0.7, 21). It is not caused by GameState. My unverified guess is that it predates the two-berth harbour (two zones share the id DOCK_LIGHTHOUSE and boat.gd skips zones by id when leaving).
- BACKLOG.md and HANDOFF.md under GoalOrientedAgent were not updated (outside my write area; BACKLOG.md is generated from state/backlog.json). T01 still reads 'open' with stale evidence 'project.godot has no [autoload]', and R10 and R15 cite the same stale claim.
- The event log records each event under the phase it had before that event's own phase change (BOILER_FED is logged under ARRIVAL_AND_COAL). This is how it is written; it could mislead QA readers.
- The restart path through `reload_current_scene()` and the stale-line timing fix are not play-tested (no editor access).

**Diff summary:**
```
modified  LightingTheStorm/scripts/dialogue/dialogue_loader.gd  (+8 -0)
modified  LightingTheStorm/scripts/core/game_state.gd  (+5 -1)
modified  LightingTheStorm/tools/test_game_state.gd  (+1 -0)
created   LightingTheStorm/HANDOFF_T01_GameState.md  (+91 -0)
created   LightingTheStorm/things to work on next.md.tmp_check  (+0 -0)
modified  LightingTheStorm/things to work on next.md  (+3 -4)
```
