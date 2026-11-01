# Lighthouse greybox props and their FAL replacements (T45)

1 November 2026. This is the list of every lighthouse prop that is still built from primitives (boxes, cylinders, spheres), with a plan to replace them with generated FAL models. **It needs the creator's approval before any credits are spent.**

## How the list was made

I loaded the level and listed every visible mesh in the interior (`InteriorRooms`, `LighthouseInterior`, the front door): 1,290 meshes in all. 916 of them are primitives, 351 are built in code and 24 are the FAL models already in place (desk, chair, filing cabinet, beds, wardrobe, sea chest, stove, tub, kitchen table, telegraph, oil lamps, barrels, crates, coats, boiler, steam engine, shovel, arc lamp). Most of the primitives are architecture: walls, beams, skirting, window and door frames, stair rails and the lamp-room structure. Those stay as they are (see "Keep as primitives" below). What's left are the props in the tables below.

Rooms use the code's names: **B1** basement, **G** ground floor, **L1** keeper's quarters (the first floor in the house), **L2** the tower landing for control and diagnostics, **L3** the lamp room. No props were found for the left and right huts in the Interior Plan V4 (they aren't built yet).

Sizes are the old greybox's bounds in metres (width x height x depth). Role: **D** decor, **C** has its own collider, **I** part of an interaction.

## Cost

FAL Hunyuan v3 costs $0.375 a model. The Lighthouse Finisher cap is $7.80, and $5.25 of it is spent, so **$2.55 is left: enough for 6 models.**

| Batch | Models | Cost | Beyond the remaining $2.55 |
|---|---|---|---|
| Priority 1 | 6 | $2.25 | within the cap |
| Priorities 1 and 2 | 22 | $8.25 | **$5.70 more** |
| All three priorities | 30 | $11.25 | **$8.70 more** |

Nine more groups can reuse models we already have, at no cost (the reuse table).

## Priority 1: on the slice's route, seen up close (6 models, $2.25, within the cap)

The six submissions are drafted in `AIAgentCrew/sample_submissions/lighthouse_props_t45/` and pass `main_asset.py --check-only` (6 of 6 approved). Nothing has been sent to FAL.

| # | New model | Replaces | Room | Size (m) | Role | Why first |
|---|---|---|---|---|---|---|
| 1 | `lhi_wall_sconce` | B_Sconce_* (3), G_Sconce_* (3), G_TowerLamp, L1_TowerLamp, L2_LampA/B: about 9 sphere-and-plate lamps | B1, G, tower | 0.2 x 0.3 x 0.2 each | D | Lights the whole route; one model, used 9 times. The glass centre has to land where the old sphere was, because the light cards' halos sit there. |
| 2 | `lhi_bookcase_filled` | Office_Shelf* (4), Office_ShelfSide* (2), Office_Book* (81) | G office | 1.9 x 1.75 x 0.35 | D, C | Seen from the entry where Ted greets the player; one model replaces 87 meshes. |
| 3 | `lhi_switchboard` | B_Switchboard plus its dials (3), knife switch and red/green lamps | B1 | 0.8 x 1.1 x 0.5 | D | Next to the boiler during the coal job. |
| 4 | `lhi_workbench_vice` | B_WorkBench, B_Vice, B_BenchTop | B1 | 1.5 x 1.05 x 1.0 | D, C | Basement, beside the coal job. |
| 5 | `lhi_instrument_cabinet` | L2_Cabinet plus its dials (3), lamps (2) and switch | L2 | 1.25 x 1.9 x 0.8 | D, C | Passed on every climb to the lamp room. |
| 6 | `lhi_water_cistern` | B_Cistern, B_CisternFeed, B_CisternStrap* (3) | B1 | 2.0 long, 0.6 diameter, feed pipe 1.3 | D | Largest primitive object in the basement. |

## Priority 2: seen, but off the main route (16 models, $6.00)

| # | New model | Replaces | Room | Size (m) | Role |
|---|---|---|---|---|---|
| 7 | `lhi_pendant_lamp` | L1_HallLamp (3), L1_MessLamp + cord, L1_QuartersLamp, L1_WashLamp, Store_Bulb + hanging flex | L1, G | 0.26 globe on a 0.4 drop | D |
| 8 | `lhi_chart_table` | Office_ChartTable + legs; also reused for L1_ChartTable | G, L1 | 1.16 x 0.86 x 1.04 | D, C |
| 9 | `lhi_tool_wall` | B_ToolBoard, B_Tool (7), B_ToolRack | B1 | 1.4 x 0.9 board | D |
| 10 | `lhi_parts_shelf` | B_PartsShelf (3), B_PartsPost (2), B_Part (8) | B1 | 1.05 x 2.0 x 0.85 | D, C |
| 11 | `lhi_store_shelf` | Store_ShelfBoard (3), Store_ShelfPost (2), Store_Tin (6); also reused for L1_HallShelf | G store, L1 | 1.0 x 1.9 x 1.25 | D, C |
| 12 | `lhi_steel_locker` | L2_Locker, L2_LockerDoor | L2 | 1.0 x 1.8 x 0.4 | D, C |
| 13 | `lhi_boot_bench` | G_BootBench, G_Boots (2) | G | 2.3 x 0.6 x 1.4 | D, C |
| 14 | `lhi_umbrella_stand` | G_UmbrellaStand, G_Umbrella (2) | G | 0.34 x 1.2 x 0.34 | D, C |
| 15 | `lhi_notice_board` | G_NoticeBoard | G | 0.9 x 1.05 | D |
| 16 | `lhi_washstand` | L1_Basin, L1_BasinBowl, L1_BasinTap | L1 | 0.85 x 1.1 x 0.75 | D, C |
| 17 | `lhi_kitchen_counter` | L1_Counter, L1_CounterTop, L1_Sink, L1_SinkTap | L1 | 1.8 x 1.2 x 1.4 | D, C |
| 18 | `lhi_radio_desk` | L1_RadioDesk, L1_RadioDial (3), L1_RadioKey (the telegraph on it is already FAL) | L1 | 1.75 x 1.05 x 1.2 | D, C |
| 19 | `lhi_mess_bench` | L1_MessBenchA, L1_MessBenchB | L1 | 1.4 long, seat 0.45 | D, C |
| 20 | `lhi_nightstand` | L1_Nightstand | L1 | 0.67 x 0.55 x 0.67 | D, C |
| 21 | `lhi_wall_clock` | Office_Clock + face, L1_MessClock + face | G, L1 | 0.38 diameter | D |
| 22 | `lhi_barometer` | L2_Barometer + face | L2 | 0.4 diameter | D |

## Priority 3: small dressing, fine as primitives for Gate 1 (8 models, $3.00)

`lhi_rope_coil` (Store_Rope, L2_Rope), `lhi_pots_and_mugs` (L1_Pot x6, L1_MugS x4, kitchen shelves), `lhi_linen_stack` (L1_Linen x9), `lhi_barograph` (L2_Barograph), `lhi_oil_can` (L2_WaterCan), `lhi_hose_reel` (L1_Hose), `lhi_towel_rail` (L1_Towel, L1_TowelRail), `lhi_pinned_chart` (L2_Chart).

## Reuse existing FAL models (no cost)

| Greybox | Reuse | Room |
|---|---|---|
| B_LobbyBarrel | `lhi_oak_barrel` | B1 |
| B_Oilskin (4) and their pegs | `lhi_oilskin_coat` | B1 |
| L1_Coat_Ted | `lhi_oilskin_coat` | L1 |
| L1_RadioChair + legs (4) | `lhi_keeper_chair` | L1 |
| L2_Table | `lhi_kitchen_table`, scaled to 1.0 x 0.45 (or the chart table once it exists) | L2 |
| L1_ChartTable | `lhi_chart_table` (#8) | L1 |
| L1_HallShelf + boards | `lhi_store_shelf` (#11) | L1 |
| B_LobbyBench | `lhi_mess_bench` (#19) | B1 |
| Daniel's chair at the boiler | its own task, T43 | B1 |

## Keep as primitives (architecture and trim)

These read correctly as built and aren't props: walls, linings, floors, ceilings, beams, joists, rafters, ridge, collars, cornices, skirting, panelling and rails; window kits (glass, jambs, mullions, sills, quoins, keystones); door jambs, lintels and the front door's planks; the stairs, newels, landing rings and every rail; the lamp room's mullions, rafters, gallery posts and rails; pipes, steam main, valves, cables, cable tray, drains and wall vents; tiles and hearth; rugs, runners and the door mat; the coal bin, coal heap and fire frame, which are part of the coal job (`coal_pile.gd`, `fire_flame.gd`) and stay as built.

## How a replacement goes in

The Lighthouse Finisher process that placed the first 14 props:
1. `python main_asset.py <folder> --check-only` (free; done for priority 1).
2. Dry run of `main_fal.py`, then `--go` within the approved spend. Record each spend in `GERFramework/reports/lighthouse_finisher_fal_ledger.json`.
3. `tools/import_new_props.py`, downscale the texture to 2048, `tools/decimate_props.gd -- <tris> 1024 <id>`.
4. Add an entry to `scripts/world/interior/hero_props.gd`. The greybox is hidden and keeps its collision, so anchors, lights and tests don't change.
5. `tools/audit_lighthouse.gd -- check` (triangle budget), the interior tests, and screenshots of each room.

## Questions for the creator

1. **Spend:** approve priority 1 ($2.25, within the remaining $2.55)? And priority 2 as well, which needs **$5.70 more** than the cap allows?
2. **T48, "the L2 bathroom":** in the code the bathroom (tub, washstand, towel) is on **L1**, the first floor of the house, and **L2** is the tower landing with the instrument cabinet and locker. Does T48 mean the first-floor bathroom? If so, its props are #16, #17, the towel rail and the existing tub.
