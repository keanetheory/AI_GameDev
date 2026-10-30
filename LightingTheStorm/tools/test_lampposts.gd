# test_lampposts.gd - run: Godot --headless --path . --script res://tools/test_lampposts.gd
# T36: the three dock lampposts (scripts/world/lampposts.gd, data/world/lampposts.json) in the real level: two on the island dock, one
# either side of the harbour opening on the jetty tips; one at the Saltgate quay by the landing. Each stands on the ground, is 3.4 m
# tall, has a collider and a warm light that is only on while the player is near; none blocks a berth or the opening.
extends SceneTree

var _lv: Node
var _f := 0
var _fails := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 60:
		_run()
		quit(1 if _fails > 0 else 0)
	return false


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null or mi.material_override != null and mi.mesh is SphereMesh:
			continue
		var b: AABB = mi.global_transform * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


func _run() -> void:
	var lp: Node = _lv.get_node("Lampposts")
	_check(lp != null and lp.posts.size() == 3, "three lampposts are placed (%d)" % lp.posts.size())
	var by_id := {}
	for p in lp.posts:
		by_id[String(p["node"].name)] = p
	var north: Node3D = by_id["Lamppost_IslandDock_North"]["node"]
	var south: Node3D = by_id["Lamppost_IslandDock_South"]["node"]
	var salt: Node3D = by_id["Lamppost_Saltgate_Dock"]["node"]
	# the island pair: either side of the opening, at the jetty tips
	_check(absf(north.global_position.y - 1.5) < 0.4 and absf(south.global_position.y - 1.5) < 0.4, "both island lamps stand on the jetty decks (y %.2f and %.2f)" % [north.global_position.y, south.global_position.y])
	var berth: Node3D = null
	var port: Node3D = null
	for z in get_nodes_in_group("dock_zone"):
		if z.zone_id == "DOCK_LIGHTHOUSE" and berth == null:
			berth = z
		if z.zone_id == "DOCK_PORT":
			port = z
	var mid := (north.global_position.z + south.global_position.z) * 0.5
	_check(absf(north.global_position.x - south.global_position.x) < 0.5 and south.global_position.z - north.global_position.z > 10.0, "one each side of the harbour opening, level with each other (%.1f m apart)" % (south.global_position.z - north.global_position.z))
	_check(absf(mid - 20.5) < 1.0, "centred on the opening between the two jetties (middle z %.1f)" % mid)
	_check(north.global_position.x < berth.global_position.x - 4.0, "out at the jetty tips, outboard of the berths")
	# the Saltgate lamp
	var landing: Vector3 = port.landing
	var d2 := Vector2(salt.global_position.x - landing.x, salt.global_position.z - landing.z).length()
	_check(d2 < 6.0 and absf(salt.global_position.y - landing.y) < 1.2, "the Saltgate lamp stands on the quay by the landing, %.1f m from it (y %.2f, landing %.2f)" % [d2, salt.global_position.y, landing.y])
	_check(Vector2(salt.global_position.x - port.global_position.x, salt.global_position.z - port.global_position.z).length() < 12.0, "and beside the berth where the launch docks")
	# the model
	var box := _aabb(north)
	_check(absf(box.size.y - 3.4) < 0.15 and absf(box.position.y - north.global_position.y) < 0.1, "the post is 3.4 m tall and stands on its base (%.2f m)" % box.size.y)
	# a collider
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	var sq := PhysicsShapeQueryParameters3D.new()
	var probe := SphereShape3D.new()
	probe.radius = 0.1
	sq.shape = probe
	sq.transform = Transform3D(Basis(), north.global_position + Vector3(0.0, 1.0, 0.0))
	var found := false
	for h in space.intersect_shape(sq, 8):
		if (h["collider"] as Node).get_parent() == north:
			found = true
	_check(found, "the post has a solid collider (nobody walks through it)")
	# the light: on only near the player
	var player: Node3D = _lv.get_node("Player")
	player.global_position = north.global_position + Vector3(8, 1, 0)
	lp._process(0.016)
	_check(by_id["Lamppost_IslandDock_North"]["light"].visible and not by_id["Lamppost_Saltgate_Dock"]["light"].visible, "near the island dock its lamps are lit and the Saltgate's light is off")
	player.global_position = salt.global_position + Vector3(6, 1, 0)
	lp._process(0.016)
	_check(by_id["Lamppost_Saltgate_Dock"]["light"].visible and not by_id["Lamppost_IslandDock_North"]["light"].visible, "at the Saltgate the other way round")
	_check(by_id["Lamppost_Saltgate_Dock"]["head"].visible, "every lamp head stays lit (it shows from the sea)")
	var l0: float = by_id["Lamppost_Saltgate_Dock"]["light"].light_energy
	lp._process(0.4)
	_check(absf(by_id["Lamppost_Saltgate_Dock"]["light"].light_energy - l0) > 0.001, "the gas light flickers")
	var lit := 0
	for n in _lv.find_children("*", "OmniLight3D", true, false):
		if (n as OmniLight3D).is_visible_in_tree():
			lit += 1
	print("     live OmniLights with the player at the Saltgate: %d (Lighting budget max_dynamic_lights 16, see handoff)" % lit)
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
