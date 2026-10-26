# test_collider_bake.gd - run: Godot --headless --path . --script res://tools/test_collider_bake.gd
# Checks the collider bakes (tools/bake_colliders.gd) against the live build:
#   1. every collider_builder node in Level.tscn found a bake (none is built live, so the bake is up to date), and
#   2. each baked node matches a fresh copy built live with the same settings: the same triangles and vertices on every
#      mesh still in the level, and the same collision shape (kind, face or point count, backface setting, layers).
# Exits 1 on any failure.
extends SceneTree

const Builder := preload("res://scripts/world/collider_builder.gd")

var _lv: Node
var _f := 0
var _fails := 0


func _initialize() -> void:
	_lv = (load("res://scenes/Level.tscn") as PackedScene).instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	if _f != 2:
		return false
	var nodes: Array[Node] = []
	for n in _lv.find_children("*", "Node3D", true, false):
		if n.get_script() == Builder:
			nodes.append(n)
	print("test_collider_bake: %d builder nodes" % nodes.size())
	Builder.bake_reads = false
	var holder := Node3D.new()
	root.add_child(holder)
	var checked := 0
	for n in nodes:
		var from_bake: String = n.used_bake
		var has_work: bool = n.solid or n._flattens() or n._carves()
		if has_work and from_bake == "":
			_fail("%s was built live: its bake is missing or stale (run tools/bake_colliders.gd)" % n.get_path())
		if from_bake == "":
			continue
		var live := Node3D.new()
		live.set_script(Builder)
		for p in n.get_property_list():
			if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and p["usage"] & PROPERTY_USAGE_STORAGE:
				live.set(p["name"], n.get(p["name"]))
		live.transform = n.global_transform
		holder.add_child(live)
		var a := _signature(n)
		var b := _signature(live)
		for mesh in a:         # by name: other scripts remove some meshes after the build (interior_rooms.gd drops the v3 stairs)
			if a[mesh] != b.get(mesh):
				_fail("%s/%s (%s) differs from a live build:\n  baked %s\n  live  %s" % [n.get_path(), mesh, from_bake, a[mesh], b.get(mesh)])
		checked += 1
	print("test_collider_bake: %d nodes compared with a live build" % checked)
	if _fails == 0:
		print("RESULT: OK")
	quit(1 if _fails > 0 else 0)
	return false


# Mesh path (in the model) -> the vertex and index counts of every surface and a sum of the kept triangles' corners, then
# its collision.
func _signature(n: Node) -> Dictionary:
	var out := {}
	var model: Node = n.get_child(0)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi.visible and String(mi.name).ends_with(n.marker_suffix):
			continue
		var m := []
		out[String(model.get_path_to(mi))] = m
		var am := mi.mesh as ArrayMesh
		if am:
			for s in am.get_surface_count():
				var arr := am.surface_get_arrays(s)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var idx = arr[Mesh.ARRAY_INDEX]
				var sum := Vector3.ZERO
				if idx != null:
					for i in idx:
						sum += v[i]
				m.append([v.size(), idx.size() if idx != null else -1, sum.snapped(Vector3.ONE * 0.01)])
		for body in mi.get_children():
			if body is StaticBody3D:
				m.append(["layer", body.collision_layer])
				for cs in body.get_children():
					var sh = (cs as CollisionShape3D).shape
					if sh is ConcavePolygonShape3D:
						m.append(["concave", sh.get_faces().size(), sh.backface_collision])
					elif sh is ConvexPolygonShape3D:
						m.append(["convex", sh.points.size()])
	return out


func _fail(msg: String) -> void:
	_fails += 1
	print("test_collider_bake: FAIL ", msg)
