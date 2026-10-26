# probe_rain_gpu.gd - run WINDOWED (needs the GPU): Godot --path . --script res://tools/probe_rain_gpu.gd
# Question (creator hypothesis, LHF finish): is a raindrop that STARTS inside a GPUParticlesCollisionBox3D ever hidden?
# Two identical rain emitters (the rig's material: hide on contact), same fall speed as lighting_rig.gd, each with its own box:
#   LEFT  : the emitter sits INSIDE the box (box spans y 0..20, emitter at y 10)
#   RIGHT : the emitter sits ABOVE the box (box spans y 0..8, emitter at y 10)
# Drops drawn below the emitter line are counted per side (bright pixels). The box is the same height on neither side, so the
# count that matters is the region y 0..8, which is inside the box on BOTH sides. Expect RIGHT = 0 (hidden on entry).
# LEFT > 0 proves a drop that starts inside is never hidden.
extends SceneTree

var _f := 0
var _cam: Camera3D


func _make(x: float, box_y0: float, box_y1: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = 4000
	p.lifetime = 0.9
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(1.2, 0.5, 1.2)
	m.direction = Vector3(0, -1, 0)
	m.spread = 0.0
	m.initial_velocity_min = 30.0
	m.initial_velocity_max = 38.0
	m.gravity = Vector3(0, -9.8, 0)
	m.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.35)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = mat
	p.draw_pass_1 = q
	p.position = Vector3(x, 10, 0)
	root.add_child(p)
	var b := GPUParticlesCollisionBox3D.new()
	b.size = Vector3(4, box_y1 - box_y0, 4)
	b.position = Vector3(x, (box_y0 + box_y1) * 0.5, 0)
	root.add_child(b)


func _initialize() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 5, 14)
	_cam.look_at_from_position(_cam.position, Vector3(0, 5, 0))
	root.add_child(_cam)
	_cam.current = true
	_make(-4.0, 0.0, 20.0)
	_make(4.0, 0.0, 8.0)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 40:
		return false
	var img := root.get_texture().get_image()
	var w := img.get_width()
	var h := img.get_height()
	# project y = 0 and y = 8 on the camera plane (z = 0) to screen rows, and x = -4 / +4 columns +-2.2
	var rows := [_cam.unproject_position(Vector3(0, 8, 0)).y, _cam.unproject_position(Vector3(0, 0, 0)).y]
	var left := 0
	var right := 0
	var left_above := 0
	var right_above := 0
	var above_row: float = _cam.unproject_position(Vector3(0, 10, 0)).y
	for y in range(0, h):
		for x in range(0, w):
			var c := img.get_pixel(x, y)
			if c.r < 0.5:
				continue
			var ws := _cam.unproject_position(Vector3(-4, 0, 0)).x
			var we2 := _cam.unproject_position(Vector3(4, 0, 0)).x
			var in_left: bool = absf(x - ws) < 90.0
			var in_right: bool = absf(x - we2) < 90.0
			if y >= int(rows[0]) and y <= int(rows[1]):
				if in_left:
					left += 1
				if in_right:
					right += 1
			elif y < int(rows[0]) and y > int(above_row):
				if in_left:
					left_above += 1
				if in_right:
					right_above += 1
	print("bright pixels y 8..10 (above both boxes' lower part): LEFT(in box) %d  RIGHT(above box) %d" % [left_above, right_above])
	print("bright pixels y 0..8 (inside the box on both sides)  : LEFT %d  RIGHT %d" % [left, right])
	print("spawn-inside drop drawn inside the box: %s" % ("YES (hypothesis holds)" if left > 20 and right < 5 else "NO / inconclusive"))
	img.save_png("res://../GERFramework/shots/probe_rain_gpu.png")
	quit(0)
	return false
