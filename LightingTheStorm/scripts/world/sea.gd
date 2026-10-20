# sea.gd - large flat sea plane with an animated wave shader, driven by a sea state (0 glass .. 5 storm).
# The wave shape lives in ONE place, wave_height(), which the shader mirrors. Anything that floats
# (the boat) calls Sea.wave_height(x, z, Sea.wave_time) so it rides exactly the surface you see.
# To change the wave SHAPE, change wave_height() and the matching lines in the shader together.
# To change how rough the sea is, change data/world/wave_spec.json (state table, shelter) - no code.
# Sea state 1 is the original look. The Wave Creator Agent's WaveSystem (wave_system.gd) sets target_state;
# the sea eases to it (so nothing pops) and tells everyone else through sea_state_changed and Sea.state.
extends MeshInstance3D

## The smoothed sea state changed by a visible amount (0 glass .. 5 storm). Lighting, Sound and island
## reactions read this; they never set it.
signal sea_state_changed(state: float)

@export var size := 2000.0
@export var spec_path := "res://data/world/wave_spec.json"

const MAX_SHELTERS := 4

## Seconds of wave phase. Advances faster in rougher seas, so it is a phase, not a clock.
static var wave_time := 0.0
## Smoothed sea state, 0..5. State 1 is the original calm look.
static var state := 1.0
## Where the state is heading. Set by WaveSystem, nothing else.
static var target_state := 1.0
## Waves on or off (off: the sea still moves, as state 1, and nothing pushes the boat).
static var waves_enabled := true
## Reduced hazard-intensity preset: 1.0 normal, 0.6 reduced (scales wave height and push).
static var intensity := 1.0

static var _states: Array = [{"amplitude_mult": 1.0, "wavelength_scale": 1.0, "time_scale": 1.0, "push_fraction": 0.0, "gust_fraction": 0.0, "gust_period_s": 0}]
static var _smoothing := 0.4
## Dock shelters: Vector4(x, z, inner, outer) and the amplitude factor each allows at its centre.
static var _shelter_pos: Array[Vector4] = []
static var _shelter_cap_state: Array[float] = []
static var _amp := 1.0
static var _kscale := 1.0
static var _tscale := 1.0

const SHADER_CODE := "
shader_type spatial;
uniform vec4 deep : source_color = vec4(0.03, 0.12, 0.16, 1.0);
uniform float wave_t = 0.0;
uniform float amp = 1.0;
uniform float k_scale = 1.0;
uniform vec4 shelter_pos[4];
uniform float shelter_factor[4];
void vertex() {
	float f = 1.0;
	for (int i = 0; i < 4; i++) {
		float d = distance(VERTEX.xz, shelter_pos[i].xy);
		f = min(f, mix(shelter_factor[i], 1.0, smoothstep(shelter_pos[i].z, shelter_pos[i].w, d)));
	}
	VERTEX.y += (sin(VERTEX.x * 0.15 * k_scale + wave_t * 1.2) * 0.35 + sin(VERTEX.z * 0.11 * k_scale + wave_t * 0.9) * 0.3) * amp * f;
}
void fragment() {
	ALBEDO = deep.rgb;
	ROUGHNESS = 0.15;
	METALLIC = 0.4;
}
"

var _mat: ShaderMaterial
var _last_emitted := 1.0


## Amplitude factor (0..1) at world (x, z) from the dock shelters: 1 in open water, less near a dock.
static func shelter_at(x: float, z: float) -> float:
	var f := 1.0
	for i in _shelter_pos.size():
		var cap := _cap_factor(i)
		var s := _shelter_pos[i]
		var d := Vector2(x - s.x, z - s.y).length()
		var t := clampf((d - s.z) / maxf(s.w - s.z, 0.001), 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		f = minf(f, lerpf(cap, 1.0, t))
	return f


## The amplitude a dock's shelter allows at its centre, as a share of the open sea's, for the live state.
static func _cap_factor(i: int) -> float:
	var s := state if waves_enabled else minf(state, 1.0)
	return clampf(_lookup("amplitude_mult", _shelter_cap_state[i]) / maxf(_lookup("amplitude_mult", s), 0.0001), 0.0, 1.0)


## Height of the water surface above the sea node's own level, at world (x, z), at wave phase t.
static func wave_height(x: float, z: float, t: float) -> float:
	return (sin(x * 0.15 * _kscale + t * 1.2) * 0.35 + sin(z * 0.11 * _kscale + t * 0.9) * 0.3) * _amp * shelter_at(x, z)


## The sea state a boat feels at (x, z): the smoothed state, held down near a dock, and zero-ish when waves are off.
static func local_state(x: float, z: float) -> float:
	var s := state if waves_enabled else minf(state, 1.0)
	var f := shelter_at(x, z)
	if f >= 0.999:
		return s
	# find the state whose amplitude matches the sheltered amplitude, so push and visuals agree
	var want := _lookup("amplitude_mult", s) * f
	for i in range(_states.size() - 1):
		var a: float = _states[i]["amplitude_mult"]
		var b: float = _states[i + 1]["amplitude_mult"]
		if want <= b:
			return float(i) + clampf((want - a) / maxf(b - a, 0.0001), 0.0, 1.0)
	return s


## Table value at a fractional state, linearly interpolated.
static func _lookup(key: String, s: float) -> float:
	var n := _states.size()
	var i := clampi(int(floor(s)), 0, n - 1)
	var j := mini(i + 1, n - 1)
	return lerpf(float(_states[i][key]), float(_states[j][key]), clampf(s - float(i), 0.0, 1.0))


## Public table lookup for WaveSystem (push and gust strengths by state).
static func table(key: String, s: float) -> float:
	return _lookup(key, s)


static func load_spec(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Sea: %s not found; using the built-in calm sea" % path)
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


static func set_shelters(zones: Array) -> void:
	_shelter_pos.clear()
	_shelter_cap_state.clear()
	for z in zones.slice(0, MAX_SHELTERS):
		_shelter_pos.append(Vector4(z["x"], z["z"], z["inner"], z["outer"]))
		_shelter_cap_state.append(z["cap_state"])


func _ready() -> void:
	wave_time = 0.0
	state = 1.0
	target_state = 1.0
	waves_enabled = true
	intensity = 1.0
	var spec := load_spec(spec_path)
	if spec.has("states"):
		_states = spec["states"]
		_smoothing = float(spec.get("state_smoothing_per_s", 0.4))
		waves_enabled = bool(spec.get("waves_enabled", true))
	_last_emitted = state
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = 200
	plane.subdivide_depth = 200
	mesh = plane
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	material_override = _mat
	_apply(0.0)


func _process(delta: float) -> void:
	state = move_toward(state, clampf(target_state, 0.0, 5.0), _smoothing * delta)
	_apply(delta)
	if absf(state - _last_emitted) >= 0.02:
		_last_emitted = state
		sea_state_changed.emit(state)


func _apply(delta: float) -> void:
	var s := state if waves_enabled else minf(state, 1.0)
	_amp = _lookup("amplitude_mult", s) * intensity
	_kscale = 1.0 / _lookup("wavelength_scale", s)
	_tscale = _lookup("time_scale", s)
	wave_time += delta * _tscale
	_mat.set_shader_parameter("wave_t", wave_time)
	_mat.set_shader_parameter("amp", _amp)
	_mat.set_shader_parameter("k_scale", _kscale)
	var pos := PackedVector4Array()
	var fac := PackedFloat32Array()
	for i in MAX_SHELTERS:
		pos.append(_shelter_pos[i] if i < _shelter_pos.size() else Vector4(0, 0, 0.001, 0.002))
		fac.append(_cap_factor(i) if i < _shelter_pos.size() else 1.0)
	_mat.set_shader_parameter("shelter_pos", pos)
	_mat.set_shader_parameter("shelter_factor", fac)
