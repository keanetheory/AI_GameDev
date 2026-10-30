# test_ted_anim.gd - run: Godot --headless --path . --script res://tools/test_ted_anim.gd
# Ted's Meshy rig (Assets/Characters/ted.glb, 30 Oct 2026): he stands in the Idle_3 loop, walks in Walking, talks in
# Stand_Talking_Angry while one of his own lines plays (another speaker's line does not move him), and the model is turned to face -Z.
extends SceneTree

var _ted: Node3D
var _f := 0
var _fails := 0


func _initialize() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	_ted = (load("res://scripts/character/npc.gd") as GDScript).spawn(holder, "TED", Vector3.ZERO)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _process(_d: float) -> bool:
	_f += 1
	if _f == 4:
		var a: AnimationPlayer = _ted._anim
		_check(a != null, "Ted has an AnimationPlayer")
		for c in ["Idle_3", "Walking", "Stand_Talking_Angry"]:
			_check(a.has_animation(c), "the %s clip is there" % c)
			_check(a.get_animation(c).loop_mode == Animation.LOOP_LINEAR, "%s loops" % c)
		_check(a.current_animation == "Idle_3" and a.is_playing(), "standing, he plays Idle_3 (%s)" % a.current_animation)
		var dlg := root.get_node("Dialogue")
		dlg.line_started.emit("X", "ARTHUR", "", "")
		_check(a.current_animation == "Idle_3", "another speaker's line leaves Ted idle")
		dlg.line_started.emit("TED_X", "TED", "", "")
		_check(a.current_animation == "Stand_Talking_Angry", "his own line plays the talking clip (%s)" % a.current_animation)
		dlg.line_finished.emit("TED_X")
		_check(a.current_animation == "Idle_3", "and he goes back to idle when it ends (%s)" % a.current_animation)
		_ted.walk(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, -5)]))
		_ted._update_anim()
		_check(a.current_animation == "Walking", "walking, he plays Walking (%s)" % a.current_animation)
		_check(absf(absf(_ted.get_node("Model").rotation.y) - PI) < 0.01, "the model is turned 180 degrees to face -Z")
		print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
		quit(1 if _fails > 0 else 0)
	return false
