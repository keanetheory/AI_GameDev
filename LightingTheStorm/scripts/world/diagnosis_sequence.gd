# diagnosis_sequence.gd - the beacon diagnosis and the briefing (backlog T05; Exec Summary step 3, Technical Strategy BEACON_DIAGNOSIS).
# GameState creates one inside the level once it is ready, so Level.tscn carries none of it. Every number is in
# data/world/diagnosis_sequence.json. This script only reports events; GameState owns the phase and the dialogue plays the lines.
#
#   SAILORS_INSIDE + DANIEL_IN_BASEMENT -> a few seconds later BEACON_STILL_DARK (Ted, now in the lamp room, calls the player up: "Dynamo's
#       running and still no light ... Lantern room, Isaac. With me."); Ted appears beside the arc lamp;
#   the player reaches the lamp room -> LAMP_ROOM_ENTERED (Ted: "Arc lamp's in the middle. Let's open her up ...");
#   a few seconds later -> BURNER_DIAGNOSED: the cracked burner Ted has taken out appears on the floor beside him ("Cracked clean
#       through. The burner's finished ..."), then he names the ship, which is in view out of the lamp-room windows;
#   the player comes back down to the hall where Arthur waits -> BURNER_BRIEFING (Ted: "No burner, no beacon. There's a spare at the
#       Saltgate ... Go with Arthur"), and if they then dawdle IDLE_STEP_3 nudges until the boat casts off;
#   later, the player enters the lamp room carrying the replacement burner -> LAMP_ROOM_REENTERED (Ted: "Socket's open. Burner in ...").
# The arc lamp is not animated open: the socket is simply empty and the broken burner turns up on the floor (an art task).
extends Node

const Ted := preload("res://scripts/character/ted.gd")
const Routes := preload("res://scripts/character/npc_routes.gd")
const SPEC_PATH := "res://data/world/diagnosis_sequence.json"

var spec: Dictionary = {}
var ted: Node3D

var _gs: Node
var _level: Node
var _dark_in := -1.0
var _open_in := -1.0
var _idle_in := -1.0
var _idle_count := 0
var _hall_spot := Vector3.ZERO
var _broken: Array = []


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	_level = level
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("diagnosis_sequence: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	var route := Routes.route("sailors_dock_to_hall")
	if route.size() > 0:
		_hall_spot = route[route.size() - 1]
	# the cracked burner lies on the lamp-room floor from the build; it is not there until Ted has taken it out
	for nm in ["BrokenBurner", "BrokenBurnerCloth"]:
		var n := level.find_child(nm, true, false) as Node3D
		if n:
			n.visible = false
			_broken.append(n)
	gs.event_emitted.connect(_on_event)


func _on_event(id: String, _phase: int) -> void:
	match id:
		"SAILORS_INSIDE", "DANIEL_IN_BASEMENT":
			if _dark_in < 0.0 and _gs.fired.has("SAILORS_INSIDE") and _gs.fired.has("DANIEL_IN_BASEMENT") and not _gs.fired.has("BEACON_STILL_DARK"):
				_dark_in = float(spec["still_dark_delay_s"])
		"BEACON_STILL_DARK":
			_place_ted()
		"BURNER_DIAGNOSED":
			for n in _broken:
				n.visible = true
		"BURNER_BRIEFING":
			_idle_in = float(spec["idle_step3"]["first_nudge_s"])
			_idle_count = 0
		"BOAT_CAST_OFF":
			_idle_in = -1.0
			_gs.reset_idle("IDLE_STEP_3")


func _process(delta: float) -> void:
	if spec.is_empty():
		return
	if _dark_in >= 0.0:
		_dark_in -= delta
		if _dark_in < 0.0:
			_dark_in = -2.0
			_gs.emit_event("BEACON_STILL_DARK")
	if _open_in >= 0.0:
		_open_in -= delta
		if _open_in < 0.0:
			_open_in = -2.0
			_gs.emit_event("BURNER_DIAGNOSED")
	if _idle_in >= 0.0:
		_idle_in -= delta
		if _idle_in < 0.0:
			_idle_count += 1
			_gs.idle("IDLE_STEP_3")
			_idle_in = float(spec["idle_step3"]["next_nudge_s"]) if _idle_count < int(spec["idle_step3"]["tiers"]) else -2.0
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var p := player.global_position
	if _in_lamp_room(p):
		if _gs.fired.has("BEACON_STILL_DARK") and not _gs.fired.has("LAMP_ROOM_ENTERED"):
			_gs.emit_event("LAMP_ROOM_ENTERED")
			_open_in = float(spec["open_delay_s"])
		elif _gs.fired.has("BURNER_PICKED_UP") and not _gs.fired.has("LAMP_ROOM_REENTERED") and _carrying_burner():
			_gs.emit_event("LAMP_ROOM_REENTERED")
	elif _gs.fired.has("BURNER_DIAGNOSED") and not _gs.fired.has("BURNER_BRIEFING") and _in_hall(p):
		_gs.emit_event("BURNER_BRIEFING")


func _place_ted() -> void:
	if ted != null and is_instance_valid(ted):
		return
	var t: Dictionary = spec["ted"]
	ted = Ted.new()
	_level.add_child(ted)
	ted.setup(String(t["pose_clip"]), float(t["pose_time"]))
	ted.global_position = Vector3(float(t["spot"][0]), float(t["spot"][1]), float(t["spot"][2]))
	ted.face(Vector3(float(t["look_at"][0]), float(t["look_at"][1]), float(t["look_at"][2])))


func _in_lamp_room(p: Vector3) -> bool:
	var r: Dictionary = spec["lamp_room"]
	var c: Array = r["centre"]
	return Vector2(p.x - float(c[0]), p.z - float(c[1])).length() < float(r["radius_m"]) and p.y > float(r["y_band"][0]) and p.y < float(r["y_band"][1])


func _in_hall(p: Vector3) -> bool:
	var h: Dictionary = spec["hall"]
	return Vector2(p.x - _hall_spot.x, p.z - _hall_spot.z).length() < float(h["radius_m"]) and p.y > float(h["y_band"][0]) and p.y < float(h["y_band"][1])


func _carrying_burner() -> bool:
	var carry := get_node_or_null("/root/Carry")
	return carry != null and carry.is_holding() and String(carry.held_kind) == "burner"
