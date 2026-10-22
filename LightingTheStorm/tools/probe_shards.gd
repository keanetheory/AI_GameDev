extends SceneTree
# probe_shards.gd - find pieces of the island or the exterior model that stick into the lighthouse's rooms: random rays
# from inside a room; any hit on a collider that belongs to the Island or Lighthouse nodes (not the interior) is a shard.
# usage: Godot --headless --path . --script res://tools/probe_shards.gd -- <u0> <u1> <v0> <v1> <y0> <y1>   (house frame)
const OFF := Vector3(5, 9.61, -8.5)
const SILL := Vector3(-3.494, 0.0, 8.874)
const U := Vector3(0.9024, 0.0, -0.4309)
const V := Vector3(-0.4309, 0.0, -0.9024)
var _f := 0


func _hw(u: float, y: float, v: float) -> Vector3:
	return OFF + SILL + U * u + V * v + Vector3(0, y, 0)


func _hf(p: Vector3) -> Vector3:
	var r := p - OFF - SILL
	return Vector3(r.dot(U), p.y - OFF.y, r.dot(V))


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var a := OS.get_cmdline_user_args()
	var b := [-2.1, 5.5, 0.5, 6.7, -1.9, 0.7]
	if a.size() >= 6:
		for i in 6:
			b[i] = float(a[i])
	var sp := root.get_world_3d().direct_space_state
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var hits := {}
	for i in 6000:
		var o := _hw(rng.randf_range(b[0], b[1]), rng.randf_range(b[4], b[5]), rng.randf_range(b[2], b[3]))
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var r := sp.intersect_ray(PhysicsRayQueryParameters3D.create(o, o + d * 4.0))
		if r.is_empty():
			continue
		var n: Node = r["collider"]
		var chain := ""
		var c := n
		while c != null and c != root:
			chain = String(c.name) + "/" + chain
			c = c.get_parent()
		if chain.contains("/Island/") or chain.contains("/Lighthouse/") or chain.contains("RockPatch"):
			var p := _hf(r["position"])
			var key := "%s  at u%.1f v%.1f y%.2f" % [chain.get_slice("/", 1) + "/" + chain.get_slice("/", 2), snappedf(p.x, 0.25), snappedf(p.z, 0.25), snappedf(p.y, 0.1)]
			hits[key] = hits.get(key, 0) + 1
	var keys := hits.keys()
	keys.sort()
	print("shards found: ", keys.size(), " distinct spots")
	for k in keys:
		print("  ", k, "  x", hits[k])
	quit()
	return false
