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

	# the music (creator, 3 Nov 2026): Landed at Bracken Isle -> (Ted's briefing done) Get to Saltgate -> (burner) Get to Bracken Isle
	var dlg := root.get_node("Dialogue")
	_check(mx.music_track == "landed" and mx._music[mx._music_cur].stream != null and (mx._music[mx._music_cur].stream as AudioStreamOggVorbis).loop, "the music starts on 'Landed at Bracken Isle', looping")
	dlg.line_finished.emit("TED_S3_01")
	_check(mx.music_track == "landed", "another line ending does not move the music on")
	dlg.line_finished.emit("TED_S3_02")
	_check(mx.music_track == "saltgate", "once Ted's briefing line has ended it is 'Get to Saltgate'")
	mx.advance(1.0)
	_check(mx._music[1 - mx._music_cur].playing and mx._music[mx._music_cur].volume_db < float(mx.spec["music"]["volume_db"]), "the switch crossfades: both tracks sound partway through")
	mx.advance(5.0)
	_check(not mx._music[1 - mx._music_cur].playing and absf(mx._music[mx._music_cur].volume_db - float(mx.spec["music"]["volume_db"])) < 0.1, "after the crossfade only the new track plays, at the set level")

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
	_check(mx.music_track == "saltgate", "casting off (the fallback cue) leaves 'Get to Saltgate' playing")
	gs.emit_event("BURNER_PICKED_UP")
	_check(mx.music_track == "bracken", "picking up the burner moves it to 'Get to Bracken Isle'")
	dlg.line_finished.emit("TED_S3_02")
	_check(mx.music_track == "bracken", "a late cue never takes the music back")
	gs.emit_event("RETURN_DEPARTED")
	mx.advance(10.0, true)
	var wind_start: float = mx.levels["wind"]
	_check(wind_start > wind_island, "the return is windier than the island (%.1f vs %.1f dB)" % [wind_start, wind_island])
	var dl: Node = gs.deadline()
	dl._process(90.0)
	mx.advance(10.0, true)
	var wind_mid: float = mx.levels["wind"]
	dl._process(85.0)       # 175 of 180 s: just short of the deadline
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
	var rain_before: float = mx.targets["rain"]
	var mach_before: float = mx.targets["machinery"]
	var music_before: float = mx._music[mx._music_cur].volume_db
	dlg.line_started.emit("TEST", "ARTHUR", "ARTHUR: test", "")
	mx.advance(1.0)
	_check(absf(mx.targets["wind"] - before_duck) < 0.1 and absf(mx.targets["rain"] - rain_before) < 0.1, "speech does not cut through the wind and rain (creator, 3 Nov 2026)")
	_check(absf(mx._music[mx._music_cur].volume_db - music_before) < 0.1, "nor through the music")
	_check(mx.targets["machinery"] < mach_before - 3.0, "the boiler dips under speech (%.1f to %.1f dB)" % [mach_before, mx.targets["machinery"]])
	dlg.line_finished.emit("TEST")
	mx.advance(2.0)
	_check(absf(mx.targets["machinery"] - mach_before) < 0.1, "and comes back when the line ends")

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
	_check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) <= -79.0, "the music has faded out for the Failed screen")
	_check(mx.win_horns == 0, "a failed ship sounds no win horn")
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
	var mx_r: Node = gs.audio()
	_check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) > -1.0 and mx_r != null and mx_r.music_track == "landed", "and the music starts again from 'Landed at Bracken Isle'")
	# the win path: the saved ship's horn sounds once as it clears the rock
	var mx2: Node = gs.audio()
	var dl2: Node = gs.deadline()
	gs.emit_event("BOAT_CAST_OFF")
	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	dl2._process(100.0)
	gs.emit_event("BURNER_FITTED")
	gs.emit_event("SHIP_WIN")
	var guard := 0
	while not dl2.ship.cleared and guard < 3000:
		dl2.ship._process(0.1)
		guard += 1
	_check(dl2.ship.cleared and mx2.win_horns == 1, "a saved ship sounds its horn once as it clears the rock (%d blast)" % mx2.win_horns)
	for i in 600:
		dl2.ship._process(0.1)
	_check(mx2.win_horns == 1, "and only once as it carries on to port")
	mx2.advance(30.0)
	_check(mx2.music_track == "bracken" and mx2._music[mx2._music_cur].playing and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) > -1.0, "on a win the music keeps playing")
	lv2.queue_free()
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
