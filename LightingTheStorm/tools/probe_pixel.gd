# probe_pixel.gd - run: Godot --headless --path . --script res://tools/probe_pixel.gd -- cx cy cz tx ty tz px py [fov] [w] [h]
# Which node is under a pixel of a shot: casts a ray from the shot camera (same arguments as shoot.sh) through pixel (px, py) and lists every
# mesh instance whose bounds the ray crosses (nearest first), plus the first collider. Meshes without collision (kit parts) show up too.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 14:
		return false
	var a := OS.get_cmdline_user_args()
	var from := Vector3(float(a[0]), float(a[1]), float(a[2]))
	var to := Vector3(float(a[3]), float(a[4]), float(a[5]))
	var px := float(a[6])
	var py := float(a[7])
	var fov := float(a[8]) if a.size() > 8 else 75.0
	var w := float(a[9]) if a.size() > 9 else 1600.0
	var h := float(a[10]) if a.size() > 10 else 900.0
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.fov = fov
	cam.global_position = from
	cam.look_at(to, Vector3.UP)
	var dir := cam.project_ray_normal(Vector2(px, py)) if false else _dir(cam, px, py, w, h, fov)
	var hits := []
	for n in root.get_node("Level").find_children("*", "GeometryInstance3D", true, false):
		var vi := n as GeometryInstance3D
		var box := vi.global_transform * vi.get_aabb()
		var t := _ray_box(from, dir, box)
		if t >= 0.0:
			hits.append([t, String(vi.get_path()).trim_prefix("/root/Level/")])
	hits.sort_custom(func(x, y): return x[0] < y[0])
	for i in mini(40, hits.size()):
		print("  %.2f m  %s" % [hits[i][0], hits[i][1]])
	var sp := root.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 40.0)
	var r := sp.intersect_ray(q)
	var hp := Vector3.ZERO
	if not r.is_empty():
		hp = r["position"]
		print("hit point world ", hp, " normal ", r["normal"], " | house frame ", root.get_node("Level/InteriorRooms").frame.to_local(hp), " | lighthouse local ", root.get_node("Level/Lighthouse").to_local(hp))
	print("first collider: ", "none" if r.is_empty() else "%.2f m %s" % [from.distance_to(r["position"]), String((r["collider"] as Node).get_path()).trim_prefix("/root/Level/")])
	quit()
	return false


func _dir(cam: Camera3D, px: float, py: float, w: float, h: float, fov: float) -> Vector3:
	var th := tan(deg_to_rad(fov) * 0.5)
	var x := ((px / w) * 2.0 - 1.0) * th * (w / h)
	var y := (1.0 - (py / h) * 2.0) * th
	return (cam.global_transform.basis * Vector3(x, y, -1.0)).normalized()


func _ray_box(o: Vector3, d: Vector3, b: AABB) -> float:
	var tmin := 0.0
	var tmax := 1e9
	for i in 3:
		if absf(d[i]) < 1e-8:
			if o[i] < b.position[i] or o[i] > b.end[i]:
				return -1.0
		else:
			var t1 := (b.position[i] - o[i]) / d[i]
			var t2 := (b.end[i] - o[i]) / d[i]
			tmin = maxf(tmin, minf(t1, t2))
			tmax = minf(tmax, maxf(t1, t2))
			if tmin > tmax:
				return -1.0
	return tmin
