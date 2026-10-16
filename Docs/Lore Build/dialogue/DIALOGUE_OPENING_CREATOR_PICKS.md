# Opening Dialogue: Creator Picks

Walkthrough on 2026-10-15. Each of the 17 "pick one" groups in the live revised opening dialogue (56 lines) was reviewed against the Canon and Review Orchestrator's rules, and the creator kept one line per group. The result is 39 lines with no random alternates. The previous docs and diagrams are in [archive/2026-10-15_before_creator_picks](archive/2026-10-15_before_creator_picks/).

The Canon review in the walkthrough used the crew's rules (the live crew could not run: the Anthropic key in `.env` was rejected). The review stored with the picked data is computed by deterministic checks, not by a model.

**Story-beat revision, 2026-10-16.** The creator then fixed the story order (`AIAgentCrew/canon.py` `STORY_BEATS`): the player starts outside and Ted opens the door; after a beat, coal; then the sailors; only then does Ted find the burner broken; then the Saltgate crossing. `AIAgentCrew/story_beats.py` applies that to these picks without changing any line ID:

| Line | Change |
|---|---|
| `TED_S1_01` | Now the greeting at the door: "Hrmph. You're the new guy, then. Storm season, and they send me a new money toff. In." |
| `TED_S1_03` | Moved to `LIGHTHOUSE_ENTERED` (inside, after a beat) |
| `TED_S1_09` | Step 1 ends at the boiler: "Now we'll see if the old girl lights." |
| `TED_S3_00` | **New**, on `BEACON_STILL_DARK`: Ted takes Isaac up to the lantern room |
| `TED_S1_10`, `TED_S1_11` | Moved to step 3; Ted opens the lamp and finds the burner broken ("We need a new one.") |
| `TED_S3_02` | "There's a spare at the Saltgate" (was "Outpost") |
| `ARTHUR_S3_04`, Arthur's step 3 nudges | The Saltgate quays instead of the outpost; `OUTPOST_REACHED` and `IDLE_OUTPOST` are now `SALTGATE_REACHED` and `IDLE_SALTGATE` |

The set is now 40 lines. The rewritten lines need a Dialogue agent and Canon re-review, and new audio, before recording.

## Picks

| Step | Plays on | Kept | Dropped | Canon note at the time |
|---|---|---|---|---|
| 1 | `GAME_STARTED` | `TED_S1_03` | `TED_S1_02` | Both clean. |
| 1 | `COAL_LOADED_FIRST` | `TED_S1_05` | `TED_S1_06` | Kept line carries Ted's snark and avoids a further "Isaac". |
| 1 | `COAL_LOADED_HALF` | `TED_S1_08` | `TED_S1_07` | Dropped line used "Isaac" again in step 1. |
| 2 | `SAILORS_MOORED` | `TED_S2_01` | `TED_S2_02` | Names the rowboat and the stranded sailors. |
| 2 | `GATE_APPROACHED` | `ARTHUR_S2_02` | `ARTHUR_S2_01` | "We mean no harm" reads wary and may hint at a reason for being on the water (open decision). |
| 2 | `GATE_OPENED` | `ARTHUR_S2_04` | `ARTHUR_S2_03` | Dropped line had Arthur use "Isaac" before any introduction. |
| 2 | `DANIEL_IN_BASEMENT` | `DANIEL_OPT_02` | `DANIEL_OPT_01` | Stronger wall hint, still ambiguous. |
| 3 | `BURNER_BRIEFING` | `TED_S3_02` | `TED_S3_01` | Dropped line said "Arthur's boat", which clashes with the rowboat and Ted's launch. |
| 3 | `BOARDING_THRESHOLD` | `ARTHUR_S3_01` | `ARTHUR_S3_02` | Both clean. |
| 3 | `BOAT_CAST_OFF` | `ARTHUR_S3_03` | `ARTHUR_S3_03B` | Dropped line said "Slow on the turns", implying a throttle. The boat has one fixed speed. |
| 3 | `OUTBOUND_NEAR_MISS` | `ARTHUR_S3_07` | `ARTHUR_S3_06` | Both clean. |
| 3 | `OUTBOUND_COLLISION` | `ARTHUR_S3_08` (reworded) | `ARTHUR_S3_09` | Both lines implied a reverse control. See the reword below. |
| 3 | `SHIP_SIGHTED` | `ARTHUR_S3_11` | `ARTHUR_S3_10` | Kept line ties the ship to the dead beacon (Pillar 1). |
| Optional | `BASEMENT_TALK` | `DANIEL_OPT_04` | `DANIEL_OPT_03` | Adds the "Arthur says it's just weather" thread. |
| Optional | `BASEMENT_BANG` | `DANIEL_OPT_06` | `DANIEL_OPT_05` | Asks the silent player to answer; works as nervous comedy. |
| Optional | `WALL_WHISPER_HEARD` | `DANIEL_OPT_08` | `DANIEL_OPT_07` | "Don't listen to it" treats the voice like an entity but confirms nothing. |
| Optional | `POSTER_EXAMINED` | `ARTHUR_S0_13` | `ARTHUR_S0_12` | Stronger hint that Arthur knows something. |

## Reword

`ARTHUR_S3_08`, on `OUTBOUND_COLLISION`. The boat has one speed and is steered only with A and D, so "back her off" implied a reverse control.

- Before: "Hold on! Back her off the rock and steer clear. Gently now."
- After: "Hold on! Swing wide of the rock and steer clear. Gently now."

This reword is the creator's pick on a suggestion; it has not been through a live Dialogue agent and Canon re-review.

## Effects to be aware of

- **Arthur-knows-more thread.** `DANIEL_OPT_04` and `ARTHUR_S0_13` together hint that Arthur knows about the Flighted. His link to them is undecided in the lore, so this is a story decision still open.
- **"Isaac" use.** `TED_S3_02`, `ARTHUR_S3_03` and `ARTHUR_S3_07` all use the player's name in the crossing. Re-count against the one-in-five limit when the set is final.
- **Game data not updated.** `LightingTheStorm/data/dialogue/dialogue_opening.json` is still the older 61-line draft. The picked data is in `AIAgentCrew/sample_output_picked/dialogue_opening.json`.
- **Voice casting** has been re-run offline on the 39 lines (`AIAgentCrew/voice_output_picked_offline`). The live run is waiting on a working Anthropic key.

Machine-readable record: `AIAgentCrew/sample_output_picked/creator_picks.json`. Rebuild with `python AIAgentCrew/apply_creator_picks.py`.
