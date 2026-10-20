# test_interior_lights.gd - run: Godot --headless --path . --script res://tools/test_interior_lights.gd
# The lighting spec allows 8 dynamic lights and 2 shadow casters for the scene. The interior has 15 lights; this proves
# interior_lights.gd keeps no more than 6 lit and no more than 2 casting shadows wherever the player stands, and that
# there is light where the player is (a dark room would be a different bug).
extends SceneTree

var _lv: Node
var _player: Node3D
var _lights: Node
var _f := 0
var _spot := 0
var _wait := 0
var _fails := 0
# name, world position
var _spots := [["outside the door", Vector3(-2.0, 10.7, 4.0)], ["entry hall", Vector3(0.6, 10.8, -1.5)], ["boiler room", Vector3(-1.0, 7.8, -3.6)],
	["stairs, low", Vector3(7.0, 14.0, -3.0)], ["stairs, high", Vector3(7.5, 24.0, -4.0)], ["lamp room", Vector3(8.5, 28.6, -4.9)], ["far out on the island", Vector3(-40.0, 2.0, 30.0)]]


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_player = _lv.get_node("Player")
	_lights = _lv.get_node("LighthouseInteriorLights")


func _ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_fails += 1


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	if _wait == 0:
		_player.global_position = _spots[_spot][1]
		_player.velocity = Vector3.ZERO
	_wait += 1
	if _wait < 50:           # long enough for the lights to fade to their targets
		_player.global_position = _spots[_spot][1]
		return false
	var live: int = _lights.live_count()
	var sh: int = _lights.shadow_count()
	var name: String = _spots[_spot][0]
	_ok(live <= 6 and sh <= 2, "%s: %d interior lights lit (max 6), %d with shadows (max 2)" % [name, live, sh])
	if name != "far out on the island" and name != "outside the door":
		_ok(live >= 1, "%s: at least one light is on where the player is" % name)
	_spot += 1
	_wait = 0
	if _spot >= _spots.size():
		print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
		quit(1 if _fails > 0 else 0)
	return false
