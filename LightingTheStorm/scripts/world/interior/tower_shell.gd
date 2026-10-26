# tower_shell.gd - the tower's inner wall, the stair, and the windows (Lighthouse Interior Creator Agent).
# The exterior model's tower is not a closed room inside: at the base it is a wide ragged plinth (radius 3 to over 5 m, open in
# places) and higher up its wall has gaps where the house meets it. This builds:
#   - a stone lining round the whole stairwell, ground floor to lamp-room floor. The wall is THICK AT THE BASE AND TAPERS: a
#     3.0 m plinth to 4.9 m, then a cone from 3.4 m at the first floor down to 2.9 m at the lamp room (a real tower's wall thins
#     as it rises). Openings only where there is a way through: the hall doorway, the keeper's quarters (first floor, house
#     side), the tower landing window, and the windows in data/world/lighthouse_windows.json, whose deep reveals show the
#     wall's thickness;
#   - the spiral stair as ONE mesh per step, from the newel to the wall (the v3 steps, which stopped at 2.07 m, are removed). Each
#     is a solid 0.4 m slab. At the four landings the steps stay narrow, because the landing rings join there.
# Bearings are degrees from +x toward +z round the tower axis; 147 is the house side.
extends "res://scripts/world/interior/rooms_tower.gd"

const GF := 0.97
const SECTOR := 3.75
const BAND := 0.25
const PLINTH_TOP := 4.92
const HOUSE_SIDE := Vector2(139.0, 165.0)      # the first floor's doorway into the tower: 1.3 m wide (it was a 45 degree gap, 2.4 m, much wider than its frame)
const G_DOOR := Vector2(127.5, 165.0)          # the hall's way into the tower
const WINDOW := Vector2(135.0, 160.0)          # the tower landing window (Level.tscn carve), bearing 147
const LANDING_STEPS := [[0, 2], [22, 25], [46, 49], [92, 95]]
const StairTread := preload("res://scripts/world/interior/stair_tread.gd")
const WINDOWS_JSON := "res://data/world/lighthouse_windows.json"
const AUTHORED_WALL := 0.75                   # the authored shell's tower wall thickness (build_shell_v1.py WALL_T)
const REVEAL := 0.8                            # how deep the window reveals are: the wall's thickness there

var windows: Array = []


var _radii: Dictionary = {}


## The lining's radius at height y on `bearing`: the tapered cone, pulled in to just inside the measured exterior wall wherever
## the wall comes closer (data/world/tower_radii.json, baked by tools/bake_tower_radii.gd), so nothing of the exterior shows through.
func wall_radius(y: float, bearing: float) -> float:
	if authored:
		# the authored shell (Assets/Models/lighthouse/shell/build_tower_shell_v1.py): its inner face IS this analytic radius, no measured pull-in
		return minf(analytic_inner(y), house_bite(y, bearing))
	if y < PLINTH_TOP:
		return 3.0
	var r := maxf(2.9, 3.4 - 0.0385 * (y - PLINTH_TOP))
	if not _radii.is_empty():
		var rows: Array = _radii["rows"]
		var j := clampi(int(floor((y - float(_radii["y0"])) / float(_radii["y_step"]))), 0, rows.size() - 1)
		var k := int(floor(fposmod(bearing, 360.0) / float(_radii["bearing_step"]))) % (rows[j] as Array).size()
		var m: float = rows[j][k]
		if m <= 0.0:
			# no measurement here (the table has -1 over the carved clearing at 15.5 to 17.5 m): use the smallest measured radius within two rows and
			# four sectors, so the lining stays in front of whatever the exterior leaves poking in (the shards in the stairwell wall, creator 2026-10-25)
			var best := 99.0
			var nk: int = (rows[j] as Array).size()
			for dj in range(-2, 3):
				var jj := clampi(j + dj, 0, rows.size() - 1)
				for dk in range(-4, 5):
					var v: float = rows[jj][(k + dk + nk) % nk]
					if v > 0.0:
						best = minf(best, v)
			m = best if best < 99.0 else -1.0
		if m > 0.0:
			r = minf(r, maxf(float(_radii["min_radius"]), m - float(_radii["margin"])))
	return r


func _load_windows() -> void:
	var rf := FileAccess.open("res://data/world/tower_radii.json", FileAccess.READ)
	if rf:
		_radii = JSON.parse_string(rf.get_as_text())
	var f := FileAccess.open(WINDOWS_JSON, FileAccess.READ)
	if f:
		windows = (JSON.parse_string(f.get_as_text()) as Dictionary).get("windows", [])
	# the tower landing window is a baked carve in Level.tscn (bearing 147, 1.0 x 1.8 m, centre y 15.09), not an entry in the windows data: it gets the same
	# reveals, mullion and glass as the others here, and the same stone surround outside (exterior_openings.gd), in place of a floating wooden frame
	windows.append({"id": "T_landing_147", "kind": "tower", "bearing": 147.0, "y": 15.09, "w": 1.0, "h": 1.8})


func _tower_window_open(mid: float, a0: float, a1: float, y0: float, y1: float) -> bool:
	# a panel opens only when its CENTRE is inside the window: the opening is never larger than the carve in the exterior, so no
	# quantised corner shows the raw exterior behind it (the reveal bars cover the difference)
	for w in windows:
		if w["kind"] != "tower":
			continue
		var r := wall_radius(w["y"], w["bearing"])
		var half := rad_to_deg(float(w["w"]) * 0.5 / r)
		var ym := (y0 + y1) * 0.5
		if absf(mid - float(w["bearing"])) < half and absf(ym - float(w["y"])) < float(w["h"]) * 0.5:
			return true
	return false


func build_shell(kit, lh: Node3D) -> void:
	K = kit
	_lh = lh
	_load_windows()
	var P := Node3D.new()
	P.name = "TowerShell"
	lh.add_child(P)
	if not authored:
		_lining(P)
	_stairs(P)
	_tower_window_frames(P)


func _lining(P: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sectors := int(360.0 / SECTOR)
	var ys: Array[float] = [0.67, 3.4, PLINTH_TOP]
	var y := PLINTH_TOP + BAND
	while y < 17.9 - 0.001:
		ys.append(y)
		y += BAND
	ys.append(17.9)
	for s in sectors:
		var a0 := SECTOR * float(s)
		var a1 := a0 + SECTOR
		var mid := a0 + SECTOR * 0.5
		for j in ys.size() - 1:
			var y0: float = ys[j]
			var y1: float = ys[j + 1]
			var open := false
			if y1 <= 3.4 + 0.001 and mid > G_DOOR.x and mid < G_DOOR.y:
				open = true      # the hall's doorway
			elif y0 >= PLINTH_TOP - 0.001 and y1 <= 7.45 + 0.001 and mid > HOUSE_SIDE.x and mid < HOUSE_SIDE.y:
				open = true      # the first floor's rooms
			elif y0 >= 14.1 - 0.001 and y1 <= 16.1 + 0.001 and mid > WINDOW.x and mid < WINDOW.y:
				open = true      # the tower landing window
			elif _tower_window_open(mid, a0, a1, y0, y1):
				open = true
			if open:
				continue
			_wall_quad(st, a0, a1, y0, y1)
	# the plinth's shoulder: the wall steps in from 3.0 to 3.4 at PLINTH_TOP
	for s in sectors:
		var mid := SECTOR * (float(s) + 0.5)
		if mid > HOUSE_SIDE.x and mid < HOUSE_SIDE.y:
			continue
		_shelf(st, 3.0, wall_radius(PLINTH_TOP + 0.001, mid), SECTOR * float(s), SECTOR * float(s + 1), PLINTH_TOP)
	var mi := MeshInstance3D.new()
	mi.name = "TowerLining"
	st.generate_normals()
	mi.mesh = st.commit()
	mi.material_override = _ds("stone")
	P.add_child(mi)
	mi.create_trimesh_collision()
	for c in mi.get_children():
		if c is StaticBody3D:
			c.collision_layer = 1
			for sh in c.get_children():
				var cs := (sh as CollisionShape3D).shape as ConcavePolygonShape3D
				if cs:
					cs.backface_collision = true
	K.count += 1


## The radius at a sector edge (bearing `a`, height y): the smaller of the two sectors it joins, so neighbouring panels share
## their vertices and there is no crack between them.
func _edge_r(y: float, a: float) -> float:
	return minf(wall_radius(y, a - SECTOR * 0.5), wall_radius(y, a + SECTOR * 0.5))


func _wall_quad(st: SurfaceTool, a0: float, a1: float, y0: float, y1: float) -> void:
	var t0 := deg_to_rad(a0)
	var t1 := deg_to_rad(a1)
	var p00 := Vector3(TOWER.x + _edge_r(y0, a0) * cos(t0), y0, TOWER.y + _edge_r(y0, a0) * sin(t0))
	var p10 := Vector3(TOWER.x + _edge_r(y0, a1) * cos(t1), y0, TOWER.y + _edge_r(y0, a1) * sin(t1))
	var p01 := Vector3(TOWER.x + _edge_r(y1, a0) * cos(t0), y1, TOWER.y + _edge_r(y1, a0) * sin(t0))
	var p11 := Vector3(TOWER.x + _edge_r(y1, a1) * cos(t1), y1, TOWER.y + _edge_r(y1, a1) * sin(t1))
	var mid := deg_to_rad((a0 + a1) * 0.5)
	var nrm := Vector3(-cos(mid), 0.0, -sin(mid))      # facing the axis
	_tri(st, p00, p10, p11, nrm)
	_tri(st, p00, p11, p01, nrm)


func _shelf(st: SurfaceTool, r0: float, r1: float, a0: float, a1: float, y: float) -> void:
	var t0 := deg_to_rad(a0)
	var t1 := deg_to_rad(a1)
	var p := [
		Vector3(TOWER.x + r0 * cos(t0), y, TOWER.y + r0 * sin(t0)), Vector3(TOWER.x + r1 * cos(t0), y, TOWER.y + r1 * sin(t0)),
		Vector3(TOWER.x + r1 * cos(t1), y, TOWER.y + r1 * sin(t1)), Vector3(TOWER.x + r0 * cos(t1), y, TOWER.y + r0 * sin(t1)),
	]
	_tri(st, p[0], p[1], p[2], Vector3.DOWN)
	_tri(st, p[0], p[2], p[3], Vector3.DOWN)


## One mesh per step, newel to wall, a solid slab 0.4 m thick (the v3 slabs were 0.18 m and stopped at 2.07 m).
## The radius a piece spanning bearings a0..a1 at height y may reach: the wall's inner face (the smallest over the span), and with the authored shell exactly that,
## because the shell is exact; with the old exterior mesh 2 cm into it so no gap shows.
func span_radius(y: float, a0: float, a1: float) -> float:
	if not authored:
		return wall_radius(y, (a0 + a1) * 0.5) + 0.02
	return minf(wall_radius(y, a0), minf(wall_radius(y, (a0 + a1) * 0.5), wall_radius(y, a1)))


func _stairs(P: Node3D) -> void:
	var stone := _ds("stone_worn")
	for i in 96:
		var narrow := false
		for g in LANDING_STEPS:
			if i >= g[0] and i <= g[1]:
				narrow = true
		var a0 := LANDING_DEG + 15.0 * i
		var bot := 0.97 + float(i) * RISE
		var top := bot + RISE
		var wb := fposmod(a0 + 7.5, 360.0)
		if wb > WINDOW.x - 22.5 and wb < WINDOW.y + 22.5 and bot > 13.0:
			narrow = true      # the treads in front of the tower window keep the view clear
		var r := 2.07 if narrow else span_radius(top, a0, a0 + 15.0)
		var thick := RISE if narrow else 0.4
		# collision as before (newel to wall, hidden); what you see is a detailed tread over the walkable 1.14..2.07 m, and a plain filler
		# slab out to the wall behind the outer rail
		_arc(P, "StepBody_%d" % i, 1.14, r, a0, a0 + 15.0, top - thick, top, stone, true, false)
		StairTread.add(P, "Step_%d" % i, TOWER, 1.12, 2.07, a0, a0 + 15.0, top, thick, stone, i)
		if r > 2.09:
			_arc(P, "StepFill_%d" % i, 2.06, r, a0, a0 + 15.0, top - thick, top - 0.03, stone, false)
		elif i < 92 and bot > 13.0 and wb > WINDOW.x - 22.5 and wb < WINDOW.y + 22.5:
			# the steps in front of the tower landing window keep the window itself clear, but left a void between their edge and the wall (the
			# "missing section of the stairs", creator 2026-10-25): fill out to the wall on both sides of the window's own sector (bearing 147 +- 14)
			var wr := span_radius(top, a0, a0 + 15.0)
			for seg in [[a0, minf(a0 + 15.0, 133.0)], [maxf(a0, 161.0), a0 + 15.0]]:
				if seg[1] - seg[0] > 0.5:
					_arc(P, "StepWindowFill_%d_%d" % [i, int(seg[0])], 2.06, wr, seg[0], seg[1], top - RISE, top - 0.03, stone, false)
		elif i <= 2:
			# the first narrow steps beside the hall door left the ring's floor showing between their outer edge and the wall (creator,
			# 2026-10-25): fill out to the wall, from the ring up to each step's top, but only past the doorway (bearing 165 on) so the way in stays open
			var fa0 := maxf(a0, 165.0 + 360.0 * floorf(a0 / 360.0))
			if fa0 < a0 + 14.0:
				_arc(P, "StepWallFill_%d" % i, 2.06, span_radius(top, fa0, a0 + 15.0), fa0, a0 + 15.0, 0.97 - 0.004, top - 0.03, stone, false)


## Reveals, glass and a barrier for each tower window: the reveal boxes are the wall's thickness (REVEAL deep).
func _tower_window_frames(P: Node3D) -> void:
	var stone := _m("stone")
	for w in windows:
		if w["kind"] != "tower":
			continue
		var b: float = w["bearing"]
		var y: float = w["y"]
		var ww: float = w["w"]
		var hh: float = w["h"]
		var r := wall_radius(y, b)
		var rc := r + REVEAL * 0.5
		if authored:
			# the authored wall already has real reveals (the opening is cut through its 0.75 m): no stone boxes, the pane stands mid-wall
			var rg := r + AUTHORED_WALL * 0.5
			_rbox(P, w["id"] + "_Glass", b, rg, ww, 0.02, y - hh * 0.5, y + hh * 0.5, _m("glass"), false)
			_rbox(P, w["id"] + "_Mullion", b, rg - 0.01, 0.04, 0.04, y - hh * 0.5, y + hh * 0.5, _m("iron_dark"), false)
			var bar2 := _rbox(P, w["id"] + "_Barrier", b, r + 0.06, ww + 0.1, 0.1, y - hh * 0.5 - 0.1, y + hh * 0.5, _m("glass"), true)
			bar2.visible = false
			(bar2.get_node("Body") as StaticBody3D).add_to_group("glass")
			continue
		var dth := rad_to_deg((ww * 0.5 + 0.2) / r)      # jambs 0.4 m wide: they cover the sector quantisation round the opening
		_rbox(P, w["id"] + "_Sill", b, rc, ww + 0.9, REVEAL, y - hh * 0.5 - 0.3, y - hh * 0.5, _m("stone"), false)
		_rbox(P, w["id"] + "_Head", b, rc, ww + 0.9, REVEAL, y + hh * 0.5, y + hh * 0.5 + 0.3, _m("stone"), false)
		_rbox(P, w["id"] + "_JambL", b - dth, rc, 0.4, REVEAL, y - hh * 0.5, y + hh * 0.5, _m("stone"), false)
		_rbox(P, w["id"] + "_JambR", b + dth, rc, 0.4, REVEAL, y - hh * 0.5, y + hh * 0.5, _m("stone"), false)
		_rbox(P, w["id"] + "_Glass", b, r + REVEAL, ww, 0.02, y - hh * 0.5, y + hh * 0.5, _m("glass"), false)
		_rbox(P, w["id"] + "_Mullion", b, r + REVEAL - 0.01, 0.04, 0.04, y - hh * 0.5, y + hh * 0.5, _m("iron_dark"), false)
		var bar := _rbox(P, w["id"] + "_Barrier", b, r + 0.06, ww + 0.1, 0.1, y - hh * 0.5 - 0.1, y + hh * 0.5, _m("glass"), true)
		bar.visible = false
		(bar.get_node("Body") as StaticBody3D).add_to_group("glass")
	K.count += 4
