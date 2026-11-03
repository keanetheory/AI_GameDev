# Ted: Dialogue

Part of *Artifact #2: Character Dialogue Sequences*. [Opening dialogue (all characters)](../DIALOGUE_OPENING_FINAL.md) · [Lore file](../../characters/chr_ted.md) · [Data (the game's script)](../../../../LightingTheStorm/data/dialogue/dialogue_opening.json)

**Status:** `creator_picked`. Written by the Opening Dialogue Crew with a live model (0 revision round(s)), then the creator picked one line per 'pick one' group on 2026-10-15 (deterministic review verdict **PASS**); since then the T50/T52 humour pass and the creator's edits. These are the lines the game plays and the voice clips were recorded from.

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

- **34 lines** across 6 sections, 0 alternate groups (the creator picked one line per group, so none remain).
- By kind: discovery 2, nudge 10, objective 7, reaction 14, setting 1.

## Optional discoveries

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S0_13` | `POSTER_EXAMINED` | reaction | "Nothing there for us. Leave it be. The burner, the burner." | Brusque, uneasy. |

## Step 1: Arrive and feed the boiler

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S1_01` | `GAME_STARTED` | setting | "Hrmph. The new guy. Storm season, and they send me a money toff in shoes like that. In. Mind the gull, he's the landlord." | Gruff, weary, dry. Ends on a cough. |
| `TED_S1_03` | `LIGHTHOUSE_ENTERED` | objective | "Boiler's cold and the beacon's starving. Hasn't eaten since the Pleistocene. Engine room, Isaac. Shovel coal. Quickly. It's sulking." | Blunt, barking an order. |
| `TED_S1_04` | `FIREBOX_APPROACHED` | reaction | "That's the firebox. Feed it coal, mind your sleeves, and don't make eye contact. It holds grudges." | Gruff, shouted down the stairwell. |
| `TED_S1_04b` | `FIREBOX_APPROACHED` | reaction | "Also, if you hear singing down there, that's the pipes. Don't sing back." | Gruff, shouted down the stairwell. |
| `TED_S1_05` | `COAL_LOADED_FIRST` | reaction | "There she goes. Keep shovelling. The needle is a coward and only moves when watched." | Snarky, muffled through the floor. |
| `TED_S1_05b` | `COAL_LOADED_FIRST` | reaction | "One shovel's worth. The old girl ate it and didn't even say thank you. Rude." | Snarky, muffled through the floor. |
| `TED_S1_08` | `COAL_LOADED_HALF` | reaction | "Gauge is waking up. Nobody tell it what year it is. It'll want its pension." | Shouted, gruff. |
| `TED_S1_09` | `BOILER_FED` | objective | "Hear that dynamo whine? That's joy, that is. Or a mouse in the works. Either way, she lives, and I'm putting it in the log as a miracle." | Gruff, a rare note of satisfaction. |
| `TED_S1_I1` | `IDLE_STEP_1` | nudge (tier 1) | "Standing there won't warm the boiler. I tried it for a whole winter. Boiler stayed cold. I got a cold." | Dry, sarcastic. |
| `TED_S1_I2` | `IDLE_STEP_1` | nudge (tier 2) | "Basement, Isaac. Engine room. The coal's the big black heap. It's not a sleeping dog. Don't pet it." | Impatient, louder. |
| `TED_S1_I3` | `IDLE_STEP_1` | nudge (tier 3) | "Engine room. Shovel. Firebox. In that order. I've written it on my hand in case I forget too." | Flat, slow and clear, exasperated. |
| `TED_S1_I4` | `IDLE_STEP_1` | nudge (tier 4) | "I'll tell you what's down there: coal, a boiler, and my last shred of hope. Go and fetch all three." | Flat, slow and clear, exasperated. |
| `TED_S1_I5` | `IDLE_STEP_1` | nudge (tier 5) | "I'm not angry, Isaac. I'm a lighthouse keeper. We don't get angry. We just glare, slowly, in a circle." | Flat, slow and clear, exasperated. |
| `TED_S1_I6` | `IDLE_STEP_1` | nudge (tier 6) | "Go down the stairs. They're the ones that go down. Isaac, I believe in you, which is a first for me." | Flat, slow and clear, exasperated. |

## Step 2: Let the sailors in

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S2_01` | `SAILORS_MOORED` | objective | "Rowboat at my dock. Two men in it, wetter than the sea itself, which I didn't think possible. Go and let them in at the island gate." | Gruff, reluctantly charitable. |
| `TED_S2_03` | `WINDOW_LOOKED` | reaction | "See them? Soaked and stranded. One of them's waving a sock like a flag of surrender. Gate's down the path. Go on." | Grunting, gesturing. |
| `TED_S2_04` | `SAILORS_INSIDE` | reaction | "Thought the same of you. Hrmph. Dry yourselves." | Gruff, a cough hiding a smile. |
| `TED_S2_04b` | `SAILORS_INSIDE` | reaction | "The boy can warm up downstairs. Boiler's finally working now it's fed. Don't tell it I said that. It's sensitive." | Gruff, a cough hiding a smile. |
| `TED_S2_I1` | `IDLE_STEP_2` | nudge (tier 1) | "Those sailors won't dry themselves on my dock, Isaac. I checked. For an hour." | Dry, impatient. |
| `TED_S2_I2` | `IDLE_STEP_2` | nudge (tier 2) | "The gate, Isaac. Down the path from the dock. One of them's started negotiating with the gate. He's not winning." | Louder, irritated. |
| `TED_S2_I3` | `IDLE_STEP_2` | nudge (tier 3) | "Walk to the island gate and open it. Let them in. Before they start naming the rocks." | Flat, slow and clear. |
| `TED_S2_I4` | `IDLE_STEP_2` | nudge (tier 4) | "I can hear them from here, and so can the fish. Isaac, the gate. It's a door that lives outdoors." | Flat, slow and clear. |

## Step 3: Fetch a new burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S3_00` | `BEACON_STILL_DARK` | objective | "Dynamo's running and still no light. Something's wrong up top. Lantern room, Isaac. With me. Let's see if we can't get this old girl glowing." | Gruff and uneasy, looking up the stairs; the hum of the dynamo under him. |
| `TED_S1_10` | `LAMP_ROOM_ENTERED` | reaction | "Arc lamp's in the middle. Let's open her up. It's an examination, except only one of us knows what they're doing. No offence...actually, take offence, you'll get used to it." | Shouted up the stairs, wheezing. |
| `TED_S1_11` | `BURNER_DIAGNOSED` | discovery | "Cracked clean through. The burner's finished. Hrmph. We need a new one." | Low, grim, with a cough. |
| `TED_S3_05` | `BURNER_DIAGNOSED` | discovery | "A passenger ship? Now? It's not in the log! Without the beacon she'll find the rocks. Go, Isaac! Take the boat, take the sailor, take a coat!" | Shocked, then barking; shouted from the dock path. |
| `TED_S3_02` | `BURNER_BRIEFING` | objective | "No burner, no beacon. There's a spare at the Saltgate. Go with Arthur, Isaac. He knows the way. He's also the only one who knows where the boat keeps its feelings." | Grim, urgent, coughing. |

## Step 4: Fit the burner

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S4_01` | `RETURN_ARRIVED` | objective | "Bring the burner up here, Isaac! Don't you dare drop it! I've had a day, and it's only half over!" | Shouted down the stairwell, hoarse, urgent. |
| `TED_S4_03` | `LAMP_ROOM_REENTERED` | objective | "Socket's open. Burner in, and be quick about it. Slowly, mind. She's old. Quick and slow, Isaac. It's called finesse." | Tense, close at hand. |
| `TED_S4_06` | `BURNER_FITTED` | reaction | "That's the burner home. Stand back, Isaac. Give her room to wake. She's not a morning person." | Gruff, hushed. |

## Step 5: Resolution

| ID | Plays on | Kind | Line | Delivery |
|---|---|---|---|---|
| `TED_S5_02` | `SHIP_WIN` | reaction | "She sees us! Look at her go, clear of the rocks. You did it, you money toff." | Cracked, half-laughing. |
| `TED_F_01` | `SHIP_FAIL` | reaction | "No. No, turn! Turn, you fool, the rocks! Oh, no." | Shouted, then a breaking whisper. |
| `TED_F_03` | `SHIP_FAIL` | reaction | "That ship...we didn't get the burner out in time...those poor souls on board...we've failed...FAILED!!" | Sorrowful, upset: grief breaking into anguish on the last word. |

## Staging, hints and notes

- `TED_S1_01` *staging:* Isaac stands outside the lighthouse door in the wind; Ted opens it and looks him over.
- `TED_S1_01` *note:* Introduces eclipse, storm season and the Saltgate. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken). | Plays when the player knocks (the one Ted line spoken with the player outside, creator 30 Oct 2026).
- `TED_S1_03` *staging:* Inside the hall, after a beat. Ted points toward the basement stairs.
- `TED_S1_03` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S1_03` *assist hint:* Go to the basement engine room and shovel coal into the boiler firebox until the gauge climbs.
- `TED_S1_04` *note:* Creator, 2026-11-03: plays when the player is at the firebox (FIREBOX_APPROACHED), not on entering the engine room.
- `TED_S1_04b` *note:* Creator, 2026-11-03: plays when the player is at the firebox (FIREBOX_APPROACHED), not on entering the engine room.
- `TED_S1_05` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `TED_S1_05b` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `TED_S1_08` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `TED_S1_09` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S2_01` *staging:* Ted at the window, wind rattling the glass.
- `TED_S2_01` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- `TED_S2_01` *assist hint:* Go to the island gate by the dock and open it for the stranded sailors.
- `TED_S2_04` *note:* Proposal pairing with ARTHUR_S2_05. 'The boy' means Daniel.
- `TED_S2_04b` *note:* Proposal pairing with ARTHUR_S2_05. 'The boy' means Daniel.
- `TED_S3_00` *staging:* Ted at the foot of the tower stairs, looking up at the dark lantern.
- `TED_S3_00` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S3_00` *assist hint:* Follow Ted up the tower stairs to the lantern room.
- `TED_S1_10` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S1_11` *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S3_05` *note:* Creator pick, 29 Oct 2026; moved the same day: Ted names the ship in the lamp room straight after "The burner's finished", with the ship in view (creator order: coal, up to the lamp room, "the burner is busted", then the unplanned ship). Plays after TED_S1_11. Passes the offline rules.
- `TED_S3_02` *staging:* Ted in the lighthouse hall, lamplight swaying as the wind shakes the walls.
- `TED_S3_02` *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- `TED_S3_02` *assist hint:* Board the steam launch with Arthur and cross the Gullwater to the Saltgate quays to fetch the replacement burner.
- `TED_S0_13` *note:* Optional event; location-neutral. Gate: play only after BURNER_DIAGNOSED; read earlier, the line is dropped. Poster stays ambiguous. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Creator, 2026-11-03: Ted's line, not Arthur's (was ARTHUR_S0_13).
- `TED_S1_I3` *assist hint:* Go to the basement engine room, take the shovel and load coal into the firebox until the gauge climbs.
- `TED_S2_I3` *assist hint:* Walk to the island gate near the dock and open it to let the sailors in.
- `TED_S4_01` *staging:* Ted calls from the lamp room.
- `TED_S4_01` *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review. Plays after Arthur's "Go, go, go" arrival line.
- `TED_S4_03` *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review. Needs the new LAMP_ROOM_REENTERED event.
- `TED_S4_03` *assist hint:* Fit the burner into the lamp socket.
- `TED_S4_06` *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review.
- `TED_S5_02` *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review.
- `TED_F_01` *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review. Reason line TED_F_03 follows once the creator has reworded it.
- `TED_F_03` *note:* Creator wording, 29 Oct 2026 (replaces the 19 Oct 'All is lost for those on board' line, canon FAIL_REASON_LINE). Plays after TED_F_01, then silence and the Failed screen. Pause 9 s so it starts as the ship strikes (about 13.6 s after SHIP_FAIL, after TED_F_01).

---
*Generated by `LightingTheStorm/tools/build_character_pages.py` from `data/dialogue/dialogue_opening.json`. Do not edit by hand.*
