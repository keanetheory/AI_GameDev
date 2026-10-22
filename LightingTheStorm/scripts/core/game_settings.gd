# game_settings.gd - the GameSettings autoload: the player's brightness, sound levels and subtitles choice.
# Saved to user://settings.cfg, applied the moment it changes, and loaded before the first screen. The title screen's
# settings page (scripts/ui/settings_screen.gd) is the only thing that edits it.
#   brightness         0.6 .. 1.6, 1.0 = as designed. A full-screen multiply drawn over everything (this autoload's own
#                      CanvasLayer), so it works on the title, the settings page and the game alike.
#   music_volume       0 .. 1: the "Music" audio bus (background sound: the title's video sound, wind, rain, engine, music).
#   dialogue_volume    0 .. 1: the "Dialogue" audio bus (every spoken line). Both buses are made here if the project has none;
#                      new audio should be routed to them (AudioStreamPlayer.bus = "Music" / "Dialogue").
#   subtitles_enabled  the Subtitles autoload hides the spoken-line subtitles when this is off. The journal is unaffected.
extends Node

signal changed

const PATH := "user://settings.cfg"
const BUS_MUSIC := "Music"
const BUS_DIALOGUE := "Dialogue"
const BRIGHTNESS_MIN := 0.6
const BRIGHTNESS_MAX := 1.6
const SHADER := "
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float level = 1.0;
void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	// above 1: lift the picture (a gentle gamma, so highlights do not clip); below 1: darken it
	c = level >= 1.0 ? pow(c, vec3(1.0 / level)) : c * level;
	COLOR = vec4(c, 1.0);
}
"

var brightness := 1.0
var music_volume := 0.8
var dialogue_volume := 1.0
var subtitles_enabled := true

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_DIALOGUE)
	_build_overlay()
	load_settings()
	apply()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	brightness = clampf(float(cf.get_value("display", "brightness", brightness)), BRIGHTNESS_MIN, BRIGHTNESS_MAX)
	music_volume = clampf(float(cf.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	dialogue_volume = clampf(float(cf.get_value("audio", "dialogue_volume", dialogue_volume)), 0.0, 1.0)
	subtitles_enabled = bool(cf.get_value("accessibility", "subtitles", subtitles_enabled))


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("display", "brightness", brightness)
	cf.set_value("audio", "music_volume", music_volume)
	cf.set_value("audio", "dialogue_volume", dialogue_volume)
	cf.set_value("accessibility", "subtitles", subtitles_enabled)
	cf.save(PATH)


func set_brightness(v: float) -> void:
	brightness = clampf(v, BRIGHTNESS_MIN, BRIGHTNESS_MAX)
	apply()


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	apply()


func set_dialogue_volume(v: float) -> void:
	dialogue_volume = clampf(v, 0.0, 1.0)
	apply()


func set_subtitles_enabled(on: bool) -> void:
	subtitles_enabled = on
	apply()


## Push the values to the screen, the audio buses and everything listening, then save.
func apply() -> void:
	if _mat:
		_mat.set_shader_parameter("level", brightness)
		_rect.visible = absf(brightness - 1.0) > 0.005
	_set_bus(BUS_MUSIC, music_volume)
	_set_bus(BUS_DIALOGUE, dialogue_volume)
	changed.emit()
	save_settings()


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "BrightnessLayer"
	_layer.layer = 127
	add_child(_layer)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	_rect.visible = false
	_layer.add_child(_rect)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _set_bus(bus_name: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i >= 0:
		AudioServer.set_bus_mute(i, linear <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.001)))
