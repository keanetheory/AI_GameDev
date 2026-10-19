# test_subtitles.gd - run: Godot --headless --path . --script res://tools/test_subtitles.gd
# Checks the Subtitles autoload (scripts/ui/subtitle_ui.gd) by driving the Dialogue autoload's signals:
#  1. line_started shows the subtitle (speaker prefix intact) and line_finished hides it;
#  2. journal_entry_added writes the entry once (a repeat id is ignored) and shows the "Journal updated" note;
#  3. the journal action (J) opens and closes the journal panel;
#  4. assist_hint stays hidden while Dialogue.assist_mode is off and shows when it is on;
#  5. GameState.restarted clears the subtitle and the journal;
#  6. the real opening dialogue: GAME_STARTED shows Ted's first line and writes JRN_01.
# Exit code 0 = all checks passed.
extends SceneTree

var _fails := 0


func _initialize() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		_fails += 1


func _run() -> void:
	await process_frame   # in script mode the autoloads' _ready has not run yet inside _initialize
	var ui: Node = root.get_node_or_null("Subtitles")
	var dl: Node = root.get_node_or_null("Dialogue")
	var gs: Node = root.get_node_or_null("GameState")
	_check(ui != null and dl != null and gs != null, "Subtitles, Dialogue and GameState autoloads exist")
	if ui == null or dl == null or gs == null:
		quit(1)
		return
	gs.debug_log = false
	_check(InputMap.has_action("journal"), "the 'journal' input action exists")

	# 1. subtitles
	_check(not ui.subtitle_label.visible, "no subtitle at the start")
	dl.line_started.emit("T_01", "TED", "TED: Hrmph. In.", "gruff")
	_check(ui.subtitle_label.visible and ui.subtitle_label.text == "TED: Hrmph. In.", "line_started shows the subtitle with the speaker")
	dl.line_started.emit("A_01", "ARTHUR", "ARTHUR: Watch the water.", "")
	_check(ui.subtitle_label.text == "ARTHUR: Watch the water.", "the next line replaces it")
	dl.line_finished.emit("A_01")
	_check(not ui.subtitle_label.visible and ui.subtitle_label.text == "", "line_finished hides it")

	# 2. journal entries
	_check(ui.entries.is_empty() and ui.notice_label.modulate.a == 0.0, "journal empty and no note at the start")
	dl.journal_entry_added.emit("JRN_X", "Shovel coal.")
	_check(ui.entries.size() == 1 and ui.journal_text.text.contains("Shovel coal."), "journal_entry_added writes the entry")
	_check(ui.notice_label.modulate.a > 0.9, "the 'Journal updated' note shows")
	dl.journal_entry_added.emit("JRN_X", "Shovel coal.")
	_check(ui.entries.size() == 1, "a repeated journal id is ignored")
	dl.journal_entry_added.emit("JRN_Y", "Open the gate.")
	_check(ui.entries.size() == 2 and ui.journal_text.text.find("Shovel") < ui.journal_text.text.find("Open"), "entries keep their order")

	# 3. the journal key
	_check(not ui.journal_panel.visible, "journal closed at the start")
	_press("journal")
	await process_frame
	_check(ui.journal_panel.visible, "J opens the journal")
	_release("journal")
	await process_frame
	_press("journal")
	await process_frame
	_check(not ui.journal_panel.visible, "J closes it again")
	_release("journal")

	# 4. the assist hint
	dl.assist_mode = false
	dl.assist_hint.emit(1, "Go down the stairs.")
	_check(not ui.hint_label.visible, "assist hint stays hidden while assist mode is off")
	dl.assist_mode = true
	dl.assist_hint.emit(1, "Go down the stairs.")
	_check(ui.hint_label.visible and ui.hint_label.text == "Go down the stairs.", "assist hint shows when assist mode is on")
	dl.assist_mode = false
	dl.line_finished.emit("X")
	_check(not ui.hint_label.visible, "the hint goes with the line")

	# 5. restart
	dl.line_started.emit("T_02", "TED", "TED: Again.", "")
	ui.journal_panel.visible = true
	gs.restarted.emit()
	_check(not ui.subtitle_label.visible and ui.entries.is_empty() and not ui.journal_panel.visible, "restart clears subtitle, journal and panel")

	# 6. the real opening dialogue through GameState
	var level := Node3D.new()
	level.name = "FakeLevel"
	root.add_child(level)
	await create_timer(1.5).timeout   # TED_S1_01 has a 1 s pause before it
	_check(ui.subtitle_label.visible and ui.subtitle_label.text.begins_with("TED:"), "GAME_STARTED shows Ted's first line ('%s')" % ui.subtitle_label.text.left(30))
	_check(ui.entries.size() == 1 and ui.entries[0]["id"] == "JRN_01", "GAME_STARTED writes JRN_01")

	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(0 if _fails == 0 else 1)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _release(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
