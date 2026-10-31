# shot_view.gd - run (needs a window): Godot --path . --script res://tools/shot_view.gd -- <out.png> <px> <py> <pz> <tx> <ty> <tz> [seconds]
# A still of the real level from the player standing at (px,py,pz) looking at (tx,ty,tz); the HUD is hidden. For lighting checks.
extends SceneTree

var _f := 0
var _a: PackedStringArray


func _initialize() -> void:
	_a = OS.get_cmdline_user_args()
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _process(_d: float) -> bool:
	_f += 1
	var gs := root.get_node("GameState")
	if _f == 20:
		var p := root.get_node("Level/Player") as CharacterBody3D
		p.global_position = Vector3(float(_a[1]), float(_a[2]), float(_a[3]))
		p.look_at(Vector3(float(_a[4]), p.global_position.y, float(_a[6])), Vector3.UP)
		var head := p.get_node("Head") as Node3D
		var eye := p.global_position + Vector3(0, 1.6, 0)
		var t := Vector3(float(_a[4]), float(_a[5]), float(_a[6]))
		head.rotation.x = atan2(t.y - eye.y, Vector2(t.x - eye.x, t.z - eye.z).length())
		var hud: Node = gs.guidance()
		if hud:
			hud.visible = false
	if _f == 130:
		root.get_texture().get_image().save_png(_a[0])
		quit()
	return false
