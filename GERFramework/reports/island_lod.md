# ISL-09: Bracken Isle at distance (visibility ranges and LOD)

Island Creator Agent, 2 Nov 2026. Branch Monday2ndWork. Priority 3 (lowered by the creator on 27 Oct), so kept lean.

## What the camera actually sees the island from

| View | Distance from the lighthouse | Notes |
|---|---|---|
| Walking the island | 0 to about 75 m | the far corners of the rock are 73 m from the tower, 82 m from the gate |
| Berthing at the island dock (-27, 18) | 35 to 50 m | |
| Return crossing (data/world/ship_route.json: Saltgate dock (6, 531) to island dock (-27, 18), straight line) | 530 m down to 45 m | RETURN fog 0.014 |
| The Saltgate quay, looking back | about 547 m | OUTBOUND fog 0.008, BEACON_RELIT 0.012. Not 1.5 km: the Saltgate is 540 m south of the lighthouse |

## The 27 Oct finding (RockPatch nodes were full island copies)

No longer true. RockPatchSE, RockPatchSE2 and RockPatchNE now load `Assets/Models/island/rock_patch.glb` (its own small model, not
island_craggy.glb). They keep their import LODs and cost 300 primitives each per pass at 530 m (8,320 at 80 m). Nothing to do.

## What made the island expensive (measured before any change)

`tools/measure_island_cost.gd` (needs a window, 1600 x 900, vsync off): a free camera at boat eye height (3 m) on the return line, looking
at the tower, RETURN phase, lightning flashes held off; plus the Saltgate quay (7 m) in OUTBOUND and BEACON_RELIT. Each point reads the
Performance monitors (all passes, shadow cascades included, so a mesh in 2 to 5 passes counts 2 to 5 times), then hides the island and
reads again; the difference is the island's share. With `breakdown` it hides each island node in turn.

At 530 m the island was 1,568 of the frame's 1,768 draw calls. By node (draw calls / primitives at 530 m):

| Node | Draws | Prims | What it is |
|---|---|---|---|
| InteriorRooms | 868 | 273,154 | the tower lining (TowerShell, 216 meshes) and spiral stair (SpiralDown, 84) had no range at all; plus the lamp room |
| IslandGate | 270 | 30,082 | 135 meshes: the gate and its side walls |
| Lighthouse | 150 | 73,214 | the exterior shell plus 74 window-surround pieces (exterior_openings.gd) |
| LighthouseDoor | 142 | 9,872 | 71 planks |
| LighthouseInterior | 120 | 968 | 60 greybox meshes |
| Island (the rock) | 2 | 369,782 | 185k triangles per pass at every distance: the carve and flatten rebuild the mesh and drop its import LODs |
| Lampposts | 4 | 81,768 | |
| Harbour, HarbourStairs | 4 | 111,088 | |

## What was changed

1. **The rock's LODs are back.** `scripts/world/collider_builder.gd`: new export `keep_lods` (default off). When on, a mesh that is
   flattened or carved gets LODs generated again (ImporterMesh.generate_lods, merge 60 degrees, split 180 so no vertex is split and the
   LODs index the baked arrays), stored in the collider bake and applied on load (no runtime cost; generation is about 1 s, in the bake
   tool only). Only the Island node has it on (`keep_lods = true` in Level.tscn), and the bake key only changes when it is on, so no
   other node's bake changed. LODs: 185k (full), 91,003 and 22,751 triangles.
2. **The rock uses them at sea distances.** At Godot's default lod_bias the coarsest LOD (error about 2.5 m) stays above the 1-pixel
   threshold until about 1.5 km, so it was never used. `scripts/world/island_lod.gd` sets lod_bias 0.3 on the rock: full detail inside
   about 300 m, 91k at 400 to 530 m, 22.7k from the Saltgate quay. The island walk and the berth always get full detail.
3. **Visibility ranges on the small pieces.** `scripts/world/island_lod.gd` (new node `IslandLOD` in Level.tscn, after Lampposts) waits
   4 physics frames for the builders, then gives a range to every piece that has none under:
   - InteriorRooms/TowerShell, InteriorRooms/SpiralDown, LighthouseInterior: end 100 m, margin 12 m, no fade (only seen through windows);
   - LighthouseDoor, IslandGate: end 150 m, margin 12 m, fade (they dissolve rather than pop).
   Never ranged, whatever group: anything whose bounds reach above 27 m (the lamp room floor), anything under /LampRoom/ or /BeamPivot/,
   the lighthouse_exterior shell, and anything that glows (unshaded, emission energy 0.25 or more, or a ShaderMaterial it cannot read).
   toon_look.gd's indoor fill (emission 0.05) does not count as a glow. Pieces that already have a range (interior_culling.gd's 34 m
   house rooms) are left alone. 704 pieces get a range.
4. Tried and backed out: the lamp post models at 150 m. Hiding the post uncovered its glowing head, which the lantern had hidden from
   some angles (a new warm dot at 150 to 200 m), for 4 to 7 draw calls. Not worth a visible change; the posts keep no range.

Not changed: the rock patches, the harbour, the harbour stairs (hiding them would show the trench carved for them), the lighthouse
shell and its window surrounds, the lamp room, the beam, the lights, island materials, the lighting rig.

## Before and after (draw calls / primitives, whole frame; island share in brackets)

| Point | Phase | Draws before | Draws after | Prims before | Prims after |
|---|---|---|---|---|---|
| return, 530 m | RETURN | 1,768 (1,568) | 680 (480) | 5.63 M (953k) | 5.38 M (705k) |
| return, 400 m | RETURN | 2,558 (2,349) | 929 (720) | 4.71 M (1.52 M) | 4.34 M (1.15 M) |
| return, 300 m | RETURN | 2,536 (2,348) | 907 (719) | 4.08 M (1.52 M) | 3.99 M (1.43 M) |
| return, 200 m | RETURN | 3,049 (2,849) | 1,155 (955) | 3.85 M (2.11 M) | 3.74 M (2.00 M) |
| return, 130 m | RETURN | 3,643 (3,458) | 2,177 (1,992) | 3.76 M (2.57 M) | 3.72 M (2.52 M) |
| return, 80 m | RETURN | 4,124 (3,910) | 4,124 (3,910) | 3.89 M (2.83 M) | 3.89 M (2.83 M) |
| return, 47 m | RETURN | 4,117 (3,902) | 4,117 (3,902) | 3.96 M (2.77 M) | 3.96 M (2.77 M) |
| Saltgate quay, 547 m | OUTBOUND | 1,774 (1,569) | 688 (483) | 5.55 M (1.01 M) | 5.16 M (628k) |
| Saltgate quay, 547 m | BEACON_RELIT | 1,782 (1,569) | 696 (483) | 5.55 M (1.01 M) | 5.16 M (628k) |

The rock alone: 369,782 primitives at 530 m before, 182,006 after; from the Saltgate quay 369,782 before, 45,502 after.

Render time on this machine (GPU, ms, whole frame): before 2.10 / 1.99 / 1.94 / 2.08 / 2.06 / 2.01 from 400 m to 47 m, after
1.89 / 1.82 / 1.81 / 1.93 / 1.96 / 1.90; Saltgate quay 2.25 before, 2.05 after. The first point (530 m) reads about 3.5 ms in every run,
before and after: it is the first frame sampled after load (warm-up), not the island. CPU render time at the Saltgate: 0.64 ms before,
0.45 ms after. This GPU is fast, so the time saving is small here; the draw-call saving (69 per cent of the island's share at sea
distances) is what carries to slower machines.

Acceptance:
- **Frame cost does not rise as the island comes into view.** From the Saltgate (547 m) in to 200 m the whole frame is now 680 to 1,155
  draw calls, against 1,768 to 3,049 before, and GPU time is flat at 1.8 to 2.0 ms from 400 m to the berth. The cost does rise inside
  about 130 m, where the gate, the door and the tower's insides are close enough to see; inside 80 m nothing changed (by design: the walk
  and the berth are untouched).
- **Silhouette unchanged.** Before/after crops, enlarged, top before and bottom after: `GERFramework/reports/isl09_shots/isl09_compare_*.png`
  (530, 400, 300, 200, 130 and 80 m on the return; the Saltgate quay in OUTBOUND and BEACON_RELIT). Read by eye: the rock outline, the
  tower, the lamp room and the sea stacks match at every point. Pixel difference in the island crop: 0.03 to 0.6 per cent of pixels
  differ by more than 24 levels, the same as the 80 m point where nothing changed (rain, spray particles and cloud drift between runs).
  Full frames: `isl09_before_*.png`, `isl09_after_*.png`.

## Tests

All headless (`Godot --headless --path LightingTheStorm --script res://tools/<test>.gd`), 2 Nov 2026, after the change:

| Test | Result |
|---|---|
| tools/test_island_lod.gd (new) | ALL PASSED, 21 checks: IslandLOD applied (704 pieces ranged); the rock has LODs and lod_bias 0.3; no range under 600 m on the rock, the 3 rock patches, the harbour, the harbour stairs, the lamp posts, the lighthouse shell, the lamp room, the beam or any of 264 glowing/landmark pieces; gate 135/135, door 71/71, TowerShell 311/318, SpiralDown 133/133 ranged, none under 100 m |
| tools/test_island_coverage.gd | PASS (exit 0): dock-to-door route 0 fall-through and 0 invisible-wall clusters (lone points 0, 6; whole island 1, 200, as before: collision is untouched) |
| tools/test_island_walk.gd | exit 0, all four routes REACHED THE END |
| tools/test_slice_playthrough.gd | RESULT: OK (0 failed), all 25 story events in order |
| tools/test_collider_bake.gd | RESULT: OK: every builder found its bake; 32 nodes match a live build (the island's LODs regenerate identically) |
| tools/test_interior_culling.gd | ALL PASSED (the house's own 34 m culling is untouched) |
| tools/measure_load_time.gd -- island (ISL-03) | 0.79 to 0.80 s to the second frame (ISL-03 recorded 0.94 s on 27 Oct; budget 2 s): applying the baked LODs costs nothing measurable |

The headless runs print about 1,900 `Parameter "m" is null` errors from the dummy renderer; they are the same count with the IslandLOD node
removed, so they predate this work.

## Findings for other agents (not changed here)

- **Lighting agent / Lighthouse Finisher: the lamp room is the biggest cost left at sea distances.** InteriorRooms/LampRoom (87 meshes
  plus 51 in the gallery) is 288 draw calls and 252,842 primitives at 530 m (about 126k triangles per pass) with no LODs. It must stay
  visible (it is the landmark), but its lens or lamp model could have LODs or a decimated copy beyond about 100 m.
- **Lighthouse Finisher: 74 window-surround pieces** (Lighthouse/T_*_Kit, exterior_openings.gd) are 150 draws at 530 m. They use a
  ShaderMaterial, so island_lod.gd leaves them alone; a range of about 200 m with fade, or merging each kit into one mesh, would remove
  most of that.
- **Lighting agent: four tower lamp glasses** (InteriorRooms/TowerLandings/*_Glass) glow but interior_culling.gd stops them at 34 m. If the
  tower windows are meant to glow from the sea, that range hides them; if the glow comes from the lit-window cards, nothing to do.
- **Lighting agent: the beam was not visible in the BEACON_RELIT stills** (before or after). Setting the rig's phase does not light the
  lamp; the beam is driven by the lamp beacon in play. test_island_lod.gd proves the beam and the lamp room have no visibility range, so
  ISL-09 cannot hide it, but a still of the lit beam from the Saltgate needs the real relit state.

## For the creator

- The collider bake for the island has a new name: `Assets/Baked/colliders/island_craggy_7f5ae75025b5.res` (6.7 MB, was 6.2 MB) replaces
  `island_craggy_946838846d0d.res`, which the bake tool deleted as unused (it is still in git at HEAD). No other bake file changed.
  To go back: set `keep_lods = false` on the Island node and restore the old file from git (or re-run tools/bake_colliders.gd).
- No .import file was touched and nothing was reimported. No FAL spend. Nothing committed.
- Only a human can check: the fade of the gate and the door at 150 m while sailing away (the stills are static), and how the LOD switch on
  the rock at about 300 m looks in motion (on this screen it is under 4 pixels and in heavy fog).
