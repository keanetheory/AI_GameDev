# settings_screen.gd - the settings page, opened from the title screen's cog. Brightness, background sound level, dialogue sound
# level, and a subtitles checkbox. Each control writes straight to the GameSettings autoload (scripts/core/game_settings.gd),
# which applies and saves it at once, so what the player hears and sees changes as they drag. Back returns to the title.
# The same page can be opened from a pause menu later: set `return_scene`.
extends Control

const TITLE_SCENE := "res://scenes/Title.tscn"
const SILVER := Color(0.725, 0.745, 0.769)
const AMBER := Color(0.753, 0.478, 0.118)
const GOLD := Color(0.722, 0.588, 0.18)

@export var return_scene := TITLE_SCENE

var brightness_slider: HSlider
var music_slider: HSlider
var dialogue_slider: HSlider
var subtitles_check: CheckBox
var back_button: Button
var _values: Dictionary = {}     # slider -> its percentage label
var _settings: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_settings = get_node_or_null("/root/GameSettings")
	_build()
	_load_values()


func _build() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.055, 0.057, 0.065)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.13, 0.96)
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 56
	sb.content_margin_right = 56
	sb.content_margin_top = 36
	sb.content_margin_bottom = 36
	panel.add_theme_stylebox_override("panel", sb)
	centre.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	col.custom_minimum_size = Vector2(620, 0)
	panel.add_child(col)

	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://scripts/ui/title_screen.gd").serif(false))
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", GOLD)
	col.add_child(title)
	col.add_child(HSeparator.new())

	brightness_slider = _row(col, "Brightness", GameSettingsRange.BRIGHT_MIN, GameSettingsRange.BRIGHT_MAX, 0.02, "BrightnessSlider")
	music_slider = _row(col, "Background sound", 0.0, 1.0, 0.01, "MusicSlider")
	dialogue_slider = _row(col, "Dialogue sound", 0.0, 1.0, 0.01, "DialogueSlider")

	subtitles_check = CheckBox.new()
	subtitles_check.name = "SubtitlesCheck"
	subtitles_check.text = "  Subtitles"
	subtitles_check.add_theme_font_override("font", load("res://scripts/ui/title_screen.gd").serif(false))
	subtitles_check.add_theme_font_size_override("font_size", 26)
	subtitles_check.add_theme_color_override("font_color", SILVER)
	subtitles_check.toggled.connect(func(on: bool): _settings.set_subtitles_enabled(on) if _settings else null)
	col.add_child(subtitles_check)
	col.add_child(HSeparator.new())

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(180, 48)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_override("font", load("res://scripts/ui/title_screen.gd").serif(false))
	back_button.add_theme_font_size_override("font_size", 26)
	back_button.pressed.connect(back)
	col.add_child(back_button)
	back_button.grab_focus()


func _row(col: VBoxContainer, label_text: String, lo: float, hi: float, step: float, node_name: String) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(240, 0)
	l.add_theme_font_override("font", load("res://scripts/ui/title_screen.gd").serif(false))
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", SILVER)
	row.add_child(l)
	var s := HSlider.new()
	s.name = node_name
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.custom_minimum_size = Vector2(240, 30)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(_on_slider.bind(s))
	row.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(70, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_size_override("font_size", 24)
	v.add_theme_color_override("font_color", AMBER)
	row.add_child(v)
	_values[s] = v
	return s


func _load_values() -> void:
	if _settings == null:
		return
	brightness_slider.set_value_no_signal(_settings.brightness)
	music_slider.set_value_no_signal(_settings.music_volume)
	dialogue_slider.set_value_no_signal(_settings.dialogue_volume)
	subtitles_check.set_pressed_no_signal(_settings.subtitles_enabled)
	for s in _values:
		_show(s)


func _on_slider(v: float, s: HSlider) -> void:
	if _settings:
		if s == brightness_slider:
			_settings.set_brightness(v)
		elif s == music_slider:
			_settings.set_music_volume(v)
		elif s == dialogue_slider:
			_settings.set_dialogue_volume(v)
	_show(s)


func _show(s: HSlider) -> void:
	(_values[s] as Label).text = "%d%%" % roundi(s.value * 100.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back()


func back() -> void:
	get_tree().change_scene_to_file(return_scene)


## The slider limits, mirrored from game_settings.gd (a script cannot read another script's const through an autoload name here).
class GameSettingsRange:
	const BRIGHT_MIN := 0.6
	const BRIGHT_MAX := 1.6
