extends SceneTree
# probe_tower_radii.gd - the tower's inner wall radius (from the axis) every 15 degrees at chosen heights, for sizing floors
# that must reach the wall. Prints one line per height: the radius per bearing, -1 where nothing is hit.
# Run: Godot --headless --path . --script res://tools/probe_tower_radii.gd -- <local y> [<local y> ...]
const OFF := Vector3(5, 9.61, -8.5)
var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var ys := []
	for a in OS.get_cmdline_user_args():
		ys.append(float(a))
	var sp := root.get_world_3d().direct_space_state
	var axis := OFF + Vector3(3.5, 0, 3.6)
	for y in ys:
		var row := []
		for k in 24:
			var a := deg_to_rad(15.0 * k)
			var d := Vector3(cos(a), 0, sin(a))
			var from := axis + Vector3(0, y, 0) + d * 2.15
			var r := sp.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + d * 3.0))
			row.append(snappedf(2.15 + from.distance_to(r["position"]), 0.01) if not r.is_empty() else -1.0)
		print("y %.2f %s" % [y, str(row)])
	quit()
	return false
