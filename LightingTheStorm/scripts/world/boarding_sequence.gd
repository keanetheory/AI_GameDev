# boarding_sequence.gd - Arthur as the only crossing companion (backlog T11; Exec Summary steps 4-8, Technical Strategy invariants).
# GameState creates one inside the level once it is ready. Every number is in data/world/boarding_sequence.json. It only reports events.
#
#   BURNER_BRIEFING -> a few seconds later Arthur leaves his spot in the hall and walks the baked route to the launch's berth (the
#       boat will not cast off until he is aboard: "Arthur is on his way"), then takes his seat beside the helm;
#   the player comes up to the launch with Arthur aboard -> BOARDING_THRESHOLD (Arthur: "In you get. One hand on the wheel ...");
#   BOAT_CAST_OFF -> a few seconds later SHIP_SIGHTED (Arthur: "There! Ship's lights, out in the swell ...");
#   Arthur rides the whole crossing (he "keeps the engine turning" at the Saltgate); the capsule rides the boat's rig, so it pitches and
#       rolls with it;
#   RETURN_ARRIVED (the launch docks at the lighthouse) -> Arthur's "Go, go, go - don't you wait for me!", then he steps ashore on the
#       jetty and stays there: he leaves the player to climb to the lamp.
extends Node

const Npc := preload("res://scripts/character/npc.gd")
const Routes := preload("res://scripts/character/npc_routes.gd")
const SPEC_PATH := "res://data/world/boarding_sequence.json"

enum Stage { WAITING, WALKING, ABOARD, ASHORE }

var stage: int = Stage.WAITING
var spec: Dictionary = {}
var arthur: Node3D
var boat: Node3D

var _gs: Node
var _level: Node
var _leave_in := -1.0
var _sight_in := -1.0
var _ashore_in := -1.0


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	_level = level
	boat = get_tree().get_first_node_in_group("boat") as Node3D
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("boarding_sequence: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	gs.event_emitted.connect(_on_event)


func _on_event(id: String, _phase: int) -> void:
	match id:
		"BURNER_BRIEFING":
			if stage == Stage.WAITING and _leave_in < 0.0:
				_leave_in = float(spec["leave_delay_s"])
				if boat != null and "cast_off_hold" in boat:
					boat.cast_off_hold = String(spec["hold_text"])
		"BOAT_CAST_OFF":
			_sight_in = float(spec["sight_delay_s"])
		"RETURN_ARRIVED":
			_ashore_in = float(spec["ashore_delay_s"])


func _process(delta: float) -> void:
	if spec.is_empty():
		return
	if _leave_in >= 0.0:
		_leave_in -= delta
		if _leave_in < 0.0:
			_leave_in = -2.0
			_leave_for_the_launch()
	if _sight_in >= 0.0:
		_sight_in -= delta
		if _sight_in < 0.0:
			_sight_in = -2.0
			_gs.emit_event("SHIP_SIGHTED")
	if _ashore_in >= 0.0:
		_ashore_in -= delta
		if _ashore_in < 0.0:
			_ashore_in = -2.0
			_step_ashore()
	if stage == Stage.ABOARD and not _gs.fired.has("BOARDING_THRESHOLD") and boat != null:
		var p := get_tree().get_first_node_in_group("player") as Node3D
		if p != null and Vector2(p.global_position.x - boat.global_position.x, p.global_position.z - boat.global_position.z).length() < float(spec["board_distance_m"]):
			_gs.emit_event("BOARDING_THRESHOLD")


func _leave_for_the_launch() -> void:
	var sailors: Node = _gs.sailors()
	arthur = sailors.arthur if sailors != null else null
	var route := Routes.route("hall_to_launch_berth")
	if arthur == null:
		arthur = Npc.spawn(_level, "ARTHUR", route[0])
	stage = Stage.WALKING
	arthur.arrived.connect(_on_arrived)
	arthur.walk(route, "to_launch")


func _on_arrived(route_name: String) -> void:
	if route_name == "to_launch":
		_board()


func _board() -> void:
	var rig := boat.get_node_or_null("Rig") if boat != null else null
	if rig == null:
		push_warning("boarding_sequence: the boat has no Rig to sit on")
		return
	var s: Array = spec["seat"]
	arthur.sit(rig, Vector3(float(s[0]), float(s[1]), float(s[2])))
	stage = Stage.ABOARD
	if "cast_off_hold" in boat:
		boat.cast_off_hold = ""


func _step_ashore() -> void:
	if arthur == null or stage != Stage.ABOARD:
		return
	var j: Array = spec["jetty_spot"]
	arthur.release_seat()
	arthur.walk(PackedVector3Array([arthur.global_position, Vector3(float(j[0]), float(j[1]), float(j[2]))]), "ashore")
	stage = Stage.ASHORE
