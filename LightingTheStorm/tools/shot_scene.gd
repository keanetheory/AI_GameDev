# shot_scene.gd - render a UI scene for a few seconds (video needs a window): Godot --path . --write-movie out.png --fixed-fps 10
# --quit-after 60 --script res://tools/shot_scene.gd -- res://scenes/Title.tscn
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var s := (load(a[0]) as PackedScene).instantiate()
	root.add_child(s)
