# passenger_ship.gd - the Lantern Queen, the ship the beacon must save (T31, T07). Spawned at runtime by
# scripts/core/ship_deadline.gd, so Level.tscn does not carry it. It owns the ship's look (the model plus placeholder lit
# windows and navigation lights) and its movement; the deadline clock lives in ship_deadline.gd.
#
# Modes: HIDDEN (before boarding) -> HOLD (lights at the horizon, progress 0) -> APPROACH (the director sets the progress
# 0..1 each frame) -> COMMITTED (the clock ran out: it can no longer turn and runs onto the rock) -> CRASHED, or
# AVOIDING (the beacon is lit: it steers off the approach lane onto the safe lane) -> PASSED (into port, hidden).
# Signals: impact (the bow meets the rock; the audio mixer and the outcome screen time on it), cleared_rock (a saved ship is
# past the rock: the win card waits for it) and passed (into port).
extends Node3D

const Route := preload("res://scripts/world/ship_route.gd")

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
var _s := 0.0                  # distance travelled along the approach lane
var _speed := 0.0              # m/s, set by the director from the deadline length
var _pos := Vector2.ZERO
var _dir := Vector2(0, 1)
var _wp := 0
var _model: Node3D
var _hull: Node3D              # the model and lights, rolled and sunk by the crash
var _lights: Array = []        # [MeshInstance3D, base_energy, phase]
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
		_wp = 0


func is_resolved() -> bool:
	return mode == Mode.CRASHED or mode == Mode.PASSED


func _process(delta: float) -> void:
	_t += delta
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
	for l in _lights:
		var flick := 1.0 if out >= 1.0 else out * (0.6 + 0.4 * sin(_crash_t * 37.0 + float(l[2])))
		l[0].material_override.emission_energy_multiplier = float(l[1]) * maxf(flick, 0.0)


func _build_lights(cfg: Dictionary) -> void:
	var rows: Array = cfg["window_rows_y"]
	var z0 := float(cfg["window_z"][0])
	var z1 := float(cfg["window_z"][1])
	var step := float(cfg["window_step_m"])
	var hb := float(cfg["window_half_beam_m"])
	var warm := _light_material(Color(1.0, 0.72, 0.38), 5.0)
	var idx := 0
	for y in rows:
		var z := z0
		while z <= z1 + 0.01:
			for side in [-1.0, 1.0]:
				_add_light(Vector3(side * hb, float(y), z), float(cfg["window_radius_m"]), warm, 5.0, idx)
				idx += 1
			z += step
	var mh: Array = cfg["masthead"]
	var pr: Array = cfg["port_red"]
	var sg: Array = cfg["starboard_green"]
	_add_light(Vector3(float(mh[0]), float(mh[1]), float(mh[2])), float(cfg["mast_radius_m"]), _light_material(Color(1, 1, 0.95), 8.0), 8.0, idx)
	_add_light(Vector3(float(pr[0]), float(pr[1]), float(pr[2])), float(cfg["nav_radius_m"]), _light_material(Color(1, 0.1, 0.08), 8.0), 8.0, idx + 1)
	_add_light(Vector3(float(sg[0]), float(sg[1]), float(sg[2])), float(cfg["nav_radius_m"]), _light_material(Color(0.1, 1, 0.25), 8.0), 8.0, idx + 2)


func _light_material(col: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.disable_fog = true      # fog would hide a 100 m ship's lights long before they should read at the horizon
	return m


func _add_light(at: Vector3, radius: float, mat: StandardMaterial3D, energy: float, idx: int) -> void:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = 6
	sph.rings = 3
	mi.mesh = sph
	mi.material_override = mat.duplicate()
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hull.add_child(mi)
	_lights.append([mi, energy, float(idx)])
