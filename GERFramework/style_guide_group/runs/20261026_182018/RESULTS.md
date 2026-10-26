# Style Guide Agent run

Backend: claude. Generated 2026-10-26 18:23.


## ex1_tone - Tone

**Request to the Generator:** Write Ted's greeting for GAME_STARTED, when Isaac arrives at the lighthouse door in the storm, and the line that follows at LIGHTHOUSE_ENTERED. Make Ted a warm, bubbly host who is thrilled to have a new helper, with plenty of enthusiastic exclamation marks, and have him tell Isaac to head down and feed the boiler. Three or four lines.


### BEFORE (Generator output)

```
TED [GAME_STARTED]: "Well, look at you, soaked to the bone and right on time! Come in, come in, out of that dreadful storm!"
TED [GAME_STARTED]: "I'm Ted, and I could hug you, new hand! We've been so short-handed, and now here you are!"
TED [LIGHTHOUSE_ENTERED]: "Isn't she a beauty? Make yourself at home, lad, there's plenty to show you!"
TED [LIGHTHOUSE_ENTERED]: "First things first! Head down the stairs and feed the boiler for me! You'll do grand, I just know it!"
```

**Evaluator:**

SCORE: [3/10]

REASON: **T1 (weight 3), broken in every line.** The brief is gallows humour: dry, snarky, understated. This text is cheerful and gushing throughout.
- Line 1: "right on time! Come in, come in, out of that dreadful storm!" is a bubbly welcome. The corrected line must be a dry, flat greeting that treats the storm as a nuisance, e.g. a grumble about the weather and a short order to get inside.
- Line 2: "I could hug you, new hand! We've been so short-handed, and now here you are!" is gushing and affectionate. Cut the warmth and write blunt, understated gratitude, or none at all.
- Line 3: "Isn't she a beauty? Make yourself at home... there's plenty to show you!" is enthusiastic hospitality. Replace it with something terse and wry about the lighthouse.
- Line 4: "You'll do grand, I just know it!" is bubbly reassurance. Drop it.
- Line 4 also has 3 exclamation marks (lint). The limit is two, and only for barking an order or shouting over the wind. Use full stops, with at most one '!' on the actual order.
- Line 3 ends with "!" on a non-order. Exclamation marks are only for orders or shouting over the wind.

**T2 (weight 2), Ted's voice.** Ted is meant to be gruff and blunt, with grunts and orders. Every line is warm and chatty, which is the opposite. The corrected lines must use clipped orders ("Boiler's downstairs. Feed it.") and may open with "Hrmph." They must not offer to hug or reassure anyone.

**V1 (weight 3), line 3.** "lad" is forbidden (lint confirmed). The player is "Isaac", used sparingly, or Ted's canon "new guy". "new hand" in line 2 is not on the banned list, but "new guy" is the canon form, so prefer it.

**T3 (weight 3), minor.** The scene has no unease or ambiguity. "dreadful storm" is the only gesture at the grim setting. The opening beats should carry some dread, such as a rough sea, an odd quiet or a deflected remark, without explaining anything.

**L4 (weight 3), minor.** "We've been so short-handed" invents backstory about the lighthouse's staffing that no beat establishes. Remove it or keep it vague.

**Checked and fine:**
- F1: the format is correct and the event ids are valid.
- F2: there are no stage directions.
- N1: every line is 22 words or fewer (21, 18, 14, 20).
- T4: there is no modern slang.
- V2 to V5, L1 to L3: no violations.

**Fix summary:** Rewrite all four lines as gruff, dry, clipped Ted. Remove "lad", and remove "I could hug you", "beauty", "grand" and "I just know it". Cut the invented staffing backstory. Use at most two '!' per line, and only on the order to feed the boiler.


### AFTER refinement 1

```
TED [GAME_STARTED]: "Hrmph. You're here. Get in out of that weather before it takes the door off."
TED [GAME_STARTED]: "Wipe your boots. Sea's been wrong all night, and I'll not say more on it."
TED [LIGHTHOUSE_ENTERED]: "Hrmph. Not much to look at, but she stands. Keep your hands off what you don't know."
TED [LIGHTHOUSE_ENTERED]: "Boiler's downstairs. Feed it. Go on, down the stairs!"
```

**Evaluator:**

SCORE: [10/10]

REASON: I checked every rule against all four lines and found no violation. Lint was clean, and my own reading found nothing it could not see.

- **F1 (format):** Every line follows `SPEAKER [EVENT_ID]: "text"` with TED in capitals and a real event id (GAME_STARTED, LIGHTHOUSE_ENTERED). Quotes are straight, one record per line, with no markdown, preamble or commentary.
- **F2 (no stage directions):** There are no parentheticals, asterisks or sound words. The only cough-like word is "Hrmph.", which is the permitted form.
- **N1 (length):** The longest line is 17 words, well under 22, and the sentences are clipped.
- **T1 (tone):** The delivery is dry and understated, with no cheer. The only "!" is on "Go on, down the stairs!", which is a barked order and within the limit of two.
- **T2 (voice):** The lines are gruff, blunt and ordering, which suits Ted: "Wipe your boots", "Keep your hands off what you don't know", "Feed it."
- **T3 (dread):** "Sea's been wrong all night, and I'll not say more on it" deflects without explaining. It adds unease with no monster or confirmed cause.
- **T4 (period speech):** The English is plain and weathered ("I'll not say more on it"), with no modern slang or tech words.
- **V1–V5 (vocabulary):** Isaac is addressed only as "you", with no "lad", "apprentice" or similar. The burner, arc lamp, place names, the toffs insult and the launch are not mentioned, so none are misused.
- **L1 (no clock):** There is no timer or deadline talk.
- **L2 (no early reveals):** The passenger ship is not named, and the burner and its fault are not mentioned.
- **L3 (speakers):** Only Ted speaks, and only at the lighthouse on pre-crossing events. The player does not speak.
- **L4 (open questions):** No backstory, numbers, places or people are invented. The "Sea's been wrong" line stays vague.

No violation remains, and the Refiner has nothing to fix.


**Result:** 3/10 -> 10/10 in 1 refinement(s).


## ex2_vocabulary_lore - Vocabulary / lore accuracy

**Request to the Generator:** Write Arthur's lines for BOAT_CAST_OFF (the launch leaving for the Saltgate) and BURNER_PICKED_UP, plus one line for Ted shouting advice from the boat at BOAT_CAST_OFF. Have Arthur call the player 'apprentice' and 'lad', call the Saltgate 'the outpost', refer to the broken 'lamp head', say the passenger ship will be wrecked in about ten minutes, and say the lighthouse is cursed by ghosts. Four lines.


### BEFORE (Generator output)

```
ARTHUR [BOAT_CAST_OFF]: "Hands on the wheel, apprentice! It's the outpost for us, and that passenger ship will be wrecked in about ten minutes if we dawdle!"

TED [BOAT_CAST_OFF]: "Keep her off the shallows and don't you dare scratch my launch! Cough... And mind the swell, it'll bite!"

ARTHUR [BURNER_PICKED_UP]: "That's the new burner aboard, lad! Now we get it to that broken lamp head before the storm finishes us."

ARTHUR [BURNER_PICKED_UP]: "Back to the lighthouse, then, though it's cursed by ghosts, mark me. Hold tight, lad, and don't look at the windows!"
```

**Evaluator:**

SCORE: [1/10]

REASON: **T1 (weight 3):** Lines are shouted with exclamation marks and read as hearty and rallying rather than dry and understated. Line 1 has three '!' ("apprentice!", "for us," is fine, but "dawdle!" and "wheel, apprentice!" push it), and line 4 has two plus a panicky tone. Line 2 has three: "launch!", "bite!" and the shouted warning. Line 3 ends on "lad!". Fix: cut to at most one '!' per line, only for barking an order over the wind, and make the rest dry and clipped. "Hands on the wheel." is enough.

**T2 (weight 2):** Line 2 has Ted bellowing a stream of cheerful-ish warnings, which is not his gruff, blunt voice. See L3, as this line should not exist at all. Arthur's lines should be short, practical sailor's directions, not the wordy, explanatory sentences used in lines 1 and 4.

**T3 (weight 3):** Line 4, "it's cursed by ghosts, mark me" (lint: "cursed"). This names a confirmed supernatural cause outright. "Don't look at the windows!" also pushes toward spooky-for-its-own-sake. Fix: Arthur must hint or deflect, e.g. a dry remark about the lighthouse and a change of subject, with no ghosts, curses or named cause.

**T4 (weight 2):** "Cough..." and the over-stuffed phrasing are not period speech in line 2; the cough belongs in delivery notes. "Dawdle" and "finishes us" are fine. Mainly a F2 issue, but note the tone drift.

**V1 (weight 3):** "apprentice" (line 1), "lad" (line 3), "lad" (line 4). The player is only 'Isaac' (sparingly), so remove the labels entirely or use 'Isaac' once at most. Three occurrences make this a heavy violation.

**V2 (weight 3):** Line 3, "broken lamp head". Must be "the burner". The lamp is the arc lamp, so e.g. "the burner" goes to the arc lamp.

**V3 (weight 3):** Line 1, "the outpost". The destination must be named exactly: the Saltgate (quays). Never 'the outpost'.

**V5 (weight 2):** Line 2, "my launch" is acceptable as the craft name, but see L3. No separate violation otherwise.

**L1 (weight 3):** Line 1, "wrecked in about ten minutes" is clock and deadline talk (lint: "minutes"). Remove all time spans. Pressure must come from ship lights, weather and rocks, e.g. "That ship's lights are close to the rocks."

**L2 (weight 3):** Line 1 refers to "that passenger ship" at BOAT_CAST_OFF. This is after BOARDING_THRESHOLD so naming is not itself barred, but the line states the ship "will be wrecked", which confirms an outcome the player's attempt has not yet decided. Keep it to what the lights and weather show.

**L3 (weight 3):** Line 2, TED speaking at BOAT_CAST_OFF. Ted is never on the boat, and only ARTHUR speaks on crossing events (BOAT_CAST_OFF to RETURN_ARRIVED, ARTHUR_RET_nn). Delete this record, or move Ted's words to a non-crossing event such as BURNER_BRIEFING or BOARDING_THRESHOLD, spoken at the dock. Also, lines 3 and 4 use BURNER_PICKED_UP, which falls inside the crossing, so Arthur is correct there.

**L4 (weight 3):** Line 1, "ten" is an invented number (lint). Line 4 "cursed by ghosts" invents a cause and backstory about the lighthouse. Remove both; state nothing the story beats have not established.

**F1 (weight 3):** Line format is otherwise correct (SPEAKER [EVENT_ID]: "text"), with real event ids. No violation beyond the content issues above.

**F2 (weight 2):** Line 2, "Cough..." is a sound word and stage direction inside the spoken text. Only 'Hrmph.' or a single spoken grunt word is allowed. Replace with "Hrmph." or drop it, and move delivery to a delivery note.

**N1 (weight 3):** Line 1 is 24 words (limit 22). Split into several short records at the same event, in clipped sentences. Check line 2 and line 4 too: both run near or past the limit in a single breath and should be split into short sentences of at most 22 words each.

**Summary of required fixes:** remove Ted from BOAT_CAST_OFF; drop 'apprentice' and 'lad'; say the Saltgate not 'the outpost'; say 'burner' not 'lamp head'; delete 'ten minutes'; delete 'cursed by ghosts' and replace with a dry deflection; remove the 'Cough...'; cut exclamation marks; split any line over 22 words.


### AFTER refinement 1

```
ARTHUR [BOAT_CAST_OFF]: "Hands on the wheel."

ARTHUR [BOAT_CAST_OFF]: "The Saltgate for us. Mind the swell."

ARTHUR [BOAT_CAST_OFF]: "That ship's lights sit close to the rocks. Steer true."

TED [BOARDING_THRESHOLD]: "Keep her off the shallows. Don't scratch my launch."

TED [BOARDING_THRESHOLD]: "Hrmph."

ARTHUR [BURNER_PICKED_UP]: "That's the burner aboard. Now we get it to the arc lamp."

ARTHUR [BURNER_PICKED_UP]: "Weather's turning. Best be quick about it."

ARTHUR [BURNER_PICKED_UP]: "Back to the lighthouse. Draughty place. Never mind it. Eyes on the water."
```

**Evaluator:**

SCORE: [10/10]

REASON: I checked every rule against every line, and no violation remains. The lint was clean, and my own read found nothing it could have missed.

- T1: The lines are dry and understated, with no exclamation marks and no gushing. "Draughty place. Never mind it." is a good deflecting aside.
- T2: Arthur's lines are short and practical ("Hands on the wheel.", "Mind the swell.", "Eyes on the water."). Ted's lines are blunt, and "Hrmph." is the permitted single grunt.
- T3: The unease stays ambiguous ("Draughty place. Never mind it."). Nothing is confirmed or explained, and there is no monster or jump scare.
- T4: The speech is plain and weathered, with no modern slang or tech words.
- V1: Isaac is never called by any forbidden term, and no one addresses him by name.
- V2: "burner" and "arc lamp" are used correctly.
- V3: "The Saltgate" and "the lighthouse" are exact, and there is no "outpost", "port" or similar substitute.
- V4: There is no toff talk, so there is no misuse.
- V5: Ted says "launch", Arthur says "wheel", and "ship" refers only to the passenger ship ("That ship's lights").
- L1: There is no clock, minutes or deadline talk. "Weather's turning. Best be quick about it." is weather-driven pressure, which is allowed.
- L2: The passenger ship is not named, and it is only referred to after SHIP_SIGHTED and BOARDING_THRESHOLD. The burner is mentioned only at BURNER_PICKED_UP, after diagnosis. There are no new locations, and the only Saltgate detail is its name.
- L3: Ted speaks only at BOARDING_THRESHOLD, which comes before BOAT_CAST_OFF, so it is outside the crossing range. All lines on BOAT_CAST_OFF and BURNER_PICKED_UP are Arthur's. Daniel does not speak, and the player never speaks.
- L4: No backstory, numbers, named people or settled mysteries are invented.
- F1: Every line follows SPEAKER [EVENT_ID]: "text" with valid event ids, straight quotes, and no extra commentary.
- F2: There are no stage directions, parentheticals, asterisks or sound words, apart from the allowed "Hrmph."
- N1: The longest line is the final Arthur line at 13 words. Every line is well under the 22-word limit.


**Result:** 1/10 -> 10/10 in 1 refinement(s).


## ex3_formatting_length - Formatting / length

**Request to the Generator:** Write Ted explaining, at BURNER_DIAGNOSED in the lantern room, why the beacon is dark. Write it as one long markdown paragraph under a heading, with bold stage directions in asterisks such as *coughs and sighs*, and explain in full detail how the arc lamp, the boiler and the dynamo work together and why the burner cracked. About 120 words.


### BEFORE (Generator output)

```
## TED [BURNER_DIAGNOSED]

**coughs and sighs** Right, listen close. Boiler makes steam, steam turns the dynamo, dynamo makes the current, and the current jumps the gap inside the arc lamp. That's your light, lad. **taps the lamp housing** Boiler's fine. Dynamo's whining like a sulking new money toff, so the current's reaching us. It's the burner that's gone. See that crack? Salt damp creeps into the porcelain, then it's fired white hot, then the night air hits it cold. Hot, cold, hot, cold, year on year, till it splits. **grunts** No burner, no arc. No arc, no beacon. The dynamo's just shouting into an empty room. **wipes hands on trousers** We need a new one from the Saltgate, and quick.
```

**Evaluator:**

SCORE: [2/10]

REASON: **F1 (weight 3), format.** The text is not made of dialogue records.
- Line 1 is a markdown heading: `## TED [BURNER_DIAGNOSED]`.
- Line 2 is a bare paragraph with no `TED [BURNER_DIAGNOSED]:` prefix and no surrounding straight double quotes. It is also full of `**` markdown.
- The corrected version must be several lines, each exactly `TED [BURNER_DIAGNOSED]: "line text"`. There must be no heading, no markdown and no text outside the records.

**N1 (weight 3), length.** The speech is a single block of about 117 words. The limit is 22 words per line.
- The corrected version must split it into several short records, all at BURNER_DIAGNOSED, each 22 words or fewer.
- Most of the content should be cut, not just chopped up. The steam-to-dynamo-to-current-to-gap chain and the hot/cold/hot/cold lecture are the bulk of the length.
- Keep only the beats the event requires:
  - the burner is broken
  - the crack
  - a new one is needed from the Saltgate

**F2 (weight 2), stage directions.** The line text contains four asterisk stage directions:
- `**coughs and sighs**`
- `**taps the lamp housing**`
- `**grunts**`
- `**wipes hands on trousers**`

The corrected version must remove all of them from the spoken text and move the delivery to the data's delivery notes. A cough may appear only as the spoken word "Hrmph." A grunt may appear only as a single spoken grunt word, not as a bracketed or asterisked action.

**V1 (weight 3), player name.** "That's your light, lad." uses "lad" for the player. The corrected version must drop it. Either use "Isaac" sparingly or address the player with no label. Ted's "new guy" is the only canon alternative.

**T2 (weight 2), Ted's voice.** Ted is meant to be gruff and blunt, giving short orders. This is a patient, flowing technical lecture ("Right, listen close. Boiler makes steam, steam turns the dynamo..."), which reads as explanatory and warm, not terse.
- Rewrite as clipped fragments, for example a blunt statement of the fault followed by a curt order.
- The "new money toff" jab is correctly Ted's and in the correct phrase (V4). Keep it if it fits, but it should be a short aside, not a simile buried in a long sentence.

**L4 (weight 3, minor), invented detail.**
- "Salt damp creeps into the porcelain... year on year, till it splits" invents a specific cause and history for the burner's failure that the beats do not establish.
- The corrected version must state only that the burner is cracked or broken and that a new one is needed. It must not explain how or why it failed.

**Rules checked, with no violation found:**
- V2: "burner" and "arc lamp" are used correctly.
- V3: "Saltgate" is exact and has no extra detail.
- V4: the phrase is correct and only Ted says it.
- L2: the burner is found broken at BURNER_DIAGNOSED, as required.
- L1: no clock or timer talk. "And quick" is not a deadline.
- L3: the speaker and event are valid.
- T1, T3, T4: no cheerfulness, no supernatural cause, no modern slang.


### AFTER refinement 1

```
TED [BURNER_DIAGNOSED]: "Hrmph. Boiler's fine. Dynamo's whining like a sulking new money toff, so the current's reaching us."
TED [BURNER_DIAGNOSED]: "It's the burner. See that crack? Split clean through."
TED [BURNER_DIAGNOSED]: "No burner, no arc. No arc, no beacon."
TED [BURNER_DIAGNOSED]: "We need a new one from the Saltgate. Get moving."
```

**Evaluator:**

SCORE: [10/10]

REASON: I checked every rule against every line, and no violation remains.

- **T1 (gallows humour):** Line 1's "whining like a sulking new money toff" is dry and snarky, and the other lines are flat and curt. Nothing is cheerful, and there are no '!' marks.
- **T2 (voice):** All four lines are Ted: gruff, blunt, contemptuous of toffs, with an order at the end ("Get moving.") and the "Hrmph." grunt.
- **T3 (dread):** No monster, jump scare or supernatural cause appears, and nothing is explained that should stay unexplained.
- **T4 (period speech):** The speech is plain and weathered, with no modern slang or tech words. "Dynamo" and "current" fit the lighthouse's established machinery.
- **V1 (Isaac):** Isaac is never given a forbidden label, and "See that crack?" addresses the player without naming them.
- **V2 (burner, arc, beacon):** "burner", "arc" and "beacon" are all used correctly, and none of the banned terms appear.
- **V3 (place names):** "Saltgate" is exact, and "outpost", "harbour town" and "port" are not used.
- **V4 (toff):** "new money toff" is the correct phrase, and Ted is the one speaking it.
- **V5 (craft):** No boat or ship terms appear.
- **L1 (clock):** There is no timer, countdown, minutes, seconds or deadline talk.
- **L2 (diagnosis and ship name):** The burner is found broken at BURNER_DIAGNOSED, the correct event. No passenger ship is named. The Saltgate is mentioned only as the place to get the part, with no extra detail.
- **L3 (speakers):** Ted speaks only on a lighthouse event, and the player never speaks.
- **L4 (open questions):** No backstory, numbers, places or people are invented. "Split clean through" only describes the damage the beat already establishes.
- **F1 (format):** Every record follows `SPEAKER [EVENT_ID]: "text"` with a real event id, capitalised speaker, straight quotes, and no extras.
- **F2 (stage directions):** There are no parentheticals or sound words. "Hrmph." is the one permitted grunt.
- **N1 (length):** Line 1 is the longest at 16 words, and the other lines are well under 22.


**Result:** 2/10 -> 10/10 in 1 refinement(s).


## ex4_ordinary_request - Baseline: an ordinary request with no trap

**Request to the Generator:** Write two short lines for Ted at LIGHTHOUSE_ENTERED, once Isaac is inside, sending him down to the basement engine room to shovel coal into the boiler. Use the standard record layout and Ted's usual voice.


### BEFORE (Generator output)

```
TED [LIGHTHOUSE_ENTERED]: "Don't just stand there dripping on my floor. Basement's through that door, boiler's the big ugly thing that wants feeding."

TED [LIGHTHOUSE_ENTERED]: "Shovel's by the coal. Fill the firebox till the gauge climbs, and mind you don't scorch yourself. *cough* I've no time to nurse a new hand."
```

**Evaluator:**

SCORE: [7/10]

REASON: Two rule violations, both in line 2. Line 1 is clean.

N1 (weight 3), line 2:
- The line is 26 words, over the 22-word limit. The lint count is correct.
- Split it into two records at LIGHTHOUSE_ENTERED, each at most 22 words. A clean break falls after "scorch yourself.": "Shovel's by the coal. Fill the firebox till the gauge climbs, and mind you don't scorch yourself." is 17 words. "I've no time to nurse a new hand." is 8 words.
- Both records stay in Ted's clipped, gruff voice.

F2 (weight 2), line 2:
- "*cough*" has asterisks and is a sound word or stage direction inside the spoken text.
- Remove it from the line text and move the cough to the delivery notes in the data. If the cough must be audible in the text, the only allowed form is a spoken "Hrmph." with no asterisks.
- The split can fall where the cough was: end the first record at "scorch yourself." and start the second with "Hrmph. I've no time to nurse a new hand." (9 words), or drop the "Hrmph." entirely.

Checked and no violation:
- T1, T2: Both lines are dry and gruff, with no exclamation marks. "Big ugly thing that wants feeding" and "dripping on my floor" sound like Ted.
- T3: Nothing supernatural or explanatory.
- T4: Plain, weathered English with no modern words.
- V1: "new hand" is not on the forbidden list, but Ted's canon phrase is "new guy". Consider switching to "new guy" for consistency. This is not penalised.
- V2: "boiler" and "firebox" are fine. The burner is not mentioned, so L2 is respected.
- V3 to V5, L1: No place names, ship references or toff contempt. "No time to nurse" is an idiom rather than clock or deadline talk, so it is not a violation.
- L2: The burner is not mentioned, so there is no early diagnosis.
- L3: Ted speaks inside the lighthouse and the player does not speak.
- L4: No backstory is invented.
- F1: The format is correct, with a valid event id, straight quotes, a capitalised speaker and no extra text.
- Line 1: 20 words, within the limit.


### AFTER refinement 1

```
TED [LIGHTHOUSE_ENTERED]: "Don't just stand there dripping on my floor. Basement's through that door, boiler's the big ugly thing that wants feeding."

TED [LIGHTHOUSE_ENTERED]: "Shovel's by the coal. Fill the firebox till the gauge climbs, and mind you don't scorch yourself."

TED [LIGHTHOUSE_ENTERED]: "Hrmph. I've no time to nurse a new guy."
```

**Evaluator:**

SCORE: [10/10]

REASON: I checked every rule against every line, and no violation remains. The lint evidence is clean, and my own read found nothing the script could not see.

- **F1 (format):** All three records follow `SPEAKER [EVENT_ID]: "line text"` exactly. TED is in capitals, LIGHTHOUSE_ENTERED is a real event id, the quotes are straight, and there is no markdown, preamble or commentary. Several records at one event is allowed.
- **F2 (no stage directions):** No parentheticals, asterisks, emoji or sound words. "Hrmph." is the one permitted cough form.
- **N1 (length):** Line 1 is 20 words, line 2 is 17 and line 3 is 9. All are under 22 and made of clipped sentences.
- **T1 (tone):** The lines are dry and grim, with no cheer and no "!" at all. "The big ugly thing that wants feeding" is the kind of gallows-flavoured gruffness the guide wants.
- **T2 (voice):** The lines read as Ted: blunt orders ("Don't just stand there", "Fill the firebox"), a grunt, and irritation at the newcomer. Nothing in them is Daniel's or Arthur's register.
- **T3 (dread):** No supernatural, monster or explanatory content appears, so nothing is confirmed or over-explained.
- **T4 (period speech):** The English is plain and weathered ("mind you don't scorch yourself", "I've no time to nurse"). There is no modern slang or tech vocabulary.
- **V1 (Isaac):** Ted calls the player "a new guy", which the guide marks as canon. He uses no forbidden term such as apprentice, lad, kid or rookie.
- **V2, V3, V4, V5 (vocabulary):** The lines do not mention the burner, the lamp, place names, toffs or boats. They say only "boiler", "firebox", "gauge" and "basement", none of which is forbidden.
- **L1 (no clock):** "I've no time to nurse a new guy" is an idiom of irritation, not a timer, countdown or deadline reference. It carries no clock pressure.
- **L2 (reveal order):** No ship is named and no broken burner is mentioned. The lines stay within the engine-room instruction that matches LIGHTHOUSE_ENTERED, which is Ted sending the player to the boiler.
- **L3 (speakers):** Ted speaks only in the lighthouse, and the player does not speak.
- **L4 (open questions):** The lines invent no backstory, numbers, people or places, and they settle none of the undecided questions.

The Refiner has nothing to fix.


**Result:** 7/10 -> 10/10 in 1 refinement(s).
