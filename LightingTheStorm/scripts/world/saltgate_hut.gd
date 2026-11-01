# saltgate_hut.gd - the walk-in equipment hut on the Saltgate pier head (backlog T49): the generated open-fronted shed
# (slt_equipment_hut.glb), scaled to `width_m` across its front, its floor on the node's origin and its open front toward the node's -z.
# Lit inside by one warm lamp under the roof; the rain is kept out by a box of its interior air added to the RainShelter volumes (the
# rain shader discards drops inside them). Walkable: a trimesh collider from the model itself (walls, floor, roof, the bench),
# physics layer 1. The stone steps up to the pier head are a stone_stairs.gd node in Level.tscn (SaltgateHutSteps). Runtime only,
# like the other generated set pieces.
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
