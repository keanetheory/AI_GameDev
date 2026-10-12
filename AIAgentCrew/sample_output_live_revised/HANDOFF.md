# HANDOFF - GATE1_OPENING_DIALOGUE

## 1. Task and goal
Write the Gate 1 opening dialogue (steps 1-3) for Ted, Jeff and Daniel as game data with stable IDs.

## 2. Files changed
- `dialogue_opening.json` (game data), `DIALOGUE_OPENING.md` (review list)
- `handoffs/01_dialogue_brief.json`, `02_dialogue.json`, `03_dialogue_review.json`, `run_log.json`

## 3. How to run and test
- Godot 4: copy `dialogue_opening.json` to `res://data/dialogue/` and use `scripts/dialogue/dialogue_loader.gd`.
- Regenerate: `python main_dialogue.py --out dialogue_output`

## 4. Observed behaviour
PASS. All four pillar checks and all decisions-log checks pass. All six earlier issues are resolved. (1) DANIEL_OPT_07 and DANIEL_OPT_08 now carry an explicit gate: basement only, after DANIEL_IN_BASEMENT. (2) The poster lines are retagged to step 0 as JEFF_S0_12 and JEFF_S0_13, are location-neutral, and have no landing staging. (3) JEFF_S3_O2 and JEFF_S3_O3 are non-spatial. (4) The unclear 'carry it' wording is removed. (5) TED_S3_01 and TED_S3_02 are staged in the hall. (6) The poster lines are gated to after SAILORS_INSIDE, so Jeff is always present. For implementation: enforce the gates on DANIEL_OPT_07/08 and JEFF_S0_12/13 in code, since they exist only as note text. Optionally, the creator may confirm who owns the powered launch, because TED_S3_01 says 'Jeff's boat' while the sailors arrived by rowboat. This is non-blocking and implies nothing about why the sailors were on the water. The line set is ready for the next stage.
Run mode: llm. Guardrail feedback during the run:
- Dialogue agent (attempt 1): 1 error(s)
- Dialogue agent (attempt 2): 28 error(s)

- [PASS] Pillar 1: The light must return - everything leads back to the beacon: Every step points back to the beacon. TED_S1_02 and TED_S1_03 open on the starved beacon. TED_S1_09 and TED_S1_11 send the new guy to the arc lamp and its broken burner. TED_S3_02 says 'No burner, no beacon.' JEFF_S3_11 has the ship unable to see the rocks because there is no beacon. The revised poster lines JEFF_S0_12 and JEFF_S0_13 steer the player back to 'the burner', and JEFF_S3_05 turns the player back across the water.
- [PASS] Pillar 2: The storm sets the clock - pressure from the world, never a timer, meter or enemy: Pressure comes only from rocks, weather, darkness and ship lights: JEFF_S3_03, JEFF_S3_03B, JEFF_S3_06, JEFF_S3_10, JEFF_S3_11, TED_S1_01. No line contains a countdown, a deadline, a clock or a numeric figure. 'One hand on the wheel' (JEFF_S3_01) is an idiom, not timer talk. JEFF_S2_04 'Quick, now' is an urge to move, not a deadline. No enemy is written.
- [PASS] Pillar 3: Your hands, your eyes - first-person, physical, guidance from Ted and Jeff, not markers: Guidance is spoken by Ted and Jeff and tied to physical action: TED_S1_04 and TED_S1_05 (shovelling), TED_S2_03 (the path to the gate), JEFF_S3_01 and JEFF_S3_03 (wheel and rocks), JEFF_S3_O3 (pick up the burner and bring it to the boat). Staging is physical (Ted points to the stairs, Ted at the window). TED_S3_01 and TED_S3_02 are now staged in the hall, matching BURNER_BRIEFING. No line uses a marker, waypoint or meter.
- [PASS] Pillar 4: Dread you can read - ambiguity, no jump scares, the player knows what to do and why they failed: Unease is carried by ambiguous Daniel lines (DANIEL_OPT_02, DANIEL_OPT_05 to DANIEL_OPT_08) with mundane readings always offered, such as pipes, draught and wind. No scare is written. Hazard reactions are short and recoverable: JEFF_S3_06, JEFF_S3_07, JEFF_S3_08 ('Back her off the rock'), JEFF_S3_09 ('Reverse, turn wide, try again'). None gives a failure verdict. All four IDLE_* events have a three-tier ladder (hint, sharper, explicit), 12 nudge lines in total: TED_S1_I1 to I3, TED_S2_I1 to I3, JEFF_S3_I1 to I3, JEFF_S3_O1 to O3. The tier 2 and 3 lines state the action plainly, so the player always knows what to do. The previously unclear JEFF_S3_12 'carry it' line is gone.
- [PASS] Player term: only 'the new guy'; no 'apprentice'; no lad/lass/man; 'the boy' means Daniel: No line, subtitle, assist_text or journal entry uses 'apprentice', 'lad', 'lass' or 'man'. The player term appears as 'the new guy' in TED_S1_02, TED_S1_03, TED_S1_06, TED_S1_07, TED_S2_02, TED_S3_01, JEFF_S2_03, JEFF_S3_02, JEFF_S0_12 and DANIEL_OPT_03, among others. TED_S2_04 'The boy can warm up downstairs' refers to Daniel, who is about to go to the basement. No player lines are written.
- [PASS] Ship reveal: Ted never names the passenger ship before BOARDING_THRESHOLD: No Ted line mentions a ship. TED_S3_01 and TED_S3_02 (BURNER_BRIEFING, before boarding) speak only of the burner, the outpost, the Gullwater and Jeff. TED_S2_I2 refers only to 'Someone's shouting out there'. The ship is first mentioned by Jeff at SHIP_SIGHTED (JEFF_S3_10, JEFF_S3_11), which comes after BOARDING_THRESHOLD (JEFF_S3_01, JEFF_S3_02).
- [PASS] No supernatural confirmation; poster and whispers stay ambiguous: Each uncanny beat comes with a mundane reading. DANIEL_OPT_05 and DANIEL_OPT_06 say pipes. DANIEL_OPT_07 says draught. DANIEL_OPT_08 says wind. DANIEL_OPT_04 says weather. DANIEL_OPT_02 trails off with 'never mind'. JEFF_S0_12 ('Old paper') and JEFF_S0_13 ('Nothing there for us') dismiss the poster without naming or explaining it. The word 'Flighted' is never used. No line states a cause.
- [PASS] 'burner' not 'lamp head': 'Lamp head' appears nowhere. The part is always 'burner' (TED_S1_10, TED_S1_11, TED_S3_01, JEFF_S3_04, JEFF_S3_05, JEFF_S3_O1 to O3, JRN_03). 'Arc lamp' refers to the fixture, not the part.
- [PASS] Daniel stays in the basement: All eight Daniel lines (DANIEL_OPT_01 to DANIEL_OPT_08) are basement lines. DANIEL_OPT_01 and DANIEL_OPT_02 fire on DANIEL_IN_BASEMENT with staging beside the boiler. DANIEL_OPT_03 to DANIEL_OPT_06 are noted 'basement only, after DANIEL_IN_BASEMENT'. DANIEL_OPT_07 and DANIEL_OPT_08 now carry an explicit gate: play only in the basement after DANIEL_IN_BASEMENT, never elsewhere, with staging 'Daniel in the basement, close to the wall'. No Daniel line appears in step 3 or at the outpost.
- [PASS] Line length: 22 words or fewer, shoutable: I counted the longest lines. TED_S2_01 and TED_S2_02 run to 18 words each. TED_S3_01, TED_S1_03 and TED_S1_09 come next at 16 to 17 words. Every other line is shorter, so none reaches the 22-word limit. The nudge lines (JEFF_S3_O1, JEFF_S3_O2, TED_S2_I3) are very short.
- [PASS] No significant outpost detail: The outpost is never described. The only references are 'the landing' (JEFF_S3_04, JEFF_S3_I3), where the boat docks, and the staging note 'calling from the landing' in JEFF_S3_O1. JEFF_S3_O2 ('Find the burner! Keep looking. Look sharp!') and JEFF_S3_O3 ('Find the burner, pick it up, and bring it to the boat') are non-spatial. The old 'in there somewhere' and 'Go inside the outpost' lines are gone. The poster lines have moved to step 0 as JEFF_S0_12 and JEFF_S0_13, and no longer sit at the outpost.
- [PASS] No timers, countdowns, numbers or deadline talk: Spoken text contains no clock, countdown or deadline language, and no numeric figures beyond the idiom in JEFF_S3_01. Urgency is expressed only through weather, rocks and ship lights (JEFF_S3_10, JEFF_S3_11).
- [PASS] Ted introduces setting and each objective; reuse of canon lines; alternates and groups: TED_S1_01 introduces the eclipse, storm season and the Saltgate. Objectives are given by Ted in TED_S1_02/03 (step 1), TED_S2_01/02 (step 2) and TED_S3_01/02 (step 3). All 17 alternate groups (TED_S1_OBJ, TED_S1_COAL, TED_S1_GAUGE, TED_S2_OBJ, JEFF_S2_GATE, JEFF_S2_OPEN, DANIEL_SHELTER, DANIEL_TALK, DANIEL_BANG, DANIEL_WHISPER, TED_S3_OBJ, JEFF_S3_BOARD, JEFF_S3_CAST, JEFF_S3_NEAR, JEFF_S3_HIT, JEFF_S3_SHIP, JEFF_S0_POSTER) have exactly two options sharing one trigger. Every line has subtitle text.
- [PASS] Open creator decisions respected; RETURN_DEPARTED and fail lines not written: JEFF_S2_05 and TED_S2_04 are both flagged as proposals in their notes (Ted and Jeff's relationship is TBD). No line states or implies why Jeff and Daniel were on the water. No voiced/unvoiced decision is made in the lines. No RETURN_DEPARTED or JEFF_RET_* lines exist. The collision and near-miss lines (JEFF_S3_06 to JEFF_S3_09) carry no failure verdicts.

## 5. Not verified
- Voice performance and lore approval (creator).
- The loader script has not been run in the Godot engine.

## 6. Licences and provenance
Text generated by the Opening Dialogue Crew from the GDD and Lore Build canon; no external assets.

## 7. Interface or contract changes proposed
New event IDs (see `events` in the JSON). The existing event RETURN_DEPARTED is the hand-off to JEFF_RET_*.

## 8. Open creator decisions
- Which lines are voiced is a cost decision for the creator; subtitles exist for every line.
- Why Jeff and Daniel were on the water (smugglers?) remains open; no line states or implies a reason.
- Ted and Jeff's relationship is TBD in the lore; the 'drowned by now' exchange (JEFF_S2_05, TED_S2_04) is flagged as a proposal only.
- Fail-reason and outcome lines belong to the Story / Fail-State agent and are not written here.
- Where the Flighted poster physically sits is still undecided; JEFF_S0_12 and JEFF_S0_13 are deliberately location-neutral.
