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
Gate 1 opening dialogue covers all events except RETURN_DEPARTED and passes all four pillars, with 'the new guy' used as the player term, no ship named by Ted before BOARDING_THRESHOLD, 'burner' only, no supernatural confirmation, every line at 18 words or fewer, 17 alternate groups of two options each, and complete tier 1-3 nudge ladders for all four IDLE_* events. Verdict is REVISE on two Decisions-log failures. Daniel's WALL_WHISPER_HEARD lines (DANIEL_OPT_07/08) are not gated to the basement, and the poster lines (JEFF_S3_12/13) and outpost nudges (JEFF_S3_O2/O3) add unsanctioned outpost detail. Minor fixes are also listed: the unclear 'carry it' in JEFF_S3_12 and the dock/hall staging mismatch on TED_S3_01/02. The four open creator decisions, including voicing cost and the unresolved status of the 'drowned by now' exchange, are carried forward undecided.
Run mode: llm. Guardrail feedback during the run:
- Dialogue agent (attempt 1): 1 error(s)
- Dialogue agent (attempt 2): 28 error(s)

- [PASS] Pillar 1: The light must return - everything leads back to the beacon: Every objective line points back to the beacon. TED_S1_02/03 ('Beacon's starved'), TED_S1_09 and TED_S1_11 (dynamo, arc lamp, cracked burner) set the problem. TED_S2_01/02 and TED_S3_01/02 ('No burner, no beacon') carry it forward. JEFF_S3_04 and JEFF_S3_05 retrieve the burner and head back, and JEFF_S3_11 ('No beacon') keeps the stakes on the light. JRN_01 to JRN_03 agree.
- [PASS] Pillar 2: The storm sets the clock - pressure from the world, never a timer, meter or enemy: No line uses timers, countdowns, numbers or deadline talk. Pressure comes from wind, rocks, the swell and ship lights (JEFF_S3_03, JEFF_S3_06, JEFF_S3_10, JEFF_S3_11, TED_S1_01). 'One hand on the wheel' (JEFF_S3_01) is an idiom, not a count. Urgency words such as 'Quick, now' (JEFF_S2_04) and 'Come on!' (JEFF_S3_I2) set no deadline. The collision lines (JEFF_S3_08, JEFF_S3_09) give recovery guidance and no failure verdict.
- [PASS] Pillar 3: Your hands, your eyes - first-person and physical, guidance from Ted and Jeff, not markers: Every objective and nudge is spoken in the world by Ted or Jeff, and the actions are physical: shovel, firebox, gate, wheel (TED_S1_04, TED_S2_03, JEFF_S3_01, JEFF_S3_I3). No line uses a marker or HUD pointer. assist_text on TED_S1_02/03, TED_S2_01/02, TED_S3_01/02 and the tier-3 nudges is optional restatement text, not a waypoint. The player has no lines.
- [PASS] Pillar 4: Dread you can read - unease and ambiguity, no jump scares, player always knows what to do: Unease is carried by Daniel's nervous chatter (DANIEL_OPT_02, _05, _06, _07, _08) with mundane readings always offered ('pipes', 'the draught', 'wind makes all sorts of voices'), and no scare beat exists. Every IDLE_* event has consecutive tiers 1, 2, 3 (hint, sharper, explicit): IDLE_STEP_1 = TED_S1_I1 to I3, IDLE_STEP_2 = TED_S2_I1 to I3, IDLE_STEP_3 = JEFF_S3_I1 to I3, IDLE_OUTPOST = JEFF_S3_O1 to O3. Hazards are clear and recoverable (JEFF_S3_06 to JEFF_S3_09). Minor clarity flag: JEFF_S3_12 says 'Don't read it, carry it', which is ambiguous about what to carry.
- [PASS] Player term: only 'the new guy'; never apprentice, lad, lass or man; no player lines; 'the boy' means Daniel: The player is addressed only as 'the new guy' (TED_S1_02, TED_S1_03, TED_S1_06, TED_S1_07, TED_S2_02, TED_S2_I1, TED_S2_I2, TED_S3_01, TED_S3_02, JEFF_S2_03, JEFF_S3_02, JEFF_S3_03, JEFF_S3_07, DANIEL_OPT_03 and others). No line or journal entry contains 'apprentice', 'lad', 'lass' or 'man'. 'The boy' in TED_S2_04 is flagged in its note as Daniel. No line has the player as speaker.
- [PASS] Ship reveal: Ted never names the passenger ship before BOARDING_THRESHOLD: No TED_* line mentions a ship or ship lights. The only ship mentions are JEFF_S3_10 and JEFF_S3_11, triggered by SHIP_SIGHTED, which is ordered after BOARDING_THRESHOLD (JEFF_S3_01/02) in step 3. Jeff, not Ted, delivers them.
- [PASS] No supernatural confirmation; Flighted poster and wall whispers stay ambiguous: DANIEL_OPT_05/06 ('Pipes... Say pipes'), DANIEL_OPT_07 ('Just the draught, in the stones'), DANIEL_OPT_08 ('Wind makes all sorts of voices'), DANIEL_OPT_02 ('Did the walls just... never mind') and DANIEL_OPT_04 ('Jeff says it's just weather') all keep a mundane reading open. JEFF_S3_12 and JEFF_S3_13 deflect the poster without explaining it. No cause is confirmed anywhere.
- [PASS] 'burner' not 'lamp head': 'burner' is used in TED_S1_10, TED_S1_11, TED_S3_01, TED_S3_02, JEFF_S3_04, JEFF_S3_05, JEFF_S3_I1, JEFF_S3_O1 to O3 and JRN_03. 'lamp head' appears nowhere. 'arc lamp' (TED_S1_09, TED_S1_10) is the fixture, which is allowed.
- [FAIL] Daniel stays in the basement; no Daniel lines elsewhere: DANIEL_OPT_01 to DANIEL_OPT_06 are tied to DANIEL_IN_BASEMENT, BASEMENT_TALK and BASEMENT_BANG, which are basement events. DANIEL_OPT_07 and DANIEL_OPT_08 trigger on WALL_WHISPER_HEARD, defined as a 'whisper in the lighthouse walls' (step 0, optional). That event is not restricted to the basement or to after DANIEL_IN_BASEMENT, so the trigger could play Daniel's voice in the lantern room or before he arrives. No gating is stated in the lines.
- [PASS] Line length: 22 words or fewer, with subtitles for every line: The longest lines are TED_S2_01 (18 words), TED_S1_09 (17), TED_S1_03 (16) and JEFF_S2_03 (15). All 76 lines have subtitle text. Voicing is left to the creator.
- [FAIL] No significant outpost detail: JEFF_S3_12 and JEFF_S3_13 (POSTER_EXAMINED) are tagged step 3, and JEFF_S3_12's delivery is 'calling from the landing'. That silently places the Flighted poster at the outpost, but POSTER_EXAMINED is a step 0 optional event with no location in the brief. JEFF_S3_O2 and JEFF_S3_O3 ('The burner's in there somewhere', 'Go inside the outpost') add an interior to the outpost that the brief does not establish. Jeff's other outpost lines (JEFF_S3_04, JEFF_S3_O1) are acceptable.
- [PASS] Alternate groups share a trigger and have at least two options: All 17 groups have two options on a shared trigger: TED_S1_OBJ (02, 03), TED_S1_COAL (05, 06), TED_S1_GAUGE (07, 08), TED_S2_OBJ (01, 02), JEFF_S2_GATE (01, 02), JEFF_S2_OPEN (03, 04), DANIEL_SHELTER (OPT_01, 02), DANIEL_TALK (OPT_03, 04), DANIEL_BANG (OPT_05, 06), DANIEL_WHISPER (OPT_07, 08), TED_S3_OBJ (01, 02), JEFF_S3_BOARD (01, 02), JEFF_S3_CAST (03, 03B), JEFF_S3_NEAR (06, 07), JEFF_S3_HIT (08, 09), JEFF_S3_SHIP (10, 11), JEFF_S3_POSTER (12, 13).
- [PASS] Open creator decisions not silently decided; scope respected: No line states or implies why Jeff and Daniel were on the water (JEFF_S2_01 and JEFF_S2_02 say only 'soaked' and 'cold and wet'). The 'drowned by now' pair JEFF_S2_05 and TED_S2_04 is flagged as a proposal in the notes of both lines. Nothing is written for RETURN_DEPARTED and there are no JEFF_RET_* lines. No fail-reason or outcome lines exist: OUTBOUND_COLLISION and OUTBOUND_NEAR_MISS have only recoverable Jeff reactions (JEFF_S3_06 to JEFF_S3_09).

## 5. Not verified
- Voice performance and lore approval (creator).
- The loader script has not been run in the Godot engine.

## 6. Licences and provenance
Text generated by the Opening Dialogue Crew from the GDD and Lore Build canon; no external assets.

## 7. Interface or contract changes proposed
New event IDs (see `events` in the JSON). The existing event RETURN_DEPARTED is the hand-off to JEFF_RET_*.

## 8. Open creator decisions
- Which lines are voiced is a cost decision for the creator. Subtitles exist for every line.
- Why Jeff and Daniel were on the water (smugglers?) is left open. No line states or implies a reason.
- Ted and Jeff's relationship is TBD in the lore. The 'drowned by now' exchange (JEFF_S2_05 and TED_S2_04) is only a proposal.
- Fail-reason and outcome lines belong to the Story / Fail-State agent, not this brief.
