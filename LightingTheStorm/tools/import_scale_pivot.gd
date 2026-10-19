# import_scale_pivot.gd - EditorScenePostImport for FAL-generated models.
# Scales the model so its height (TARGET_HEIGHT_M) or longest horizontal extent
# (TARGET_FOOTPRINT_M) matches its category
# (1 unit = 1 m) and moves the pivot to the centre of the base at ground level.
# Enable per model: Import dock > Advanced > Import Script, or set
#   import_script/path="res://tools/import_scale_pivot.gd"
# in the model's .glb.import file. The category is read from the folder:
# res://Assets/Models/<category>/...
@tool
extends EditorScenePostImport

# Real-world height of each category's model, in metres. Add a category here
# before importing its FAL model; unlisted categories are left untouched.
const TARGET_HEIGHT_M := {
	"lighthouse": 27.0,
	"Characters": 1.83,  # Ted, 6 ft
	"prop": 0.9,         # burner_broken / burner_replacement: carried in both hands, fits the arc lamp
}
# Categories sized by their longest horizontal extent (X or Z) instead of height,
# e.g. an island whose height depends on its terrain.
const TARGET_FOOTPRINT_M := {
	"island": 90.0,
	"saint_calder_city": 480.0,
	"dock": 20.0,   # dock_harbour: quay with a two-boat bay, spans the island's harbour inlet
	"boat": 6.0,
	"saltgate": 50.0,
	"cliff_terrain": 120.0,
	"sea_rocks": 22.0,
}
# Per-model footprint overrides (file name without extension) for a model that shares a folder with
# differently sized ones.
const TARGET_FOOTPRINT_BY_FILE_M := {
	"rowboat": 4.2,   # Arthur and Daniel's two-man rowboat, smaller than the 6 m steam launch
}
# Turns a category's model about Y so it faces Godot's forward axis (-Z).
# Generated models face whichever way the concept views did.
const FACING_YAW_DEG := {
	"boat": 180.0,
}


func _post_import(scene: Node) -> Object:
	var category := get_source_file().get_base_dir().get_file()
	if not TARGET_HEIGHT_M.has(category) and not TARGET_FOOTPRINT_M.has(category):
		push_warning("import_scale_pivot: no target height for category '%s', model left as imported" % category)
		return scene

	var bounds := _bounds(scene, Transform3D.IDENTITY)
	if bounds.size.y <= 0.0001:
		push_error("import_scale_pivot: %s has no mesh bounds" % get_source_file())
		return scene

	var s: float
	var target: float
	var file_key := get_source_file().get_file().get_basename()
	if TARGET_FOOTPRINT_BY_FILE_M.has(file_key):
		target = TARGET_FOOTPRINT_BY_FILE_M[file_key]
		s = target / maxf(bounds.size.x, bounds.size.z)
	elif TARGET_FOOTPRINT_M.has(category):
		target = TARGET_FOOTPRINT_M[category]
		s = target / maxf(bounds.size.x, bounds.size.z)
	else:
		target = TARGET_HEIGHT_M[category]
		s = target / bounds.size.y
	var base_centre := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var yaw := deg_to_rad(FACING_YAW_DEG.get(category, 0.0))
	var rot := Basis(Vector3.UP, yaw)
	var fix := Transform3D(rot * Basis.from_scale(Vector3(s, s, s)), rot * (-base_centre * s))
	for child in scene.get_children():
		if child is Node3D:
			child.transform = fix * child.transform

	print("import_scale_pivot: %s scaled x%.4f (target %.1f m), result %.1f x %.1f x %.1f m, pivot at base centre" % [
		get_source_file().get_file(), s, target, bounds.size.x * s, bounds.size.y * s, bounds.size.z * s])
	_matte(scene)
	return scene


# glTF's metallic factor defaults to 1 when a generator leaves it out (Hunyuan3D multi-view does), which
# renders stone and brick as dark metal with no diffuse light. Nothing in the game is metal-textured,
# so any material without a metallic map is made fully non-metallic.
func _matte(scene: Node) -> void:
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i) as BaseMaterial3D
			if mat and mat.metallic > 0.0 and mat.metallic_texture == null:
				print("import_scale_pivot: %s surface %d metallic %.2f -> 0" % [get_source_file().get_file(), i, mat.metallic])
				mat.metallic = 0.0


# Combined AABB of every mesh under `node`, in the scene root's space.
func _bounds(node: Node, parent_xform: Transform3D) -> AABB:
	var xform := parent_xform
	if node is Node3D:
		xform = parent_xform * (node as Node3D).transform
	var result := AABB()
	var have := false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		result = xform * (node as MeshInstance3D).mesh.get_aabb()
		have = true
	for child in node.get_children():
		var b := _bounds(child, xform)
		if b.size != Vector3.ZERO:
			result = b if not have else result.merge(b)
			have = true
	return result
