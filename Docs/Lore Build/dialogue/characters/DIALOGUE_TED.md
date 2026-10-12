# Ted: Dialogue

Part of *Artifact #2: Character Dialogue Sequences*. [Opening dialogue (all characters)](../DIALOGUE_OPENING_FINAL.md) · [Lore file](../../characters/chr_ted.md) · [Data (crew output)](../../../../Agent%20Crew/storm_crew/storm_crew/sample_output_live_revised/dialogue_opening.json)

**Status:** `proposed`. Written by the Opening Dialogue Crew with a live model (1 revision round(s)); reviewer verdict **PASS**. The creator approves voice and lore before anything is recorded.

## Voice (from the lore file)

> - **speech_pattern:** snarky, gruff, old-school
> - **vocabulary:** calls city folk "new money toffs"
> - **verbal_habits:** grunts, coughs
> - **sample_lines:**
>   - "A passenger ship? NOW? But the lighthouse beacon is broken!" (shared with Jeff)
>   - "What the hell is a passenger ship doing coming here, now?? It's not in the log!"
>   - "What are you looking at, you a new money toff?? Get off your arse and sort out the light!"
> - **voice_casting_notes:** gravelly older male, coastal accent

## At a glance

- **23 lines** across 3 sections, 5 alternate groups (the game plays one option at random).
- By kind: discovery 1, nudge 6, objective 7, reaction 8, setting 1.

## Step 1: Feed the boiler

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S1_01` | `GAME_STARTED` | setting | "Eclipse, storm season, and the Saltgate howling. Of course they send a new money toff." | Gruff, weary, dry. Ends on a cough. |
| `TED_S1_02` | `GAME_STARTED` | objective · alt `TED_S1_OBJ` | "Beacon's starved. Basement, engine room. Shovel coal into the boiler, the new guy." | Blunt, barking an order. |
| `TED_S1_03` | `GAME_STARTED` | objective · alt `TED_S1_OBJ` | "Boiler's cold and the beacon's starving. Down to the engine room. Shovel coal, the new guy." | Blunt, barking an order. |
| `TED_S1_04` | `ENGINE_ROOM_ENTERED` | reaction | "That's the firebox. Feed it coal, mind your sleeves, and don't stand gawping." | Gruff, shouted down the stairwell. |
| `TED_S1_05` | `COAL_LOADED_FIRST` | reaction · alt `TED_S1_COAL` | "There she goes. Keep shovelling; the needle won't climb on good intentions." | Snarky, muffled through the floor. |
| `TED_S1_06` | `COAL_LOADED_FIRST` | reaction · alt `TED_S1_COAL` | "Good. Again. A fire's a hungry thing, the new guy." | Grudging approval. |
| `TED_S1_07` | `COAL_LOADED_HALF` | reaction · alt `TED_S1_GAUGE` | "Needle's stirring. Don't stop now, the new guy." | Shouted, encouraging in a grumbling way. |
| `TED_S1_08` | `COAL_LOADED_HALF` | reaction · alt `TED_S1_GAUGE` | "Gauge is waking up. Put your back into it." | Shouted, gruff. |
| `TED_S1_09` | `BOILER_FED` | objective | "Hear that dynamo whine? Good. Now up to the lantern room and look over the arc lamp." | Gruff, a rare note of satisfaction. |
| `TED_S1_10` | `LAMP_ROOM_ENTERED` | reaction | "Arc lamp's in the middle. Open her up and look at the burner." | Shouted up the stairs, wheezing. |
| `TED_S1_11` | `BURNER_DIAGNOSED` | discovery | "Cracked clean through. The burner's finished. Hrmph. Nothing to mend up here." | Low, grim, with a cough. |
| `TED_S1_I1` | `IDLE_STEP_1` | nudge (tier 1) | "Standing there won't warm the boiler. Think where the heat comes from, the new guy." | Dry, sarcastic. |
| `TED_S1_I2` | `IDLE_STEP_1` | nudge (tier 2) | "Basement, the new guy. The engine room. Coal's piled by the firebox." | Impatient, louder. |
| `TED_S1_I3` | `IDLE_STEP_1` | nudge (tier 3) | "Go down to the engine room. Take the shovel. Load coal into the firebox." | Flat, slow and clear, exasperated. |

## Step 2: Let the sailors in

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S2_01` | `SAILORS_MOORED` | objective · alt `TED_S2_OBJ` | "Rowboat's moored at my dock. Stranded sailors, by the look. Go let them in at the island gate." | Gruff, reluctantly charitable. |
| `TED_S2_02` | `SAILORS_MOORED` | objective · alt `TED_S2_OBJ` | "Someone's tied up at my dock. Down to the island gate, the new guy. Open it for them." | Gruff, reluctantly charitable. |
| `TED_S2_03` | `WINDOW_LOOKED` | reaction | "See them? Soaked and stranded. The gate's down the path from the dock. Go on." | Grunting, gesturing. |
| `TED_S2_04` | `SAILORS_INSIDE` | reaction | "Thought the same of you. Hrmph. Dry yourselves. The boy can warm up downstairs." | Gruff, a cough hiding a smile. |
| `TED_S2_I1` | `IDLE_STEP_2` | nudge (tier 1) | "Those sailors won't dry themselves on my dock, the new guy." | Dry, impatient. |
| `TED_S2_I2` | `IDLE_STEP_2` | nudge (tier 2) | "The gate, the new guy. Down the path from the dock. Someone's shouting out there." | Louder, irritated. |
| `TED_S2_I3` | `IDLE_STEP_2` | nudge (tier 3) | "Walk to the island gate and open it. Let them in." | Flat, slow and clear. |

## Step 3: Fetch the replacement burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S3_01` | `BURNER_BRIEFING` | objective · alt `TED_S3_OBJ` | "Spare burner's at the outpost across the Gullwater. Jeff's boat will take you, the new guy." | Grim, urgent, coughing. |
| `TED_S3_02` | `BURNER_BRIEFING` | objective · alt `TED_S3_OBJ` | "No burner, no beacon. Outpost, across the Gullwater. Go with Jeff, the new guy." | Grim, urgent, coughing. |

## Staging, hints and notes

- `TED_S1_01` *staging:* Ted at the lighthouse entrance, wind audible outside.
- `TED_S1_01` *note:* Introduces eclipse, storm season and the Saltgate.
- `TED_S1_02` *staging:* Ted points toward the basement stairs.
- `TED_S1_02` *assist hint:* Go to the basement engine room and shovel coal into the boiler firebox until the gauge climbs.
- `TED_S1_03` *staging:* Ted points toward the basement stairs.
- `TED_S1_03` *assist hint:* Go to the basement engine room and shovel coal into the boiler firebox until the gauge climbs.
- `TED_S1_09` *assist hint:* Climb to the lantern room and inspect the arc lamp.
- `TED_S1_I3` *assist hint:* Go to the basement engine room, take the shovel and load coal into the firebox until the gauge climbs.
- `TED_S2_01` *staging:* Ted at the window, wind rattling the glass.
- `TED_S2_01` *assist hint:* Go to the island gate by the dock and open it for the stranded sailors.
- `TED_S2_02` *staging:* Ted at the window, wind rattling the glass.
- `TED_S2_02` *assist hint:* Go to the island gate by the dock and open it for the stranded sailors.
- `TED_S2_04` *note:* Proposal pairing with JEFF_S2_05. 'The boy' means Daniel.
- `TED_S2_I3` *assist hint:* Walk to the island gate near the dock and open it to let the sailors in.
- `TED_S3_01` *staging:* Ted in the lighthouse hall, lamplight swaying as the wind shakes the walls.
- `TED_S3_01` *assist hint:* Board Jeff's engine boat and cross the Gullwater to the outpost to retrieve the replacement burner.
- `TED_S3_02` *staging:* Ted in the lighthouse hall, lamplight swaying as the wind shakes the walls.
- `TED_S3_02` *assist hint:* Board Jeff's engine boat and cross the Gullwater to the outpost to retrieve the replacement burner.

---
*Generated by `LightingTheStorm/tools/build_character_pages.py` from `dialogue_opening.json`. Do not edit by hand.*
