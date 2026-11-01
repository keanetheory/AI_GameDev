# test_carry.gd - run: Godot --headless --path . --script res://tools/test_carry.gd
# The carry system (backlog T29) end to end in the real level, through the real E key:
#   1. one item at a time: with the burner in hand a second item cannot be taken;
#   2. nowhere to drop it: holding it, with no socket in reach, nothing is offered and no action puts it down;
#   3. not in the boat either: the launch has no cargo slot (creator, 1 Nov 2026: the burner is never put down between
#      the Saltgate hut and the lamp), so standing on its deck nothing is offered;
#   4. holding it, boarding, casting off (RETURN_DEPARTED) and a hazard recovery leave it in the hands;
#   5. a restart clears the hands.
# Exits 0 when every check passes, 1 otherwise.
extends SceneTree

var _lv: Node
var _boat: Node3D
var _player: CharacterBody3D
var _burner: Node3D
var _gs: Node
var _carry: Node
var _im: Node
var _f := 0
var _step := 0
var _wait := 0
var _failed := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_boat = _lv.get_node("Boat")
	_player = _lv.get_node("Player")
	_burner = _lv.get_node("BurnerPickup")
	_gs = root.get_node_or_null("GameState")
	_carry = root.get_node_or_null("Carry")
	_im = root.get_node_or_null("Interaction")


func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	Input.action_release("interact")
	match _step:
		0:
			_check(_carry != null and _im != null and _gs != null, "the Carry, Interaction and GameState autoloads exist")
			var port := _zone("DOCK_PORT")
			_boat.global_position = Vector3(port.global_position.x, 0.0, port.global_position.z)
			_boat.rotation.y = deg_to_rad(port.berth_yaw_deg)
			_boat.state = _boat.State.DOCKED
			_boat.current_zone = port
			_boat.docked.emit("DOCK_PORT")
			_check(_boat.get_node("Rig").find_children("*", "Node3D", true, false).all(func(n): return not n.has_signal("placed")),
				"the boat has no cargo slot (no CarrySocket on its rig)")
			# in the hut, between the workbench and the open front, facing the burner
			var hut := _lv.get_node("SaltgateHut") as Node3D
			var from := _burner.global_position - hut.global_transform.basis.z * 1.0
			from.y = hut.global_position.y
			_stand_at(from, _burner.global_position + Vector3.UP * 0.1)
			_next(5)
		1:
			Input.action_press("interact")   # pick the burner up
			_next(3)
		2:
			_check(_carry.is_holding() and _burner.held, "E picked the burner up into the hands")
			_check(_carry.held_kind == "burner", "it is a burner ('%s')" % _carry.held_kind)
			var other := Node3D.new()
			root.add_child(other)
			_check(not _carry.hold(other, "crate", "crate", Vector3.ZERO, Vector3.ZERO, 1.0), "a second item cannot be taken: one item at a time")
			other.queue_free()
			_check(not _burner.can_interact(_player), "the pickup spot is no longer offered")
			# 2. nowhere to drop it: the quay deck below the steps
			_stand_at(_zone("DOCK_PORT").landing, _zone("DOCK_PORT").landing + Vector3(0.0, 0.5, 4.0))
			_next(5)
		3:
			_check(_im.focus == null, "holding it with no socket in reach, nothing is offered ('%s')" % _im._label.text)
			var drop_actions := InputMap.get_actions().filter(func(a): return not String(a).begins_with("ui_") and (String(a).contains("drop") or String(a).contains("put")))
			_check(drop_actions.is_empty(), "there is no drop action in the input map")
			# 3. on the boat's deck, aft of the helm where the cargo slot used to be, looking down at it
			var aft: Vector3 = _boat.get_node("Rig").to_global(Vector3(0.0, 0.13, 0.3))
			_stand_at(aft, _boat.get_node("Rig").to_global(Vector3(0.0, 0.13, 1.3)))
			_next(8)
		4:
			_check(_im.focus == null and _im._label.text == "", "on the boat's deck nothing offers to take the burner ('%s')" % _im._label.text)
			_check(_carry.is_holding(), "still holding it")
			# 4. board and cast off holding it: look away from everything, near the boat
			_stand_at(_boat.global_position + Vector3(0.0, 4.0, 7.0), _boat.global_position + Vector3(0.0, 4.0, 40.0))
			_next(5)
		5:
			Input.action_press("interact")   # board while holding
			_next(5)
		6:
			_check(_boat.driving and _carry.is_holding(), "boarded the launch holding the burner")
			Input.action_press("interact")   # cast off
			_next(10)
		7:
			_check(_gs.fired.has("RETURN_DEPARTED") and _gs.phase_name() == "RETURN", "casting off fired RETURN_DEPARTED (%s)" % _gs.phase_name())
			_check(_carry.is_holding(), "still in the hands under way")
			_boat._recover()
			_check(_boat._stun > 0.0, "the recovery ran (the boat is held still for %.1f s)" % _boat._stun)
			var cam: Camera3D = _player.get_node("Head/Camera3D")
			var model: Node3D = cam.get_node_or_null("Model")
			_check(_carry.is_holding() and model != null, "a hazard recovery leaves it in the hands")
			if model:
				var size := cam.get_viewport().get_visible_rect().size
				var centre := model.global_position + model.global_transform.basis.y * 0.45
				var px := cam.unproject_position(centre)
				_check(not cam.is_position_behind(centre) and px.y > size.y * 0.5 and px.y < size.y, "it is in the lower half of the view (y=%.0f of %.0f)" % [px.y, size.y])
			# 5. restart clears the hands
			_gs.restarted.emit()
			_check(not _carry.is_holding(), "a restart clears the hands")
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	if _f > 4000:
		print("FAIL: TIMEOUT in step ", _step)
		quit(1)
	return false


## Stand `at` (feet), looking at `look_at_point`.
func _stand_at(at: Vector3, look_at_point: Vector3) -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = at
	var flat := Vector3(look_at_point.x, at.y, look_at_point.z)
	if flat.distance_to(at) > 0.01:
		_player.look_at(flat, Vector3.UP)
	var eye := at + Vector3.UP * 1.6
	var d := Vector2(look_at_point.x - eye.x, look_at_point.z - eye.z).length()
	_player.get_node("Head").rotation.x = atan2(look_at_point.y - eye.y, maxf(d, 0.01))


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1


func _zone(zone_id: String) -> Node3D:
	for z in get_nodes_in_group("dock_zone"):
		if z.zone_id == zone_id:
			return z
	return null
