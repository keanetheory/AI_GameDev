# player.gd - first-person walker. WASD move, Shift sprint, Space jump, mouse look, Esc frees the mouse.
extends CharacterBody3D

@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.0025
## Highest ledge the player steps onto without jumping (metres).
@export var step_height := 0.4

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var _head: Node3D = $Head
var _spawn := Vector3.ZERO
## Set while the player is seated in the boat (see scripts/world/boat.gd).
var boat: Node3D = null


func _ready() -> void:
	_spawn = global_position
	add_to_group("player")
	floor_max_angle = deg_to_rad(60.0)
	floor_snap_length = 0.5
	floor_stop_on_slope = false
	max_slides = 6
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clamp(_head.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if boat:   # the boat carries us; it sets our position each frame
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	var dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := (transform.basis * Vector3(dir.x, 0.0, dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = wish.x * speed
	velocity.z = wish.z * speed
	_step_up(Vector3(velocity.x, 0.0, velocity.z) * delta)
	move_and_slide()
	if global_position.y < -40.0:  # fell out of the world
		global_position = _spawn
		velocity = Vector3.ZERO


## If something low blocks the way, lift the body over it; floor snapping brings it back down.
func _step_up(motion: Vector3) -> void:
	if not is_on_floor() or motion.length_squared() < 0.000001:
		return
	if not test_move(global_transform, motion):
		return
	var raised := global_transform.translated(Vector3.UP * step_height)
	if not test_move(raised, motion):
		global_position.y += step_height


## Called by the boat: sit at the helm. Walking and collision are off until stop_driving().
func start_driving(b: Node3D) -> void:
	boat = b
	velocity = Vector3.ZERO
	$CollisionShape3D.set_deferred("disabled", true)


## Step out of the boat onto the dock at `at`.
func stop_driving(at: Vector3) -> void:
	boat = null
	global_position = at
	velocity = Vector3.ZERO
	$CollisionShape3D.set_deferred("disabled", false)
