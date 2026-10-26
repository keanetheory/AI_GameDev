# interior_rooms.gd - builds the lighthouse interior's rooms, props and fittings (Lighthouse Interior Creator Agent).
# The greybox shell (Assets/Models/lighthouse/interior/lighthouse_greybox_v3.glb, node LighthouseInterior) supplies the
# floors, walls, stairs and tower spiral. This node, at the same origin, adds everything that makes them rooms:
#   rooms_house.gd  - the ground floor (vestibule, hall, posters, office, storage) and basement (coal store, boiler room,
#                     steam engine and dynamo, workshop, wall voids)
#   rooms_tower.gd  - the first floor (keeper's quarters) and the tower landings
#   lantern.gd      - the lamp room: glass all round, the arc lamp, the burner socket
# Put one node of this script in Level.tscn after LighthouseInterior and before InteriorAnchors.
# Everything is placed in the house frame (kit.gd): u along the front wall, v inward from the door, y local height.
extends Node3D

const Kit := preload("res://scripts/world/interior/kit.gd")
const House := preload("res://scripts/world/interior/rooms_house.gd")
const Tower := preload("res://scripts/world/interior/rooms_tower.gd")
const Lantern := preload("res://scripts/world/interior/lantern.gd")
const Spiral := preload("res://scripts/world/interior/spiral_down.gd")
const Shell := preload("res://scripts/world/interior/tower_shell.gd")
const RoofLiner := preload("res://scripts/world/interior/roof_liner.gd")
const HeroProps := preload("res://scripts/world/interior/hero_props.gd")
const Trim := preload("res://scripts/world/interior/trim.gd")

const DOOR_SILL := Vector3(-3.494, 0.0, 8.874)   # the entry door's sill, x/z in the lighthouse frame
const YAW := 0.4457                              # atan2(0.4309, 0.9024): turns +x onto the house's front wall

## v3 greybox parts that the furnished rooms replace.
const REPLACED := ["B1_boiler_placeholder", "B1_coal_pile_placeholder", "B1_dynamo_placeholder", "G_office_counter"]
## First match wins: part-name fragment -> material (kit.gd). Gives the greybox walls and floors real surfaces.
const RESKIN := [
	["G_floor_west", "planks"], ["G_floor", "flags"], ["G_tower_link", "flags"], ["B1_floor", "flags_dark"],
	["B1_stair", "stone"], ["B1_switchback", "stone"], ["Tower_spiral_step", "stone"], ["Tower_ground_floor", "flags"],
	["Tower_inner_guard_core", "stone"], ["Lantern_gallery", "wood_dark"], ["Lantern_arc_lamp_mount", "iron_dark"],
	["B1_", "brick"], ["G_", "plaster"],
]

var kit
var frame: Node3D
var house
var anchors := {}           # role -> world position, for interior_anchors.gd
var refs := {}
var trim                          # trim.gd: skirting, cornice, architraves, hearth
var hero_props                    # hero_props.gd: the generated furniture
var roof_liner: Node3D           # roof_liner.gd: the first floor's ceiling
var build_ms := 0            # how long the build took, for tools/test_interior_budget.gd
var node_count := 0          # nodes the kit made


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	frame = Node3D.new()
	frame.name = "HouseFrame"
	frame.position = Vector3(DOOR_SILL.x, 0.0, DOOR_SILL.z)
	frame.rotation.y = YAW
	add_child(frame)
	kit = Kit.new(frame)
	if Tower.shell_mode() != 0:
		kit.shell_spec = Tower.shell_spec()
	_prepare_greybox()
	house = House.new()
	house.build(kit, frame)
	for role in house.anchors:
		var a: Vector3 = house.anchors[role]
		anchors[role] = kit.world(a.x, a.y, a.z)
	refs.merge(house.refs)
	var tower = Tower.new()
	tower.build(kit, frame, self)
	for role in tower.anchors:
		var t: Vector3 = tower.anchors[role]
		anchors[role] = kit.world(t.x, t.y, t.z)
	for role in tower.anchors_lh:
		anchors[role] = to_global(tower.anchors_lh[role])
	refs.merge(tower.refs)
	var shell = Shell.new()
	shell.build_shell(kit, self)
	if shell.authored:
		_add_authored_shell()
	var spiral = Spiral.new()
	spiral.build_spiral(kit, frame, self)
	for role in spiral.anchors:
		var sp: Vector3 = spiral.anchors[role]
		anchors[role] = kit.world(sp.x, sp.y, sp.z)
	var lantern = Lantern.new()
	lantern.build_lantern(kit, self)
	for role in lantern.anchors_lh:
		anchors[role] = to_global(lantern.anchors_lh[role])
	refs.merge(lantern.refs)
	trim = Trim.new()
	trim.build(kit, frame)
	hero_props = HeroProps.new()
	hero_props.build(frame)
	if not shell.authored:      # the authored roof has its own underside: no liner
		roof_liner = Node3D.new()
		roof_liner.set_script(RoofLiner)
		roof_liner.name = "RoofLiner"
		add_child(roof_liner)
		roof_liner.build(frame, kit.mats["plaster_dark"])
	var mgr := get_parent().get_node_or_null("LighthouseInteriorLights")
	if mgr and mgr.has_method("adopt"):
		for l in kit.lights:
			mgr.adopt(l)
	build_ms = Time.get_ticks_msec() - t0
	node_count = kit.count


## The authored tower shell (build_tower_shell_v1.py), in place of the exterior mesh's tower. Experiment, LHF_SHELL=1.
func _add_authored_shell() -> void:
	var full := Tower.shell_mode() == 2
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_file("res://Assets/Models/lighthouse/shell/lighthouse_shell_v1.glb" if full else "res://Assets/Models/lighthouse/shell/lighthouse_tower_shell_v1.glb", st)
	var sh := doc.generate_scene(st) as Node3D
	sh.name = "LighthouseShell"
	var lh := get_parent().get_node("Lighthouse")
	lh.add_child(sh)
	# the shell's faces carry four materials (build_shell_v1.py): outside stone, roof, room plaster, basement brick
	var ext_stone := (kit.mats["stone"] as StandardMaterial3D).duplicate() as StandardMaterial3D
	ext_stone.albedo_color = Color(0.46, 0.44, 0.42)
	var roof := (kit.mats["flags_dark"] as StandardMaterial3D).duplicate() as StandardMaterial3D
	roof.albedo_color = Color(0.16, 0.18, 0.22)
	# at night the outside is lit by the moon alone and read as a black cut-out: a faint cold glow of its own texture keeps the stone and slate visible
	for om in [ext_stone, roof]:
		(om as StandardMaterial3D).emission_enabled = true
		(om as StandardMaterial3D).emission = Color(0.5, 0.6, 0.78)
		(om as StandardMaterial3D).emission_texture = (om as StandardMaterial3D).albedo_texture
		(om as StandardMaterial3D).emission_energy_multiplier = 0.1
	ext_stone.set_meta("base_albedo", true)      # (toon_look.gd: no interior fill on the outside of the building)
	roof.set_meta("base_albedo", true)
	var by_name := {"shell_stone": ext_stone, "shell_roof": roof, "shell_plaster": kit.mats["plaster"], "shell_brick": kit.mats["brick"]}
	for mi in sh.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var order := [ext_stone, kit.mats["plaster"], kit.mats["brick"], roof]      # the glb's surfaces come out in the material slot order of build_shell_v1.py
		for i in mini(m3.mesh.get_surface_count(), order.size()):
			var sm: Material = m3.mesh.surface_get_material(i)
			var nm: String = sm.resource_name if sm else ""
			var k: int = by_name.keys().find(nm) if by_name.has(nm) else i
			m3.set_surface_override_material(i, by_name[nm] if by_name.has(nm) else order[i])
		if OS.get_environment("LHF_SHELL_SHADOW") == "off":
			m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m3.create_trimesh_collision()
	if full:
		# the shell replaces the exterior mesh and the greybox's thin walls and floors (its partitions stay)
		var cv := lh.get_node_or_null("convert")
		if cv:
			cv.visible = false
			for body in cv.find_children("*", "CollisionObject3D", true, false):
				(body as CollisionObject3D).collision_layer = 0
		var gb := get_parent().get_node_or_null("LighthouseInterior")
		if gb:
			for n in gb.find_children("*", "Node3D", true, false):
				var nm := String(n.name)
				if nm.begins_with("G_floor") or nm.begins_with("G_front_wall") or nm.begins_with("G_outer") or nm.begins_with("G_back_wall") or nm.begins_with("B1_floor") or nm.begins_with("B1_rear_wall") or nm.begins_with("B1_west_wall") or nm.begins_with("B1_east_wall") or nm.begins_with("B1_front_wall") or nm.begins_with("G_tower_link"):
					n.visible = false
					for body in n.find_children("*", "CollisionObject3D", true, false):
						(body as CollisionObject3D).collision_layer = 0


## Remove the v3 placeholders the new props replace, and give the remaining greybox its surfaces.
func _prepare_greybox() -> void:
	var gb := get_parent().get_node_or_null("LighthouseInterior")
	if gb == null:
		push_warning("interior_rooms: LighthouseInterior not found")
		return
	var cache := {}
	for node in gb.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var nm := String(mi.name)
		if REPLACED.has(nm) or nm.begins_with("B1_stair_") or nm.begins_with("B1_switchback") or nm.begins_with("Tower_spiral_step_"):
			mi.get_parent().remove_child(mi)
			mi.queue_free()
			continue
		if OS.get_environment("LHF_HIDE") != "" and OS.get_environment("LHF_HIDE").split(",").has(nm):
			mi.visible = false      # triage switch: name the greybox parts to hide
		for rule in RESKIN:
			if nm.contains(rule[0]):
				var key: String = rule[1]
				if not cache.has(key):
					var m: StandardMaterial3D = (kit.mats[key] as StandardMaterial3D).duplicate()
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
					cache[key] = m
				mi.material_override = cache[key]
				break
