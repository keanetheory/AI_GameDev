# Handoff for further work

_Written 2026-10-19 14:05. Closed because: the creator said the requirements are met._

**Goal:** Bring LightingTheStorm to the state the GDD (Exec Summary, Technical Strategy, AI Agent Strategy) describes for the Gate 1 vertical slice, consistent with the concept art and the AI crew briefs, or document precisely what remains so work can resume later.

**Progress:** 26% (1 met, 9 partial, 11 unmet of 21 requirements)

**Session log:** `logs/session_20261019_140415.md`

## Done this project

- nothing yet

## Outstanding, in the order to do them

| ID | Score | Task | Category | Owner role | Effort | Status |
|---|---|---|---|---|---|---|
| T01 | **10** | Create the central GameState autoload: phase machine, event bus, restart | code | Gameplay / Systems agent | M | open |
| T02 | **10** | Greybox lighthouse interior route: door, hall, basement, tower stairs, lantern room | scene | Level Layout agent | L | open |
| T06 | **10** | Burner pickup at the Saltgate, boat cargo, and the return-departure clock trigger | code | Gameplay / Systems agent | M | open |
| T07 | **10** | Hidden ship deadline with ship placeholder, elapsed-time lighting and debug time scale | code | Gameplay / Systems agent | M | open |
| T08 | **10** | Win and fail outcomes: final burner fit, foghorn, grounding, silence, 'Failed' screen with reason, restart | code | Story / Fail-State agent | L | open |
| T03 | **9** | Generic first-person interaction system and the boiler coal job | code | Gameplay / Systems agent | M | open |
| T04 | **9** | Window moment, moored rowboat, island gate and sailors' scripted walk-in | scene | Level Layout agent | L | open |
| T05 | **9** | Lantern room diagnosis: Ted opens the arc lamp and finds the burner broken | code | Gameplay / Systems agent | M | open |
| T09 | **8** | Decide the fail reason line, deliverer and audio-only fail alternative | decision | Canon and Review Orchestrator | S | open |
| T10 | **8** | Integrate the crossing crew's hazard forecast: data file, loader, placed buoys/debris, Arthur calls | code | Hazard Forecast agent | M | open |
| T11 | **7** | Put Arthur aboard and add the arrival 'go go go' beat on the lighthouse dock | code | Gameplay / Systems agent | M | open |
| T12 | **7** | Subtitle and journal UI fed by the DialogueLoader signals | code | Dialogue agent | M | open |
| T13 | **7** | Drive perceptual storm cues from elapsed deadline time and trigger BEACON_RELIT | code | Lighting agent | M | open |
| T16 | **7** | Lock Ted's presence and final lamp-room line list | decision | Canon and Review Orchestrator | S | open |
| T14 | **6** | Placeholder audio: wind, rain, machinery, buoy bell, foghorn, ship impact, mix by phase | audio | Sound agent | M | open |
| T15 | **6** | Decide whether the prototype needs controller support, then add bindings and prompts | decision | Player Movement agent | M | open |
| T17 | **6** | Tune and record the Gate 0 steering go/no-go (speed, route length, time per crossing) | test | Boat / Physics agent | M | open |
| T19 | **5** | Set a placeholder deadline length and write the crossing-penalty values | decision | Production Orchestrator | S | open |
| T20 | **5** | QA scenario list and automated state-transition checks for the Gate 1 slice | test | QA agent | M | open |
| T18 | **4** | Review the rewritten opening lines and re-record the six changed voice lines | dialogue | Dialogue agent | M | open |
| T22 | **4** | Write LightingTheStorm/readme.md and per-task HANDOFF.md template; reconcile doc gaps | doc | Production Orchestrator | S | open |
| T21 | **3** | Strip or gate debug UI (lighting label, F5-F8 phase jumps) behind a debug flag | code | Lighting agent | S | open |
| T23 | **3** | Bake mainland/cliff carving and collision to cut level load time | code | Level Layout agent | L | open |

### T01 [10/10] Create the central GameState autoload: phase machine, event bus, restart
Add a GameState autoload (register in project.godot) holding the phase enum (ARRIVAL_AND_COAL → … → RESOLUTION), an emit_event(event_id) bus with a debug event log, and a restart() that reloads the slice. Add the DialogueLoader as a child or autoload, and connect GameState events to DialogueLoader.trigger(), the lighting rig's set_phase() and the boat's signals. Every other Gate 1 task hangs off this contract.


### T02 [10/10] Greybox lighthouse interior route: door, hall, basement, tower stairs, lantern room
The Lighthouse node is an exterior glb only. Build a greybox interior following ConceptArt/narrative_blueprints (entry hall, basement boiler room, stairs, lantern room), the entrance door, a window with a view of the dock and rowboat, and a lamp room window with a clear sightline to the ship route and island rocks. Player start moves outside the door, and interaction anchors are added for the other tasks.
- Blocked by: Needs the Godot editor to place and walk-test the interior and sightlines; the Ted-lock decision affects how Ted is staged.
- Needs the creator, not just the agent


### T06 [10/10] Burner pickup at the Saltgate, boat cargo, and the return-departure clock trigger
Add a burner pickup at the Saltgate quays (Assets/Models/saltgate), carried as cargo aboard the boat and never lost on a hit. Casting off from DOCK_PORT with the burner aboard emits RETURN_DEPARTED, which starts the single hidden deadline once. Change lighting_rig.gd so RETURN depends on the burner event, not just any departure from DOCK_PORT.
- Blocked by: Depends on GameState.


### T07 [10/10] Hidden ship deadline with ship placeholder, elapsed-time lighting and debug time scale
Implement a numeric internal deadline timer (no UI), pausing in menus, with a placeholder ship whose lights hold at the horizon until the clock starts and then approach. Expose a debug time scale and event log. The value is a placeholder constant until playtests set it.
- Blocked by: Depends on GameState and the burner/return trigger. The final deadline length is a creator decision (B4), so use a labelled placeholder.


### T08 [10/10] Win and fail outcomes: final burner fit, foghorn, grounding, silence, 'Failed' screen with reason, restart
Add the burner-fit interaction at the lamp (Ted waiting there, BEACON_RELIT), then resolve WIN or FAIL exactly once. FAIL plays foghorn, ship grounding, silence and a title screen with a reason line, and restarts the slice; the three expiry locations (crossing, lamp room, stairs) get their audio-only or sightline presentation, with a visual or subtitle alternative.
- Blocked by: The fail reason line wording and who delivers it (B3) and the audio-only accessibility alternative (B8) are open creator decisions; the lamp room sightline needs editor checks.
- Needs the creator, not just the agent


### T03 [9/10] Generic first-person interaction system and the boiler coal job
Add a raycast/Area-based interactable (using the existing 'interact' action) with a short prompt, then the boiler interaction: pick up and shovel coal until the gauge climbs, emitting BOILER_FED and starting the dynamo hum/effect. Prompts must be diegetic text, not quest markers.
- Blocked by: Depends on the GameState task and the interior greybox.


### T04 [9/10] Window moment, moored rowboat, island gate and sailors' scripted walk-in
Add a distinct rowboat at the island dock visible from the window, trigger the SAILORS_MOORED window moment with a short-delay fallback, make the existing island gate (1-gate.glb) a single interaction, and script Arthur and Daniel walking to the lighthouse and Daniel to the basement (DANIEL_IN_BASEMENT). Needs placeholder Arthur and Daniel meshes.
- Blocked by: Needs the editor to place the rowboat, gate and NPC paths; greybox Arthur and Daniel and the rowboat do not exist yet.
- Needs the creator, not just the agent


### T05 [9/10] Lantern room diagnosis: Ted opens the arc lamp and finds the burner broken
Implement the BEACON_DIAGNOSIS trigger that fires only after DANIEL_IN_BASEMENT, with Ted leading the player to the lantern room, the arc lamp opening, BURNER_DIAGNOSED and BURNER_BRIEFING opening the way to the boat. Reuse the dialogue lines in dialogue_opening.json.
- Blocked by: Depends on GameState, the interior and Ted being in the scene.


### T09 [8/10] Decide the fail reason line, deliverer and audio-only fail alternative
The creator must choose the wording of the short line shown on 'Failed' and who delivers it (Ted, Arthur or the journal), and what subtitle or visual alternative replaces the audio-only fail cue on the crossing and the stairs. Agents must not choose these.
- Blocked by: Creator decision.
- Needs the creator, not just the agent


### T10 [8/10] Integrate the crossing crew's hazard forecast: data file, loader, placed buoys/debris, Arthur calls
Copy return_crossing.json into LightingTheStorm/data, add crossing_loader.gd to the scene with a route-position feed from the boat, spawn hazards (rocks, buoys, debris) from it, and play Arthur's calls as subtitles from the same safe-lane signal. Add an equivalent, easier outbound forecast. Do not add waves or branching.
- Blocked by: Best done after Arthur is in the boat; steering feel play check needed.


### T11 [7/10] Put Arthur aboard and add the arrival 'go go go' beat on the lighthouse dock
Seat Arthur on the engine boat as the only companion, fire BOARDING_THRESHOLD (Ted introduces the ship) and the SALTGATE_REACHED and arrival events from dock-zone arrival. Plays his line on return arrival, then he leaves the player to climb.
- Blocked by: Depends on GameState and the crossing integration.


### T12 [7/10] Subtitle and journal UI fed by the DialogueLoader signals
Add a CanvasLayer showing speaker-attributed subtitles from line_started and a handwritten-style journal reading journal_entry_added. No quest markers and no timer; the assist hint stays off by default.


### T13 [7/10] Drive perceptual storm cues from elapsed deadline time and trigger BEACON_RELIT
In lighting_rig.gd, add a blend by normalised elapsed deadline time for rain, lightning, wind audio and ship lights while keeping hazard density and visibility on route position. Add the BEACON_RELIT trigger and a beam sweep.
- Blocked by: Depends on the deadline task.


### T16 [7/10] Lock Ted's presence and final lamp-room line list
Confirm Ted is present and speaks live and settle which lamp-room lines to record, since every line is voice-over cost. The GDD requires this by the end of week 3. Dialogue and staging work for the lantern room depends on it.
- Blocked by: Creator decision.
- Needs the creator, not just the agent


### T14 [6/10] Placeholder audio: wind, rain, machinery, buoy bell, foghorn, ship impact, mix by phase
Add placeholder audio buses and AudioStreamPlayers for wind, rain, boiler/dynamo, buoy bells, foghorn and impact, mixed by phase and with Arthur's calls kept audible. Record source and licence per file and wire the six re-recorded voice lines later.
- Blocked by: Needs audio source files and licences; sound choices need creator ears.
- Needs the creator, not just the agent


### T15 [6/10] Decide whether the prototype needs controller support, then add bindings and prompts
Technical Strategy Gate 1 requires keyboard and controller but the Exec Summary puts controller in the full game (B14). The creator should settle this. If yes, add joypad bindings (steer, interact, look), a gamepad look in player.gd and prompt glyphs in the boat label.
- Blocked by: Creator decision B14, then a controller test in the editor.
- Needs the creator, not just the agent


### T17 [6/10] Tune and record the Gate 0 steering go/no-go (speed, route length, time per crossing)
Level.tscn overrides the boat's speed to 10.0 m/s while boat_spec.json says 3.0, and the route is about 500 m. Play both crossings, record crossing times against the 10-minute target, tune speed, steering and recovery as data, and write the go/no-go for the creator.
- Blocked by: Needs a human playtest in the Godot editor.
- Needs the creator, not just the agent


### T19 [5/10] Set a placeholder deadline length and write the crossing-penalty values
The deadline length and exact collision costs are deliberately undecided until the return crossing is tested. Record a clearly labelled placeholder deadline, the outbound-crossing penalty (B9, deferred) and the collision cost so the QA tuning pass has numbers to compare against.
- Blocked by: Creator decision after the crossing is playable.
- Needs the creator, not just the agent


### T20 [5/10] QA scenario list and automated state-transition checks for the Gate 1 slice
Write a reproducible scenario list covering each phase transition, the clock starting once, the exactly-once outcome, restart, each fail expiry location and a keyboard/controller pass. Add headless GDScript checks beside the existing tools/test_boat.gd where practical.
- Blocked by: Depends on the GameState task.


### T18 [4/10] Review the rewritten opening lines and re-record the six changed voice lines
Run TED_S1_01, S1_09, S1_10, S1_11, S3_02, ARTHUR_S3_04 and the new TED_S3_00 through Dialogue and Canon review and the creator's sign-off, record the outcome in DIALOGUE_OPENING_CREATOR_PICKS.md, then regenerate audio (dry run first). Add the playback hook to the game later.
- Blocked by: Creator sign-off on voice and lore; ElevenLabs credits for regeneration.
- Needs the creator, not just the agent


### T22 [4/10] Write LightingTheStorm/readme.md and per-task HANDOFF.md template; reconcile doc gaps
The game readme is empty. Document engine version (4.3 Forward Plus per project.godot), how to run, controls, event IDs, scene ownership and a HANDOFF.md template. Also flag the controller contradiction (Tech Strategy vs Exec Summary) and the unconfirmed week-5 fallback wording (item 6) for the creator.


### T21 [3/10] Strip or gate debug UI (lighting label, F5-F8 phase jumps) behind a debug flag
lighting_rig.gd shows an on-screen 'Lighting: <phase>' label and lets F5-F8 jump phases. Hide these unless a debug setting is on, so they cannot be mistaken for a HUD in tester builds.


### T23 [3/10] Bake mainland/cliff carving and collision to cut level load time
mainland.gd and collider_builder.gd carve about 22,000 triangles, build trees and collision at every load (about 10 s headless). Bake the carved meshes, height table and collision as resources and keep builders editor-only.
- Blocked by: Needs the Godot editor to bake and verify.
- Needs the creator, not just the agent


## Deferred or skipped (with the creator's note)

- T24 Fix walkway rock-wall teeth and brighten the dark walkway (deferred): low value until lighting pass

## Requirements not yet met

- R01 (unmet) Slice starts with the player outside the lighthouse; Ted opens the door ('You're the new guy, then') and the player enters (GAME_STARTED, LIGHTHOUSE_ENTERED). - LightingTheStorm/scenes/Level.tscn has no door, no Ted node and no trigger areas; the Lighthouse node is only the exterior glb (lighthouse_exterior_v3.glb). Assets/Characters/ted.glb exists but is not instanced in Level.tscn. 'things to work on next.md' item 7 confirms.
- R02 (unmet) Player feeds the boiler with coal in the basement (first hands-on job); steam comes up and the dynamo runs (BOILER_FED). - No boiler, basement or interaction code in LightingTheStorm/scripts or Level.tscn. The 'interact' action exists in project.godot but only boat.gd reads it; the Lighthouse has no interior.
- R03 (unmet) Ted at the window shows the sailors' rowboat moored at the dock; the player opens the island gate; Arthur and Daniel walk in on a scripted path and Daniel stays in the basement. The rowboat is visibly distinct from the engine boat. - Assets/Island/environment/1-gate.glb exists as a model, but there is no gate interaction, no rowboat model (Assets/Models/boat has only boat_launch.glb), and no Arthur/Daniel models or NPC scripts.
- R04 (unmet) Beacon diagnosis only after the sailors are in: the dynamo runs, the beacon stays dark, Ted takes the player to the lantern room, opens the arc lamp and finds the burner broken (BEACON_STILL_DARK, LAMP_ROOM_ENTERED, BURNER_DIAGNOSED). - No lantern room or lamp in the scene. data/dialogue/dialogue_opening.json has the lines (TED_S3_00 on BEACON_STILL_DARK etc.), but nothing fires these events.
- R05 (partial) Boarding: player meets Arthur at the engine boat; at the boarding threshold Ted names the ship and the ship appears on the horizon; no deadline yet. - boat.gd lets the player board with E and cast off (board(), cast_off()), but there is no Arthur aboard, no BOARDING_THRESHOLD/SHIP_SIGHTED event and no ship object anywhere in Level.tscn.
- R07 (partial) Hazards (rocks, reefs, buoys, debris) are readable, with a shared hazard forecast and a single safe-route signal that Arthur's calls read from. - Level.tscn has SeaStack1-11, cliffs and headlands as static hazards (layer 2). No buoys or debris. AIAgentCrew/output/return_crossing.json and AIAgentCrew/godot/crossing_loader.gd exist but there is no LightingTheStorm/data/return_crossing.json and nothing in the game uses the loader (grep for 'return_crossing' in LightingTheStorm: no matches).
- R08 (partial) Outbound crossing to the Saltgate quays and return crossing to the lighthouse are playable end to end, with harder return hazards. - The geometry exists: DockZoneLighthouse at about z=18, DockZonePort at z=527, Saltgate quay models. The boat can sail between them. No separate return hazard density or route-position difficulty, and the full slice cannot be completed because the surrounding beats are missing.
- R09 (unmet) Player finds and picks up the replacement burner at the Saltgate; it is carried aboard and can never be permanently lost (BURNER_PICKED_UP). - No burner object, pickup or cargo state in any script. lighting_rig.gd line 131 sets RETURN on any departure from DOCK_PORT with the comment 'means the burner is aboard'.
- R10 (unmet) The only timer is a hidden numeric ship deadline that starts once on RETURN_DEPARTED (burner aboard), is inactive before then, stops in menus, and has a debug time scale and event log. - grep for deadline/ship/fail in LightingTheStorm/scripts returns no implementation. No game state autoload exists in project.godot.
- R11 (partial) Storm split: sound, rain, lightning, wind and ship lights follow elapsed deadline time; hazard density and visibility follow phase and route position only. - lighting_rig.gd has phases ISLAND/OUTBOUND/RETURN/BEACON_RELIT driven by boat departed signals, with F5-F8 debug jumps. There is no elapsed-time driver and no hazard-density channel; BEACON_RELIT has no trigger.
- R12 (unmet) Final repair: player climbs to the lamp, Ted waits there, and the player fits the burner to the beacon (final hands-on job); Arthur says 'go go go, don't wait for me' on arrival. - No lamp, no burner-fit interaction, no arrival trigger on the lighthouse dock zone. Arrival line exists only as crew data (AIAgentCrew/output/return_crossing.json).
- R13 (unmet) Win and fail outcomes resolve exactly once per attempt: win = ship sails safely into port; fail = foghorn, ship runs aground, silence, 'Failed' title screen with a reason line. The lamp room has a clear sightline; no cutaway camera. - No ship, no outcome code, no title/fail screen, no audio nodes (grep for AudioStreamPlayer in LightingTheStorm *.gd/*.tscn: none). The lighthouse has no lamp room.
- R14 (partial) After a fail the player can restart the slice from its start. - Only dialogue_loader.gd reset_for_restart() and crossing_loader.gd reset_for_restart() stubs exist. No scene reload or global reset and no caller.
- R15 (unmet) Explicit phase state machine (ARRIVAL_AND_COAL through RESOLUTION) with stable event IDs; every transition has a single owner; audio, UI and dialogue respond to events and never drive progression. - The only event consumer is scripts/dialogue/dialogue_loader.gd (trigger(event_id)), which is not in Level.tscn, and no code emits the event IDs. 'things to work on next.md' item 7 lists the unwired IDs.
- R16 (partial) Guidance comes from Ted and Arthur by voice/subtitle and a handwritten objective journal, with no markers or visible timer; apprentice never speaks; spoken navigation cues have subtitles with speaker attribution. - dialogue_loader.gd emits line_started/journal_entry_added with subtitle text and speaker, but there is no subtitle or journal UI and no audio playback ('the game does not play line audio yet', things to work on next.md item 4). No timer or markers exist, which satisfies the negative rule by absence.
- R17 (unmet) The slice is playable on keyboard and controller, with controller prompts. - project.godot [input] has only InputEventKey bindings; player.gd uses mouse-motion look only; boat prompts are hard-coded '[E]', '[A] / [D]'.
- R18 (unmet) Placeholder audio: layered wind and rain, machinery, buoy bells, foghorn, ship impact; states mixed by phase; no shock stingers. - No AudioStreamPlayer in scenes or scripts; no audio files under LightingTheStorm/Assets.
- R19 (partial) Warm lamplight against blue-grey storm light; the beam is a navigational anchor from the sea; beacon and hazards stay legible in every phase; greybox art is acceptable. - lighting_rig.gd (532 lines) builds sky, rain, lightning and lit windows per phase from data/world/lighting_spec.json. No working beacon beam because there is no lamp; 'things to work on next.md' item 2 reports the walkway as nearly black; legibility of hazards in each phase not verified in-engine.
- R20 (partial) Scope and hard rules are respected: first-person only, no combat/jump scares/visible timer/markers, one lighthouse + one sea + the Saltgate, no waves, no branching, no added significant Saltgate detail. - No violating features found in scripts. A debug label 'Lighting: <phase>' (lighting_rig.gd _build_label) and F5-F8 phase hotkeys are on-screen debug UI that must not ship. Mainland.gd builds a large generated mainland with about 2,600 trees and a walkway, which is beyond a 'minimal' Saltgate; not verified against the creator's intent.
- R21 (partial) Each agent task ends with a HANDOFF.md; game data uses JSON/.tres with stable IDs; the project documents engine version and conventions. - AIAgentCrew produces HANDOFF.md/REPORT.md and JSON data (world_output/, output/). LightingTheStorm/readme.md is empty (0 B). project.godot pins 4.3 Forward Plus. The game folder has no task HANDOFF.md files; the crew's boat_spec/lighting_spec are copied into data/world but only lighting_spec is consumed.

To resume: `python main.py` (it reloads `state/backlog.json`; `rescan` re-analyses against the current files).
