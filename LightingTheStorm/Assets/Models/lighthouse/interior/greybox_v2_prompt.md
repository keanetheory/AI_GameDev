# Prompt for lighthouse_greybox_v2

Attach these four files with the prompt (all in this folder, or `C:\GameDev\preptheinterior` for v1):
`lighthouse_greybox_v1.glb`, `lighthouse_greybox_v1_alignment.json`, `exterior_door_measured.json`, `exterior_heightmap_local.json`.

---

Generate `lighthouse_greybox_v2.glb` and `lighthouse_greybox_v2_alignment.json`: a greybox interior for the lighthouse in my Godot 4.3 game, built to fit inside an existing exterior model. v1 (attached) has a good room list but does not fit the exterior. This version must fit the measurements below exactly. Use trimesh in Python as before and give me the script as well as the files.

COORDINATE FRAME (same as v1, do not change it)
- Metres, Y up, glTF axes. This is the exterior model's local frame after import: base centre at the origin, model 27 m tall.
- Godot places the greybox with no extra transform, so every coordinate below is final.

THE ENTRY (measured in Godot; this is the fixed point everything fits around)
- The front door's sill centre is at (-3.494, 0.97, 8.874).
- Its outward normal is (0.4309, 0, 0.9024) (yaw 25.5 deg from +Z), and it runs along (0.9024, 0, -0.4309).
- The opening is 1.8 m wide and 3.0 m tall. The door plane is the outer face of the house wall at the door; outside it is a 1.2 m deep porch that belongs to the exterior.
- Leave the opening clear. I already have the hinged door: it swings inward 100 deg, so keep a 1.8 m radius quarter circle inside the door free of walls and furniture.
- The house's north wall runs through the door along (0.9024, 0, -0.4309). Its inner face must sit no more than 0.25 m behind the door plane.

THE EXTERIOR SHELL (stay inside it)
- `exterior_heightmap_local.json` gives the exterior's top surface every 1 m (x -14..12, z -10..14). Use it as the house footprint and roof: interior walls must stay at least 0.3 m inside the outer walls and under the roof.
- House: the eaves are at about y 7-8 and the ridge runs diagonally at about y 9-10. Nothing may poke through the roof; v1's upper floor (top at 9.2) did.
- Tower: centred at about (3.5, 3.6). Outer radius 3.27 at y 12, 2.97 at y 16 and 2.63 at y 20; its top is at about y 24. Keep interior parts inside radius (outer - 0.4) at every height.
- The south side of the house stands on a boulder plinth 2-4 m high. There is no entry there, so do not put one there.

FLOORS
- Ground floor: walking surface at y 0.97, level with the sill. This replaces v1's 3.6.
- Basement: about 3 m below, walking surface at about y -2.0. It goes below the model's base into the island rock, which I will carve; keep its footprint inside the house footprint.
- Upper floor under the roof: walking surface at about y 3.9, with walls no higher than the eaves above it (about y 6.8).
- Every floor is a 0.2 m slab with its top at the walking height.
- Minimum headroom is 2.2 m and minimum doorway width is 1.0 m everywhere.

ROOMS AND GAMEPLAY (from the GDD; keep v1's set, moved to fit)
1. Entry hall straight through the front door. Ted meets the player here, and later the briefing with Ted and Arthur happens here.
2. A ground-floor window looking towards the island dock, where the sailors' rowboat moors. Direction from the house to the dock: (-0.77, 0, 0.63). Make the window opening at least 1.2 x 1.0 m, sill at y 1.9.
3. Stairs from the hall down to the basement engine room. It holds the boiler, the coal pile, the dynamo and a clear spot where Daniel stays.
4. A route from the hall into the tower, and stairs up the tower to the lantern room.
5. The lantern room at the top of the tower. Its floor is at about y 20.5, under the tower top at y 24. It needs open views all round (window openings at least 1.2 m tall around the full circle) and the arc lamp in the middle with a socket for the burner. The burner is 0.8 x 0.9 x 0.7 m with a round mounting base 0.8 m across. Ted waits here at the end, out of the line of sight to the sea.
- Keep the upper floor (a bedroom under the roof, as in v1) only if it fits under the roof with 2.2 m headroom.

PLAYER LIMITS (so every route is walkable)
- The player is a capsule 0.6 m wide and 1.7 m tall. It steps up 0.4 m on its own and walks up slopes to 60 deg.
- Stairs: riser at most 0.2 m, tread at least 0.28 m, width at least 0.9 m, headroom at least 2.1 m measured above each tread. In the tower, a spiral or a switchback against the wall is fine if it meets these. Put a landing at least 1.0 x 1.0 m at the top and bottom of every flight and wherever the stairs change direction.
- No gaps the capsule can fall through, and no steps without a solid riser under the tread.

GEOMETRY RULES
- Every part is a closed box or prism mesh with outward normals: no coplanar overlapping faces (they z-fight) and no zero-thickness faces.
- Walls 0.2 m thick. Doorways are real gaps in the wall, not separate parts placed over a wall.
- Name parts with a level prefix as in v1 (B1_, G_, L1_, Tower_, Lantern_). Name every marker part *_marker and make it a 0.3 m cube sitting on the floor.
- Markers:
  - G_entry_marker (just inside the door)
  - G_ted_greeting_marker
  - G_window_view_marker (where the player stands to look at the dock)
  - B1_boiler_interaction_marker
  - B1_coal_pickup_marker
  - B1_daniel_marker
  - Lantern_arc_lamp_socket_marker (the socket centre, at the height the burner's base sits)
  - Lantern_ted_marker
- No materials are needed. Keep the part count under 400.

ALIGNMENT FILE (`lighthouse_greybox_v2_alignment.json`)
Same fields as v1, plus:
- ground_floor_y, basement_floor_y, upper_floor_y and lantern_floor_y
- the entry door's centre, normal and width, copied from above
- every marker's name and centre
- a list of the checks you ran (below), each with its result

CHECKS TO RUN IN THE SCRIPT BEFORE SAVING (print each result)
- The door opening is clear: a 1.8 x 3.0 m box 0.3 m deep behind the door plane intersects no part.
- The door swing quarter circle is clear.
- No part lies outside the heightmap footprint (with the 0.3 m margin) or above the heightmap's roof height at its x, z.
- No tower part is outside radius (outer - 0.4).
- Every stair riser is at most 0.2 m, every tread at least 0.28 m, and the headroom over each tread at least 2.1 m.
- The capsule can walk from G_entry_marker to B1_daniel_marker and to Lantern_arc_lamp_socket_marker. A coarse voxel flood fill at 0.1 m is enough.
