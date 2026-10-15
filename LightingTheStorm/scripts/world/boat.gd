# boat.gd - the steam launch. Implements AIAgentCrew/world_output/boat_spec.json:
# one fixed speed, steered only by A and D (move_left / move_right), W and S do nothing,
# a rudder that eases out and returns to centre, a little sideways drift, and automatic
# docking when it enters a dock zone.
# E boards (when on the dock) and casts off (when seated and tied up); Q steps back onto the dock.
extends Node3D

signal docked(zone_id: String)
signal departed(zone_id: String)
signal hazard_hit

enum State { DOCKED, SAILING, DOCKING }

@export var speed := 3.0                  # m/s, fixed
@export var max_turn_rate_deg := 35.0     # deg/s at full rudder
@export var steer_response_s := 0.35      # time for the rudder to swing from centre to full
@export var drift_factor := 0.15          # share of the old velocity kept each second (sideways slide)
@export var dock_approach_speed := 3.0    # m/s, eased down to nothing at the berth
@export var board_radius := 10.0          # how close the player must be to board
@export var seat_offset := Vector3(0.0, 0.5, 0.2)   # where the player stands at the helm (boat space)
@export var water_level := 0.5            # sea surface height
@export var draft := 0.35                 # keel depth below the surface
@export_flags_3d_physics var hazard_mask := 2          # physics layer of rocks, cliffs and the island
@export var hull_size := Vector3(2.8, 1.2, 5.6)        # box used to detect hazard hits
@export var recovery_back_s := 2.5        # on a hit, move back to where the boat was this long ago
@export var recovery_pause_s := 1.5       # small cost: held still this long (you can still turn)

var state := State.DOCKED
var rudder := 0.0
var velocity := Vector3.ZERO
## Tide / Wave hook from the spec: a push in m/s added to the boat's velocity each physics frame.
## Zero until the Tide / Wave agent supplies it.
var water_push := Vector2.ZERO
var current_zone: Node3D = null
var driving := false

var _leave_zone: Node3D = null
var _stun := 0.0
var _trail: Array[Transform3D] = []      # recent clear positions, newest last
var _trail_timer := 0.0
var _hull_shape := BoxShape3D.new()
var _player: Node3D = null
var _prompt: Label
@onready var _hull: Node3D = get_node_or_null("Hull")


func _ready() -> void:
	_hull_shape.size = hull_size
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.position.y = -90.0
	var layer := CanvasLayer.new()
	layer.add_child(_prompt)
	add_child(layer)
	_player = get_tree().get_first_node_in_group("player")
	# Start tied up at the nearest zone.
	var best := INF
	for zone in get_tree().get_nodes_in_group("dock_zone"):
		var d := _flat_distance(zone)
		if d < best:
			best = d
			current_zone = zone
	if current_zone:
		global_position = Vector3(current_zone.global_position.x, 0.0, current_zone.global_position.z)
		rotation.y = deg_to_rad(current_zone.berth_yaw_deg)
	_snap_to_water()


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	var yaw_before := rotation.y
	match state:
		State.SAILING:
			_sail(delta)
		State.DOCKING:
			_dock(delta)
		State.DOCKED:
			rudder = move_toward(rudder, 0.0, delta / steer_response_s)
	_snap_to_water()
	if _hull:
		_hull.rotation.z = lerp(_hull.rotation.z, -rudder * 0.07, 1.0 - exp(-6.0 * delta))
	if driving and _player:
		_player.rotate_y(rotation.y - yaw_before)   # the view turns with the boat
		_player.global_position = to_global(seat_offset)
	_handle_input()
	_update_prompt()


# --- public actions (also used by tools/test_boat.gd) ---

func board() -> void:
	if driving or _player == null:
		return
	driving = true
	_player.start_driving(self)


func cast_off() -> void:
	if state != State.DOCKED or not driving:
		return
	_leave_zone = current_zone
	state = State.SAILING
	velocity = Vector3.ZERO
	_stun = 0.0
	_trail.clear()
	_trail_timer = 0.0
	departed.emit(current_zone.zone_id if current_zone else "")


func disembark() -> void:
	if not driving or state != State.DOCKED or current_zone == null:
		return
	driving = false
	_player.stop_driving(current_zone.landing)


# --- movement ---

func _sail(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right") if driving else 0.0
	rudder = move_toward(rudder, axis, delta / steer_response_s)
	rotation.y -= rudder * deg_to_rad(max_turn_rate_deg) * delta
	if _stun > 0.0:   # after a hit: held still, but you can turn to line up a way out
		_stun -= delta
		velocity = Vector3.ZERO
		return
	var forward := -global_transform.basis.z
	velocity = velocity.lerp(forward * speed, 1.0 - pow(drift_factor, delta))
	var push := Vector3(water_push.x, 0.0, water_push.y)
	global_position += (velocity + push) * delta
	if _hits_hazard(global_transform):
		_recover()
		return
	_trail_timer += delta
	if _trail_timer >= 0.5:
		_trail_timer = 0.0
		_trail.append(global_transform)
		if _trail.size() > 40:
			_trail.pop_front()
	# Entering a zone other than the one we just left starts auto-docking.
	for zone in get_tree().get_nodes_in_group("dock_zone"):
		var d := _flat_distance(zone)
		if zone == _leave_zone:
			if d > zone.radius + 2.0:
				_leave_zone = null
		elif d < zone.radius:
			current_zone = zone
			state = State.DOCKING
			break


func _dock(delta: float) -> void:
	rudder = move_toward(rudder, 0.0, delta / steer_response_s)
	var berth := Vector3(current_zone.global_position.x, global_position.y, current_zone.global_position.z)
	var to_berth := berth - global_position
	var dist := to_berth.length()
	var step := minf(dock_approach_speed, dist * 0.7 + 0.15) * delta   # slows as it nears the berth
	velocity = to_berth.normalized() * (step / delta) if dist > 0.01 else Vector3.ZERO
	global_position += to_berth.normalized() * minf(step, dist)
	rotation.y = lerp_angle(rotation.y, deg_to_rad(current_zone.berth_yaw_deg), 1.0 - exp(-1.5 * delta))
	var yaw_err := absf(angle_difference(rotation.y, deg_to_rad(current_zone.berth_yaw_deg)))
	if dist < 0.1 and yaw_err < 0.02:
		velocity = Vector3.ZERO
		state = State.DOCKED
		docked.emit(current_zone.zone_id)


func _hits_hazard(at: Transform3D) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _hull_shape
	q.transform = Transform3D(at.basis, at.origin + Vector3(0.0, 0.9, 0.0))
	q.collision_mask = hazard_mask
	return not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## Spec: on a hazard hit the boat bounces off and is moved to the nearest safe point with a small cost.
func _recover() -> void:
	var back := maxi(0, _trail.size() - 1 - int(recovery_back_s / 0.5))
	var target := Transform3D(global_transform.basis, global_position)
	var found := false
	for i in range(back, -1, -1):
		if not _hits_hazard(_trail[i]):
			target = _trail[i]
			found = true
			break
	if found:
		global_position = target.origin
		rotation.y = target.basis.get_euler().y
		_trail.resize(maxi(0, back))
	else:
		# No clear trail yet: shove back along the bow line until clear.
		var step := global_transform.basis.z * 1.0
		for i in 60:
			global_position += step
			if not _hits_hazard(global_transform):
				break
	velocity = Vector3.ZERO
	_stun = recovery_pause_s
	hazard_hit.emit()


func _snap_to_water() -> void:
	global_position.y = water_level - draft


func _flat_distance(node: Node3D) -> float:
	return Vector2(global_position.x - node.global_position.x, global_position.z - node.global_position.z).length()


# --- input and prompt ---

func _handle_input() -> void:
	if Input.is_action_just_pressed("interact"):
		if not driving and state == State.DOCKED and _player_in_reach():
			board()
		elif driving and state == State.DOCKED:
			cast_off()
	elif Input.is_action_just_pressed("disembark"):
		disembark()


func _player_in_reach() -> bool:
	if _player == null:
		return false
	var d := Vector2(_player.global_position.x - global_position.x, _player.global_position.z - global_position.z).length()
	return d < board_radius and absf(_player.global_position.y - global_position.y) < 6.0


func _update_prompt() -> void:
	var text := ""
	if not driving:
		if state == State.DOCKED and _player_in_reach():
			text = "[E] Board the launch"
	elif state == State.DOCKED:
		text = "[E] Cast off      [Q] Step onto the dock"
	elif state == State.SAILING:
		text = "Rocks! Steer clear..." if _stun > 0.0 else "[A] / [D] Steer"
	elif state == State.DOCKING:
		text = "Docking..."
	_prompt.text = text
