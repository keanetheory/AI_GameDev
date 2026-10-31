# test_guidance_hud.gd - run: Godot --headless --path . --script res://tools/test_guidance_hud.gd
# T54 and T55: the goal tracker (upper right) and the controls list (lower right), in the real level through the real GameState.
#   - every goal waits on a real story event, once each; the first goal is "knock" and the tracker advances one goal per event, with a tick
#     and the old text shown for a moment before the next goal;
#   - a player who skips ahead is never shown a goal behind them; a fresh attempt starts again at the first goal;
#   - the tracker never shows time;
#   - the controls follow the player's mode, their key names come from the input map, and the debug keys are not listed;
#   - both hide when the attempt resolves; they sit in the right-hand corners and do not overlap each other.
extends SceneTree

var _lv: Node
var _gs: Node
var _f := 0
var _fails := 0
var _stub: Node
var _sv: SubViewport
var _sv_hud: CanvasLayer


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	# a headless window is tiny, so the layout is checked on a HUD inside a 1280 x 720 viewport of its own, with a stand-in GameState
	var stub := GDScript.new()
	stub.source_code = "extends Node
var fired := {}
var outcome := 0
enum Outcome { NONE, WIN, FAIL }
"
	stub.reload()
	_stub = Node.new()
	_stub.set_script(stub)
	root.add_child(_stub)
	_sv = SubViewport.new()
	_sv.size = Vector2i(1280, 720)
	root.add_child(_sv)
	_sv_hud = (load("res://scripts/ui/guidance_hud.gd") as GDScript).new()
	_sv.add_child(_sv_hud)
	_sv_hud.setup(_stub, _lv)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 40:
		_run()
		quit(1 if _fails > 0 else 0)
	return false


func _run() -> void:
	_gs = root.get_node("GameState")
	var hud: CanvasLayer = _gs.guidance()
	_check(hud != null and hud.goals.size() >= 15, "GameState made the guidance HUD with its goals (%d)" % (hud.goals.size() if hud else 0))
	if hud == null:
		return
	# the data
	var seen := {}
	var ok := true
	for g in hud.goals:
		ok = ok and _gs.EVENTS.has(String(g["done_on"])) and not seen.has(g["done_on"]) and String(g["text"]).length() > 0 and String(g["text"]).length() < 60
		seen[g["done_on"]] = true
	_check(ok, "every goal is one short line that waits on a real story event, each event once")
	var banned := true
	for g in hud.goals:
		var t := String(g["text"]).to_lower()
		banned = banned and not (t.contains("time") or t.contains("minute") or t.contains("seconds") or t.contains("deadline") or t.contains("hurry"))
	_check(banned, "no goal mentions time (the deadline stays hidden)")
	# the start
	_check(hud.active_index() == 0 and hud.goal_text(0) == "Knock on the lighthouse door", "a new attempt starts on the first goal: knock on the door")
	_check(hud._goal_panel.visible and hud._ctl_panel.visible, "both panels show")
	# where they sit
	var vp: Vector2 = Vector2(_sv.size)
	var gr: Rect2 = _sv_hud._goal_panel.get_global_rect()
	var cr: Rect2 = _sv_hud._ctl_panel.get_global_rect()
	_check(absf(gr.end.x - (vp.x - 24.0)) < 1.5 and absf(gr.position.y - 24.0) < 1.5, "the goal tracker sits in the upper right corner, 24 px in (%s of %s)" % [gr, vp])
	_check(absf(cr.end.x - (vp.x - 24.0)) < 1.5 and absf(cr.end.y - (vp.y - 24.0)) < 1.5, "the controls sit in the lower right corner, 24 px in (%s)" % cr)
	_check(not gr.intersects(cr) and gr.position.x > vp.x * 0.5 and cr.position.x > vp.x * 0.5, "they stay in the right-hand corners and do not overlap")
	# the story, event by event
	var advanced := true
	for i in hud.goals.size():
		if hud.active_index() != i:
			advanced = false
			print("     goal %d expected, %d active" % [i, hud.active_index()])
			break
		_gs.emit_event(String(hud.goals[i]["done_on"]))
		if i < hud.goals.size() - 1 and hud.active_index() != i + 1:
			advanced = false
			print("     after %s: goal %d expected, %d active" % [hud.goals[i]["done_on"], i + 1, hud.active_index()])
			break
		if _gs.outcome != _gs.Outcome.NONE:
			break
	_check(advanced, "the tracker advances exactly one goal per story event, in order")
	# the tick and the next goal (a fresh stub, so it does not depend on the level's own timing)
	var stub := GDScript.new()
	stub.source_code = "extends Node\nvar fired := {}\nvar outcome := 0\nenum Outcome { NONE, WIN, FAIL }\n"
	stub.reload()
	var sn := Node.new()
	sn.set_script(stub)
	root.add_child(sn)
	var h2: CanvasLayer = (load("res://scripts/ui/guidance_hud.gd") as GDScript).new()
	root.add_child(h2)
	h2.setup(sn, _lv)
	_check(h2.shown_goal == 0 and h2._goal_label.text == "Knock on the lighthouse door", "a fresh attempt shows the first goal")
	sn.fired["GAME_STARTED"] = true
	h2._process(0.1)
	_check(h2._goal_label.text.begins_with("✓") and h2._goal_label.text.contains("Knock"), "when a goal is done, a tick and the old text show first (%s)" % h2._goal_label.text)
	h2._process(2.0)
	_check(h2.shown_goal == 1 and h2._goal_label.text == "Go inside the lighthouse", "then the next goal (%s)" % h2._goal_label.text)
	# skipping ahead: the lamp room before the gate
	sn.fired["LAMP_ROOM_ENTERED"] = true
	_check(h2.active_index() == h2.goals.find({"id": "DIAGNOSE", "text": "Help Ted open up the arc lamp", "done_on": "BURNER_DIAGNOSED"}) or h2.goal_text(h2.active_index()) == "Help Ted open up the arc lamp", "a player who skips ahead is shown the goal after the latest one done, never one behind (%s)" % h2.goal_text(h2.active_index()))
	# the controls
	var foot: Array = hud.controls_rows("ON_FOOT")
	var helm: Array = hud.controls_rows("AT_HELM")
	_check(_row(foot, "Move") == "WASD" and _row(foot, "Interact") == "E" and _row(foot, "Sprint") == "Shift" and _row(foot, "Jump") == "Space" and _row(foot, "Pause") == "P", "on foot: WASD move, E interact, Shift sprint, Space jump, P pause (read from the input map)")
	_check(_row(helm, "Steer") == "A / D" and _row(helm, "Step ashore") == "Q" and _row(helm, "Cast off (when moored)") == "E", "at the helm: A / D steer, E cast off, Q step ashore")
	var all_text := ""
	for r in foot + helm:
		all_text += r["keys"] + " " + r["label"] + " "
	_check(not (all_text.contains("F9") or all_text.contains("F10") or all_text.contains("F11") or all_text.contains("Page") or all_text.contains("Home")), "the debug keys are not listed")
	var named := true
	for m in ["ON_FOOT", "AT_HELM"]:
		for r in hud.controls_rows(m):
			named = named and r["keys"] != "?" and r["keys"] != ""
	_check(named, "every control has a key name")
	# C hides the list down to "Controls (C)" and brings it back; the choice outlives the level
	_check(_row(foot, "Hide controls") == "C" and _row(helm, "Hide controls") == "C", "the list itself says C hides the controls (the key read from the input map)")
	var Hud := load("res://scripts/ui/guidance_hud.gd") as GDScript
	_check(Hud.controls_open and h2._ctl_grid.visible and not h2._ctl_collapsed.visible, "the controls start open")
	var press := InputEventAction.new()
	press.action = "toggle_controls"
	press.pressed = true
	h2._unhandled_input(press)
	_check(not Hud.controls_open and not h2._ctl_grid.visible and h2._ctl_collapsed.visible and h2._ctl_collapsed.text == "Controls (C)" and h2._ctl_panel.size.y < 50.0, "pressing C shrinks the list to just \"%s\" (%.0f px tall)" % [h2._ctl_collapsed.text, h2._ctl_panel.size.y])
	var h3: CanvasLayer = Hud.new()
	root.add_child(h3)
	h3.setup(sn, _lv)
	_check(h3._ctl_collapsed.visible and not h3._ctl_grid.visible, "a restart (a new HUD) keeps it collapsed")
	h2._unhandled_input(press)
	_check(Hud.controls_open and h2._ctl_grid.visible and not h2._ctl_collapsed.visible, "pressing C again opens the full list")
	h3.queue_free()
	hud._set_mode("AT_HELM")
	_check(hud.mode == "AT_HELM" and hud._ctl_grid.get_child_count() == helm.size() * 2, "the list switches to the helm rows")
	hud._set_mode("ON_FOOT")
	# the controls dim after a while and brighten when the mode changes
	h2._t = 100.0
	h2._bright_left = 0.0
	for i in 60:
		h2._process(0.1)
	_check(h2._ctl_panel.modulate.a < 0.6, "the controls settle back after the first minute (alpha %.2f)" % h2._ctl_panel.modulate.a)
	h2._set_mode("AT_HELM")
	for i in 20:
		h2._process(0.1)
	_check(h2._ctl_panel.modulate.a > 0.9, "and come back to full strength when the mode changes (alpha %.2f)" % h2._ctl_panel.modulate.a)
	# resolved: both hide
	_check(_gs.outcome == _gs.Outcome.WIN, "the story reached the win")
	hud._process(0.1)
	_check(not hud._goal_panel.visible and not hud._ctl_panel.visible, "both panels hide once the attempt resolves")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])


func _row(rows: Array, label: String) -> String:
	for r in rows:
		if r["label"] == label:
			return r["keys"]
	return "(missing %s)" % label
