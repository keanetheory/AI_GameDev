# HANDOFF - T05: the lamp-room diagnosis and the briefing

## 1. Task and goal

The beacon diagnosis (Exec Summary step 3, Technical Strategy BEACON_DIAGNOSIS): only after the sailors are in, Ted takes the player to the lamp room, finds the burner broken and names the ship; then the player is briefed and sent to the Saltgate. Built to the creator's order of 29 Oct 2026: coal, up to the lamp room where Ted waits, "the burner is busted", then the unplanned ship. Serves R04; builds on T04 (the sailors), T28 (the lamp and the broken burner prop) and T33 (the coal job). The same lamp-room trigger now also fires `LAMP_ROOM_REENTERED` (accepted in Decisions A17, A33).

## 2. Files changed

New:
- `scripts/world/diagnosis_sequence.gd`: the director (GameState creates it inside the level, like the others). Reports BEACON_STILL_DARK, LAMP_ROOM_ENTERED, BURNER_DIAGNOSED, BURNER_BRIEFING, LAMP_ROOM_REENTERED and nudges IDLE_STEP_3.
- `scripts/character/ted.gd`: Ted in the level (the rigged ted.glb in a frozen pose: the first frame of his `Alert_Quick_Turn_Right` clip, because he has no idle clip).
- `data/world/diagnosis_sequence.json`: every delay, Ted's spot, the lamp-room and hall zones, the idle nudges.
- `tools/test_diagnosis_sequence.gd` (26 checks); `tools/probe_ted.gd`, `tools/probe_ted_spot.gd`.

Edited: `scripts/core/game_state.gd` (creates the director; `diagnosis()`), `tools/shot.gd` (`SHOT_TED=<clip>:<time>`), `readme.md`.

Not touched: `Level.tscn`, `lantern.gd` (the cracked burner is hidden and revealed at run time), the lamp socket, the dialogue data (the lines for these events were already in it).

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_diagnosis_sequence.gd
```

The beat, with the current timings: once Arthur is in the hall (`SAILORS_INSIDE`) and Daniel is in the basement (`DANIEL_IN_BASEMENT`), 8 s later `BEACON_STILL_DARK` fires (Ted: "Dynamo's running and still no light ... Lantern room, Isaac. With me.") and Ted appears in the lamp room beside the arc lamp, off the player's route to the burner seat, next to where the burner will lie. When the player reaches the lamp room (within 3.3 m of the lamp axis, above y 27; the stairs below do not count) `LAMP_ROOM_ENTERED` fires (Ted: "Arc lamp's in the middle. Let's open her up ..."); 5 s later `BURNER_DIAGNOSED` fires and the cracked burner appears on the floor (Ted: "Cracked clean through. The burner's finished...", then he names the ship, which is in view out of the lamp-room windows). When the player is back in the hall near Arthur `BURNER_BRIEFING` fires (Ted: "No burner, no beacon. There's a spare at the Saltgate ... Go with Arthur, Isaac."; the phase moves to BOARDING). If the player then dawdles, `IDLE_STEP_3` nudges after 60 s and every 30 s up to three tiers (Arthur's ladder), until `BOAT_CAST_OFF`. Later, entering the lamp room carrying the replacement burner (after `BURNER_PICKED_UP`) fires `LAMP_ROOM_REENTERED` (Ted: "Socket's open. Burner in ...").

## 4. Observed behaviour

`test_diagnosis_sequence.gd`: OK, 0 failed. Walking into the lamp room early fires nothing; Arthur in the hall alone is not enough; Ted shouts about 8 s after both sailors are in and appears at (8.5, 27.5, -6.8), facing the lamp, on a spot clear of the lamp, rails and glass; the spiral stairs below do not trigger the lamp room; the lamp-room entry, the diagnosis (the cracked burner becomes visible only then), the briefing (phase to BOARDING), the idle ladder (three tiers) and `LAMP_ROOM_REENTERED` (not when empty-handed) all fire once and in order. The earlier game-state, sailors, NPC, lamp-fit, ship, audio, outcome, subtitle and interior-walk tests still pass. A rendered still shows Ted in his coat beside the arc lamp and the cracked burner on the floor.

## 5. Not verified

- Not played. Whether 8 s, 5 s and the dialogue pauses feel right, and whether Ted's lines land in order (the loader's pauses run on real time).
- Ted is frozen in one pose; he has no walking to the lamp room, no lip-sync, and no voice audio (subtitles only).
- The arc lamp is not animated open: its socket is simply empty and the burner appears on the floor. An opening animation needs art.
- `BURNER_BRIEFING` fires on the player's return to the hall; Ted says it from the lamp room (voice only), though the line's staging note says "Ted in the lighthouse hall".
- The briefing and the idle nudges are timed from the player's position only, not from whether Ted has finished speaking.
- The 2 m inside-the-door spot of Arthur and the hall zone (3.2 m) were set from the baked route.

## 6. Licences and provenance

None new (Ted, the burner and the lamp are existing project assets).

## 7. Interface or contract changes proposed

PROPOSED: `GameState.diagnosis()`; the director emits the five lamp-room and briefing events (no new IDs); `BURNER_DIAGNOSED` reveals the cracked burner.

## 8. Open creator decisions

- Should Ted come down to the hall for the briefing (a walking Ted, which needs an animation set), or stay in the lamp room and brief the player by voice as built?
- Should the arc lamp visibly open (an art task), or is the empty socket and the burner on the floor enough?
