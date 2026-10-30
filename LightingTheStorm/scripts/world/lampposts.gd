# lampposts.gd - the gas street lamps on the docks (backlog T36; creator, 31 Oct 2026): two on the island dock, one either side of the
# opening of the harbour (the tips of the two jetties), and one at the Saltgate quay where the launch docks. One node in Level.tscn;
# the posts, their spots and their light are in data/world/lampposts.json. Each post is the imported Meshy model
# (Assets/Models/lamppost/lamppost.glb, 3.4 m, pivot at the base) standing on the ground (found by a ray down at the first physics
# frame), with a small collider so nobody walks through it, an emissive lamp head (fog-proof, so it reads from the sea) and a warm
# OmniLight that flickers a little like gas. A light is only switched on while the player is within light_range_m, which keeps the
# number of live lights down (the Lighting agent's budget is max_dynamic_lights in lighting_spec.json).
extends Node3D

const SPEC_PATH := "res://data/world/lampposts.json"

var spec: Dictionary = {}
var posts: Array = []       # {node, light, head, base_energy, phase}
var _t := 0.0


func _ready() -> void:
	var f := FileAccess.open(SPEC_PATH, FileAccess.READ)
	if f == null:
		push_error("lampposts: cannot read %s" % SPEC_PATH)
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	spec = d
	await get_tree().physics_frame
	await get_tree().physics_frame
	for p in spec["posts"]:
		_make(p)


func _ground_y(x: float, z: float, near_y: float) -> float:
	var space := get_world_3d().direct_space_state
	var best := near_y
	var top := near_y + 6.0
	for _i in 12:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, near_y - 8.0, z))
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var y: float = hit["position"].y
		if hit["normal"].y > 0.7 and y <= near_y + 1.5 and y >= near_y - 3.0:
			return y
		top = y - 0.05
	return best


func _make(p: Dictionary) -> void:
	var l: Dictionary = spec["lamp"]
	var y := _ground_y(float(p["x"]), float(p["z"]), float(p["y"]))
	var root := Node3D.new()
	root.name = String(p["id"])
	root.position = Vector3(float(p["x"]), y, float(p["z"]))
	root.rotation.y = deg_to_rad(float(p.get("yaw_deg", 0.0)))
	add_child(root)
	var ps := load(String(spec["model"])) as PackedScene
	if ps:
		root.add_child(ps.instantiate())
	else:
		push_warning("lampposts: %s did not load" % spec["model"])
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = float(l["collider_radius_m"])
	cyl.height = float(l["height_m"])
	cs.shape = cyl
	cs.position = Vector3(0, float(l["height_m"]) * 0.5, 0)
	body.add_child(cs)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = float(l["head_radius_m"])
	sph.height = float(l["head_radius_m"]) * 2.0
	sph.radial_segments = 8
	sph.rings = 4
	head.mesh = sph
	head.position = Vector3(0, float(l["light_height_m"]), 0)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var col := Color(float(l["colour"][0]), float(l["colour"][1]), float(l["colour"][2]))
	hm.albedo_color = col
	hm.emission_enabled = true
	hm.emission = col
	hm.emission_energy_multiplier = float(l["head_emission"])
	hm.disable_fog = true
	head.material_override = hm
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(head)
	var light := OmniLight3D.new()
	light.position = Vector3(0, float(l["light_height_m"]), 0)
	light.light_color = col
	light.light_energy = float(l["energy"])
	light.omni_range = float(l["range_m"])
	light.omni_attenuation = float(l["attenuation"])
	light.shadow_enabled = false
	root.add_child(light)
	posts.append({"node": root, "light": light, "head": head, "base": float(l["energy"]), "phase": randf() * 6.28})


func _process(delta: float) -> void:
	if posts.is_empty():
		return
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var range_m := float(spec["lamp"]["light_range_m"])
	for p in posts:
		var light: OmniLight3D = p["light"]
		var on := player == null or player.global_position.distance_to((p["node"] as Node3D).global_position) < range_m
		light.visible = on
		(p["head"] as MeshInstance3D).visible = true
		var flick := 1.0 + 0.06 * sin(_t * 7.0 + float(p["phase"])) + 0.04 * sin(_t * 13.1 + float(p["phase"]) * 2.0)
		light.light_energy = float(p["base"]) * flick
