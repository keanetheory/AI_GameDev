# guidance_hud.gd - the goal tracker (upper right) and the controls list (lower right) (backlog T54 and T55; creator, 30 Oct 2026).
# GameState creates one inside the level, so a restart (which reloads the level) gives a fresh one. It only reads GameState and the
# input map; it never drives story progress.
#   - Goal tracker: one short objective from data/world/goals.json. The goal shown is the one after the latest goal whose done_on event
#     has fired, so a player who skips ahead is never shown a goal behind them. When the shown goal is done, a tick and the old text
#     stay for a moment, then the next goal fades in. It never shows time: the ship deadline stays hidden.
#   - Controls: the keys for what the player is doing now (ON_FOOT, or AT_HELM while seated in the launch), from
#     data/world/controls.json, with the key names read from the real input map so they cannot drift from the bindings. It stays at
#     full strength for the first dim_after_s seconds and after the mode changes, then settles back to dim_alpha.
#   - Both hide when the attempt resolves (the Failed screen and the win card take over the screen) and while the title is up.
# Look: the style guide's silver and amber on a dark translucent panel, small type.
extends CanvasLayer

const GOALS_PATH := "res://data/world/goals.json"
const CONTROLS_PATH := "res://data/world/controls.json"
const SILVER := Color(0.725, 0.745, 0.769)
const AMBER := Color(0.753, 0.478, 0.118)
const TICK := Color(0.62, 0.78, 0.6)

var goals: Array = []
var goal_spec: Dictionary = {}
var controls_spec: Dictionary = {}
var shown_goal := -1             # index of the goal on screen (-1 before the first frame)
var mode := ""                   # ON_FOOT or AT_HELM

var _gs: Node
var _goal_panel: PanelContainer
var _goal_heading: Label
var _goal_label: Label
var _ctl_panel: PanelContainer
var _ctl_grid: GridContainer
var _ctl_heading: Label
var _flash_left := 0.0
var _t := 0.0
var _bright_left := 0.0
var _goal_tween: Tween


func setup(gs: Node, _level: Node) -> void:
	_gs = gs
	layer = 4
	process_mode = Node.PROCESS_MODE_ALWAYS     # still shown while paused
	goal_spec = _read(GOALS_PATH)
	controls_spec = _read(CONTROLS_PATH)
	goals = goal_spec.get("goals", [])
	_build()
	_set_mode(_current_mode())
	_show_goal(active_index())


func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("guidance_hud: cannot read %s" % path)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


# --- the goal ---

## The goal that should be on screen now: the one after the latest whose done_on has fired (0 before anything), or -1 when all are done.
func active_index() -> int:
	var latest := -1
	if _gs != null:
		for i in goals.size():
			if _gs.fired.has(String(goals[i]["done_on"])):
				latest = i
	return latest + 1 if latest + 1 < goals.size() else -1


func goal_text(i: int) -> String:
	return String(goals[i]["text"]) if i >= 0 and i < goals.size() else ""


func _show_goal(i: int) -> void:
	shown_goal = i
	_goal_label.text = goal_text(i)
	_goal_label.add_theme_color_override("font_color", SILVER)
	_goal_panel.visible = i >= 0
	if _goal_tween:
		_goal_tween.kill()
	_goal_label.modulate.a = 0.0
	_goal_tween = create_tween()
	_goal_tween.tween_property(_goal_label, "modulate:a", 1.0, 0.5)


# --- the controls ---

func _current_mode() -> String:
	var p := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	return "AT_HELM" if p != null and p.get("boat") != null else "ON_FOOT"


func _set_mode(m: String) -> void:
	mode = m
	for c in _ctl_grid.get_children():
		_ctl_grid.remove_child(c)
		c.queue_free()
	for row in controls_rows(m):
		var k := Label.new()
		k.text = row["keys"]
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		k.add_theme_color_override("font_color", AMBER)
		k.add_theme_font_size_override("font_size", 15)
		var l := Label.new()
		l.text = row["label"]
		l.add_theme_color_override("font_color", SILVER)
		l.add_theme_font_size_override("font_size", 15)
		_ctl_grid.add_child(k)
		_ctl_grid.add_child(l)
	_bright_left = float(controls_spec.get("bright_after_mode_change_s", 6.0))


## The rows for a mode as {keys, label}, the key names read from the input map.
func controls_rows(m: String) -> Array:
	var out: Array = []
	for row in controls_spec.get("modes", {}).get(m, []):
		var keys := ""
		if row.has("text"):
			keys = String(row["text"])
		else:
			var names: Array = []
			for a in row.get("actions", []):
				names.append(key_name(String(a)))
			var short := true
			for n in names:
				short = short and String(n).length() == 1
			keys = "".join(names) if short and names.size() > 2 else " / ".join(names)
		out.append({"keys": keys, "label": String(row["label"])})
	return out


## The first key bound to an action, named for the player's keyboard layout ("W", "Shift", "Space").
static func key_name(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			var labelled: int = DisplayServer.keyboard_get_keycode_from_physical(code)
			return OS.get_keycode_string(labelled if labelled != 0 else code)
	return "?"


# --- frame ---

func _process(delta: float) -> void:
	if _gs == null:
		return
	_t += delta
	var resolved: bool = _gs.outcome != _gs.Outcome.NONE
	_goal_panel.visible = not resolved and (shown_goal >= 0 or _flash_left > 0.0)
	_ctl_panel.visible = not resolved
	if resolved:
		return
	# the goal
	var target := active_index()
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_show_goal(target)
	elif target != shown_goal:
		if shown_goal >= 0 and (target > shown_goal or target < 0):
			_flash_left = float(goal_spec.get("done_flash_s", 1.4))      # a tick and the old text, then the next goal
			_goal_label.text = "✓  " + goal_text(shown_goal)
			_goal_label.add_theme_color_override("font_color", TICK)
			_goal_label.modulate.a = 1.0
			_goal_panel.visible = true
		else:
			_show_goal(target)
	# the controls
	var m := _current_mode()
	if m != mode:
		_set_mode(m)
	if _bright_left > 0.0:
		_bright_left -= delta
	var dim: bool = _t > float(controls_spec.get("dim_after_s", 45.0)) and _bright_left <= 0.0
	var want := float(controls_spec.get("dim_alpha", 0.5)) if dim else 1.0
	_ctl_panel.modulate.a = lerpf(_ctl_panel.modulate.a, want, 1.0 - exp(-3.0 * delta))


# --- building the panels ---

func _panel(heading: String) -> Array:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.07, 0.62)
	sb.border_color = Color(SILVER.r, SILVER.g, SILVER.b, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	var h := Label.new()
	h.text = heading
	h.add_theme_color_override("font_color", AMBER)
	h.add_theme_font_size_override("font_size", 12)
	box.add_child(h)
	return [p, box, h]


## Puts a panel in the upper right or the lower right corner, 24 px in from the edges, sized to its contents (a full-screen margin
## container that ignores the mouse, so the panel shrinks and grows from its corner as the text changes).
func _corner(panel: Control, bottom: bool) -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.size_flags_vertical = Control.SIZE_SHRINK_END if bottom else Control.SIZE_SHRINK_BEGIN
	m.add_child(panel)
	add_child(m)


func _build() -> void:
	# goal tracker: upper right
	var g := _panel(String(goal_spec.get("heading", "GOAL")))
	_goal_panel = g[0]
	_goal_heading = g[2]
	_goal_label = Label.new()
	_goal_label.custom_minimum_size = Vector2(290, 0)
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_label.add_theme_color_override("font_color", SILVER)
	_goal_label.add_theme_font_size_override("font_size", 18)
	(g[1] as VBoxContainer).add_child(_goal_label)
	_corner(_goal_panel, false)
	# controls: lower right
	var c := _panel(String(controls_spec.get("heading", "CONTROLS")))
	_ctl_panel = c[0]
	_ctl_heading = c[2]
	_ctl_grid = GridContainer.new()
	_ctl_grid.columns = 2
	_ctl_grid.add_theme_constant_override("h_separation", 12)
	_ctl_grid.add_theme_constant_override("v_separation", 2)
	(c[1] as VBoxContainer).add_child(_ctl_grid)
	_corner(_ctl_panel, true)
