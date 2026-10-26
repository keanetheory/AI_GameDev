# probe_wall_planes.gd - run: Godot --headless --path . --script res://tools/probe_wall_planes.gd
# For the first floor and the ground floor, rays from OUTSIDE each house wall in to the exterior: the measured outer-face distance from the
# lining plane at a grid of heights and positions, per wall (median, min, max). Shows where the lining / patches stand beyond the real wall.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 16:
		return false
	var rooms := root.get_node("Level/InteriorRooms")
	var frame: Node3D = rooms.frame
	var sp := root.get_world_3d().direct_space_state
	var lh := root.get_node("Level/Lighthouse")
	var walls := {"west": [Vector3(-1, 0, 0), -3.06, "v", 0.95, 8.7], "back": [Vector3(0, 0, -1), -8.7, "u", -3.06, 5.4], "front": [Vector3(0, 0, 1), -0.88, "u", -3.0, 5.4]}
	for wn in walls:
		var w: Array = walls[wn]
		for yb in [[1.5, 3.4, "ground"], [5.6, 7.2, "first"]]:
			var ds := []
			var miss := 0
			var total := 0
			var at: float = w[3]
			while at <= w[4]:
				var y: float = yb[0]
				while y <= yb[1]:
					var out: Vector3 = w[0]
					var plane: Vector3
					if wn == "west":
						plane = Vector3(w[1], y, -at)
					elif wn == "back":
						plane = Vector3(at, y, w[1])
					else:
						plane = Vector3(at, y, w[1])
					var q := PhysicsRayQueryParameters3D.create(frame.to_global(plane + out * 4.0), frame.to_global(plane - out * 0.5))
					q.collision_mask = 1
					var r := sp.intersect_ray(q)
					total += 1
					if r.is_empty() or not lh.is_ancestor_of(r["collider"]):
						miss += 1
					else:
						ds.append((frame.to_local(r["position"]) - plane).dot(out))
						if wn == "west" and yb[2] == "first" and ds.size() % 7 == 0:
							print("    west first: at %.1f y %.1f -> outer face %.2f from the lining plane (%s)" % [at, y, ds[-1], String((r["collider"] as Node).get_path()).get_slice("/", 3)])
					y += 0.4
				at += 0.4
			ds.sort()
			var med: float = ds[ds.size() / 2] if ds.size() > 0 else -1.0
			print("%-5s %-6s: median %.2f  min %.2f  max %.2f  (%d of %d rays hit the exterior, %d went through a hole)" % [wn, yb[2], med, ds[0] if ds.size() > 0 else -1.0, ds[-1] if ds.size() > 0 else -1.0, ds.size(), total, miss])
	quit()
	return false
