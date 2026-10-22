extends SceneTree
# probe_tower_intruders.gd - pieces of the exterior model hanging inside the tower stairwell: rays from points on the axis,
# out in every direction (a sphere of rays), reporting hits of the Lighthouse node's collision (not InteriorRooms) closer
# than the lining. Prints bearing / height / radius in tower terms. Run: Godot --headless --path . --script res://tools/probe_tower_intruders.gd
const OFF := Vector3(5, 9.61, -8.5)
var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var sp := root.get_world_3d().direct_space_state
	var axis := OFF + Vector3(3.5, 0, 3.6)
	var found := {}
	for y in range(5, 19, 1):
		var from := axis + Vector3(0, float(y) + 0.3, 0)
		for k in 48:
			for e in [-60, -30, 0, 30, 60]:
				var az := deg_to_rad(7.5 * k)
				var el := deg_to_rad(float(e))
				var d := Vector3(cos(az) * cos(el), sin(el), sin(az) * cos(el))
				var r := sp.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + d * 2.7))
				if r.is_empty():
					continue
				var chain := ""
				var c: Node = r["collider"]
				while c != null and c != root:
					chain = String(c.name) + "/" + chain
					c = c.get_parent()
				if not chain.contains("/Lighthouse/"):
					continue
				var p: Vector3 = r["position"] - axis
				var key := "bearing %3d  y %4.1f  r %.2f" % [snappedi(rad_to_deg(atan2(p.z, p.x)), 15) % 360, snappedf(p.y + 0.0 + float(y) * 0.0 + (axis.y - OFF.y) * 0.0, 0.5) + (axis.y - OFF.y) + 0.0, Vector2(p.x, p.z).length()]
				found[key] = found.get(key, 0) + 1
	var keys := found.keys()
	keys.sort()
	print("intruders: ", keys.size())
	for k in keys.slice(0, 60):
		print("  ", k)
	quit()
	return false
