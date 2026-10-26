# opening_kit.gd - the stone dressing for the lighthouse's openings (Lighthouse Finisher Agent, LHF-12).
# The exterior model's windows and door are ragged holes. Every opening gets the same kit on its outside: a surround of
# dressed stone that stands proud of the wall and overlaps the hole's edge, so no flap or gap shows. Windows: jambs, a lintel with
# a keystone, a sloped sill that throws the rain off. The door: quoined jambs, a voussoir arch, a fanlight with iron spokes over
# the door, and a threshold stone. All parts are plain meshes (no collision) in one local frame: x along the wall, y up, z out of
# the wall; the origin is on the wall's outer face at the opening's centre (a door's: at its sill).
extends RefCounted

const PROJ := 0.2           # how far the surround stands out of the wall


static func _box(parent: Node3D, nm: String, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


## A window surround: `w` x `h` opening, centre at the origin.
static func window(parent: Node3D, id: String, w: float, h: float, stone: Material) -> Node3D:
	var k := Node3D.new()
	k.name = id + "_Surround"
	parent.add_child(k)
	var d := PROJ + 0.1
	var zc := PROJ * 0.5 - 0.05
	var jw := 0.38                                    # wide enough to cover the ragged edge the carve leaves round the hole
	# jambs in alternating long and short blocks (quoins)
	var n := int(ceil((h + 0.2) / 0.45))
	for i in n:
		var y0 := -h * 0.5 - 0.1 + i * 0.45
		var bh := minf(0.45, h * 0.5 + 0.1 - y0)
		if bh < 0.05:
			continue
		var bw := jw + (0.08 if i % 2 == 0 else -0.04)
		for side in [-1.0, 1.0]:
			_box(k, "Quoin%d_%s" % [i, "L" if side < 0.0 else "R"], Vector3(bw, bh - 0.025, d), Vector3(side * (w * 0.5 + bw * 0.5 - 0.02), y0 + bh * 0.5, zc), stone)
	_box(k, "Lintel", Vector3(w + 1.0, 0.3, d + 0.04), Vector3(0.0, h * 0.5 + 0.2, zc + 0.02), stone)
	_box(k, "Keystone", Vector3(0.24, 0.42, d + 0.1), Vector3(0.0, h * 0.5 + 0.22, zc + 0.05), stone)
	# the sill: a slab that leans outward so the rain runs off it, over a plain course
	_box(k, "Sill", Vector3(w + 0.9, 0.14, d + 0.14), Vector3(0.0, -h * 0.5 - 0.1, zc + 0.07), stone, Vector3(deg_to_rad(-7.0), 0.0, 0.0))
	_box(k, "SillCourse", Vector3(w + 0.8, 0.16, d), Vector3(0.0, -h * 0.5 - 0.27, zc), stone)
	return k


## The main door's surround. `w` x `h` is the door; the origin is at the sill's centre. `ink` is the iron for the fanlight spokes,
## `glass` the fanlight's dark glass.
static func door(parent: Node3D, id: String, w: float, h: float, stone: Material, iron: Material, glass: Material) -> Node3D:
	var k := Node3D.new()
	k.name = id + "_Surround"
	parent.add_child(k)
	var d := PROJ + 0.14
	var zc := PROJ * 0.5 - 0.05
	var jw := 0.34
	# quoined jambs: blocks of alternating width up each side
	var n := int(ceil(h / 0.5))
	for i in n:
		var y0 := i * 0.5
		var bh := minf(0.5, h - y0)
		var wide := (i % 2 == 0)
		var bw := jw + (0.1 if wide else -0.06)
		for side in [-1.0, 1.0]:
			var cx: float = side * (w * 0.5 + bw * 0.5 - 0.02)
			_box(k, "Quoin%d_%s" % [i, "L" if side < 0.0 else "R"], Vector3(bw, bh - 0.02, d), Vector3(cx, y0 + bh * 0.5, zc), stone)
	# the lintel course and the arch: voussoirs round a half circle over the door
	_box(k, "Lintel", Vector3(w + 0.9, 0.24, d + 0.04), Vector3(0.0, h + 0.12, zc + 0.02), stone)
	var r_in := w * 0.5 + 0.06
	var cy := h + 0.24
	var count := 11
	for i in count:
		var a := PI * (float(i) + 0.5) / float(count)
		var rr := r_in + 0.17
		var arc_w := (PI * rr / float(count)) * 1.08
		var m := _box(k, "Voussoir%d" % i, Vector3(0.34 + (0.06 if i % 2 == 0 else 0.0), arc_w, d + 0.02), Vector3(cos(a) * rr, cy + sin(a) * rr, zc + 0.01), stone)
		m.rotation = Vector3(0.0, 0.0, a)         # the block's long side (its x) points out along the radius
	# the fanlight: dark glass in the half circle, with iron spokes
	var fan := MeshInstance3D.new()
	fan.name = "Fanlight"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 24
	for i in steps:
		var a0 := PI * float(i) / float(steps)
		var a1 := PI * float(i + 1) / float(steps)
		for pt in [Vector3(0, cy, -0.04), Vector3(cos(a0) * r_in, cy + sin(a0) * r_in, -0.04), Vector3(cos(a1) * r_in, cy + sin(a1) * r_in, -0.04)]:
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(pt)
	fan.mesh = st.commit()
	fan.material_override = glass
	k.add_child(fan)
	for i in range(1, 6):
		var a := PI * float(i) / 6.0
		var spoke := _box(k, "Spoke%d" % i, Vector3(0.035, r_in, 0.05), Vector3(cos(a) * r_in * 0.5, cy + sin(a) * r_in * 0.5, -0.02), iron)
		spoke.rotation = Vector3(0.0, 0.0, a - PI * 0.5)
	_box(k, "FanRing", Vector3(r_in * 2.0, 0.05, 0.05), Vector3(0.0, cy + 0.01, -0.02), iron)
	# the threshold and a worn step
	_box(k, "Threshold", Vector3(w + 0.5, 0.1, 0.5), Vector3(0.0, 0.05, 0.12), stone)
	_box(k, "Step", Vector3(w + 0.9, 0.14, 0.45), Vector3(0.0, 0.07 - 0.12, 0.55), stone)
	return k
