# audio_mixer.gd - the Gate 1 placeholder audio (backlog T14): layered wind and rain, the boiler and dynamo, the launch's engine,
# buoy bells, the ship's foghorn and impact, mixed by game phase. GameState creates one inside the level once it is ready (like the
# ship deadline), so Level.tscn carries no audio nodes. All levels live in data/world/audio_spec.json.
#
# Mixing rules:
#   - the phase picks each layer's level; on the return the storm layers follow elapsed deadline time (Decisions A2), and a
#     frozen clock (burner fitted) keeps them where they were;
#   - indoors (the house footprint) the wind and rain are muffled by a low-pass on the Ambience bus;
#   - while anyone speaks the boiler and the engine duck (duck.layers), so Arthur's calls stay audible; speech does not cut
#     through the wind, the rain or the music (creator, 3 November 2026);
#   - the music (the creator's own, looping) moves forward through its tracks on story cues, crossfading on the Music bus;
#   - a voice line is placed by where its speaker is: quieter with distance, and muffled and echoing through a floor or an
#     outside wall (Ted calling from the lamp room to the basement), on the Voice bus the dialogue loader plays on;
#   - the engine only sounds while the boat is under way;
#   - a saved ship sounds its horn once as it clears the rock;
#   - at SHIP_FAIL: the ship's foghorn sounds (3D, from the ship), then the crash when the ship strikes, then silence, then
#     fail_audio_finished is emitted for the Failed screen (T08). The sequence is timed on game time, so pause freezes it.
# The sound effects are still synthesised placeholders (Assets/Audio/placeholder/SOURCES.md); the music is real
# (Assets/Audio/music/SOURCES.md).
extends Node

const SPEC_PATH := "res://data/world/audio_spec.json"
const SILENT_DB := -80.0

signal fail_audio_finished

var spec: Dictionary = {}
var players: Dictionary = {}          # name -> AudioStreamPlayer / AudioStreamPlayer3D
var levels: Dictionary = {}           # name -> current dB (smoothed)
var targets: Dictionary = {}          # name -> target dB, as of the last advance()
var indoor_t := 0.0                   # 0 outside .. 1 inside
var duck_t := 0.0
var speaking := 0
var fail_active := false
var silence_done := false
var win_horns := 0                    # blasts sounded by a saved ship (one per attempt)

var _gs: Node
var _boat: Node
var _culling: Node
var _ship: Node3D
var _lowpass: AudioEffectLowPassFilter
var _bells: Array = []
var _bell_timers: Array = []
var _rng := RandomNumberGenerator.new()
var _fail_t := 0.0
var _horn_left := 0
var _horn_next := 0.0
var _impact_t := -1.0
var _silence_t := -1.0
var _bus_amb := -1
var _bus_sfx := -1
var _bus_voice := -1
var _voice_lowpass: AudioEffectLowPassFilter
var _voice_reverb: AudioEffectReverb
var voice_speaker := ""               # who is speaking now ("" between lines)
var voice_db := 0.0                   # the Voice bus level, as of the last advance()
var voice_walled := 0.0               # 0 same space .. 1 a floor or an outside wall between speaker and player
var _voice_snap := false              # a new line jumps straight to its placement instead of gliding from the last one
var _bus_music := -1
var music_track := ""                 # the track now playing (spec music.order), "" before the first
var _music: Array = []                # two AudioStreamPlayers: the one fading in, the one fading out
var _music_cur := 0                   # index in _music of the player now fading in
var _music_mix := 1.0                 # 0..1 through the crossfade


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("audio_mixer: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	_rng.randomize()
	_boat = get_tree().get_first_node_in_group("boat")
	_culling = level.get_node_or_null("InteriorCulling")
	_make_buses()
	_make_players(level)
	gs.event_emitted.connect(_on_event)
	var dlg := get_node_or_null("/root/Dialogue")
	if dlg:
		dlg.line_started.connect(func(_a, who, _c, _d2) -> void:
			speaking += 1
			voice_speaker = String(who)
			_voice_snap = true)
		dlg.line_finished.connect(func(line_id) -> void:
			speaking = maxi(speaking - 1, 0)
			voice_speaker = ""
			_music_cue("after_line", String(line_id)))
	var dl: Node = gs.deadline()
	if dl and dl.ship:
		_attach_ship(dl.ship)
	advance(0.0, true)


func _make_buses() -> void:
	for nm in spec["buses"]:
		if AudioServer.get_bus_index(nm) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nm)
			AudioServer.set_bus_send(i, "Master")
	_bus_amb = AudioServer.get_bus_index("Ambience")
	_bus_sfx = AudioServer.get_bus_index("SFX")
	_bus_music = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(_bus_amb, 0.0)    # a restart after a fail comes back from silence
	AudioServer.set_bus_volume_db(_bus_sfx, 0.0)
	if _bus_music >= 0:
		AudioServer.set_bus_volume_db(_bus_music, 0.0)
	_lowpass = null
	for i in AudioServer.get_bus_effect_count(_bus_amb):
		if AudioServer.get_bus_effect(_bus_amb, i) is AudioEffectLowPassFilter:
			_lowpass = AudioServer.get_bus_effect(_bus_amb, i)
	if _lowpass == null:
		_lowpass = AudioEffectLowPassFilter.new()
		_lowpass.cutoff_hz = 20500.0
		AudioServer.add_bus_effect(_bus_amb, _lowpass)
	_make_voice_bus()


## The Voice bus (made by the dialogue loader, or here if this runs first): the jaw's spectrum analyser first, so it hears the
## dry voice, then the distance low-pass and the stairwell echo. A restart finds them already there and reuses them.
func _make_voice_bus() -> void:
	var nm := "Voice"
	_bus_voice = AudioServer.get_bus_index(nm)
	if _bus_voice < 0:
		AudioServer.add_bus()
		_bus_voice = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_voice, nm)
		AudioServer.set_bus_send(_bus_voice, "Master")
	_voice_lowpass = null
	_voice_reverb = null
	var has_analyser := false
	for i in AudioServer.get_bus_effect_count(_bus_voice):
		var fx := AudioServer.get_bus_effect(_bus_voice, i)
		if fx is AudioEffectSpectrumAnalyzer:
			has_analyser = true
		elif fx is AudioEffectLowPassFilter:
			_voice_lowpass = fx
		elif fx is AudioEffectReverb:
			_voice_reverb = fx
	if not has_analyser:
		AudioServer.add_bus_effect(_bus_voice, AudioEffectSpectrumAnalyzer.new(), 0)
	if _voice_lowpass == null:
		_voice_lowpass = AudioEffectLowPassFilter.new()
		AudioServer.add_bus_effect(_bus_voice, _voice_lowpass)
	if _voice_reverb == null:
		_voice_reverb = AudioEffectReverb.new()
		_voice_reverb.room_size = 0.7     # a stone stairwell
		_voice_reverb.damping = 0.4
		_voice_reverb.predelay_msec = 60.0
		_voice_reverb.spread = 0.6
		_voice_reverb.dry = 1.0
		AudioServer.add_bus_effect(_bus_voice, _voice_reverb)
	_voice_lowpass.cutoff_hz = 20500.0
	_voice_reverb.wet = 0.0
	voice_db = float(spec.get("voice", {}).get("base_db", 0.0))
	AudioServer.set_bus_volume_db(_bus_voice, voice_db)


func _stream(nm: String) -> AudioStream:
	var s: Dictionary = spec["streams"][nm]
	var res := load(String(s["path"])) as AudioStreamWAV
	if res == null:
		push_warning("audio_mixer: %s did not load (run  godot --headless --import  after adding sounds)" % s["path"])
		return null
	var st := res.duplicate() as AudioStreamWAV
	if bool(s["loop"]):
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
	return st


func _make_players(level: Node) -> void:
	for nm in ["wind", "rain", "engine"]:
		var p := AudioStreamPlayer.new()
		p.name = nm.capitalize()
		p.bus = "Ambience"
		p.stream = _stream(nm)
		p.volume_db = SILENT_DB
		add_child(p)
		players[nm] = p
		levels[nm] = SILENT_DB
		if p.stream:
			p.play()
	# the boiler and dynamo: a 3D source in the basement, heard through the walls by distance
	var m := AudioStreamPlayer3D.new()
	m.name = "Machinery"
	m.bus = "Ambience"
	m.stream = _stream("machinery")
	m.volume_db = SILENT_DB
	m.unit_size = 6.0
	m.max_distance = 70.0
	m.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	var lh := level.get_node_or_null("Lighthouse") as Node3D
	m.position = (lh.global_position if lh else Vector3(5, 9.6, -8.5)) + Vector3(-1.0, -9.0, 2.0)
	add_child(m)
	players["machinery"] = m
	levels["machinery"] = SILENT_DB
	if m.stream:
		m.play()
	var b: Dictionary = spec["bells"]
	for pos in b["positions"]:
		var bp := AudioStreamPlayer3D.new()
		bp.name = "Bell%d" % _bells.size()
		bp.bus = "SFX"
		bp.stream = _stream("bell")
		bp.volume_db = float(b["volume_db"])
		bp.unit_size = float(b["unit_size"])
		bp.max_distance = float(b["max_distance"])
		bp.position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
		add_child(bp)
		_bells.append(bp)
		_bell_timers.append(_rng.randf_range(0.5, float(b["interval_s"][1])))
	if spec.has("music"):
		for i in 2:
			var mp := AudioStreamPlayer.new()
			mp.name = "Music%d" % i
			mp.bus = "Music"
			mp.volume_db = SILENT_DB
			add_child(mp)
			_music.append(mp)
		_play_music(String(spec["music"]["start"]), true)


## The music track as a looping stream (each player gets its own copy, so the loop flag never leaks between them).
func _music_stream(track: String) -> AudioStream:
	var path := String(spec["music"]["tracks"][track]["path"])
	var res := load(path) as AudioStreamOggVorbis
	if res == null:
		push_warning("audio_mixer: %s did not load (run  godot --headless --import  after adding music)" % path)
		return null
	var st := res.duplicate() as AudioStreamOggVorbis
	st.loop = true
	return st


## Crossfades to a track. Cues only move forward through music.order, so a late fallback never takes the music back.
func _play_music(track: String, snap := false) -> void:
	var order: Array = spec["music"]["order"]
	if track == music_track or order.find(track) < order.find(music_track):
		return
	var st := _music_stream(track)
	if st == null:
		return
	if music_track != "":
		_music_cur = 1 - _music_cur     # the old track keeps the other player and fades out on it
	music_track = track
	var p: AudioStreamPlayer = _music[_music_cur]
	p.stream = st
	p.volume_db = SILENT_DB
	p.play()
	_music_mix = 1.0 if snap else 0.0


func _music_cue(kind: String, id: String) -> void:
	if not spec.has("music"):
		return
	for c in spec["music"]["cues"]:
		if String(c.get(kind, "")) == id:
			_play_music(String(c["play"]))


## The bells ring from the real buoys (crossing_sequence.gd) once they are placed; extra bells keep their placeholder spots.
func place_bells(positions: Array) -> void:
	for i in mini(positions.size(), _bells.size()):
		(_bells[i] as AudioStreamPlayer3D).global_position = positions[i]


func _attach_ship(ship: Node3D) -> void:
	_ship = ship
	for nm in ["foghorn", "impact"]:
		var p := AudioStreamPlayer3D.new()
		p.name = nm.capitalize()
		p.bus = "SFX"
		p.stream = _stream(nm)
		p.unit_size = 120.0
		p.max_distance = 2500.0
		p.position = Vector3(0.0, 14.0, -42.0)     # up on the bow's bridge deck (the ship's own frame; bow is -Z)
		ship.add_child(p)
		players[nm] = p
	ship.impact.connect(_on_impact)
	ship.cleared_rock.connect(_on_cleared_rock)


func _process(delta: float) -> void:
	advance(delta)


## One mixing step (the test calls this directly with a chosen dt; snap=true jumps to the targets).
func advance(delta: float, snap := false) -> void:
	if spec.is_empty() or _gs == null:
		return
	var phase := String(_gs.phase_name())
	var row: Dictionary = spec["phases"].get(phase, {})
	var prog: float = _gs.deadline_progress()
	indoor_t = move_toward(indoor_t, 1.0 if (_culling != null and bool(_culling.get("inside"))) else 0.0, float(spec["indoor"]["rate_per_s"]) * delta)
	var duck_goal := 1.0 if speaking > 0 else 0.0
	var duck_rate: float = float(spec["duck"]["attack_per_s"]) if duck_goal > duck_t else float(spec["duck"]["release_per_s"])
	duck_t = move_toward(duck_t, duck_goal, duck_rate * delta)
	var duck_db: float = float(spec["duck"]["ambience_db"]) * duck_t
	var ducked: Array = spec["duck"].get("layers", ["wind", "rain", "machinery", "engine"])
	var in_db: float = float(spec["indoor"]["ambience_db"]) * indoor_t
	targets["wind"] = _val(row.get("wind", SILENT_DB), prog) + (duck_db if ducked.has("wind") else 0.0) + in_db
	targets["rain"] = _val(row.get("rain", SILENT_DB), prog) + (duck_db if ducked.has("rain") else 0.0) + in_db
	targets["machinery"] = _val(row.get("machinery", SILENT_DB), prog) + (duck_db if ducked.has("machinery") else 0.0)
	var under_way := true
	if bool(spec["engine_only_when_underway"]):
		var vel: Variant = _boat.get("velocity") if _boat != null else null
		var drv: Variant = _boat.get("driving") if _boat != null else null
		under_way = _boat != null and (drv == true or (vel is Vector3 and (vel as Vector3).length() > 1.0))
	targets["engine"] = (_val(row.get("engine", SILENT_DB), prog) + (duck_db if ducked.has("engine") else 0.0)) if under_way else SILENT_DB
	var k := 1.0 if snap else 1.0 - exp(-float(spec["smoothing_per_s"]) * delta)
	for nm in ["wind", "rain", "engine", "machinery"]:
		levels[nm] = lerpf(float(levels[nm]), float(targets[nm]), k)
		var p: Node = players[nm]
		p.set("volume_db", maxf(float(levels[nm]), SILENT_DB))
	if _lowpass:
		_lowpass.cutoff_hz = lerpf(20500.0, float(spec["indoor"]["lowpass_hz"]), indoor_t)
	_step_voice(delta, snap)
	_step_music(delta, snap)
	_step_bells(delta)
	_step_fail(delta)


## The crossfade: the new track rises from silence to music.volume_db while the old one falls away, then stops.
func _step_music(delta: float, snap: bool) -> void:
	if _music.is_empty() or music_track == "":
		return
	var m: Dictionary = spec["music"]
	_music_mix = 1.0 if snap else minf(_music_mix + delta / maxf(float(m["crossfade_s"]), 0.01), 1.0)
	var top := float(m["volume_db"])
	var cur: AudioStreamPlayer = _music[_music_cur]
	var old: AudioStreamPlayer = _music[1 - _music_cur]
	cur.volume_db = top + linear_to_db(maxf(_music_mix, 0.0001))
	old.volume_db = top + linear_to_db(maxf(1.0 - _music_mix, 0.0001))
	if _music_mix >= 1.0 and old.playing:
		old.stop()


func _val(entry: Variant, prog: float) -> float:
	if entry is Array:
		return lerpf(float(entry[0]), float(entry[1]), clampf(prog, 0.0, 1.0))
	return float(entry)


## Places the line being spoken: its speaker's distance from the player, and a floor or an outside wall between them.
func _step_voice(delta: float, snap: bool) -> void:
	var v: Dictionary = spec.get("voice", {})
	if v.is_empty() or _bus_voice < 0:
		return
	var goal_db := float(v["base_db"]) + float(v.get("speaker_db", {}).get(voice_speaker, 0.0))
	var goal_walled := 0.0
	var dist_t := 0.0
	var spk := _speaker_node(voice_speaker)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if spk != null and player != null:
		var a := spk.global_position
		var b := player.global_position
		dist_t = clampf(inverse_lerp(float(v["near_m"]), float(v["far_m"]), a.distance_to(b)), 0.0, 1.0)
		var in_a: bool = _gs.inside_building(a)
		var in_b: bool = _gs.inside_building(b)
		if in_a != in_b:
			goal_walled = 1.0
		elif in_a:
			goal_walled = clampf(inverse_lerp(float(v["floor_gap_m"]), float(v["floor_full_m"]), absf(a.y - b.y)), 0.0, 1.0)
		goal_db += float(v["far_db"]) * dist_t + float(v["wall_db"]) * goal_walled
	var k := 1.0 if (snap or _voice_snap) else 1.0 - exp(-float(v["rate_per_s"]) * delta)
	_voice_snap = false
	voice_db = lerpf(voice_db, goal_db, k)
	voice_walled = lerpf(voice_walled, goal_walled, k)
	AudioServer.set_bus_volume_db(_bus_voice, voice_db)
	var open_hz := lerpf(20500.0, float(v["far_cutoff_hz"]), dist_t)
	_voice_lowpass.cutoff_hz = lerpf(open_hz, float(v["wall_cutoff_hz"]), voice_walled)
	_voice_reverb.wet = float(v["wall_reverb_wet"]) * voice_walled


func _speaker_node(who: String) -> Node3D:
	if who == "":
		return null
	for n in get_tree().get_nodes_in_group("npc"):
		if String(n.get("who")) == who and n is Node3D:
			return n
	return null


func _step_bells(delta: float) -> void:
	if fail_active:
		return
	var iv: Array = spec["bells"]["interval_s"]
	for i in _bells.size():
		_bell_timers[i] -= delta
		if _bell_timers[i] <= 0.0:
			_bell_timers[i] = _rng.randf_range(float(iv[0]), float(iv[1]))
			var bp: AudioStreamPlayer3D = _bells[i]
			if bp.stream:
				bp.volume_db = float(spec["bells"]["volume_db"]) + float(spec["duck"]["ambience_db"]) * duck_t
				bp.play()


func _on_event(id: String, _phase: int) -> void:
	_music_cue("on_event", id)
	if id == "SHIP_FAIL" and not fail_active:
		fail_active = true
		_fail_t = 0.0
		_horn_left = int(spec["fail"]["horn_blasts"])
		_horn_next = 0.0
		var dl: Node = _gs.deadline()
		if _ship == null and dl and dl.ship:
			_attach_ship(dl.ship)


## A saved ship sounds its horn once as it clears the rock (creator, 29 October 2026).
func _on_cleared_rock() -> void:
	if fail_active or (_gs != null and _gs.outcome == _gs.Outcome.FAIL):
		return
	win_horns += 1
	var h: Node = players.get("foghorn")
	if h and h.get("stream"):
		h.set("volume_db", float(spec["win"]["horn_db"]))
		h.call("play")


func _on_impact() -> void:
	_impact_t = 0.0
	var p: Node = players.get("impact")
	if p and p.get("stream"):
		p.set("volume_db", float(spec["impact_db"]))
		p.call("play")


func _step_fail(delta: float) -> void:
	if not fail_active:
		return
	_fail_t += delta
	while _horn_left > 0 and _fail_t >= _horn_next:
		var h: Node = players.get("foghorn")
		if h and h.get("stream"):
			h.set("volume_db", float(spec["fail"]["horn_db"]))
			h.call("play")
		_horn_left -= 1
		_horn_next += float(spec["fail"]["horn_gap_s"])
	if _impact_t >= 0.0:
		_impact_t += delta
		var f: Dictionary = spec["fail"]
		if _silence_t < 0.0 and _impact_t >= float(f["after_impact_s"]):
			_silence_t = 0.0
		if _silence_t >= 0.0:
			_silence_t += delta
			var fade := clampf(_silence_t / float(f["silence_fade_s"]), 0.0, 1.0)
			var db := lerpf(0.0, SILENT_DB, fade)
			AudioServer.set_bus_volume_db(_bus_amb, db)
			AudioServer.set_bus_volume_db(_bus_sfx, db)
			if _bus_music >= 0:
				AudioServer.set_bus_volume_db(_bus_music, db)   # the music fades with the rest for the Failed screen
			if not silence_done and _silence_t >= float(f["silence_fade_s"]) + float(f["silence_hold_s"]):
				silence_done = true
				fail_audio_finished.emit()
