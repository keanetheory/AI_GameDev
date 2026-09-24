Lighthouse Keeper’s Apprentice — AI Agent Strategy

Purpose: let a solo creator delegate bounded implementation and content tasks while retaining authority over design, tone, and the release build. Read the Executive Summary and Technical Strategy before taking a task.

Working rules for every agent

1. Work from a task brief that names a goal, inputs, owned files or scenes, interfaces, acceptance checks, and dependencies. Ask when a canon choice is unresolved; do not silently decide it.
2. Keep changes narrow and reversible. Make one branch or change set per task; do not overwrite another agent’s scene, script, or source asset. If an integration contract must change, raise it before editing dependants.
3. Match the four design rules: dread, environmental threat, legible pressure, and compact locations. No combat, monster reveal, jump scare, visible timer, or new major location.
4. Return actual editable outputs, source files and licences/provenance for external assets, import settings, test instructions, and known limitations. Mockups or prose alone do not count as implementation.
5. Run the relevant project import/build and focused checks. State what you observed, what you could not verify, and which human decision remains.
6. The creator reviews and merges each change. AI output is a first pass; dialogue performance, art fit, tuning, and story interpretation require human judgement.

Ownership and handoffs

|Agent           |Initial deliverable                                                                |Input contract                                                |Review gate                                        |
|----------------|-----------------------------------------------------------------------------------|--------------------------------------------------------------|---------------------------------------------------|
|Boat/Physics    |Steering spike, authored wave fields, boat reaction and tunable parameters.        |Hazard forecast API, one steering axis, recovery event.       |Creator plays Gate 0; readable, enjoyable steering.|
|Level Layout    |Greybox lighthouse route, short sea corridor, outpost pickup and sightlines.       |Location sizes, beacon visibility, interaction anchors.       |Traversal and camera checks in engine.             |
|Gameplay/Systems|Phase controller, repair interaction, boarding trigger, cargo and ending states.   |Stable event and save IDs from Technical Strategy.            |Gate 1 complete end-to-end; no dead ends.          |
|Lighting        |Beacon sweep, warm/cold contrast, storm visibility presets.                        |Scene anchors, performance budget, hazard visibility rules.   |Beacon and wave cues remain legible at every phase.|
|Sound           |Layered storm, machinery and foghorn, cue mix; source list and licences.           |Escalation events and speaker priority.                       |Jeff’s warnings remain audible; no shock stingers. |
|Asset           |Props and modular set dressing with source meshes and import notes.                |Scale, pivot, collision, palette and approved reference sheet.|Assets import cleanly and fit the intended tone.   |
|Dialogue        |Ted/Jeff/Daniel lines, subtitle variants, journal text in structured data.         |Character voices, phase events, ambiguity constraint.         |Creator approves voice and lore before recording.  |
|QA              |Reproducible scenario list and bug reports, including both companions and outcomes.|Playable build, event log, acceptance checklist.              |Developer reproduces and prioritises findings.     |

These are work roles, not eight agents that must run at once. One agent can take successive bounded tasks. Boat/Physics and Gameplay/Systems agree on event names before parallel implementation; Level Layout provides scene anchors before Lighting, Sound, and Asset integrate.

Recommended sequence

1. Creator: approve engine, reconcile Ted/coda canon, define the Gate 0 feel target and target hardware.
2. Boat/Physics + creator: build and play the steering spike. Pause broader content production until the crossing works.
3. Level Layout and Gameplay/Systems: establish greybox route, interaction anchors, event IDs, and a running Gate 1 slice.
4. Lighting and Sound: add just enough feedback to evaluate readable waves, storm escalation, beacon, and ship pressure.
5. Dialogue and Asset: fill approved content after the slice proves the route; keep sources editable.
6. QA and creator: test first-time play, both input methods, all phase transitions, both companion variants and endings as they are added.

Example agent task brief

> **Task:** Implement the Gate 0 boat steering spike in the selected engine. **Inputs:** Technical Strategy boat section, greybox sea scene, approved event IDs. **Owned output:** boat scene/controller and tuning resource, plus a short README. **Constraints:** automatic propulsion, one steering axis, authored wave hazards, no visible timer, no irreversible failure. **Acceptance:** keyboard and controller both complete a two-minute route; approaching crests and broadside risk are visible; a capsize recovers; steering and hazard strength can be tuned from data. **Handoff:** changed files, playable build instructions, observed behaviour, known limitations, and any interface change proposal. Stop and ask the creator to assess feel before expanding the system.

Review checklist for every handoff

• Does the work run in the integrated project, from a clean checkout, with documented inputs?
• Is the output editable and are third-party rights and licences recorded?
• Are state changes and event IDs consistent with the shared contract?
• Does it pass its task’s concrete acceptance checks?
• Does it preserve the design rules and avoid deciding an unresolved story point?
• What did human playtesting reveal about feel, clarity, and pacing?

When a review fails, return a focused revision task with a reproducible observation. Record accepted decisions and changed contracts in the project documentation so later agents receive the same source of truth.