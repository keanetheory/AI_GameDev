Lighting the Storm — Decisions to be Made

Status: updated 1 October 2026 after the six-reviewer design review, 16 October 2026 for the creator’s fixed story beats, and 19 October 2026 for the creator’s answers to the Goal-Oriented Agent’s dependency review (A17 to A26). Section A records what the creator decided in and after the review (these are now canon and reflected in the amended Executive Summary, Technical Strategy and AI Agent Strategy). Section B lists what is still open, including new items raised by the review. When a decision is made, update the Executive Summary or Technical Strategy and move it to the Decided list.

A. Decided in the review

1. Retry model at Gate 1. A fail returns the player to the start of the slice (fail, then restart). The full retry and save model is settled before Gate 2. (Was: item 5, “After the fail state”.)
2. Storm escalation. Split into two channels: sound, lightning, wind and the ship’s lights follow elapsed time; hazard density, route width and hazard visibility follow phase and route position only.
3. Return-crossing shortcut. Not in Gate 1. “Unlocked routes” is removed from the save contract. Route branching is a Gate 2 candidate on the cut list.
4. Folk-horror discoveries. The core discoveries move into the lighthouse and island, before boarding, tied to why the beacon failed. The Saltgate keeps a lighter set.
5. Ted (decision outcome). Lock his presence by the end of week 3. He is staged at the lamp for the climax and outcome, with voice and position only.
6. Clock start. The deadline starts when the player, with the burner aboard, begins the return crossing to the lighthouse (not on boarding). There is no fail state before then, so the outbound crossing and the Saltgate give the player a feel for the boat. The ship is introduced by Ted at the boarding threshold.
7. Sailors’ arrival. There is no crash. Arthur and Daniel, overwhelmed by the storm, moor at the island’s dock seeking shelter. Ted sees them from the window and the player opens the island gate (the same gate).
8. Arthur. His motivation is to stop the ship from running aground, as he has realised the storm is getting nasty. After the second crossing he tells the player to go on without him; his reaction to the outcome is not recorded.
9. Daniel after the gate. He goes to the basement and stays there; his reaction to the outcome is not recorded. (Was: item 2.)
10. Fail presentation. The foghorn, the ship runs aground on the island, silence, then a “Failed” title screen with a short reason line. There are three fail states, all after the return crossing begins: on the return crossing it is audio only; in the lamp room the ship is seen and the audio still sounds; on the stairs it is audio only unless a window sightline exists.
11. Repairs at Gate 1. Two hands-on jobs: feeding the boiler with coal, then fitting the burner (16 October 2026; see A15). Further repairs belong to Gate 2 and the full game. (Replaces: item 11, “Prototype repair”, in part; see B7.)
12. Apprentice. The apprentice never speaks, so others give the moral beat.
13. Crossing penalty rules. Loose for Gate 1; to be reviewed for the full-game build. (Updates: item 6.)
14. Engine. Godot 4 with GDScript, confirmed by the creator after reviewing the Engine Comparison pros and cons. (Was: open item 12.)
15. Which two repairs (16 October 2026). Resolved by the story beats: the player feeds the boiler with coal (step 1), and fits the replacement burner to the beacon at the end (the final repair). (Was: open item B15.)
16. Story beats (16 October 2026). In order: the player (Isaac, “the new guy”) starts outside and Ted opens the door; Ted sends him to the basement to shovel coal into the boiler; Arthur and Daniel moor at the dock and the player opens the island gate (on the path from the dock to the lighthouse), with Daniel staying in the basement; the dynamo runs but the beacon stays dark, and Ted, only after the sailors are in, takes the player to the lantern room and finds the burner broken; the outbound crossing with Arthur goes to the Saltgate quays (Saint Calder’s abandoned harbour, not “the outpost”); the storm escalates on the return; the player fits the burner before the passenger ship runs aground. The part is “the burner”.
17. Event IDs and phase boundaries (19 October 2026). The four IDs first proposed in the game’s GameState script are accepted: RETURN_ARRIVED, BURNER_FITTED, SHIP_WIN and SHIP_FAIL, with the phase boundaries listed in the Technical Strategy core state contract. (Was: T26 in the agent backlog.)
18. The burner (19 October 2026). The broken and replacement burners follow the concept sheets in ConceptArt/burner. The replacement sits on the ground at the Saltgate dock, close to where the player disembarks. The player picks it up with his hands and carries it in his hands on the boat back to the island. He cannot put it down anywhere except the boat and the lamp. The prop is generated as a FAL model from the concept art.
19. Ted’s presence (19 October 2026). Ted is present inside the lighthouse throughout the game. (Resolves the presence half of B1.)
20. Fail reason line (19 October 2026). Voiced by Ted and shown as a subtitle: “All is lost for those on board...the storm takes more lives. What were you doing, you money toff!” The visual is the passenger ship crashing and breaking up on one of the rocks right next to the island. (Was: B3; resolves B8 for the lamp room and the crossing.)
21. Controller (19 October 2026). There is no controller in this iteration; the prototype is keyboard and mouse. (Was: B14.)
22. Lamp-room sightline (19 October 2026). The lamp room has views all around. One view faces the rock next to the island where the ship either crashes or passes by safely. (Resolves the sightline half of B7.)
23. Pause (19 October 2026). The deadline stops in menus and on deliberate pause. (Resolves the rule in B6.)
24. Boat speed (19 October 2026). The boat stays at 10 m/s until the waves are complete.
25. Sailor placeholders (19 October 2026). Arthur and Daniel are capsules for the prototype; the rigged test character is Ted. The rowboat follows ConceptArt/rowboat and is generated as a FAL model.
26. The stairs case (19 October 2026). If the player is on the stairs when the deadline runs out, they see nothing; the passenger ship crash plays out regardless of whether it is seen. (Resolves the rest of B7 and B8.)
27. Discoveries content (23 October 2026). The core discoveries (about four to six) live in the lighthouse and on the island, in the untimed opening before boarding; the Saltgate keeps a light set of one or two. Each ties to why the beacon failed through a human cause that is never explained: clues show the burner was neglected or tampered with by people (keepers, and the people hiding in the walls), but never say who or why. The supernatural stays unconfirmed, and the Flighted are not named as the cause. The built poster (POSTER_EXAMINED) and wall whisper (WALL_WHISPER_HEARD) are the first two; the individual items are chosen in the Gate 2 narrative pass. (Resolves B2 and T34.)

B. Still open

Story and canon

1. Ted’s presence. Presence resolved 19 October 2026 (see A19). Still open: Ted’s lamp-room lines are voice only; decide the final list of lines (each is voice-over cost).
2. Discoveries content. Resolved 23 October 2026 (see A27).
3. Fail reason line. Resolved 19 October 2026 (see A20).

Ship deadline and fail state

4. Deadline length. Set from measured playtests so a first-time player who follows cues has room for some mistakes. To be reviewed once the boat crossing back from the Saltgate has been tested; no value is set until then.
5. Final retry and save model (before Gate 2). Decide between a run-start snapshot and a phase-start snapshot. Whichever is chosen must restore time and weather together; if phase-start, define the minimum remaining time. Decide where checkpoints are, if any.
6. Pause rules. Resolved 19 October 2026: the deadline stops during menus and deliberate pause (see A23). Still open: check for exploits before Gate 2.
7. Lamp-room sightline. Resolved 19 October 2026 (see A22 and A26).
8. Accessibility for audio-only fail cues. Resolved 19 October 2026: Ted’s reason line is subtitled, the visual is the ship breaking up on the rock (see A20), and on the stairs the player sees nothing while the crash plays out (see A26).
9. Outbound crossing penalties. With no deadline before the return crossing, collisions on the outbound crossing cost no deadline time. Decide what they cost instead (for example a slowdown or recovery only) so the outbound crossing still teaches the player. Deferred by the creator: to be decided later, as part of the penalty review.

Boat and crossings

10. Docking and recovery. Proposed: docking at the Saltgate quays and the lighthouse jetty is automatic; leaving the playable corridor triggers a recovery to the last safe point at a time cost. Confirm, and define dock zones and safe points.
11. Crossing failure policy details. Proposed: a collision adds water, slows the boat or causes a brief capsize and recovery, costing deadline time; the burner can never be permanently lost. Rules are loose for Gate 1; write down exact costs and limits for the full game.
12. Bailing interaction. Add a simple bailing action only if playtests show it improves the crossing without overloading the one-control steering promise.

Production

13. Target hardware and the Gate 0 feel target. Define the target PC and what “enjoyable steering” means well enough to judge the steering spike.
14. Controller support in the prototype. Resolved 19 October 2026: no controller in this iteration (see A21).
15. Which two repairs. Resolved 16 October 2026 for Gate 1: feeding the boiler, then the burner fit (see A15). Still open: the full repair list for the full game.
16. Week 5 load. Week 5 holds the beacon diagnosis and burner fit, deadline, fail presentation and Ted’s lamp lines. If it slips, decide between simplifying the diagnosis and burner fit for Gate 1, cutting waves (already first), or extending the schedule.
17. Full-game estimate and cut list. Complete after Gate 1 using measured data. Provisional cut order: wave hazards; return-crossing route branching; repairs beyond feeding the boiler and fitting the burner; Saltgate optional discoveries beyond the light set.
18. Token budget. Figures have not been re-baselined for the post-review changes (second repair, fail-state work, orchestrator overhead). Re-measure after week 1.

AI agent oversight

19. Orchestrator authority. Confirm the Production Orchestrator and the Canon and Review Orchestrator may write briefs and assign workers without per-task approval, with escalation limited to the triggers listed in the AI Agent Strategy. The creator keeps merge authority.

Stretch goals

20. Wave hazards. Waves that push or roll the boat are a stretch goal (Executive Summary, Technical Strategy). Decide at the end of week 4 whether the schedule has room to start them in week 5, and after playtests whether they stay in the full game.
