# spiral_down.gd - the spiral stair from the hall down to the basement (replaces the v3 greybox's switchback flights).
# One full turn of 15 stone treads round a central newel, in the stairwell hole of the ground floor (u 0.8..3.6, v 2.3..5.7),
# like the tower's main stair. It starts at the middle of the hole's front edge and comes out at the same angle at the
# foot, into the basement lobby. The outer edge has a handrail and an invisible wall, open at the first and last tread.
# Built in the lighthouse frame (the treads are wedges round a centre), so it shares the helpers of rooms_tower.gd.
extends "res://scripts/world/interior/rooms_tower.gd"

const StairTread := preload("res://scripts/world/interior/stair_tread.gd")
const GF := 0.97
const B1 := -2.0
const STEPS := 15
const R_IN := 0.3
const R_OUT := 1.35
## The stair's centre in the house frame (u, v).
const CENTRE_UV := Vector2(2.2, 4.0)

var centre := Vector2.ZERO


func build_spiral(kit, house: Node3D, lh: Node3D) -> void:
	K = kit
	_lh = lh
	var lp: Vector3 = house.position + house.basis * kit.p(CENTRE_UV.x, 0.0, CENTRE_UV.y)
	centre = Vector2(lp.x, lp.z)
	var P := Node3D.new()
	P.name = "SpiralDown"
	lh.add_child(P)
	var dh := (GF - B1) / float(STEPS + 1)
	# the hall side of the house is the +z direction of the house frame: bearing of the door normal in the lighthouse frame
	var front := rad_to_deg(atan2(0.9024, 0.4309))
	var stone := _ds("stone_worn")
	var wood := _m("wood_dark")
	var iron := _m("iron_dark")
	var span := 360.0 / float(STEPS)
	for k in STEPS:
		var a0 := front - span * 0.5 + span * k
		var top := GF - dh * float(k + 1)
		_arc(P, "SpiralBody_%d" % k, R_IN - 0.02, R_OUT, a0, a0 + span, top - 0.12, top, stone, true, false, centre)
		StairTread.add(P, "SpiralStep_%d" % k, centre, R_IN - 0.02, R_OUT, a0, a0 + span, top, 0.18, stone, 500 + k)
	# one more step, flush with the hall floor, in front of the first tread (creator, 2026-10-25): the way in was a drop from the edge of the
	# hole to the first tread, and a player stepping in sideways could fall straight to the basement. This one is level with the floor, so
	# the stair is entered across it and the first real tread is a normal riser below.
	var a_land := front - span * 1.5
	_arc(P, "SpiralLanding", R_IN - 0.02, R_OUT, a_land, a_land + span, GF - 0.18, GF, stone, true, false, centre)
	StairTread.add(P, "SpiralLandingStep", centre, R_IN - 0.02, R_OUT, a_land, a_land + span, GF, 0.18, stone, 499)
	# the newel
	_cyl(P, "SpiralNewel", Vector3(centre.x, B1, centre.y), Vector3(centre.x, GF + 0.3, centre.y), R_IN, _m("stone"), true)
	# the handrail on the outer edge, open at the first and last tread
	var pts: Array[Vector3] = []
	for k in STEPS + 1:
		var a := front - span * 0.5 + span * k
		pts.append(_ptc(a, R_OUT - 0.03, GF - dh * float(k + 1) + 0.95))
	for k in range(1, STEPS - 1):
		var a0 := front - span * 0.5 + span * k
		var top := GF - dh * float(k + 1)
		_cyl(P, "SpiralRail_Post%d" % k, _ptc(a0, R_OUT - 0.03, top), pts[k], 0.025, iron, false)
		_cyl(P, "SpiralRail_Bar%d" % k, pts[k], pts[k + 1], 0.032, wood, false)
		_arc(P, "SpiralRail_Wall%d" % k, R_OUT - 0.04, R_OUT - 0.01, a0, a0 + span, top + 0.3, top + 1.1, iron, true, false, centre)   # starts 0.3 above the tread: it must not hang at head height over the floor below
	_g_opening(P, front)
	K.count += 8
	anchors["spiral_top"] = Vector3(CENTRE_UV.x, GF, CENTRE_UV.y - R_OUT - 0.2)
	anchors["spiral_foot"] = Vector3(CENTRE_UV.x, B1 + 0.15, CENTRE_UV.y - R_OUT - 0.25)


## The ground floor round the stair: the v3 hole is a 2.8 x 3.4 m rectangle, far bigger than the spiral, and its corners
## were a drop to the basement. Floor fills everything outside a circle just wider than the treads (an annulus out to the
## hole's corners, 4 mm under the floor so the existing floor wins where they overlap), and a rail runs round the circle
## except across the entrance, where the hall floor meets the first tread.
func _g_opening(P: Node3D, front: float) -> void:
	_arc(P, "G_StairFloor", R_OUT + 0.07, 2.35, 0.0, 360.0, GF - 0.2, GF - 0.004, _ds("flags"), true, true, centre)
	var iron := _m("iron_dark")
	var wood := _m("wood_dark")
	var rr := R_OUT + 0.1
	var gap := 32.0
	for a0 in range(0, 360, 15):
		var mid := float(a0) + 7.5
		var d := absf(fposmod(mid - front + 180.0, 360.0) - 180.0)
		if d < gap:
			continue
		_cyl(P, "G_StairRing_Post%d" % a0, _ptc(float(a0), rr, GF), _ptc(float(a0), rr, GF + 1.0), 0.03, iron, false)
		_cyl(P, "G_StairRing_Bar%d" % a0, _ptc(float(a0), rr, GF + 1.0), _ptc(float(a0) + 15.0, rr, GF + 1.0), 0.035, wood, false)
		_arc(P, "G_StairRing_Wall%d" % a0, rr - 0.03, rr + 0.03, float(a0), float(a0) + 15.0, GF, GF + 1.0, iron, true, false, centre)


func _ptc(bearing_deg: float, r: float, y: float) -> Vector3:
	var a := deg_to_rad(bearing_deg)
	return Vector3(centre.x + r * cos(a), y, centre.y + r * sin(a))
