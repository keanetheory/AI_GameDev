# exterior_wall_detail.gd - swaps the lighthouse exterior's material for the close-range stone shader (LHF-11).
# The shader (exterior_wall_detail.gdshader) keeps the model's baked texture and adds masonry only near the camera. This node
# builds one ShaderMaterial from the model's own material (its texture and colour), so the distant look is unchanged.
# Put one node of this script in Level.tscn after the Lighthouse node. `enabled` = false restores the original material.
extends Node

const SHADER := preload("res://scripts/world/exterior_wall_detail.gdshader")
const PLAIN_MODE := "render_mode cull_disabled, specular_disabled;"

@export var target_path := NodePath("../Lighthouse")
@export var enabled := true
@export var tower_centre := Vector2(8.5, -4.9)       # world x, z (Lighthouse node origin (5, 9.61, -8.5) + (3.5, 3.6))
@export var ground_y := 10.58

var swapped := 0
var _orig := {}                                      # MeshInstance3D -> [surface materials before]
var _mat: ShaderMaterial
var _toon_shader: Shader
var _rough := 0.3
var toon := false
var _flat_mats: Array[ShaderMaterial] = []


## A material for built stone (the opening kit): the same masonry, joints and weathering, on a plain stone colour.
func flat_material(col := Color(0.42, 0.34, 0.27)) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _toon_shader if (toon and _toon_shader) else SHADER
	m.set_shader_parameter("flat_albedo", true)
	m.set_shader_parameter("flat_col", col)
	m.set_shader_parameter("tower_centre", tower_centre)
	m.set_shader_parameter("ground_y", ground_y)
	m.set_shader_parameter("surface_roughness", _rough if toon else 1.0)
	_flat_mats.append(m)
	return m


## The cel look (toon_look.gd): the same shader with toon diffuse and a crisper surface; off restores the plain one.
func set_toon(on: bool, roughness := 0.3) -> void:
	toon = on
	_rough = roughness
	for fm in _flat_mats:
		fm.shader = _shader_for(on)
		fm.set_shader_parameter("surface_roughness", roughness if on else 1.0)
	if _mat == null:
		return
	if on:
		if _toon_shader == null:
			_toon_shader = Shader.new()
			_toon_shader.code = SHADER.code.replace(PLAIN_MODE, "render_mode cull_disabled, specular_disabled, diffuse_toon;")
		_mat.shader = _toon_shader
		_mat.set_shader_parameter("surface_roughness", roughness)
	else:
		_mat.shader = SHADER
		_mat.set_shader_parameter("surface_roughness", 1.0)


func _shader_for(on: bool) -> Shader:
	if on:
		if _toon_shader == null:
			_toon_shader = Shader.new()
			_toon_shader.code = SHADER.code.replace(PLAIN_MODE, "render_mode cull_disabled, specular_disabled, diffuse_toon;")
		return _toon_shader
	return SHADER


func _ready() -> void:
	apply(enabled)


func apply(on: bool) -> void:
	var lh := get_node_or_null(target_path)
	if lh == null:
		return
	for mi in lh.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or m.is_ancestor_of(self) or "LighthouseShell" in String(m.get_path()):
			continue      # (the authored shell has its own materials: the baked-texture masonry shader is for the generated exterior only)
		for i in m.mesh.get_surface_count():
			if on:
				var src := m.get_active_material(i) as BaseMaterial3D
				if src == null or src.albedo_texture == null:
					continue
				if not _orig.has(m):
					_orig[m] = {}
				_orig[m][i] = m.get_surface_override_material(i)
				m.set_surface_override_material(i, _material_for(src))
				swapped += 1
			elif _orig.has(m) and _orig[m].has(i):
				m.set_surface_override_material(i, _orig[m][i])
	if not on:
		swapped = 0
		_orig.clear()


func _material_for(src: BaseMaterial3D) -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = SHADER
		_mat.set_shader_parameter("tower_centre", tower_centre)
		_mat.set_shader_parameter("ground_y", ground_y)
		_mat.set_shader_parameter("albedo_tex", src.albedo_texture)
		_mat.set_shader_parameter("albedo_color", src.albedo_color)
	return _mat
