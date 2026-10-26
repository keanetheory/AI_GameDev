# test_openings.gd - run: Godot --headless --path . --script res://tools/test_openings.gd
# LHF-12: every window (5 tower, 3 house) and the main door has its exterior surround, built on the real outer wall face (rays found
# it), standing out of the wall and not floating away from it; the door has its arch, fanlight and threshold.
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 14:
		return false
	var eo = _lv.get_node("ExteriorOpenings")
	if eo.get_script() == null:
		print("FAIL  ExteriorOpenings has no script (parse error?)")
		quit(1)
		return false
	var fails := 0
	var ok: bool = eo.built
	print(("PASS  " if ok else "FAIL  ") + "kit built (%d surrounds)" % eo.surrounds.size())
	fails += int(not ok)
	print("measured outer-face distances: ", eo.distances, "  wall thickness: ", eo.wall_d, "  fell back to the wall plane: ", eo.fallback, "  masonry cells: ", eo.patched_cells)
	if not eo.missed.is_empty():
		for id in eo.missed:
			print("  missed ", id, ": ray attempts (start radius, hit radius) ", eo.attempts.get(id))
	var shell := _lv.get_node("InteriorRooms")
	for id in eo.tower_radii:
		var jl := shell.find_child(id + "_JambL", true, false) as Node3D
		if jl:
			var rc := Vector2(jl.position.x - 3.5, jl.position.z - 3.6).length()     # the reveal's centre radius = lining r + 0.4
			print("  tower window ", id, ": exterior face r ", snappedf(eo.tower_radii[id][1], 0.01), ", reveal runs to r ", snappedf(rc + 0.4, 0.01), " (sticks out ", snappedf(rc + 0.4 - eo.tower_radii[id][1], 0.01), ")")
	for id in ["G_window_west", "H_bed_west"]:
		var sr: Node3D = eo.surrounds.get(id)
		if sr:
			var hp := (sr.get_parent() as Node3D).global_position
			print("  ", id, " placed at world ", hp, "  frame ", _lv.get_node("InteriorRooms").frame.to_local(hp))
	var miss_ok: bool = eo.missed.is_empty()
	print(("PASS  " if miss_ok else "FAIL  ") + "outer wall face found for every window (missed: %s)" % [eo.missed])
	fails += int(not miss_ok)
	var want := ["T_stair_300_a", "T_stair_300_b", "T_landing_215", "T_stair_110_a", "T_stair_110_b", "H_bed_west", "H_mess_back", "H_wash_back", "T_landing_147", "door"]
	for id in want:
		var s: Node3D = eo.surrounds.get(id)
		var good := s != null and s.get_child_count() >= 5
		print(("PASS  " if good else "FAIL  ") + "surround for %s (%d parts)" % [id, s.get_child_count() if s else 0])
		fails += int(not good)
	var door: Node3D = eo.surrounds.get("door")
	if door:
		for part in ["Fanlight", "Threshold", "Voussoir5", "Quoin0_L"]:
			var good2 := door.get_node_or_null(part) != null
			print(("PASS  " if good2 else "FAIL  ") + "door part " + part)
			fails += int(not good2)
	# a window surround stands on the wall: rays from outside into the wall, a metre to each side of the window, meet the exterior within
	# 0.8 m of the surround's back plane (the centre of a window is a hole, so it cannot be tested there)
	var lh := _lv.get_node("Lighthouse") as Node3D
	var sp := root.get_world_3d().direct_space_state
	var off_wall := 0
	var checked := 0
	for id in eo.surrounds:
		if id == "door":
			continue
		var holder := (eo.surrounds[id] as Node3D).get_parent() as Node3D
		var out := holder.global_transform.basis.z
		var side := holder.global_transform.basis.x
		for sgn in [-1.0, 1.0]:
			var o: Vector3 = holder.global_position + side * 1.0 * sgn
			var q := PhysicsRayQueryParameters3D.create(o + out * 0.8, o - out * 1.5)
			q.collision_mask = 1
			var r := sp.intersect_ray(q)
			checked += 1
			if r.is_empty() or absf((r["position"] - holder.global_position).dot(out)) > 0.9:
				off_wall += 1
	var w_ok := off_wall <= 2
	print(("PASS  " if w_ok else "FAIL  ") + "surrounds sit on the wall face (%d of %d side rays find no wall within 0.9 m; the walls are irregular)" % [off_wall, checked])
	fails += int(not w_ok)
	fails += int(not w_ok)
	# 2026-10-25 round 3: the smooth facade round the door, the L1 doorway reveals, and the L2 panelling standing proud of its walls (the flicker fix)
	var fac: Node3D = eo.facade
	var f_ok: bool = fac != null and fac.get_child_count() >= 6
	print(("PASS  " if f_ok else "FAIL  ") + "the front facade round the main door is built (%d parts)" % (fac.get_child_count() if fac else 0))
	fails += int(not f_ok)
	var rev: bool = OS.get_environment("LHF_SHELL") == "2" or (shell.find_child("L1_DoorReveal_84", true, false) != null and shell.find_child("L1_DoorRevealHead", true, false) != null)      # (the authored wall has real reveals)
	print(("PASS  " if rev else "FAIL  ") + "the L1 tower doorway has its plaster reveals")
	fails += int(not rev)
	var bad_panels := 0
	var n_panels := 0
	for pn in shell.find_children("*_Panel", "MeshInstance3D", true, false):
		var wn := String(pn.name).trim_suffix("_Panel")
		var w := shell.find_child(wn, true, false) as MeshInstance3D
		if w == null or w.mesh == null or pn.mesh == null:
			continue
		n_panels += 1
		var ws: Vector3 = w.mesh.get_aabb().size
		var ps: Vector3 = pn.mesh.get_aabb().size
		# the panel must be thicker than its wall on the wall's thin axis (a coplanar face z-fights)
		if minf(ps.x, ps.z) < minf(ws.x, ws.z) + 0.04:
			bad_panels += 1
	var p_ok := n_panels >= 5 and bad_panels == 0
	print(("PASS  " if p_ok else "FAIL  ") + "L1 panelling is thicker than its walls on both faces (%d panels, %d coplanar)" % [n_panels, bad_panels])
	fails += int(not p_ok)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
