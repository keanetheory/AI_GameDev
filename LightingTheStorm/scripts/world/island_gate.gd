# island_gate.gd - the lockable iron gate at the top of the harbour stairs, on the one path from the dock up to the
# lighthouse (geography.md). The model (Assets/Models/island/island_gate.glb, built by tools/island/build_island_gate.py)
# has two meshes: "Frame" (pillars and wall stubs) and "Leaf", whose origin is on the hinge line at the ground. Put this
# node at the middle of the gateway on the ground, at the top of the HarbourStairs flight so the pillars span both parapets;
# the model's front (+Z, the padlock side) faces down the stairs to the dock.
# E opens and closes it; the leaf swings towards the dock by open_angle_deg, so it never sweeps the player on the
# lighthouse side. Collision: boxes for the two pillars and wall stubs, and a box on the leaf that moves with it.
# Story (backlog T04): once SAILORS_MOORED has fired, coming within approach_radius reports GATE_APPROACHED and the
# first opening reports GATE_OPENED. Before that it is just a gate, so using it early does not spend those beats.
extends "res://scripts/interaction/interactable.gd"

signal opened
signal closed

@export var model_path := "res://Assets/Models/island/island_gate.glb"
@export var open_angle_deg := 90.0      # positive swings the free edge towards +Z (down the stairs); more hits the east parapet
@export var swing_time_s := 0.9
@export var start_open := false
@export var approach_radius := 6.0
## Depth of the pillar and wall collision boxes (the model's rocks at the base stick out further than the masonry).
@export var wall_depth := 0.75

var is_open := false

var _hinge: AnimatableBody3D
var _leaf_box := AABB()
var _tween: Tween
var _gs: Node


func _init() -> void:
	prompt = "Open the gate"
	reach = 2.4


func _ready() -> void:
	super._ready()
	add_to_group("gate")
	_gs = get_node_or_null("/root/GameState")
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	add_child(model)
	var leaf := model.find_child("Leaf", true, false) as Node3D
	var frame := model.find_child("Frame", true, false) as Node3D
	if leaf == null or frame == null:
		push_error("island_gate: %s needs Frame and Leaf meshes" % model_path)
		return
	var frame_box := _local_aabb(frame)
	_leaf_box = _local_aabb(leaf)
	# the leaf swings on an AnimatableBody3D at its hinge (the Leaf's origin); the mesh is moved under it in place
	var leaf_xf := global_transform.affine_inverse() * leaf.global_transform
	_hinge = AnimatableBody3D.new()
	_hinge.name = "Hinge"
	_hinge.collision_layer = 1
	_hinge.collision_mask = 0
	_hinge.position = leaf_xf.origin
	add_child(_hinge)
	leaf.get_parent().remove_child(leaf)
	_hinge.add_child(leaf)
	leaf.transform = Transform3D(leaf_xf.basis, Vector3.ZERO)
	_add_box(_hinge, AABB(_leaf_box.position - _hinge.position, _leaf_box.size).grow(-0.02), 0.12)
	# pillars and wall stubs either side of the gateway
	var walls := StaticBody3D.new()
	walls.name = "Walls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	var top := frame_box.end.y
	var zc := _leaf_box.get_center().z
	for side in [[frame_box.position.x, _leaf_box.position.x], [_leaf_box.end.x, frame_box.end.x]]:
		var a := AABB(Vector3(side[0], 0.0, zc - wall_depth * 0.5), Vector3(side[1] - side[0], top, wall_depth))
		_add_box(walls, a, -1.0)
	_build_wings(frame, walls, frame_box)
	if start_open:
		is_open = true
		_hinge.rotation.y = deg_to_rad(open_angle_deg)


func _physics_process(_d: float) -> void:
	if _gs == null or not _story_live() or _gs.fired.has("GATE_APPROACHED"):
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p and p.global_position.distance_to(middle()) < approach_radius:
		_gs.emit_event("GATE_APPROACHED")


func prompt_text() -> String:
	return "Close the gate" if is_open else "Open the gate"


func interact(player: Node3D) -> void:
	toggle()
	interacted.emit(player)


func reach_point() -> Vector3:
	return middle()


func aim_point() -> Vector3:
	return middle() + Vector3.UP * 1.2


## Middle of the gateway at the ground, in world space.
func middle() -> Vector3:
	return to_global(Vector3(_leaf_box.get_center().x, 0.0, _leaf_box.get_center().z))


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_swing(deg_to_rad(open_angle_deg))   # the hinge is on +X: a positive turn about Y brings the free edge to +Z
	opened.emit()
	if _gs and _story_live():
		_gs.emit_event("GATE_OPENED")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_swing(0.0)
	closed.emit()


func _story_live() -> bool:
	return _gs.fired.has("SAILORS_MOORED")


func _swing(target_y: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(_hinge, "rotation:y", target_y, swing_time_s)


## Wing walls that tie the gate into the island either side (Island Creator ISL-14, creator 2026-10-27: the frame stood free, with sea and sky
## past the west pillar and open plateau past the east one). Coursed blocks in the frame's own stone, with collision on the Walls body.
## This node's space: x along the gate (west -), y up from the path, z towards the dock. Measured 2026-10-29 with a falling sphere: west of the
## gate the cliff drops about 1 m per 0.5 m to 4.3 m below the path at 3.5 m out; east, the plateau is level with the path and the rock on
## the stair side rises 0.4 to 1 m from 2.5 m out.
const WINGS := [
	# [x0, x1, top, bottom, yaw]: a run of courses from x0 to x1, turned by yaw degrees about its x0 end (negative turns it towards the dock).
	# West: a buttress stepping down the cliff face. East: a low wall angled back to the rock that rises on the stair side.
	[-2.95, -1.75, 1.5, -6.0, 0.0],
	[-3.7, -2.9, -0.5, -6.0, 0.0],
	[1.7, 2.9, 1.15, -0.9, -32.0],
	[2.8, 3.95, 0.7, -0.9, -32.0],
]
const COURSE := 0.3


func _build_wings(frame: Node3D, walls: StaticBody3D, frame_box: AABB) -> void:
	var mat: Material = null
	for mi in ([frame] + frame.find_children("*", "MeshInstance3D", true, false)):
		if mi is MeshInstance3D and (mi as MeshInstance3D).mesh != null:
			mat = (mi as MeshInstance3D).get_active_material(0)
			break
	var holder := Node3D.new()
	holder.name = "Wings"
	add_child(holder)
	var zc := frame_box.get_center().z
	var depth := 0.6
	var rng := RandomNumberGenerator.new()
	rng.seed = 1427
	var n := 0
	var pivot := 0.0
	for w in WINGS:
		var x0: float = w[0]
		var x1: float = w[1]
		var top: float = w[2]
		var bot: float = w[3]
		var yaw := deg_to_rad(float(w[4]))
		if absf(yaw) > 0.0 and absf(x0 - 1.7) < 0.01:
			pivot = x0                                      # every turned run turns about the east pillar's foot, so they stay in line
		var px := pivot if absf(yaw) > 0.0 else 0.0
		var run := Node3D.new()
		run.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(px, 0.0, zc)) * Transform3D(Basis(), Vector3(-px, 0.0, -zc))
		holder.add_child(run)
		var y := bot
		var row := 0
		while y < top - 0.05:
			var h := minf(COURSE, top - y)
			# blocks 0.3 to 0.55 m long, joints staggered row to row, each a little proud or shy of the face and of its neighbours so the ink
			# draws the masonry rather than one slab
			var cuts := [x0]
			var c := x0 + (0.2 if row % 2 == 1 else 0.0) + rng.randf_range(0.3, 0.55)
			while c < x1 - 0.2:
				cuts.append(c)
				c += rng.randf_range(0.3, 0.55)
			cuts.append(x1)
			for k in cuts.size() - 1:
				var mi := MeshInstance3D.new()
				mi.name = "Block_%d" % n
				n += 1
				var bm := BoxMesh.new()
				var d := depth + rng.randf_range(-0.08, 0.08)
				bm.size = Vector3(float(cuts[k + 1]) - float(cuts[k]) - 0.035, h - 0.035, d)
				mi.mesh = bm
				mi.material_override = mat
				mi.position = Vector3((float(cuts[k]) + float(cuts[k + 1])) * 0.5, y + h * 0.5, zc + rng.randf_range(-0.04, 0.04))
				run.add_child(mi)
			y += h
			row += 1
		var shape := BoxShape3D.new()
		shape.size = Vector3(x1 - x0, top - bot, depth)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.transform = run.transform * Transform3D(Basis(), Vector3((x0 + x1) * 0.5, (top + bot) * 0.5, zc))
		walls.add_child(cs)
	wing_blocks = n


var wing_blocks := 0


func _add_box(body: Node3D, box: AABB, min_depth: float) -> void:
	var size := box.size
	if min_depth > 0.0:
		size.z = maxf(size.z, min_depth)
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = box.get_center()
	body.add_child(cs)


## AABB of every mesh under `n` (and `n` itself), in this node's space.
func _local_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var inv := global_transform.affine_inverse()
	for mi in [n] + n.find_children("*", "MeshInstance3D", true, false):
		if not (mi is MeshInstance3D) or (mi as MeshInstance3D).mesh == null:
			continue
		var b := inv * (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
