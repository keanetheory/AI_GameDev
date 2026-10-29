# probe_anchors.gd - prints the lighthouse interior anchors in world space (the places NPC routes aim for).
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	if _f == 12:
		var rooms := _lv.get_node("InteriorRooms")
		var a: Dictionary = rooms.anchors
		for k in a:
			print("ANCHOR %-22s %s" % [k, a[k]])
		var door := _lv.get_node("LighthouseDoor")
		print("DOOR middle ", door.middle(), " out ", door.global_transform.basis.z)
		for z in get_nodes_in_group("dock_zone"):
			print("DOCK ", z.zone_id, z.global_position, " berth yaw ", z.berth_yaw_deg)
		quit()
	return false
