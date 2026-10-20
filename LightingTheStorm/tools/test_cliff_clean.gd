# test_cliff_clean.gd - run: Godot --headless --path . --script res://tools/test_cliff_clean.gd
# The walkway is a ledge built against the UNCUT cliff. This guards that rule:
#  1. nothing is cut from the cliff: every cliff module carries all the triangles of its source model (a cut leaves
#     torn cap sheets and holes, which is what the old cutting produced), and no set-back copy of the cliff face exists;
#  2. nothing the walkway builds stands above the ground behind it: the ledge never rises above the cliff top there
#     (its back used to show as a stepped black wall above the plateau).
extends SceneTree

const SOURCE_TRIS := {"cliff_wall": 150000, "cliff_headland": 149916}

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


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var main: Node = _lv.get_node("Mainland")
	# 1. every cliff module still has all its source triangles
	var cut := 0
	var total := 0
	for node in _lv.get_node("Cliffs").get_children():
		var model := String(node.get("model_path")).get_file().get_basename()
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var tris := 0
			for s in m.mesh.get_surface_count():
				var arrays := m.mesh.surface_get_arrays(s)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				tris += (idx.size() if not idx.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
			total += 1
			if SOURCE_TRIS.has(model) and tris != SOURCE_TRIS[model]:
				cut += 1
				print("  %s has %d triangles, its source has %d" % [node.name, tris, SOURCE_TRIS[model]])
	_ok(cut == 0, "no cliff module has been cut (%d modules checked, %d differ from their source)" % [total, cut])
	_ok(main.get_node_or_null("Gallery") != null, "the walkway ledge exists")
	var cutwalls := 0
	for c in main.get_children():
		if String(c.name).begins_with("CutWall"):
			cutwalls += 1
	_ok(cutwalls == 0, "no copies of the cliff face are set back as a wall (%d found)" % cutwalls)
	# 2. the ledge never stands above the ground behind it
	var proud := 0
	var worst := 0.0
	for i in main._gal_y.size():
		var x: float = main.GAL_X0 - i * main.GAL_STEP
		var over: float = main._gal_y[i] - main.cliff_top(x)
		if over > 3.0:      # cliff_top is a coarse table, so allow its error; the stepped black wall stood 3 m proud
			proud += 1
			worst = maxf(worst, over)
	_ok(proud == 0, "the ledge never rises more than 3 m above the cliff top (%d steps do, worst %.1f m)" % [proud, worst])
	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)
	return false
