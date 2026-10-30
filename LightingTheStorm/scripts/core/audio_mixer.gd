# audio_mixer.gd - the Gate 1 placeholder audio (backlog T14): layered wind and rain, the boiler and dynamo, the launch's engine,
# buoy bells, the ship's foghorn and impact, mixed by game phase. GameState creates one inside the level once it is ready (like the
# ship deadline), so Level.tscn carries no audio nodes. All levels live in data/world/audio_spec.json.
#
# Mixing rules:
#   - the phase picks each layer's level; on the return the storm layers follow elapsed deadline time (Decisions A2), and a
#     frozen clock (burner fitted) keeps them where they were;
#   - indoors (the house footprint) the wind and rain are muffled by a low-pass on the Ambience bus;
#   - while anyone speaks the ambience and effects duck, so Arthur's calls stay audible;
#   - the engine only sounds while the boat is under way;
#   - a saved ship sounds its horn once as it clears the rock;
#   - at SHIP_FAIL: the ship's foghorn sounds (3D, from the ship), then the crash when the ship strikes, then silence, then
#     fail_audio_finished is emitted for the Failed screen (T08). The sequence is timed on game time, so pause freezes it.
# No audio assets are real yet: the sounds are synthesised placeholders (Assets/Audio/placeholder/SOURCES.md).
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
		dlg.line_started.connect(func(_a, _b, _c, _d2) -> void: speaking += 1)
		dlg.line_finished.connect(func(_a) -> void: speaking = maxi(speaking - 1, 0))
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
	AudioServer.set_bus_volume_db(_bus_amb, 0.0)    # a restart after a fail comes back from silence
	AudioServer.set_bus_volume_db(_bus_sfx, 0.0)
	_lowpass = null
	for i in AudioServer.get_bus_effect_count(_bus_amb):
		if AudioServer.get_bus_effect(_bus_amb, i) is AudioEffectLowPassFilter:
			_lowpass = AudioServer.get_bus_effect(_bus_amb, i)
	if _lowpass == null:
		_lowpass = AudioEffectLowPassFilter.new()
		_lowpass.cutoff_hz = 20500.0
		AudioServer.add_bus_effect(_bus_amb, _lowpass)


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
	var in_db: float = float(spec["indoor"]["ambience_db"]) * indoor_t
	targets["wind"] = _val(row.get("wind", SILENT_DB), prog) + duck_db + in_db
	targets["rain"] = _val(row.get("rain", SILENT_DB), prog) + duck_db + in_db
	targets["machinery"] = _val(row.get("machinery", SILENT_DB), prog) + duck_db
	var under_way := true
	if bool(spec["engine_only_when_underway"]):
		var vel: Variant = _boat.get("velocity") if _boat != null else null
		var drv: Variant = _boat.get("driving") if _boat != null else null
		under_way = _boat != null and (drv == true or (vel is Vector3 and (vel as Vector3).length() > 1.0))
	targets["engine"] = (_val(row.get("engine", SILENT_DB), prog) + duck_db) if under_way else SILENT_DB
	var k := 1.0 if snap else 1.0 - exp(-float(spec["smoothing_per_s"]) * delta)
	for nm in ["wind", "rain", "engine", "machinery"]:
		levels[nm] = lerpf(float(levels[nm]), float(targets[nm]), k)
		var p: Node = players[nm]
		p.set("volume_db", maxf(float(levels[nm]), SILENT_DB))
	if _lowpass:
		_lowpass.cutoff_hz = lerpf(20500.0, float(spec["indoor"]["lowpass_hz"]), indoor_t)
	_step_bells(delta)
	_step_fail(delta)


func _val(entry: Variant, prog: float) -> float:
	if entry is Array:
		return lerpf(float(entry[0]), float(entry[1]), clampf(prog, 0.0, 1.0))
	return float(entry)


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
			if not silence_done and _silence_t >= float(f["silence_fade_s"]) + float(f["silence_hold_s"]):
				silence_done = true
				fail_audio_finished.emit()
