# Lighthouse finish: report (2026-10-26)

## A. Tools built (all committed in 671120e plus the lighting update)
| Tool | Run | What it measures |
|---|---|---|
| `tools/audit_clipping.gd` | headless | A outside the walls, B edges cutting the exterior mesh, C props clipping, D real-world scale (props, doorways, windows) |
| `tools/probe_lighting.gd` | windowed | luma and saturation of a fixed 0.5 m wall sample at 2/4/6/8 m, every room incl. basement |
| `tools/probe_rain_render.gd` | windowed | rain drawn in magenta, 8 headings x 5 pitches at 16 positions; counts drops whose sight ray ends on a solid interior surface. Positive control outside |
| `tools/test_rain_cover.gd` | headless | every interior air point (house columns to the roof underside, tower out to the measured wall) is inside a shelter volume |
| `tools/probe_rain_heightfield.gd`, `probe_rain_gpu.gd` | windowed | the controlled GPU experiments below |

## B. Rain
Hypothesis (spawn inside a collision box is never hit): **disproved** (probe_rain_gpu: a drop born inside the box is hidden at once).
Real cause: GPU particle collision hides a drop a frame or two **late** (probe_rain_heightfield: drops are drawn up to ~0.9 m below the surface they hit, for the height field and for boxes alike). Wherever the ceiling is within a metre of the roof (house attic, lamp-room dome) drops were drawn indoors. Also the house box stopped at 8.9 while the roof cavity reaches 10.0 (12.2 at holes in the exterior roof) and the lantern box was 0.14 m short of the glass.
Fix: `rain_streak.gdshader` discards any fragment inside the RainShelter volumes (draw time, no latency, frame-rate independent). Collision boxes removed (they also threw splash specks off their invisible tops). Volumes: house to 12.4, lantern radius 2.84 / top 25.3.
Before (probe, RETURN): house_L1 416 to 2655 px, house_L1_b 545, attic 365, lamp room 420. Volumes switched off: attic 169, lamp room 744.
After: RETURN and ISLAND 0 px at all 15 interior positions; OUTBOUND 0 except lamp_room which showed 123 px once in four runs (rain seen through the lantern glass leaking past the probe's mask, not indoors; the other three runs 0). Control (outside) 72 to 1172 px.
Tests: 18 of 18 lighthouse tests, test_rain_cover, audit_lighthouse -- check (799,030 tris) all pass.
Shell defect found, not patched: 5 columns of the house have **no ceiling** (a ray from the first floor goes through a hole in the exterior roof). Rain is hidden there by the volume; the hole remains.

## C. Lighting (measured, ISLAND phase; table in lighthouse_lighting_before.csv)
- Tower (G, L1, L2, stair): luma 0.30 to 0.51, flat with distance. Pass.
- **Basement: luma 0.25 to 0.29, saturation 0.43 to 0.61, far/near 0.95 to 0.99. It is the darkest room but NOT washed out and does not fall off with distance.** I could not reproduce "washed out" with these samples. Which view do you mean (the stair down, the boiler from the stair)?
- House: hall sight line #1 falls 0.47 (2 m) to 0.17 (4 m) to 0.04 (8 m); hall #2 saturation 0.34 to 0.21; L1 saturation 0.28 to 0.18. Cause found for hall #1: the far sample is a face of the **exterior mesh** (`material_col`) showing inside the room; no interior material covers it, so it gets no fill and no lamp reaches it. That is the layer problem, not a light-budget problem.
- No lighting change made. A fix on top of the current shell would be another patch (more fill or a card on the exposed exterior face).

## Clipping audit (current numbers)
A outside the walls: 9 meshes (L1 floor, lining and skirt poke through the west wall; lamp-room ring beam crosses the glass). B: 82 of 999 interior meshes cut through the exterior mesh (tower window heads/jambs, step fills). C: 10 prop overlaps (coats, barrels, desk and chair, bed in a wall). D: 10 props outside real-world size (cabinet 0.71 m high, telegraph 0.64, barrels 0.95 wide), 2 windows 0.8 m high; doorways pass.

## D. Shell proposal (needs your approval)
Reason: every open finding above is the exterior mesh and the code-built interior fighting (holes in the roof, exterior faces inside rooms, 82 crossings). Patching adds layers.
Build ONE authored modular shell in Blender, exported as a single glb: tower (thick wall, window openings at the 9 data/world/lighthouse_windows.json positions), house (ground, first floor, attic, gables, roof seated on the walls, closed roof and lantern cap), basement, floors and stair openings to data/world/stair_spec.json, doorways 0.9 x 2.0 clear, lantern base. Keep: hero props, boiler fire, posters, lamp, cel look, rain volumes (re-derived from the authored rooms). Retire: roof liner, masonry patches and facade cells, carve lists in Level.tscn, light cards for exposed faces, the tower radius table. Keep exterior v3 and the old interior scripts as v-numbered fallbacks.
Cost: no FAL. A multi-session job; the code-built rooms would be re-seated on authored floors, and the lighting is then re-measured (and baked GI becomes practical because the shell is clean).

## Update 2026-10-26 (after the creator's answers)
### Washout (the creator's two screenshots)
The washed-out look is the amber "fill" emission (ToonLook.fill 0.13) lifting every surface toward cream. Measured on the creator's two images: washed (stairwell from the hall) luma 0.50 / saturation 0.38 / dark-pixel share 0.16; good (basement from the stair) luma 0.33 / 0.47 / 0.37. `tools/probe_washout.gd` reproduces both from `lhf_views.gd` (stair_down_view 0.51 / 0.43, basement_from_stair 0.33 / 0.65) and sweeps the fill: at 0.13 the tower and house sit at saturation 0.26 to 0.39; at 0.05 they sit at 0.45 to 0.53; at 0 the dark colours show fully but far walls go near black (house L1 luma 0.10). Set to **0.05** (commit a9bffc0): washout probe passes except tower_L1_b147 (sat 0.35, deliberately dark corner), house_L1 (0.34) and house_attic (0.37), which are grey plaster, a material fix. Trade-off: the 2/4/6/8 m consistency in the house is a little lower than at 0.13 (hall #2 far/near 0.77). The real fix for far walls is baked light on a clean shell, not more emission.

### Shell (step D): started, not finished, default build unchanged
- `Assets/Models/lighthouse/shell/build_shell_v1.py` (Blender 5.2 headless; `RENDER=1` writes previews to GERFramework/shots/shell_v1_*.png) builds one solid by CSG: tower cone + house basement, ground floor, first-floor slab, first-floor walls with a gable roof, lantern deck and dome cap, minus every room's inner volume (the faces the interior is built to) minus doorways and the 8 + 1 windows from data/world/lighthouse_windows.json. The house wins where it meets the tower, so a real wall stands between hall and tower. Output `lighthouse_shell_v1.glb` (7,110 verts). Open edges: 69 (tangent unions, to be cleaned). `build_tower_shell_v1.py` is the tower-only first version.
- Try it: `LHF_SHELL=1` (tower wall only) or `LHF_SHELL=2` (whole shell, exterior mesh and greybox walls hidden). Both off by default; the audit and tests are unchanged without the variable.
- Audit with the authored shell (SEAM 0.05 m so a panel sunk into a wall is not clipping): old exterior B = 61 crossings, mostly lamp-room rafters and mullions; `LHF_SHELL=1` B = 55; `LHF_SHELL=2` B = 111, A = 80. **So it does not yet resolve the clipping.** The causes are listed and fixable, none is a mystery:
  1. Window reveals and sills are built 0.8 m deep (REVEAL) for the old wall; the authored wall is 0.75 thick, so they poke out of the outer face (accounts for most of A).
  2. The lantern: the shell's deck is solid to 18.33 across the whole disc; lantern.gd builds its own floor, kerb, mullions and stair rail from 17.9 to 18.3. The deck must be an annulus (r 2.9 to 4.0) with the code floor inside.
  3. Tower fills, rings and G_StairFloor were built to the old measured radii; with a clean wall they should end exactly at the analytic inner radius (done in tower_shell.gd for the stairs; landings and rings not yet).
  4. Near the house the tower air is cut by the house wall slab (up to 0.77 m at the first floor), so landing rings and the L1 doorway landing must stop at the wall there.
  5. First-floor roof, ceiling height and eave are my gable (eave 7.0, ridge 9.9); the L1 furniture, roof liner and gable panels were placed under the old irregular roof and need re-seating, and the roof liner and gable panels are to be retired.
Expect another session of integration; each of 1 to 5 has a number in the audit to drive it to zero.
