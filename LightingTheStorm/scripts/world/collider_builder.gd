# collider_builder.gd - instances a .glb and gives every mesh trimesh collision.
# Set visible_mesh = false for collision-only models (island collider, dock barriers).
# @tool: it also runs in the editor so the models show in the 3D viewport. The instanced model and
# its children have no owner, so they are never saved into the .tscn; collision is built at runtime only.
@tool
extends Node3D

@export_file("*.glb") var model_path := ""
@export var visible_mesh := true
@export var solid := true
## Trimesh follows the mesh exactly (good for walkable ground). Convex is a cheap hull for big
## things you only need to bump into (cliffs, sea rocks).
@export_enum("Trimesh", "Convex") var collision_kind := 0
## Physics layers of the collision body: 1 = world (the player walks on it), 2 = hazards the boat hits.
@export_flags_3d_physics var body_layers := 1
## FAL meshes often have flipped or one-sided faces: make collision and rendering
## work from both sides so there are no holes and thin parts (dock decks) show.
@export var double_sided := true
## Boxes (in this node's local space) whose triangles are removed before collision is built,
## e.g. to cut a generated dock out of an island so a better one can replace it.
@export var carve_boxes: Array[AABB] = []


func _ready() -> void:
	var scene: PackedScene = load(model_path)
	if scene == null:
		push_error("Could not load %s" % model_path)
		return
	for old in get_children():   # re-entry (editor reload): never stack a second copy
		old.queue_free()
	var root := scene.instantiate()
	add_child(root)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not carve_boxes.is_empty():
			_carve(mi)
		if solid and not Engine.is_editor_hint():
			if collision_kind == 1:
				mi.create_convex_collision(true, true)
			else:
				mi.create_trimesh_collision()
			for child in mi.get_children():
				if child is StaticBody3D:
					child.collision_layer = body_layers
			if double_sided and collision_kind == 0:
				for shape in mi.find_children("*", "CollisionShape3D", true, false):
					var concave := (shape as CollisionShape3D).shape as ConcavePolygonShape3D
					if concave:
						concave.backface_collision = true
		if double_sided and mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
				if mat:
					mat = mat.duplicate()
					mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					mi.set_surface_override_material(i, mat)
		mi.visible = visible_mesh


func _carve(mi: MeshInstance3D) -> void:
	var src := mi.mesh as ArrayMesh
	if src == null:
		return
	var to_local := global_transform.affine_inverse() * mi.global_transform
	var carved := ArrayMesh.new()
	var removed := 0
	for surf in src.get_surface_count():
		var arrays := src.surface_get_arrays(surf)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			idx = PackedInt32Array(range(verts.size()))
		var kept := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var c := to_local * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
			var inside := false
			for box in carve_boxes:
				if box.has_point(c):
					inside = true
					break
			if inside:
				removed += 1
			else:
				kept.append(idx[t])
				kept.append(idx[t + 1])
				kept.append(idx[t + 2])
		arrays[Mesh.ARRAY_INDEX] = kept
		carved.add_surface_from_arrays(src.surface_get_primitive_type(surf), arrays)
		carved.surface_set_material(carved.get_surface_count() - 1, src.surface_get_material(surf))
	mi.mesh = carved
	print("collider_builder: carved ", removed, " triangles from ", model_path.get_file())
