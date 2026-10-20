# cliff_dressing.gd - the foot of the cliffs: rubble and scree in the cliff's own rock, a few sea stacks off the headland
# tips, and spray that rises with the sea state (the Wave agent's Sea.state). All placement comes from the baked
# waterline (data/world/cliff_foot.json, made by tools/bake_walkway.gd) and the headlands in data/world/cliff_layout.json,
# so it follows the coast if the layout changes. Put one in Level.tscn after Mainland.
extends Node3D

const Sea := preload("res://scripts/world/sea.gd")
const BUILDER := preload("res://scripts/world/collider_builder.gd")

const FOOT_PATH := "res://data/world/cliff_foot.json"
const LAYOUT_PATH := "res://data/world/cliff_layout.json"
const STACK_MODEL := "res://Assets/Models/sea_rocks/sea_stack.glb"

## Keep the quay, the docks and the piers clear.
const CLEAR_X := Vector2(-100.0, 125.0)
@export var rubble_per_point := 6
@export var seed_value := 3
@export var water_level := 0.5

var _spray: Array[GPUParticles3D] = []


func _ready() -> void:
	var foot := _load(FOOT_PATH)
	var layout := _load(LAYOUT_PATH)
	if foot.is_empty():
		push_warning("cliff_dressing: %s missing; run tools/bake_walkway.gd" % FOOT_PATH)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_build_rubble(foot, rng)
	_build_stacks_and_spray(foot, layout, rng)


func _process(_delta: float) -> void:
	var r := clampf(Sea.state / 5.0, 0.0, 1.0)
	for p in _spray:
		p.amount_ratio = lerpf(0.08, 1.0, r * r)     # a little mist in calm water, a wall of spray in a storm


func _load(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


# ---------- rubble ----------

func _build_rubble(foot: Dictionary, rng: RandomNumberGenerator) -> void:
	var mesh := _rock_mesh(rng)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var xf: Array[Transform3D] = []
	var cols: Array[Color] = []
	var xs: Array = foot["x"]
	var zs: Array = foot["z"]
	for i in xs.size():
		var x: float = xs[i]
		if x > CLEAR_X.x and x < CLEAR_X.y:
			continue
		for k in rubble_per_point:
			var s := lerpf(0.5, 2.6, pow(rng.randf(), 2.2))          # many small stones, a few boulders
			var px := x + rng.randf_range(-1.6, 1.6)
			var pz: float = float(zs[i]) - rng.randf_range(0.2, 8.0) * (0.4 + s * 0.35)
			var py := water_level - 0.35 * s + rng.randf_range(-0.1, 0.3)
			var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)) * Basis.from_scale(Vector3(s * rng.randf_range(0.8, 1.3), s * rng.randf_range(0.6, 1.0), s * rng.randf_range(0.8, 1.3)))
			xf.append(Transform3D(basis, Vector3(px, py, pz)))
			var v := rng.randf_range(0.7, 1.1)
			cols.append(Color(v, v, v))
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Rubble"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var main := get_parent().get_node_or_null("Mainland")
	mmi.material_override = main._rock_material() if main and main.has_method("_rock_material") else null
	add_child(mmi)
	print("cliff_dressing: %d stones of rubble along the cliff foot" % xf.size())


## One angular, lumpy stone: an octahedron split twice and pushed about by noise, flat shaded.
func _rock_mesh(rng: RandomNumberGenerator) -> ArrayMesh:
	var n := FastNoiseLite.new()
	n.seed = 17
	n.frequency = 0.9
	var base: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -0.6, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var faces := [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]
	var tris: Array = []
	for f in faces:
		tris.append([base[f[0]], base[f[1]], base[f[2]]])
	for pass_i in 2:
		var nxt: Array = []
		for t in tris:
			var ab: Vector3 = ((t[0] + t[1]) * 0.5).normalized()
			var bc: Vector3 = ((t[1] + t[2]) * 0.5).normalized()
			var ca: Vector3 = ((t[2] + t[0]) * 0.5).normalized()
			nxt.append([t[0], ab, ca])
			nxt.append([ab, t[1], bc])
			nxt.append([ca, bc, t[2]])
			nxt.append([ab, bc, ca])
		tris = nxt
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		var pts: Array[Vector3] = []
		for v in t:
			var vv: Vector3 = v
			pts.append(vv * (0.75 + 0.5 * (n.get_noise_3dv(vv * 3.0) * 0.5 + 0.5)))
		var nrm := (pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized()
		for p in pts:
			st.set_normal(nrm)
			st.set_color(Color.WHITE)
			st.add_vertex(p)
	return st.commit()


# ---------- stacks and spray ----------

func _build_stacks_and_spray(foot: Dictionary, layout: Dictionary, rng: RandomNumberGenerator) -> void:
	var xs: Array = foot["x"]
	var zs: Array = foot["z"]
	var tips: Array[Vector3] = []
	for m in layout.get("modules", []):
		if not String(m["model"]).contains("headland"):
			continue
		var hx: float = m["pos"][0]
		var zmin := INF
		var xat := hx
		for i in xs.size():
			if absf(float(xs[i]) - hx) < 40.0 and float(zs[i]) < zmin:
				zmin = float(zs[i])
				xat = float(xs[i])
		if zmin == INF:
			continue
		tips.append(Vector3(xat, water_level, zmin))
	for tip in tips:
		# two stacks off the tip, well outside the headland and clear of the boat's lane
		for k in 2:
			var sx := tip.x + (-1.0 if k == 0 else 1.0) * rng.randf_range(14.0, 26.0)
			var sz := tip.z - rng.randf_range(12.0, 24.0)
			var n := Node3D.new()
			n.set_script(BUILDER)
			n.name = "ShoreStack_%d_%d" % [int(tip.x), k]
			n.set("model_path", STACK_MODEL)
			n.set("solid", false)          # the heavy convex hull of a 150k-triangle model costs about 0.35 s each; a cylinder is plenty

			var s := rng.randf_range(0.45, 0.8)
			n.position = Vector3(sx, -3.0, sz)
			n.rotation.y = rng.randf() * TAU
			n.scale = Vector3(s, rng.randf_range(0.5, 0.8), s)
			add_child(n)
			_cylinder_collider(n)
			_spray_at(Vector3(sx, water_level, sz + 3.0))
		_spray_at(tip + Vector3(0, 0, -1.0))
		_spray_at(tip + Vector3(-9, 0, 4))
		_spray_at(tip + Vector3(9, 0, 4))
	print("cliff_dressing: %d headland tips, %d spray emitters" % [tips.size(), _spray.size()])


var _dot: Texture2D = null


## A soft round blob (white in the middle, clear at the edge), so a spray droplet is mist and not a hard square.
func _soft_dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		_dot = gt
	return _dot


## A cheap solid for a stack: a cylinder sized from the model's bounds, on the hazard layers like the other sea rocks.
func _cylinder_collider(stack: Node3D) -> void:
	var box := AABB()
	var first := true
	for mi in stack.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var wb: AABB = m.global_transform * m.mesh.get_aabb()
		box = wb if first else box.merge(wb)
		first = false
	if first:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 3
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.36 * maxf(box.size.x, box.size.z)
	cyl.height = maxf(box.size.y, 4.0)
	cs.shape = cyl
	body.add_child(cs)
	body.global_position = box.get_center()
	add_child(body)


func _spray_at(pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 36
	p.lifetime = 1.8
	p.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 24, 24))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0.25)
	pm.spread = 28.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 8.0
	pm.gravity = Vector3(0, -5.0, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3.0, 0.2, 2.0)
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1, 0.6))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.55))
	grad.set_color(1, Color(0.85, 0.92, 1.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(2.6, 2.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _soft_dot()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.9, 0.95, 1.0, 1.0)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	p.draw_pass_1 = quad
	p.position = pos
	add_child(p)
	_spray.append(p)
