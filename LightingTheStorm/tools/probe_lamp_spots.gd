# probe_lamp_spots.gd - the deck height and the edges at candidate lamppost spots (island dock tips, Saltgate quay by the landing).
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 40:
		var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
		var ex: Array[RID] = [(_lv.get_node("Player") as CharacterBody3D).get_rid()]
		for z in [12.0, 13.0, 14.0, 14.7, 15.5, 16.5, 24.5, 25.5, 26.3, 27.0, 28.0, 29.0]:
			var row := []
			for x in [-40.0, -38.0, -36.0, -34.0, -32.0, -30.0, -28.0]:
				var q := PhysicsRayQueryParameters3D.create(Vector3(x, 8.0, z), Vector3(x, -3.0, z))
				q.exclude = ex
				var h := space.intersect_ray(q)
				row.append("-" if h.is_empty() else str(snappedf(h["position"].y, 0.1)))
			print("JETTY z=%.1f  x=-40..-28 step2: %s" % [z, row])
		var port: Node3D = null
		for zn in get_nodes_in_group("dock_zone"):
			if zn.zone_id == "DOCK_PORT":
				port = zn
		print("PORT zone ", port.global_position, " landing ", port.landing, " yaw ", port.berth_yaw_deg, " entrance ", port.entrance)
		var lp: Vector3 = port.landing
		for dz in [-6.0, -3.0, 0.0, 3.0, 6.0]:
			var row2 := []
			for dx in [-6.0, -3.0, 0.0, 3.0, 6.0]:
				var q2 := PhysicsRayQueryParameters3D.create(Vector3(lp.x + dx, lp.y + 8.0, lp.z + dz), Vector3(lp.x + dx, lp.y - 6.0, lp.z + dz))
				q2.exclude = ex
				var h2 := space.intersect_ray(q2)
				row2.append("-" if h2.is_empty() else str(snappedf(h2["position"].y, 0.1)))
			print("QUAY dz=%.0f dx=-6..6 step3: %s" % [dz, row2])
		quit()
	return false
