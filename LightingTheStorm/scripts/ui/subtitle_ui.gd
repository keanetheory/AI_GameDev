# subtitle_ui.gd - the Subtitles autoload (backlog T12): speaker-attributed subtitles and the player's journal.
# It only listens to the Dialogue autoload (scripts/dialogue/dialogue_loader.gd) and GameState; it never drives story
# progress. No timer and no quest markers (Pillars 2 and 3):
#   - line_started   -> the subtitle appears at the bottom of the view (the text already carries "TED:", "ARTHUR:" ...)
#   - line_finished  -> it disappears
#   - journal_entry_added -> the entry is written into the journal and a quiet "Journal updated" note shows briefly;
#     J (the "journal" action) opens and closes the journal, which does not pause the game
#   - assist_hint    -> a dim hint under the subtitle, only while Dialogue.assist_mode is on (off by default)
#   - GameState.restarted -> everything is cleared for the new attempt
extends Node

const JOURNAL_ACTION := "journal"
const PAPER := Color(0.82, 0.75, 0.6)
const INK := Color(0.16, 0.1, 0.06)
const SPEAKER_COLOURS := {"TED": Color(0.96, 0.82, 0.55), "ARTHUR": Color(0.7, 0.82, 0.92), "DANIEL": Color(0.85, 0.85, 0.85)}

var subtitle_label: Label
var hint_label: Label
var notice_label: Label
var journal_panel: PanelContainer
var journal_text: Label
var entries: Array = []   # {id, text}, in the order they were written

var _dialogue: Node
var _notice_tween: Tween


func _ready() -> void:
	_build_ui()
	_dialogue = get_node_or_null("/root/Dialogue")
	if _dialogue == null:
		push_error("Subtitles: the Dialogue autoload is missing (project.godot [autoload])")
	else:
		_dialogue.line_started.connect(_on_line_started)
		_dialogue.line_finished.connect(_on_line_finished)
		_dialogue.journal_entry_added.connect(_on_journal_entry)
		_dialogue.assist_hint.connect(_on_assist_hint)
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.restarted.connect(_on_restarted)
	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		settings.changed.connect(func(): if not _subtitles_on(): subtitle_label.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(JOURNAL_ACTION) and not event.is_echo():
		toggle_journal()
		get_viewport().set_input_as_handled()


func toggle_journal() -> void:
	journal_panel.visible = not journal_panel.visible


func _on_line_started(_line_id: String, speaker: String, subtitle: String, _delivery: String) -> void:
	subtitle_label.text = subtitle
	subtitle_label.add_theme_color_override("font_color", SPEAKER_COLOURS.get(speaker.to_upper(), Color.WHITE))
	subtitle_label.visible = _subtitles_on()


## The player's subtitles choice (settings screen). The journal and the hint line are not subtitles and ignore it.
func _subtitles_on() -> bool:
	var gs := get_node_or_null("/root/GameSettings")
	return gs == null or gs.subtitles_enabled


func _on_line_finished(_line_id: String) -> void:
	subtitle_label.visible = false
	subtitle_label.text = ""
	hint_label.visible = false


func _on_assist_hint(_step: int, text: String) -> void:
	if _dialogue != null and _dialogue.assist_mode:
		hint_label.text = text
		hint_label.visible = true


func _on_journal_entry(journal_id: String, text: String) -> void:
	for e in entries:
		if e["id"] == journal_id:
			return
	entries.append({"id": journal_id, "text": text})
	_refresh_journal()
	_show_notice()


func _on_restarted() -> void:
	entries.clear()
	_refresh_journal()
	subtitle_label.visible = false
	subtitle_label.text = ""
	hint_label.visible = false
	journal_panel.visible = false
	notice_label.modulate.a = 0.0


func _refresh_journal() -> void:
	var parts: Array = []
	for e in entries:
		parts.append(e["text"])
	journal_text.text = "\n\n".join(parts) if not parts.is_empty() else "(Nothing written yet.)"


func _show_notice() -> void:
	if _notice_tween:
		_notice_tween.kill()
	notice_label.modulate.a = 1.0
	_notice_tween = create_tween()
	_notice_tween.tween_interval(3.5)
	_notice_tween.tween_property(notice_label, "modulate:a", 0.0, 1.5)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SubtitleLayer"
	layer.layer = 10
	add_child(layer)

	subtitle_label = _label(26, 6)
	subtitle_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle_label.custom_minimum_size.x = 840      # narrow enough to clear the controls list in the lower right (guidance_hud.gd)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	subtitle_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	subtitle_label.position.y = -50.0
	subtitle_label.visible = false
	layer.add_child(subtitle_label)

	hint_label = _label(18, 4)
	hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint_label.position.y = -20.0
	hint_label.modulate = Color(1, 1, 1, 0.6)
	hint_label.visible = false
	layer.add_child(hint_label)

	notice_label = _label(18, 4)
	notice_label.text = "Journal updated  [J]"
	# upper right, below the goal tracker (guidance_hud.gd) so the two never overlap
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	notice_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	notice_label.offset_top += 120.0
	notice_label.offset_bottom += 120.0
	notice_label.modulate.a = 0.0
	layer.add_child(notice_label)

	journal_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_content_margin_all(28)
	style.set_corner_radius_all(3)
	journal_panel.add_theme_stylebox_override("panel", style)
	journal_panel.set_anchors_preset(Control.PRESET_CENTER)
	journal_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	journal_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	journal_panel.custom_minimum_size = Vector2(620, 0)
	journal_panel.visible = false
	journal_text = Label.new()
	journal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_text.custom_minimum_size.x = 560
	journal_text.add_theme_font_size_override("font_size", 24)
	journal_text.add_theme_color_override("font_color", INK)
	var hand := SystemFont.new()   # a handwritten face if the machine has one, otherwise the default font
	hand.font_names = PackedStringArray(["Segoe Script", "Bradley Hand", "Ink Free", "Comic Sans MS"])
	journal_text.add_theme_font_override("font", hand)
	journal_panel.add_child(journal_text)
	layer.add_child(journal_panel)
	_refresh_journal()


func _label(size: int, outline: int) -> Label:
	var l := Label.new()   # same look as the boat's prompt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	return l
