# Playtest QA Agent: prioritised plan

- Assessor: **Playtest QA Assessment Agent** (knowledge up to date)
- Phase: **awaiting_approval** | plan review loops used: 1 of 3
- Blocking findings left: **0**

**Mission:** Play the Gate 1 slice the way a player would, end to end and off the golden path, in the exported Windows build as well as the editor, and turn everything that breaks, stalls, overruns or stutters into scored backlog items with evidence, so the creator only ships a slice that has been played through properly. It reports and proposes; it does not change gameplay, art or dialogue itself.

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| QA-01 | **10** | Run every headless test and both full-slice playthroughs, and report each result with its output |  | failing |
| QA-02 | **10** | Bring QA_SCENARIOS.md up to date with the 3 Nov changes before playing to it |  | failing |
| QA-03 | **9** | Measure the frame rate and memory along the whole route in the exported build, on both GPUs |  | failing |
| QA-04 | **9** | Hunt softlocks, stuck characters and stuck players off the golden path |  | failing |
| QA-05 | **8** | Check dialogue and music timing with the recorded clips: overruns, overlaps and beats talked over |  | failing |
| QA-06 | **8** | Visual sweep of fixed views for black areas, missing meshes and characters clipping into walls |  | failing |
| QA-07 | **7** | File every new finding into the backlog, scored and with evidence, and fix nothing in gameplay |  | failing |
| QA-08 | **6** | A one-page playtest sheet for human testers: what to try and what to report |  | failing |
| QA-09 | **5** | One command that runs the whole suite and prints a summary |  | failing |

## Detail

### QA-01 [10/10] Run every headless test and both full-slice playthroughs, and report each result with its output
Run every tools/test_*.gd script headless, plus test_slice_playthrough.gd and its '-- fail' run (S01, S02), with the Godot editor closed where a test needs it (test_interior_budget fails with it open). Record pass or fail, the failing checks and the run time of each test in one table. A failure is re-run once to separate a flaky test from a real fault, and both results are reported.

- Why this score: The launch gate: nothing ships on a red test. Not lower because every other objective reads these results; it is the baseline.
- Done when: GERFramework/reports/playtest_qa_suite.md lists every test with pass or fail and the output of each failure; the two playthroughs are included
- Owner: Playtest QA Agent | works with: QA agent, Offline AI Crew
- Depends on: nothing
- Baseline evidence:
  - GERFramework/reports/playtest_qa_suite.md is missing
  - GERFramework/reports/playtest_qa_suite.md is missing

### QA-02 [10/10] Bring QA_SCENARIOS.md up to date with the 3 Nov changes before playing to it
Since the list was written: Daniel speaks one line per basement visit (BASEMENT_VISITED, three lines then silence); Ted's firebox line waits for FIREBOX_APPROACHED; the poster line is Ted's, after BURNER_DIAGNOSED; speech no longer ducks the wind, the rain or the music; voices are placed by distance and floor; every line is recorded; the music changes when TED_S3_02 ends and on BURNER_PICKED_UP; the win text shows 23 s after the rock is cleared, with no veil; the last goal is 'Go outside and watch the ship'. Update rows S08, S09, S12, S17 and S18, add rows for the music, the voice placement and the win text, and fix the Known gaps list.

- Why this score: The scenario list is the agent's script, and playing to a stale one tests the wrong game. Not 9 because several rows are already wrong (S08, S09, S17) and the voice gap is closed.
- Done when: every 3 Nov change has a row with its automated test or 'manual'; no row describes behaviour the game no longer has
- Owner: Playtest QA Agent | works with: QA agent, Sound agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/QA_SCENARIOS.md: /BASEMENT_VISITED/ matched 0 (need >= 1)
  - LightingTheStorm/QA_SCENARIOS.md: /FIREBOX_APPROACHED/ matched 0 (need >= 1)
  - LightingTheStorm/QA_SCENARIOS.md: /nothing is recorded/ matched 1 (need >= 0 and <= 0)

### QA-03 [9/10] Measure the frame rate and memory along the whole route in the exported build, on both GPUs
From a fresh export in build/windows, put the player at fixed points: the front door, the hall, the basement, the tower stairs, the lamp room, the outbound crossing, the Saltgate quay, the return crossing in the storm (late in the deadline), and the win. Record frames per second (minimum and median), frame-time spikes over 50 ms, peak system memory and video memory, once on the NVIDIA GPU and once on the Intel integrated GPU (--gpu-index 1). Write the table into requirements.md and flag any point under 30 fps on integrated graphics.

- Why this score: requirements.md only has the opening view; the interior (858k triangles) and the storm crossing are unmeasured, and integrated graphics got 35 fps where it is lightest. Not 10 because the game runs; this sets the published requirements and does not unblock play.
- Done when: a table of fps, spikes and memory at each point for both GPUs; requirements.md updated from it
- Owner: Playtest QA Agent | works with: Lighting agent, Level Layout agent
- Depends on: QA-01
- Baseline evidence:
  - GERFramework/reports/playtest_qa_performance.md is missing
  - requirements.md: /lamp room \|/ matched 0 (need >= 1)

### QA-04 [9/10] Hunt softlocks, stuck characters and stuck players off the golden path
Scripted exploratory runs: leave and re-enter rooms mid-line, open and shut the gate while the sailors walk, board before Arthur, carry the burner to odd places, fall off the jetty, restart mid-sequence (F9) in every phase, pause through each beat. Check that each NPC reaches its target in time on every route (Ted, Arthur, Daniel), that the player can walk out of every room and up every stair (collision sweeps along the baked routes), that the boat cannot be stranded, and that a restart after a win or a fail is clean. Every finding has steps to reproduce.

- Why this score: A softlock ends a run with no way on, the worst bug a short game can ship. Not 10 because the golden path is already covered by tests; this is the off-path search.
- Done when: each run listed with its steps and result; every softlock or stuck case has steps to reproduce and a proposed owner
- Owner: Playtest QA Agent | works with: Player Movement agent, Gameplay / Systems agent
- Depends on: QA-01, QA-02
- Baseline evidence:
  - GERFramework/reports/playtest_qa_exploratory.md is missing

### QA-05 [8/10] Check dialogue and music timing with the recorded clips: overruns, overlaps and beats talked over
Play each trigger's queue with the real clip lengths and list every line that runs past the event that should end it, overlaps a line from another trigger, or is cut by a scene change; Arthur's return calls against the hazard each one warns of; the music cues against the beats; Daniel's three visits; Ted's poster gate. A timing table per step.

- Why this score: The clips are real now and longer than the old reading times (about 508 s against 449 s), and one already runs past its beat (TED_F_03 plays from 15.2 to 27.1 s against the Failed screen at 22 s). Not 9 because it hurts the feel, not the run.
- Done when: a timing table per step with every overrun and overlap; TED_F_03 against the Failed screen reported with options
- Owner: Playtest QA Agent | works with: Sound agent, Dialogue agent, Story / Fail-State agent
- Depends on: QA-02
- Baseline evidence:
  - GERFramework/reports/playtest_qa_timing.md is missing
  - GERFramework/reports/playtest_qa_timing.md is missing

### QA-06 [8/10] Visual sweep of fixed views for black areas, missing meshes and characters clipping into walls
Add views to tools/visual_views.json for each room, the dock, the gate, the Saltgate and the crossings, with Ted, Arthur and Daniel at their standing spots, and run visual_check.py. Report black-area failures, missing meshes, and characters that are dark or clip into walls (known: characters darken in rooms whose lights the light budget has switched off), and give the creator a contact sheet.

- Why this score: Players see what tests cannot; a character in a wall or a black room reads as broken. Not 9 because visual_check.py already covers the cliff and lamp-room views; this widens it to the whole slice.
- Done when: every new view rendered and scored; a contact sheet for the creator
- Owner: Playtest QA Agent | works with: Lighting agent, Level Layout agent
- Depends on: QA-01
- Baseline evidence:
  - GERFramework/reports/visual_check.md exists
  - LightingTheStorm/tools/visual_views.json: /hall/ matched 0 (need >= 1)

### QA-07 [7/10] File every new finding into the backlog, scored and with evidence, and fix nothing in gameplay
Each finding becomes a backlog item in GoalOrientedAgent (the 1-10 rubric, the evidence, the owner agent, 'QA:' in the title), linked from the reports. The agent proposes fixes but does not make them: gameplay, art, dialogue and audio changes go through their owner agents and the creator.

- Why this score: Findings left in a report get lost; the backlog is where the creator decides. Not 8 because it is the hand-off, not the testing.
- Done when: every report finding has a backlog item or is marked a duplicate; no gameplay file changed by this agent
- Owner: Playtest QA Agent | works with: Creator
- Depends on: QA-03, QA-04, QA-05, QA-06
- Baseline evidence:
  - GoalOrientedAgent/BACKLOG.md: /QA:/ matched 0 (need >= 1)

### QA-08 [6/10] A one-page playtest sheet for human testers: what to try and what to report
From the Manual column of QA_SCENARIOS.md: one page with how to unpack and run the zip, what to try, the questions to answer (how long it took, where you were stuck, what you did not understand), and how to send screenshots back.

- Why this score: Some things only a person can judge (pacing, whether a beat is understood, steering feel), and friends testing the build need a short guide. Not 7 because the creator can playtest without it.
- Done when: one page in plain language, with install steps that match requirements.md
- Owner: Playtest QA Agent | works with: Creator
- Depends on: QA-02
- Baseline evidence:
  - GERFramework/reports/playtest_sheet.md is missing

### QA-09 [5/10] One command that runs the whole suite and prints a summary
A script (tools/run_all_tests.sh) that runs every test headless, times each one, writes the summary table QA-01 uses, and exits non-zero on any failure.

- Why this score: Every later QA pass and the deployment agent's gate reuse it. Not 6 because the tests already run one by one.
- Done when: one command, a summary table, a non-zero exit on failure
- Owner: Playtest QA Agent | works with: QA agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/tools/run_all_tests.sh is missing

## Questions for you

- None

## Review history

### Loop 1 (2026-11-03T15:39:58+00:00)
- no findings
