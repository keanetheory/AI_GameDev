# rooms_house.gd - the house's ground floor and basement, furnished (Lighthouse Interior Creator Agent, pass 1).
# Blueprint (ConceptArt/narrative_blueprints, Interior Plan V4): G = entry vestibule, hallway with the Flighted posters,
# keeper's office, storage room, stairs down, tower stair up. B1 = coal store, boiler room (shovel coal here), steam
# engine and dynamo, maintenance workshop, stores, crawlspace and wall voids. The walls, floors and stairs are the
# v3 greybox (a .glb); this adds the partitions, props, trim, lights and the things the story uses.
# All coordinates are house-frame (u along the front wall, v inward from the door, y local height); see kit.gd.
extends RefCounted

const Poster := preload("res://scripts/world/interior/poster.gd")
const Gauge := preload("res://scripts/world/interior/boiler_gauge.gd")
const Job := preload("res://scripts/world/interior/coal_job.gd")
const Pile := preload("res://scripts/world/interior/coal_pile.gd")
const Hatch := preload("res://scripts/world/interior/firebox_hatch.gd")
const Flame := preload("res://scripts/world/interior/fire_flame.gd")
const Zone := preload("res://scripts/world/interior/zone_trigger.gd")

const GF := 0.97
const B1 := -2.0
const CEIL := 3.75         # top of the ground-floor walls
const BCEIL := 0.77        # underside of the ground floor slab: the basement ceiling
const WALL := Color(0.0, 0.0, 0.0)

var K
## Positions this build moves from the v3 markers, house frame (u, y, v). interior_anchors.gd reads them.
var anchors := {}
## Nodes other scripts need: the boiler gauge and fire light, the posters.
var refs := {}


func build(kit, parent: Node3D) -> void:
	K = kit
	var g := Node3D.new()
	g.name = "Ground"
	parent.add_child(g)
	var b := Node3D.new()
	b.name = "Basement"
	parent.add_child(b)
	_ground(g)
	_basement(b)


# ======================================================================== GROUND FLOOR

func _ground(P: Node3D) -> void:
	# --- shell: ceiling, beams, panelling, trim
	K.box(P, "G_Ceiling", -2.25, 5.65, 0.35, 6.8, CEIL, CEIL + 0.2, "plaster_dark")
	for i in 6:
		var u := -1.9 + 1.5 * i
		K.box(P, "G_Beam_%d" % i, u - 0.1, u + 0.1, 0.4, 6.75, CEIL - 0.2, CEIL, "wood_dark", false)
	var wh := GF + 1.05
	K.box(P, "G_Panel_FrontL", -2.15, -0.95, 0.36, 0.41, GF, wh, "wood_dark", false)
	K.box(P, "G_Panel_FrontR", 0.95, 5.55, 0.36, 0.41, GF, wh, "wood_dark", false)
	K.box(P, "G_Panel_West", -2.15, -2.10, 0.36, 6.7, GF, wh, "wood_dark", false)
	K.box(P, "G_Panel_Back", -2.15, 5.55, 6.65, 6.7, GF, wh, "wood_dark", false)
	K.box(P, "G_Panel_East", 5.5, 5.55, 2.25, 6.7, GF, wh, "wood_dark", false)
	K.box(P, "G_PanelRail_West", -2.15, -2.08, 0.36, 6.7, wh, wh + 0.06, "wood", false)
	K.box(P, "G_PanelRail_Back", -2.15, 5.55, 6.63, 6.7, wh, wh + 0.06, "wood", false)
	K.box(P, "G_Cornice_West", -2.15, -2.05, 0.36, 6.7, CEIL - 0.1, CEIL, "wood", false)
	K.box(P, "G_Cornice_Back", -2.15, 5.55, 6.6, 6.7, CEIL - 0.1, CEIL, "wood", false)
	# --- the front door's frame (the door itself is the LighthouseDoor node)
	var dh := 2.95
	var dj := 0.0
	K.box(P, "G_DoorLintel", -1.0 + dj, 1.0 - dj, 0.1, 0.45, GF + dh, GF + dh + 0.08, "wood_dark", false)
	# LHF-12: the inside of the door: jambs, a worn stone threshold and a doorstop, so the frame reads the same as the outside's
	K.box(P, "G_DoorJamb_L", -1.0 + dj, -0.9 + dj, 0.1, 0.45, GF, GF + dh, "wood_dark", false)
	K.box(P, "G_DoorJamb_R", 0.9 - dj, 1.0 - dj, 0.1, 0.45, GF, GF + dh, "wood_dark", false)
	K.box(P, "G_Threshold", -0.95, 0.95, 0.12, 0.5, GF - 0.01, GF + 0.03, "stone", false)

	# --- entry vestibule and hallway (u -2.25..5.65, v 0.35..2.3)
	K.box(P, "G_Rug", -0.8, 0.8, 0.55, 2.2, GF, GF + 0.02, "rug", false)
	K.box(P, "G_DoorMat", -0.6, 0.6, 0.38, 0.62, GF, GF + 0.03, "canvas", false)
	# coats and boots on the right of the door
	K.rod(P, "G_CoatRail", Vector3(2.35, GF + 1.85, 0.42), Vector3(4.65, GF + 1.85, 0.42), 0.02, "iron", false)
	var coat_u := [2.45, 2.95, 3.5, 4.05, 4.45]
	for i in coat_u.size():
		var cu: float = coat_u[i]
		var tone: String = ["leather", "navy", "leather", "cloth_green", "navy"][i % 5]
		K.box(P, "G_Coat_%d" % i, cu, cu + 0.34, 0.43, 0.58, GF + 0.55, GF + 1.8, tone, false)
		K.box(P, "G_CoatCollar_%d" % i, cu + 0.04, cu + 0.3, 0.42, 0.6, GF + 1.65, GF + 1.85, tone, false)
	K.box(P, "G_BootBench", 2.3, 4.7, 0.45, 0.85, GF, GF + 0.42, "wood", true)
	K.box(P, "G_Boots_0", 2.5, 2.75, 0.5, 0.78, GF + 0.42, GF + 0.62, "black", false)
	K.box(P, "G_Boots_1", 2.85, 3.1, 0.5, 0.78, GF + 0.42, GF + 0.6, "black", false)
	K.pole(P, "G_UmbrellaStand", 5.2, 0.7, GF, GF + 0.6, 0.13, "iron_dark", true)
	K.rod(P, "G_Umbrella_0", Vector3(5.18, GF + 0.55, 0.7), Vector3(5.1, GF + 1.2, 0.66), 0.018, "black")
	K.rod(P, "G_Umbrella_1", Vector3(5.22, GF + 0.55, 0.72), Vector3(5.3, GF + 1.1, 0.78), 0.018, "wood_dark")
	# wall lanterns either side of the door
	for i in 2:
		var lu := -1.55 if i == 0 else 1.75
		_sconce(P, "G_Sconce_Front%d" % i, Vector3(lu, GF + 2.2, 0.47), Vector3(0, 0, 1), 1.5, 5.0)
	# the posters (E reads them; POSTER_EXAMINED)
	_poster(P, "Poster_Storms", Vector3(1.55, GF + 1.6, 0.37), Vector3(0, 0, 1), "poster_storms_a", -1.5)
	_poster(P, "Poster_Seasons", Vector3(-2.1, GF + 1.6, 1.35), Vector3(1, 0, 0), "poster_seasons_a", 1.2)
	_poster(P, "Poster_Moon", Vector3(-1.55, GF + 1.6, 0.37), Vector3(0, 0, 1), "poster_storms_b", 2.0)     # keeps its node name; the old third slogan was not canon
	_poster(P, "Poster_Seasons_B", Vector3(5.15, GF + 1.6, 0.37), Vector3(0, 0, 1), "poster_seasons_b", -2.5)
	# documents board between the posters and the window
	K.box(P, "G_NoticeBoard", -2.1, -2.06, 1.95, 2.95, GF + 1.0, GF + 2.05, "wood_dark", false)
	var doc_n := [[2.1, 1.6, 0.0], [2.35, 1.45, 0.1], [2.62, 1.55, -0.1], [2.82, 1.35, 0.05]]
	for i in doc_n.size():
		var d: Array = doc_n[i]
		var dv: float = d[0]
		K.sheet(P, "G_Notice_%d" % i, Vector3(-2.04, GF + d[1] + 0.35, dv), Vector3(1, 0, 0), 0.2, 0.28, "paper_old")
	K.sheet(P, "G_Tidetable", Vector3(-2.04, GF + 1.85, 2.5), Vector3(1, 0, 0), 0.34, 0.5, "paper", "TIDES AND\nTHE MOON\n\nentered by hand,\nsigned T.", 26, Color(0.1, 0.1, 0.12))

	# --- keeper's office (u -2.15..1.0, v 3.35..6.7): west of the stairs
	_office(P)
	# --- storage room (u 3.7..5.55, v 3.3..6.7): east of the stairs
	_storage(P)
	# --- the stairwell: spiral_down.gd fills the rest of the hole with floor and rails the opening round the spiral
	# --- tower door frame (east wall aperture u 5.65, v 0.8..2.25, header 3.25)
	K.box(P, "G_TowerDoor_Jamb0", 5.5, 5.8, 0.68, 0.8, GF, GF + 2.3, "wood_dark", false)
	K.box(P, "G_TowerDoor_Jamb1", 5.5, 5.8, 2.25, 2.37, GF, GF + 2.3, "wood_dark", false)
	K.box(P, "G_TowerDoor_Head", 5.5, 5.8, 0.68, 2.37, GF + 2.3, GF + 2.43, "wood_dark", false)
	_sconce(P, "G_Sconce_Tower", Vector3(5.48, GF + 2.0, 2.45), Vector3(-1, 0, 0), 1.3, 4.5)
	# --- wall voids in the hall panelling: where Ted says it's only the wind (WALL_WHISPER_HEARD)
	_void(P, "G_WallVoid_West", Vector3(-2.15, GF + 0.55, 5.95), Vector3(1, 0, 0), 0.5, 0.7, "whisper")
	_void(P, "G_WallVoid_East", Vector3(5.5, GF + 0.55, 3.0), Vector3(-1, 0, 0), 0.5, 0.7, "whisper")


func _office(P: Node3D) -> void:
	# desk and chair against the back wall
	K.box(P, "Office_DeskTop", -1.75, -0.25, 5.9, 6.65, GF + 0.74, GF + 0.8, "wood", true)
	K.box(P, "Office_DeskLeft", -1.72, -1.6, 5.95, 6.6, GF, GF + 0.74, "wood_dark", true)
	K.box(P, "Office_DeskRight", -0.4, -0.28, 5.95, 6.6, GF, GF + 0.74, "wood_dark", true)
	K.box(P, "Office_DeskBack", -1.6, -0.4, 6.5, 6.6, GF + 0.2, GF + 0.74, "wood_dark", false)
	K.box(P, "Office_Blotter", -1.3, -0.7, 6.0, 6.35, GF + 0.8, GF + 0.815, "cloth_green", false)
	K.box(P, "Office_Ledger", -1.55, -1.3, 6.05, 6.4, GF + 0.8, GF + 0.86, "leather", false)
	K.box(P, "Office_Chair_Seat", -1.2, -0.75, 5.3, 5.75, GF + 0.42, GF + 0.47, "wood", true)
	K.box(P, "Office_Chair_Back", -1.2, -0.75, 5.27, 5.33, GF + 0.47, GF + 0.95, "wood", false)
	for i in 4:
		var cu := -1.2 if i % 2 == 0 else -0.8
		var cv := 5.3 if i < 2 else 5.7
		K.box(P, "Office_Chair_Leg_%d" % i, cu, cu + 0.05, cv, cv + 0.05, GF, GF + 0.42, "wood_dark", false)
	# oil lamp on the desk
	K.pole(P, "Office_Lamp_Base", -0.55, 6.3, GF + 0.8, GF + 0.86, 0.07, "brass", false)
	K.pole(P, "Office_Lamp_Glass", -0.55, 6.3, GF + 0.86, GF + 1.08, 0.055, "glow_warm", false)
	K.light(P, "Office_LampLight", Vector3(-0.55, GF + 1.2, 6.2), Color(1.0, 0.72, 0.4), 1.3, 4.5, 0.18)
	# shelves with ledgers on the west wall
	for i in 4:
		K.box(P, "Office_Shelf_%d" % i, -2.12, -1.8, 4.5, 6.4, GF + 0.55 + 0.42 * i, GF + 0.58 + 0.42 * i, "wood", false)
	K.box(P, "Office_ShelfSide0", -2.12, -1.8, 4.47, 4.52, GF + 0.5, GF + 2.25, "wood_dark", true)
	K.box(P, "Office_ShelfSide1", -2.12, -1.8, 6.38, 6.43, GF + 0.5, GF + 2.25, "wood_dark", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for r in 4:
		var v := 4.56
		while v < 6.3:
			var w := rng.randf_range(0.05, 0.11)
			var tone: String = ["leather", "cloth_green", "paper_navy", "wood_dark"][rng.randi() % 4]
			K.box(P, "Office_Book_%d_%d" % [r, int(v * 100)], -2.1, -1.88, v, v + w, GF + 0.58 + 0.42 * r, GF + 0.58 + 0.42 * r + rng.randf_range(0.2, 0.34), tone, false)
			v += w + 0.012
	# filing cabinet, chart table with a sea chart, stool
	K.box(P, "Office_Cabinet", 0.2, 0.72, 6.1, 6.68, GF, GF + 1.3, "iron", true)
	for i in 3:
		K.box(P, "Office_CabinetDrawer_%d" % i, 0.21, 0.23, 6.14, 6.64, GF + 0.12 + 0.4 * i, GF + 0.48 + 0.4 * i, "iron_dark", false)
	K.box(P, "Office_ChartTable", -0.2, 0.75, 4.55, 5.25, GF + 0.8, GF + 0.86, "wood", true)
	for ci in 2:
		var cu2 := -0.15 if ci == 0 else 0.62
		K.box(P, "Office_ChartLeg_%d" % ci, cu2, cu2 + 0.1, 4.6, 5.2, GF, GF + 0.8, "wood_dark", false)
	K.sheet(P, "Office_Chart", Vector3(0.27, GF + 0.867, 4.9), Vector3(0, 1, 0), 0.85, 0.6, "paper_old", "BRACKEN ISLE\nto SALTGATE\n  ~ ~ ~", 34, Color(0.14, 0.1, 0.07))
	# a rug and a wall clock
	K.box(P, "Office_Rug", -1.5, 0.2, 4.4, 5.6, GF, GF + 0.02, "rug", false)
	K.disc(P, "Office_Clock", Vector3(-0.2, GF + 2.2, 6.62), Vector3(0, 0, 1), 0.2, 0.05, "brass")
	K.disc(P, "Office_ClockFace", Vector3(-0.2, GF + 2.2, 6.59), Vector3(0, 0, 1), 0.16, 0.03, "gauge_face")
	K.sheet(P, "Office_ChartPin", Vector3(-1.0, GF + 1.5, 6.64), Vector3(0, 0, -1), 0.9, 0.55, "paper_old", "STORM LOG", 30, Color(0.15, 0.1, 0.07))


func _storage(P: Node3D) -> void:
	# walls: a doorway 0.95 wide in the front partition
	K.box(P, "Store_WallW", 3.65, 3.75, 3.3, 6.7, GF, CEIL, "plaster", true)
	K.box(P, "Store_FrontA", 3.65, 4.15, 3.25, 3.35, GF, CEIL, "plaster", true)
	K.box(P, "Store_FrontB", 5.1, 5.55, 3.25, 3.35, GF, CEIL, "plaster", true)
	K.box(P, "Store_Lintel", 4.15, 5.1, 3.25, 3.35, GF + 2.35, CEIL, "plaster", true)
	K.box(P, "Store_DoorJamb0", 4.12, 4.2, 3.2, 3.4, GF, GF + 2.35, "wood_dark", false)
	K.box(P, "Store_DoorJamb1", 5.05, 5.13, 3.2, 3.4, GF, GF + 2.35, "wood_dark", false)
	# crates, barrels, shelving, rope
	K.box(P, "Store_Crate_0", 4.0, 4.7, 5.5, 6.2, GF, GF + 0.7, "wood", true)
	K.box(P, "Store_Crate_1", 4.1, 4.7, 5.55, 6.15, GF + 0.7, GF + 1.25, "wood_dark", true)
	K.box(P, "Store_Crate_2", 4.0, 4.6, 4.7, 5.3, GF, GF + 0.55, "wood_dark", true)
	for i in 3:
		K.pole(P, "Store_Barrel_%d" % i, 5.15, 3.9 + 0.55 * i, GF, GF + 0.85, 0.26, "wood", true)
		K.pole(P, "Store_BarrelBand_%d" % i, 5.15, 3.9 + 0.55 * i, GF + 0.2, GF + 0.26, 0.275, "iron_dark", false)
		K.pole(P, "Store_BarrelBand2_%d" % i, 5.15, 3.9 + 0.55 * i, GF + 0.6, GF + 0.66, 0.275, "iron_dark", false)
	for i in 3:
		K.box(P, "Store_ShelfBoard_%d" % i, 4.95, 5.5, 5.55, 6.65, GF + 0.5 + 0.55 * i, GF + 0.53 + 0.55 * i, "wood", false)
	K.box(P, "Store_ShelfPost0", 5.4, 5.5, 5.5, 5.58, GF, GF + 1.9, "wood_dark", true)
	K.box(P, "Store_ShelfPost1", 5.4, 5.5, 6.6, 6.68, GF, GF + 1.9, "wood_dark", true)
	for i in 6:
		var su := 5.05 + 0.07 * (i % 3)
		K.box(P, "Store_Tin_%d" % i, su, su + 0.1, 5.65 + 0.16 * i, 5.65 + 0.16 * i + 0.11, GF + 0.53 + 0.55 * (i / 3), GF + 0.53 + 0.55 * (i / 3) + 0.14, "brass", false)
	K.pole(P, "Store_Rope", 4.35, 4.15, GF, GF + 0.2, 0.28, "canvas", false)
	K.pole(P, "Store_Hanging_Light", 4.7, 4.5, CEIL - 0.45, CEIL, 0.01, "iron_dark", false)
	K.sphere(P, "Store_Bulb", Vector3(4.7, CEIL - 0.5, 4.5), 0.07, "glow_warm")
	K.light(P, "Store_Light", Vector3(4.7, CEIL - 0.55, 4.5), Color(1.0, 0.78, 0.5), 1.0, 4.0)
	K.sheet(P, "Store_Sign", Vector3(4.6, GF + 2.55, 3.22), Vector3(0, 0, -1), 0.5, 0.18, "paper_old", "STORE", 40, Color(0.1, 0.07, 0.05))


func _stair_rails(P: Node3D) -> void:
	# the hole: u 0.8..3.6, v 2.3..5.7. The spiral stair (spiral_down.gd) starts at the middle of the front edge, so the
	# front rail stops either side of a 1.4 m opening.
	var h := GF + 1.0
	_rail(P, "G_Rail_West", Vector3(0.78, GF, 2.3), Vector3(0.78, GF, 5.72), h)
	_rail(P, "G_Rail_Back", Vector3(0.78, GF, 5.72), Vector3(3.62, GF, 5.72), h)
	_rail(P, "G_Rail_East", Vector3(3.62, GF, 5.72), Vector3(3.62, GF, 2.3), h)
	_rail(P, "G_Rail_FrontE", Vector3(3.62, GF, 2.28), Vector3(2.9, GF, 2.28), h)
	_rail(P, "G_Rail_FrontW", Vector3(1.5, GF, 2.28), Vector3(0.78, GF, 2.28), h)
	K.box(P, "G_StairPad", 1.5, 2.9, 2.2, 2.6, GF - 0.2, GF, "flags", true)


## A railing along a straight run: posts every ~0.8 m, a top rail and a mid rail; solid (a thin wall) so it stops the player.
func _rail(P: Node3D, nm: String, a: Vector3, b: Vector3, top: float) -> void:
	var n := maxi(2, int(a.distance_to(b) / 0.8) + 1)
	for i in n:
		var t := float(i) / float(n - 1)
		var pt := a.lerp(b, t)
		K.pole(P, "%s_Post%d" % [nm, i], pt.x, pt.z, a.y, top, 0.035, "wood_dark", false)
	K.rod(P, nm + "_Top", Vector3(a.x, top, a.z), Vector3(b.x, top, b.z), 0.04, "wood", false)
	K.rod(P, nm + "_Mid", Vector3(a.x, a.y + 0.5, a.z), Vector3(b.x, a.y + 0.5, b.z), 0.02, "wood_dark", false)
	var du := absf(b.x - a.x)
	var dv := absf(b.z - a.z)
	var c := (a + b) * 0.5
	if du > dv:
		K.box(P, nm + "_Body", minf(a.x, b.x), maxf(a.x, b.x), c.z - 0.04, c.z + 0.04, a.y, top, "wood_dark", true).visible = false
	else:
		K.box(P, nm + "_Body", c.x - 0.04, c.x + 0.04, minf(a.z, b.z), maxf(a.z, b.z), a.y, top, "wood_dark", true).visible = false


## A wall lamp: a brass bracket, a glass and a warm light. `normal` is the way it faces (away from the wall).
func _sconce(P: Node3D, nm: String, at: Vector3, normal: Vector3, energy: float, rng: float) -> void:
	var n := normal.normalized()
	K.box(P, nm + "_Plate", at.x - 0.06 * absf(n.z) - 0.02 * absf(n.x), at.x + 0.06 * absf(n.z) + 0.02 * absf(n.x), at.z - 0.06 * absf(n.x) - 0.02 * absf(n.z), at.z + 0.06 * absf(n.x) + 0.02 * absf(n.z), at.y - 0.1, at.y + 0.1, "brass", false)
	K.sphere(P, nm + "_Glass", at + n * 0.1, 0.07, "glow_warm", 1.3)
	K.light(P, nm + "_Light", at + n * 0.45 + Vector3(0, 0.1, 0), Color(1.0, 0.76, 0.46), energy, rng, 0.08)


## A Flighted poster (LHF-09): a hand-made letterpress texture (tools/make_flighted_posters.py): black, silver and navy ink on aged
## paper, misregistered, torn at the edges (alpha-scissored), with paste drips and a fold. Canon: fac_flighted.md. The art is a
## flat decal 12 mm off the wall (the wall's own surface is behind it), so nothing z-fights; a few degrees of tilt keep a row of
## posters from looking hung by a ruler. `tex` is one of the poster_*.png in Assets/Textures/interior.
func _poster(P: Node3D, nm: String, c: Vector3, normal: Vector3, tex: String, tilt_deg := 0.0) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://Assets/Textures/interior/%s.png" % tex) as Texture2D
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var s = K.sheet(P, nm, c, normal, 0.72, 1.0, m)
	s.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(tilt_deg))
	var it := Node3D.new()
	it.set_script(Poster)
	it.name = "Read"
	s.add_child(it)
	refs[nm] = it


## A wall void: a dark recess behind an iron grille, where something is heard but never seen. A trigger fires the
## event once when the player stands near it (the Sound agent adds the audio at the Marker3D).
func _void(P: Node3D, nm: String, at: Vector3, normal: Vector3, w: float, h: float, kind: String) -> void:
	var n := normal.normalized()
	var along := Vector3(n.z, 0, n.x)
	var hu := absf(along.x) * w * 0.5 + absf(n.x) * 0.02
	var hv := absf(along.z) * w * 0.5 + absf(n.z) * 0.02
	K.box(P, nm + "_Hole", at.x - hu - 0.02, at.x + hu + 0.02, at.z - hv - 0.02, at.z + hv + 0.02, at.y - h * 0.5, at.y + h * 0.5, "black", false)
	for i in 5:
		var t := -0.4 + 0.2 * i
		var gp := at + along * t * w
		K.rod(P, nm + "_Bar%d" % i, gp + Vector3(0, -h * 0.5, 0) + n * 0.03, gp + Vector3(0, h * 0.5, 0) + n * 0.03, 0.012, "iron_dark")
	var m = K.node(P, "LHI_WallVoid_" + nm, at)
	m.set_meta("kind", kind)
	m.set_meta("note", "a wall void: " + kind + " sound source (WALL_WHISPER_HEARD / BASEMENT_BANG / BASEMENT_TALK)")
	m.add_to_group("lhi_wall_void")
	refs[nm] = m
	var ev: String = {"whisper": "WALL_WHISPER_HEARD", "bang": "BASEMENT_BANG", "talk": "BASEMENT_TALK"}.get(kind, "WALL_WHISPER_HEARD")
	var gate: String = {"bang": "BOILER_FED", "talk": "DANIEL_IN_BASEMENT"}.get(kind, "")
	_zone(P, "Zone_" + nm, at + n * 0.9 - Vector3(0, h * 0.5 - 0.5, 0), Vector3(1.8, 1.8, 1.8), ev, gate)


# ======================================================================== BASEMENT

func _basement(P: Node3D) -> void:
	# --- ceiling joists (the underside of the ground floor is planks; these hide its flatness). They stop at the stairwell:
	# the hole in the ground floor (u 0.8..3.6, v 2.3..5.7) is open, and joists across it would hang in the opening.
	for i in 7:
		var v := 0.8 + 0.9 * i
		if v + 0.1 > 2.3 and v - 0.1 < 5.7:
			K.box(P, "B_JoistW_%d" % i, -2.15, 0.78, v - 0.1, v + 0.1, 0.62, BCEIL, "wood_dark", false)
			K.box(P, "B_JoistE_%d" % i, 3.62, 5.55, v - 0.1, v + 0.1, 0.62, BCEIL, "wood_dark", false)
		else:
			K.box(P, "B_Joist_%d" % i, -2.15, 5.55, v - 0.1, v + 0.1, 0.62, BCEIL, "wood_dark", false)
	# --- coal store (SE corner, the far corner from the firebox so the player crosses the whole basement): a walled cell
	# u 3.0..5.55, v 0.45..2.3 with a doorway in its west wall, a low bin front and the heap against the east wall
	K.box(P, "B_CoalWall_W1", 2.9, 3.1, 0.45, 0.85, B1, BCEIL, "brick", true)
	K.box(P, "B_CoalWall_W2", 2.9, 3.1, 1.85, 2.5, B1, BCEIL, "brick", true)
	K.box(P, "B_CoalLintel", 2.9, 3.1, 0.85, 1.85, 0.15, BCEIL, "brick", true)
	K.box(P, "B_CoalWall_N", 3.0, 5.55, 2.3, 2.5, B1, BCEIL, "brick", true)
	K.box(P, "B_CoalBinFront", 4.3, 4.45, 0.45, 2.3, B1, B1 + 0.95, "wood_dark", true)
	for i in 4:
		K.box(P, "B_CoalBinPost_%d" % i, 4.24, 4.5, 0.5 + 0.55 * i, 0.58 + 0.55 * i, B1, B1 + 1.2, "wood", false)
	_coal_pile(P, "B_CoalHeap", 4.95, 1.35, B1, 0.72, 1.05, 190, 5)
	K.box(P, "B_CoalHeap_Core", 4.5, 5.5, 0.55, 2.25, B1, B1 + 0.35, "coal", false)
	# the shovel, stuck in the heap with its handle leaning toward the player (the generated model, blade down in the coal)
	var sv = K.model(P, "B_Shovel", "res://Assets/Models/prop/lhi_coal_shovel.glb", Vector3(4.75, B1 + 0.62, 1.05), 90.0, 1.0)
	sv.get_node("Model").rotation_degrees = Vector3(0.0, 0.0, 22.0)
	K.light(P, "B_CoalLamp", Vector3(3.9, 0.2, 1.4), Color(1.0, 0.68, 0.38), 0.9, 3.5, 0.1)
	# --- boiler: the generated model (lhi_boiler.glb: brick plinth, riveted shell, copper band, barred firebox with its fire baked in,
	# brass gauge and water glass). Door faces +u (the player's side). Scaled to 1.5 m wide, 2.25 m tall.
	K.model(P, "B_Boiler", "res://Assets/Models/prop/lhi_boiler.glb", Vector3(-1.45, B1, 5.55), 90.0, 2.5, Vector3(1.5, 2.2, 1.5), AABB(Vector3(-0.2, -0.12, -0.5), Vector3(0.4, 0.45, 0.45)))
	K.pole(P, "B_Flue", -1.45, 5.55, B1 + 2.2, BCEIL, 0.14, "iron_dark", false)
	# The generated door and its scanned fire are cut away (kit.model's carve); an iron surround covers the ragged rim, a dark
	# recess shows the inside of the firebox, and a bed of glowing coal lies in it. The player shovels coal into this opening.
	var rim = K.colour(Color(0.16, 0.16, 0.18), 0.6, 0.6)
	K.box(P, "B_FireFrame_L", -1.02, -0.9, 5.08, 5.23, B1 + 0.05, B1 + 1.5, rim, false)
	K.box(P, "B_FireFrame_R", -1.02, -0.9, 5.87, 6.02, B1 + 0.05, B1 + 1.5, rim, false)
	K.box(P, "B_FireFrame_Head", -1.02, -0.9, 5.08, 6.02, B1 + 1.12, B1 + 1.5, rim, false)
	K.box(P, "B_FireFrame_Sill", -1.02, -0.88, 5.1, 6.0, B1 + 0.05, B1 + 0.17, rim, false)
	var inner = K.colour(Color(0.04, 0.025, 0.02), 0.95)
	inner.cull_mode = BaseMaterial3D.CULL_FRONT          # we look at the inside faces of this box: a recess
	K.box(P, "B_FireRecess", -1.5, -0.96, 5.24, 5.86, B1 + 0.18, B1 + 1.11, inner, false)
	# LHF-05: the fire bed is a dark coal base (no more flat red slab); fire_flame.gd puts glowing lumps and cel-shaded flames on it.
	var coal_glow = K.colour(Color(0.05, 0.035, 0.03), 0.9)
	var fire_glow = K.box(P, "B_FireDoorGlow", -1.45, -1.0, 5.28, 5.82, B1 + 0.18, B1 + 0.24, coal_glow, false)
	var flame := Node3D.new()
	flame.set_script(Flame)
	flame.position = K.p(-1.22, B1 + 0.24, 5.55)
	flame.rotation_degrees.y = 90.0          # the card's front (+z) faces +u, the player's side
	P.add_child(flame)
	refs["fire_light"] = K.light(P, "B_FireLight", Vector3(-0.45, B1 + 0.9, 5.55), Color(1.0, 0.5, 0.2), 2.0, 5.5, 0.1)
	# the pressure gauge the coal job drives: a big dial on the wall above the coal-side corner of the boiler (the model's own
	# gauge is a still picture)
	var gauge = K.node(P, "B_BoilerGauge", Vector3(-2.2, B1 + 1.75, 4.2))
	gauge.set_script(Gauge)
	K.disc(gauge, "B_GaugeRim", Vector3(0.0, 0.0, 0.0), Vector3(1, 0, 0), 0.2, 0.06, "brass")
	K.disc(gauge, "B_GaugeFace", Vector3(0.0, 0.0, 0.0) + Vector3(0.03, 0, 0), Vector3(1, 0, 0), 0.17, 0.03, "gauge_face")
	var needle := Node3D.new()
	needle.name = "Needle"
	needle.position = KP(0.04, 0.0, 0.0)
	gauge.add_child(needle)
	K.box(needle, "NeedleBar", -0.008, 0.008, -0.008, 0.008, 0.0, 0.14, "lamp_red", false)
	K.sheet(P, "B_GaugePlate", Vector3(-2.19, B1 + 1.48, 4.2), Vector3(1, 0, 0), 0.34, 0.1, "paper_old", "STEAM", 30, Color(0.12, 0.09, 0.07))
	refs["gauge"] = gauge
	gauge.set_level(0.0)
	# steam main: boiler -> along the back wall -> down the east wall -> the engine
	K.rod(P, "B_Pipe_0", Vector3(-1.2, 0.3, 6.0), Vector3(-1.2, 0.3, 6.5), 0.08, "iron")
	K.rod(P, "B_Pipe_1", Vector3(-1.2, 0.3, 6.5), Vector3(-1.2, 0.46, 6.5), 0.08, "iron")
	K.rod(P, "B_SteamMain", Vector3(-1.2, 0.46, 6.5), Vector3(5.4, 0.46, 6.5), 0.1, "canvas")
	for i in 14:
		var bu := -0.8 + 0.45 * i
		K.rod(P, "B_LagBand_%d" % i, Vector3(bu, 0.46, 6.5), Vector3(bu + 0.05, 0.46, 6.5), 0.108, "iron_dark")
	K.rod(P, "B_Drop", Vector3(5.4, 0.46, 6.5), Vector3(5.4, -0.55, 6.5), 0.08, "iron")
	K.rod(P, "B_RunDown", Vector3(5.4, -0.55, 6.5), Vector3(5.4, -0.55, 3.3), 0.08, "iron")
	K.rod(P, "B_RunIn", Vector3(5.4, -0.55, 3.3), Vector3(4.85, -0.55, 3.3), 0.08, "iron")
	for i in 3:
		K.disc(P, "B_ValveWheel_%d" % i, Vector3(1.0 + 1.7 * i, 0.46, 6.35), Vector3(0, 1, 0), 0.1, 0.02, "iron_dark")
		K.pole(P, "B_ValveStem_%d" % i, 1.0 + 1.7 * i, 6.5, 0.46, 0.5, 0.015, "iron_dark", false)
	K.disc(P, "B_ValveWheel_Eng", Vector3(5.4, -0.2, 5.0), Vector3(1, 0, 0), 0.11, 0.02, "iron_dark")
	# water cistern above the west wall and its feed
	K.rod(P, "B_Cistern", Vector3(-2.0, 0.28, 2.65), Vector3(-2.0, 0.28, 4.55), 0.3, "boiler", false)
	for i in 3:
		K.rod(P, "B_CisternStrap_%d" % i, Vector3(-2.0, 0.28, 2.9 + 0.7 * i), Vector3(-2.0, 0.28, 2.93 + 0.7 * i), 0.315, "iron_dark")
	K.rod(P, "B_CisternFeed", Vector3(-2.0, 0.0, 4.4), Vector3(-1.75, -1.3, 4.9), 0.04, "copper")
	# sconces
	_sconce(P, "B_Sconce_Boiler", Vector3(-2.1, B1 + 2.05, 3.7), Vector3(1, 0, 0), 1.2, 4.5)
	_sconce(P, "B_Sconce_Lobby", Vector3(2.2, B1 + 2.0, 0.5), Vector3(0, 0, 1), 1.2, 4.5)
	# --- lobby (u -0.5..3.6, v 0.45..2.3): the foot of the stairs
	K.box(P, "B_LobbyBench", 0.5, 1.9, 0.5, 0.95, B1, B1 + 0.5, "wood", true)
	for i in 4:
		K.pole(P, "B_OilskinPeg_%d" % i, 0.7 + 0.35 * i, 0.5, B1 + 1.6, B1 + 1.65, 0.015, "iron_dark", false)
		K.box(P, "B_Oilskin_%d" % i, 0.55 + 0.35 * i, 0.82 + 0.35 * i, 0.46, 0.58, B1 + 0.7, B1 + 1.65, "leather" if i % 2 == 0 else "canvas", false)
	K.pole(P, "B_LobbyBarrel", 0.2, 3.4, B1, B1 + 0.85, 0.28, "wood", true)
	K.box(P, "B_ToolRack", -2.1, -2.0, 2.6, 3.4, B1 + 0.9, B1 + 1.9, "wood_dark", false)
	# --- engine room (u 3.6..5.55, v 2.5..6.7): the generated steam engine with its dynamo and flywheel (lhi_steam_engine.glb),
	# long axis along v. The flywheel is part of the model, so it no longer turns.
	K.model(P, "B_SteamEngine", "res://Assets/Models/prop/lhi_steam_engine.glb", Vector3(4.55, B1, 4.9), 0.0, 2.2, Vector3(1.35, 1.3, 2.0))
	var flywheel = null
	# the switchboard on the east wall before the engine
	K.box(P, "B_Switchboard", 5.4, 5.55, 2.6, 3.4, B1 + 1.0, B1 + 2.1, "wood_dark", false)
	for i in 3:
		K.disc(P, "B_Switchboard_Dial_%d" % i, Vector3(5.38, B1 + 1.8, 2.72 + 0.24 * i), Vector3(-1, 0, 0), 0.08, 0.03, "gauge_face")
	var green_lamp = K.disc(P, "B_Switchboard_Lamp_Green", Vector3(5.38, B1 + 1.3, 2.75), Vector3(-1, 0, 0), 0.04, 0.03, K.colour(Color(0.2, 1.0, 0.35), 0.4, 0.0, 2.0))
	K.disc(P, "B_Switchboard_Lamp_Red", Vector3(5.38, B1 + 1.3, 3.05), Vector3(-1, 0, 0), 0.04, 0.03, "lamp_red")
	K.box(P, "B_Switchboard_Knife", 5.37, 5.4, 3.15, 3.25, B1 + 1.1, B1 + 1.5, "brass", false)
	_sconce(P, "B_Sconce_Engine", Vector3(5.5, B1 + 2.15, 6.2), Vector3(-1, 0, 0), 1.2, 4.5)
	# --- workshop and stores along the back (u 0.9..3.6, v 5.75..6.7), behind the stair landing
	K.box(P, "B_WorkBench", 1.0, 2.4, 6.3, 6.67, B1, B1 + 0.85, "wood", true)
	K.box(P, "B_BenchTop", 0.98, 2.42, 6.25, 6.69, B1 + 0.85, B1 + 0.9, "wood_dark", false)
	K.box(P, "B_Vice", 1.15, 1.4, 6.3, 6.5, B1 + 0.9, B1 + 1.08, "iron_dark", false)
	K.box(P, "B_ToolBoard", 0.95, 2.45, 6.66, 6.69, B1 + 1.2, B1 + 2.1, "wood_dark", false)
	for i in 7:
		K.box(P, "B_Tool_%d" % i, 1.05 + 0.2 * i, 1.1 + 0.2 * i, 6.6, 6.66, B1 + 1.45, B1 + 1.45 + 0.28 + 0.08 * (i % 3), "iron", false)
	K.box(P, "B_PartsShelf_0", 2.6, 3.55, 6.25, 6.68, B1 + 0.5, B1 + 0.53, "wood", false)
	K.box(P, "B_PartsShelf_1", 2.6, 3.55, 6.25, 6.68, B1 + 1.1, B1 + 1.13, "wood", false)
	K.box(P, "B_PartsShelf_2", 2.6, 3.55, 6.25, 6.68, B1 + 1.7, B1 + 1.73, "wood", false)
	K.box(P, "B_PartsPost_0", 3.5, 3.56, 6.2, 6.28, B1, B1 + 1.9, "wood_dark", true)
	K.box(P, "B_PartsPost_1", 2.55, 2.61, 6.2, 6.28, B1, B1 + 1.9, "wood_dark", true)
	for i in 8:
		var pu := 2.7 + 0.1 * i
		K.box(P, "B_Part_%d" % i, pu, pu + 0.08, 6.3, 6.45, B1 + 0.53 + 0.6 * (i % 3), B1 + 0.53 + 0.6 * (i % 3) + 0.1 + 0.03 * i, "brass" if i % 2 == 0 else "copper", false)
	K.light(P, "B_WorkshopLight", Vector3(2.0, B1 + 2.1, 6.2), Color(1.0, 0.78, 0.5), 0.9, 3.5)
	# --- crawlspace wall voids: the whispers and bangs, sound sources only (LHI-10)
	_void(P, "B_WallVoid_West", Vector3(-2.15, B1 + 0.5, 3.4), Vector3(1, 0, 0), 0.6, 0.8, "bang")
	_void(P, "B_WallVoid_Front", Vector3(0.3, B1 + 0.5, 0.46), Vector3(0, 0, 1), 0.6, 0.8, "whisper")
	_void(P, "B_WallVoid_East", Vector3(5.5, B1 + 0.5, 3.1), Vector3(-1, 0, 0), 0.6, 0.8, "talk")
	# --- the coal job (T33): heap, firebox door, gauge, engine
	var job := Node.new()
	job.name = "CoalJob"
	job.set_script(Job)
	P.add_child(job)
	job.gauge = gauge
	job.fire_light = refs["fire_light"]
	job.fire_glow = fire_glow
	job.fire_flame = flame
	flame.bind_light(refs["fire_light"])
	job.flywheel = flywheel
	job.green_lamp = green_lamp
	job._ready()
	var pile := Node3D.new()
	pile.name = "CoalHeapInteract"
	pile.set_script(Pile)
	pile.position = K.p(4.9, B1 + 0.3, 1.4)
	P.add_child(pile)
	pile.job_path = pile.get_path_to(job)
	var hatch := Node3D.new()
	hatch.name = "FireboxHatch"
	hatch.set_script(Hatch)
	hatch.position = K.p(-0.66, B1 + 0.95, 5.55)
	P.add_child(hatch)
	hatch.job_path = hatch.get_path_to(job)
	refs["coal_job"] = job
	refs["coal_pile"] = pile
	refs["firebox_hatch"] = hatch
	# --- zones that report the canon entry events
	_zone(P, "Zone_LighthouseEntered", Vector3(0.0, GF + 1.2, 1.3), Vector3(2.2, 2.4, 1.4), "LIGHTHOUSE_ENTERED", "")
	_zone(P, "Zone_EngineRoomEntered", Vector3(2.2, B1 + 1.0, 1.8), Vector3(2.4, 2.0, 1.2), "ENGINE_ROOM_ENTERED", "")
	# --- anchors moved to suit the new layout (the v3 markers were beside the old placeholder boxes)
	anchors["boiler_interaction"] = Vector3(-0.1, B1 + 0.15, 5.55)
	anchors["coal_pickup"] = Vector3(3.75, B1 + 0.15, 1.4)
	anchors["daniel"] = Vector3(4.0, B1 + 0.15, 3.4)
	anchors["shovel_rack"] = Vector3(4.1, B1 + 0.15, 1.05)


func _zone(P: Node3D, nm: String, at: Vector3, size: Vector3, event: String, after: String) -> Area3D:
	var z := Area3D.new()
	z.name = nm
	z.set_script(Zone)
	z.event_id = event
	z.size = size
	z.after_event = after
	z.position = K.p(at.x, at.y, at.z)
	P.add_child(z)
	return z


func KP(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, -z)


## A heap of coal as 'n' small tumbled lumps (one MultiMesh, no collision: the bin walls hold the player out).
func _coal_pile(P: Node3D, nm: String, cu: float, cv: float, base_y: float, radius: float, height: float, n: int, seed_v: int) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3(1, 1, 1)
	mm.mesh = bm
	mm.instance_count = n
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in n:
		var r := radius * sqrt(rng.randf())
		var a := rng.randf() * TAU
		var h := height * pow(maxf(0.0, 1.0 - r / radius), 1.2)
		var s := rng.randf_range(0.07, 0.17)
		var pos := KP(cu + cos(a) * r, base_y + h + s * 0.3, cv + sin(a) * r)
		var bs := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3(s, s * rng.randf_range(0.6, 1.0), s * rng.randf_range(0.8, 1.2)))
		mm.set_instance_transform(i, Transform3D(bs, pos))
	var mi := MultiMeshInstance3D.new()
	mi.name = nm
	mi.multimesh = mm
	mi.material_override = K.mats["coal"]
	P.add_child(mi)
	K.count += 1
