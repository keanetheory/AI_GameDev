# shot_outcome.gd - render the Failed screen or the win card over a dark stand-in for the level, for a visual check.
# Run: Godot --path . --write-movie <out>.png --fixed-fps 10 --quit-after 40 --script res://tools/shot_outcome.gd -- FAIL|WIN
extends SceneTree

const GsStub := """extends Node
enum Outcome { NONE, WIN, FAIL }
var outcome := 2
signal event_emitted(id, phase)
func audio(): return null
func deadline(): return null
func restart(): pass
"""

var _scr: Node
var _f := 0


func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var gs := Node.new()
	var sc := GDScript.new()
	sc.source_code = GsStub
	sc.reload()
	gs.set_script(sc)
	root.add_child(gs)
	var kind := String(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else "FAIL"
	gs.outcome = 2 if kind == "FAIL" else 1
	_scr = load("res://scripts/ui/outcome_screen.gd").new()
	root.add_child(_scr)
	_scr.setup(gs, root)
	_scr._show(kind)


func _process(delta: float) -> bool:
	_f += 1
	return false
