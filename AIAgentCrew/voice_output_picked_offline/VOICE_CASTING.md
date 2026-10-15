# Voice Casting: opening dialogue

Status: **proposed** (mode offline, verdict PASS). Nothing has been sent to ElevenLabs. Approve each voice preview before generating lines.

## TED: gruff old lighthouse master
- male, older, rough British coastal, weathered; timbre gravelly, pace measured, energy medium
- Voice Design prompt: A gravelly older male voice in his late sixties with a rough coastal British accent, weathered by salt and tobacco. Gruff, dry and snarky, slow to warm up, with a rasp and an occasional cough. Speaks in short barking sentences.
- Contrast: Lowest and slowest of the three; gravel and rasp where Arthur is reedy and Daniel bright.
- Canon basis: chr_ted voice_casting_notes: gravelly older male, coastal accent; chr_ted verbal_habits: grunts, coughs
- Settings: {'stability': 0.5, 'similarity_boost': 0.8, 'style': 0.3, 'speed': 0.95, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 1300

## ARTHUR: wry frantic sea guide
- male, older, coastal British, sailor's cadence; timbre reedy, pace brisk, energy high
- Voice Design prompt: A wiry, old male voice, reedy and thin, with a coastal sailor's accent. Wry and warm underneath, quick and frantic under pressure, voice cracking when he shouts over wind and an engine.
- Contrast: Higher and faster than Ted, thin and reedy; older and more cracked than Daniel.
- Canon basis: chr_arthur voice_casting_notes: wiry, old, frantic; chr_arthur speech_pattern: snarky, funny
- Settings: {'stability': 0.35, 'similarity_boost': 0.8, 'style': 0.4, 'speed': 1.05, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 943

## DANIEL: anxious young sailor
- male, young adult, soft coastal British, youthful; timbre bright, pace quick, energy medium
- Voice Design prompt: A young male voice in his early twenties, bright and enthusiastic, soft coastal accent. Light-hearted and chatty, with nervous laughs and a voice that thins and speeds up when anxious.
- Contrast: The only young voice: bright and quick, where Ted and Arthur are older.
- Canon basis: chr_daniel voice_casting_notes: young, enthusiastic male; chr_daniel speech_pattern: light-hearted, anxious
- Settings: {'stability': 0.4, 'similarity_boost': 0.75, 'style': 0.35, 'speed': 1.05, 'use_speaker_boost': True} (design `eleven_ttv_v3`, TTS `eleven_v3`)
- Script characters: 301

## Suggestions for the creator
- Audition Ted first: his cough tags depend on v3 handling them well.
- Consider a light filter on lines shouted across the Gullwater (a Sound agent mix decision, not a voice change).

## Open creator decisions
- Which lines are voiced is a cost decision for the creator; character counts are in the report.
- Creator approves each voice preview before any line is generated.

## Review
Voice casting for 3 speakers and 39 lines. All deterministic checks pass. Nothing has been sent to ElevenLabs; the creator approves voices first.
- PASS: 1. The light must return: Ted's objective lines keep their meaning; only delivery tags were added.
- PASS: 2. The storm sets the clock: No timer or number wording in the 39 tts_text lines or previews.
- PASS: 3. Your hands, your eyes: Guidance stays spoken by Ted and Arthur; voices carry no markers.
- PASS: 4. Dread you can read: Daniel's whisper and bang lines gain only tone tags; no cause is named.
- PASS: Canon casting notes honoured: TED: chr_ted: 'gravelly older male, coastal accent'; ARTHUR: chr_arthur: 'wiry, old, frantic'; DANIEL: chr_daniel: 'young, enthusiastic male'
- PASS: No real-person likeness: All three descriptions describe sound only.
- PASS: Script text unchanged: All 39 tts_text lines equal the script once tags are stripped.
- PASS: Voices distinct: Timbre and pace differ for every pair of speakers.

## Guardrail log
- VOICE_CASTING_PLAN attempt 1: BLOCKED: TED: describe the sound only; no real people, actors or 'sounds like' comparisons. | TED_S1_01: tts_text must equal the script text once [tags] are removed (no rewriting).
- VOICE_CASTING_PLAN attempt 2: PASS
- VOICE_CASTING_REVIEW attempt 1: PASS