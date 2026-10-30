# shot_ted.gd - run (needs a window): Godot --path . --script res://tools/shot_ted.gd -- <out.png>
# A still of Ted as the game spawns him, standing at the origin, camera in front of him on the -Z side (the way he should face).
extends SceneTree

var _f := 0
var _out := "user://ted.png"
var _close := false
var _ted: Node3D
var _who := "TED"
var _sit := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_close = args.size() > 1 and args[1] == "close"   # a head close-up with the jaw wide open
	if args.size() > 2:
		_who = args[2]                                  # TED, ARTHUR, DANIEL
	_sit = args.size() > 3 and args[3] == "sit"        # sat on a 0.45 m box with the sit clip
	var holder := Node3D.new()
	root.add_child(holder)
	_ted = (load("res://scripts/character/npc.gd") as GDScript).spawn(holder, _who, Vector3.ZERO)
	if _sit:
		var seat := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 0.05, 0.4)
		seat.mesh = bm
		holder.add_child(seat)
		seat.position = Vector3(0, 0.0, 0)
		_ted.sit(seat, Vector3.ZERO)
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
	if _f == 30 and _sit:
		var m := _ted.get_node("Model") as Node3D
		var sk := m.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		for n in ["Hips", "Head"]:
			for i in sk.get_bone_count():
				if sk.get_bone_name(i).ends_with(n):
					print("SIT ", n, " y = ", (sk.global_transform * sk.get_bone_global_pose(i)).origin.y)
	if _f == 30:
		root.get_texture().get_image().save_png(_out)
		quit()
	return false
