# test_arthur_anim.gd - run: Godot --headless --path . --script res://tools/test_arthur_anim.gd
# Arthur's Meshy rig (Assets/Characters/arthur.glb, 30 Oct 2026): Idle_3 standing, Walking walking, Talk_with_Right_Hand_Open while one
# of his own lines plays, Chair_Sit_Idle_M on a seat (on a plank, put away when he stands), a jaw that opens while he speaks, 1.78 m tall.
extends SceneTree

var _arthur: Node3D
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
	_arthur = (load("res://scripts/character/npc.gd") as GDScript).spawn(holder, "ARTHUR", Vector3(3, 0, 0))


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _jaw_angle() -> float:
	var jaw: Node = _arthur.get_node("JawLipsync")
	var sk: Skeleton3D = jaw._skeleton
	return sk.get_bone_pose_rotation(jaw._jaw_idx).angle_to(sk.get_bone_rest(jaw._jaw_idx).basis.get_rotation_quaternion())


func _process(_d: float) -> bool:
	_f += 1
	if _f == 4:
		var a: AnimationPlayer = _arthur._anim
		_check(a != null, "Arthur has an AnimationPlayer (his own model, not a capsule)")
		for c in ["Idle_3", "Walking", "Talk_with_Right_Hand_Open", "Chair_Sit_Idle_M"]:
			_check(a.has_animation(c) and a.get_animation(c).loop_mode == Animation.LOOP_LINEAR, "%s is there and loops" % c)
		_check(a.current_animation == "Idle_3", "standing, he plays Idle_3 (%s)" % a.current_animation)
		var dlg := root.get_node("Dialogue")
		dlg.line_started.emit("ARTHUR_X", "ARTHUR", "", "")
		_check(a.current_animation == "Talk_with_Right_Hand_Open", "his own line plays the talking clip (%s)" % a.current_animation)
		dlg.line_finished.emit("ARTHUR_X")
		_arthur.sit(_seat, Vector3.ZERO)
		_check(a.current_animation == "Chair_Sit_Idle_M", "on a seat he plays the sit clip (%s)" % a.current_animation)
		_check(_arthur.get_node_or_null("Bench") != null, "he brings a plank to sit on")
		dlg.line_started.emit("ARTHUR_Y", "ARTHUR", "", "")
		_check(a.current_animation == "Chair_Sit_Idle_M", "he keeps sitting while he talks")
		dlg.line_finished.emit("ARTHUR_Y")
		_arthur.release_seat()
		_check(a.current_animation == "Idle_3", "standing again, he plays Idle_3 (%s)" % a.current_animation)
		_arthur.walk(PackedVector3Array([Vector3(3, 0, 0), Vector3(3, 0, -5)]))
		_arthur._update_anim()
		_check(a.current_animation == "Walking", "walking, he plays Walking (%s)" % a.current_animation)
		_check(absf(absf(_arthur.get_node("Model").rotation.y) - PI) < 0.01, "the model is turned 180 degrees to face -Z")
		_check(_arthur.get_node_or_null("JawLipsync") != null and _arthur.get_node("JawLipsync")._jaw_idx >= 0, "he has a jaw bone driven by jaw_lipsync")
		_arthur.state = _arthur.State.IDLE
		dlg.line_started.emit("ARTHUR_Z", "ARTHUR", "", "")
		_f_talk = _f
	if _f_talk > 0 and _f > _f_talk:
		_max_open = maxf(_max_open, _jaw_angle())
		if _f >= _f_talk + 45:
			_check(_max_open > 0.05, "his jaw opens while he speaks (%.1f degrees)" % rad_to_deg(_max_open))
			print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
			quit(1 if _fails > 0 else 0)
	return false
