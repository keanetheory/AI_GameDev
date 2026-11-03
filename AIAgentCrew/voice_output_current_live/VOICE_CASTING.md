# Voice Casting: opening dialogue

Status: **needs_revision** (mode llm, verdict REVISE). Nothing has been sent to ElevenLabs. Approve each voice preview before generating lines.

## TED: gruff lighthouse master
- male, older, weathered north-east English coastal, broad flat vowels; timbre gravelly, low and dry, with a smoker's rasp and a habit of coughing, pace measured, energy low
- Voice Design prompt: A gravelly older male, coastal accent: a weathered, low-pitched voice with a dry rasp, like salt and gravel in the throat. Slow, deliberate and sardonic, with a flat deadpan delivery and long grumbling pauses. Occasional grunts, wheezes and coughs. Volume rises to a hoarse bark when he shouts, but the pitch stays deep and the voice never gets light or bright. Close-mic, indoor warmth.
- Contrast: Lowest, slowest and most gravelly of the three, with dry deadpan delivery and coughs. Arthur is higher, reedier and faster. Daniel is young, light and bright. Even shouted, Ted stays deep and hoarse, so he reads as the heavy voice in a storm.
- Canon basis: chr_ted voice_casting_notes: 'gravelly older male, coastal accent'; Voices: gruff, snarky, old-school; grunts and coughs; introduces the setting and each objective
- Settings: {'stability': 0.5, 'similarity_boost': 0.75, 'style': 0.35, 'speed': 0.92, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 3430

## ARTHUR: wry frantic old sailor
- male, older, soft West Country sea-lilt, lighter and more musical than Ted; timbre wiry, reedy, slightly nasal and thin, mid-to-high pitch with a cracking edge when shouting, pace quick, energy high
- Voice Design prompt: A wiry, old, frantic male voice with a soft West Country sea-lilt. Thin, reedy and slightly nasal, in a mid-to-high register with a rough crack when he strains. Quick and clipped, wry and friendly with a wary edge. Under pressure he turns breathless and shouts hoarsely over an engine, with fast rhythm and rising pitch. Calm moments are dry, steady and a little weary.
- Contrast: Higher, thinner and faster than Ted's low rasp, with a lilting accent and a cracking, urgent edge. He is clearly older and more nasal than Daniel, who is smooth and youthful. His shouted lines are rough and reedy, never deep like Ted's.
- Canon basis: chr_arthur voice_casting_notes: 'wiry, old, frantic'; Voices: older sailor, wry and frantic under pressure, friendly but wary; guides the crossing
- Settings: {'stability': 0.35, 'similarity_boost': 0.75, 'style': 0.5, 'speed': 1.08, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 2519

## DANIEL: anxious young sailor
- male, young adult, light, modern southern English, no strong regional marker; timbre bright, smooth and boyish, light in the chest, with a slightly breathy, wavering quality when nervous, pace brisk, energy medium
- Voice Design prompt: A young, enthusiastic male voice, early twenties, with a light southern English accent. Bright, smooth and boyish with a slightly breathy quality. Light-hearted chatter that wobbles into anxiety: trailing off mid-sentence, nervous laughs, forced cheer, and whispering when spooked. Fairly quick and bouncy, with no rasp or grit. Higher and softer than the older men.
- Contrast: The only young, smooth, bright voice, with no rasp, so he stands apart from both Ted's deep gravel and Arthur's thin old reediness. His nervous laughs, trailing sentences and whispers carry his anxiety. He stays in the basement, so he never competes with Arthur's storm shouting.
- Canon basis: chr_daniel voice_casting_notes: 'young, enthusiastic male'; Voices: younger sailor, light-hearted and anxious; shelters in the basement and stays there
- Settings: {'stability': 0.35, 'similarity_boost': 0.75, 'style': 0.45, 'speed': 1.1, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 336

## Suggestions for the creator
- Audition each preview_text in Voice Design and generate 3 candidates per speaker. Pick the set where Ted is the lowest and slowest, Arthur the thinnest and fastest, and Daniel the brightest.
- Check Ted and Arthur at storm volume with engine and rain mixed in. If their shouts blur together, push Arthur's pitch higher and thinner rather than louder.
- Ted's muffled 'through the floor' lines (TED_S1_04, S1_04b, S1_05, S1_05b, S1_08) are best handled with in-engine low-pass and reverb on one clean take, not a separate voice.
- The nudge ladders (S1_I1-I6, S2_I1-I4, ARTHUR_S3_I1-I3 and O1-O3) rise in stability as they get more explicit: wry or dry first, flat and clear last.
- The three coastfolk voices are separated by pitch, texture and pace. The accents are deliberately light so they do not imply backstory about where the men are from.
- Keep the delivery of TED_F_03 raw and breaking: it carries a single opening [sighs] tag so the script text stays exact, and the grief breaking into anguish on 'FAILED!!' can come from the capitals and low stability. Consider one take at lower stability and one safer take, and let the Story / Fail-State agent choose.

## Open creator decisions
- Which lines are voiced and which are subtitle-only is a cost decision for the creator; every line here is prepared for ElevenLabs regardless.
- Why Arthur and Daniel were on the water is left open, so no voice note implies smugglers or any backstory.
- Ted and Arthur's relationship is still TBD in the lore. The 'drowned by now' exchange is a proposal, and the voices are cast as warm underneath without defining the history.
- Final accents (north-east coastal for Ted, soft West Country lilt for Arthur, light southern for Daniel) are a casting proposal for the creator to accept or change.
- Whether the supernatural ambiguity (wall whispers, singing pipes) gets any special audio treatment is left to the creator; no voice here confirms a cause.

## Review
Verdict REVISE: all four pillar checks pass, but the timer-wording check fails because ARTHUR_DOCK_L2 says 'seven apologies'. Casting notes, no real-person likeness, no supernatural confirmation and distinct voices all pass, and script-text fidelity is conditional because the script itself was not supplied. Non-blocking items are the 'new boy' wording in TED_S1_10, the S1 prefixes on the lantern-room burner lines, the unspecified trigger for TED_S0_13, and gaps in line IDs. All open creator decisions are carried forward unchanged.
- PASS: Pillar 1 - The light must return: Ted's lines keep pointing at the beacon: TED_S3_00 ('Dynamo's running and still no light'), TED_S1_11 ('We need a new one'), TED_S3_02 ('No burner, no beacon'), TED_S4_01 and TED_S4_03 (bring the burner up, fit it) and TED_S4_06 ('That's the burner home'). Arthur's ARTHUR_S3_04, S3_05, S3_I1 and S3_O1-O3 keep the burner as the goal. TED_S5_02 pays off the relit beacon ('She sees us!').
- PASS: Pillar 2 - The storm sets the clock: Pressure comes from the world: ship lights in ARTHUR_S3_11, rocks in ARTHUR_S3_03, S3_07, S3_08 and ARTHUR_RET_01-05, and the ship named in TED_S3_05. No line shows a timer, meter or enemy. The one spelled-out number ('seven' in ARTHUR_DOCK_L2) is not a clock, but it breaks the number rule and is logged under the timer-wording check.
- PASS: Pillar 3 - Your hands, your eyes: Guidance comes only from Ted and Arthur by voice, with no markers. Ted gives the objectives (TED_S1_03, S2_01, S3_02). Arthur gives the physical steering and fetching cues (ARTHUR_S3_01 'One hand on the wheel', ARTHUR_RET_02 'Left! Your left!', ARTHUR_S3_O3 'pick it up, and bring it to the boat'). Daniel never gives directions.
- PASS: Pillar 4 - Dread you can read: Hazard calls are plain and actionable: ARTHUR_RET_01-05, ARTHUR_NEAR_3 ('Steer away') and ARTHUR_HIT_2 ('Swing wide and steady her'). The nudge ladders go from hint to explicit: TED_S1_I1-I6, TED_S2_I1-I4, ARTHUR_S3_I1-I3 and ARTHUR_S3_O1-O3 (16 lines, consecutive tiers). Daniel's whispers (DANIEL_OPT_04, OPT_06, OPT_08) build unease without a scare. TED_F_03 is the fixed fail reason line.
- PASS: Canon casting notes honoured: TED is a gravelly older male with a coastal accent, matching chr_ted. ARTHUR is wiry, old and frantic, matching chr_arthur. DANIEL is a young, enthusiastic male, matching chr_daniel. Each profile's canon_basis cites its note. The accent regions (north-east for Ted, West Country for Arthur, southern for Daniel) go beyond the canon notes, and the plan flags them as proposals.
- PASS: No real-person likeness: No profile (TED, ARTHUR, DANIEL) names an actor, celebrity or 'sounds like' reference. Voice descriptions use only generic timbre, age and accent terms.
- PASS: Script text unchanged: The script itself was not supplied, so I could not diff against it. In every tts_text, the only additions I found are bracketed audio tags such as [coughs], [shouts] and [nervous laugh]. Each preview_text matches its line text (TED_S1_01, TED_S1_11, ARTHUR_RET_02, DANIEL_OPT_02/04/06/08). TED_F_03 carries one opening [sighs] and keeps the fixed wording. This is conditional on the Script agent confirming wording.
- FAIL: No timer wording: ARTHUR_DOCK_L2 says 'I counted seven apologies owed to the rocks', a spelled-out number, and the rule is 'No timers, countdowns, numbers or deadline talk'. Lower-risk time and quantity words: ARTHUR_S3_07 ('Plenty of time to hug them later'), TED_S2_I1 ('For an hour'), TED_S4_01 ('only half over'), ARTHUR_S3_O1 ('Twice'). TED_F_03 contains 'in time', but it is the fixed fail reason line and exempt.
- PASS: No supernatural confirmation: No line names a cause for the singing or the walls. TED_S1_04b ('that's the pipes') and DANIEL_OPT_06/08/04 ('Pipes, right?', 'Wind makes all sorts of voices', 'just weather') stay deniable. ARTHUR_NEAR_2 ('One of them winked at me!') and ARTHUR_RET_04 ('They bite!') are jokes, not claims. Watch ARTHUR_NEAR_2 for tone.
- PASS: Voices distinct: Ted is deep, slow and rasping (speed 0.92, energy low). Arthur is thin, reedy and quick, with an older West Country lilt (1.08, high). Daniel is bright and boyish (1.1, medium). Their timbres and ages differ. Arthur and Daniel's settings are close (stability 0.35 for both, speed 1.08 vs 1.1), so they rest on the Voice Design prompts. The suggestion calling Arthur 'fastest' conflicts with Daniel's higher speed.
- PASS: Dialogue rules (Isaac, Saltgate, burner, Daniel in basement, ship naming): Daniel's lines (DANIEL_OPT_02/04/06/08) and TED_S2_04b stay in the basement. No 'lad', 'lass', 'man', 'apprentice', 'outpost' or 'lamp head' appears. The destination is the Saltgate (TED_S3_02, ARTHUR_S3_04, ARTHUR_S3_I2/I3). Ted first names the ship in TED_S3_05, after the burner diagnosis in TED_S1_11. No added Saltgate detail.
- PASS: Open creator decisions not decided: The plan prepares every line for ElevenLabs without choosing voiced vs subtitle-only. It implies no smuggler backstory for Arthur and Daniel. The 'drowned by now' exchange (ARTHUR_S2_05, TED_S2_04) is not given a defined history. The note that the voices are cast 'warm underneath' is a mild steer on the Ted/Arthur relationship and should be watched.

## Guardrail log
- VOICE_CASTING_PLAN attempt 1: BLOCKED: TED_F_03: tts_text must equal the script text once [tags] are removed (no rewriting).
- VOICE_CASTING_PLAN attempt 2: PASS
- VOICE_CASTING_REVIEW attempt 1: PASS