# npc.gd - a capsule stand-in character (backlog T30): Arthur and Daniel are capsules for the prototype (creator, 19 October 2026;
# Ted is the rigged character). One script, four behaviours: walk a path, wait, follow the player, sit at a seat on the boat.
#
#   var arthur := Npc.spawn(level, "ARTHUR", Vector3(-27, 0.3, 26.3))
#   arthur.walk(NpcRoutes.route("sailors_dock_to_hall"))     # then arthur.arrived fires with the route name
#   arthur.wait(2.0); arthur.follow(player, 2.0); arthur.sit(boat_seat_node)
#
# Routes are baked from the real level by tools/bake_npc_paths.gd (data/world/npc_paths.json): every point carries its floor height,
# so the walker only interpolates between points (no physics, no raycasts) and a path through the spiral stairs just works.
# The walker has no collision of its own: a route is only as good as its bake, and tools/test_npc.gd checks the baked routes
# against the level. Characters are capsules with a small dark nose on the front so the way they face reads (forward is -Z).
extends Node3D

signal arrived(route_name: String)
signal reached_waypoint(index: int)
signal released                 # left a seat

enum State { IDLE, WALKING, WAITING, FOLLOWING, SEATED }

const LOOKS := {
	# Arthur is a FAL Hunyuan v3 mesh rigged in Meshy (31 Oct 2026), same Mixamo rig and jaw bone as Ted: Walking, Idle_3 (Ted's, copied
	# in by tools/copy_clips.py: his own Idle_03 is a stretch with his hands at his head), and Chair_Sit_Idle_M on the launch's and the
	# rowboat's seats, held at its halfway point (sit_hold_frac): later in the clip he leans back and his body goes through the boat
	# (creator, 30 Oct 2026). His download has no talking clip, so he stays in Idle_3 while his jaw moves.
	"ARTHUR": {"model": "res://Assets/Characters/arthur.glb", "height": 1.78, "radius": 0.32, "speed": 1.45, "walk_clip": "Walking", "run_clip": "Running", "idle_clip": "Idle_3", "sit_clip": "Chair_Sit_Idle_M", "sit_hold_frac": 0.5, "model_yaw_deg": 180.0, "jaw": true, "ease_bones": {"mixamorig_LeftUpLeg": 0.72, "mixamorig_RightUpLeg": 0.72, "mixamorig_LeftLeg": 0.8, "mixamorig_RightLeg": 0.8, "mixamorig_LeftFoot": 0.6, "mixamorig_LeftToeBase": 0.6}},
	# Daniel is a FAL Hunyuan v3 mesh rigged in Meshy (31 Oct 2026), same Mixamo rig and jaw bone: Walking, Talk_Passionately while his own
	# line plays, Sit_Cross_Legged on the rowboat's seat, and Idle_3 standing (Ted's, copied in by tools/copy_clips.py: his download has
	# no standing idle).
	"DANIEL": {"model": "res://Assets/Characters/daniel.glb", "height": 1.66, "radius": 0.28, "speed": 1.55, "walk_clip": "Walking", "run_clip": "Running", "idle_clip": "Idle_3", "talk_clip": "Talk_Passionately", "sit_clip": "Sit_Cross_Legged", "bench_m": 0.42, "model_yaw_deg": 180.0, "jaw": true},
	# Ted is a FAL Hunyuan v3 mesh rigged in Meshy (31 Oct 2026): his own model, Walking while he walks and Idle_3 (looping) when he stands.
	# His download has no talking clip, so he stays in Idle_3 while his jaw moves. The Meshy rig faces +Z, so the model is turned
	# 180 degrees about Y to face -Z like everything else.
	"TED": {"model": "res://Assets/Characters/ted.glb", "height": 1.83, "radius": 0.3, "speed": 1.15, "walk_clip": "Walking", "run_clip": "Running", "idle_clip": "Idle_3", "model_yaw_deg": 180.0, "jaw": true},
}

@export var who := "ARTHUR"
var state: int = State.IDLE
var walk_speed := 1.45
var route_name := ""
var route_index := 0

var _pts: PackedVector3Array = PackedVector3Array()
var _wait_left := 0.0
var _resume_after_wait := false
var _follow_target: Node3D
var _follow_gap := 2.0
var _follow_speed := 1.7
var _seat_parent: Node
var _body: MeshInstance3D
var _look: Dictionary = {}
var _anim: AnimationPlayer
var _walking_anim := false
var _gait := 1.0                # walk clip speed: walk_speed over his normal pace, so a hurry looks like a jog, not a glide
var _running := false           # walk_speed at RUN_AT x his pace or more: the run clip (creator, 2 Nov 2026: Arthur runs to the launch)
const RUN_AT := 1.6             # a pace this many times his normal walk or more is a run
const RUN_CLIP_MPS := 3.0       # the speed the Meshy run clip's feet move at, so the clip is played to match the ground
var _talking := false
var _sit_held := false          # the sit clip has reached its hold point and is paused there


static func spawn(parent: Node, character: String, at: Vector3) -> Node3D:
	var n: Node3D = (load("res://scripts/character/npc.gd") as GDScript).new()
	n.who = character
	n.name = character.capitalize()
	parent.add_child(n)
	n.global_position = at
	return n


func _ready() -> void:
	_look = LOOKS.get(who, LOOKS["ARTHUR"])
	walk_speed = float(_look["speed"])
	_build_body()
	add_to_group("npc")


func _build_body() -> void:
	if _look.has("model"):
		_build_model()
		return
	var h: float = _look["height"]
	var r: float = _look["radius"]
	_body = MeshInstance3D.new()
	_body.name = "Capsule"
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = h
	_body.mesh = cap
	_body.position = Vector3(0.0, h * 0.5, 0.0)       # the node's origin is at the feet
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _look["colour"]
	mat.roughness = 0.9
	_body.material_override = mat
	add_child(_body)
	var nose := MeshInstance3D.new()
	nose.name = "Nose"
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.16)
	nose.mesh = box
	nose.position = Vector3(0.0, h * 0.86, -r * 0.95)
	var nm := StandardMaterial3D.new()
	nm.albedo_color = Color(0.1, 0.08, 0.07)
	nose.material_override = nm
	add_child(nose)


## Arthur's left boot is skinned badly at the ankle: when the trailing foot points down, the boot stretches out at an odd angle
## (creator, 2 Nov 2026; his right foot and Ted's walk on his rig do the same motion without it). `ease_bones` turns those bones only
## part of the way from their rest pose in the walk and run clips (1 = as animated, 0 = held at rest). The clips are shared by every
## copy of the model, so it is done once per clip.
func _ease_bones(model: Node3D) -> void:
	var ease: Dictionary = _look.get("ease_bones", {})
	var skels := model.find_children("*", "Skeleton3D", true, false)
	if ease.is_empty() or skels.is_empty() or _anim == null:
		return
	var skel := skels[0] as Skeleton3D
	for k in ["walk_clip", "run_clip"]:
		if not _look.has(k) or not _anim.has_animation(String(_look[k])):
			continue
		var a := _anim.get_animation(String(_look[k]))
		if a.has_meta("eased_bones"):
			continue
		a.set_meta("eased_bones", true)
		for t in a.get_track_count():
			if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
				continue
			var bone := String(a.track_get_path(t).get_concatenated_subnames())
			if not ease.has(bone):
				continue
			var idx := skel.find_bone(bone)
			if idx < 0:
				continue
			var rest := skel.get_bone_rest(idx).basis.get_rotation_quaternion()
			for i in a.track_get_key_count(t):
				var q: Quaternion = a.track_get_key_value(t, i)
				a.track_set_key_value(t, i, rest.slerp(q, float(ease[bone])))


func _build_model() -> void:
	var ps := load(String(_look["model"])) as PackedScene
	if ps == null:
		push_warning("npc: %s did not load" % _look["model"])
		return
	var m := ps.instantiate() as Node3D
	m.name = "Model"
	m.rotation.y = deg_to_rad(float(_look.get("model_yaw_deg", 0.0)))
	add_child(m)
	var aps := m.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		_anim = aps[0]
		for k in ["walk_clip", "run_clip", "idle_clip", "talk_clip", "sit_clip"]:
			if _look.has(k) and _anim.has_animation(String(_look[k])):
				_anim.get_animation(String(_look[k])).loop_mode = Animation.LOOP_LINEAR
		_ease_bones(m)
		if _look.get("jaw", false):
			# the jaw bone (tools/add_jaw_bone.py) opens from the voice, or flaps while this character's line is "spoken"
			var jaw := Node.new()
			jaw.name = "JawLipsync"
			jaw.set_script(load("res://scripts/character/jaw_lipsync.gd"))
			jaw.set("dialogue_loader", get_node_or_null("/root/Dialogue"))
			jaw.set("speaker_id", who)
			add_child(jaw)
		if _look.has("talk_clip"):
			var dlg := get_node_or_null("/root/Dialogue")
			if dlg and dlg.has_signal("line_started"):
				dlg.line_started.connect(_on_line_started)
				dlg.line_finished.connect(_on_line_finished)
		_stand()


func _stand() -> void:
	if _anim == null:
		return
	_walking_anim = false
	if state == State.SEATED and _look.has("sit_clip") and _anim.has_animation(String(_look["sit_clip"])):
		var sc := String(_look["sit_clip"])
		if _sit_held and _anim.assigned_animation == sc:
			return       # already sitting, paused at its hold point: a line of dialogue must not sit him down again
		_sit_held = false
		_play_loop(sc)
		return
	_sit_held = false
	if _talking and _look.has("talk_clip") and _anim.has_animation(String(_look["talk_clip"])):
		_play_loop(String(_look["talk_clip"]))
		return
	if _look.has("idle_clip") and _anim.has_animation(String(_look["idle_clip"])):
		_play_loop(String(_look["idle_clip"]))
		return
	var clip := String(_look.get("pose_clip", ""))
	if _anim.has_animation(clip):
		_anim.play(clip)
		_anim.seek(0.0, true)
		_anim.pause()


## The boat models have no thwart at the height the sit clip assumes (it sits on a chair about half a metre above the feet), so a
## seated model character brings a plank: a bench of boards across the boat under him, taken away when he stands.
func _set_bench(on: bool) -> void:
	var old := get_node_or_null("Bench")
	if old:
		old.queue_free()
	if not on or not _look.has("sit_clip"):
		return
	var bench := MeshInstance3D.new()
	bench.name = "Bench"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.95, 0.07, 0.34)
	bench.mesh = bm
	bench.position = Vector3(0.0, float(_look.get("bench_m", 0.5)), 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.14, 0.1)
	bench.material_override = mat
	add_child(bench)


func _play_loop(clip: String) -> void:
	if _anim.current_animation != clip or not _anim.is_playing():
		_anim.play(clip, 0.25)


func _on_line_started(_line_id: String, speaker: String, _subtitle: String, _delivery: String) -> void:
	_talking = speaker == who
	if not _walking_anim:
		_stand()


func _on_line_finished(_line_id: String) -> void:
	_talking = false
	if not _walking_anim:
		_stand()


func _update_anim() -> void:
	if _anim == null:
		return
	if state == State.SEATED and not _sit_held and _look.has("sit_hold_frac") and _anim.current_animation == String(_look.get("sit_clip", "")):
		var hold_at: float = _anim.current_animation_length * float(_look["sit_hold_frac"])
		if _anim.current_animation_position >= hold_at:
			_anim.pause()
			_sit_held = true
	var walking := state == State.WALKING or state == State.FOLLOWING
	if walking and not _walking_anim:
		_walking_anim = true
		if _running and _anim.has_animation(String(_look.get("run_clip", ""))):
			_anim.play(String(_look["run_clip"]), -1.0, clampf(walk_speed / RUN_CLIP_MPS, 0.7, 1.4))
		else:
			_anim.play(String(_look["walk_clip"]), -1.0, _gait)
	elif not walking and _walking_anim:
		_stand()


## Walk the points in order (world positions at floor height). arrived(route_name) fires at the last one.
func walk(points: PackedVector3Array, name_of_route := "", speed := -1.0) -> void:
	if state == State.SEATED:
		release_seat()
	_pts = points
	route_name = name_of_route
	route_index = 0
	if speed > 0.0:
		walk_speed = speed
	_gait = maxf(walk_speed / float(_look["speed"]), 1.0)
	var run := _gait >= RUN_AT
	if run != _running:
		_running = run
		_walking_anim = false          # switch between the walk and the run clip on the next update
	state = State.WALKING if points.size() > 0 else State.IDLE
	if points.size() == 1:
		_step_to(points[0], 1000.0)


## Stand still for `seconds`; if `then_resume`, a walk in progress carries on afterwards.
func wait(seconds: float, then_resume := true) -> void:
	_resume_after_wait = then_resume and state == State.WALKING
	_wait_left = seconds
	state = State.WAITING


## Turn to look at a point (on the ground plane).
func face(point: Vector3) -> void:
	var flat := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if flat.length() > 0.01:
		rotation.y = atan2(-flat.x, -flat.z)


func stop() -> void:
	state = State.IDLE
	_pts = PackedVector3Array()


## Keep `gap` metres from the target (on the ground plane), at the target's floor height.
func follow(target: Node3D, gap := 2.0, speed := 1.7) -> void:
	if state == State.SEATED:
		release_seat()
	_follow_target = target
	_follow_gap = gap
	_follow_speed = speed
	state = State.FOLLOWING


## Sit at a seat: become a child of the seat node (a boat's seat, say) so the character rides along. `bench` false when the seat is a
## real chair (Daniel's, T43): no stand-in plank under him.
func sit(seat: Node3D, offset := Vector3.ZERO, bench := true) -> void:
	if state != State.SEATED:
		_seat_parent = get_parent()
	state = State.SEATED
	_pts = PackedVector3Array()
	reparent(seat, false)
	position = offset
	rotation = Vector3.ZERO
	_stand()
	_set_bench(bench)


func release_seat() -> void:
	if state != State.SEATED or _seat_parent == null or not is_instance_valid(_seat_parent):
		state = State.IDLE
		return
	reparent(_seat_parent, true)
	state = State.IDLE
	_stand()
	_set_bench(false)
	released.emit()


func _process(delta: float) -> void:
	_update_anim()
	match state:
		State.WALKING:
			_walk(delta)
		State.WAITING:
			_wait_left -= delta
			if _wait_left <= 0.0:
				state = State.WALKING if _resume_after_wait else State.IDLE
		State.FOLLOWING:
			_follow(delta)


func _walk(delta: float) -> void:
	var budget := walk_speed * delta
	while budget > 0.0 and route_index < _pts.size():
		var to: Vector3 = _pts[route_index]
		var d := global_position.distance_to(to)
		if d <= budget:
			budget -= d
			_step_to(to, d)
			reached_waypoint.emit(route_index)
			route_index += 1
			if state != State.WALKING:
				return       # a reached_waypoint listener told us to wait or stop
		else:
			_step_to(global_position + (to - global_position).normalized() * budget, budget)
			budget = 0.0
	if route_index >= _pts.size() and state == State.WALKING:
		state = State.IDLE
		arrived.emit(route_name)


func _step_to(p: Vector3, dist: float) -> void:
	var flat := Vector3(p.x - global_position.x, 0.0, p.z - global_position.z)
	global_position = p
	if flat.length() > 0.001 and dist > 0.0:
		var yaw := atan2(-flat.x, -flat.z)           # the nose (-Z) leads
		rotation.y = lerp_angle(rotation.y, yaw, 0.35)


func _follow(delta: float) -> void:
	if _follow_target == null or not is_instance_valid(_follow_target):
		state = State.IDLE
		return
	var me := global_position
	var tp := _follow_target.global_position
	var flat := Vector3(tp.x - me.x, 0.0, tp.z - me.z)
	var dist := flat.length()
	if dist > _follow_gap:
		var move := minf(_follow_speed * delta, dist - _follow_gap)
		var np := me + flat.normalized() * move
		np.y = lerpf(me.y, tp.y, clampf(4.0 * delta, 0.0, 1.0))
		_step_to(np, move)
