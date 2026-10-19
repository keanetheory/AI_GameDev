# test_burner_pickup.gd - run: Godot --headless --path . --script res://tools/test_burner_pickup.gd
# The Saltgate pickup end to end, driven through the real E key (the "interact" action):
#   1. dock at DOCK_PORT (SALTGATE_REACHED) and step ashore at the landing;
#   2. walk up to the burner and face it: the prompt shows; E picks it up (BURNER_PICKED_UP);
#   3. the burner now rides in front of the camera, in the lower half of the view;
#   4. E boards the launch and E again casts off: RETURN_DEPARTED fires and the phase is RETURN,
#      with the burner still in the player's hands.
# Exits 0 when every check passes, 1 otherwise.
extends SceneTree

var _lv: Node
var _boat: Node3D
var _player: CharacterBody3D
var _burner: Node3D
var _gs: Node
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
			_check(_gs != null, "GameState autoload is present")
			var port := _zone("DOCK_PORT")
			_boat.global_position = Vector3(port.global_position.x, 0.0, port.global_position.z)
			_boat.rotation.y = deg_to_rad(port.berth_yaw_deg)
			_boat.state = _boat.State.DOCKED
			_boat.current_zone = port
			_boat.docked.emit("DOCK_PORT")          # what arriving at the quays reports
			_player.global_position = port.landing   # stepped ashore
			_next(10)
		1:
			_check(_gs.fired.has("SALTGATE_REACHED"), "SALTGATE_REACHED on docking at the quays")
			var land: Vector3 = _zone("DOCK_PORT").landing
			var flat := Vector2(_burner.global_position.x - land.x, _burner.global_position.z - land.z).length()
			_check(flat > 1.5 and flat < 4.0, "the burner is a few steps from the landing (%.1f m)" % flat)
			var to_boat := Vector2(_burner.global_position.x - _boat.global_position.x, _burner.global_position.z - _boat.global_position.z).length()
			_check(to_boat > _boat.board_radius, "the burner is outside the boat's board radius, so one E cannot do both (%.1f m)" % to_boat)
			# walk up to it: stand 1.5 m away, facing it, looking a little down
			var from := _burner.global_position + Vector3(1.5, 0.0, 0.0)
			_player.global_position = from
			_player.look_at(Vector3(_burner.global_position.x, from.y, _burner.global_position.z), Vector3.UP)
			_player.get_node("Head").rotation.x = deg_to_rad(-25.0)
			_next(5)
		2:
			_check(root.get_node("Interaction")._label.text == "[E] Pick up the burner", "prompt shows next to the burner ('%s')" % root.get_node("Interaction")._label.text)
			Input.action_press("interact")
			_next(3)
		3:
			var cam: Camera3D = _player.get_node("Head/Camera3D")
			var model: Node3D = cam.get_node_or_null("Model")
			_check(_burner.held, "E picked the burner up")
			_check(model != null, "the burner model now rides on the camera")
			_check(_gs.burner_aboard and _gs.fired.has("BURNER_PICKED_UP"), "GameState got BURNER_PICKED_UP")
			_check(root.get_node("Interaction")._label.text == "", "the pickup prompt is gone")
			if model:
				var size := cam.get_viewport().get_visible_rect().size
				var centre := model.global_position + model.global_transform.basis.y * 0.45   # mid-height of the burner
				var px := cam.unproject_position(centre)
				_check(not cam.is_position_behind(centre) and px.y > size.y * 0.5 and px.y < size.y,
					"the held burner sits in the lower half of the view (y=%.0f of %.0f)" % [px.y, size.y])
			# walk to the berth: inside board radius
			_player.global_position = _boat.global_position + Vector3(0.0, 4.0, 7.0)
			_next(3)
		4:
			Input.action_press("interact")   # board
			_next(5)
		5:
			_check(_boat.driving, "E boarded the launch while holding the burner")
			Input.action_press("interact")   # cast off
			_next(10)
		6:
			_check(_gs.fired.has("RETURN_DEPARTED"), "casting off from DOCK_PORT with the burner fired RETURN_DEPARTED")
			_check(_gs.phase_name() == "RETURN", "phase is RETURN (%s)" % _gs.phase_name())
			_check(_burner.held and _player.get_node("Head/Camera3D").get_node_or_null("Model") != null, "the burner is still in hand on the boat")
			_gs.dump_log()
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	if _f > 3000:
		print("FAIL: TIMEOUT in step ", _step)
		quit(1)
	return false


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
