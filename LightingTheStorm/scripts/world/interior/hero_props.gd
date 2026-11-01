# hero_props.gd - the generated furniture that replaces the interior's box props (Lighthouse Finisher Agent, LHF-08).
# Each entry names a FAL model (Assets/Models/prop/lhi_*.glb, decimated by tools/decimate_props.gd), the floor footprint it stands on
# in the house frame (u, v, floor y), the way it faces, and the greybox nodes it replaces. The replaced boxes are only HIDDEN: their
# collision stays exactly as it was, and the interaction anchors, lights and tests that name them are untouched. The model is
# scaled to the footprint (or to a height), and stands on the floor with its pivot (the centre of its base) at the footprint's centre.
# Facing: `face` is the house-frame direction the model's front looks toward: "-v" toward the front wall/door, "+v" toward the back,
# "+u" east, "-u" west. The generated models' front is local +z, which in the frame is -v at yaw 0.
extends RefCounted

const PROP := "res://Assets/Models/prop/"
const GF := 0.97
const L1 := 5.2025
## The generated textures come out paler than the interior's palette (stone grey, slate, muted wood): this multiplies them down and
## warms them a touch so they sit in the room. 1 = as generated.
const TINT := Color(0.66, 0.62, 0.57)
const YAW := {"-v": 0.0, "+u": 90.0, "+v": 180.0, "-u": 270.0}

## id, model, centre u, centre v, floor y, footprint u, footprint v (0 = fit by height only), height (0 = from footprint), face,
## yaw jitter (degrees, so repeats do not look stamped), replaced node names (a trailing * matches a numbered family), and optionally `true` to stretch
## the model to the height on its own (a squat model that must stand taller than its footprint allows: the filing cabinet came out 0.71 m tall)
const ENTRIES := [
	["office_desk", "lhi_keeper_desk", -1.0, 6.275, GF, 1.5, 0.75, 0.7, "-v", 0.0, ["Office_DeskTop", "Office_DeskLeft", "Office_DeskRight", "Office_DeskBack"]],
	["office_chair", "lhi_keeper_chair", -0.975, 5.35, GF, 0.45, 0.45, 0.9, "+v", 3.0, ["Office_Chair_Seat", "Office_Chair_Back", "Office_Chair_Leg_*"], true],
	["office_cabinet", "lhi_filing_cabinet", 0.46, 6.39, GF, 0.52, 0.58, 1.25, "-u", 0.0, ["Office_Cabinet", "Office_CabinetDrawer_*"], true],
	["bed_0", "lhi_keeper_bed", -2.45, 4.325, L1, 1.0, 2.05, 0.75, "-v", 0.0, ["L1_BedFrame_0", "L1_BedMattress_0", "L1_BedBlanket_0", "L1_BedPillow_0", "L1_BedLeg_0_*"]],
	["bed_1", "lhi_keeper_bed", -2.45, 7.125, L1, 1.0, 2.05, 0.75, "-v", 0.0, ["L1_BedFrame_1", "L1_BedMattress_1", "L1_BedBlanket_1", "L1_BedPillow_1", "L1_BedLeg_1_*"]],
	["wardrobe", "lhi_wardrobe", -0.625, 6.95, L1, 0.6, 1.2, 1.95, "+u", 0.0, ["L1_Wardrobe", "L1_WardrobeDoorGap"]],
	["sea_chest", "lhi_sea_chest", -1.2, 8.325, L1, 1.0, 0.65, 0.5, "-v", 0.0, ["L1_SeaChest", "L1_SeaChestBand_a", "L1_SeaChestBand_b"]],
	["stove", "lhi_cast_iron_stove", 4.95, 6.45, L1, 0.8, 0.9, 0.95, "-u", 0.0, ["L1_Stove", "L1_StoveTop"]],
	["tub", "lhi_iron_bathtub", 0.725, 8.25, L1, 1.3, 1.3, 0.6, "-u", 0.0, ["L1_Tub", "L1_TubInside"]],
	["mess_table", "lhi_kitchen_table", 3.2, 5.65, L1, 1.4, 1.3, 0.68, "-v", 0.0, ["L1_MessTable", "L1_MessTableLeg_*"]],
	["telegraph", "lhi_telegraph_set", 1.22, 3.8, L1 + 0.78, 0.3, 0.6, 0.38, "-u", 0.0, ["L1_RadioSet"]],
	["lamp_office", "lhi_oil_lamp", -0.55, 6.3, GF + 0.8, 0.0, 0.0, 0.36, "-v", 0.0, ["Office_Lamp_Base", "Office_Lamp_Glass"]],
	["lamp_night", "lhi_oil_lamp", -2.65, 5.7, L1 + 0.55, 0.0, 0.0, 0.3, "+u", 0.0, ["L1_NightLampBase", "L1_NightLampGlass"]],
	["barrel_0", "lhi_oak_barrel", 5.15, 3.75, GF, 0.47, 0.47, 0.85, "-v", 0.0, ["Store_Barrel_0", "Store_BarrelBand_0", "Store_BarrelBand2_0"], true],
	["barrel_1", "lhi_oak_barrel", 5.15, 4.4, GF, 0.47, 0.47, 0.85, "-v", 0.0, ["Store_Barrel_1", "Store_BarrelBand_1", "Store_BarrelBand2_1"], true],
	["barrel_2", "lhi_oak_barrel", 5.15, 5.05, GF, 0.47, 0.47, 0.85, "-v", 0.0, ["Store_Barrel_2", "Store_BarrelBand_2", "Store_BarrelBand2_2"], true],
	["crate_0", "lhi_wooden_crate", 4.35, 5.9, GF, 0.62, 0.62, 0.7, "-u", 8.0, ["Store_Crate_0"]],
	["crate_1", "lhi_wooden_crate", 4.4, 5.85, GF + 0.7, 0.6, 0.6, 0.55, "-u", -12.0, ["Store_Crate_1"]],
	["crate_2", "lhi_wooden_crate", 4.3, 5.0, GF, 0.6, 0.6, 0.55, "-u", 15.0, ["Store_Crate_2"]],
	# three coats on the rail, far enough apart that they do not pass through each other (five at 0.5 m overlapped by 0.3 m); the other two greybox coats
	# are hidden with them
	["coat_0", "lhi_oilskin_coat", 2.7, 0.505, GF + 0.55, 0.0, 0.0, 1.25, "+v", 0.0, ["G_Coat_0", "G_CoatCollar_0", "G_Coat_1", "G_CoatCollar_1"]],
	["coat_2", "lhi_oilskin_coat", 3.55, 0.505, GF + 0.55, 0.0, 0.0, 1.2, "+v", -5.0, ["G_Coat_2", "G_CoatCollar_2", "G_Coat_3", "G_CoatCollar_3"]],
	["coat_4", "lhi_oilskin_coat", 4.4, 0.505, GF + 0.55, 0.0, 0.0, 1.25, "+v", -3.0, ["G_Coat_4", "G_CoatCollar_4"]],
]

## Replaced in place (T45, 1 Nov 2026): the model is fitted into the bounds of the greybox meshes it replaces (names may end in *), in their
## parent's frame (the house rooms or the tower landings), with its front toward `face` in that frame (+x, -x, +z, -z: away from the wall
## behind it, measured by ray) and its back against that side of the bounds. Options: "h" a height to fit instead of the bounds' (the mess
## benches' greybox is only the seat plank), "y0" the floor the model stands on, "yaw" extra degrees. The greybox is hidden; its collision stays.
const IN_PLACE := [
	# basement
	["switchboard", "lhi_switchboard", ["B_Switchboard", "B_Switchboard_*"], "-x", {}],
	["workbench", "lhi_workbench_vice", ["B_WorkBench", "B_Vice", "B_BenchTop"], "+z", {}],
	["tool_board", "lhi_tool_wall", ["B_ToolBoard", "B_Tool_*"], "+z", {}],
	["tool_rack", "lhi_tool_wall", ["B_ToolRack"], "+x", {}],
	["parts_shelf", "lhi_parts_shelf", ["B_PartsShelf*", "B_PartsPost*", "B_Part_*"], "+z", {}],
	["cistern", "lhi_water_cistern", ["B_Cistern", "B_CisternFeed", "B_CisternStrap*"], "+x", {}],
	["lobby_bench", "lhi_mess_bench", ["B_LobbyBench"], "-z", {}],
	["lobby_barrel", "lhi_oak_barrel", ["B_LobbyBarrel"], "+x", {}],
	# ground floor
	["bookcase", "lhi_bookcase_filled", ["Office_Shelf*", "Office_ShelfSide*", "Office_Book*"], "+x", {"y0": GF, "h": 2.25}],      # the greybox shelves hang from 1.47 m: the bookcase stands on the floor
	["chart_table", "lhi_chart_table", ["Office_ChartTable", "Office_ChartLeg*"], "+z", {}],      # long side along the greybox (x), so it faces +z
	["clock_office", "lhi_wall_clock", ["Office_Clock", "Office_ClockFace"], "+z", {}],
	["notice_board", "lhi_notice_board", ["G_NoticeBoard"], "+x", {}],
	["umbrella_stand", "lhi_umbrella_stand", ["G_UmbrellaStand", "G_Umbrella*"], "-x", {}],
	["boot_bench", "lhi_boot_bench", ["G_BootBench", "G_Boots*"], "-z", {}],
	["store_shelf", "lhi_store_shelf", ["Store_ShelfBoard*", "Store_ShelfPost*", "Store_Tin*"], "-x", {}],
	# first floor (keeper's quarters)
	["washstand", "lhi_washstand", ["L1_Basin", "L1_BasinBowl", "L1_BasinTap"], "-z", {}],
	["kitchen_counter", "lhi_kitchen_counter", ["L1_Counter", "L1_CounterTop", "L1_Sink", "L1_SinkTap"], "+x", {}],
	["nightstand", "lhi_nightstand", ["L1_Nightstand"], "+x", {}],
	["radio_desk", "lhi_radio_desk", ["L1_RadioDesk", "L1_RadioDial*", "L1_RadioKey"], "-x", {}],
	["radio_chair", "lhi_keeper_chair", ["L1_RadioChair", "L1_RadioChairLeg*"], "+x", {"h": 0.9, "y0": L1}],
	["mess_bench_a", "lhi_mess_bench", ["L1_MessBenchA"], "+z", {"h": 0.45, "y0": L1}],
	["mess_bench_b", "lhi_mess_bench", ["L1_MessBenchB"], "+z", {"h": 0.45, "y0": L1}],
	["clock_mess", "lhi_wall_clock", ["L1_MessClock", "L1_MessClockFace"], "-x", {}],
	["hall_shelf", "lhi_store_shelf", ["L1_HallShelf", "L1_HallShelfBoard*"], "-z", {}],
	["chart_table_l1", "lhi_chart_table", ["L1_ChartTable"], "+x", {}],
	["coat_ted", "lhi_oilskin_coat", ["L1_Coat_Ted"], "+z", {}],
	# the tower's L2 landing (control and diagnostics)
	["instrument_cabinet", "lhi_instrument_cabinet", ["L2_Cabinet", "L2_CabinetDial*", "L2_CabinetLamp*", "L2_CabinetSwitch"], "-x", {}],
	["locker", "lhi_steel_locker", ["L2_Locker", "L2_LockerDoor"], "-z", {}],
	["side_table", "lhi_kitchen_table", ["L2_Table"], "-z", {}],
	["barometer", "lhi_barometer", ["L2_Barometer", "L2_BarometerFace"], "-z", {}],
]
const FACE := {"+x": Vector3.RIGHT, "-x": Vector3.LEFT, "+z": Vector3.BACK, "-z": Vector3.FORWARD}

## Lamp fixtures (T45): the generated sconce or pendant is fitted round each lamp's glowing glass sphere ("<name>_Glass", which the light cards and
## the light itself key on, so it stays), and the old plate, cap or flex is hidden. A sconce's arm points from the plate out to the glass.
## Each model: where its glass globe sits in the model (measured from its near-white texels) and the globe's radius.
const LAMP_MODELS := {
	"sconce": ["lhi_wall_sconce", Vector3(-0.248, 0.326, 0.008), 0.18],      # the globe hangs at the arm's end, on the model's -x; the backplate is at +x
	"pendant": ["lhi_pendant_lamp", Vector3(0.017, 0.236, 0.002), 0.16],
}
## lamp name, model, the parts to hide
const LAMPS := [
	["B_Sconce_Boiler", "sconce", ["_Plate"]], ["B_Sconce_Engine", "sconce", ["_Plate"]], ["B_Sconce_Lobby", "sconce", ["_Plate"]],
	["G_Sconce_Front0", "sconce", ["_Plate"]], ["G_Sconce_Front1", "sconce", ["_Plate"]], ["G_Sconce_Tower", "sconce", ["_Plate"]],
	["G_TowerLamp", "sconce", ["_Plate"]], ["L1_TowerLamp", "sconce", ["_Plate"]], ["L2_LampA", "sconce", ["_Plate"]], ["L2_LampB", "sconce", ["_Plate"]],
	["L1_HallLamp", "pendant", ["_Cap"]], ["L1_HallLamp2", "pendant", ["_Cap"]], ["L1_HallLamp3", "pendant", ["_Cap"]],
	["L1_MessLamp", "pendant", ["_Cap", "Cord"]], ["L1_QuartersLamp", "pendant", ["_Cap"]], ["L1_WashLamp", "pendant", ["_Cap"]],
]
## Greybox that is simply taken away (collision stays): the wash room's towel rail and towel stuck out across its doorway (the "stick cutting
## through the bathroom", creator, 30 Oct / 1 Nov 2026), and the new washstand carries its own towel bar.
const HIDE_ONLY := ["L1_TowelRail", "L1_Towel"]
const GLASS_GROW := 1.12         # the old glass sphere stands just proud of the model's globe, so its glow shows through

var placed := {}                 # entry id -> the Node3D holder
var skipped := []                # entry ids whose model could not be loaded (the greybox stays)
var hidden := 0


func build(frame: Node3D) -> void:
	for e in ENTRIES:
		_place(frame, e)


## The IN_PLACE models, searched for under `rooms` (InteriorRooms: the house frame and the tower landings).
func build_in_place(rooms: Node3D) -> void:
	var meshes := rooms.find_children("*", "MeshInstance3D", true, false)
	for e in IN_PLACE:
		var nodes: Array = []
		for mi in meshes:
			for pat in e[2]:
				if String(mi.name).match(pat):
					nodes.append(mi)
					break
		if nodes.is_empty():
			skipped.append(e[0])
			continue
		_place_in(nodes, e)
	for l in LAMPS:
		_place_lamp(rooms, l)
	for nm in HIDE_ONLY:
		var n := rooms.find_child(nm, true, false) as Node3D
		if n:
			n.visible = false
			hidden += 1


func _place_lamp(rooms: Node3D, l: Array) -> void:
	var glass := rooms.find_child(str(l[0]) + "_Glass", true, false) as MeshInstance3D
	var lm: Array = LAMP_MODELS[l[1]]
	var ps := load(PROP + str(lm[0]) + ".glb") as PackedScene
	if glass == null or ps == null:
		skipped.append(l[0])
		return
	var parent := glass.get_parent() as Node3D
	var gb := _rel(glass, parent) * glass.get_aabb()
	var at := gb.get_center()
	var s := minf(gb.size.x, gb.size.z) * 0.5 / float(lm[2])
	var yaw := 0.0
	for tail in l[2]:
		var part := parent.get_node_or_null(str(l[0]) + str(tail)) as MeshInstance3D
		if part == null:
			continue
		if l[1] == "sconce":
			var out := at - (_rel(part, parent) * part.get_aabb()).get_center()      # from the plate on the wall out to the glass
			out.y = 0.0
			if out.length() > 0.01:
				yaw = atan2(out.z, -out.x)                                          # the model's -x (its arm) along `out`
		part.visible = false
		hidden += 1
	var holder := Node3D.new()
	holder.name = "Hero_" + str(l[0])
	holder.rotation.y = yaw
	holder.scale = Vector3.ONE * s
	parent.add_child(holder)
	var inst := ps.instantiate() as Node3D
	inst.name = "Model"
	holder.add_child(inst)
	holder.position = at - Basis(Vector3.UP, yaw) * (lm[1] as Vector3) * s
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF      # a lamp's own fixture would shadow its light
		_tint(mi as MeshInstance3D)
	glass.scale *= GLASS_GROW
	placed[l[0]] = holder


func _place_in(nodes: Array, e: Array) -> void:
	var ps := load(PROP + str(e[1]) + ".glb") as PackedScene
	if ps == null:
		skipped.append(e[0])
		return
	var parent := (nodes[0] as Node3D).get_parent() as Node3D
	var box := AABB()
	for i in nodes.size():
		var m := nodes[i] as MeshInstance3D
		var b := _rel(m, parent) * m.get_aabb()
		box = b if i == 0 else box.merge(b)
	var opts: Dictionary = e[4]
	var face: Vector3 = FACE[e[3]]
	var inst := ps.instantiate() as Node3D
	inst.name = "Model"
	var mb := _bounds(inst)
	if mb.size.y <= 0.0001:
		skipped.append(e[0])
		inst.free()
		return
	var yaw := atan2(face.x, face.z) + deg_to_rad(float(opts.get("yaw", 0.0)))
	var quarter := absf(sin(yaw)) > 0.5                     # turned 90 degrees: the model's x runs along the frame's z
	var msz := Vector3(mb.size.z if quarter else mb.size.x, mb.size.y, mb.size.x if quarter else mb.size.z)
	# fit inside the bounds, ignoring a side under 15 cm (a board on a wall has almost no depth); the short side may run over by a third
	var ratios: Array = []
	for a in [0, 2]:
		if box.size[a] >= 0.15:
			ratios.append(box.size[a] / msz[a])
	ratios.sort()
	var s := 1.0
	if ratios.size() == 2:
		s = minf(ratios[1], ratios[0] * 1.35)
	elif ratios.size() == 1:
		s = ratios[0]
	var h := float(opts.get("h", box.size.y))
	s = minf(s, h / msz.y * 1.15) if ratios.size() > 0 else h / msz.y
	var y0 := float(opts.get("y0", box.position.y))
	# the model's base centre on the bounds' bottom centre, then slid back so its back meets the bounds' back
	var c := box.get_center()
	var axis := 0 if absf(face.x) > 0.5 else 2
	var back := c[axis] - face[axis] * box.size[axis] * 0.5
	c[axis] = back + face[axis] * msz[axis] * s * 0.5
	var holder := Node3D.new()
	holder.name = "Hero_" + str(e[0])
	holder.rotation.y = yaw
	holder.scale = Vector3.ONE * s
	parent.add_child(holder)
	holder.add_child(inst)
	var pivot := Basis(Vector3.UP, yaw) * (mb.get_center() * Vector3(1, 0, 1) + Vector3(0, mb.position.y, 0)) * s
	holder.position = Vector3(c.x, y0, c.z) - pivot
	for g in inst.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		_tint(mi as MeshInstance3D)
	placed[e[0]] = holder
	for n in nodes:
		(n as Node3D).visible = false
		hidden += 1


## `n`'s transform relative to `to` (an ancestor), without needing the scene tree.
func _rel(n: Node3D, to: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var p: Node = n
	while p != null and p != to:
		if p is Node3D:
			t = (p as Node3D).transform * t
		p = p.get_parent()
	return t


func _place(frame: Node3D, e: Array) -> void:
	var path: String = PROP + str(e[1]) + ".glb"
	var ps := load(path) as PackedScene
	if ps == null:
		skipped.append(e[0])
		return
	var inst := ps.instantiate() as Node3D
	inst.name = "Model"
	var box := _bounds(inst)
	if box.size.y <= 0.0001:
		skipped.append(e[0])
		inst.free()
		return
	var yaw: float = YAW[e[8]] + float(e[9])
	var fu: float = e[5]
	var fv: float = e[6]
	var h: float = e[7]
	var s := 1.0
	if h > 0.0 and (fu <= 0.0 or fv <= 0.0):
		s = h / box.size.y                                  # a height-fitted prop (coats, barrels, lamps)
	elif fu > 0.0 and fv > 0.0:
		# fit the footprint: the model's long side along the footprint's long side
		var long_model := maxf(box.size.x, box.size.z)
		var long_fp := maxf(fu, fv)
		var swap := (box.size.x > box.size.z) != (fu > fv) and absf(box.size.x - box.size.z) > 0.1 * long_model
		if swap:
			yaw += 90.0
		s = minf(long_fp / long_model, (minf(fu, fv) / minf(box.size.x, box.size.z)) * 1.35)
		if h > 0.0:
			s = minf(s, h / box.size.y * 1.15)
	var holder := Node3D.new()
	holder.name = "Hero_" + str(e[0])
	holder.position = Vector3(float(e[2]), float(e[4]), -float(e[3]))      # kit.gd p(): z = -v
	holder.rotation.y = deg_to_rad(yaw)
	holder.scale = Vector3.ONE * s
	if e.size() > 11 and e[11] and h > 0.0:
		holder.scale.y = h / box.size.y
	frame.add_child(holder)
	holder.add_child(inst)
	for g in inst.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		_tint(mi as MeshInstance3D)
	placed[e[0]] = holder
	for nm in e[10]:
		_hide(frame, nm)


## Hide the greybox nodes the model replaces (a name ending in * hides a numbered family). Collision stays.
func _hide(frame: Node3D, nm: String) -> void:
	if nm.ends_with("*"):
		var stem := nm.trim_suffix("*")
		for n in frame.find_children(stem + "*", "MeshInstance3D", true, false):
			(n as Node3D).visible = false
			hidden += 1
	else:
		var n := frame.find_child(nm, true, false) as Node3D
		if n:
			n.visible = false
			hidden += 1


func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var b := mi.mesh.get_aabb()
		var tr := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != root.get_parent():
			if p is Node3D:
				tr = (p as Node3D).transform * tr
			p = p.get_parent()
		b = tr * b
		box = b if first else box.merge(b)
		first = false
	return box


var _tinted := {}                # source material -> tinted duplicate (shared by every instance of a model)


func _tint(mi: MeshInstance3D) -> void:
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i) as StandardMaterial3D
		if m == null:
			continue
		if not _tinted.has(m):
			var d := m.duplicate() as StandardMaterial3D
			d.albedo_color = d.albedo_color * TINT
			_tinted[m] = d
		mi.set_surface_override_material(i, _tinted[m])
