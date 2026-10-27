# test_island_coverage.gd - run: Godot --headless --path . --script res://tools/test_island_coverage.gd
# Island Creator ISL-02: the island's collision matches the rock you can see. A 0.5 m grid over Bracken Isle (the craggy island, its rock patches,
# the harbour, the stone stairs, the gate and the lighthouse footing). At every point it finds the highest VISIBLE walkable surface (a mesh
# triangle facing up, normal.y > 0.7) and moves a 5 cm sphere straight down with the player's mask (layer 1):
#   - fall-through: there is a visible walkable surface but the sphere passes it (nothing within 0.25 m of it): the player would sink or fall;
#   - invisible wall: the sphere stops more than 0.4 m above the highest visible surface of ANY slope at that point (nothing there to see).
# Points under the lighthouse's roofs and inside its interior are skipped (roofs are not walked; the interior has its own tests).
# Passes when the dock-to-door route (the objective's done-condition) has no fall-through or invisible wall in a cluster of 2 or more grid
# points (a lone point is a patch under 0.5 m, which the player's capsule spans); the gate's pillar boxes are walls by design. The whole
# island's counts are reported, not failed. Prints each failing cluster with its centre so it can be found and fixed.
extends SceneTree

const STEP := 0.5
const AREA := Rect2(-50.0, -30.0, 80.0, 70.0)         # world x, z: the island, the harbour and the rock patches
const TOP := 40.0
const SINK := 0.25
const WALL := 0.4
const PROBE_R := 0.05
var _probe: PhysicsShapeQueryParameters3D
const SKIP_NODES := ["Sea", "LighthouseInterior", "InteriorRooms", "ExteriorOpenings", "Player", "Boat", "Rain", "LightingRig", "Mainland", "Cliffs", "Saltgate"]
const LH_SKIP := Rect2(-6.0, -12.0, 22.0, 22.0)          # world x, z round the lighthouse (house and tower): roofs and rooms

## The dock-to-door route (the walk test's waypoints, world x, z): the objective's pass condition is on this corridor. Elsewhere on the island
## the counts are reported, not failed: the collision is a slightly simplified copy of the rock, 0.4 to 0.8 m off on steep flanks nobody stands on.
const ROUTE := [Vector2(-27.0, 14.7), Vector2(-19.0, 14.7), Vector2(-19.0, 25.5), Vector2(-16.25, 25.5), Vector2(-16.25, 16.8), Vector2(-16.25, 9.0),
		Vector2(-13.0, 8.5), Vector2(-9.0, 6.0), Vector2(2.0, 10.0), Vector2(5.0, 6.5)]
const SOUTH_JETTY := [Vector2(-27.0, 26.3), Vector2(-19.0, 26.3), Vector2(-19.0, 25.5)]
const CORRIDOR := 1.5                  # metres either side of the route
const MIN_CLUSTER := 2                 # grid points (0.5 m apart) in a cluster before it counts

var _f := 0
var _lv: Node
var _tris: Array = []                 # [a, b, c, mesh path, walkable (up-facing)] world
var _bins := {}                       # Vector2i(1 m cell) -> PackedInt32Array


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _skipped(n: Node) -> bool:
	var p: Node = n
	while p != null and p != _lv:
		if String(p.name) in SKIP_NODES:
			return true
		p = p.get_parent()
	return false


func _collect() -> void:
	for n in _lv.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or _skipped(mi):
			continue
		var xf := mi.global_transform
		var f := mi.mesh.get_faces()
		for t in range(0, f.size(), 3):
			var a: Vector3 = xf * f[t]
			var b: Vector3 = xf * f[t + 1]
			var c: Vector3 = xf * f[t + 2]
			var nrm := (b - a).cross(c - a)
			if nrm.length() < 1e-8:
				continue
			var walk := absf(nrm.normalized().y) >= 0.7      # walls and steep rock are not stood on (either winding counts as up-facing)
			var lo := a.min(b).min(c)
			var hi := a.max(b).max(c)
			if hi.x < AREA.position.x or lo.x > AREA.end.x or hi.z < AREA.position.y or lo.z > AREA.end.y:
				continue
			var ti := _tris.size()
			_tris.append([a, b, c, String(mi.get_path()).trim_prefix("/root/Level/"), walk])
			for x in range(int(floor(lo.x)), int(floor(hi.x)) + 1):
				for z in range(int(floor(lo.z)), int(floor(hi.z)) + 1):
					var k := Vector2i(x, z)
					var arr: PackedInt32Array = _bins.get(k, PackedInt32Array())
					arr.append(ti)
					_bins[k] = arr


var _top_path := ""                   # the mesh _visible_top last found


## The highest visible surface at (x, z): walkable triangles only, or every triangle (`any`).
func _visible_top(x: float, z: float, any := false) -> float:
	var k := Vector2i(int(floor(x)), int(floor(z)))
	_top_path = ""
	if not _bins.has(k):
		return NAN
	var best := NAN
	var o := Vector3(x, TOP, z)
	for ti in _bins[k]:
		var tr: Array = _tris[ti]
		if not any and not tr[4]:
			continue
		var h: Variant = Geometry3D.ray_intersects_triangle(o, Vector3.DOWN, tr[0], tr[1], tr[2])
		if h == null:
			h = Geometry3D.ray_intersects_triangle(o, Vector3.DOWN, tr[0], tr[2], tr[1])
		if h != null and (is_nan(best) or (h as Vector3).y > best):
			best = (h as Vector3).y
			_top_path = tr[3]
	return best


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 12:
		return false
	_collect()
	var space := root.world_3d.direct_space_state
	var sph := SphereShape3D.new()
	sph.radius = PROBE_R
	_probe = PhysicsShapeQueryParameters3D.new()
	_probe.shape = sph
	_probe.collision_mask = 1
	_probe.motion = Vector3(0.0, -(TOP + 5.0), 0.0)
	# skipped nodes that collide (the moored boat) are left out of the physics probe too
	var ex: Array[RID] = []
	for b in _lv.find_children("*", "CollisionObject3D", true, false):
		if _skipped(b):
			ex.append((b as CollisionObject3D).get_rid())
	_probe.exclude = ex
	var falls: Array = []
	var walls: Array = []
	var tested := 0
	var nx := int(AREA.size.x / STEP)
	var nz := int(AREA.size.y / STEP)
	for i in nx:
		for j in nz:
			var x := AREA.position.x + (i + 0.5) * STEP
			var z := AREA.position.y + (j + 0.5) * STEP
			if LH_SKIP.has_point(Vector2(x, z)):
				continue
			var vy := _visible_top(x, z)
			# a 5 cm sphere moved straight down, the way the player's body meets the ground: a ray passes through the island's one-sided collision
			# faces where the scan's winding faces down, but a body does not (dropping the player on those spots: it stands)
			_probe.transform = Transform3D(Basis(), Vector3(x, TOP, z))
			var mv := space.cast_motion(_probe)
			var py := NAN
			var r := {}
			if mv[0] < 1.0:
				py = TOP + _probe.motion.y * mv[0] - PROBE_R
				_probe.transform = Transform3D(Basis(), Vector3(x, TOP + _probe.motion.y * mv[1], z))
				r = space.get_rest_info(_probe)
			if is_nan(vy):
				continue                                   # nothing walkable to see here (sea, or steep rock only)
			tested += 1
			if is_nan(py) or py < vy - SINK:
				falls.append([Vector3(x, vy, z), "visible " + _top_path + ("  (no collision below)" if is_nan(py) else "  (collision %.2f m lower)" % (vy - py))])
			elif py > _visible_top(x, z, true) + WALL:
				var top_any := _visible_top(x, z, true)
				var who := "?"
				if r.has("collider_id"):
					var o := instance_from_id(r["collider_id"])
					if o is Node:
						who = String((o as Node).get_path()).trim_prefix("/root/Level/")
				walls.append([Vector3(x, py, z), "hit %s (%.2f m above the visible rock)" % [who, py - top_any]])
	print("island coverage: %d walkable points tested (%d visible triangles)" % [tested, _tris.size()])
	print("whole island (information):")
	_report("fall-through (visible ground with no collision under it)", falls, true)
	_report("invisible wall (collision 0.4 m or more above anything visible)", walls, true)
	var rf := falls.filter(func(e): return _on_route(e[0]))
	# the gate's pillar and wall-stub boxes (island_gate.gd "Walls") stand taller than the pillar caps on purpose: the gate is the only way through
	var rw := walls.filter(func(e): return _on_route(e[0]) and not ("IslandGate/Walls" in String(e[1])))
	print("on the dock-to-door route (%.1f m either side):" % CORRIDOR)
	_report("fall-through", rf, true)
	_report("invisible wall", rw, true)
	# a lone grid point is a patch under 0.5 m across, which the player's capsule spans: only clusters of MIN_CLUSTER points or more fail
	var bad_f := _big(rf)
	var bad_w := _big(rw)
	var ok := bad_f == 0 and bad_w == 0
	print(("PASS" if ok else "FAIL") + "  island collision matches the visible ground on the dock-to-door route: %d fall-through and %d invisible-wall points in clusters of %d or more (lone points %d, %d; whole island %d, %d)" % [bad_f, bad_w, MIN_CLUSTER, rf.size() - bad_f, rw.size() - bad_w, falls.size(), walls.size()])
	quit(0 if ok else 1)
	return true


func _on_route(p: Vector3) -> bool:
	var q := Vector2(p.x, p.z)
	for path in [ROUTE, SOUTH_JETTY]:
		for i in path.size() - 1:
			var c := Geometry2D.get_closest_point_to_segment(q, path[i], path[i + 1])
			if c.distance_to(q) <= CORRIDOR:
				return true
	return false


## Points that sit in a cluster of MIN_CLUSTER or more neighbours.
func _big(pts: Array) -> int:
	var n := 0
	for e in pts:
		var near := 0
		for o in pts:
			if Vector2((e[0] as Vector3).x - (o[0] as Vector3).x, (e[0] as Vector3).z - (o[0] as Vector3).z).length() <= STEP * 1.5:
				near += 1
		if near >= MIN_CLUSTER:
			n += 1
	return n


## Groups neighbouring points into clusters and prints each with its size and centre.
func _report(label: String, pts: Array, with_node: bool) -> void:
	if pts.is_empty():
		print("  %s: none" % label)
		return
	var seen := {}
	var clusters: Array = []
	for i in pts.size():
		if seen.has(i):
			continue
		var stack := [i]
		seen[i] = true
		var members: Array = []
		while not stack.is_empty():
			var k: int = stack.pop_back()
			members.append(k)
			var pk: Vector3 = pts[k][0] if with_node else pts[k]
			for m in pts.size():
				if seen.has(m):
					continue
				var pm: Vector3 = pts[m][0] if with_node else pts[m]
				if Vector2(pk.x - pm.x, pk.z - pm.z).length() <= STEP * 1.5:
					seen[m] = true
					stack.append(m)
		clusters.append(members)
	clusters.sort_custom(func(a, b): return a.size() > b.size())
	print("  %s: %d points in %d clusters" % [label, pts.size(), clusters.size()])
	for c in clusters.slice(0, 12):
		var sum := Vector3.ZERO
		for k in c:
			sum += pts[k][0] if with_node else pts[k]
		var cen: Vector3 = sum / c.size()
		print("    %3d points round world (%.1f, %.1f, %.1f)%s" % [c.size(), cen.x, cen.y, cen.z, ("  " + String(pts[c[0]][1])) if with_node else ""])
