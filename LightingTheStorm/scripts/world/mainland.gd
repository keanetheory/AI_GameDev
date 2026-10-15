# mainland.gd - the decorative mainland behind the cliffs: a forested plateau, the harbour road CUT INTO
# the cliff face from the Saltgate quay (an open-air cutting: the cliff face above the road is removed and
# replaced by a COPY of the cliff mesh and texture set back from the edge, so the road is a ledge in the
# rock itself), and the cart road through the trees to the city gate. The cut flares open into the quay at
# its east end (no end wall), so the wooden boardwalks run straight onto it. The ledge, its rock wall and
# the plateau all have collision when the game runs, so the whole walkway can be walked.
# Nothing here is walkable (no collision): it exists so the quay, cliffs and city read as one place.
# @tool: builds in the editor too. Generated nodes have no owner, so they are never saved in the .tscn.
@tool
extends Node3D

## Cliff-top height (convex hull of the cliff pieces at z = 590), every 10 m from x = -400. 0 = no cliff.
const TOPS_X0 := -400.0
const TOPS := [0, 0, 0, 0, 9.5, 29.1, 30.9, 31, 31.1, 31.1, 31.2, 31.2, 31.2, 31.3, 31.2, 30.6, 39.7, 39.7, 39.8, 39.8, 39.8, 39.9, 39.8, 39.7, 39.4, 38.7, 37.5, 36.3, 33.3, 33.3, 33.4, 33.5, 33.5, 33.5, 33.6, 33.1, 31.9, 42.1, 42.2, 42.2, 42.3, 42.3, 42.4, 42.2, 41.8, 40.7, 39.1, 32.2, 32.2, 32.3, 32.3, 32.3, 32.4, 32.4, 32.4, 31.9, 37.2, 37.2, 37.3, 37.3, 37.3, 37.4, 37.2, 37.1, 36.7, 36.1, 34.9, 35.2, 35.2, 35.2, 35.3, 35.3, 35.4, 35.4, 35.2, 34.5, 33.2, 32, 0, 0, 0, 0, 3, 0, 0]
## Ramp control points along the cliff face: x, deck height, z of the cliff face at that height.
const RAMP := [
	[14, 3, 560.5], [8, 4.01, 560.6], [2, 5.03, 560.7], [-4, 6.04, 560.9], [-10, 7.05, 561.1], [-16, 8.06, 561.3],
	[-22, 9.08, 561.6], [-28, 10.09, 562.1], [-34, 11.1, 557.9], [-40, 12.12, 557.3], [-46, 13.13, 557.3], [-52, 14.14, 557.4],
	[-58, 15.15, 557.6], [-64, 16.17, 557.8], [-70, 17.18, 557.9], [-76, 18.19, 558.2], [-82, 19.21, 558.4], [-88, 20.22, 558.6],
	[-94, 21.23, 558.8], [-100, 22.24, 559], [-106, 23.26, 559.2], [-112, 24.27, 559.5], [-118, 25.28, 559.7], [-124, 26.3, 559.9],
	[-130, 27.31, 560.1], [-136, 28.32, 561.3], [-142, 29.33, 565.6], [-148, 30.35, 565.7], [-154, 31.36, 565.9], [-160, 32.37, 566.1],
	[-166, 33.39, 566.3], [-172, 34.4, 566.5], [-178, 35.41, 567.5], [-184, 36.42, 568.4], [-190, 37.44, 569.4], [-196, 38.45, 570.7],
]

const ROAD_W := 6.0
const TERRAIN_X := Vector2(-350.0, 390.0)
const TERRAIN_Z := Vector2(580.0, 700.0)
const CITY_CENTRE := Vector2(15.0, 865.0)
const CITY_RADIUS := 245.0
## Road from the top of the ramp to the city gate (x, z). The first point continues the ramp.
const FOREST_ROAD := [Vector2(-196, 573.5), Vector2(-203, 579), Vector2(-206, 585), Vector2(-199, 597),
	Vector2(-181, 607), Vector2(-156, 612), Vector2(-129, 623), Vector2(-102, 617), Vector2(-76, 626),
	Vector2(-52, 636), Vector2(-31, 631), Vector2(-14, 641)]

@export var tree_count := 2600
@export var tree_seed := 11

var _noise := FastNoiseLite.new()
var _road_xz: Array[Vector2] = []     # forest road samples, for keeping trees off it


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	_noise.seed = 7
	_noise.frequency = 0.011
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_build_terrain()
	_build_roads()
	_build_trees()


# ---------- ground ----------

func cliff_top(x: float) -> float:
	var f := (x - TOPS_X0) / 10.0
	var i := clampi(int(floor(f)), 0, TOPS.size() - 2)
	var a: float = TOPS[i]
	var b: float = TOPS[i + 1]
	if a < 20.0:
		a = b
	if b < 20.0:
		b = a
	if a < 20.0:
		return 33.0
	return lerpf(a, b, clampf(f - i, 0.0, 1.0))


func terrain_h(x: float, z: float) -> float:
	var t := smoothstep(598.0, 640.0, z)
	var lip := cliff_top(x) - 2.0
	var forest := 38.4 - 2.4 * smoothstep(600.0, 645.0, z) + _noise.get_noise_2d(x, z) * 3.0 * (1.0 - 0.7 * smoothstep(620.0, 650.0, z))
	var h := lerpf(lip, forest, t)
	var edge := minf(minf(x - TERRAIN_X.x, TERRAIN_X.y - x), TERRAIN_Z.y - z)
	return lerpf(-3.0, h, smoothstep(0.0, 40.0, edge))


func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 5.0
	var nx := int((TERRAIN_X.y - TERRAIN_X.x) / step)
	var nz := int((TERRAIN_Z.y - TERRAIN_Z.x) / step)
	var verts: Array[Vector3] = []
	for j in nz + 1:
		for i in nx + 1:
			var x := TERRAIN_X.x + i * step
			var z := TERRAIN_Z.x + j * step
			verts.append(Vector3(x, terrain_h(x, z), z))
	for j in nz:
		for i in nx:
			var a := verts[j * (nx + 1) + i]
			var b := verts[j * (nx + 1) + i + 1]
			var c := verts[(j + 1) * (nx + 1) + i]
			var d := verts[(j + 1) * (nx + 1) + i + 1]
			for tri in [[a, b, c], [b, d, c]]:            # clockwise from above = front-facing in Godot
				var n: Vector3 = -(tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
				for v in tri:
					st.set_normal(n)
					st.set_color(_ground_colour(v, n))
					st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = st.commit()
	mi.material_override = _vertex_colour_material(1.0)
	add_child(mi)
	if not Engine.is_editor_hint():
		mi.create_trimesh_collision()      # so the top of the walkway leads onto ground you can stand on
		_solidify(mi, 1)


func _ground_colour(v: Vector3, n: Vector3) -> Color:
	var m := _noise.get_noise_2d(v.x * 2.3 + 91.0, v.z * 2.3) * 0.5 + 0.5
	var moss := Color(0.15, 0.19, 0.09).lerp(Color(0.30, 0.29, 0.13), m)   # forest floor to dry grass
	var rock := Color(0.22, 0.22, 0.23)
	return moss.lerp(rock, clampf((1.0 - n.y - 0.18) * 3.0, 0.0, 1.0))


# ---------- roads ----------

func _build_roads() -> void:
	_build_gallery()
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var end_i := int(round((GAL_X0 + 196.0) / GAL_STEP))
	var forest := _forest_points(Vector3(-196.0, _gal_y[end_i], 573.5))
	_sweep(stone, forest, ROAD_W + 2.4, 1.0, 0.0, 0.0, -0.06, Color(0.27, 0.27, 0.14), Color(0.20, 0.20, 0.12))   # worn grassy shoulder
	_sweep(stone, forest, ROAD_W, 1.0, 0.0, 0.0, 0.0, Color(0.42, 0.33, 0.22), Color(0.26, 0.26, 0.26))           # packed dirt
	_road_xz.clear()
	for i in range(0, forest.size(), 2):
		_road_xz.append(Vector2(forest[i].x, forest[i].z))
	var mi := MeshInstance3D.new()
	mi.name = "Roads"
	mi.mesh = stone.commit()
	mi.material_override = _vertex_colour_material(0.95)
	add_child(mi)


# ---------- the gallery road cut into the cliff ----------

const GAL_X0 := 46.0          # start, east of the quay; the road runs towards -x
const GAL_FLARE := Vector2(30.0, 46.0)   # between these x the cut tapers from full depth back to the plain cliff face
const GAL_X1 := -204.0        # end, on the cliff top
const GAL_STEP := 1.0
const GAL_DEPTH := 6.5        # how far the cut reaches into the rock (also the width of the road)

var _gal_y: Array[float] = []     # road height per step
var _gal_z: Array[float] = []     # cliff face z per step (smoothed)
var _gal_top: Array[float] = []   # top of the cut per step
var _gal_depth: Array[float] = []  # how far the cut reaches into the rock at each step


func _gallery_profile() -> void:
	_gal_y.clear()
	_gal_z.clear()
	_gal_top.clear()
	_gal_depth.clear()
	var n := int(round((GAL_X0 - GAL_X1) / GAL_STEP)) + 1
	var last: int = RAMP.size() - 1
	for i in n:
		var x := GAL_X0 - i * GAL_STEP
		var y := 3.0
		var z := 560.5 + 0.8 * clampf((x - 14.0) / 32.0, 0.0, 1.0)     # the face drifts out slightly towards the east
		if x < RAMP[0][0]:
			if x >= RAMP[last][0]:
				for k in last:
					var a: Array = RAMP[k]
					var b: Array = RAMP[k + 1]
					if x <= a[0] and x >= b[0]:
						var t: float = (a[0] - x) / (a[0] - b[0])
						y = lerpf(a[1], b[1], t)
						z = lerpf(a[2], b[2], t)
						break
			else:   # past the last control point: keep the grade up to the cliff top
				var a2: Array = RAMP[last - 1]
				var b2: Array = RAMP[last]
				y = b2[1] + (b2[1] - a2[1]) / (a2[0] - b2[0]) * (b2[0] - x)
				z = b2[2]
		_gal_y.append(y)
		_gal_z.append(z)
	for pass_i in 3:   # smooth the face wobble
		for i in range(1, n - 1):
			_gal_z[i] = (_gal_z[i - 1] + 2.0 * _gal_z[i] + _gal_z[i + 1]) * 0.25
	for i in n:
		var x := GAL_X0 - i * GAL_STEP
		_gal_top.append(_gal_y[i] + 90.0)      # open to the sky: everything above the road is cut away
		_gal_depth.append(GAL_DEPTH * (1.0 - smoothstep(GAL_FLARE.x, GAL_FLARE.y, x)))


## Metres the quay-end floor sticks out past the cliff face, so it meets the quay deck.
func _apron(x: float) -> float:
	return 4.0 * smoothstep(-8.0, 10.0, x)


var _cliff_mat: Material = null
var _wall_copies := 0


func _build_gallery() -> void:
	_gallery_profile()
	_carve_gallery()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var floor_col := Color(0.27, 0.23, 0.18)
	var lip := Color(0.30, 0.30, 0.29)
	var n := _gal_y.size()
	for i in n - 1:
		var x0 := GAL_X0 - i * GAL_STEP
		var x1 := x0 - GAL_STEP
		var y0 := _gal_y[i]
		var y1 := _gal_y[i + 1]
		var f0 := _gal_z[i] - 0.5 - _apron(x0)
		var f1 := _gal_z[i + 1] - 0.5 - _apron(x1)
		var b0 := _gal_z[i] + _gal_depth[i]
		var b1 := _gal_z[i + 1] + _gal_depth[i + 1]
		var shade := 0.86 + 0.26 * fposmod(i * 0.618, 1.0)      # block-to-block variation
		_quad(st, Vector3(x0, y0, f0), Vector3(x1, y1, f1), Vector3(x1, y1, b1), Vector3(x0, y0, b0), floor_col * shade, Vector3.UP)
		# stone lip on the front edge of the floor, and a corbel under any part that sticks out
		_quad(st, Vector3(x0, y0, f0), Vector3(x1, y1, f1), Vector3(x1, y1 - 1.2, f1 + 0.3), Vector3(x0, y0 - 1.2, f0 + 0.3), lip * shade, Vector3(0, 0, -1))
		if _apron(x0) > 0.15:
			_quad(st, Vector3(x0, y0 - 1.2, f0 + 0.3), Vector3(x1, y1 - 1.2, f1 + 0.3), Vector3(x1, y1 - 4.0, _gal_z[i + 1]), Vector3(x0, y1 - 4.0 + (y0 - y1), _gal_z[i]), lip * 0.8, Vector3(0, -1, -0.6).normalized())
	var mi := MeshInstance3D.new()
	mi.name = "Gallery"
	mi.mesh = st.commit()
	mi.material_override = _vertex_colour_material(1.0)
	add_child(mi)
	if not Engine.is_editor_hint():
		mi.create_trimesh_collision()
		_solidify(mi, 1)
	print("mainland: cut walkway - %d cliff-face copies set back as its rock wall" % _wall_copies)


## Makes the trimesh collision body just created under `mi` hit from both sides, on the given layers.
func _solidify(mi: MeshInstance3D, layers: int) -> void:
	for child in mi.get_children():
		if child is StaticBody3D and not child.is_queued_for_deletion():
			(child as StaticBody3D).collision_layer = layers
			for sh in child.get_children():
				var cs := sh as CollisionShape3D
				if cs and cs.shape is ConcavePolygonShape3D:
					(cs.shape as ConcavePolygonShape3D).backface_collision = true


## Removes the cliff face above the road and sets a COPY of it back by GAL_DEPTH as the rock wall of the
## cutting, so the road reads as a ledge cut into the cliffs themselves (same mesh, same texture).
func _carve_gallery() -> void:
	_wall_copies = 0
	var cliffs := get_parent().get_node_or_null("Cliffs") if get_parent() else null
	if cliffs == null:
		return
	for node in cliffs.get_children():
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			_carve_mesh(mi as MeshInstance3D)


func _carve_mesh(mi: MeshInstance3D) -> void:
	var src := mi.mesh as ArrayMesh
	if src == null:
		return
	var xf := mi.global_transform
	var nrm_basis := xf.basis.inverse().transposed()
	var wb: AABB = xf * src.get_aabb()
	if wb.end.x < GAL_X1 - 2.0 or wb.position.x > GAL_X0 + 2.0:
		return
	var steps := _gal_y.size()
	var carved := ArrayMesh.new()
	var copy := ArrayMesh.new()
	var removed := 0
	for surf in src.get_surface_count():
		var arrays := src.surface_get_arrays(surf)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			idx = PackedInt32Array(range(verts.size()))
		var kept := PackedInt32Array()
		var gone := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var c := xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
			if c.x <= GAL_X0 and c.x >= GAL_X1:
				var k := int((GAL_X0 - c.x) / GAL_STEP)
				if _gal_depth[k] > 0.15 and c.y >= _gal_y[k] - 0.15 and c.y <= _gal_top[k] \
						and c.z >= _gal_z[k] - 0.6 and c.z <= _gal_z[k] + _gal_depth[k]:
					removed += 1
					# keep only the sea-facing rock for the wall copy (not the grassy top); the mesh's own
					# vertex normals say which way a face points (its winding does not)
					var nrm := (xf.basis * (normals[idx[t]] + normals[idx[t + 1]] + normals[idx[t + 2]])).normalized()
					if nrm.z < -0.3:
						gone.append(idx[t])
						gone.append(idx[t + 1])
						gone.append(idx[t + 2])
					continue
			kept.append(idx[t])
			kept.append(idx[t + 1])
			kept.append(idx[t + 2])
		var mat := src.surface_get_material(surf)
		if _cliff_mat == null:
			_cliff_mat = mat
		arrays[Mesh.ARRAY_INDEX] = kept
		carved.add_surface_from_arrays(src.surface_get_primitive_type(surf), arrays)
		carved.surface_set_material(carved.get_surface_count() - 1, mat)
		if not gone.is_empty():
			# the copy is baked in world space; each vertex is set back by the cut's depth at its own x,
			# so where the cut tapers out the copy blends smoothly back into the plain cliff face
			var arrays2 := src.surface_get_arrays(surf)
			var cv := PackedVector3Array()
			var cn := PackedVector3Array()
			cv.resize(verts.size())
			cn.resize(verts.size())
			for vi in verts.size():
				var w := xf * verts[vi]
				var kk := clampi(int((GAL_X0 - w.x) / GAL_STEP), 0, steps - 1)
				cv[vi] = w + Vector3(0.0, 0.0, _gal_depth[kk])
				cn[vi] = (nrm_basis * normals[vi]).normalized()
			arrays2[Mesh.ARRAY_VERTEX] = cv
			arrays2[Mesh.ARRAY_NORMAL] = cn
			arrays2[Mesh.ARRAY_INDEX] = gone
			copy.add_surface_from_arrays(src.surface_get_primitive_type(surf), arrays2)
			copy.surface_set_material(copy.get_surface_count() - 1, mat)
			_wall_copies += gone.size() / 3
	mi.mesh = carved
	if copy.get_surface_count() > 0:
		var wall := MeshInstance3D.new()
		wall.name = "CutWall_" + str(mi.get_instance_id())
		wall.mesh = copy
		add_child(wall)
		if not Engine.is_editor_hint():
			wall.create_trimesh_collision()
			_solidify(wall, 3)
	if not Engine.is_editor_hint():
		# The cliff's solid hull would fill the cut. Swap it for collision that follows the carved mesh.
		for child in mi.get_children():
			if child is StaticBody3D:
				child.queue_free()
		mi.create_trimesh_collision()
		_solidify(mi, 3)


func _forest_points(from: Vector3) -> Array[Vector3]:
	var ctrl: Array[Vector3] = []
	for p in FOREST_ROAD:
		ctrl.append(Vector3(p.x, 0.0, p.y))
	var pts := _spline(ctrl, 18)
	var s := 0.0
	for i in pts.size():
		if i > 0:
			s += Vector2(pts[i].x - pts[i - 1].x, pts[i].z - pts[i - 1].z).length()
		var z := pts[i].z
		var offset := lerpf(2.1, 0.14, smoothstep(598.0, 630.0, z))   # raised on the lip, on the ground in the trees
		var ground := terrain_h(pts[i].x, z) + offset
		pts[i].y = lerpf(from.y, ground, smoothstep(0.0, 26.0, s))      # eases off the end of the ramp
	return pts


## Catmull-Rom through the control points, `per` samples per segment.
func _spline(ctrl: Array[Vector3], per: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in ctrl.size() - 1:
		var p0 := ctrl[maxi(i - 1, 0)]
		var p1 := ctrl[i]
		var p2 := ctrl[i + 1]
		var p3 := ctrl[mini(i + 2, ctrl.size() - 1)]
		for k in per:
			var t := float(k) / per
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	out.append(ctrl[ctrl.size() - 1])
	return out


## Extrudes a slab along a path. `width` is centred on the path (plus `inner_ext` on the inland side),
## `lateral` shifts it sideways (+ = left of travel), `lift` raises the top surface.
func _sweep(st: SurfaceTool, pts: Array[Vector3], width: float, thick: float, inner_ext: float,
		lateral: float, lift: float, top_col: Color, side_col: Color) -> void:
	var rows: Array = []
	for i in pts.size():
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, pts.size() - 1)]
		var t := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		var n := Vector3(-t.z, 0.0, t.x)            # left of travel
		var c := pts[i] + n * lateral + Vector3(0.0, lift, 0.0)
		var l := c + n * (width * 0.5)
		var r := c - n * (width * 0.5 + inner_ext)
		rows.append([l, r, l - Vector3(0, thick, 0), r - Vector3(0, thick, 0)])
	for i in rows.size() - 1:
		var p: Array = rows[i]
		var q: Array = rows[i + 1]
		var blk := 0.88 + 0.24 * float((i / 2) % 3 == 0) + 0.06 * float(i % 2)      # stone-course banding
		var lw: Vector3 = (p[0] - p[1]).normalized()      # towards the left edge
		_quad(st, p[0], q[0], q[1], p[1], top_col * blk, Vector3.UP)        # top
		_quad(st, p[2], p[3], q[3], q[2], side_col, Vector3.DOWN)           # underside
		_quad(st, p[0], p[2], q[2], q[0], side_col * blk, lw)               # left wall
		_quad(st, p[1], q[1], q[3], p[3], side_col, -lw)                    # right wall
	var f: Array = rows[0]
	var e: Array = rows[rows.size() - 1]
	var back: Vector3 = (rows[0][0] - rows[1][0]).normalized()
	var fwd: Vector3 = (rows[rows.size() - 1][0] - rows[rows.size() - 2][0]).normalized()
	_quad(st, f[0], f[1], f[3], f[2], side_col, back)
	_quad(st, e[0], e[2], e[3], e[1], side_col, fwd)


## One quad as two triangles. Godot treats CLOCKWISE (seen from outside) as front-facing, so the winding
## is arranged that way; `want` is the outward direction used to pick it, and the normal points outward.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, want := Vector3.ZERO) -> void:
	for tri in [[a, b, c], [a, c, d]]:
		var g: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
		if g.length() < 0.0001:
			continue                                  # degenerate (cone tips)
		if want != Vector3.ZERO and g.dot(want) > 0.0:
			tri = [tri[0], tri[2], tri[1]]            # reverse to clockwise-from-outside
			g = -g
		var n := -g.normalized()                      # outward
		for v in tri:
			st.set_normal(n)
			st.set_color(col)
			st.add_vertex(v)


func _box(st: SurfaceTool, centre: Vector3, size: Vector3, col: Color) -> void:
	var h := size * 0.5
	var c := [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	var faces := [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [3, 7, 6, 2], [1, 2, 6, 5], [0, 4, 7, 3]]
	var outs := [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(0, -1, 0), Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	for k in 6:
		var f: Array = faces[k]
		_quad(st, centre + c[f[0]], centre + c[f[1]], centre + c[f[2]], centre + c[f[3]], col, outs[k])


# ---------- trees ----------

func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = tree_seed
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _conifer_mesh()
	var xforms: Array[Transform3D] = []
	var cols: Array[Color] = []
	var tries := 0
	while xforms.size() < tree_count and tries < tree_count * 6:
		tries += 1
		var x := rng.randf_range(TERRAIN_X.x + 20.0, TERRAIN_X.y - 20.0)
		var z := rng.randf_range(TERRAIN_Z.x + 4.0, TERRAIN_Z.y - 20.0)
		if z < 574.0 or Vector2(x - CITY_CENTRE.x, z - CITY_CENTRE.y).length() < CITY_RADIUS:
			continue
		if _near_road(x, z):
			continue
		var y := terrain_h(x, z)
		if y < 5.0:
			continue
		var s := rng.randf_range(0.7, 1.6)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s * rng.randf_range(0.85, 1.15), s, s * rng.randf_range(0.85, 1.15)))
		xforms.append(Transform3D(basis, Vector3(x, y - 0.4, z)))
		var v := rng.randf_range(0.7, 1.15)
		cols.append(Color(v, v * rng.randf_range(0.95, 1.1), v, 1.0))
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Forest"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.material_override = _vertex_colour_material(1.0)
	add_child(mmi)


func _near_road(x: float, z: float) -> bool:
	for p in _road_xz:
		if absf(p.x - x) < 8.5 and absf(p.y - z) < 8.5 and Vector2(p.x - x, p.y - z).length() < 8.5:
			return true
	return false


func _conifer_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cone(st, Vector3(0, 0, 0), 0.45, 3.0, 6, Color(0.17, 0.12, 0.08))       # trunk
	_cone(st, Vector3(0, 2.0, 0), 3.4, 5.5, 8, Color(0.07, 0.15, 0.11))
	_cone(st, Vector3(0, 5.2, 0), 2.6, 5.0, 8, Color(0.08, 0.17, 0.12))
	_cone(st, Vector3(0, 8.2, 0), 1.7, 4.6, 8, Color(0.09, 0.19, 0.13))
	return st.commit()


func _cone(st: SurfaceTool, base: Vector3, radius: float, height: float, sides: int, col: Color) -> void:
	var tip := base + Vector3(0, height, 0)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0 := base + Vector3(cos(a0), 0, sin(a0)) * radius
		var p1 := base + Vector3(cos(a1), 0, sin(a1)) * radius
		var mid := (a0 + a1) * 0.5
		var side_out := Vector3(cos(mid), 0.55, sin(mid)).normalized()
		_quad(st, p0, p1, tip, tip, col, side_out)
		_quad(st, base, p1, p0, p0, col, Vector3.DOWN)


func _vertex_colour_material(rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
