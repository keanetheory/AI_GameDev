# HANDOFF - T30: capsule Arthur and Daniel and a path-follower script

## 1. Task and goal

Arthur and Daniel are capsules for the prototype (creator, 19 October 2026). One NPC script that walks a path, waits, follows the player, or sits at a seat on the boat. The FAL rowboat was already done (T30 earlier part). Serves R03, R05 and R12; unblocks T04 (the window moment, gate and walk-in), T05 and T11 (Arthur aboard).

## 2. Files changed

New:
- `scripts/character/npc.gd`: the capsule character (Arthur: tall, teal-grey coat; Daniel: shorter, yellow oilskin; a dark nose marks the front, forward is -Z). `Npc.spawn(parent, "ARTHUR", at)`, then `walk(points, route_name)`, `wait(seconds)`, `follow(target, gap)`, `sit(seat, offset)`, `release_seat()`, `stop()`. Signals `arrived(route_name)`, `reached_waypoint(i)`, `released`.
- `scripts/character/npc_routes.gd`: reads the baked routes (`Routes.route("sailors_dock_to_hall")`).
- `data/world/npc_paths.json`: the baked routes (world positions with floor heights, about 0.1 m apart outdoors and 0.25 m indoors).
- `tools/bake_npc_paths.gd`: bakes them from the real level; `tools/test_npc.gd`; `tools/probe_anchors.gd`, `probe_porch.gd`, `probe_npc_block.gd` (diagnostics).

Edited: `tools/shot.gd` (`SHOT_NPC=<route>:<0..1>` shows the sailors on a route), `readme.md`.

Not touched: Level.tscn (nothing is placed in the level yet: that is T04), the gate, the door, the interior, dialogue.

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_npc.gd
godot --headless --path . --script res://tools/bake_npc_paths.gd   # after the island, harbour, door or interior change
```

Baked routes: `sailors_dock_to_porch`, `sailors_dock_to_hall` (Arthur's walk-in: the south jetty where the rowboat moors, the back quay, up the stone stairs through the gate, across the plateau, the porch, through the door to the hall just inside), `daniel_dock_to_basement` (the same, then through the hall and down the spiral to his basement marker, where he stays), `porch_to_hall`, `hall_to_porch`, and `hall_to_launch_berth` (Arthur from the hall to the player's north-jetty berth, for boarding in T11). About 60 m, 70 m and 70 m at 1.45 and 1.55 m/s: about 45 s door to door.

Using it (T04): `var a := Npc.spawn(level, "ARTHUR", route[0]); a.arrived.connect(...); a.walk(Routes.route("sailors_dock_to_hall"), "sailors_dock_to_hall")`. The walker has no collision of its own; it interpolates between the baked points, so the gate must be open (the island gate and the door were opened while baking) and the bake must be re-run when the level changes.

## 4. Observed behaviour

`test_npc.gd`: OK, 0 failed (26 checks). All six routes baked; they start at the south jetty and end in the hall just inside the door (Arthur) and 0.2 m from Daniel's basement marker; the route passes through the door opening; a chest-high 0.3 m walker's body is clear along the whole of the three long routes with the gate and door open; with the island gate shut the same route is blocked (control); both walkers arrive once each in about length / speed (46 s), end on the last point, and Daniel stays put for 20 s afterwards; `wait()` holds and then resumes; `follow()` closes to and keeps a 2 m gap when the target moves 30 m; `sit()` rides a moving seat and `release_seat()` puts the walker back. The bake slid nine blocked samples sideways where the plateau path brushed a rock. A rendered still shows the capsules on the stone stairs under the gate.

## 5. Not verified

- Not seen walking in the real game: no scene places them yet, so the walk, the gate and the dialogue timing are for T04.
- The capsules are dark at night and have no animation, shadows tuned, or toon outline; they will look like bright placeholders in some lighting.
- The walker does not avoid the player or each other (Arthur and Daniel can overlap if started together): T04 should start Daniel a few seconds behind.
- The boat seat: `sit()` takes any Node3D; the engine boat has the player's seat offset only, so Arthur's seat position on the boat is for T11.
- The baked jump of up to 0.49 m between two samples (a stair riser at the gate) shows as a small snap.

## 6. Licences and provenance

None: capsule meshes made in code.

## 7. Interface or contract changes proposed

PROPOSED: the route names above and the `Npc` API as the shared way to move Arthur and Daniel (T04, T05, T11). No new event IDs.

## 8. Open creator decisions

- Where exactly the rowboat is moored (the routes start at the south jetty, (-27, 26.3)); T04 places the rowboat and the window moment there.
- Whether Arthur should wait in the hall or follow the player once inside (the routes support both).
