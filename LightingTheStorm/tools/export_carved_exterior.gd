# export_carved_exterior.gd - run: Godot --headless --path . --script res://tools/export_carved_exterior.gd
# Writes the exterior as the game sees it AFTER the carves and the stray-mesh clip (not the wall patches) to Assets/Models/lighthouse/repair/exterior_carved_in.glb,
# in the Lighthouse node's frame, with its materials. The input of Assets/Models/lighthouse/repair/repair_exterior.py (Blender).
extends SceneTree
var _lv: Node
var _f := 0
func _initialize() -> void:
	OS.set_environment("LHF_NO_WALL_PATCH", "1")
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
func _process(_d: float) -> bool:
	_f += 1
	if _f < 10:
		return false
	var lh := _lv.get_node("Lighthouse") as Node3D
	var out := Node3D.new()
	out.name = "Exterior"
	var n := 0
	for mi in lh.get_node("convert").find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or String(m.name).begins_with("WallPatch_"):
			continue
		var d := MeshInstance3D.new()
		d.name = String(m.name)
		d.mesh = m.mesh
		d.transform = lh.global_transform.affine_inverse() * m.global_transform
		out.add_child(d)
		n += 1
	root.add_child(out)
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_scene(out, st)
	var err := doc.write_to_filesystem(st, ProjectSettings.globalize_path("res://Assets/Models/lighthouse/repair/exterior_carved_in.glb"))
	print("export_carved_exterior: %d meshes, error %d" % [n, err])
	quit(0)
	return false
