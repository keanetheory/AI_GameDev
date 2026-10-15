# Voice Casting: opening dialogue

Status: **proposed** (mode llm, verdict PASS). Nothing has been sent to ElevenLabs. Approve each voice preview before generating lines.

## TED: gruff lighthouse master
- male, older, weathered British coastal accent, rough and rural; timbre gravelly, low and dry, with a smoker's rasp and a wheezy edge, pace measured, energy medium
- Voice Design prompt: Gravelly older male, coastal accent. A weathered lighthouse keeper in his sixties or seventies with a low chest voice, deep rasp and a dry wheeze. Slow, clipped delivery that barks orders, grumbles under his breath and clears his throat or coughs mid-sentence. Sarcastic and impatient, with a faint buried warmth. Close and rough, projected to be heard over wind and stairwells.
- Contrast: Ted is the lowest, slowest and roughest voice, with a gravel rasp and coughs. Arthur is higher, thinner and faster, and Daniel is the brightest and youngest. Ted's flat low delivery is the easiest to tell apart in a storm.
- Canon basis: chr_ted voice casting note: 'gravelly older male, coastal accent'; Character brief: gruff, snarky, old-school; grunts and coughs; calls city folk 'new money toffs'; Ted introduces the setting and each objective
- Settings: {'stability': 0.5, 'similarity_boost': 0.75, 'style': 0.35, 'speed': 0.92, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 1300

## ARTHUR: wry, frantic old sailor
- male, elderly, lilting northern British sailor's accent, lighter than Ted's; timbre wiry, reedy and thin with a slight crack, mid-high pitch, pace quick, energy high
- Voice Design prompt: Wiry, old, frantic male voice. An elderly sailor with a thin, reedy, slightly cracked mid-high voice and a light northern sea-faring lilt. Fast and clipped, wry and friendly at rest, with a rising, breathless, rattled edge under pressure. He shouts over an engine, stays wary and keeps a warm joking undertone. Clearly higher and more nasal than a gravelly bass.
- Contrast: Arthur is thin, reedy, fast and rising in pitch, where Ted is low, slow and gravelly. Compared with Daniel he is older, more cracked and wry, and his panic is controlled and urgent rather than nervous and chattering.
- Canon basis: chr_arthur voice casting note: 'wiry, old, frantic'; Character brief: older sailor, wry and frantic under pressure, friendly but wary; Arthur guides the crossing
- Settings: {'stability': 0.35, 'similarity_boost': 0.75, 'style': 0.5, 'speed': 1.1, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 943

## DANIEL: anxious young sailor
- male, young adult, clean, youthful southern British accent; timbre bright, smooth and light, slightly high-pitched, with a nervous tremble, pace brisk, energy medium
- Voice Design prompt: Young, enthusiastic male. A man in his early twenties with a bright, smooth, light tenor and a clean youthful southern English accent. Chatty and eager, with forced cheer that wobbles into anxiety. He trails off mid-sentence, laughs nervously, loses his breath and drops to a hushed half-whisper when spooked. No rasp or grit, warm and boyish.
- Contrast: Daniel is the youngest, brightest and smoothest voice, with no rasp, and his anxiety shows as trailing, tremulous chatter and nervous laughs. Ted is a low gravelly bark and Arthur is an older, thinner, cracked rasp. Daniel's lines are heard only in the basement, which also separates him.
- Canon basis: chr_daniel voice casting note: 'young, enthusiastic male'; Character brief: younger sailor, light-hearted and anxious; Shelters in the basement and stays there
- Settings: {'stability': 0.4, 'similarity_boost': 0.75, 'style': 0.45, 'speed': 1.05, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 301

## Suggestions for the creator
- Audition each preview_text in Voice Design and pick the closest of the generated previews before locking voice IDs. Check that the three voices stay distinct with storm and engine noise mixed in.
- Ted's coughs and wheezes are tagged only where the delivery note asks for them. Consider recording the coughs and grunts as separate non-verbal one-shots to layer in, so the voice generation stays clean.
- Arthur's lines shouted over the engine may need the engine bed mixed lower in the boat sections so his lines stay intelligible.
- Daniel is only heard in the basement. Consider room reverb and a muffled, pipe-and-stone treatment in the mix rather than in the voice design.
- The nudge ladders (I1, I2, I3 and O1, O2, O3) are set to rise in stability: I1/O1 are dry and varied, I2/O2 are louder, and I3/O3 are flat and clear. Check that the explicit tier is easy to understand in testing.
- Tags are kept to at most two per line and placed only where the delivery note calls for them. If the model over-performs a tag, remove it and rely on the stability setting.

## Open creator decisions
- Which lines are voiced and which are subtitle-only is a cost decision for the creator. This plan prepares all 39 lines.
- Why Arthur and Daniel were on the water (smugglers?) is left open and nothing in the casting implies an answer.
- Ted and Arthur's relationship is TBD in the lore. The 'drowned by now' exchange (ARTHUR_S2_05 and TED_S2_04) is a proposal, and its warmth is a delivery choice the creator may change.
- Final accents (coastal, northern, southern) are casting suggestions built on the canon notes and can be shifted by the creator.
- Fail-reason and outcome lines belong to the Story / Fail-State agent and are not cast here.

## Review
The VoiceCastingPlan passes all four pillar checks and all decisions-log checks. It covers 39 lines for TED, ARTHUR and DANIEL, with profiles matching the three canon casting notes, no real-person references, and distinct voices by timbre, pace and age. Line wording matches the canon sample lines, with only bracketed delivery tags added, and no line has timer wording, supernatural confirmation, banned player address, a Ted mention of the ship, or new outpost detail. The open creator decisions are carried forward unchanged, and the script owner should confirm the ARTHUR_S0_13 ID prefix and the numbering gaps.
- PASS: Pillar 1: The light must return - everything leads back to the beacon: Every Ted objective line points back to the beacon: TED_S1_03 (boiler and starving beacon), TED_S1_10 and TED_S1_11 (burner cracked), and TED_S3_02 ('No burner, no beacon'). Arthur's ARTHUR_S3_04, ARTHUR_S3_05, ARTHUR_S3_I1 and ARTHUR_S3_O1 to O3 keep the burner as the goal. The casting plan adds no off-goal content.
- PASS: Pillar 2: The storm sets the clock - no timer, meter or enemy: Pressure comes from the world: ARTHUR_S3_11 (ship's lights in the swell), ARTHUR_S3_03 and ARTHUR_S3_07 (rocks), TED_S1_04 and TED_S1_05 (gauge/needle as in-world objects). No line contains countdown, timer or deadline wording. Arthur's urgency is delivery only (speed 1.1, stability 0.25 to 0.35), not scripted time pressure.
- PASS: Pillar 3: Your hands, your eyes - physical, first-person guidance from Ted and Arthur, no markers: Guidance comes only from Ted (TED_S1_I1 to I3, TED_S2_I1 to I3, TED_S2_03) and Arthur (ARTHUR_S3_01, ARTHUR_S3_I3, ARTHUR_S3_O3). Directions are physical ('Take the shovel', 'Walk to the island gate and open it', 'take the wheel'). No line refers to a marker or UI. Daniel gives no navigation.
- PASS: Pillar 4: Dread you can read - ambiguity, no jump scares, player always knows what to do: Daniel's unease (DANIEL_OPT_02, 04, 06, 08) uses hushed or nervous delivery tags ([nervous laugh], [breathless], [whispers]) and offers weather and pipes as explanations. No scare cues or stingers are specified. Each of the four idle events (S1, S2, S3 boarding, S3 burner search) has three tiers: hint (I1/O1), sharper (I2/O2), explicit (I3/O3). Arthur's lines in the crossing (ARTHUR_S3_03, 07, 08) name the hazard and the correction.
- PASS: Canon casting notes honoured: TED: 'gravelly older male, coastal accent' maps to the gravelly, weathered coastal profile, older male, rasp and coughs. ARTHUR: 'wiry, old, frantic' maps to wiry, reedy, elderly, quick, high energy. DANIEL: 'young, enthusiastic male' maps to young adult male, bright and chatty. The canon_basis entries for all three speakers cite the matching chr_* note.
- PASS: No real-person likeness: None of the three profiles (TED, ARTHUR, DANIEL) names an actor, public figure or sound-alike reference. Voices are built from descriptive Voice Design prompts (eleven_ttv_v3 design, eleven_v3 TTS) only.
- PASS: Script text unchanged: The spoken text of every line matches the canon sample lines shown in the preview_texts, for example TED_S1_01, TED_S1_08, TED_S1_11, ARTHUR_S2_02, ARTHUR_S2_05, ARTHUR_S3_11 and DANIEL_OPT_02, 04, 06, 08. The only additions are bracketed delivery tags, at most two per line, plus the stability value. No wording was rewritten. The full script was not in the supplied context, so non-sample lines could not be diffed word for word (see issues).
- PASS: No timer wording: No line across the 39 uses a countdown, a number, a clock term or deadline talk. 'Quick, now' (ARTHUR_S2_04) and 'Go!' (ARTHUR_S3_I3) are urgency of delivery, not deadlines. 'Thought you'd be drowned by now' (ARTHUR_S2_05) is banter, not a deadline.
- PASS: No supernatural confirmation: DANIEL_OPT_02 ('Did the walls just... never mind'), DANIEL_OPT_06 ('Pipes, right? Say pipes.') and DANIEL_OPT_08 ('Wind makes all sorts of voices') stay ambiguous. DANIEL_OPT_04 has Arthur dismissing it as 'just weather'. No Ted or Arthur line confirms a cause. The plan keeps the ambiguity in delivery tags only.
- PASS: Voices distinct: TED is low, gravelly, measured, speed 0.92, stability 0.5. ARTHUR is thin, reedy, quick, speed 1.1, stability 0.35. DANIEL is bright, smooth, young, speed 1.05, stability 0.4. Each profile has a contrast_note, and Daniel's lines are basement-only, which separates him further.
- PASS: Dialogue rules: Isaac only, Ted's objectives, no ship name by Ted, 'burner': 'apprentice', 'lad', 'lass', 'man' and 'lamp head' appear in no line. The player is addressed only as 'Isaac' (e.g. TED_S1_03, ARTHUR_S3_03). Ted introduces the three steps in TED_S1_03 (coal), TED_S2_01 (gate) and TED_S3_02 (outpost). No Ted line names the passenger ship; only ARTHUR_S3_11 mentions 'Ship's lights'. 'The boy' in TED_S2_04 refers to Daniel.
- PASS: Nudge ladders and alternates: Ladders are complete and consecutive: TED_S1_I1 to I3, TED_S2_I1 to I3, ARTHUR_S3_I1 to I3 and ARTHUR_S3_O1 to O3. The DANIEL_OPT group has four options (02, 04, 06, 08), which is above the minimum of two. Group and trigger assignment sits in the script, not the casting plan.
- PASS: Daniel stays in basement; no significant outpost detail: Daniel's lines (DANIEL_OPT_02, 04, 06, 08) are all set 'down here' in the basement, and the plan states his lines are heard only there. Outpost content is limited to the landing and the burner (ARTHUR_S3_04, ARTHUR_S3_05) and ARTHUR_S0_13 ('Nothing there for us.'). No new outpost detail is introduced.
- PASS: Open creator decisions not decided; scope respected: The plan prepares all 39 lines and leaves the voiced versus subtitle-only choice to the creator. Nothing implies why Arthur and Daniel were on the water. The ARTHUR_S2_05 and TED_S2_04 exchange is labelled a proposal. Fail-reason and outcome lines are not cast. The line count of 39 matches the lines array.

## Guardrail log
- VOICE_CASTING_PLAN attempt 1: PASS
- VOICE_CASTING_REVIEW attempt 1: PASS