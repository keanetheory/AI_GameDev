# Wave QA scenarios (waves on and off)

Automated: `Godot --headless --path LightingTheStorm --script res://tools/test_wave_crossings.gd` (curve, tables, switches, perfect-reflex sailing at each state).

| # | Scenario | Pass when |
|---|---|---|
| 1 | Outbound at its worst (state 2), perfect steering | max 10 m or less off line; no wave hit |
| 2 | Return at state 3, 4 and 5 | disturbance rises with state; still reaches the quay line |
| 3 | Outbound forced to state 5 | still no wave hit and no penalty |
| 4 | Return forced to state 5 | at least one wave hit: brief slow-down, water in the boat, no capsize |
| 5 | Waves off at state 5 | boat behaves like state 1: no push, calm look |
| 6 | Reduced preset (0.6) | push is 0.6 of normal; wave height 0.6 of normal |
| 7 | Dock at state 5 (both docks) | auto-docking completes; water near the dock is state 2 or lower |
| 8 | Reload mid-return | sea state restores with elapsed time (needs the deadline clock, GOA T07) |
| 9 | Speed 3, 8 and 10 m/s in boat_spec.json | push feel is the same (push is a fraction of speed); legs 170 s, 65 s, 51 s |
| 10 | Human playtest, both legs | creator signs off outbound feel (easy and simple) and return feel (hectic, fighting the sea, gusts, relief near the island) |

Not covered by automation: human reaction time. The test bot corrects every frame, so a human will be shoved further than the numbers.
