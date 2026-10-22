# tower_shell.gd - the tower's inner wall and the stair's full width (Lighthouse Interior Creator Agent).
# The exterior model's tower is not a closed room inside: at the base it is a wide ragged plinth (radius 3 to over 5 m, open in
# places), higher up its wall has gaps where the house meets it, and the spiral only filled radius 1.14-2.07 of it, so the player
# could look out through the gaps to the island and the empty shell of the house. This builds:
#   - a lining wall round the whole stairwell, from the ground floor up to the lamp-room floor, at the radius the exterior wall
#     leaves room for at each height (probe: tools/probe_tower_radii.gd), with openings only where there is a way through: the
#     entry from the hall (ground floor), the house side of the first floor (the keeper's quarters), and the tower window;
#   - an extension to every stair tread, out to that wall, so the spiral is a full-width stair against the wall. The treads at the
#     landings (the entry, the first floor, the control landing, the lamp-room floor) are left alone: the landing ring joins there.
# Bearings are in degrees from +x toward +z round the tower axis, as everywhere in the tower; 147 is the house side.
extends "res://scripts/world/interior/rooms_tower.gd"

const GF := 0.97
const SECTOR := 7.5
const Y_BREAKS := [0.67, 3.4, 4.92, 7.4, 9.15, 12.0, 14.1, 16.1, 17.9]
const HOUSE_SIDE := Vector2(135.0, 180.0)      # where the first floor's rooms are: no tower wall at L1 height
const G_DOOR := Vector2(127.5, 165.0)          # the hall's way into the tower
const WINDOW := Vector2(135.0, 160.0)          # the tower landing window (Level.tscn carve): bearing 147, the house side
const LANDING_STEPS := [[0, 2], [22, 25], [46, 49], [92, 95]]


## The lining's radius at height y, in the sector centred on `bearing`.
func wall_radius(y: float, bearing: float) -> float:
	var house := bearing > HOUSE_SIDE.x and bearing < HOUSE_SIDE.y
	if y < 4.92:
		return 3.0
	if y < 7.4:
		return 3.4
	if y < 9.15:
		return 3.0 if house else 3.4
	return 2.95 if y < 12.0 else 2.9


func build_shell(kit, lh: Node3D) -> void:
	K = kit
	_lh = lh
	var P := Node3D.new()
	P.name = "TowerShell"
	lh.add_child(P)
	_lining(P)
	_stair_extensions(P)


func _lining(P: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sectors := int(360.0 / SECTOR)
	for s in sectors:
		var a0 := SECTOR * float(s)
		var a1 := a0 + SECTOR
		var mid := a0 + SECTOR * 0.5
		var prev_r := -1.0
		for j in Y_BREAKS.size() - 1:
			var y0: float = Y_BREAKS[j]
			var y1: float = Y_BREAKS[j + 1]
			var r := wall_radius((y0 + y1) * 0.5, mid)
			var open := false
			if y1 <= 3.4 + 0.001 and mid > G_DOOR.x and mid < G_DOOR.y:
				open = true      # the hall's doorway
			if y0 >= 4.92 - 0.001 and y1 <= 7.4 + 0.001 and mid > HOUSE_SIDE.x and mid < HOUSE_SIDE.y:
				open = true      # the first floor's rooms
			if y0 >= 14.1 - 0.001 and y1 <= 16.1 + 0.001 and mid > WINDOW.x and mid < WINDOW.y:
				open = true      # the tower window
			if not open:
				_wall_quad(st, r, a0, a1, y0, y1)
			# a shelf where the wall steps in or out between this band and the one below
			if prev_r > 0.0 and absf(prev_r - r) > 0.01:
				_shelf(st, minf(prev_r, r), maxf(prev_r, r), a0, a1, y0, prev_r > r)
			prev_r = r if not open else prev_r
	var mi := MeshInstance3D.new()
	mi.name = "TowerLining"
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


func _wall_quad(st: SurfaceTool, r: float, a0: float, a1: float, y0: float, y1: float) -> void:
	var t0 := deg_to_rad(a0)
	var t1 := deg_to_rad(a1)
	var p00 := Vector3(TOWER.x + r * cos(t0), y0, TOWER.y + r * sin(t0))
	var p10 := Vector3(TOWER.x + r * cos(t1), y0, TOWER.y + r * sin(t1))
	var p01 := Vector3(p00.x, y1, p00.z)
	var p11 := Vector3(p10.x, y1, p10.z)
	var mid := deg_to_rad((a0 + a1) * 0.5)
	var nrm := Vector3(-cos(mid), 0.0, -sin(mid))      # facing the axis
	_tri(st, p00, p10, p11, nrm)
	_tri(st, p00, p11, p01, nrm)


func _shelf(st: SurfaceTool, r0: float, r1: float, a0: float, a1: float, y: float, up: bool) -> void:
	var t0 := deg_to_rad(a0)
	var t1 := deg_to_rad(a1)
	var p := [
		Vector3(TOWER.x + r0 * cos(t0), y, TOWER.y + r0 * sin(t0)), Vector3(TOWER.x + r1 * cos(t0), y, TOWER.y + r1 * sin(t0)),
		Vector3(TOWER.x + r1 * cos(t1), y, TOWER.y + r1 * sin(t1)), Vector3(TOWER.x + r0 * cos(t1), y, TOWER.y + r0 * sin(t1)),
	]
	var nrm := Vector3.UP if up else Vector3.DOWN
	_tri(st, p[0], p[1], p[2], nrm)
	_tri(st, p[0], p[2], p[3], nrm)


## Extend every non-landing tread out to the lining: a wedge from the tread's outer edge (2.07) to the wall, the same height.
func _stair_extensions(P: Node3D) -> void:
	var stone := _ds("stone")
	for i in 96:
		var skip := false
		for g in LANDING_STEPS:
			if i >= g[0] and i <= g[1]:
				skip = true
		var a0 := LANDING_DEG + 15.0 * i
		# the tower window: leave the treads in front of it as they were, so the view out stays clear
		var wb := fposmod(a0 + 7.5, 360.0)
		if wb > WINDOW.x - 22.5 and wb < WINDOW.y + 22.5 and bot_y(i) > 13.0:
			skip = true
		if skip:
			continue
		var bot := 0.97 + float(i) * RISE
		var r := wall_radius(bot + RISE * 0.5, fposmod(a0 + 7.5, 360.0))
		_arc(P, "StairExt_%d" % i, 2.06, r + 0.02, a0, a0 + 15.0, bot, bot + RISE, stone, true)


func bot_y(i: int) -> float:
	return 0.97 + float(i) * RISE
