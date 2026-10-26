# probe_tower_outside.gd - run: Godot --headless --path . --script res://tools/probe_tower_outside.gd
# Visible meshes of the interior (and the light cards) that reach past the tower's outer wall between world heights 12 and 34:
# the horizontal reach from the tower axis (world 8.5, -4.9) of every bounding-box corner, with the mesh's material colour.
extends SceneTree

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var lv := root.get_node("Level")
	var out := []
	for rn in ["InteriorRooms", "RoomLightCards", "ExteriorOpenings", "RainShelter"]:
		var r := lv.get_node_or_null(rn)
		if r == null:
			continue
		for n in r.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree():
				continue
			var b := mi.mesh.get_aabb()
			var reach := 0.0
			var ymin := 1e9
			var ymax := -1e9
			for i in 8:
				var c := mi.global_transform * b.get_endpoint(i)
				reach = maxf(reach, Vector2(c.x - 8.5, c.z + 4.9).length())
				ymin = minf(ymin, c.y)
				ymax = maxf(ymax, c.y)
			if reach > 3.0 and reach < 7.0 and ymax > 14.0 and ymin < 34.0 and not String(mi.get_path()).contains("HouseFrame") and not String(mi.get_path()).contains("Door"):
				var col := "-"
				var m := mi.material_override
				if m == null and mi.mesh.get_surface_count() > 0:
					m = mi.mesh.surface_get_material(0)
				if m is StandardMaterial3D:
					col = str((m as StandardMaterial3D).albedo_color)
				out.append([snappedf(reach, 0.01), snappedf(ymin, 0.1), snappedf(ymax, 0.1), String(mi.get_path()).trim_prefix("/root/Level/"), col])
	out.sort_custom(func(a, b): return a[0] > b[0])
	for o in out.slice(0, 40):
		print("  ", o)
	quit()
	return false
