# test_audio_mixer.gd - run: Godot --headless --path . --script res://tools/test_audio_mixer.gd
# T14: the placeholder audio (scripts/core/audio_mixer.gd, data/world/audio_spec.json) through the real GameState autoload with a
# stand-in level. Checks the sounds load and loop, the mix follows the phase and (on the return) the deadline clock, the
# indoor muffle, ducking under speech, the engine only under way, and the fail sequence: foghorn, crash, silence, then
# fail_audio_finished. The mixer is stepped by hand, so the headless audio driver does not matter.
extends SceneTree

const BoatStandIn := """extends Node3D
var velocity := Vector3.ZERO
var driving := false
signal docked(zone_id)
signal departed(zone_id)
signal hazard_hit
"""

var _fails := 0
var _started := false


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _process(_d: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var lv := Node3D.new()
	lv.name = "StandInLevel"
	var boat := Node3D.new()
	var sc := GDScript.new()
	sc.source_code = BoatStandIn
	sc.reload()
	boat.set_script(sc)
	boat.name = "Boat"
	boat.add_to_group("boat")
	lv.add_child(boat)
	var culling := Node.new()
	culling.name = "InteriorCulling"
	var cs := GDScript.new()
	cs.source_code = "extends Node\nvar inside := false\n"
	cs.reload()
	culling.set_script(cs)
	lv.add_child(culling)
	root.add_child(lv)
	await process_frame
	await process_frame
	var mx: Node = gs.audio()
	_check(mx != null and not mx.spec.is_empty(), "GameState creates the audio mixer when the level is ready")
	if mx == null:
		quit(1)
		return
	for nm in ["wind", "rain", "machinery", "engine"]:
		var p: Node = mx.players[nm]
		_check(p.stream != null and (p.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s loads and loops" % nm)
	for nm in ["foghorn", "impact"]:
		_check(mx.players[nm].stream != null, "%s loads (spawned on the ship)" % nm)
	_check(AudioServer.get_bus_index("Ambience") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "the Ambience and SFX buses exist")

	# phase mix
	mx.advance(10.0, true)
	var wind_island: float = mx.levels["wind"]
	_check(mx.levels["machinery"] <= -79.0 and mx.levels["engine"] <= -79.0, "arrival: the boiler is cold and the engine silent")
	gs.emit_event("BOILER_FED")
	mx.advance(10.0, true)
	_check(mx.levels["machinery"] > -20.0, "once the boiler is fed the machinery comes up (%.1f dB)" % mx.levels["machinery"])
	gs.emit_event("BOAT_CAST_OFF")
	mx.advance(10.0, true)
	_check(mx.levels["engine"] <= -79.0, "outbound but not moving: no engine")
	boat.velocity = Vector3(0, 0, 8)
	mx.advance(10.0, true)
	_check(mx.levels["engine"] > -30.0, "outbound under way: the engine chugs (%.1f dB)" % mx.levels["engine"])
	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	mx.advance(10.0, true)
	var wind_start: float = mx.levels["wind"]
	_check(wind_start > wind_island, "the return is windier than the island (%.1f vs %.1f dB)" % [wind_start, wind_island])
	var dl: Node = gs.deadline()
	dl._process(105.0)
	mx.advance(10.0, true)
	var wind_mid: float = mx.levels["wind"]
	dl._process(100.0)      # 205 of 210 s: just short of the deadline
	mx.advance(10.0, true)
	var wind_end: float = mx.levels["wind"]
	_check(wind_start < wind_mid and wind_mid < wind_end, "on the return the storm follows the deadline clock (%.1f, %.1f, %.1f dB)" % [wind_start, wind_mid, wind_end])

	# indoor muffle and ducking
	var cutoff_out: float = mx._lowpass.cutoff_hz
	culling.inside = true
	mx.advance(2.0)
	_check(mx._lowpass.cutoff_hz < cutoff_out and mx.targets["wind"] < wind_end, "inside the house the ambience is muffled and quieter")
	culling.inside = false
	mx.advance(2.0)
	var before_duck: float = mx.targets["wind"]
	var dlg := root.get_node("Dialogue")
	dlg.line_started.emit("TEST", "ARTHUR", "ARTHUR: test", "")
	mx.advance(1.0)
	_check(mx.targets["wind"] < before_duck - 3.0, "while someone speaks the ambience ducks (%.1f to %.1f dB)" % [before_duck, mx.targets["wind"]])
	dlg.line_finished.emit("TEST")
	mx.advance(2.0)
	_check(absf(mx.targets["wind"] - before_duck) < 0.1, "and comes back when the line ends")

	# the fail sequence: foghorn at SHIP_FAIL, crash, silence, then the signal
	var finished := [0]
	mx.fail_audio_finished.connect(func() -> void: finished[0] += 1)
	var horn_times: Array = []
	var left_before := int(mx.spec["fail"]["horn_blasts"])
	dl._process(500.0)      # the deadline runs out: SHIP_FAIL fires, the ship is committed
	_check(mx.fail_active, "SHIP_FAIL starts the fail sequence")
	var t := 0.0
	var impact_seen := false
	var impact_at := -1.0
	while t < 60.0 and finished[0] == 0:
		dl.ship._process(0.1)
		mx.advance(0.1)
		t += 0.1
		if mx._horn_left < left_before:
			horn_times.append(t)
			left_before = mx._horn_left
		if mx._impact_t >= 0.0 and not impact_seen:
			impact_seen = true
			impact_at = t
	var blasts := int(mx.spec["fail"]["horn_blasts"])
	var before_crash := 0
	for h in horn_times:
		if h < impact_at:
			before_crash += 1
	_check(horn_times.size() == blasts and before_crash == blasts, "the foghorn blasts %d times, all before the crash at %.1f s (at %s s)" % [blasts, impact_at, horn_times])
	_check(impact_seen, "the ship's impact sound is triggered when it strikes the rock")
	_check(finished[0] == 1, "silence ends the sequence: fail_audio_finished fired once, %.1f s after the deadline" % t)
	_check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")) <= -79.0, "the buses are silent when the Failed screen is due")
	# a restart brings the sound back
	gs.restart()
	lv.queue_free()
	await process_frame
	var lv2 := Node3D.new()
	lv2.name = "StandInLevel2"
	var boat2 := Node3D.new()
	boat2.add_to_group("boat")
	lv2.add_child(boat2)
	root.add_child(lv2)
	await process_frame
	await process_frame
	_check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")) > -1.0, "after a restart the buses are back at full level")
	lv2.queue_free()
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
