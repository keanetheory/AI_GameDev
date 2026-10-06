# crossing_loader.gd - Godot 4 / GDScript
# Reads the Storm Crossing Crew's return_crossing.json and feeds the return crossing:
# hazard spawns, the single safe-route signal, and Jeff's calls (all from ONE forecast,
# so Jeff can never disagree with the hazards). Attach to a Node in the sea scene and
# call advance(route_m) each physics frame with the boat's distance along the route.
extends Node

signal segment_entered(segment_id: String, safe_lane: String)
signal jeff_call(call_id: String, subtitle: String, direction: String)
signal return_arrived(arrival_line: String)

@export_file("*.json") var data_path := "res://data/return_crossing.json"

var data: Dictionary = {}
var _fired_calls := {}
var _current_segment := ""
var _arrived := false


func _ready() -> void:
	var file := FileAccess.open(data_path, FileAccess.READ)
	if file == null:
		push_error("Crossing data not found: %s" % data_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("phase", "") != "RETURN":
		push_error("return_crossing.json is not RETURN phase data")
		return
	data = parsed


func hazards() -> Array:
	# Every hazard with its absolute route position, for the spawner to place.
	var out := []
	for seg in data.get("segments", []):
		out.append_array(seg["hazards"])
	return out


func advance(route_m: float) -> void:
	if data.is_empty() or _arrived:
		return
	for seg in data["segments"]:
		var call: Dictionary = seg["jeff_call"]
		if route_m >= call["trigger_route_m"] and not _fired_calls.has(call["call_id"]):
			_fired_calls[call["call_id"]] = true
			jeff_call.emit(call["call_id"], call["subtitle"], call["direction"])
		var start: float = seg["start_m"]
		if route_m >= start and route_m < start + seg["length_m"] and _current_segment != seg["segment_id"]:
			_current_segment = seg["segment_id"]
			segment_entered.emit(_current_segment, seg["safe_lane"])
	if route_m >= data["tuning"]["route_length_m"]:
		_arrived = true
		return_arrived.emit(data["arrival_line"]["line"])


func reset_for_restart() -> void:
	# Gate 1 retry model: fail, then restart the slice.
	_fired_calls.clear()
	_current_segment = ""
	_arrived = false
