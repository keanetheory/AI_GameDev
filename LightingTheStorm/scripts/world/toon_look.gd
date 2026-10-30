# toon_look.gd - the cel-shaded look for the whole lighthouse (Lighthouse Finisher Agent, LHF-10; approved by the creator 2026-10-24
# after the basement sample). Style guide: gritty dark cel-shaded, heavy ink outlines, flat cel shading with hard-edged shadows.
#   - every material on the interior's meshes (all floors, the tower, the lamp room) is switched to toon diffuse (a hard light/dark
#     step) with no specular glints. The materials are changed IN PLACE and their originals remembered, so the scripts that hold a
#     reference to one (the lamp's lens, the switchboard lamp, the coal job) keep working;
#   - the exterior's wall shader is switched to toon by exterior_wall_detail.gd (set_toon);
#   - a full-screen ink outline (toon_outline.gdshader) on a quad parented to the camera, drawn whenever the camera is near the
#     lighthouse, masked in world space to the lighthouse itself so the island and the sea are not outlined.
# Key F8 switches it on and off in play, to compare. `enabled` is the starting state. One node in Level.tscn after InteriorRooms.
extends Node

const OUTLINE_SHADER := preload("res://scripts/world/toon_outline.gdshader")

@export var enabled := true
## The lighthouse in world space (the outline is only drawn within this cylinder, and only while the camera is near it).
@export var mask_centre := Vector3(4.9, 20.0, -4.2)
@export var mask_radius := 12.0
@export var mask_half_height := 14.0
@export var camera_range := 130.0
## The ink: thickness in pixels at 1080p. 1.2 since 27 Oct 2026 (creator: "thinner and darker"; it was 1.8).
@export var ink_thickness := 1.2
## The ink's colour: a neutral near-black charcoal (creator, 27 Oct 2026: darker, and not the navy blue it was, (0.004, 0.006, 0.016)). Still not
## pure black, so it reads as ink against the darkest shadows. Set from here it is an sRGB colour (the shader's source_color hint converts it):
## (0.04, 0.04, 0.045) draws as about (10, 10, 11) on screen.
@export var ink_colour := Color(0.04, 0.04, 0.045)
## How hard the light/dark step is: lower is crisper (Godot softens the toon edge with roughness).
@export_range(0.05, 1.0) var toon_roughness := 0.22
## How much of each surface's own colour it gives off regardless of the lights (the "fill"): the interior has only 6 live lights, each reaching a few metres, so a wall
## beyond the nearest lamp used to fall to near black and lose its colour (creator, 2026-10-25: "washed out when further away"). 0 = off.
@export_range(0.0, 1.0) var fill := 0.05
## The fill's tint: the lamps' amber, so the unlit parts of a room keep the warm palette (a neutral fill greyed everything out).
@export var fill_tint := Color(1.0, 0.74, 0.42)
## Nodes whose meshes are scanned, relative to this node's parent.
@export var scan_paths: Array[NodePath] = [NodePath("InteriorRooms"), NodePath("LighthouseInterior")]
## Outdoor nodes that get the same toon shading but no amber fill, and keep the distance fog (Island Creator ISL-13, creator 2026-10-27: the
## island and dock should have the lighthouse's toon feel).
@export var exterior_paths: Array[NodePath] = [NodePath("Island"), NodePath("RockPatchSE"), NodePath("RockPatchSE2"), NodePath("RockPatchNE"),
		NodePath("Harbour"), NodePath("HarbourStairs"), NodePath("IslandGate"), NodePath("Lampposts")]
## The island's ink region (world space): a second cylinder, cut off just above the sea so the waves are not outlined.
@export var island_mask_centre := Vector3(-10.0, 8.0, 5.0)
@export var island_mask_radius := 48.0
@export var island_mask_half_height := 20.0
@export var sea_cut_y := 0.9

var toon_count := 0                      # materials switched to toon
var mesh_count := 0                      # meshes scanned
var _mats := {}                          # StandardMaterial3D -> [diffuse_mode, specular_mode, roughness, emission_enabled, emission, energy, emission_texture, disable_fog] before
var _outdoor := {}                       # the materials from exterior_paths: toon, but no fill and the fog kept
var _outline: MeshInstance3D
var _outline_mat: ShaderMaterial
var _cam: Camera3D


func _ready() -> void:
	_build_outline()
	_scan.call_deferred()


func _scan() -> void:
	_mats.clear()
	_outdoor.clear()
	mesh_count = 0
	for outdoor in [false, true]:
		for path in (exterior_paths if outdoor else scan_paths):
			var root := get_parent().get_node_or_null(path)
			if root == null:
				continue
			for n in root.find_children("*", "MeshInstance3D", true, false):
				var mi := n as MeshInstance3D
				if mi.mesh == null:
					continue
				mesh_count += 1
				_collect(mi.material_override, outdoor)
				for i in mi.mesh.get_surface_count():
					_collect(mi.get_surface_override_material(i), outdoor)
					_collect(mi.mesh.surface_get_material(i), outdoor)
	set_enabled(enabled)


func _collect(m: Material, outdoor := false) -> void:
	if m is StandardMaterial3D and not _mats.has(m):
		var sm := m as StandardMaterial3D
		_mats[m] = [sm.diffuse_mode, sm.specular_mode, sm.roughness, sm.emission_enabled, sm.emission, sm.emission_energy_multiplier, sm.emission_texture, sm.disable_fog]
		if outdoor:
			_outdoor[m] = true


func set_enabled(on: bool) -> void:
	enabled = on
	toon_count = 0
	for m in _mats:
		if not is_instance_valid(m):
			continue
		var sm := m as StandardMaterial3D
		var o: Array = _mats[m]
		if on:
			sm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			sm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED      # no glints: flat cel colour
			sm.roughness = minf(float(o[2]), toon_roughness)         # the toon step is as hard as the surface is smooth
			if _outdoor.has(m):
				toon_count += 1
				continue                                             # outdoors: the fog stays and there is no indoor fill
			sm.disable_fog = true                                    # the distance fog is for the open air: indoors it only greys the walls
			if fill > 0.0 and not bool(o[3]) and not sm.has_meta("base_albedo") and sm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and sm.blend_mode == BaseMaterial3D.BLEND_MODE_MIX:
				sm.emission_enabled = true
				sm.emission = sm.albedo_color * fill_tint
				sm.emission_texture = sm.albedo_texture
				sm.emission_energy_multiplier = fill
			toon_count += 1
		else:
			sm.diffuse_mode = o[0]
			sm.specular_mode = o[1]
			sm.roughness = o[2]
			sm.emission_enabled = o[3]
			sm.emission = o[4]
			sm.emission_energy_multiplier = o[5]
			sm.emission_texture = o[6]
			sm.disable_fog = o[7]
	var ext := get_parent().get_node_or_null("LighthouseWallDetail")
	if ext and ext.has_method("set_toon"):
		ext.set_toon(on, toon_roughness)
	if _outline:
		_outline.visible = on and _camera_near()


func _build_outline() -> void:
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = OUTLINE_SHADER
	_outline_mat.set_shader_parameter("thickness", ink_thickness)
	_outline_mat.set_shader_parameter("ink", ink_colour)
	_outline_mat.set_shader_parameter("mask_centre", mask_centre)
	_outline_mat.set_shader_parameter("mask_radius", mask_radius)
	_outline_mat.set_shader_parameter("mask_half_height", mask_half_height)
	_outline_mat.set_shader_parameter("island_centre", island_mask_centre)
	_outline_mat.set_shader_parameter("island_radius", island_mask_radius)
	_outline_mat.set_shader_parameter("island_half_height", island_mask_half_height)
	_outline_mat.set_shader_parameter("sea_cut_y", sea_cut_y)
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	q.flip_faces = true
	_outline = MeshInstance3D.new()
	_outline.name = "ToonOutline"
	_outline.mesh = q
	_outline.material_override = _outline_mat
	_outline.extra_cull_margin = 16384.0
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_outline.visible = false


func _camera_near() -> bool:
	return _cam != null and Vector2(_cam.global_position.x - mask_centre.x, _cam.global_position.z - mask_centre.z).length() < camera_range


func _process(_d: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != _cam:
		_cam = cam
		if _outline.get_parent():
			_outline.get_parent().remove_child(_outline)
		if _cam:
			_cam.add_child(_outline)
	if _outline:
		_outline.visible = enabled and _camera_near()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		set_enabled(not enabled)
