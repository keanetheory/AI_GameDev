extends SceneTree
# probe_ray.gd - what does a ray from a world point hit? Prints the node path, hit point (world and lighthouse-local) and
# whether the hit node is visible. usage: ... --script res://tools/probe_ray.gd -- fx fy fz  tx ty tz  [steps]
# With steps it fans the ray's elevation from 0 to +50 degrees in that many steps.
var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var a := OS.get_cmdline_user_args()
	var from := Vector3(float(a[0]), float(a[1]), float(a[2]))
	var to := Vector3(float(a[3]), float(a[4]), float(a[5]))
	var steps := int(a[6]) if a.size() > 6 else 1
	var sp := root.get_world_3d().direct_space_state
	var flat := Vector3(to.x - from.x, 0, to.z - from.z)
	for i in steps:
		var el := deg_to_rad(50.0 * float(i) / float(maxi(steps - 1, 1)))
		var d := (flat.normalized() * cos(el) + Vector3.UP * sin(el)).normalized() * 12.0
		var q := PhysicsRayQueryParameters3D.create(from, from + d)
		q.hit_back_faces = true
		var r := sp.intersect_ray(q)
		if r.is_empty():
			print("el %.0f: nothing" % rad_to_deg(el))
			continue
		var path := str((r["collider"] as Node).get_path())
		var p: Vector3 = r["position"]
		print("el %.0f: %s at world %s local %s" % [rad_to_deg(el), path.substr(max(path.length() - 70, 0)), str(p.snapped(Vector3(0.01, 0.01, 0.01))), str((p - Vector3(5, 9.61, -8.5)).snapped(Vector3(0.01, 0.01, 0.01)))])
	quit()
	return false
