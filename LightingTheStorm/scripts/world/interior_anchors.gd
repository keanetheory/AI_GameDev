# interior_anchors.gd - named places inside the lighthouse that other agents' scripts attach to.
# The Gameplay / Systems agent builds the boiler job, the lantern diagnosis and the burner fit; the Level Layout agent
# stages Ted, Daniel and the sailors; the Sound agent places machinery and whispers. They all need fixed, named positions
# that survive a re-export of the greybox, so those positions live here, read from the greybox's alignment file.
# Each anchor is a Marker3D named LHI_Anchor_<role>, in the group "lhi_anchor", with meta "role" and "note".
# Put one node of this script in Level.tscn (a child of the Level, after LighthouseInterior).
extends Node3D

const ALIGNMENT := "res://Assets/Models/lighthouse/interior/lighthouse_greybox_v3_alignment.json"
const AXIS := Vector3(8.5, 0.0, -4.9)
## Where the rowboat is seen arriving from the tower window: just outside the harbour mouth (the berth inside is hidden).
const ROWBOAT_SIGHT := Vector3(-48.0, 0.8, 24.0)

var anchors := {}


func _ready() -> void:
	var interior := get_parent().get_node_or_null("LighthouseInterior") as Node3D
	var f := FileAccess.open(ALIGNMENT, FileAccess.READ)
	if interior == null or f == null:
		push_warning("interior_anchors: LighthouseInterior or %s missing" % ALIGNMENT)
		return
	var al: Dictionary = JSON.parse_string(f.get_as_text())
	var mk: Dictionary = al["markers"]
	var gy: float = al["ground_floor_y"]
	var door: Dictionary = al["entry_door"]
	var dn := Vector3(door["normal"][0], 0.0, door["normal"][2])
	var dc := Vector3(door["centre"][0], door["centre"][1], door["centre"][2])
	_add("door_outside", interior.to_global(dc + dn * 1.5), "outside the front door, where the player starts and Ted opens it")
	_add("entry", interior.to_global(_v(mk["G_entry_marker"])), "just inside the door")
	_add("ted_greeting", interior.to_global(_v(mk["G_ted_greeting_marker"])), "where Ted stands to greet the new guy")
	_add("window_ground", interior.to_global(_v(mk["G_window_view_marker"])) + Vector3(0.4309, 0.0, 0.9024) * 0.6, "ground-floor window (opening centre). It sees the sea but NOT the dock: the island plateau is in the way")
	_add("boiler_interaction", interior.to_global(_v(mk["B1_boiler_interaction_marker"])), "stand here to feed the boiler")
	_add("coal_pickup", interior.to_global(_v(mk["B1_coal_pickup_marker"])), "the coal pile: take coal here")
	_add("daniel", interior.to_global(_v(mk["B1_daniel_marker"])), "where Daniel waits in the basement")
	_add("arc_lamp_socket", interior.to_global(_v(mk["Lantern_arc_lamp_socket_marker"])), "the arc lamp's burner socket: diagnosis and the final burner fit")
	_add("burner_fit", interior.to_global(_v(mk["Lantern_arc_lamp_socket_marker"])), "same place as the socket; the interaction for fitting the replacement burner")
	_add("ted_lantern", interior.to_global(_v(mk["Lantern_ted_marker"])), "where Ted waits in the lamp room")
	# the tower landing window: a stair step at bearing -57 degrees, around y 23.3, stood on at eye height 24.9
	var az := deg_to_rad(-57.0)
	_add("window_tower_eye", AXIS + Vector3(sin(az) * 1.6, 24.9, cos(az) * 1.6), "eye position at the tower landing window: the one window that sees the water outside the harbour")
	_add("rowboat_sighting", ROWBOAT_SIGHT, "where the rowboat is seen arriving, visible from the tower window (the berth itself is hidden)")
	_add("lamp_eye", interior.to_global(Vector3(mk["Lantern_arc_lamp_socket_marker"][0], float(al["lantern_floor_y"]) + 1.6, mk["Lantern_arc_lamp_socket_marker"][2])), "eye height in the lamp room: it sees all round, for the ship's end")
	# places only the furnished rooms define (first floor, tower landings, shovel rack, ...)
	var rooms := get_parent().get_node_or_null("InteriorRooms")
	if rooms != null and rooms.get("anchors") is Dictionary:
		for role in rooms.anchors:
			if not anchors.has(role):
				_add(role, rooms.anchors[role], "a place in the furnished rooms (interior_rooms.gd)")


func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


func _add(role: String, world_pos: Vector3, note: String) -> void:
	# the furnished rooms (interior_rooms.gd) move some anchors to suit their layout
	var rooms := get_parent().get_node_or_null("InteriorRooms")
	if rooms != null and rooms.get("anchors") is Dictionary and (rooms.anchors as Dictionary).has(role):
		world_pos = rooms.anchors[role]
	var m := Marker3D.new()
	m.name = "LHI_Anchor_" + role
	m.set_meta("role", role)
	m.set_meta("note", note)
	m.add_to_group("lhi_anchor")
	add_child(m)
	m.global_position = world_pos
	anchors[role] = m
