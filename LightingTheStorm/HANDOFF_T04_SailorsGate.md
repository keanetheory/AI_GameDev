# HANDOFF - T04: window moment, moored rowboat, island gate and the sailors' scripted walk-in

## 1. Task and goal

The shelter-and-gate beat (Exec Summary step 2, Technical Strategy "shelter and gate", Decisions A7): after the boiler is fed Arthur and Daniel row in and moor at the island dock; Ted sends the player to open the island gate; once it is open the sailors walk up to the lighthouse, Arthur into the hall and Daniel down to the basement, where he stays. Serves R03; builds on T30 (the capsule sailors and their routes) and the existing island gate; unblocks T05 (the diagnosis needs `DANIEL_IN_BASEMENT`).

## 2. Files changed

New:
- `scripts/world/sailors_sequence.gd`: the director. GameState creates it inside the level (like the ship deadline and the audio), so `Level.tscn` holds none of it. Reports SAILORS_MOORED, WINDOW_LOOKED, SAILORS_INSIDE and DANIEL_IN_BASEMENT; the gate itself reports GATE_APPROACHED and GATE_OPENED.
- `scripts/world/rowboat.gd`: the rowboat (the FAL model, rowed in along a path, then bobbing at its berth; a visual only).
- `data/world/sailors_sequence.json`: every delay, the rowboat's path and seats, where the sailors wait, the window spot, the idle nudges.
- `tools/test_sailors_sequence.gd` (35 checks); `tools/probe_rowboat.gd`.

Edited: `scripts/core/game_state.gd` (creates the director; `sailors()` accessor), `tools/shot.gd` (`SHOT_ROWBOAT=1`), `readme.md`.

Not touched: `Level.tscn`, the gate script, the interior, the dialogue data (the lines for these events were already in it).

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_sailors_sequence.gd
```

The beat, with the current timings: `BOILER_FED`, then 5 s, the rowboat comes in at the harbour mouth (84 m out) and rows to the south berth at 1.9 m/s (about 30 s); `SAILORS_MOORED` fires when it berths (Ted: "Rowboat's moored at my dock ... open the island gate"); 2 s later the sailors step ashore and walk up the stairs, Arthur stopping 2.4 m below the gate and Daniel 3.8 m, facing it; `WINDOW_LOOKED` fires when the player stands at the tower landing window looking out at the harbour mouth, or 10 s after mooring, whichever comes first (Ted: "See them?"); the player comes up (the gate reports `GATE_APPROACHED` at 6 m) and opens it (`GATE_OPENED`; Arthur: "Good hands on that gate"); 0.8 s later Arthur walks on through the gate to the hall (`SAILORS_INSIDE`, about 16 s), Daniel 3.5 s behind him, on down the spiral to the basement (`DANIEL_IN_BASEMENT`, which moves the phase on to BEACON_DIAGNOSIS). If the gate stays shut, `IDLE_STEP_2` is called after 40 s and every 25 s, up to three tiers (Ted's hint, sharper, explicit lines).

## 4. Observed behaviour

`test_sailors_sequence.gd`: OK, 0 failed. No rowboat before the boiler is fed; it comes in a few seconds after, with Arthur and Daniel aboard; SAILORS_MOORED fires at 34 s; the rowboat sits at the south berth beside the south jetty, clear of the launch's berth; both sailors wait below the shut gate and do not pass it; the fallback fires WINDOW_LOOKED, and so does the look (player at the tower landing window facing out); the idle ladder is called; GATE_APPROACHED and GATE_OPENED fire; Arthur reaches the hall, Daniel the basement (y 7.6) and stays 30 s later; the events came in the story's order and each fired once. The rowboat's path is clear of the harbour, the jetties and the rocks along its whole length (a 2.2 x 4.4 m box, every metre), and the tower landing window sees the rowboat on all 15 sampled points of its row in. Earlier ship, audio, outcome, game-state, gate, subtitle, lamp-fit and sightline tests still pass. A rendered still shows the rowboat moored beside the teal launch with the sailors aboard.

## 5. Not verified

- Not played: the whole beat has only run stepped by hand. The 5 s start, the 34 s row-in and whether Ted's lines land well with it need a play (the dialogue loader's own pauses run on real time).
- The berth is hidden from every window (the plateau is in the way), so the window moment is the rowboat arriving outside the harbour mouth, seen only if the player happens to be at the tower landing window then; otherwise the 10 s fallback fires Ted's "See them?" line anyway.
- The sailors stand rather than sit in the rowboat, and step ashore by walking up the 1 m height difference in a straight line; they have no animation.
- Arthur stays in the hall after arriving. His next move (to the launch, for boarding) is T11, with the baked `hall_to_launch_berth` route.
- If the player closes the gate again while the sailors are on their way through, nothing stops them (they have no collision).
- A restart reloads the level, so the beat starts again from the boiler.

## 6. Licences and provenance

None new (the rowboat is the FAL model from T30; the capsules are made in code).

## 7. Interface or contract changes proposed

PROPOSED: `GameState.sailors()`; the director emits the four story events (no new IDs). The window moment is as described above (tower landing window, with fallback).

## 8. Open creator decisions

- The window moment: the berth is hidden from every window, so should Ted's "See them?" stay a fallback line, or should the rowboat's row-in be made visible from the ground-floor window (closed on 27 Oct) or L1?
- Arthur's idle behaviour in the hall (waiting, or following the player) until T11.
