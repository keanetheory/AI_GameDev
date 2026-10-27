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

var placed := {}                 # entry id -> the Node3D holder
var skipped := []                # entry ids whose model could not be loaded (the greybox stays)
var hidden := 0


func build(frame: Node3D) -> void:
	for e in ENTRIES:
		_place(frame, e)


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
