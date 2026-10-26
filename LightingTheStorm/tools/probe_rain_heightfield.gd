# probe_rain_heightfield.gd - run WINDOWED: Godot --path . --script res://tools/probe_rain_heightfield.gd
# Does the rig's rain height field (GPUParticlesCollisionHeightField3D, camera-following, layer-1 meshes) stop drops at a roof?
# Three identical rain columns over three 4 x 4 m roof slabs at y 6, each with a drawn 4 m high column of magenta drops under it:
#   A: a plain box slab (outward windings)           -> drops must stop at the top: 0 magenta below the slab
#   B: the same slab built with INWARD windings (every triangle flipped)  -> shows whether back faces are culled from the field
#   C: a slab made of a single quad (no thickness), upward facing
# Counts magenta pixels in the 5 m under each slab (screen rows between y 1 and y 5).
extends SceneTree

var _f := 0
var _cam: Camera3D


func _slab(x: float, flip: bool, quad: bool) -> void:
	var mi := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	st.set_material(mat)
	var h := 2.0
	var verts: Array = []
	if quad:
		verts = [Vector3(-h, 0, -h), Vector3(-h, 0, h), Vector3(h, 0, h), Vector3(-h, 0, -h), Vector3(h, 0, h), Vector3(h, 0, -h)]
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(4, 0.2, 4)
		verts = Array(bm.get_faces())
	for i in range(0, verts.size(), 3):
		var tri := [verts[i], verts[i + 1], verts[i + 2]]
		if flip:
			tri = [tri[0], tri[2], tri[1]]
		for v in tri:
			st.add_vertex(v)
	st.generate_normals()
	mi.mesh = st.commit()
	mi.position = Vector3(x, 6, 0)
	root.add_child(mi)
	var p := GPUParticles3D.new()
	p.amount = 3000
	p.lifetime = 0.9
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(1.6, 0.5, 1.6)
	m.direction = Vector3(0, -1, 0)
	m.spread = 0.0
	m.initial_velocity_min = 30.0
	m.initial_velocity_max = 38.0
	m.gravity = Vector3(0, -9.8, 0)
	m.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.35)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.albedo_color = Color(1, 0, 1)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm
	p.draw_pass_1 = q
	p.position = Vector3(x, 12, 0)
	root.add_child(p)


func _initialize() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	_cam = Camera3D.new()
	_cam.fov = 60.0
	_cam.look_at_from_position(Vector3(0, 4, 20), Vector3(0, 4, 0))
	root.add_child(_cam)
	_cam.current = true
	_slab(-7.0, false, false)
	_slab(0.0, true, false)
	_slab(7.0, false, true)
	var hf := GPUParticlesCollisionHeightField3D.new()
	hf.size = Vector3(30, 40, 20)
	hf.resolution = GPUParticlesCollisionHeightField3D.RESOLUTION_512
	hf.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
	hf.position = Vector3(0, 6, 0)
	root.add_child(hf)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 40:
		return false
	var img := root.get_texture().get_image()
	var names := ["A outward box", "B inward box (windings flipped)", "C single quad"]
	var xs := [-7.0, 0.0, 7.0]
	var y_hi := _cam.unproject_position(Vector3(0, 5, 0)).y
	var y_lo := _cam.unproject_position(Vector3(0, 1, 0)).y
	var y_top := _cam.unproject_position(Vector3(0, 12, 0)).y
	var y_roof := _cam.unproject_position(Vector3(0, 6.2, 0)).y
	for i in 3:
		var cx := _cam.unproject_position(Vector3(xs[i], 0, 0)).x
		var below := 0
		var above := 0
		for y in range(int(y_top), int(y_lo)):
			for x in range(int(cx) - 120, int(cx) + 120):
				var c := img.get_pixel(x, y)
				if c.r > 0.6 and c.b > 0.6 and c.g < 0.35:
					if y > y_roof:
						below += 1
					else:
						above += 1
		print("%-34s magenta above the slab: %5d   BELOW the slab (should be 0): %5d" % [names[i], above, below])
	img.save_png("res://../GERFramework/shots/probe_rain_heightfield.png")
	quit(0)
	return false
