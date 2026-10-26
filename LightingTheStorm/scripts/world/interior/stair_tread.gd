# stair_tread.gd - one stone spiral step, drawn properly (Lighthouse Finisher Agent, LHF-04).
# The old steps were plain slabs. Each tread now has: a bull-nosed front edge that overhangs the step below, a chamfered
# outer edge, a worn middle (vertex colour: lighter and smoother where feet fall, darker and grimier at the newel and wall
# joints and in the corner under the nosing), a small tint difference per step so no two stones match, and a flat riser
# back to the step below. Visual only: the caller keeps its own collision body, so the walk and the flood-fill route do not change.
# One MeshInstance3D per step. Bearings are degrees from +x toward +z round the centre; the stair climbs with rising bearing.
extends RefCounted

const NOSE := 0.028          # how far the front edge overhangs the step below (metres along the arc at mid radius)
const BEVEL := 0.035         # the rounded edge's depth
const COLS := 4              # radial strips across the tread, so the wear can shade across it


static func add(parent: Node3D, nm: String, centre: Vector2, r0: float, r1: float, a0: float, a1: float, top: float,
		thick: float, mat: Material, seed_i: int) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9000 + seed_i
	var tint := 0.94 + rng.randf() * 0.12                    # each stone a little different
	var warm := rng.randf_range(-0.02, 0.02)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mid := (r0 + r1) * 0.5
	var dn := rad_to_deg(NOSE / maxf(mid, 0.1))              # the overhang as an angle
	var db := rad_to_deg(BEVEL / maxf(mid, 0.1))
	var an := a0 - dn                                        # where the top surface starts (over the step below)
	var bot := top - thick
	# ---- the top surface, in COLS radial strips: worn in the middle
	for c in COLS:
		var ra := lerpf(r0, r1, float(c) / COLS)
		var rb := lerpf(r0, r1, float(c + 1) / COLS)
		var wa := _wear(float(c) / COLS)
		var wb := _wear(float(c + 1) / COLS)
		_quad(st, centre, ra, rb, an + db, a1, top, top, Vector3.UP, _col(wa, tint, warm), _col(wb, tint, warm), _col(wa, tint, warm), _col(wb, tint, warm))
		# the rounded nose: a bevel from the flat top down to the overhang's lip
		_quad(st, centre, ra, rb, an, an + db, top - BEVEL, top, Vector3(-0.5, 0.8, 0.0), _col(wa * 0.8, tint, warm), _col(wb * 0.8, tint, warm), _col(wa, tint, warm), _col(wb, tint, warm))
	# ---- the riser under the nose, set back from the lip, down to the step below
	_quad(st, centre, r0, r1, an, an, top - 0.176, top - BEVEL, Vector3(-1.0, 0.0, 0.0), _col(0.55, tint, warm), _col(0.55, tint, warm), _col(0.7, tint, warm), _col(0.7, tint, warm))
	# ---- the sides and the far end, down to the stair's body (the newel and the next step hide most of this)
	_wall_r(st, centre, r1, a0, a1, bot, top, _col(0.62, tint, warm), 1.0)           # outer edge (chamfer is a darker band)
	_wall_r(st, centre, r0, a0, a1, bot, top, _col(0.5, tint, warm), -1.0)           # against the newel
	_quad(st, centre, r0, r1, a1, a1, bot, top, Vector3(1.0, 0.0, 0.0), _col(0.6, tint, warm), _col(0.6, tint, warm), _col(0.6, tint, warm), _col(0.6, tint, warm))
	_quad(st, centre, r0, r1, a0, a0, bot, top, Vector3(-1.0, 0.0, 0.0), _col(0.6, tint, warm), _col(0.6, tint, warm), _col(0.6, tint, warm), _col(0.6, tint, warm))
	_quad(st, centre, r0, r1, a0, a1, bot, bot, Vector3.DOWN, _col(0.4, tint, warm), _col(0.4, tint, warm), _col(0.4, tint, warm), _col(0.4, tint, warm))
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = _vertex_mat(mat)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


static var _mat_cache := {}


static func _vertex_mat(mat: Material) -> Material:
	var key := mat.get_instance_id()
	if _mat_cache.has(key) and is_instance_valid(_mat_cache[key]):
		return _mat_cache[key]
	var m := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache[key] = m
	return m


## 0..1 across the tread: 1 is the worn middle, 0 the edges at the newel and the wall.
static func _wear(f: float) -> float:
	return 0.55 + 0.45 * sin(PI * clampf(f, 0.0, 1.0))


static func _col(w: float, tint: float, warm: float) -> Color:
	var v := (0.62 + 0.38 * w) * tint
	return Color(v + warm, v, v - warm)


static func _p(centre: Vector2, r: float, a_deg: float, y: float) -> Vector3:
	var a := deg_to_rad(a_deg)
	return Vector3(centre.x + r * cos(a), y, centre.y + r * sin(a))


## A quad between two radii and two bearings (or the same bearing, or the same height). Corner colours: c00 (r0,a0) c10 (r1,a0)
## c01 (r0,a1) c11 (r1,a1) for flat quads; for vertical quads the heights go y0/y1 on the same corners.
static func _quad(st: SurfaceTool, centre: Vector2, ra: float, rb: float, aa: float, ab: float, y0: float, y1: float,
		n: Vector3, c00: Color, c10: Color, c01: Color, c11: Color) -> void:
	var p00: Vector3
	var p10: Vector3
	var p01: Vector3
	var p11: Vector3
	if absf(aa - ab) < 1e-6:                      # a radial riser / end face: spans r and height
		p00 = _p(centre, ra, aa, y0)
		p10 = _p(centre, rb, aa, y0)
		p01 = _p(centre, ra, aa, y1)
		p11 = _p(centre, rb, aa, y1)
	else:                                         # a horizontal or sloped face: spans r and bearing, with y0 at aa and y1 at ab
		p00 = _p(centre, ra, aa, y0)
		p10 = _p(centre, rb, aa, y0)
		p01 = _p(centre, ra, ab, y1)
		p11 = _p(centre, rb, ab, y1)
	for tri in [[p00, p10, p11, c00, c10, c11], [p00, p11, p01, c00, c11, c01]]:
		for k in 3:
			st.set_color(tri[3 + k])
			st.set_normal(n)
			st.add_vertex(tri[k])


## A cylindrical wall at radius r between two bearings, from y0 to y1.
static func _wall_r(st: SurfaceTool, centre: Vector2, r: float, a0: float, a1: float, y0: float, y1: float, c: Color, out: float) -> void:
	var n := maxi(1, ceili(absf(a1 - a0) / 7.5))
	for i in n:
		var t0 := lerpf(a0, a1, float(i) / n)
		var t1 := lerpf(a0, a1, float(i + 1) / n)
		var p0 := _p(centre, r, t0, y0)
		var p1 := _p(centre, r, t1, y0)
		var p2 := _p(centre, r, t1, y1)
		var p3 := _p(centre, r, t0, y1)
		var nm := Vector3(cos(deg_to_rad((t0 + t1) * 0.5)), 0.0, sin(deg_to_rad((t0 + t1) * 0.5))) * out
		for tri in [[p0, p1, p2], [p0, p2, p3]]:
			for q in tri:
				st.set_color(c)
				st.set_normal(nm)
				st.add_vertex(q)
