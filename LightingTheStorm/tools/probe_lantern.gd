extends SceneTree
# probe_lantern.gd - the exterior model's lantern: wall radius per height, the roof's underside, and the gallery floor.
# Run: Godot --headless --path . --script res://tools/probe_lantern.gd
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
	print("outward hits (radius from axis) at local y, bearings 0..315 step 45:")
	for y in [17.95, 18.2, 18.6, 19.0, 19.6, 20.2, 20.8, 21.4, 21.9, 22.4, 23.0, 23.6]:
		var row := []
		for k in 8:
			var a := deg_to_rad(45.0 * k + 10.0)
			var d := Vector3(cos(a), 0, sin(a))
			var from := axis + Vector3(0, y, 0) + d * 0.7
			var r := sp.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + d * 5.0))
			row.append(snappedf(0.7 + from.distance_to(r["position"]), 0.01) if not r.is_empty() else -1.0)
		print("  y %.2f  %s" % [y, str(row)])
	print("upward hits (height above the lantern floor 17.9) at radius, bearing 10/100/190/280:")
	for rad in [0.8, 1.4, 2.0, 2.5, 2.9, 3.2]:
		var row2 := []
		for b in [10.0, 100.0, 190.0, 280.0]:
			var a2 := deg_to_rad(b)
			var from2 := axis + Vector3(cos(a2) * rad, 17.95, sin(a2) * rad)
			var r2 := sp.intersect_ray(PhysicsRayQueryParameters3D.create(from2, from2 + Vector3.UP * 12.0))
			row2.append(snappedf(r2["position"].y - OFF.y, 0.01) if not r2.is_empty() else -1.0)
		print("  r %.1f  roof underside local y: %s" % [rad, str(row2)])
	print("downward hits (local y of the floor) at radius:")
	for rad in [0.8, 1.4, 2.0, 2.5, 2.9, 3.3, 3.7]:
		var a3 := deg_to_rad(100.0)
		var from3 := axis + Vector3(cos(a3) * rad, 21.0, sin(a3) * rad)
		var r3 := sp.intersect_ray(PhysicsRayQueryParameters3D.create(from3, from3 + Vector3.DOWN * 5.0))
		print("  r %.1f  first surface below y21: %s" % [rad, str(snappedf(r3["position"].y - OFF.y, 0.01)) if not r3.is_empty() else "none"])
	quit()
	return false
