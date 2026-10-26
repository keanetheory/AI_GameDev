# trim.gd - architectural trim for the house (Lighthouse Finisher Agent, LHF-15): what makes a room read as built, not boxed.
# Everything is non-solid (the rooms' collision is untouched) and built in the house frame (kit.gd: u along the front wall, v inward,
# y absolute). It adds:
#   - moulded skirting boards (a tall plinth under a bead) round every ground-floor panelled wall, the first-floor lining and both
#     sides of every first-floor partition, so the plaster no longer meets the floor in a flat line;
#   - a stepped cornice on the ground-floor front and east walls (the west and back walls already had one) and under the first-floor
#     eaves-side walls;
#   - a picture rail in the hall and office, and door architraves (jambs, a head with a returning cap) on the ground-floor doorways;
#   - first floor: a stone hearth slab round the stove and a kitchen splash back of pale tile behind the sink and counter (a chimney
#     breast was tried and removed: the stove stands clear of the wall and the breast read as floating);
#   - basement: brick piers every 1.8 m along the walls, iron pipe brackets, a cable run with clips along the west wall and ceiling, a
#     conduit dropping to each lamp, and a floor drain with a grate.
# Door and window frames that already exist (kit, rooms_tower _doorframe, exterior_openings) are not duplicated.
extends RefCounted

const GF := 0.97
const L1 := 5.2025
const CEIL := 3.75
const B1 := -2.0
const BCEIL := 0.77

var K
var built := 0
var group: Node3D


func build(kit, frame: Node3D) -> void:
	K = kit
	group = Node3D.new()
	group.name = "Trim"
	frame.add_child(group)
	_ground()
	_first_floor()
	if OS.get_environment("LHF_SHELL") != "2":      # the authored shell has its own gable walls
		_gables()
	_basement()
	_hearth()


func _b(nm: String, u0: float, u1: float, v0: float, v1: float, y0: float, y1: float, m) -> void:
	K.box(group, nm, u0, u1, v0, v1, y0, y1, m, false)
	built += 1


## A skirting board along one wall: `wall` is "u" (the wall runs along u at a fixed v) or "v" (runs along v at a fixed u); `at` is the
## wall face; `side` is +1 or -1, the direction the room is on. Plinth 0.13 high, 0.025 proud, with a thin bead on top.
func _skirt(nm: String, wall: String, at: float, a0: float, a1: float, side: float, y: float, m := "wood_dark") -> void:
	var p := 0.028
	var q := 0.015
	if wall == "u":
		_b(nm + "_P", a0, a1, at, at + side * p, y, y + 0.13, m)
		_b(nm + "_B", a0, a1, at, at + side * (p + q), y + 0.13, y + 0.155, "wood")
	else:
		_b(nm + "_P", at, at + side * p, a0, a1, y, y + 0.13, m)
		_b(nm + "_B", at, at + side * (p + q), a0, a1, y + 0.13, y + 0.155, "wood")


## A stepped cornice: two stacked, widening strips under the ceiling.
func _cornice(nm: String, wall: String, at: float, a0: float, a1: float, side: float, y_top: float) -> void:
	for k in 2:
		var d := 0.07 + 0.06 * k
		var y0 := y_top - 0.14 + 0.07 * (1 - k) * 0.0 - 0.0
		var h := 0.07
		var yy := y_top - h * (k + 1)
		if wall == "u":
			_b("%s_%d" % [nm, k], a0, a1, at, at + side * d, yy, yy + h, "wood" if k == 0 else "wood_dark")
		else:
			_b("%s_%d" % [nm, k], at, at + side * d, a0, a1, yy, yy + h, "wood" if k == 0 else "wood_dark")


func _ground() -> void:
	# skirting over the panel bases (panel faces: west u -2.10, back v 6.65, east u 5.5, front v 0.41)
	_skirt("G_SkirtWest", "v", -2.10, 0.41, 6.65, 1.0, GF)
	_skirt("G_SkirtBack", "u", 6.65, -2.10, 5.5, -1.0, GF)
	_skirt("G_SkirtEast", "v", 5.5, 2.25, 6.65, -1.0, GF)
	_skirt("G_SkirtFrontL", "u", 0.41, -2.10, -0.95, 1.0, GF)
	_skirt("G_SkirtFrontR", "u", 0.41, 0.95, 5.5, 1.0, GF)
	# the cornice the west and back walls already have, on the front and east
	_cornice("G_CorniceFront", "u", 0.41, -2.15, 5.55, 1.0, CEIL - 0.1)
	_cornice("G_CorniceEast", "v", 5.5, 0.41, 6.7, -1.0, CEIL - 0.1)
	# a picture rail round the hall, 0.5 m under the cornice
	var pr := GF + 2.55
	_b("G_PicRail_West", -2.10, -2.065, 0.45, 6.6, pr, pr + 0.035, "wood")
	_b("G_PicRail_Back", -2.1, 5.45, 6.615, 6.65, pr, pr + 0.035, "wood")
	_b("G_PicRail_East", 5.465, 5.5, 2.3, 6.6, pr, pr + 0.035, "wood")
	# architraves on the two doorways that have none: the storage room's door and the tower doorway's inside
	_architrave("G_ArchStore", "u", 3.37, 4.2, 5.05, 1.0, GF, 2.35)


## A doorway surround on a wall that runs along u at v = `at`: jambs, a head with a cap that returns at each end.
func _architrave(nm: String, wall: String, at: float, a0: float, a1: float, side: float, y0: float, h: float) -> void:
	var w := 0.1
	var pr := 0.03
	if wall == "u":
		_b(nm + "_JL", a0 - w, a0, at, at + side * pr, y0, y0 + h, "wood")
		_b(nm + "_JR", a1, a1 + w, at, at + side * pr, y0, y0 + h, "wood")
		_b(nm + "_Head", a0 - w, a1 + w, at, at + side * pr, y0 + h, y0 + h + w, "wood")
		_b(nm + "_Cap", a0 - w - 0.04, a1 + w + 0.04, at, at + side * (pr + 0.02), y0 + h + w, y0 + h + w + 0.04, "wood_dark")


func _first_floor() -> void:
	var Y := L1
	# the lining planes: west u -3.0, back v 8.7, east u 5.39 (rooms_tower.gd); skirting on their room side
	_skirt("L1_SkirtLiningWest", "v", -3.0, 0.95, 8.7, 1.0, Y)
	_skirt("L1_SkirtLiningBack", "u", 8.7, -3.0, 5.39, -1.0, Y)
	_skirt("L1_SkirtLiningEast", "v", 5.39, 2.2, 8.6, -1.0, Y)
	# partitions: both faces. H1 v 2.55..2.65 (doorways at u -2.1..-1.0, -0.1..1.0, 3.3..4.5), W1 u -0.25..-0.15, W2 u 1.45..1.55, W3 v 5.55..5.65
	for seg in [[-3.0, -2.1], [-1.0, -0.1], [1.0, 3.3], [4.5, 5.4]]:
		_skirt("L1_SkirtH1S_%d" % int(seg[0] * 10), "u", 2.55, seg[0], seg[1], -1.0, Y)
		_skirt("L1_SkirtH1N_%d" % int(seg[0] * 10), "u", 2.65, seg[0], seg[1], 1.0, Y)
	_skirt("L1_SkirtW1W", "v", -0.25, 2.65, 8.6, -1.0, Y)
	_skirt("L1_SkirtW1E", "v", -0.15, 2.65, 8.6, 1.0, Y)
	_skirt("L1_SkirtW2W", "v", 1.45, 2.65, 6.3, -1.0, Y)
	_skirt("L1_SkirtW2E", "v", 1.55, 2.65, 6.3, 1.0, Y)
	_skirt("L1_SkirtW2bW", "v", 1.45, 7.2, 8.6, -1.0, Y)
	_skirt("L1_SkirtW2bE", "v", 1.55, 7.2, 8.6, 1.0, Y)
	_skirt("L1_SkirtW3S", "u", 5.55, -0.2, 1.45, -1.0, Y)
	_skirt("L1_SkirtW3N", "u", 5.65, -0.2, 1.45, 1.0, Y)
	# a picture rail along the long partitions' mess and hall sides
	var pr := Y + 1.85
	_b("L1_PicRail_W2", 1.55, 1.585, 2.7, 6.2, pr, pr + 0.03, "wood")
	# the mess: a splash back of pale tile behind the sink and counter (u 1.6..2.3, against the back wall v 8.7)
	for i in 6:
		for j in 3:
			var u0 := 1.6 + 0.12 * i
			_b("L1_Tile_%d_%d" % [i, j], u0 + 0.004, u0 + 0.116, 8.66, 8.69, Y + 0.95 + 0.1 * j, Y + 0.95 + 0.1 * j + 0.096, "whitewash")
	_b("L1_TileCap", 1.6, 2.32, 8.64, 8.7, Y + 1.25, Y + 1.275, "wood")


func _hearth() -> void:
	var Y := L1
	# the stove stands at u 4.55..5.35, v 6.0..6.9 by the east lining (u 5.39): a stone hearth under and in front of it.
	_b("L1_Hearth", 4.1, 5.39, 5.75, 7.15, Y, Y + 0.035, "stone")
	_b("L1_HearthEdge", 4.06, 4.1, 5.71, 7.19, Y, Y + 0.05, "stone")


func _basement() -> void:
	# brick piers every 1.8 m on the west and back walls (the walls stand at u -2.15, v 6.7)
	for i in 4:
		var v := 1.4 + 1.6 * i
		_b("B_PierW_%d" % i, -2.15, -1.95, v - 0.2, v + 0.2, B1, BCEIL, "brick")
		_b("B_PierWCap_%d" % i, -2.15, -1.92, v - 0.22, v + 0.22, BCEIL - 0.1, BCEIL, "stone")
		_b("B_PierWBase_%d" % i, -2.15, -1.92, v - 0.22, v + 0.22, B1, B1 + 0.2, "stone")
	# a skirt course of dark stone along the base of the brick walls
	_b("B_PlinthW", -2.15, -2.1, 0.5, 6.7, B1, B1 + 0.16, "flags_dark")
	_b("B_PlinthBack", -2.15, 5.55, 6.64, 6.7, B1, B1 + 0.16, "flags_dark")
	# cable run: a tray along the west wall near the ceiling, with a clip every 0.8 m, and a drop to the wall light
	var ty := BCEIL - 0.35
	_b("B_CableTray", -2.15, -2.05, 0.5, 6.6, ty, ty + 0.04, "iron_dark")
	K.rod(group, "B_Cable_0", Vector3(-2.06, ty + 0.05, 0.5), Vector3(-2.06, ty + 0.05, 6.6), 0.012, "black")
	K.rod(group, "B_Cable_1", Vector3(-2.06, ty + 0.09, 0.5), Vector3(-2.06, ty + 0.09, 6.6), 0.012, "iron_dark")
	for i in 8:
		var v := 0.7 + 0.8 * i
		_b("B_CableClip_%d" % i, -2.1, -2.04, v, v + 0.05, ty, ty + 0.13, "iron")
		built += 1
	# iron brackets under the steam main: every 1.2 m along the back wall
	for i in 5:
		var u := -1.2 + 1.5 * i
		_b("B_Bracket_%d" % i, u, u + 0.04, 6.6, 6.7, B1 + 1.2, B1 + 1.38, "iron")
	# a drain with a grate in the floor of the boiler room
	_b("B_Drain", 1.0, 1.5, 3.7, 4.2, B1, B1 + 0.012, "black")
	for i in 5:
		_b("B_DrainBar_%d" % i, 1.03 + 0.09 * i, 1.07 + 0.09 * i, 3.72, 4.18, B1 + 0.012, B1 + 0.03, "iron_dark")


## The gable ends of the first floor (creator, 2026-10-25: "the top of Ted's room has no walls"). The plaster ceiling follows the roof pitch and
## stops at the end walls, and the lining there stops at the wall top, so the exterior roof (orange, with its own texture) showed in the triangle
## between them. A plaster panel in each end plane closes it: apex at the ridge, base overlapping the lining below.
func _gables() -> void:
	var Y := L1
	for g in [[-3.0, 2.6, -1.0], [5.39, 2.2, 1.0]]:          # [u of the end wall, base height above the floor, direction the room is (+u / -u)]
		var u: float = g[0]
		var base: float = Y + float(g[1])
		# the ceiling line: front slope (v 0.9, Y+1.45) to the ridge (v 5.0, Y+4.0), back slope to (v 8.9, Y+1.6): where it meets `base`
		var v_front := 0.9 + (base - (Y + 1.45)) / (2.55 / 4.1)
		var v_back := 5.0 + ((Y + 4.0) - base) / (2.4 / 3.9)
		var top := Y + 3.97
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for pts in [[Vector3(u, base, -v_front), Vector3(u, base, -v_back), Vector3(u, top, -5.0)]]:
			for k in [0, 1, 2]:
				st.set_normal(Vector3(-float(g[2]), 0.0, 0.0))
				st.add_vertex(pts[k])
		var mi := MeshInstance3D.new()
		mi.name = "L1_Gable_%s" % ("W" if u < 0.0 else "E")
		mi.mesh = st.commit()
		var m := (K.mats["plaster"] as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.add_child(mi)
		built += 1
