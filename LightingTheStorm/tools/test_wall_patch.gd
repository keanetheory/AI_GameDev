# test_wall_patch.gd - run: Godot --headless --path . --script res://tools/test_wall_patch.gd
# The holes in the tower's exterior wall are closed with copies of the wall (scripts/world/wall_patch.gd, baked by tools/bake_wall_patch.gd): the baked copies are
# loaded into the exterior, and none of them lies inside the tower's lining (they are a thin outer skin, so they cannot clip the interior).
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 12:
		return false
	var wp = _lv.get_node("InteriorRooms/WallPatch")
	var fails := 0
	var ok: bool = wp.built and wp.patched_cells > 0
	print(("PASS  " if ok else "FAIL  ") + "the baked wall copies are in the exterior (%d cells)" % wp.patched_cells)
	fails += int(not ok)
	var n := 0
	var inside := 0
	var lh := _lv.get_node("Lighthouse") as Node3D
	for c in lh.get_node("convert").get_children():
		if String(c.name).begins_with("WallPatch_"):
			n += 1
			var mi := c as MeshInstance3D
			var v: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for p in v:
				var l := lh.to_local(mi.global_transform * p)
				var r := Vector2(l.x - 3.5, l.z - 3.6).length()
				if r < 2.6 and l.y > 4.0:
					inside += 1
	ok = n > 0
	print(("PASS  " if ok else "FAIL  ") + "%d patch mesh instances under the exterior" % n)
	fails += int(not ok)
	ok = inside == 0
	print(("PASS  " if ok else "FAIL  ") + "no patch vertex lies inside the tower's lining radius (%d)" % inside)
	fails += int(not ok)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
