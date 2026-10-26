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
## LHF-12: boards, iron straps, studs and a ring handle instead of one flat box (the collision is the same box).
@export var detailed := true

var is_open := false

var _leaf: AnimatableBody3D
var _tween: Tween


func _init() -> void:
	reach = 2.6   # metres (flat) from the door's middle (see reach_point)


func _ready() -> void:
	if OS.get_environment("LHF_SHELL") == "2":      # the authored shell cuts the opening to this height (data/world/shell_spec.json front_door_h), under the 3.75 m ceiling
		height = 2.7
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
	var centre := Vector3(width * 0.5, height * 0.5, -thickness * 0.5)   # just inside the outer face
	if detailed:
		_build_planks(centre)
	else:
		var mesh := MeshInstance3D.new()
		mesh.mesh = box
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


## The leaf's look: vertical boards (three tones, slightly different lengths), three iron straps with studs on both faces, hinge
## straps on the hinge edge, and a ring handle on the free edge. All visual; `centre` is the leaf's middle.
func _build_planks(centre: Vector3) -> void:
	var vis := Node3D.new()
	vis.name = "Planks"
	vis.position = centre
	_leaf.add_child(vis)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var tones := [colour, colour.lightened(0.1), colour.darkened(0.12)]
	var mats: Array[StandardMaterial3D] = []
	for t in tones:
		var m := StandardMaterial3D.new()
		m.albedo_color = t
		m.roughness = 0.9
		mats.append(m)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.07, 0.075, 0.09)
	iron.roughness = 0.55
	iron.metallic = 0.5
	var n := 9
	var pw := width / float(n)
	for i in n:
		var bm := BoxMesh.new()
		var ph := height - rng.randf_range(0.0, 0.03)
		bm.size = Vector3(pw - 0.012, ph, thickness)
		var mi := MeshInstance3D.new()
		mi.name = "Plank%d" % i
		mi.mesh = bm
		mi.material_override = mats[i % 3]
		mi.position = Vector3(-width * 0.5 + pw * (i + 0.5), (ph - height) * 0.5, 0.0)
		vis.add_child(mi)
	for face in [1.0, -1.0]:
		var z: float = (thickness * 0.5 + 0.006) * face
		for sy in [-height * 0.4, 0.0, height * 0.4]:
			var sb := BoxMesh.new()
			sb.size = Vector3(width - 0.08, 0.13, 0.014)
			var strap := MeshInstance3D.new()
			strap.name = "Strap"
			strap.mesh = sb
			strap.material_override = iron
			strap.position = Vector3(0.0, sy, z)
			vis.add_child(strap)
			for k in 9:
				var st := BoxMesh.new()
				st.size = Vector3(0.045, 0.045, 0.02)
				var stud := MeshInstance3D.new()
				stud.name = "Stud"
				stud.mesh = st
				stud.material_override = iron
				stud.position = Vector3(-width * 0.5 + 0.14 + (width - 0.28) * float(k) / 8.0, sy, z + 0.01 * face)
				vis.add_child(stud)
	# the ring handle and its plate, on the free edge (+x), outside
	var plate := BoxMesh.new()
	plate.size = Vector3(0.12, 0.22, 0.02)
	var pm := MeshInstance3D.new()
	pm.name = "HandlePlate"
	pm.mesh = plate
	pm.material_override = iron
	pm.position = Vector3(width * 0.5 - 0.22, -height * 0.05, thickness * 0.5 + 0.02)
	vis.add_child(pm)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.045
	ring.outer_radius = 0.065
	var rm := MeshInstance3D.new()
	rm.name = "HandleRing"
	rm.mesh = ring
	rm.material_override = iron
	rm.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	rm.position = Vector3(width * 0.5 - 0.22, -height * 0.05 - 0.06, thickness * 0.5 + 0.05)
	vis.add_child(rm)
