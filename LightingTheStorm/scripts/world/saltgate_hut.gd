# saltgate_hut.gd - the walk-in equipment hut on the Saltgate dock (backlog T49): the generated open-fronted shed (slt_equipment_hut.glb),
# scaled to `width_m` across its front, its floor on the node's origin (dock level) and its open front toward the node's -z, on the edge of
# the landing strip. Its back stands over the water where the stone pier head was (carved out of the Saltgate quay), on timber piles.
# Lit inside by one warm lamp under the roof; the rain is kept out by a box of its interior air added to the RainShelter volumes (the
# rain shader discards drops inside them). Walkable: a trimesh collider from the model itself (walls, floor, roof, the workbench),
# physics layer 1. Runtime only, like the other generated set pieces.
extends Node3D

@export_file("*.glb") var model_path := "res://Assets/Models/prop/slt_equipment_hut.glb"
## Across the open front, metres.
@export var width_m := 3.4
## The generated textures are paler than the Saltgate's dark palette (as hero_props.gd TINT).
@export var tint := Color(0.62, 0.6, 0.58)
## A lantern's worth of warm light under the roof, so the inside reads at night (one light, no shadows: inside the Lighting budget,
## max_dynamic_lights 18, since only the Saltgate lamppost is lit near it).
@export var lamp_energy := 1.6
@export var lamp_range := 4.5
## Timber piles under the floor, down into the sea: their bottom, and their radius.
@export var pile_bottom_y := -2.5
@export var pile_radius := 0.14
## How far the plank deck runs out past the open front, onto the landing strip (no gap or lip at the door).
@export var deck_apron := 0.95      # under the strip too: its scanned planks have slits by the landing point (15-45 cm)
## The interior air, inset from the walls and under the roof, as a share of the hut's width, height and depth.
@export var rain_air := Vector3(0.9, 0.92, 0.9)

var model: Node3D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var ps := load(model_path) as PackedScene
	if ps == null:
		push_warning("saltgate_hut: %s did not load" % model_path)
		return
	model = ps.instantiate() as Node3D
	model.name = "Model"
	var box := _bounds(model)
	var s := width_m / maxf(box.size.x, 0.01)
	model.scale = Vector3.ONE * s
	model.rotation.y = PI                       # the model's open front is its +z; the node's front is -z
	model.position = Vector3(box.get_center().x * s, -box.position.y * s, box.get_center().z * s)
	add_child(model)
	var lamp := OmniLight3D.new()
	lamp.name = "HutLamp"
	lamp.light_color = Color(1.0, 0.72, 0.42)
	lamp.light_energy = lamp_energy
	lamp.omni_range = lamp_range
	lamp.shadow_enabled = false
	lamp.position = Vector3(0.0, box.size.y * s * 0.62, 0.3)       # under the ridge, a little in from the open front
	add_child(lamp)
	_deck(box.size * s)
	_piles(box.size * s)
	_keep_rain_out(box.size * s)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
			if mat:
				var d := mat.duplicate() as StandardMaterial3D
				d.albedo_color = d.albedo_color * tint
				m.set_surface_override_material(i, d)
		m.create_trimesh_collision()
		for c in m.get_children():
			if c is StaticBody3D:
				(c as StaticBody3D).collision_layer = 1
				for sh in c.get_children():
					var cs := (sh as CollisionShape3D).shape as ConcavePolygonShape3D
					if cs:
						cs.backface_collision = true


func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var t := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != root:
			t = (p as Node3D).transform * t
			p = p.get_parent()
		var b := t * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## A plank deck under the whole hut and a little way out of the door: the generated model only half has a floor (none by the open
## front, none across one side), which the stone pier head used to hide; over the water the player fell through. Solid, layer 1.
func _deck(size: Vector3) -> void:
	var depth := size.z + deck_apron
	var mi := MeshInstance3D.new()
	mi.name = "Deck"
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.14, depth)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.27, 0.2, 0.14)
	mat.roughness = 0.95
	mi.material_override = mat
	mi.position = Vector3(0.0, -0.075, -deck_apron * 0.5)     # top just under the model's own floor boards; the apron is at the front (-z)
	add_child(mi)
	var body := StaticBody3D.new()
	body.name = "DeckBody"
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = bm.size
	cs.shape = sh
	body.add_child(cs)
	mi.add_child(body)


## Piles at the corners, the middle of each side and under the floor's middle, from the floor down into the water.
func _piles(size: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.15, 0.11)
	mat.roughness = 0.95
	var hx := size.x * 0.5 - pile_radius
	var hz := size.z * 0.5 - pile_radius
	var top := 0.05
	var length := top - (pile_bottom_y - global_position.y)
	var k := 0
	for x in [-hx, 0.0, hx]:
		for z in [-hz, 0.0, hz]:
			var pile := MeshInstance3D.new()
			pile.name = "Pile_%d" % k
			var cyl := CylinderMesh.new()
			cyl.top_radius = pile_radius
			cyl.bottom_radius = pile_radius * 1.1
			cyl.height = length
			cyl.radial_segments = 8
			pile.mesh = cyl
			pile.material_override = mat
			pile.position = Vector3(x, top - length * 0.5, z)
			add_child(pile)
			k += 1


## The hut's interior air as a rain shelter volume (rain_shelter.gd), handed to the rain by the LightingRig.
func _keep_rain_out(size: Vector3) -> void:
	var rs := get_node_or_null("../RainShelter")
	if rs == null or not ("volumes" in rs):
		push_warning("saltgate_hut: no RainShelter: the rain will fall inside the hut")
		return
	var air := Vector3(size.x * rain_air.x, size.y * rain_air.y, size.z * rain_air.z)
	rs.volumes.append({"xf": global_transform * Transform3D(Basis(), Vector3(0.0, air.y * 0.5, 0.0)), "size": air, "name": "SaltgateHut"})
	var rig := get_node_or_null("../LightingRig")
	if rig and rig.has_method("apply_rain_shelters"):
		call_deferred("_apply_rain", rig)               # after the rig has built its rain, if it has not yet


func _apply_rain(rig: Node) -> void:
	if rig.get("_rain") != null:                        # no rain in a headless test run
		rig.apply_rain_shelters()
