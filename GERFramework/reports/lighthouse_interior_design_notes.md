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
| G stairs down | the stairwell gets a railing (the v3 hole had none) | `rooms_house.gd` |
| B1 coal store | walled cell, wooden bin front, a heap of 190 lumps | `rooms_house.gd` |
| B1 boiler room | brick plinth, boiler shell and dome, copper bands, firebox door with a glow and a flickering light, pressure gauge, water glass, lagged steam main, valve wheels, water cistern | `rooms_house.gd` |
| B1 steam engine and dynamo | bedplate, cylinder, steam chest, piston rod, flywheel (turns when the boiler is fed), crankshaft, dynamo with copper coil and belt, switchboard with dials and lamps | `rooms_house.gd` |
| B1 workshop and stores | bench, vice, tool board, parts shelving | `rooms_house.gd` |
| B1 crawlspace and wall voids | five grilled voids (two in the hall, three below) with trigger zones | `rooms_house.gd`, `zone_trigger.gd` |
| L1 keeper's quarters | hall from the tower door, sleeping quarters (two beds, chest, wardrobe), radio and chart room, wash room, kitchen and mess with a stove, linen shelving, a gabled plaster ceiling under the roof | `rooms_tower.gd` |
| L2 control and diagnostics | a landing ring round the spiral inside the tower: electrical control cabinet, instrument station, tool locker, water can | `rooms_tower.gd` |
| L3 lamp room | full redesign, below | `lantern.gd` |

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

## Open or deferred

- The foundation chamber under the tower (blueprint B1 item 6) needs a carve in the island collider and has no story use.
- The left hut and right annex are closed storage and exterior only, as the blueprint says.
- Textures are procedural; the Asset agent can replace them. The first-floor and lamp-room lighting needs a Lighting agent pass.
- Ted's window staging (tower landing window recommended) and the lamp-room diagnosis (T05) are the Gameplay agent's.
