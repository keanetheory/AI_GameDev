Lighting the Storm — What’s Changed

Post-review amendments, 1 October 2026. This compares the three amended documents with their 25 September 2026 originals. The originals are unchanged in the source folder. Each section below covers one document and is grouped by theme. Review references (for example “Issue #1”) point to the Top 5 issues in the review board’s synthesis; “Decision A–E” are the five disagreements the creator resolved.

At a glance

|Theme                          |Exec Summary|Technical Strategy|AI Agent Strategy|
|-------------------------------|:----------:|:----------------:|:---------------:|
|Crash removed (sailors shelter)|     ✔      |        ✔         |        ✔        |
|Clock starts on return crossing |     ✔      |        ✔         |        ✔        |
|Fail-state contract            |     ✔      |        ✔         |        ✔        |
|Retry model (Decision A)       |     ✔      |        ✔         |        ✔        |
|Storm split (Decision B)       |     ✔      |        ✔         |        ✔        |
|Route branching deferred (C)   |     ✔      |        ✔         |        ✔        |
|Discoveries moved (Decision D) |     ✔      |        ✔         |                 |
|Ted locked, staged (Decision E)|     ✔      |        ✔         |        ✔        |
|Two repairs for Gate 1         |     ✔      |        ✔         |        ✔        |
|Orchestrator oversight         |            |                  |        ✔        |
|Engine confirmed (Godot 4)     |     ✔      |        ✔         |        ✔        |
|Handoff format (HANDOFF.md)    |            |                  |        ✔        |

Not changed in any document: the four pillars’ intent, the scope rule, waves as a stretch goal, the one-control fixed-speed boat, and Jeff as the only crossing companion.

---

1. Exec Summary

File: Final_GDD_Post_Review/Exec Summary.md

Story and cast
• Crash removed. The rowboat no longer crashes. Jeff and Daniel, overwhelmed by the storm, moor on the island looking for shelter. Ted sees them from the window and tells the player to open the island gate (the same gate as before). Step 2 is renamed “Shelter and gate”.
• Jeff. Motivation added: he has realised the storm is getting nasty and wants to stop the ship being wrecked. After the second crossing he tells the player to go on without him (“go go go, don’t wait for me”). His reaction to the outcome is not recorded.
• Daniel. Goes to the basement and stays there. His reaction to the outcome is not recorded.
• Ted (Decision E). Presence to be locked by the end of week 3. He is staged at the lamp for the final repair and for both outcomes, with voice and position only (no separate cutscene). He also names the ship at the boarding threshold.
• Apprentice. Stated explicitly as never speaking, so others give the moral beat.
• Rowboat. “Wrecked” changed to “moored” in the two-boats note.

Deadline and ship stakes (Issues #2, #3, #5)
• Clock start. The deadline starts when the player, with the burner aboard, sets off on the return crossing, instead of on boarding. There is no fail state before then, so the outbound crossing and outpost are free practice. Pre-deadline text updated to match.
• Ship introduced. The ship now appears at the boarding threshold, with Ted naming its lights as the reason for the errand. This addresses the review finding that the stakes were never introduced in-game.
• Pillar 2 and pillar 3. Pillar 2 adds the split: elapsed time drives what the player perceives, phase and position drive what they collide with. Pillar 3 now reads “see the sailors from the window” and “see or hear the ship’s fate”. Pillar 4 adds “a stated reason on failure”.

Fail state and retry (Issue #1, Issue #2, Decision A)
• New section: Fail-state contract. Every fail runs: foghorn, ship crashes into the island, silence, “Failed” title screen. The deadline runs only from the return crossing, so there are three fail states. On the return crossing it is audio only. In the lamp room the player sees the ship hit the island and the audio still sounds. On the stairs it is audio only unless a window sightline exists. A short reason line is always shown.
• Retry. For Gate 1 a fail restarts the slice. The full retry and save model is settled before Gate 2, and must not produce unwinnable saves.
• Outcome step. Step 8 now reads “the ship crashes into the island” (was “runs aground”), with Ted reacting.

Scope and content (Decisions C, D)
• Discoveries. The core folk-horror discoveries move to the lighthouse and island, before boarding and outside the deadline, tied to why the beacon failed. The outpost keeps a lighter set.
• Gate 1 repairs. Two repairs in the prototype (was one); further repairs move to Gate 2 and the full game. Prototype scope text updated.
• Route branching. Added to the out-of-prototype list and the cut list. “Unlocked routes” is no longer a feature.
• Crossing penalties. Noted as deliberately loose for Gate 1, to be reviewed for the full game.

Added sections
• Change log at the top.
• Gate 2+ estimate and ranked cut list (placeholder). Provisional order: waves, route branching, repairs beyond two, outpost discoveries beyond the light set. Estimates and owners are to be added after Gate 1.
• Decisions log table at the end, recording the twelve review outcomes and the later engine confirmation (Godot 4 with GDScript).
• Outcome checks updated: ship introduced at the boarding threshold, a failed player can say why, a fail restarts the slice, and the final retry and save model is tested for unwinnable saves.

Not changed: tone, no-combat and no-jump-scare rules, the 30-minute and 10-minute targets, the Steam release target, and the audio and lighting direction.

---

2. Technical Strategy

File: Final_GDD_Post_Review/Technical Strategy.md

Milestones and gates
• Gate 0. Now also delivers the shared hazard forecast with a single safe-route signal (it was previously missing from the schedule).
• Gate 1. Two repairs; Ted seeing the moored rowboat from the window; island gate; clock starts on the return crossing; a fail restarts the slice; a “Failed” title screen; a failed player is told why.
• Gate 2. Adds lighthouse and island discoveries and the final retry and save model; a reload must restore time and weather together; route branching reviewed as a cut-list candidate.
• Gate 3. Checkpoints are now conditional on the Gate 2 model.

Six-week schedule (Issue: week 4 overloaded)
• Week 2. Adds the hazard forecast to the feel work.
• Week 3. Adds docking and disembarking; Ted’s presence must be locked by the end of this week.
• Week 4. Rebalanced: one repair, window and gate, Jeff’s calls, return-crossing clock trigger, plus a first deadline tuning pass with an outside tester. The second repair is moved out.
• Week 5. Now holds the second repair, the deadline, the fail-state presentation, the lamp-room sightline and Ted’s lamp voice lines. A risk note says this week is heavily loaded and that the creator, not an agent, decides what gives.
• Week 6. Unchanged.

State contract and save data (Issue #1)
• Phase rename. CRASH_AND_GATE becomes SHELTER_AND_GATE.
• Save fields. “Unlocked routes” removed.
• Invariants. The deadline is inactive until the return-departure event; the outcome resolves exactly once per attempt (was “exactly once”). A rule added that “Proposed” items must not be enforced as invariants or gate criteria until approved.
• Retry and snapshots. New paragraph: Gate 1 restarts the slice; Gate 2 decides the final model. Any snapshot restores elapsed time and weather together, so a reload cannot place a player in a guaranteed fail. If phase-start snapshots are used, a minimum remaining time must be defined. “Save remaining time at checkpoints” is removed.

Boat and weather
• Two weather channels (Decision B). Perceptual channel (wind, rain, lightning, thunder, ship’s lights, sky mood) follows elapsed time. Hazard channel (density, route width, hazard visibility) follows phase and route position only. Elapsed time never increases what the player collides with, which also makes offline tuning possible.
• Docking and recovery. Because the boat cannot stop, docking at the outpost and lighthouse jetties is automatic. Leaving the corridor or missing a dock approach triggers a recovery to the last safe point at a time cost.
• Hazard forecast. Explicitly one safe-route signal; not designed for multiple routes until branching is approved.
• Penalty rules. Marked loose for Gate 1, with exact costs and limits to be written down for the full game.

Sequences and deadline
• Shelter-and-gate sequence replaces the crash sequence. No crash; moored rowboat seen from the window; Daniel goes to the basement.
• Ted’s second half. Voice lines delivered from the lamp room only; each added line is flagged as voice-over cost.
• Deadline rules. Starts at the return-departure trigger (burner aboard, boat under way); no fail before it; the ship holds at its starting lights until the clock starts; pause exploits to be checked before Gate 2.
• Fail-state presentation. New sub-section specifying the sequence per location, the lamp-room sightline, and Ted’s reaction by voice.

Presentation, validation and risks
• Audio mix adds the ship’s impact. Audio-only fail cues need a subtitle or visual alternative.
• Validation adds restart and reload consistency, the fail reason being understood from each expiry location, and an early week 4 deadline tuning pass.
• Risks add week 5 loading alongside boat feel and scope creep.

Engine
• Godot 4 with GDScript is now stated as confirmed by the creator (was “proposed”), after reviewing the Engine Comparison pros and cons. The Unity fallback sentence is replaced by a statement that the contracts are engine-neutral.

Not changed: scene ownership and data-driven content rules, the wave stretch goal behaviour, remappable controls, and the hazard-readability rules.

---

3. AI Agent Strategy

File: Final_GDD_Post_Review/AI Agent Strategy.md

Orchestration and oversight (new)
• New section: Orchestration and oversight. Two orchestrator agents delegate to the worker roles and oversee the work.
  – Production Orchestrator: turns creator goals and gates into task briefs, assigns workers, orders dependencies, tracks the schedule, holds event IDs and contracts, and assembles the integrated build.
  – Canon and Review Orchestrator: checks each handoff against the pillars, scope rule and decisions log; blocks work that decides unresolved story; keeps the decisions log current.
• Escalation. A table lists when each orchestrator must go back to the creator: missed exit tests, contract changes, conflicting tasks, week 5 slipping, canon questions such as Ted, the retry model or penalty rules, and failed pillar tests.
• Orchestrator rules. Brief before delegating; orchestrators own contracts; gate checks require evidence; a fixed report format; orchestrators never merge; parallelism is limited to what the integration contract supports. The creator keeps merge authority and the final say on design.
• Example brief. A new example orchestrator brief for the Gate 1 fail-state presentation, alongside the existing Gate 0 steering spike brief.

Worker roles and handoffs
• Two new roles. Hazard Forecast (shared forecast and safe-route signal) and Story/Fail-State (fail sequence, reason line, ship reveal, Ted’s lamp staging).
• Existing roles updated to match the amended design:
  – Boat/Physics: docking, recovery and dock zones.
  – Level Layout: moored-rowboat window view, island gate and the lamp-room sightline to the ship and island rocks.
  – Gameplay/Systems: two repairs, return-departure clock trigger, restart on a fail, shelter-and-gate trigger.
  – Sound: ship impact; perceptual storm cues follow elapsed time.
  – Dialogue: Ted’s voice-only lamp lines.
  – QA: restart and win/fail tested from every expiry location.
• Role note. The roles are work roles, not a fixed number of agents running at once, now including the two orchestrators.

Rules, sequence and checklist
• Working rules. Added: treat items in the Executive Summary’s decisions log as canon; do not build anything marked Proposed, deferred or on the cut list (waves, route branching, repairs beyond the first two) without the creator’s go-ahead.
• Sequence. Expanded to ten steps: orchestrators write the briefs; Ted is locked by week 3; Hazard Forecast joins the steering spike; Story/Fail-State implements the fail-state contract before week 5 ends; and before Gate 2 the Canon and Review Orchestrator tables the retry model, penalty rules and branching cut-list item for the creator’s decision.
• Review checklist. Adds: does the work respect the decisions log (return-crossing clock start, storm split, two Gate 1 repairs, no crash, fail-state contract), and has the orchestrator reported the result, including failures and blocked decisions.

Handoff format and engine (new)
• New section: Handoff format. A table sets the file types: Godot text files (.tscn, .gd, .tres) for scenes, scripts and resources; JSON or .tres with stable IDs for game data; Blender and glTF for meshes, WAV for audio sources; a HANDOFF.md per task; a REPORT.md per task or gate from the orchestrator; contract changes proposed in the HANDOFF.md.
• HANDOFF.md has eight fixed headings (task and goal, files changed, how to run and test, observed behaviour, not verified, licences and provenance, interface or contract changes, open creator decisions). REPORT.md uses the six orchestrator report fields.
• A handoff without a HANDOFF.md goes back to the worker. Review checklist adds a check for a complete HANDOFF.md and the agreed file types.
• Engine stated as Godot 4 (confirmed). Sequence step 1 no longer lists the engine as something to settle.

Not changed: the six general working rules’ intent (narrow reversible changes, editable outputs with provenance, run builds and focused checks, creator reviews and merges), the Gate 0 steering-spike brief, and the human-review-gate approach.

---

Later amendments
• Outpost detail. No significant detail is added to the outpost until the prototype is considered complete. Ideas for more folk-horror, canon clues and documentation are parked in Dreams for the game (Additional/Dreams for the game.md). Recorded in the Exec Summary, Technical Strategy and AI Agent Strategy.
• Deadline length. To be reviewed once the boat crossing back from the outpost has been tested.
• Outbound crossing penalties. Deferred by the creator.

Related files

• Final_GDD_Post_Review/Lighting the Storm - Design Submission (.md and .pdf) and Design Brief (.md and .pdf) were regenerated from these changes.
• Final_GDD_Post_Review/Additional/Decisions to be made.md lists the decided items and the 19 still open (including outbound crossing penalties). Additional/Dreams for the game.md carries the new outpost entry.
