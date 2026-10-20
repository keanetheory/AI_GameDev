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
	var lantern = Lantern.new()
	lantern.build_lantern(kit, self)
	for role in lantern.anchors_lh:
		anchors[role] = to_global(lantern.anchors_lh[role])
	refs.merge(lantern.refs)
	var mgr := get_parent().get_node_or_null("LighthouseInteriorLights")
	if mgr and mgr.has_method("adopt"):
		for l in kit.lights:
			mgr.adopt(l)
	build_ms = Time.get_ticks_msec() - t0
	node_count = kit.count


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
		if REPLACED.has(nm):
			mi.get_parent().remove_child(mi)
			mi.queue_free()
			continue
		for rule in RESKIN:
			if nm.contains(rule[0]):
				var key: String = rule[1]
				if not cache.has(key):
					var m: StandardMaterial3D = (kit.mats[key] as StandardMaterial3D).duplicate()
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
					cache[key] = m
				mi.material_override = cache[key]
				break
