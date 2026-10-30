# test_daniel_anim.gd - run: Godot --headless --path . --script res://tools/test_daniel_anim.gd
# Daniel's Meshy rig (Assets/Characters/daniel.glb, 30 Oct 2026): Walking walking, a frozen standing pose (no idle clip in his download), Talk_with_Hands_Open while one
# of his own lines plays, Sit_Cross_Legged on a seat (on a plank, put away when he stands), a jaw that opens while he speaks, 1.66 m tall.
extends SceneTree

var _daniel: Node3D
var _seat: Node3D
var _f := 0
var _fails := 0
var _f_talk := 0
var _max_open := 0.0


func _initialize() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	_seat = Node3D.new()
	holder.add_child(_seat)
	_daniel = (load("res://scripts/character/npc.gd") as GDScript).spawn(holder, "DANIEL", Vector3(3, 0, 0))


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _jaw_angle() -> float:
	var jaw: Node = _daniel.get_node("JawLipsync")
	var sk: Skeleton3D = jaw._skeleton
	return sk.get_bone_pose_rotation(jaw._jaw_idx).angle_to(sk.get_bone_rest(jaw._jaw_idx).basis.get_rotation_quaternion())


func _process(_d: float) -> bool:
	_f += 1
	if _f == 4:
		var a: AnimationPlayer = _daniel._anim
		_check(a != null, "Daniel has an AnimationPlayer (his own model, not a capsule)")
		for c in ["Walking", "Talk_with_Hands_Open", "Sit_Cross_Legged"]:
			_check(a.has_animation(c) and a.get_animation(c).loop_mode == Animation.LOOP_LINEAR, "%s is there and loops" % c)
		_check(not a.is_playing(), "standing, he holds a still pose (no idle clip) (%s)" % a.current_animation)
		var dlg := root.get_node("Dialogue")
		dlg.line_started.emit("DANIEL_X", "DANIEL", "", "")
		_check(a.current_animation == "Talk_with_Hands_Open", "his own line plays the talking clip (%s)" % a.current_animation)
		dlg.line_finished.emit("DANIEL_X")
		_daniel.sit(_seat, Vector3.ZERO)
		_check(a.current_animation == "Sit_Cross_Legged", "on a seat he plays the sit clip (%s)" % a.current_animation)
		_check(_daniel.get_node_or_null("Bench") != null, "he brings a plank to sit on")
		dlg.line_started.emit("DANIEL_Y", "DANIEL", "", "")
		_check(a.current_animation == "Sit_Cross_Legged", "he keeps sitting while he talks")
		dlg.line_finished.emit("DANIEL_Y")
		_daniel.release_seat()
		_check(not a.is_playing(), "standing again, he holds the still pose (%s)" % a.current_animation)
		_daniel.walk(PackedVector3Array([Vector3(3, 0, 0), Vector3(3, 0, -5)]))
		_daniel._update_anim()
		_check(a.current_animation == "Walking", "walking, he plays Walking (%s)" % a.current_animation)
		_check(absf(absf(_daniel.get_node("Model").rotation.y) - PI) < 0.01, "the model is turned 180 degrees to face -Z")
		_check(_daniel.get_node_or_null("JawLipsync") != null and _daniel.get_node("JawLipsync")._jaw_idx >= 0, "he has a jaw bone driven by jaw_lipsync")
		_daniel.state = _daniel.State.IDLE
		dlg.line_started.emit("DANIEL_Z", "DANIEL", "", "")
		_f_talk = _f
	if _f_talk > 0 and _f > _f_talk:
		_max_open = maxf(_max_open, _jaw_angle())
		if _f >= _f_talk + 45:
			_check(_max_open > 0.05, "his jaw opens while he speaks (%.1f degrees)" % rad_to_deg(_max_open))
			print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
			quit(1 if _fails > 0 else 0)
	return false
