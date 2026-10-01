# Lighting the Storm — Technical Strategy

Basis: Executive Summary and source GDD, amended 1 October 2026 after the design review. This is an implementation proposal, not a claim that the original GDD selected an engine or fixed numeric tuning values.

## Change log (post-review amendments)

- Gate table: Gate 1 now has two repairs, a return-crossing clock start, and “fail, then restart the slice”. Gate 2 must settle the final retry and save model.
- State contract: CRASH_AND_GATE renamed SHELTER_AND_GATE; “unlocked routes” removed; the exactly-once invariant is now per attempt; a time-and-weather snapshot is specified for Gate 2.
- Weather: split into a perceptual channel (elapsed time) and a hazard channel (phase and route position).
- Deadline: starts when the burner is aboard and the boat sets off on the return crossing; no fail state before then; fail-state presentation specified per location; the ship is introduced at the boarding threshold.
• Boat: docking, disembarking, and recovery defined for a fixed-speed boat with no throttle.
- Schedule: hazard forecast added; week 4 rebalanced; early deadline tuning pass added; Ted lock-in added as a week 3 exit item.
- Crossing penalty rules marked as loose for Gate 1.
- Crash sequence replaced by the shelter-and-gate sequence.
- Fail-state presentation restated as three fail states, all after the return crossing begins (return crossing, lamp room, stairs); there is no fail state before the return crossing begins.
- Outpost kept minimal until the prototype is complete; deadline length to be reviewed once the return crossing is tested.
- Engine confirmed by the creator as Godot 4 with GDScript (was “proposed”); the Unity fallback sentence is replaced by a statement that the contracts below are engine-neutral.

## Engine and project shape

Engine: Godot 4 (confirmed by the creator after reviewing the Engine Comparison pros and cons), using GDScript for the first playable. Its scene-based structure suits the compact locations and scripted interactions, and a single developer can iterate quickly without adding a toolchain. Commit the exact engine version and renderer choice with the initial project; evaluate controller input and storm lighting on the target PC early. The contracts below do not depend on the engine. Blender is the source for authored meshes; imported scene assets should have documented scale, collision, pivot, and naming conventions.

Keep scenes and scripts separately owned where possible: lighthouse, sea, outpost, shared player and interaction scenes, and a central game-state resource/controller. Store content such as repairs, dialogue, assistance presets, and journal text as data, with stable IDs. Avoid hard-wiring story progress into individual prop scripts.

## Milestones and gates

|Gate                        |Deliverable                                                                                               |Acceptance                                                                                                                                                                |
|----------------------------|----------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|0. Steering spike           |Greybox powered boat on a sea that moves for atmosphere only, rocks, buoys and debris, readable heading and collision feedback, and the shared hazard forecast with a single safe-route signal.|A player can steer through a short route using steering alone; the designer can tune it without rewriting physics. Stop or redesign if the core crossing is not enjoyable.|
|1. Ten-minute vertical slice|Two repairs, Ted seeing the moored rowboat from the window, island gate opening, boarding with Jeff, outbound crossing, burner pickup, harder return crossing, burner fitting with Ted at the lamp, placeholder ship with win and fail outcomes, and a “Failed” title screen.|Playable end to end in about 10 minutes on keyboard and controller; the ship deadline starts when the boat sets off on the return crossing with the burner aboard; a crossing mistake costs time but does not trap the run; a fail returns to the start of the slice (restart); both outcomes are reachable and a failed player is told why.|
|2. Narrative alpha          |Complete repairs, lighthouse and island discoveries, outpost discoveries, full dialogue, both outcomes, and the final retry and save model.|All story states can be finished; no dead-end save or cargo loss; the retry model has been tested so a reload can never produce an unwinnable state (time and weather restored together). Route branching is reviewed as a cut-list candidate.|
|3. Content and polish       |Final atmosphere, audio, accessibility, checkpoints (if the Gate 2 model uses them), tuning and optional discoveries.|New-player sessions demonstrate legible navigation and the intended 30 minute pacing.                                                                                     |

## Six-week prototype schedule

Assumes a solo developer working about 40 hours a week with AI assistance. Gate 0 closes at the end of week 2 and Gate 1 at the end of week 6.

|Week|Focus                                                                                   |Exit test                                          |
|----|----------------------------------------------------------------------------------------|---------------------------------------------------|
|1   |Project setup and asset pipeline; boat controller with fixed speed and one steering axis; greybox sea that moves visually; first rocks, buoys and debris.|The boat steers and collides reliably on the greybox sea.|
|2   |Steering feel, hazard readability, collision feedback and recovery; the shared hazard forecast (single safe-route signal) (Gate 0).|Go/no-go: steering past hazards is fun on its own. |
|3   |Outpost (minimal detail until the prototype is complete) and burner pickup; return crossing with denser hazards; storm visibility and lighting tuned for readability; docking and disembarking.|Both crossings playable end to end. Ted’s presence is locked by the end of this week.|
|4   |First repair, Ted at the window and the moored rowboat, island gate opening, Jeff at the engine boat, Jeff’s direction calls, return-crossing clock trigger; first rough deadline tuning pass on the full path.|The full 10-minute path is playable and has been run end to end by at least one outside tester.|
|5   |Second repair, hidden ship deadline, fail-state presentation (horn, crash, silence, “Failed” screen, reason line), lamp-room sightline, Ted’s lamp voice lines, win and fail outcomes, placeholder audio.|Both outcomes reachable and the fail reason is shown.|
|6   |Playtests with 3–5 new players, tuning, bug fixing, tester build (Gate 1).              |The prototype outcome checks pass.                 |

Risk: week 5 is heavily loaded. If it slips, the creator decides between dropping the second repair for Gate 1, cutting wave hazards (already first to go), or extending the schedule. Do not decide silently.

Wave hazards are a stretch goal, not part of this schedule. Start them only after Gate 0 has passed, and only when the current week’s exit test is already met. Keep them behind a single on/off setting so the build always works without them, and cut them first if any week slips. If steering fails the week 2 go/no-go, redesign the crossing before starting week 3 work.

### Core state contract

Use explicit phase states, for example LIGHTHOUSE_REPAIRS → SHELTER_AND_GATE → BOARDING → OUTBOUND → OUTPOST → RETURN → FINAL_REPAIR → RESOLUTION (WIN or FAIL). Save phase, completed repair IDs, gate state, burner state, elapsed deadline time, ship state, discoveries, and difficulty preset. The save contract no longer includes “unlocked routes”; route branching is deferred to Gate 2 as a cut-list candidate. Every transition has a single owner and can be replayed in a debug build. Use game events for audio, UI, and dialogue responses rather than allowing those systems to alter progression directly.

Retry and snapshots: for Gate 1, a fail restarts the slice from its start. Before Gate 2, decide the final retry and save model. Whatever is chosen, a snapshot must restore elapsed deadline time and weather state together, so a reload cannot place the player in a guaranteed fail (a player reloading low on time with the worst weather). If a phase-start snapshot is used, define the minimum remaining time it restores. Do not save remaining time at checkpoints on its own.

Invariants: the deadline is inactive until the return-departure event (burner aboard and the boat under way on the return crossing); Jeff is the only crossing companion; a burner pickup precedes return completion; the ship outcome resolves exactly once per attempt, as WIN (burner fitted before expiry) or FAIL (deadline expired). The journal reflects state, but never determines it. Rules marked Proposed in this document must not be enforced as invariants or gate criteria until the creator approves them; Decided (review) items in the Executive Summary are approved.

### Boat and weather simulation

Start with a constrained, tunable approximation: a forward-moving boat with one fixed speed and one player steering axis. The player steers but has no throttle. The core crossing challenge is steering past placed hazards (rocks, reefs, buoys, and floating debris) along a route that narrows and darkens as the storm worsens. The sea surface animates for atmosphere only and does not push the boat. Expose the fixed speed (a tuning value, not a player control), steering response, hazard spacing and density, collision penalty, and recovery delay as data. Tune for clear cause and effect.

Because the boat cannot stop, docking is automatic: arriving within a dock trigger zone at the outpost jetty or the lighthouse jetty ends steering control and moors the boat, followed by a disembark interaction. If the boat leaves the playable corridor or the player misses the dock approach, the recovery event returns the boat to the last safe point on the route with a time cost. Define each dock zone, the safe points, and the recovery behaviour as data.

Stretch goal, waves: if time allows (see the six-week schedule), add authored travelling wave fields that apply heading, roll, and temporary speed penalties according to impact angle and intensity, with wave spacing, wave force, and capsize threshold exposed as data. Build it as an optional layer behind one on/off setting, so the crossing stays complete and tuned without it. Prefer readable, authored waves over physically realistic water.

Use a shared hazard forecast for hazards (and wave crests, if built), boat reaction, and Jeff’s calls, so his warnings never disagree with the actual threat. Jeff’s calls read from the same safe-route signal, with explicit difficulty-dependent lead time and frequency. The forecast uses one safe-route signal; do not design it for multiple routes until branching is approved. Never make both the world and the signal unreadable at once.

Prototype failure policy: a collision with a rock or debris (or a broadside wave hit, if waves are built) adds water, slows the boat or causes a brief capsize-and-recovery at a nearby safe point; these events consume deadline time once the clock is running (on the outbound crossing they cost no deadline time). On return, cargo mishandling delays progress and creates a clear recovery interaction. Proposed: keep the burner recoverable aboard or at a marked nearby point, never permanently lost. Add a simple bailing interaction only if it improves the crossing in playtests; it must not overload the one-control steering promise. These crossing penalty rules are loose for Gate 1 and must be reviewed, with exact costs and limits written down, for the full-game build.

Weather has two channels, so that struggling players are not punished twice.
• Perceptual channel, driven by elapsed deadline time once the clock is running (before it starts, set by phase): wind audio, rain, lightning, thunder, the ship’s lights and position, and the overall mood of the sky.
• Hazard channel, driven by phase and route position only: hazard density, route width, and the visibility needed to read hazards.
Elapsed time must never raise what the player collides with. Preserve a minimum visibility of nearby hazards (and wave cues, if built) and the immediate route on every preset. Use landmarks, compass, buoy silhouettes, and the beacon when facing home. Because the hazard channel does not depend on elapsed time, deadline tuning can be done offline and repeated from the same position.

### Repairs, shelter and gate, and final pressure

Implement repair jobs from data: diagnosis, required fixed-toolkit item or interaction, puzzle steps, completion event, journal update, and optional route unlock (an optional field for later; not saved in Gate 1). The Gate 1 slice uses two repairs and one final burner installation. Later repairs (optic, rotation, fuel/fog signal, stormproofing) belong to Gate 2 and the full game, with short puzzle interactions and no crafting economy.

The shelter and gate sequence is scripted and is part of the Gate 1 slice. After the repairs, Ted prompts the player to look out of the window; Jeff and Daniel’s rowboat is moored on the island, the sailors overwhelmed by the storm and looking for shelter. There is no crash. Proposed: trigger the moment when the window is in view, with a fallback after a short delay so it cannot be missed. Ted then tells the player to open the island gate (the existing gate). Opening it is a single interaction; Jeff and Daniel walk into the lighthouse on their own along a scripted path, with no escort. Daniel goes to the basement and stays there. The gate opening completes SHELTER_AND_GATE and opens the route to the engine boat, where Jeff waits.

Ted, in the second half, is staged at the lamp by position, with voice lines delivered from the lamp room only. At the boarding threshold he names the passenger ship’s lights as the reason for the errand. After the second crossing, Jeff’s “go go go, don’t wait for me” line plays on arrival. Neither Jeff’s nor Daniel’s reaction to the outcome is recorded. Every additional Ted line is voice-over cost; keep new lines to those needed.

For the deadline, store a numeric internal time but display only the passenger ship’s position/lights and weather cues. It is the only timer in the game; the final repair runs on the same deadline. The ship first appears at the boarding threshold. It holds at its starting lights until the clock starts. Rules: start on the return-departure event, when the burner is aboard and the boat starts moving back to the lighthouse; there is no fail state before then, so the outbound crossing and the outpost give the player a free feel for the boat; stop during menus and deliberate pause; continue through the return crossing, recoveries, and final repair. Before Gate 2, decide whether pausing can be exploited. Provide a debug time scale and event log for repeatable QA.

Fail-state presentation. On expiry, resolve FAIL once. The sequence is: foghorn, the ship crashes into the island, silence, then a “Failed” title screen showing a short reason line. The deadline runs only from the return departure, so there are three fail states; what the player perceives depends on where they are.
• On the return crossing (burner aboard): audio only: ship horn, crash sounds, silence, then the “Failed” title screen (no cutaway camera).
• In the lamp room: the player sees the ship hit the island. The audio still sounds. The lamp room needs a clear sightline to the ship’s route and the island rocks.
• Elsewhere in the lighthouse (stairs): audio only, as on the crossing, unless a window sightline exists.
Ted reacts from the lamp room by voice. If the burner is fitted first, the win state shows the ship sailing calmly into port, again from the lamp room. Gate 1 fail returns to the start of the slice; the final retry and save model is a Gate 2 decision. Set the duration from measured playtests so a first-time player who follows cues has room for some mistakes. The deadline length is reviewed once the return crossing from the outpost has been tested.

## Presentation and accessibility

All viewpoints are first-person; there are no cutaway or exterior cameras. The moored rowboat is seen through the lighthouse window, and the ship outcome from the lamp room (or heard elsewhere), so both need clear sightlines. Use the beacon as a consistent landmark from the sea. Budget dynamic lights around the beacon, nearby player lights, and key hazards; prototype rain and fog on target hardware before dressing the levels. Audio mixes by state: indoor machinery, shore surf, crossing wind and waves, foghorn, companion calls, the ship’s impact, and ship proximity. Put spoken navigation cues in subtitles with speaker attribution and a visual direction option. Remappable steering and interaction, controller prompts, adjustable sensitivity, and a reduced hazard-intensity preset (which also lowers wave intensity, if waves are built) support the promised legibility. Audio-only fail cues need a subtitle or visual alternative for deaf and hard-of-hearing players.

## Validation and integration

• Automate state transitions where practical: the return-departure event starts the clock once, repair updates the journal, gate opening advances the phase, cargo recovery preserves completion, the ship outcome resolves once per attempt as win or fail, and a restart or reload resumes a consistent phase with time and weather restored together.
• Run manual play sessions for steering feel, hazard readability (and wave readability, if built), Jeff’s cue usefulness, pressure without UI timer, retry fairness, the fail reason being understood from each expiry location, and both endings. Record observed failures and tune one variable set at a time.
• Hold an early deadline tuning pass in week 4 with at least one outside tester, rather than waiting until week 6.
• Keep an exportable playable build at each gate. An agent task is complete only when its changed scene/scripts, importable assets, setup notes, and verification evidence work in the integrated project.

The largest production risk remains boat feel; keeping waves as a stretch goal removes the hardest part of that risk from the critical path. The second is scope creep across repairs, cinematics, and environmental detail, and week 5 loading. Gate 0 and the ten-minute slice should decide whether the full game is feasible before those costs grow.
