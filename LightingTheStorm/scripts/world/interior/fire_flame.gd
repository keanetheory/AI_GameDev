# fire_flame.gd - the boiler's living fire (Lighthouse Finisher Agent, LHF-05): a bed of glowing coals, three layers of cel-shaded
# flame cards with a stepped flicker, a few drifting sparks, and a flickering light. It replaces the flat red slab in the firebox.
# coal_job.gd calls set_level(0..1) as the loads go in: low, sullen flames before any coal, tall bright ones when the dynamo runs.
# Sits at the floor of the firebox opening, local +z facing the player (rooms_house.gd turns it to +u). Everything is made in code:
# one shader (spatial, unshaded, stepped colour bands), nine coal lumps, one small GPUParticles3D, no extra dynamic lights (the
# boiler's existing fire light is driven from here).
extends Node3D

const WIDTH := 0.56          # card width: the firebox opening is 0.62 m across
const MAX_H := 0.85          # card height at full fire: the recess is 0.93 m tall

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform float level : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
uniform float speed = 1.0;
uniform vec3 core_col : source_color = vec3(1.0, 0.86, 0.45);
uniform vec3 mid_col : source_color = vec3(1.0, 0.5, 0.1);
uniform vec3 edge_col : source_color = vec3(0.72, 0.16, 0.04);
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	float y = 1.0 - UV.y;                       // 0 at the coals, 1 at the tip
	float dx = abs(UV.x - 0.5) * 2.0;
	float t = TIME * speed;
	float n = vn(vec2(UV.x * 3.5 + seed, y * 2.6 - t * 2.1)) * 0.65 + vn(vec2(UV.x * 8.0 - seed, y * 5.5 - t * 3.6)) * 0.35;
	float height = mix(0.28, 1.0, level);
	float yy = y / height;
	float body = (1.0 - yy) * (1.0 - dx * mix(1.15, 0.8, level)) + (n - 0.5) * 0.85;
	if (yy > 1.0 || body < 0.1) { discard; }
	vec3 c = edge_col;
	if (body > 0.28) { c = mid_col; }
	if (body > 0.52) { c = core_col; }
	ALBEDO = c * mix(0.7, 1.15, level);
}
"""

var _mats: Array[ShaderMaterial] = []
var _lumps: Array[MeshInstance3D] = []
var _lump_mat: StandardMaterial3D
var _sparks: GPUParticles3D
var light: OmniLight3D            # the boiler's fire light; set before add_child or via bind_light()
var _light_base := 2.0
var _level := 0.0
var _t := 0.0
var _flick := 1.0
var _next_flick := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "FireFlame"
	_rng.seed = 77
	var sh := Shader.new()
	sh.code = SHADER
	for i in 3:
		var q := QuadMesh.new()
		q.size = Vector2(WIDTH * (1.0 - 0.14 * i), MAX_H)
		var mi := MeshInstance3D.new()
		mi.name = "Flame%d" % i
		mi.mesh = q
		mi.position = Vector3(0.0, MAX_H * 0.5, -0.12 + 0.12 * i)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("seed", 3.7 * i)
		m.set_shader_parameter("speed", 0.85 + 0.2 * i)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_mats.append(m)
	_lump_mat = StandardMaterial3D.new()
	_lump_mat.albedo_color = Color(0.05, 0.035, 0.03)
	_lump_mat.emission_enabled = true
	_lump_mat.emission = Color(0.95, 0.3, 0.06)
	_lump_mat.roughness = 0.9
	for i in 10:
		var lump := MeshInstance3D.new()
		lump.name = "Coal%d" % i
		var bm := BoxMesh.new()
		var s := _rng.randf_range(0.07, 0.13)
		bm.size = Vector3(s, s * 0.7, s * 1.1)
		lump.mesh = bm
		lump.position = Vector3(_rng.randf_range(-0.23, 0.23), s * 0.3, _rng.randf_range(-0.2, 0.2))
		lump.rotation = Vector3(_rng.randf_range(-0.5, 0.5), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.5, 0.5))
		lump.material_override = _lump_mat
		lump.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lump)
		_lumps.append(lump)
	_build_sparks()
	set_level(_level)


func _build_sparks() -> void:
	_sparks = GPUParticles3D.new()
	_sparks.name = "Sparks"
	_sparks.amount = 10
	_sparks.lifetime = 1.4
	_sparks.local_coords = true
	_sparks.position = Vector3(0.0, 0.12, 0.0)
	_sparks.visibility_aabb = AABB(Vector3(-1, -0.5, -1), Vector3(2, 2, 2))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.2, 0.02, 0.15)
	pm.direction = Vector3(0.0, 1.0, 0.25)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0.0, 0.1, 0.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	_sparks.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.012)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.albedo_color = Color(1.0, 0.78, 0.35)
	q.material = sm
	_sparks.draw_pass_1 = q
	_sparks.emitting = false
	add_child(_sparks)


## Hand the boiler's fire light over: its energy is now set here (the base from the light as it stands).
func bind_light(l: OmniLight3D) -> void:
	light = l
	if light:
		_light_base = light.light_energy


## 0 = banked embers and a low flicker, 1 = a roaring fire.
func set_level(f: float) -> void:
	_level = clampf(f, 0.0, 1.0)
	for m in _mats:
		m.set_shader_parameter("level", _level)
	if _lump_mat:
		_lump_mat.emission_energy_multiplier = 0.9 + 1.5 * _level
	if _sparks:
		_sparks.emitting = _level >= 0.3
		_sparks.amount_ratio = clampf(_level, 0.3, 1.0)


func _process(delta: float) -> void:
	_t += delta
	if _t >= _next_flick:
		# a stepped flicker (cel-style): a new brightness a few times a second, never a smooth dim
		_next_flick = _t + _rng.randf_range(0.06, 0.16)
		_flick = [0.82, 0.92, 1.0, 1.1, 1.2][_rng.randi() % 5]
		if _lump_mat:
			_lump_mat.emission_energy_multiplier = (0.9 + 1.5 * _level) * (0.85 + 0.3 * _rng.randf())
	if light:
		light.light_energy = _light_base * (0.55 + 0.9 * _level) * _flick
