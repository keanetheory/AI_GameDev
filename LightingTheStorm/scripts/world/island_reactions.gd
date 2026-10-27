# island_reactions.gd - Bracken Isle reacts to the storm (Island Creator ISL-05, creator 2026-10-27).
# Three cheap effects, all driven by the Wave agent's sea state (Sea.state, 0..5) and the reduced-intensity preset (Sea.intensity), no lights:
#   - wet rock: the island's rock materials get darker and glossier as the sea rises (albedo towards 72%, roughness down to 0.35);
#   - darker faces: the same darkening is the "darker faces" of the storm (the toon step keeps them flat, ToonLook);
#   - shoreline spray: a ring of spray bursts at the waterline round the rock, from a faint mist in calm water to a wall of spray in a storm.
#     The harbour side (the jetties and the stone quay, bearings 110 to 160 from the island's centre) is left clear so the dock reads.
# Put one node of this script in Level.tscn after the Island and the Sea. The spray points are the island's waterline, measured with rays
# at sea level from outside (27 Oct 2026); move them if the island moves.
extends Node3D

const Sea := preload("res://scripts/world/sea.gd")

@export var rock_paths: Array[NodePath] = [NodePath("../Island"), NodePath("../RockPatchSE"), NodePath("../RockPatchSE2"), NodePath("../RockPatchNE")]
## How dark the wettest rock gets (fraction of its dry colour) and how glossy (roughness).
@export_range(0.3, 1.0) var wet_albedo := 0.72
@export_range(0.05, 1.0) var wet_roughness := 0.35
## World (x, z) of each spray burst: the island's waterline every 20 degrees, harbour side left out.
const SPRAY_AT := [Vector2(32.6, 15.7), Vector2(28.0, 29.7), Vector2(8.9, 40.2), Vector2(-5.0, 33.3), Vector2(-34.1, 7.1),
		Vector2(-37.5, -3.7), Vector2(-23.2, -13.3), Vector2(-24.4, -31.6), Vector2(-12.6, -41.0), Vector2(2.6, -41.4),
		Vector2(17.0, -36.1), Vector2(35.0, -31.6), Vector2(43.7, -15.7), Vector2(35.4, -5.1)]
const WATER_Y := 0.4

var wetness := 0.0                       # 0 dry .. 1 soaked, smoothed; read by tests
var spray: Array[GPUParticles3D] = []
var _rock: Array = []                    # [StandardMaterial3D, dry albedo, dry roughness]


func _ready() -> void:
	_collect_rock.call_deferred()        # after ToonLook has switched the materials (it records their originals first)
	for p in SPRAY_AT:
		_spray_at(Vector3(p.x, WATER_Y, p.y))


func _collect_rock() -> void:
	var seen := {}
	for path in rock_paths:
		var root := get_node_or_null(path)
		if root == null:
			continue
		for n in root.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			for i in mi.mesh.get_surface_count():
				for m in [mi.get_surface_override_material(i), mi.mesh.surface_get_material(i), mi.material_override]:
					if m is StandardMaterial3D and not seen.has(m):
						seen[m] = true
						_rock.append([m, (m as StandardMaterial3D).albedo_color, (m as StandardMaterial3D).roughness])


## How wet the sea state makes the rock: dry at 1 (calm), soaked from 4 up, scaled by the reduced-intensity preset.
static func target_wetness(state: float, intensity: float) -> float:
	return clampf((state - 1.0) / 3.0, 0.0, 1.0) * clampf(intensity, 0.0, 1.0)


func _process(delta: float) -> void:
	var r := clampf(Sea.state / 5.0, 0.0, 1.0) * clampf(Sea.intensity, 0.0, 1.0)
	for p in spray:
		p.amount_ratio = lerpf(0.05, 1.0, r * r)
	wetness = move_toward(wetness, target_wetness(Sea.state, Sea.intensity), delta * 0.1)      # rock dries and soaks over about ten seconds
	for e in _rock:
		var m: StandardMaterial3D = e[0]
		if not is_instance_valid(m):
			continue
		var dry: Color = e[1]
		m.albedo_color = Color(dry.r, dry.g, dry.b, dry.a).lerp(Color(dry.r * wet_albedo, dry.g * wet_albedo, dry.b * wet_albedo, dry.a), wetness)
		m.roughness = lerpf(float(e[2]), minf(float(e[2]), wet_roughness), wetness)


func _spray_at(pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.name = "Spray_%d" % spray.size()
	p.amount = 28
	p.lifetime = 1.6
	p.visibility_aabb = AABB(Vector3(-10, -2, -10), Vector3(20, 18, 20))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 30.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 7.0
	pm.gravity = Vector3(0, -5.0, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3.0, 0.2, 3.0)
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.5))
	grad.set_color(1, Color(0.85, 0.92, 1.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(2.4, 2.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _soft_dot()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.9, 0.95, 1.0, 1.0)
	quad.material = mat
	p.draw_pass_1 = quad
	p.position = pos
	p.amount_ratio = 0.05
	add_child(p)
	spray.append(p)


var _dot: ImageTexture


func _soft_dot() -> ImageTexture:
	if _dot:
		return _dot
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 15.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) * clampf(1.0 - d, 0.0, 1.0)))
	_dot = ImageTexture.create_from_image(img)
	return _dot
