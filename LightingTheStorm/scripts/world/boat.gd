# boat.gd - the steam launch. Implements AIAgentCrew/world_output/boat_spec.json:
# one fixed speed, steered only by A and D (move_left / move_right), W and S do nothing,
# a rudder that eases out and returns to centre, a little sideways drift, and automatic
# docking when it enters a dock zone.
# E boards (when on the dock) and casts off (when seated and tied up); Q steps back onto the dock.
# The boat floats: it rides the same waves as the sea shader (Sea.wave_height), heaving, pitching and
# rolling with them, and its hull has a solid deck the player can jump onto and stand on while it moves.
extends Node3D

const Sea := preload("res://scripts/world/sea.gd")

signal docked(zone_id: String)
signal departed(zone_id: String)
signal hazard_hit
## Auto-docking has taken over the boat at a dock zone (the player lets go of the wheel).
signal docking_started(zone_id: String)
## A hard hit (see hard_bounce): the boat was thrown back and is rocking.
signal hard_hit
## A wave (not a rock) hit the boat: it slows briefly and takes on water. WaveSystem calls apply_wave_hit(); it never happens outbound.
signal wave_hit(water: float)

enum State { DOCKED, SAILING, DOCKING }

@export var speed := 8.0                  # m/s, fixed. Overridden by speed_mps in data/world/boat_spec.json (Wave workshop D4: held as data)
@export var max_turn_rate_deg := 35.0     # deg/s at full rudder
@export var steer_response_s := 0.35      # time for the rudder to swing from centre to full
@export var drift_factor := 0.15          # share of the old velocity kept each second (sideways slide)
@export var dock_approach_speed := 3.0    # m/s, eased down to nothing at the berth
@export var board_radius := 10.0          # how close the player must be to board
@export var seat_offset := Vector3(0.0, 0.5, 0.2)   # where the player stands at the helm (boat space)
@export var cargo_offset := Vector3(0.0, 0.13, 1.3)  # the cargo slot on the deck, aft of the helm (boat space)
@export var water_level := 0.5            # sea surface height
@export var draft := 0.35                 # keel depth below the surface
@export var wave_follow := 1.0            # 0 = ignore the waves, 1 = ride them exactly, >1 = exaggerate
@export var half_length := 2.6            # bow/stern sample distance for pitch
@export var half_beam := 1.3              # port/starboard sample distance for roll
@export_flags_3d_physics var hazard_mask := 2          # physics layer of rocks, cliffs and the island
@export var hull_size := Vector3(2.8, 1.2, 5.6)        # box used to detect hazard hits
@export var recovery_back_s := 2.5        # on a hit, move back to where the boat was this long ago
@export var recovery_pause_s := 1.5       # small cost: held still this long (you can still turn)
## Return-crossing collisions (the creator, 31 Oct 2026): instead of being put back at the last clear spot, the boat is thrown back from
## what it hit, further from where it is, and rocks hard. crossing_sequence.gd switches this on for the return and sets the numbers
## from data/world/crossing_sequence.json.
var hard_bounce := false
var bounce_distance_m := 11.0
var bounce_time_s := 1.2
var rock_deg := 14.0
var rock_time_s := 2.2
var bounce_stun_s := 0.8

var state := State.DOCKED
var rudder := 0.0
var velocity := Vector3.ZERO
## Tide / Wave hook from the spec: a push in m/s added to the boat's velocity each physics frame.
## Zero until the Tide / Wave agent supplies it.
var water_push := Vector2.ZERO
## Water taken on from wave hits, 0 (dry) to 1 (swamped). Drains slowly. Feedback for the HUD and Sound; no input is needed to bail.
var water_in_boat := 0.0
var current_zone: Node3D = null
var driving := false
## Non-empty: the boat will not cast off yet and the prompt says why (boarding_sequence.gd holds it until Arthur is aboard).
var cast_off_hold := ""

var _leave_zone: Node3D = null
var _grace_zone: Node3D = null    # the berth just left: hazards are ignored until the boat is out through its entrance
var _at_entrance := true          # docking: past the zone's entrance (or it has none)
var _stun := 0.0
var _bounce_vel := Vector3.ZERO     # the throw back after a hard hit, decaying to nothing over bounce_time_s
var _bounce_t := -1.0
var _base_pitch := 0.0              # the swell's pitch and roll, smoothed; a hard hit's rocking is added on top
var _base_roll := 0.0
var _rock_t := -1.0                 # time since a hard hit while the hull is still rocking
var _slow := 0.0                  # seconds of wave-hit slow-down left
var _slow_factor := 1.0
var _water_drain := 0.02
var _trail: Array[Transform3D] = []      # recent clear positions, newest last
var _trail_timer := 0.0
var _hull_shape := BoxShape3D.new()
var _player: Node3D = null
var _prompt: Label
var _rig: Node3D            # holds the hull model and its collision; this is what pitches and rolls
var _deck: AnimatableBody3D
var _hull: Node3D
var cargo: Node3D           # the cargo slot (a CarrySocket); what is put down on the deck rides with the hull


func _ready() -> void:
	_load_speed_from_spec()
	add_to_group("boat")   # GameState finds the boat by this group and turns its signals into events
	_build_rig()
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
	_float(0.0)


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
	_float(delta)
	if driving and _player:
		_player.rotate_y(rotation.y - yaw_before)   # the view turns with the boat
		_player.global_position = _rig.to_global(seat_offset)
	_handle_input()
	_update_prompt()


# --- public actions (also used by tools/test_boat.gd) ---

func board() -> void:
	if driving or _player == null:
		return
	driving = true
	_player.start_driving(self)


func cast_off() -> void:
	if state != State.DOCKED or not driving or cast_off_hold != "":
		return
	_leave_zone = current_zone
	_grace_zone = current_zone
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


## Wave hit (Wave workshop D3): a brief slow-down and some water in the boat. Never a capsize.
func apply_wave_hit(slow_s: float, slow_factor: float, water: float, drain_per_s: float) -> void:
	if state != State.SAILING:
		return
	_slow = slow_s
	_slow_factor = slow_factor
	_water_drain = drain_per_s
	water_in_boat = minf(1.0, water_in_boat + water)
	wave_hit.emit(water_in_boat)


## The crossing speed is data (boat_spec.json speed_mps), so it can be retuned after playtests without code.
func _load_speed_from_spec() -> void:
	var f := FileAccess.open("res://data/world/boat_spec.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary and d.has("speed_mps"):
		speed = float(d["speed_mps"])


# --- movement ---

func _sail(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right") if driving else 0.0
	rudder = move_toward(rudder, axis, delta / steer_response_s)
	rotation.y -= rudder * deg_to_rad(max_turn_rate_deg) * delta
	if _bounce_t >= 0.0:   # being thrown back from a hard hit: the throw decays; stop at once if it runs into something else
		_bounce_t += delta
		var left := 1.0 - _bounce_t / bounce_time_s
		if left <= 0.0:
			_bounce_t = -1.0
			_bounce_vel = Vector3.ZERO
		else:
			var before := global_position
			global_position += _bounce_vel * left * delta
			if _hits_hazard(global_transform):
				global_position = before
				_bounce_t = -1.0
				_bounce_vel = Vector3.ZERO
		velocity = Vector3.ZERO
		return
	if _stun > 0.0:   # after a hit: held still, but you can turn to line up a way out
		_stun -= delta
		velocity = Vector3.ZERO
		return
	var forward := -global_transform.basis.z
	_slow = maxf(0.0, _slow - delta)
	water_in_boat = move_toward(water_in_boat, 0.0, _water_drain * delta)
	var speed_now := speed * (_slow_factor if _slow > 0.0 else 1.0)
	velocity = velocity.lerp(forward * speed_now, 1.0 - pow(drift_factor, delta))
	var push := Vector3(water_push.x, 0.0, water_push.y)
	global_position += (velocity + push) * delta
	if _grace_zone and _flat_distance(_grace_zone) > _grace_distance(_grace_zone):
		_grace_zone = null
	if _grace_zone == null and _hits_hazard(global_transform):
		if hard_bounce:
			_hard_hit()
		else:
			_recover()
		return
	_trail_timer += delta
	if _trail_timer >= 0.5:
		_trail_timer = 0.0
		_trail.append(global_transform)
		if _trail.size() > 40:
			_trail.pop_front()
	# Entering a zone other than the one we just left starts auto-docking. Berths that share a zone_id
	# (the two in the lighthouse harbour) count as one place: none of them catches the boat until it
	# has cleared them all (berths and entrances), and coming back it ties up at the nearest.
	var zones := get_tree().get_nodes_in_group("dock_zone")
	if _leave_zone:
		var clear := true
		for zone in zones:
			if zone.zone_id == _leave_zone.zone_id and minf(_flat_distance(zone), _capture_distance(zone)) <= zone.radius + 2.0:
				clear = false
		if clear:
			_leave_zone = null
	var nearest: Node3D = null
	for zone in zones:
		if _leave_zone and zone.zone_id == _leave_zone.zone_id:
			continue
		if _capture_distance(zone) < zone.radius and (nearest == null or _capture_distance(zone) < _capture_distance(nearest)):
			nearest = zone
	if nearest:
		current_zone = nearest
		state = State.DOCKING
		_at_entrance = nearest.entrance == Vector3.ZERO
		docking_started.emit(nearest.zone_id)


func _dock(delta: float) -> void:
	rudder = move_toward(rudder, 0.0, delta / steer_response_s)
	rotation.y = lerp_angle(rotation.y, deg_to_rad(current_zone.berth_yaw_deg), 1.0 - exp(-1.5 * delta))
	var yaw_err := absf(angle_difference(rotation.y, deg_to_rad(current_zone.berth_yaw_deg)))
	# With an entrance: first to the entrance, then (once turned to the berth heading) straight in.
	var heading_in := _at_entrance        # past the entrance (or none): the goal is the berth itself
	var goal: Vector3 = current_zone.global_position if heading_in else current_zone.entrance
	var berth := Vector3(goal.x, global_position.y, goal.z)
	var to_berth := berth - global_position
	var dist := to_berth.length()
	if not heading_in and dist < 0.3:
		_at_entrance = true
	var hold: bool = _at_entrance and current_zone.entrance != Vector3.ZERO and yaw_err > 0.2
	var step := 0.0 if hold else minf(dock_approach_speed, dist * 0.7 + 0.15) * delta   # slows as it nears the berth
	velocity = to_berth.normalized() * (step / delta) if dist > 0.01 else Vector3.ZERO
	global_position += to_berth.normalized() * minf(step, dist)
	if heading_in and dist < 0.1 and yaw_err < 0.02:
		velocity = Vector3.ZERO
		state = State.DOCKED
		docked.emit(current_zone.zone_id)


## How far from a berth the boat is still leaving it: out through the harbour entrance (the piers either side
## brush the hull box, and the swell dips the hull below the dock's footings), or the zone's radius if it has none.
func _grace_distance(zone: Node3D) -> float:
	if zone.entrance != Vector3.ZERO:
		return Vector2(zone.global_position.x - zone.entrance.x, zone.global_position.z - zone.entrance.z).length() + 3.0
	return zone.radius + 2.0


func _hits_hazard(at: Transform3D) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _hull_shape
	q.transform = Transform3D(at.basis, at.origin + Vector3(0.0, 0.9, 0.0))
	q.collision_mask = hazard_mask
	return not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## A hard hit: clear the hull of what it struck, then throw the boat back along the line away from it, over bounce_time_s, and rock it.
## Nothing is reset: the boat ends further from where it was, wherever that is.
func _hard_hit() -> void:
	var away := Vector3.ZERO
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _hull_shape
	q.transform = Transform3D(global_transform.basis, global_position + Vector3(0.0, 0.9, 0.0))
	q.collision_mask = hazard_mask
	for h in get_world_3d().direct_space_state.intersect_shape(q, 1):
		var c := h["collider"] as Node3D
		if c != null:
			away = global_position - c.global_position
	away.y = 0.0
	if away.length() < 0.1:
		away = -(-global_transform.basis.z)        # no better idea: straight back
	away = away.normalized()
	for i in 16:                                    # step out of the overlap first, half a metre at a time
		if not _hits_hazard(global_transform):
			break
		global_position += away * 0.5
	_bounce_vel = away * (2.0 * bounce_distance_m / bounce_time_s)
	_bounce_t = 0.0
	_rock_t = 0.0
	_stun = bounce_stun_s
	velocity = Vector3.ZERO
	hazard_hit.emit()
	hard_hit.emit()


## Spec: on a hazard hit the boat bounces off and is moved to the nearest safe point with a small cost.
func _recover() -> void:
	var back := maxi(0, _trail.size() - 1 - int(recovery_back_s / 0.5))
	var target := Transform3D(global_transform.basis, global_position)
	var found := false
	for i in range(mini(back, _trail.size() - 1), -1, -1):   # empty trail (hit just after casting off): skip to the shove below
		if not _hits_hazard(_trail[i]):
			target = _trail[i]
			found = true
			break
	if found:
		global_position = target.origin
		rotation.y = target.basis.get_euler().y
		_trail.resize(maxi(0, back))
	else:
		# No clear trail yet: back to the berth just left (a shove along the bow line ran the boat up the shore).
		if current_zone:
			global_position = Vector3(current_zone.global_position.x, global_position.y, current_zone.global_position.z)
			rotation.y = deg_to_rad(current_zone.berth_yaw_deg)
			_grace_zone = current_zone
		else:
			var step := global_transform.basis.z * 1.0
			for i in 12:
				global_position += step
				if not _hits_hazard(global_transform):
					break
	velocity = Vector3.ZERO
	_stun = recovery_pause_s
	hazard_hit.emit()


## Rides the waves: height from the water under the hull, pitch and roll from the surface slope.
func _float(delta: float) -> void:
	var t: float = Sea.wave_time
	var fwd := -global_transform.basis.z
	var right := global_transform.basis.x
	var p := global_position
	var h_c := Sea.wave_height(p.x, p.z, t)
	var h_bow := Sea.wave_height(p.x + fwd.x * half_length, p.z + fwd.z * half_length, t)
	var h_stern := Sea.wave_height(p.x - fwd.x * half_length, p.z - fwd.z * half_length, t)
	var h_right := Sea.wave_height(p.x + right.x * half_beam, p.z + right.z * half_beam, t)
	var h_left := Sea.wave_height(p.x - right.x * half_beam, p.z - right.z * half_beam, t)
	var avg := (h_c * 2.0 + h_bow + h_stern + h_right + h_left) / 6.0
	global_position.y = water_level + avg * wave_follow - draft
	var pitch := atan2((h_bow - h_stern) * wave_follow, half_length * 2.0)
	var roll := atan2((h_right - h_left) * wave_follow, half_beam * 2.0) - rudder * 0.07
	var k := 1.0 if delta <= 0.0 else 1.0 - exp(-8.0 * delta)
	_base_pitch = lerp_angle(_base_pitch, pitch, k)
	_base_roll = lerp_angle(_base_roll, roll, k)
	var rock_roll := 0.0
	var rock_pitch := 0.0
	if _rock_t >= 0.0:     # after a hard hit the hull rocks hard, side to side, dying away; added after the swell smoothing so it is not softened
		_rock_t += delta
		var damp := exp(-_rock_t * 1.5)
		rock_roll = sin(_rock_t * 10.0) * deg_to_rad(rock_deg) * damp
		rock_pitch = sin(_rock_t * 7.5 + 1.0) * deg_to_rad(rock_deg * 0.45) * damp
		if _rock_t > rock_time_s:
			_rock_t = -1.0
	_rig.rotation.x = _base_pitch + rock_pitch
	_rig.rotation.z = _base_roll + rock_roll
	if _deck:
		_deck.global_transform = _rig.global_transform


## The hull model and a solid deck. The deck is an AnimatableBody3D, so a player standing on it is
## carried along as the boat heaves, tilts and sails.
func _build_rig() -> void:
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	cargo = load("res://scripts/interaction/carry_socket.gd").new()   # a child of the rig, so it pitches and rolls with the boat
	cargo.name = "CargoSlot"
	cargo.position = cargo_offset
	cargo.prompt = "Put it down"
	cargo.reach = 4.5            # the dock's landing is a few metres off the deck and above it, and the burner is
	cargo.vertical_reach = 3.5   # taken back from there, so it must be reachable without jumping aboard
	_rig.add_child(cargo)
	_hull = get_node_or_null("Hull")
	if _hull:
		_hull.reparent(_rig, false)
	_deck = AnimatableBody3D.new()
	_deck.name = "Deck"
	_deck.sync_to_physics = true
	_deck.collision_layer = 1      # the player walks on it; layer 2 (hazards) is for rocks, so the boat never hits itself
	_deck.collision_mask = 0
	# Not a child of the moving rig: a kinematic body only reports platform velocity (so a standing
	# player is carried) when ITS OWN transform changes. _float() copies the rig's transform onto it.
	_deck.top_level = true
	add_child(_deck)
	_deck.global_transform = _rig.global_transform
	if _hull == null:
		return
	var faces := PackedVector3Array()
	for mi in _hull.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var to_rig := _rig.global_transform.affine_inverse() * m.global_transform   # the deck body sits at the rig, so rig space
		for v in m.mesh.get_faces():
			faces.append(to_rig * v)
	if faces.is_empty():
		return
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_deck.add_child(cs)


func _flat_distance(node: Node3D) -> float:
	return Vector2(global_position.x - node.global_position.x, global_position.z - node.global_position.z).length()


## Flat distance to where a dock zone catches the boat (its entrance, or the berth).
func _capture_distance(zone: Node3D) -> float:
	var p: Vector3 = zone.capture_point()
	return Vector2(global_position.x - p.x, global_position.z - p.z).length()


# --- input and prompt ---

func _handle_input() -> void:
	if Input.is_action_just_pressed("interact"):
		if not driving and state == State.DOCKED and _player_in_reach() and not _interaction_busy():
			board()
		elif driving and state == State.DOCKED:
			cast_off()
	elif Input.is_action_just_pressed("disembark"):
		disembark()


## The Interaction autoload is offering something else right now (the cargo slot): leave that E to it.
func _interaction_busy() -> bool:
	var im := get_node_or_null("/root/Interaction")
	return im != null and im.focus != null


func _player_in_reach() -> bool:
	if _player == null:
		return false
	var d := Vector2(_player.global_position.x - global_position.x, _player.global_position.z - global_position.z).length()
	return d < board_radius and absf(_player.global_position.y - global_position.y) < 6.0


func _update_prompt() -> void:
	var text := ""
	if not driving:
		if state == State.DOCKED and _player_in_reach() and not _interaction_busy():
			text = "[E] Board the launch"
	elif state == State.DOCKED:
		text = "[E] Cast off      [Q] Step onto the dock" if cast_off_hold == "" else "[Q] Step onto the dock      (%s)" % cast_off_hold
	elif state == State.SAILING:
		text = "Rocks! Steer clear..." if _stun > 0.0 else "[A] / [D] Steer"
	elif state == State.DOCKING:
		text = "Docking..."
	_prompt.text = text
