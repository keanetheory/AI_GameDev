# test_title_settings.gd - run: Godot --headless --path . --script res://tools/test_title_settings.gd
# The title screen and the settings page, through real input events:
#   1. the title is the project's main scene and shows the video (looping), the logo, the prompt and the cog;
#   2. a key press before the grace period does nothing; after it, any key starts the game (the Level scene);
#   3. a mouse button or a gamepad button starts it too, and a click on the cog opens settings instead;
#   4. the settings page has brightness, background sound, dialogue sound and a subtitles checkbox, filled from GameSettings;
#   5. moving each control changes GameSettings, the audio buses and the brightness overlay, and writes the settings file;
#   6. the subtitles checkbox hides the spoken-line subtitles (the Subtitles autoload) and shows them again;
#   7. Back returns to the title.
# Exits 0 when every check passes, 1 otherwise.
extends SceneTree

var _step := 0
var _f := 0
var _wait := 0
var _failed := 0
var _gs: Node
var _scene: Node


func _initialize() -> void:
	_gs = root.get_node("GameSettings")
	root.size = Vector2i(1600, 900)      # a headless script run starts with a 64 x 64 window


func _physics_process(_d: float) -> bool:
	_f += 1
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/Title.tscn", "the title is the project's main scene")
			_load("res://scenes/Title.tscn")
			_next(12)
		1:
			var t := current_scene
			_check(t != null and t.name == "Title", "the title scene is up")
			_check(not root.get_node("GameState").fired.has("GAME_STARTED"), "the title does not start the game (no GAME_STARTED, so no first line over the title)")
			_check(t.video != null and t.video.loop and t.video.stream != null and t.video.is_playing(), "the video is playing and loops")
			_check(t.get_node("Logo").texture != null, "the title lettering is shown")
			_check(t.cog.get_global_rect().size.x > 20, "the layout is up")
			_check(t.prompt.text == "(press any button to start)", "the prompt reads '%s'" % t.prompt.text)
			var r: Rect2 = t.prompt.get_global_rect()
			var lg: Rect2 = t.get_node("Logo").get_global_rect()
			_check(r.position.y >= lg.end.y - 2.0, "the prompt sits underneath the title")
			# the headless window cannot be resized, so check what places the cog: anchored to the bottom right corner, inset from it
			_check(t.cog.anchor_left == 1.0 and t.cog.anchor_top == 1.0 and t.cog.offset_right < 0.0 and t.cog.offset_bottom < 0.0, "the cog is anchored in the bottom right corner")
			_press_key(KEY_SPACE)     # inside the grace period
			_next(2)
		2:
			_check(current_scene != null and current_scene.name == "Title", "a key pressed in the first moments does nothing")
			_next(30)
		3:
			_press_key(KEY_ENTER)
			_next(8)
		4:
			_check(current_scene != null and current_scene.name == "Level", "any key starts the game (the Level scene, as it is now)")
			_check(root.get_node("GameState").fired.has("GAME_STARTED"), "the game starts when the level loads (GAME_STARTED)")
			_load("res://scenes/Title.tscn")
			_next(30)
		5:
			_press_pad(JOY_BUTTON_A)
			_next(8)
		6:
			_check(current_scene != null and current_scene.name == "Level", "a gamepad button starts the game")
			_load("res://scenes/Title.tscn")
			_next(30)
		7:
			var cog: Control = current_scene.cog
			_click(cog.get_global_rect().get_center())
			_next(8)
		8:
			_check(current_scene != null and current_scene.name == "Settings", "clicking the cog opens the settings page, not the game")
			var s := current_scene
			_check(s.brightness_slider != null and s.music_slider != null and s.dialogue_slider != null and s.subtitles_check != null, "the page has brightness, background sound, dialogue sound and a subtitles checkbox")
			_check(absf(s.music_slider.value - _gs.music_volume) < 0.001 and s.subtitles_check.button_pressed == _gs.subtitles_enabled, "the controls show the current settings")
			s.brightness_slider.value = 1.3
			s.music_slider.value = 0.4
			s.dialogue_slider.value = 0.65
			s.subtitles_check.button_pressed = false
			_next(2)
		9:
			_check(absf(_gs.brightness - 1.3) < 0.001, "brightness set (%.2f)" % _gs.brightness)
			_check(_gs._rect.visible and absf(float(_gs._mat.get_shader_parameter("level")) - 1.3) < 0.001, "the brightness overlay follows")
			var mi := AudioServer.get_bus_index("Music")
			var di := AudioServer.get_bus_index("Dialogue")
			_check(mi >= 0 and di >= 0, "the Music and Dialogue buses exist")
			_check(absf(db_to_linear(AudioServer.get_bus_volume_db(mi)) - 0.4) < 0.01, "background sound level set on the Music bus")
			_check(absf(db_to_linear(AudioServer.get_bus_volume_db(di)) - 0.65) < 0.01, "dialogue sound level set on the Dialogue bus")
			_check(not _gs.subtitles_enabled, "subtitles are off")
			var sub := root.get_node("Subtitles")
			sub._on_line_started("T1", "TED", "TED: hello", "")
			_check(not sub.subtitle_label.visible, "with subtitles off a spoken line shows no subtitle")
			_gs.set_subtitles_enabled(true)
			sub._on_line_started("T2", "TED", "TED: hello", "")
			_check(sub.subtitle_label.visible, "with subtitles on it does")
			sub._on_line_finished("T2")
			var cf := ConfigFile.new()
			_check(cf.load("user://settings.cfg") == OK and absf(float(cf.get_value("display", "brightness", 0.0)) - 1.3) < 0.001, "the settings were saved to the settings file")
			current_scene.back_button.pressed.emit()
			_next(8)
		10:
			_check(current_scene != null and current_scene.name == "Title", "Back returns to the title")
			# put the player's settings back
			_gs.set_brightness(1.0)
			_gs.set_music_volume(0.8)
			_gs.set_dialogue_volume(1.0)
			_gs.set_subtitles_enabled(true)
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	if _f > 3000:
		print("FAIL: TIMEOUT in step ", _step)
		quit(1)
	return false


func _load(path: String) -> void:
	if current_scene:
		current_scene.queue_free()
	var s := (load(path) as PackedScene).instantiate()
	root.add_child(s)
	current_scene = s


func _press_key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)


func _press_pad(btn: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	Input.parse_input_event(e)


func _click(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.global_position = pos
	e.pressed = true
	Input.parse_input_event(e)
	var u := e.duplicate() as InputEventMouseButton
	u.pressed = false
	Input.parse_input_event(u)


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1
