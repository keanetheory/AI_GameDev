# Playtest QA: dialogue and music timing with the recorded clips (QA-05)

3 Nov 2026, Playtest QA agent. Headless, the real level and GameState, the real clip lengths (68 lines, 527.8 s of speech; `tools/probe_clip_lengths.gd`). Times are game seconds from the level load.

How it was measured: `tools/probe_dialogue_timing.gd` runs the full-slice playthrough unchanged and logs every event, every line queued / held / started / ended, the music track and the outcome screen. `tools/probe_dialogue_timing_paced.gd` is the same run with a **patient** player who waits until nobody is talking before each step (up to the burner; from the burner on the clock runs, so the return is sailed at the playthrough's fixed pace of about 9 m/s). The scripted player teleports between beats, so where a human walks (up the tower, ashore and up to the lamp) it is faster than any person; those cases are marked "harness-fast".

How the loader works (relevant to every row): one queue for all speakers, first in first out; a line plays its whole clip plus 0.25 s; nothing is ever cut, dropped for being late, or pre-empted. A `requires` condition (Ted: player inside; Daniel: both in the basement) is checked when the line is queued; a held line joins the back of the queue when its condition comes true. So two voices never overlap; every problem below is a line arriving **late**, after the moment it is about.

## Findings

| # | What | Evidence | Severity | Owner | Backlog |
|---|---|---|---|---|---|
| F1 | **TED_F_03 talks over the silence and the Failed screen.** TED_F_01 plays 0 to 6.2 s after SHIP_FAIL; TED_F_03 has pause_before 9 s and an 11.52 s clip, so it runs 15.2 to 26.9 s. The fail audio: horns at 0, 5 and 10 s, the ship strikes at about 13.6 s, the silence fades from 18.6 to 20.6 s and holds to about 22.1 s, then the Failed screen fades in over 2.5 s. The Voice bus is not part of the silence (audio_mixer.gd `_step_fail` fades Ambience, SFX and Music only), so the whole silence is talked over and the line runs about 4.8 s into the Failed screen. Only when the player is inside at SHIP_FAIL (on the boat both lines are held and the restart clears them). | clip lengths; `data/world/audio_spec.json` "fail"; `outcome_screens.json`; audio_mixer.gd 452-461 | 6 | Sound agent, Story / Fail-State; creator decides | T71 |
| F2 | **Arthur's collision lines pile up.** Every collision queues a line (`crossing_sequence.gd _on_hit`, lines `once: false`, no cooldown): in the fail run 10 x ARTHUR_HIT_3 queued back to back (57 s of "She won't take much more!"); in an earlier run HIT_2, HIT_3, HIT_3 ran on for 19 s after the hits. The near-miss calls have a cooldown; the hit calls do not. | paced fail table below (ARTHUR_HIT_3 x10) | 5 | Gameplay / Systems (crossing), Sound | T72 |
| F3 | **Navigation calls wait behind other lines.** ARTHUR_RET_01 ("Straight down the middle!") waited 6.8 s behind Arthur's burner line ARTHUR_S3_05 (about 65 m at the boat's speed); ARTHUR_RET_04 waited 3.2 s behind a near-miss line; after a collision the safe-lane call waits for the 5 to 7 s hit line. A call that comes after its hazard is passed misdirects. Proposal: the calls (RET, NEAR, HIT) are dropped when stale or jump the queue; the pickup line plays before casting off or is shortened. | paced win, Step 6 | 6 | Gameplay / Systems, Sound | T73 |
| F4 | **No expiry on queued or held lines, so held lines arrive in a late burst.** Ted's lines held while the player is outside are all released on stepping in and queue behind whatever is playing. In the patient run Ted's sailor greeting (TED_S2_04, 04b) and his call to the lamp room (TED_S3_00, "still no light, something's wrong up top") played 14 to 34 s after their moment, after the player was already in the lamp room, and "Cracked clean through" (TED_S1_11) 34 s after BURNER_DIAGNOSED. At the end (harness-fast): "Bring the burner up here" (TED_S4_01) played after the burner was fitted and the ship saved, "Socket's open" 7 s after the fit, "She sees us!" (TED_S5_02) 27 s after SHIP_WIN. A person walking the stairs gives the queue more time, so how often this is heard needs a human playtest, but nothing guards against it. Proposal: a line may carry `expires_on` (an event after which it is dropped) or a maximum wait. | paced win, Steps 3 and 7 | 5 | Gameplay / Systems (dialogue_loader.gd) | T74 |
| F5 | **Arthur's Saltgate lines lag the docking.** ARTHUR_S3_11 (ship sighted, 9.5 s) is still playing as the launch docks; ARTHUR_DOCK_01 ("Hands off now ... get ready to jump") starts 9.6 s after docking began and "There's the Saltgate quay. Fetch the burner" 11.4 s after SALTGATE_REACHED. The outbound here is teleported (harness-fast: a real outbound crossing takes about 50 s, which would clear the queue). | paced win, Steps 4 and 5 | 3 | Sound, creator (pacing) | duplicate of T74 (same mechanism) |
| F6 | **A line can start while the game is paused.** The `pause_before` wait uses `get_tree().create_timer(pause)`, which keeps counting while the tree is paused (process_always defaults to true), so a line queued just before P is pressed starts (subtitle and voice) while paused. Seen with TED_S1_01 (pause_before 1 s). The clip timer itself respects the pause. | `tools/probe_exploratory.gd -- pause_beats` | 4 | Gameplay / Systems (dialogue_loader.gd `_play_queue`) | T75 |
| F7 | **Ted's poster line is lost for good if the poster is read before BURNER_DIAGNOSED.** The line is dropped (`requires_drop`) and POSTER_EXAMINED is one-shot, so reading it again later fires nothing. The poster is in the hall at the start, so most players will read it early. | `probe_exploratory.gd -- poster_early`: the second read "accepted=false"; TED_S0_13 never played | 4 | Gameplay / Systems, creator | T76 |

Checked and correct:
- Music: 'Landed at Bracken Isle' from the start; 'Get to Saltgate' exactly when TED_S3_02 ends (both at 236.2 s); 'Get to Bracken Isle' on BURNER_PICKED_UP (288.9 s); the later cast-off cue did not move it back; after a restart it is back on 'Landed' (S23). On the win it keeps playing; on the fail it fades with the silence (test_audio_mixer).
- Daniel: nothing while the player is upstairs; his first line on the first visit down (DANIEL_OPT_02 at BASEMENT_VISITED); three visits then silence are covered by `test_sailors_sequence.gd` (S09).
- Ted's firebox lines wait for FIREBOX_APPROACHED (TED_S1_04 queued at the firebox zone at 32.2 s, not on entering the engine room at 31.8 s).
- The diagnosis waits for Ted's "Let's open her up" when the queue is clear (TED_S1_10 ended 164.7 s, BURNER_DIAGNOSED 165.4 s); when the queue is busy the fallback opens the lamp before he has said it (fast run: BURNER_DIAGNOSED 128.2 s, TED_S1_10 started 141.1 s).
- Leaving the building mid-line: the line finishes (the condition is only checked when queued); nothing is left held (`-- leave_midline`).

## TED_F_03 against the Failed screen: options for the creator

| Option | Effect | Cost |
|---|---|---|
| A. Play TED_F_03 on the Failed screen on purpose (trigger it once the screen has faded in, pause about 1 s) | The epitaph over the black screen; the silence stays silent | A new trigger (an outcome-screen event); the Failed screen stays up at least 12 s |
| B. Hold the Failed screen until the voice queue is empty | Nothing is cut; the fail sequence grows to about 27 s | One condition in outcome_screen.gd |
| C. Shorten pause_before to about 1.5 s | F_03 runs 7.7 to 19.4 s: ends before the silence, but talks over the crash at 13.6 s | Data only |
| D. Re-record F_03 shorter, or cut it | Fits the gap after the crash | Voice credits (creator) |
| E. Leave it | Ted talks through the silence and into the screen | None |

Recommendation: A or B, which keep the silence the fail contract asks for.

## Timing tables (patient player)

Columns: queued (or released from hold), held from, starts, ends, clip length, wait in the queue, and the story events that fired while it was speaking.

### Patient player, the win


**Step 1: arrive and feed the boiler**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| TED_S1_01 | 2.8 | - | 3.7 | 17.9 | 13.92 | 0.9 | - |
| TED_S1_03 | 3.2 | - | 20.0 | 31.5 | 11.20 | 16.8 | - |
| TED_S1_04 | 32.2 | - | 32.7 | 44.0 | 11.04 | 0.4 | - |
| TED_S1_04b | 32.2 | - | 45.5 | 52.4 | 6.64 | 13.3 | - |
| TED_S1_05 | 52.8 | - | 52.7 | 60.1 | 7.12 | -0.1 | COAL_LOADED_FIRST (52.7), COAL_LOADED_HALF (53.8), BOILER_FED (55.3) |

**Step 2: the sailors and the gate**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| TED_S1_05b | 52.8 | - | 60.9 | 67.9 | 6.80 | 8.1 | - |
| TED_S1_08 | 53.8 | - | 67.9 | 74.7 | 6.56 | 14.1 | - |
| TED_S1_09 | 55.4 | - | 75.6 | 88.7 | 12.80 | 20.2 | SAILORS_MOORED (88.2) |
| TED_S2_01 | 88.2 | - | 89.2 | 99.5 | 10.00 | 1.0 | WINDOW_LOOKED (98.2) |
| TED_S2_03 | 98.2 | - | 99.5 | 110.2 | 10.40 | 1.2 | - |
| ARTHUR_S2_02 | 111.0 | - | 111.0 | 120.4 | 9.20 | -0.1 | GATE_APPROACHED (111.0), GATE_OPENED (111.4) |
| ARTHUR_S2_04 | 111.5 | - | 120.4 | 125.6 | 4.88 | 9.0 | - |
| ARTHUR_S2_05 | 134.3 | - | 135.7 | 140.8 | 4.80 | 1.4 | - |
| ARTHUR_S2_06 | 134.3 | - | 141.8 | 151.2 | 9.12 | 7.4 | DANIEL_IN_BASEMENT (142.7), BEACON_STILL_DARK (150.8) |

**Step 3: the diagnosis and the briefing**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| TED_S1_10 | 151.3 | - | 151.2 | 164.7 | 13.20 | -0.1 | LAMP_ROOM_ENTERED (151.2) |
| TED_S2_04 | 151.4 | 134.3 | 165.8 | 171.6 | 5.60 | 14.3 | - |
| TED_S2_04b | 151.4 | 134.3 | 172.2 | 184.0 | 11.52 | 20.7 | - |
| TED_S3_00 | 151.4 | 150.8 | 185.5 | 198.7 | 12.88 | 34.1 | - |
| TED_S1_11 | 165.4 | - | 199.5 | 205.8 | 6.08 | 34.1 | - |
| TED_S3_05 | 165.4 | - | 206.9 | 220.1 | 12.96 | 41.5 | - |

**Step 4: boarding and the outbound crossing**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| TED_S3_02 | 220.2 | - | 220.9 | 236.2 | 14.96 | 0.7 | - |
| ARTHUR_S3_01 | 246.9 | - | 246.8 | 254.3 | 7.36 | -0.1 | BOARDING_THRESHOLD (246.8) |
| ARTHUR_S3_03 | 254.7 | - | 254.4 | 260.4 | 5.76 | -0.3 | BOAT_CAST_OFF (254.4) |
| ARTHUR_S3_11 | 262.5 | - | 262.9 | 272.7 | 9.52 | 0.4 | SALTGATE_REACHED (269.3) |

**Step 5: the Saltgate**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| ARTHUR_DOCK_01 (x2) | 263.1 | - | 272.7 | 280.2 | 7.28 | 9.6 | - |
| ARTHUR_S3_04 | 269.4 | - | 280.8 | 288.8 | 7.68 | 11.4 | - |
| ARTHUR_S3_05 | 288.9 | - | 288.8 | 295.9 | 6.88 | -0.1 | BURNER_PICKED_UP (288.8), RETURN_DEPARTED (289.0) |

**Step 6: the return crossing**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| ARTHUR_RET_01 | 289.1 | - | 295.9 | 299.8 | 3.60 | 6.8 | - |
| ARTHUR_RET_02 | 298.1 | - | 299.8 | 303.2 | 3.12 | 1.7 | - |
| ARTHUR_RET_03 | 311.9 | - | 311.8 | 315.7 | 3.60 | -0.1 | - |
| ARTHUR_S3_07 | 323.2 | - | 323.2 | 328.7 | 5.28 | -0.1 | - |
| ARTHUR_RET_04 | 325.5 | - | 328.7 | 332.6 | 3.60 | 3.2 | - |
| ARTHUR_RET_05 | 339.4 | - | 339.3 | 344.1 | 4.48 | -0.1 | - |
| ARTHUR_NEAR_2 | 351.1 | - | 351.0 | 355.2 | 3.92 | -0.1 | - |

**Step 7: the fit and the ending**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| ARTHUR_S4_01 | 368.4 | - | 368.7 | 375.2 | 6.24 | 0.2 | BURNER_FITTED (368.7), SHIP_WIN (373.2) |
| TED_S4_03 | 368.5 | - | 375.8 | 382.2 | 6.16 | 7.3 | - |
| TED_S4_01 | 369.2 | 368.4 | 383.2 | 391.9 | 8.32 | 14.1 | - |
| TED_S4_06 | 369.2 | - | 392.4 | 399.4 | 6.72 | 23.3 | - |
| TED_S5_02 | 373.3 | - | 400.4 | 408.0 | 7.28 | 27.2 | - |
| DANIEL_OPT_02 | 440.0 | - | 439.7 | cut | 11.68 | -0.3 | BASEMENT_VISITED (439.7), BASEMENT_TALK (440.0) |

Music, screens and waits: MUSIC landed at 0.5; MUSIC saltgate at 236.2; MUSIC bracken at 288.9; SCREEN WIN at 436.6


### Patient player, the fail (from the return crossing)

**Step 6: the return crossing**

| Line | Queued | Held from | Starts | Ends | Clip s | Wait in queue s | Story events while it speaks |
|---|---|---|---|---|---|---|---|
| ARTHUR_RET_01 | 288.9 | - | 295.8 | 299.6 | 3.60 | 6.8 | - |
| ARTHUR_S3_08 | 298.0 | - | 299.6 | 305.3 | 5.36 | 1.7 | - |
| ARTHUR_HIT_2 | 300.6 | - | 305.3 | 312.6 | 6.96 | 4.7 | - |
| ARTHUR_HIT_3 (x10) | 302.9 | - | 312.6 | 318.6 | 5.76 | 9.7 | - |

Music, screens and waits: MUSIC landed at 0.5; MUSIC saltgate at 236.2; MUSIC bracken at 288.7; SCREEN FAIL at 380.8; RESTART - at 380.8; MUSIC landed at 381.3; SCREEN hidden at 381.3

Held and never spoken: TED_F_01, TED_F_03

The earlier steps of the fail run match the win run. On the return the scripted player stops steering, so the boat keeps colliding: that is where the ten ARTHUR_HIT_3 lines come from. Ted's fail lines were held because the player was on the boat, and the restart cleared them, as the creator's rule intends.

## Fast scripted player (the playthrough as written)

The playthrough does not wait for speech, so by the return crossing the queue is 70 to 80 s behind (the briefing TED_S3_02 plays during the return crossing, and Arthur's five calls after the burner is fitted). No person plays this fast; it shows that the queue has no back-pressure.
