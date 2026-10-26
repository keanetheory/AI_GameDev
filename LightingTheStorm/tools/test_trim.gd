# test_trim.gd - run: Godot --headless --path . --script res://tools/test_trim.gd
# LHF-15: the trim (trim.gd) is built, is entirely non-solid (no new collision), stays inside the house, and no joist or beam trim
# crosses the stairwell openings (the ground-floor hole u 0.8..3.6, v 2.3..5.7).
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 10:
		return false
	var rooms := _lv.get_node("InteriorRooms")
	var tr = rooms.trim
	var fails := 0
	var n: int = tr.built
	print(("PASS  " if n >= 100 else "FAIL  ") + "trim pieces built: %d" % n)
	fails += int(n < 100)
	var g: Node3D = tr.group
	var bodies := g.find_children("*", "CollisionObject3D", true, false).size()
	print(("PASS  " if bodies == 0 else "FAIL  ") + "the trim adds no collision (%d bodies)" % bodies)
	fails += int(bodies > 0)
	var frame: Node3D = rooms.frame
	var outside := 0
	var in_hole := 0
	for c in g.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		var p := frame.to_local(mi.global_transform * mi.mesh.get_aabb().get_center())     # the bounds' centre, not the node origin (the gables' vertices are in frame coordinates)
		var u := p.x
		var v := -p.z
		if u < -3.2 or u > 5.75 or v < 0.2 or v > 9.1:
			outside += 1
		var sz: Vector3 = mi.mesh.get_aabb().size
		# a piece centred over the stairwell hole at the ground floor height is a fault
		if u > 0.85 and u < 3.55 and v > 2.35 and v < 5.65 and p.y > 0.0 and p.y < 5.0:
			in_hole += 1
	print(("PASS  " if outside == 0 else "FAIL  ") + "every trim piece is inside the house (%d outside)" % outside)
	fails += int(outside > 0)
	print(("PASS  " if in_hole == 0 else "FAIL  ") + "nothing hangs in the stairwell hole (%d)" % in_hole)
	fails += int(in_hole > 0)
	for nm in ([] if OS.get_environment("LHF_SHELL") == "2" else ["L1_Gable_W", "L1_Gable_E"]) + ["G_SkirtWest_P", "G_CorniceFront_0", "L1_SkirtW1E_P", "B_PierW_0", "B_Drain", "L1_Hearth", "L1_Tile_0_0"]:
		var ok := g.get_node_or_null(nm) != null
		print(("PASS  " if ok else "FAIL  ") + nm)
		fails += int(not ok)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
