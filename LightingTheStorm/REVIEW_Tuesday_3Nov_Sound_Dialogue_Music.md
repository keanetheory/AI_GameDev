# Tuesday 3 Nov: sound, dialogue and music review sheet

Prepared by the scheduled reminder run on 3 Nov. Nothing in the game was changed, nothing was spent and nothing was committed. Fill in the "Your call" columns and the assistant will make the edits.

## Part 1: the sounds

**Read first.** All eight sounds are synthesised CC0 stand-ins made by `tools/make_placeholder_audio.py`. The assistant checked them **numerically only** (peak, level, spectrum, loop seams) and **has never heard them**. Headless Godot has no audio device, so the 3D falloff and the real loudness balance have not been heard either.

Levels are in dB (0 = the file at full volume). A pair like `[-12, -2]` means "at deadline progress 0, then at progress 1": the storm gets louder as the hidden clock runs out.

| Sound | File | What it is | Where it plays | Level | Your call (keep / retune / replace) |
|---|---|---|---|---|---|
| Wind | `wind_loop.wav` (12 s loop) | band-limited noise, slow gusts, faint whistle | everywhere, Ambience bus | -18 on arrival, rising by phase to -14 at sea; return, final repair and resolution `[-12, -2]` | |
| Rain | `rain_loop.wav` (8 s loop) | hiss, droplet ticks, low patter | everywhere, Ambience bus | -26 on arrival, rising to -20 at sea; return onward `[-16, -5]` | |
| Boiler and dynamo | `machinery_loop.wav` (8 s loop) | boiler rumble, 50 Hz hum, whine, steam hiss | 3D source in the basement, heard through the walls by distance | silent (-80) until `BOILER_FED`, then -12; -30 while at sea; silent at the Saltgate; outside -14 | |
| Launch engine | `engine_loop.wav` (4 s loop) | steam launch chugging 4 times a second | the boat, **only while under way** | outbound -20; return `[-14, -6]`; otherwise silent | |
| Buoy bells | `bell.wav` (5 s) | struck bell, inharmonic partials | 3 placeholder 3D buoys beside the return route (positions guessed until T10), random every 6 to 11 s | -4, heard up to 300 m | |
| Ship's foghorn | `foghorn.wav` (4.5 s) | two detuned low voices, slow attack | from the passenger ship (3D): **3 blasts on a fail**, **1 blast on a win** as she clears the rock | fail +4, win 0 | |
| Ship impact | `ship_impact.wav` (6 s) | crack, sub thump, steel groan, rubble | from the ship as she strikes the rock | +6 | |
| Door knock | `knock.wav` (1.6 s) | three knuckle raps on heavy wood | the front door at the opening | (set in the opening code) | |

**Mix rules**

- **Duck under dialogue:** while Ted, Arthur or Daniel speak, wind, rain, machinery and engine drop by 6 dB (fast in, slower out). The foghorn, impact and bells are **not** ducked.
- **Indoor muffle:** inside the house footprint the wind and rain go through a 700 Hz low-pass and drop 5 dB. It does **not** cover the tower stairs or the lamp room yet (the inside check is house-only). Should it?
- **Fail sequence** (seconds after the deadline): foghorn at 0.1, 5.1 and 10.1 → impact at about 13.6 → both buses fade to silence from 18.6 to 20.6 → 1.5 s of silence → **Failed screen at 22.0 s**. A restart brings the buses back to full.

**After any change:** retune levels in `data/world/audio_spec.json` or the sounds themselves in `tools/make_placeholder_audio.py`; put any real recording's source and licence (with credit if CC BY) in `Assets/Audio/placeholder/SOURCES.md`; then run:

```bash
godot --headless --path . --import
```

```bash
godot --headless --path . --script res://tools/test_audio_mixer.gd
```

### Voice lines still to record

No voice is recorded yet for: **TED_S3_00, TED_S3_05, ARTHUR_S4_01, TED_S4_03, TED_S4_06, TED_S5_02, TED_F_01, TED_F_03, ARTHUR_S3_I2, ARTHUR_S3_I3**, plus the **six re-worded lines**. Recording them needs ElevenLabs credits; the assistant will ask before spending any. There is also no voice playback hook yet, so the duck follows the dialogue's reading timer, not real audio.

## Part 2: the dialogue lines and timings (T50, T51, T52)

`data/dialogue/dialogue_opening.json` has 69 lines (status `creator_picked`). Commit a5b5ea6 already did a humour pass and a timing review (T50/T52), so today is your sign-off on top of that, not a rewrite.

**How timing works now** (`scripts/dialogue/dialogue_loader.gd`):

- each line waits its `pause_before`, then shows for `max(1.4 s, words × 0.38 s)` and moves on by itself;
- lines on the same trigger queue one after another;
- idle nudges (`IDLE_*`) and hazard calls repeat; story lines play once.

**Rules to keep:** Ted speaks only inside the lighthouse (including the doorway and the window), Daniel only in the basement, and **line ids stay as they are** (the tests use them; change the text only).

**Things worth a look:**

1. **Fail timing clash.** TED_F_01 runs 0 to 3.8 s; TED_F_03 waits 9 s and so starts at about 12.8 s and runs to about 17.7 s. That puts "That ship... we've failed... FAILED!!" **0.8 s before the crash and over it**. Do you want Ted to speak after the impact? For example, a `pause_before` of about 10.5 would start him at 14.3 s, between the crash and the fade.
2. **Word-count timing on ellipses.** TED_F_03 joins words with "..." and no spaces, so it counts as 13 words and is shown for only about 4.9 s. Once it's recorded, the real clip length should drive it.
3. **Story beats to read aloud for length:** TED_S1_01 (the door), TED_S3_05 (the passenger ship), TED_S3_02 (the briefing) and TED_S4_03 (the lamp socket) are the longest. Check they don't overrun the action.
4. **Opening exchange.** SAILORS_INSIDE queues four lines: Arthur 1.5 s → Ted 1.0 s → Ted 0.5 s → Arthur 1.0 s. Is that pacing right for a reunion?
5. Goal wording from the Guidance work (HANDOFF_T54_T55) was left for today's review.

**T51 (where people look):** start with the SAILORS_INSIDE exchange (Arthur ↔ Ted, then Arthur watching Daniel go down), then TED_S1_01 at the door (at Isaac), TED_S2_01 (out of the window at the dock), and TED_S4_06 (at the lamp).

**T52 (snark and humour):** the current tone is absurd and dry throughout, including the hazard calls. One question to settle: should the fail lines (TED_F_01, TED_F_03) and TED_S5_02 stay completely straight? They are the only straight lines in the script now.

## Part 3: the music (T50)

**There is no music in the project yet.** The only audio is the eight placeholders above. For each piece you have, give:

| Title | Composer / source URL | Licence (credit text if CC BY) | When it fires: phase, event, or deadline clock |
|---|---|---|---|
| | | | |

The assistant will then add a `music` section to `audio_spec.json` and a Music bus with fades to `scripts/core/audio_mixer.gd`. It will need your decisions on whether the music ducks under dialogue, whether it stops for the fail silence, and whether there is a win sting. Then it will run:

```bash
godot --headless --path . --script res://tools/test_audio_mixer.gd
```

```bash
godot --headless --path . --script res://tools/test_slice_playthrough.gd
```

## Part 4: this evening (T53)

Generate the **playtest QA agents** and a **web deployment agent** that exports to HTML5 and packages the game for itch.io. The agent briefs go through the approval gate first, and the credits list needs to be in place: Meshy CC BY 4.0, the FAL terms, and any CC BY music. Nothing will be spent, no agents will be run and nothing will be committed without your go-ahead.
