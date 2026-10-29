# Ted's lamp-room and fail lines: proposals for the creator to pick (T16, T37) and the T18 review

**Status:** proposed, 29 Oct 2026. Nothing here is in `dialogue_opening.json` or the voice plan. Every line passes the deterministic rules (`python AIAgentCrew/check_proposed_lines.py`): 22 words or fewer, no numbers or timer words, "burner" not "lamp head", no supernatural cause, ship named only after boarding. They have not been through a live Dialogue agent or Canon re-review, and the creator approves voice and lore. Machine-readable copy: `AIAgentCrew/proposed_ted_lines.json`.

## Creator picks (29 Oct 2026)

`TED_S4_01` (RETURN_ARRIVED), `TED_S4_03` (LAMP_ROOM_REENTERED, new event), `TED_S4_06` (BURNER_FITTED), `TED_S5_02` (SHIP_WIN), `TED_F_01` (SHIP_FAIL crash line). Added to `LightingTheStorm/data/dialogue/dialogue_opening.json` as steps 4 and 5 (45 lines). `TED_F_03` reworded by the creator and added (46 lines). **Open:** `LAMP_ROOM_REENTERED` still needs T26 acceptance; nothing recorded yet (no credits spent).

## T16: the lamp-room list to voice

Already in the data and kept: the diagnosis lines `TED_S3_00`, `TED_S1_10`, `TED_S1_11`, `TED_S3_02`. Arthur's "Go, go, go" on arrival already exists (`arrival_line` in `return_crossing.json`). Missing, so proposed (pick one per group):

| Trigger | ID | Line | Delivery |
|---|---|---|---|
| `RETURN_ARRIVED` | `TED_S4_01` | "Up here, Isaac! Bring the burner. Mind the stairs, and don't you dare drop it!" | Shouted down the stairwell, hoarse, urgent |
| `RETURN_ARRIVED` | `TED_S4_02` | "Burner in hand? Then climb! The lamp room, Isaac. She won't light herself." | Shouted down the stairwell, gruff, coughing |
| `LAMP_ROOM_REENTERED` (**new event**) | `TED_S4_03` | "Socket's open. Burner in, and be quick about it. Slowly, mind. She's old." | Tense, close at hand |
| `LAMP_ROOM_REENTERED` (**new event**) | `TED_S4_04` | "Well, don't just stand there gawping. The burner goes in the socket. Go on." | Impatient, softer on "Go on" |
| `BURNER_FITTED` | `TED_S4_05` | "Seated. Come on, old girl. Come on. Let's see if she catches." | Low, held breath |
| `BURNER_FITTED` | `TED_S4_06` | "That's the burner home. Stand back, Isaac. Give her room to wake." | Gruff, hushed |
| `SHIP_WIN` | `TED_S5_01` | "There's the light, and she's turning clear of the rocks. Hrmph. Not bad, Isaac. Not bad." | Gruff, a cough over real relief |
| `SHIP_WIN` | `TED_S5_02` | "She sees us! Look at her go, clear of the rocks. You did it, you money toff." | Cracked, half-laughing |

`LAMP_ROOM_REENTERED` is not in the approved event list (T26). Either accept it, or fold the waiting line into `RETURN_ARRIVED` by choosing only one of `TED_S4_01/02` and dropping the waiting group.

## T37: Ted at SHIP_FAIL

The crash happens in the world and the game does not wait (A30), so keep each line short enough to land in a few seconds. Proposed order: one crash line as the ship strikes, then the fixed reason line, then silence and the Failed screen.

| Order | ID | Line | Delivery |
|---|---|---|---|
| 1 (pick one) | `TED_F_01` | "No. No, turn! Turn, you fool, the rocks! Oh, no." | Shouted, then a breaking whisper |
| 1 (pick one) | `TED_F_02` | "She's too close. She's too close! Turn, damn you. Turn!" | Rising, desperate, voice cracking |
| 2 (fixed) | `TED_F_03` | "That ship...we didn't get the burner out in time...those poor souls on board...we've failed...FAILED!!" | Sorrowful, upset (creator wording, 29 Oct) |

Notes: `TED_F_02` uses "damn", which is stronger than Ted's lore (he says "what the hell"); drop it if you want him cleaner. The reason line is the creator's fixed wording from 19 Oct (`canon.py` `FAIL_REASON_LINE`). Wiring waits on T07 firing `SHIP_FAIL`.

**Isaac count:** 4 of the 11 proposed lines use the player's name; canon aims for about one in five. Picking one line per group and preferring the ones without "Isaac" (`TED_S4_03`, `TED_S4_04`, `TED_S4_05`, `TED_F_01`, `TED_F_02`, `TED_S5_02`) brings it back in range.

## T18: review of the rewritten opening lines

The seven lines (`TED_S1_01`, `S1_09`, `S1_10`, `S1_11`, `S3_02`, `ARTHUR_S3_04`, `TED_S3_00`) all pass the deterministic rules. Read-through against the story beats:

- **Order and story flow:** door greeting, coal, dynamo, then the sailors (the old `TED_S1_09` promised "we'll see if the old girl lights" at BOILER_FED, which now reads as a tease that the sailors interrupt; `TED_S3_00` then picks it up with "Dynamo's running and still no light"). Consistent.
- **Saltgate, not "outpost":** the new text says Saltgate everywhere. The recorded audio still says "outpost" and "landing".
- **Judgement calls for you:** `TED_S1_01` ends on a bare "In." (reads curt, matches the cough direction); `TED_S1_10` and `S1_11` are fine, and `S1_11` now sends the player to `S3_02`'s spare burner.

**Audio that no longer matches the text: eight lines, not six.** The recorded set (`voice_output_picked_live/elevenlabs`) differs from the current text for `TED_S1_01`, `TED_S1_09`, `TED_S1_10`, `TED_S1_11`, `TED_S3_02`, `ARTHUR_S3_04`, **and `ARTHUR_S3_I2` and `ARTHUR_S3_I3`** (both still say "outpost"). `TED_S3_00` has no audio at all. Add the picked T16/T37 lines and the reason line to the same regeneration. Dry run first; `--send` spends ElevenLabs credits.

## Ted names the ship (BURNER_DIAGNOSED, moved 29 Oct from BOARDING_THRESHOLD) (drafted 29 Oct 2026; creator picked `TED_S3_05`, added to the game data, 47 lines)

The GDD (Exec Summary step 4) says Ted names the passenger ship at the boarding threshold, but the only line on that event is Arthur's `ARTHUR_S3_01`. Arthur's own ship line is on `SHIP_SIGHTED`. Pick one, or neither (then change the GDD so Arthur introduces the ship):

| ID | Line | Delivery |
|---|---|---|
| `TED_S3_05` | "A passenger ship? Now? It's not in the log! Without the beacon she'll find the rocks. Go, Isaac!" | Shocked, then barking |
| `TED_S3_06` | "That's a passenger ship out there, and she's heading for my rocks. No beacon, no hope. Go!" | Grim, urgent, coughing |

`TED_S3_05` echoes the lore sample line ("A passenger ship? NOW?... It's not in the log!"). Either plays before Arthur's "In you get". Added to `dialogue_opening.json` before `ARTHUR_S3_01`.

**Moved 29 Oct 2026 (creator):** `TED_S3_05` now plays on `BURNER_DIAGNOSED`, straight after `TED_S1_11` ("The burner's finished"), in the lamp room with the ship in view (Decisions A34). `canon.py` `SHIP_NAMED_FROM` is now `BURNER_DIAGNOSED`.
