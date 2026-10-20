# test_cliff_seams.gd - run: Godot --headless --path . --script res://tools/test_cliff_seams.gd
# Looks for gaps in the cliff line, the way a player on the boat would: sweeps horizontal rays at the VISIBLE rock from the
# sea along its whole length, at several heights, and reports every place a ray passes straight through where the
# cliff top says there should be rock (a crack between modules, or a hole). Also checks the modules' world boxes touch.
extends SceneTree

const X_STEP := 0.5
const HEIGHTS := [2.0, 5.0, 8.0, 11.0, 14.0, 17.0, 20.0, 23.0, 26.0]
const FROM_Z := 480.0
const TO_Z := 700.0
## Gaps up to this wide (metres of cliff line) are cracks the eye does not catch from the boat; wider ones fail.
const MAX_GAP_M := 4.0
const DEEPEST_FRONT := 20.0

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


## The deepest front among the module boxes that cover x (the wall's front, not a headland sticking out in front of it):
## a ray that stops more than DEEPEST_FRONT beyond this went through to the back of a module.
func _front(boxes: Array[AABB], x: float) -> float:
	var f := -INF
	for b in boxes:
		if x >= b.position.x and x <= b.end.x:
			f = maxf(f, b.position.z)
	return f if f != -INF else 560.0


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var main: Node = _lv.get_node("Mainland")
	var cliffs: Node = _lv.get_node("Cliffs")
	# 1. module boxes: neighbours along the line must touch or overlap
	var boxes: Array[AABB] = []
	var by_name := {}
	for node in cliffs.get_children():
		var box := AABB()
		var first := true
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var wb: AABB = m.global_transform * m.mesh.get_aabb()
			box = wb if first else box.merge(wb)
			first = false
		if not first:
			boxes.append(box)
			by_name[node.name] = box
	boxes.sort_custom(func(a: AABB, b: AABB) -> bool: return a.position.x < b.position.x)
	var worst := 0.0
	for i in boxes.size() - 1:
		var gap := boxes[i + 1].position.x - boxes[i].end.x
		worst = maxf(worst, gap)
	_ok(worst <= 0.5, "cliff modules touch or overlap along the line (widest gap between module boxes %.2f m, %d modules)" % [worst, boxes.size()])
	# 2. rays through the cliff line. A ray must stop at the FRONT of the rock. One that only stops at the back of the module
	# (more than DEEPEST_FRONT m behind the front there) went through a crack between columns: that is a see-through facade.
	# the VISIBLE rock: ray tests against the real triangles, not the collision shapes
	var rays = MeshRays.new()
	for mi in cliffs.find_children("*", "MeshInstance3D", true, false):
		rays.add_mesh(mi as MeshInstance3D, -400.0, 410.0)
	print("sorted %d cliff triangles for ray tests" % rays.triangles)
	var misses: Array = []
	var tested := 0
	var x := -360.0          # from the first wall module; beyond the last headland the coast simply ends
	while x <= 385.0:
		var top: float = main.cliff_top(x)
		if top > 12.0:     # the cliff exists here (cliff_top is 33 where unknown, so also require a real top)
			for h in HEIGHTS:
				if h >= top - 1.5:
					continue
				tested += 1
				var hit: Variant = rays.first_hit(Vector3(x, h, FROM_Z), Vector3(0, 0, 1))
				var through := hit == null or (hit as Vector3).z > _front(boxes, x) + DEEPEST_FRONT
				if through:
					misses.append(Vector2(x, h))
		x += X_STEP
	# group the misses into runs along x
	var runs := 0
	var longest := 0.0
	var last := -9999.0
	var start := 0.0
	var by_h := {}
	for m in misses:
		by_h[m.y] = by_h.get(m.y, 0) + 1
	misses.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for m in misses:
		if m.x - last > X_STEP * 1.5:
			runs += 1
			start = m.x
		last = m.x
		longest = maxf(longest, last - start + X_STEP)
	var run_list := []
	var cur_s := 0.0
	var cur_l := -9999.0
	for m in misses:
		if m.x - cur_l > X_STEP * 1.5:
			if cur_l > -9000.0:
				run_list.append("%.0f..%.0f" % [cur_s, cur_l])
			cur_s = m.x
		cur_l = m.x
	if cur_l > -9000.0:
		run_list.append("%.0f..%.0f" % [cur_s, cur_l])
	print("miss runs (x): " + ", ".join(run_list))
	print("rays: %d tested, %d passed straight through, in %d run(s); longest run %.0f m; misses by height %s" % [tested, misses.size(), runs, longest, by_h])
	if misses.size() > 0:
		var shown := []
		for i in mini(misses.size(), 12):
			shown.append("(x %.0f, y %.0f)" % [misses[i].x, misses[i].y])
		print("first misses: " + " ".join(shown))
	_ok(longest <= MAX_GAP_M, "no see-through gap wider than %.0f m in the cliff line (longest %.0f m)" % [MAX_GAP_M, longest])
	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)
	return false
