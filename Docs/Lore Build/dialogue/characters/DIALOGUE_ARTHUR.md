# Arthur: Dialogue

Part of *Artifact #2: Character Dialogue Sequences*. [Opening dialogue (all characters)](../DIALOGUE_OPENING_FINAL.md) · [Lore file](../../characters/chr_arthur.md) · [Data (crew output)](../../../../Agent%20Crew/storm_crew/storm_crew/sample_output_live_revised/dialogue_opening.json)

**Status:** `proposed`. Written by the Opening Dialogue Crew with a live model (1 revision round(s)); reviewer verdict **PASS**. The creator approves voice and lore before anything is recorded.

## Voice (from the lore file)

> - **speech_pattern:**  snarky, funny, per pillar 3
> - **vocabulary:** seasoned sailor's
> - **verbal_habits:** none
> - **sample_lines:**
>   - "A passenger ship? NOW? But the lighthouse beacon is broken!"
>   - "Turn the boat left, man, LEFT! Wash your ears out before the sea washes us out!"
> - **voice_casting_notes:** wiry, old, frantic

## At a glance

- **25 lines** across 3 sections, 8 alternate groups (the game plays one option at random).
- By kind: discovery 3, nudge 6, reaction 16.

## Optional discoveries

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S0_12` | `POSTER_EXAMINED` | reaction · alt `ARTHUR_S0_POSTER` | "Old paper, Isaac. Don't dwell on it. The burner's what matters." | Wary, brusque. |
| `ARTHUR_S0_13` | `POSTER_EXAMINED` | reaction · alt `ARTHUR_S0_POSTER` | "Nothing there for us. Leave it be. The burner, the burner." | Brusque, uneasy. |

## Step 2: Let the sailors in

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S2_01` | `GATE_APPROACHED` | reaction · alt `ARTHUR_S2_GATE` | "Hoy, up there! Open the gate, would you? We're soaked to the bone." | Shouting over wind, friendly but wary. |
| `ARTHUR_S2_02` | `GATE_APPROACHED` | reaction · alt `ARTHUR_S2_GATE` | "Easy now, we mean no harm. Just cold and wet. The gate, please?" | Wry, wary, hands raised. |
| `ARTHUR_S2_03` | `GATE_OPENED` | reaction · alt `ARTHUR_S2_OPEN` | "Bless you, Isaac. Daniel, in you come, before the wind changes its mind." | Relieved, wry. |
| `ARTHUR_S2_04` | `GATE_OPENED` | reaction · alt `ARTHUR_S2_OPEN` | "Good hands on that gate. Daniel, move. Quick, now." | Frantic, slightly flustered. |
| `ARTHUR_S2_05` | `SAILORS_INSIDE` | reaction | "Ted, you old rock. Thought you'd be drowned by now." | Wry, warm underneath. |

## Step 3: Fetch the replacement burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S3_01` | `BOARDING_THRESHOLD` | reaction · alt `ARTHUR_S3_BOARD` | "In you get. One hand on the wheel, eyes on the rocks." | Wry, brisk, wary. |
| `ARTHUR_S3_02` | `BOARDING_THRESHOLD` | reaction · alt `ARTHUR_S3_BOARD` | "Sit tight, Isaac. She steers easy if you let her." | Wry, steadying. |
| `ARTHUR_S3_03` | `BOAT_CAST_OFF` | reaction · alt `ARTHUR_S3_CAST` | "Keep her off the rocks, Isaac. Watch the water, not the dark." | Frantic, shouting over the engine. |
| `ARTHUR_S3_03B` | `BOAT_CAST_OFF` | reaction · alt `ARTHUR_S3_CAST` | "Off we go. Slow on the turns. The Gullwater forgives nothing." | Wry, tense, over the engine. |
| `ARTHUR_S3_06` | `OUTBOUND_NEAR_MISS` | reaction · alt `ARTHUR_S3_NEAR` | "Rocks! Ease her over. Easy, easy. Good." | Sharp, frantic, then relieved. |
| `ARTHUR_S3_07` | `OUTBOUND_NEAR_MISS` | reaction · alt `ARTHUR_S3_NEAR` | "Too close! Give the rocks some room, Isaac." | Sharp, breathless. |
| `ARTHUR_S3_08` | `OUTBOUND_COLLISION` | reaction · alt `ARTHUR_S3_HIT` | "Hold on! Back her off the rock and steer clear. Gently now." | Shouted, rattled but steady. |
| `ARTHUR_S3_09` | `OUTBOUND_COLLISION` | reaction · alt `ARTHUR_S3_HIT` | "That hull's taken worse. Reverse, turn wide, try again." | Gritted, wry, calming. |
| `ARTHUR_S3_10` | `SHIP_SIGHTED` | discovery · alt `ARTHUR_S3_SHIP` | "Lights on the water! A big ship, and she's bearing for the rocks." | Hushed, alarmed, wry edge gone. |
| `ARTHUR_S3_11` | `SHIP_SIGHTED` | discovery · alt `ARTHUR_S3_SHIP` | "There! Ship's lights, out in the swell. She can't see the rocks. No beacon." | Hushed, tight, urgent. |
| `ARTHUR_S3_04` | `OUTPOST_REACHED` | reaction | "There's the landing. Fetch the burner. I'll keep the engine turning." | Quick, tense. |
| `ARTHUR_S3_05` | `BURNER_PICKED_UP` | discovery | "That's it? Good. Hold it close. Back across we go." | Relieved, still wary. |
| `ARTHUR_S3_I1` | `IDLE_STEP_3` | nudge (tier 1) | "Ted wants that burner, Isaac. Boat's waiting on you." | Wry, nudging. |
| `ARTHUR_S3_I2` | `IDLE_STEP_3` | nudge (tier 2) | "Come on! The outpost, across the Gullwater. Get in the boat." | Frantic, louder. |
| `ARTHUR_S3_I3` | `IDLE_STEP_3` | nudge (tier 3) | "Board the boat, take the wheel, steer for the outpost landing. Go!" | Flat, urgent, clear. |
| `ARTHUR_S3_O1` | `IDLE_OUTPOST` | nudge (tier 1) | "Burner won't walk to the boat, Isaac." | Dry, calling from the landing. |
| `ARTHUR_S3_O2` | `IDLE_OUTPOST` | nudge (tier 2) | "Find the burner! Keep looking. Look sharp!" | Frantic, louder. |
| `ARTHUR_S3_O3` | `IDLE_OUTPOST` | nudge (tier 3) | "Find the burner, pick it up, and bring it to the boat." | Flat, urgent, clear. |

## Staging, hints and notes

- `ARTHUR_S2_05` *note:* Proposal: Ted and Arthur relationship is TBD in lore.
- `ARTHUR_S0_12` *note:* Optional event; location-neutral. Gate: play only once Arthur is present (after SAILORS_INSIDE). Poster stays ambiguous.
- `ARTHUR_S0_13` *note:* Optional event; location-neutral. Gate: play only once Arthur is present (after SAILORS_INSIDE). Poster stays ambiguous.
- `ARTHUR_S3_I3` *assist hint:* Board the engine boat, steer across the Gullwater and land at the outpost to fetch the burner.
- `ARTHUR_S3_O3` *assist hint:* Find the replacement burner, pick it up and bring it back to the boat.

---
*Generated by `LightingTheStorm/tools/build_character_pages.py` from `dialogue_opening.json`. Do not edit by hand.*
