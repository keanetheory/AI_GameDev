# HANDOFF - T10: the return crossing's hazard forecast in the level

## Update, 31 Oct 2026 (the creator's play)

The creator found the steering fine and asked for: **(1)** the hazards on the sea from the start of the game (they are now placed when the level is ready, so the outbound crossing weaves round them too; the `spawn_on` note is in `crossing_sequence.json`); **(2)** near-miss and collision lines that get more frantic each time, three levels each (`ARTHUR_NEAR_1..3`, level 3 repeating; `ARTHUR_HIT_1..3`; the old `ARTHUR_S3_07` and `ARTHUR_S3_08` are level 1; they play on near misses and collisions on both crossings and the counts start again each crossing; near misses now also count passes close to the forecast's hazards, not only the sea stacks); **(3)** `DOCKING_DIALOGUE` ("Hands off now, you've done the steering, I'll bring her in while you get ready to jump.") every time auto-docking starts (`boat.docking_started`), and at the lighthouse after a return with collisions an admonishment in three levels (1 hit, 2-3 hits, 4 or more: `DOCKING_DIALOGUE_LIGHTHOUSE_1..3`) before the "go go go"; **(4)** a return collision rocks the boat hard (up to about 14 degrees of roll), throws it back about 11 m over 1.2 s from what it hit instead of resetting it to an earlier spot, and charges the deadline 5 s (`boat.hard_bounce`, set on the return only; outbound collisions keep the old recovery and cost nothing). The numbers are in `data/world/crossing_sequence.json` (`return_collision`, `docking`, `near_miss`). `tools/test_crossing_sequence.gd` now has 55 checks covering all of it. Not verified by feel: the throw distance and the rocking against real play.

## 1. Task and goal

Integrate the Storm Crossing Crew's forecast (`AIAgentCrew/output/return_crossing.json`): the data file, the loader with a route-position feed from the boat, hazards (rocks, reefs, buoys, debris) placed from it, and Arthur's calls as subtitles from the same safe-lane signal (Technical Strategy "shared hazard forecast"; Pillar 4). Also gives the outbound crossing its missing `OUTBOUND_NEAR_MISS`. Serves R07 and R08.

## 2. Files changed

New:
- `data/world/return_crossing.json`: the forecast (copied; one line changed, see section 8); `data/world/crossing_sequence.json`: how it lies on the level.
- `scripts/world/crossing_loader.gd` (the crew's loader, copied, new data path), `crossing_hazards.gd` (the four hazard shapes), `crossing_sequence.gd` (the director; GameState creates it inside the level).
- `tools/test_crossing_sequence.gd` (27 checks).

Edited: `scripts/core/game_state.gd` (creates the director; `crossing()`), `scripts/core/audio_mixer.gd` (`place_bells`: the bells now ring from the real buoys), `data/dialogue/dialogue_opening.json` (Arthur's five calls `ARTHUR_RET_01..05` with their trigger ids, five matching entries in `events`), `tools/shot.gd` (`SHOT_CROSSING=1`), `tools/test_boat.gd`, `test_boat_float.gd`, `test_disembark.gd` and `test_wave_crossings.gd` (set the `no_crossing_hazards` meta so their simple bots sail without the hazards), `readme.md`.

Not touched: the boat's steering and hazard test, `Level.tscn`, the sea stacks.

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_crossing_sequence.gd
```

How it works: when the boat docks at the Saltgate (`SALTGATE_REACHED`; also on `BURNER_PICKED_UP` if that comes first) the director places the forecast's 15 hazards along the straight line from the quay (6, 531.5) to the harbour mouth (-24, 80) in the forecast's left, centre and right lanes (12 m off the line; left is west, right is east when heading home). The forecast's 600 m is stretched over that 452 m line. On the return the boat's distance along the line is fed to the loader every physics frame, which fires Arthur's call ahead of each segment (the `ARTHUR_RET_n` dialogue lines, as subtitles) and reports the segment's safe lane (`segment_entered`, `director.safe_lane`): centre, left, right, centre, left. Hazards are on physics layer 2, so the boat's existing hull test and recovery treat them like the sea stacks. A rock is a small copy of the sea stack with a foam ring; a reef is three low rocks in white water; a buoy is red with a blinking lamp (and its bell); debris is three pale planks. Outbound, passing within 5 m of a sea stack's edge without touching it fires `OUTBOUND_NEAR_MISS` (repeatable, 12 s cool-down per stack).

## 4. Observed behaviour

`test_crossing_sequence.gd`: OK, 0 failed. No hazards before the Saltgate; docking there places all 15 (4 rocks, 4 reefs, 4 buoys, 3 debris); each sits in its forecast lane; none is within 8 m of a sea stack or 10 m of the island (closest 16.8 m); the boat's hull test hits every hazard; the safe lane (centre, left, right, centre, left, with the lane change eased over the last quarter of each segment) is clear for the launch along its whole length, and still clear with 1.4 m of margin each side and 2 m at each end; Arthur's five calls fire once each, in order, at their trigger positions, and are spoken as lines; the safe-lane signal reads centre, left, right, centre, left; the bells move onto the buoys; a pass 3 m off a stack's edge fires OUTBOUND_NEAR_MISS and not again at once. The game-state, audio, boarding, intro, ship, outcome, subtitle, wave, disembark and boat tests still pass. A rendered still shows a rock with its foam ring and a reef ahead on the return.

## 5. Not verified

- Not sailed by a person: steering feel, whether the 12 m lanes and the calls give enough warning at 8 m/s (the forecast assumed 6), and the readability of the hazards at night in rain.
- The forecast was made for a 600 m, 6 m/s crossing; here it is stretched over 452 m and sailed at 8 m/s, so each call's lead is shorter in time (about 3.5 s). `arthur_call_lead_m` and the segment lengths were not retuned.
- Collisions on the return charge nothing (the deadline penalties are T19); `director.hazard_hits` counts them.
- Waves are on in the real game: the swell and push at sea states 3 to 5 were not combined with the hazard lanes in a bot run.
- The foam rings and the reef are flat placeholder shapes; the buoy's blinking lamp is not synchronised with its bell.
- No hazards on the outbound crossing beyond the existing stacks (by design: free practice).

## 6. Licences and provenance

None new (the rock reuses `Assets/Models/sea_rocks/sea_stack.glb`).

## 7. Interface or contract changes proposed

PROPOSED: `GameState.crossing()`; `ARTHUR_RET_01..05` as dialogue triggers outside the GameState event list (the crossing crew's own vocabulary, `existing_crew_event`); `OUTBOUND_NEAR_MISS` is now emitted.

## 8. Open creator decisions

- `ARTHUR_RET_05` read "Hard left, lad! Rocks to starboard!"; canon says nobody calls the player lad, so it now reads "Hard left! Rocks to starboard!" in the game data (the crew's original output is unchanged).
- Should the forecast be regenerated for the level's real route length (452 m) and the 8 m/s speed, with longer call leads?
- Should a return collision cost deadline time now (T19), and how much?
