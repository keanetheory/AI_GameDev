# HANDOFF - T46, T47: the stairwell (floating orbs of light, exterior mesh showing through)

## 1. Task and goal

- T46 (score 8, Level Layout agent): "Remove the random orbs of light in the lighthouse stairwell". Creator, 30 Oct 2026: "there are random orbs of light in the stairwell of the lighthouse, we need to remove those". Keep the light count within `max_dynamic_lights` 18.
- T47 (score 8, Level Layout agent): "Fix the clipping in the stairwell where the external mesh comes through". Creator, 30 Oct 2026: "there are still clippings in the stairwell where the external mesh is coming through". Keep the collider bake in step (`test_collider_bake.gd` was already failing on `G_outer_west_window_infill`).

Neither lists a requirement id. Commits: 0158cad (31 Oct 2026, T46 part; the same commit holds T56 and T58, see `HANDOFF_T56_T58_ControlsToggle_NoProximityLight.md`) and 81b94ee (1 Nov 2026, T47). Note written 2 Nov 2026 to close R21.

## 2. Files changed

T46 (0158cad):
- `scripts/world/room_light_cards.gd`: new `_bulb(light)` finds the fixture's glass or bulb mesh (`X_Light` has `X_Glass` or `X_Bulb`). A halo is now added only for a light with a fixture, and is centred on the bulb. Cause: the eight bare `Spiral` stair lights had no fixture, and wall lamps' real lights hang about half a metre out from the bulb, so their additive halos floated in the air.
- `tools/test_room_lights.gd`: checks every halo sits on its bulb, none on a bare light, no halo on Spiral1-8; the player now stands on a real floor (the `l1_ring` anchor).
- `tools/shot_view.gd` (new): a still from a player position and look target (needs a window).

T47 (81b94ee):
- `scripts/world/exterior_clip.gd`: it looked for the scan's `convert` node directly under the Lighthouse; since the v4 exterior that node is one level down, so the clip had silently done nothing. It now uses `find_child`, warns if the node is missing, and also removes triangles that only partly stand inside the tower lining (corners, edge middles or centre) when none of them reaches within 0.7 m of the real outer wall. It tags the changed meshes `clipped_after_build`.
- `scripts/world/interior_rooms.gd`: the ground window infill is tagged `added_after_build`.
- `tools/test_collider_bake.gd`: skips added meshes; compares clipped meshes by vertex count and collision, not triangles.
- Not changed: the exterior model, the baked colliders, `Level.tscn`.

## 3. How to run and test

From `LightingTheStorm/` (creator's binary: `C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe`):

```
godot --headless --path . --script res://tools/test_room_lights.gd
godot --headless --path . --script res://tools/test_collider_bake.gd
godot --headless --path . --script res://tools/test_interior_anchors.gd
godot --headless --path . --script res://tools/test_sightlines.gd
godot --headless --path . --script res://tools/test_rain_shelter.gd
```

Every level load prints `exterior_clip: N of M exterior triangles ... were taken out`. If it ever prints 0 or the warning, the clip has lost the scan again.

## 4. Observed behaviour

Run by me on 2 Nov 2026 (Godot 4.3.stable, at eba7a35):
- Every level load printed `exterior_clip: 242 of 35961 exterior triangles stood inside the rooms and were taken out` (the backlog's figure of 242).
- `test_room_lights.gd`: ALL PASSED. 27 pools, 17 halos, 9 window pools; "every halo sits on its lamp's bulb: 17 halos, 0 floating, 0 on a bare light"; "the stair lights (Spiral1 to 8) have no halo"; 6 live lights, 2 shadowed.
- `test_collider_bake.gd`: `RESULT: OK` (the old `G_outer_west_window_infill` failure is gone).
- `test_interior_anchors.gd`, `test_sightlines.gd`, `test_rain_shelter.gd` (0 of 160 stairwell points uncovered): ALL PASSED.
- `test_interior_budget.gd`: OK (25 lights in the level under 70; every interior light managed; at most 6 lit).
- The backlog also records eight before/after stairwell renders and a probe of every mesh against the lining; I did not repeat those.

## 5. Not verified

- Not walked by me: the stairwell from bottom to top in play, looking for any remaining orb or sliver, especially at grazing angles near the windows.
- The stairwell is now lit by the Spiral lights with no visible source glow; whether it reads too dark or the light looks sourceless is a matter of looks.
- No automated test asserts that no exterior triangle stands inside the lining; the probe used for that was a one-off.
- The 0.7 m reach could in principle remove a real outer-wall triangle where the wall is thinner; the renders reportedly show the tower outside unchanged.

## 6. Licences and provenance

None. No external assets.

## 7. Interface or contract changes proposed

None outside the code. The mesh metas `added_after_build` and `clipped_after_build` are internal markers for the bake test.

## 8. Open creator decisions

- Should the eight bare stair lights get real fixtures (for example the new FAL wall sconce), so the stairwell light has a visible source?
