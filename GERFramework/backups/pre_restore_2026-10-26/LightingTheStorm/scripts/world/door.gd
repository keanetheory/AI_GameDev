# door.gd - a hinged greybox door. Put this node at the hinge, at the sill: local X runs along the door (the panel
# extends to +X), Y is up, +Z faces outside. E opens it (it swings inward by open_angle_deg) and closes it again when
# the player is close and facing it. The panel's collision moves with it, so the doorway is blocked while it is shut.
# First used for the lighthouse's main entry (backlog T02). It is an Interactable (scripts/interaction/): the
# Interaction autoload owns the prompt, the reach and facing test, and the E key; this script only says what E does.
extends "res://scripts/interaction/interactable.gd"

signal opened
signal closed

@export var width := 1.8
@export var height := 3.0
@export var thickness := 0.1
@export var open_angle_deg := 100.0       # positive swings the free edge inward (towards -Z)
@export var swing_time_s := 0.6
@export var colour := Color(0.32, 0.22, 0.14)
@export var start_open := false

var is_open := false

var _leaf: AnimatableBody3D
var _tween: Tween


func _init() -> void:
	reach = 2.6   # metres (flat) from the door's middle (see reach_point)


func _ready() -> void:
	super._ready()
	add_to_group("door")
	_leaf = AnimatableBody3D.new()
	_leaf.name = "Leaf"
	_leaf.collision_layer = 1
	_leaf.collision_mask = 0
	add_child(_leaf)
	var box := BoxMesh.new()
	box.size = Vector3(width, height, thickness)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	box.material = mat
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	var centre := Vector3(width * 0.5, height * 0.5, -thickness * 0.5)   # just inside the outer face
	mesh.position = centre
	_leaf.add_child(mesh)
	var shape := BoxShape3D.new()
	shape.size = box.size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = centre
	_leaf.add_child(cs)
	if start_open:
		is_open = true
		_leaf.rotation.y = deg_to_rad(open_angle_deg)


func prompt_text() -> String:
	return "Close the door" if is_open else "Open the door"


func interact(player: Node3D) -> void:
	toggle()
	interacted.emit(player)


func reach_point() -> Vector3:
	return middle()


func aim_point() -> Vector3:
	return middle() + Vector3.UP * 1.4


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_swing(deg_to_rad(open_angle_deg))
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_swing(0.0)
	closed.emit()


## Middle of the doorway in world space (where reach is measured from).
func middle() -> Vector3:
	return to_global(Vector3(width * 0.5, 0.0, 0.0))


func _swing(target_y: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(_leaf, "rotation:y", target_y, swing_time_s)
