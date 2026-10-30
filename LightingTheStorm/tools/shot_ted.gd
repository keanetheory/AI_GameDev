# shot_ted.gd - run (needs a window): Godot --path . --script res://tools/shot_ted.gd -- <out.png>
# A still of Ted as the game spawns him, standing at the origin, camera in front of him on the -Z side (the way he should face).
extends SceneTree

var _f := 0
var _out := "user://ted.png"
var _close := false
var _ted: Node3D


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_close = args.size() > 1 and args[1] == "close"   # a head close-up with the jaw wide open
	var holder := Node3D.new()
	root.add_child(holder)
	_ted = (load("res://scripts/character/npc.gd") as GDScript).spawn(holder, "TED", Vector3.ZERO)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 200, 0)
	root.add_child(light)
	var cam := Camera3D.new()
	root.add_child(cam)
	if _close:
		cam.fov = 14.0
		cam.look_at_from_position(Vector3(-1.6, 1.62, -1.6), Vector3(0, 1.62, 0))
	else:
		cam.look_at_from_position(Vector3(0.6, 1.5, -3.2), Vector3(0, 1.0, 0))
	cam.current = true


func _process(_d: float) -> bool:
	_f += 1
	if _close and _f == 10:
		var jaw: Node = _ted.get_node("JawLipsync")
		jaw.max_open_deg = 18.0
		jaw._speaking_text = true
		jaw.set_process(false)
		jaw._skeleton.set_bone_pose_rotation(jaw._jaw_idx, jaw._skeleton.get_bone_rest(jaw._jaw_idx).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, deg_to_rad(18.0)))
	if _f == 30:
		root.get_texture().get_image().save_png(_out)
		quit()
	return false
