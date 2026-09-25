Lighting the Storm — Technical Strategy

Basis: Executive Summary and source GDD. This is an implementation proposal, not a claim that the original GDD selected an engine or fixed numeric tuning values.

Engine and project shape

Proposed engine: Godot 4, using GDScript for the first playable. Its scene-based structure suits the compact locations and scripted interactions, and a single developer can iterate quickly without adding a toolchain. Commit the exact engine version and renderer choice with the initial project; evaluate controller input and storm lighting on the target PC early. If an existing Unity project or strong Unity experience changes this choice, retain the contracts below and prototype the boat there instead. Blender is the source for authored meshes; imported scene assets should have documented scale, collision, pivot, and naming conventions.

Keep scenes and scripts separately owned where possible: lighthouse, sea, outpost, shared player and interaction scenes, and a central game-state resource/controller. Store content such as repairs, dialogue, assistance presets, and journal text as data, with stable IDs. Avoid hard-wiring story progress into individual prop scripts.

Milestones and gates

|Gate                        |Deliverable                                                                                               |Acceptance                                                                                                                                                                |
|----------------------------|----------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|0. Steering spike           |Greybox powered boat on a sea that moves for atmosphere only, rocks, buoys and debris, readable heading and collision feedback.|A player can steer through a short route using steering alone; the designer can tune it without rewriting physics. Stop or redesign if the core crossing is not enjoyable.|
|1. Ten-minute vertical slice|One repair, rowboat crash seen from the window, gate opening, boarding with Jeff, outbound crossing, burner pickup, harder return crossing, burner fitting, placeholder ship with win and fail outcomes.|Playable end to end in about 10 minutes on keyboard and controller; the ship deadline starts only on boarding; a crossing mistake costs time but does not trap the run.|
|2. Narrative alpha          |Complete repairs, outpost discoveries, full dialogue, both outcomes.                                      |All story states can be finished; no dead-end save or cargo loss.                                                                                                         |
|3. Content and polish       |Final atmosphere, audio, accessibility, checkpoints, tuning and optional discoveries.                     |New-player sessions demonstrate legible navigation and the intended 30 minute pacing.                                                                                     |

Six-week prototype schedule

Assumes a solo developer working about 40 hours a week with AI assistance. Gate 0 closes at the end of week 2 and Gate 1 at the end of week 6.

|Week|Focus                                                                                   |Exit test                                          |
|----|----------------------------------------------------------------------------------------|---------------------------------------------------|
|1   |Project setup and asset pipeline; boat controller with fixed speed and one steering axis; greybox sea that moves visually; first rocks, buoys and debris.|The boat steers and collides reliably on the greybox sea.|
|2   |Steering feel, hazard readability, collision feedback and recovery (Gate 0).            |Go/no-go: steering past hazards is fun on its own. |
|3   |Outpost and burner pickup; return crossing with denser hazards; storm visibility and lighting tuned for readability.|Both crossings playable end to end.|
|4   |One repair, crash through the window, gate opening, Jeff at the engine boat, Jeff’s direction calls.|The full 10-minute path is playable.  |
|5   |Hidden ship deadline, win and fail outcomes, placeholder audio.                         |Both outcomes reachable.                           |
|6   |Playtests with 3–5 new players, tuning, bug fixing, tester build (Gate 1).              |The prototype outcome checks pass.                 |

Wave hazards are a stretch goal, not part of this schedule. Start them only after Gate 0 has passed, and only when the current week’s exit test is already met; the earliest sensible slot is spare time in week 5. Keep them behind a single on/off setting so the build always works without them, and cut them first if any week slips. If steering fails the week 2 go/no-go, redesign the crossing before starting week 3 work.

Core state contract

Use explicit phase states, for example LIGHTHOUSE_REPAIRS → CRASH_AND_GATE → BOARDING → OUTBOUND → OUTPOST → RETURN → FINAL_REPAIR → RESOLUTION (WIN or FAIL). Save phase, completed repair IDs, gate state, unlocked routes, burner state, elapsed deadline time, ship state, discoveries, and difficulty preset. Every transition has a single owner and can be replayed in a debug build. Use game events for audio, UI, and dialogue responses rather than allowing those systems to alter progression directly.

Invariants: the deadline is inactive before the first boarding event; Jeff is the only crossing companion; a burner pickup precedes return completion; the ship outcome resolves exactly once, as WIN (burner fitted before expiry) or FAIL (deadline expired). The journal reflects state, but never determines it.

Boat and weather simulation

Start with a constrained, tunable approximation: a forward-moving boat with one fixed speed and one player steering axis. The player steers but has no throttle. The core crossing challenge is steering past placed hazards (rocks, reefs, buoys, and floating debris) along a route that narrows and darkens as the storm worsens. The sea surface animates for atmosphere only and does not push the boat. Expose the fixed speed (a tuning value, not a player control), steering response, hazard spacing and density, collision penalty, and recovery delay as data. Tune for clear cause and effect.

Stretch goal, waves: if time allows (see the six-week schedule), add authored travelling wave fields that apply heading, roll, and temporary speed penalties according to impact angle and intensity, with wave spacing, wave force, and capsize threshold exposed as data. Build it as an optional layer behind one on/off setting, so the crossing stays complete and tuned without it. Prefer readable, authored waves over physically realistic water.

Use a shared hazard forecast for hazards (and wave crests, if built), boat reaction, and Jeff’s calls, so his warnings never disagree with the actual threat. Jeff’s calls read from the same safe-route signal, with explicit difficulty-dependent lead time and frequency. Never make both the world and the signal unreadable at once.

Prototype failure policy: a collision with a rock or debris (or a broadside wave hit, if waves are built) adds water, slows the boat or causes a brief capsize-and-recovery at a nearby safe point; these events consume deadline time. On return, cargo mishandling delays progress and creates a clear recovery interaction. Proposed: keep the burner recoverable aboard or at a marked nearby point, never permanently lost. Add a simple bailing interaction only if it improves the crossing in playtests; it must not overload the one-control steering promise.

Weather escalates by phase and elapsed deadline time through coherent changes to sea motion, hazard density, wind audio, rain, visibility, and lighting. Preserve a minimum visibility of nearby hazards (and wave cues, if built) and the immediate route on every preset. Use landmarks, compass, buoy silhouettes, and the beacon when facing home.

Repairs, crash and gate, and final pressure

Implement repair jobs from data: diagnosis, required fixed-toolkit item or interaction, puzzle steps, completion event, journal update, and optional route unlock. The initial slice uses one repair and one final burner installation. Later repairs can include optic, rotation, fuel/fog signal, and stormproofing, with short puzzle interactions and no crafting economy.

The crash and gate sequence is scripted and is part of the Gate 1 slice. After the repairs, Ted prompts the player to look out of the window; the rowboat carrying Jeff and Daniel crashes onto Bracken Isle in the player’s first-person view. Proposed: trigger the crash when the window is in view, with a fallback after a short delay so it cannot be missed. Ted then tells the player to open the lighthouse gate. Opening it is a single interaction; Jeff and Daniel walk into the lighthouse on their own along a scripted path, with no escort. The gate opening completes CRASH_AND_GATE and opens the route to the engine boat, where Jeff waits.

For the deadline, store a numeric internal time but display only the passenger ship’s position/lights and weather cues. It is the only timer in the game; the final repair runs on the same deadline. Proposed rules: start on first outbound boarding; stop during menus and deliberate pause; continue through playable crossings, outpost search, recoveries, and final repair; save remaining time at checkpoints. On expiry, trigger the fail state: the ship runs aground, seen in first person. If the burner is fitted first, the win state shows the ship sailing calmly into port. What follows the fail state (checkpoint retry or restart) is tracked in Decisions to be made. Set the duration from measured playtests so a first-time player who follows cues has room for some mistakes. Provide a debug time scale and event log for repeatable QA.

Presentation and accessibility

All viewpoints are first-person; there are no cutaway or exterior cameras. The crash is seen through the lighthouse window, and the ship outcome from the lighthouse, so both need clear sightlines. Use the beacon as a consistent landmark from the sea. Budget dynamic lights around the beacon, nearby player lights, and key hazards; prototype rain and fog on target hardware before dressing the levels. Audio mixes by state: indoor machinery, shore surf, crossing wind and waves, foghorn, companion calls, and ship proximity. Put spoken navigation cues in subtitles with speaker attribution and a visual direction option. Remappable steering and interaction, controller prompts, adjustable sensitivity, and a reduced hazard-intensity preset (which also lowers wave intensity, if waves are built) support the promised legibility.

Validation and integration

• Automate state transitions where practical: boarding starts the clock once, repair updates the journal, gate opening advances the phase, cargo recovery preserves completion, the ship outcome resolves once as win or fail, reload resumes a consistent phase.
• Run manual play sessions for steering feel, hazard readability (and wave readability, if built), Jeff’s cue usefulness, pressure without UI timer, checkpoint fairness, and both endings. Record observed failures and tune one variable set at a time.
• Keep an exportable playable build at each gate. An agent task is complete only when its changed scene/scripts, importable assets, setup notes, and verification evidence work in the integrated project.

The largest production risk remains boat feel; keeping waves as a stretch goal removes the hardest part of that risk from the critical path. The second is scope creep across repairs, cinematics, and environmental detail. Gate 0 and the ten-minute slice should decide whether the full game is feasible before those costs grow.