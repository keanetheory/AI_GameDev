# probe_window_face.gd - run: Godot --headless --path . --script res://tools/probe_window_face.gd -- <x> <y> <z>
# From a world point (a window's carve centre), rays in 16 horizontal directions: distance and normal of the first hit on the lighthouse
# exterior, so a surround can be placed on the real outer face.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 14:
		return false
	var a := OS.get_cmdline_user_args()
	var c := Vector3(float(a[0]), float(a[1]), float(a[2]))
	var sp := root.get_world_3d().direct_space_state
	var lh := root.get_node("Level/Lighthouse")
	for k in 16:
		var ang := TAU * k / 16.0
		var dir := Vector3(cos(ang), 0, sin(ang))
		var q := PhysicsRayQueryParameters3D.create(c, c + dir * 6.0)
		q.collision_mask = 1
		var r := sp.intersect_ray(q)
		var line := "dir %3d: " % int(rad_to_deg(ang))
		if r.is_empty() or not lh.is_ancestor_of(r["collider"]):
			line += "none"
		else:
			line += "%.2f m  normal (%.2f, %.2f, %.2f)" % [c.distance_to(r["position"]), r["normal"].x, r["normal"].y, r["normal"].z]
		print(line)
	quit()
	return false
