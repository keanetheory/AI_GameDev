# probe_gallery.gd - run: Godot --headless --path . --script res://tools/probe_gallery.gd
# Height profile of the exterior's lantern gallery (deck, rail, posts): rays straight down at radii round the tower, several bearings.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 12:
		return false
	var sp := root.get_world_3d().direct_space_state
	var c := Vector3(8.5, 0, -4.9)
	for b in [0, 45, 90, 135, 180, 225, 270, 315]:
		var line := "bearing %3d: " % b
		for r10 in range(28, 58, 2):
			var r := r10 / 10.0
			var o := c + Vector3(cos(deg_to_rad(b)) * r, 40.0, sin(deg_to_rad(b)) * r)
			var q := PhysicsRayQueryParameters3D.create(o, o + Vector3(0, -20.0, 0))
			q.collision_mask = 1
			var h := sp.intersect_ray(q)
			line += "%.1f:%s " % [r, "-" if h.is_empty() else "%.2f" % (h["position"].y - 9.61)]
		print(line)
	quit()
	return false
