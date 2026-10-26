# probe_greybox_tower.gd - run: Godot --headless --path . --script res://tools/probe_greybox_tower.gd
# The v3 greybox shell's meshes that are still visible inside the tower (local y 5 to 18, within 4 m of the axis): name, height range, reach.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 16:
		return false
	var gb := root.get_node("Level/LighthouseInterior") as Node3D
	var out := []
	for n in gb.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var b := mi.mesh.get_aabb()
		var ymin := 1e9
		var ymax := -1e9
		var reach := 0.0
		for i in 8:
			var c := gb.to_local(mi.global_transform * b.get_endpoint(i))
			ymin = minf(ymin, c.y)
			ymax = maxf(ymax, c.y)
			reach = maxf(reach, Vector2(c.x - 3.5, c.z - 3.6).length())
		if ymax > 5.0 and ymin < 18.5 and reach < 4.6 and String(mi.name).begins_with("Tower"):
			out.append([String(mi.name), snappedf(ymin, 0.1), snappedf(ymax, 0.1), snappedf(reach, 0.1)])
	var kinds := {}
	for o in out:
		var k: String = String(o[0]).rstrip("0123456789_")
		kinds[k] = kinds.get(k, 0) + 1
	print("greybox tower meshes: %d" % out.size(), "  by kind: ", kinds)
	for o in out.slice(0, 12):
		print("  ", o)
	quit()
	return false
