# Arthur: Dialogue

Part of *Artifact #2: Character Dialogue Sequences*. [Opening dialogue (all characters)](../DIALOGUE_OPENING_FINAL.md) · [Lore file](../../characters/chr_arthur.md) · [Data (the game's script)](../../../../LightingTheStorm/data/dialogue/dialogue_opening.json)

**Status:** `creator_picked`. Written by the Opening Dialogue Crew with a live model (0 revision round(s)), then the creator picked one line per 'pick one' group on 2026-10-15 (deterministic review verdict **PASS**); since then the T50/T52 humour pass and the creator's edits. These are the lines the game plays and the voice clips were recorded from.

## Voice (from the lore file)

> - **speech_pattern:**  snarky, funny, per pillar 3
> - **vocabulary:** seasoned sailor's
> - **verbal_habits:** none
> - **sample_lines:**
>   - "A passenger ship? NOW? But the lighthouse beacon is broken!"
>   - "Turn the boat left, man, LEFT! Wash your ears out before the sea washes us out!"
> - **voice_casting_notes:** wiry, old, frantic

## At a glance

- **31 lines** across 3 sections, 0 alternate groups (the creator picked one line per group, so none remain).
- By kind: discovery 2, nudge 6, reaction 23.

## Step 2: Let the sailors in

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S2_02` | `GATE_APPROACHED` | reaction | "Easy now, we mean no harm. Just cold and wet. And Daniel's been apologising to a seagull since the rowboat. Gate, please?" | Wry, wary, hands raised. |
| `ARTHUR_S2_04` | `GATE_OPENED` | reaction | "Good hands on that gate. Daniel, move. No, the other way. Quick, now." | Frantic, slightly flustered. |
| `ARTHUR_S2_05` | `SAILORS_INSIDE` | reaction | "Ted, you old rock. Thought you'd be drowned by now. Or at least moss." | Wry, warm underneath. |
| `ARTHUR_S2_06` | `SAILORS_INSIDE` | reaction | "I'll wait here until Daniel has settled in. He gets homesick in new buildings. He once cried at a staircase." | Steady, a little weary, watching the stairwell. |

## Step 3: Fetch a new burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S3_01` | `BOARDING_THRESHOLD` | reaction | "In you get. One hand on the wheel, eyes on the rocks. Not on me. I'm not a rock. Ask Ted." | Wry, brisk, wary. |
| `ARTHUR_S3_11` | `SHIP_SIGHTED` | discovery | "There! Ship's lights, out in the swell. She can't see the rocks. No beacon. She's about as lost as Daniel in a staircase." | Hushed, tight, urgent. |
| `ARTHUR_S3_03` | `BOAT_CAST_OFF` | reaction | "Keep her off the rocks, Isaac. Watch the water, not the dark. The dark's just showing off." | Frantic, shouting over the engine. |
| `ARTHUR_S3_07` | `ARTHUR_NEAR_1` | reaction | "Too close! Give the rocks some room, Isaac. Plenty of time to hug them later." | Sharp, breathless. |
| `ARTHUR_S3_08` | `ARTHUR_HIT_1` | reaction | "Hold on! Swing wide of the rock. Gently now. It's had worse." | Shouted, rattled but steady. |
| `ARTHUR_NEAR_2` | `ARTHUR_NEAR_2` | reaction | "Careful, Isaac! Far too close. One of them winked at me!" | Tight, worried, louder. |
| `ARTHUR_NEAR_3` | `ARTHUR_NEAR_3` | reaction | "Isaac! We'll be on the rocks! Steer away, steer away, now, now, now!" | Frantic, near panic, shouted over the engine. |
| `ARTHUR_HIT_2` | `ARTHUR_HIT_2` | reaction | "Hold on, Isaac! She's taking a beating! Swing wide and steady her, quick! She's not even ours!" | Alarmed, shouted. |
| `ARTHUR_HIT_3` | `ARTHUR_HIT_3` | reaction | "She won't take much more! Get clear and steer true! I'm too handsome to drown!" | Desperate, hoarse. |
| `ARTHUR_DOCK_01` | `DOCKING_DIALOGUE` | reaction | "Hands off now, you've done the steering, I'll bring her in while you get ready to jump. Try not to land on a fish." | Steadying, calm, taking the wheel. |
| `ARTHUR_DOCK_L1` | `DOCKING_DIALOGUE_LIGHTHOUSE_1` | reaction | "Hands off now. That was rough going, Isaac. I'll bring her in; you get ready to jump. We only brushed the sea once." | Dry, a little pointed. |
| `ARTHUR_DOCK_L2` | `DOCKING_DIALOGUE_LIGHTHOUSE_2` | reaction | "Hands off! You nearly wrecked us out there, Isaac. I'll bring her in; be ready to jump. I owe a lot of apologies to them rocks!" | Sharp, angry under the relief. |
| `ARTHUR_DOCK_L3` | `DOCKING_DIALOGUE_LIGHTHOUSE_3` | reaction | "Hands off, for pity's sake! You hit everything out there! I'll bring her in, you just be ready to jump! The sea sent a strongly worded letter!" | Furious, shouted. |
| `ARTHUR_S3_04` | `SALTGATE_REACHED` | reaction | "There's the Saltgate quay. Fetch the burner. I'll keep the engine turning. Touch nothing you can't pronounce." | Quick, tense. |
| `ARTHUR_S3_05` | `BURNER_PICKED_UP` | discovery | "That's it? Good. Hold it close. Back across we go. Don't sneeze on it." | Relieved, still wary. |
| `ARTHUR_RET_01` | `ARTHUR_RET_01` | reaction | "Straight down the middle! It's a corridor!" | Shouted over the engine and the storm, urgent. |
| `ARTHUR_RET_02` | `ARTHUR_RET_02` | reaction | "Left! Your left! The left one!" | Shouted over the engine and the storm, urgent. |
| `ARTHUR_RET_03` | `ARTHUR_RET_03` | reaction | "Bring her right! Right, now! Not wrong, right!" | Shouted over the engine and the storm, urgent. |
| `ARTHUR_RET_04` | `ARTHUR_RET_04` | reaction | "Steady, middle! Don't you touch them! They bite!" | Shouted over the engine and the storm, urgent. |
| `ARTHUR_RET_05` | `ARTHUR_RET_05` | reaction | "Hard left! Rocks to starboard! It's a rock convention!" | Shouted over the engine and the storm, urgent. |
| `ARTHUR_S3_I1` | `IDLE_STEP_3` | nudge (tier 1) | "Ted wants that burner, Isaac. Boat's waiting on you. It's started tapping its foot." | Wry, nudging. |
| `ARTHUR_S3_I2` | `IDLE_STEP_3` | nudge (tier 2) | "Come on! The Saltgate, across the Gullwater. Get in the boat. It's sulking. Everything here sulks." | Frantic, louder. |
| `ARTHUR_S3_I3` | `IDLE_STEP_3` | nudge (tier 3) | "Board the boat, take the wheel, steer for the Saltgate quays. Go!" | Flat, urgent, clear. |
| `ARTHUR_S3_O1` | `IDLE_SALTGATE` | nudge (tier 1) | "Burner won't walk to the boat, Isaac. I've asked it. Twice." | Dry, calling from the landing. |
| `ARTHUR_S3_O2` | `IDLE_SALTGATE` | nudge (tier 2) | "Find the burner! Keep looking. Look sharp! Look blunt, if sharp isn't working!" | Frantic, louder. |
| `ARTHUR_S3_O3` | `IDLE_SALTGATE` | nudge (tier 3) | "Find the burner, pick it up, and bring it to the boat." | Flat, urgent, clear. |

## Step 4: Fit the burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `ARTHUR_S4_01` | `RETURN_ARRIVED` | reaction | "That's the jetty! Go, go, go. Don't you wait for me! I'll tie her up. Badly. Go!" | Urgent, shouted, already stepping onto the jetty. |

## Staging, hints and notes

- `ARTHUR_S2_02` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S2_04` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S2_05` *note:* Proposal: Ted and Arthur relationship is TBD in lore.
- `ARTHUR_S2_06` *staging:* Arthur stands just inside the main door and stays there while Daniel goes down.
- `ARTHUR_S2_06` *note:* Creator, 30 Oct 2026: Arthur waits just past the main door and says this once he is in. Plays after TED_S2_04. Passes the offline rules.
- `ARTHUR_S3_01` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_11` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_03` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `ARTHUR_S3_07` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Now triggered by crossing_sequence.gd on every near miss, outbound or return, as level 1 of three that get more frantic (creator, 31 Oct 2026).
- `ARTHUR_S3_08` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. Reworded from: "Hold on! Back her off the rock and steer clear. Gently now." | Now triggered by crossing_sequence.gd on a collision, outbound or return, as level 1 of three (creator, 31 Oct 2026).
- `ARTHUR_NEAR_2` *note:* Creator, 31 Oct 2026: near-miss lines get more frantic each time.
- `ARTHUR_NEAR_3` *note:* Level 3 repeats for every further near miss on the crossing.
- `ARTHUR_HIT_2` *note:* Creator, 31 Oct 2026: three levels of concern.
- `ARTHUR_HIT_3` *note:* Level 3 repeats for every further collision on the crossing.
- `ARTHUR_DOCK_01` *note:* Creator, 31 Oct 2026 (DOCKING_DIALOGUE): plays every time the boat starts auto-docking, at the Saltgate and at the lighthouse. Wording is the creator's.
- `ARTHUR_DOCK_L1` *note:* Replaces DOCKING_DIALOGUE at the lighthouse when the return had 1 collision (creator, 31 Oct 2026). Plays before "go go go".
- `ARTHUR_DOCK_L2` *note:* Replaces DOCKING_DIALOGUE at the lighthouse when the return had 2 or 3 collisions.
- `ARTHUR_DOCK_L3` *note:* Replaces DOCKING_DIALOGUE at the lighthouse when the return had 4 or more collisions.
- `ARTHUR_S3_04` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `ARTHUR_RET_01` *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: centre.
- `ARTHUR_RET_02` *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: left.
- `ARTHUR_RET_03` *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: right.
- `ARTHUR_RET_04` *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: centre.
- `ARTHUR_RET_05` *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: left. Changed from 'Hard left, lad!' (canon: nobody calls the player lad).
- `ARTHUR_S3_I3` *assist hint:* Board the engine boat, steer across the Gullwater and land at the Saltgate quays to fetch the burner.
- `ARTHUR_S3_O3` *assist hint:* Find the replacement burner, pick it up and bring it back to the boat.
- `ARTHUR_S4_01` *note:* The crossing crew's arrival_line (AIAgentCrew/output/return_crossing.json), added to the opening data for T11. Plays before TED_S4_01.

---
*Generated by `LightingTheStorm/tools/build_character_pages.py` from `data/dialogue/dialogue_opening.json`. Do not edit by hand.*
