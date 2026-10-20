# wave_system.gd - the Wave Creator Agent's runtime: decides how rough the sea is and what it does to the boat.
# Policy lives in data/world/wave_spec.json (decisions D1-D10 of GERFramework/workshops/wave_design_workshop.md):
#   - the target sea state follows the game phase: calm at the island and quay, outbound easing from 1 to 2 as the
#     boat nears the Saltgate, the return building from 3 to 5, the storm easing once the beacon is relit;
#   - the sea pushes the boat only through boat.water_push (a set plus gusts, always smaller than A/D steering);
#   - on the return only, a strong gust can hit the boat broadside: a brief slow-down and some water, never a capsize.
# Sea (sea.gd) smooths the state and draws it; this node never touches the boat's controls or inputs.
# Put one in Level.tscn. It finds the Sea, the boat and GameState by itself.
extends Node

const Sea := preload("res://scripts/world/sea.gd")

@export var spec_path := "res://data/world/wave_spec.json"
## Tests only: hold the sea at this state (0..5) instead of following the game. -1 = follow the game.
var force_state := -1.0
## Tests only: switch wave hits off while measuring drift.
var hits_enabled := true
## Tests only: treat the game as being in this phase name (e.g. "RETURN"). "" = ask GameState.
var force_phase := ""
## Tests only: route progress override 0..1. -1 = measure from the boat.
var force_progress := -1.0

var spec: Dictionary = {}
var _sea: Node = null
var _boat: Node3D = null
var _gs: Node = null
var _lighthouse := Vector2.ZERO
var _port := Vector2.ZERO
var _t := 0.0
var _last_pulse := 0.0
var _cooldown := 0.0
var _return_clock := 0.0     # fallback seconds on the return, only used if GameState has no deadline clock

## Last values, so tools and other agents can read what the sea is doing to the boat.
var last_push := Vector2.ZERO
var last_local_state := 1.0
var last_pulse := 0.0
var hit_count := 0


func _ready() -> void:
	add_to_group("wave_system")
	spec = Sea.load_spec(spec_path)
	_connect.call_deferred()


func _connect() -> void:
	_sea = get_parent().get_node_or_null("Sea")
	_boat = get_tree().get_first_node_in_group("boat")
	_gs = get_node_or_null("/root/GameState")
	var zones: Array = []
	var lh: Array[Vector2] = []
	for z in get_tree().get_nodes_in_group("dock_zone"):
		var p := Vector2(z.global_position.x, z.global_position.z)
		if z.zone_id == "DOCK_LIGHTHOUSE":
			lh.append(p)
		elif z.zone_id == "DOCK_PORT":
			_port = p
		for s in spec.get("shelter", []):
			if s["zone_id"] == z.zone_id:
				zones.append({"x": p.x, "z": p.y, "inner": s["inner_m"], "outer": s["outer_m"], "cap_state": s["cap_state"]})
	if not lh.is_empty():
		for p in lh:
			_lighthouse += p / lh.size()
	Sea.set_shelters(zones)
	Sea.waves_enabled = bool(spec.get("waves_enabled", true))


func _physics_process(delta: float) -> void:
	if _sea == null or spec.is_empty():
		return
	_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	var phase: String = force_phase if force_phase != "" else (String(_gs.phase_name()) if _gs else "ISLAND")
	var progress: float = force_progress if force_progress >= 0.0 else _route_progress()
	if phase == "RETURN":
		_return_clock += delta
	else:
		_return_clock = 0.0
	var target: float = force_state if force_state >= 0.0 else target_state(spec, phase, progress, _deadline_progress())
	Sea.target_state = target
	if force_state >= 0.0:
		Sea.state = force_state    # tests want the state now, not eased in
	_update_boat(delta, phase)


## Settings hooks (WAV-07): waves on/off, and the reduced hazard-intensity preset (multiplies wave height and push by 0.6).
func set_waves_enabled(on: bool) -> void:
	Sea.waves_enabled = on
	if not on and _boat:
		_boat.water_push = Vector2.ZERO


func set_reduced_preset(on: bool) -> void:
	Sea.intensity = float(spec.get("reduced_preset_multiplier", 0.6)) if on else 1.0


## The sea state the game calls for. Pure: no scene access, so tests can sweep it.
## route_progress is 0 at the lighthouse dock and 1 at the quay. deadline_progress is -1 until the clock exists.
static func target_state(sp: Dictionary, phase: String, route_progress: float, deadline_progress: float) -> float:
	var c: Dictionary = sp.get("curve", {})
	match phase:
		"OUTBOUND":
			var o: Dictionary = c["OUTBOUND"]
			var t := clampf((route_progress - float(o["ramp_starts_at"])) / maxf(1.0 - float(o["ramp_starts_at"]), 0.001), 0.0, 1.0)
			return lerpf(float(o["from"]), float(o["to"]), t * t * (3.0 - 2.0 * t))
		"RETURN":
			var r: Dictionary = c["RETURN"]
			var p := deadline_progress if deadline_progress >= 0.0 else clampf(1.0 - route_progress, 0.0, 1.0)
			var t := clampf(p / maxf(float(r["reaches_full_at"]), 0.001), 0.0, 1.0)
			return lerpf(float(r["from"]), float(r["to"]), t * t * (3.0 - 2.0 * t))
		"FINAL_REPAIR":
			return float(c["FINAL_REPAIR"])
		"RESOLUTION":
			return float(c["RESOLUTION"])
		_:   # ARRIVAL_AND_COAL, SHELTER_AND_GATE, BEACON_DIAGNOSIS, BOARDING, SALTGATE
			return float(c.get("ISLAND", 1.0))


## Gust pulse 0..1: irregular, from two slow sines, so gusts arrive unevenly rather than as a metronome.
static func gust_pulse(t: float, period_s: float) -> float:
	if period_s <= 0.0:
		return 0.0
	return maxf(0.0, sin(TAU * t / period_s) * sin(TAU * t / (period_s * 1.7) + 1.3))


## Push on the boat as a fraction of its speed, at a sea state and gust pulse. Includes the reduced-preset multiplier.
static func push_fraction(local_state: float, pulse: float) -> float:
	return (Sea.table("push_fraction", local_state) + Sea.table("gust_fraction", local_state) * pulse) * Sea.intensity


func _route_progress() -> float:
	if _boat == null:
		return 0.0
	var a := _lighthouse
	var b := _port
	var ab := b - a
	if ab.length_squared() < 1.0:
		return 0.0
	var p := Vector2(_boat.global_position.x, _boat.global_position.z)
	return clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)


func _deadline_progress() -> float:
	if _gs and _gs.has_method("deadline_progress"):
		return float(_gs.deadline_progress())
	return -1.0


func _update_boat(_delta: float, phase: String) -> void:
	if _boat == null:
		return
	var pos := _boat.global_position
	last_local_state = Sea.local_state(pos.x, pos.z)
	var period := Sea.table("gust_period_s", last_local_state)
	last_pulse = gust_pulse(_t, period)
	var sailing: bool = _boat.state == 1   # Boat.State.SAILING
	if not Sea.waves_enabled or not sailing:
		_boat.water_push = Vector2.ZERO
		last_push = Vector2.ZERO
		_last_pulse = last_pulse
		return
	var dir_a: Array = spec.get("set_direction_xz", [1.0, 0.0])
	var dir := Vector2(dir_a[0], dir_a[1]).normalized()
	last_push = dir * push_fraction(last_local_state, last_pulse) * _boat.speed
	_boat.water_push = last_push
	# Wave hit: the return only, in heavy water, on a strong gust that has just risen (D3).
	var wh: Dictionary = spec.get("wave_hit", {})
	if hits_enabled and phase == "RETURN" and _cooldown <= 0.0 and last_local_state >= float(wh.get("return_min_state", 4.0)) \
			and last_pulse >= float(wh.get("gust_pulse_threshold", 0.6)) and _last_pulse < float(wh.get("gust_pulse_threshold", 0.6)):
		_cooldown = float(wh.get("cooldown_s", 6.0))
		hit_count += 1
		_boat.apply_wave_hit(float(wh.get("slow_s", 2.0)), float(wh.get("slow_factor", 0.5)), float(wh.get("water_added", 0.15)), float(wh.get("water_drain_per_s", 0.02)))
	_last_pulse = last_pulse
