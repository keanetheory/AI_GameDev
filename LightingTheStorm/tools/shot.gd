# shot.gd - render still frames of the level from a camera, for visual checks.
# Run: Godot --path . --write-movie <out>.png --fixed-fps 10 --quit-after N --script res://tools/shot.gd -- x y z  tx ty tz
# (no --headless: it needs the renderer). Frame N of the PNG sequence is the picture.
extends SceneTree

const Sea := preload("res://scripts/world/sea.gd")

var _f := 0
var _cam: Camera3D
var _from := Vector3.ZERO
var _phase := ""
var _lv: Node
var _to := Vector3.ZERO

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var lv: Node = load("res://scenes/Level.tscn").instantiate()
	_lv = lv
	root.add_child(lv)
	_cam = Camera3D.new()
	_cam.far = 3000.0
	_cam.fov = 70.0
	root.add_child(_cam)
	_cam.current = true
	var p := Vector3(float(args[0]), float(args[1]), float(args[2]))
	var t := Vector3(float(args[3]), float(args[4]), float(args[5]))
	_from = p
	_to = t
	_phase = args[6] if args.size() > 6 else ""     # optional lighting phase: ISLAND, OUTBOUND, RETURN, BEACON_RELIT
	if args.size() > 7:
		Sea.target_state = float(args[7])
		Sea.state = float(args[7])
	var pl := lv.get_node_or_null("Player")
	if pl:
		# SHOT_INTERIOR=1: the player (disabled, unseen) stands at the camera so the interior lights come on
		pl.global_position = p if OS.get_environment("SHOT_INTERIOR") == "1" else Vector3(0, -500, 0)    # out of the shot
		pl.process_mode = Node.PROCESS_MODE_DISABLED
		for c in pl.find_children("*", "Camera3D", true, false):
			(c as Camera3D).current = false
		for c in lv.find_children("*", "CanvasLayer", true, false):
			(c as CanvasLayer).visible = false      # no HUD, subtitles or labels in the picture


func _process(_d: float) -> bool:
	_f += 1
	if _f == 3 and OS.get_environment("SHOT_HOLD") != "":     # an item held in view, as the player would see it (coal, burner)
		var cam := _cam
		var item: Node3D = null
		if OS.get_environment("SHOT_HOLD") == "fit":      # the burner already fitted in the lamp socket
			var sock: Node3D = _lv.get_node("InteriorRooms").refs["lamp_socket"]
			sock.receive(_lv.get_node("BurnerPickup/Model"))
			return false
		var pose := [Vector3.ZERO, Vector3.ZERO, 1.0]
		if OS.get_environment("SHOT_HOLD") == "coal":
			var job: Node = _lv.get_node("InteriorRooms").refs["coal_job"]
			item = job._make_shovel()
			pose = [job.held_offset, job.held_rotation_deg, job.held_scale]
		else:
			var bp := _lv.get_node("BurnerPickup")
			item = bp.get_node("Model")
			pose = [bp.held_offset, bp.held_rotation_deg, bp.held_scale]
		item.reparent(cam, false) if item.get_parent() != null else cam.add_child(item)
		item.transform = Transform3D(Basis.from_euler((pose[1] as Vector3) * (PI / 180.0)).scaled(Vector3.ONE * float(pose[2])), pose[0])
	if _f == 3 and OS.get_environment("SHOT_RELIT") == "1":     # the lamp lit at full: as after BURNER_FITTED
		var rooms := _lv.get_node_or_null("InteriorRooms")
		if rooms and rooms.refs.has("lamp_beacon"):
			var bc: Node3D = rooms.refs["lamp_beacon"]
			bc.lit = true
			bc.level = 1.0
			bc._apply(1.0)
	if _phase == "MAP":      # a map view: no fog, so a high camera can see the whole coast
		var we := _lv.get_node_or_null("WorldEnvironment") as WorldEnvironment
		if we and we.environment:
			we.environment.fog_enabled = false
			we.environment.volumetric_fog_enabled = false
	elif _phase != "" and _f == 5:
		var rig := _lv.get_node_or_null("LightingRig")
		if rig:
			rig.set_phase(_phase, true)
	if _cam.is_inside_tree():
		_cam.look_at_from_position(_from, _to, Vector3.UP)
		if not _cam.current:
			_cam.make_current()    # the player's camera claims "current" when it is ready; take it back
	return false
