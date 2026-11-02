# shot_cam.gd - run (needs a window): Godot --path . --script res://tools/shot_cam.gd -- <out.png> <cx> <cy> <cz> <tx> <ty> <tz> [fov]
# A still of the real level from a free camera at (cx,cy,cz) looking at (tx,ty,tz); the player is left where it is and the HUD is hidden.
# For exterior checks from points the player cannot stand on (the back of the lighthouse, the sea).
extends SceneTree

var _f := 0
var _a: PackedStringArray
var _cam: Camera3D


func _initialize() -> void:
	_a = OS.get_cmdline_user_args()
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		_cam = Camera3D.new()
		_cam.fov = float(_a[7]) if _a.size() > 7 and _a[7].is_valid_float() else 70.0
		_cam.far = 4000.0
		root.add_child(_cam)
		_cam.global_position = Vector3(float(_a[1]), float(_a[2]), float(_a[3]))
		_cam.look_at(Vector3(float(_a[4]), float(_a[5]), float(_a[6])), Vector3.UP)
		_cam.make_current()
		var hud: Node = root.get_node("GameState").guidance()
		if hud:
			hud.visible = false
		for arg in _a:
			if arg.begins_with("hide="):
				for path in arg.trim_prefix("hide=").split(","):
					var n := root.get_node_or_null(path) as Node3D
					if n:
						n.visible = false
	if _f == 130:
		root.get_texture().get_image().save_png(_a[0])
		quit()
	return false
