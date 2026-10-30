# intro_sequence.gd - the opening of the game (creator, 30 October 2026; Exec Summary step 1, Decisions A16).
# GameState creates one inside the level once it is ready. The game starts with Ted already inside, behind the shut front door:
#   the player knocks (E on the door shows "Knock") -> the knock sounds -> GAME_STARTED, Ted's greeting ("Hrmph. You're the new guy,
#   then ... In.") -> Ted opens the door -> the player steps in (LIGHTHOUSE_ENTERED, Ted: "Boiler's cold ... Shovel coal, Isaac.")
#   and Ted walks up the tower to the lamp room while he says it, where he waits (the diagnosis finds him there).
# If the level has no front door (a test scene) nothing is held and GameState starts the game as before. Ted is the rigged character
# (npc.gd "TED"). All timings are in data/world/intro_sequence.json.
extends Node

const Npc := preload("res://scripts/character/npc.gd")
const Routes := preload("res://scripts/character/npc_routes.gd")
const SPEC_PATH := "res://data/world/intro_sequence.json"

var holds_start := false           # GameState waits for the knock before it starts the game
var spec: Dictionary = {}
var ted: Node3D
var door: Node

var _gs: Node
var _level: Node
var _anchors: Node
var _start_in := -1.0
var _open_in := -1.0
var _knock_player: AudioStreamPlayer3D
var _walked := false


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	_level = level
	door = level.get_node_or_null("LighthouseDoor")
	_anchors = level.get_node_or_null("InteriorAnchors")
	if Engine.has_meta("skip_intro") or door == null or _anchors == null or not door.has_signal("knocked"):
		return       # (tests that need an ordinary front door set the "skip_intro" meta first)
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("intro_sequence: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	holds_start = true
	door.knock_mode = true
	door.knocked.connect(_on_knock)
	gs.event_emitted.connect(_on_event)
	var st := load(String(spec["knock"]["sound"])) as AudioStream
	if st:
		_knock_player = AudioStreamPlayer3D.new()
		_knock_player.stream = st
		_knock_player.volume_db = float(spec["knock"]["db"])
		_knock_player.unit_size = 8.0
		_knock_player.max_distance = 60.0
		_knock_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		door.add_child(_knock_player)
		_knock_player.position = Vector3(float(door.width) * 0.5, 1.4, 0.0)


func _process(delta: float) -> void:
	if spec.is_empty():
		return
	if ted == null and _anchors.anchors.has("ted_greeting"):
		_spawn_ted()
	if _start_in >= 0.0:
		_start_in -= delta
		if _start_in < 0.0:
			_start_in = -2.0
			_gs.emit_event("GAME_STARTED")
	if _open_in >= 0.0:
		_open_in -= delta
		if _open_in < 0.0:
			_open_in = -2.0
			door.open()
			door.enabled = true       # from now on the door is an ordinary door


## Ted waits just inside, behind the shut door, out of the swing of the leaf.
func _spawn_ted() -> void:
	var at: Vector3 = (_anchors.anchors["ted_greeting"] as Node3D).global_position
	var route := Routes.route("ted_to_lamp")
	if route.size() > 0:
		at = route[0]              # the baked start is on the floor; the anchor floats a few centimetres above it
	ted = Npc.spawn(_level, "TED", at)
	ted.face(door.middle())


func _on_knock() -> void:
	if _knock_player:
		_knock_player.play()
	_start_in = float(spec["reply_delay_s"])
	_open_in = float(spec["reply_delay_s"]) + float(spec["open_after_start_s"])


func _on_event(id: String, _phase: int) -> void:
	if id == "LIGHTHOUSE_ENTERED" and not _walked and ted != null:
		_walked = true
		var route := Routes.route("ted_to_lamp")
		if route.size() > 0:
			ted.walk(route, "ted_to_lamp", float(spec["ted_walk_speed_mps"]))
			ted.arrived.connect(_on_ted_arrived)


func _on_ted_arrived(_route: String) -> void:
	var t: Array = spec["lamp_look_at"]
	ted.face(Vector3(float(t[0]), float(t[1]), float(t[2])))
