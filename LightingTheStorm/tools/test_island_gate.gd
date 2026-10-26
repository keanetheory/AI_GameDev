# test_island_gate.gd - run: Godot --headless --path . --script res://tools/test_island_gate.gd
# The island gate at the top of the harbour stairs (scripts/world/island_gate.gd), driven through the real E key:
#   0. prints the ground under the gate's footprint (the model must sit on it, not float or sink);
#   1. on the lighthouse side facing the gate, the prompt reads "[E] Open the gate";
#   2. walking at the shut gate, the player cannot get through;
#   3. E opens it (before SAILORS_MOORED: no GATE_OPENED is reported) and the player walks through towards the dock;
#   4. E closes it; after SAILORS_MOORED, coming close reports GATE_APPROACHED and opening reports GATE_OPENED.
# Exits 0 when every check passes, 1 otherwise.
extends SceneTree

var _lv: Node
var _gate: Node3D
var _player: CharacterBody3D
var _gs: Node
var _f := 0
var _step := 0
var _wait := 0
var _failed := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_gate = _lv.get_node("IslandGate")
	_player = _lv.get_node("Player")
	_gs = root.get_node("GameState")


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
			_ground()
			_stand_behind()
			_next(20)
		1:
			_check(_prompt() == "[E] Open the gate", "prompt on the lighthouse side ('%s')" % _prompt())
			Input.action_press("move_forward")
			_next(90)
		2:
			Input.action_release("move_forward")
			_check(_through() < 0.05, "a shut gate blocks the gateway (%.2f m past the gate line)" % _through())
			_stand_behind()
			_next(10)
		3:
			Input.action_press("interact")
			_next(70)
		4:
			_check(_gate.is_open, "E opened the gate")
			_check(not _gs.fired.has("GATE_OPENED"), "no GATE_OPENED before the sailors have moored")
			Input.action_press("move_forward")
			_next(90)
		5:
			Input.action_release("move_forward")
			_check(_through() > 0.8, "with the gate open the player walks through (%.2f m past the gate line)" % _through())
			_stand_behind()
			_next(10)
		6:
			_check(_prompt() == "[E] Close the gate", "prompt offers to close it ('%s')" % _prompt())
			Input.action_press("interact")
			_next(70)
		7:
			_check(not _gate.is_open, "E closed it again")
			_player.global_position = _gate.middle() + Vector3(0, 0.05, -25)   # well away
			_gs.emit_event("SAILORS_MOORED")
			_next(5)
		8:
			_check(not _gs.fired.has("GATE_APPROACHED"), "no GATE_APPROACHED while the player is far away")
			_stand_behind()
			_next(10)
		9:
			_check(_gs.fired.has("GATE_APPROACHED"), "GATE_APPROACHED once the sailors are moored and the player comes close")
			Input.action_press("interact")
			_next(70)
		10:
			_check(_gate.is_open and _gs.fired.has("GATE_OPENED"), "opening it after SAILORS_MOORED reports GATE_OPENED")
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	if _f > 3000:
		print("FAIL: TIMEOUT in step ", _step)
		quit(1)
	return false


## Ground height under the gateway, the two pillars and the wall ends (rays from above, ignoring the gate itself).
func _ground() -> void:
	var sp := root.get_world_3d().direct_space_state
	var ex: Array[RID] = []
	for b in _gate.find_children("*", "CollisionObject3D", true, false):
		ex.append((b as CollisionObject3D).get_rid())
	var g := _gate.global_position
	for dx in [-1.8, -1.1, 0.0, 1.1, 1.8]:
		for dz in [-3.0, -1.5, -0.5, 0.0, 0.5]:
			var p := g + Vector3(dx, 0, dz)
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 30.0, p + Vector3.DOWN * 30.0)
			q.exclude = ex
			var r := sp.intersect_ray(q)
			var hit := "nothing" if r.is_empty() else "%.2f (%s)" % [r["position"].y, (r["collider"] as Node).name]
			print("ground  dx %+.1f dz %+.1f : %s   (gate base y %.2f)" % [dx, dz, hit, g.y])


func _prompt() -> String:
	return root.get_node("Interaction")._label.text


## On the lighthouse side (-Z of the gate), 1.3 m back from the gateway, facing the dock.
func _stand_behind() -> void:
	var m: Vector3 = _gate.middle()
	var fwd: Vector3 = _gate.global_transform.basis.z   # towards the dock
	_player.velocity = Vector3.ZERO
	_player.global_position = m - fwd * 1.3 + Vector3.UP * 0.1
	_player.look_at(_player.global_position + fwd, Vector3.UP)
	_player.get_node("Head").rotation.x = 0.0


## How far past the gate line the player is, towards the dock.
func _through() -> float:
	var fwd: Vector3 = _gate.global_transform.basis.z
	return (_player.global_position - _gate.middle()).dot(fwd)


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1
