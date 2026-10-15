# debug_walk.gd - run: Godot --path . --script res://tools/debug_walk.gd
# Loads the level, holds a movement key and prints where the player ends up.
extends SceneTree

var _player: CharacterBody3D
var _frame := 0
var _start := Vector3.ZERO


func _initialize() -> void:
	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	_player = level.get_node("Player")


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 60:
		_start = _player.global_position
		print("settled at ", _start, " on_floor=", _player.is_on_floor())
		Input.action_press("move_forward")
	if _frame > 9999 and _frame % 3 == 0:
		print(_frame, " pos=", _player.global_position, " vel=", _player.velocity, " floor=", _player.is_on_floor(), " wall=", _player.is_on_wall(), " n=", _player.get_slide_collision_count())
	if _frame in [90, 200, 399]:
		print("frame ", _frame, " pos=", _player.global_position, " vel=", _player.velocity,
			" collisions=", _player.get_slide_collision_count())
		for i in _player.get_slide_collision_count():
			var c := _player.get_slide_collision(i)
			print("  hit ", c.get_collider(), " normal=", c.get_normal())
	if _frame == 150:
		var space := _player.get_world_3d().direct_space_state
		for h in [0.0, 0.1, 0.2, 0.3, 0.4, 0.9, 1.5]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(0, h, -1.5), Vector3(0, h, -4.0))
			q.exclude = [_player.get_rid()]
			var r := space.intersect_ray(q)
			print("ray h=", h, " -> ", r.get("position"), " ", r.get("collider"), " parent=", r["collider"].get_parent().get_parent().name if r.has("collider") else "")
	if _frame == 160:
		var sp := _player.get_world_3d().direct_space_state
		for z in [-0.5, -1.0, -1.5, -2.0, -2.5, -3.0, -4.0, -6.0]:
			var q2 := PhysicsRayQueryParameters3D.create(Vector3(0, 3.0, z), Vector3(0, -5.0, z))
			q2.exclude = [_player.get_rid()]
			var r2 := sp.intersect_ray(q2)
			print("down z=", z, " -> y=", r2["position"].y if r2.has("position") else "none")
	if _frame == 400:
		quit()
	return false
