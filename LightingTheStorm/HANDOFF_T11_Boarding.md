# HANDOFF - T11: Arthur aboard, boarding, and the arrival beat

## 1. Task and goal

Seat Arthur on the engine boat as the only companion, fire BOARDING_THRESHOLD, add the ship-sighted beat, and give the return arrival its "go go go" beat on the lighthouse dock (Exec Summary steps 4-8; Technical Strategy invariants: Arthur is the only crossing companion). Serves R05 and R12. Builds on T30 (the capsules), T04 (Arthur in the hall) and T05 (the briefing).

## 2. Files changed

New: `scripts/world/boarding_sequence.gd` (the director; GameState creates it inside the level), `data/world/boarding_sequence.json`, `tools/test_boarding_sequence.gd` (22 checks).

Edited: `scripts/world/boat.gd` (`cast_off_hold`: a non-empty text blocks casting off and is shown in the prompt), `scripts/core/game_state.gd` (creates the director; `boarding()`), `data/dialogue/dialogue_opening.json` (`ARTHUR_S4_01`, the crossing crew's arrival line on RETURN_ARRIVED, before Ted's `TED_S4_01`), `tools/shot.gd` (`SHOT_BOARD=1`), `readme.md`.

Not touched: the boat's controls and physics, the dock zones, the crossing crew's data (T10).

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_boarding_sequence.gd
```

The beat: after `BURNER_BRIEFING`, 3 s later Arthur leaves his spot in the hall and walks the baked `hall_to_launch_berth` route (about 44 s) to the launch's berth and takes his seat beside and just ahead of the helm; until he is aboard the boat will not cast off (the prompt reads "[Q] Step onto the dock (Arthur is on his way)"). When the player comes within 7 m of the launch with Arthur aboard, `BOARDING_THRESHOLD` fires (Arthur: "In you get. One hand on the wheel, eyes on the rocks."). 8 s after `BOAT_CAST_OFF`, `SHIP_SIGHTED` fires (Arthur: "There! Ship's lights, out in the swell ..."). Arthur is a child of the boat's rig, so he pitches and rolls with it for the whole crossing (his "keep the engine turning" line at the Saltgate already exists). On `RETURN_ARRIVED` (the launch docks at the lighthouse) Arthur shouts "That's the jetty! Go, go, go - don't you wait for me!", 2 s later steps ashore and walks to the north jetty, where he stays.

## 4. Observed behaviour

`test_boarding_sequence.gd`: OK, 0 failed. The boat is free before the briefing and held after it; Arthur walks down in 44 s and sits aboard beside the helm (clear of the player's spot and the engine); the boat refuses to cast off before he is aboard and is free after; BOARDING_THRESHOLD fires when the player comes up to the launch, not before; the launch casts off with him aboard; SHIP_SIGHTED fires about 8 s after casting off; he rides the boat when it moves; on the return he shouts the line, steps ashore onto the jetty at (-26, 1.5, 14.7) and stays. The earlier game-state, intro, diagnosis, sailors, ship, outcome, subtitle, wave, disembark and boat tests still pass. A rendered still shows Arthur's capsule in the launch beside the wheel.

## 5. Not verified

- Not played end to end: the 3 s start, the 44 s walk and whether it is better to wait for the player to arrive.
- Arthur stands rather than sits, with no animation; the capsule may clip the hull's rail at the edge of its seat in rough water (not measured at sea state 5).
- If the player boards before Arthur arrives they wait at the helm ("Arthur is on his way"); the prompt is the only cue.
- On the return Arthur's arrival line is spoken from the boat as it docks; his jetty spot is a single point, so he does not walk back up to the hall.
- OUTBOUND_NEAR_MISS and the return calls (ARTHUR_RET_*) are still T10's.
- Ted's lines stay held while the player is on the boat (the Ted-only-inside rule).

## 6. Licences and provenance

None new.

## 7. Interface or contract changes proposed

PROPOSED: `boat.cast_off_hold`; `GameState.boarding()`; BOARDING_THRESHOLD and SHIP_SIGHTED are now emitted (no new IDs); `ARTHUR_S4_01` in the opening data.

## 8. Open creator decisions

- Should Arthur wait in the hall until the player is near the stairs, rather than leaving 3 s after the briefing and waiting at the boat?
- Should Arthur go back up to the hall after he steps ashore (the crossing is over; the story says he tells the player to go on without him)?
