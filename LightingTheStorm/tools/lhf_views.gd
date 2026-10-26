# lhf_views.gd - the fixed set of interior camera positions shared by the lighthouse probes (probe_rain_render, probe_lighting).
# Every room of the lighthouse, standing at eye height; each view looks at a wall, ceiling or floor (not at a window or the sky).
# tower(y, r, bearing_deg): a point in the tower's frame (axis at local 3.5, 3.6; bearing from +x toward +z); house(u, y, v): kit.gd frame.
extends RefCounted

const TOWER := Vector2(3.5, 3.6)


static func tower(lh: Node3D, y: float, r: float, bearing_deg: float) -> Vector3:
	var a := deg_to_rad(bearing_deg)
	return lh.to_global(Vector3(TOWER.x + cos(a) * r, y, TOWER.y + sin(a) * r))


static func house(rooms: Node, u: float, y: float, v: float) -> Vector3:
	return rooms.frame.to_global(Vector3(u, y, -v))


## [{name, room, from, to}] - `to` is the point looked at. Rooms: the id used by the lighting probe.
static func views(lv: Node) -> Array:
	var lh := lv.get_node("Lighthouse") as Node3D
	var rooms := lv.get_node("InteriorRooms")
	var out: Array = []
	var eye := 1.6
	# tower floors (Lighthouse-local y: ground 0.97, L1 5.2, L2 9.435, lantern floor 17.9). The camera stands on the stair's inner strip or the ring.
	out.append({"name": "tower_ground", "room": "tower_G", "from": tower(lh, 0.97 + eye, 1.6, 250.0), "to": tower(lh, 0.97 + eye, 3.3, 250.0)})
	out.append({"name": "tower_L1", "room": "tower_L1", "from": tower(lh, 5.2 + eye, 1.7, 250.0), "to": tower(lh, 5.2 + eye, 3.3, 250.0)})
	out.append({"name": "tower_L2_ring", "room": "tower_L2", "from": tower(lh, 9.435 + eye, 2.6, 250.0), "to": tower(lh, 9.435 + eye, 3.4, 250.0)})
	out.append({"name": "tower_L2_up", "room": "tower_L2", "from": tower(lh, 9.435 + eye, 2.6, 250.0), "to": tower(lh, 9.435 + 5.0, 3.2, 250.0)})
	out.append({"name": "tower_L2_down", "room": "tower_L2", "from": tower(lh, 9.435 + eye, 2.6, 250.0), "to": tower(lh, 9.435 - 1.5, 2.9, 20.0)})
	out.append({"name": "tower_L2_b60", "room": "tower_L2", "from": tower(lh, 9.435 + eye, 1.4, 60.0), "to": tower(lh, 9.435 + eye, 3.4, 60.0), "grey_palette": true})
	out.append({"name": "tower_L2_b147", "room": "tower_L2", "from": tower(lh, 9.435 + eye, 1.4, 147.0), "to": tower(lh, 9.435 + eye, 3.4, 147.0), "grey_palette": true})
	out.append({"name": "tower_L1_b147", "room": "tower_L1", "from": tower(lh, 5.2 + eye, 2.4, 147.0), "to": tower(lh, 5.2 + eye, 3.3, 147.0)})
	out.append({"name": "tower_mid_stair", "room": "tower_stair", "from": tower(lh, 13.0, 1.6, 60.0), "to": tower(lh, 13.0, 3.1, 60.0)})
	out.append({"name": "lamp_room", "room": "lamp_room", "from": tower(lh, 17.9 + eye, 1.4, 200.0), "to": tower(lh, 17.9 + eye, 2.6, 200.0)})
	# house (kit frame: u along the front wall, v inward, y model height; L1 slab at 5.2)
	out.append({"name": "hall", "room": "house_G", "from": house(rooms, 1.0, 0.97 + eye, 3.0), "to": house(rooms, -2.5, 0.97 + eye, 3.0)})
	out.append({"name": "house_L1", "room": "house_L1", "from": house(rooms, 0.5, 5.2 + eye, 4.0), "to": house(rooms, 4.5, 5.2 + eye, 4.0)})
	out.append({"name": "house_L1_b", "room": "house_L1", "from": house(rooms, 3.5, 5.2 + eye, 6.0), "to": house(rooms, 0.5, 5.2 + eye, 6.0)})
	out.append({"name": "house_attic", "room": "house_L1", "from": house(rooms, 0.5, 5.2 + eye, 5.0), "to": house(rooms, 1.2, 8.4, 5.0)})
	# basement: floor y of the basement comes from the boiler anchor
	var boiler := Vector3.ZERO
	for a in lv.get_tree().get_nodes_in_group("lhi_anchor"):
		if a.get_meta("role") == "boiler_interaction":
			boiler = (a as Node3D).global_position
	out.append({"name": "basement", "room": "basement", "from": boiler + Vector3(0, eye, 0), "to": boiler + Vector3(-3.0, eye, 0)})
	# the view the creator called washed out (stairwell seen from the hall) and its counterpart (the basement from the stair, "properly coloured")
	out.append({"name": "stair_down_view", "room": "stairwell", "from": house(rooms, 2.2, 0.97 + 2.0, 1.0), "to": house(rooms, 2.2, 0.0, 4.0), "frame_stats": true})
	out.append({"name": "basement_from_stair", "room": "basement", "from": boiler + Vector3(-1.5, 3.0, 1.0), "to": boiler + Vector3(0.0, 0.5, -1.0), "frame_stats": true})
	# positive control: on the open ground 6 m out from the front door, away from the lighthouse. Rain MUST show here or the probe is blind.
	var door := Vector3.ZERO
	for a in lv.get_tree().get_nodes_in_group("lhi_anchor"):
		if a.get_meta("role") == "door_outside":
			door = (a as Node3D).global_position
	var away := door - lh.to_global(Vector3(TOWER.x, 0.0, TOWER.y))
	away.y = 0.0
	door += away.normalized() * 6.0
	out.append({"name": "CONTROL_outside", "room": "outside", "from": door + Vector3(0, eye, 0), "to": door, "control": true})
	return out
