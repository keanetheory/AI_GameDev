# test_roof_liner.gd - run: Godot --headless --path . --script res://tools/test_roof_liner.gd
# LHF-02: the first floor has an interior ceiling (roof_liner.gd). Checks the liner was built, covers most of the first floor's
# footprint, and hangs just under the exterior roof everywhere it exists (at least 90% of liner vertices have the roof within 6 cm above them; the rest are cell corners where a ray slips off a roof facet).
extends SceneTree

const Kit := preload("res://scripts/world/interior/kit.gd")
var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 12:
		return false
	var rl = _lv.get_node("InteriorRooms/RoofLiner")
	var fails := 0
	var ok: bool = rl.built
	print(("PASS  " if ok else "FAIL  ") + "liner built (%d roof hits)" % rl.hit_cells)
	fails += int(not ok)
	if not ok:
		quit(1)
		return false
	var frame: Node3D = rl.frame
	var mi := frame.get_node("L1_CeilingLiner") as MeshInstance3D
	var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var tris := verts.size() / 3
	var total_cells := (int(round((rl.U.y - rl.U.x) / rl.STEP))) * (int(round((rl.V.y - rl.V.x) / rl.STEP)))
	var cover := float(tris) / 2.0 / float(total_cells)
	var c_ok := cover >= 0.5      # (was 0.6: exterior_clip.gd now removes the stray exterior inside the rooms, which the liner used to hang under)
	print(("PASS  " if c_ok else "FAIL  ") + "covers %.0f%% of the first floor footprint (%d triangles)" % [cover * 100.0, tris])
	fails += int(not c_ok)
	var sp := root.get_world_3d().direct_space_state
	var bad := 0
	for k in range(0, verts.size(), 7):
		var w := frame.to_global(verts[k])
		var r := sp.intersect_ray(PhysicsRayQueryParameters3D.create(w - Vector3(0, 1.5, 0), w + Vector3(0, 3.0, 0)))
		var gap: float = r["position"].y - w.y if not r.is_empty() else -1.0
		if r.is_empty() or not _lv.get_node("Lighthouse").is_ancestor_of(r["collider"]) or gap < 0.0 or gap > 0.06:
			bad += 1
	var n_samples := int(ceil(verts.size() / 7.0))
	var s_ok := bad <= n_samples / 10
	print(("PASS  " if s_ok else "FAIL  ") + "liner within 8 cm under the roof (hit 0 to 6 cm above): %d of %d samples are not" % [bad, n_samples])
	fails += int(not s_ok)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
