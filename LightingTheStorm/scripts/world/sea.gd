# sea.gd - large flat sea plane with a simple animated wave shader.
extends MeshInstance3D

@export var size := 2000.0

const SHADER_CODE := "
shader_type spatial;
uniform vec4 deep : source_color = vec4(0.03, 0.12, 0.16, 1.0);
void vertex() {
	VERTEX.y += sin(VERTEX.x * 0.15 + TIME * 1.2) * 0.35 + sin(VERTEX.z * 0.11 + TIME * 0.9) * 0.3;
}
void fragment() {
	ALBEDO = deep.rgb;
	ROUGHNESS = 0.15;
	METALLIC = 0.4;
}
"


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = 200
	plane.subdivide_depth = 200
	mesh = plane
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	material_override = mat
