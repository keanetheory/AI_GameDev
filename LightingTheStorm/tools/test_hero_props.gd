# test_hero_props.gd - run: Godot --headless --path . --script res://tools/test_hero_props.gd
# LHF-08: the generated furniture is placed (none skipped), the greybox boxes it replaces are hidden but their collision is kept, each
# model stands on its footprint inside the house, and the whole set is within a triangle budget (LHF-06).
extends SceneTree

const MAX_TRIS := 450000          # the whole set of hero props
const MAX_ONE := 40000            # any one model

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _tris(n: Node) -> int:
	var t := 0
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (m as MeshInstance3D).mesh
		if mesh:
			for i in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(i)
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				t += idx.size() / 3
	return t


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 10:
		return false
	var hp = _lv.get_node("InteriorRooms").hero_props
	var fails := 0
	var ok: bool = hp.skipped.is_empty()
	print(("PASS  " if ok else "FAIL  ") + "every hero prop's model loaded (skipped: %s)" % [hp.skipped])
	fails += int(not ok)
	var n_ok: bool = hp.placed.size() == hp.ENTRIES.size()
	print(("PASS  " if n_ok else "FAIL  ") + "%d of %d placed, %d greybox nodes hidden" % [hp.placed.size(), hp.ENTRIES.size(), hp.hidden])
	fails += int(not n_ok)
	var total := 0
	var worst := 0
	var off := []
	var frame: Node3D = _lv.get_node("InteriorRooms").frame
	for id in hp.placed:
		var holder: Node3D = hp.placed[id]
		var t := _tris(holder)
		total += t
		worst = maxi(worst, t)
		var p := frame.to_local(holder.global_position)
		# inside the house's footprint, in the frame: u -3.1..5.6, v 0.3..9.0
		if p.x < -3.1 or p.x > 5.6 or -p.z < 0.3 or -p.z > 9.0:
			off.append(id)
	print(("PASS  " if off.is_empty() else "FAIL  ") + "all inside the house footprint (outside: %s)" % [off])
	fails += int(not off.is_empty())
	var b_ok := total <= MAX_TRIS and worst <= MAX_ONE
	print(("PASS  " if b_ok else "FAIL  ") + "triangles: %d in all (limit %d), largest model %d (limit %d)" % [total, MAX_TRIS, worst, MAX_ONE])
	fails += int(not b_ok)
	# collision kept: a replaced solid greybox box still has its body (the desk top and the wardrobe)
	for nm in ["Office_DeskTop", "L1_Wardrobe", "L1_Stove", "Store_Crate_0"]:
		var n := frame.find_child(nm, true, false)
		var good: bool = n != null and not (n as Node3D).visible and n.get_node_or_null("Body") != null
		print(("PASS  " if good else "FAIL  ") + "%s hidden, collision body kept" % nm)
		fails += int(not good)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
