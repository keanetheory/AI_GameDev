Lighting the Storm — Decisions to be Made

Status: updated 1 October 2026 after the six-reviewer design review. Section A records what the creator decided in and after the review (these are now canon and reflected in the amended Executive Summary, Technical Strategy and AI Agent Strategy). Section B lists what is still open, including new items raised by the review. When a decision is made, update the Executive Summary or Technical Strategy and move it to the Decided list.

A. Decided in the review

1. Retry model at Gate 1. A fail returns the player to the start of the slice (fail, then restart). The full retry and save model is settled before Gate 2. (Was: item 5, “After the fail state”.)
2. Storm escalation. Split into two channels: sound, lightning, wind and the ship’s lights follow elapsed time; hazard density, route width and hazard visibility follow phase and route position only.
3. Return-crossing shortcut. Not in Gate 1. “Unlocked routes” is removed from the save contract. Route branching is a Gate 2 candidate on the cut list.
4. Folk-horror discoveries. The core discoveries move into the lighthouse and island, before boarding, tied to why the beacon failed. The outpost keeps a lighter set.
5. Ted (decision outcome). Lock his presence by the end of week 3. He is staged at the lamp for the climax and outcome, with voice and position only.
6. Clock start. The deadline starts when the player, with the burner aboard, begins the return crossing to the lighthouse (not on boarding). There is no fail state before then, so the outbound crossing and outpost give the player a feel for the boat. The ship is introduced by Ted at the boarding threshold.
7. Sailors’ arrival. There is no crash. Jeff and Daniel, overwhelmed by the storm, moor on the island seeking shelter. Ted sees them from the window and the player opens the island gate (the same gate).
8. Jeff. His motivation is to stop the ship from crashing, as he has realised the storm is getting nasty. After the second crossing he tells the player to go on without him; his reaction to the outcome is not recorded.
9. Daniel after the gate. He goes to the basement; his reaction to the outcome is not recorded. (Was: item 2.)
10. Fail presentation. The foghorn, the ship crashes into the island, silence, then a “Failed” title screen with a short reason line. There are three fail states, all after the return crossing begins: on the return crossing it is audio only; in the lamp room the ship is seen and the audio still sounds; on the stairs it is audio only unless a window sightline exists.
11. Repairs at Gate 1. Two repairs. Further repairs belong to Gate 2 and the full game. (Replaces: item 11, “Prototype repair”, in part; see B7.)
12. Apprentice. The apprentice never speaks, so others give the moral beat.
13. Crossing penalty rules. Loose for Gate 1; to be reviewed for the full-game build. (Updates: item 6.)
14. Engine. Godot 4 with GDScript, confirmed by the creator after reviewing the Engine Comparison pros and cons. (Was: open item 12.)

B. Still open

Story and canon

1. Ted’s presence. Confirm by the end of week 3 that he is present and speaks live; the design assumes so. Confirm before recording dialogue. Ted’s lamp-room lines are voice only; decide the final list of lines (each is voice-over cost).
2. Discoveries content. Decide which discoveries live in the lighthouse and island and which stay at the outpost, and how each ties to why the beacon failed. The outpost is untimed and gets no significant added detail until the prototype is considered complete; ideas for more folk-horror, canon clues and documentation are parked in Dreams for the game.
3. Fail reason line. Decide the wording and who delivers it (Ted, Jeff, or the journal).

Ship deadline and fail state

4. Deadline length. Set from measured playtests so a first-time player who follows cues has room for some mistakes. To be reviewed once the boat crossing back from the outpost has been tested; no value is set until then.
5. Final retry and save model (before Gate 2). Decide between a run-start snapshot and a phase-start snapshot. Whichever is chosen must restore time and weather together; if phase-start, define the minimum remaining time. Decide where checkpoints are, if any.
6. Pause rules. Proposed: the deadline stops during menus and deliberate pause. Check for exploits before Gate 2.
7. Lamp-room sightline. Confirm the lamp room can see the ship’s route and the island rocks, and decide the stairs case (audio only unless a window sightline exists).
8. Accessibility for audio-only fail cues. Decide the subtitle or visual alternative for the audio-only fail cue on the return crossing and the stairs.
9. Outbound crossing penalties. With no deadline before the return crossing, collisions on the outbound crossing cost no deadline time. Decide what they cost instead (for example a slowdown or recovery only) so the outbound crossing still teaches the player. Deferred by the creator: to be decided later, as part of the penalty review.

Boat and crossings

10. Docking and recovery. Proposed: docking at the outpost and lighthouse jetties is automatic; leaving the playable corridor triggers a recovery to the last safe point at a time cost. Confirm, and define dock zones and safe points.
11. Crossing failure policy details. Proposed: a collision adds water, slows the boat or causes a brief capsize and recovery, costing deadline time; the burner can never be permanently lost. Rules are loose for Gate 1; write down exact costs and limits for the full game.
12. Bailing interaction. Add a simple bailing action only if playtests show it improves the crossing without overloading the one-control steering promise.

Production

13. Target hardware and the Gate 0 feel target. Define the target PC and what “enjoyable steering” means well enough to judge the steering spike.
14. Controller support in the prototype. Technical Strategy’s Gate 1 requires keyboard and controller; the Executive Summary lists controller support under the full game. Decide whether the prototype needs it.
15. Which two repairs. Choose the two lighthouse repairs in the Gate 1 slice, and the full repair list for the full game.
16. Week 5 load. Week 5 holds the second repair, deadline, fail presentation and Ted’s lamp lines. If it slips, decide between dropping the second repair for Gate 1, cutting waves (already first), or extending the schedule.
17. Full-game estimate and cut list. Complete after Gate 1 using measured data. Provisional cut order: wave hazards; return-crossing route branching; repairs beyond the first two; outpost optional discoveries beyond the light set.
18. Token budget. Figures have not been re-baselined for the post-review changes (second repair, fail-state work, orchestrator overhead). Re-measure after week 1.

AI agent oversight

19. Orchestrator authority. Confirm the Production Orchestrator and the Canon and Review Orchestrator may write briefs and assign workers without per-task approval, with escalation limited to the triggers listed in the AI Agent Strategy. The creator keeps merge authority.

Stretch goals

20. Wave hazards. Waves that push or roll the boat are a stretch goal (Executive Summary, Technical Strategy). Decide at the end of week 4 whether the schedule has room to start them in week 5, and after playtests whether they stay in the full game.
