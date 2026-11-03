extends SceneTree
# Film the FAL barograph (lhi_barograph.glb, placed by hero_props.gd on the L2 side table) from the player's view, with a slow
# turn, so the video shows a generated model in its place in the level.
var _lv: Node
var _f := 0
var _target: Node3D
var _player: CharacterBody3D
var _base_yaw := 0.0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _find() -> Node3D:
	for n in _lv.find_children("*", "Node3D", true, false):
		var nm := String(n.name).to_lower()
		if nm.contains("barograph") and n is Node3D and (n as Node3D).is_visible_in_tree():
			return n
	return null


func _process(_d: float) -> bool:
	_f += 1
	if _player == null:
		_player = _lv.get_node_or_null("Player")
	if _f == 45:
		_target = _find()
		if _target == null:
			print("FILM: no barograph found")
			return false
		var t: Vector3 = _target.global_position
		print("FILM: barograph at ", t, " (", _target.get_path(), ")")
		var centre := Vector3(8.5, t.y, -4.9)   # the tower's axis: stand inside, between the barograph and the stairwell
		var away: Vector3 = (centre - t).normalized()
		var stand: Vector3 = t + away * 1.3
		stand.y = t.y - 1.0
		_player.global_position = stand
		var look: Vector3 = t - stand
		_base_yaw = atan2(-look.x, -look.z)
		_player.rotation.y = _base_yaw
	if _target != null and _f > 45:
		_player.velocity = Vector3.ZERO
		var t: Vector3 = _target.global_position
		var eye: Vector3 = _player.get_node("Head").global_position
		var flat := Vector2(t.x - eye.x, t.z - eye.z).length()
		_player.get_node("Head").rotation.x = atan2(t.y - eye.y + 0.05, flat)
		_player.rotation.y = _base_yaw + deg_to_rad(6.0) * sin(float(_f - 45) / 60.0)
	return false
