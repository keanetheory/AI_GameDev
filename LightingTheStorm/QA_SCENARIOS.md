# Gate 1 slice: QA scenarios (backlog T20)

How to use this list: the **automated** column names the headless test that already checks the scenario (run them from this folder, see `readme.md`); the **manual** column is what only a person can judge. Everything here runs against the real level and the real `GameState`. The two full-slice runs take about 70 to 100 seconds each (the game runs at 8x):

```bash
godot --headless --path . --script res://tools/test_slice_playthrough.gd            # S01, the whole win
godot --headless --path . --script res://tools/test_slice_playthrough.gd -- fail    # S02, the failure and the restart
```

Phase order the machine must follow, one step at a time: ARRIVAL_AND_COAL, SHELTER_AND_GATE (BOILER_FED), BEACON_DIAGNOSIS (DANIEL_IN_BASEMENT), BOARDING (BURNER_BRIEFING), OUTBOUND (BOAT_CAST_OFF), SALTGATE (SALTGATE_REACHED), RETURN (RETURN_DEPARTED), FINAL_REPAIR (RETURN_ARRIVED), RESOLUTION (SHIP_WIN or SHIP_FAIL). No fail state exists before RETURN_DEPARTED; the outcome resolves exactly once per attempt.

## Scenarios

| ID | Scenario | Expected | Automated | Manual |
|---|---|---|---|---|
| S01 | Golden path: knock, coal, sailors and gate, lamp-room diagnosis, briefing, boarding, outbound, burner, return on the safe lane, fit the burner | 25 story events once each in order; the eight phases in order; every moment has its line; the hidden clock runs only from RETURN_DEPARTED and freezes at the fit; SHIP_WIN, then the win card | `test_slice_playthrough.gd` | Pacing (a first-time player: 10 to 15 minutes?), whether each beat is understood without a marker |
| S02 | Deadline runs out on the return crossing, then Enter | SHIP_FAIL once; the ship runs onto the rock; foghorn, crash, silence; the Failed screen with a reason line; Enter restarts the slice from the shut front door with a fresh clock and sea | `test_slice_playthrough.gd -- fail`, `test_outcome_screen.gd`, `test_ship_deadline.gd` | Whether the 22 s from expiry to the screen feels right; Ted's fail lines are held while the player is on the boat (creator rule) |
| S03 | Deadline runs out while the player is in the lamp room, on the stairs, or in the hall | Same events and sequence wherever the player is; the lamp room sees the ship strike the rock; on the stairs the player only hears it (A26, A30) | `test_ship_route.gd` (the lamp-room sightline), `test_outcome_screen.gd` | Stand in each place and watch; windows on the stairs |
| S04 | Burner fitted at the last moment | The ship steers clear at any fit time up to the deadline (18 m clear water minimum); SHIP_WIN 4.5 s after the fit | `test_ship_route.gd`, `test_lamp_fit.gd` | Whether a very late fit looks plausible |
| S05 | Player is slow at each step | Ted's and Arthur's nudge ladders (IDLE_STEP_1, 2, 3) escalate through three tiers and stop when the step is done; nothing progresses by itself except the sailors' arrival | `test_sailors_sequence.gd` (IDLE_STEP_2), `test_diagnosis_sequence.gd` (IDLE_STEP_3) | IDLE_STEP_1 (the coal) has no automated check; the nudge wording |
| S06 | Player is quick: skips ahead, enters the lamp room before the sailors, boards early | Early lamp-room entry fires nothing; the boat refuses to cast off until Arthur is aboard ("Arthur is on his way"); the briefing waits for the diagnosis | `test_diagnosis_sequence.gd`, `test_boarding_sequence.gd` | Boarding before Arthur arrives |
| S07 | Gate shut | The sailors wait below it and never pass; Ted's IDLE_STEP_2 nudges | `test_sailors_sequence.gd`, `test_island_gate.gd` | Closing the gate again while the sailors are walking through (they have no collision) |
| S08 | Ted's lines only inside the building | Held while the player is outside, spoken once inside; nudges dropped; the knock greeting is the one exception | `test_intro_sequence.gd`, `test_slice_playthrough.gd` | The Tuesday sound review: Ted's loudness and muffling elsewhere |
| S09 | Daniel speaks only with the player in the basement | His arrival line and basement lines are held until the player is down there with him | `test_sailors_sequence.gd`, `test_slice_playthrough.gd` | |
| S10 | The opening | E shows "Knock"; the knock sounds; Ted opens the door; then his greeting; Ted walks up the tower as he orders the coal | `test_intro_sequence.gd`, `test_door.gd` | The knock sound, Ted's walk (53 s) |
| S11 | Hazards on the sea from the start, outbound and return | 15 hazards placed at level load; the safe lane is clear with margin; near misses (within 2.5 m) and collisions get more frantic in three levels; outbound collisions recover as before, return collisions throw the boat back 3 m, rock it hard and charge 5 s | `test_crossing_sequence.gd` | Steering feel at 8 m/s; hazard readability at night in rain |
| S12 | Auto-docking | DOCKING_DIALOGUE at both docks every time; at the lighthouse after return collisions the admonishment (1, 2 to 3, 4 or more hits), before "go go go" | `test_crossing_sequence.gd`, `test_slice_playthrough.gd` | The docking take-over (the player's jump ashore) |
| S13 | The burner can never be permanently lost | It is carried in the hands, rides the boat, can only be put in the boat's slot or the lamp socket; fitting is final | `test_carry.gd`, `test_burner_pickup.gd`, `test_lamp_fit.gd` | |
| S14 | Pause (P) and the debug aids | P freezes the clock and the ship and releases the mouse; Page Up and Page Down scale the deadline; F9 restarts; F10 dumps the event and deadline logs | `test_ship_deadline.gd`, `test_debug_flags.gd` | Pausing between jobs on the return (the exploit question, B6) |
| S15 | Restart after a fail or a win | A new attempt: level reloaded, state cleared, door shut and knockable, deadline -1, hazards back, buses at full level | `test_slice_playthrough.gd -- fail`, `test_game_state.gd` | |
| S16 | Waves on and off | Easy outbound, hectic return, never out-pushes the steering; waves off behaves calm | `test_wave_crossings.gd` | Whether the return reads as "hectic" without being unfair |
| S17 | Audio mix | Layers follow the phase; the storm follows the deadline clock; ducking under speech; indoor muffle; the fail sequence | `test_audio_mixer.gd` | Everything about how it sounds (nothing has been heard): the Tuesday 3 Nov review |
| S18 | Goal tracker (upper right) | One short goal at a time, in story order, never behind the player; a tick and the old text for a moment when a goal is done; hidden once the attempt resolves; never shows time; fresh on restart | `test_guidance_hud.gd`, `test_slice_playthrough.gd` | Whether the wording is clear and the pace of the goals feels right; that it does not crowd the "Journal updated" note |
| S19 | Controls list (lower right) | The keys for what the player is doing (on foot, at the helm), read from the input map; debug keys not listed; dims after 45 s and comes back when the mode changes | `test_guidance_hud.gd` | Legibility over the bright sky and the dark interior; that the subtitles clear it (they were narrowed to 840 px) |

## Known gaps (not yet automated or not decided)

- IDLE_STEP_1 (the coal nudges) and the idle nudge wording.
- Real steering by a person along the safe lane (the full-slice test puts the boat on the route; the sweep tests prove the lane is clear).
- Deadline length (3:30 is a placeholder) and the outbound collision penalty (T19); the return penalty is 5 s.
- Voice: nothing is recorded; the line list to record is in `data/dialogue/dialogue_opening.json`.
