# Lighting the Storm — AI Agent Strategy

Purpose: let a solo creator delegate bounded implementation and content tasks while retaining authority over design, tone, and the release build. Orchestrator agents split briefs and oversee delegated work; the creator retains the final say. Read the Executive Summary and Technical Strategy before taking a task. Decisions to be made lists unresolved canon; the Decisions log in the Executive Summary lists what has been decided. Dreams for the game holds ideas outside the current scope; do not build anything from it without the creator’s approval.

## Change log (post-review amendments, 1 October 2026)

• Added an orchestration and oversight layer: orchestrators delegate to worker agents, track dependencies and contracts, and escalate canon decisions.
• Added Story/Fail-State and Hazard Forecast worker roles.
• Updated working rules, handoffs, sequence, example briefs and checklist for the review decisions (return-crossing clock start, fail-state contract, storm split, two Gate 1 repairs, Ted lock-in, no crash).
• Added a Handoff format section: file types for engine content and game data, and a standard HANDOFF.md note per task.
• Fail-state brief and example orchestrator brief updated: three fail states, all after the return crossing begins (return crossing, lamp room, stairs).
• Added a working rule: no significant outpost detail until the creator considers the prototype complete.
• Engine confirmed by the creator as Godot 4 with GDScript, after reviewing the Engine Comparison pros and cons. Agents use Godot’s text-based files.

## Working rules for every agent

1. Work from a task brief that names a goal, inputs, owned files or scenes, interfaces, acceptance checks, and dependencies. Ask when a canon choice is unresolved (see Decisions to be made); do not silently decide it. Treat items in the Executive Summary’s Decisions log as canon.
2. Keep changes narrow and reversible. Make one branch or change set per task; do not overwrite another agent’s scene, script, or source asset. If an integration contract must change, raise it before editing dependants.
3. Match the four design pillars in the Executive Summary (the light must return; the storm sets the clock; your hands, your eyes; dread you can read) and the small-world scope rule. No combat, monster reveal, jump scare, visible timer, quest markers, non-first-person cameras, or new major location.
4. Return actual editable outputs, source files and licences/provenance for external assets, import settings, test instructions, and known limitations. Mockups or prose alone do not count as implementation.
5. Run the relevant project import/build and focused checks. State what you observed, what you could not verify, and which human decision remains.
6. The creator reviews and merges each change. AI output is a first pass; dialogue performance, art fit, tuning, and story interpretation require human judgement.
7. Do not build anything marked Proposed, deferred, or on the cut list (waves, route branching, further repairs beyond the first two) without the creator’s go-ahead. Do not add significant detail to the outpost until the creator considers the prototype complete.

## Orchestration and oversight

The creator delegates goals to orchestrators; orchestrators delegate bounded tasks to worker agents. Orchestrators plan, sequence, and check; they do not decide design.

|Orchestrator              |Responsibility                                                                                                                                  |Escalates to the creator when                                                         |
|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
|Production Orchestrator   |Turns a creator goal or gate into a task list; writes task briefs; assigns work to worker roles; orders dependencies; tracks status against the six-week schedule; keeps event IDs and contracts in sync across agents; assembles the integrated build.|A schedule exit test is missed; a contract must change; two tasks conflict; week 5 load slips (second repair, waves). |
|Canon and Review Orchestrator|Checks every handoff against the review checklist, the four pillars, the scope rule, and the Decisions log; blocks work that decides an unresolved story point; keeps the Decisions log and changed contracts current; collects QA findings.|A canon question appears (for example Ted, retry model, penalty rules); a pillar test fails; a fail-state or ship-reveal rule is unclear.|

## Orchestrator rules:
1. Brief before delegating. No worker task starts without a brief that names owner, inputs, interfaces, acceptance checks, and dependencies.
2. Hold the contracts. Orchestrators own event names, save IDs, the state contract, and the hazard-forecast interface; workers propose changes, orchestrators raise them.
3. Gate checks. Before a gate, the orchestrators confirm every acceptance item in the Technical Strategy with evidence (builds, logs, playtest notes) and report any gap. The creator decides whether a gate is passed.
4. Report in a fixed format: what was delegated, what came back, what passed review, what failed and why, what remains, and which creator decisions are blocking.
5. Never merge. Only the creator merges, ships, or approves tone, steering feel, voice, and lore.
6. Limit parallelism. Run at most the tasks the integration contract supports; Boat/Physics and Gameplay/Systems agree on event names before parallel implementation.

## Ownership and handoffs

|Agent           |Initial deliverable                                                                |Input contract                                                |Review gate                                        |
|----------------|-----------------------------------------------------------------------------------|--------------------------------------------------------------|---------------------------------------------------|
|Boat/Physics    |Steering spike, hazard collisions, boat reaction, docking, recovery, tunable parameters. Wave fields only as a later stretch task.|Hazard forecast API, one steering axis, recovery event, dock zones.|Creator plays Gate 0; readable, enjoyable steering.|
|Hazard Forecast |Shared hazard forecast and single safe-route signal read by hazards, boat reaction and Jeff’s calls.|Route data, hazard placement, difficulty presets.|Jeff’s calls never disagree with the forecast; one route only until branching is approved.|
|Level Layout    |Greybox lighthouse route, window view of the moored rowboat and island gate, short sea corridor, outpost pickup, lamp-room sightline to the ship and island rocks.|Location sizes, beacon visibility, interaction anchors.       |Traversal and camera checks in engine.             |
|Gameplay/Systems|Phase controller, repair interaction (two repairs for Gate 1), shelter and gate trigger, boarding trigger, return-departure clock trigger, cargo, win and fail states, restart.|Stable event and save IDs from Technical Strategy.            |Gate 1 complete end-to-end; no dead ends.          |
|Story/Fail-State|Fail-state presentation (horn, crash, silence, “Failed” screen, reason line), ship reveal at the boarding threshold, Ted’s lamp-room staging and lines.|Fail-state contract, phase events, Decisions log.|Fail reason understood from every expiry location; no cutaway camera.|
|Lighting        |Beacon sweep, warm/cold contrast, storm visibility presets.                        |Scene anchors, performance budget, hazard visibility rules.   |Beacon and hazards remain legible at every phase. |
|Sound           |Layered storm, machinery and foghorn, ship impact, cue mix; source list and licences. Perceptual storm cues follow elapsed time.|Escalation events and speaker priority.                       |Jeff’s warnings remain audible; no shock stingers. |
|Asset           |Props and modular set dressing with source meshes and import notes.                |Scale, pivot, collision, palette and approved reference sheet.|Assets import cleanly and fit the intended tone.   |
|Dialogue        |Ted/Jeff/Daniel lines, subtitle variants, journal text in structured data. Voice lines only for Ted at the lamp.|Character voices, phase events, ambiguity constraint.         |Creator approves voice and lore before recording.  |
|QA              |Reproducible scenario list and bug reports, including the win and fail outcomes and restart.|Playable build, event log, acceptance checklist.              |Developer reproduces and prioritises findings.     |

These are work roles, not a fixed number of agents running at once. One agent can take successive bounded tasks. Boat/Physics and Gameplay/Systems agree on event names before parallel implementation; Level Layout provides scene anchors before Lighting, Sound, and Asset integrate.

## Handoff format

Engine: Godot 4 with GDScript (confirmed by the creator). Godot stores scenes, scripts and resources as plain text, so agents can read, edit and diff them, and the creator can review each change set.

|What is handed off          |Format                                                                                       |Notes                                                                                           |
|----------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
|Scenes, scripts, resources  |Godot text files: .tscn, .gd, .tres                                                         |One branch or change set per task; no edits to another agent’s files.                           |
|Game data                   |JSON or .tres with stable IDs                                                                |Repairs, dialogue, journal text, difficulty presets, hazard placement, assist presets.          |
|Source art and audio        |Blender .blend and exported glTF for meshes; WAV for audio sources; import settings as .import files|Provenance and licence recorded per asset. Scale, pivot, collision and naming follow Technical Strategy.|
|Task handoff note           |HANDOFF.md, one per task, stored with the change set                                         |Fixed headings, below. Written by the worker agent.                                             |
|Orchestrator report         |REPORT.md, one per task or per gate                                                          |Fixed headings, below. Written by the orchestrator from the HANDOFF.md notes.                   |
|Contract changes            |Proposal in the HANDOFF.md, then an update to the project documentation once the creator accepts it|Event names, save IDs, state contract and the hazard-forecast interface.          |

HANDOFF.md headings, in this order:
1. Task and goal.
2. Files changed (paths, scenes and resources added or edited).
3. How to run and test (clean checkout, engine version, steps, controls).
4. Observed behaviour (what was seen, with evidence such as event log lines or a short capture).
5. Not verified (what could not be checked, and why).
6. Licences and provenance (every external asset).
7. Interface or contract changes proposed.
8. Open creator decisions (canon questions, unresolved items).

REPORT.md headings, in this order: what was delegated; what came back; what passed review; what failed and why; what remains; creator decisions that are blocking.

Rules:
• A handoff without a HANDOFF.md is incomplete and goes back to the worker.
• Use the stable IDs in the shared contract for events, saves and data entries; do not invent new IDs without raising a contract change.
• Keep notes short and factual; state what was observed rather than what was intended.

## Recommended sequence

1. Creator: settle the items in Decisions to be made, starting with the Gate 0 feel target and target hardware. The engine is confirmed as Godot 4. Lock Ted’s presence by the end of week 3.
2. Production Orchestrator: break the work into briefs and the dependency order; Canon and Review Orchestrator confirms the Decisions log is current.
3. Boat/Physics + Hazard Forecast + creator: build and play the steering spike. Pause broader content production until the crossing works.
4. Level Layout and Gameplay/Systems: establish greybox route, interaction anchors, event IDs, the return-departure clock trigger, and a running Gate 1 slice.
5. Lighting and Sound: add just enough feedback to evaluate readable hazards, storm escalation (perceptual channel by time, hazard channel by phase and position), beacon, and ship pressure.
6. Story/Fail-State: implement the fail-state contract before week 5 ends.
7. Dialogue and Asset: fill approved content after the slice proves the route; keep sources editable.
8. QA and creator: test first-time play, both input methods, all phase transitions, restart, and the win and fail endings from every expiry location as they are added.
9. Stretch, waves: only after Gate 0 passes and the six-week schedule in Technical Strategy has room, Boat/Physics adds wave hazards as an optional layer behind one on/off setting. QA confirms the build still plays correctly with waves off. Do not start this task without the creator’s go-ahead.
10. Before Gate 2: Canon and Review Orchestrator tables the retry and save model, penalty rules, and branching cut-list item for the creator’s decision.

## Example agent task brief

> **Task:** Implement the Gate 0 boat steering spike in the selected engine. **Inputs:** Technical Strategy boat section, greybox sea scene, approved event IDs. **Owned output:** boat scene/controller and tuning resource, plus a short README. **Constraints:** one fixed speed with no throttle, one steering axis, placed rock, buoy and debris hazards, no wave forces (waves are a later stretch task), no visible timer, no irreversible failure. **Acceptance:** keyboard and controller both complete a two-minute route; approaching hazards and collision risk are visible; a collision recovers; steering and hazard strength can be tuned from data. **Handoff:** changed files, playable build instructions, observed behaviour, known limitations, and any interface change proposal. Stop and ask the creator to assess feel before expanding the system.

## Example orchestrator brief

> **Goal (from creator):** Deliver the Gate 1 fail-state presentation. **Orchestrator:** Production Orchestrator. **Delegates to:** Story/Fail-State (presentation), Level Layout (lamp-room sightline), Sound (horn, impact, silence), Gameplay/Systems (FAIL resolve, restart), QA (test from each expiry location). **Inputs:** Executive Summary fail-state contract; Technical Strategy fail-state presentation. **Constraints:** no cutaway camera; FAIL resolves once per attempt; Gate 1 restart returns to the start of the slice; three fail states, all after the return crossing begins: audio-only on the return crossing and on the stairs (unless a window sightline exists), and the ship seen and heard from the lamp room, which needs a clear sightline. **Acceptance:** a tester can say why they failed from each location; the event log shows a single FAIL. **Report:** per task status, review result, open creator decisions. **Escalate:** any need to change the retry model, add a camera, or add voice cost beyond Ted’s lamp-room lines.

## Review checklist for every handoff

- Does the work run in the integrated project, from a clean checkout, with documented inputs?
- Is the output editable and are third-party rights and licences recorded?
- Are state changes and event IDs consistent with the shared contract?
- Does it pass its task’s concrete acceptance checks?
- Does it pass each design pillar’s test and the scope rule, and avoid deciding an unresolved story point?
- Does it respect the Decisions log (return-crossing clock start, storm split, two Gate 1 repairs, no crash, fail-state contract)?
- What did human playtesting reveal about feel, clarity, and pacing?
- Has the orchestrator reported the result, including failures and blocked decisions?
- Is there a complete HANDOFF.md in the standard format, with data in the agreed file types?

When a review fails, return a focused revision task with a reproducible observation. Record accepted decisions and changed contracts in the project documentation so later agents receive the same source of truth.
