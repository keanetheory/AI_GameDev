extends SceneTree
# probe_shell.gd - how far is the lighthouse's inner wall from the tower axis at each height, and where are the house walls?
# Run: Godot --headless --path . --script res://tools/probe_shell.gd

const OFF := Vector3(5, 9.61, -8.5)
var _f := 0

func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())

func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var sp := root.get_world_3d().direct_space_state
	var axis := OFF + Vector3(3.5, 0, 3.6)
	print("tower: height(local y) -> inner wall distance at bearings 0,45,...,315 (min/max)")
	for y in [2.0, 4.0, 5.2, 6.0, 7.0, 8.0, 9.4, 11.0, 13.0, 15.0, 17.0]:
		var ds := []
		for k in 8:
			var a := deg_to_rad(45.0 * k)
			var dirv := Vector3(cos(a), 0, sin(a)); var from := Vector3(axis.x, OFF.y + y + 1.0, axis.z) + dirv * 2.1
			var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(cos(a), 0, sin(a)) * 6.0)
			var r := sp.intersect_ray(q)
			ds.append(snappedf(2.1 + from.distance_to(r["position"]), 0.01) if not r.is_empty() else -1.0)
		print("  y %.1f  %s" % [y, str(ds)])
	quit()
	return false
