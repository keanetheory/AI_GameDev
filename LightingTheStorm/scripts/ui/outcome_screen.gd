# outcome_screen.gd - the end of an attempt (backlog T08, Exec Summary "Fail-state contract", Decisions A20/A30).
# GameState creates one inside the level. It does nothing until the outcome resolves (SHIP_WIN or SHIP_FAIL, exactly once):
#   FAIL: waits for the fail audio (foghorn, the crash, silence: audio_mixer.gd emits fail_audio_finished), then fades in the
#         "Failed" screen with a short reason line. The game never waits for the player before that: the ship really runs
#         onto the rock whatever the player is doing, and Ted's lines play over it.
#   WIN:  waits until the saved ship is past the grounding rock (passenger_ship.gd cleared_rock) plus a beat, then shows a
#         plain end card.
# Enter, Space or R restart the slice (Gate 1 retry model: fail, then restart); Esc on the win card goes back to the title.
# Wording and look are placeholders (data/world/outcome_screens.json).
extends CanvasLayer

const SPEC_PATH := "res://data/world/outcome_screens.json"
const TITLE_SCENE := "res://scenes/Title.tscn"
const SILVER := Color(0.725, 0.745, 0.769)
const AMBER := Color(0.753, 0.478, 0.118)

signal shown(kind: String)

var spec: Dictionary = {}
var kind := ""                 # "" until shown, then "FAIL" or "WIN"
var showing := false

var _gs: Node
var _ship: Node
var _mixer: Node
var _veil: ColorRect
var _title: Label
var _reason: Label
var _prompt: Label
var _fade := 1.0
var _t_shown := 0.0
var _win_wait := -1.0          # counts down once the saved ship has cleared the rock
var _fail_wait := -1.0         # fallback countdown after the impact, only when there is no audio mixer
var _cleared := false


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("outcome_screen: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	layer = 100
	name = "OutcomeScreen"
	_build()
	gs.event_emitted.connect(_on_event)
	_mixer = gs.audio()
	if _mixer:
		_mixer.fail_audio_finished.connect(func() -> void: _show("FAIL"))
	var dl: Node = gs.deadline()
	if dl and dl.ship:
		_ship = dl.ship
		_ship.cleared_rock.connect(func() -> void:
			_cleared = true
			if gs.outcome == gs.Outcome.WIN and _win_wait < 0.0:
				_win_wait = float(spec["win_card_delay_s"]))
		_ship.passed.connect(func() -> void:
			if gs.outcome == gs.Outcome.WIN:
				_show("WIN"))
		_ship.impact.connect(func() -> void:
			if _mixer == null:
				_fail_wait = float(spec["fallback_after_impact_s"]))


func _build() -> void:
	_veil = ColorRect.new()
	_veil.name = "Veil"
	_veil.color = Color(0.015, 0.02, 0.03, 0.0)
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.custom_minimum_size = Vector2(900, 0)
	box.add_theme_constant_override("separation", 22)
	box.modulate.a = 0.0
	box.name = "Box"
	_veil.add_child(box)
	_title = _label(72, SILVER)
	_reason = _label(26, SILVER)
	_prompt = _label(20, AMBER)
	box.add_child(_title)
	box.add_child(_reason)
	box.add_child(_prompt)
	_veil.visible = false


func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	return l


func _on_event(id: String, _phase: int) -> void:
	if id == "SHIP_WIN" and _cleared and _win_wait < 0.0:
		_win_wait = float(spec["win_card_delay_s"])


func _process(delta: float) -> void:
	if spec.is_empty():
		return
	if _win_wait >= 0.0 and not showing:
		_win_wait -= delta
		if _win_wait <= 0.0:
			_show("WIN")
	if _fail_wait >= 0.0 and not showing:
		_fail_wait -= delta
		if _fail_wait <= 0.0:
			_show("FAIL")
	if showing:
		_t_shown += delta
		var fade_s: float = float(spec[kind.to_lower()]["fade_s"])
		_fade = clampf(_t_shown / fade_s, 0.0, 1.0)
		_veil.color.a = 0.82 * _fade
		_veil.get_node("Box").modulate.a = clampf((_t_shown - fade_s * 0.4) / (fade_s * 0.6), 0.0, 1.0)


func _show(k: String) -> void:
	if showing or _gs == null:
		return
	# the screen only ever shows the outcome that actually resolved
	if (k == "FAIL") != (_gs.outcome == _gs.Outcome.FAIL):
		return
	kind = k
	showing = true
	_t_shown = 0.0
	var s: Dictionary = spec[k.to_lower()]
	_title.text = String(s["title"])
	_reason.text = String(s["reason"])
	_prompt.text = String(s["prompt"])
	_veil.visible = true
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	shown.emit(k)


func _unhandled_input(event: InputEvent) -> void:
	if not showing or _t_shown < float(spec["input_grace_s"]):
		return
	var key := event as InputEventKey
	var click := event as InputEventMouseButton
	if key != null and key.pressed and not key.echo:
		if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE or key.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			_gs.restart()
		elif key.keycode == KEY_ESCAPE and kind == "WIN":
			get_viewport().set_input_as_handled()
			_gs.get_tree().paused = false
			_gs.get_tree().change_scene_to_file(TITLE_SCENE)
	elif click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_gs.restart()
