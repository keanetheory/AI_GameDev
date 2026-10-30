# sailors_sequence.gd - the shelter-and-gate beat (backlog T04; Exec Summary step 2, Technical Strategy "shelter and gate", Decisions A7).
# GameState creates one inside the level once it is ready (like the ship deadline and the audio), so Level.tscn carries none of it.
#
#   BOILER_FED   -> a few seconds later Arthur and Daniel (capsules, T30) row in at the harbour mouth in the rowboat;
#   rowboat berths at the south jetty -> SAILORS_MOORED (Ted: "Rowboat's moored at my dock ... open the island gate");
#   the sailors step ashore and wait on the stairs below the island gate, facing it;
#   WINDOW_LOOKED -> the player looks out of the tower landing window after they have moored (it sees the water outside the harbour
#                    mouth, tools/test_sightlines.gd), or fallback_s after they moor, whichever is first (Ted: "See them?");
#   the player walks up (the gate reports GATE_APPROACHED) and opens it (GATE_OPENED);
#   the sailors walk on up through the gate to the lighthouse: Arthur into the hall (SAILORS_INSIDE), Daniel a few seconds behind
#   and on down the spiral to the basement, where he stays (DANIEL_IN_BASEMENT, which ends SHELTER_AND_GATE).
# If the gate stays shut Ted's IDLE_STEP_2 ladder nudges (hint, sharper, explicit). Routes are baked (tools/bake_npc_paths.gd);
# every number is in data/world/sailors_sequence.json. This script only reports events; GameState owns the phase.
extends Node

const Npc := preload("res://scripts/character/npc.gd")
const Routes := preload("res://scripts/character/npc_routes.gd")
const Rowboat := preload("res://scripts/world/rowboat.gd")
const SPEC_PATH := "res://data/world/sailors_sequence.json"

enum Stage { WAITING, ARRIVING, LANDING, AT_GATE, ENTERING, DONE }

var stage: int = Stage.WAITING
var spec: Dictionary = {}
var rowboat: Node3D
var arthur: Node3D
var daniel: Node3D
var window_looked := false

var _gs: Node
var _level: Node
var _gate: Node
var _arrive_in := -1.0
var _land_in := -1.0
var _window_fallback := -1.0
var _idle_in := -1.0
var _idle_count := 0
var _gate_open := false
var _arthur_leg2: PackedVector3Array = PackedVector3Array()
var _daniel_leg2: PackedVector3Array = PackedVector3Array()
var _arthur_start := -1.0
var _daniel_start := -1.0
var _arthur_waiting := false
var _daniel_waiting := false


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	_level = level
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("sailors_sequence: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	_gate = get_tree().get_first_node_in_group("gate")
	gs.event_emitted.connect(_on_event)


func _on_event(id: String, _phase: int) -> void:
	match id:
		"BOILER_FED":
			if stage == Stage.WAITING and _arrive_in < 0.0:
				_arrive_in = float(spec["arrive_delay_s"])
		"GATE_OPENED":
			_gate_open = true
			_gs.reset_idle("IDLE_STEP_2")
			_idle_in = -1.0
			_try_enter()


func _process(delta: float) -> void:
	if spec.is_empty():
		return
	if _arrive_in >= 0.0:
		_arrive_in -= delta
		if _arrive_in < 0.0:
			_arrive_in = -2.0
			_begin_arrival()
	if _land_in >= 0.0:
		_land_in -= delta
		if _land_in < 0.0:
			_land_in = -2.0
			_step_ashore()
	if _arthur_start >= 0.0:
		_arthur_start -= delta
		if _arthur_start < 0.0:
			_arthur_start = -2.0
			arthur.walk(_arthur_leg2, "sailors_dock_to_hall")
	if _daniel_start >= 0.0:
		_daniel_start -= delta
		if _daniel_start < 0.0:
			_daniel_start = -2.0
			daniel.walk(_daniel_leg2, "daniel_dock_to_basement")
	if _window_fallback >= 0.0:
		_window_fallback -= delta
		if _window_fallback < 0.0:
			_window_fallback = -2.0
			_fire_window()
	if _idle_in >= 0.0:
		_idle_in -= delta
		if _idle_in < 0.0:
			_idle_count += 1
			_gs.idle("IDLE_STEP_2")
			_idle_in = float(spec["idle"]["next_nudge_s"]) if _idle_count < int(spec["idle"]["tiers"]) else -2.0
	if _gs.fired.has("SAILORS_MOORED") and not window_looked and _player_at_window():
		_fire_window()


# ---- the arrival ----

func _begin_arrival() -> void:
	stage = Stage.ARRIVING
	rowboat = Rowboat.new()
	_level.add_child(rowboat)
	rowboat.setup(spec["rowboat"])
	rowboat.moored.connect(_on_moored)
	arthur = Npc.spawn(_level, "ARTHUR", rowboat.global_position)
	daniel = Npc.spawn(_level, "DANIEL", rowboat.global_position)
	arthur.sit(rowboat, rowboat.seat_arthur)
	daniel.sit(rowboat, rowboat.seat_daniel)
	arthur.arrived.connect(_on_walk_done)
	daniel.arrived.connect(_on_walk_done)
	rowboat.row()


func _on_moored() -> void:
	stage = Stage.LANDING
	_gs.emit_event("SAILORS_MOORED")
	_land_in = float(spec["step_ashore_delay_s"])
	_window_fallback = float(spec["window"]["fallback_s"])
	_idle_in = float(spec["idle"]["first_nudge_s"])


func _step_ashore() -> void:
	arthur.release_seat()
	daniel.release_seat()
	var w: Dictionary = spec["wait_at_gate"]
	var a := _leg_split(Routes.route("sailors_dock_to_hall"), float(w["arthur_back_m"]))
	var d := _leg_split(Routes.route("daniel_dock_to_basement"), float(w["daniel_back_m"]))
	_arthur_leg2 = a["rest"]
	_daniel_leg2 = d["rest"]
	_arthur_waiting = true
	_daniel_waiting = true
	arthur.walk(a["first"], "to_gate")
	daniel.walk(d["first"], "to_gate")
	stage = Stage.AT_GATE


## Split a route at the point `back_m` metres before the gate: [first] walks to the gate, [rest] goes on through it.
func _leg_split(route: PackedVector3Array, back_m: float) -> Dictionary:
	var gate_at := Vector3.ZERO
	if _gate != null:
		gate_at = _gate.middle()
	var gi := 0
	var best := INF
	for i in route.size():
		var d := Vector2(route[i].x - gate_at.x, route[i].z - gate_at.z).length()
		if d < best:
			best = d
			gi = i
	var idx := gi
	var acc := 0.0
	while idx > 0 and acc < back_m:
		acc += route[idx].distance_to(route[idx - 1])
		idx -= 1
	var first := PackedVector3Array()
	var rest := PackedVector3Array()
	for i in route.size():
		if i <= idx:
			first.append(route[i])
		if i >= idx:
			rest.append(route[i])
	return {"first": first, "rest": rest}


func _on_walk_done(route_name: String) -> void:
	match route_name:
		"to_gate":
			_try_enter()
		"sailors_dock_to_hall":
			_gs.emit_event("SAILORS_INSIDE")
		"daniel_dock_to_basement":
			_daniel_sits_down()
			_gs.emit_event("DANIEL_IN_BASEMENT")
			stage = Stage.DONE


## Daniel's resting place is sat in the basement, where the walk ends (creator, 30 Oct 2026): a seat marker on the floor where he stands,
## facing the way he was walking, and the sit clip on the plank every seated model character brings until a real chair is generated.
func _daniel_sits_down() -> void:
	var seat := Node3D.new()
	seat.name = "DanielSeat"
	_level.add_child(seat)
	seat.global_position = daniel.global_position
	seat.rotation.y = daniel.global_rotation.y
	daniel.sit(seat, Vector3.ZERO)


## Both sailors are at the gate (or still walking up to it) and the gate is open: on through it.
func _try_enter() -> void:
	if not _gate_open or stage != Stage.AT_GATE:
		return
	if arthur.state == Npc.State.WALKING or daniel.state == Npc.State.WALKING:
		return       # still on the way up; their arrival calls this again
	stage = Stage.ENTERING
	_arthur_start = float(spec["after_gate_open"]["arthur_delay_s"])
	_daniel_start = float(spec["after_gate_open"]["daniel_delay_s"])


# ---- the window ----

func _fire_window() -> void:
	if window_looked:
		return
	window_looked = true
	_window_fallback = -2.0
	_gs.emit_event("WINDOW_LOOKED")


func _player_at_window() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var cam := get_viewport().get_camera_3d()
	if player == null or cam == null:
		return false
	var w: Dictionary = spec["window"]
	var spot: Array = w["spot"]
	var p := player.global_position
	if Vector2(p.x - float(spot[0]), p.z - float(spot[2])).length() > float(w["radius_m"]):
		return false
	if p.y < float(w["height_band_m"][0]) or p.y > float(w["height_band_m"][1]):
		return false
	var look: Array = w["look_toward"]
	var to := (Vector3(float(look[0]), float(look[1]), float(look[2])) - cam.global_position).normalized()
	return (-cam.global_transform.basis.z).dot(to) >= float(w["look_dot_min"])
