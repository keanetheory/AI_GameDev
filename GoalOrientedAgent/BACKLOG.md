# Backlog

_Generated 2026-10-19 16:24 by the Goal-Oriented Agent. Do not edit by hand; the source of truth is `state/backlog.json`._

**Goal:** Bring LightingTheStorm to the state the GDD (Exec Summary, Technical Strategy, AI Agent Strategy) describes for the Gate 1 vertical slice, consistent with the concept art and the AI crew briefs, or document precisely what remains so work can resume later.

**Goal progress:** 33% (2 met, 10 partial, 9 unmet of 21 requirements)

## Requirements

| ID | Status | Requirement | Source | Evidence |
|---|---|---|---|---|
| R01 | UNMET | Slice starts with the player outside the lighthouse; Ted opens the door ('You're the new guy, then') and the player enters (GAME_STARTED, LIGHTHOUSE_ENTERED). | Exec Summary, Story and gameplay sequence step 1; Technical Strategy Gate 1 and state contract | LightingTheStorm/scenes/Level.tscn has no door, no Ted node and no trigger areas; the Lighthouse node is only the exterior glb (lighthouse_exterior_v3.glb). Assets/Characters/ted.glb exists but is not instanced in Level.tscn. 'things to work on next.md' item 7 confirms. |
| R02 | UNMET | Player feeds the boiler with coal in the basement (first hands-on job); steam comes up and the dynamo runs (BOILER_FED). | Exec Summary step 1 and Decisions log (Repairs); Technical Strategy 'Repairs, shelter and gate' | No boiler, basement or interaction code in LightingTheStorm/scripts or Level.tscn. The 'interact' action exists in project.godot but only boat.gd reads it; the Lighthouse has no interior. |
| R03 | UNMET | Ted at the window shows the sailors' rowboat moored at the dock; the player opens the island gate; Arthur and Daniel walk in on a scripted path and Daniel stays in the basement. The rowboat is visibly distinct from the engine boat. | Exec Summary step 2 and 'Two boats'; Technical Strategy shelter and gate sequence | Assets/Island/environment/1-gate.glb exists as a model, but there is no gate interaction, no rowboat model (Assets/Models/boat has only boat_launch.glb), and no Arthur/Daniel models or NPC scripts. |
| R04 | UNMET | Beacon diagnosis only after the sailors are in: the dynamo runs, the beacon stays dark, Ted takes the player to the lantern room, opens the arc lamp and finds the burner broken (BEACON_STILL_DARK, LAMP_ROOM_ENTERED, BURNER_DIAGNOSED). | Exec Summary step 3; Technical Strategy state contract | No lantern room or lamp in the scene. data/dialogue/dialogue_opening.json has the lines (TED_S3_00 on BEACON_STILL_DARK etc.), but nothing fires these events. |
| R05 | PARTIAL | Boarding: player meets Arthur at the engine boat; at the boarding threshold Ted names the ship and the ship appears on the horizon; no deadline yet. | Exec Summary step 4; Pillar 3; Technical Strategy deadline rules | boat.gd lets the player board with E and cast off (board(), cast_off()), but there is no Arthur aboard, no BOARDING_THRESHOLD/SHIP_SIGHTED event and no ship object anywhere in Level.tscn. |
| R06 | MET | Boat: one steering axis, one fixed speed, no throttle, automatic docking at the Saltgate quays and the lighthouse jetty, and recovery to a safe point on a hit. | Technical Strategy 'Boat and weather simulation'; Exec Summary Outcome checks | LightingTheStorm/scripts/world/boat.gd (fixed speed, Input.get_axis steer, _dock(), _recover() with trail); dock_zone.gd; Level.tscn DockZoneLighthouse/South and DockZonePort; spec in data/world/boat_spec.json. Not play-verified (no editor). Note Level.tscn overrides speed=10.0 vs spec 3.0. |
| R07 | PARTIAL | Hazards (rocks, reefs, buoys, debris) are readable, with a shared hazard forecast and a single safe-route signal that Arthur's calls read from. | Technical Strategy boat/weather section; AI Agent Strategy (Hazard Forecast); Exec Summary Pillar 4 | Level.tscn has SeaStack1-11, cliffs and headlands as static hazards (layer 2). No buoys or debris. AIAgentCrew/output/return_crossing.json and AIAgentCrew/godot/crossing_loader.gd exist but there is no LightingTheStorm/data/return_crossing.json and nothing in the game uses the loader (grep for 'return_crossing' in LightingTheStorm: no matches). |
| R08 | PARTIAL | Outbound crossing to the Saltgate quays and return crossing to the lighthouse are playable end to end, with harder return hazards. | Exec Summary steps 5 and 7; Technical Strategy Gate 1 and week 3 | The geometry exists: DockZoneLighthouse at about z=18, DockZonePort at z=527, Saltgate quay models. The boat can sail between them. No separate return hazard density or route-position difficulty, and the full slice cannot be completed because the surrounding beats are missing. 19 Oct 2026: tools/test_boat.gd now sails both crossings headless at 10 m/s and docks at each end (outbound 69 s, return 81 s, 0 hits on its weave route); no separate return hazard density yet. |
| R09 | UNMET | Player finds and picks up the replacement burner at the Saltgate; it is carried aboard and can never be permanently lost (BURNER_PICKED_UP). | Exec Summary step 6; Technical Strategy invariants and failure policy | No burner object, pickup or cargo state in any script. lighting_rig.gd line 131 sets RETURN on any departure from DOCK_PORT with the comment 'means the burner is aboard'. |
| R10 | UNMET | The only timer is a hidden numeric ship deadline that starts once on RETURN_DEPARTED (burner aboard), is inactive before then, stops in menus, and has a debug time scale and event log. | Exec Summary Fail-state contract; Technical Strategy 'Repairs, shelter and gate, and final pressure' and Invariants; Pillar 2 | GameState provides the event log and RETURN_DEPARTED event, but there is still no numeric deadline, ship or time scale (T07). The old note 'no game state autoload exists' no longer holds. |
| R11 | PARTIAL | Storm split: sound, rain, lightning, wind and ship lights follow elapsed deadline time; hazard density and visibility follow phase and route position only. | Exec Summary decisions log (Storm escalation); Technical Strategy weather channels; Pillar 2 | lighting_rig.gd has phases ISLAND/OUTBOUND/RETURN/BEACON_RELIT driven by boat departed signals, with F5-F8 debug jumps. There is no elapsed-time driver and no hazard-density channel; BEACON_RELIT has no trigger. |
| R12 | UNMET | Final repair: player climbs to the lamp, Ted waits there, and the player fits the burner to the beacon (final hands-on job); Arthur says 'go go go, don't wait for me' on arrival. | Exec Summary step 7-8; Technical Strategy 'Repairs' | No lamp, no burner-fit interaction, no arrival trigger on the lighthouse dock zone. Arrival line exists only as crew data (AIAgentCrew/output/return_crossing.json). |
| R13 | UNMET | Win and fail outcomes resolve exactly once per attempt: win = ship sails safely into port; fail = foghorn, ship runs aground, silence, 'Failed' title screen with a reason line. The lamp room has a clear sightline; no cutaway camera. | Exec Summary Fail-state contract; Technical Strategy fail-state presentation; Pillar 4 | No ship, no outcome code, no title/fail screen, no audio nodes (grep for AudioStreamPlayer in LightingTheStorm *.gd/*.tscn: none). The lighthouse has no lamp room. |
| R14 | PARTIAL | After a fail the player can restart the slice from its start. | Exec Summary Retry model and Outcome checks; Technical Strategy Gate 1 acceptance | GameState.restart() resets the attempt state, resets Dialogue (now also dropping a stale line) and calls reload_current_scene(). F9 triggers it. The state reset is covered by the headless test, but the scene reload was not run and there is no fail screen to call it yet. |
| R15 | PARTIAL | Explicit phase state machine (ARRIVAL_AND_COAL through RESOLUTION) with stable event IDs; every transition has a single owner; audio, UI and dialogue respond to events and never drive progression. | Technical Strategy 'Core state contract'; AI Agent Strategy rule 4 | GameState autoload has the Phase enum in Technical Strategy order, emit_event with stable IDs (canon.py OPENING_EVENTS plus four proposed), one-shot rules and an event log. Headless test_game_state.gd passes. Still partial: nothing in the level reports most opening events yet (no door, boiler, gate or lantern-room triggers), and the four new IDs and phase boundaries await the creator. |
| R16 | PARTIAL | Guidance comes from Ted and Arthur by voice/subtitle and a handwritten objective journal, with no markers or visible timer; apprentice never speaks; spoken navigation cues have subtitles with speaker attribution. | Pillar 3; Technical Strategy 'Presentation and accessibility'; Exec Summary Cast | dialogue_loader.gd emits line_started/journal_entry_added with subtitle text and speaker, but there is no subtitle or journal UI and no audio playback ('the game does not play line audio yet', things to work on next.md item 4). No timer or markers exist, which satisfies the negative rule by absence. |
| R17 | MET | The slice is playable on keyboard and mouse (creator, 19 October 2026: no controller in this iteration). | Technical Strategy Gate 1 acceptance; Decisions to be made B14 (open: is controller needed for the prototype?) | Creator decision 19 October 2026 removed controller support from this iteration. project.godot binds steer, interact and disembark to keys and player.gd uses mouse look; boat prompts show keyboard keys. Not play-verified. |
| R18 | UNMET | Placeholder audio: layered wind and rain, machinery, buoy bells, foghorn, ship impact; states mixed by phase; no shock stingers. | Exec Summary 'Cast and atmosphere'; Technical Strategy presentation; AI Agent Strategy (Sound) | No AudioStreamPlayer in scenes or scripts; no audio files under LightingTheStorm/Assets. |
| R19 | PARTIAL | Warm lamplight against blue-grey storm light; the beam is a navigational anchor from the sea; beacon and hazards stay legible in every phase; greybox art is acceptable. | Exec Summary 'Cast and atmosphere'; AI Agent Strategy (Lighting) | lighting_rig.gd (532 lines) builds sky, rain, lightning and lit windows per phase from data/world/lighting_spec.json. No working beacon beam because there is no lamp; 'things to work on next.md' item 2 reports the walkway as nearly black; legibility of hazards in each phase not verified in-engine. |
| R20 | PARTIAL | Scope and hard rules are respected: first-person only, no combat/jump scares/visible timer/markers, one lighthouse + one sea + the Saltgate, no waves, no branching, no added significant Saltgate detail. | Exec Summary scope rule; AI Agent Strategy working rules 3 and 7 | No violating features found in scripts. A debug label 'Lighting: <phase>' (lighting_rig.gd _build_label) and F5-F8 phase hotkeys are on-screen debug UI that must not ship. Mainland.gd builds a large generated mainland with about 2,600 trees and a walkway, which is beyond a 'minimal' Saltgate; not verified against the creator's intent. |
| R21 | PARTIAL | Each agent task ends with a HANDOFF.md; game data uses JSON/.tres with stable IDs; the project documents engine version and conventions. | AI Agent Strategy 'Handoff format'; Technical Strategy 'Engine and project shape' | AIAgentCrew produces HANDOFF.md/REPORT.md and JSON data (world_output/, output/). LightingTheStorm/readme.md is empty (0 B). project.godot pins 4.3 Forward Plus. The game folder has no task HANDOFF.md files; the crew's boat_spec/lighting_spec are copied into data/world but only lighting_spec is consumed. |

## Tasks (open first, highest score first)

| ID | Score | Task | Category | Owner role | Effort | Status |
|---|---|---|---|---|---|---|
| T02 | **10** | Greybox lighthouse interior route: door, hall, basement, tower stairs, lantern room | scene | Level Layout agent | L | open |
| T06 | **10** | Saltgate burner pickup: place the burner by the landing, pick it up, carry it aboard | code | Gameplay / Systems agent | M | open |
| T07 | **10** | Hidden ship deadline with ship placeholder, elapsed-time lighting and debug time scale | code | Gameplay / Systems agent | M | open |
| T08 | **10** | Win and fail outcomes: foghorn, grounding, silence, 'Failed' screen with reason, restart | code | Story / Fail-State agent | L | open |
| T29 | **10** | Hand carry: pick up the burner, hold it on the boat, fit it at the lamp | code | Gameplay / Systems agent | M | open |
| T32 | **10** | Burner fit: carry the burner up to the lamp and fit it (BURNER_FITTED, BEACON_RELIT) | code | Gameplay / Systems agent | M | open |
| T03 | **9** | Generic first-person interaction system (raycast, prompt, the 'interact' action) | code | Gameplay / Systems agent | M | open |
| T04 | **9** | Window moment, moored rowboat, island gate and sailors' scripted walk-in | scene | Level Layout agent | L | open |
| T05 | **9** | Lantern room diagnosis: Ted opens the arc lamp and finds the burner broken | code | Gameplay / Systems agent | M | open |
| T28 | **9** | Greybox lamp socket, boiler, coal and gauge (the two FAL burners are done) | asset | Asset agent | M | open |
| T30 | **9** | Capsule Arthur and Daniel and a path-follower script (the FAL rowboat is done) | code | Gameplay / Systems agent | M | open |
| T31 | **9** | Passenger ship placeholder, its approach route and the grounding point | scene | Level Layout agent | M | open |
| T33 | **9** | Boiler coal job (BOILER_FED), using the interaction system | code | Gameplay / Systems agent | S | open |
| T10 | **8** | Integrate the crossing crew's hazard forecast: data file, loader, placed buoys/debris, Arthur calls | code | Hazard Forecast agent | M | open |
| T11 | **7** | Put Arthur aboard and add the arrival 'go go go' beat on the lighthouse dock | code | Gameplay / Systems agent | M | open |
| T12 | **7** | Subtitle and journal UI fed by the DialogueLoader signals | code | Dialogue agent | M | open |
| T13 | **7** | Drive perceptual storm cues from elapsed deadline time and trigger BEACON_RELIT | code | Lighting agent | M | open |
| T14 | **6** | Placeholder audio: wind, rain, machinery, buoy bell, foghorn, ship impact, mix by phase | audio | Sound agent | M | open |
| T16 | **6** | Fix the final list of Ted's lamp-room lines to record | decision | Dialogue agent | S | open |
| T19 | **5** | Set a placeholder deadline length and write the crossing-penalty values | decision | Production Orchestrator | S | open |
| T20 | **5** | QA scenario list and automated state-transition checks for the Gate 1 slice | test | QA agent | M | open |
| T34 | **5** | Resolve the discoveries content (B2) on Friday 23 October 2026 | decision | Canon and Review Orchestrator | S | open |
| T18 | **4** | Review the rewritten opening lines and re-record the six changed voice lines | dialogue | Dialogue agent | M | open |
| T22 | **4** | Write LightingTheStorm/readme.md and per-task HANDOFF.md template; reconcile doc gaps | doc | Production Orchestrator | S | open |
| T21 | **3** | Strip or gate debug UI (lighting label, F5-F8 phase jumps) behind a debug flag | code | Lighting agent | S | open |
| T23 | **3** | Bake mainland/cliff carving and collision to cut level load time | code | Level Layout agent | L | open |
| T01 | **10** | Create the central GameState autoload: phase machine, event bus, restart | code | Gameplay / Systems agent | M | done |
| T27 | **9** | Decide what the burner is, how it is carried, and how it is staged at the Saltgate | decision | Canon and Review Orchestrator | S | done |
| T09 | **8** | Decide the fail reason line, deliverer and audio-only fail alternative | decision | Canon and Review Orchestrator | S | done |
| T26 | **7** | Accept the proposed event IDs and phase boundaries into the contract docs | decision | Canon and Review Orchestrator | S | done |
| T15 | **6** | Decide whether the prototype needs controller support, then add bindings and prompts | decision | Player Movement agent | M | done |
| T17 | **6** | Tune and record the Gate 0 steering go/no-go (speed, route length, time per crossing) | test | Boat / Physics agent | M | deferred |
| T25 | **5** | Repair tools/test_boat.gd for the two-berth harbour and make it fail on timeout | test | Boat / Physics agent | S | done |
| T24 | **2** | Fix walkway rock-wall teeth and brighten the dark walkway | scene | Asset agent | M | deferred |

## Build order (dependencies first; see `GOA Dependency Order.md`)

| Wave | Order | ID | Task | Depends on | Waiting on |
|---|---|---|---|---|---|
| 0 | 1 | T34 | Resolve the discoveries content (B2) on Friday 23 October 2026 | - | ready |
| 0 | 2 | T16 | Fix the final list of Ted's lamp-room lines to record | - | ready |
| 1 | 4 | T03 | Generic first-person interaction system (raycast, prompt, the 'interact' action) | T15 | ready |
| 1 | 5 | T29 | Hand carry: pick up the burner, hold it on the boat, fit it at the lamp | T03, T27 | T03 |
| 1 | 6 | T12 | Subtitle and journal UI fed by the DialogueLoader signals | - | ready |
| 1 | 7 | T21 | Strip or gate debug UI (lighting label, F5-F8 phase jumps) behind a debug flag | - | ready |
| 2 | 8 | T02 | Greybox lighthouse interior route: door, hall, basement, tower stairs, lantern room | - | ready |
| 2 | 9 | T28 | Greybox lamp socket, boiler, coal and gauge (the two FAL burners are done) | T02, T27 | T02 |
| 2 | 10 | T30 | Capsule Arthur and Daniel and a path-follower script (the FAL rowboat is done) | - | ready |
| 2 | 11 | T31 | Passenger ship placeholder, its approach route and the grounding point | - | ready |
| 3 | 12 | T33 | Boiler coal job (BOILER_FED), using the interaction system | T02, T03, T26, T28 | T02, T03, T28 |
| 3 | 13 | T04 | Window moment, moored rowboat, island gate and sailors' scripted walk-in | T02, T30, T33 | T02, T30, T33 |
| 3 | 14 | T05 | Lantern room diagnosis: Ted opens the arc lamp and finds the burner broken | T02, T04, T26, T28, T30 | T02, T04, T28, T30 |
| 3 | 15 | T11 | Put Arthur aboard and add the arrival 'go go go' beat on the lighthouse dock | T30, T31 | T30, T31 |
| 3 | 16 | T06 | Saltgate burner pickup: place the burner by the landing, pick it up, carry it aboard | T25, T26, T28, T29 | T28, T29 |
| 4 | 17 | T19 | Set a placeholder deadline length and write the crossing-penalty values | T25 | ready |
| 4 | 18 | T07 | Hidden ship deadline with ship placeholder, elapsed-time lighting and debug time scale | T06, T31 | T06, T31 |
| 4 | 19 | T32 | Burner fit: carry the burner up to the lamp and fit it (BURNER_FITTED, BEACON_RELIT) | T02, T26, T28, T29 | T02, T28, T29 |
| 4 | 20 | T13 | Drive perceptual storm cues from elapsed deadline time and trigger BEACON_RELIT | T07, T32 | T07, T32 |
| 4 | 21 | T14 | Placeholder audio: wind, rain, machinery, buoy bell, foghorn, ship impact, mix by phase | - | ready |
| 4 | 22 | T08 | Win and fail outcomes: foghorn, grounding, silence, 'Failed' screen with reason, restart | T26, T07, T09, T12, T14, T31 | T07, T12, T14, T31 |
| 5 | 23 | T10 | Integrate the crossing crew's hazard forecast: data file, loader, placed buoys/debris, Arthur calls | T12 | T12 |
| 5 | 24 | T20 | QA scenario list and automated state-transition checks for the Gate 1 slice | T08 | T08 |
| 5 | 25 | T18 | Review the rewritten opening lines and re-record the six changed voice lines | - | ready |
| 5 | 26 | T22 | Write LightingTheStorm/readme.md and per-task HANDOFF.md template; reconcile doc gaps | T26 | ready |
| 5 | 27 | T23 | Bake mainland/cliff carving and collision to cut level load time | - | ready |

## Task detail

### T02 [10/10] Greybox lighthouse interior route: door, hall, basement, tower stairs, lantern room  (open)

The Lighthouse node is an exterior glb only. Build a greybox interior following ConceptArt/narrative_blueprints (entry hall, basement boiler room, stairs, lantern room), the entrance door, a window with a view of the dock and rowboat, and a lamp room window with a clear sightline to the ship route and island rocks. Player start moves outside the door, and interaction anchors are added for the other tasks. The lamp room has views all around; one view faces the rock next to the island where the ship crashes or passes safely. Ted is inside the lighthouse throughout the game.

- **Why 10:** Steps 1-4 and 8-9 all happen inside the building, so the slice cannot be played without it. It is not an 11 because it only needs greybox and is a scene task that can be checked by walking.
- **Evidence:** Exec Summary steps 1-4, 8-9; Level.tscn Lighthouse node (exterior model only); ConceptArt/narrative_blueprints/Brussskania Lighthouse Blueprint Poster.png
- **Blocked by:** Needs the Godot editor to place and walk-test the interior and sightlines.
- **Needs the creator** (cannot be done by the agent alone)

### T06 [10/10] Saltgate burner pickup: place the burner by the landing, pick it up, carry it aboard  (open)

Place the replacement burner (T28) on the ground at the Saltgate dock, close to where the player disembarks at DockZonePort. Picking it up fires GameState.emit_event('BURNER_PICKED_UP') and the player carries it in his hands (T29). GameState already emits RETURN_DEPARTED only when the burner is aboard and the lighting rig already follows GameState. Remove or debug-gate the F11 stand-in once this works.

- **Why 10:** The clock start is the core pillar-2 mechanic and a stated Gate 1 acceptance item, so a 10. Not higher because it does not need to be pretty.
- **Evidence:** Technical Strategy invariants: deadline inactive until the return-departure event; scripts/world/lighting_rig.gd line 131; boat.gd departed signal
- **Blocked by:** Tasks T25, T26, T28, T29. The boat must reliably reach DOCK_PORT (T25).
- **Depends on:** T25, T26, T28, T29 (still open: T28, T29)

### T07 [10/10] Hidden ship deadline with ship placeholder, elapsed-time lighting and debug time scale  (open)

Implement a numeric internal deadline timer (no UI), pausing in menus, with a placeholder ship whose lights hold at the horizon until the clock starts and then approach. Expose a debug time scale and event log. The value is a placeholder constant until playtests set it. Pause rule (creator, 19 October 2026): the deadline stops in menus and on deliberate pause.

- **Why 10:** The ship and the deadline are the only stakes; without them neither outcome exists. It is a 10 for the same reason as the outcome task.
- **Evidence:** Technical Strategy deadline rules and 'Provide a debug time scale and event log'; Pillar 2
- **Blocked by:** Tasks T06, T31. Depends on GameState and the burner/return trigger. The final deadline length is a creator decision (B4), so use a labelled placeholder.
- **Depends on:** T06, T31 (still open: T06, T31)

### T08 [10/10] Win and fail outcomes: foghorn, grounding, silence, 'Failed' screen with reason, restart  (open)

Resolve WIN or FAIL exactly once. FAIL plays the foghorn, the ship grounding and silence, then a title screen with a reason line, and restarts the slice; the three expiry locations (crossing, lamp room, stairs) get their audio-only or sightline presentation, with a visual or subtitle alternative. The burner fit moved to T32. Fail reason line (creator): Ted voices "All is lost for those on board...the storm takes more lives. What were you doing, you money toff!", shown as a subtitle; the visual is the ship breaking up on the rock next to the island. On the stairs the player sees nothing; the crash plays out regardless (creator, A26).

- **Why 10:** Both outcomes and restart are explicit Gate 1 acceptance items, so a 10. Not lower because without it the slice has no ending.
- **Evidence:** Exec Summary Fail-state contract; Technical Strategy fail-state presentation and Gate 1 acceptance; no outcome code in LightingTheStorm/scripts
- **Blocked by:** Tasks T26, T07, T09, T12, T14, T31.
- **Depends on:** T26, T07, T09, T12, T14, T31 (still open: T07, T12, T14, T31)
- **Needs the creator** (cannot be done by the agent alone)

### T29 [10/10] Hand carry: pick up the burner, hold it on the boat, fit it at the lamp  (open)

The player picks the burner up with his hands and holds it, visible in first person, through the return crossing, the walk up from the dock and the stairs. The only places it can be released are the boat and the lamp socket; there is no drop elsewhere. It survives boat.gd _recover() on a hazard hit. Steering and boarding must work while holding it. GameState.burner_aboard follows the carried state.

- **Why 10:** Without it the burner cannot get from the Saltgate to the lamp, so the slice cannot be finished: 10.
- **Evidence:** scripts/player/player.gd has no interaction or carry code; scripts/world/boat.gd has no cargo; scripts/core/game_state.gd burner_aboard
- **Blocked by:** Tasks T03, T27. T03 (interaction system); T27 (how it is carried).
- **Depends on:** T03, T27 (still open: T03)

### T32 [10/10] Burner fit: carry the burner up to the lamp and fit it (BURNER_FITTED, BEACON_RELIT)  (open)

Split out of T08. With Ted waiting in the lamp room, the player carries the burner off the boat, up the stairs and fits it into the arc-lamp socket, emitting BURNER_FITTED. GameState already maps BURNER_FITTED to FINAL_REPAIR and the BEACON_RELIT lighting.

- **Why 10:** The final hands-on job and the win condition, so 10.
- **Evidence:** Exec Summary step 8; scripts/core/game_state.gd BURNER_FITTED (proposed)
- **Blocked by:** Tasks T02, T26, T28, T29.
- **Depends on:** T02, T26, T28, T29 (still open: T02, T28, T29)

### T03 [9/10] Generic first-person interaction system (raycast, prompt, the 'interact' action)  (open)

Add a raycast/Area-based interactable using the existing 'interact' action, with a short diegetic prompt (no quest markers). It is the template for the boiler (T33), gate (T04), burner carry (T29) and burner fit (T32). The boiler job itself moved to T33.

- **Why 9:** It is the first hands-on job and the template for the gate and burner interactions, so it is needed for Gate 1. It is below 10 because the state controller and interior come first.
- **Evidence:** Exec Summary step 1; LightingTheStorm/project.godot (interact action); scripts/world/boat.gd only consumer of interact
- **Blocked by:** Tasks T15. Controller decision (T15) settles the prompt glyphs.
- **Depends on:** T15 (all closed)

### T04 [9/10] Window moment, moored rowboat, island gate and sailors' scripted walk-in  (open)

Add a distinct rowboat at the island dock visible from the window, trigger the SAILORS_MOORED window moment with a short-delay fallback, make the existing island gate (1-gate.glb) a single interaction, and script Arthur and Daniel walking to the lighthouse and Daniel to the basement (DANIEL_IN_BASEMENT). Needs placeholder Arthur and Daniel meshes.

- **Why 9:** Beat 3 is a required slice stage and gates the diagnosis, so it is 9. It is below 10 because it can use capsule placeholders.
- **Evidence:** Exec Summary step 2 and 'Two boats'; Technical Strategy shelter and gate sequence; Assets/Island/environment/1-gate.glb; ConceptArt/characters (Arthur, Daniel sheets), ConceptArt/dock
- **Blocked by:** Tasks T02, T30, T33. Needs the editor to place the rowboat, gate and NPC paths; greybox Arthur and Daniel and the rowboat do not exist yet.
- **Depends on:** T02, T30, T33 (still open: T02, T30, T33)
- **Needs the creator** (cannot be done by the agent alone)

### T05 [9/10] Lantern room diagnosis: Ted opens the arc lamp and finds the burner broken  (open)

Implement the BEACON_DIAGNOSIS trigger that fires only after DANIEL_IN_BASEMENT, with Ted leading the player to the lantern room, the arc lamp opening, BURNER_DIAGNOSED and BURNER_BRIEFING opening the way to the boat. Reuse the dialogue lines in dialogue_opening.json.

- **Why 9:** It is the story pivot that sends the player to the Saltgate, so it is needed to pass Gate 1. It is under 10 because it can be a simple triggered sequence once the interior and state exist.
- **Evidence:** Exec Summary step 3; Technical Strategy BEACON_DIAGNOSIS; data/dialogue/dialogue_opening.json lines TED_S3_00..02
- **Blocked by:** Tasks T02, T04, T26, T28, T30. Depends on GameState, the interior and Ted being in the scene.
- **Depends on:** T02, T04, T26, T28, T30 (still open: T02, T04, T28, T30)

### T28 [9/10] Greybox lamp socket, boiler, coal and gauge (the two FAL burners are done)  (open)

Generate the broken and replacement burners as FAL models from ConceptArt/burner/Broken Burner.png and Replacement Burner.png through the Asset agent (main_asset.py --check-only first; downscale the 4096 textures to 2048). The sheets carry the old 'Brusskania' label, so keep any brand text off the model (the brand is Saint Calder). The arc-lamp socket, boiler, coal pile and gauge can stay greybox for Gate 1. The burner has lifting rings and a mounting base, so the lamp socket should match its base.

- **Why 9:** T05, T06, T32 and T33 all need these objects, so 9. Greybox is enough, so not 10.
- **Evidence:** LightingTheStorm/Assets has no burner, lamp, boiler or coal; ConceptArt has no burner or arc-lamp sheet
- **Blocked by:** Tasks T02, T27. The lamp socket must match the burner's mounting base.
- **Depends on:** T02, T27 (still open: T02)
- **Result (partial):** Burners done, 19 Oct 2026: Assets/Models/prop/burner_replacement.glb and burner_broken.glb, 40k triangles each, 0.8 x 0.9 x 0.7 m. FAL Hunyuan3D v3 (textured, front + side views cropped from the concept sheets into AIAgentCrew/sample_submissions/derived/; main_asset.py --check-only APPROVE first). FAL returned about 500k triangles and 4096 textures, so each model was downscaled to a 2048 texture and decimated in Blender 5.2; the full-detail versions are in the model folder's source/ (gdignored). Imported headless through tools/import_scale_pivot.gd (prop height 0.9 m, rowboat 4.2 m long; both estimates). Still to do: the greybox arc-lamp socket, boiler, coal pile and gauge.

### T30 [9/10] Capsule Arthur and Daniel and a path-follower script (the FAL rowboat is done)  (open)

Arthur and Daniel are capsules for the prototype (creator, 19 October 2026). The rigged test character is Ted (Assets/Characters/ted.glb), present inside the lighthouse throughout. Generate the rowboat as a FAL model from ConceptArt/rowboat/Crude Rowboat Concept Sheet.png. Add one NPC script that walks a path, waits, follows the player, or sits at a seat on the boat.

- **Why 9:** Three story tasks depend on it, so 9. Capsules would do, so not 10.
- **Evidence:** Assets/Characters has only ted.glb and the rigged test character; Assets/Models/boat has only boat_launch.glb; ConceptArt/characters
- **Blocked by:** Paths need an editor check.
- **Needs the creator** (cannot be done by the agent alone)
- **Result (partial):** Rowboat done, 19 Oct 2026: Assets/Models/boat/rowboat.glb, 60k triangles, 2.0 x 1.1 x 4.2 m (beamy, as the concept sheet is; check the width and whether the thwarts and oars survived decimation). FAL Hunyuan3D v3 (textured, front + side views cropped from the concept sheets into AIAgentCrew/sample_submissions/derived/; main_asset.py --check-only APPROVE first). FAL returned about 500k triangles and 4096 textures, so each model was downscaled to a 2048 texture and decimated in Blender 5.2; the full-detail versions are in the model folder's source/ (gdignored). Imported headless through tools/import_scale_pivot.gd (prop height 0.9 m, rowboat 4.2 m long; both estimates). Still to do: capsule Arthur and Daniel and the path-follower script.

### T31 [9/10] Passenger ship placeholder, its approach route and the grounding point  (open)

A placeholder passenger ship with lights and a path from the horizon toward the port that the deadline drives. On a win it passes one of the rocks right next to the island safely; on a fail it crashes and breaks up on that rock. The rock must be in clear view from the lamp room, which has views all around (creator, 19 October 2026).

- **Why 9:** T07, T08 and the ship-sighted beat of T11 depend on it, so 9.
- **Evidence:** No ship object in Level.tscn; Exec Summary fail-state contract (runs aground); Technical Strategy lamp-room sightline
- **Blocked by:** Needs the editor for the route and sightline.
- **Needs the creator** (cannot be done by the agent alone)

### T33 [9/10] Boiler coal job (BOILER_FED), using the interaction system  (open)

Split out of T03. In the basement, pick up and shovel coal until the gauge climbs, emitting LIGHTHOUSE_ENTERED on entry and BOILER_FED when done, and start the dynamo hum or effect.

- **Why 9:** The first hands-on job and a Gate 1 beat, so 9.
- **Evidence:** Exec Summary step 1
- **Blocked by:** Tasks T02, T03, T26, T28.
- **Depends on:** T02, T03, T26, T28 (still open: T02, T03, T28)

### T10 [8/10] Integrate the crossing crew's hazard forecast: data file, loader, placed buoys/debris, Arthur calls  (open)

Copy return_crossing.json into LightingTheStorm/data, add crossing_loader.gd to the scene with a route-position feed from the boat, spawn hazards (rocks, buoys, debris) from it, and play Arthur's calls as subtitles from the same safe-lane signal. Add an equivalent, easier outbound forecast. Do not add waves or branching.

- **Why 8:** Readable hazards and Arthur's guidance are the central skill and Pillar 4. It is below 10 because the slice runs with only static rocks, and the pipeline already exists.
- **Evidence:** AIAgentCrew/output/return_crossing.json; AIAgentCrew/godot/crossing_loader.gd; Technical Strategy hazard forecast; Level.tscn SeaStack nodes only
- **Blocked by:** Tasks T12. Best done after Arthur is in the boat; steering feel play check needed.
- **Depends on:** T12 (still open: T12)

### T11 [7/10] Put Arthur aboard and add the arrival 'go go go' beat on the lighthouse dock  (open)

Seat Arthur on the engine boat as the only companion, fire BOARDING_THRESHOLD (Ted introduces the ship) and the SALTGATE_REACHED and arrival events from dock-zone arrival. Plays his line on return arrival, then he leaves the player to climb.

- **Why 7:** Companion guidance is part of the beats but the slice can be tested with the loader's lines alone, so 7.
- **Evidence:** Exec Summary steps 4-7 and Cast; boat.gd docked signal; dialogue_opening.json
- **Blocked by:** Tasks T30, T31. Depends on GameState and the crossing integration.
- **Depends on:** T30, T31 (still open: T30, T31)

### T12 [7/10] Subtitle and journal UI fed by the DialogueLoader signals  (open)

Add a CanvasLayer showing speaker-attributed subtitles from line_started and a handwritten-style journal reading journal_entry_added. No quest markers and no timer; the assist hint stays off by default.

- **Why 7:** Without it, guidance and the journal are invisible and no voice audio is playing, but the slice is technically completable by greybox. 7 reflects importance without blocking core logic.
- **Evidence:** Pillar 3; Technical Strategy accessibility; dialogue_loader.gd signals have no listeners

### T13 [7/10] Drive perceptual storm cues from elapsed deadline time and trigger BEACON_RELIT  (open)

In lighting_rig.gd, add a blend by normalised elapsed deadline time for rain, lightning, wind audio and ship lights while keeping hazard density and visibility on route position. Add the BEACON_RELIT trigger and a beam sweep.

- **Why 7:** This implements the storm-split decision and Pillar 2, but the slice works with phase-only lighting, so 7.
- **Evidence:** Exec Summary decisions log (Storm escalation); lighting_rig.gd phases and 'BEACON_RELIT has no trigger yet'
- **Blocked by:** Tasks T07, T32. Depends on the deadline task.
- **Depends on:** T07, T32 (still open: T07, T32)

### T14 [6/10] Placeholder audio: wind, rain, machinery, buoy bell, foghorn, ship impact, mix by phase  (open)

Add placeholder audio buses and AudioStreamPlayers for wind, rain, boiler/dynamo, buoy bells, foghorn and impact, mixed by phase and with Arthur's calls kept audible. Record source and licence per file and wire the six re-recorded voice lines later.

- **Why 6:** Audio carries the deadline when there is no UI and the fail cue on the crossing. Placeholder is acceptable per Gate 1, so 6.
- **Evidence:** Exec Summary atmosphere; AI Agent Strategy (Sound); no AudioStreamPlayer anywhere in LightingTheStorm
- **Blocked by:** Needs audio source files and licences; sound choices need creator ears.
- **Needs the creator** (cannot be done by the agent alone)

### T16 [6/10] Fix the final list of Ted's lamp-room lines to record  (open)

Ted's presence is settled (creator, 19 October 2026: he is inside the lighthouse throughout the game). What remains is the final list of lamp-room lines to voice, since every line is voice-over cost: the diagnosis lines (TED_S3_*), the waiting line when the player returns, the burner-fit and win reaction, and the fail reason line (canon.py FAIL_REASON_LINE).

- **Why 6:** It blocks recording, not building, so 6: the lamp-room tasks can use subtitles until the lines are voiced.
- **Evidence:** Exec Summary decisions log (Ted); Decisions to be made B1; Assets/Characters/ted.glb exists
- **Blocked by:** Creator sign-off on the line list.
- **Needs the creator** (cannot be done by the agent alone)

### T19 [5/10] Set a placeholder deadline length and write the crossing-penalty values  (open)

The deadline length and exact collision costs are deliberately undecided until the return crossing is tested. Record a clearly labelled placeholder deadline, the outbound-crossing penalty (B9, deferred) and the collision cost so the QA tuning pass has numbers to compare against.

- **Why 5:** It is needed for the tuning pass but cannot be settled before the crossing exists, so 5.
- **Evidence:** Decisions to be made B4, B9, B11; Exec Summary Crossing penalties 'loose for Gate 1'
- **Blocked by:** Tasks T25. Time a crossing at 10 m/s (the creator's speed until the waves are complete), then set the labelled placeholder.
- **Depends on:** T25 (all closed)
- **Needs the creator** (cannot be done by the agent alone)

### T20 [5/10] QA scenario list and automated state-transition checks for the Gate 1 slice  (open)

Write a reproducible scenario list covering each phase transition, the clock starting once, the exactly-once outcome, restart, each fail expiry location and a keyboard/controller pass. Add headless GDScript checks beside the existing tools/test_boat.gd where practical.

- **Why 5:** Gate checks need evidence, but it only becomes useful once the state controller exists, so 5.
- **Evidence:** Technical Strategy 'Validation and integration'; AI Agent Strategy (QA); tools/test_boat.gd
- **Blocked by:** Tasks T08. Depends on the GameState task.
- **Depends on:** T08 (still open: T08)

### T34 [5/10] Resolve the discoveries content (B2) on Friday 23 October 2026  (open)

Decide which discoveries live in the lighthouse and island and which stay at the Saltgate, and how each ties to why the beacon failed. POSTER_EXAMINED and WALL_WHISPER_HEARD already exist as optional events. The creator asked to be reminded on Friday.

- **Why 5:** It shapes optional interior content, not the critical path, so 5.
- **Evidence:** Decisions to be made B2; canon.py OPENING_EVENTS optional events
- **Blocked by:** Creator decision, due Friday 23 October 2026.
- **Needs the creator** (cannot be done by the agent alone)

### T18 [4/10] Review the rewritten opening lines and re-record the six changed voice lines  (open)

Run TED_S1_01, S1_09, S1_10, S1_11, S3_02, ARTHUR_S3_04 and the new TED_S3_00 through Dialogue and Canon review and the creator's sign-off, record the outcome in DIALOGUE_OPENING_CREATOR_PICKS.md, then regenerate audio (dry run first). Add the playback hook to the game later. Add Ted's fail reason line (canon.py FAIL_REASON_LINE) to the recording list.

- **Why 4:** The game does not play audio yet, so nothing breaks today. It must be done before voice is hooked up, so 4.
- **Evidence:** things to work on next.md items 4 and 5; AIAgentCrew/voice_output_picked_live/elevenlabs/lines
- **Blocked by:** Creator sign-off on voice and lore; ElevenLabs credits for regeneration.
- **Needs the creator** (cannot be done by the agent alone)

### T22 [4/10] Write LightingTheStorm/readme.md and per-task HANDOFF.md template; reconcile doc gaps  (open)

The game readme is empty. Document engine version (4.3 Forward Plus per project.godot), how to run, controls, event IDs, scene ownership and a HANDOFF.md template. Also flag the controller contradiction (Tech Strategy vs Exec Summary) and the unconfirmed week-5 fallback wording (item 6) for the creator.

- **Why 4:** Helps agents and the creator review each change, but does not block play, so 4.
- **Evidence:** LightingTheStorm/readme.md (0 B); AI Agent Strategy 'Handoff format'; things to work on next.md item 6
- **Blocked by:** Tasks T26.
- **Depends on:** T26 (all closed)

### T21 [3/10] Strip or gate debug UI (lighting label, F5-F8 phase jumps) behind a debug flag  (open)

lighting_rig.gd shows an on-screen 'Lighting: <phase>' label and lets F5-F8 jump phases. Hide these unless a debug setting is on, so they cannot be mistaken for a HUD in tester builds.

- **Why 3:** Minor polish and a possible pillar-3 irritation. Not needed for the slice to run, so 3.
- **Evidence:** scripts/world/lighting_rig.gd _build_label and F5-F8 handling

### T23 [3/10] Bake mainland/cliff carving and collision to cut level load time  (open)

mainland.gd and collider_builder.gd carve about 22,000 triangles, build trees and collision at every load (about 10 s headless). Bake the carved meshes, height table and collision as resources and keep builders editor-only.

- **Why 3:** Quality of life for testing and builds, not a gate requirement, so 3.
- **Evidence:** things to work on next.md item 3; scripts/world/mainland.gd _ready()
- **Blocked by:** Needs the Godot editor to bake and verify.
- **Needs the creator** (cannot be done by the agent alone)

### T01 [10/10] Create the central GameState autoload: phase machine, event bus, restart  (done)

Add a GameState autoload (register in project.godot) holding the phase enum (ARRIVAL_AND_COAL → … → RESOLUTION), an emit_event(event_id) bus with a debug event log, and a restart() that reloads the slice. Add the DialogueLoader as a child or autoload, and connect GameState events to DialogueLoader.trigger(), the lighting rig's set_phase() and the boat's signals. Every other Gate 1 task hangs off this contract.

- **Why 10:** Nothing else can be wired without it, and the slice cannot run end to end, so it is a 10. It is not scored lower because six other tasks depend on it.
- **Evidence:** Technical Strategy: Core state contract; LightingTheStorm/project.godot [autoload] registers GameState and Dialogue (found already present when T01 ran); LightingTheStorm/scripts/dialogue/dialogue_loader.gd; LightingTheStorm/things to work on next.md item 7
- **Result (partial):** T01's premise was out of date. `GameState` and `Dialogue` are already registered in `project.godot`, and `scripts/core/game_state.gd` already has the phase enum, `emit_event()`, the event log, `restart()` and the wiring to Dialogue, the lighting rig and the boat. I verified that against the contract and the headless test passes. I made two small fixes, wrote the missing handoff note, and reworded item 7 of the work list. Two things are not done. I couldn't update the agent bookkeeping, which is outside my write area. And `test_boat.gd` times out, which I traced to something other than GameState.

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

### T27 [9/10] Decide what the burner is, how it is carried, and how it is staged at the Saltgate  (done)

No document or concept art says what the burner looks like. Decide its form (an arc-lamp burner assembly that fits the style guide), whether it is carried in the hands or in a crate, how the broken one differs from the spare, whether the player can ever put it down outside the boat and the lamp (saying no keeps the 'never permanently lost' invariant simple), and how it sits on the Saltgate quay without adding significant Saltgate detail.

- **Why 9:** Every physical part of the burner thread (props, carrying, pickup, fit) waits on it, so 9. It is a short decision, not a 10.
- **Evidence:** Exec Summary steps 3, 6, 8; Technical Strategy invariants (burner never permanently lost); AI Agent Strategy rule: no significant Saltgate detail; No burner in LightingTheStorm/Assets or ConceptArt
- **Blocked by:** Creator decision.
- **Needs the creator** (cannot be done by the agent alone)
- **Result (done):** Creator decision, 19 October 2026. The burner follows ConceptArt/burner (Broken Burner.png, Replacement Burner.png). The replacement sits on the ground at the Saltgate dock close to where the player disembarks. The player picks it up with his hands and carries it in his hands on the boat back to the island, and cannot put it down anywhere except the boat and the lamp. The prop is a FAL model generated from the concept art. Recorded in Docs/GDD/Final_GDD_Post_Review/Supporting_Documentation/Decisions to be made.md (A18).

### T09 [8/10] Decide the fail reason line, deliverer and audio-only fail alternative  (done)

The creator must choose the wording of the short line shown on 'Failed' and who delivers it (Ted, Arthur or the journal), and what subtitle or visual alternative replaces the audio-only fail cue on the crossing and the stairs. Agents must not choose these.

- **Why 8:** It directly blocks the outcome task and Pillar 4's 'told why', but it is a quick decision, so 8 and not 10.
- **Evidence:** Decisions to be made B3 and B8; Exec Summary Fail-state contract
- **Blocked by:** Creator decision.
- **Needs the creator** (cannot be done by the agent alone)
- **Result (done):** Creator decision, 19 October 2026. Ted voices the fail reason line and it is shown as a subtitle: "All is lost for those on board...the storm takes more lives. What were you doing, you money toff!" The visual is the passenger ship crashing and breaking up on one of the rocks right next to the island. (The first wording ended 'lad???', which broke the canon rule against calling the player lad; the creator changed it to 'you money toff!'.) Recorded in Docs/GDD/Final_GDD_Post_Review/Supporting_Documentation/Decisions to be made.md (A20).

### T26 [7/10] Accept the proposed event IDs and phase boundaries into the contract docs  (done)

RETURN_ARRIVED, BURNER_FITTED, SHIP_WIN, SHIP_FAIL and the PHASE_ON_EVENT table exist only in game_state.gd. The creator or orchestrators should accept or rename them, then copy the result into canon.py and the Technical Strategy state-contract paragraph so T02-T08 build on the same names.

- **Why 7:** Six other tasks inherit these names, so a late rename is expensive. It is only a decision, not code.
- **Evidence:** LightingTheStorm/HANDOFF_T01_GameState.md section 7; LightingTheStorm/scripts/core/game_state.gd EVENTS and PHASE_ON_EVENT; Technical Strategy: Core state contract
- **Blocked by:** Creator or orchestrator approval
- **Needs the creator** (cannot be done by the agent alone)
- **Result (done):** Creator decision, 19 October 2026. The four proposed event IDs (RETURN_ARRIVED, BURNER_FITTED, SHIP_WIN, SHIP_FAIL) and the phase boundaries are accepted. Copied into AIAgentCrew/canon.py (LATER_EVENTS, PHASE_ON_EVENT) and the Technical Strategy core state contract; the PROPOSED comments in game_state.gd now point at canon. Recorded in Docs/GDD/Final_GDD_Post_Review/Supporting_Documentation/Decisions to be made.md (A17).

### T15 [6/10] Decide whether the prototype needs controller support, then add bindings and prompts  (done)

Technical Strategy Gate 1 requires keyboard and controller but the Exec Summary puts controller in the full game (B14). The creator should settle this. If yes, add joypad bindings (steer, interact, look), a gamepad look in player.gd and prompt glyphs in the boat label.

- **Why 6:** It is a Gate 1 acceptance line with an open doc contradiction, so it matters, but it is not required to play the slice with a keyboard.
- **Evidence:** Decisions to be made B14; LightingTheStorm/project.godot has only InputEventKey; scripts/player/player.gd mouse look only
- **Blocked by:** Creator decision B14, then a controller test in the editor.
- **Needs the creator** (cannot be done by the agent alone)
- **Result (done):** Creator decision, 19 October 2026. No controller in this iteration; the prototype is keyboard and mouse. Technical Strategy Gate 1 acceptance reworded. Recorded in Docs/GDD/Final_GDD_Post_Review/Supporting_Documentation/Decisions to be made.md (A21).

### T17 [6/10] Tune and record the Gate 0 steering go/no-go (speed, route length, time per crossing)  (deferred)

Level.tscn overrides the boat's speed to 10.0 m/s while boat_spec.json says 3.0, and the route is about 500 m. Play both crossings, record crossing times against the 10-minute target, tune speed, steering and recovery as data, and write the go/no-go for the creator.

- **Why 6:** Steering feel is the largest production risk but it is a creator judgment that needs a playtest, so it is 6 and not higher.
- **Evidence:** Technical Strategy week 2 go/no-go; Level.tscn Boat speed=10.0; data/world/boat_spec.json speed_mps 3.0; DockZonePort at z=527
- **Blocked by:** Tasks T25. Needs a human playtest in the Godot editor.
- **Depends on:** T25 (all closed)
- **Needs the creator** (cannot be done by the agent alone)
- **Result (deferred):** Creator decision, 19 October 2026: the boat stays at 10 m/s until the waves are complete. Re-tune speed and steering then. data/world/boat_spec.json (3.0) is not read by the game.

### T25 [5/10] Repair tools/test_boat.gd for the two-berth harbour and make it fail on timeout  (done)

The crossing test times out in step 10 and the outbound leg re-docks at DOCK_LIGHTHOUSE instead of reaching DOCK_PORT. Find out whether the test or the boat's zone handling is wrong (two zones share the id DOCK_LIGHTHOUSE), fix it, and make the script exit non-zero on TIMEOUT so QA can rely on it. Creator (19 October 2026): fix it now.

- **Why 5:** It is the only automated proof that docking works end to end, and the Gate 1 slice depends on docking at both ends. It is not higher because the boat has been playable by hand.
- **Evidence:** LightingTheStorm/tools/test_boat.gd; LightingTheStorm/scripts/world/boat.gd; LightingTheStorm/scenes/Level.tscn DockZoneLighthouse and DockZoneLighthouseSouth; Technical Strategy: Boat and weather simulation (docking)
- **Result (done):** The boat was fine; the test was stale. _route_around_stacks() wove round every child of SeaRocks, but the level now has stacks far out to the sides, so the third waypoint (-162, 16) turned the boat back past the harbour mouth, where it correctly auto-docked at the lighthouse again. The weave now only uses stacks within 100 m of the lane (and beyond z=60). The test exits 1 via _fail() on a timeout or on docking at the wrong end. Headless run on Godot 4.3: outbound docked at DOCK_PORT after 69 s, return docked at DOCK_LIGHTHOUSE after 81 s, 0 hits, DONE, exit 0. test_game_state.gd still passes. Files: LightingTheStorm/tools/test_boat.gd.

### T24 [2/10] Fix walkway rock-wall teeth and brighten the dark walkway  (deferred)

Clip cliff triangles at the floor plane (or add a rubble skirt) and lighten the walkway vertex colours or add warm lamps, after checking against the final lighting pass.

- **Why 2:** Visual polish on a mainland walkway outside the core path, and the Saltgate must stay minimal, so 2.
- **Evidence:** things to work on next.md items 1 and 2; scripts/world/mainland.gd _build_gallery()
- **Blocked by:** Needs editor visual checks; also check against the 'no significant Saltgate detail' rule.
- **Needs the creator** (cannot be done by the agent alone)
