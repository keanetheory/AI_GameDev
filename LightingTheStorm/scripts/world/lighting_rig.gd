# lighting_rig.gd - the night's lighting, read from data/world/lighting_spec.json (written by the World crew's
# Lighting agent). It builds the supermoon light, the storm sky (storm_sky.gdshader: drifting cloud, the moon
# and its gap, lightning in the cloud base), rain that follows the camera, lightning flashes and Saint Calder's
# lit windows, and sets the environment's ambient light and fog for the current phase.
#
# Phases follow the game: ISLAND until the boat leaves the island, OUTBOUND on the way to the Saltgate, RETURN
# once it leaves the Saltgate with the burner, BEACON_RELIT once the burner is fitted. The GameState autoload
# calls set_phase() as the story moves (follow_boat_signals is off by default). F5-F8 jump straight to a phase
# (ISLAND, OUTBOUND, RETURN, BEACON_RELIT) so the look can be compared; each change blends over blend_s.
# Runtime only: nothing here touches the scene in the editor, so nothing it builds is saved into Level.tscn.
extends Node3D

const DebugFlags := preload("res://scripts/core/debug_flags.gd")

const PHASES := ["ISLAND", "OUTBOUND", "RETURN", "BEACON_RELIT"]
const SKY_SHADER := preload("res://scripts/world/storm_sky.gdshader")
const WINDOW_SHADER := "
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never, fog_disabled;
uniform float glow = 0.2;
uniform float flicker = 1.0;
varying vec4 v_custom;
varying vec3 v_colour;
void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_colour = COLOR.rgb;
	// keep far windows a pixel or two wide instead of vanishing
	float dist = length((MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	VERTEX *= max(1.0, dist * 0.0016);
}
void fragment() {
	float ph = v_custom.x * 100.0;
	float wave = sin(TIME * (1.1 + v_custom.z * 2.5) + ph) * sin(TIME * (0.31 + v_custom.z * 0.6) + ph * 1.7);
	float f = mix(1.0, smoothstep(-0.35, 0.55, wave), flicker * step(0.5, v_custom.y));
	vec2 c = abs(UV - 0.5);
	float soft = 1.0 - smoothstep(0.32, 0.5, max(c.x, c.y));
	ALBEDO = v_colour * glow * f * soft * 2.5;
}
"

@export_file("*.json") var spec_path := "res://data/world/lighting_spec.json"
@export_enum("ISLAND", "OUTBOUND", "RETURN", "BEACON_RELIT") var start_phase := "ISLAND"
## Seconds a change of phase takes to blend in.
@export var blend_s := 6.0
@export var environment: NodePath = ^"../WorldEnvironment"
## The scene's existing light, switched off while the rig runs (the moon replaces it).
@export var replaces_light: NodePath = ^"../Sun"
@export var boat: NodePath = ^"../Boat"
@export var saint_calder: NodePath = ^"../SaintCalder"
## Where the windows read at glow_at_lighthouse and at glow_at_saltgate.
@export var lighthouse_point := Vector3(5, 10, -8.5)
@export var saltgate_point := Vector3(15, 3, 550)
## The spec's lightning energy is for the flash on its own; scaled down so the tonemapper keeps hazards dark.
@export var lightning_scale := 0.35
@export var window_count := 600
## Share of strikes placed in front of the camera (the rest land anywhere around it).
@export_range(0.0, 1.0) var in_view_share := 0.75
## F5-F8 phase jumps and the "Lighting: <phase>" label. Only ever on in a debug build (see debug_flags.gd).
@export var debug_keys := true
## false: the GameState autoload drives the phases (scripts/core/game_state.gd). true: the rig also follows the
## boat's departed signal itself, for running the scene on its own. Leave false in the game or both would drive it.
@export var follow_boat_signals := false
## Rain look (creator, 2026-10-22: darker and thinner). rain_thin scales how many streaks fall; rain_dark scales their brightness.
@export_range(0.1, 1.0) var rain_thin := 0.62
@export_range(0.1, 1.0) var rain_dark := 0.5
@export_range(0.05, 0.6) var rain_alpha := 0.2
## How much of each phase's wind slant the rain takes (creator, 2026-10-22: straight down). 0 = vertical, 1 = the spec's slant.
@export_range(0.0, 1.0) var rain_slant_scale := 0.0
## Fall speed in metres a second (min, max), and the length of each streak in metres.
@export var rain_speed := Vector2(30.0, 38.0)
@export var rain_streak_len := 0.35

var phase := ""
var _spec: Dictionary = {}
var _env: Environment
var _sky_mat: ShaderMaterial
var _moon: DirectionalLight3D
var _moon_base := 0.0   # the moon light's energy for the phase, before the eclipse takes some away
var _moon_dim := 1.0    # 0..1 how much of the moon is left (eclipse_object.gd)
var _fog_base := Color(0.17, 0.23, 0.25)  # the phase's fog colour, before the eclipse takes some away
var _ambient_base := 0.5  # the phase's ambient energy, before the eclipse takes some away

## How much ambient light survives a total eclipse (1 = none lost). The ambient follows the moon's dimming down to this.
@export_range(0.0, 1.0) var ambient_floor := 0.05
## The same for the distance fog's colour: how much of it is left once the eclipse is total. Fog sets the colour of
## everything far away (the lighthouse, the stacks, the far shore), and the lights do not reach it.
@export_range(0.0, 1.0) var fog_floor := 0.06
var _bolt: DirectionalLight3D
var _rain: GPUParticles3D
const RAIN_SHADER := preload("res://scripts/world/rain_streak.gdshader")
@export var rain_shelter: NodePath = ^"../RainShelter"     # its volumes (interior air) are cut out of the rain
var _rain_mat: ParticleProcessMaterial
var _splash: GPUParticles3D
var _rain_floor: GPUParticlesCollisionHeightField3D
var _windows: MultiMeshInstance3D
var _window_mat: ShaderMaterial
var _label: Label
var _label_t := 0.0
var _from: Dictionary = {}
var _to: Dictionary = {}
var _cur: Dictionary = {}
var _blend := 1.0
var _rng := RandomNumberGenerator.new()
var _next_flash := 4.0
var _flash_t := -1.0
var _flash_len := 0.2
var _flash_peak := 1.0
var _pulses: Array = []      # [start_s, length_s, level] per cloud flicker in the current strike
var _headless := false


func _ready() -> void:
	debug_keys = debug_keys and DebugFlags.allowed()
	add_to_group("lighting_rig")   # GameState finds the rig by this group and drives set_phase()
	_headless = DisplayServer.get_name() == "headless"
	var f := FileAccess.open(spec_path, FileAccess.READ)
	if f == null:
		push_error("lighting_rig: cannot read %s" % spec_path)
		return
	_spec = JSON.parse_string(f.get_as_text())
	_rng.randomize()
	var old := get_node_or_null(replaces_light) as Light3D
	if old:
		old.visible = false
	_build_moon()
	_build_lightning()
	if not _headless:
		_build_sky()
		_build_rain()
		if debug_keys:
			_build_label()
		_build_windows.call_deferred()
	var b := get_node_or_null(boat)
	if follow_boat_signals and b and b.has_signal("departed"):
		b.departed.connect(_on_boat_departed)
	set_phase(start_phase, true)


# ---------------- phases ----------------

## Switches to a phase (ISLAND, OUTBOUND, RETURN, BEACON_RELIT), blending over blend_s unless `instant`.
func set_phase(id: String, instant := false) -> void:
	var p := _phase_spec(id)
	if p.is_empty():
		return
	phase = id
	_to = _values(p)
	if instant or _cur.is_empty():
		_cur = _to.duplicate()
		_blend = 1.0
		_apply(_cur)
	else:
		_from = _cur.duplicate()
		_blend = 0.0
	_next_flash = _rng.randf_range(1.5, 4.0)
	if _label:
		_label.text = "Lighting: " + id
		_label_t = 2.5


func _on_boat_departed(zone_id: String) -> void:
	if zone_id == "DOCK_LIGHTHOUSE" and phase == "ISLAND":
		set_phase("OUTBOUND")
	elif zone_id == "DOCK_PORT":
		set_phase("RETURN")   # leaving the Saltgate means the burner is aboard


func _phase_spec(id: String) -> Dictionary:
	for p in _spec.get("phases", []):
		if p["phase_id"] == id:
			return p
	push_error("lighting_rig: no phase %s in the spec" % id)
	return {}


## The numbers one phase sets, flattened so two phases can be blended.
func _values(p: Dictionary) -> Dictionary:
	var c: Dictionary = p["clouds"]
	var r: Dictionary = p["rain"]
	var l: Dictionary = p["lightning"]
	return {
		"ambient_colour": Color.html(p["ambient_colour"]), "ambient_energy": float(p["ambient_energy"]),
		"fog_colour": Color.html(p["fog_colour"]), "fog_density": float(p["fog_density"]),
		"coverage": float(c["coverage"]), "darkness": float(c["darkness"]), "drift": float(c["drift_mps"]),
		"cloud_top": Color.html(c["top_colour"]), "cloud_under": Color.html(c["underside_colour"]),
		"moon_gap": 1.0 if c["moon_gap"] else 0.0,
		"low_coverage": float(c.get("low_coverage", 0.0)), "low_opacity": float(c.get("low_opacity", 0.0)),
		"low_drift": float(c.get("low_drift_mps", 0.0)), "low_colour": Color.html(c.get("low_colour", "#0E0E10")),
		"rain": float(r["intensity"]), "slant": float(r["slant_deg"]),
		"lightning": bool(l["enabled"]), "interval": l["interval_s"] if l["enabled"] else [0.0, 0.0],
	}


func _process(delta: float) -> void:
	if _spec.is_empty():
		return
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta / maxf(blend_s, 0.01))
		var t := _blend * _blend * (3.0 - 2.0 * _blend)
		for k in _to:
			var a = _from.get(k, _to[k])
			var b = _to[k]
			_cur[k] = lerp(a, b, t) if (a is float or a is Color) else b
		_apply(_cur)
	_update_lightning(delta)
	_follow_camera()
	if _label and _label_t > 0.0:
		_label_t -= delta
		_label.modulate.a = clampf(_label_t, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not debug_keys or key == null or not key.pressed or key.echo:
		return
	var i := [KEY_F5, KEY_F6, KEY_F7, KEY_F8].find(key.keycode)
	if i >= 0:
		set_phase(PHASES[i])
		get_viewport().set_input_as_handled()


func _apply(v: Dictionary) -> void:
	var dark: float = v["darkness"]
	if _env:
		_env.ambient_light_color = v["ambient_colour"]
		_ambient_base = float(v["ambient_energy"])
		_env.ambient_light_energy = _ambient_base * _ambient_scale()
		_fog_base = v["fog_colour"]
		_env.fog_light_color = _fog_base * _fog_scale()
		_env.fog_density = v["fog_density"]
	if _sky_mat:
		_sky_mat.set_shader_parameter("coverage", v["coverage"])
		_sky_mat.set_shader_parameter("darkness", dark)
		_sky_mat.set_shader_parameter("drift", v["drift"])
		_sky_mat.set_shader_parameter("cloud_top", v["cloud_top"])
		_sky_mat.set_shader_parameter("cloud_under", v["cloud_under"])
		_sky_mat.set_shader_parameter("moon_gap", v["moon_gap"])
		_sky_mat.set_shader_parameter("low_coverage", v["low_coverage"])
		_sky_mat.set_shader_parameter("low_opacity", v["low_opacity"])
		_sky_mat.set_shader_parameter("low_drift", v["low_drift"])
		_sky_mat.set_shader_parameter("low_colour", v["low_colour"])
	if _moon:
		# the moon lights both crossings; the thickening storm only takes the edge off it
		_moon_base = float(_spec["moon"]["light_energy"]) * (1.0 - 0.3 * dark)
		_moon.light_energy = _moon_base * _moon_dim
	if _rain:
		var amount: float = v["rain"]
		_rain.emitting = amount > 0.01
		_rain.amount_ratio = clampf(amount, 0.0, 1.0) * rain_thin
		var slant := deg_to_rad(float(v["slant"])) * rain_slant_scale
		_rain_mat.direction = Vector3(sin(slant) * 0.8, -cos(slant), sin(slant) * 0.6).normalized()


# ---------------- moon and environment ----------------

func _build_moon() -> void:
	var m: Dictionary = _spec["moon"]
	_moon = DirectionalLight3D.new()
	_moon.name = "Moon"
	_moon.light_color = Color.html(m["colour"])
	_moon.light_energy = float(m["light_energy"])
	_moon.light_specular = 0.22      # keeps the moon's path on the sea from blowing out
	_moon.shadow_enabled = true
	_moon.directional_shadow_max_distance = 300.0
	_moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(_moon)
	_moon.global_basis = Basis.looking_at(-_moon_dir())


## Fog is self-lit (the lights never touch it), so it is dimmed by hand along the same curve as the ambient.
func _fog_scale() -> float:
	return lerpf(fog_floor, 1.0, _moon_dim)


func _ambient_scale() -> float:
	return lerpf(ambient_floor, 1.0, _moon_dim)


## The eclipse object (eclipse_object.gd drives this): drawn in the sky shader between the moon and the cloud.
## radius is its angular radius in radians, spin in turns. Does nothing in a headless run (there is no sky).
func set_eclipse(tex: Texture2D, dir: Vector3, right: Vector3, radius: float, spin: float, moon_left := 1.0, reflection := 1.0) -> void:
	_moon_dim = clampf(moon_left, 0.0, 1.0)
	if _env:
		_env.ambient_light_energy = _ambient_base * _ambient_scale()
		_env.fog_light_color = _fog_base * _fog_scale()
	if _moon:
		_moon.light_energy = _moon_base * _moon_dim
	var sea := get_parent().get_node_or_null("Sea") if get_parent() else null
	if sea and sea.has_method("set_moon_dim"):
		sea.set_moon_dim(_moon_dim)
	if _sky_mat == null:
		return
	_sky_mat.set_shader_parameter("moon_light", _moon_dim)
	_sky_mat.set_shader_parameter("reflection_dim", reflection)
	_sky_mat.set_shader_parameter("eclipse_tex", tex)
	_sky_mat.set_shader_parameter("eclipse_dir", dir)
	_sky_mat.set_shader_parameter("eclipse_right", right)
	_sky_mat.set_shader_parameter("eclipse_radius", radius)
	_sky_mat.set_shader_parameter("eclipse_spin", spin)


## Direction towards the moon, from its compass bearing (0 = north = -Z) and elevation.
func _moon_dir() -> Vector3:
	var m: Dictionary = _spec["moon"]
	var az := deg_to_rad(float(m["azimuth_deg"]))
	var el := deg_to_rad(float(m["elevation_deg"]))
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el)).normalized()


func _build_sky() -> void:
	var we := get_node_or_null(environment) as WorldEnvironment
	if we == null or we.environment == null:
		push_error("lighting_rig: no WorldEnvironment at %s" % environment)
		return
	_env = we.environment.duplicate()   # the scene's own resource is left as it is
	we.environment = _env
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SKY_SHADER
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_env.fog_enabled = true
	_env.fog_sky_affect = 0.25
	var m: Dictionary = _spec["moon"]
	_sky_mat.set_shader_parameter("moon_dir", _moon_dir())
	_sky_mat.set_shader_parameter("moon_colour", Color.html(m["colour"]))
	_sky_mat.set_shader_parameter("moon_radius", deg_to_rad(1.1 * float(m["disc_scale"])))
	_sky_mat.set_shader_parameter("flash_colour", Color.html(_spec["lightning"]["colour"]))
	var city := get_node_or_null(saint_calder) as Node3D
	if city:
		var to_city := city.global_position - lighthouse_point
		_sky_mat.set_shader_parameter("dark_dir", Vector3(to_city.x, 0.0, to_city.z).normalized())


# ---------------- lightning ----------------

func _build_lightning() -> void:
	_bolt = DirectionalLight3D.new()
	_bolt.name = "LightningFlash"
	_bolt.light_color = Color.html(_spec["lightning"]["colour"])
	_bolt.light_energy = 0.0
	_bolt.shadow_enabled = false
	_bolt.light_specular = 0.05      # no second hot streak on the sea
	_bolt.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(_bolt)


## Fires one strike now (also used by tests and screenshots); `towards` aims it, otherwise anywhere in the
## sky. A strike is ONE scene-wide flash (what the photosensitivity cap counts) plus a visible forked bolt
## that strobes the cloud around it strobe_pulses times (the flicker stays in that cloud).
func flash_now(towards := Vector3.ZERO) -> void:
	var lt: Dictionary = _spec["lightning"]
	# Most strikes land in front of the player, low enough to be seen when looking at the horizon
	# (the view only reaches about 37 degrees up); some land off to the sides for the sense of a storm all round.
	var az := _rng.randf_range(0.0, TAU)
	var cam := get_viewport().get_camera_3d()
	if cam and _rng.randf() < in_view_share:
		var fwd := -cam.global_basis.z
		az = atan2(fwd.x, -fwd.z) + deg_to_rad(_rng.randf_range(-35.0, 35.0))
	var el := deg_to_rad(_rng.randf_range(12.0, 20.0))
	var dir := Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
	if towards != Vector3.ZERO:
		dir = towards.normalized()
	_bolt.global_basis = Basis.looking_at(-dir)
	_flash_len = _rng.randf_range(float(lt["flash_duration_s"][0]), float(lt["flash_duration_s"][1]))
	_flash_peak = _rng.randf_range(0.6, 1.0)
	_flash_t = 0.0
	# the flickers: each a short sharp pulse, fading a little each time
	_pulses.clear()
	var n := _rng.randi_range(int(lt.get("strobe_pulses", [1, 1])[0]), int(lt.get("strobe_pulses", [1, 1])[1]))
	var gap: Array = lt.get("strobe_gap_s", [0.08, 0.08])
	var t := 0.0
	var level := 1.0
	for i in n:
		_pulses.append([t, _rng.randf_range(0.06, 0.1), level])
		t += _rng.randf_range(float(gap[0]), float(gap[1]))
		level *= _rng.randf_range(0.55, 0.9)
	if _sky_mat:
		_sky_mat.set_shader_parameter("flash_dir", dir)
		if lt.get("bolt_visible", false):
			_make_bolt(dir)


## Builds a jagged, forked bolt in the plane facing the camera at `dir` and hands it to the sky shader.
func _make_bolt(dir: Vector3) -> void:
	var b_axis := (Vector3.UP - dir * dir.dot(Vector3.UP)).normalized()   # "up" on the sky at the strike
	var t_axis := b_axis.cross(dir).normalized()
	var segs: Array[Vector4] = []
	# main channel: from the top of the cloud sideways and down, midpoint-displaced
	var start := Vector2(_rng.randf_range(-0.12, 0.12), _rng.randf_range(0.26, 0.34))
	var end := Vector2(start.x + _rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.3, -0.2))
	var main := _jag([start, end], 4, 0.08)
	for i in main.size() - 1:
		segs.append(Vector4(main[i].x, main[i].y, main[i + 1].x, main[i + 1].y))
	# two to four forks branching off it
	for f in _rng.randi_range(2, 4):
		var k := _rng.randi_range(1, main.size() - 3)
		var from: Vector2 = main[k]
		var to := from + Vector2(_rng.randf_range(-0.22, 0.22), _rng.randf_range(-0.18, -0.05))
		var fork := _jag([from, to], 2, 0.04)
		for i in fork.size() - 1:
			if segs.size() < 48:
				segs.append(Vector4(fork[i].x, fork[i].y, fork[i + 1].x, fork[i + 1].y))
	var packed := PackedVector4Array()
	for v in segs.slice(0, 48):
		packed.append(v)
	_sky_mat.set_shader_parameter("bolt", packed)
	_sky_mat.set_shader_parameter("bolt_count", packed.size())
	_sky_mat.set_shader_parameter("bolt_t", t_axis)
	_sky_mat.set_shader_parameter("bolt_b", b_axis)


## Midpoint displacement: splits every segment `levels` times, pushing each midpoint sideways.
func _jag(pts: Array, levels: int, amount: float) -> Array:
	for l in levels:
		var out := [pts[0]]
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var n := (b - a).orthogonal().normalized()
			out.append((a + b) * 0.5 + n * _rng.randf_range(-amount, amount))
			out.append(b)
		pts = out
		amount *= 0.55
	return pts


func _update_lightning(delta: float) -> void:
	if _cur.get("lightning", false):
		_next_flash -= delta
		if _next_flash <= 0.0:
			flash_now()
			var iv: Array = _cur["interval"]
			# never closer than the photosensitivity cap allows
			var gap := 1.0 / float(_spec["lightning"]["max_flashes_per_second"])
			_next_flash = maxf(gap, _rng.randf_range(float(iv[0]), float(iv[1])))
	var e := 0.0
	var strobe := 0.0
	if _flash_t >= 0.0:
		_flash_t += delta
		var attack := 0.025
		e = _flash_t / attack if _flash_t < attack else exp(-(_flash_t - attack) / maxf(_flash_len * 0.45, 0.01))
		e *= _flash_peak
		for p in _pulses:
			var u: float = _flash_t - float(p[0])
			if u >= 0.0 and u < float(p[1]) * 2.5:
				strobe = maxf(strobe, float(p[2]) * (1.0 if u < float(p[1]) else exp(-(u - float(p[1])) / (float(p[1]) * 0.4))))
		var last: Array = _pulses[-1] if not _pulses.is_empty() else [0.0, 0.0, 0.0]
		if _flash_t > maxf(_flash_len * 3.0, float(last[0]) + float(last[1]) * 2.5):
			_flash_t = -1.0
			e = 0.0
			strobe = 0.0
	_bolt.light_energy = float(_spec["lightning"]["peak_energy"]) * lightning_scale * e
	if _sky_mat:
		_sky_mat.set_shader_parameter("flash", e)
		_sky_mat.set_shader_parameter("strobe", strobe)
		# the channel lingers faintly between flickers, so the bolt reads as one strike
		_sky_mat.set_shader_parameter("bolt_glow", maxf(strobe, 0.45 * e if _flash_t >= 0.0 else 0.0))


# ---------------- rain ----------------

func _build_rain() -> void:
	_rain = GPUParticles3D.new()
	_rain.name = "Rain"
	_rain.amount = 8000
	_rain.lifetime = 0.9
	_rain.local_coords = false
	_rain.top_level = true
	_rain.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	_rain_mat = ParticleProcessMaterial.new()
	_rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_rain_mat.emission_box_extents = Vector3(26, 1, 26)
	_rain_mat.direction = Vector3(0, -1, 0)
	_rain_mat.spread = 3.0
	_rain_mat.initial_velocity_min = rain_speed.x
	_rain_mat.initial_velocity_max = rain_speed.y
	_rain_mat.gravity = Vector3(0, -9.8, 0)
	# rain stops where it lands (boat, dock, island, lighthouse, sea) and throws up a few small drops there
	_rain_mat.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	_rain_mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_COLLISION
	_rain_mat.sub_emitter_amount_at_collision = 1
	_rain_mat.sub_emitter_keep_velocity = false
	_rain.process_material = _rain_mat
	var streak := QuadMesh.new()
	streak.size = Vector2(0.018, rain_streak_len)
	var c := Color.html(_phase_spec("RETURN")["rain"]["colour"])
	var mat := ShaderMaterial.new()
	mat.shader = RAIN_SHADER
	mat.set_shader_parameter("albedo", Color(c.r * rain_dark, c.g * rain_dark, c.b * rain_dark, rain_alpha))
	mat.set_shader_parameter("fixed_y", true)
	streak.material = mat
	_rain.draw_pass_1 = streak
	_rain.emitting = false
	add_child(_rain)
	_build_splash(Color(c.r * 0.7, c.g * 0.7, c.b * 0.7, 0.55))
	_build_rain_floor()
	apply_rain_shelters()


## Hands the RainShelter volumes (the lighthouse's interior air) to the rain and splash materials, which discard any fragment inside one.
## Boxes only turned about the vertical axis (kit frame and tower bars are). Safe to call again if the volumes change.
func apply_rain_shelters() -> void:
	var rs := get_node_or_null(rain_shelter)
	if rs == null or not ("volumes" in rs):
		return
	var a := PackedVector4Array()
	var b := PackedVector4Array()
	for v in rs.volumes:
		var xf: Transform3D = v["xf"]
		var h: Vector3 = (v["size"] as Vector3) * 0.5
		var ax := Vector2(xf.basis.x.x, xf.basis.x.z).normalized()
		a.append(Vector4(xf.origin.x, xf.origin.y, xf.origin.z, h.x))
		b.append(Vector4(ax.x, ax.y, h.y, h.z))
	var n := mini(a.size(), 32)
	a.resize(32)
	b.resize(32)
	for m in [_rain.draw_pass_1.material, _splash.draw_pass_1.material]:
		var sm := m as ShaderMaterial
		sm.set_shader_parameter("vol_n", n)
		sm.set_shader_parameter("vol_a", a)
		sm.set_shader_parameter("vol_b", b)


## The small drops thrown up where a raindrop hits: a short burst of tiny specks that fly up and fall back.
func _build_splash(col: Color) -> void:
	_splash = GPUParticles3D.new()
	_splash.name = "RainSplash"
	_splash.amount = 3000
	_splash.lifetime = 0.35
	_splash.local_coords = false
	_splash.top_level = true
	_splash.emitting = false       # a sub-emitter: the rain starts it, at the point of impact
	_splash.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 2.4
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	_splash.process_material = pm
	var drop := QuadMesh.new()
	drop.size = Vector2(0.05, 0.1)
	var dm := ShaderMaterial.new()
	dm.shader = RAIN_SHADER
	dm.set_shader_parameter("albedo", col)
	dm.set_shader_parameter("fixed_y", false)
	drop.material = dm
	_splash.draw_pass_1 = drop
	add_child(_splash)
	_rain.sub_emitter = _rain.get_path_to(_splash)


## What the rain lands on: a height field of everything under the camera, seen from above. It follows the camera, so it always
## covers the rain's 52 m box, and it is redrawn every frame so the boat's motion counts. The lighthouse roof stops the rain
## over its rooms (a drop that starts under a roof is already inside the field's surface and is hidden at once).
func _build_rain_floor() -> void:
	_rain_floor = GPUParticlesCollisionHeightField3D.new()
	_rain_floor.name = "RainFloor"
	_rain_floor.top_level = true
	_rain_floor.size = Vector3(60, 80, 60)
	_rain_floor.resolution = GPUParticlesCollisionHeightField3D.RESOLUTION_512
	_rain_floor.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
	_rain_floor.follow_camera_enabled = true
	if "heightfield_mask" in _rain_floor:   # not on every engine build; without it the default (all layers) is fine
		_rain_floor.set("heightfield_mask", 1)   # the world's visible surfaces (layer 1)
	add_child(_rain_floor)


func _follow_camera() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if _rain:
		_rain.global_position = cam.global_position + Vector3(0, 12, 0)
	if _splash:
		_splash.global_position = cam.global_position
	if _rain_floor:
		_rain_floor.global_position = cam.global_position
	if _window_mat:
		var city := get_node_or_null(saint_calder) as Node3D
		if city:
			var sc: Dictionary = _spec["saint_calder"]
			var d_far := lighthouse_point.distance_to(city.global_position)
			var d_near := saltgate_point.distance_to(city.global_position)
			var t := clampf(inverse_lerp(d_far, d_near, cam.global_position.distance_to(city.global_position)), 0.0, 1.0)
			_window_mat.set_shader_parameter("glow", lerpf(float(sc["glow_at_lighthouse"]), float(sc["glow_at_saltgate"]), t))


# ---------------- Saint Calder's windows ----------------

## Scatters lit windows over the city's walls that face the sea (and so the player).
func _build_windows() -> void:
	var city := get_node_or_null(saint_calder) as Node3D
	if city == null or not _spec["saint_calder"]["window_lights"]:
		return
	var tris: Array = []      # [a, b, c, normal]
	var areas := PackedFloat32Array()
	var total := 0.0
	var facing := (lighthouse_point - city.global_position)
	facing = Vector3(facing.x, 0.0, facing.z).normalized()
	for mi in city.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).mesh
		if m == null:
			continue
		var xf := (mi as MeshInstance3D).global_transform
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				idx = PackedInt32Array(range(v.size()))
			for t in range(0, idx.size(), 3):
				var a := xf * v[idx[t]]
				var b := xf * v[idx[t + 1]]
				var c := xf * v[idx[t + 2]]
				var n := (b - a).cross(c - a)
				var area := n.length() * 0.5
				if area < 0.5:
					continue
				n = n.normalized()
				if absf(n.y) > 0.3 or n.dot(facing) < 0.25:
					n = -n         # generated meshes sometimes wind the other way
					if absf(n.y) > 0.3 or n.dot(facing) < 0.25:
						continue
				tris.append([a, b, c, n])
				total += area
				areas.append(total)
	if tris.is_empty():
		push_warning("lighting_rig: no sea-facing walls found on Saint Calder for windows")
		return
	var colours: Array = _spec["saint_calder"]["colours"]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1.4, 2.0)
	mm.mesh = quad
	mm.instance_count = window_count
	for i in window_count:
		var k := areas.bsearch(_rng.randf() * total)
		var tri: Array = tris[mini(k, tris.size() - 1)]
		var r1 := sqrt(_rng.randf())
		var r2 := _rng.randf()
		var p: Vector3 = tri[0] * (1.0 - r1) + tri[1] * (r1 * (1.0 - r2)) + tri[2] * (r1 * r2)
		var n: Vector3 = tri[3]
		var x := Vector3.UP.cross(n).normalized()
		mm.set_instance_transform(i, Transform3D(Basis(x, n.cross(x), n), p + n * 0.2))
		mm.set_instance_color(i, Color.html(colours[_rng.randi() % colours.size()]))
		mm.set_instance_custom_data(i, Color(_rng.randf(), _rng.randf(), _rng.randf(), 0.0))
	_window_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WINDOW_SHADER
	_window_mat.shader = sh
	_window_mat.set_shader_parameter("flicker", 1.0 if "flicker" in str(_spec["saint_calder"]["flicker"]).to_lower() else 0.0)
	_windows = MultiMeshInstance3D.new()
	_windows.name = "SaintCalderWindows"
	_windows.multimesh = mm
	_windows.material_override = _window_mat
	_windows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_windows.top_level = true
	add_child(_windows)
	_windows.global_transform = Transform3D.IDENTITY


func _build_label() -> void:
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	layer.add_child(_label)
	add_child(layer)
