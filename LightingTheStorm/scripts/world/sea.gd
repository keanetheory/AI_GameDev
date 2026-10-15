# sea.gd - large flat sea plane with a simple animated wave shader.
# The wave shape lives in ONE place, wave_height(), which the shader mirrors. Anything that floats
# (the boat) calls Sea.wave_height(x, z, Sea.wave_time) so it rides exactly the surface you see.
# To change the waves later, change wave_height() and the matching two lines in the shader together.
extends MeshInstance3D

@export var size := 2000.0

## Seconds the waves have been running. Drives both the shader and anything that floats.
static var wave_time := 0.0

const SHADER_CODE := "
shader_type spatial;
uniform vec4 deep : source_color = vec4(0.03, 0.12, 0.16, 1.0);
uniform float wave_t = 0.0;
void vertex() {
	VERTEX.y += sin(VERTEX.x * 0.15 + wave_t * 1.2) * 0.35 + sin(VERTEX.z * 0.11 + wave_t * 0.9) * 0.3;
}
void fragment() {
	ALBEDO = deep.rgb;
	ROUGHNESS = 0.15;
	METALLIC = 0.4;
}
"

var _mat: ShaderMaterial


## Height of the water surface above the sea node's own level, at world (x, z), at time t.
static func wave_height(x: float, z: float, t: float) -> float:
	return sin(x * 0.15 + t * 1.2) * 0.35 + sin(z * 0.11 + t * 0.9) * 0.3


func _ready() -> void:
	wave_time = 0.0
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = 200
	plane.subdivide_depth = 200
	mesh = plane
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	material_override = _mat


func _process(delta: float) -> void:
	wave_time += delta
	_mat.set_shader_parameter("wave_t", wave_time)
