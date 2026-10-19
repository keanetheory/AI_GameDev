# test_interaction.gd - run: Godot --headless --path . --script res://tools/test_interaction.gd
# Checks the interaction system (scripts/interaction/) with the real Player scene on a small floor, no level:
#  1. facing an interactable in reach: it is offered with the prompt "[E] <text>", and E uses it once;
#  2. looking away, standing too far, or `enabled = false` offers nothing and E does nothing;
#  3. with two in reach, the nearer one in the middle of the view wins;
#  4. an override of can_interact() and prompt_text() is respected;
#  5. nothing is offered or used while seated in the boat, or while the manager is blocked.
# Exit code 0 = all checks passed.
extends SceneTree

const BASE := "res://scripts/interaction/interactable.gd"
const DYNAMIC := "extends \"res://scripts/interaction/interactable.gd\"\nvar open := false\nvar ready_to_use := true\nfunc can_interact(_p: Node3D) -> bool:\n\treturn ready_to_use\nfunc prompt_text() -> String:\n\treturn \"Close it\" if open else \"Open it\"\nfunc interact(p: Node3D) -> void:\n\topen = not open\n\tinteracted.emit(p)\n"

var _fails := 0
var _uses := 0
var _player: CharacterBody3D
var _im: Node


func _initialize() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		_fails += 1


func _make(script_path: String, pos: Vector3, label: String) -> Node3D:
	var n := Node3D.new()
	n.set_script(load(script_path))
	n.prompt = label
	n.position = pos
	n.interacted.connect(func(_p): _uses += 1)
	root.add_child(n)
	return n


func _press_e() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	await physics_frame


func _run() -> void:
	await process_frame   # in script mode the autoloads' _ready has not run yet inside _initialize
	_im = root.get_node_or_null("Interaction")
	_check(_im != null, "the Interaction autoload exists")
	if _im == null:
		quit(1)
		return
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	root.add_child(floor_body)
	_player = load("res://scenes/Player.tscn").instantiate()
	root.add_child(_player)
	_player.global_position = Vector3.ZERO   # faces -Z, camera at 1.6 m
	await physics_frame
	await physics_frame

	# 1. one interactable straight ahead, 1.5 m away
	var lever := _make(BASE, Vector3(0, 0, -1.5), "Pull the lever")
	await physics_frame
	await physics_frame
	_check(_im.focus == lever, "facing it in reach: it is the focus")
	_check(_im._label.text == "[E] Pull the lever", "prompt reads '%s'" % _im._label.text)
	await _press_e()
	_check(_uses == 1, "E uses it once (%d)" % _uses)

	# 2. cases that must offer nothing
	_player.rotate_y(PI)   # look away
	await physics_frame
	await physics_frame
	_check(_im.focus == null and _im._label.text == "", "looking away offers nothing")
	var before := _uses
	await _press_e()
	_check(_uses == before, "E does nothing when nothing is offered")
	_player.rotate_y(PI)
	lever.reach = 1.0   # now 1.5 m away is too far
	await physics_frame
	await physics_frame
	_check(_im.focus == null, "out of reach offers nothing")
	lever.reach = 2.5
	lever.enabled = false
	await physics_frame
	await physics_frame
	_check(_im.focus == null, "enabled = false offers nothing")
	lever.enabled = true

	# 3. two in reach: the nearer, more central one wins
	var far_one := _make(BASE, Vector3(0.6, 0, -2.2), "Far one")
	await physics_frame
	await physics_frame
	_check(_im.focus == lever, "the nearer, more central one wins")
	lever.enabled = false
	await physics_frame
	await physics_frame
	_check(_im.focus == far_one, "when it is disabled the other one is offered")
	lever.enabled = true
	far_one.queue_free()

	# 4. overridden can_interact and prompt_text
	var dyn_script := GDScript.new()
	dyn_script.source_code = DYNAMIC
	dyn_script.reload()
	lever.enabled = false
	var door := Node3D.new()
	door.set_script(dyn_script)
	door.position = Vector3(0, 0, -1.2)
	door.interacted.connect(func(_p): _uses += 1)
	root.add_child(door)
	await physics_frame
	await physics_frame
	_check(_im._label.text == "[E] Open it", "dynamic prompt '%s'" % _im._label.text)
	before = _uses
	await _press_e()
	_check(_uses == before + 1 and door.open, "its interact() override ran")
	await physics_frame
	_check(_im._label.text == "[E] Close it", "prompt follows state ('%s')" % _im._label.text)
	door.ready_to_use = false
	await physics_frame
	await physics_frame
	_check(_im.focus == null, "can_interact() override hides it")
	door.ready_to_use = true

	# 5. seated in the boat, and blocked
	_player.set("boat", Node3D.new())
	await physics_frame
	await physics_frame
	_check(_im.focus == null, "nothing is offered while seated in the boat")
	before = _uses
	await _press_e()
	_check(_uses == before, "E does nothing while seated in the boat")
	_player.set("boat", null)
	_im.blocked = true
	await physics_frame
	await physics_frame
	_check(_im.focus == null, "nothing is offered while blocked")
	_im.blocked = false
	await physics_frame
	await physics_frame
	_check(_im.focus == door, "offered again once unblocked")

	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(0 if _fails == 0 else 1)
