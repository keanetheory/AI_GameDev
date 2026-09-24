Lighthouse Keeper’s Apprentice — Technical Strategy

Basis: Executive Summary and source GDD. This is an implementation proposal, not a claim that the original GDD selected an engine or fixed numeric tuning values.

Engine and project shape

Proposed engine: Godot 4, using GDScript for the first playable. Its scene-based structure suits the compact locations and scripted interactions, and a single developer can iterate quickly without adding a toolchain. Commit the exact engine version and renderer choice with the initial project; evaluate controller input and storm lighting on the target PC early. If an existing Unity project or strong Unity experience changes this choice, retain the contracts below and prototype the boat there instead. Blender is the source for authored meshes; imported scene assets should have documented scale, collision, pivot, and naming conventions.

Keep scenes and scripts separately owned where possible: lighthouse, sea, outpost, shared player and interaction scenes, and a central game-state resource/controller. Store content such as repairs, dialogue, assistance presets, and journal text as data, with stable IDs. Avoid hard-wiring story progress into individual prop scripts.

Milestones and gates

|Gate                        |Deliverable                                                                                               |Acceptance                                                                                                                                                                |
|----------------------------|----------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|0. Steering spike           |Greybox powered boat, one wave type, rocks, readable heading and risk feedback.                           |A player can steer through a short route using steering alone; the designer can tune it without rewriting physics. Stop or redesign if the core crossing is not enjoyable.|
|1. Ten-minute vertical slice|One repair, departure, outbound pickup, harder return, beacon fitting, one companion and placeholder ship.|Playable end to end on keyboard and controller; ship countdown starts only on boarding; a mistake costs time but does not trap the run.                                   |
|2. Narrative alpha          |Complete repairs, wreck rescue, both companions, outpost discoveries, both outcomes.                      |All story states and branches can be finished; no dead-end save or cargo loss.                                                                                            |
|3. Content and polish       |Final atmosphere, audio, accessibility, checkpoints, tuning and optional secrets.                         |New-player sessions demonstrate legible navigation and the intended 45–60 minute pacing.                                                                                  |

Core state contract

Use explicit phase states, for example LIGHTHOUSE_REPAIRS → WRECK_RESCUE → COMPANION_CHOICE → OUTBOUND → OUTPOST → RETURN → FINAL_REPAIR → RESOLUTION. Save phase, completed repair IDs, unlocked routes, companion ID, burner state, elapsed deadline time, ship state, discoveries, and difficulty preset. Every transition has a single owner and can be replayed in a debug build. Use game events for audio, UI, and dialogue responses rather than allowing those systems to alter progression directly.

Invariants: the deadline is inactive before the first boarding event; there is exactly one selected companion; a burner pickup precedes return completion; ship collision resolves once; the player can always finish after a ship collision. The journal reflects state, but never determines it.

Boat and weather simulation

Start with a constrained, tunable approximation: a forward-moving boat with automatic motor speed and one player steering axis. Compute wave influence from authored travelling wave fields and wind direction; apply heading, roll, and speed penalties according to wave impact angle and intensity. Expose speed, steering response, wave spacing, wave force, capsize threshold, and recovery delay as data. Tune for clear cause and effect before seeking physically realistic water.

Use a shared hazard forecast for visual crests, boat reaction, and companion cues. That prevents warnings from disagreeing with the actual threat except when Daniel is intentionally wrong. Jeff’s calls and Daniel’s flashlight should share the same safe-route signal, with explicit difficulty-dependent lead time, frequency, and error rate. Daniel’s errors must still be learnable and recoverable; never make both the world and the signal unreadable at once.

Prototype failure policy: a broadside hit adds water, slows the boat or causes a brief capsize-and-recovery at a nearby safe point; these events consume deadline time. On return, cargo mishandling delays progress and creates a clear recovery interaction. Proposed: keep the burner recoverable aboard or at a marked nearby point, never permanently lost. Add a simple bailing interaction only if it improves the crossing in playtests; it must not overload the one-control steering promise.

Weather escalates by phase and elapsed deadline time through coherent changes to waves, wind audio, rain, visibility, and lighting. Preserve a minimum visibility of nearby wave cues and the immediate route on every preset. Use landmarks, compass, buoy silhouettes, and the beacon when facing home.

Repairs, rescue, and final pressure

Implement repair jobs from data: diagnosis, required fixed-toolkit item or interaction, puzzle steps, completion event, journal update, and optional route unlock. The initial slice uses one repair and one final burner installation. Later repairs can include optic, rotation, fuel/fog signal, and stormproofing, with short puzzle interactions and no crafting economy.

The wreck rescue is a guided route between the wreck and lighthouse; both Jeff and Daniel must arrive before companion selection. For the slice, script the choice and rescue state as a temporary start condition, then replace it with the full sequence at Gate 2.

For the deadline, store a numeric internal time but display only the passenger ship’s position/lights and weather cues. Proposed rules: start on first outbound boarding; stop during menus and deliberate pause; continue through playable crossings, outpost search, recoveries, and final repair; save remaining time at checkpoints. On expiry, queue a visible ship collision and the late ending, while letting the player finish restoring the beacon. Set the duration from measured playtests so a first-time player who follows cues has room for some mistakes. Provide a debug time scale and event log for repeatable QA.

Presentation and accessibility

Use the beacon as a consistent exterior reference. Budget dynamic lights around the beacon, nearby player lights, and key hazards; prototype rain and fog on target hardware before dressing the levels. Audio mixes by state: indoor machinery, shore surf, crossing wind and waves, foghorn, companion calls, and ship proximity. Put spoken navigation cues in subtitles with speaker attribution and a visual direction option; make Daniel’s light readable without relying solely on colour. Remappable steering and interaction, controller prompts, adjustable sensitivity, and a reduced wave-intensity preset support the promised legibility.

Validation and integration

• Automate state transitions where practical: boarding starts the clock once, repair updates journal and gate, cargo recovery preserves completion, ship outcome resolves once, reload resumes a consistent phase.
• Run manual play sessions for steering feel, wave readability, Jeff/Daniel cue usefulness, pressure without UI timer, checkpoint fairness, and both endings. Record observed failures and tune one variable set at a time.
• Keep an exportable playable build at each gate. An agent task is complete only when its changed scene/scripts, importable assets, setup notes, and verification evidence work in the integrated project.

The largest production risk remains boat feel. The second is scope creep across repairs, cinematics, and environmental detail. Gate 0 and the ten-minute slice should decide whether the full game is feasible before those costs grow.