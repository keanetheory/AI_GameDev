# Lighthouse Finisher Agent: work report (pass 1, 2026-10-24)

Approved 2026-10-24 ("good to go on all fronts - use FAL credits - cap it at $7.80"). **FAL spend so far: $0.00 of $7.80.**

## Baseline (LHF-01, partial)
- Green-test baseline before any change: test_interior_anchors, test_interior_budget, test_interior_lights, test_sightlines, test_door, test_spiral_down, test_coal_job, test_lamp_fit, test_interior_walk: **9 of 9 pass**.
- Baseline shots in `GERFramework/shots/`: `base_boiler`, `base_hall`, `base_stair_low`, `base_stair_mid`, `base_stair_up`, `base_stair_down`, `base_stair_side`. The stair shots were taken from guessed camera positions and are not useful (inside the newel or outside the wall); redo them from the house-frame tool once a route-based camera exists.
- Not yet done: per-room triangle and draw-call counts, exterior close-ups, the full fixed shot list.

## Done
| Objective | What changed | Verified |
|---|---|---|
| LHF-03 rain indoors | `scripts/world/rain_shelter.gd` (node `RainShelter` in Level.tscn): 7 invisible particle-collision boxes fill the house, the tower stairwell and the lamp room. A raindrop that enters one is hidden. | `tools/test_rain_shelter.gd` passes (every interior anchor and 160 stairwell points covered; door step, dock and lantern gallery not covered). **Not verified:** that the GPU hides the drops (headless has no GPU); needs one look in the editor in a storm. |
| LHF-05 boiler fire | `scripts/world/interior/fire_flame.gd`: ten glowing coal lumps, three layers of stepped, cel-shaded flame cards, ten sparks, a stepped light flicker. The red slab (`B_FireDoorGlow`) is now a dark coal base. `coal_job.gd` drives the level 0 to 1 with the six loads. | Shot `fire0.png` (flames and embers at level 0); test_coal_job, test_interior_budget, test_interior_lights pass. **Not shot:** the fire at full level, and the sparks (GPU). |
| LHF-09 posters | Four hand-made letterpress textures (`tools/make_flighted_posters.py` to `Assets/Textures/interior/poster_*.png`): black, silver and navy ink, misregistered, torn edges, paste drips, a fold. Canon slogans only: the old third slogan "KEEP THE MOON'S HOUR" is gone. Four posters in the hall, tilted a degree or two, 12 mm off the wall. The generated model and its paper strips are no longer used. | Shots `poster_a/b/c`; no z-fighting seen from the angles shot; test_interior_anchors passes. The `Read` interaction is kept (not exercised by a test). |

## Pass 2 (2026-10-24, after "continue with the stairs and the exterior-inside-interior fix")
| Objective | What changed | Verified |
|---|---|---|
| LHF-02 exterior inside interior | Re-ran the probes with the **true room bounds** (the first run reached v 8.9, past the ground floor's back wall at about v 6.7, which made hundreds of false "island hits"). Corrected: tower 0 intruders; basement 13 and ground floor 45 hits, all on the wall faces at the room edges (the exterior wall behind the interior lining, not intrusions); L1 about 550 hits on the roof underside, which was the real problem: **L1 had no ceiling of its own** and showed the exterior roof with its exterior texture. New `scripts/world/interior/roof_liner.gd`: samples the roof underside with rays on a 25 cm grid and hangs a plaster liner 2 cm below it (visual only). | `tools/test_roof_liner.gd`: liner built, covers 66% of the L1 footprint (cells beside the stairwell and at steep gables are skipped), and 93% of sampled liner points have the roof within 6 cm above. **Not done:** the gable walls above the knee wall at L1 are still the greybox wall and the exterior's own surface where they meet the roof; no separate liner for them. |
| LHF-04 stairs | Every step is now a detailed stone tread (`scripts/world/interior/stair_tread.gd`): a rounded nose overhanging the step below, a visible riser, a worn middle (lighter, smoother) against dark joints at the newel and the wall, and a small tint difference per step. Used for all 96 tower steps and all 15 basement steps. Collision and route are exactly as before (hidden bodies keep the old shapes). A single spec, `data/world/stair_spec.json`: rise 0.18 m +-5%, going on the walk line 0.25 to 0.45 m, headroom at least 2.0 m. | `tools/test_stair_spec.gd`: tower rise 0.176 m (96 of 96 within spec), going 0.42 m, least headroom 2.24 m; basement rise 0.186 m (15 of 15), going 0.36 m, headroom 2.94 m. Shots `stairs_i6`, `stairs_i30`, `stairs_i70`. The walk, spiral and door tests still pass. |

### Stair facts worth knowing (they decide what a bigger rebuild would be)
- The walkable stair is only the inner strip, newel radius 1.14 m out to 2.07 m (0.93 m wide). The existing outer rail at 2.1 m blocks the rest, so the slab out to the tower wall (up to about 3.4 m) is a filler that nobody can reach. I left it, now as a plain slab behind the rail.
- The central drum is 2.3 m across. A more realistic stair would sit against the wall with a small open eye, but that moves the walkable surface, the landing rings and the rail, and is a bigger rebuild than this pass. Say if you want it.
- The going on the walk line is 0.42 m with a 0.176 m rise (about 24 steps a turn), shallower than a real lighthouse stair; it plays comfortably but it is not tight.

## Pass 3 (2026-10-24): exterior walls (LHF-11) and the cel-shaded sample (LHF-10)
| Objective | What changed | Verified |
|---|---|---|
| LHF-11 exterior walls | `scripts/world/exterior_wall_detail.gdshader` + `exterior_wall_detail.gd` (node `LighthouseWallDetail`): the exterior keeps its baked texture (silhouette and distance look unchanged) and, only within about 5 to 22 m of the camera, gets coursed masonry (a block for every 0.64 x 0.32 m, joints, a bevel, a tint for each block), a few centimetres of bump from the joints, dirty drip streaks and a damp, greener base. The tower's courses follow its curve. Stone only (a brightness mask leaves the dark timber and the door alone). Close up, the baked colour is read from a blurrier mip so its pixel blocks go. No geometry changed, so no collision, route or silhouette change. | Torch-lit close-ups before and after (`ext_*` and `ext_*2`): the tower and the house wall read as real coursed stone. The test for this is visual only; no headless check. |
| LHF-10 cel look (basement sample) | `scripts/world/toon_look.gd` (node `ToonLook`) + `toon_outline.gdshader`: the 214 basement meshes get toon diffuse (a hard light/dark step; no glints) and a full-screen ink outline (depth and normal edges, near-black navy, about 1.8 px) that draws only while the camera is in the basement. The originals are kept, **F8 switches the look on and off in play**, and `enabled` sets the starting state. The ground floor and above are untouched. | `tools/test_toon_look.gd` (basement meshes toon, ground floor and tower steps not, off restores the originals, on again). Shots `toon_boiler`, `toon_final` against the earlier `base_boiler`. Forward+ only. **Awaiting your approval** before it spreads. |

### Not fixed (and why)
- **The door pillars and the window surrounds are lumpy and ragged** (curled flaps of the model's own geometry, a flat brown slab door). That is geometry, not texture; the shader makes the stone read better but cannot reshape it. It belongs to the opening kit (LHF-12): stone reveals, lintel, sill and door frame built over the ragged edges.
- No bevelled stringcourses, plinth or lintels added to the exterior mesh yet.
- The toon look uses one shared setting; the hard step width (`toon_roughness`), outline thickness (`ink_thickness`) and ink colour are single values on `ToonLook` / the shader, so they are quick to tune when you have seen it.

## Pass 4 (2026-10-24): the cel look everywhere (LHF-10) and the opening kit (LHF-12)
The creator approved the basement sample ("Apply it to the whole lighthouse and the exterior, then continue with the opening kit").

| Objective | What changed | Verified |
|---|---|---|
| LHF-10 cel look, whole lighthouse | `toon_look.gd` now covers every interior material (all floors, the tower, the lamp room): toon diffuse, no glints, a crisp step. Materials are changed **in place** and the originals remembered, so the lamp lens, the switchboard lamp and the coal job, which hold references to some materials, keep working (an earlier design that swapped in copies would have broken them). The exterior's wall shader (`exterior_wall_detail.gd set_toon`) and the opening kit's stone use toon diffuse too. The ink outline is masked in world space to the lighthouse (a cylinder 12 m round it), so the island and the sea get none, and fades out between 40 and 110 m so the lighthouse still has an outline from the water. F8 still toggles everything. | `tools/test_toon_look.gd` (191 materials over 1196 meshes; basement, ground floor, tower step and L2 ring are toon; exterior is toon; off restores; on again). Shots `cel_hall`, `cel_ext_door`, `cel_ext_tower`: the hall is ink-outlined, the exterior outlines only the lighthouse. **Not checked:** the look in a boat view from the sea; the cost of the outline pass on a weak GPU. |
| LHF-12 opening kit | **Windows (5 tower, 3 house):** `opening_kit.gd` + `exterior_openings.gd` build a cut-stone surround on the outside of each window: quoined jambs, a lintel with a keystone, a sloped sill over a plain course, standing 0.2 m proud so it hides the ragged cut. The wall face is measured by ray at two points beside each window (and falls back to the nearest measured face where the exterior wall is missing). **Door:** quoined jambs, a voussoir arch of 11 stones, a fanlight with iron spokes, a threshold and a worn step; the leaf is boards with three iron straps and studs on both faces, hinge straps and a ring handle (`door.gd`, collision unchanged); inside, jambs and a stone threshold. **Missing wall:** where the carve had removed the exterior's wall at the first floor and the plaster lining showed from outside, 63 cells of masonry now close it (cells found by ray, window openings left clear). **Reveals:** the tower reveals were 0.8 m deep and stuck out 0.17 to 0.82 m past the real wall; they are trimmed to end just inside the measured face. The house reveals deepened from 0.65 to 1.05 m (the measured wall). | `tools/test_openings.gd`: all 8 windows and the door built (3 windows needed the fallback plane), door has its arch, fanlight, threshold and quoins; 15 of 16 side rays find the wall within 0.9 m. Shots `kit_door`, `kit_tower`, `kit_hbed`. A right-handedness bug (a mirrored basis turned the tower surround's normals inside out and rendered it black) was found by shot and fixed. |

### Not done
- **Two older openings have no surround:** the ground-floor west window (the one over the dock) and the tower landing window at bearing 147 are baked carves, not in `lighthouse_windows.json`, so the kit does not know them.
- The lamp-room glass and gallery rail (LHF-13) are not touched.
- The wall's thickness is uneven (0.55 to 1.05 m measured); the masonry patches sit on a median plane, so a patch can stand a few centimetres off the true wall.
- No bevelled stringcourses or base plinth on the exterior mesh itself.
- Not yet seen in the game's own night lighting: all exterior close-ups were taken with the shot tool's torch (`SHOT_TORCH=1`).

## Pass 5 (2026-10-24): props (LHF-08), with FAL
**FAL spend: $5.25 of the $7.80 cap** (14 textured text-to-3D models at $0.375; $2.55 left; no failures, no retries). Ledger: `reports/lighthouse_finisher_fal_ledger.json`. Every submission passed `main_asset.py --check-only` offline first.

| What | Detail |
|---|---|
| Models generated (14) | keeper's desk, chair, iron bed, wardrobe, sea chest, cast-iron stove, claw-foot tub, oak barrel, wooden crate, coat, kitchen table, telegraph set, oil lamp, filing cabinet (`AIAgentCrew/sample_submissions/lighthouse_interior/`). |
| Weight problem and fix | Each model arrived as **500,000 triangles with a 22 MB texture**; 24 placed instances would have been about 12 million triangles. `tools/decimate_props.gd` uses Godot's own meshoptimizer LODs (UVs survive), keeps the full copy in `prop/source/`, compacts the vertices, shrinks the texture to 1024 and re-exports. Results: 13,800 to 24,000 triangles each (barrel 9,270), 1.5 to 2.5 MB each instead of 20 MB. The whole placed set is 418,622 triangles. A second decimation pass emptied two models (Godot makes no LODs for a small mesh), so they stay at 16,332 (coat) and 21,242 (crate) triangles. `tools/import_new_props.py` registers a model with the scale-and-pivot import script. The usual `meshoptimizer` Python package would not build here (no compiler), which is why Godot does it. |
| Placement | `scripts/world/interior/hero_props.gd` places 24 pieces (desk, chair, cabinet, 2 beds, wardrobe, sea chest, stove, tub, mess table, telegraph, 2 lamps, 3 barrels, 3 crates, 5 coats), each on the footprint of the box it replaces, with facing and a little yaw jitter. The 71 replaced greybox nodes are only **hidden**: collision, anchors, lights and tests that name them are untouched. The generated colours are paler than the room's palette, so a darkening tint is applied. |
| Everything else that is still a box | Every furniture-scale box (0.12 to 2.6 m on every side) now has chamfered edges (`kit.gd bevel_mesh`) so the ink outlines catch a real edge: shelves, counters, benches, nightstand, basin and so on. Walls, floors and beams are left square. |
| Tests | `tools/test_hero_props.gd`: all 24 placed, none skipped, all inside the house, 418,622 triangles (limit 450,000; the first limit of 400,000 was exceeded by repeated props), largest model 24,034, replaced boxes hidden with collision kept. **15 of 15 lighthouse tests pass.** Shots `p_office`, `p_hall`, `p_quarters`, `p_mess`, `p_wash`, `p_radio`. |

### Not done / known
- Props that are still plain bevelled boxes: bookshelves (office and hall), nightstand, basin, counter, benches, the radio desk and chair, chart tables, parts shelf and the basement's other items. They look better but are not models.
- The generated oilskin coats came out as trench coats on hangers (light cream, a good look, but not oilskin), all one colour.
- The sea chest was not seen in a shot (placement and bounds pass the test).
- 24 instances at 418k triangles is heavier than I would like; Godot also generates distance LODs for each on import. A later pass can lower the repeated props.
- `prop/source/` now holds **936 MB** (the 4K originals, plus a full-detail 2K copy of each of the 14 new models, about 20 MB each). The `_full2k` copies can be deleted whenever you like; the 4K originals can regenerate them.

## Pass 6 (2026-10-24): the lamp room and gallery (LHF-13)
The lamp room was already in decent shape (glass all round, brass arc lamp, timber floor, glazing bars); what let it down was the **gallery outside** and the **lit look**.

| What | Detail |
|---|---|
| Gallery balustrade | The exterior model's rail was a ring of lumpy posts (probe: deck top at y 18.33 out to r 4.0, rail posts to y 19.3). `Level.tscn` now carves that band out (`carve_cylinders`, y 18.45 to 19.9, r 4.25: only the rail and posts live there, the deck is below it). `lantern.gd _gallery()` builds the replacement: 16 iron newel posts with brass caps and finials, a brass handrail, a mid rail, a toe board and 120 slim balusters as one MultiMesh (one draw call). Visual only; the glass is sealed and nobody goes out there. Probe: `tools/probe_gallery.gd`. |
| Lit lamp | It was a cold white that blew the lens out to flat white. Now warm gold (`lit_colour` (1.0, 0.84, 0.5), the style guide's gold): lens, core, light and spot all take it; lens emission 0.3 to 0.22 so the lens bands stay visible. |
| Beam | It was a hard capsule with a bright disc at the far mouth. The shader now fades the far end out, softens the edges where the cone leaves the eye (a facing term) and uses the gold tint. |
| Tests | 15 of 15 pass, including `test_lamp_fit` (the lens-glow threshold was calibrated to the old 0.3 energy and is checked mid-rise; I lowered it from 0.2 to 0.05 rather than undo the blow-out fix) and `test_sightlines` (the balusters have no collision). Shots `lamp3_gallery`, `lit2_in`, `lit3_sea`. |

### Notes
- The beacon's look is the Lighting agent's to own (backlog T13); this is a better-than-placeholder pass, all values exported (`lit_colour`, `lens_energy`, `beam` shader).
- The far mouth of the beam can still show faintly when it is seen end-on. The lit lamp was only shot with the shot tool's relit switch, not through the playable burner fit (the lamp-fit test covers the fit itself).

## Pass 7 (2026-10-24): per-room lighting and materials (LHF-14)
The rule: the interior may have **6 live lights at once** (`interior_lights.gd`; 2 shadow casters; the spec allows 8 dynamic lights for the scene), but the building has 40 lamps, so most are not real lights at any moment. The pass makes every lamp *read* as lit with **no extra dynamic light**.

| What | Detail |
|---|---|
| Light cards | `scripts/world/room_light_cards.gd` (node `RoomLightCards`): a stepped three-ring floor pool under all 40 lamps (found by ray to the floor), a soft halo round every bulb (a billboarded quad, so a lamp is a glowing thing, not a white disc), per-instance colour and alpha on **one shared material each**, unshaded additive, no shadows. The pool is brighter while the real light is off and fades to a faint painted edge when the real light comes on (no doubling). |
| Per-room colours | The existing lights now take room colours by name: deep orange basement and firebox, amber hall, office and stores, pale lamp in the wash room, green-grey instrument glow on the radio and L2, silver in the lamp room. |
| Window light | Cold moon-and-storm pools on the floor in front of all 8 windows and a glow in the window glass, driven by the lighting rig: the moon's strength, the phase's cloud darkness (ISLAND 0.72 against RETURN 0.40) and a white flash with every lightning bolt (reads 1.00 in a flash). |
| Materials | The plaster and whitewash base colours were lowered (0.62 to 0.5, 0.7 to 0.6) so the new light does not blow the walls to cream. |
| Test | `tools/test_room_lights.gd`: 40 pools, 40 halos, 8 window pools; **the cards add zero Light3D nodes**; window light follows the phase and flashes; room colours; **6 live and 2 shadowed with the player in the lamp-rich mess**. **16 of 16 lighthouse tests pass.** Shots `l0_*` (before), `l2_`, `l3_`, `l4_` (after) in ISLAND and RETURN. |

### Found along the way
- My first version of `test_room_lights` **passed falsely**: `await` inside a physics-process test returns early, so it quit with exit 0 after only four checks. Rewritten as a counted state machine (all eight checks now run). No older test uses that pattern.

### Not done / to look at
- The coal store shot was taken too close to the wall to judge, so the coal store, store and office were checked by the test but not by eye in RETURN.
- The ISLAND and RETURN interiors still look similar (the interior is lit by its own lamps; only the window light changes with the phase). That is by design for a building at night, but it is worth your look.
- The boiler floor pool is large and orange; it is easy to lower (`far` in `room_light_cards.gd _process`).
- The Lighting agent owns the rig; nothing in the rig was edited.

## Pass 8 (2026-10-24): architectural trim (LHF-15)
`scripts/world/interior/trim.gd` (built from `interior_rooms.gd`; 123 pieces, all non-solid, so collision and the walk route are untouched):

| Where | Trim |
|---|---|
| Ground floor | Moulded skirting (a plinth under a bead) over the panel bases on all four walls; a stepped two-strip cornice on the front and east walls (the west and back already had one); a picture rail round the hall; a door architrave (jambs and a head with a returning cap) on the storage-room doorway. |
| First floor | Skirting on the three lining walls and on **both faces of every partition** (H1, W1, W2, W3, with the doorway gaps left open); a picture rail on the mess wall; a kitchen splash back of 18 pale tiles behind the sink with a wood cap; a stone hearth under and in front of the stove. |
| Basement | Four brick piers on the west wall with stone bases and caps; a dark-stone plinth course round the walls; a cable tray with two cables and eight clips along the west wall near the ceiling; five iron brackets under the steam main; a floor drain with a five-bar grate. |

| Test | `tools/test_trim.gd`: 123 pieces, **zero collision bodies**, all inside the house, **nothing in the stairwell hole**, named pieces present. **17 of 17 lighthouse tests pass.** Shots `t1_*`, `t3_*` (hall, mess, boiler, office). |
|---|---|

### Tried and removed
- A **chimney breast** with a shelf behind the L1 stove: the stove stands clear of the east wall, so the breast read as floating. Removed (the stove pipe already rises to the ceiling).

### Not done
- **Tower rings and stair landings** (L1/L2 rings, lamp room) got no skirting or cornice; the lamp room and L2 ring already have iron rings and a ring beam.
- **Window and ceiling trim at the first floor** (architraves on the L1 window openings, an eaves cornice) were not added: the eaves are sloped and the openings sit behind the exterior kit.
- **Floor layouts:** the floors still use the old textures; no new board or flagstone patterns. Only the hearth, plinth course and drain were added.
- The picture rail and skirting are subtle in the shots (at this camera distance they read mainly through the ink outline).

## Pass 9 (2026-10-24): geometry and polygon audit (LHF-06)
New tool `LightingTheStorm/tools/audit_lighthouse.gd` (`-- json` writes `reports/lighthouse_finisher_audit.json`; `-- check` is a budget gate). It counts what is drawn: triangles, surfaces (one draw call per pass each), materials and nodes, by source and by level, and lists the biggest meshes.

### Before and after
| | Before | After |
|---|---|---|
| **Triangles drawn** | **2,535,041** | **800,627** (-68%) |
| Largest single mesh | 500,000 | 56,018 |
| Surfaces (draw calls per pass) | 1,433 | 1,433 (see below) |
| Materials | 92 | 92 |
| Nodes | 2,758 | 2,758 |
| Interior build time (repeat runs) | 0.8 s (original code) | 1.1 to 1.2 s (460 more kit nodes: trim, hero props, light cards) |

### What the audit found
**Four older generated props were never decimated: 500,000 triangles each, about 1.9 M of the 2.5 M.** The boiler, arc lamp, steam engine and **the coal shovel (a fresh 385,000-triangle copy every time the player picks up a shovelful)**. (The 14 newer props had been decimated in LHF-08.) Fixes, with the full-detail copies kept in `prop/source/`:

| Model | Triangles | Texture |
|---|---|---|
| Boiler (hero) | 500,728 to **67,676** (it looked ragged at 34,000: faceted dome, mangled gauge, so I stepped up) | 2048 |
| Arc lamp (hero) | 500,000 to **56,018** | 2048 |
| Steam engine | 499,954 to **25,140** | 1024 |
| Coal shovel | 498,784 to **19,858** | 1024 |

Each is 2 to 8 MB instead of 20 MB. The boiler and the lamp were checked in shots after decimation.

### Culling (`scripts/world/interior_culling.gd`, node `InteriorCulling`)
- The house is about 1,200 meshes over three levels; you see one or two at a time. While the camera is inside the house footprint: on the ground floor and in the basement the **first floor is hidden** (275 meshes at the moment of test; 403 with the other rules); on the first floor the ground floor and basement are hidden. The stairwell still shows the basement from the hall.
- Outside, every interior mesh stops drawing beyond 34 m, so the lighthouse seen from the sea does not pay for its furniture.
- The tower, the spiral stair, the tower lining and the lamp room are never culled (they are seen through doorways from everywhere).
- **Draw calls in the table are the scene total, not what is drawn from any one spot:** culling hides 400 to 900 meshes in each of the three levels depending on where you stand.

### Budget (a regression gate)
`audit_lighthouse.gd -- check`: triangles <= 900,000 (now 800,627), largest mesh <= 100,000 (56,018), surfaces <= 1,600 (1,433), materials <= 120 (92), nodes <= 3,200 (2,758). `tools/test_interior_culling.gd` covers the culling rules.

### Left, honestly
- **Hero props are now the biggest share: 418,622 of the 800,627 triangles** (24 pieces at 9,000 to 24,000 each). Godot's decimation steps in halves from 9,000 up, so a smaller repeated prop (a coat, a crate) cannot go below about 9,000 without a different tool.
- **No static-mesh merging by material or MultiMesh for the box props** (the kit's 740 meshes still render as 740 draw calls when visible). Culling halves what is visible; merging would need collision and interaction nodes untangled from the visuals and was not started.
- I only measured triangles and draw calls from mesh data. **No frame-time or load-time measurement on a real GPU**; headless cannot give one. `measure_load_time` was not re-run.
- 18 of 18 lighthouse tests pass after these changes.

## Pass 10 (2026-10-25): the creator's 15-point playtest feedback
All fixed or mostly fixed; see the STATUS table in `reports/lighthouse_finisher_feedback_2026-10-24.md`. Root causes worth keeping in mind: (1) interior_culling.gd filed levels by mesh centre (hid the L1 floor); (2) the bevelled-box face triangulation left a wedge out of every box; (3) house reveal boxes were deeper than the real wall; (4) masonry patches must be wound clockwise into the wall for Godot; (5) the tower radius table has gaps (-1) in the carved clearing. Tests: **18 of 18 pass** plus `audit_lighthouse.gd -- check` (798,885 triangles, 1,473 surfaces, 95 materials, 2,805 nodes); `test_stair_spec` now also checks the landing step, wall fills and the removed pole.

## Pass 11 (2026-10-25): round-3 feedback (items 16 to 21)
See the round-3 table in `reports/lighthouse_finisher_feedback_2026-10-24.md`. New tests: the fill, fog and lens exclusion (`test_toon_look`), the facade, doorway reveals and panelling depth (`test_openings`), the L2 ring and attic rain cover (`test_rain_shelter`). **18 of 18 pass**; audit gate 799,030 triangles, 1,481 surfaces, 96 materials, 2,822 nodes.

## Tests after pass 9
test_interior_anchors, test_interior_walk, test_coal_job, test_lamp_fit, test_sightlines, test_spiral_down, test_door, test_interior_lights, test_interior_budget, test_rain_shelter, test_roof_liner, test_stair_spec, test_toon_look, test_openings, test_hero_props, test_room_lights, test_trim, test_interior_culling: **18 of 18 pass.** (test_interior_budget failed once at 3.2 s against a 2.5 s limit while the machine was busy, and also failed with these changes stashed; it passes at 12 s on a quiet machine.)

## Not started
LHF-06, 07, 08 (props), 10 (cel look sample), 11 (walls), 12 to 18. Still open from the earlier list: the 4096-to-2048 and polygon audit, and per-room tri counts for the baseline.

## Pass 12 (2026-10-27, branch Tuesday27): playtest fixes, clean-up and the final round (LHF-16 to 18)

### What changed (one commit each, `git log d94b480..0ccae52`)
| Commit | Change |
|---|---|
| 2dc22d5 | The authored shell (`Assets/Models/lighthouse/shell/`) and every shell-only code path deleted; `shell_spec.json` kept (wall_patch, repair_exterior read it). Ground-floor window over the dock **closed** (creator): inside, a stretched copy of the greybox lintel; outside, the hole through the chimney breast filled flat in the chimney's stone. Scan shards cut out of the tower windows. `audit_clipping` check B fixed: it found no exterior under v4 and was passing on nothing. |
| 1507a1b | Dark spikes beside the L2 window: ink on creases in the tower lining, where unmeasured cells of `tower_radii.json` took the smallest radius nearby. `tower_shell.wall_radius` now blends along the row. |
| 1e7ac5b | Props resized and spaced (filing cabinet 1.25 m, telegraph 0.38 m, barrels 0.47 m, three coats instead of five, chair out of the desk). Tower window surrounds measured past the lining with the true radius (they sat inside the wall), curve-aware stone depth. |
| 0832261 | Back windows 1.0 m tall (were 0.8). Hole fills coloured from wall faces, not roof faces. West gable lining built in strips under the sloping ceiling. |
| 1490da9 | The scan has no wall at the back-west corner of the first floor: two flat panels close it (plain render; a texture copy from the neighbouring wall came out as a collage and was dropped). |
| d6c4245 | The scan's lantern roof hung inside the lamp-room drum, through the ceiling between the rafters: removed. |
| 2da7a49 | Plaster, dark plaster and whitewash warmed from neutral grey to a lime cream (the grey, washed-out plaster item). |
| 0ccae52 | Every exterior triangle with a corner inside the first floor's rooms removed, fills included (the brown flaps under the back-west ceiling, triangles through the floor). Beds turned along the gable wall (they lay across the room, head in the wall). Front-door fanlight brought forward so the lintel and the scan wall no longer hide it. `audit_clipping` boxes props in the house frame. |

`lighthouse_exterior_v4.glb` is now **generated** by `Assets/Models/lighthouse/repair/repair_exterior.py` (Blender 5.2, `blender -b -P repair_exterior.py`): edit the script, not the .glb. After a rebuild: Godot `--import`, `tools/bake_colliders.gd`, `tools/bake_tower_radii.gd`.

### LHF-16 regression
- **19 of 19 lighthouse tests pass**; `audit_lighthouse -- check` passes: 766,825 triangles (limit 900k), 1,473 draw calls (1,600), 101 materials (120).
- Clipping audit (`reports/lighthouse_clipping_audit.json`), morning to end of day: A outside the walls 4 to **0**; B interior meshes crossing the exterior 63 to **30**; C prop overlaps 10 to **0**; D1 prop sizes 10 to **0**; D2 doorways pass; D3 windows 2 to **0**.
- **Visual regression** (new): `tools/lighthouse_views.json`, 18 fixed cameras (14 rooms, 4 outside). Run `SHOT_INTERIOR=1 SHOT_FRAMES=40 python tools/visual_check.py --views tools/lighthouse_views.json`. **17 of 18 pass.** `lh_out_front` fails at 48% flat-dark: the front facade in night shadow (picture checked: intact, fanlight lit). It is the check's known weakness with shadowed walls, not a hole.

### LHF-17 offline checks
- `main_asset.py sample_submissions/lighthouse_interior --check-only`: **19 of 19 approved**. No new FAL submissions today ($0 spent; $5.25 of $7.80 used in total).
- Canon and Review Orchestrator offline (`main.py --offline`, output to a scratch folder): **PASS**, 4 of 4 pillar checks. It reviews the crossing game data; it does not look at the lighthouse.
- **Interior assessor: 9/10, zero BLOCK** (baseline: LIG-03 failing, no route/sightline/clipping proof). REVISE: clipping B (30 meshes); LIG-03 still fails, Level.tscn has 15 OmniLight3D nodes against a limit of 8 (runtime budget passes: at most 6 lit); the corner panel needs stone. NOTE: `Parameter "m" is null` log noise; test_interior_budget's wording "39 of 25"; G_window_view_marker still a walk target behind the closed window; a small dark notch at the lamp-room glass ring.
- **Exterior assessor: 7/10, zero BLOCK** (baseline v3 passed 4 of 4; v4 passes 3 of 4). REVISE: the corner panels read as a flat pale box from the back; v4 has 44 open loops where the check allows 0, about 18 real openings and about 26 pinholes and slivers (a ring at the lantern deck, 18.2 to 18.5 m); the tan fill triangles under the back windows; clipping B. NOTE: do not add an import script to v4 (its 34.3 scale is baked in). Not verified offline: the closed chimney window from outside, the sea silhouette per phase with v4, day lighting.

### LHF-18 fallbacks
- `LHF_EXTERIOR=v3` still loads the original exterior with its run-time carves (`collider_builder.gd`).
- Every earlier v4 is in git history: the 26 Oct original is `git show d94b480:LightingTheStorm/Assets/Models/lighthouse/lighthouse_exterior_v4.glb`. Not copied as files (9 MB each, and the creator is keeping the push small).
- The FAL originals are in `C:\bkupConceptArt\FAL_3D_Models`.

### Left, honestly
- Two small exterior slivers at the back-west corner of the first-floor ceiling.
- The closed corner and some hole fills are flat single-colour patches (the tan triangles under the back windows), not textured stone.
- A grey rectangle on the west wall beside the chimney (there before today).
- B: 30 interior meshes still cross the exterior mesh: window reveal edges, the lamp room's rings at the glass, L1 lining strips and skirting. None was seen in the renders.
- Only the Godot editor or a playtest can judge: the plaster colour, the flat patches at a distance, and the fanlight's glow in play.
