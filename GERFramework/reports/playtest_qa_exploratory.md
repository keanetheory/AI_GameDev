# Playtest QA: off the golden path (QA-04)

3 Nov 2026, Playtest QA agent. Every run is scripted and headless in the real level through the real GameState (`LightingTheStorm/tools/probe_exploratory.gd -- <mode>`, which drives the unchanged `test_slice_playthrough.gd` and, at a hook, does what an awkward player would). Observe only: no game file was changed. Where the scripted player teleports, that is said. What only a person can judge is listed at the end.

## Summary

| Run | Result | Backlog |
|---|---|---|
| Walk off the Saltgate quay into the sea | **SOFTLOCK.** No sea floor at the Saltgate: the player falls out of the world and is respawned at the start spot on the lighthouse island, 524 m from the boat. Before the burner: stranded, no boat, no fail state, no restart key in the release build. With the burner: a **sequence break**: walk up and fit it, SHIP_WIN without the return crossing (RETURN_DEPARTED never fires, no deadline) | T77 (9) |
| Aim the boat at the lighthouse island on the outbound | **The boat sails through the island.** From the lighthouse dock, aimed at the tower: 0 collisions for 8 s while it crossed the island past the tower (about 1.7 m from its axis) and came out on the east side; the first collision came at about 10 s on the far shore. Steering away afterwards frees it (not stranded) | T78 (7) |
| Restart (F9, debug builds) 1 s after each of 12 story events, after SHIP_WIN, after the win text, and 1 s into the fail sequence | All 15 **clean**: level reloaded, phase ARRIVAL_AND_COAL, nothing fired, dialogue queue and holds empty, no subtitle left, Carry empty (also when restarting while holding the burner), not paused, deadline -1, outcome NONE, music 'Landed', door shut and knockable; the knock then starts the game (GAME_STARTED) every time | - |
| Shut the gate while the sailors walk through it | No softlock: they walk on through the shut leaf (they have no collision) and SAILORS_INSIDE fires with the gate shut. Visual only: they pass through the closed gate | T83 (3) |
| Pause for 1 s on every story event | The clock, the ship and the voice hold while paused. One fault: a line whose `pause_before` was running starts while paused (TED_S1_01) | T75 (4) |
| Read the poster before the diagnosis, then again after | Ted's poster line is dropped and can never be heard (POSTER_EXAMINED is one-shot) | T76 (4) |
| Step outside each time Ted starts a line (first four), come back 2 s later | The lines finish; nothing is left held; no softlock | - |
| After the fit, go outside to watch the ship (the last goal) | No softlock; the win text shows. A spot up to 3.3 m from the tower axis counts as inside, 3.6 m and beyond as outside. Ted's win lines are queued at the fit and at SHIP_WIN while the player is still inside, so they play wherever the player is, late (see the timing report, F4) | duplicate of T74 |
| Fall off the lighthouse jetty | Not a softlock: the island has ground under the water near the jetty (the player stands at y -0.5 and walks back to the landing) | - |
| Boat stranding (steer into the island, hard left, straight) | Not stranded: outbound collisions recover to the trail; after the run the boat is free and moving (21.7 m in 8 s) | - |
| Board before Arthur | Covered by `test_boarding_sequence.gd` (cast-off refused until Arthur is aboard), passing | - |
| Carry the burner to odd places | It cannot be put down except in the boat slot or the lamp (`test_carry.gd`, passing). The one odd place found is the sea at the Saltgate (above) | T77 |
| NPCs reach their targets | Ted to the lamp room, the sailors to the hall and basement, Arthur to the launch: all within the playthrough's limits in every run above, including with the gate shut on them. NPCs have no collision, so the player can never block them (they walk through the player) | - |
| Walk out of every room and up every stair | `tools/check_interior_reach.gd`: see below. `test_interior_walk.gd`, `test_spiral_down.gd`, `test_stair_spec.gd`, `test_island_walk.gd`, `test_path_walk.gd`, `test_cliffwalk.gd`, `test_boardwalk.gd` all pass (suite report) | - |

## Steps to reproduce

### T77: walking off the Saltgate quay strands the player (or skips the return)
1. Play to the Saltgate and step ashore at the landing (3.6, 3.05, 535.6).
2. Walk straight towards the moored launch and past it, off the quay edge (heading from the landing to the boat at about (6.0, 0, 531.4)).
3. The player drops into the sea, falls through it (no floor), and at y -40, about 4 s later, `player.gd` puts them back at their start position (14, 15.5, 8) on the lighthouse island.
4. Before picking up the burner: there is no boat on the island, nothing can fail before RETURN_DEPARTED, and F9 is off in the release build: the only way on is to quit the game.
5. With the burner in hand: walk up to the lamp and fit it: LAMP_ROOM_REENTERED, BURNER_FITTED and SHIP_WIN fire with RETURN_DEPARTED never fired and the deadline never started.

Trace at 1x (`probe_exploratory.gd -- saltgate_fall=early`): y 3.09 at the landing, 1.17 at the quay edge, then -5.5, -12.2, -21.4, -33.4, -39.8, then a jump of 515 m to (14, 15.5, 8). Proposed fix (Player Movement agent): a sea floor or a water volume at the Saltgate, and a respawn to the nearest landing (or into the boat) rather than the level start; and (Gameplay / Systems) BURNER_FITTED should not be accepted before RETURN_DEPARTED.

### T78: the boat sails through the lighthouse island
1. Board at the lighthouse dock and cast off.
2. Steer straight at the lighthouse.
3. The boat passes over the island and through the tower without a collision and comes out on the east side; positions every 2 s: (-24.4, 13.0), (-10.9, 4.9), (2.9, -3.3), (16.6, -11.4); first collision at about 10 s.

The boat's hazard query is on physics layer 2 ("rocks, cliffs and the island", boat.gd `hazard_mask`); the island's own collision apparently is not on that layer along this line. Proposed owner: Gameplay / Systems (boat), with the Level Layout agent for the island colliders.

### T83: the sailors walk through the shut gate
Open the gate when the sailors are waiting below it, then shut it again 1.5 s later: Arthur is 1 m short of the leaf; both walk through the closed leaf and in. Proposal: the gate refuses to close while a walker is within 2 m, or the walkers wait.

### T75: a line starts during pause
Press P within a line's `pause_before` (for example in the first second after the knock): the subtitle and voice start while paused. dialogue_loader.gd `_play_queue`: `create_timer(pause)` should be `create_timer(pause, false)`.

### T76: Ted's poster line lost
Read the hall's Storms poster before going up to the lamp room; after BURNER_DIAGNOSED read it again: nothing (POSTER_EXAMINED was used up by the first read and its line dropped).

## Interior reach sweep

`tools/check_interior_reach.gd` (flood fill over the game's collision from the porch, door open): 19 of 20 markers REACHED, from the entry and the hall window down to the boiler and coal, up through L1 (landing, hall, quarters, radio, mess, ring) and L2 (landing, control, instruments) to the lamp stand. The one NOT REACHED is `ANCHOR_daniel` (nearest walkable spot 0.37 m higher and about 1 m away, local (-2.375, -1.63, 4.625)): Daniel's own standing anchor sits on something the player cannot stand on. Not a defect for play: the story only needs the player in the basement, and `B1_daniel_marker` beside him is reached. Recorded, no backlog item.

## Not verified (needs a person)
- Real steering along the safe lane, and whether a person can strand the boat against the Saltgate quay or a rock stack with real input.
- Whether a person can actually reach the Saltgate quay edge at the spot used (it is 6 m from the landing towards the berth; the scripted walk got there).
- Jumping off the tower gallery or other high places; walking into every corner of every room (only the flood fill was run).
- Pausing through each beat by eye (the subtitles under the pause screen).
- The probes use the debug build (headless); in the release build F9 does not exist, which makes T77 worse.
