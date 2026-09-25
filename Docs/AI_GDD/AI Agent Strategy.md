Lighting the Storm — AI Agent Strategy

Purpose: let a solo creator delegate bounded implementation and content tasks while retaining authority over design, tone, and the release build. Read the Executive Summary and Technical Strategy before taking a task. Decisions to be made lists unresolved canon. Dreams for the game holds ideas outside the current scope; do not build anything from it without the creator’s approval.

Working rules for every agent

1. Work from a task brief that names a goal, inputs, owned files or scenes, interfaces, acceptance checks, and dependencies. Ask when a canon choice is unresolved (see Decisions to be made); do not silently decide it.
2. Keep changes narrow and reversible. Make one branch or change set per task; do not overwrite another agent’s scene, script, or source asset. If an integration contract must change, raise it before editing dependants.
3. Match the four design pillars in the Executive Summary (the light must return; the storm sets the clock; your hands, your eyes; dread you can read) and the small-world scope rule. No combat, monster reveal, jump scare, visible timer, quest markers, non-first-person cameras, or new major location.
4. Return actual editable outputs, source files and licences/provenance for external assets, import settings, test instructions, and known limitations. Mockups or prose alone do not count as implementation.
5. Run the relevant project import/build and focused checks. State what you observed, what you could not verify, and which human decision remains.
6. The creator reviews and merges each change. AI output is a first pass; dialogue performance, art fit, tuning, and story interpretation require human judgement.

Ownership and handoffs

|Agent           |Initial deliverable                                                                |Input contract                                                |Review gate                                        |
|----------------|-----------------------------------------------------------------------------------|--------------------------------------------------------------|---------------------------------------------------|
|Boat/Physics    |Steering spike, hazard collisions, boat reaction and tunable parameters. Wave fields only as a later stretch task.|Hazard forecast API, one steering axis, recovery event.|Creator plays Gate 0; readable, enjoyable steering.|
|Level Layout    |Greybox lighthouse route, window view of the crash, gate, short sea corridor, outpost pickup and sightlines.|Location sizes, beacon visibility, interaction anchors.       |Traversal and camera checks in engine.             |
|Gameplay/Systems|Phase controller, repair interaction, crash trigger, gate, boarding trigger, cargo, win and fail states.|Stable event and save IDs from Technical Strategy.            |Gate 1 complete end-to-end; no dead ends.          |
|Lighting        |Beacon sweep, warm/cold contrast, storm visibility presets.                        |Scene anchors, performance budget, hazard visibility rules.   |Beacon and hazards remain legible at every phase. |
|Sound           |Layered storm, machinery and foghorn, cue mix; source list and licences.           |Escalation events and speaker priority.                       |Jeff’s warnings remain audible; no shock stingers. |
|Asset           |Props and modular set dressing with source meshes and import notes.                |Scale, pivot, collision, palette and approved reference sheet.|Assets import cleanly and fit the intended tone.   |
|Dialogue        |Ted/Jeff/Daniel lines, subtitle variants, journal text in structured data.         |Character voices, phase events, ambiguity constraint.         |Creator approves voice and lore before recording.  |
|QA              |Reproducible scenario list and bug reports, including the win and fail outcomes.   |Playable build, event log, acceptance checklist.              |Developer reproduces and prioritises findings.     |

These are work roles, not eight agents that must run at once. One agent can take successive bounded tasks. Boat/Physics and Gameplay/Systems agree on event names before parallel implementation; Level Layout provides scene anchors before Lighting, Sound, and Asset integrate.

Recommended sequence

1. Creator: settle the items in Decisions to be made, starting with the engine, Ted’s presence, the Gate 0 feel target and target hardware.
2. Boat/Physics + creator: build and play the steering spike. Pause broader content production until the crossing works.
3. Level Layout and Gameplay/Systems: establish greybox route, interaction anchors, event IDs, and a running Gate 1 slice.
4. Lighting and Sound: add just enough feedback to evaluate readable hazards, storm escalation, beacon, and ship pressure.
5. Dialogue and Asset: fill approved content after the slice proves the route; keep sources editable.
6. QA and creator: test first-time play, both input methods, all phase transitions, and the win and fail endings as they are added.
7. Stretch, waves: only after Gate 0 passes and the six-week schedule in Technical Strategy has room, Boat/Physics adds wave hazards as an optional layer behind one on/off setting. QA confirms the build still plays correctly with waves off. Do not start this task without the creator’s go-ahead.

Example agent task brief

> **Task:** Implement the Gate 0 boat steering spike in the selected engine. **Inputs:** Technical Strategy boat section, greybox sea scene, approved event IDs. **Owned output:** boat scene/controller and tuning resource, plus a short README. **Constraints:** one fixed speed with no throttle, one steering axis, placed rock, buoy and debris hazards, no wave forces (waves are a later stretch task), no visible timer, no irreversible failure. **Acceptance:** keyboard and controller both complete a two-minute route; approaching hazards and collision risk are visible; a collision recovers; steering and hazard strength can be tuned from data. **Handoff:** changed files, playable build instructions, observed behaviour, known limitations, and any interface change proposal. Stop and ask the creator to assess feel before expanding the system.

Review checklist for every handoff

• Does the work run in the integrated project, from a clean checkout, with documented inputs?
• Is the output editable and are third-party rights and licences recorded?
• Are state changes and event IDs consistent with the shared contract?
• Does it pass its task’s concrete acceptance checks?
• Does it pass each design pillar’s test and the scope rule, and avoid deciding an unresolved story point?
• What did human playtesting reveal about feel, clarity, and pacing?

When a review fails, return a focused revision task with a reproducible observation. Record accepted decisions and changed contracts in the project documentation so later agents receive the same source of truth.