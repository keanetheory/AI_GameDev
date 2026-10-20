# check_interior_reach.gd - run: Godot --headless --path . --script res://tools/check_interior_reach.gd
# Can the player walk from the lighthouse porch to every interior marker? Flood fills the walkable map
# (tools/interior_reach.gd) over the game's real collision with the door left open, then checks each marker in the
# loaded greybox's alignment file. Prints each marker as REACHED or NOT REACHED (with the nearest reachable spot),
# then exits 0 if all are reached. Set REACH_DUMP=<file> to also write every spot (local x, y, z, reached) as JSON.
extends SceneTree

const Reach := preload("res://tools/interior_reach.gd")
## Places in the furnished rooms that must be reachable on foot from the porch.
const ROOM_ANCHORS := ["boiler_interaction", "coal_pickup", "daniel", "l1_landing", "l1_hall", "l1_quarters", "l1_radio", "l1_mess",
	"l1_ring", "l2_landing", "l2_control", "l2_instruments", "lamp_stand"]

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f == 5:
		_lv.get_node("LighthouseDoor").open()
	if _f < 60:   # let the door finish swinging
		return false
	_run()
	return true


func _run() -> void:
	var player: CharacterBody3D = _lv.get_node("Player")
	var exclude: Array[RID] = [player.get_rid()]
	var reach := Reach.new(_lv.get_world_3d().direct_space_state, exclude)
	reach.build()
	print("REACH standable spots: ", reach.spot_count)
	var door: Node3D = _lv.get_node("LighthouseDoor")
	if not reach.flood(door.middle() + door.global_transform.basis.z * 1.0):   # 1 m out in the porch
		print("REACH FAIL: no standable spot in the porch")
		quit(1)
		return
	print("REACH reachable spots: ", reach.seen.size())
	var missing := 0
	for name in markers(_lv):
		if name == "Lantern_arc_lamp_socket_marker":   # inside the lamp now; ANCHOR_lamp_stand covers reaching it
			continue
		var w: Vector3 = markers(_lv)[name]
		var near := reach.nearest(w, true)
		var ok := not near.is_empty() and Vector2(near["pos"].x - w.x, near["pos"].z - w.z).length() < 0.8 and absf(near["pos"].y - w.y) < 0.5
		if not ok:
			missing += 1
		var where := "nothing reachable" if near.is_empty() else "nearest reachable (local) %s" % str(near["pos"] - Reach.LIGHTHOUSE)
		print("REACH %-30s %s   %s" % [name, "REACHED" if ok else "NOT REACHED", where])
	var bands := {}   # how high the reachable area goes, per 1 m band, in local y
	for key in reach.seen:
		var parts: PackedStringArray = key.split(",")
		var band := int(floor(reach.floors["%s,%s" % [parts[0], parts[1]]][int(parts[2])] - Reach.LIGHTHOUSE.y))
		bands[band] = bands.get(band, 0) + 1
	var keys := bands.keys()
	keys.sort()
	print("REACH reachable spots by local height band: ", keys.map(func(b): return "%d:%d" % [b, bands[b]]))
	var dump := OS.get_environment("REACH_DUMP")
	if dump != "":
		var spots := []
		for key in reach.floors:
			var parts: PackedStringArray = key.split(",")
			var c: Vector2 = reach.cell_centre(int(parts[0]), int(parts[1]))
			for k in reach.floors[key].size():
				var y: float = reach.floors[key][k]
				spots.append([c.x - Reach.LIGHTHOUSE.x, y - Reach.LIGHTHOUSE.y, c.y - Reach.LIGHTHOUSE.z, reach.seen.has("%s,%d" % [key, k])])
		FileAccess.open(dump, FileAccess.WRITE).store_string(JSON.stringify(spots))
	print("RESULT: %s (%d markers not reached)" % ["OK" if missing == 0 else "FAILED", missing])
	quit(0 if missing == 0 else 1)


## Marker name -> world position of the floor under it, from the alignment file next to the loaded greybox.
static func markers(level: Node) -> Dictionary:
	var model: String = level.get_node("LighthouseInterior").model_path
	var ali: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(model.get_basename() + "_alignment.json"))
	var out := {}
	for name in ali["markers"]:
		var p: Array = ali["markers"][name]
		out[name] = Reach.LIGHTHOUSE + Vector3(p[0], p[1] - 0.15, p[2])   # marker centres sit 0.15 above their floor
	# the furnished rooms' places (interior_rooms.gd): ANCHOR_<role> -> world position
	var rooms := level.get_node_or_null("InteriorRooms")
	if rooms != null and rooms.get("anchors") is Dictionary:
		for role in ROOM_ANCHORS:
			if rooms.anchors.has(role):
				out["ANCHOR_" + role] = rooms.anchors[role]
	return out
