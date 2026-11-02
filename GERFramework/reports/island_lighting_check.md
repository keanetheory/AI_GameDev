# Bracken Isle: lighting check in all four phases (ISL-04)

Island Creator Agent, 2 November 2026, with the Lighting agent's offline validators. Real level (`scenes/Level.tscn`), Godot 4.3, rendered in a window at 1280x720; budget and material checks headless.

## How the stills were taken

`LightingTheStorm/tools/shot_phase.gd` (new) loads the level once and, for each phase, does what F5-F8 do (`LightingRig.set_phase(phase, instant)`), plus:

- sets the sea state the Wave agent's curve gives near the island in that phase (`WaveSystem.force_state`: ISLAND 1, OUTBOUND 1, RETURN 5, BEACON_RELIT 5) and the island's wetness to match (ISL-05), so RETURN shows the wet, darker rock the player will see;
- lights the lamp for BEACON_RELIT only (dark before), sweep frozen, beam turned 55 degrees off the camera line so it crosses the frame;
- holds lightning off for the main stills; `flash` adds one still a few frames after a strike for RETURN and BEACON_RELIT;
- moves the (hidden) player to the viewpoint so the interior lights behave as in play; hides the HUD and the debug phase label.

Run: `Godot --path . --script res://tools/shot_phase.gd -- <out_dir> [phases=...] [views=...] [flash] [nofog] [prefix=...]`.

## Phase x viewpoint (all in `GERFramework/shots/island/`)

| Viewpoint | ISLAND | OUTBOUND | RETURN | BEACON_RELIT |
|---|---|---|---|---|
| Dock (south jetty, up the stair to the gate) | `isl_dock_ISLAND.png`: OK | `isl_dock_OUTBOUND.png`: OK | `isl_dock_RETURN.png`: OK, darker wet rock | `isl_dock_BEACON_RELIT.png`: OK, beam over the tower |
| Path (plateau past the gate, to the lighthouse) | `isl_path_ISLAND.png`: OK | `isl_path_OUTBOUND.png`: OK | `isl_path_RETURN.png`: OK | `isl_path_BEACON_RELIT.png`: OK |
| Lighthouse window (inside the lamp-room glass, down to the harbour) | `isl_window_ISLAND.png`: **washed out** (F2) | `isl_window_OUTBOUND.png`: same | `isl_window_RETURN.png`: same | `isl_window_BEACON_RELIT.png`: same |
| Gallery (same line, just outside the glass) | `isl_gallery_ISLAND.png`: OK, tower shadow on the plateau | `isl_gallery_OUTBOUND.png`: OK | `isl_gallery_RETURN.png`: OK, wet rock, spray | `isl_gallery_BEACON_RELIT.png`: OK |
| Sea approach (115 m out, from the Saltgate side) | `isl_sea_ISLAND.png`: OK, silhouette | `isl_sea_OUTBOUND.png`: OK | `isl_sea_RETURN.png`: OK, spray ring; `isl_sea_RETURN_flash.png` | `isl_sea_BEACON_RELIT.png`: beam sweeps over the island; `isl_sea_BEACON_RELIT_flash.png` |

All 22 stills were looked at one by one. The gallery view was added because the in-room window view (what the player sees) is hidden behind the lantern glass, so it cannot be used to judge the rock.

## The checks

| Check | Result | How |
|---|---|---|
| Matte stone: no metallic or emissive leaks | **Pass** | `tools/test_island_lighting.gd`: all 10 materials on Island, RockPatch x3, Harbour, HarbourStairs and IslandGate have metallic 0 and emission off, dry and fully wet (ISL-05's wetness lowers roughness, never adds metal). In the stills nothing on the rock glows or glints; the only warm points are the lighthouse windows and the dock lampposts (Lighting agent sources) |
| Shadows land on the rock | **Pass** | The moon casts shadows (300 m directional shadow distance) and every rock mesh casts them. Seen in the stills: the tower's shadow lies across the plateau (`isl_gallery_*`), the house shades the plateau (`isl_path_*`), the crags shade the stair (`isl_dock_*`) |
| The beacon sweep catches the island rocks | **Not met, by geometry: creator / Lighting agent decision (F1)** | The beam's visible cone sweeps over the island and reads clearly from the dock, path and sea (`isl_*_BEACON_RELIT.png`), but its light never lands on the rock: the headless test casts rays down the spot's cone in 36 headings and none meets island rock. Even tipping the spot 20 degrees down does not reach it |
| Fog keeps hazards legible | **Pass** | A hazard at each phase's `hazard_visibility_m` keeps 46% (ISLAND), 41% (OUTBOUND), 38% (RETURN) and 19% (BEACON_RELIT) of its contrast (exp(-density x distance)). In the sea stills the island reads as a dark shape against the sky in every phase. Under a lightning flash the island (luma 68) stays darker than the sea (79-94), so the flash does not wash the rock out (spec legibility check "hazards read darker than the sea during a flash") |
| Dynamic lights within `max_dynamic_lights` (18) and `max_shadow_casters` (2) | **Pass** | `test_island_lighting.gd`, every phase x viewpoint. Positional lights: 3 (dock, path, sea; the two harbour lampposts and the Saltgate hut lamp), 5 with the beacon lit (+ lamp Glow, beam Spot), 7-9 in the lamp room (+ 3 tower spiral lamps and the Lantern). Counting the moon too, as `world_validators.py` does (+2 for moon and lightning), the most is 10 of 18. Shadow casters: at most 2 positional (lamp room) plus the moon's directional shadow (F4) |

## Findings

**F1. The beacon's light never touches the island (creator / Lighting agent).** The lantern is 29 m up; the plateau around it is 9-11 m high within 25 m and drops to the sea by 35-45 m (`tools/measure_island_footprint.gd`, ground rings). The placeholder spot (`lamp_beacon.gd`/`lantern.gd`: 11 degree cone, 90 m range, energy 14) points at the horizon, so it passes over the rock, as a real lighthouse beam does. It also never reaches the sea: tipped down 4 degrees its lower edge still hits nothing within 90 m, and from 8 degrees down it meets the sea inside its range. So today the spot is a live dynamic light that lights nothing. The options are a judgment call, so nothing has been changed:
  - (a) accept: the visible beam sweeping over the island is the read, and the objective's "catches the rocks" is dropped;
  - (b) tip the spot about 8 degrees down so its lower edge sweeps the sea and the outer rocks 60-90 m out (the island itself still stays dark);
  - (c) a second, steep, short-range "spill" at the lantern foot to catch the plateau (one more dynamic light);
  - (d) drop the spot and keep only the visible beam (one dynamic light fewer).
  The beacon belongs to the Lighting agent (backlog T13, `lamp_beacon.gd` says it is a placeholder) and the lighthouse code, not the island. Note also that the spec's `LIGHT_BEACON` says energy 8 and range 400 m, while the game's spot is 14 and 90 m; T13 should reconcile them.

**F2. From inside the lamp room the island is a pale slate wash (creator / Lighthouse lane).** The lantern glass (`lantern.gd`, `Lamp_Glass`, albedo (0.2, 0.27, 0.33) at 65% opacity) was made dense on 25 Oct so the glazed drum reads from the sea. From the inside, it lays a flat blue-grey over the view: the harbour and jetties show only as ink lines (`isl_window_*.png`), against `isl_gallery_*.png` taken 0.4 m further out. If the window view of the island matters (Ted names the ship from the lamp room), a fix would be to draw the glass's inner face lighter (a back-face pass at about 25% opacity), so the sea look stays. Not changed: it is the lighthouse's file and the creator asked for the dense glass.

**F3. Debug key clash: F8.** The rig's F8 (jump to BEACON_RELIT) and ToonLook's F8 (toon look on/off) share a key. In a debug build the rig marks the key handled first, so ToonLook never sees F8; in a release build the rig's keys are off and F8 only toggles the toon look. Harmless, but the toon toggle cannot be used in debug builds. Suggest moving ToonLook to another key (lighthouse lane; reported, not changed).

**F4. What `max_shadow_casters` counts.** `world_validators.py` counts the spec's `sources` with `casts_shadow` (none of them do) and adds the moon and lightning to the dynamic-light count, but not to the shadow count. In play, the lamp room has 2 shadowed interior lights plus the moon's directional shadow. Under the validator's reading that is within budget; if the moon is meant to count, the lamp room is at 3 of 2. For the Lighting agent to state in the spec (one line in `max_dynamic_lights_note` or a `max_shadow_casters_note`).

**F5. The Lighting agent's copy is one step behind the game.** `AIAgentCrew/world_output/lighting_spec.json` has `max_dynamic_lights` 16 and no note; the game's `data/world/lighting_spec.json` has 18 (creator, 31 Oct, T36) with its note. Both pass the validator. `offline_world_llm.py` already writes 18, so a `main_world.py --offline --godot-dir` run would not lower the game's figure, but it would drop the note. The Lighting agent should copy the game spec back into `world_output/` the next time it runs.

## What the Lighting agent checked (offline, no tokens)

- `world_validators.check_lighting` (with `world_schemas.LightingSpec` and the style-guide palette) on the game's `LightingTheStorm/data/world/lighting_spec.json`: schema OK, **PASS** (palette colours only, lightning interval above the flash cap (spec 2/s, cap 3/s), no light a navigation marker, legibility checks covering hazards, lightning, beacon, moon, rain and Saint Calder, budget arithmetic).
- The same on `AIAgentCrew/world_output/lighting_spec.json`: **PASS**; it differs from the game spec only in `max_dynamic_lights` (F5).
- No change was made to `lighting_rig.gd` or `lighting_spec.json`, so there was nothing new to pass through the validators. `main_world.py` was not run, because it would rewrite `world_output/` from the scripted offline LLM.

## Island materials

No island material needed fixing: the rock, the patches, the harbour, the stairs and the gate are matte in every phase and react to the storm as ISL-05 intended (darker, glossier in RETURN, never emissive).

## Not verified

- Motion: the beacon's sweep, rain, spray and the lightning strobe were judged from stills, not in motion. The 60 s photosensitivity recording in the spec's legibility checks is the Lighting agent's and was not run here.
- Phase blends (the 6 s cross-fade) and the eclipse dimming were not captured; every still uses an instant phase change with the moon at full strength.
- The window view was taken from one point inside the lamp room; the house windows (no clear view of the island) were not used.
- A human should press F5-F8 in the editor at the dock and at the lamp room and confirm the stills match what they see.

## Tests

- `tools/test_island_lighting.gd` (new): ALL PASSED (prints F1 as a FINDING, not a failure).
- `tools/test_island_coverage.gd`: PASS (dock-to-door route 0 fall-through, 0 invisible-wall clusters).
- `tools/test_island_walk.gd`: all four routes reach their ends.
- `tools/test_island_reactions.gd`: OK (0 failed).
- `tools/test_interior_lights.gd`: ALL PASSED.

## Creator decisions, 2 Nov 2026, and what was done

- **F1 (beacon never lights the rock):** add a short spill of light onto the rocks, and shade the beam so it is less of a straight, solid shaft.
  - `lantern.gd` adds a `Spill` spot on the beam pivot: 5 m out along the beam, tipped 36 degrees down, 26 degree cone with a soft rim, 60 m range, energy 6 (`lamp_beacon.gd` `spill_energy`), no shadow. It turns with the beam. `test_island_lighting.gd` now checks it lands on island rock: 35 of 36 headings, 23-51 m from the lamp.
  - The beam is now a flat strip that turns about its own axis to face the eye, with soft edges, an early fade toward its end and slow rain streaks drifting outward. The old open cone showed its mouth as a hard-edged disc whenever the beam swung toward the viewer, and the clouds behind that disc disappeared. A stock material showed the same disc, so the cause was not the shader; the strip has no inside and the disc is gone.
  - The horizontal `Spot` is unchanged (it still lights nothing; T13 for the Lighting agent).
- **F2 (lamp-room glass):** clearer from inside. The pane is a small shader: 65% opaque seen from outside the glass ring, 14% from inside it, no specular glints.
- **F3-F5:** unchanged, still for the Lighting agent and the lighthouse lane.
- Lighting agent, offline: `world_validators.check_lighting` on the game's `lighting_spec.json` returns no issues (the spill uses the lamp's own palette colour; the spec is unchanged).
- Stills (scratch, not in the repo): before/after from the dock, the path, the lamp-room window and the sea.
- **The beam's own light (creator, 2 Nov 2026: tip it down to sweep the sea):** the beam and its spot dip 5 degrees (`lantern.gd` `BEAM_TILT_DEG`); the spot's range is 400 m (the spec's LIGHT_BEACON range) with a slow falloff (spot_attenuation 0.25). Its lower edge meets the sea about 100 m out and its centre about 335 m out (`test_island_lighting.gd`). In the BEACON_RELIT fog it reads as a faint warm sweep over the wave crests, not a bright band.
