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


## A window surround: `w` x `h` opening, centre at the origin. `recess`: how far its stones reach back into the wall behind the outer face at the
## opening's centre line. `curve_r`: the radius of a round wall (the tower), 0 for a flat one. The surround is flat, so on a round wall each stone
## reaches back further by the wall's fall-away at its outer end (0.12 m at the side stones of a 0.9 m window): the side stones meet the wall
## and the middle ones stay outside the interior lining (the tower's wall is thin; 0.1 m everywhere put the keystone through the lining).
static func window(parent: Node3D, id: String, w: float, h: float, stone: Material, recess := 0.1, curve_r := 0.0) -> Node3D:
	var k := Node3D.new()
	k.name = id + "_Surround"
	parent.add_child(k)
	var jw := 0.38                                    # wide enough to cover the ragged edge the carve leaves round the hole
	# jambs in alternating long and short blocks (quoins)
	var n := int(ceil((h + 0.2) / 0.45))
	for i in n:
		var y0 := -h * 0.5 - 0.1 + i * 0.45
		var bh := minf(0.45, h * 0.5 + 0.1 - y0)
		if bh < 0.05:
			continue
		var bw := jw + (0.08 if i % 2 == 0 else -0.04)
		var rq := recess + _fall(w * 0.5 + bw + 0.03, curve_r)
		for side in [-1.0, 1.0]:
			# their inner faces stand 3 cm back from the opening, behind the interior's reveal: flush with it they showed inside the window as stepped teeth
			_box(k, "Quoin%d_%s" % [i, "L" if side < 0.0 else "R"], Vector3(bw, bh - 0.025, PROJ + rq), Vector3(side * (w * 0.5 + bw * 0.5 + 0.03), y0 + bh * 0.5, (PROJ - rq) * 0.5), stone)
	# the long stones cover the wall's fall-away only half way to their ends: all the way, their middles would come through the lining
	var rl := recess + _fall((w + 1.0) * 0.5, curve_r) * 0.5
	_box(k, "Lintel", Vector3(w + 1.0, 0.3, PROJ + rl + 0.04), Vector3(0.0, h * 0.5 + 0.2, (PROJ - rl) * 0.5 + 0.02), stone)
	_box(k, "Keystone", Vector3(0.24, 0.42, PROJ + recess + 0.1), Vector3(0.0, h * 0.5 + 0.22, (PROJ - recess) * 0.5 + 0.05), stone)
	# the sill: a slab that leans outward so the rain runs off it, over a plain course
	_box(k, "Sill", Vector3(w + 0.9, 0.14, PROJ + rl + 0.14), Vector3(0.0, -h * 0.5 - 0.1, (PROJ - rl) * 0.5 + 0.07), stone, Vector3(deg_to_rad(-7.0), 0.0, 0.0))
	_box(k, "SillCourse", Vector3(w + 0.8, 0.16, PROJ + rl), Vector3(0.0, -h * 0.5 - 0.27, (PROJ - rl) * 0.5), stone)
	return k


## How far a round wall of radius `r` falls back from its tangent `x` along it (0 for a flat wall).
static func _fall(x: float, r: float) -> float:
	return 0.0 if r <= 0.0 else r - sqrt(maxf(r * r - x * x, 0.0))


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
