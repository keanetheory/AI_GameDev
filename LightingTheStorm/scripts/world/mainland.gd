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
const TREE_MIN_Z := 584.0     # trees stay back from the cliff lip: bare moss and rock on the edge
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
var _tops_real: Array[float] = []     # cliff-top height measured from the actual cliff meshes (see _measure_tops)
var _road_xz: Array[Vector2] = []     # forest road samples, for keeping trees off it


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	_noise.seed = 7
	_noise.frequency = 0.011
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_measure_tops()
	_build_terrain()
	_build_roads()
	_build_trees()


# ---------- ground ----------

## Measures the top surface of the cliff pieces at z = 590, every 10 m, straight from their meshes (before
## the walkway is cut). The baked TOPS table came from the solid collision hull, which stands a little
## above the visible rock, so the plateau built from it floated above the real cliff top.
func _measure_tops() -> void:
	_tops_real.clear()
	var cliffs := get_parent().get_node_or_null("Cliffs") if get_parent() else null
	if cliffs == null:
		return
	var best: Array[float] = []
	best.resize(TOPS.size())
	best.fill(0.0)
	const Z := 590.0
	for node in cliffs.get_children():
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var xf := m.global_transform
			var wb: AABB = xf * m.mesh.get_aabb()
			if wb.position.z > Z or wb.end.z < Z:
				continue
			var faces := m.mesh.get_faces()
			for t in range(0, faces.size(), 3):
				var a := xf * faces[t]
				var b := xf * faces[t + 1]
				var c := xf * faces[t + 2]
				if (a.z > Z and b.z > Z and c.z > Z) or (a.z < Z and b.z < Z and c.z < Z):
					continue            # does not cross the line z = 590
				var x_lo := minf(a.x, minf(b.x, c.x))
				var x_hi := maxf(a.x, maxf(b.x, c.x))
				var i0 := maxi(0, int(ceil((x_lo - TOPS_X0) / 10.0)))
				var i1 := mini(best.size() - 1, int(floor((x_hi - TOPS_X0) / 10.0)))
				for i in range(i0, i1 + 1):
					var px := TOPS_X0 + i * 10.0
					var d := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
					if absf(d) < 0.000001:
						continue
					var l1 := ((b.z - c.z) * (px - c.x) + (c.x - b.x) * (Z - c.z)) / d
					var l2 := ((c.z - a.z) * (px - c.x) + (a.x - c.x) * (Z - c.z)) / d
					var l3 := 1.0 - l1 - l2
					if l1 >= 0.0 and l2 >= 0.0 and l3 >= 0.0:
						best[i] = maxf(best[i], l1 * a.y + l2 * b.y + l3 * c.y)
	_tops_real = best


func cliff_top(x: float) -> float:
	var f := (x - TOPS_X0) / 10.0
	var i := clampi(int(floor(f)), 0, TOPS.size() - 2)
	var table: Array = _tops_real if _tops_real.size() == TOPS.size() else TOPS
	var a: float = table[i]
	var b: float = table[i + 1]
	if a < 20.0:
		a = b
	if b < 20.0:
		b = a
	if a < 20.0:
		return 33.0
	return lerpf(a, b, clampf(f - i, 0.0, 1.0))


func terrain_h(x: float, z: float) -> float:
	var t := smoothstep(598.0, 640.0, z)
	var lip := cliff_top(x) - 0.4
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
	var forest := _forest_points(_walk_end if _walk_end != Vector3.ZERO else Vector3(-196.0, 38.0, 573.5))
	_road_xz.clear()
	for i in range(0, forest.size(), 2):
		_road_xz.append(Vector2(forest[i].x, forest[i].z))
	# Two surfaces: a worn, grassy shoulder that fades the path into the ground, and the packed earth itself.
	var shoulder := SurfaceTool.new()
	shoulder.begin(Mesh.PRIMITIVE_TRIANGLES)
	_sweep(shoulder, forest, ROAD_W + 3.2, PATH_THICK, 0.0, 0.0, -0.08, Color(0.20, 0.21, 0.11), Color(0.16, 0.16, 0.09), 0.18, 14.0)
	var earth := SurfaceTool.new()
	earth.begin(Mesh.PRIMITIVE_TRIANGLES)
	_sweep(earth, forest, ROAD_W, PATH_THICK, 0.0, 0.0, 0.0, Color(1.0, 1.0, 1.0), Color(0.45, 0.40, 0.33), 0.12, 10.0)
	var mesh := shoulder.commit()
	earth.commit(mesh)
	mesh.surface_set_material(0, _vertex_colour_material(1.0))
	mesh.surface_set_material(1, _earth_material())
	var mi := MeshInstance3D.new()
	mi.name = "Roads"
	mi.mesh = mesh
	add_child(mi)
	if not Engine.is_editor_hint():
		mi.create_trimesh_collision()      # the path is solid ground: it was visual only, so the player fell through it
		_solidify(mi, 1)


## Packed earth for the path: a seamless mottled brown with grit and the odd stone, mapped in world space so the
## path carries no texture seams. Built here (no asset to import) and cached.
var _earth_mat: StandardMaterial3D = null


func _earth_material() -> Material:
	if _earth_mat != null:
		return _earth_mat
	const N := 256
	var n1 := FastNoiseLite.new()
	n1.seed = 21
	n1.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n1.frequency = 0.035
	n1.fractal_octaves = 4
	var img1: Image = n1.get_seamless_image(N, N)
	var n2 := FastNoiseLite.new()
	n2.seed = 5
	n2.noise_type = FastNoiseLite.TYPE_CELLULAR
	n2.frequency = 0.09
	var img2: Image = n2.get_seamless_image(N, N)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var img := Image.create(N, N, false, Image.FORMAT_RGB8)
	var dark := Color(0.26, 0.18, 0.11)
	var mid := Color(0.46, 0.33, 0.21)
	var dry := Color(0.60, 0.47, 0.31)
	var stone := Color(0.55, 0.52, 0.47)
	for y in N:
		for x in N:
			var v: float = img1.get_pixel(x, y).r
			var c := dark.lerp(mid, clampf(v * 1.6, 0.0, 1.0)).lerp(dry, clampf((v - 0.55) * 2.5, 0.0, 1.0))
			var cell: float = img2.get_pixel(x, y).r
			if cell > 0.86:                      # pebbles
				c = c.lerp(stone, 0.7)
			c = c * (0.93 + 0.14 * rng.randf())   # grit
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.vertex_color_use_as_albedo = true
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.22, 0.22, 0.22)
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_earth_mat = m
	return m


# ---------- the walkway: a rock ledge built against the UNCUT cliff face ----------
# Nothing is cut from the cliff. tools/bake_walkway.gd measures the real rock along the walkway and writes
# data/world/walkway_profile.json; this builds the ledge from it: a floor in front of the face with its back edge
# buried in the rock, a shelf of rock under it sloping back into the face, and a toe where floor meets wall, all in the
# cliff's own material. The cliff above and behind stays whole, so there is nothing to see through.

const GAL_X0 := 46.0          # start, at the quay's east end; the walkway runs towards -x
const GAL_STEP := 1.0
const WALK_W := 6.5           # width of the walkway in front of the face
const CLEAR := 3.5            # the floor starts at least this far in front of the most protruding rock at floor height
const BURY := 1.2             # how far the floor's back edge is buried in the rock
const ROCK_TILE := 0.07       # world-space texture scale for the ledge: one tile of the cliff texture every ~14 m
const EDGE_WANDER := 0.6      # how far the sea-side edge of the walkway wanders, metres
const FLOOR_BUMP := 0.07      # unevenness of the walkway floor, metres
const PATH_THICK := 2.5       # the path slab is sunk this deep, so it never hovers over the ground with daylight under it
const TOE_HEIGHT := 1.4       # height of the rock toe where the floor meets the cliff wall
const TOE_DEPTH := 1.8        # how far out from the wall the toe reaches
const SHELF_DROP := 5.0       # how far the rock under the sea-side edge slopes down towards the face
const QUAY_FRONT_Z := 560.2   # at the quay end the floor reaches out to meet the boardwalks and the link ramp: its front edge is here at x = -8 ...
const QUAY_APRON := 4.0       # ... and this much further out by x = 10, as before the rebuild
const PROFILE_PATH := "res://data/world/walkway_profile.json"

var _gal_y: Array[float] = []      # floor height per step
var _gal_z: Array[float] = []      # z of the floor's front (sea-side) edge per step
var _gal_depth: Array[float] = []  # front edge to buried back edge per step
var _gal_low: Array[float] = []    # z of the cliff face three metres below the floor
var _gal_taper: Array[float] = []  # 1 along the ledge, easing to 0 over its last metres, where it runs out flush
var _walk_end := Vector3.ZERO      # centre of the ledge's far end: where the earth path begins
var _cliff_mat: Material = null


## Floor height of the ramp at x (before it is held to the ground behind).
func ramp_y(x: float) -> float:
	if x >= RAMP[0][0]:
		return 3.0
	var last: int = RAMP.size() - 1
	if x < RAMP[last][0]:
		var a2: Array = RAMP[last - 1]
		var b2: Array = RAMP[last]
		return b2[1] + (b2[1] - a2[1]) / (a2[0] - b2[0]) * (b2[0] - x)
	for k in last:
		var a: Array = RAMP[k]
		var b: Array = RAMP[k + 1]
		if x <= a[0] and x >= b[0]:
			return lerpf(a[1], b[1], (a[0] - x) / (a[0] - b[0]))
	return 3.0


func _load_profile() -> bool:
	_gal_y.clear()
	_gal_z.clear()
	_gal_depth.clear()
	_gal_low.clear()
	_gal_taper.clear()
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f == null:
		push_warning("mainland: %s missing; run tools/bake_walkway.gd. No walkway built." % PROFILE_PATH)
		return false
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return false
	var ys: Array = d["y"]
	var zd: Array = d["z_deep"]
	var zl: Array = d["z_low"]
	var zpr: Array = d.get("z_prot", zd)
	var n := ys.size()
	var taper_n: int = int(d.get("end_taper", 8))
	for i in n:
		_gal_y.append(float(ys[i]))
		var x_i := GAL_X0 - i * GAL_STEP
		var front := minf(float(zd[i]) - WALK_W, float(zpr[i]) - CLEAR)      # clear of the rock that sticks out into the walkway
		if x_i > -8.0:
			# at the quay end the floor reaches out to meet the boardwalks and the timber link ramp, whose ends sit at fixed heights and positions
			front = minf(front, QUAY_FRONT_Z - QUAY_APRON * smoothstep(-8.0, 10.0, x_i))
		_gal_z.append(front)
		_gal_depth.append(float(zd[i]) + BURY - front)
		_gal_low.append(float(zl[i]))
		var left := n - 1 - i
		_gal_taper.append(clampf(float(left) / float(taper_n), 0.0, 1.0))
	var e := n - 1
	_walk_end = Vector3(GAL_X0 - e * GAL_STEP, _gal_y[e], _gal_z[e] + 0.5 * _gal_depth[e])
	return n > 2


## The cliff's own material, switched to world-space triplanar mapping so it can cover the ledge: the same texture,
## roughness and normal map as the rock beside it, not a flat colour.
func _rock_material() -> Material:
	if _cliff_mat == null:
		var cliffs := get_parent().get_node_or_null("Cliffs") if get_parent() else null
		if cliffs:
			for mi in cliffs.find_children("*", "MeshInstance3D", true, false):
				var m := mi as MeshInstance3D
				if m.mesh and m.mesh.get_surface_count() > 0 and m.mesh.surface_get_material(0):
					_cliff_mat = m.mesh.surface_get_material(0)
					break
	var base := _cliff_mat as BaseMaterial3D
	if base == null:
		return _vertex_colour_material(1.0)
	var m2 := base.duplicate() as BaseMaterial3D
	m2.uv1_triplanar = true
	m2.uv1_world_triplanar = true
	m2.uv1_scale = Vector3(ROCK_TILE, ROCK_TILE, ROCK_TILE)
	m2.uv1_triplanar_sharpness = 4.0
	m2.vertex_color_use_as_albedo = true     # the per-block shade multiplies the texture (kept near 1.0)
	m2.albedo_color = Color(0.74, 0.77, 0.80)   # worn and a little darker than the sunlit face, so the moss does not glow underfoot
	m2.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m2


## A point across the walkway at step i: t = 0 at the sea-side edge, 1 at the buried back edge. The surface is
## slightly uneven and the sea-side edge wanders, so it reads as worn rock, not a ruler line.
func _gal_point(i: int, t: float) -> Vector3:
	var x := GAL_X0 - i * GAL_STEP
	var front := _gal_z[i]
	var back := front + _gal_depth[i]
	var wander := (_noise.get_noise_2d(x * 3.1, 17.0) * 0.5 + 0.5) * EDGE_WANDER * (1.0 - smoothstep(0.0, 0.25, t))
	var z := lerpf(front + wander, back, t)
	var bump := _noise.get_noise_2d(x * 1.7, z * 1.7) * FLOOR_BUMP * sin(clampf(t, 0.0, 1.0) * PI * 0.5 + 0.35)
	return Vector3(x, _gal_y[i] + bump, z)


func _build_gallery() -> void:
	if not _load_profile():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := _gal_y.size()
	const ACROSS := 6
	for i in n - 1:
		var shade := 0.9 + 0.1 * fposmod(i * 0.618, 1.0)      # a whisper of block-to-block variation; the texture does the rest
		var col := Color(shade, shade, shade)
		for j in ACROSS:
			var t0 := float(j) / ACROSS
			var t1 := float(j + 1) / ACROSS
			_quad(st, _gal_point(i, t0), _gal_point(i + 1, t0), _gal_point(i + 1, t1), _gal_point(i, t1), col, Vector3.UP)
		var k := _gal_taper[i]
		var k2 := _gal_taper[i + 1]
		# the rock the ledge stands on: from the sea-side edge a short rounded shoulder, then a slope back and down to
		# where the face is three metres lower, so the ledge is a shelf of the cliff and never an overhanging slab
		var e0 := _gal_point(i, 0.0)
		var e1 := _gal_point(i + 1, 0.0)
		var drop0 := SHELF_DROP * k * (0.75 + 0.5 * (_noise.get_noise_2d(e0.x * 0.9, 5.0) * 0.5 + 0.5))
		var drop1 := SHELF_DROP * k2 * (0.75 + 0.5 * (_noise.get_noise_2d(e1.x * 0.9, 5.0) * 0.5 + 0.5))
		var f0 := Vector3(e0.x, e0.y - drop0, minf(_gal_low[i] + 0.4, e0.z + 0.2 + _gal_depth[i]))
		var f1 := Vector3(e1.x, e1.y - drop1, minf(_gal_low[i + 1] + 0.4, e1.z + 0.2 + _gal_depth[i + 1]))
		var o0 := Vector3(e0.x, e0.y - 0.5 * k, e0.z + 0.15)
		var o1 := Vector3(e1.x, e1.y - 0.5 * k2, e1.z + 0.15)
		_quad(st, e0, e1, o1, o0, col * 0.85, Vector3(0, 0.3, -1).normalized())
		_quad(st, o0, o1, f1, f0, col * 0.75, Vector3(0, -0.4, -1).normalized())
		# the rock beneath the floor's buried back edge, closing the underside against the face
		var b0 := _gal_point(i, 1.0)
		var b1 := _gal_point(i + 1, 1.0)
		_quad(st, b0, b1, Vector3(b1.x, f1.y, f1.z), Vector3(b0.x, f0.y, f0.z), col * 0.6, Vector3(0, -0.2, 1).normalized())
		# a rock toe up the wall where floor meets face, so the join reads as rock grown into rock
		var ts := 1.0 - TOE_DEPTH / maxf(_gal_depth[i], 1.0)
		var ts2 := 1.0 - TOE_DEPTH / maxf(_gal_depth[i + 1], 1.0)
		var w0 := _gal_point(i, 1.0 - BURY / _gal_depth[i])
		var w1 := _gal_point(i + 1, 1.0 - BURY / _gal_depth[i + 1])
		var h := TOE_HEIGHT * k * (0.7 + 0.6 * (_noise.get_noise_2d(w0.x * 1.3, 33.0) * 0.5 + 0.5))
		var h2 := TOE_HEIGHT * k2 * (0.7 + 0.6 * (_noise.get_noise_2d(w1.x * 1.3, 33.0) * 0.5 + 0.5))
		_quad(st, _gal_point(i, ts), _gal_point(i + 1, ts2), Vector3(w1.x, w1.y + h2, w1.z + 0.35), Vector3(w0.x, w0.y + h, w0.z + 0.35), col * 0.9, Vector3(0, 0.6, -1).normalized())
	# close both ends of the ledge, so it is a solid piece of rock from the side too
	for end_i in [0, n - 1]:
		var fr := _gal_point(end_i, 0.0)
		var bk := _gal_point(end_i, 1.0)
		var kk := _gal_taper[end_i]
		var lowp := Vector3(fr.x, fr.y - SHELF_DROP * kk, minf(_gal_low[end_i] + 0.4, bk.z))
		var out := Vector3(1, 0, 0) if end_i == 0 else Vector3(-1, 0, 0)
		_tri(st, fr, bk, lowp, Color(0.55, 0.55, 0.55), out)
	var mi := MeshInstance3D.new()
	mi.name = "Gallery"
	mi.mesh = st.commit()
	mi.material_override = _rock_material()
	add_child(mi)
	if not Engine.is_editor_hint():
		mi.create_trimesh_collision()
		_solidify(mi, 1)
	print("mainland: walkway ledge built against the uncut cliff: %d steps, ends at (%.0f, %.1f, %.1f)" % [n, _walk_end.x, _walk_end.y, _walk_end.z])


## A single triangle, wound so its normal points along `want`.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, want: Vector3) -> void:
	var g := (b - a).cross(c - a)
	if g.length() < 0.0001:
		return
	var tri := [a, b, c]
	if g.dot(want) > 0.0:
		tri = [a, c, b]
		g = -g
	var nrm := -g.normalized()
	for v in tri:
		st.set_normal(nrm)
		st.set_color(col)
		st.add_vertex(v)


## Makes the trimesh collision body just created under `mi` hit from both sides, on the given layers.
func _solidify(mi: MeshInstance3D, layers: int) -> void:
	for child in mi.get_children():
		if child is StaticBody3D and not child.is_queued_for_deletion():
			(child as StaticBody3D).collision_layer = layers
			for sh in child.get_children():
				var cs := sh as CollisionShape3D
				if cs and cs.shape is ConcavePolygonShape3D:
					(cs.shape as ConcavePolygonShape3D).backface_collision = true


func _forest_points(from: Vector3) -> Array[Vector3]:
	# the path starts exactly where the ledge ends, then bends into the old forest road
	var ctrl: Array[Vector3] = [Vector3(from.x, 0.0, from.z)]
	if from.x > -194.0:
		ctrl.append(Vector3((from.x - 203.0) * 0.5, 0.0, (from.z + 579.0) * 0.5))
	for k in range(1, FOREST_ROAD.size()):
		ctrl.append(Vector3(FOREST_ROAD[k].x, 0.0, FOREST_ROAD[k].y))
	var pts := _spline(ctrl, 18)
	var s := 0.0
	for i in pts.size():
		if i > 0:
			s += Vector2(pts[i].x - pts[i - 1].x, pts[i].z - pts[i - 1].z).length()
		var z := pts[i].z
		var offset := 0.1          # flush with the ground: a slab sunk 2.5 m with its top just proud, so no side shows
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
func _sweep(st: SurfaceTool, pts: Array[Vector3], width_in: float, thick: float, inner_ext: float,
		lateral: float, lift: float, top_col: Color, side_col: Color, jitter := 0.0, start_taper := 0.0) -> void:
	var rows: Array = []
	var arc := 0.0
	for i in pts.size():
		if i > 0:
			arc += Vector2(pts[i].x - pts[i - 1].x, pts[i].z - pts[i - 1].z).length()
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, pts.size() - 1)]
		var t := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		var n := Vector3(-t.z, 0.0, t.x)            # left of travel
		var width := width_in * (1.0 + jitter * _noise.get_noise_2d(pts[i].x * 0.6, pts[i].z * 0.6))     # the edge wanders, it is not a ruler line
		if start_taper > 0.0:
			width *= lerpf(0.3, 1.0, smoothstep(0.0, start_taper, arc))     # the path fades in from the end of the ledge, not as a tile with a square end
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
	const VARIANTS := 3
	var xforms: Array = []
	var cols: Array = []
	for v in VARIANTS:
		xforms.append([])
		cols.append([])
	var placed := 0
	var tries := 0
	while placed < tree_count and tries < tree_count * 6:
		tries += 1
		var x := rng.randf_range(TERRAIN_X.x + 20.0, TERRAIN_X.y - 20.0)
		var z := rng.randf_range(TERRAIN_Z.x + 4.0, TERRAIN_Z.y - 20.0)
		if z < TREE_MIN_Z or Vector2(x - CITY_CENTRE.x, z - CITY_CENTRE.y).length() < CITY_RADIUS:
			continue
		if _near_road(x, z):
			continue
		var y := terrain_h(x, z)
		if y < 5.0:
			continue
		var s := rng.randf_range(0.6, 1.25)
		var lean := Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(), rng.randf_range(0.0, 0.10))   # wind-leaned, never ruler-straight
		var basis := lean * Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s * rng.randf_range(0.85, 1.15), s * rng.randf_range(0.9, 1.15), s * rng.randf_range(0.85, 1.15)))
		var v := rng.randi() % VARIANTS
		xforms[v].append(Transform3D(basis, Vector3(x, y - 0.4, z)))
		var c := rng.randf_range(0.7, 1.15)
		cols[v].append(Color(c, c * rng.randf_range(0.95, 1.1), c, 1.0))
		placed += 1
	for v in VARIANTS:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _pine_mesh(v)
		mm.instance_count = xforms[v].size()
		for i in xforms[v].size():
			mm.set_instance_transform(i, xforms[v][i])
			mm.set_instance_color(i, cols[v][i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Forest%d" % v
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.material_override = _vertex_colour_material(1.0)
		add_child(mmi)


func _near_road(x: float, z: float) -> bool:
	for p in _road_xz:
		if absf(p.x - x) < 8.5 and absf(p.y - z) < 8.5 and Vector2(p.x - x, p.y - z).length() < 8.5:
			return true
	return false


## Slimmer, taller, ragged pines in three variants (the concept art's trees are tall and narrow with uneven tiers, not
## squat cones). Each tier is a short, slightly lopsided cone: radius and height jitter, the tip leans, so no two tiers
## match and the silhouette is broken.
func _pine_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + variant * 31
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := 15.0 + 2.5 * variant
	_cone(st, Vector3(0, 0, 0), 0.4, 4.0, 6, Color(0.14, 0.10, 0.07))       # trunk, bare to a height
	var tiers := 6 + variant
	var y := 2.6
	for k in tiers:
		var f := float(k) / float(tiers)
		var r := lerpf(2.5, 0.7, pow(f, 0.85)) * rng.randf_range(0.75, 1.15)
		var h := rng.randf_range(3.4, 4.6)
		var lean := Vector3(rng.randf_range(-0.5, 0.5), 0.0, rng.randf_range(-0.5, 0.5)) * (1.0 - f)
		var shade := lerpf(0.045, 0.075, f) * rng.randf_range(0.85, 1.15)
		var col := Color(shade, shade * 1.9, shade * 1.55)
		_cone_lean(st, Vector3(0, y, 0), r, h, 7, col, lean)
		y += (height - 3.0 - y) / float(tiers - k) * 0.9 + 0.2
	return st.commit()


## A cone whose tip is moved sideways by `lean` and whose rim is a little ragged.
func _cone_lean(st: SurfaceTool, base: Vector3, radius: float, height: float, sides: int, col: Color, lean: Vector3) -> void:
	var tip := base + Vector3(0, height, 0) + lean
	var rim: Array[Vector3] = []
	for i in sides:
		var a := TAU * i / sides
		var rr := radius * (0.82 + 0.3 * absf(sin(a * 2.7 + radius)))
		rim.append(base + Vector3(cos(a), 0, sin(a)) * rr)
	for i in sides:
		var p0 := rim[i]
		var p1 := rim[(i + 1) % sides]
		var mid := (p0 + p1) * 0.5 - base
		var side_out := Vector3(mid.x, 0.55 * radius, mid.z).normalized()
		_quad(st, p0, p1, tip, tip, col, side_out)
		_quad(st, base, p1, p0, p0, col, Vector3.DOWN)


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
