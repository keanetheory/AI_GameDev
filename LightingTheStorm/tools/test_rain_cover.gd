# test_rain_cover.gd - run: Godot --headless --path . --script res://tools/test_rain_cover.gd
# LHF finish, rain (CPU side). Every column of the house first floor must have its WHOLE height, floor to the ceiling/roof underside
# found by a ray, covered by the RainShelter boxes, and every point of the tower stairwell out to the wall (ray measured) too.
# Found by tools/probe_rain_render.gd (GPU frames): drops drawn under the roof ridge, above the old house box (top 8.9).
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 6:
		return false
	var rs = _lv.get_node("RainShelter")
	var fr: Node3D = _lv.get_node("InteriorRooms").frame
	var lh := _lv.get_node("Lighthouse") as Node3D
	var space := root.world_3d.direct_space_state
	var fails := 0
	# 1. house: columns inside the shelter's own plan rectangle
	var cols := 0
	var bad := 0
	var worst := 0.0
	var worst_at := ""
	var hist := {}
	var holes := 0
	for ui in range(-11, 21):
		for vi in range(4, 36):
			var u := ui * 0.25 + 0.01
			var v := vi * 0.25 + 0.01
			var lo: Vector3 = fr.to_global(Vector3(u, 5.45, -v))
			var ru := space.intersect_ray(PhysicsRayQueryParameters3D.create(lo, lo + Vector3(0, 12, 0)))
			if ru.is_empty():
				continue
			var under: float = fr.to_local(ru["position"]).y
			cols += 1
			if under > 10.0:
				print("      high hit at u %.2f v %.2f y %.2f on %s" % [u, v, under, str((ru["collider"] as Node).get_path())])
			var hb := int(floor(under))
			hist[hb] = hist.get(hb, 0) + 1
			if under > 10.5:      # no ceiling in this column: the ray went through a hole in the exterior roof to its upper skin. A shell defect, still has to be covered
				holes += 1
			var p: Vector3 = fr.to_global(Vector3(u, under - 0.05, -v))
			if not rs.covers(p):
				bad += 1
				if under > worst:
					worst = under
					worst_at = "u %.2f v %.2f underside y %.2f" % [u, v, under]
	print("%s  house columns with uncovered air under the ceiling/roof: %d of %d  %s" % ["PASS" if bad == 0 else "FAIL", bad, cols, worst_at])
	fails += int(bad > 0)
	print("      columns with no ceiling (a hole in the exterior roof: a shell defect, covered here by the box): %d" % holes)
	print("      underside height histogram (frame y, 1 m buckets): ", hist)
	# 2. tower: points from the axis out to 0.1 m inside the wall (first collider hit on a horizontal ray), every 15 degrees and every half metre of height
	var tpts := 0
	var tbad := 0
	var tworst := ""
	for yi in range(2, 54):
		var y := 0.97 + yi * 0.33
		for k in 24:
			var a := TAU * k / 24.0
			var axis: Vector3 = lh.to_global(Vector3(3.5, y, 3.6))
			var dirv := Vector3(cos(a), 0, sin(a))
			var rh := space.intersect_ray(PhysicsRayQueryParameters3D.create(axis, axis + dirv * 6.0))
			var reach := 6.0 if rh.is_empty() else axis.distance_to(rh["position"])
			if reach > 4.5:
				continue      # a doorway or window opening in that direction
			for rr in [0.5, 1.0, 1.5, 2.0, 2.5, maxf(reach - 0.04, 0.1)]:
				if rr > reach - 0.02:
					continue
				var q: Vector3 = axis + dirv * rr
				var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(q, q + Vector3(0, 30, 0)))
				if up.is_empty():
					continue      # nothing above: the lantern gallery or outside
				tpts += 1
				if not rs.covers(q):
					tbad += 1
					if tworst == "":
						tworst = "e.g. tower y %.2f bearing %d r %.2f (wall at %.2f)" % [y, int(rad_to_deg(a)), rr, reach]
	print("%s  tower interior points not covered: %d of %d  %s" % ["PASS" if tbad == 0 else "FAIL", tbad, tpts, tworst])
	fails += int(tbad > 0)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
