# interaction_manager.gd - the Interaction autoload (backlog T03).
# One place that reads the "interact" action for on-foot use, so several interactables near each other never fire
# together and only one prompt is ever on screen. Each physics frame it asks every node in the "interactable" group
# (see interactable.gd) how good a target it is, offers the best one, and on E calls its interact().
#
# What it does not do:
#  - It stays quiet while the player is seated in the boat. The boat keeps its own E (board, cast off), so keep
#    interactables outside the boat's board_radius.
#  - It does not decide what happens. Interactables report to GameState themselves (GameState.emit_event(...)).
#  - Existing scripts (door.gd, burner_pickup.gd, boat.gd) still run their own prompts until they are converted.
extends Node

signal focus_changed(target: Node3D)
signal used(target: Node3D)

## Turn the whole system off (for example during a cutscene or the fail screen).
var blocked := false
var focus: Node3D = null

var _player: Node3D
var _camera: Camera3D
var _label: Label


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PromptLayer"
	layer.layer = 5
	_label = Label.new()   # same look as the boat's, door's and burner's prompts
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.position.y = -130.0
	layer.add_child(_label)
	add_child(layer)


func _physics_process(_delta: float) -> void:
	_find_player()
	var best: Node3D = null
	if not blocked and _player != null and _camera != null and _player.get("boat") == null:
		var best_score := INF
		for n in get_tree().get_nodes_in_group("interactable"):
			if not n.has_method("focus_score"):
				continue
			var s: float = n.focus_score(_player, _camera)
			if s >= 0.0 and s < best_score:
				best_score = s
				best = n
	_set_focus(best)
	if focus != null and Input.is_action_just_pressed("interact"):
		var target := focus
		target.interact(_player)
		used.emit(target)


func prompt_for(target: Node3D) -> String:
	return "[%s] %s" % [action_label("interact"), target.prompt_text()]


## The key shown for an action, read from the input map so a rebind (or a glyph for a controller) changes it here only.
func action_label(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		var key := ev as InputEventKey
		if key != null:
			var code: Key = key.keycode
			if code == KEY_NONE:   # bound by physical key: show what that key is labelled on this keyboard layout
				code = key.physical_keycode
				if DisplayServer.get_name() != "headless":   # the headless server does not support the lookup
					code = DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
			var text := OS.get_keycode_string(code)
			if text != "":
				return text
	return "E"


func _set_focus(target: Node3D) -> void:
	if target != focus:
		focus = target
		focus_changed.emit(focus)
	_label.text = prompt_for(focus) if focus != null else ""


func _find_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	_player = get_tree().get_first_node_in_group("player")
	_camera = _player.get_node_or_null("Head/Camera3D") if _player else null
