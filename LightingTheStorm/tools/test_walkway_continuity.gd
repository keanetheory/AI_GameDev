# test_walkway_continuity.gd - run: Godot --headless --path . --script res://tools/test_walkway_continuity.gd
# The walkway from the Saltgate quay up to the cliff top and on to the plateau, checked three ways:
#  1. floor: a vertical ray at several points across the walkway, every metre, must land on solid floor at about the
#     expected height (no hole to fall through);
#  2. plateau: a grid of vertical rays behind the cliff top, from the walkway's top end to the city road, must all hit ground;
#  3. views: from eye height along the walkway, rays aimed inland must hit the rock wall (no look through to a void).
# tools/test_cliffwalk.gd walks the route with the real player capsule; this one finds the holes it could miss.
extends SceneTree

const MeshRays := preload("res://tools/mesh_rays.gd")
var _lv: Node
var _f := 0
var _fails := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_fails += 1


func _ray(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b)
	q.collision_mask = 0xFFFFFFFF
	q.hit_back_faces = true
	q.hit_from_inside = true     # a ray that starts inside a solid collider still counts as hitting it
	return space.intersect_ray(q)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var main: Node = _lv.get_node("Mainland")
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	# 1. floor
	var n: int = main._gal_y.size()
	var holes := 0
	var off_height := 0
	var checked := 0
	for i in range(0, n - 1):
		for t in [0.15, 0.4, 0.65, 0.9]:
			var depth: float = main._gal_depth[i]
			if depth < 1.0:
				continue
			var p: Vector3 = main._gal_point(i, t)
			checked += 1
			var hit := _ray(space, Vector3(p.x, p.y + 3.0, p.z), Vector3(p.x, p.y - 3.0, p.z))
			if hit.is_empty():
				holes += 1
			else:
				var rise: float = hit["position"].y - p.y
				var limit: float = 0.5 if t < 0.8 else float(main.TOE_HEIGHT) * 1.4 + 0.5     # the back of the floor climbs into the rock toe
				if rise > limit or rise < -0.5:
					off_height += 1
					if off_height <= 5:
						print("  off-height at x %.0f t %.2f: expected y %.2f, ray hit %.2f" % [p.x, t, p.y, hit["position"].y])
	_ok(holes == 0, "walkway floor: %d of %d sample points have solid floor under them (%d holes)" % [checked - holes, checked, holes])
	_ok(off_height == 0, "walkway floor sits at its designed height everywhere (%d points more than 0.5 m off)" % off_height)
	# 2. plateau behind the cliff top
	var misses := 0
	var tested := 0
	var x := -200.0
	while x <= 40.0:
		var z := 576.0
		while z <= 640.0:
			tested += 1
			if _ray(space, Vector3(x, 80.0, z), Vector3(x, -5.0, z)).is_empty():
				misses += 1
			z += 8.0
		x += 8.0
	_ok(misses == 0, "plateau behind the walkway: %d of %d ray points hit ground (%d holes)" % [tested - misses, tested, misses])
	# 3. views from eye height, aimed inland at the wall: tested against the VISIBLE rock (what the player sees). The
	# cliff's physics collider is a little porous to very thin rays, which says nothing about what is on screen.
	var rays = MeshRays.new()
	for mi in _lv.get_node("Cliffs").find_children("*", "MeshInstance3D", true, false):
		rays.add_mesh(mi as MeshInstance3D, -250.0, 60.0)
	var voids := 0
	var views := 0
	for i in range(0, n - 1, 4):
		var p: Vector3 = main._gal_point(i, 0.5)
		if main.cliff_top(p.x) - p.y < 8.0:
			continue       # at the very top of the walkway the wall ends and the open plateau begins
		for dy in [-0.1, 0.05, 0.3, 0.6]:      # straight inland at four pitches (the ray helper needs rays in a constant-x plane)
			views += 1
			var from := Vector3(p.x, p.y + 1.7, p.z)
			if rays.first_hit(from, Vector3(0.0, dy, 1.0).normalized()) == null:
				voids += 1
				if voids <= 6:
					print("  void at x %.0f (pitch %.2f), floor y %.1f, cliff top %.1f" % [p.x, dy, p.y, main.cliff_top(p.x)])
	_ok(voids == 0, "looking inland from the walkway: %d of %d views end on rock, not a void (%d see through)" % [views - voids, views, voids])
	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)
	return false
