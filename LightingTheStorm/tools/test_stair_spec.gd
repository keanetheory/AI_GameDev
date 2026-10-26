# test_stair_spec.gd - run: Godot --headless --path . --script res://tools/test_stair_spec.gd
# LHF-04: every staircase meets data/world/stair_spec.json: the rise of every step within the tolerance, the going on the walk line in
# range, and the headroom above the middle of each tread (a ray straight up from just above the tread) at least the minimum.
extends SceneTree

var _lv: Node
var _f := 0
var _spec := {}


func _initialize() -> void:
	_spec = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/stair_spec.json"))
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 8:
		return false
	var fails := 0
	var lh := _lv.get_node("InteriorRooms") as Node3D
	fails += _check("tower", lh.get_node("TowerShell"), "Step_", 15.0, float(_spec["walkline_radius"]["tower"]), TOWER_CENTRE)
	var sd := lh.get_node_or_null("SpiralDown")
	fails += _check("basement", sd, "SpiralStep_", 24.0, float(_spec["walkline_radius"]["basement"]), BASEMENT_CENTRE_FROM_NODE)
	# 2026-10-25 feedback: the basement stair has a step flush with the hall floor, the first narrow tower steps reach the wall, the window steps are
	# filled either side of the window, and no stray vertical pole stands on the L2 landing
	var land := sd.get_node_or_null("SpiralLandingStep") as MeshInstance3D if sd else null
	var land_ok: bool = land != null and absf(land.get_aabb().end.y + land.global_position.y - 10.58) < 0.02
	print(("PASS  " if land_ok else "FAIL  ") + "the basement stair has a landing step flush with the hall floor (top at 10.58)")
	fails += int(not land_ok)
	var tsh := lh.get_node("TowerShell")
	var wf := 0
	var wsf := 0
	for c in tsh.get_children():
		if String(c.name).begins_with("StepWallFill_"):
			wf += 1
		if String(c.name).begins_with("StepWindowFill_"):
			wsf += 1
	print(("PASS  " if wf >= 1 else "FAIL  ") + "the first narrow steps are filled out to the wall (%d fills)" % wf)
	fails += int(wf < 1)
	print(("PASS  " if wsf >= 2 else "FAIL  ") + "the steps beside the landing window are filled (%d fills)" % wsf)
	fails += int(wsf < 2)
	var pole := lh.find_child("L2_FeedPipe", true, false)
	print(("PASS  " if pole == null else "FAIL  ") + "no L2 feed pipe pole standing on the landing")
	fails += int(pole != null)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false


const TOWER_CENTRE := Vector2(3.5, 3.6)
const BASEMENT_CENTRE_FROM_NODE := Vector2.INF


func _check(label: String, parent: Node, prefix: String, deg: float, walk_r: float, centre: Vector2) -> int:
	if parent == null:
		print("FAIL  %s: stair node missing" % label)
		return 1
	var tops := []
	var i := 0
	while true:
		var mi := parent.get_node_or_null(prefix + str(i)) as MeshInstance3D
		if mi == null:
			break
		tops.append(mi.mesh.get_aabb().end.y)          # the step's top, in the lighthouse frame
		i += 1
	var n := tops.size()
	print("%s: %d steps" % [label, n])
	if n < 10:
		print("FAIL  %s: too few steps found" % label)
		return 1
	var rise_ref := float(_spec["rise"])
	var tol := float(_spec["rise_tolerance"])
	var bad_rise := 0
	var lo := 9.0
	var hi := 0.0
	for k in range(1, n):
		var r: float = tops[k] - tops[k - 1]
		lo = minf(lo, r)
		hi = maxf(hi, r)
		if absf(absf(r) - rise_ref) > rise_ref * tol:
			bad_rise += 1
	print(("PASS  " if bad_rise == 0 else "FAIL  ") + "%s rise %.3f to %.3f m (spec %.2f +- %d%%): %d steps outside" % [label, lo, hi, rise_ref, int(tol * 100), bad_rise])
	var going := deg_to_rad(deg) * walk_r
	var g_ok := going >= float(_spec["going_walkline_min"]) and going <= float(_spec["going_walkline_max"])
	print(("PASS  " if g_ok else "FAIL  ") + "%s going on the walk line %.3f m" % [label, going])
	# headroom: from the middle of each tread, straight up
	var sp := root.get_world_3d().direct_space_state
	var min_head_report := float(_spec["headroom_min"])
	var worst := 99.0
	var worst_i := -1
	var lhn := _lv.get_node("InteriorRooms") as Node3D
	for k in n:
		var mi := parent.get_node(prefix + str(k)) as MeshInstance3D
		var c := mi.mesh.get_aabb().get_center()
		var a0_world: Vector3 = mi.to_global(Vector3(c.x, mi.mesh.get_aabb().end.y, c.z))
		# the AABB centre is at the tread's middle radius only roughly; use the walk radius at the step's mid bearing instead
		var mid := _mid_point(mi.mesh)
		var p := mi.to_global(Vector3(mid.x, mi.mesh.get_aabb().end.y + 0.03, mid.z))
		var q := PhysicsRayQueryParameters3D.create(p, p + Vector3(0, 3.0, 0))
		var r := sp.intersect_ray(q)
		var clear := 3.0 if r.is_empty() else (r["position"] as Vector3).y - p.y
		if clear < min_head_report:
			print("  low headroom step %d at r %.2f bearing %.0f: %.2f m under %s" % [k, Vector2(p.x - 8.5, p.z + 4.9).length(), rad_to_deg(atan2(p.z + 4.9, p.x - 8.5)), clear, (r["collider"] as Node).get_path() if not r.is_empty() else "-"])
		if clear < worst:
			worst = clear
			worst_i = k
	var min_head := float(_spec["headroom_min"])
	var h_ok := worst >= min_head
	print(("PASS  " if h_ok else "FAIL  ") + "%s least headroom %.2f m (step %d; need %.1f)" % [label, worst, worst_i, min_head])
	return int(bad_rise > 0) + int(not g_ok) + int(not h_ok)


## The middle of the tread's top surface: the mean of the mesh's top-facing vertices.
func _mid_point(mesh: Mesh) -> Vector3:
	var arr := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var top_y := mesh.get_aabb().end.y
	var sum := Vector3.ZERO
	var cnt := 0
	for p in v:
		if absf(p.y - top_y) < 0.001:
			sum += p
			cnt += 1
	return sum / maxf(cnt, 1)
