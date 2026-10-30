# crossing_sequence.gd - the return crossing's hazard forecast, laid on the level (backlog T10; Technical Strategy "shared hazard
# forecast", AI Agent Strategy "Hazard Forecast"). GameState creates one inside the level once it is ready. All the numbers are in
# data/world/crossing_sequence.json; the forecast itself is data/world/return_crossing.json (the Storm Crossing Crew's output) and is
# read by crossing_loader.gd, so the hazards, the safe-lane signal and Arthur's calls all come from ONE forecast and can never disagree.
#
#   SALTGATE_REACHED -> the forecast's hazards (rocks, reefs, buoys, debris) are placed along the straight line from the quay to the
#       harbour mouth, in the forecast's left, centre and right lanes (hazards.gd); the audio mixer's bells move onto the buoys;
#   on the return the boat's distance along that line (stretched to the forecast's 600 m) is fed to the loader every physics frame:
#       it fires Arthur's calls (ARTHUR_RET_01 ... as dialogue lines) ahead of each segment and reports the segment and its safe lane;
#   outbound, passing close to a sea stack without touching it fires OUTBOUND_NEAR_MISS (Arthur: "Too close! ...").
# Collision costs are T19's: nothing here charges the deadline yet (hazard_hits counts them for the QA pass).
extends Node

const Loader := preload("res://scripts/world/crossing_loader.gd")
const Hazards := preload("res://scripts/world/crossing_hazards.gd")
const SPEC_PATH := "res://data/world/crossing_sequence.json"
const SAILING := 1

signal segment_entered(segment_id: String, safe_lane: String)

var spec: Dictionary = {}
var loader: Node
var hazard_nodes: Array = []
var safe_lane := ""
var segment_id := ""
var hazard_hits := 0
var calls_made: Array = []

var _gs: Node
var _level: Node
var _boat: Node3D
var _port := Vector2.ZERO
var _berth := Vector2.ZERO
var _dir := Vector2(0, -1)
var _right := Vector2(1, 0)
var _corridor := 1.0
var _k := 1.0                        # world metres per forecast metre
var _stacks: Array = []              # {centre Vector2, r}
var _near_cool: Dictionary = {}
var _spawned := false


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	_level = level
	_boat = get_tree().get_first_node_in_group("boat") as Node3D
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("crossing_sequence: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	_port = Vector2(float(spec["port"][0]), float(spec["port"][1]))
	_berth = Vector2(float(spec["end"][0]), float(spec["end"][1]))      # where the forecast ends (the harbour mouth)
	_corridor = _port.distance_to(_berth)
	_dir = (_berth - _port) / _corridor
	_right = Vector2(-_dir.y, _dir.x)           # heading home (-Z), right is +X
	loader = Loader.new()
	loader.name = "CrossingLoader"
	add_child(loader)
	if loader.data.is_empty():
		push_error("crossing_sequence: the forecast did not load")
		return
	_k = _corridor / float(loader.data["tuning"]["route_length_m"])
	loader.arthur_call.connect(_on_call)
	loader.segment_entered.connect(_on_segment)
	if _boat != null and _boat.has_signal("hazard_hit"):
		_boat.hazard_hit.connect(func() -> void: hazard_hits += 1)
	gs.event_emitted.connect(_on_event)


# ---- the forecast on the level ----

## World position of a forecast route position and lane (left -1, centre 0, right +1).
func world_point(route_m: float, lane: String) -> Vector2:
	var lat := 0.0
	match lane:
		"left":
			lat = -1.0
		"right":
			lat = 1.0
	return _port + _dir * (route_m * _k) + _right * (lat * float(spec["lane_offset_m"]))


## The boat's distance along the corridor in forecast metres (0 at the quay, 600 at the harbour mouth).
func route_position(p: Vector3) -> float:
	return clampf((Vector2(p.x, p.z) - _port).dot(_dir) / _k, 0.0, float(loader.data["tuning"]["route_length_m"]))


func lane_point(route_m: float, lane: String) -> Vector2:
	return world_point(route_m, lane)


func _on_event(id: String, _phase: int) -> void:
	if id == spec["spawn_on"] or id == "BURNER_PICKED_UP":
		_spawn_hazards()


func _spawn_hazards() -> void:
	if _spawned or loader == null or Engine.has_meta("no_crossing_hazards"):
		return       # (tests that sail the whole route with a simple bot set the "no_crossing_hazards" meta first)
	_spawned = true
	var buoys: Array = []
	for h in loader.hazards():
		var p := world_point(float(h["route_m"]), String(h["lane"]))
		var body: StaticBody3D = Hazards.make(h, Vector3(p.x, 0.5, p.y), _dir, spec["hazards"])
		_level.add_child(body)
		hazard_nodes.append(body)
		if String(h["type"]) == "buoy":
			buoys.append(body.global_position + Vector3(0, 1.0, 0))
	var mixer: Node = _gs.audio()
	if mixer != null and mixer.has_method("place_bells") and not buoys.is_empty():
		mixer.place_bells(buoys)


# ---- the crossing ----

func _physics_process(_delta: float) -> void:
	if loader == null or _boat == null:
		return
	var st: Variant = _boat.get("state")
	var sailing: bool = st != null and int(st) == SAILING      # (boat.gd State: DOCKED, SAILING, DOCKING)
	var phase: String = _gs.phase_name()
	if sailing and (phase == "RETURN" or phase == "FINAL_REPAIR"):
		loader.advance(route_position(_boat.global_position))
	elif sailing and phase == "OUTBOUND":
		_near_misses()


func _on_call(call_id: String, _subtitle: String, _direction: String) -> void:
	calls_made.append(call_id)
	var dlg := get_node_or_null("/root/Dialogue")
	if dlg:
		dlg.trigger(call_id)       # Arthur's line, as subtitles, from the same forecast


func _on_segment(seg: String, lane: String) -> void:
	segment_id = seg
	safe_lane = lane
	segment_entered.emit(seg, lane)


func _near_misses() -> void:
	if _stacks.is_empty():
		for r in _level.get_node("SeaRocks").get_children():
			var aabb := AABB()
			var first := true
			for c in r.find_children("*", "MeshInstance3D", true, false):
				var mi := c as MeshInstance3D
				if mi.mesh == null:
					continue
				var b: AABB = mi.global_transform * mi.get_aabb()
				aabb = b if first else aabb.merge(b)
				first = false
			if not first:
				_stacks.append({"name": String(r.name), "centre": Vector2(aabb.get_center().x, aabb.get_center().z), "r": maxf(aabb.size.x, aabb.size.z) * 0.5})
	var bp := Vector2(_boat.global_position.x, _boat.global_position.z)
	var now := Time.get_ticks_msec() / 1000.0
	for s in _stacks:
		var gap: float = bp.distance_to(s["centre"]) - float(s["r"]) - 2.8      # from the hull's nose to the rock's edge
		if gap > 1.0 and gap < float(spec["near_miss"]["edge_m"]) and now - float(_near_cool.get(s["name"], -100.0)) > 12.0:
			_near_cool[s["name"]] = now
			_gs.emit_event("OUTBOUND_NEAR_MISS")
