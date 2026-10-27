# kit.gd - the building blocks the lighthouse interior is made from (Lighthouse Interior Creator Agent).
# Everything is placed in the HOUSE FRAME used by the greybox generator (Assets/Models/lighthouse/interior/build_lighthouse_greybox_v3.py):
#   u = metres along the front wall (the door is at u 0), v = metres inward from the front door plane, y = height in the
#   lighthouse's local frame (ground floor 0.97, basement floor -2.0). The frame root is turned to the house so a box
#   given in u/v/y lines up with the greybox walls. Boxes may be solid (collision on layer 1) or only visual.
# Textures are made here in code (seeded noise), so there are no image files to import, and they are mapped in world
# space ("triplanar"), so a texture keeps its scale on a 0.1 m trim or a 7 m wall.
extends RefCounted

const GF := 0.97
const B1 := -2.0
const FLOOR_LAYER := 1

var root: Node3D                  # the house frame
var mats := {}
var count := 0                    # nodes made, for the tests' budget
var lights: Array[OmniLight3D] = []   # every light made, so the interior's light manager can take them over


func _init(frame: Node3D) -> void:
	root = frame
	_make_materials()


# ---------------------------------------------------------------- positions

## A point given as house-frame (u, y, v) -> the frame's local space (x = u, y, z = -v).
static func p(u: float, y: float, v: float) -> Vector3:
	return Vector3(u, y, -v)


## A house-frame point in world space.
func world(u: float, y: float, v: float) -> Vector3:
	return root.to_global(p(u, y, v))


# ---------------------------------------------------------------- primitives

## A box between two house-frame corners. `solid` gives it collision; `nm` names the MeshInstance3D.
func box(parent: Node3D, nm: String, u0: float, u1: float, v0: float, v1: float, y0: float, y1: float, m, solid := true) -> MeshInstance3D:
	var size := Vector3(absf(u1 - u0), absf(y1 - y0), absf(v1 - v0))
	var mi := MeshInstance3D.new()
	mi.name = nm
	if bevel_furniture and minf(size.x, minf(size.y, size.z)) >= BEVEL_MIN_DIM and maxf(size.x, maxf(size.y, size.z)) <= BEVEL_MAX_DIM:
		mi.mesh = bevel_mesh(size)           # LHF-08: furniture-scale boxes get a chamfered edge that catches the light and the ink
	else:
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
	mi.material_override = _m(m)
	mi.position = p((u0 + u1) * 0.5, (y0 + y1) * 0.5, (v0 + v1) * 0.5)
	parent.add_child(mi)
	count += 1
	if solid:
		_collide(mi, BoxShape3D.new(), size)
	return mi


## Chamfered boxes (LHF-08). A box between BEVEL_MIN_DIM and BEVEL_MAX_DIM on every side is furniture, not a wall or a beam.
const BEVEL_MIN_DIM := 0.12
const BEVEL_MAX_DIM := 2.6
const BEVEL := 0.014
var bevel_furniture := true
static var _bevel_cache := {}


static func bevel_mesh(size: Vector3) -> ArrayMesh:
	var key := Vector3(snappedf(size.x, 0.001), snappedf(size.y, 0.001), snappedf(size.z, 0.001))
	if _bevel_cache.has(key):
		return _bevel_cache[key]
	var h := size * 0.5
	var b := minf(BEVEL, minf(size.x, minf(size.y, size.z)) * 0.12)
	var i := h - Vector3(b, b, b)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var axes := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	# the six faces, pulled in by the bevel
	for a in 3:
		var a1: int = (a + 1) % 3
		var a2: int = (a + 2) % 3
		for sa in [-1.0, 1.0]:
			var n: Vector3 = axes[a] * sa
			var q := []
			for s1 in [-1.0, 1.0]:
				for s2 in [-1.0, 1.0]:
					q.append(n * h[a] + axes[a1] * (s1 * i[a1]) + axes[a2] * (s2 * i[a2]))
			_bq(st, q[0], q[1], q[2], q[3], n)      # strip order (the nested loops give --, -+, +-, ++): the old order left a triangular wedge out of every face
	# the twelve edge strips
	for a in 3:
		var a1: int = (a + 1) % 3
		var c: int = (a + 2) % 3
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var p1: Vector3 = axes[a] * (sa * h[a]) + axes[a1] * (sb * i[a1])
				var p2: Vector3 = axes[a] * (sa * i[a]) + axes[a1] * (sb * h[a1])
				var n: Vector3 = (axes[a] * sa + axes[a1] * sb).normalized()
				var lo: Vector3 = axes[c] * -i[c]
				var hi: Vector3 = axes[c] * i[c]
				_bq(st, p1 + lo, p1 + hi, p2 + lo, p2 + hi, n)
	# the eight corners
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var pa := Vector3(sx * h.x, sy * i.y, sz * i.z)
				var pb := Vector3(sx * i.x, sy * h.y, sz * i.z)
				var pc := Vector3(sx * i.x, sy * i.y, sz * h.z)
				_bt(st, pa, pb, pc, Vector3(sx, sy, sz).normalized())
	var mesh := st.commit()
	_bevel_cache[key] = mesh
	return mesh


static func _bq(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	_bt(st, a, b, c, n)
	_bt(st, c, b, d, n)


## One triangle, wound so Godot (clockwise front faces) shows it from the side `n` points to.
static func _bt(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)


## An upright cylinder (a post, a tank) centred on house-frame (u, v), from y0 to y1.
func pole(parent: Node3D, nm: String, u: float, v: float, y0: float, y1: float, r: float, m, solid := true, r_top := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r if r_top < 0.0 else r_top
	cm.bottom_radius = r
	cm.height = absf(y1 - y0)
	cm.radial_segments = 24 if r > 0.15 else 10
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = _m(m)
	mi.position = p(u, (y0 + y1) * 0.5, v)
	parent.add_child(mi)
	count += 1
	if solid:
		var cs := CylinderShape3D.new()
		cs.radius = r
		cs.height = absf(y1 - y0)
		_collide_shape(mi, cs)
	return mi


## A cylinder between two house-frame points (u, y, v): a pipe, a rod, a strut.
func rod(parent: Node3D, nm: String, a: Vector3, b: Vector3, r: float, m, solid := false) -> MeshInstance3D:
	var pa := p(a.x, a.y, a.z)
	var pb := p(b.x, b.y, b.z)
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = pa.distance_to(pb)
	cm.radial_segments = 10
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = _m(m)
	var up := (pb - pa).normalized()
	var ref := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := up.cross(ref).normalized()
	var z := x.cross(up).normalized()
	mi.transform = Transform3D(Basis(x, up, z), (pa + pb) * 0.5)
	parent.add_child(mi)
	count += 1
	if solid:
		var cs := CylinderShape3D.new()
		cs.radius = r
		cs.height = cm.height
		_collide_shape(mi, cs)
	return mi


## A disc (a flywheel, a gauge face, a porthole) standing in a plane: axis is a house-frame direction (u, y, v).
func disc(parent: Node3D, nm: String, c: Vector3, axis: Vector3, r: float, thick: float, m, solid := false) -> MeshInstance3D:
	return rod(parent, nm, c - axis.normalized() * thick * 0.5, c + axis.normalized() * thick * 0.5, r, m, solid)


func sphere(parent: Node3D, nm: String, c: Vector3, r: float, m, squash := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0 * squash
	sm.radial_segments = 20
	sm.rings = 10
	mi.mesh = sm
	mi.material_override = _m(m)
	mi.position = p(c.x, c.y, c.z)
	parent.add_child(mi)
	count += 1
	return mi


## An imported model (res://Assets/Models/prop/lhi_*.glb: scaled to 0.9 m on its longest side, pivot at the base centre) placed
## in the house frame: `scale` multiplies that 0.9 m, `yaw_deg` turns it about the vertical (positive turns its +z toward the
## house +u). `footprint` (a box size in the model's own metres after scaling, x width, y height, z depth) adds one solid
## collision box centred over the base, or Vector3.ZERO for none.
func model(parent: Node3D, nm: String, path: String, at: Vector3, yaw_deg: float, scale: float, footprint := Vector3.ZERO, carve := AABB()) -> Node3D:
	var ps := load(path) as PackedScene
	var w := Node3D.new()
	w.name = nm
	w.position = p(at.x, at.y, at.z)
	w.rotation.y = deg_to_rad(yaw_deg)
	w.scale = Vector3.ONE * scale
	parent.add_child(w)
	count += 1
	if ps == null:
		push_warning("kit.model: cannot load %s" % path)
		return w
	var inst := ps.instantiate() as Node3D
	inst.name = "Model"
	w.add_child(inst)
	if carve.size != Vector3.ZERO:
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			_carve_mesh(mi as MeshInstance3D, carve)
	for g in inst.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if footprint != Vector3.ZERO:
		var sb := StaticBody3D.new()
		sb.name = "Body"
		sb.collision_layer = FLOOR_LAYER
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = footprint / scale
		cs.shape = bx
		cs.position = Vector3(0, bx.size.y * 0.5, 0)
		sb.add_child(cs)
		w.add_child(sb)
	return w


## Remove from a mesh every triangle whose centre is inside `box`, given in the mesh's own raw coordinates (the generated models
## store z as height). Used to take a door off the generated boiler.
func _carve_mesh(mi: MeshInstance3D, box: AABB) -> void:
	var src := mi.mesh as ArrayMesh
	if src == null:
		return
	var out := ArrayMesh.new()
	var removed := 0
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			idx = PackedInt32Array(range(v.size()))
		var kept := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var c := (v[idx[t]] + v[idx[t + 1]] + v[idx[t + 2]]) / 3.0
			if box.has_point(c):
				removed += 1
			else:
				kept.append(idx[t])
				kept.append(idx[t + 1])
				kept.append(idx[t + 2])
		arr[Mesh.ARRAY_INDEX] = kept
		out.add_surface_from_arrays(src.surface_get_primitive_type(s), arr)
		out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(s))
	mi.mesh = out
	print("kit: carved %d triangles from %s" % [removed, mi.name])


func node(parent: Node3D, nm: String, at := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	n.position = p(at.x, at.y, at.z)
	parent.add_child(n)
	return n


func light(parent: Node3D, nm: String, at: Vector3, colour: Color, energy: float, rng: float, flicker := 0.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm
	l.position = p(at.x, at.y, at.z)
	l.light_color = AMBER if (colour.g > 0.65 and colour.b > 0.35) else colour   # every warm white is the amber gas and steam light
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	if flicker > 0.0:
		l.set_meta("flicker", flicker)
	parent.add_child(l)
	lights.append(l)
	return l


## Text on a flat sheet standing against a wall. `normal` is the house-frame direction the sheet faces ((0,0,1) faces +v).
func sheet(parent: Node3D, nm: String, c: Vector3, normal: Vector3, w: float, h: float, m, text := "", font_px := 40, text_col := Color(0.05, 0.05, 0.07), text_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	mi.mesh = qm
	mi.material_override = _m(m)
	var n := p(normal.x, normal.y, normal.z).normalized()
	var up := Vector3.UP
	if absf(n.dot(up)) > 0.99:      # a page lying flat (a chart on a table): "up" on the page is the house's far wall (-v, +z here)
		up = Vector3(0, 0, -1) * signf(n.dot(Vector3.UP)) * -1.0
	var x := up.cross(n).normalized()
	mi.transform = Transform3D(Basis(x, n.cross(x).normalized(), n), p(c.x, c.y, c.z) + n * 0.012)
	parent.add_child(mi)
	count += 1
	if text != "":
		var lb := Label3D.new()
		lb.name = "Text"
		lb.text = text
		lb.font_size = font_px
		lb.pixel_size = 0.0022
		lb.modulate = text_col
		lb.outline_size = 0
		lb.width = w * 440.0
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.position = Vector3(0, text_y, 0.004)
		mi.add_child(lb)
	return mi


# ---------------------------------------------------------------- collision helpers

func _collide(mi: MeshInstance3D, shape: BoxShape3D, size: Vector3) -> void:
	shape.size = size
	_collide_shape(mi, shape)


func _collide_shape(mi: MeshInstance3D, shape: Shape3D) -> void:
	var sb := StaticBody3D.new()
	sb.name = "Body"
	sb.collision_layer = FLOOR_LAYER
	var cs := CollisionShape3D.new()
	cs.shape = shape
	sb.add_child(cs)
	mi.add_child(sb)


# ---------------------------------------------------------------- materials

func _m(m) -> Material:
	if m is Material:
		return m
	return mats.get(String(m), mats["plaster"])


func colour(c: Color, rough := 0.9, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var s := StandardMaterial3D.new()
	s.albedo_color = c
	s.roughness = rough
	s.metallic = metal
	if emit > 0.0:
		s.emission_enabled = true
		s.emission = c
		s.emission_energy_multiplier = emit
	return s


func _textured(kind: String, tint := Color.WHITE, rough := 0.9, metal := 0.0, scale := 0.5) -> StandardMaterial3D:
	var s := StandardMaterial3D.new()
	s.albedo_texture = _texture(kind)
	s.albedo_color = tint
	s.roughness = rough
	s.metallic = metal
	s.uv1_triplanar = true
	s.uv1_world_triplanar = true
	s.uv1_scale = Vector3(scale, scale, scale)
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return s


## The style guide's palette (Docs/Lore Build/world/style_guide.md): gritty, dark, muted, desaturated. Stone grey #6B6B66,
## sea slate #2C3A40, navy #1F2A44, silver #B9BEC4, amber #C07A1E, gold #B8962E, Arthur's green #2F4A34, Daniel's red #7A2620.
## Lamps are amber (the steam and gas light); the arc lamp and the beacon are cold silver. Nothing clean, glossy or saturated.
const AMBER := Color(0.88, 0.68, 0.45)
const SILVER := Color(0.73, 0.75, 0.77)


func _make_materials() -> void:
	mats["plaster"] = _textured("plaster", Color(0.5, 0.5, 0.48), 0.97, 0.0, 0.35)
	mats["plaster_dark"] = _textured("plaster", Color(0.42, 0.41, 0.38), 0.97, 0.0, 0.35)
	mats["whitewash"] = _textured("plaster", Color(0.6, 0.6, 0.58), 0.97, 0.0, 0.35)
	mats["flags"] = _textured("flags", Color(0.6, 0.63, 0.66), 0.92, 0.0, 0.5)
	mats["flags_dark"] = _textured("flags", Color(0.4, 0.43, 0.47), 0.92, 0.0, 0.5)
	mats["planks"] = _textured("planks", Color(0.68, 0.6, 0.52), 0.9, 0.0, 0.5)
	mats["wood"] = _textured("planks", Color(0.45, 0.37, 0.3), 0.85, 0.0, 0.6)
	mats["wood_dark"] = _textured("planks", Color(0.27, 0.22, 0.18), 0.8, 0.0, 0.6)
	mats["brick"] = _textured("brick", Color(0.66, 0.6, 0.58), 0.95, 0.0, 0.5)
	mats["stone"] = _textured("flags", Color(0.55, 0.55, 0.53), 0.95, 0.0, 0.3)
	mats["stone_worn"] = _textured("flags", Color(0.23, 0.205, 0.185), 0.98, 0.0, 0.3)      # the stairs: darker, worn grey-brown stone (creator, 2026-10-26: "a worn stone feel")
	mats["iron"] = _textured("metal", Color(0.4, 0.42, 0.45), 0.65, 0.6, 0.8)
	mats["iron_dark"] = _textured("metal", Color(0.17, 0.18, 0.2), 0.7, 0.5, 0.8)
	mats["boiler"] = _textured("metal", Color(0.33, 0.29, 0.27), 0.6, 0.6, 0.6)
	mats["copper"] = colour(Color(0.5, 0.33, 0.23), 0.55, 0.7)
	mats["brass"] = colour(Color(0.62, 0.52, 0.22), 0.5, 0.75)         # dulled gold, #B8962E gone dark with age
	mats["coal"] = _textured("coal", Color(0.22, 0.22, 0.24), 0.55, 0.1, 0.8)
	mats["canvas"] = _textured("plaster", Color(0.5, 0.47, 0.38), 1.0, 0.0, 1.2)
	mats["paper"] = _textured("plaster", Color(0.72, 0.69, 0.6), 1.0, 0.0, 2.0)
	mats["paper_navy"] = colour(Color(0.07, 0.09, 0.16), 1.0)           # the Flighted: black, silver, navy
	mats["paper_old"] = colour(Color(0.6, 0.56, 0.44), 1.0)
	mats["rug"] = colour(Color(0.24, 0.17, 0.15), 1.0)
	mats["cloth_green"] = colour(Color(0.18, 0.29, 0.2), 1.0)           # Arthur's green #2F4A34, muted
	mats["navy"] = colour(Color(0.12, 0.16, 0.27), 1.0)                 # Ted's navy #1F2A44
	mats["red_dark"] = colour(Color(0.4, 0.15, 0.13), 1.0)              # Daniel's red #7A2620, muted
	mats["leather"] = colour(Color(0.22, 0.14, 0.1), 0.75)
	mats["black"] = colour(Color(0.03, 0.03, 0.035), 0.85)
	mats["fire"] = colour(Color(0.75, 0.48, 0.12), 0.6, 0.0, 3.0)       # amber #C07A1E
	mats["glow_warm"] = colour(AMBER, 0.5, 0.0, 1.2)
	mats["gauge_face"] = colour(Color(0.68, 0.66, 0.56), 0.7)
	mats["lamp_green"] = colour(Color(0.3, 0.8, 0.4), 0.4, 0.0, 1.6)
	mats["lamp_red"] = colour(Color(0.85, 0.2, 0.15), 0.4, 0.0, 1.6)
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.46, 0.58, 0.64, 0.30)
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.roughness = 0.1
	g.metallic = 0.1
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	mats["glass"] = g


# Textures. Each is 128 px and repeats every 2 m at scale 0.5. Noise is made seamless so the repeat does not show.
func _texture(kind: String) -> ImageTexture:
	var n := FastNoiseLite.new()
	n.seed = 7 + kind.hash() % 1000
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.06
	var cloud := n.get_seamless_image(128, 128)
	var n2 := FastNoiseLite.new()
	n2.seed = 99 + kind.hash() % 1000
	n2.noise_type = FastNoiseLite.TYPE_CELLULAR
	n2.frequency = 0.12
	var fine := n2.get_seamless_image(128, 128)
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 + kind.hash() % 1000
	var tile_tone: Array = []
	for i in 64:
		tile_tone.append(rng.randf_range(0.82, 1.1))
	for y in 128:
		for x in 128:
			var c := cloud.get_pixel(x, y).r
			var f := fine.get_pixel(x, y).r
			var col := Color.WHITE
			match kind:
				"flags":   # 4 x 4 flagstones with dark joints and a stagger on alternate rows
					var row := y / 32
					var xx := (x + (16 if row % 2 == 1 else 0)) % 128
					var col_i := xx / 32
					var joint := (y % 32) < 2 or (xx % 32) < 2
					var tone: float = tile_tone[row * 4 + col_i] * (0.85 + 0.3 * c)
					col = Color(0.12, 0.12, 0.12) if joint else Color(0.62, 0.62, 0.6) * tone * (0.92 + 0.12 * f)
				"planks":   # 8 boards across, grain along y
					var board := x / 16
					var gap := (x % 16) < 1
					var tone2: float = tile_tone[board] * (0.8 + 0.4 * n.get_noise_2d(x * 0.6, y * 0.04) * 0.5 + 0.2)
					var seam := (y + board * 37) % 128 < 1
					col = Color(0.1, 0.07, 0.05) if (gap or seam) else Color(0.46, 0.42, 0.38) * tone2
				"brick":   # 8 x 16 courses of brick with mortar
					var course := y / 8
					var bx := (x + (8 if course % 2 == 1 else 0)) % 128
					var mortar := (y % 8) < 1 or (bx % 16) < 1
					var t3: float = tile_tone[(course * 3 + bx / 16) % 64] * (0.8 + 0.4 * c)
					col = Color(0.5, 0.48, 0.44) if mortar else Color(0.4, 0.31, 0.28) * t3 * (0.9 + 0.2 * f)
				"metal":
					var s := 0.55 + 0.35 * c + 0.12 * f
					col = Color(s, s, s * 1.03)
				"coal":
					var s2 := 0.25 + 0.5 * f * f + 0.25 * c
					col = Color(s2, s2, s2 * 1.05)
				_:   # plaster: a warm, mottled wall
					var s3 := 0.82 + 0.22 * c - 0.1 * f
					col = Color(s3, s3 * 0.97, s3 * 0.92)
			img.set_pixel(x, y, col.clamp())
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
