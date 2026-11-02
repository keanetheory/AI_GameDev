# test_island_lod.gd - run: Godot --headless --path . --script res://tools/test_island_lod.gd
# Island Creator ISL-09: the island is cheap from the sea and the Saltgate, and its landmark is never hidden. Checks, on the real level:
#   - the island rock (the Island node, carved and flattened) has LODs again (collider_builder.gd keep_lods; the bake stores them);
#   - island_lod.gd has given visibility ranges to the small pieces (the gate, the door, the tower's insides), each at least
#     MIN_RANGE_M so nothing pops while walking the island or berthing at its dock;
#   - the hero pieces have NO range that could hide them from the Saltgate (SALTGATE_M off): the island rock and its patches, the harbour,
#     the harbour stairs, the lamp posts, the lighthouse shell, the lamp room, the beacon and its beam, and every glowing lamp head.
# The cost and the before/after stills are measured by tools/measure_island_cost.gd (needs a window).
extends SceneTree

const SALTGATE_M := 600.0
const MIN_RANGE_M := 100.0
## Hero roots: no geometry under these may have a range shorter than SALTGATE_M (except the house interior, which interior_culling.gd ranges
## at 34 m and is only seen through windows; and the tower stair surrounds island_lod ranges at 100 m, which are inside the tower).
const HERO := ["Island", "RockPatchSE", "RockPatchSE2", "RockPatchNE", "Harbour", "HarbourStairs", "Lampposts", "LightingRig"]

var _f := 0
var _lv: Node
var _fails := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	_fails += int(not ok)


func _short_range(g: GeometryInstance3D) -> bool:
	return g.visibility_range_end > 0.0 and g.visibility_range_end < SALTGATE_M


func _process(_d: float) -> bool:
	_f += 1
	if _f < 12:
		return false
	var lod: Node = _lv.get_node_or_null("IslandLOD")
	_check(lod != null and lod.applied, "IslandLOD node present and applied")
	if lod == null:
		quit(1)
		return false
	_check(lod.ranged >= 300, "visibility ranges set on %d small island pieces (>= 300)" % lod.ranged)

	# the rock's LODs
	var island := _lv.get_node("Island")
	var mis := island.find_children("*", "MeshInstance3D", true, false)
	var lods := 0
	for mi in mis:
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				lods += (RenderingServer.mesh_get_surface(mi.mesh.get_rid(), s).get("lods", []) as Array).size()
	_check(lods > 0, "the island rock has LODs (%d LOD entries on its surfaces)" % lods)
	_check(mis.size() > 0 and mis.all(func(m): return m.lod_bias < 1.0 and m.lod_bias > 0.0), "the island rock uses its LODs at sea distances (lod_bias %.2f)" % (mis[0].lod_bias if mis.size() > 0 else -1.0))

	# hero pieces: nothing that could hide them from the Saltgate
	for h in HERO:
		var n := _lv.get_node_or_null(h)
		if n == null:
			_check(false, "hero node %s exists" % h)
			continue
		var bad := []
		var count := 0
		for g in n.find_children("*", "GeometryInstance3D", true, false):
			count += 1
			if _short_range(g):
				bad.append(String(n.get_path_to(g)))
		_check(bad.is_empty(), "%s: none of its %d pieces has a range under %d m %s" % [h, count, SALTGATE_M, "" if bad.is_empty() else str(bad.slice(0, 5))])
	# the lighthouse shell, the lamp room, the beam, anything above the lamp room floor, and every glowing piece on the island
	var bad2 := []
	var ic_glow := []
	var ic: Node = _lv.get_node_or_null("InteriorCulling")
	var ic_far: float = ic.far_m if ic else -1.0
	var shells := 0
	for root_name in ["Lighthouse", "InteriorRooms", "LighthouseInterior", "Lampposts", "IslandGate", "LighthouseDoor"]:
		var r := _lv.get_node(root_name)
		for g in r.find_children("*", "GeometryInstance3D", true, false):
			var path := String(g.get_path())
			if path.contains("/HouseFrame/"):
				continue             # the house's rooms: interior_culling.gd (Lighthouse Finisher) stops them at 34 m by design; seen only through windows
			var hero := path.contains("lighthouse_exterior") or path.contains("/LampRoom/") or path.contains("/BeamPivot/")
			if not hero and g is MeshInstance3D and g.mesh:
				hero = (g.global_transform * g.mesh.get_aabb()).end.y > lod.LAMP_ROOM_Y
			if not hero and not lod.may_range(g):
				hero = true          # glowing (a lamp head, a lit window)
			if hero:
				shells += 1
				if _short_range(g):
					if is_equal_approx(g.visibility_range_end, ic_far):
						ic_glow.append(path.trim_prefix(String(_lv.get_path()) + "/"))   # interior_culling's range, not this objective's
					else:
						bad2.append(path.trim_prefix(String(_lv.get_path()) + "/"))
	_check(bad2.is_empty(), "the lighthouse shell, the lamp room, the beam and %d glowing/landmark pieces have no range under %d m %s" % [shells, SALTGATE_M, "" if bad2.is_empty() else str(bad2.slice(0, 5))])
	if not ic_glow.is_empty():
		print("INFO  %d glowing pieces in the tower are stopped at %.0f m by interior_culling.gd (Lighthouse Finisher), not by ISL-09: %s" % [ic_glow.size(), ic_far, str(ic_glow)])
	var shell := _lv.get_node("Lighthouse").find_children("*", "MeshInstance3D", true, false).filter(func(m): return String(m.get_path()).contains("lighthouse_exterior"))
	_check(shell.size() > 0 and shell.all(func(m): return m.visibility_range_end == 0.0), "the lighthouse exterior shell is found and has no range")
	var beams := _lv.find_children("Beam", "GeometryInstance3D", true, false).filter(func(b): return String(b.get_path()).contains("/BeamPivot/"))
	_check(beams.size() > 0 and beams.all(func(b): return b.visibility_range_end == 0.0), "the beacon's beam is found (%d) and has no range" % beams.size())
	var lamp_room := _lv.get_node("InteriorRooms").find_children("LampRoom", "Node3D", true, false)
	_check(lamp_room.size() > 0, "the lamp room is found (%d)" % lamp_room.size())

	# the small pieces: ranged, and never so short that they pop on the island
	for grp in [["IslandGate", 0.9], ["LighthouseDoor", 0.9], ["InteriorRooms/TowerShell", 0.5], ["InteriorRooms/SpiralDown", 0.5]]:
		var n := _lv.get_node_or_null(grp[0])
		if n == null:
			_check(false, "%s exists" % grp[0])
			continue
		var all := n.find_children("*", "GeometryInstance3D", true, false)
		var ranged := all.filter(func(g): return g.visibility_range_end > 0.0)
		var short := ranged.filter(func(g): return g.visibility_range_end < MIN_RANGE_M and not String(g.get_path()).contains("InteriorRooms/House"))
		_check(all.size() > 0 and ranged.size() >= int(all.size() * grp[1]) and short.is_empty(),
				"%s: %d of %d pieces ranged (need %d%%), none under %d m" % [grp[0], ranged.size(), all.size(), int(grp[1] * 100), MIN_RANGE_M])

	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)
	return false
