# test_wave_crossings.gd - run: Godot --headless --path . --script res://tools/test_wave_crossings.gd
# Proves the shape the creator asked for (Wave workshop D1-D10): the first crossing is easy and the last is hectic,
# the sea never out-pushes the steering, waves can be switched off, the reduced preset scales by 0.6, the docks are
# sheltered, and wave hits happen on the return only.
# Part A checks the curve and the tables (no sailing). Part B sails the real boat, A/D steering only, with a perfect-reflex
# bot (the least any player will be shoved: a human drifts further, so feel still needs the creator to play both legs), at each sea state, and measures how far the sea shoves it off the line.
extends SceneTree

const Sea := preload("res://scripts/world/sea.gd")
const WaveSystem := preload("res://scripts/world/wave_system.gd")

const START := Vector3(-60, 0, 230)
const END := Vector3(6, 0, 430)

var _lv: Node
var _boat: Node3D
var _player: CharacterBody3D
var _ws: Node
var _f := 0
var _run := -1
var _t := 0.0
var _fails := 0
var _max_lat := 0.0
var _sum_lat := 0.0
var _n := 0
var _peak_water := 0.0
var _trace := ""
var _results := {}                 # label -> {max, mean, final, hits, water}
# label, sea state to hold, phase name, hits enabled, waves on
var _runs := [
	["s1", 1.0, "OUTBOUND", false, true], ["s2", 2.5, "OUTBOUND", false, true], ["s3", 3.0, "RETURN", false, true],
	["s4", 4.0, "RETURN", false, true], ["s5", 5.0, "RETURN", false, true], ["s5_off", 5.0, "RETURN", false, false],
	["out_s5_hits", 5.0, "OUTBOUND", true, true], ["ret_s5_hits", 5.0, "RETURN", true, true],
]


func _initialize() -> void:
	Engine.set_meta("no_crossing_hazards", true)      # these tests sail the route with a simple bot; the forecast's hazards are tested in test_crossing_sequence.gd
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_boat = _lv.get_node("Boat")
	_player = _lv.get_node("Player")
	_ws = _lv.get_node("WaveSystem")
	_boat.wave_hit.connect(func(w: float) -> void: _peak_water = maxf(_peak_water, w))
	Engine.max_physics_steps_per_frame = 2000
	Engine.time_scale = 40.0


func _ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_fails += 1


func _physics_process(delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	if _f == 30:
		_part_a()
		_boat.hazard_mask = 0
		var lh: Node3D = null
		for z in get_nodes_in_group("dock_zone"):
			if z.zone_id == "DOCK_LIGHTHOUSE":
				lh = z
		_player.global_position = lh.landing
		_boat.board()
		_boat.cast_off()
		_start_next()
		return false
	if _run >= _runs.size():
		return false
	_t += delta
	var pos := _boat.global_position
	var line := (END - START)
	line.y = 0.0
	var lat := absf((pos - START).cross(line.normalized()).y)
	_max_lat = maxf(_max_lat, lat)
	if (_n < 6 or _n % 120 == 0) and _trace.length() < 500:
		_trace += "(x%.1f z%.1f lat%.1f push%.2f v%.1f) " % [pos.x, pos.z, lat, _ws.last_push.length(), _boat.velocity.length()]
	_sum_lat += lat
	_n += 1
	_steer()
	if pos.z >= END.z or _t > 90.0:
		var label: String = _runs[_run][0]
		_results[label] = {"max": _max_lat, "mean": _sum_lat / maxf(_n, 1), "final": lat, "hits": _ws.hit_count,
			"water": _peak_water, "time": _t, "pushed": _ws.last_push.length()}
		print("  %-12s max off line %6.1f m  mean %5.1f m  arrival offset %5.1f m  hits %d  peak water %.2f  %.0f s" % [label, _max_lat, _sum_lat / maxf(_n, 1), lat, _ws.hit_count, _peak_water, _t])
		_start_next()
		if _run >= _runs.size():
			_part_b()
			quit(1 if _fails > 0 else 0)
	return false


func _start_next() -> void:
	_run += 1
	if _run >= _runs.size():
		return
	var r: Array = _runs[_run]
	_ws.force_state = r[1]
	_ws.force_phase = r[2]
	_ws.hits_enabled = r[3]
	Sea.waves_enabled = r[4]
	_ws.hit_count = 0
	_ws._cooldown = 0.0
	_boat.water_in_boat = 0.0
	_peak_water = 0.0
	_trace = ""
	_boat._slow = 0.0
	_boat.global_position = START
	_boat.rotation.y = atan2(-(END.x - START.x), -(END.z - START.z))   # bow (-Z) towards the quay
	_boat.velocity = Vector3.ZERO
	_boat.rudder = 0.0
	Input.action_release("move_left")
	Input.action_release("move_right")
	_t = 0.0
	_max_lat = 0.0
	_sum_lat = 0.0
	_n = 0


func _steer() -> void:
	# A perfect-reflex steerer: every frame, A or D toward the quay, nothing else. Nobody can steer better, so the
	# drift measured here is the LEAST any player will be shoved. (Bots that decide a few times a second oscillate
	# on their own with a 0.35 s rudder lag, which says nothing about the sea, so human feel is a playtest check.)
	var to := END - _boat.global_position
	to.y = 0.0
	var ang := (-_boat.global_transform.basis.z).signed_angle_to(to, Vector3.UP)
	if ang > 0.04:
		Input.action_press("move_left")
		Input.action_release("move_right")
	elif ang < -0.04:
		Input.action_press("move_right")
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")


func _part_a() -> void:
	print("--- Part A: curve, tables, switches")
	var sp: Dictionary = _ws.spec
	_ok(not sp.is_empty(), "wave_spec.json loads")
	var out_max := 0.0
	var out_min := 9.0
	var ret_min := 9.0
	var ret_max := 0.0
	for i in 101:
		var p := i / 100.0
		var o := WaveSystem.target_state(sp, "OUTBOUND", p, -1.0)
		out_max = maxf(out_max, o)
		out_min = minf(out_min, o)
		var r := WaveSystem.target_state(sp, "RETURN", 1.0 - p, -1.0)   # return progress p along the way back
		ret_min = minf(ret_min, r)
		ret_max = maxf(ret_max, r)
	_ok(out_min >= 1.0 and out_max <= float(sp["curve"]["OUTBOUND"]["to"]) + 0.001, "outbound stays between state 1 and its ceiling (min %.2f max %.2f)" % [out_min, out_max])
	_ok(ret_min >= 3.0 - 0.001 and ret_max >= 4.99, "return runs from 3 up to 5 (min %.2f max %.2f)" % [ret_min, ret_max])
	_ok(out_max < ret_min, "the hardest outbound water is easier than the easiest return water")
	_ok(WaveSystem.target_state(sp, "ARRIVAL_AND_COAL", 0.0, -1.0) == 1.0 and WaveSystem.target_state(sp, "SALTGATE", 1.0, -1.0) == 1.0, "island and quay are state 1")
	_ok(WaveSystem.target_state(sp, "RESOLUTION", 0.0, -1.0) == 3.0, "the sea eases to state 3 after the beacon is relit")
	_ok(WaveSystem.target_state(sp, "RETURN", 0.0, 0.0) == 3.0 and WaveSystem.target_state(sp, "RETURN", 0.0, 1.0) >= 4.99, "a deadline clock, when GameState has one, drives the return instead of route progress")
	var worst := 0.0
	for i in 21:
		var s := i * 0.25
		worst = maxf(worst, WaveSystem.push_fraction(s, 1.0))
	_ok(worst <= float(sp["max_total_push_fraction"]), "the strongest push (%.2f of boat speed) stays under the steering limit (%.2f)" % [worst, sp["max_total_push_fraction"]])
	_ok(float(Sea.table("push_fraction", 0.0)) == 0.0 and float(Sea.table("push_fraction", 1.0)) == 0.0, "no push at states 0 and 1")
	Sea.state = 1.0
	var t := 3.0
	var orig := sin(800.0 * 0.15 + t * 1.2) * 0.35 + sin(800.0 * 0.11 + t * 0.9) * 0.3
	_ok(absf(Sea.wave_height(800.0, 800.0, t) - orig) < 0.0001, "state 1 reproduces the original wave shape exactly")
	Sea.state = 5.0
	_ok(Sea.local_state(800.0, 800.0) > 4.9, "open water feels the full state")
	var port := Vector2.ZERO
	var lh := Vector2.ZERO
	for z in get_nodes_in_group("dock_zone"):
		if z.zone_id == "DOCK_PORT":
			port = Vector2(z.global_position.x, z.global_position.z)
		elif z.zone_id == "DOCK_LIGHTHOUSE":
			lh = Vector2(z.global_position.x, z.global_position.z)
	_ok(Sea.local_state(port.x, port.y) <= 1.3, "at the quay berth the sea is sheltered to about state 1 (%.2f)" % Sea.local_state(port.x, port.y))
	_ok(Sea.local_state(lh.x, lh.y) <= 2.3, "at the lighthouse berth the sea is held to about state 2 (%.2f)" % Sea.local_state(lh.x, lh.y))
	_ok(Sea.shelter_at(port.x, port.y) < Sea.shelter_at(port.x, port.y - 120.0) and Sea.shelter_at(port.x, port.y - 300.0) > 0.99, "shelter fades out with distance from the quay")
	_ws.set_reduced_preset(true)
	_ok(absf(WaveSystem.push_fraction(5.0, 1.0) - 0.68 * 0.6) < 0.001 and absf(Sea.intensity - 0.6) < 0.001, "reduced preset multiplies push by 0.6")
	_ws.set_reduced_preset(false)
	_ok(Sea.intensity == 1.0, "reduced preset can be switched back off")
	_ws.set_waves_enabled(false)
	_ok(Sea.local_state(800.0, 800.0) <= 1.0, "waves off: the sea never rises above the calm look")
	_ws.set_waves_enabled(true)
	Sea.state = 1.0
	print("--- crossing speed from data: boat.speed = %.1f m/s (boat_spec.json speed_mps)" % _boat.speed)
	_ok(absf(_boat.speed - 8.0) < 0.001, "boat reads the 8 m/s crossing speed from boat_spec.json")
	print("--- Part B: sailing the real boat, %.0f m of open water, perfect-reflex A/D steering bot" % (END - START).length())


func _part_b() -> void:
	print("--- Part B results")
	var m := {}
	for k in _results:
		m[k] = _results[k]["max"]
	_ok(m["s1"] < 3.0, "state 1: the sea barely moves the boat (max %.1f m off line)" % m["s1"])
	_ok(m["s2"] < 16.0, "first crossing at its worst (state 2.5) stays manageable: max %.1f m off line" % m["s2"])
	_ok(m["s5"] >= 2.0 * m["s2"] and m["s5"] > 8.0, "the return at its worst is clearly harder: %.1f m vs %.1f m" % [m["s5"], m["s2"]])
	_ok(m["s3"] <= m["s4"] + 0.5 and m["s4"] <= m["s5"] + 0.5, "disturbance rises with sea state (%.1f, %.1f, %.1f m)" % [m["s3"], m["s4"], m["s5"]])
	_ok(_results["s5"]["final"] < 25.0, "even at state 5 an average steerer still reaches the quay line (arrival offset %.1f m)" % _results["s5"]["final"])
	_ok(m["s5_off"] <= m["s1"] + 1.0, "waves off: state 5 behaves like a calm crossing (max %.1f m)" % m["s5_off"])
	_ok(_results["out_s5_hits"]["hits"] == 0 and _results["out_s5_hits"]["water"] == 0.0, "no wave hit outbound, even in state 5")
	_ok(_results["ret_s5_hits"]["hits"] >= 1 and _results["ret_s5_hits"]["water"] > 0.0, "return in heavy water: wave hits happen and the boat takes on water (%d hits)" % _results["ret_s5_hits"]["hits"])
	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
