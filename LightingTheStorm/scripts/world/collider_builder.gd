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
## Boxes (in this node's local space) inside which vertices above the box floor (position.y) are pressed
## down onto it, e.g. so the island's boulders sink into the ground instead of poking through a
## building. Outside each box the push fades out over flatten_falloff metres, so rocks taper down.
@export var flatten_boxes: Array[AABB] = []
@export var flatten_falloff := 3.0
## A path pressed into the mesh (this node's local space): a centre line whose y is the walking height,
## e.g. stairs cut through a cliff lip. Vertices within press_half_width of the line and above it are
## pressed down onto it; beyond that the push fades out over press_falloff metres. Never raises anything.
@export var press_path: PackedVector3Array = PackedVector3Array()
@export var press_half_width := 1.4
@export var press_falloff := 1.5


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
		if not flatten_boxes.is_empty() or press_path.size() >= 2:
			_flatten(mi)
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


func _flatten(mi: MeshInstance3D) -> void:
	var src := mi.mesh as ArrayMesh
	if src == null:
		return
	var to_local := global_transform.affine_inverse() * mi.global_transform
	var to_mesh := to_local.affine_inverse()
	var flat := ArrayMesh.new()
	var moved := 0
	var reach := press_half_width + press_falloff
	var press_box := AABB()
	if press_path.size() >= 2:
		press_box = AABB(press_path[0], Vector3.ZERO)
		for q in press_path:
			press_box = press_box.expand(q)
		press_box = press_box.grow(reach)
		press_box.size.y = 1e6          # any height: the test is in x/z only
		press_box.position.y = -5e5
	for surf in src.get_surface_count():
		var arrays := src.surface_get_arrays(surf)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var changed := {}
		for i in verts.size():
			var p := to_local * verts[i]
			var target := p.y
			for box in flatten_boxes:
				var floor_y := box.position.y
				if p.y <= floor_y or p.y > box.end.y:
					continue
				var dx := maxf(0.0, maxf(box.position.x - p.x, p.x - box.end.x))
				var dz := maxf(0.0, maxf(box.position.z - p.z, p.z - box.end.z))
				var t := clampf(sqrt(dx * dx + dz * dz) / maxf(flatten_falloff, 0.001), 0.0, 1.0)
				t = t * t * (3.0 - 2.0 * t)     # smoothstep: no crease where the taper starts or ends
				target = minf(target, floor_y + (p.y - floor_y) * t)
			if press_path.size() >= 2 and press_box.has_point(p):
				target = minf(target, _press_target(p, reach))
			if target < p.y - 0.001:
				verts[i] = to_mesh * Vector3(p.x, target, p.z)
				changed[i] = true
		if changed.is_empty():
			flat.add_surface_from_arrays(src.surface_get_primitive_type(surf), arrays)
			flat.surface_set_material(flat.get_surface_count() - 1, src.surface_get_material(surf))
			continue
		moved += changed.size()
		# Re-light the moved vertices: average the (area-weighted) normals of the faces around them,
		# keeping each face on the same side as the mesh's original normals.
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			idx = PackedInt32Array(range(verts.size()))
		if normals.size() == verts.size():
			var acc := {}
			for t in range(0, idx.size(), 3):
				var a := idx[t]
				var b := idx[t + 1]
				var c := idx[t + 2]
				if not (changed.has(a) or changed.has(b) or changed.has(c)):
					continue
				var n := (verts[b] - verts[a]).cross(verts[c] - verts[a])
				if n.dot(normals[a] + normals[b] + normals[c]) < 0.0:
					n = -n
				for v in [a, b, c]:
					if changed.has(v):
						acc[v] = acc.get(v, Vector3.ZERO) + n
			for v in acc:
				if acc[v].length_squared() > 1e-12:
					normals[v] = acc[v].normalized()
			arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_VERTEX] = verts
		flat.add_surface_from_arrays(src.surface_get_primitive_type(surf), arrays)
		flat.surface_set_material(flat.get_surface_count() - 1, src.surface_get_material(surf))
	mi.mesh = flat
	print("collider_builder: flattened ", moved, " vertices of ", model_path.get_file())


# Height a vertex at local `p` is pressed down to by press_path (p.y itself when out of reach).
func _press_target(p: Vector3, reach: float) -> float:
	var best := INF
	var y := p.y
	for i in press_path.size() - 1:
		var a := press_path[i]
		var b := press_path[i + 1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(p.x - a.x, p.z - a.z).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var d := Vector2(p.x - a.x, p.z - a.z).distance_to(ab * t)
		if d < best:
			best = d
			y = lerpf(a.y, b.y, t)
	if best > reach or p.y <= y:
		return p.y
	var k := clampf((best - press_half_width) / maxf(press_falloff, 0.001), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	return y + (p.y - y) * k


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
