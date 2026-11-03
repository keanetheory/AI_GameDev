# perf_route.gd - QA-03 (Playtest QA), observe only: frame rate and video memory along the Gate 1 route.
# Meant for the exported release build (tools/ is not in the .pck, so pass this file by its path on disk):
#   LightingTheStorm.exe --resolution 1600x900 [--gpu-index 1] --script C:/GameDev/AI_GameDev/LightingTheStorm/tools/perf_route.gd -- static
#   ... -- static twice  goes round the fixed points twice (the second lap has no first-sight shader compiles)
#   LightingTheStorm.exe ... --script .../perf_route.gd               (the win playthrough at 1x, segmented by story event)
#   LightingTheStorm.exe ... --script .../perf_route.gd -- fail       (the fail playthrough at 1x: the storm late in the deadline)
# It also runs in the editor build (Godot --path . --script res://tools/perf_route.gd -- static).
# static: the player is put at fixed points (front door, hall, basement, tower stairs, lamp room, dock, gate, Saltgate quay) and
#   turns a full circle over HOLD_S seconds at each; nothing in the story is triggered on purpose.
# route: test_slice_playthrough.gd unchanged, but at 1x game speed, so the frames are a player's frames; a segment runs from one
#   story event to the next.
# Each segment prints: PERF,<segment>,<frames>,<median fps>,<worst 1 s fps>,<1% low fps>,<spikes over 50 ms>,<worst frame ms>,
# <video MB max>. Peak system memory is read from outside (PowerShell PeakWorkingSet64).
extends "test_slice_playthrough.gd"

const HOLD_S := 8.0
const SETTLE_S := 1.0          # frames in the first second after a teleport are reported apart (a player never teleports)
const SPIKE_MS := 50.0

var _static := false
var _seg := "load"
var _seg_t0 := 0
var _ft: Array = []            # this segment's frame times, ms
var _ft_settle: Array = []
var _vmax := 0.0
var _last_us := 0
var _results: Array = []
var _sw := false
var _real_t := 0.0


func _initialize() -> void:
	_static = OS.get_cmdline_user_args().has("static")
	super._initialize()
	Engine.time_scale = 1.0
	Engine.max_physics_steps_per_frame = 8


func _mark(name: String) -> void:
	_flush()
	_seg = name
	_seg_t0 = Time.get_ticks_usec()


func _flush() -> void:
	if _ft.size() < 10:
		_ft.clear()
		_ft_settle.clear()
		return
	var s := _ft.duplicate()
	s.sort()
	var med: float = s[s.size() / 2]
	var p99: float = s[mini(s.size() - 1, int(s.size() * 0.99))]
	var spikes := 0
	for f in _ft:
		if f > SPIKE_MS:
			spikes += 1
	var settle_spikes := 0
	for f in _ft_settle:
		if f > SPIKE_MS:
			settle_spikes += 1
	# worst 1 s window: frames counted per whole second of real time
	var worst := 1.0e9
	var acc := 0.0
	var n := 0
	for f in _ft:
		acc += f
		n += 1
		if acc >= 1000.0:
			worst = minf(worst, n * 1000.0 / acc)
			acc = 0.0
			n = 0
	if worst > 1.0e8:
		worst = 1000.0 / med
	var line := "PERF,%s,%d,%.0f,%.0f,%.0f,%d,%.0f,%.0f,settle_spikes=%d,settle_worst_ms=%.0f" % [_seg, _ft.size(), 1000.0 / med, worst,
		1000.0 / p99, spikes, s[s.size() - 1], _vmax, settle_spikes, (_ft_settle.max() if not _ft_settle.is_empty() else 0.0)]
	print(line)
	_results.append(line)
	_ft.clear()
	_ft_settle.clear()
	_vmax = 0.0


func _sample() -> void:
	var now := Time.get_ticks_usec()
	if _last_us != 0:
		var ms := (now - _last_us) / 1000.0
		if now - _seg_t0 < int(SETTLE_S * 1.0e6):
			_ft_settle.append(ms)
		else:
			_ft.append(ms)
	_last_us = now
	_vmax = maxf(_vmax, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)


func _process(delta: float) -> bool:
	_sample()
	if not _sw and root.has_node("GameState"):
		_sw = true
		root.get_node("GameState").event_emitted.connect(func(id: String, _p: int) -> void: _mark("after " + id))
		_mark("load")
	if _static:
		if not _started:
			_started = true
			_tour()
		return false
	return super._process(delta)


func _wait_real(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await process_frame


func _turn_hold(player: Node3D) -> void:
	var t0 := Time.get_ticks_msec()
	var yaw0 := player.rotation.y
	while Time.get_ticks_msec() - t0 < (HOLD_S + SETTLE_S) * 1000.0:
		player.rotation.y = yaw0 + TAU * (Time.get_ticks_msec() - t0) / ((HOLD_S + SETTLE_S) * 1000.0)
		player.velocity = Vector3.ZERO
		await process_frame


func _tour() -> void:
	await _wait_real(6.0)          # the level finishes building
	var player: CharacterBody3D = _lv.get_node("Player")
	var rooms: Node = _lv.get_node("InteriorRooms")
	var door: Node3D = _lv.get_node("LighthouseDoor")
	var z_in: Node3D = _zone("LIGHTHOUSE_ENTERED")
	var out_dir := Vector3(door.global_position.x - z_in.global_position.x, 0, door.global_position.z - z_in.global_position.z).normalized()
	var stand_a: Variant = rooms.anchors["lamp_stand"]
	var stand: Vector3 = stand_a if stand_a is Vector3 else (stand_a as Node3D).global_position
	var gate: Node = get_first_node_in_group("gate")
	var port := _dock("DOCK_PORT")
	var home := _dock("DOCK_LIGHTHOUSE")
	var pts := [
		["front door", door.global_position + out_dir * 2.5 + Vector3(0, 0.2, 0)],
		["hall", Vector3(0.4, 10.6, -1.9)],
		["basement", Vector3(3.6, 7.9, -4.4)],
		["tower stairs", Vector3(8.5 + 2.0, lerpf(10.6, stand.y, 0.5) + 0.6, -4.9)],
		["lamp room", stand + Vector3(0, 0.1, 0)],
		["lighthouse dock", (home.global_position if home else Vector3.ZERO) + Vector3(0, 1.5, 0)],
		["island gate", gate.middle() + Vector3(0, 0.1, 3.0)],
		["Saltgate quay", (port.global_position if port else Vector3.ZERO) + Vector3(0, 1.5, 0)],
	]
	var rounds := 2 if OS.get_cmdline_user_args().has("twice") else 1     # twice: a second lap shows which spikes were first-sight shader compiles
	for lap in rounds:
		for p in pts:
			player.global_position = p[1]
			player.velocity = Vector3.ZERO
			_mark("static%s: %s" % [" lap 2" if lap == 1 else "", String(p[0])])
			await _turn_hold(player)
			print("     at %s: player %s on_floor=%s" % [p[0], player.global_position, player.is_on_floor()])
	_flush()
	print("RESULT: OK (0 failed)")
	quit(0)


func _finalize() -> void:
	_flush()
	print("=== PERF SUMMARY ===")
	for l in _results:
		print(l)
