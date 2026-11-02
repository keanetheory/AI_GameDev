# shot_phase.gd - run (needs a window): Godot --path . --script res://tools/shot_phase.gd -- <out_dir> [phases=ISLAND,RETURN] [views=dock,sea] [flash] [nofog] [prefix=isl] [beam=55] [hide=Name1,Name2]
# Island Creator ISL-04: stills of Bracken Isle in each lighting phase from fixed island viewpoints, in one run (the level loads once).
# For each phase it forces the LightingRig's phase (instant, as F5-F8 do), sets the sea state the Wave agent's curve gives near the
# island in that phase (WaveSystem.force_state) and the island's wetness to match (IslandReactions), lights the lamp for BEACON_RELIT
# (dark before it) and holds lightning off, so the stills compare like for like. `flash` adds one still per phase that has lightning,
# taken a few frames after a strike (the hazards-in-silhouette check). Writes <out_dir>/<prefix>_<view>_<PHASE>.png at 1280x720.
# The player is moved to the viewpoint (so the interior lights behave as in play) and hidden; the HUD is hidden.
extends SceneTree

const VIEWS := {
	# name: [camera, look-at, fov]
	"dock": [Vector3(-27.5, 3.3, 28.5), Vector3(-12.0, 9.0, 8.0), 65.0],        # on the south jetty, up the stairs to the gate
	"path": [Vector3(-14.5, 12.5, 9.5), Vector3(6.0, 14.0, -6.0), 65.0],        # on the plateau past the gate, towards the lighthouse
	"window": [Vector3(6.6, 29.5, -3.2), Vector3(-24.0, 2.0, 21.0), 60.0],      # inside the lamp room, through the glass, down over the island to the harbour
	"gallery": [Vector3(6.3, 29.3, -2.9), Vector3(-26.0, 1.0, 21.0), 60.0],     # the same line from just outside the glass (no pane in the way)
	"sea": [Vector3(-38.0, 5.0, 115.0), Vector3(-8.0, 9.0, 0.0), 50.0],         # the boat's approach from the Saltgate side
	# ISL-06: the concept art's four raised three-quarter views (ConceptArt/island), 110 m out and 60 m up; not part of the default set
	"cmp_front": [Vector3(-92.1, 60.0, 67.2), Vector3(-5.0, 3.0, 0.0), 45.0],    # "front view of island": the dock and stair face-on
	"cmp_rear": [Vector3(82.1, 60.0, -67.2), Vector3(-5.0, 3.0, 0.0), 45.0],     # "Rear rocky island": the far side from the dock
	"cmp_left": [Vector3(-98.0, 60.0, -58.8), Vector3(-5.0, 3.0, 0.0), 45.0],    # "Left-side view": the dock at the right
	"cmp_right": [Vector3(28.4, 60.0, 104.8), Vector3(-5.0, 3.0, 0.0), 45.0],    # "Right-Side View": the dock at the left
}
const DEFAULT_VIEWS := ["dock", "path", "window", "gallery", "sea"]
const PHASES := ["ISLAND", "OUTBOUND", "RETURN", "BEACON_RELIT"]
const SEA_FOR := {"ISLAND": 1.0, "OUTBOUND": 1.0, "RETURN": 5.0, "BEACON_RELIT": 5.0}
const SETTLE := 40       # frames after a phase or view change before the still (spray, lights, rain)

var _a: PackedStringArray
var _out := ""
var _prefix := "isl"
var _phases: Array = PHASES.duplicate()
var _views: Array = DEFAULT_VIEWS.duplicate()
var _nofog := false
var _flash := false
var _hide: PackedStringArray = []    # node names hidden before the stills (isolating a piece)
var _beam_off := 55.0    # degrees the beam is turned off the line to the camera (lower: the spill lands on the camera's side)
var _jobs: Array = []    # [phase, view, flash]
var _j := 0
var _wait := 0
var _f := 0
var _lv: Node3D
var _rig: Node
var _cam: Camera3D
var _beacon: Node


func _initialize() -> void:
	_a = OS.get_cmdline_user_args()
	_out = _a[0] if _a.size() > 0 else "user://"
	for arg in _a:
		if arg.begins_with("phases="):
			_phases = Array(arg.trim_prefix("phases=").split(","))
		elif arg.begins_with("views="):
			_views = Array(arg.trim_prefix("views=").split(","))
		elif arg.begins_with("prefix="):
			_prefix = arg.trim_prefix("prefix=")
		elif arg.begins_with("hide="):
			_hide = arg.trim_prefix("hide=").split(",")
		elif arg.begins_with("beam="):
			_beam_off = float(arg.trim_prefix("beam="))
		elif arg == "flash":
			_flash = true
		elif arg == "nofog":
			_nofog = true     # shape comparisons only (ISL-06): the distance fog off so the whole island reads
	for ph in _phases:
		for v in _views:
			_jobs.append([ph, v, false])
		if _flash and (ph == "RETURN" or ph == "BEACON_RELIT"):
			_jobs.append([ph, "sea", true])
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _setup() -> void:
	_rig = _lv.get_node("LightingRig")
	_beacon = _lv.get_node("InteriorRooms").refs.get("lamp_beacon")
	_cam = Camera3D.new()
	_cam.far = 4000.0
	root.add_child(_cam)
	_cam.make_current()
	for nm in _hide:
		for n in root.find_children(nm, "Node3D", true, false):
			(n as Node3D).visible = false
	var gs := root.get_node_or_null("GameState")
	if gs and gs.has_method("guidance"):
		var hud: Node = gs.guidance()
		if hud:
			hud.visible = false
	var pl := _lv.get_node_or_null("Player") as Node3D
	if pl:
		pl.process_mode = Node.PROCESS_MODE_DISABLED
		pl.visible = false
		for c in pl.find_children("*", "Camera3D", true, false):
			(c as Camera3D).current = false
	_cam.make_current()


func _start(job: Array) -> void:
	var ph: String = job[0]
	var v: Array = VIEWS[job[1]]
	_rig.set_phase(ph, true)
	_rig._next_flash = 1e9
	if _nofog and _rig.get("_env"):
		(_rig._env as Environment).fog_enabled = false
	if _rig.get("_label"):
		(_rig._label as CanvasItem).visible = false     # the debug "Lighting: <phase>" label
	_lv.get_node("WaveSystem").force_state = SEA_FOR[ph]
	var r := _lv.get_node_or_null("IslandReactions")
	if r:
		r.wetness = clampf((SEA_FOR[ph] - 1.0) / 3.0, 0.0, 1.0)
	var pl := _lv.get_node_or_null("Player") as Node3D
	if pl:
		pl.global_position = v[0]
	_cam.fov = v[2]
	_cam.look_at_from_position(v[0], v[1], Vector3.UP)
	if _beacon:
		var on: bool = ph == "BEACON_RELIT"
		_beacon.lit = on
		_beacon.level = 1.0 if on else 0.0
		_beacon._apply(_beacon.level)
		_beacon.sweep_deg_s = 0.0
		var pivot: Node3D = _beacon._beam_pivot
		if pivot and on:
			# turn the beam 55 degrees (beam=) off the line to the camera, so it crosses the frame instead of shining into the lens
			var to_cam: Vector3 = v[0] - pivot.global_position
			var hd := atan2(-to_cam.z, to_cam.x) + deg_to_rad(_beam_off)
			pivot.global_rotation = Vector3(0.0, hd, 0.0)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	if _f == 20:
		_setup()
	if _j >= _jobs.size():
		quit()
		return false
	var job: Array = _jobs[_j]
	if _wait == 0:
		_start(job)
	_wait += 1
	if job[2] and _wait == SETTLE - 4:
		_rig.flash_now(VIEWS["sea"][1])
	if _wait < SETTLE:
		return false
	var name := "%s_%s_%s%s.png" % [_prefix, job[1], job[0], "_flash" if job[2] else ""]
	var img := root.get_texture().get_image()
	if img.get_width() != 1280:
		img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	img.save_png(_out.path_join(name))
	print("SHOT %s" % name)
	_wait = 0
	_j += 1
	return false
