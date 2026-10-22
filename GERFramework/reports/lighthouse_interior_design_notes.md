# Lighthouse interior: design notes (updated 2026-10-20, after the room build)

How the interior maps to the Interior Plan V4 blueprint (`ConceptArt/narrative_blueprints/Brussskania Lighthouse Blueprint Poster.png`, which says "schematic, not to scale; may be adjusted in production") and to how a real lighthouse is built; what was built, what was measured, and what is still open. Measurements come from the running level (`tools/probe_*.gd`).

## What was built (creator decisions of 2026-10-20: L1 and L2 walk-through; boiler room and hallway first; a lamp-room burner interaction; the lamp room's wall replaced by glass)

The v3 greybox (a `.glb`) still supplies floors, walls, the basement stairs and the 96-step tower spiral. `scripts/world/interior_rooms.gd` (node `InteriorRooms` in `Level.tscn`) builds everything else, in code, in the house's own frame (`interior/kit.gd`: u along the front wall, v inward, y local height), with procedural textures and no imported art. It builds in about 260 ms, makes about 870 nodes, 136 solid bodies and 25 lights (`tools/test_interior_budget.gd`).

| Blueprint | Now | Where |
|---|---|---|
| G entry vestibule | coats on a rail, boot bench, umbrella stand, rug, door mat, two wall lanterns | `rooms_house.gd` |
| G hallway, posters and documents | three posters (two Flighted, one moon-cycle) and a notice board with the tide table; E reads a Flighted poster and fires POSTER_EXAMINED | `rooms_house.gd` |
| G keeper's office | desk, chair, lamp, ledgers on shelves, filing cabinet, chart table with a sea chart, clock | `rooms_house.gd` |
| G storage room | walled room with a doorway: crates, barrels, shelving, rope, a bulb | `rooms_house.gd` |
| G stairs down | a spiral stair (15 stone treads round a newel, one full turn) replaces the v3 switchback flights; the hole gets a railing, open at the front where the spiral starts | `spiral_down.gd`, `rooms_house.gd` |
| B1 coal store | a walled cell in the south-east corner, the far corner from the firebox (south-west), so the player crosses the whole basement; wooden bin front, a heap of 190 lumps, a shovel standing in it | `rooms_house.gd` |
| B1 boiler room | brick plinth, boiler shell and dome, copper bands, firebox door with a glow and a flickering light, pressure gauge, water glass, lagged steam main, valve wheels, water cistern | `rooms_house.gd` |
| B1 steam engine and dynamo | bedplate, cylinder, steam chest, piston rod, flywheel (turns when the boiler is fed), crankshaft, dynamo with copper coil and belt, switchboard with dials and lamps | `rooms_house.gd` |
| B1 workshop and stores | bench, vice, tool board, parts shelving | `rooms_house.gd` |
| B1 crawlspace and wall voids | five grilled voids (two in the hall, three below) with trigger zones | `rooms_house.gd`, `zone_trigger.gd` |
| L1 keeper's quarters | hall from the tower door, sleeping quarters (two beds, chest, wardrobe), radio and chart room, wash room, kitchen and mess with a stove, linen shelving, a gabled plaster ceiling under the roof | `rooms_tower.gd` |
| L2 control and diagnostics | a landing ring round the spiral inside the tower: electrical control cabinet, instrument station, tool locker, water can | `rooms_tower.gd` |
| L3 lamp room | full redesign, below | `lantern.gd` |

## Look and feel (from the AI Crew's style guide and lighting spec)

Source: `Docs/Lore Build/world/style_guide.md` (gritty dark cel-shaded; muted, desaturated; mid-to-late 1800s gaslight and steam; no clean glossy surfaces, neon or saturated colour) and `AIAgentCrew/world_output/lighting_spec.json` (steam glow amber #C07A1E, arc lamp and beacon silver #B9BEC4, the beacon "dark, failing flicker, relit steady sweep"). Applied in `interior/kit.gd`: stone-grey plaster, slate flags, dark desaturated timber and brick, dulled brass and copper, every warm lamp amber, the lens, beam and lamp-room light cold silver, posters black, silver and navy on aged paper, coats in Ted's navy and Arthur's green. Not done: cel shading and ink outlines (the rest of the level is lit normally), and the beacon's pre-fit "failing flicker".

## The lamp room (LHI-12, LHI-13)

The exterior model's lantern is a solid wall with painted glazing. The level cuts the whole band away; this puts the room back:

- a timber floor out to the glass and an iron kerb flush with the gallery deck (y 18.3);
- twelve slim mullions and one continuous pane from the kerb to a plaster ceiling and ring beam (which hide the torn roof underside the cut leaves), so the player looks out over the sea, the island, the cliffs and the Saltgate from every side; the glass is solid for the player and ignored by sight tests;
- the stair opening is railed, with a gap where the spiral arrives;
- the arc lamp: brass pedestal, a burner bay (open cage of brass bars), an eight-band Fresnel lens, a chimney. Dark and cold at the start; the broken burner Ted took out lies on the floor;
- **the burner interaction**: hold the burner, face the lamp, `[E] Fit the burner into the lamp`. It is a `CarrySocket` that accepts only the burner and keeps it. It fires BURNER_FITTED (GameState moves to FINAL_REPAIR and the BEACON_RELIT lighting) and the lamp comes up over 3.5 s: the lens glows, a light rises, a beam sweeps out over the water. The look is a placeholder; the Lighting agent owns the final beacon (T13).

## The coal job (LHI-14, T33)

E at the heap takes a shovelful (held in view, one item at a time, like the burner); E at the firebox feeds it; six loads (data on the node). COAL_LOADED_FIRST, COAL_LOADED_HALF, BOILER_FED. The gauge, the fire and its glow climb, the flywheel starts and the switchboard lamp goes green. Zones report LIGHTHOUSE_ENTERED and ENGINE_ROOM_ENTERED.

## Measured facts that shaped the build

- **The house roof leaves no room for a second house floor.** Headroom above y 5.3 is 1.8-4.5 m and none above y 6.9. So L1 is the house's upper floor and L2 is a landing ring in the tower. The spiral passes the house side at y 5.20 and 9.43 every turn, which is where L1's doorway and L2's landing fall.
- **The real house is bigger than the greybox.** Upstairs the shell runs u -3.0 to 5.5 and v about 0.9 to 9.0 (the greybox ground floor stops at v 6.8). L1 uses the real extent.
- **The tower is hollow enough.** Inner wall radius about 3.9 m at L1 and 3.2-3.4 m at L2; the spiral occupies radius 1.14-2.07, so the L2 ring is 1.1 m wide and its fittings are 0.2 m deep.
- **The dock berth cannot be seen from any window**; the tower landing window sees the water outside the harbour mouth (the rowboat sighting is at (-48, 0.8, 24)).
- Lantern: no wall left in the band; roof underside 22.06 at radius 2.0; deck top 18.3 from radius 2.9.

## Fixes from the 2026-10-22 playthrough

- **Rock and model shards in the basement ceiling.** The island mesh and the exterior model have large triangles that cross into the basement from outside; the level's carve removes triangles by their centre, so they stayed. `collider_builder.gd` has a new `carve_oriented_any` (a triangle goes if any corner is inside the box), set on the Island and Lighthouse nodes in `Level.tscn`. `tools/probe_shards.gd` lists what still pokes into a room (169 spots in the basement before, 16 after, all outside walls).
- **Firebox flicker.** The glow panel shared a face with its door frame (z-fighting) and the fire light's flicker was fast and deep. It is now a glowing slot behind bars, protruding 1 cm, with a slow 10% flicker.
- **Stair clipping.** The spiral filled the stairwell hole edge to edge; it is now 1.35 m radius, centred 4.0 m in, clear of the hole's rails, the storage wall and the coal cell.
- **Stray sign** in the coal doorway removed.
- **First-floor hall:** a plaster knee wall along the front closes the gap under the sloping ceiling; lamps lowered off the ceiling.

## Fixes from the second playthrough (2026-10-22)

- **The tower had no floor round the stair.** The v3 greybox floors only the ring under the spiral (radius 1.14-2.07); the rest of the base was a pit with the island visible below, and the first-floor ring left the house side open. Now: a ground-floor ring out to radius 3.0 with a low stone parapet (open at the entry), and a full first-floor ring with an outer rail (open across the house doorway). `rooms_tower.gd` `_g_ring`, `_l1_ring`. The tower wall is ragged and open at these heights (radius 3.0 to over 5 m; `tools/probe_tower_radii.gd`), so the rings stop short of it.
- **The basement spiral was not joined to the hall floor.** The v3 stairwell hole is 2.8 x 3.4 m and the spiral only filled a circle in it, so the player could step off beside the first tread. The floor now fills the hole outside a circle just wider than the treads, with a rail round the circle except across the entrance (`spiral_down.gd` `_g_opening`). `tools/test_spiral_down.gd` now pushes at that rail from eight sides.
- **First floor, second pass:** door frames at every doorway, a lining on the east wall, rugs, keeper's rules, calendar, clock, coat hooks, a book shelf, lamps lowered and brightened, the stove glow made amber.

## Tower stairwell rebuild (2026-10-22, third playthrough)

- `interior/tower_shell.gd` builds a stone lining round the whole tower stairwell, ground floor to lamp-room floor, at the radius the exterior wall leaves room for at each height (2.9-3.4 m; `tools/probe_tower_radii.gd`). It has openings only where there is a real way through: the hall doorway (ground floor), the keeper's quarters (first floor, house side) and the tower landing window. This closes the gaps through which the player could see the island and the empty shell of the house, and the gap at the L2 landing.
- Every spiral tread now runs out to that wall (`StairExt_*`), except the landing treads and those in front of the window. The stair handrails are gone, as asked. The ground, first and second floor rings meet the lining too; the old rail round the L2 ring is removed and its fittings moved clear of the stair.
- The tower window's bearing is 147 degrees (the house side), not the 303 I first assumed from its sin/cos form; `test_sightlines` caught the lining blocking it.

## Fifth pass (2026-10-22): windows, tower wall, stairs, shovel, win

- **Windows** (`data/world/lighthouse_windows.json`, baked into `Level.tscn` by `tools/bake_windows.py`): five in the tower (two on the stair at bearing 300, two at 110, one at the control landing, 215) and three in the house (bedroom west, mess and wash room at the back). Each has deep stone reveals, glass, an iron mullion and an invisible barrier. Exterior triangles hanging into the stairwell are cleared by the same bake.
- **Tower wall thickness and taper:** a 3.0 m plinth to the first floor, then a cone from 3.4 m to 2.9 m, pulled in to a measured table (`data/world/tower_radii.json`, `tools/bake_tower_radii.gd`) so no exterior surface shows through; sector edges share vertices so there are no cracks.
- **Stairs:** the v3 half-width steps are replaced by solid 0.4 m steps from newel to wall, one mesh each (the landing steps stay narrow).
- **Shovel:** it now moves: dips into the heap and comes up loaded, then thrusts at the firebox, tips and is put away. This also fixed a bug: the shovelful was never reparented into the camera (a parentless node), so it was never visible in the hands.
- **SHIP_WIN** is reported 4.5 s after the burner is fitted, if no outcome has resolved.
- **Art** handed to the Asset agent (`handoff_asset_agent_lighthouse_interior.md`).

## Open or deferred

- The foundation chamber under the tower (blueprint B1 item 6) needs a carve in the island collider and has no story use.
- The left hut and right annex are closed storage and exterior only, as the blueprint says.
- Textures are procedural; the Asset agent can replace them. The first-floor and lamp-room lighting needs a Lighting agent pass.
- Ted's window staging (tower landing window recommended) and the lamp-room diagnosis (T05) are the Gameplay agent's.
