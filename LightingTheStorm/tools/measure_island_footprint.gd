# measure_island_footprint.gd - run: Godot --headless --path . --script res://tools/measure_island_footprint.gd
# Island Creator ISL-06: the size of Bracken Isle as built, against the lore's "roughly 330 m long and 140 m wide"
# (Docs/Lore Build/regions/reg_bracken_isle.md). Prints the world AABB of the Island node's meshes (the whole rock, the
# underwater skirt included) and the footprint at the waterline (y 0.4, the sea's rest height in island_reactions.gd),
# found by rays straight down on a 1 m grid: the extent of the points where the rock stands above the water.
# Also prints the ground height on rings round the lighthouse (what the beacon's beam would have to reach).
extends SceneTree

const WATER_Y := 0.4

var _lv: Node3D
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var isl := _lv.get_node("Island") as Node3D
	var box := AABB()
	var first := true
	var tris := 0
	for n in isl.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var b := mi.global_transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	print("MESH AABB  x %.1f..%.1f (%.1f m)  y %.1f..%.1f (%.1f m)  z %.1f..%.1f (%.1f m)" % [box.position.x, box.end.x, box.size.x, box.position.y, box.end.y, box.size.y, box.position.z, box.end.z, box.size.z])
	var bodies := {}
	for nm in ["Island", "RockPatchSE", "RockPatchSE2", "RockPatchNE"]:
		for b in _lv.get_node(nm).find_children("*", "StaticBody3D", true, false):
			bodies[b.get_instance_id()] = true
	var space := _lv.get_world_3d().direct_space_state
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	var area := 0
	var top := -1e9
	var top_at := Vector2.ZERO
	var x := floorf(box.position.x)
	while x <= box.end.x:
		var z := floorf(box.position.z)
		while z <= box.end.z:
			var r := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 80, z), Vector3(x, -20, z)))
			if not r.is_empty() and bodies.has((r["collider"] as Object).get_instance_id()) and (r["position"] as Vector3).y > WATER_Y:
				lo = Vector2(minf(lo.x, x), minf(lo.y, z))
				hi = Vector2(maxf(hi.x, x), maxf(hi.y, z))
				area += 1
				if (r["position"] as Vector3).y > top:
					top = (r["position"] as Vector3).y
					top_at = Vector2(x, z)
			z += 1.0
		x += 1.0
	print("WATERLINE FOOTPRINT  x %.0f..%.0f (%.0f m)  z %.0f..%.0f (%.0f m)  area above water ~%d m2  highest rock %.1f m at (%.0f, %.0f)" % [lo.x, hi.x, hi.x - lo.x, lo.y, hi.y, hi.y - lo.y, area, top, top_at.x, top_at.y])
	# the longest extent in any direction (the lore's "long" side need not lie along an axis)
	var best := 0.0
	var best_deg := 0
	for deg in range(0, 180, 5):
		var d := Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg)))
		var mn := 1e9
		var mx := -1e9
		var w_mn := 1e9
		var w_mx := -1e9
		var p := Vector2(-d.y, d.x)
		var gx := lo.x
		while gx <= hi.x:
			var gz := lo.y
			while gz <= hi.y:
				var r := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(gx, 80, gz), Vector3(gx, -20, gz)))
				if not r.is_empty() and bodies.has((r["collider"] as Object).get_instance_id()) and (r["position"] as Vector3).y > WATER_Y:
					var v := Vector2(gx, gz)
					mn = minf(mn, v.dot(d))
					mx = maxf(mx, v.dot(d))
					w_mn = minf(w_mn, v.dot(p))
					w_mx = maxf(w_mx, v.dot(p))
				gz += 2.0
			gx += 2.0
		if mx - mn > best:
			best = mx - mn
			best_deg = deg
			print("  longest so far: %.0f m at bearing %d deg (x towards +z), width across it %.0f m" % [best, deg, w_mx - w_mn])
	# ground round the lighthouse (8.5, -4.9): what the beacon would light
	for ring in [15.0, 25.0, 35.0, 45.0]:
		var hs := []
		for k in 12:
			var a := deg_to_rad(30.0 * k)
			var px: float = 8.5 + cos(a) * ring
			var pz: float = -4.9 - sin(a) * ring
			var r := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(px, 80, pz), Vector3(px, -20, pz)))
			hs.append("%.0f" % ((r["position"] as Vector3).y if not r.is_empty() else -99.0))
		print("GROUND %2.0f m from the lantern, every 30 deg: %s" % [ring, " ".join(hs)])
	quit()
	return true
