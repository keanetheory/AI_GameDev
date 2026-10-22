# preview_model.gd - render one .glb alone on a neutral ground with two lights, from a given yaw.
# Run: Godot --path . --write-movie <out>.png --fixed-fps 10 --quit-after 8 --script res://tools/preview_model.gd -- <res://model.glb> <yaw_deg> [pitch_deg]
extends SceneTree

var _cam: Camera3D
var _f := 0
var _centre := Vector3.ZERO
var _dist := 2.0
var _yaw := 0.0
var _pitch := 15.0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var m := (load(a[0]) as PackedScene).instantiate() as Node3D
	root.add_child(m)
	_yaw = float(a[1]) if a.size() > 1 else 0.0
	_pitch = float(a[2]) if a.size() > 2 else 15.0
	var box := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var b := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	_centre = box.get_center()
	_dist = maxf(box.size.length() * (1.25 if _pitch > 1.0 or _yaw != 0.0 else 0.62), 0.5)
	print("size ", box.size)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.44, 0.47)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.ambient_light_energy = 0.7
	we.environment = env
	root.add_child(we)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, 35, 0)
	l.light_energy = 1.1
	root.add_child(l)
	_cam = Camera3D.new()
	root.add_child(_cam)
	_cam.current = true


func _process(_d: float) -> bool:
	_f += 1
	var y := deg_to_rad(_yaw)
	var p := deg_to_rad(_pitch)
	var off := Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * _dist
	_cam.look_at_from_position(_centre + off, _centre, Vector3.UP)
	return false
