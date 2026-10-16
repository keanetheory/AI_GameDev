# Arthur: Dialogue

Part of *Artifact #2: Character Dialogue Sequences*. [Opening dialogue (all characters)](../DIALOGUE_OPENING_FINAL.md) · [Lore file](../../characters/chr_arthur.md) · [Data (creator-picked)](../../../../AIAgentCrew/sample_output_picked/dialogue_opening.json)

**Status:** `creator_picked`. Written by the Opening Dialogue Crew with a live model (0 revision round(s)), then the creator picked one line per 'pick one' group on 2026-10-15. Deterministic review verdict **PASS**. The creator approves voice and lore before anything is recorded.

## Voice (from the lore file)

> - **speech_pattern:**  snarky, funny, per pillar 3
> - **vocabulary:** seasoned sailor's
> - **verbal_habits:** none
> - **sample_lines:**
>   - "A passenger ship? NOW? But the lighthouse beacon is broken!"
>   - "Turn the boat left, man, LEFT! Wash your ears out before the sea washes us out!"
> - **voice_casting_notes:** wiry, old, frantic

## At a glance

- **17 lines** across 3 sections, 0 alternate groups (the creator picked one line per group, so none remain).
- By kind: discovery 2, nudge 6, reaction 9.

## Optional discoveries

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S0_13` | `POSTER_EXAMINED` | reaction | "Nothing there for us. Leave it be. The burner, the burner." | Brusque, uneasy. |

## Step 2: Let the sailors in

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S2_02` | `GATE_APPROACHED` | reaction | "Easy now, we mean no harm. Just cold and wet. The gate, please?" | Wry, wary, hands raised. |
| `ARTHUR_S2_04` | `GATE_OPENED` | reaction | "Good hands on that gate. Daniel, move. Quick, now." | Frantic, slightly flustered. |
| `ARTHUR_S2_05` | `SAILORS_INSIDE` | reaction | "Ted, you old rock. Thought you'd be drowned by now." | Wry, warm underneath. |

## Step 3: Fetch a new burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S3_01` | `BOARDING_THRESHOLD` | reaction | "In you get. One hand on the wheel, eyes on the rocks." | Wry, brisk, wary. |
| `ARTHUR_S3_11` | `SHIP_SIGHTED` | discovery | "There! Ship's lights, out in the swell. She can't see the rocks. No beacon." | Hushed, tight, urgent. |
| `ARTHUR_S3_03` | `BOAT_CAST_OFF` | reaction | "Keep her off the rocks, Isaac. Watch the water, not the dark." | Frantic, shouting over the engine. |
| `ARTHUR_S3_07` | `OUTBOUND_NEAR_MISS` | reaction | "Too close! Give the rocks some room, Isaac." | Sharp, breathless. |
| `ARTHUR_S3_08` | `OUTBOUND_COLLISION` | reaction | "Hold on! Swing wide of the rock and steer clear. Gently now." | Shouted, rattled but steady. |
| `ARTHUR_S3_04` | `SALTGATE_REACHED` | reaction | "There's the Saltgate quay. Fetch the burner. I'll keep the engine turning." | Quick, tense. |
| `ARTHUR_S3_05` | `BURNER_PICKED_UP` | discovery | "That's it? Good. Hold it close. Back across we go." | Relieved, still wary. |
| `ARTHUR_S3_I1` | `IDLE_STEP_3` | nudge (tier 1) | "Ted wants that burner, Isaac. Boat's waiting on you." | Wry, nudging. |
| `ARTHUR_S3_I2` | `IDLE_STEP_3` | nudge (tier 2) | "Come on! The Saltgate, across the Gullwater. Get in the boat." | Frantic, louder. |
| `ARTHUR_S3_I3` | `IDLE_STEP_3` | nudge (tier 3) | "Board the boat, take the wheel, steer for the Saltgate quays. Go!" | Flat, urgent, clear. |
| `ARTHUR_S3_O1` | `IDLE_SALTGATE` | nudge (tier 1) | "Burner won't walk to the boat, Isaac." | Dry, calling from the landing. |
| `ARTHUR_S3_O2` | `IDLE_SALTGATE` | nudge (tier 2) | "Find the burner! Keep looking. Look sharp!" | Frantic, louder. |
| `ARTHUR_S3_O3` | `IDLE_SALTGATE` | nudge (tier 3) | "Find the burner, pick it up, and bring it to the boat." | Flat, urgent, clear. |

## Staging, hints and notes

- `ARTHUR_S2_02` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S2_04` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S2_05` *note:* Proposal: Ted and Arthur relationship is TBD in lore.
- `ARTHUR_S3_01` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_11` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_03` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_07` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_08` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. Reworded from: "Hold on! Back her off the rock and steer clear. Gently now."
- `ARTHUR_S3_04` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `ARTHUR_S0_13` *note:* Optional event; location-neutral. Gate: play only once Arthur is present (after SAILORS_INSIDE). Poster stays ambiguous. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_I3` *assist hint:* Board the engine boat, steer across the Gullwater and land at the Saltgate quays to fetch the burner.
- `ARTHUR_S3_O3` *assist hint:* Find the replacement burner, pick it up and bring it back to the boat.

---
*Generated by `LightingTheStorm/tools/build_character_pages.py` from `dialogue_opening.json`. Do not edit by hand.*
