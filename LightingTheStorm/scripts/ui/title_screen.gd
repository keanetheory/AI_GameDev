# title_screen.gd - the title screen: the storm video looping behind the game's title, "(press any button to start)", and a
# settings cog in the bottom right. Any key, mouse button or gamepad button starts the game (the Level scene, as it is now:
# when the start of the game changes, change START_SCENE). The cog opens the settings screen instead.
# The video has no sound track (removed on request; the title music comes later and should play on the "Music" bus).
# The lettering is the splash screen's own title, cut out of INTRO_SPLASH_SCREEN.png (Assets/UI/title_logo.png), so it is the
# same typeface; the prompt is a serif italic like the splash's tagline.
extends Control

const START_SCENE := "res://scenes/Level.tscn"
const SETTINGS_SCENE := "res://scenes/Settings.tscn"
const VIDEO := "res://Assets/UI/title_background.ogv"
const LOGO := "res://Assets/UI/title_logo.png"
const COG := "res://Assets/UI/settings_cog.png"
const SILVER := Color(0.725, 0.745, 0.769)
const AMBER := Color(0.753, 0.478, 0.118)

## Ignore keys for the first moments, so a held key from the launcher or a stray press does not skip the screen.
@export var input_grace_s := 0.35

var video: VideoStreamPlayer
var prompt: Label
var cog: TextureButton
var _t := 0.0
var _starting := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	video.play()


func _build() -> void:
	video = VideoStreamPlayer.new()
	video.name = "Video"
	video.stream = load(VIDEO)
	video.set_anchors_preset(Control.PRESET_FULL_RECT)
	video.expand = true
	video.loop = true
	video.bus = "Music"
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(video)
	# a soft dark band behind the title and the prompt so the lettering reads over the bright sky
	var shade := TextureRect.new()
	shade.name = "Shade"
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.anchor_top = 0.28
	shade.anchor_bottom = 0.78
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	# the title, centred
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = load(LOGO)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.anchor_left = 0.17
	logo.anchor_right = 0.83
	logo.anchor_top = 0.38
	logo.anchor_bottom = 0.60
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	# "(press any button to start)" underneath
	prompt = Label.new()
	prompt.name = "Prompt"
	prompt.text = "(press any button to start)"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.anchor_left = 0.2
	prompt.anchor_right = 0.8
	prompt.anchor_top = 0.62
	prompt.anchor_bottom = 0.7
	prompt.add_theme_font_override("font", serif(true))
	prompt.add_theme_font_size_override("font_size", 30)
	prompt.add_theme_color_override("font_color", SILVER)
	prompt.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06))
	prompt.add_theme_constant_override("outline_size", 8)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	# the settings cog, bottom right
	cog = TextureButton.new()
	cog.name = "SettingsCog"
	cog.texture_normal = load(COG)
	cog.ignore_texture_size = true
	cog.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	cog.custom_minimum_size = Vector2(64, 64)
	cog.anchor_left = 1.0
	cog.anchor_right = 1.0
	cog.anchor_top = 1.0
	cog.anchor_bottom = 1.0
	cog.offset_left = -96.0
	cog.offset_right = -32.0
	cog.offset_top = -96.0
	cog.offset_bottom = -32.0
	cog.modulate = Color(1, 1, 1, 0.8)
	cog.tooltip_text = "Settings"
	cog.pressed.connect(open_settings)
	cog.mouse_entered.connect(func(): cog.modulate = Color(1, 1, 1, 1.0))
	cog.mouse_exited.connect(func(): cog.modulate = Color(1, 1, 1, 0.8))
	add_child(cog)


## A serif face like the splash's tagline (Georgia where it exists, else the nearest serif the system has).
static func serif(italic := false) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Book Antiqua", "Times New Roman", "serif"])
	f.font_italic = italic
	return f


func _process(delta: float) -> void:
	_t += delta
	if prompt:
		prompt.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 2.2))


func _input(event: InputEvent) -> void:
	if _starting or _t < input_grace_s:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		pressed = event.pressed and not cog.get_global_rect().has_point(event.position)
	elif event is InputEventJoypadButton:
		pressed = event.pressed
	if pressed:
		get_viewport().set_input_as_handled()
		start_game()


func start_game() -> void:
	if _starting:
		return
	_starting = true
	get_tree().change_scene_to_file(START_SCENE)


func open_settings() -> void:
	if _starting:
		return
	_starting = true
	get_tree().change_scene_to_file(SETTINGS_SCENE)
