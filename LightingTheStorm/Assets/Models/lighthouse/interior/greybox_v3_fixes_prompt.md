# Fixes for lighthouse_greybox_v3

Attach: `build_lighthouse_greybox_v2.py`, `lighthouse_greybox_v2_alignment.json`, `exterior_door_measured.json`, `exterior_heightmap_local.json`.

---

Update `build_lighthouse_greybox_v2.py` to make `lighthouse_greybox_v3.glb` and `lighthouse_greybox_v3_alignment.json`. Keep everything not listed below exactly as in v2: the frame, the door, the ground floor, the basement and its stairs, and the part names. My Godot carving of the exterior and the island is matched to them.

I tested v2 in Godot with the player's capsule against the real collision. The entry hall, the dock window and the whole basement are reachable. Fix these five problems:

1. TOWER WALKWAY BLOCKED BY THE EAST WALL
   - `G_tower_link` (u 5.65..8.05, v 0.65..1.9) runs straight through `G_outer_east` (u = 5.65, v 0.36..6.8), which has no opening.
   - Split `G_outer_east` into two pieces so there is a doorway at least 1.2 m wide and 2.3 m tall where the link crosses it.

2. NO TOWER GROUND FLOOR
   - `Tower_entry_landing` sits inside `Tower_inner_guard_core`. The landing's centre is 1.03 m from the tower centre and the core's radius is 1.05. Nothing connects the walkway to the first spiral step: below them is only the exterior's base, 1 m down.
   - Remove `Tower_entry_landing`.
   - Add `Tower_ground_floor`: an annular slab around the core, inner radius 1.10, outer radius 2.07, top at y 0.97, 0.2 m thick. It must meet `G_tower_link` and the bottom of `Tower_spiral_step_000` with no gap.

3. LANTERN ROOM AT THE WRONG HEIGHT (my earlier figure was wrong)
   - The exterior's lantern deck is at y 17.9 and its glazing roof is at y 21.9-22.3, about 4 m of headroom. The glazing is at about radius 2.3-2.5 from the tower centre (3.5, 3.6).
   - Put the lantern floor (`Lantern_gallery_*`) with its top at y 17.95, as an annulus from radius 1.08 to 2.20.
   - End the spiral there: (17.95 - 0.97) / 0.175 = 97 steps of about 0.175 m, same radii and 24 steps per turn.
   - Move `Lantern_arc_lamp_mount`, `Lantern_arc_lamp_socket_marker` and `Lantern_ted_marker` down with it, keeping the same offsets above the floor.
   - The exterior has its own lamp object at the centre (radius up to 1.0, y 18-22). I will carve that out, so the greybox arc lamp replaces it.

4. NO HEADROOM AT THE TOP OF THE SPIRAL
   - In v2 the lantern floor covered the whole ring, so it sat 0-2 m above the last turn of steps.
   - Leave a stair opening in the lantern floor over the final steps. Every tread must have at least 2.1 m clear above it, measured to the underside of anything above (lantern floor, upper steps).
   - In practice that means leaving out the floor sectors over the last 12 steps (about half a turn).
   - Add a 1.0 x 1.0 m landing where the last step meets the lantern floor.

5. BEDROOM WITH NO WAY UP
   - `L1_floor` (y 3.9) has no stairs to it.
   - Remove `L1_floor` and `L1_bedroom_marker` for now. It has no Gate 1 gameplay, and a compliant stair would cut into the hall.

ALSO
- Extend `G_floor_entry` under the doorway so it starts at the door plane (v = -0.02) instead of v = 0.35. That closes the 0.35 m gap under the threshold; I patched it in Godot for v2.
- Markers can stay as 0.3 m cubes. Godot hides them and gives them no collision.

CHECKS (run them on the geometry itself, not from the formulas)
- Headroom: cast a ray upward from the middle of every stair tread (basement flights and spiral) and report the smallest clearance to any part above. It must be at least 2.1 m.
- Tower: report the gap between `G_tower_link`, `Tower_ground_floor` and `Tower_spiral_step_000`. It should be 0.
- East wall: report the clear width and height of the new opening.
- Record each check and its result in the alignment file, as in v2.
