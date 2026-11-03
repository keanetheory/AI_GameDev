# probe_dock_hitch.gd - QA-03 follow-up (Playtest QA), observe only: where does the frame-time spike at the lighthouse dock come from?
#   Godot --headless --path . --script res://tools/probe_dock_hitch.gd
# Puts the player at a few spots round the lighthouse berth (in the moored launch, on the jetty at the landing, in the water
# beside it, and a control spot in the hall) and records, for 6 s at each, the worst physics and process times per frame
# (Performance TIME_PHYSICS_PROCESS / TIME_PROCESS) and whether the player is on the floor.
extends SceneTree

var _lv: Node
var _t := 0.0
var _started := false


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(delta: float) -> bool:
	_t += delta
	if not _started and _t > 3.0:
		_started = true
		_run()
	return false


func _run() -> void:
	var player: CharacterBody3D = _lv.get_node("Player")
	var z: Node3D = null
	for d in get_nodes_in_group("dock_zone"):
		if d.zone_id == "DOCK_LIGHTHOUSE":
			z = d
	var boat: Node3D = _lv.get_node("Boat")
	var spots := [
		["hall (control)", Vector3(0.4, 10.6, -1.9)],
		["in the moored launch (zone + 1.5 m, the perf spot)", z.global_position + Vector3(0, 1.5, 0)],
		["on the launch deck", boat.global_position + Vector3(0, 1.8, 0)],
		["on the jetty at the landing", z.landing + Vector3(0, 0.3, 0)],
		["in the water beside the berth", z.global_position + (z.global_position - z.landing).normalized() * 5.0 + Vector3(0, 0.5, 0)],
	]
	for s in spots:
		player.global_position = s[1]
		player.velocity = Vector3.ZERO
		var t0 := _t
		while _t - t0 < 1.0:
			await process_frame
		var worst_phys := 0.0
		var worst_proc := 0.0
		var n := 0
		var slow := 0
		t0 = _t
		while _t - t0 < 6.0:
			await process_frame
			var ph := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			var pr := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			worst_phys = maxf(worst_phys, ph)
			worst_proc = maxf(worst_proc, pr)
			slow += int(ph > 20.0)
			n += 1
		print("DOCK,%s,frames=%d,worst_physics_ms=%.1f,worst_process_ms=%.1f,physics_frames_over_20ms=%d,player=%s,on_floor=%s" % [
			s[0], n, worst_phys, worst_proc, slow, player.global_position, player.is_on_floor()])
	quit(0)
