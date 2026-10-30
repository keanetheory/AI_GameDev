# shot_ted.gd - run (needs a window): Godot --path . --script res://tools/shot_ted.gd -- <out.png>
# A still of Ted as the game spawns him, standing at the origin, camera in front of him on the -Z side (the way he should face).
extends SceneTree

var _f := 0
var _out := "user://ted.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	var holder := Node3D.new()
	root.add_child(holder)
	(load("res://scripts/character/npc.gd") as GDScript).spawn(holder, "TED", Vector3.ZERO)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 200, 0)
	root.add_child(light)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0.6, 1.5, -3.2), Vector3(0, 1.0, 0))
	cam.current = true


func _process(_d: float) -> bool:
	_f += 1
	if _f == 30:
		root.get_texture().get_image().save_png(_out)
		quit()
	return false
