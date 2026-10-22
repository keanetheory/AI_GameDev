# Handoff to the Asset agent: lighthouse interior art (2026-10-22)

From the Lighthouse Interior Creator Agent. The creator asked for the art objectives to go to the Asset agent. Everything in the interior is greybox: boxes and cylinders, with procedural noise textures made in code (`LightingTheStorm/scripts/world/interior/kit.gd`). Nothing structural depends on the art, so each item can be replaced one at a time. The Asset agent's rules apply: style guide (`Docs/Lore Build/world/style_guide.md`), `main_asset.py --check-only` first, FAL Hunyuan v3 models downscaled from 4096 to 2048 (memory: fal-hunyuan-v3-texture-size), no retired "Brusskania" text on models (the brand is Saint Calder).

## Art objectives

| # | What | Where it is now | Notes |
|---|---|---|---|
| A1 | **Surface textures**: stone-grey plaster, slate flagstones, dark timber, brick, stone tower wall, iron | `kit.gd` `_texture()` and `_make_materials()` (128 px noise, triplanar, world scale 0.3-0.8) | Hand-painted, grimy, muted, desaturated; seamless. Palette: stone grey #6B6B66, sea slate #2C3A40, navy #1F2A44, silver #B9BEC4, amber #C07A1E, gold #B8962E |
| A2 | **Flighted posters** (canon: crude letterpress, black, silver and navy only; a dark sphere eclipsing a silver moon above waves; slogans "THEY BRING THE STORMS", "THEY CHANGE THE SEASONS") | `rooms_house.gd` `_poster()`: paper quad with a text label and flat discs | Prompts in `Docs/Lore Build/factions/fac_flighted.md` (`poster_prompt`, `poster_prompt_alt`). Three sizes 0.72 x 1.0 m |
| A3 | **Boiler and firebox** | `rooms_house.gd` `_basement()`: cylinder shell, dome, copper bands, bar-fronted firebox | Needs the gauge (`B_BoilerGauge`, script `boiler_gauge.gd` moves a child named `Needle`) and the firebox door glow (`B_FireDoorGlow`) kept as separate nodes |
| A4 | **Steam engine, flywheel, dynamo, switchboard** | same file | Flywheel node `B_Flywheel` is rotated by `coal_job.gd`; the green lamp `B_Switchboard_Lamp_Green` is driven too |
| A5 | **Arc lamp and Fresnel lens** | `interior/lantern.gd` `_arc_lamp()` | Bands named `Lens_*` are lit by `lamp_beacon.gd`; the burner socket is the node `LampSocket` (mount pose in `mount_rotation_deg`); the lamp must match the burner's mounting base (backlog T28, models in `Assets/Models/prop/burner_*.glb`) |
| A6 | **Spiral stairs and tower stonework** | `tower_shell.gd` (lining, one mesh per step), `spiral_down.gd` | Lining follows a measured radius table (`data/world/tower_radii.json`); keep that profile if the wall is re-modelled |
| A7 | **Furniture and props at concept-art density**: beds, desk, shelves, chart table, stove, tub, crates, barrels, coats, tools, books, paperwork | `rooms_house.gd`, `rooms_tower.gd` | Replace boxes with models; keep the collision boxes |
| A8 | **Coal, shovel and the shovelful held in view** | `coal_job.gd` `_make_shovel()`; heap `_coal_pile()` | The held pose is `held_offset` / `held_rotation_deg` on the `CoalJob` node |
| A9 | **Window frames and glass** (stone reveals, iron mullions) | `windows` data `data/world/lighthouse_windows.json`, built in `tower_shell.gd` and `rooms_tower.gd` | Eight windows: five in the tower, three in the house |
| A10 | **Cel shading and ink outlines** (style guide) | not applied: the rest of the level is lit normally | Needs a shared decision with the Lighting agent so the interior matches the exterior |

## What the Asset agent should not touch

Collision, anchors (`LHI_Anchor_*`), the interaction scripts (`coal_pile.gd`, `firebox_hatch.gd`, `lamp_socket.gd`, `poster.gd`), the light manager (`interior_lights.gd`), and the baked data (`tower_radii.json`, the window boxes in `Level.tscn`). The interior tests (`tools/test_interior_walk.gd`, `test_spiral_down.gd`, `test_coal_job.gd`, `test_lamp_fit.gd`, `test_interior_budget.gd`) must still pass after any replacement.
