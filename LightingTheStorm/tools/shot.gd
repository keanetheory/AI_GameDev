# shot.gd - render still frames of the level from a camera, for visual checks.
# Run: Godot --path . --write-movie <out>.png --fixed-fps 10 --quit-after N --script res://tools/shot.gd -- x y z  tx ty tz
# (no --headless: it needs the renderer). Frame N of the PNG sequence is the picture.
# SHOT_BOARD=1 shows Arthur aboard the launch.
# SHOT_INTRO=1 shows the front door open with Ted waiting just inside.
# SHOT_ROWBOAT=1 shows the sailors' rowboat moored at the south berth.
# SHOT_NPC=<route>:<0..1> puts the capsule sailors on a baked route.
# SHOT_SHIP=<0..1> shows the passenger ship at that deadline progress (SHOT_SHIP=crash:<s> a while after it struck the rock).
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
		var ws := lv.get_node_or_null("WaveSystem")
		if ws:
			ws.force_state = float(args[7])      # the wave system would otherwise steer the sea back to its own state
	if OS.get_environment("SHOT_TORCH") == "1":      # SHOT_TORCH=1: a lamp at the camera, to inspect surfaces that the night leaves black
		var torch := OmniLight3D.new()
		torch.light_energy = 6.0
		torch.omni_range = 14.0
		torch.shadow_enabled = false
		torch.position = p
		lv.add_child(torch)
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
	if _f == 8:      # SHOT_HIDE=a/b,c: hide those nodes (paths from the Level; the interior is built by now)
		for nm in OS.get_environment("SHOT_HIDE").split(",", false):
			var hn := root.get_node_or_null("Level/" + nm)
			if hn:
				hn.visible = false
			else:
				print("SHOT_HIDE: no node ", nm)
	if _f == 6 and OS.get_environment("SHOT_NOFOG") == "1":      # SHOT_NOFOG=1: no distance fog (triage: is the washout the fog?)
		var we := root.find_children("*", "WorldEnvironment", true, false)
		for w in we:
			if (w as WorldEnvironment).environment:
				(w as WorldEnvironment).environment.fog_enabled = false
	if _f == 2 and OS.get_environment("SHOT_BOAT") != "":     # e.g. SHOT_BOAT=DOCK_PORT: the launch tied up at that berth
		var boat: Node3D = _lv.get_node("Boat")
		for z in get_nodes_in_group("dock_zone"):
			if z.zone_id == OS.get_environment("SHOT_BOAT"):
				boat.global_position = Vector3(z.global_position.x, 0.0, z.global_position.z)
				boat.rotation.y = deg_to_rad(z.berth_yaw_deg)
				boat.current_zone = z
	if _f == 4 and OS.get_environment("SHOT_BOARD") != "":      # SHOT_BOARD=1: Arthur aboard the launch at the lighthouse berth
		var gsb := get_root().get_node_or_null("GameState")
		var bq: Node = gsb.boarding() if gsb else null
		if bq:
			bq._leave_for_the_launch()
			bq.arthur.stop()
			bq._board()
	if _f == 4 and OS.get_environment("SHOT_INTRO") != "":      # SHOT_INTRO=1: the front door open and Ted waiting just inside, as after the knock
		var gsi := get_root().get_node_or_null("GameState")
		var intro: Node = gsi.intro() if gsi else null
		if intro:
			intro._spawn_ted()
			_lv.get_node("LighthouseDoor").open()
	if _f == 4 and OS.get_environment("SHOT_ROWBOAT") != "":      # SHOT_ROWBOAT=1: the rowboat at its berth with Arthur and Daniel aboard
		var gs2 := get_root().get_node_or_null("GameState")
		var sq: Node = gs2.sailors() if gs2 else null
		if sq:
			sq._begin_arrival()
			sq.rowboat._place(sq.rowboat.berth())
	if _f == 4 and OS.get_environment("SHOT_NPC") != "":      # SHOT_NPC=sailors_dock_to_hall:0.3 puts Arthur there and Daniel a few metres behind
		var Npc := preload("res://scripts/character/npc.gd")
		var Routes := preload("res://scripts/character/npc_routes.gd")
		var route := Routes.route(OS.get_environment("SHOT_NPC").get_slice(":", 0))
		var frac := float(OS.get_environment("SHOT_NPC").get_slice(":", 1))
		var i := clampi(int(frac * (route.size() - 1)), 0, route.size() - 1)
		var j := clampi(i - 25, 0, route.size() - 1)
		var art := Npc.spawn(_lv, "ARTHUR", route[i])
		var dan := Npc.spawn(_lv, "DANIEL", route[j])
		art.look_at(art.global_position + (route[mini(i + 3, route.size() - 1)] - route[i]) * Vector3(1, 0, 1) + Vector3(0.001, 0, 0), Vector3.UP)
		dan.look_at(dan.global_position + (route[mini(j + 3, route.size() - 1)] - route[j]) * Vector3(1, 0, 1) + Vector3(0.001, 0, 0), Vector3.UP)
	if _f == 4 and OS.get_environment("SHOT_SHIP") != "":      # SHOT_SHIP=0.5: the passenger ship at that deadline progress; =crash:12: 12 s after it struck the rock
		var gs := get_root().get_node_or_null("GameState")
		var dl: Node = gs.deadline() if gs else null
		if dl == null or dl.ship == null:
			print("SHOT_SHIP: no ship (GameState has no deadline director)")
		else:
			var spec := OS.get_environment("SHOT_SHIP")
			dl.ship.appear()
			if spec.begins_with("crash"):
				dl.ship.set_progress(1.0)
				dl.ship.commit()
				var secs := float(spec.get_slice(":", 1)) + 40.0
				var t := 0.0
				while t < secs:
					dl.ship._process(0.1)
					t += 0.1
			else:
				dl.ship.set_progress(float(spec))
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
