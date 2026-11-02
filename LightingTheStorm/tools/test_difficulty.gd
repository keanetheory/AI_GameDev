# test_difficulty.gd - run: Godot --headless --path . --script res://tools/test_difficulty.gd
# T60 (creator, 2 Nov 2026): the title screen's difficulty sets the hidden ship deadline: Easy 3:00, Medium 2:30, Hard 2:00.
#   1. a test-script run starts on Easy whatever the player saved; the route data holds the three lengths;
#   2. on the title, Right / Left (and the d-pad) step the difficulty without starting the game, stopping at the ends;
#   3. a click on a difficulty chooses it without starting the game, and the choice is saved in the settings file;
#   4. starting the game on Hard gives the level a 2:00 deadline.
# The player's own settings file is put back afterwards. Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const Deadline := preload("res://scripts/core/ship_deadline.gd")
const Route := preload("res://scripts/world/ship_route.gd")

var _step := 0
var _wait := 0
var _failed := 0
var _gs: Node
var _saved := ""
var _had_file := false


func _initialize() -> void:
	_gs = root.get_node("GameSettings")
	root.size = Vector2i(1600, 900)
	_had_file = FileAccess.file_exists(_gs.PATH)
	if _had_file:
		_saved = FileAccess.get_file_as_string(_gs.PATH)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_failed += 1


func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	Input.parse_input_event(e)


func _pad(b: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = true
	Input.parse_input_event(e)


func _physics_process(_d: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	var t := current_scene
	match _step:
		0:
			_check(_gs.difficulty == "easy", "a test-script run starts on Easy (%s)" % _gs.difficulty)
			var spec := Route.load_spec()
			var lens := {}
			for d in ["easy", "medium", "hard"]:
				_gs.difficulty = d
				lens[d] = Deadline.deadline_length(spec)
			_gs.difficulty = "easy"
			_check(is_equal_approx(lens["easy"], 180.0) and is_equal_approx(lens["medium"], 150.0) and is_equal_approx(lens["hard"], 120.0), "Easy 3:00, Medium 2:30, Hard 2:00 (%s)" % [lens])
			change_scene_to_file("res://scenes/Title.tscn")
			_wait = 40
		1:
			_check(t != null and t.name == "Title" and t.difficulty_buttons.size() == 3, "the title shows three difficulties")
			var names := []
			for d in t.difficulty_buttons:
				names.append(t.difficulty_buttons[d].text)
			_check(names == ["Easy", "Medium", "Hard"], "labelled %s, with no times shown (the deadline stays hidden)" % [names])
			var row: Control = t.get_node("Difficulty")
			# the headless window cannot be resized, so check what places it: anchored just below the prompt's band
			_check(row.anchor_top >= t.prompt.anchor_bottom and row.anchor_bottom <= 0.85, "the difficulty sits under the prompt")
			_key(KEY_RIGHT)
			_wait = 2
		2:
			_check(t.name == "Title" and _gs.difficulty == "medium", "Right steps to Medium and does not start the game")
			_key(KEY_RIGHT)
			_wait = 2
		3:
			_key(KEY_RIGHT)
			_wait = 2
		4:
			_check(t.name == "Title" and _gs.difficulty == "hard", "Right again: Hard, and it stops there")
			_pad(JOY_BUTTON_DPAD_LEFT)
			_wait = 2
		5:
			_check(t.name == "Title" and _gs.difficulty == "medium", "the d-pad steps it too")
			t.difficulty_buttons["easy"].pressed.emit()
			_wait = 2
		6:
			_check(t.name == "Title" and _gs.difficulty == "easy", "a click on Easy chooses it without starting the game")
			_check(t.difficulty_buttons["easy"].get_theme_color("font_color") == t.AMBER, "the chosen difficulty is shown in amber")
			t.difficulty_buttons["hard"].pressed.emit()
			var cf := ConfigFile.new()
			_check(cf.load(_gs.PATH) == OK and cf.get_value("gameplay", "difficulty", "") == "hard", "the choice is saved in the settings file")
			_key(KEY_ENTER)
			_wait = 90
		7:
			_check(t != null and t.name == "Level", "any other key still starts the game")
			var director: Node = root.get_node("GameState")._director
			_check(director != null and is_equal_approx(director.length_s, 120.0), "on Hard the level's deadline is 2:00 (%s s)" % (director.length_s if director else -1.0))
			_finish()
	_step += 1
	return false


func _finish() -> void:
	if _had_file:
		var f := FileAccess.open(_gs.PATH, FileAccess.WRITE)
		f.store_string(_saved)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_gs.PATH))
	print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
	quit(1 if _failed > 0 else 0)
