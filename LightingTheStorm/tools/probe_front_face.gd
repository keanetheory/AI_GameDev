# probe_front_face.gd - run: Godot --headless --path . --script res://tools/probe_front_face.gd
# The exterior's front wall around the main door, as a depth map: rays from 4 m outside, level and straight at the wall, on a grid of house-frame
# u (along the wall) and heights; prints the distance of the first hit as z (house frame: +z is outward from the door's plane). A smooth facade panel
# must stand at or beyond the largest z to hide every lump.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 16:
		return false
	var frame: Node3D = root.get_node("Level/InteriorRooms").frame
	var lh := root.get_node("Level/Lighthouse")
	var sp := root.get_world_3d().direct_space_state
	var gf := 0.97
	var hdr := "u:     "
	for i in 13:
		hdr += "%5.2f " % (-3.0 + 0.5 * i)
	print(hdr)
	for yi in range(0, 11):
		var y := gf + 0.3 + 0.4 * yi
		var line := "y%5.2f " % (y - gf)
		for i in 13:
			var u := -3.0 + 0.5 * i
			var o := frame.to_global(Vector3(u, y, 4.0))
			var t := frame.to_global(Vector3(u, y, -1.5))
			var q := PhysicsRayQueryParameters3D.create(o, t)
			q.collision_mask = 1
			var r := sp.intersect_ray(q)
			if r.is_empty() or not lh.is_ancestor_of(r["collider"]):
				line += "  --- "
			else:
				line += "%5.2f " % frame.to_local(r["position"]).z
		print(line)
	quit()
	return false
