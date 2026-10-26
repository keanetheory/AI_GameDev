# rooms_tower.gd - the first floor and the tower landings (Lighthouse Interior Creator Agent, pass 2).
# L1 (blueprint "Keeper's Quarters") is the house's upper floor, reached up the tower stair: the spiral comes back to the
# house side every turn (y 5.20, 9.43, ...), and at L1 a doorway through the tower wall opens onto the house floor.
# L2 (blueprint "Control and Diagnostics") cannot be a house floor: the roof is too low (measured: 1.8-4.5 m of headroom
# above y 5.3, none above y 6.9). It is a landing ring round the spiral inside the tower, with the electrical control
# cabinet, the instrument station, the tool locker and the lamp-room hatch notes.
# House-frame coordinates (u, v, y) for L1; the tower pieces are in the lighthouse's own frame (centre T, bearings in
# degrees from +x toward +z), because the spiral is.
extends RefCounted

const TOWER := Vector2(3.5, 3.6)
const RISE := (17.9 - 0.97) / 96.0
const L1 := 0.97 + 24.0 * RISE      # 5.2025: the spiral is back on the house side
const L2 := 0.97 + 48.0 * RISE      # 9.4350
const LANDING_DEG := 147.0          # the bearing at which the spiral passes the house side
## The authored shell (Assets/Models/lighthouse/shell, LHF_SHELL set): the wall is exact, so the code is fitted to it, not the other way round.
var authored := shell_mode() != 0


## 0 (the default, the original lighthouse) = the old generated exterior with the code-built lining; 1 = the old exterior with the authored tower wall;
## 2 = the whole authored shell (build_shell_v1.py). Set LHF_SHELL=2 to try it; it is off by the creator's decision (2026-10-26: "I really don't like it").
static func shell_mode() -> int:
	var v := OS.get_environment("LHF_SHELL")
	return 0 if v == "" else int(v)
static var _spec: Dictionary = {}
const INNER_R := 2.13               # the ring's inner edge: just outside the stair (outer radius 2.07)

var K
var anchors := {}        # house frame (u, y, v)
var anchors_lh := {}     # lighthouse frame (x, y, z)
var refs := {}
var _mat_cache := {}
var _lh: Node3D


func build(kit, house: Node3D, lh: Node3D) -> void:
	K = kit
	_lh = lh
	var p1 := Node3D.new()
	p1.name = "FirstFloor"
	house.add_child(p1)
	_l1_house(p1)
	var p2 := Node3D.new()
	p2.name = "TowerLandings"
	lh.add_child(p2)
	_g_ring(p2)
	_l1_ring(p2)
	_l2_ring(p2)


# ======================================================================== L1: keeper's quarters (house frame)

func _l1_house(P: Node3D) -> void:
	var Y := L1
	# the floor: one slab over the ground floor's ceiling; planks on top, the doorway link into the tower
	# the slab's edges show from outside wherever the exterior wall is carved away, so the slab is STONE (a belt course) and the plank floor is a
	# thin sheet on top of it, inset 4 cm so the stone edge frames it (creator, 2026-10-25: a plank panel hung off the front-left corner)
	if authored:
		# the shell's slab is the floor (collision too); a thin plank sheet inset 4 cm inside the shell's inner faces, and the doorway sill is the slab itself
		var sp := shell_spec()
		K.box(P, "L1_FloorPlanks", float(sp["first_u"][0]) + 0.04, float(sp["first_u"][1]) - 0.04, float(sp["first_v"][0]) + 0.04, float(sp["first_v"][1]) - 0.04, Y - 0.012, Y, "planks", false)
	else:
		K.box(P, "L1_Floor", -3.0, 5.5, 0.9, 9.0, 3.95, Y - 0.012, "stone", true)
		K.box(P, "L1_FloorPlanks", -2.96, 5.46, 0.94, 8.96, Y - 0.012, Y, "planks", false)
		K.box(P, "L1_TowerLink", 5.4, 6.6, 1.0, 2.2, Y - 0.2, Y - 0.008, "flags", true)
	# partitions, 2.3 m high (the roof is higher than that wherever there is a partition), with doorways
	var pw := 2.1
	# H1: v 2.6, the hall's back wall, with doors into the sleeping quarters, the radio room and the mess
	_wall(P, "L1_H1_a", -3.0, -2.1, 2.55, 2.65, Y, pw)
	_wall(P, "L1_H1_b", -1.0, -0.1, 2.55, 2.65, Y, pw)
	_wall(P, "L1_H1_c", 1.0, 3.3, 2.55, 2.65, Y, pw)
	_wall(P, "L1_H1_d", 4.5, 5.38, 2.55, 2.65, Y, pw)      # ends at the east wall: at 5.5 it poked through the tower lining as a cream sliver (creator, 2026-10-25)
	# W1: u -0.2, between sleeping quarters and the radio / wash rooms
	_wall(P, "L1_W1", -0.25, -0.15, 2.65, 8.6, Y, pw)
	# W2: u 1.5, between the radio / wash rooms and the mess, with a gap into the wash room
	_wall(P, "L1_W2_a", 1.45, 1.55, 2.65, 6.3, Y, pw)
	_wall(P, "L1_W2_b", 1.45, 1.55, 7.2, 8.6, Y, pw)
	# W3: v 5.6, radio room | wash room
	_wall(P, "L1_W3", -0.2, 1.5, 5.55, 5.65, Y, pw)
	# doorway lintels
	var lint_top := (ceil_rel(2.6) - 0.03) if not authored else pw      # to the ceiling
	K.box(P, "L1_Lintel_Bed", -2.1, -1.0, 2.55, 2.65, Y + 2.0, Y + lint_top, "plaster", false)
	K.box(P, "L1_Lintel_Radio", -0.1, 1.0, 2.55, 2.65, Y + 2.0, Y + lint_top, "plaster", false)
	K.box(P, "L1_Lintel_Mess", 3.3, 4.5, 2.55, 2.65, Y + 2.0, Y + lint_top, "plaster", false)
	if not authored:      # the wash room doorway (W2 gap, v 6.3 to 7.2) closed above its frame
		K.box(P, "L1_Lintel_Wash", 1.45, 1.55, 6.3, 7.2, Y + 2.1, Y + ceil_rel(7.2) - 0.03, "plaster", false)
	var hw := _house_windows()
	if authored:
		# the shell is the roof, the walls and the window openings: only the timbers, the glass panes and the trim are built here
		_roof_timbers(P, Y)
		_house_window_panes(P, hw)
	else:
		_ceiling(P, Y)
		# plaster lining over the exterior model's dirty inside faces on the west and back walls
		K.box(P, "L1_LiningFront", -3.0, 5.4, 0.88, 0.95, Y, Y + 1.5, "plaster", true)
		_lined_wall(P, "L1_LiningWest", "west", 0.95, 8.7, -3.06, -3.0, Y, Y + 2.7, hw)
		_lined_wall(P, "L1_LiningBack", "back", -3.06, 5.4, 8.7, 8.76, Y, Y + 1.85, hw)
		_house_window_frames(P, hw)
	# collar beams across under the lined roof
	var cu0 := -3.0 if not authored else -2.2
	var cu1 := 5.4 if not authored else 4.58
	for i in 4:
		K.box(P, "L1_Collar_%d" % i, cu0, cu1, 3.0 + 1.4 * i, 3.15 + 1.4 * i, Y + 2.15, Y + 2.3, "wood_dark", false)
	var sv1 := 8.95 if not authored else 8.68
	for i in 4:
		K.box(P, "L1_Skirt_%d" % i, -3.0 + 2.2 * i, -2.9 + 2.2 * i, 0.95, sv1, Y, Y + 0.12, "wood_dark", false)

	# --- hall (v 1.0..2.6): from the tower door west; low eaves on the front, so shelving only
	K.box(P, "L1_Runner", -2.6, 5.0, 1.55, 2.2, Y, Y + 0.02, "rug", false)
	K.box(P, "L1_HallShelf", -2.2, 0.6, 1.0, 1.4, Y, Y + 1.4, "wood_dark", true)
	for i in 3:
		K.box(P, "L1_HallShelfBoard_%d" % i, -2.2, 0.6, 0.98, 1.42, Y + 0.45 + 0.4 * i, Y + 0.48 + 0.4 * i, "wood", false)
	for i in 9:
		var bu := -2.1 + 0.3 * i
		K.box(P, "L1_Linen_%d" % i, bu, bu + 0.24, 1.0, 1.35, Y + 0.48 + 0.4 * (i % 3), Y + 0.74 + 0.4 * (i % 3), "canvas" if i % 2 == 0 else "paper", false)
	if authored:      # inside the shell's doorway opening (v 1.0 to 2.3, 2.1 high), not in its jambs
		var dv: Array = shell_spec()["l1_door_v"]
		K.box(P, "L1_TowerDoorFrame_a", 5.3, 5.55, dv[0], dv[0] + 0.1, Y, Y + 2.0, "wood_dark", false)
		K.box(P, "L1_TowerDoorFrame_b", 5.3, 5.55, dv[1] - 0.1, dv[1], Y, Y + 2.0, "wood_dark", false)
		K.box(P, "L1_TowerDoorFrame_c", 5.3, 5.55, dv[0], dv[1], Y + 2.0, Y + 2.1, "wood_dark", false)
	else:
		K.box(P, "L1_TowerDoorFrame_a", 5.38, 5.6, 0.95, 1.12, Y, Y + 2.0, "wood_dark", false)
		K.box(P, "L1_TowerDoorFrame_b", 5.38, 5.6, 2.08, 2.25, Y, Y + 2.0, "wood_dark", false)
		K.box(P, "L1_TowerDoorFrame_c", 5.38, 5.6, 0.95, 2.25, Y + 2.0, Y + 2.12, "wood_dark", false)
	_lamp(P, "L1_HallLamp", Vector3(4.4, Y + 1.7, 1.5), 1.6)
	_lamp(P, "L1_HallLamp2", Vector3(1.6, Y + 1.75, 1.9), 1.7)
	_lamp(P, "L1_HallLamp3", Vector3(-1.6, Y + 1.75, 1.9), 1.7)

	# --- sleeping quarters (u -3.0..-0.2, v 2.65..9.0)
	for i in 2:
		var v0 := 3.3 + 2.8 * i
		K.box(P, "L1_BedFrame_%d" % i, -2.95, -1.95, v0, v0 + 2.05, Y + 0.25, Y + 0.45, "wood_dark", true)
		K.box(P, "L1_BedMattress_%d" % i, -2.9, -2.0, v0 + 0.05, v0 + 2.0, Y + 0.45, Y + 0.62, "canvas", true)
		K.box(P, "L1_BedBlanket_%d" % i, -2.9, -2.0, v0 + 0.7, v0 + 2.0, Y + 0.62, Y + 0.7, "cloth_green" if i == 0 else "rug", false)
		K.box(P, "L1_BedPillow_%d" % i, -2.85, -2.05, v0 + 0.1, v0 + 0.55, Y + 0.62, Y + 0.76, "paper", false)
		for k in 4:
			var lu := -2.95 if k % 2 == 0 else -2.05
			var lv := v0 if k < 2 else v0 + 1.97
			K.box(P, "L1_BedLeg_%d_%d" % [i, k], lu, lu + 0.08, lv, lv + 0.08, Y, Y + 0.25, "wood_dark", false)
	K.box(P, "L1_Nightstand", -2.9, -2.4, 5.45, 5.95, Y, Y + 0.55, "wood", true)
	K.pole(P, "L1_NightLampBase", -2.65, 5.7, Y + 0.55, Y + 0.6, 0.08, "brass", false)
	K.pole(P, "L1_NightLampGlass", -2.65, 5.7, Y + 0.6, Y + 0.78, 0.05, "glow_warm", false)
	_lamp(P, "L1_QuartersLamp", Vector3(-1.5, Y + 2.1, 5.2), 1.1)
	K.light(P, "L1_BedLight", Vector3(-2.5, Y + 1.0, 5.7), Color(1.0, 0.72, 0.42), 1.0, 4.2, 0.12)
	K.box(P, "L1_SeaChest", -1.7, -0.7, 8.0, 8.65, Y, Y + 0.5, "wood_dark", true)
	K.box(P, "L1_SeaChestBand_a", -1.55, -1.5, 7.98, 8.67, Y, Y + 0.52, "iron_dark", false)
	K.box(P, "L1_SeaChestBand_b", -0.9, -0.85, 7.98, 8.67, Y, Y + 0.52, "iron_dark", false)
	K.box(P, "L1_Wardrobe", -0.95, -0.3, 6.3, 7.6, Y, Y + 1.95, "wood_dark", true)
	K.box(P, "L1_WardrobeDoorGap", -0.32, -0.3, 6.93, 6.97, Y + 0.1, Y + 1.85, "black", false)
	K.box(P, "L1_BedRug", -2.0, -0.7, 4.0, 6.6, Y, Y + 0.02, "rug", false)
	K.sheet(P, "L1_Photo", Vector3(-2.97, Y + 1.45, 4.3), Vector3(1, 0, 0), 0.22, 0.3, "paper_old", "T.", 28, Color(0.14, 0.1, 0.07))

	# --- radio and chart room (u -0.2..1.5, v 2.65..5.6)
	K.box(P, "L1_RadioDesk", 0.95, 1.45, 3.0, 4.7, Y, Y + 0.78, "wood", true)
	K.box(P, "L1_RadioSet", 1.05, 1.4, 3.3, 4.3, Y + 0.78, Y + 1.15, "iron_dark", false)
	for i in 3:
		K.disc(P, "L1_RadioDial_%d" % i, Vector3(1.03, Y + 0.97, 3.5 + 0.3 * i), Vector3(-1, 0, 0), 0.07, 0.03, "brass")
	K.rod(P, "L1_RadioKey", Vector3(1.1, Y + 0.8, 4.45), Vector3(1.28, Y + 0.84, 4.45), 0.015, "brass")
	K.box(P, "L1_RadioChair", 0.35, 0.8, 3.5, 3.95, Y + 0.38, Y + 0.43, "wood", true)
	for k in 4:
		var cu := 0.35 if k % 2 == 0 else 0.76
		var cv := 3.5 if k < 2 else 3.91
		K.box(P, "L1_RadioChairLeg_%d" % k, cu, cu + 0.05, cv, cv + 0.05, Y, Y + 0.38, "wood_dark", false)
	K.sheet(P, "L1_RadioLog", Vector3(1.43, Y + 1.5, 3.8), Vector3(-1, 0, 0), 0.45, 0.35, "paper_old", "NO SIGNAL\nSTORM LOG", 26, Color(0.14, 0.1, 0.07))
	K.light(P, "L1_RadioGlow", Vector3(0.9, Y + 1.2, 3.9), Color(0.7, 0.85, 0.6), 0.5, 3.2, 0.2)
	K.box(P, "L1_ChartTable", -0.1, 0.5, 4.3, 5.4, Y, Y + 0.85, "wood_dark", true)
	K.sheet(P, "L1_Chart", Vector3(0.2, Y + 0.857, 4.85), Vector3(0, 1, 0), 0.5, 0.9, "paper_old", "GULLWATER", 30, Color(0.14, 0.1, 0.07))

	# --- wash room (u -0.2..1.5, v 5.65..9.0)
	_lamp(P, "L1_WashLamp", Vector3(0.6, Y + 1.9, 7.2), 1.0)
	K.box(P, "L1_Tub", 0.05, 1.4, 7.6, 8.9, Y, Y + 0.55, "iron", true)
	K.box(P, "L1_TubInside", 0.15, 1.3, 7.7, 8.8, Y + 0.5, Y + 0.56, "gauge_face", false)
	K.rod(P, "L1_TubTap", Vector3(0.75, Y + 0.85, 8.88), Vector3(0.75, Y + 0.65, 8.7), 0.025, "brass")
	K.box(P, "L1_Basin", 0.2, 0.9, 6.0, 6.5, Y, Y + 0.85, "wood_dark", true)
	K.box(P, "L1_BasinBowl", 0.3, 0.8, 6.05, 6.45, Y + 0.85, Y + 0.9, "gauge_face", false)
	K.rod(P, "L1_BasinTap", Vector3(0.55, Y + 0.95, 6.4), Vector3(0.55, Y + 1.08, 6.4), 0.02, "brass")
	K.sheet(P, "L1_Mirror", Vector3(0.55, Y + 1.5, 5.67), Vector3(0, 0, 1), 0.4, 0.55, K.colour(Color(0.5, 0.58, 0.62), 0.1, 0.9))
	K.rod(P, "L1_TowelRail", Vector3(1.4, Y + 1.2, 6.2), Vector3(1.4, Y + 1.2, 7.0), 0.015, "brass")
	K.box(P, "L1_Towel", 1.38, 1.44, 6.35, 6.85, Y + 0.7, Y + 1.2, "canvas", false)

	# --- mess and kitchen (u 1.5..5.4, v 2.65..9.0)
	K.box(P, "L1_MessTable", 2.5, 3.9, 5.0, 6.3, Y + 0.74, Y + 0.8, "wood", true)
	for k in 4:
		var tu := 2.55 if k % 2 == 0 else 3.8
		var tv := 5.05 if k < 2 else 6.2
		K.box(P, "L1_MessTableLeg_%d" % k, tu, tu + 0.08, tv, tv + 0.08, Y, Y + 0.74, "wood_dark", false)
	K.box(P, "L1_MessBenchA", 2.5, 3.9, 4.45, 4.8, Y + 0.4, Y + 0.45, "wood", true)
	K.box(P, "L1_MessBenchB", 2.5, 3.9, 6.5, 6.85, Y + 0.4, Y + 0.45, "wood", true)
	for k in 4:
		K.pole(P, "L1_MugS_%d" % k, 2.8 + 0.3 * k, 5.65, Y + 0.8, Y + 0.88, 0.04, "iron", false)
	K.box(P, "L1_Stove", 4.55, 5.35, 6.0, 6.9, Y, Y + 0.95, "iron_dark", true)
	K.box(P, "L1_StoveTop", 4.5, 5.4, 5.95, 6.95, Y + 0.95, Y + 1.0, "iron", false)
	K.box(P, "L1_StoveGlow", 4.53, 4.56, 6.3, 6.6, Y + 0.35, Y + 0.55, K.colour(Color(0.72, 0.36, 0.08), 0.6, 0.0, 1.6), false)
	K.pole(P, "L1_StovePipe", 5.1, 6.45, Y + 1.0, (Y + 3.7) if not authored else roof_under(6.45) - 0.03, 0.09, "iron_dark", false)
	K.light(P, "L1_StoveLight", Vector3(4.3, Y + 0.5, 6.45), Color(1.0, 0.5, 0.2), 0.9, 3.6, 0.3)
	K.box(P, "L1_Counter", 1.6, 2.3, 7.3, 8.9, Y, Y + 0.9, "wood_dark", true)
	K.box(P, "L1_CounterTop", 1.58, 2.34, 7.28, 8.92, Y + 0.9, Y + 0.95, "wood", false)
	K.box(P, "L1_Sink", 1.7, 2.2, 7.6, 8.2, Y + 0.88, Y + 0.96, "iron", false)
	K.rod(P, "L1_SinkTap", Vector3(1.75, Y + 1.0, 7.9), Vector3(1.75, Y + 1.2, 7.9), 0.02, "brass")
	for i in 2:
		K.box(P, "L1_KitchenShelf_%d" % i, 1.55, 1.85, 3.3, 5.0, Y + 1.25 + 0.4 * i, Y + 1.28 + 0.4 * i, "wood", false)
	for i in 6:
		K.pole(P, "L1_Pot_%d" % i, 1.7, 3.4 + 0.28 * i, Y + 1.28, Y + 1.43, 0.06, "iron" if i % 2 == 0 else "copper", false)
	_lamp(P, "L1_MessLamp", Vector3(3.2, Y + 2.0, 5.65), 1.4)
	K.rod(P, "L1_MessLampCord", Vector3(3.2, Y + 2.0, 5.65), Vector3(3.2, Y + 2.4, 5.65), 0.008, "iron_dark")

	# --- the second pass: door frames, wall dressing, rugs, the east wall lining
	_doorframe(P, "L1_DoorBed", -2.1, -1.0, 2.6, Y, 2.0)
	_doorframe(P, "L1_DoorRadio", -0.1, 1.0, 2.6, Y, 2.0)
	_doorframe(P, "L1_DoorMess", 3.3, 4.5, 2.6, Y, 2.0)
	_doorframe(P, "L1_DoorWash", 6.3, 7.2, 1.5, Y, 2.0, true)
	# the east wall's plaster starts at v 3.3: nearer the doorway the tower's curved lining stands only 0.1 m behind this plane, and the sheet's
	# edge poked through it as a tall cream flap beside the frame (creator, 2026-10-25). The 1.1 m between the doorway and v 3.3 is the doorway's
	# own reveal, below.
	if not authored:
		K.box(P, "L1_LiningEast", 5.39, 5.45, 3.3, 8.6, Y, Y + 2.3, "plaster", true)
		for rv in [[0.84, 0.95], [2.25, 2.36]]:      # the doorway's two reveals, flush with the jambs, running out to the lining's chord
			K.box(P, "L1_DoorReveal_%d" % int(rv[0] * 100), 5.38, 5.95, rv[0], rv[1], Y, Y + 2.14, "plaster", false)
		K.box(P, "L1_DoorRevealHead", 5.38, 5.95, 0.84, 2.36, Y + 2.12, Y + 2.24, "plaster", false)
	K.box(P, "L1_RugMess", 2.2, 4.2, 4.4, 6.9, Y, Y + 0.015, "rug", false)
	K.box(P, "L1_RugRadio", -0.1, 0.9, 3.0, 4.2, Y, Y + 0.015, "rug", false)
	K.sheet(P, "L1_Rules", Vector3(2.0, Y + 1.5, 2.5), Vector3(0, 0, -1), 0.5, 0.65, "paper_old", "KEEPER'S RULES

1. THE LAMP
   NEVER GOES DARK.
2. LOG THE HOUR.
3. KEEP THE
   BOILER FED.", 24, Color(0.12, 0.09, 0.07))
	K.sheet(P, "L1_Calendar", Vector3(1.44, Y + 1.5, 6.0), Vector3(1, 0, 0), 0.32, 0.42, "paper", "OCT
the moon
full
the 22nd", 26, Color(0.1, 0.1, 0.14))
	K.sheet(P, "L1_Barometer_Note", Vector3(-0.55, Y + 1.55, 2.64), Vector3(0, 0, 1), 0.36, 0.28, "paper_old", "GLASS FALLING", 26, Color(0.12, 0.09, 0.07))
	K.disc(P, "L1_MessClock", Vector3(5.38, Y + 1.7, 4.2), Vector3(-1, 0, 0), 0.17, 0.04, "brass")
	K.disc(P, "L1_MessClockFace", Vector3(5.36, Y + 1.7, 4.2), Vector3(-1, 0, 0), 0.14, 0.03, "gauge_face")
	for hk in 4:
		K.pole(P, "L1_Hook_%d" % hk, -2.15 + 0.3 * hk, 0.92, Y + 1.15, Y + 1.2, 0.02, "iron_dark", false)
	K.box(P, "L1_Coat_Ted", -1.1, -0.85, 0.9, 0.98, Y + 0.3, Y + 1.15, "navy", false)
	K.box(P, "L1_Shelf_Bed", -2.99, -2.7, 7.0, 8.0, Y + 1.2, Y + 1.23, "wood", false)
	for bk in 5:
		K.box(P, "L1_Book_%d" % bk, -2.97, -2.76, 7.05 + 0.18 * bk, 7.17 + 0.18 * bk, Y + 1.23, Y + 1.5, ["leather", "cloth_green", "navy", "paper_navy", "leather"][bk], false)
	# anchors for other agents
	anchors["l1_landing"] = Vector3(5.0, Y, 1.6)
	anchors["l1_hall"] = Vector3(2.0, Y, 2.0)
	anchors["l1_quarters"] = Vector3(-1.6, Y, 4.6)
	anchors["l1_radio"] = Vector3(0.35, Y, 3.1)
	anchors["l1_mess"] = Vector3(3.2, Y, 3.6)


func _house_windows() -> Array:
	var out := []
	var f := FileAccess.open("res://data/world/lighthouse_windows.json", FileAccess.READ)
	if f:
		for w in (JSON.parse_string(f.get_as_text()) as Dictionary).get("windows", []):
			if w["kind"] == "house":
				out.append(w)
	return out


## A lined wall of the house with gaps for the windows on it. `wall` "west": runs along v (a0..a1) at u in [f0, f1];
## "back": runs along u at v in [f0, f1]. Below the sill and above the head the wall stays.
func _lined_wall(P: Node3D, nm: String, wall: String, a0: float, a1: float, f0: float, f1: float, y0: float, y1: float, wins: Array) -> void:
	var cuts := []
	for w in wins:
		if w["wall"] == wall:
			cuts.append(w)
	cuts.sort_custom(func(p, q): return p["at"] < q["at"])
	var cur := a0
	var i := 0
	for w in cuts:
		var lo: float = w["at"] - w["w"] * 0.5
		var hi: float = w["at"] + w["w"] * 0.5
		_lw_box(P, "%s_%d" % [nm, i], wall, cur, lo, f0, f1, y0, y1)
		var sill: float = w["y"] - w["h"] * 0.5
		var head: float = w["y"] + w["h"] * 0.5
		_lw_box(P, "%s_%d_Sill" % [nm, i], wall, lo, hi, f0, f1, y0, sill)
		if head < y1:
			_lw_box(P, "%s_%d_Head" % [nm, i], wall, lo, hi, f0, f1, head, y1)
		cur = hi
		i += 1
	_lw_box(P, "%s_%d" % [nm, i], wall, cur, a1, f0, f1, y0, y1)


func _lw_box(P: Node3D, nm: String, wall: String, a0: float, a1: float, f0: float, f1: float, y0: float, y1: float) -> void:
	if a1 - a0 < 0.01 or y1 - y0 < 0.01:
		return
	if wall == "west":
		K.box(P, nm, f0, f1, a0, a1, y0, y1, "plaster", true)
	else:
		K.box(P, nm, a0, a1, f0, f1, y0, y1, "plaster", true)


## Deep reveals (the wall's thickness), a glass pane and an invisible barrier for each house window.
func _house_window_frames(P: Node3D, wins: Array) -> void:
	for w in wins:
		var at: float = w["at"]
		var ww: float = w["w"]
		var hh: float = w["h"]
		var y: float = w["y"]
		var s := y - hh * 0.5
		var h := y + hh * 0.5
		var id: String = w["id"]
		var west: bool = w["wall"] == "west"
		var f0 := -3.06 if west else 8.7           # the lining plane
		var d := 1.05                              # the wall's thickness here (measured: the exterior's real outer face, test_openings)
		var f1 := f0 - d if west else f0 + d
		var lo := minf(f0, f1)
		var hi := maxf(f0, f1)
		var jl := at - ww * 0.5
		var jh := at + ww * 0.5
		if west:
			K.box(P, id + "_Sill", lo, hi, jl - 0.1, jh + 0.1, s - 0.1, s, "stone", false)
			K.box(P, id + "_Head", lo, hi, jl - 0.1, jh + 0.1, h, h + 0.1, "stone", false)
			K.box(P, id + "_JambL", lo, hi, jl - 0.1, jl, s, h, "stone", false)
			K.box(P, id + "_JambR", lo, hi, jh, jh + 0.1, s, h, "stone", false)
			K.box(P, id + "_Glass", f1 + 0.04, f1 + 0.06, jl, jh, s, h, "glass", false)
			K.box(P, id + "_Mullion", f1 + 0.03, f1 + 0.07, at - 0.02, at + 0.02, s, h, "iron_dark", false)
			var b = K.box(P, id + "_Barrier", f0 + 0.04, f0 + 0.12, jl - 0.05, jh + 0.05, s - 0.1, h, "glass", true)
			b.visible = false
			(b.get_node("Body") as StaticBody3D).add_to_group("glass")
		else:
			K.box(P, id + "_Sill", jl - 0.1, jh + 0.1, lo, hi, s - 0.1, s, "stone", false)
			K.box(P, id + "_Head", jl - 0.1, jh + 0.1, lo, hi, h, h + 0.1, "stone", false)
			K.box(P, id + "_JambL", jl - 0.1, jl, lo, hi, s, h, "stone", false)
			K.box(P, id + "_JambR", jh, jh + 0.1, lo, hi, s, h, "stone", false)
			K.box(P, id + "_Glass", jl, jh, f1 - 0.06, f1 - 0.04, s, h, "glass", false)
			K.box(P, id + "_Mullion", at - 0.02, at + 0.02, f1 - 0.07, f1 - 0.03, s, h, "iron_dark", false)
			var b2 = K.box(P, id + "_Barrier", jl - 0.05, jh + 0.05, f0 - 0.12, f0 - 0.04, s - 0.1, h, "glass", true)
			b2.visible = false
			(b2.get_node("Body") as StaticBody3D).add_to_group("glass")


## The authored roof's underside height at house-frame v (data/world/shell_spec.json: eave at both long walls, ridge along u at the middle of v).
func roof_under(v: float) -> float:
	var sp := shell_spec()
	var v0: float = sp["first_v"][0]
	var v1: float = sp["first_v"][1]
	var vm := (v0 + v1) * 0.5
	var e: float = sp["l1_eave"]
	var r: float = sp["l1_ridge"]
	return e + (r - e) * (v - v0) / (vm - v0) if v <= vm else e + (r - e) * (v1 - v) / (v1 - vm)


## Ridge beam and rafters under the authored roof's own underside (the shell has no timbers).
func _roof_timbers(P: Node3D, Y: float) -> void:
	var sp := shell_spec()
	var u0: float = sp["first_u"][0]
	var u1: float = sp["first_u"][1]
	var v0: float = sp["first_v"][0]
	var v1: float = sp["first_v"][1]
	var vm := (v0 + v1) * 0.5
	K.box(P, "L1_RidgeBeam", u0 + 0.02, u1 - 0.02, vm - 0.08, vm + 0.08, roof_under(vm) - 0.2, roof_under(vm) - 0.04, "wood_dark", false)
	for i in 5:
		var u := u0 + 0.4 + 2.1 * i
		if u > u1 - 0.1:
			continue
		_rafter(P, "L1_Rafter_F%d" % i, u, Vector2(v0 + 0.05, roof_under(v0 + 0.05) + 0.0), Vector2(vm - 0.05, roof_under(vm - 0.05)))
		_rafter(P, "L1_Rafter_B%d" % i, u, Vector2(vm + 0.05, roof_under(vm + 0.05)), Vector2(v1 - 0.05, roof_under(v1 - 0.05)))


## Glass, mullion and the invisible barrier for each first-floor window: the shell's wall is cut through, the pane stands mid-wall.
func _house_window_panes(P: Node3D, wins: Array) -> void:
	var sp := shell_spec()
	var t: float = sp["house_wall_t"]
	for w in wins:
		var at: float = w["at"]
		var ww: float = w["w"]
		var s := float(w["y"]) - float(w["h"]) * 0.5
		var h := float(w["y"]) + float(w["h"]) * 0.5
		var id: String = w["id"]
		var jl := at - ww * 0.5
		var jh := at + ww * 0.5
		if w["wall"] == "west":
			var f0: float = sp["first_u"][0]
			var g := f0 - t * 0.5
			K.box(P, id + "_Glass", g - 0.01, g + 0.01, jl, jh, s, h, "glass", false)
			K.box(P, id + "_Mullion", g - 0.02, g + 0.02, at - 0.02, at + 0.02, s, h, "iron_dark", false)
			var b = K.box(P, id + "_Barrier", f0 - 0.12, f0 - 0.04, jl, jh, s - 0.1, h, "glass", true)
			b.visible = false
			(b.get_node("Body") as StaticBody3D).add_to_group("glass")
		else:
			var f1: float = sp["first_v"][1]
			var g2 := f1 + t * 0.5
			K.box(P, id + "_Glass", jl, jh, g2 - 0.01, g2 + 0.01, s, h, "glass", false)
			K.box(P, id + "_Mullion", at - 0.02, at + 0.02, g2 - 0.02, g2 + 0.02, s, h, "iron_dark", false)
			var b2 = K.box(P, id + "_Barrier", jl, jh, f1 + 0.04, f1 + 0.12, s - 0.1, h, "glass", true)
			b2.visible = false
			(b2.get_node("Body") as StaticBody3D).add_to_group("glass")


## A plaster ceiling following the roof (measured: roof headroom above the floor is 1.9 m at v 1, 4.5 m at the ridge v 5,
## 2 m at v 8.5), 0.45 m under it, so the exterior model's lumpy roof underside does not show. Two tilted slabs.
func _ceiling(P: Node3D, Y: float) -> void:
	var u0 := -3.0
	var u1 := 5.45
	var th := 0.12
	_tilt_slab(P, "L1_CeilingFront", u0, u1, Vector2(0.9, Y + 1.45), Vector2(5.0, Y + 4.0), th)
	_tilt_slab(P, "L1_CeilingBack", u0, u1, Vector2(5.0, Y + 4.0), Vector2(8.9, Y + 1.6), th)
	K.box(P, "L1_RidgeBeam", u0 + 0.05, u1 - 0.45, 4.92, 5.08, Y + 3.88, Y + 4.02, "wood_dark", false)      # stops 0.45 m short of the east wall: it ran on into the tower as a plank through the L2 window (creator, 2026-10-26)
	for i in 5:
		var v := 1.6 + 0.0
		var u := u0 + 0.4 + 2.1 * i
		if u > u1 - 0.1:
			continue          # the fifth pair stood at u 5.8, past the east wall, and its slope ran through the tower doorway (creator, 2026-10-25)
		_rafter(P, "L1_Rafter_F%d" % i, u, Vector2(0.9, Y + 1.45), Vector2(5.0, Y + 4.0))
		_rafter(P, "L1_Rafter_B%d" % i, u, Vector2(5.0, Y + 4.0), Vector2(8.9, Y + 1.6))


## A slab between two (v, y) points, spanning u0..u1, tilted about the u axis (house frame).
func _tilt_slab(P: Node3D, nm: String, u0: float, u1: float, a: Vector2, b: Vector2, th: float) -> void:
	var dv := b.x - a.x
	var dy := b.y - a.y
	var ln := sqrt(dv * dv + dy * dy)
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = Vector3(u1 - u0, th, ln)
	mi.mesh = bm
	mi.material_override = K.mats["plaster"]
	var x := Vector3(1, 0, 0)
	var y := Vector3(0, dv, dy) / ln
	var z := Vector3(0, -dy, dv) / ln
	mi.transform = Transform3D(Basis(x, y, z), K.p((u0 + u1) * 0.5, (a.y + b.y) * 0.5 - th * 0.5, (a.x + b.x) * 0.5))
	P.add_child(mi)
	K.count += 1


func _rafter(P: Node3D, nm: String, u: float, a: Vector2, b: Vector2) -> void:
	K.rod(P, nm, Vector3(u, a.y - 0.14, a.x), Vector3(u, b.y - 0.14, b.x), 0.07, "wood_dark")


## A timber door frame across a partition gap: two jambs and a head. `side` true: the gap runs along v at u = `at` (the wash
## room's door in the W2 wall), otherwise along u at v = `at`.
func _doorframe(P: Node3D, nm: String, a0: float, a1: float, at: float, y: float, h: float, side := false) -> void:
	var t := 0.07
	if side:
		K.box(P, nm + "_J0", at - 0.1, at + 0.1, a0 - t, a0, y, y + h, "wood_dark", false)
		K.box(P, nm + "_J1", at - 0.1, at + 0.1, a1, a1 + t, y, y + h, "wood_dark", false)
		K.box(P, nm + "_H", at - 0.1, at + 0.1, a0 - t, a1 + t, y + h, y + h + 0.08, "wood_dark", false)
	else:
		K.box(P, nm + "_J0", a0 - t, a0, at - 0.1, at + 0.1, y, y + h, "wood_dark", false)
		K.box(P, nm + "_J1", a1, a1 + t, at - 0.1, at + 0.1, y, y + h, "wood_dark", false)
		K.box(P, nm + "_H", a0 - t, a1 + t, at - 0.1, at + 0.1, y + h, y + h + 0.08, "wood_dark", false)


## A partition under the authored roof: its top follows the underside (a flat top would poke through the roof near the eaves).
func _sloped_wall(P: Node3D, nm: String, u0: float, u1: float, v0: float, v1: float, y0: float, h: float) -> void:
	var sp := shell_spec()
	var va: float = sp["first_v"][0]
	var vb: float = sp["first_v"][1]
	var vm := (va + vb) * 0.5
	var top := y0 + h
	var e: float = sp["l1_eave"]
	var r: float = sp["l1_ridge"]
	# where the roof underside (minus a hand's breadth) reaches the partition's full height, on each slope
	var vf := va + (top + 0.02 - e) * (vm - va) / (r - e)
	var vbk := vb - (top + 0.02 - e) * (vb - vm) / (r - e)
	var pts: Array = [Vector2(v0, y0), Vector2(v1, y0), Vector2(v1, minf(top, roof_under(v1) - 0.02))]
	if vbk < v1 and vbk > v0:
		pts.append(Vector2(vbk, top))
	if vf > v0 and vf < v1:
		pts.append(Vector2(vf, top))
	pts.append(Vector2(v0, minf(top, roof_under(v0) - 0.02)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	for side in [[u0, 1.0], [u1, -1.0]]:
		for i in range(1, n - 1):
			var tri := [pts[0], pts[i], pts[i + 1]]
			if side[1] < 0.0:
				tri = [pts[0], pts[i + 1], pts[i]]
			for q in tri:
				st.set_normal(Vector3(-side[1], 0, 0))
				st.add_vertex(K.p(side[0], q.y, q.x))
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var pa0: Vector3 = K.p(u0, a.y, a.x)
		var pa1: Vector3 = K.p(u1, a.y, a.x)
		var pb0: Vector3 = K.p(u0, b.y, b.x)
		var pb1: Vector3 = K.p(u1, b.y, b.x)
		var nn: Vector3 = (pb0 - pa0).cross(pa1 - pa0).normalized()
		for q in [pa0, pb0, pa1, pa1, pb0, pb1]:
			st.set_normal(nn)
			st.add_vertex(q)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = st.commit()
	var mat: Material = K.mats["plaster"]
	var m2 := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
	m2.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m2
	P.add_child(mi)
	mi.create_trimesh_collision()
	K.count += 1


## First-floor ceiling height above the floor at house-frame v, as the old ceiling slabs (_ceiling) build it: a front slope from v 0.9 (1.45 m) to the ridge at v 5.0
## (4.0 m), a back slope down to v 8.9 (1.6 m).
static func ceil_rel(v: float) -> float:
	return 1.45 + (v - 0.9) * (4.0 - 1.45) / (5.0 - 0.9) if v <= 5.0 else 4.0 - (v - 5.0) * (4.0 - 1.6) / (8.9 - 5.0)


## A partition that runs right up to the ceiling (creator, 2026-10-26: "walls not meeting the ceiling"): a plaster panel u0..u1 whose top follows `ceil_rel` along v,
## 3 cm under it. A partition along u (v0..v1 thin) is flat at the ceiling's height at its v.
func _wall_to_ceiling(P: Node3D, nm: String, u0: float, u1: float, v0: float, v1: float, y0: float) -> void:
	var top_at := func(v: float) -> float:
		return y0 + ceil_rel(clampf(v, 0.9, 8.9)) - 0.03
	if (v1 - v0) <= (u1 - u0):
		var vm := (v0 + v1) * 0.5
		K.box(P, nm, u0, u1, v0, v1, y0, top_at.call(vm), "plaster", true)
		return
	var pts: Array = [Vector2(v0, y0), Vector2(v1, y0)]
	var vs: Array = []
	var v := v1
	while v > v0 + 0.01:
		vs.append(v)
		v -= 0.4
	vs.append(v0)
	if v0 < 5.0 and v1 > 5.0:
		vs.append(5.0)
		vs.sort()
		vs.reverse()
	for q in vs:
		pts.append(Vector2(q, top_at.call(q)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	for side in [[u0, 1.0], [u1, -1.0]]:
		for i in range(1, n - 1):
			var tri := [pts[0], pts[i], pts[i + 1]]
			if side[1] < 0.0:
				tri = [pts[0], pts[i + 1], pts[i]]
			for q in tri:
				st.set_normal(Vector3(-side[1], 0, 0))
				st.add_vertex(K.p(side[0], q.y, q.x))
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var pa0: Vector3 = K.p(u0, a.y, a.x)
		var pa1: Vector3 = K.p(u1, a.y, a.x)
		var pb0: Vector3 = K.p(u0, b.y, b.x)
		var pb1: Vector3 = K.p(u1, b.y, b.x)
		var nn: Vector3 = (pb0 - pa0).cross(pa1 - pa0).normalized()
		for q in [pa0, pb0, pa1, pa1, pb0, pb1]:
			st.set_normal(nn)
			st.add_vertex(q)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = st.commit()
	var m2 := (K.mats["plaster"] as StandardMaterial3D).duplicate() as StandardMaterial3D
	m2.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m2
	P.add_child(mi)
	mi.create_trimesh_collision()
	K.count += 1


func _wall(P: Node3D, nm: String, u0: float, u1: float, v0: float, v1: float, y0: float, h: float) -> void:
	if authored and (v1 - v0) > (u1 - u0) and v1 > 7.0:
		_sloped_wall(P, nm, u0, u1, v0, v1, y0, h)      # a partition running up to the back eaves
	elif not authored and absf(y0 - L1) < 0.01:
		_wall_to_ceiling(P, nm, u0, u1, v0, v1, y0)      # first-floor partitions reach the ceiling
	else:
		K.box(P, nm, u0, u1, v0, v1, y0, y0 + h, "plaster", true)
	# the wainscot panel stands PAD proud of both faces of the wall, on the thin axis. It used to be padded only for walls running along u: a wall
	# running along v got a panel with exactly its own footprint, so their faces were coplanar and z-fought (the panelling "flickering in and out
	# of view", creator 2026-10-25), and the 1 cm padding that existed was inside the depth precision at a few metres.
	var pad := 0.03
	if u1 - u0 > v1 - v0:
		K.box(P, nm + "_Panel", u0, u1, v0 - pad, v1 + pad, y0, y0 + 0.9, "wood_dark", false)
	else:
		K.box(P, nm + "_Panel", u0 - pad, u1 + pad, v0, v1, y0, y0 + 0.9, "wood_dark", false)


func _lamp(P: Node3D, nm: String, at: Vector3, energy: float) -> void:
	K.sphere(P, nm + "_Glass", at, 0.1, "glow_warm", 1.3)
	K.rod(P, nm + "_Cap", at + Vector3(0, 0.1, 0), at + Vector3(0, 0.18, 0), 0.03, "brass")
	K.light(P, nm + "_Light", at + Vector3(0, -0.1, 0), Color(1.0, 0.75, 0.45), energy, 4.6, 0.1)


# ======================================================================== the authored shell's house wall (data/world/shell_spec.json)

static func shell_spec() -> Dictionary:
	if _spec.is_empty():
		var f := FileAccess.open("res://data/world/shell_spec.json", FileAccess.READ)
		_spec = JSON.parse_string(f.get_as_text())
	return _spec


## The authored tower's inner radius at height y: a plinth of 3.0 to 4.92, then a cone from 3.4 narrowing to 2.9 (build_shell_v1.py r_in).
static func analytic_inner(y: float) -> float:
	return 3.0 if y < 4.92 else maxf(2.9, 3.4 - 0.0385 * (y - 4.92))


## The first radius (from 1 m out) along `bearing` at height `y` where the tower's air runs into a wall of the house, or 99 if it never does. The shell cuts the
## tower's air by the house's walls (their outer faces, thickness house_wall_t) up to tower_cut_top, so a ring or fill must stop there.
func house_bite(y: float, bearing_deg: float) -> float:
	var sp := shell_spec()
	if y >= float(sp["tower_cut_top"]):
		return 99.0
	var t: float = sp["house_wall_t"]
	var o: Array = sp["house_origin"]
	var ax: Array = sp["tower_axis"]
	var yaw: float = sp["house_yaw"]
	var gu: Array = sp["ground_u"]
	var gv: Array = sp["ground_v"]
	var fu: Array = sp["first_u"]
	var fv: Array = sp["first_v"]
	var upper: bool = y >= float(sp["slab_top"])
	var u0: float = (fu[0] if upper else gu[0]) - t
	var u1: float = (fu[1] if upper else gu[1]) + t
	var v0: float = (fv[0] if upper else gv[0]) - t
	var v1: float = (fv[1] if upper else gv[1]) + t
	var a := deg_to_rad(bearing_deg)
	var r := 1.0
	while r < 4.6:
		var rx: float = float(ax[0]) + r * cos(a) - float(o[0])
		var rz: float = float(ax[1]) + r * sin(a) - float(o[1])
		var u: float = rx * cos(yaw) - rz * sin(yaw)
		var v: float = -(rx * sin(yaw) + rz * cos(yaw))
		if u > u0 and u < u1 and v > v0 and v < v1:
			return r - 0.02
		r += 0.02
	return 99.0


## A ring of flooring from r0 out to r1 round the tower axis. With the authored shell the outer edge follows the wall: sectors of 7.5 degrees, each stopped where the
## house wall bites into the tower, and left out where nothing is left. Otherwise one full arc, as before.
func _ring_floor(P: Node3D, nm: String, r0: float, r1: float, y0: float, y1: float, m, solid: bool) -> void:
	if not authored:
		_arc(P, nm, r0, r1, 0.0, 360.0, y0, y1, m, solid)
		return
	var step := 7.5
	var ym := (y0 + y1) * 0.5
	for k in int(360.0 / step):
		var a0 := step * float(k)
		# the wall is a plane: the sector's nearest corner decides, and a few cm in so the edge sits clear of the face
		var ro := minf(minf(r1, analytic_inner(ym) - 0.01), minf(house_bite(ym, a0), minf(house_bite(ym, a0 + step * 0.5), house_bite(ym, a0 + step))) - 0.04)
		if ro > r0 + 0.05:
			_arc(P, "%s_%d" % [nm, k], r0, ro, a0, a0 + step, y0, y1, m, solid)


# ======================================================================== tower landings (lighthouse frame)

## The tower's ground floor beyond the spiral: the v3 greybox only floors the ring under the stair (radius 1.14-2.07), so
## the tower base was a pit round it with the island visible below. A full ring out to radius 3.0, a low stone parapet
## on its rim, open across the house doorway side where the entry slab comes in.
func _g_ring(P: Node3D) -> void:
	var m := _ds("flags")
	_ring_floor(P, "G_TowerRing", 2.05, 3.03, 0.97 - 0.3, 0.97 - 0.008, m, true)
	_wall_lamp(P, "G_TowerLamp", 100.0, 2.95, 0.97 + 2.0, 1.3)
	anchors_lh["g_tower_ring"] = _pt(100.0, 2.55, 0.97)


func _l1_ring(P: Node3D) -> void:
	var m := _ds("flags")
	# a full ring out to the tower lining (tower_shell.gd); its top sits 1.2 cm under the house floor and the doorway slab
	_ring_floor(P, "L1_TowerRing", 2.1, 3.42, L1 - 0.28, L1 - 0.012, m, true)
	# above the ring the spiral runs out to the wall, so the ring is walkable only where there is headroom (about bearing
	# 320 round to the landing at 147)
	_cyl(P, "L1_Hose", _pt(30.0, 3.0, L1 + 0.1), _pt(30.0, 3.0, L1 + 0.22), 0.3, _m("canvas"), false)
	_wall_lamp(P, "L1_TowerLamp", 20.0, 3.3, L1 + 1.9, 1.3)
	anchors_lh["l1_ring"] = _pt(40.0, 2.8, L1)


func _l2_ring(P: Node3D) -> void:
	var m := _ds("planks")
	var R := 2.93
	_arc(P, "L2_TowerRing", 2.1, R + 0.02, 0.0, 360.0, L2 - 0.28, L2 - 0.006, m, true)
	# the electrical control cabinet (the dynamo's output comes up here): bearing 30
	_rbox(P, "L2_Cabinet", 30.0, R - 0.1, 1.3, 0.2, L2, L2 + 1.9, _m("iron_dark"), true)
	for i in 3:
		_rdisc(P, "L2_CabinetDial_%d" % i, 30.0 - 4.0 + 4.0 * i, R - 0.21, L2 + 1.5, 0.08, _m("gauge_face"))
	_rdisc(P, "L2_CabinetLampG", 30.0 - 3.0, R - 0.21, L2 + 1.15, 0.035, _m("lamp_green"))
	_rdisc(P, "L2_CabinetLampR", 30.0 + 3.0, R - 0.21, L2 + 1.15, 0.035, _m("lamp_red"))
	_rbox(P, "L2_CabinetSwitch", 30.0, R - 0.21, 0.09, 0.03, L2 + 0.7, L2 + 1.05, _m("brass"), false)
	# the instrument station (barometer, barograph, thermometer): bearing 205, on a small table
	_rbox(P, "L2_Table", 75.0, R - 0.1, 1.0, 0.2, L2, L2 + 0.8, _m("wood_dark"), true)
	_rbox(P, "L2_Barograph", 75.0, R - 0.1, 0.45, 0.18, L2 + 0.8, L2 + 1.0, _m("brass"), false)
	_rdisc(P, "L2_Barometer", 75.0, R - 0.06, L2 + 1.7, 0.2, _m("brass"))
	_rdisc(P, "L2_BarometerFace", 75.0, R - 0.1, L2 + 1.7, 0.17, _m("gauge_face"))
	_rbox(P, "L2_Chart", 70.0, R - 0.05, 0.6, 0.02, L2 + 1.1, L2 + 1.5, _m("paper_old"), false)
	# tool locker and a barrel
	_rbox(P, "L2_Locker", 100.0, R - 0.1, 1.0, 0.2, L2, L2 + 1.8, _m("wood_dark"), true)
	_rbox(P, "L2_LockerDoor", 100.0, R - 0.21, 0.9, 0.02, L2 + 0.1, L2 + 1.7, _m("iron_dark"), false)
	_rbox(P, "L2_WaterCan", 345.0, R - 0.1, 0.55, 0.2, L2, L2 + 0.7, _m("wood"), true)
	# a pegged coil of rope by the landing
	_cyl(P, "L2_Rope", _pt(122.0, R - 0.2, L2), _pt(122.0, R - 0.2, L2 + 0.14), 0.18, _m("canvas"), false)
	# (the brass feed pipe that ran up the wall here stood off the lining and ended in mid air: removed, 2026-10-25)
	_wall_lamp(P, "L2_LampA", 60.0, R - 0.02, L2 + 1.9, 0.9)
	_wall_lamp(P, "L2_LampB", 335.0, R - 0.02, L2 + 1.9, 0.9)
	anchors_lh["l2_control"] = _pt(30.0, 2.5, L2)
	anchors_lh["l2_instruments"] = _pt(75.0, 2.5, L2)
	anchors_lh["l2_landing"] = _pt(147.0, 2.6, L2)
	refs["L2_Cabinet"] = P.get_node_or_null("L2_Cabinet")


## The spiral's outer handrail: a post at every step's outer edge, a rod between them and an invisible wall so nobody steps
## off into the gap between the stair and the tower wall. Open at the landings (the ring and the house doorway join the
## stair there), at the foot, and at the top where the stair arrives on the lamp-room floor.
const STAIR_GAPS := [[0, 2], [22, 25], [46, 49], [92, 95]]


func _stair_rail(P: Node3D) -> void:
	var iron := _m("iron_dark")
	var R := 2.1
	var pts: Array[Vector3] = []
	for k in 97:
		pts.append(_pt(LANDING_DEG + 15.0 * k, R, 0.97 + float(k + 1) * RISE + 0.95))
	for i in 96:
		var gap := false
		for g in STAIR_GAPS:
			if i >= g[0] and i <= g[1]:
				gap = true
		if gap:
			continue
		var a0 := LANDING_DEG + 15.0 * i
		var ytop := 0.97 + float(i + 1) * RISE
		_cyl(P, "StairRail_Post%d" % i, _pt(a0, R, ytop), pts[i], 0.022, iron, false)
		_cyl(P, "StairRail_Bar%d" % i, pts[i], pts[i + 1], 0.03, iron, false)
		_arc(P, "StairRail_Wall%d" % i, R - 0.015, R + 0.015, a0, a0 + 15.0, ytop - 0.02, ytop + 1.0, iron, true, false)


# ---- helpers in the lighthouse frame

func _pt(bearing_deg: float, r: float, y: float) -> Vector3:
	var a := deg_to_rad(bearing_deg)
	return Vector3(TOWER.x + r * cos(a), y, TOWER.y + r * sin(a))


func _m(name: String) -> Material:
	return K.mats[name]


func _ds(name: String) -> Material:
	if not _mat_cache.has(name):
		var m: StandardMaterial3D = (K.mats[name] as StandardMaterial3D).duplicate()
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_cache[name] = m
	return _mat_cache[name]


## An arc of floor (or rail wall): an annulus sector from bearing a0 to a1 (degrees, increasing), r0..r1, y0..y1. One mesh
## and one convex collision shape per wedge of at most 15 degrees. `solid` false = no collision; `visible` false = invisible.
func _arc(P: Node3D, nm: String, r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, mat: Material, solid: bool, vis := true, ctr := TOWER) -> MeshInstance3D:
	var n := maxi(1, ceili(absf(a1 - a0) / 15.0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body: StaticBody3D = null
	if solid:
		body = StaticBody3D.new()
		body.name = "Body"
		body.collision_layer = 1
	for i in n:
		var t0 := deg_to_rad(a0 + (a1 - a0) * float(i) / float(n))
		var t1 := deg_to_rad(a0 + (a1 - a0) * float(i + 1) / float(n))
		var q := [
			Vector3(ctr.x + r0 * cos(t0), y0, ctr.y + r0 * sin(t0)), Vector3(ctr.x + r1 * cos(t0), y0, ctr.y + r1 * sin(t0)),
			Vector3(ctr.x + r1 * cos(t1), y0, ctr.y + r1 * sin(t1)), Vector3(ctr.x + r0 * cos(t1), y0, ctr.y + r0 * sin(t1)),
			Vector3(ctr.x + r0 * cos(t0), y1, ctr.y + r0 * sin(t0)), Vector3(ctr.x + r1 * cos(t0), y1, ctr.y + r1 * sin(t0)),
			Vector3(ctr.x + r1 * cos(t1), y1, ctr.y + r1 * sin(t1)), Vector3(ctr.x + r0 * cos(t1), y1, ctr.y + r0 * sin(t1)),
		]
		var c: Vector3 = (q[0] + q[2] + q[4] + q[6]) * 0.25
		# faces as quads of 4 corner indices; each gets its outward normal from the centroid
		for f in [[4, 5, 6, 7], [3, 2, 1, 0], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]:
			var a: Vector3 = q[f[0]]
			var b: Vector3 = q[f[1]]
			var cc: Vector3 = q[f[2]]
			var d: Vector3 = q[f[3]]
			var nrm := (b - a).cross(cc - a).normalized()
			var mid := (a + cc) * 0.5
			if nrm.dot(mid - c) < 0.0:
				nrm = -nrm
			_tri(st, a, b, cc, nrm)
			_tri(st, a, cc, d, nrm)
		if solid:
			var cs := CollisionShape3D.new()
			var sh := ConvexPolygonShape3D.new()
			sh.points = PackedVector3Array(q)
			cs.shape = sh
			body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.visible = vis
	P.add_child(mi)
	if body:
		mi.add_child(body)
	K.count += 1
	return mi


## Triangle with a front face that Godot (clockwise winding) shows from the side `nrm` points to.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, nrm: Vector3) -> void:
	var cr := (b - a).cross(c - a)
	if cr.dot(nrm) > 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		st.set_normal(nrm)
		st.add_vertex(v)


## The inner railing: posts every 15 degrees, a top bar, and an invisible solid wall, except across the listed
## [from, to] bearing gaps (where the spiral meets the landing).
func _rail(P: Node3D, nm: String, y: float, a0: float, a1: float, gaps: Array) -> void:
	var segs := maxi(1, ceili(absf(a1 - a0) / 15.0))
	var iron := _m("iron_dark")
	for i in segs + 1:
		var a := a0 + (a1 - a0) * float(i) / float(segs)
		if _in_gaps(a, gaps):
			continue
		_cyl(P, "%s_Post%d" % [nm, i], _pt(a, INNER_R, y), _pt(a, INNER_R, y + 1.0), 0.03, iron, false)
	var run := a0
	while run < a1 - 0.01:
		var nxt := minf(a1, run + 15.0)
		var mid := (run + nxt) * 0.5
		if not _in_gaps(mid, gaps):
			_cyl(P, "%s_Top%d" % [nm, int(run)], _pt(run, INNER_R, y + 1.0), _pt(nxt, INNER_R, y + 1.0), 0.035, iron, false)
			_cyl(P, "%s_Mid%d" % [nm, int(run)], _pt(run, INNER_R, y + 0.5), _pt(nxt, INNER_R, y + 0.5), 0.018, iron, false)
			_arc(P, "%s_Wall%d" % [nm, int(run)], INNER_R - 0.01, INNER_R + 0.01, run, nxt, y, y + 1.0, iron, true, false)
		run = nxt


func _in_gaps(a: float, gaps: Array) -> bool:
	var am := fposmod(a, 360.0)
	for g in gaps:
		var lo := fposmod((g as Vector2).x, 360.0)
		var hi := fposmod((g as Vector2).y, 360.0)
		if (lo <= hi and am >= lo and am <= hi) or (lo > hi and (am >= lo or am <= hi)):
			return true
	return false


## A cylinder between two lighthouse-frame points.
func _cyl(P: Node3D, nm: String, a: Vector3, b: Vector3, r: float, mat: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = a.distance_to(b)
	cm.radial_segments = 12
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	var up := (b - a).normalized()
	var ref := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := up.cross(ref).normalized()
	var z := x.cross(up).normalized()
	mi.transform = Transform3D(Basis(x, up, z), (a + b) * 0.5)
	P.add_child(mi)
	K.count += 1
	if solid:
		var sb := StaticBody3D.new()
		sb.name = "Body"
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = r
		sh.height = cm.height
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


## A box standing against the tower wall at `bearing`, centred at radius `r`: w along the wall, d radial, y0..y1.
func _rbox(P: Node3D, nm: String, bearing: float, r: float, w: float, d: float, y0: float, y1: float, mat: Material, solid: bool) -> MeshInstance3D:
	var a := deg_to_rad(bearing)
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = Vector3(w, y1 - y0, d)
	mi.mesh = bm
	mi.material_override = mat
	# local +z points toward the tower axis, local x runs along the wall
	var theta := atan2(-cos(a), -sin(a))
	mi.rotation.y = theta
	mi.position = Vector3(TOWER.x + r * cos(a), (y0 + y1) * 0.5, TOWER.y + r * sin(a))
	P.add_child(mi)
	K.count += 1
	if solid:
		var sb := StaticBody3D.new()
		sb.name = "Body"
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = bm.size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


## A round dial on the wall, facing the tower axis.
func _rdisc(P: Node3D, nm: String, bearing: float, r: float, y: float, rad: float, mat: Material) -> void:
	var a := deg_to_rad(bearing)
	var p0 := Vector3(TOWER.x + r * cos(a), y, TOWER.y + r * sin(a))
	var inward := Vector3(-cos(a), 0, -sin(a))
	_cyl(P, nm, p0, p0 + inward * 0.03, rad, mat, false)


func _wall_lamp(P: Node3D, nm: String, bearing: float, r: float, y: float, energy: float) -> void:
	var a := deg_to_rad(bearing)
	var inward := Vector3(-cos(a), 0, -sin(a))
	var at := Vector3(TOWER.x + r * cos(a), y, TOWER.y + r * sin(a))
	_cyl(P, nm + "_Plate", at, at + inward * 0.08, 0.07, _m("brass"), false)
	var s := MeshInstance3D.new()
	s.name = nm + "_Glass"
	var sm := SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.2
	s.mesh = sm
	s.material_override = _m("glow_warm")
	s.position = at + inward * 0.16
	P.add_child(s)
	var l := OmniLight3D.new()
	l.name = nm + "_Light"
	l.position = at + inward * 0.5 + Vector3(0, 0.1, 0)
	l.light_color = Color(1.0, 0.76, 0.46)
	l.light_energy = energy
	l.omni_range = 4.5
	l.set_meta("flicker", 0.08)
	P.add_child(l)
	K.lights.append(l)
