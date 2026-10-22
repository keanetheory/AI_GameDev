extends SceneTree
# probe_mesh_box.gd - list a model's mesh instances with their AABBs and transforms (in the model root's space), and how many
# triangles have their centre inside an optional box. usage: ... --script res://tools/probe_mesh_box.gd -- <res://model.glb> [x0 y0 z0 x1 y1 z1]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var m := (load(a[0]) as PackedScene).instantiate() as Node3D
	root.add_child(m)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var n := mi as MeshInstance3D
		var xf := Transform3D.IDENTITY      # raw mesh coordinates (the mesh stores z as height)
		var bb := xf * n.get_aabb()
		print("mesh ", n.name, " aabb pos ", bb.position, " size ", bb.size, " surfaces ", n.mesh.get_surface_count())
		if a.size() >= 7:
			var box := AABB(Vector3(float(a[1]), float(a[2]), float(a[3])), Vector3(float(a[4]) - float(a[1]), float(a[5]) - float(a[2]), float(a[6]) - float(a[3])))
			var arr := n.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var inside := 0
			for t in range(0, idx.size(), 3):
				var c := xf * ((v[idx[t]] + v[idx[t + 1]] + v[idx[t + 2]]) / 3.0)
				if box.has_point(c):
					inside += 1
			print("  triangles ", idx.size() / 3, " centres inside the box: ", inside)
	quit()
