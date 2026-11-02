# route_viewer.gd - run (needs a window): Godot --path . --script res://tools/route_viewer.gd [-- route=<name>] [-- out=<folder>]
# With snap=<seconds> (and route=, cam=follow|overhead) it walks that route on its own, saves a screenshot every <seconds> into out= and quits on arrival.
# Watch Ted, Arthur and Daniel walk their baked routes (data/world/npc_paths.json, tools/bake_npc_paths.gd) one at a time, in the real
# level, so the creator can say what to change. Every route is drawn as a coloured line with its waypoints; the chosen one is bright.
#   1-7        choose a route and walk it (the character and the speed are the ones the game uses)
#   R          walk it again from the start           Space  pause / resume
#   [ / ]      slower / faster playback (0.25x .. 4x)  C      camera: follow -> overhead -> free
#   V          lines through walls on / off            L      lines on / off
#   P          screenshot (into out=, default user://route_shots)
#   Free camera: hold the right mouse button to look, WASD to move, Q / E down / up, Shift faster.   Esc  quit
# The gate and the lighthouse door are opened (as the baker does), the knock is skipped and the player is parked at the camera so the
# interior culling and the room lights behave as they do in play. Nothing here changes the game.
extends SceneTree

const Npc := preload("res://scripts/character/npc.gd")
const Routes := preload("res://scripts/character/npc_routes.gd")
const Sailors := preload("res://scripts/world/sailors_sequence.gd")

## route -> [character, speed m/s (-1 = his normal pace), what it is in the game]
const CAST := {
	"ted_to_lamp": ["TED", 1.15, "Ted, after the player steps in: the hall door up the tower to the lamp room (intro_sequence.gd)"],
	"sailors_dock_to_hall": ["ARTHUR", -1.0, "Arthur, rowboat -> the stairs below the gate (waits) -> the hall (sailors_sequence.gd, two legs)"],
	"daniel_dock_to_basement": ["DANIEL", -1.0, "Daniel, rowboat -> the gate -> down the spiral to the basement (sailors_sequence.gd, two legs)"],
	"hall_to_launch_berth": ["ARTHUR", 2.9, "Arthur after the briefing, hurrying to the launch at 2x (boarding_sequence.gd)"],
	"sailors_dock_to_porch": ["ARTHUR", -1.0, "spare: dock -> porch (not used in the game now)"],
	"porch_to_hall": ["ARTHUR", -1.0, "spare: porch -> hall (not used in the game now)"],
	"hall_to_porch": ["ARTHUR", -1.0, "spare: hall -> porch (not used in the game now)"],
}
const COLOURS := [Color(1.0, 0.75, 0.2), Color(0.35, 0.85, 0.45), Color(0.9, 0.3, 0.25), Color(0.4, 0.7, 1.0), Color(0.8, 0.5, 0.9), Color(0.6, 0.6, 0.6), Color(0.95, 0.95, 0.5)]
const SPEEDS := [0.25, 0.5, 1.0, 2.0, 4.0]

var _lv: Node3D
var _cam: Camera3D
var _hud: Label
var _names: Array = []
var _lines: Dictionary = {}       # route -> MeshInstance3D
var _mats: Dictionary = {}
var _npc: Node3D
var _route := ""
var _speed_i := 2
var _cam_mode := 0                # 0 follow, 1 overhead, 2 free
var _xray := true
var _show_lines := true
var _paused := false
var _t := 0.0
var _walked := 0.0
var _last_pos := Vector3.ZERO
var _f := 0
var _yaw := 0.0
var _pitch := -0.3
var _out := "user://route_shots"
var _start_route := ""
var _snap := 0.0
var _snap_t := 0.0
var _snaps := 0
var _done_wait := 0.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("route="):
			_start_route = a.trim_prefix("route=")
		elif a.begins_with("cam="):
			_cam_mode = ["follow", "overhead", "free"].find(a.trim_prefix("cam="))
			_cam_mode = maxi(_cam_mode, 0)
		elif a.begins_with("snap="):
			_snap = float(a.trim_prefix("snap="))
		elif a.begins_with("out="):
			_out = a.trim_prefix("out=")
	Engine.set_meta("skip_intro", true)       # no knock: the door is an ordinary door and Ted is not placed by the intro
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _setup() -> void:
	for g in get_nodes_in_group("gate"):
		if g.has_method("open"):
			g.open()
	var door := _lv.get_node_or_null("LighthouseDoor")
	if door and door.has_method("open"):
		door.open()
	var gs := root.get_node_or_null("GameState")
	if gs and gs.has_method("guidance") and gs.guidance():
		gs.guidance().visible = false
	var settings := root.get_node_or_null("GameSettings")
	if settings:
		settings.subtitles_enabled = false      # for this run only (not saved): the opening lines would cover the view
	var pl := _lv.get_node_or_null("Player") as Node3D
	if pl:
		pl.process_mode = Node.PROCESS_MODE_DISABLED
		pl.visible = false
	_cam = Camera3D.new()
	_cam.fov = 65.0
	_cam.far = 3000.0
	root.add_child(_cam)
	_cam.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	_hud.add_theme_font_size_override("font_size", 17)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hud)
	_names = []
	for n in CAST:
		if Routes.route(n).size() > 0:
			_names.append(n)
	for n in Routes.names():
		if not _names.has(n):
			_names.append(n)
	for i in _names.size():
		_build_line(_names[i], COLOURS[i % COLOURS.size()])
	_play(_start_route if _names.has(_start_route) else _names[0])


func _build_line(n: String, col: Color) -> void:
	var pts := Routes.route(n)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(1, pts.size()):
		im.surface_add_vertex(pts[i - 1] + Vector3(0, 0.08, 0))
		im.surface_add_vertex(pts[i] + Vector3(0, 0.08, 0))
	for i in pts.size():                          # a small upright tick at every 10th point, so the spacing reads
		if i % 10 == 0:
			im.surface_add_vertex(pts[i])
			im.surface_add_vertex(pts[i] + Vector3(0, 0.35, 0))
	im.surface_end()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.no_depth_test = _xray
	m.render_priority = 10
	var mi := MeshInstance3D.new()
	mi.name = "Route_" + n
	mi.mesh = im
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lv.add_child(mi)
	for end in [[0, "start"], [pts.size() - 1, "end"]]:
		var lb := Label3D.new()
		lb.text = "%s (%s)" % [n, end[1]]
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		lb.modulate = col
		lb.font_size = 40
		lb.pixel_size = 0.004
		lb.outline_size = 8
		lb.position = pts[end[0]] + Vector3(0, 0.9, 0)
		mi.add_child(lb)
	_lines[n] = mi
	_mats[n] = m


func _play(n: String) -> void:
	_route = n
	if _npc and is_instance_valid(_npc):
		_npc.queue_free()
	var c: Array = CAST.get(n, ["ARTHUR", -1.0, ""])
	var pts := Routes.route(n)
	_npc = Npc.spawn(_lv, String(c[0]), pts[0])
	_npc.walk(pts, n, float(c[1]))
	if n == "sailors_dock_to_hall":
		_npc.arrived.connect(func(_r): Sailors.face_down_hall(_npc, _lv))     # as the game does when he gets inside
	_t = 0.0
	_done_wait = 0.0
	_walked = 0.0
	_last_pos = pts[0]
	for k in _lines:
		var on: bool = k == n
		(_mats[k] as StandardMaterial3D).albedo_color.a = 1.0 if on else 0.35
		(_mats[k] as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if on else BaseMaterial3D.TRANSPARENCY_ALPHA
	if _cam_mode == 2:
		_cam.global_position = pts[0] + Vector3(0, 4, 6)
		_cam.look_at(pts[0], Vector3.UP)
		_yaw = _cam.rotation.y
		_pitch = _cam.rotation.x


func _process(delta: float) -> bool:
	_f += 1
	if _f == 25:
		_setup()
	if _f < 26 or _npc == null or not is_instance_valid(_npc):
		return false
	var real := delta / maxf(Engine.time_scale, 0.001)
	if _npc.state == _npc.State.WALKING:
		_t += delta
		_walked += _npc.global_position.distance_to(_last_pos)
	_last_pos = _npc.global_position
	_update_camera(real)
	var pl := _lv.get_node_or_null("Player") as Node3D
	if pl:
		pl.global_position = _cam.global_position - Vector3(0, 1.6, 0)
	if _snap > 0.0:
		_snap_t += real
		if _npc.state != _npc.State.WALKING:
			_done_wait += real
		var done: bool = _done_wait > 1.0       # a moment after arriving, so the last frame shows where he ends up facing
		if _snap_t >= _snap or done:
			_snap_t = 0.0
			_snaps += 1
			DirAccess.make_dir_recursive_absolute(_out if not _out.begins_with("user://") else ProjectSettings.globalize_path(_out))
			root.get_texture().get_image().save_png("%s/%s_%02d.png" % [_out, _route, _snaps])
			if done:
				quit()
	var c: Array = CAST.get(_route, ["ARTHUR", -1.0, ""])
	var keys := ""
	for i in mini(_names.size(), 9):
		keys += "%s%d %s\n" % ["> " if _names[i] == _route else "   ", i + 1, _names[i]]
	_hud.text = "ROUTE VIEWER\n%s\n%s\nwalker %s at %.2f m/s, walked %.1f m in %.1f s %s\nplayback %sx   camera %s   lines %s%s\n\n%s\n1-7 route  R again  Space pause  [ ] speed  C camera  V through walls  L lines  P screenshot  Esc quit" % [
		_route, c[2], String(c[0]), _npc.walk_speed, _walked, _t,
		"(arrived)" if _npc.state != _npc.State.WALKING else "", SPEEDS[_speed_i], ["follow", "overhead", "free"][_cam_mode],
		"on" if _show_lines else "off", " through walls" if _xray and _show_lines else "", keys]
	return false


func _update_camera(dt: float) -> void:
	var p := _npc.global_position
	if _cam_mode == 0:
		var fwd := -_npc.global_transform.basis.z
		fwd.y = 0.0
		if fwd.length() < 0.01:
			fwd = Vector3.FORWARD
		var head := p + Vector3(0, 1.5, 0)
		var want := p - fwd.normalized() * 3.2 + Vector3(0, 2.0, 0)
		# pull in when a wall is between him and the camera (the spiral stair, doorways), as a third-person camera does
		var hit := _lv.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(head, want))
		if not hit.is_empty():
			want = head + (hit["position"] - head) * 0.85
		_cam.global_position = _cam.global_position.lerp(want, clampf(dt * 4.0, 0.0, 1.0)) if _cam.global_position.distance_to(want) < 12.0 else want
		_cam.look_at(p + Vector3(0, 1.2, 0), Vector3.UP)
	elif _cam_mode == 1:
		var want := p + Vector3(0.01, 14.0, 6.0)
		_cam.global_position = _cam.global_position.lerp(want, clampf(dt * 3.0, 0.0, 1.0)) if _cam.global_position.distance_to(want) < 20.0 else want
		_cam.look_at(p, Vector3.UP)
	else:
		var mv := Vector3.ZERO
		if Input.is_physical_key_pressed(KEY_W): mv.z -= 1
		if Input.is_physical_key_pressed(KEY_S): mv.z += 1
		if Input.is_physical_key_pressed(KEY_A): mv.x -= 1
		if Input.is_physical_key_pressed(KEY_D): mv.x += 1
		if Input.is_physical_key_pressed(KEY_E): mv.y += 1
		if Input.is_physical_key_pressed(KEY_Q): mv.y -= 1
		var sp := 12.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.0
		_cam.rotation = Vector3(_pitch, _yaw, 0.0)
		_cam.global_position += _cam.global_basis * mv * sp * dt


func _input(e: InputEvent) -> void:
	if _npc == null:
		return
	if e is InputEventMouseMotion and _cam_mode == 2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_yaw -= e.relative.x * 0.004
		_pitch = clampf(_pitch - e.relative.y * 0.004, -1.5, 1.5)
		return
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	var k: int = e.keycode
	if k >= KEY_1 and k <= KEY_9 and k - KEY_1 < _names.size():
		_play(_names[k - KEY_1])
	elif k == KEY_R:
		_play(_route)
	elif k == KEY_SPACE:
		_paused = not _paused
		paused = _paused
	elif k == KEY_BRACKETLEFT or k == KEY_BRACKETRIGHT:
		_speed_i = clampi(_speed_i + (1 if k == KEY_BRACKETRIGHT else -1), 0, SPEEDS.size() - 1)
		Engine.time_scale = SPEEDS[_speed_i]
	elif k == KEY_C:
		_cam_mode = (_cam_mode + 1) % 3
		_yaw = _cam.rotation.y
		_pitch = _cam.rotation.x
	elif k == KEY_V:
		_xray = not _xray
		for m in _mats.values():
			(m as StandardMaterial3D).no_depth_test = _xray
	elif k == KEY_L:
		_show_lines = not _show_lines
		for mi in _lines.values():
			(mi as Node3D).visible = _show_lines
	elif k == KEY_P:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out) if _out.begins_with("user://") else _out)
		var path := "%s/%s_%d.png" % [_out, _route, Time.get_ticks_msec()]
		root.get_texture().get_image().save_png(path)
		print("route_viewer: saved ", ProjectSettings.globalize_path(path) if path.begins_with("user://") else path)
	elif k == KEY_ESCAPE:
		Engine.time_scale = 1.0
		quit()
