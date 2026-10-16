# Ted: Dialogue

Part of *Artifact #2: Character Dialogue Sequences*. [Opening dialogue (all characters)](../DIALOGUE_OPENING_FINAL.md) · [Lore file](../../characters/chr_ted.md) · [Data (creator-picked)](../../../../AIAgentCrew/sample_output_picked/dialogue_opening.json)

**Status:** `creator_picked`. Written by the Opening Dialogue Crew with a live model (0 revision round(s)), then the creator picked one line per 'pick one' group on 2026-10-15. Deterministic review verdict **PASS**. The creator approves voice and lore before anything is recorded.

## Voice (from the lore file)

> - **speech_pattern:** snarky, gruff, old-school
> - **vocabulary:** calls city folk "new money toffs"
> - **verbal_habits:** grunts, coughs
> - **sample_lines:**
>   - "You're the new guy, then." (opening the door)
>   - "A passenger ship? NOW? But the lighthouse beacon is broken!" (shared with Arthur)
>   - "What the hell is a passenger ship doing coming here, now?? It's not in the log!"
>   - "What are you looking at, you a new money toff?? Get off your arse and sort out the light!"
> - **voice_casting_notes:** gravelly older male, coastal accent

## At a glance

- **19 lines** across 3 sections, 0 alternate groups (the creator picked one line per group, so none remain).
- By kind: discovery 1, nudge 6, objective 5, reaction 6, setting 1.

## Step 1: Arrive and feed the boiler

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S1_01` | `GAME_STARTED` | setting | "Hrmph. You're the new guy, then. Storm season, and they send me a new money toff. In." | Gruff, weary, dry. Ends on a cough. |
| `TED_S1_03` | `LIGHTHOUSE_ENTERED` | objective | "Boiler's cold and the beacon's starving. Down to the engine room. Shovel coal, Isaac." | Blunt, barking an order. |
| `TED_S1_04` | `ENGINE_ROOM_ENTERED` | reaction | "That's the firebox. Feed it coal, mind your sleeves, and don't stand gawping." | Gruff, shouted down the stairwell. |
| `TED_S1_05` | `COAL_LOADED_FIRST` | reaction | "There she goes. Keep shovelling; the needle won't climb on good intentions." | Snarky, muffled through the floor. |
| `TED_S1_08` | `COAL_LOADED_HALF` | reaction | "Gauge is waking up. Put your back into it." | Shouted, gruff. |
| `TED_S1_09` | `BOILER_FED` | objective | "Hear that dynamo whine? Good. Now we'll see if the old girl lights." | Gruff, a rare note of satisfaction. |
| `TED_S1_I1` | `IDLE_STEP_1` | nudge (tier 1) | "Standing there won't warm the boiler. Think where the heat comes from, Isaac." | Dry, sarcastic. |
| `TED_S1_I2` | `IDLE_STEP_1` | nudge (tier 2) | "Basement, Isaac. The engine room. Coal's piled by the firebox." | Impatient, louder. |
| `TED_S1_I3` | `IDLE_STEP_1` | nudge (tier 3) | "Go down to the engine room. Take the shovel. Load coal into the firebox." | Flat, slow and clear, exasperated. |

## Step 2: Let the sailors in

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S2_01` | `SAILORS_MOORED` | objective | "Rowboat's moored at my dock. Stranded sailors, by the look. Go let them in at the island gate." | Gruff, reluctantly charitable. |
| `TED_S2_03` | `WINDOW_LOOKED` | reaction | "See them? Soaked and stranded. The gate's down the path from the dock. Go on." | Grunting, gesturing. |
| `TED_S2_04` | `SAILORS_INSIDE` | reaction | "Thought the same of you. Hrmph. Dry yourselves. The boy can warm up downstairs." | Gruff, a cough hiding a smile. |
| `TED_S2_I1` | `IDLE_STEP_2` | nudge (tier 1) | "Those sailors won't dry themselves on my dock, Isaac." | Dry, impatient. |
| `TED_S2_I2` | `IDLE_STEP_2` | nudge (tier 2) | "The gate, Isaac. Down the path from the dock. Someone's shouting out there." | Louder, irritated. |
| `TED_S2_I3` | `IDLE_STEP_2` | nudge (tier 3) | "Walk to the island gate and open it. Let them in." | Flat, slow and clear. |

## Step 3: Fetch a new burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S3_00` | `BEACON_STILL_DARK` | objective | "Dynamo's running and still no light. Something's wrong up top. Lantern room, Isaac. With me." | Gruff and uneasy, looking up the stairs; the hum of the dynamo under him. |
| `TED_S1_10` | `LAMP_ROOM_ENTERED` | reaction | "Arc lamp's in the middle. Let's open her up and see what's ailing her." | Shouted up the stairs, wheezing. |
| `TED_S1_11` | `BURNER_DIAGNOSED` | discovery | "Cracked clean through. The burner's finished. Hrmph. We need a new one." | Low, grim, with a cough. |
| `TED_S3_02` | `BURNER_BRIEFING` | objective | "No burner, no beacon. There's a spare at the Saltgate, across the Gullwater. Go with Arthur, Isaac." | Grim, urgent, coughing. |

## Staging, hints and notes

- `TED_S1_01` *staging:* Isaac stands outside the lighthouse door in the wind; Ted opens it and looks him over.
- `TED_S1_01` *note:* Introduces eclipse, storm season and the Saltgate. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S1_03` *staging:* Inside the hall, after a beat. Ted points toward the basement stairs.
- `TED_S1_03` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S1_03` *assist hint:* Go to the basement engine room and shovel coal into the boiler firebox until the gauge climbs.
- `TED_S1_05` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `TED_S1_08` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `TED_S1_09` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S2_01` *staging:* Ted at the window, wind rattling the glass.
- `TED_S2_01` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `TED_S2_01` *assist hint:* Go to the island gate by the dock and open it for the stranded sailors.
- `TED_S2_04` *note:* Proposal pairing with ARTHUR_S2_05. 'The boy' means Daniel.
- `TED_S3_00` *staging:* Ted at the foot of the tower stairs, looking up at the dark lantern.
- `TED_S3_00` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S3_00` *assist hint:* Follow Ted up the tower stairs to the lantern room.
- `TED_S1_10` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S1_11` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S3_02` *staging:* Ted in the lighthouse hall, lamplight swaying as the wind shakes the walls.
- `TED_S3_02` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S3_02` *assist hint:* Board the steam launch with Arthur and cross the Gullwater to the Saltgate quays to fetch the replacement burner.
- `TED_S1_I3` *assist hint:* Go to the basement engine room, take the shovel and load coal into the firebox until the gauge climbs.
- `TED_S2_I3` *assist hint:* Walk to the island gate near the dock and open it to let the sailors in.

---
*Generated by `LightingTheStorm/tools/build_character_pages.py` from `dialogue_opening.json`. Do not edit by hand.*
