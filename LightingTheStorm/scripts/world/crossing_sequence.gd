# crossing_sequence.gd - the return crossing's hazard forecast, laid on the level (backlog T10; Technical Strategy "shared hazard
# forecast", AI Agent Strategy "Hazard Forecast"). GameState creates one inside the level once it is ready. All the numbers are in
# data/world/crossing_sequence.json; the forecast itself is data/world/return_crossing.json (the Storm Crossing Crew's output) and is
# read by crossing_loader.gd, so the hazards, the safe-lane signal and Arthur's calls all come from ONE forecast and can never disagree.
#
#   when the level is ready the forecast's hazards (rocks, reefs, buoys, debris) are placed along the straight line from the quay to the
#       harbour mouth, in the forecast's left, centre and right lanes (hazards.gd), so the sea is the same on both crossings; the audio
#       mixer's bells move onto the buoys;
#   on the return the boat's distance along that line (stretched to the forecast's 600 m) is fed to the loader every physics frame:
#       it fires Arthur's calls (ARTHUR_RET_01 ... as dialogue lines) ahead of each segment and reports the segment and its safe lane;
#   passing close to a sea stack or a hazard without touching it is a near miss (outbound it also fires OUTBOUND_NEAR_MISS); Arthur's
#       line gets more frantic each time, in three levels (ARTHUR_NEAR_1..3), and so does his line after a collision (ARTHUR_HIT_1..3);
#   a collision on the return throws the boat back and rocks it (boat.gd hard_bounce) and costs 5 s of deadline;
#   every time auto-docking starts Arthur says DOCKING_DIALOGUE; at the lighthouse after a rough return he admonishes instead, in three
#       levels, before the "go go go".
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
var hazard_hits := 0                 # every collision this attempt
var return_hits := 0                 # collisions on the return crossing (they cost deadline time and colour the docking line)
var leg_hits := 0                    # collisions on the current crossing (they set how frantic Arthur sounds)
var near_misses := 0                 # near misses on the current crossing
var calls_made: Array = []
var dialogue_log: Array = []         # every dialogue trigger this director fired (for the tests)

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
var _last_near := -100.0


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
		_boat.hazard_hit.connect(_on_hit)
	if _boat != null and _boat.has_signal("docking_started"):
		_boat.docking_started.connect(_on_docking)
	var rc: Dictionary = spec["return_collision"]
	if _boat != null and "bounce_distance_m" in _boat:
		_boat.bounce_distance_m = float(rc["bounce_m"])
		_boat.bounce_time_s = float(rc["bounce_s"])
		_boat.rock_deg = float(rc["rock_deg"])
		_boat.rock_time_s = float(rc["rock_s"])
		_boat.bounce_stun_s = float(rc["stun_s"])
	gs.event_emitted.connect(_on_event)
	if not Engine.has_meta("no_crossing_hazards"):
		_spawn_hazards.call_deferred()       # the sea is the same from the first minute (creator, 31 Oct 2026)


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
	match id:
		"BOAT_CAST_OFF":
			_new_leg(false)
		"RETURN_DEPARTED":
			_new_leg(true)
		"RETURN_ARRIVED":
			if _boat != null and "hard_bounce" in _boat:
				_boat.hard_bounce = false


## A crossing begins: the near-miss and collision counts start again (Arthur starts calm), and a return collision is the hard kind.
func _new_leg(is_return: bool) -> void:
	near_misses = 0
	leg_hits = 0
	if is_return:
		return_hits = 0
	if _boat != null and "hard_bounce" in _boat:
		_boat.hard_bounce = is_return


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
	if sailing and (phase == "OUTBOUND" or phase == "RETURN"):
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
	if now - _last_near > float(spec["near_miss"]["global_cooldown_s"]):
		for st in _stacks:
			if _check_near(bp, st["centre"], float(st["r"]), String(st["name"]), now):
				return
		for h in hazard_nodes:
			if is_instance_valid(h) and _check_near(bp, Vector2(h.global_position.x, h.global_position.z), float(h.get_meta("near_r", 2.0)), String(h.name), now):
				return


func _check_near(bp: Vector2, centre: Vector2, r: float, key: String, now: float) -> bool:
	var gap: float = bp.distance_to(centre) - r - 2.8      # from the hull's nose to the obstacle's edge
	if gap > 1.0 and gap < float(spec["near_miss"]["edge_m"]) and now - float(_near_cool.get(key, -100.0)) > 12.0:
		_near_cool[key] = now
		_last_near = now
		near_misses += 1
		if String(_gs.phase_name()) == "OUTBOUND":
			_gs.emit_event("OUTBOUND_NEAR_MISS")
		_say("ARTHUR_NEAR_%d" % mini(near_misses, 3))
		return true
	return false


## A collision (the boat reports hazard_hit): count it, and on the return charge the deadline and note it for the docking line.
func _on_hit() -> void:
	hazard_hits += 1
	leg_hits += 1
	var on_return: bool = _boat != null and bool(_boat.get("hard_bounce"))      # set from RETURN_DEPARTED until RETURN_ARRIVED
	if on_return:
		return_hits += 1
		var dl: Node = _gs.deadline()
		if dl != null:
			dl.add_penalty(float(spec["return_collision"]["penalty_s"]), "return collision")
	_say("ARTHUR_HIT_%d" % mini(leg_hits, 3))


## Auto-docking has taken the wheel: Arthur's DOCKING_DIALOGUE, every time; at the lighthouse after a rough return it is the admonishment.
func _on_docking(zone_id: String) -> void:
	var id := "DOCKING_DIALOGUE"
	if zone_id == "DOCK_LIGHTHOUSE" and return_hits > 0:
		var tiers: Array = spec["docking"]["tier_hits"]
		var tier := 1
		if return_hits >= int(tiers[2]):
			tier = 3
		elif return_hits >= int(tiers[1]):
			tier = 2
		id = "DOCKING_DIALOGUE_LIGHTHOUSE_%d" % tier
	_say(id)


func _say(trigger_id: String) -> void:
	dialogue_log.append(trigger_id)
	var dlg := get_node_or_null("/root/Dialogue")
	if dlg:
		dlg.trigger(trigger_id)
