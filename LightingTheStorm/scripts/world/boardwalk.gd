# boardwalk.gd - a weathered timber walkway on piles that links two decks (quay to quay, or a quay to
# the road cut into the cliff). Set `points` (centre line, deck-top height in y); everything else is built.
# Walkable: a solid box under each stretch of planking (physics layer 1, so the boat does not treat it
# as a hazard). @tool: shows in the editor; the generated nodes have no owner, so nothing is saved
# into the scene and collision is only built when the game runs.
@tool
extends Node3D

## Centre line of the deck. y is the top of the planking.
@export var points: PackedVector3Array = PackedVector3Array([Vector3(0, 3, 0), Vector3(20, 3, 0)])
@export var width := 3.0
@export var rail_both_sides := true
@export var pile_spacing := 4.0
@export var water_floor := -3.5          # piles run down to here
@export var seed := 5

const PLANK := 0.30       # plank width along the walk
const GAP := 0.03
const THICK := 0.12

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	_rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var runs: Array = []          # [start, end, yaw] per straight stretch, for collision
	for seg in points.size() - 1:
		_build_segment(st, points[seg], points[seg + 1], seg == 0, seg == points.size() - 2)
		runs.append([points[seg], points[seg + 1]])
	var mi := MeshInstance3D.new()
	mi.name = "Timber"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	add_child(mi)
	if not Engine.is_editor_hint():
		_build_collision(runs)


func _build_segment(st: SurfaceTool, a: Vector3, b: Vector3, first: bool, last: bool) -> void:
	var dir := b - a
	var length := Vector2(dir.x, dir.z).length()
	var fwd := Vector3(dir.x, 0.0, dir.z).normalized()
	var side := Vector3(-fwd.z, 0.0, fwd.x)          # left of travel
	var slope := dir.y / maxf(length, 0.001)
	var wood := Color(0.30, 0.22, 0.14)
	var dark := Color(0.17, 0.12, 0.08)
	var rope := Color(0.36, 0.30, 0.20)
	var n_planks := int(length / (PLANK + GAP))
	# planking: each plank a little different in tone, length and height, like old boards
	for i in n_planks:
		var t := (i + 0.5) * (PLANK + GAP)
		var centre := a + fwd * t + Vector3(0.0, slope * t, 0.0)
		var tone := _rng.randf_range(0.78, 1.18)
		var jitter := _rng.randf_range(-0.012, 0.012)
		var w := width + _rng.randf_range(-0.05, 0.12)
		_oriented_box(st, centre + Vector3(0.0, jitter - THICK * 0.5, 0.0), fwd, side, Vector3(PLANK, THICK, w), wood * tone)
	# two long stringers under the planks
	for s in [-1.0, 1.0]:
		var mid: Vector3 = (a + b) * 0.5 + side * (width * 0.36 * s) + Vector3(0.0, -THICK - 0.14, 0.0)
		_oriented_box(st, mid, fwd, side, Vector3(length + 0.1, 0.26, 0.22), dark, slope)
	# piles down to the seabed, a pair every pile_spacing, with a cross-beam and a brace
	var n_piles := int(ceil(length / pile_spacing)) + 1
	for i in n_piles:
		var t := minf(i * pile_spacing, length)
		var top := a + fwd * t + Vector3(0.0, slope * t - THICK - 0.1, 0.0)
		var cross := top + Vector3(0.0, -0.22, 0.0)
		_oriented_box(st, cross, fwd, side, Vector3(0.22, 0.24, width + 0.5), dark)
		for s in [-1.0, 1.0]:
			var p: Vector3 = top + side * (width * 0.5 * s)
			var tone := _rng.randf_range(0.8, 1.15)
			_pile(st, p, top.y - water_floor, 0.17, dark * tone)
			if i % 2 == 0:
				_oriented_box(st, p + Vector3(0, -1.4, 0) - side * (0.28 * s), fwd, side, Vector3(0.1, 0.1, 1.5), dark * 0.9, 0.0, 0.0, 0.7 * s)
	# handrails: posts, a top rail and a rope
	var sides: Array = [-1.0, 1.0] if rail_both_sides else [1.0]
	for s in sides:
		var n_posts := int(ceil(length / 2.0)) + 1
		for i in n_posts:
			var t := minf(i * 2.0, length)
			if (first and t < 0.8) or (last and t > length - 0.8):
				continue      # keep the ends open where the walk meets a deck
			var base: Vector3 = a + fwd * t + Vector3(0.0, slope * t, 0.0) + side * (width * 0.5 * s)
			_oriented_box(st, base + Vector3(0, 0.5, 0), fwd, side, Vector3(0.12, 1.0, 0.12), wood * _rng.randf_range(0.8, 1.1))
		var rail_start := a + fwd * (0.8 if first else 0.0)
		var rail_end := b - fwd * (0.8 if last else 0.0)
		var rl := Vector2(rail_end.x - rail_start.x, rail_end.z - rail_start.z).length()
		if rl > 0.5:
			var mid: Vector3 = (rail_start + rail_end) * 0.5 + side * (width * 0.5 * s)
			_oriented_box(st, mid + Vector3(0, 1.02, 0), fwd, side, Vector3(rl, 0.09, 0.1), wood, slope)
			_oriented_box(st, mid + Vector3(0, 0.55, 0), fwd, side, Vector3(rl, 0.04, 0.04), rope, slope)


## A box centred at `c`. `size` is (along fwd, up, along side). `slope` tilts it along the walk;
## `yaw_extra` and `lean` add small extra turns (used for braces).
func _oriented_box(st: SurfaceTool, c: Vector3, fwd: Vector3, side: Vector3, size: Vector3, col: Color,
		slope := 0.0, _unused := 0.0, lean := 0.0) -> void:
	var up := Vector3.UP
	var f := (fwd + Vector3(0.0, slope, 0.0)).normalized()
	var u := up
	if lean != 0.0:
		u = (up + side * lean).normalized()
	var h := size * 0.5
	var corners: Array[Vector3] = []
	for sz in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sx in [-1.0, 1.0]:
				corners.append(c + f * (h.x * sx) + u * (h.y * sy) + side * (h.z * sz))
	# index = (sz:0/1)*4 + (sy)*2 + (sx)
	var faces := [
		[[0, 2, 3, 1], -side], [[4, 5, 7, 6], side],     # -side, +side
		[[0, 1, 5, 4], -u], [[2, 6, 7, 3], u],           # bottom, top
		[[0, 4, 6, 2], -f], [[1, 3, 7, 5], f]]           # back, front
	for fc in faces:
		var idx: Array = fc[0]
		_quad(st, corners[idx[0]], corners[idx[1]], corners[idx[2]], corners[idx[3]], col, fc[1])


func _pile(st: SurfaceTool, base_top: Vector3, depth: float, r: float, col: Color) -> void:
	var sides := 7
	var bottom := base_top - Vector3(0.0, depth, 0.0)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0t := base_top + Vector3(cos(a0), 0, sin(a0)) * r
		var p1t := base_top + Vector3(cos(a1), 0, sin(a1)) * r
		var p0b := bottom + Vector3(cos(a0), 0, sin(a0)) * r * 1.15
		var p1b := bottom + Vector3(cos(a1), 0, sin(a1)) * r * 1.15
		var mid := (a0 + a1) * 0.5
		_quad(st, p0t, p1t, p1b, p0b, col, Vector3(cos(mid), 0, sin(mid)))


## Quad from four corners; `want` is the outward direction. Godot treats clockwise-from-outside as the
## front face, so the winding is arranged that way and the normal points outward.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, want: Vector3) -> void:
	for tri in [[a, b, c], [a, c, d]]:
		var g: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
		if g.length() < 0.00001:
			continue
		if g.dot(want) > 0.0:
			tri = [tri[0], tri[2], tri[1]]
			g = -g
		var n := -g.normalized()
		for v in tri:
			st.set_normal(n)
			st.set_color(col)
			st.add_vertex(v)


func _build_collision(runs: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "Walkable"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for r in runs:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var dir := b - a
		var length := dir.length()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(length + 0.2, 0.3, width + 0.3)
		cs.shape = box
		var f := dir.normalized()
		var s := Vector3(-f.z, 0.0, f.x).normalized()
		var u := s.cross(f).normalized() * -1.0
		if u.y < 0.0:
			u = -u
		cs.transform = Transform3D(Basis(f, u, f.cross(u).normalized()), (a + b) * 0.5 - u * 0.15)
		body.add_child(cs)
