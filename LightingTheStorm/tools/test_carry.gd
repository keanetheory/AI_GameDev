# test_carry.gd - run: Godot --headless --path . --script res://tools/test_carry.gd
# The carry system (backlog T29) end to end in the real level, through the real E key:
#   1. one item at a time: with the burner in hand a second item cannot be taken;
#   2. nowhere to drop it: holding it, with no socket in reach, nothing is offered and no action puts it down;
#   3. the boat's cargo slot: standing on the deck facing it offers "[E] Put the burner down", E sets it down on the
#      deck, GameState still has the burner aboard, and that E did not also board the launch;
#   4. a stowed burner survives a hazard recovery and goes with the boat (same slot, still on the deck);
#   5. boarding and casting off work with the burner stowed (RETURN_DEPARTED fires);
#   6. ashore again at the lighthouse landing, E takes it back into the hands; it is in view and the slot is empty;
#   7. holding it, steering/boarding/casting off and a hazard recovery leave it in the hands;
#   8. a restart clears the hands.
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
			_check(_boat.cargo != null and _boat.cargo.get_parent() == _boat.get_node("Rig"), "the boat has a cargo slot on its rig")
			_stand_at(_burner.global_position + Vector3(1.5, 0.0, 0.0), _burner.global_position + Vector3.UP * 0.45)
			_next(5)
		1:
			Input.action_press("interact")   # pick the burner up
			_next(3)
		2:
			var model: Node3D = _burner.get_node_or_null("Model")
			_check(_carry.is_holding() and _burner.held, "E picked the burner up into the hands")
			_check(_carry.held_kind == "burner", "it is a burner ('%s')" % _carry.held_kind)
			var other := Node3D.new()
			root.add_child(other)
			_check(not _carry.hold(other, "crate", "crate", Vector3.ZERO, Vector3.ZERO, 1.0), "a second item cannot be taken: one item at a time")
			other.queue_free()
			_check(not _burner.can_interact(_player), "the pickup spot is no longer offered")
			# 2. nowhere to drop it: a spot with no socket in reach
			_stand_at(_burner.global_position + Vector3(0.0, 0.0, -4.0), _burner.global_position + Vector3(0.0, 1.0, -8.0))
			_next(5)
		3:
			_check(_im.focus == null, "holding it with no socket in reach, nothing is offered ('%s')" % _im._label.text)
			var drop_actions := InputMap.get_actions().filter(func(a): return not String(a).begins_with("ui_") and (String(a).contains("drop") or String(a).contains("put")))
			_check(drop_actions.is_empty(), "there is no drop action in the input map")
			# 3. at the Saltgate the berth is about 12 m from the landing, so stowing means walking to the boat: stand on
			# the deck beside the slot, facing it
			var slot: Node3D = _boat.cargo
			_stand_at(slot.global_position + _boat.global_transform.basis.z * -1.0 + Vector3.UP * 0.05, slot.global_position + Vector3.UP * 0.4)
			_next(8)
		4:
			_check(_im.focus == _boat.cargo, "standing on the deck facing the slot offers it")
			_check(_im._label.text == "[E] Put the burner down", "prompt reads '%s'" % _im._label.text)
			Input.action_press("interact")
			_next(4)
		5:
			var model: Node3D = _boat.cargo.item
			_check(model != null and model.get_parent() == _boat.cargo, "E set the burner down in the cargo slot")
			if model == null:
				print("RESULT: FAILED (stopping: nothing was stowed)")
				quit(1)
				return false
			_check(not _carry.is_holding() and not _burner.held, "the hands are empty")
			_check(_gs.burner_aboard, "GameState still has the burner aboard")
			_check(not _boat.driving, "that E did not also board the launch")
			_check(_gs.fired.has("BURNER_PICKED_UP"), "BURNER_PICKED_UP was reported once, on the pickup")
			# the item sits on the deck: a ray down from above the slot should reach the deck close below it
			var space := _boat.get_world_3d().direct_space_state
			var q := PhysicsRayQueryParameters3D.create(model.global_position + Vector3.UP * 1.0, model.global_position + Vector3.DOWN * 2.0, 1)
			var hit := space.intersect_ray(q)
			var gap: float = model.global_position.y - hit["position"].y if not hit.is_empty() else 99.0
			_check(not hit.is_empty() and absf(gap) < 0.25, "the burner rests on the deck (%.2f m above it)" % gap)
			# 5. board and cast off, burner stowed: look away from the slot, near the boat
			_stand_at(_boat.global_position + Vector3(0.0, 4.0, 7.0), _boat.global_position + Vector3(0.0, 4.0, 40.0))
			_next(5)
		6:
			_check(_im.focus == null, "away from the slot nothing else is offered")
			Input.action_press("interact")   # board
			_next(5)
		7:
			_check(_boat.driving, "E boarded the launch with the burner stowed")
			Input.action_press("interact")   # cast off
			_next(10)
		8:
			_check(_gs.fired.has("RETURN_DEPARTED") and _gs.phase_name() == "RETURN", "casting off fired RETURN_DEPARTED (%s)" % _gs.phase_name())
			# 4. a hazard recovery moves the boat and the cargo goes with it
			var model: Node3D = _boat.cargo.item
			var before_local: Vector3 = _boat.to_local(model.global_position)
			_boat._recover()
			_check(_boat._stun > 0.0, "the recovery ran (the boat is held still for %.1f s)" % _boat._stun)
			_check(model.get_parent() == _boat.cargo and _boat.cargo.item == model, "the burner is still in the cargo slot after a recovery")
			_check(_boat.to_local(model.global_position).distance_to(before_local) < 0.6, "it is still in the same place on the deck after a recovery")
			# 6. back at the lighthouse: dock, step ashore, take it back
			var home := _zone("DOCK_LIGHTHOUSE")
			_boat.global_position = Vector3(home.global_position.x, 0.0, home.global_position.z)
			_boat.rotation.y = deg_to_rad(home.berth_yaw_deg)
			_boat.state = _boat.State.DOCKED
			_boat.current_zone = home
			_boat.disembark()
			_check(not _boat.driving, "disembarked at the lighthouse dock")
			_next(6)   # let the deck's collision follow the boat to the new berth before standing on it
		9:
			var slot: Node3D = _boat.cargo
			_stand_at(_zone("DOCK_LIGHTHOUSE").landing, slot.global_position + Vector3.UP * 0.4)
			_next(8)
		10:
			_check(_im._label.text == "[E] Pick up the burner", "prompt reads '%s'" % _im._label.text)
			Input.action_press("interact")
			_next(4)
		11:
			var cam: Camera3D = _player.get_node("Head/Camera3D")
			var model: Node3D = cam.get_node_or_null("Model")
			_check(_carry.is_holding() and model != null, "E took the burner back into the hands")
			_check(_boat.cargo.item == null, "the cargo slot is empty again")
			if model:
				var size := cam.get_viewport().get_visible_rect().size
				var centre := model.global_position + model.global_transform.basis.y * 0.45
				var px := cam.unproject_position(centre)
				_check(not cam.is_position_behind(centre) and px.y > size.y * 0.5 and px.y < size.y, "it is in the lower half of the view (y=%.0f of %.0f)" % [px.y, size.y])
			# 7. holding it: board, cast off and a recovery leave it in the hands
			_stand_at(_boat.global_position + Vector3(0.0, 4.0, 7.0), _boat.global_position + Vector3(0.0, 4.0, 40.0))
			_next(5)
		12:
			Input.action_press("interact")   # board while holding
			_next(5)
		13:
			_check(_boat.driving and _carry.is_holding(), "boarded the launch holding the burner")
			_boat._recover()
			_check(_carry.is_holding() and _player.get_node("Head/Camera3D").get_node_or_null("Model") != null, "a hazard recovery leaves it in the hands")
			# 8. restart clears the hands
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
