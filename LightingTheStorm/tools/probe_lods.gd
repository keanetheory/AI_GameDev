# probe_lods.gd - run: Godot --headless --path . --script res://tools/probe_lods.gd -- res://Assets/Models/prop/lhi_oak_barrel.glb
# Prints the LOD sizes Godot's meshoptimizer produces for a generated model (LHF-08 decimation).
extends SceneTree


func _initialize() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(path), st)
	print("load err ", err)
	var scene := doc.generate_scene(st)
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var m := mi.mesh as ArrayMesh
		var arrays := m.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		print("mesh ", mi.name, " verts ", verts.size(), " tris ", idx.size() / 3)
		var im := ImporterMesh.new()
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, m.surface_get_material(0), "s")
		var t0 := Time.get_ticks_msec()
		im.generate_lods(25.0, 60.0, [])
		print("generate_lods took ", Time.get_ticks_msec() - t0, " ms; lod count ", im.get_surface_lod_count(0))
		for l in im.get_surface_lod_count(0):
			print("  lod ", l, ": ", im.get_surface_lod_indices(0, l).size() / 3, " tris, error ", im.get_surface_lod_size(0, l))
	quit()
