# test_door.gd - run: Godot --headless --path . --script res://tools/test_door.gd
# The lighthouse's main entry door, driven through the real E key (the "interact" action):
#   1. standing in the porch facing the door, the prompt reads "[E] Open the door";
#   2. walking forward with the door shut, the player cannot get through the doorway;
#   3. E opens it, and walking forward now takes the player through the doorway;
#   4. E (facing it again) closes it.
# The interior greybox is removed for this test so only the door and the exterior's doorway are checked.
# Exits 0 when every check passes, 1 otherwise.
extends SceneTree

var _lv: Node
var _door: Node3D
var _player: CharacterBody3D
var _gs: Node
var _f := 0
var _step := 0
var _wait := 0
var _failed := 0
var _start := Vector3.ZERO


func _initialize() -> void:
	Engine.set_meta("skip_intro", true)      # these tests use the front door as an ordinary door; the knock opening is tested in test_intro_sequence.gd
	_lv = load("res://scenes/Level.tscn").instantiate()
	_lv.get_node("LighthouseInterior").free()
	root.add_child(_lv)
	_door = _lv.get_node("LighthouseDoor")
	_player = _lv.get_node("Player")


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
			_stand_in_porch()
			_next(20)
		1:
			_check(_prompt() == "[E] Open the door", "prompt in the porch ('%s')" % _prompt())
			_start = _player.global_position
			Input.action_press("move_forward")
			_next(90)   # 1.5 s of walking at the door
		2:
			Input.action_release("move_forward")
			_check(_through() < 0.05, "a shut door blocks the doorway (%.2f m past the door line)" % _through())
			_stand_in_porch()
			_next(10)
		3:
			Input.action_press("interact")
			_next(60)   # let it swing
		4:
			_check(_door.is_open, "E opened the door")
			Input.action_press("move_forward")
			_next(90)
		5:
			Input.action_release("move_forward")
			_check(_through() > 0.8, "with the door open the player walks through (%.2f m past the door line)" % _through())
			_stand_in_porch()
			_next(10)
		6:
			_check(_prompt() == "[E] Close the door", "prompt offers to close it ('%s')" % _prompt())
			Input.action_press("interact")
			_next(60)
		7:
			_check(not _door.is_open, "E closed it again")
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	if _f > 3000:
		print("FAIL: TIMEOUT in step ", _step)
		quit(1)
	return false


## The one prompt on screen is owned by the Interaction autoload.
func _prompt() -> String:
	return root.get_node("Interaction")._label.text


## In the porch, 1.2 m out from the door, facing it.
func _stand_in_porch() -> void:
	var m: Vector3 = _door.middle()
	var out: Vector3 = _door.global_transform.basis.z
	_player.velocity = Vector3.ZERO
	_player.global_position = m + out * 1.2 + Vector3.UP * 0.05
	_player.look_at(_player.global_position - out, Vector3.UP)
	_player.get_node("Head").rotation.x = 0.0


## How far past the door's outer face the player is (positive = inside).
func _through() -> float:
	var out: Vector3 = _door.global_transform.basis.z
	return (_door.middle() - _player.global_position).dot(out)


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1
