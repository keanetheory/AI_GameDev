# crossing_hazards.gd - builds the four kinds of return-crossing hazard the Storm Crossing Crew's forecast names: rock, reef, buoy
# and floating debris (backlog T10). Each is a StaticBody3D on physics layer 2 (the layer the boat's hull test and the dock logic
# treat as hazards) in the group "crossing_hazard", with meta hazard_id, type and lane. Plain placeholder shapes; the readability
# cues from the forecast are kept in the look: a dark rock ringed by foam, a line of low rocks in white water, a red blinking buoy
# (with a bell, see audio_mixer.gd), pale timber.
extends RefCounted

static func make(h: Dictionary, pos: Vector3, along: Vector2, cfg: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = String(h["hazard_id"])
	body.collision_layer = 2
	body.collision_mask = 0
	body.add_to_group("crossing_hazard")
	body.set_meta("hazard_id", h["hazard_id"])
	body.set_meta("type", h["type"])
	body.set_meta("lane", h["lane"])
	body.set_meta("route_m", h["route_m"])
	body.position = pos
	body.rotation.y = atan2(-along.x, -along.y)
	match String(h["type"]):
		"rock":
			_rock(body, cfg["rock"], 0.0, 1.0)
		"reef":
			_reef(body, cfg["reef"], cfg["rock"])
		"buoy":
			_buoy(body, cfg["buoy"])
		"debris":
			_debris(body, cfg["debris"])
		_:
			push_warning("crossing_hazards: unknown hazard type %s" % h["type"])
	return body


static func _mat(col: Color, rough := 0.9, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	return m


static func _shape(body: StaticBody3D, shape: Shape3D, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = at
	body.add_child(cs)


static func _foam(body: Node3D, radius: float, at: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.05
	ring.mesh = cyl
	ring.position = at + Vector3(0, 0.06, 0)
	ring.material_override = _mat(Color(0.82, 0.88, 0.9, 0.55), 0.6, 0.35)
	(ring.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(ring)


## A small copy of the sea stack's model (or a dark cone when the model is missing) with foam round its foot.
static func _rock(body: StaticBody3D, rock: Dictionary, x: float, scale_mul: float) -> void:
	var r: float = float(rock["radius_m"]) * scale_mul
	var root := Node3D.new()
	root.position = Vector3(x, 0.4, 0.0)
	var ps := load(String(rock["model"])) as PackedScene
	if ps:
		var m := ps.instantiate() as Node3D
		m.scale = Vector3.ONE * float(rock["scale"]) * scale_mul
		root.add_child(m)
	else:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = r * 0.3
		cm.bottom_radius = r
		cm.height = float(rock["height_m"])
		cone.mesh = cm
		cone.position = Vector3(0, cm.height * 0.5, 0)
		cone.material_override = _mat(Color(0.1, 0.11, 0.13))
		root.add_child(cone)
	body.add_child(root)
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = float(rock["height_m"])
	_shape(body, sh, Vector3(x, float(rock["height_m"]) * 0.5, 0.0))
	_foam(body, r * 1.7, Vector3(x, 0.45, 0.0))


## A line of low rocks across the lane in white water.
static func _reef(body: StaticBody3D, reef: Dictionary, rock: Dictionary) -> void:
	var n: int = int(reef["count"])
	var sp: float = float(reef["spacing_m"])
	var rr := {"scale": float(reef["scale"]), "radius_m": float(reef["radius_m"]), "height_m": 2.0, "model": rock["model"]}
	for i in n:
		_rock(body, rr, (i - (n - 1) * 0.5) * sp, 1.0)


static func _buoy(body: StaticBody3D, b: Dictionary) -> void:
	var r: float = float(b["radius_m"])
	var hgt: float = float(b["height_m"])
	var hull := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r * 0.55
	cyl.bottom_radius = r
	cyl.height = hgt
	hull.mesh = cyl
	hull.position = Vector3(0, hgt * 0.5 - 0.3, 0)
	hull.material_override = _mat(Color(0.62, 0.08, 0.06), 0.7)
	body.add_child(hull)
	var lamp := MeshInstance3D.new()
	lamp.name = "Lamp"
	var sph := SphereMesh.new()
	sph.radius = 0.3
	sph.height = 0.6
	lamp.mesh = sph
	lamp.position = Vector3(0, hgt - 0.1, 0)
	var lm := _mat(Color(1.0, 0.15, 0.1), 0.4, 6.0)
	lm.disable_fog = true
	lamp.material_override = lm
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(lamp)
	body.set_meta("blink_s", float(b["light_blink_s"]))
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = hgt
	_shape(body, sh, Vector3(0, hgt * 0.5 - 0.3, 0))


## Pale timber, a few planks tumbled together.
static func _debris(body: StaticBody3D, d: Dictionary) -> void:
	var size: Array = d["size_m"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(body.name))
	var mat := _mat(Color(0.78, 0.74, 0.66), 0.8, 0.08)
	var total := Vector3.ZERO
	for i in int(d["planks"]):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
		mi.mesh = bm
		var off := Vector3(rng.randf_range(-1.2, 1.2), 0.1, rng.randf_range(-1.4, 1.4))
		mi.position = off
		mi.rotation.y = rng.randf_range(-0.6, 0.6)
		mi.material_override = mat
		body.add_child(mi)
		var bs := BoxShape3D.new()
		bs.size = Vector3(bm.size.x, 1.2, bm.size.z)      # taller than the planks: timber rides the swell and a hull strikes it
		var cs := CollisionShape3D.new()
		cs.shape = bs
		cs.position = off + Vector3(0, 0.45, 0)
		cs.rotation.y = mi.rotation.y
		body.add_child(cs)
