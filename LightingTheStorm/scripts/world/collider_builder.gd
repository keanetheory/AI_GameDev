# collider_builder.gd - instances a .glb and gives every mesh trimesh collision.
# Set visible_mesh = false for collision-only models (island collider, dock barriers).
# @tool: it also runs in the editor so the models show in the 3D viewport. The instanced model and
# its children have no owner, so they are never saved into the .tscn; collision is built at runtime only.
@tool
extends Node3D

@export_file("*.glb") var model_path := ""
## A repaired copy of the model with the carves already applied and the holes filled (tools/export_carved_exterior.gd + Assets/Models/lighthouse/repair/repair_exterior.py).
## When set, it is used instead of model_path and the carve lists are ignored. LHF_EXTERIOR=v3 forces the original model with its carves (the fallback).
@export_file("*.glb") var repaired_model_path := ""
var _repaired := false
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
## Make the trimesh collision solid from both sides WITHOUT changing how the mesh renders: for a one-sided shell
## (a cliff) whose collider must also stop rays and bodies that start inside or behind it.
@export var backface_collision := false
## Multiplies the colour of every material, e.g. to bring a generated model's palette in line with
## the models around it.
@export var tint := Color.WHITE
## Boxes (in this node's local space) whose triangles are removed before collision is built,
## e.g. to cut a generated dock out of an island so a better one can replace it.
@export var carve_boxes: Array[AABB] = []
## Rotated boxes to cut out, for things that are not aligned with the axes (the lighthouse basement in the island).
## Each transform maps the unit cube (-0.5..0.5 on every axis) onto the box, in this node's local space.
@export var carve_oriented: Array[Transform3D] = []
## Like carve_oriented, but a triangle goes when ANY of its corners is inside the box, not only its centre. For clearing a
## room of the large triangles of a rock or a model that cross into it from outside (their centres are outside the room).
@export var carve_oriented_any: Array[Transform3D] = []
## Upright cylinders where a triangle goes if ANY corner is inside (the stairwell of the lighthouse: pieces of the exterior model
## poke inward across the room's lining, and their centres are outside the cylinder).
@export var carve_cylinders_any: Array[AABB] = []
## Upright cylinders to cut out (the lighthouse's lantern deck over the stairs, its lamp). Each AABB is the
## cylinder's bounding box in this node's local space: the circle (or ellipse) inscribed in its x/z extent, between
## its bottom and top.
@export var carve_cylinders: Array[AABB] = []
## Strips to cut out along a line: generated walls that run at an angle through things that must stay
## (a box would take a bite out of them), or a corridor for stairs. Consecutive pairs of points are the
## ends of each line (this node's local space); triangles within the half width of a line and above its
## floor go. The floor runs from one end's y to the other's, so a line can follow a slope.
@export var carve_lines: PackedVector3Array = PackedVector3Array()
@export var carve_line_half_width := 0.6
## Half width for each line in carve_lines (one per pair of points); lines without one use carve_line_half_width.
@export var carve_line_half_widths: PackedFloat32Array = PackedFloat32Array()
## When set, only the triangles inside these boxes (this node's local space) are kept: a piece of a model
## reused on its own, e.g. a patch of the island's cliff face moved over a gap in the rock.
@export var keep_boxes: Array[AABB] = []
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
## Meshes whose name ends with this are reference markers (the interior greybox's G_entry_marker and so on): they
## are hidden and get no collision, and stay in the tree so scripts can read their positions.
@export var marker_suffix := "_marker"
## Greybox colouring for untextured models: the first key (checked in order) found in a mesh's name picks its flat
## colour, so floors, stairs and walls can be told apart; "*" is the colour for names that match no key. Replaces the
## model's materials (the glTF importer gives material-less meshes a plain default one), so only set it on greyboxes.
@export var colour_by_name: Dictionary = {}

const ColliderBake := preload("res://scripts/world/collider_bake.gd")
## Where tools/bake_colliders.gd saves each node's flattening, carve and collision shapes, so a load reads them instead of
## working them out (the convex hulls and the carves were most of the level's load time). A node whose settings or model
## changed since the bake no longer matches its file and is built live, as before, until the bake is re-run.
const BAKE_DIR := "res://Assets/Baked/colliders/"
const BAKE_VERSION := 1              # bump when what is baked changes, so every old bake stops matching

static var bake_writes := false      # set by tools/bake_colliders.gd: save what is built live
static var bake_reads := true        # tools/test_collider_bake.gd turns this off to build live and compare with the bakes
static var written: Array[String] = []   # the bake files saved this run (the bake tool reports them)
static var _shared := {}             # key -> bake already made this run: copies of one model (the sea stacks) share it

var used_bake := ""                  # "disk", "shared" or "" (built live): for the bake tool and the tests


func _ready() -> void:
	_repaired = repaired_model_path != "" and OS.get_environment("LHF_EXTERIOR") != "v3" and ResourceLoader.exists(repaired_model_path)
	var scene: PackedScene = load(repaired_model_path if _repaired else model_path)
	if scene == null:
		push_error("Could not load %s" % model_path)
		return
	for old in get_children():   # re-entry (editor reload): never stack a second copy
		old.queue_free()
	var root := scene.instantiate()
	add_child(root)
	var meshes: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if marker_suffix != "" and String(mi.name).ends_with(marker_suffix):
			mi.visible = false
			continue
		meshes.append(mi)
	var build_shapes := solid and not Engine.is_editor_hint()
	var key := _bake_key(root, meshes)
	var bake = _find_bake(key, build_shapes or _flattens() or _carves())
	var live := bake == null
	if live:
		bake = ColliderBake.new()
		bake.key = key
	for m in meshes.size():
		var mi := meshes[m]
		var entry: Dictionary
		if live:
			entry = _build_entry(mi, build_shapes)
			bake.meshes.append(entry)
		else:
			entry = bake.meshes[m]
			_apply_entry(mi, entry)
		if build_shapes and entry.get("shape"):
			# what MeshInstance3D.create_*_collision() make: a StaticBody3D named <mesh>_col holding one shape
			var body := StaticBody3D.new()
			body.name = String(mi.name) + "_col"
			body.collision_layer = body_layers
			var cs := CollisionShape3D.new()
			cs.shape = entry["shape"]
			body.add_child(cs, true)
			mi.add_child(body, true)
		if (double_sided or tint != Color.WHITE) and mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
				if mat:
					mat = mat.duplicate()
					if double_sided:
						mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					mat.albedo_color *= tint
					mi.set_surface_override_material(i, mat)
		if not colour_by_name.is_empty():
			_colour_greybox(mi)
		mi.visible = visible_mesh
	if live and (build_shapes or _flattens() or _carves()):
		_shared[key] = bake
		if bake_writes:
			_save_bake(bake)


func _flattens() -> bool:
	return not flatten_boxes.is_empty() or press_path.size() >= 2


func _carves() -> bool:
	if _repaired:
		return false
	return not carve_boxes.is_empty() or not carve_oriented.is_empty() or not carve_oriented_any.is_empty() \
			or not carve_cylinders.is_empty() or not carve_cylinders_any.is_empty() or carve_lines.size() >= 2 \
			or not keep_boxes.is_empty()


# Everything that decides the result: the settings that shape it and a signature of each mesh in the model (its path,
# size and bounds), so a regenerated .glb gets a new key. The node's own transform is left out: carves are in its space.
func _bake_key(root: Node, meshes: Array[MeshInstance3D]) -> String:
	var parts := [BAKE_VERSION, repaired_model_path if _repaired else model_path, _repaired, solid, collision_kind, double_sided or backface_collision,
			carve_boxes, carve_oriented, carve_oriented_any, carve_cylinders_any, carve_cylinders, carve_lines,
			carve_line_half_width, carve_line_half_widths, keep_boxes, flatten_boxes, flatten_falloff, press_path,
			press_half_width, press_falloff, marker_suffix]
	for mi in meshes:
		var sig := [String(root.get_path_to(mi))]
		if mi.mesh:
			sig.append(mi.mesh.get_aabb())
			var am := mi.mesh as ArrayMesh
			if am:
				for s in am.get_surface_count():
					sig.append(am.surface_get_array_len(s))
					sig.append(am.surface_get_array_index_len(s))
		parts.append(sig)
	return var_to_str(parts).md5_text()


func _bake_path(key: String) -> String:
	return BAKE_DIR + "%s_%s.res" % [model_path.get_file().get_basename(), key.substr(0, 12)]


# A bake for this key: one already made this run, or the file the bake tool saved. null when there is none (or, while
# the bake tool runs, always for the first node of each key, so every file is rewritten).
func _find_bake(key: String, has_work: bool):
	if not bake_reads:
		return null
	if _shared.has(key):
		used_bake = "shared"
		return _shared[key]
	if bake_writes:
		return null
	var path := _bake_path(key)
	if not ResourceLoader.exists(path):
		if has_work:
			print("collider_builder: no bake for %s (%s), building it live; run tools/bake_colliders.gd" % [name, model_path.get_file()])
		return null
	var bake = load(path)
	if bake == null or bake.key != key:
		return null
	used_bake = "disk"
	_shared[key] = bake
	return bake


# Flattens, carves and makes the collision shape for one mesh, as the builder always has, and records the result.
func _build_entry(mi: MeshInstance3D, build_shape: bool) -> Dictionary:
	var entry := {}
	var flattens := _flattens()
	var carves := _carves()
	if flattens:
		_flatten(mi)
	if carves:
		_carve(mi)
	var am := mi.mesh as ArrayMesh
	if am and (flattens or carves):
		var verts := []
		var normals := []
		var indices := []
		for s in am.get_surface_count():
			var arrays := am.surface_get_arrays(s)
			verts.append(arrays[Mesh.ARRAY_VERTEX])
			normals.append(arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array())
			indices.append(arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array())
		if flattens:
			entry["verts"] = verts
			entry["normals"] = normals
		if carves:
			entry["indices"] = indices
	if build_shape and mi.mesh:
		var shape: Shape3D
		if collision_kind == 1:
			shape = mi.mesh.create_convex_shape(true, true)
		else:
			shape = mi.mesh.create_trimesh_shape()
			if (double_sided or backface_collision) and shape is ConcavePolygonShape3D:
				shape.backface_collision = true
		entry["shape"] = shape
	return entry


# Puts a baked flattening and carve back on the model's mesh (the shape is added by the caller).
func _apply_entry(mi: MeshInstance3D, entry: Dictionary) -> void:
	var src := mi.mesh as ArrayMesh
	if src == null or not (entry.has("verts") or entry.has("indices")):
		return
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		if entry.has("verts"):
			arrays[Mesh.ARRAY_VERTEX] = entry["verts"][s]
			if entry["normals"][s].size() > 0:
				arrays[Mesh.ARRAY_NORMAL] = entry["normals"][s]
		if entry.has("indices"):
			arrays[Mesh.ARRAY_INDEX] = entry["indices"][s]      # as the carve left it, even when it kept nothing
		out.add_surface_from_arrays(src.surface_get_primitive_type(s), arrays)
		out.surface_set_material(s, src.surface_get_material(s))
	mi.mesh = out


func _save_bake(bake) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BAKE_DIR))
	var path := _bake_path(bake.key)
	var err := ResourceSaver.save(bake, path, ResourceSaver.FLAG_COMPRESS)
	if err != OK:
		push_error("collider_builder: could not save %s (error %d)" % [path, err])
		return
	written.append(path)


func _colour_greybox(mi: MeshInstance3D) -> void:
	var lower := String(mi.name).to_lower()
	var colour = colour_by_name.get("*")
	for key in colour_by_name:
		if key != "*" and lower.contains(String(key).to_lower()):
			colour = colour_by_name[key]
			break
	if colour == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.95
	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat


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
	var oriented_inv: Array[Transform3D] = []
	for xf in carve_oriented:
		oriented_inv.append(xf.affine_inverse())
	var any_inv: Array[Transform3D] = []
	for xf in carve_oriented_any:
		any_inv.append(xf.affine_inverse())
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
			if not keep_boxes.is_empty():
				inside = true
				for box in keep_boxes:
					if box.has_point(c):
						inside = false
						break
			for box in carve_boxes:
				if box.has_point(c):
					inside = true
					break
			for inv in oriented_inv:
				if inside:
					break
				var q := inv * c
				inside = absf(q.x) <= 0.5 and absf(q.y) <= 0.5 and absf(q.z) <= 0.5
			for inv in any_inv:
				if inside:
					break
				for k in 3:
					var q2 := inv * (to_local * verts[idx[t + k]])
					if absf(q2.x) <= 0.5 and absf(q2.y) <= 0.5 and absf(q2.z) <= 0.5:
						inside = true
						break
			for cyl in carve_cylinders_any:
				if inside:
					break
				var cm := cyl.get_center()
				for k in 3:
					var pv := to_local * verts[idx[t + k]]
					if pv.y < cyl.position.y or pv.y > cyl.end.y:
						continue
					var ex := (pv.x - cm.x) / maxf(cyl.size.x * 0.5, 1e-6)
					var ez := (pv.z - cm.z) / maxf(cyl.size.z * 0.5, 1e-6)
					if ex * ex + ez * ez <= 1.0:
						inside = true
						break
			for cyl in carve_cylinders:
				if inside:
					break
				if c.y < cyl.position.y or c.y > cyl.end.y:
					continue
				var mid := cyl.get_center()
				var dx := (c.x - mid.x) / maxf(cyl.size.x * 0.5, 1e-6)
				var dz := (c.z - mid.z) / maxf(cyl.size.z * 0.5, 1e-6)
				inside = dx * dx + dz * dz <= 1.0
			for i in range(0, carve_lines.size() - 1, 2):
				if inside:
					break
				var a := carve_lines[i]
				var b := carve_lines[i + 1]
				var ab := Vector2(b.x - a.x, b.z - a.z)
				var ac := Vector2(c.x - a.x, c.z - a.z)
				var along := clampf(ac.dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
				if c.y < lerpf(a.y, b.y, along):
					continue
				var half := carve_line_half_widths[i / 2] if i / 2 < carve_line_half_widths.size() else carve_line_half_width
				inside = ac.distance_to(ab * along) < half
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
