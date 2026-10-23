# probe_castoff.gd - run: Godot --headless --path . --script res://tools/probe_castoff.gd
# Boards the launch, casts off from the lighthouse berth with NO steering and hazards ON, and prints where it goes.
extends SceneTree

var _lv: Node
var _boat: Node3D
var _f := 0
var _t := 0.0
var _go := false
var _hits := 0
var _next_print := 0.0
var _last_xf := Transform3D.IDENTITY
var _reported := false


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_boat = _lv.get_node("Boat")
	Engine.time_scale = 5.0


func _physics_process(delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	if not _go:
		_go = true
		_lv.get_node("Player").global_position = _boat.current_zone.landing
		_boat.hazard_hit.connect(func(): _hits += 1)
		_boat.board()
		_boat.cast_off()
		print("cast off from ", _boat.current_zone.name, " at ", _boat.global_position, " yaw ", rad_to_deg(_boat.rotation.y))
	_t += delta
	if _hits == 0:
		_last_xf = _boat.global_transform
	elif not _reported:
		_reported = true
		var q := PhysicsShapeQueryParameters3D.new()
		var sh := BoxShape3D.new()
		sh.size = _boat.hull_size
		q.shape = sh
		q.collision_mask = 2
		# walk back from the first hit position (the boat has been shoved; the hit was ~ one step before its old place)
		print("first hit near x=", _last_xf.origin.x, " z=", _last_xf.origin.z)
		for dx in [0, -6, -12, -20]:
			q.transform = Transform3D(_last_xf.basis, _last_xf.origin + Vector3(dx, 0.9, 0))
			for h in _boat.get_world_3d().direct_space_state.intersect_shape(q, 4):
				var c: Object = h["collider"]
				var chain := ""
				var n: Node = c as Node
				for i in 5:
					chain += n.name + " < "
					n = n.get_parent()
				var cs := (c as Node).get_child(0) as CollisionShape3D
				print("  dx=", dx, " hits ", chain, " layer ", (c as CollisionObject3D).collision_layer, " shape aabb y ", cs.shape.get_debug_mesh().get_aabb().position.y if cs and cs.shape else "?")
	if _t >= _next_print:
		_next_print += 0.5
		print("t=%.1f pos=(%.1f, %.1f) yaw=%.0f vel=%.1f push=%s hits=%d state=%d stun=%.1f" % [_t, _boat.global_position.x, _boat.global_position.z, rad_to_deg(_boat.rotation.y), _boat.velocity.length(), str(_boat.water_push), _hits, _boat.state, _boat._stun])
	if _t > 16.0:
		quit()
		return true
	return false
