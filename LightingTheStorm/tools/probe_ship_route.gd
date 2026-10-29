# probe_ship_route.gd - run: Godot --headless --path . --script res://tools/probe_ship_route.gd
# Prints the world-space bounds of the island, the sea rocks, the ship and the lighthouse so the ship route
# (data/world/ship_route.json) can be laid out against them.
extends SceneTree


func _aabb_of(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for k in c.get_children():
			stack.append(k)
		var mi := c as MeshInstance3D
		if mi and mi.mesh:
			var b: AABB = mi.global_transform * mi.get_aabb()
			out = b if first else out.merge(b)
			first = false
	return out


var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	if _f == 12:
		_report(_lv)
		quit()
	return false


func _report(lv: Node) -> void:
	for path in ["Island", "RockPatchSE", "RockPatchNE", "Lighthouse", "PassengerShip", "Harbour"]:
		var n := lv.get_node_or_null(path)
		if n:
			print("%-14s %s" % [path, _aabb_of(n)])
	for r in lv.get_node("SeaRocks").get_children():
		var b := _aabb_of(r)
		print("%-14s centre (%.1f, %.1f, %.1f) size (%.1f, %.1f, %.1f)" % [r.name, b.get_center().x, b.get_center().y, b.get_center().z, b.size.x, b.size.y, b.size.z])
	var env := lv.get_node("WorldEnvironment") as WorldEnvironment
	if env and env.environment:
		print("fog enabled %s density %s depth_end %s" % [env.environment.fog_enabled, env.environment.fog_density, env.environment.volumetric_fog_enabled])
	var cam := lv.get_viewport().get_camera_3d()
	print("camera far:", cam.far if cam else "none")
