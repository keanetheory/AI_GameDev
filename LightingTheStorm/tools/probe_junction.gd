extends SceneTree
# probe_junction.gd - what stands between the house and the tower at ground, first-floor and second-floor heights?
# Rays from inside the house toward the tower along the house's +u axis; prints where each hits, in house-frame u.
# Run: Godot --headless --path . --script res://tools/probe_junction.gd

const OFF := Vector3(5, 9.61, -8.5)
const SILL := Vector3(-3.494, 0.0, 8.874)
const U := Vector3(0.9024, 0.0, -0.4309)
const V := Vector3(-0.4309, 0.0, -0.9024)
var _f := 0


func _hw(u: float, y: float, v: float) -> Vector3:
	return OFF + SILL + U * u + V * v + Vector3(0, y, 0)


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var sp := root.get_world_3d().direct_space_state
	for y in [2.0, 3.0, 4.5, 5.6, 6.2, 6.8, 7.4, 8.2, 9.8, 10.6]:
		var row := []
		for v in [0.6, 1.0, 1.5, 2.0, 2.5, 3.5, 5.0]:
			var a := _hw(3.5, y, v)
			var q := PhysicsRayQueryParameters3D.create(a, a + U * 7.0)
			var r := sp.intersect_ray(q)
			row.append(snappedf(3.5 + a.distance_to(r["position"]), 0.01) if not r.is_empty() else -1.0)
		print("y %.1f  hit u at v=[0.6,1,1.5,2,2.5,3.5,5]: %s" % [y, str(row)])
	print("-- L1 bounds: rays at y=6.2 from the house middle --")
	for y in [5.6, 6.4]:
		for v in [1.5, 3.0, 4.5, 6.0]:
			var a3 := _hw(1.5, y, v)
			var rw := sp.intersect_ray(PhysicsRayQueryParameters3D.create(a3, a3 - U * 8.0))
			var re := sp.intersect_ray(PhysicsRayQueryParameters3D.create(a3, a3 + U * 8.0))
			print("  y %.1f v %.1f: west wall at u=%s east wall at u=%s" % [y, v, str(snappedf(1.5 - a3.distance_to(rw["position"]), 0.01)) if not rw.is_empty() else "none", str(snappedf(1.5 + a3.distance_to(re["position"]), 0.01)) if not re.is_empty() else "none"])
		for u in [-1.5, 0.0, 2.0, 4.0]:
			var a4 := _hw(u, y, 3.5)
			var rb := sp.intersect_ray(PhysicsRayQueryParameters3D.create(a4, a4 - V * 8.0))
			var rf := sp.intersect_ray(PhysicsRayQueryParameters3D.create(a4, a4 + V * 8.0))
			print("  y %.1f u %.1f: front wall at v=%s back wall at v=%s" % [y, u, str(snappedf(3.5 - a4.distance_to(rb["position"]), 0.01)) if not rb.is_empty() else "none", str(snappedf(3.5 + a4.distance_to(rf["position"]), 0.01)) if not rf.is_empty() else "none"])
	print("-- upward from the first-floor level: roof height above floor spots (house frame u,v) --")
	for v in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]:
		var row2 := []
		for u in [-1.5, 0.0, 1.5, 3.0, 4.5]:
			var a2 := _hw(u, 5.3, v)
			var q2 := PhysicsRayQueryParameters3D.create(a2, a2 + Vector3.UP * 6.0)
			var r2 := sp.intersect_ray(q2)
			row2.append(snappedf(r2["position"].y - a2.y, 0.01) if not r2.is_empty() else -1.0)
		print("v %.1f  headroom above y5.3 at u=[-1.5,0,1.5,3,4.5]: %s" % [v, str(row2)])
	quit()
	return false
