# probe_outside.gd - run: Godot --headless --path . --script res://tools/probe_outside.gd
# Lists every interior mesh (InteriorRooms, hero props, trim, kit) whose bounds stick out past the house's walls (house frame u -3.3..5.6, v 0.2..9.2),
# above the basement: the things that show through the exterior wall from outside.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 16:
		return false
	var rooms := root.get_node("Level/LighthouseInterior" if OS.get_cmdline_user_args().has("greybox") else "Level/InteriorRooms")
	var frame: Node3D = root.get_node("Level/InteriorRooms").frame
	var out := []
	for n in rooms.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var b := mi.mesh.get_aabb()
		var minu := 1e9
		var maxu := -1e9
		var minv := 1e9
		var maxv := -1e9
		var ytop := -1e9
		for i in 8:
			var c := frame.to_local(mi.global_transform * b.get_endpoint(i))
			minu = minf(minu, c.x)
			maxu = maxf(maxu, c.x)
			minv = minf(minv, -c.z)
			maxv = maxf(maxv, -c.z)
			ytop = maxf(ytop, c.y)
		if ytop < 0.5:
			continue
		var tower := String(mi.get_path()).contains("TowerShell") or String(mi.get_path()).contains("LampRoom") or String(mi.get_path()).contains("SpiralDown") or String(mi.get_path()).contains("TowerLandings")
		if tower:
			continue
		if minu < -3.3 or maxu > 5.65 or minv < 0.1 or maxv > 9.25:
			out.append([String(mi.get_path()).trim_prefix("/root/Level/InteriorRooms/"), snappedf(minu, 0.01), snappedf(maxu, 0.01), snappedf(minv, 0.01), snappedf(maxv, 0.01), snappedf(ytop, 0.01)])
	print("outside the walls: %d" % out.size())
	for o in out:
		print("  ", o)
	quit()
	return false
