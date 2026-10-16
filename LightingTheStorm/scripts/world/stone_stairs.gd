# stone_stairs.gd - a built flight of dressed-stone stairs with landings and parapets, standing on its
# own solid masonry (e.g. against the cliff from the harbour quay up to the plateau). Set `points`
# (centre line; y is the walking surface): a segment that climbs becomes steps, a level one a paved
# landing. Everything is built down to base_y, so the stairs never need the ground cut away - lay the
# line where the ground stays below the steps.
# Walkable: a smooth ramp under each flight and a box under each landing (physics layer 1); the parapets
# are solid too. @tool: shows in the editor; the generated nodes have no owner, so nothing is saved
# into the scene and collision is only built when the game runs.
@tool
extends Node3D

## Centre line. y is the walking surface (the top of the steps / paving).
@export var points: PackedVector3Array = PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, -2), Vector3(0, 3, -8)])
@export var width := 1.8
## Target height of one step; each flight is split into whole steps as close to this as fits.
@export var rise := 0.17
## Parapets per segment: 1 = left of travel, 2 = right, 3 = both, 0 = none. Missing entries mean both.
@export var walls: PackedInt32Array = PackedInt32Array()
## A parapet across the start of the first segment (e.g. a landing that is entered from the side).
@export var start_wall := false
@export var wall_thickness := 0.3
## Height of the parapets above the steps.
@export var parapet := 0.9
## Everything is built down to this height (hidden in the ground, the quay or the sea).
@export var base_y := 0.0
@export var stone := Color(0.5, 0.5, 0.47)
@export var seed := 7

const SLAB := 0.16        # depth of a step / paving stone above the masonry below it
const COURSE := 0.4       # height of a masonry course in the walls
const COPING := 0.18      # depth of the parapet coping

var _rng := RandomNumberGenerator.new()
var _shapes: Array = []   # [Shape3D, Transform3D] collected while building


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	_rng.seed = seed
	_shapes.clear()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var flags := walls[i] if i < walls.size() else 3
		_build_segment(st, points[i], points[i + 1], flags, i == 0 and start_wall)
	var mi := MeshInstance3D.new()
	mi.name = "Stone"
	mi.mesh = st.commit()
	mi.material_override = _material()
	add_child(mi)
	if not Engine.is_editor_hint():
		_build_collision()


func _build_segment(st: SurfaceTool, a: Vector3, b: Vector3, flags: int, cap_start: bool) -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var length := flat.length()
	if length < 0.01:
		return
	var fwd := flat / length
	var right := fwd.cross(Vector3.UP).normalized()
	var dy := b.y - a.y
	var climbs := absf(dy) > 0.01
	var n := maxi(1, roundi(absf(dy) / rise)) if climbs else 1
	var tread := length / n
	var mass := stone * 0.8
	if climbs:
		# one dressed slab per step on solid masonry; the slab overhangs the riser a little
		for k in n:
			var y := a.y + dy * (k + 1) / n
			var mid := a + fwd * ((k + 0.5) * tread)
			var tone := _rng.randf_range(0.94, 1.05)
			_box(st, Vector3(mid.x, y - SLAB * 0.5, mid.z) - fwd * 0.015, fwd, right, Vector3(tread + 0.03, SLAB, width), stone * tone)
			_box(st, Vector3(mid.x, (base_y + y - SLAB) * 0.5, mid.z), fwd, right, Vector3(tread, y - SLAB - base_y, width), mass)
		var te := length - tread    # ramp from the bottom to the front edge of the top step
		_add_wedge(a, fwd, right, te, a.y, b.y)
		_add_box(a + fwd * ((te + length) * 0.5), fwd, right, Vector3(tread + 0.05, b.y - base_y, width), base_y)
	else:
		# a landing: paving stones the full width, joints across the walk
		var t := 0.0
		var pave := length / maxi(1, roundi(length / 0.75))
		while t < length - 0.01:
			var mid := a + fwd * (t + pave * 0.5)
			_box(st, Vector3(mid.x, a.y - SLAB * 0.5, mid.z), fwd, right, Vector3(pave - 0.02, SLAB, width), stone * _rng.randf_range(0.94, 1.05))
			t += pave
		var c := a + fwd * (length * 0.5)
		_box(st, Vector3(c.x, (base_y + a.y - SLAB) * 0.5, c.z), fwd, right, Vector3(length, a.y - SLAB - base_y, width), mass)
		_add_box(c, fwd, right, Vector3(length, a.y - base_y, width), base_y)
	# parapets: coursed masonry from the base, with a coping that runs smoothly with the slope
	for side in [-1.0, 1.0]:
		if (side < 0.0 and flags & 1 == 0) or (side > 0.0 and flags & 2 == 0):
			continue
		var offset: Vector3 = right * (side * (width + wall_thickness) * 0.5)
		var pieces := n if climbs else maxi(1, roundi(length / 0.8))
		var piece := length / pieces
		for k in pieces:
			var t0 := k * piece
			var t1 := t0 + piece
			var c0 := a.y + dy * t0 / length + parapet
			var c1 := a.y + dy * t1 / length + parapet
			var centre: Vector3 = a + fwd * (t0 + piece * 0.5) + offset
			_courses(st, centre, fwd, right, piece + 0.01, minf(c0, c1) - COPING + 0.03)
			var e0: Vector3 = a + fwd * t0 + offset
			var e1: Vector3 = a + fwd * t1 + offset
			_slab(st, Vector3(e0.x, c0, e0.z), Vector3(e1.x, c1, e1.z), right, wall_thickness * 0.5 + 0.03, COPING, stone * 1.04)
			_add_box(centre, fwd, right, Vector3(piece, maxf(c0, c1) - base_y, wall_thickness), base_y)
	if cap_start:
		var centre := a - fwd * (wall_thickness * 0.5)
		var top := a.y + parapet
		var across := width + wall_thickness * 2.0
		_courses(st, centre, right, -fwd, across, top - COPING + 0.03)
		_box(st, Vector3(centre.x, top - COPING * 0.5, centre.z), right, -fwd, Vector3(across + 0.06, COPING, wall_thickness + 0.06), stone * 1.04)
		_add_box(centre, right, -fwd, Vector3(across, top - base_y, wall_thickness), base_y)


## Masonry courses from base_y up to `top`, `length` long along fwd and wall_thickness across.
func _courses(st: SurfaceTool, centre: Vector3, fwd: Vector3, right: Vector3, length: float, top: float) -> void:
	var y := base_y
	while y < top - 0.02:
		var h := minf(COURSE, top - y)
		_box(st, Vector3(centre.x, y + h * 0.5, centre.z), fwd, right, Vector3(length, h - 0.012, wall_thickness), stone * _rng.randf_range(0.86, 0.98))
		y += h


# --- mesh helpers ---

func _material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.05
	noise.seed = seed
	var grain := Gradient.new()
	grain.set_color(0, Color(0.66, 0.66, 0.64))
	grain.set_color(1, Color(1.0, 1.0, 1.0))
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.color_ramp = grain
	tex.width = 256
	tex.height = 256
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.7, 0.7, 0.7)
	return m


## A box centred at c; size is (along fwd, up, along right).
func _box(st: SurfaceTool, c: Vector3, fwd: Vector3, right: Vector3, size: Vector3, col: Color) -> void:
	if size.y <= 0.0:
		return
	var h := size * 0.5
	var u := Vector3.UP
	var p := func(sx: float, sy: float, sz: float) -> Vector3: return c + fwd * (h.x * sx) + u * (h.y * sy) + right * (h.z * sz)
	_quad(st, p.call(-1, 1, -1), p.call(1, 1, -1), p.call(1, 1, 1), p.call(-1, 1, 1), col, u)
	_quad(st, p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, -1, -1), col, -u)
	_quad(st, p.call(1, -1, -1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(1, 1, -1), col, fwd)
	_quad(st, p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(-1, 1, 1), p.call(-1, -1, 1), col, -fwd)
	_quad(st, p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, -1, 1), col, right)
	_quad(st, p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(-1, 1, -1), col, -right)


## A slab whose top runs from p0 to p1 (centre line, any slope), `half` either side across `right`,
## with vertical sides `thick` deep.
func _slab(st: SurfaceTool, p0: Vector3, p1: Vector3, right: Vector3, half: float, thick: float, col: Color) -> void:
	var r := right * half
	var d := Vector3(0.0, thick, 0.0)
	var along := (p1 - p0).normalized()
	var up := right.cross(along).normalized()
	if up.y < 0.0:
		up = -up
	_quad(st, p0 - r, p1 - r, p1 + r, p0 + r, col, up)
	_quad(st, p0 - r - d, p0 + r - d, p1 + r - d, p1 - r - d, col, -up)
	_quad(st, p0 + r, p1 + r, p1 + r - d, p0 + r - d, col, right)
	_quad(st, p0 - r, p0 - r - d, p1 - r - d, p1 - r, col, -right)
	_quad(st, p1 - r, p1 - r - d, p1 + r - d, p1 + r, col, along)
	_quad(st, p0 - r, p0 + r, p0 + r - d, p0 - r - d, col, -along)


## Quad from four corners; `want` is the outward direction (the winding is fixed up to face it).
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, want: Vector3) -> void:
	for tri in [[a, b, c], [a, c, d]]:
		var g: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
		if g.length() < 0.00001:
			continue
		if g.dot(want) > 0.0:
			tri = [tri[0], tri[2], tri[1]]
		for v in tri:
			st.set_normal(want)
			st.set_color(col)
			st.add_vertex(v)


# --- collision ---

## Solid box from `base` up `size.y`, centred on `c` in x/z; size is (along fwd, height, along right).
func _add_box(c: Vector3, fwd: Vector3, right: Vector3, size: Vector3, base: float) -> void:
	if size.y <= 0.01:
		return
	var box := BoxShape3D.new()
	box.size = Vector3(size.z, size.y, size.x)
	_shapes.append([box, Transform3D(Basis(right, Vector3.UP, -fwd), Vector3(c.x, base + size.y * 0.5, c.z))])


## Smooth ramp under a flight: from y0 at the bottom to y1 at `te` along the segment, filled down to base.
func _add_wedge(a: Vector3, fwd: Vector3, right: Vector3, te: float, y0: float, y1: float) -> void:
	var pts := PackedVector3Array()
	for s in [-0.5, 0.5]:
		var side: Vector3 = right * (width * s)
		var p0 := Vector3(a.x, 0.0, a.z) + side
		var p1 := p0 + fwd * te
		pts.append_array([Vector3(p0.x, base_y, p0.z), Vector3(p0.x, y0, p0.z), Vector3(p1.x, base_y, p1.z), Vector3(p1.x, y1, p1.z)])
	var shape := ConvexPolygonShape3D.new()
	shape.points = pts
	_shapes.append([shape, Transform3D.IDENTITY])


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Walkable"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.global_transform = Transform3D.IDENTITY
	for s in _shapes:
		var cs := CollisionShape3D.new()
		cs.shape = s[0]
		cs.transform = s[1]
		body.add_child(cs)
