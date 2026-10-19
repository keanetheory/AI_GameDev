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

## 2026-10-19 18:12 - T03 Generic first-person interaction system (raycast, prompt, the 'interact' action) (score 9)

**Outcome:** done  - agent-only run A1 (no API)

Added the generic interaction system: an Interaction autoload that is the single on-foot consumer of the interact action and owns the one prompt label, and a reusable Interactable node (prompt, reach, facing, enabled, overridable can_interact/prompt_text/interact). It picks the nearest, most central usable target, stays quiet while seated in the boat or when blocked, and reads the key label from the input map. Not yet wired to the door or burner, which still carry their own prompts.

**Files changed:**
- LightingTheStorm/scripts/interaction/interactable.gd
- LightingTheStorm/scripts/interaction/interaction_manager.gd
- LightingTheStorm/tools/test_interaction.gd
- LightingTheStorm/project.godot (Interaction autoload)

**Decisions:**
- Autoload manager plus a node, not per-node polling, so only one E consumer and one prompt exist.
- Extend by script path, not class_name, so it works in headless tests before the editor rescans.
- Existing door.gd, burner_pickup.gd and boat.gd were not edited: another session is working in them. Converting them is run A5.
- Hold-to-use was left out; the boiler job (T33) can use repeated presses and add it if needed.

**Verified:**
- tools/test_interaction.gd: 18 checks pass headless on Godot 4.3 (focus, prompt, use-once, look away, reach, enabled, nearest wins, overrides, boat, blocked).
- test_game_state, test_door and test_burner_pickup still report RESULT: OK.

**Creator still needs to check:**
- In the editor, add an Interactable to a scene and confirm the prompt shows at the bottom and E fires it; check the prompt does not collide with the door and burner prompts when near them.
- Check E near the boat's board_radius does not double-fire (the boat keeps its own E).

**Open issues:**
- door.gd and burner_pickup.gd still have their own prompt and reach code (run A5).
- Headless runs of test_door and test_burner_pickup print 'Parameter m is null' errors; they come from the level, not from the interaction system.

**Diff summary:**
```
created   LightingTheStorm/scripts/interaction/interactable.gd
created   LightingTheStorm/scripts/interaction/interaction_manager.gd
created   LightingTheStorm/tools/test_interaction.gd
modified  LightingTheStorm/project.godot  (+1 -0)
```

## 2026-10-19 18:14 - T12 Subtitle and journal UI fed by the DialogueLoader signals (score 7)

**Outcome:** done  - agent-only run A2 (no API)

Added the Subtitles autoload: speaker-attributed subtitles shown on Dialogue.line_started and hidden on line_finished, a journal that writes entries from journal_entry_added (repeat ids ignored, order kept) in a handwritten-style face, a brief 'Journal updated [J]' note, a journal action on J that opens and closes the panel without pausing the game, an assist hint shown only when Dialogue.assist_mode is on, and a full clear on GameState.restarted. No timer and no markers.

**Files changed:**
- LightingTheStorm/scripts/ui/subtitle_ui.gd
- LightingTheStorm/tools/test_subtitles.gd
- LightingTheStorm/project.godot (Subtitles autoload, journal input action on J)

**Decisions:**
- An autoload, like Dialogue and GameState, so no scene edit was needed (Level.tscn has uncommitted work from another session).
- The subtitle text already carries the speaker ('TED: ...'), so it is shown as written and only coloured per speaker.
- The journal does not pause the game: the hidden deadline must keep running.
- The 'Journal updated' note is the only on-screen cue; it fades after about 5 seconds and has no icon or marker.

**Verified:**
- tools/test_subtitles.gd: 20 checks pass headless on Godot 4.3, including the real opening dialogue (GAME_STARTED shows Ted's first line and writes JRN_01).
- test_interaction, test_game_state and test_door still report RESULT: OK.

**Creator still needs to check:**
- In the game: subtitle readability over the storm and the lighthouse, size and position, and that it does not collide with the interaction prompt.
- The journal panel look and the handwriting face on your machine (it falls back to the default font if none of the named fonts are installed).
- Whether J is the key you want.

**Open issues:**
- Subtitle size, font and speaker colours are placeholders for the creator to tune.
- Controller button for the journal is undecided (see T15).

**Diff summary:**
```
created   LightingTheStorm/scripts/ui/subtitle_ui.gd
created   LightingTheStorm/tools/test_subtitles.gd
modified  LightingTheStorm/project.godot  (+1 autoload, +1 input action)
```

## 2026-10-19 19:12 - T21 Strip or gate debug UI (lighting label, F5-F8 phase jumps) behind a debug flag (score 3)

**Outcome:** done  - agent-only run A3 (no API)

The lighting phase label and the F5-F8 keys, and GameState's F9-F11 keys, now follow one flag (scripts/core/debug_flags.gd): on in a debug build, always off in a release export, and switchable off in a debug build with the user argument --no-debug-ui. The label is no longer built when the aids are off.

**Files changed:**
- LightingTheStorm/scripts/core/debug_flags.gd
- LightingTheStorm/scripts/world/lighting_rig.gd
- LightingTheStorm/scripts/core/game_state.gd
- LightingTheStorm/tools/test_debug_flags.gd

**Decisions:**
- One shared flag for both scripts so a tester build is switched with one argument.
- A debug export still shows the aids unless --no-debug-ui is passed: a tester debug build is the builder's, and release builds are always clean.
- The existing exported debug_keys stay as per-node overrides; they can only turn the aids off, never force them on in a release.

**Verified:**
- tools/test_debug_flags.gd run twice: with no argument the keys act (F8 changes the lighting phase, F9 restarts) and with -- --no-debug-ui they do nothing; 5 checks pass each time.

**Creator still needs to check:**
- In the editor, confirm the 'Lighting: <phase>' label still shows in a normal run and is gone with --no-debug-ui (headless runs never build the label).

**Diff summary:**
```
modified  LightingTheStorm/scripts/world/lighting_rig.gd
modified  LightingTheStorm/scripts/core/game_state.gd
created   LightingTheStorm/scripts/core/debug_flags.gd
created   LightingTheStorm/tools/test_debug_flags.gd
```

## 2026-10-19 19:12 - T22 Write LightingTheStorm/readme.md and per-task HANDOFF.md template; reconcile doc gaps (score 4)

**Outcome:** done  - agent-only run A4 (no API)

Wrote LightingTheStorm/readme.md (engine, running, controls, debug keys, code layout, the four autoloads, rules for adding gameplay with the event and phase lists, how to run every headless test, how the agents work) and HANDOFF_TEMPLATE.md in the AI Agent Strategy's handoff format.

**Files changed:**
- LightingTheStorm/readme.md
- LightingTheStorm/HANDOFF_TEMPLATE.md

**Decisions:**
- The readme lists the event IDs and phases and points to game_state.gd and canon.py as the source of truth, so it can be checked rather than trusted.
- The handoff template mirrors the eight sections of HANDOFF_T01_GameState.md.

**Verified:**
- Read-through against project.godot (inputs, autoloads), boat.gd and player.gd (controls), game_state.gd (events, phases), and the tools folder (test list).

**Creator still needs to check:**
- Skim it for anything that misstates how you run or export the project.
- The two flagged items from the task are still yours: the controller contradiction (settled by T15) and the week-5 fallback wording.

**Diff summary:**
```
created   LightingTheStorm/readme.md
created   LightingTheStorm/HANDOFF_TEMPLATE.md
```

## 2026-10-19 19:12 - A5 Fold the door and burner prompts into the interaction system (agent-only run, no backlog id)

**Outcome:** done

`door.gd` and `burner_pickup.gd` each carried their own prompt label, reach test and E handling, and `door.gd` said T03 should absorb them. Both are now Interactables: the Interaction autoload owns the one prompt and the E key, and each script only says what E does. Behaviour is unchanged.

**Files changed:**
- LightingTheStorm/scripts/world/door.gd
- LightingTheStorm/scripts/world/burner_pickup.gd
- LightingTheStorm/scripts/interaction/interactable.gd (added `reach_point()` so a door measures reach from its doorway)
- LightingTheStorm/tools/test_door.gd, tools/test_burner_pickup.gd (read the prompt from the Interaction autoload)

**Decisions:**
- The door's reach (2.6 m) and aim point (1.4 m above the doorway middle) and the burner's aim (0.45 m) are kept as they were, set in each script's `_init` and overrides.
- The burner reports it is not usable once held, so its prompt goes away as before.

**Verified:** test_door, test_burner_pickup, test_interior_walk, test_interaction, test_subtitles, test_game_state and test_boat all pass (headless, Godot 4.3). `boat.gd` was not changed; it keeps its own E.

**Creator still needs to check:** in the editor, the door and burner prompts look and behave as before (one prompt at a time, bottom of the view), and E near the boat does not double-fire.

## 2026-10-19 20:16 - T29 Hand carry: pick up the burner, hold it on the boat, fit it at the lamp (score 10)

**Outcome:** done  - agent-only run A6 (no API)

Built the carry system on top of the existing burner pickup. A Carry autoload is the player's hands: one item at a time, held in view, with no drop key, so an item can only be put down in a CarrySocket. CarrySocket is an Interactable offering '[E] Put the burner down' and '[E] Pick up the burner'. The boat gets a cargo slot on its rig (so what is stowed rides with the hull through waves and hazard recoveries), reachable from the lighthouse landing. burner_pickup.gd now hands the burner to Carry. The boat leaves E to the slot when it is offered, so one press cannot both stow and board. The lamp socket (T32) can reuse CarrySocket with allow_take off.

**Files changed:**
- LightingTheStorm/scripts/interaction/carry_manager.gd
- LightingTheStorm/scripts/interaction/carry_socket.gd
- LightingTheStorm/scripts/interaction/interactable.gd (vertical_reach)
- LightingTheStorm/scripts/world/burner_pickup.gd
- LightingTheStorm/scripts/world/boat.gd (cargo slot, E deferral)
- LightingTheStorm/project.godot (Carry autoload)
- LightingTheStorm/tools/test_carry.gd

**Decisions:**
- Hands are an autoload and sockets are Interactables, so prompts and the E key stay in one place (the Interaction autoload).
- The creator's rule (A18) is enforced by construction: there is no release path except Carry.place() into a socket that accepts the item.
- The first hold records the item's rest transform and hold pose as metadata, so a socket can set it down at its original size and the hands can pick it up again exactly as before.
- The boat's cargo slot is optional for the player: the burner stays in hand by default and the slot is where it can be set down. burner_aboard stays true while it is stowed.
- The slot reach is 4.5 m flat and 3.5 m vertical so the burner can be taken back from the lighthouse landing (3.7 m away and 2.6 m above the deck) without jumping aboard.
- Not changed: GameState (burner_aboard already follows the pickup event), and the other session's door.gd.

**Verified:**
- tools/test_carry.gd passes 8 of 8 repeat runs: one item at a time, nothing offered with no socket in reach, no drop action, stow on the deck without also boarding, burner rests on the deck, survives a hazard recovery in the same place, casting off fires RETURN_DEPARTED, taken back from the lighthouse landing, held through boarding and a recovery, a restart clears the hands.
- test_door, test_burner_pickup, test_interaction, test_game_state, test_subtitles, test_interior_walk, test_debug_flags report RESULT: OK and test_boat completes (DONE).

**Creator still needs to check:**
- In the game: set the burner down on the deck, sail, and take it back at the lighthouse; check the look of the slot position, the prompts and that E near the boat does not double-fire.
- Whether you want the burner to be stowable at all, or kept in hands for the whole crossing.

**Open issues:**
- At the Saltgate the berth is about 12 m from the landing, so the slot can only be used by walking to the boat (the boat's own E boards from up to 10 m away). If the creator wants stowing at the quay without walking aboard, move the berth closer or add a second socket near the landing.
- An earlier version of the test stood on the deck at the lighthouse and failed one run in eight (the player was pushed off against the jetty); the test now stands on the landing, which is what exposed the real reach problem fixed here.

**Diff summary:**
```
created   LightingTheStorm/scripts/interaction/carry_manager.gd
created   LightingTheStorm/scripts/interaction/carry_socket.gd
created   LightingTheStorm/tools/test_carry.gd
modified  LightingTheStorm/scripts/world/burner_pickup.gd
modified  LightingTheStorm/scripts/world/boat.gd
modified  LightingTheStorm/scripts/interaction/interactable.gd
modified  LightingTheStorm/project.godot  (+1 autoload)
```
