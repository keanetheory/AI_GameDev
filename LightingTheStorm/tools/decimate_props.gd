# decimate_props.gd - brings the FAL props down to game weight (Lighthouse Finisher Agent, LHF-08 / LHF-06).
# The generated models are 500,000 triangles with a 2048 texture (22 MB of video memory each): far too heavy for furniture that
# is placed a dozen times in one room. This uses Godot's own meshoptimizer (ImporterMesh.generate_lods), which keeps the original
# vertices and so the UVs, picks the LOD nearest a target triangle count, drops the unused vertices, shrinks the albedo texture and
# writes the GLB back (the full-detail 2K file is kept in prop/source/, which has a .gdignore).
# run: Godot --headless --path . --script res://tools/decimate_props.gd -- <target_tris> <tex_px> <id> [<id> ...]
extends SceneTree

const PROP := "res://Assets/Models/prop/"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var target := int(a[0])
	var tex_px := int(a[1])
	for k in range(2, a.size()):
		_one(a[k], target, tex_px)
	quit()


func _one(id: String, target: int, tex_px: int) -> void:
	# an id ending in "+" decimates the file as it is now (a second pass), instead of the kept full-detail copy
	var again := id.ends_with("+")
	id = id.trim_suffix("+")
	var src := ProjectSettings.globalize_path(PROP + id + ".glb")
	var keep := ProjectSettings.globalize_path(PROP + "source/" + id + "_full2k.glb")
	if not FileAccess.file_exists(keep):
		DirAccess.copy_absolute(src, keep)
	if again:
		keep = src
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(keep, st) != OK:
		print("FAIL load ", id)
		return
	var scene := doc.generate_scene(st)
	var tris_before := 0
	var tris_after := 0
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var m := mi.mesh as ArrayMesh
		var arrays := m.surface_get_arrays(0)
		var mat := m.surface_get_material(0)
		tris_before += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		var im := ImporterMesh.new()
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mat, "s")
		var merge := float(OS.get_environment("DEC_MERGE")) if OS.get_environment("DEC_MERGE") != "" else 25.0
		var split := float(OS.get_environment("DEC_SPLIT")) if OS.get_environment("DEC_SPLIT") != "" else 60.0
		im.generate_lods(merge, split, [])
		if im.get_surface_lod_count(0) == 0:
			print("NO LODS for ", id, ": left as it is")
			scene.free()
			return
		var best := 0
		var best_d := 1 << 30
		for l in im.get_surface_lod_count(0):
			var t := im.get_surface_lod_indices(0, l).size() / 3
			if absi(t - target) < best_d:
				best_d = absi(t - target)
				best = l
		var lod_idx := im.get_surface_lod_indices(0, best)
		var out := _compact(arrays, lod_idx)
		var nm := ArrayMesh.new()
		nm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
		if mat is StandardMaterial3D:
			var sm := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			if sm.albedo_texture:
				var img := sm.albedo_texture.get_image()
				if img.is_compressed():
					img.decompress()
				if maxi(img.get_width(), img.get_height()) > tex_px:
					img.resize(tex_px, tex_px, Image.INTERPOLATE_LANCZOS)
				sm.albedo_texture = ImageTexture.create_from_image(img)
			nm.surface_set_material(0, sm)
		mi.mesh = nm
		tris_after += lod_idx.size() / 3
	var st2 := GLTFState.new()
	doc.append_from_scene(scene, st2)
	var err := doc.write_to_filesystem(st2, src)
	print("%s: %d -> %d tris, texture %d px, write %s" % [id, tris_before, tris_after, tex_px, error_string(err)])
	scene.free()


## The arrays with only the vertices the new index buffer uses.
func _compact(arrays: Array, idx: PackedInt32Array) -> Array:
	var vcount := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var remap := PackedInt32Array()
	remap.resize(vcount)
	remap.fill(-1)
	var order := PackedInt32Array()
	var new_idx := PackedInt32Array()
	new_idx.resize(idx.size())
	for i in idx.size():
		var v := idx[i]
		if remap[v] < 0:
			remap[v] = order.size()
			order.append(v)
		new_idx[i] = remap[v]
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	for k in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR, Mesh.ARRAY_TANGENT]:
		var src = arrays[k]
		if src == null or (src as Variant).size() == 0:
			continue
		match k:
			Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL:
				var o := PackedVector3Array()
				o.resize(order.size())
				for i in order.size():
					o[i] = (src as PackedVector3Array)[order[i]]
				out[k] = o
			Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2:
				var o2 := PackedVector2Array()
				o2.resize(order.size())
				for i in order.size():
					o2[i] = (src as PackedVector2Array)[order[i]]
				out[k] = o2
			Mesh.ARRAY_COLOR:
				var o3 := PackedColorArray()
				o3.resize(order.size())
				for i in order.size():
					o3[i] = (src as PackedColorArray)[order[i]]
				out[k] = o3
			Mesh.ARRAY_TANGENT:
				var o4 := PackedFloat32Array()
				o4.resize(order.size() * 4)
				for i in order.size():
					for c in 4:
						o4[i * 4 + c] = (src as PackedFloat32Array)[order[i] * 4 + c]
				out[k] = o4
	out[Mesh.ARRAY_INDEX] = new_idx
	return out
