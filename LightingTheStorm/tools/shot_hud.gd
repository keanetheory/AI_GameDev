# shot_hud.gd - run (needs a window): Godot --path . --script res://tools/shot_hud.gd -- <out.png> [ON_FOOT|AT_HELM] [goal events to fire, comma separated]
# A still of the real level with the guidance HUD (goal tracker upper right, controls lower right).
extends SceneTree

var _f := 0
var _out := "user://hud.png"
var _mode := "ON_FOOT"
var _events: PackedStringArray = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]
	if a.size() > 1:
		_mode = a[1]
	if a.size() > 2 and a[2] != "":
		_events = a[2].split(",")
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _process(_d: float) -> bool:
	_f += 1
	if _f == 60:
		for e in _events:
			root.get_node("GameState").emit_event(e)
		var hud: CanvasLayer = root.get_node("GameState").guidance()
		hud._set_mode(_mode)
		var sub := root.get_node_or_null("Subtitles")
		if sub:
			sub.notice_label.modulate.a = 1.0
	if _f == 120:
		var hud2: CanvasLayer = root.get_node("GameState").guidance()
		hud2._flash_left = 0.0
		hud2._show_goal(hud2.active_index())
	if _f == 160:
		root.get_texture().get_image().save_png(_out)
		quit()
	return false
