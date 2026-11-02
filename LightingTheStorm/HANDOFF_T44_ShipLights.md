# HANDOFF - T44: light the passenger ship properly

## 1. Task and goal

T44 (score 8, Lighting agent with the creator): "Polish the passenger ship: light it properly". Creator, 30 Oct 2026: "polish the passenger ship, right now the lights are just blobs outside the ship and they look awful". The ship (the Lantern Queen, `scripts/world/passenger_ship.gd`) should show lit portholes and windows, a lit bridge and deck lamps, masthead and navigation lights on the structure, a soft spill on the hull and water close by, and nothing floating off the hull. It must read from the lamp room and from the launch at range (R19: warm lamplight against the blue-grey storm), stay inside `max_dynamic_lights` 18 and keep the crash readable. No requirement id is listed on the task; R19 is named in its summary.

Commit 676e9b6 (1 Nov 2026). Note written 2 Nov 2026 to close R21; `HANDOFF_T07_T31_ShipDeadline.md` already has a "T44 update" section from the same commit.

## 2. Files changed

- `scripts/world/passenger_ship.gd` (+361/-91): the sphere lights are gone. At load it casts rays at the ship's own mesh (about 0.25 s) and lays 188 small emissive panes flat on the hull and superstructure: two porthole rows, the promenade and upper tier on both sides, the forward face and bridge, the after face. Panes are additive, fog-proof and grow in their own plane with distance. Seven lamps (two white mastheads, red and green sidelights in the bridge-wing lanterns, the white stern light, two globe lanterns) each visible only in its real sector, with a rain-haze glow that grows with distance. Two warm OmniLights spill on the hull and water only within 160 m of the camera. The crash fades everything through one `power` shader parameter with a flicker.
- `data/world/ship_route.json`: the `lights` block rewritten (`windows.rows`, `lamps`, `halo_*`, `spill`), with notes.
- `HANDOFF_T07_T31_ShipDeadline.md`: the T44 update section.
- Backlog JSON and BACKLOG.md: T44 done.
- Not changed: the ship's route, timing, crash or any test.

## 3. How to run and test

From `LightingTheStorm/` (creator's binary: `C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe`):

```
godot --headless --path . --script res://tools/test_ship_route.gd
godot --headless --path . --script res://tools/test_ship_deadline.gd
godot --headless --path . --script res://tools/test_outcome_screen.gd
godot --headless --path . --script res://tools/test_slice_playthrough.gd
```

To look at it: `tools/shot_cam.gd` (needs a window) takes a still from a free camera. In the game, feed the boiler and look north-east from the lamp room; the ship holds at (700, -250). All tuning is in the `lights` block of `ship_route.json`.

## 4. Observed behaviour

Run by me on 2 Nov 2026 (Godot 4.3.stable, at eba7a35):
- `test_ship_route.gd`: `RESULT: OK (0 failed)`, 21 PASS (lane, crash 11.6 s after the deadline, worst clearance 15.4 m when the beacon is lit, lamp-room and boat sightlines).
- `test_ship_deadline.gd` (29 PASS), `test_outcome_screen.gd` (17 PASS), `test_slice_playthrough.gd` (40 PASS): all `RESULT: OK (0 failed)`.
- None of these tests checks the lights themselves. I grepped `tools/`: nothing counts the windows, checks a lamp's sector, the spill's 160 m gate or the crash fade. The passing tests show the rework did not break the route, deadline or endings, not that the lighting is right.
- The commit message and backlog record renders checked from the lamp room (150 m), the launch at 560 m, bow-on, side-on, beacon relit and the crash at 2, 12 and 30 s. I did not re-render them.

## 5. Not verified

- How the ship reads in play at night in rain, from the lamp room and from the launch: the creator's eye is the test here, since the original complaint was about looks.
- The ship at the real horizon (900 m); stills were taken at 150 m and 560 m only.
- The light budget in the worst case: the two spill lights are live only within 160 m of the camera, which the code comment says happens near the crash when the interior lights are off. Nobody has counted live lights with the player near both the ship and the lampposts.
- The 0.25 s ray-cast at load is measured once; not checked on a slower machine.

## 6. Licences and provenance

None. No new assets; the ship model is unchanged.

## 7. Interface or contract changes proposed

PROPOSED (data only): the new `lights` schema in `ship_route.json` (`windows`, `lamps`, `halo_per_m`, `halo_max_m`, `spill`) replaces the old fields (`window_rows_y`, `masthead`, `port_red` and others). No events or signals changed; `impact` and `passed` are as before.

## 8. Open creator decisions

- Does the lit ship now look right? (The task was a look, so it stays open until the creator has seen it in play.)
- Should a light-count check be added to `test_ship_route.gd` (windows built, lamps in their sectors, spill off beyond 160 m)?
