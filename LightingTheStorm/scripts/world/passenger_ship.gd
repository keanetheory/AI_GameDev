# passenger_ship.gd - the Lantern Queen, the ship the beacon must save (T31, T07). Spawned at runtime by
# scripts/core/ship_deadline.gd, so Level.tscn does not carry it. It owns the ship's look (the model, its lit windows,
# navigation lights, deck lanterns and a close-range light spill, T44) and its movement; the deadline clock lives in
# ship_deadline.gd.
#
# Modes: HIDDEN (before boarding) -> HOLD (lights at the horizon, progress 0) -> APPROACH (the director sets the progress
# 0..1 each frame) -> COMMITTED (the clock ran out: it can no longer turn and runs onto the rock) -> CRASHED, or
# AVOIDING (the beacon is lit: it steers off the approach lane onto the safe lane) -> PASSED (into port, hidden).
# Signals: impact (the bow meets the rock; the audio mixer and the outcome screen time on it), cleared_rock (a saved ship is
# past the rock: the win card waits for it) and passed (into port).
extends Node3D

const Route := preload("res://scripts/world/ship_route.gd")

# Lit windows: panes laid flat on the hull. Far away a pane grows in its own plane so the windows run together into lit
# decks (they never turn into balls). power < 1 is the crash: the lights flicker and die. Additive, so a dead window
# leaves the hull as it is rather than a black square.
const WINDOW_SHADER := "
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, fog_disabled;
uniform float brightness = 2.4;
uniform float grow_per_m = 0.005;
uniform vec2 grow_max = vec2(3.2, 2.0);
uniform float power = 1.0;
varying vec4 v_custom;
varying vec3 v_colour;
void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_colour = COLOR.rgb;
	float dist = length((MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	VERTEX.xy *= min(vec2(1.0 + dist * grow_per_m), grow_max);
}
void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	if (v_custom.y > 0.5 && dot(c, c) > 1.0) {
		discard;      // a round porthole
	}
	float ph = v_custom.x * 100.0;
	float f = v_custom.z;      // this cabin's own brightness
	if (v_custom.w > 0.5) {    // a few lamps gutter
		f *= mix(0.55, 1.0, smoothstep(-0.4, 0.6, sin(TIME * 1.3 + ph) * sin(TIME * 0.37 + ph * 1.7)));
	}
	float p = power >= 1.0 ? 1.0 : power * (0.6 + 0.4 * sin(TIME * 37.0 + ph));
	ALBEDO = v_colour * brightness * f * max(p, 0.0);
}
"

# A navigation light or deck lantern: a small lit core on its mount (billboard off) and a soft glow around it (billboard
# on) that grows with distance. Each shows only in its sector, measured from the bow (+ is starboard), as on a real ship.
const LAMP_SHADER := "
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, fog_disabled, cull_disabled;
uniform vec3 colour = vec3(1.0);
uniform float brightness = 3.0;
uniform bool billboard = false;
uniform float size_m = 1.0;
uniform float per_m = 0.0;
uniform float max_m = 1.0;
uniform float sector_centre = 0.0;
uniform float sector_half = 180.0;
uniform float phase = 0.0;
uniform float power = 1.0;
varying float v_vis;
void vertex() {
	vec3 cam = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	float ang = degrees(atan(cam.x, -cam.z));
	float off = abs(mod(ang - sector_centre + 540.0, 360.0) - 180.0);
	v_vis = 1.0 - smoothstep(sector_half - 2.0, sector_half + 2.0, off);
	if (billboard) {
		float d = length(cam);
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX[3].z += min(1.2, d * 0.1);      // in front of its own lantern housing
		VERTEX.xy *= clamp(d * per_m, size_m, max_m);
	}
}
void fragment() {
	float g = 1.0;
	if (billboard) {
		float r = length(UV * 2.0 - 1.0);
		g = (exp(-r * r * 9.0) + 0.3 * exp(-r * r * 2.5)) * (1.0 - smoothstep(0.75, 1.0, r));
	}
	float p = power >= 1.0 ? 1.0 : power * (0.6 + 0.4 * sin(TIME * 37.0 + phase));
	ALBEDO = colour * brightness * g * v_vis * max(p, 0.0);
}
"

# Sectors (centre, half-width in degrees from the bow) for the lamps in ship_route.json.
const SECTORS := {"masthead": [0.0, 112.5], "starboard": [56.25, 56.25], "port": [-56.25, 56.25], "stern": [180.0, 67.5], "all": [0.0, 180.0]}

signal impact
signal passed
signal cleared_rock      # saved: the ship is past the grounding rock and the island, heading for port

enum Mode { HIDDEN, HOLD, APPROACH, COMMITTED, CRASHED, AVOIDING, PASSED }

var mode: int = Mode.HIDDEN
var spec: Dictionary = {}

var _approach := PackedVector2Array()
var _safe := PackedVector2Array()
var _commit_s := 0.0           # path distance at which the clock expires (progress 1)
var _total_s := 0.0            # path distance of the bow-on-rock point
var _join_s := 0.0             # path distance of the approach point the safe lane starts from
var _s := 0.0                  # distance travelled along the approach lane
var _speed := 0.0              # m/s, set by the director from the deadline length
var _pos := Vector2.ZERO
var _dir := Vector2(0, 1)
var _wp := 0
var _model: Node3D
var _hull: Node3D              # the model and lights, rolled and sunk by the crash
var _light_mats: Array = []    # every window and lamp ShaderMaterial, faded together by the crash
var _spill: Array = []         # the close-range OmniLights
var _t := 0.0
var _crash_t := -1.0
var _keel_y := -2.4
var cleared := false


func setup(route: Dictionary) -> void:
	spec = route
	_approach = Route.points(route["approach"]["points"])
	_safe = Route.points(route["safe_lane"]["points"])
	_total_s = Route.length(_approach)
	_commit_s = maxf(_total_s - float(route["approach"]["commit_distance_m"]), 1.0)
	var upto := PackedVector2Array()
	for i in int(route["safe_lane"]["first_is_approach_index"]) + 1:
		upto.append(_approach[i])
	_join_s = Route.length(upto)
	_keel_y = float(route["ship"]["keel_y"])
	_hull = Node3D.new()
	_hull.name = "Hull"
	add_child(_hull)
	var packed := load(String(route["ship"]["model"])) as PackedScene
	if packed:
		_model = packed.instantiate()
		_hull.add_child(_model)
	else:
		push_warning("passenger_ship: model %s did not load" % route["ship"]["model"])
	_build_lights(route["lights"])
	_place()
	visible = false


## The ship's speed in m/s: the distance to the commit point over the deadline length.
func set_deadline_length(length_s: float) -> void:
	_speed = _commit_s / maxf(length_s, 1.0)


func speed() -> float:
	return _speed


func commit_s() -> float:
	return _commit_s


func total_s() -> float:
	return _total_s


func travelled() -> float:
	return _s


func position2() -> Vector2:
	return _pos


func direction2() -> Vector2:
	return _dir


## The ship comes into view at the horizon (the boarding threshold) and holds there.
func appear() -> void:
	if mode == Mode.HIDDEN:
		mode = Mode.HOLD
		visible = true


## Deadline progress 0..1 while the clock runs: the ship's position is a pure function of it, so pausing, the debug time
## scale and replays all stay in step.
func set_progress(p: float) -> void:
	if mode == Mode.HOLD or mode == Mode.APPROACH:
		mode = Mode.APPROACH if p > 0.0 else Mode.HOLD
		_s = clampf(p, 0.0, 1.0) * _commit_s
		_place()


## The deadline ran out: the ship can no longer turn and runs on to the rock.
func commit() -> void:
	if mode == Mode.HIDDEN:
		visible = true
		mode = Mode.HOLD
	if mode == Mode.HOLD or mode == Mode.APPROACH:
		_s = _commit_s
		_place()
		mode = Mode.COMMITTED


## The beacon is lit: the ship sees the rocks and steers onto the safe lane.
func avoid() -> void:
	if mode == Mode.HIDDEN:
		visible = true
		mode = Mode.HOLD
	if mode == Mode.HOLD or mode == Mode.APPROACH:
		mode = Mode.AVOIDING
		_wp = 1 if _s >= _join_s else 0    # already past the point where the lanes part: start with the next one


func is_resolved() -> bool:
	return mode == Mode.CRASHED or mode == Mode.PASSED


func _process(delta: float) -> void:
	_t += delta
	_update_spill()
	match mode:
		Mode.COMMITTED:
			_s = minf(_s + _speed * delta, _total_s)
			_place()
			if _s >= _total_s:
				mode = Mode.CRASHED
				_crash_t = 0.0
				impact.emit()
		Mode.AVOIDING:
			_steer(delta)
		Mode.CRASHED:
			_crash(delta)
	_sway()


func _steer(delta: float) -> void:
	var target: Vector2 = _safe[_wp]
	var want := (target - _pos).normalized()
	var turn_max := deg_to_rad(float(spec["ship"]["turn_rate_deg_s"])) * delta
	var cur := atan2(_dir.x, _dir.y)
	var goal := atan2(want.x, want.y)
	var diff := wrapf(goal - cur, -PI, PI)
	cur += clampf(diff, -turn_max, turn_max)
	_dir = Vector2(sin(cur), cos(cur))
	_pos += _dir * _speed * float(spec["ship"]["saved_speed_factor"]) * delta
	_apply_transform()
	if not cleared and _pos.y > float(spec["grounding_rock"]["centre"][1]) + float(spec["grounding_rock"]["clear_past_m"]):
		cleared = true
		cleared_rock.emit()
	if _pos.distance_to(target) < float(spec["safe_lane"]["waypoint_radius_m"]):
		if _wp < _safe.size() - 1:
			_wp += 1
		else:
			mode = Mode.PASSED
			visible = false
			passed.emit()


func _place() -> void:
	var smp: Dictionary = Route.sample(_approach, _s)
	_pos = smp["pos"]
	_dir = smp["dir"]
	_apply_transform()


func _apply_transform() -> void:
	position = Vector3(_pos.x, _keel_y, _pos.y)
	rotation = Vector3(0.0, Route.yaw_for(_dir), 0.0)


## A slow roll and pitch so a 100 m ship rides the swell.
func _sway() -> void:
	if mode == Mode.CRASHED or _hull == null:
		return
	_hull.rotation = Vector3(sin(_t * 0.31) * 0.012, 0.0, sin(_t * 0.23 + 1.0) * 0.02)


func _crash(delta: float) -> void:
	var c: Dictionary = spec["crash"]
	_crash_t += delta
	var bow := minf(_crash_t / 3.0, 1.0)                        # the bow rides up on the rock
	var list := minf(_crash_t / 12.0, 1.0)                      # then she lists
	var sink := clampf((_crash_t - 6.0) / float(c["sink_s"]), 0.0, 1.0)
	_hull.rotation = Vector3(-deg_to_rad(float(c["bow_rise_deg"])) * bow, 0.0, deg_to_rad(float(c["list_deg"])) * list)
	_hull.position = Vector3(0.0, -float(c["sink_m"]) * sink, 0.0)
	var out := 1.0 - clampf((_crash_t - 2.0) / float(c["lights_out_s"]), 0.0, 1.0)
	for m in _light_mats:
		(m as ShaderMaterial).set_shader_parameter("power", out)
	for l in _spill:
		(l as OmniLight3D).light_energy = float(spec["lights"]["spill"]["energy"]) * out


## The spill lights are only live while the camera is close to the ship (the Lighting budget).
func _update_spill() -> void:
	if _spill.is_empty():
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var near := visible and cam != null and cam.global_position.distance_to(global_position) < float(spec["lights"]["spill"]["live_within_m"])
	for l in _spill:
		(l as OmniLight3D).visible = near


func _build_lights(cfg: Dictionary) -> void:
	_build_windows(cfg["windows"])
	for i in cfg["lamps"].size():
		_build_lamp(cfg["lamps"][i], cfg, i)
	var sp: Dictionary = cfg["spill"]
	for at in sp["positions"]:
		var l := OmniLight3D.new()
		l.light_color = Color.html(String(sp["colour"]))
		l.light_energy = float(sp["energy"])
		l.omni_range = float(sp["range_m"])
		l.shadow_enabled = false
		l.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		l.visible = false
		_hull.add_child(l)
		_spill.append(l)


## Lays the lit windows flat on the model: each row is a line of stations along the ship (or across it, for the bow and
## stern ends), and each window sits where a ray from outside meets the hull or superstructure there.
func _build_windows(cfg: Dictionary) -> void:
	if _model == null:
		return
	var rows: Array = cfg["rows"]
	var ylo := INF
	var yhi := -INF
	for r in rows:
		ylo = minf(ylo, float(r["y"]) - 1.0)
		yhi = maxf(yhi, float(r["y"]) + 1.0)
	var bins := _triangle_bins(ylo, yhi)
	var bins_z: Dictionary = bins[0]      # for rays across the beam (side rows)
	var bins_x: Dictionary = bins[1]      # for rays along the ship (bow and stern end rows)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4401
	var colours: Array = cfg["colours"]
	var panes: Array = []      # [Transform3D, Color, custom Color]
	for r in rows:
		var y := float(r["y"])
		var size := Vector2(float(r["size_m"][0]), float(r["size_m"][1]))
		var face := String(r.get("face", "side"))
		var outs: Array = [Vector3(-1, 0, 0), Vector3(1, 0, 0)] if face == "side" else [Vector3(0, 0, -1) if face == "bow" else Vector3(0, 0, 1)]
		var span: Array = r["z"] if face == "side" else r["x"]
		for out in outs:
			var hits: Array = []      # [point, normal] or null, one per station
			var u := float(span[0])
			while u <= float(span[1]) + 0.01:
				var at := Vector3(0.0, y, u) if face == "side" else Vector3(u, y, 0.0)
				hits.append(_hull_hit(bins_z if face == "side" else bins_x, out, at, float(r["min_out_m"])))
				u += float(r["step_m"])
			for k in hits.size():
				if hits[k] == null or not _in_line(hits, k, out, float(cfg["max_jump_m"])):
					continue
				if rng.randf() > float(r["lit_fraction"]):
					continue      # that cabin is dark
				var at: Vector3 = hits[k][0]
				var n: Vector3 = hits[k][1]
				var x := Vector3.UP.cross(n).normalized()
				var xf := Transform3D(Basis(x * size.x, n.cross(x) * size.y, n), at + n * 0.08)
				var custom := Color(rng.randf(), 1.0 if r["round"] else 0.0, rng.randf_range(0.7, 1.1), 1.0 if rng.randf() < float(cfg["flicker_fraction"]) else 0.0)
				panes.append([xf, Color.html(String(colours[rng.randi() % colours.size()])), custom])
	if panes.is_empty():
		push_warning("passenger_ship: no window found on the hull")
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE      # each instance's basis carries the pane's size
	mm.mesh = quad
	mm.instance_count = panes.size()
	for i in panes.size():
		mm.set_instance_transform(i, panes[i][0])
		mm.set_instance_color(i, panes[i][1])
		mm.set_instance_custom_data(i, panes[i][2])
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = WINDOW_SHADER
	mat.set_shader_parameter("brightness", float(cfg["brightness"]))
	mat.set_shader_parameter("grow_per_m", float(cfg["grow_per_m"]))
	mat.set_shader_parameter("grow_max", Vector2(float(cfg["grow_max"][0]), float(cfg["grow_max"][1])))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Windows"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hull.add_child(mmi)
	_light_mats.append(mat)


## The model's triangles that reach into the window band, in hull space, bucketed by whole metres of z and of x:
## [by z, by x].
func _triangle_bins(ylo: float, yhi: float) -> Array:
	var bins := [{}, {}]
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		var xf := Transform3D.IDENTITY      # relative to the hull (the ship is not in the tree yet at setup)
		var nd: Node = mi
		while nd != _hull:
			xf = (nd as Node3D).transform * xf
			nd = nd.get_parent()
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				idx = PackedInt32Array(range(v.size()))
			for t in range(0, idx.size(), 3):
				var a := xf * v[idx[t]]
				var b := xf * v[idx[t + 1]]
				var c := xf * v[idx[t + 2]]
				if maxf(a.y, maxf(b.y, c.y)) < ylo or minf(a.y, minf(b.y, c.y)) > yhi:
					continue
				var tri := [a, b, c]
				for i in 2:
					var axis := 2 if i == 0 else 0
					var by: Dictionary = bins[i]
					for k in range(floori(minf(a[axis], minf(b[axis], c[axis]))), floori(maxf(a[axis], maxf(b[axis], c[axis]))) + 1):
						if not by.has(k):
							by[k] = []
						by[k].append(tri)
	return bins


## Where a ray from outside the ship first meets an upright wall: [point, outward normal], or null when it meets none
## or only one set back past min_out (a gap). Decks and rail tops in the way are looked past. The ray runs in along -out
## (out is +X or -X for a side row, -Z for the bow end, +Z for the stern end); the bins are keyed by whole metres of the
## coordinate along the row (z for a side row, x for an end row).
func _hull_hit(bins: Dictionary, out: Vector3, at: Vector3, min_out: float):
	var from := at + out * 80.0
	var hits: Array = []      # [distance out, point, normal]
	for tri in bins.get(floori(at.z if absf(out.x) > 0.5 else at.x), []):
		var h = Geometry3D.ray_intersects_triangle(from, -out, tri[0], tri[1], tri[2])
		if h != null:
			var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			if n.dot(out) < 0.0:
				n = -n
			hits.append([(h as Vector3).dot(out), h, n])
	hits.sort_custom(func(a, b): return a[0] > b[0])
	for h in hits:
		if h[0] < min_out:
			return null
		var n: Vector3 = h[2]
		if absf(n.y) < 0.5 and n.dot(out) > 0.5:
			return [h[1], Vector3(n.x, 0.0, n.z).normalized()]      # panes stand upright
	return null


## True unless hit k juts out from its neighbours by more than max_jump (a lifeboat or a post on the wall). A recessed bay
## is fine.
func _in_line(hits: Array, k: int, out: Vector3, max_jump: float) -> bool:
	var xs: Array = []
	for j in range(maxi(k - 3, 0), mini(k + 4, hits.size())):
		if j != k and hits[j] != null:
			xs.append((hits[j][0] as Vector3).dot(out))
	if xs.size() < 2:
		return true
	xs.sort()
	return (hits[k][0] as Vector3).dot(out) - float(xs[xs.size() / 2]) <= max_jump


func _build_lamp(l: Dictionary, cfg: Dictionary, idx: int) -> void:
	var sec: Array = SECTORS[String(l["sector"])]
	var col := Color.html(String(l["colour"]))
	var lamp := Node3D.new()
	lamp.name = String(l["id"])
	lamp.position = Vector3(float(l["pos"][0]), float(l["pos"][1]), float(l["pos"][2]))
	_hull.add_child(lamp)
	for halo in [false, true]:
		var mat := ShaderMaterial.new()
		mat.shader = _lamp_shader()
		mat.set_shader_parameter("colour", Vector3(col.r, col.g, col.b))
		mat.set_shader_parameter("brightness", 1.6 if halo else 3.0)
		mat.set_shader_parameter("billboard", halo)
		mat.set_shader_parameter("size_m", float(l["halo_m"]))
		mat.set_shader_parameter("per_m", float(cfg["halo_per_m"]))
		mat.set_shader_parameter("max_m", maxf(float(cfg["halo_max_m"]), float(l["halo_m"])))
		mat.set_shader_parameter("sector_centre", float(sec[0]))
		mat.set_shader_parameter("sector_half", float(sec[1]))
		mat.set_shader_parameter("phase", float(idx) * 1.7)
		var mi := MeshInstance3D.new()
		if halo:
			var q := QuadMesh.new()
			q.size = Vector2.ONE
			mi.mesh = q
			mi.extra_cull_margin = float(cfg["halo_max_m"])      # the shader grows it past the quad's own bounds
		else:
			var sph := SphereMesh.new()
			sph.radius = float(l["core_m"])
			sph.height = sph.radius * 2.0
			sph.radial_segments = 8
			sph.rings = 4
			mi.mesh = sph
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lamp.add_child(mi)
		_light_mats.append(mat)


var _lamp_sh: Shader

## One shader shared by every lamp's core and glow (they differ only in their parameters).
func _lamp_shader() -> Shader:
	if _lamp_sh == null:
		_lamp_sh = Shader.new()
		_lamp_sh.code = LAMP_SHADER
	return _lamp_sh
