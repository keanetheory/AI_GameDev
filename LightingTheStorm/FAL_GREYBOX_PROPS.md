# Lighthouse greybox props, pass 2: inventory and FAL prep

2 November 2026. Written after the creator's basement play check: "smoke looks good and the ceiling no longer flickers, but you've added greyboxes in, list them and prep them for a FAL run, make sure you cover the other props as well".

**Nothing has been sent to FAL and no credits were spent.** The 15 submissions below are drafted and pass `main_asset.py --check-only`. The creator decides the spend. The first pass (T45, 1 Nov) is in `LIGHTHOUSE_GREYBOX_PROPS.md` and `HANDOFF_T42_T43_T45_FALProps.md`.

## What the basement check found

- **No new greybox was added on 2 Nov.** Commit 9f367db (smoke, ceiling flicker) added only `B_BoilerSmoke` and `B_EngineSmoke` (cel smoke cards from `machine_smoke.gd`), plus a carve box on the steam engine. Neither is a box prop.
- **The three named examples are already FAL models.** `B_Switchboard` (with its dials, lamps and knife switch), `B_ToolRack` and `B_LobbyBarrel` are replaced in place by `lhi_switchboard`, `lhi_tool_wall` and `lhi_oak_barrel` (`hero_props.gd` IN_PLACE, lines 54-61). I ran `tools/test_hero_props.gd` today and it passes: "68 of 68 placed, 279 greybox nodes hidden, skipped: []". If the creator still sees boxes in those spots, the cause is how the model looks or where it sits, not a missing model. Likely causes: the Blender collapse to 1.5-3.5k triangles can look blocky up close, the fit may be wrong, or a kept part may poke through (see "Kept parts that may show through"). **A screenshot from the creator of what reads as a greybox would settle it.** Nobody has checked the 30 in-place props room by room in play (handoff section 5).
- **The basement greyboxes still visible on the route** are these: the four oilskins and their pegs at the foot of the stairs (`B_Oilskin_0-3`, which the T45 plan said to reuse a model for but which never got a `hero_props` entry), the pressure gauge's brass rim, the coal bin front and its posts, the three wall-void grilles, and the four valve wheels overhead.

## Budgets measured today (before any new prop)

`tools/audit_lighthouse.gd -- check`, run 2 Nov at 0f1b07b with the working tree as it is:

| Budget | Now | Limit | Headroom |
|---|---|---|---|
| Triangles (visible) | 884,047 | 900,000 | **15,953** |
| Surfaces | 1,329 | 1,600 | 271 |
| Nodes | 2,958 | 3,200 | 242 |
| Materials | **126** | 120 | **FAIL, already 6 over** (the handoff recorded 120 on 2 Nov morning; the smoke cards added the rest) |

Every new model adds at least one material, because `hero_props._tint` makes one tinted copy per source material. **Materials must be decided before any install** (see the creator decisions at the end). Triangles: P1 and P2 fit in the 15,953 headroom only at the small per-model targets in the generation table. P3 needs the limit raised or other props decimated harder. The audit counts only visible meshes, so the hidden greyboxes free a few hundred triangles.

## 1. Inventory

Sizes are the greybox bounds in metres (width x height x depth, or diameter). Status: **FAL** = a generated model already stands there (hidden greybox, collision kept); **GREYBOX** = still drawn from primitives; **KEEP** = a primitive that stays (effect, pipework, decal or gameplay geometry). "Code/tests" lists every script or test outside the builder that names the node (from grepping `scripts/`, `tools/`, `data/` and `scenes/`).

### Basement (B1): `scripts/world/interior/rooms_house.gd` `_basement()`

| # | Node(s) | File:line | Size (m) | What it is | Code/tests that use it | Status / model |
|---|---|---|---|---|---|---|
| B1 | `B_Oilskin_0-3`, `B_OilskinPeg_0-3` | rooms_house.gd:370-371 | 4 x (0.27 x 0.95 x 0.12) | oilskin coats on pegs, foot of the stairs (lobby) | none | **GREYBOX**: free reuse of `lhi_oilskin_coat` |
| B2 | `B_BoilerGauge` > `B_GaugeRim`, `B_GaugeFace`, `Needle/NeedleBar`; `B_GaugePlate` | rooms_house.gd:333-345 | rim 0.4 dia x 0.06; plate 0.34 x 0.1 | the boiler pressure gauge the coal job drives | **boiler_gauge.gd** turns `Needle`; **coal_job.gd** `gauge.set_level`; test_coal_job.gd checks `gauge.level` (0.5, 1.0); audit_clipping.gd skips `NeedleBar` | **GREYBOX** (rim): new `lhi_pressure_gauge`. Face, needle and plate stay |
| B3 | `B_CoalBinFront`, `B_CoalBinPost_0-3` | rooms_house.gd:296-298 | 1.85 x 1.2 x 0.26 (front is solid) | timber front of the coal bin | none by name (CoalHeapInteract stands behind it) | **GREYBOX**: new `lhi_coal_bin_front` |
| B4 | `B_WallVoid_West/Front/East` `_Hole` + `_Bar0-4`, marker `LHI_WallVoid_*`, `Zone_B_WallVoid_*` | rooms_house.gd:258-276, 406-408 | 0.6 x 0.8 grille | iron grilles over the crawlspace voids (bang/whisper/talk sound sources) | **test_coal_job.gd** finds `Zone_B_WallVoid_West`; group `lhi_wall_void`; events BASEMENT_BANG / WALL_WHISPER_HEARD / BASEMENT_TALK | **GREYBOX** (bars): new `lhi_wall_grille`, shared with G4 |
| B5 | `B_ValveWheel_0-2` + `B_ValveStem_0-2`, `B_ValveWheel_Eng` | rooms_house.gd:355-358 | wheel 0.2 dia (0.22 Eng) | handwheels on the steam main, overhead at about 2.45 m | none | **GREYBOX**: new `lhi_valve_wheel` |
| B6 | `B_Switchboard`, `_Dial_0-2`, `_Lamp_Green`, `_Lamp_Red`, `_Knife` | rooms_house.gd:382-387 | 0.15 x 1.1 x 0.8 | the switchboard by the engine | **coal_job.gd** `green_lamp` (sets it visible and lit); test_coal_job.gd "the switchboard lamp is wired"; test_interior_culling.gd checks `B_Switchboard` stays hidden | **FAL** `lhi_switchboard` (hero_props.gd:54) |
| B7 | `B_ToolRack` | rooms_house.gd:373 | 0.1 x 1.0 x 0.8 | tool rack on the west wall | none | **FAL** `lhi_tool_wall` (hero_props.gd:57) |
| B8 | `B_LobbyBarrel` | rooms_house.gd:372 | 0.56 dia x 0.85 (solid) | barrel in the lobby (Daniel walks round it) | sailors_sequence path only, by position | **FAL** `lhi_oak_barrel` (hero_props.gd:61) |
| B9 | `B_LobbyBench` | rooms_house.gd:368 | 1.4 x 0.5 x 0.45 | lobby bench | none | **FAL** `lhi_mess_bench` (hero_props.gd:60) |
| B10 | `B_WorkBench`, `B_BenchTop`, `B_Vice` | rooms_house.gd:390-392 | 1.44 x 0.9 x 0.44 | workbench with vice | none | **FAL** `lhi_workbench_vice` (hero_props.gd:55) |
| B11 | `B_ToolBoard`, `B_Tool_0-6` | rooms_house.gd:393-395 | 1.5 x 0.9 board | tool wall over the bench | none | **FAL** `lhi_tool_wall` (hero_props.gd:56) |
| B12 | `B_PartsShelf_0-2`, `B_PartsPost_0-1`, `B_Part_0-7` | rooms_house.gd:396-403 | 1.0 x 1.9 x 0.48 | spare-parts shelf | none | **FAL** `lhi_parts_shelf` (hero_props.gd:58) |
| B13 | `B_Cistern`, `B_CisternStrap_0-2`, `B_CisternFeed` | rooms_house.gd:360-363 | 1.9 long x 0.6 dia | water cistern and feed pipe | none | **FAL** `lhi_water_cistern` (hero_props.gd:59) |
| B14 | `B_Sconce_Boiler/Lobby/Engine` (`_Plate`, `_Glass`, `_Light`) | rooms_house.gd:229-237, 365-366, 388 | 0.2 x 0.3 x 0.2 | wall lamps | `_Glass` keyed by room_light_cards / interior_lights | **FAL** `lhi_wall_sconce` (hero_props.gd:99) |
| B15 | `B_Boiler` | rooms_house.gd:303 | 1.5 x 2.25 x 1.5 | boiler | coal_job (firebox) | **FAL** `lhi_boiler` (K.model) |
| B16 | `B_SteamEngine` | rooms_house.gd:378 | 1.35 x 1.3 x 2.0 | steam engine and dynamo | coal_job `engine_smoke` | **FAL** `lhi_steam_engine` (K.model) |
| B17 | `B_Shovel` | rooms_house.gd:301 | 1.0 | coal shovel in the heap | coal_job shovel template | **FAL** `lhi_coal_shovel` |
| B18 | Daniel's chair | sailors_sequence.gd / sailors_sequence.json `daniel_chair` | | Daniel's seat at the boiler | test_sailors_sequence.gd | **FAL** `lhi_daniel_chair` |
| B19 | `B_CoalHeap` (MultiMesh, 190 lumps), `B_CoalHeap_Core` | rooms_house.gd:299-300 | 1.0 x 1.05 x 1.7 | the coal heap | **coal_pile.gd** (CoalHeapInteract) | KEEP: procedural, reads as coal |
| B20 | `B_FireFrame_L/R/Head/Sill`, `B_FireRecess`, `B_FireDoorGlow` | rooms_house.gd:312-321 | 0.94 x 1.45 opening | firebox surround, recess, coal bed | **coal_job.gd** drives `fire_glow` emission; **fire_flame.gd**; **test_toon_look.gd** samples `B_FireFrame_L` | KEEP: coal-job geometry. A FAL frame would fill the opening |
| B21 | `B_Flue` | rooms_house.gd:308 | 0.28 dia x 0.4 | boiler flue to the ceiling | none | KEEP (pipework) |
| B22 | `B_Pipe_0/1`, `B_SteamMain`, `B_LagBand_0-13`, `B_Drop`, `B_RunDown`, `B_RunIn` | rooms_house.gd:345-354 | 6.6 m run | steam main | none | KEEP (pipework run) |

Basement structure that is left out: joists, coal-store walls and lintel, piers, plinths, cable tray, cables, clips, brackets and drain (`trim.gd:136-160`).

### Ground floor (G): `rooms_house.gd` `_ground()`, `_office()`, `_storage()`

| # | Node(s) | File:line | Size (m) | What it is | Code/tests | Status / model |
|---|---|---|---|---|---|---|
| G1 | `G_Coat_0-4`, `G_CoatCollar_0-4` | rooms_house.gd:75-80 | 0.34 x 1.25 each | coats by the door | none | **FAL** `lhi_oilskin_coat` x3 (hero_props.gd:43-45) |
| G2 | `G_BootBench`, `G_Boots_0-1`; `G_UmbrellaStand`, `G_Umbrella_0-1`; `G_NoticeBoard` | rooms_house.gd:81-87, 97 | 2.4 x 0.42 x 0.4; 0.26 x 1.2; 1.0 x 1.05 | hall furniture | none | **FAL** boot bench, umbrella stand, notice board (hero_props.gd:66-68) |
| G3 | `G_Sconce_Front0/1`, `G_Sconce_Tower` | rooms_house.gd:89-91, 112 | 0.2 x 0.3 | wall lamps | light cards | **FAL** `lhi_wall_sconce` |
| G4 | `G_WallVoid_West/East` `_Hole` + `_Bar0-4` | rooms_house.gd:116-117 | 0.5 x 0.7 grille | panelling voids (Ted: "only the wind") | **test_coal_job.gd** `Zone_G_WallVoid_West`; WALL_WHISPER_HEARD | **GREYBOX** (bars): `lhi_wall_grille` (with B4) |
| G5 | `Office_Ledger` | rooms_house.gd:127 | 0.25 x 0.06 x 0.35 | logbook on the keeper's desk | none | **GREYBOX**: new `lhi_ledger_book` |
| G6 | `Office_Blotter` | rooms_house.gd:126 | 0.6 x 0.015 x 0.35 | desk blotter | none | KEEP (flat) |
| G7 | desk, chair, filing cabinet, desk lamp, bookcase (87 meshes), chart table, clock | rooms_house.gd:122-163 | | office furniture | test_hero_props.gd (`Office_DeskTop` hidden, body kept) | **FAL** (hero_props.gd:22-24, 33, 63-65) |
| G8 | `Store_Rope` | rooms_house.gd:191 | 0.56 dia x 0.2 | rope coil in the store | none | **GREYBOX**: new `lhi_rope_coil` |
| G9 | `Store_Bulb`, `Store_Hanging_Light` | rooms_house.gd:192-193 | 0.14 bulb on a 0.45 flex | bare bulb in the store | `Store_Light` is its light | **GREYBOX**: free reuse of `lhi_pendant_lamp` (see install plan) |
| G10 | `Store_Barrel_0-2`, `Store_Crate_0-2`, `Store_ShelfBoard/Post/Tin` | rooms_house.gd:181-190 | | store goods | test_hero_props.gd (`Store_Crate_0`) | **FAL** barrels, crates, store shelf |
| - | KEEP: `G_CoatRail` (rail under the FAL coats), the posters (`Poster_*`, interactive, FAL-made textures), `G_Notice_*`, `G_Tidetable`, `Office_Chart`, `Office_ChartPin`, `Store_Sign` (paper sheets), the rugs and door mat | | | | posters: poster.gd, POSTER_EXAMINED | KEEP |

Ground-floor structure that is left out: ceiling, beams, panelling, cornices, door jambs, lintel and threshold, store walls and jambs, stair rails, the tower door frame.

### First floor (L1, keeper's quarters): `scripts/world/interior/rooms_tower.gd` `_l1_house()`

| # | Node(s) | File:line | Size (m) | What it is | Code/tests | Status / model |
|---|---|---|---|---|---|---|
| L1 | `L1_KitchenShelf_0-1`, `L1_Pot_0-5` | rooms_tower.gd:179-182 | 0.3 x 0.6 x 1.7 | two kitchen shelves with pots | none | **GREYBOX**: new `lhi_pot_shelf` |
| L2 | `L1_MugS_0-3` | rooms_tower.gd:168-169 | 0.08 dia x 0.08 each | mugs on the mess table | none | **GREYBOX**: new `lhi_tin_mug` |
| L3 | `L1_Shelf_Bed`, `L1_Book_0-4` | rooms_tower.gd:217-219 | 0.29 x 0.3 x 1.0 | book shelf over the beds | none | **GREYBOX**: new `lhi_wall_shelf_books` |
| L4 | `L1_Linen_0-8` | rooms_tower.gd:92-94 | 9 x (0.24 x 0.26 x 0.35) | folded linen on the hall shelf | none | **GREYBOX**. The shelf under it is now `lhi_store_shelf` (hero_props.gd:79), so the boxes sit in the model's own shelves. Hide them (free) or new `lhi_linen_stack` |
| L5 | `L1_Mirror` | rooms_tower.gd:156 | 0.4 x 0.55 | wash-room mirror (a flat sheet) | none | **GREYBOX**: new `lhi_wall_mirror` (low value) |
| L6 | `L1_TubTap` | rooms_tower.gd:152 | 0.05 x 0.2 | tap rod by the FAL tub | none | GREYBOX: hide it (the tub model has its own taps; free) |
| L7 | `L1_StoveGlow` | rooms_tower.gd:172 | 0.03 x 0.2 x 0.3 | emissive firebox glow on the stove | `L1_StoveLight` beside it | KEEP. Check that it sits on the FAL stove's door, not in front of it |
| L8 | beds, nightstand, night lamp, wardrobe, sea chest, stove, tub, washstand, counter, mess table, benches, radio desk, telegraph, radio chair, chart table, mess clock, hall shelf, Ted's coat, 6 pendant lamps | rooms_tower.gd:89-216 | | quarters furniture | test_hero_props.gd (`L1_Wardrobe`, `L1_Stove`); test_interior_culling.gd (`L1_Tub`, `L1_TubInside`, `L1_TowelRail`) | **FAL** (hero_props.gd:25-34, 71-81, 102-103) |
| - | KEEP: `L1_Hook_0-3` (pegs under Ted's coat), `L1_StovePipe`, the paper sheets (`L1_Photo`, `L1_RadioLog`, `L1_Chart`, `L1_Rules`, `L1_Calendar`, `L1_Barometer_Note`), the rugs | | | | | KEEP |

L1 structure that is left out: floor, linings, lintels, collars, skirting, door frames, tower door cap, window kits, ceiling, rafters, ridge, tiles, hearth (`trim.gd`).

### Tower landings and lamp room: `rooms_tower.gd`, `lantern.gd`

| # | Node(s) | File:line | Size (m) | What it is | Code/tests | Status / model |
|---|---|---|---|---|---|---|
| T1 | `L1_Hose` | rooms_tower.gd:483 | 0.6 dia x 0.12 | hose coil on the L1 tower ring, on the climb | none | **GREYBOX**: new `lhi_fire_hose_coil` |
| T2 | `L2_Barograph` | rooms_tower.gd:501 | 0.45 x 0.2 x 0.18 | barograph on the L2 instrument table | none | **GREYBOX**: new `lhi_barograph` |
| T3 | `L2_WaterCan` | rooms_tower.gd:508 | 0.55 x 0.7 x 0.2 (solid) | water can by the L2 wall | none | **GREYBOX**: new `lhi_water_can` |
| T4 | `L2_Rope` | rooms_tower.gd:510 | 0.36 dia x 0.14 | rope coil on the L2 landing | none | **GREYBOX**: `lhi_rope_coil` (with G8) |
| T5 | `L2_Cabinet` (+ dials, lamps, switch), `L2_Locker`, `L2_Table`, `L2_Barometer`, `L2_LampA/B`, `G_TowerLamp`, `L1_TowerLamp` | rooms_tower.gd:493-513, 474, 484 | | L2 furniture and tower lamps | `refs["L2_Cabinet"]` | **FAL** (hero_props.gd:83-86, 99-101) |
| T6 | `L2_Chart` | rooms_tower.gd:504 | 0.6 x 0.4 sheet | pinned chart | none | KEEP (paper) |
| T7 | `BrokenBurnerCloth` | lantern.gd:306 | 1.0 dia x 0.02 | canvas the broken burner lies on, lamp-room floor | **diagnosis_sequence.gd:48** hides and shows it by name | **GREYBOX**: new `lhi_burner_cloth` |
| T8 | `LampModel`, `LampModelOpen`, `BrokenBurner` | lantern.gd:134-155, 296-305 | 2.6 m lamp | arc lamp (closed and open), broken burner | lamp_beacon.gd, lamp_socket.gd, diagnosis_sequence.gd | **FAL** `lhi_arc_lamp`, `lhi_arc_lamp_open`, `burner_broken` |
| - | KEEP: `Core` (the arc's emissive sphere, lamp_beacon.gd) and the beam cards | lantern.gd:163 | | effects | lamp_beacon.gd | KEEP |

Lamp-room and tower structure that is left out: floor, kerb, mullions, glass, transoms, ceiling, ring beam, rafters, gallery posts, rails and balusters, stair treads, spiral, newel, rails and invisible walls (`lantern.gd`, `tower_shell.gd`, `spiral_down.gd`).

### Surroundings

- Front door (`door.gd`): planks, straps, studs and ring handle, already dressed (LHF-12). It is a door and interactive. KEEP.
- `interior_props.gd` (the window barrier), `opening_kit.gd`, `exterior_openings.gd`, `wall_patch.gd`: structure. KEEP.
- On the island and the docks there are no primitive props. The gate, lampposts, rowboat, Saltgate hut and buoys are all models.
- At sea, outside the lighthouse: `crossing_hazards.gd:178` `_debris` builds floating timber from plain boxes, and the buoy has a fallback cylinder used only if its model fails. The debris is a FAL candidate but needs a top-up (see below).

**Counts.** Basement: 22 prop rows. 13 are already FAL; 5 are still greybox (4 need a new model, 1 is a free reuse); 4 are keeps. Elsewhere: 15 greybox prop rows still drawn from primitives (G4, G5, G8, G9, L1-L6, T1-T4, T7). Of those, 11 need a new model, 1 is a free reuse (G9) and 3 can just be hidden or skipped (L4, L5, L6). About 60 other prop groups are already FAL.

## 2. Ranked generation list and cost

Ranked by how much the player sees each prop: the basement route and coal job first, then the lamp room (the diagnosis), the tower climb and L2, the ground floor, and last the L1 quarters, which are off the main route. FAL Hunyuan3D v3 text-to-3D, **textured** (`--textured`, `generate_type: "Normal"`, as the T45 batch was run): **$0.375 each**. Without `--textured` the sender asks for `Geometry` (an untextured mesh), which is not what the pipeline uses.

Balance **$6.10**, enough for 16 models with nothing left for re-rolls. The T45 batch needed 2 re-rolls in 29.

| Rank | Model | Replaces | Uses | Tri target (each) | Cost | Running total | Fits $6.10? |
|---|---|---|---|---|---|---|---|
| 1 | `lhi_pressure_gauge` | B2 gauge rim | 1 | 1,200 | $0.375 | $0.375 | yes |
| 2 | `lhi_coal_bin_front` | B3 | 1 | 2,000 | $0.375 | $0.75 | yes |
| 3 | `lhi_wall_grille` | B4 + G4 | 5 | 800 | $0.375 | $1.125 | yes |
| 4 | `lhi_valve_wheel` | B5 | 4 | 400 | $0.375 | $1.50 | yes |
| 5 | `lhi_burner_cloth` | T7 | 1 | 800 | $0.375 | $1.875 | yes |
| 6 | `lhi_fire_hose_coil` | T1 | 1 | 1,000 | $0.375 | $2.25 | yes |
| 7 | `lhi_barograph` | T2 | 1 | 1,200 | $0.375 | $2.625 | yes |
| 8 | `lhi_water_can` | T3 | 1 | 1,000 | $0.375 | $3.00 | yes |
| 9 | `lhi_rope_coil` | G8 + T4 | 2 | 800 | $0.375 | $3.375 | yes |
| 10 | `lhi_ledger_book` | G5 | 1 | 500 | $0.375 | $3.75 | yes |
| 11 | `lhi_pot_shelf` | L1 | 1 | 2,000 | $0.375 | $4.125 | yes |
| 12 | `lhi_wall_shelf_books` | L3 | 1 | 1,200 | $0.375 | $4.50 | yes |
| 13 | `lhi_tin_mug` | L2 | 4 | 300 | $0.375 | $4.875 | yes |
| 14 | `lhi_wall_mirror` | L5 | 1 | 600 | $0.375 | $5.25 | yes |
| 15 | `lhi_linen_stack` | L4 | 9 or 3 | 600 | $0.375 | $5.625 | yes, leaves $0.475 (1 re-roll) |

- **Ranks 1-9 (priority 1 and 2), $3.375:** basement route, lamp room and tower climb. This leaves $2.725, enough for about 7 re-rolls. Added triangles at the targets come to about 14,600, inside today's 15,953 headroom.
- **All 15, $5.625:** fits the balance but leaves room for one re-roll only, and goes about 6-7k triangles over the 900k limit.
- **Recommended within $6.10:** ranks 1-12 ($4.50). Hide `L1_Linen_*` and `L1_TubTap` for free instead of generating rank 15, and skip ranks 13-14 or leave them for later. That keeps $1.60 for 4 re-rolls.
- **Needs a top-up** (no submission written yet): sea debris timber (`crossing_hazards.gd` `_debris`), an iron firebox surround (not advised, see B20), any re-rolls beyond the margin above. Each is $0.375.
- **Spend cap:** the Lighthouse Finisher ledger (`GERFramework/reports/lighthouse_finisher_fal_ledger.json`) has cap $19.425 and $16.125 spent, so **$3.30 is left under the cap, which covers 8 models.** Ranks 1-9 need the cap raised to at least $19.50, and all 15 to $21.75.

Free work with no FAL spend: B1 oilskins (`lhi_oilskin_coat`), G9 store bulb (`lhi_pendant_lamp`), and hiding L4 and L6.

## 3. Submission files

`AIAgentCrew/sample_submissions/lighthouse_props_greybox2/`. These follow the T45 format exactly: category `prop`, `fal-ai/hunyuan3d-v3/text-to-3d`, the locked style suffix ("single object on a neutral background, gritty dark cel-shaded, heavy ink outlines, flat cel shading with hard-edged shadow shapes, grimy hand-painted textures, muted, desaturated palette of stone grey #6B6B66 and slate #2C3A40, weathered mid-1800s") and the T45 negative prompt. Each `notes` field names the nodes it replaces, the size, and the downscale and decimate steps.

```
lhi_pressure_gauge.fal.json    lhi_coal_bin_front.fal.json   lhi_wall_grille.fal.json
lhi_valve_wheel.fal.json       lhi_burner_cloth.fal.json     lhi_fire_hose_coil.fal.json
lhi_barograph.fal.json         lhi_water_can.fal.json        lhi_rope_coil.fal.json
lhi_pot_shelf.fal.json         lhi_wall_shelf_books.fal.json lhi_tin_mug.fal.json
lhi_ledger_book.fal.json       lhi_wall_mirror.fal.json      lhi_linen_stack.fal.json
```

Prompts are 311-461 characters (the sender cuts at 1,024). No asset id clashes with an existing `Assets/Models/prop/*.glb`.

### Check-only result

`python main_asset.py sample_submissions/lighthouse_props_greybox2 --check-only --out <scratch>` (2 Nov 2026), with `--out` pointed away from the tracked `asset_reviews/summary.json`:

```
[asset] 15 approved, 0 need revision.
```

All 15 APPROVE with 0 findings, so nothing needed fixing. A dry run of `main_fal.py` on `lhi_pressure_gauge.fal.json` (no `--go`) showed the payload and "dry run - nothing sent".

## 4. Install plan per prop

The steps are the same for every prop (`LIGHTHOUSE_GREYBOX_PROPS.md`, "How a replacement goes in"):

1. Check-only (done).
2. `python main_fal.py <file> --go --textured` within the approved spend, plus one ledger entry each in `GERFramework/reports/lighthouse_finisher_fal_ledger.json` and `Game Audit/FAL_SPEND.md`.
3. `tools/import_new_props.py`, then `tools/downscale_glb_texture.py` (4096 to 2048).
4. Blender weld and collapse (`tools/decimate_glb.py`) to the tri target above. Godot's `decimate_props.gd` LODs stop at about 10-47k. Use a 1024 texture, and keep the originals in `Assets/Models/prop/source/` plus the backup at `C:\bkupConceptArt\FAL_3D_Models\prop\`.
5. Add a `hero_props.gd` entry: the greybox is hidden, its collision stays.
6. Run `audit_lighthouse.gd -- check`, `test_hero_props.gd` (its in-place and lamp counts go up), and take a screenshot of the room.

| Model | Where it goes in | Fit | What must keep working | Test |
|---|---|---|---|---|
| `lhi_pressure_gauge` | basement west wall above the boiler, u -2.2, y B1+1.75, v 4.2, facing +u | scale the model's dial to the 0.4 m rim. **Hide only `B_GaugeRim`.** `B_GaugeFace`, `Needle` and `B_GaugePlate` stay in front of the model's dial | boiler_gauge.gd `Needle` rotation; coal_job.gd `gauge`; the needle must not be buried in the model (move the face +x if it is) | test_coal_job.gd (gauge 0.5 / 1.0); audit_clipping.gd |
| `lhi_coal_bin_front` | IN_PLACE on `["B_CoalBinFront", "B_CoalBinPost_*"]`, face "-x" (toward the lobby and the coal-store doorway; the heap is behind it at +x) | 1.85 x 1.2 x 0.26, long side along v | `B_CoalBinFront` collision; CoalHeapInteract reach and the heap must stay visible over the top (1.2 m) | test_coal_job.gd (coal pickup); test_hero_props.gd |
| `lhi_wall_grille` | 5 voids: B_WallVoid_West (-2.15, B1+0.5, 3.4, +u), _Front (0.3, B1+0.5, 0.46, +v), _East (5.5, B1+0.5, 3.1, -u), G_WallVoid_West, G_WallVoid_East | IN_PLACE on `<void>_Bar*` per void, 0.6 x 0.8 / 0.5 x 0.7; keep `_Hole` (the black recess) behind | `LHI_WallVoid_*` markers (Sound agent), group `lhi_wall_void`, `Zone_*_WallVoid_*` triggers: all untouched | test_coal_job.gd (zone lookups) |
| `lhi_valve_wheel` | 3 on the steam main at u 1.0/2.7/4.4, y 0.46, v 6.35 (wheel up, +y); 1 on the engine feed at u 5.4, y -0.2, v 5.0 (facing -u) | IN_PLACE on `B_ValveWheel_N` + `B_ValveStem_N`; the Eng wheel alone. Fit 0.2 dia; it needs a "face" option for +y or the yaw maths takes it as a wall prop: an entry with an explicit rotation, as `B_Shovel` gets | nothing | test_hero_props.gd |
| `lhi_burner_cloth` | lamp-room floor, `_pt(262, 2.3, FLOOR)` | 1.0 across, flat. **Make the model a child of `BrokenBurnerCloth`** (or name the holder that) and hide only the disc mesh, so diagnosis_sequence.gd's show/hide by name still works | diagnosis_sequence.gd:48 (hidden until TED_S3, then shown) | test_diagnosis_sequence.gd |
| `lhi_fire_hose_coil` | tower L1 ring, bearing 30, r 3.0 | IN_PLACE on `L1_Hose` (0.6 dia x 0.12; tower frame) | the ring's walkable strip (no collision on the hose) | test_hero_props.gd |
| `lhi_barograph` | L2 table, bearing 75, on `L2_Table` (now `lhi_kitchen_table`) | IN_PLACE on `L2_Barograph`, y0 = the FAL table's top (check it, the side table was fitted to 0.8 m) | nothing | test_hero_props.gd |
| `lhi_water_can` | L2 landing, bearing 345 | IN_PLACE on `L2_WaterCan` (0.55 x 0.7 x 0.2), back to the tower wall | its collision body stays | test_hero_props.gd |
| `lhi_rope_coil` | store floor u 4.35 v 4.15, and L2 bearing 122 | IN_PLACE on `Store_Rope` and on `L2_Rope` (two entries) | nothing | test_hero_props.gd |
| `lhi_ledger_book` | office desk, u -1.43 v 6.23 | IN_PLACE on `Office_Ledger`; y0 = the FAL desk's top (the greybox's GF+0.8 may sit in or above the model) | nothing | test_hero_props.gd |
| `lhi_pot_shelf` | L1 mess wall, u 1.55-1.85, v 3.3-5.0 | IN_PLACE on `["L1_KitchenShelf_*", "L1_Pot_*"]`, face +u | nothing | test_hero_props.gd |
| `lhi_wall_shelf_books` | L1 quarters wall, u -2.99, v 7.0-8.0 | IN_PLACE on `["L1_Shelf_Bed", "L1_Book_*"]`, face +u | nothing | test_hero_props.gd |
| `lhi_tin_mug` | mess table, 4 mugs at v 5.65 | 4 IN_PLACE entries (`L1_MugS_0`..`3`), y0 = the FAL table top | nothing | test_hero_props.gd |
| `lhi_wall_mirror` | wash room, u 0.55, y L1+1.5, v 5.67, on the partition, facing into the room (+v, which is face "-z" in the frame) | IN_PLACE on `L1_Mirror` (0.4 x 0.55) | nothing | test_hero_props.gd |
| `lhi_linen_stack` | L1 hall shelf | 3 stacks on the `lhi_store_shelf` model's boards, or just add `L1_Linen_*` to HIDE_ONLY (free) | nothing | test_hero_props.gd |
| Free: `lhi_oilskin_coat` | basement lobby wall, u 0.55-1.92, v 0.46-0.58 | 2-3 IN_PLACE entries on `B_Oilskin_*` (as the G coats: 4 at 0.35 m would overlap, so hide all 4 and place 2-3) | nothing | test_hero_props.gd |
| Free: `lhi_pendant_lamp` | store ceiling, u 4.7 v 4.5 | the LAMPS list keys on `<name>_Glass`. Either add a LAMPS variant that takes the node name (`Store_Bulb`) or rename the bulb `Store_Lamp_Glass` and the flex `Store_Lamp_Cap` in rooms_house.gd | `Store_Light` (the light) | test_hero_props.gd lamp count |

The IN_PLACE fitter (`hero_props._place_in`) handles wall props. The two flat floor coils, the overhead valve wheels and the gauge need small additions to the fitter, or a K.model-style placement as the shovel has. That is a code change for the install session, not part of this prep.

### Kept parts that may show through (worth checking in the same pass)

- `B_Switchboard_Lamp_Green` is hidden by the switchboard entry (`B_Switchboard_*`), then made visible again by `coal_job._apply`. It stays at u 5.38, 2 cm off the wall, which may be inside the FAL switchboard's body. If the green lamp never shows in play, this is why.
- `Office_Chart` and `L1_Chart` (paper sheets) were placed at the greybox table heights, and `Office_Ledger` and `Office_Blotter` at the greybox desk height. After the FAL tables and desk went in, they may float or sink.
- `L1_StoveGlow` may stand in front of the FAL stove instead of on its door.
- `L1_Linen_*` now sits in the `lhi_store_shelf` model's shelves.

## 5. Decisions for the creator

1. **Spend:** approve ranks 1-9 ($3.375), ranks 1-12 ($4.50), or all 15 ($5.625) from the $6.10 balance? The finisher ledger cap has $3.30 left (8 models), so anything past rank 8 also needs the cap raised.
2. **Materials are already over budget: 126 of 120, failing the audit today**, before any new prop. Raise `MAX_MATERIALS` in `tools/audit_lighthouse.gd` (to about 140 for all 15), or merge materials (for example, share one tinted material across the small FAL props)?
3. **Triangles:** 15,953 headroom. Ranks 1-9 fit at the targets above; ranks 10-15 need `MAX_TRIS` raised by about 10k or heavier decimation elsewhere.
4. **The switchboard, tool rack and lobby barrel are already FAL.** If they still read as greyboxes to you, please send a screenshot. Re-rolling them is $0.375 each, and decimating less costs nothing.
5. **Cheap fixes instead of models:** hide `L1_Linen_*` and `L1_TubTap`, and reuse the oilskin coat and pendant lamp. All free. OK to do these in the install session?
6. **Firebox surround and sea debris:** leave them as built (recommended for the firebox), or top up for the debris?
