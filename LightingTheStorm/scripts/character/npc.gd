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
	"ARTHUR": {"height": 1.78, "radius": 0.32, "colour": Color(0.36, 0.48, 0.55), "speed": 1.45},   # older sailor: a heavy teal-grey coat
	"DANIEL": {"height": 1.66, "radius": 0.28, "colour": Color(0.92, 0.74, 0.2), "speed": 1.55},   # younger sailor: a yellow oilskin
	# Ted is the rigged character: his own model, the Walking clip while he walks, and the first frame of Alert_Quick_Turn_Right (he has
	# no idle clip) when he stands. Forward is -Z for him too.
	"TED": {"model": "res://Assets/Characters/ted.glb", "height": 1.83, "radius": 0.3, "speed": 1.15, "walk_clip": "Walking", "pose_clip": "Alert_Quick_Turn_Right"},
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


func _build_model() -> void:
	var ps := load(String(_look["model"])) as PackedScene
	if ps == null:
		push_warning("npc: %s did not load" % _look["model"])
		return
	var m := ps.instantiate() as Node3D
	m.name = "Model"
	add_child(m)
	var aps := m.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		_anim = aps[0]
		if _anim.has_animation(String(_look["walk_clip"])):
			_anim.get_animation(String(_look["walk_clip"])).loop_mode = Animation.LOOP_LINEAR
		_stand()


func _stand() -> void:
	if _anim == null:
		return
	_walking_anim = false
	var clip := String(_look["pose_clip"])
	if _anim.has_animation(clip):
		_anim.play(clip)
		_anim.seek(0.0, true)
		_anim.pause()


func _update_anim() -> void:
	if _anim == null:
		return
	var walking := state == State.WALKING or state == State.FOLLOWING
	if walking and not _walking_anim:
		_walking_anim = true
		_anim.play(String(_look["walk_clip"]))
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


## Sit at a seat: become a child of the seat node (a boat's seat, say) so the character rides along.
func sit(seat: Node3D, offset := Vector3.ZERO) -> void:
	if state != State.SEATED:
		_seat_parent = get_parent()
	state = State.SEATED
	_pts = PackedVector3Array()
	reparent(seat, false)
	position = offset
	rotation = Vector3.ZERO


func release_seat() -> void:
	if state != State.SEATED or _seat_parent == null or not is_instance_valid(_seat_parent):
		state = State.IDLE
		return
	reparent(_seat_parent, true)
	state = State.IDLE
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
