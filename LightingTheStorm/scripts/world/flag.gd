# flag.gd - Saint Calder's royal standard on a tall timber pole, marking the Saltgate quay to aim for.
# Colours follow Docs/Lore Build/world/style_guide.md: amber #C07A1E and gold #B8962E are Saint Calder's
# royal standard; the lore says the standards at the Saltgate are tattered, so the fly edge is ragged.
# Black, silver and navy are the Flighted's colours and are deliberately NOT used here.
# Flat two-step cel shading with a darker amber outline. It is weather-beaten (sun-bleached, soot and
# salt stains, moth holes, frayed edges) and fades into the fog with distance like everything else.
# @tool: shows in the editor; nothing is saved into the scene (no owners).
@tool
extends Node3D

@export var pole_height := 38.0
@export var flag_size := Vector2(16.0, 9.0)   # width along the fly, height

const AMBER := Color("#C07A1E")
const GOLD := Color("#B8962E")
const PALE := Color("#B9BEC4")

const SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled;   // fog applies, so it fades with distance

uniform vec4 amber : source_color = vec4(0.753, 0.478, 0.118, 1.0);
uniform vec4 gold : source_color = vec4(0.722, 0.588, 0.18, 1.0);
uniform vec4 ink : source_color = vec4(0.27, 0.16, 0.04, 1.0);
uniform float flag_w = 16.0;
uniform float flag_h = 9.0;

varying float v_fold;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	float fly = clamp(UV.x, 0.0, 1.0);                          // 0 at the pole, 1 at the fly edge
	float phase = TIME * 2.6 - UV.x * 7.0;
	float amp = fly * 1.9;
	VERTEX.z += sin(phase) * amp + sin(phase * 2.1 + UV.y * 3.0) * amp * 0.35;
	VERTEX.y -= fly * fly * 0.5 + sin(phase * 1.3) * fly * 0.25;
	v_fold = cos(phase);
}

void fragment() {
	vec2 uv = UV;
	// frayed, tattered fly edge: a deep ragged tear plus fine fraying, and a split near the middle
	float tear = vnoise(vec2(uv.y * 11.0, 3.0)) * 0.30 + vnoise(vec2(uv.y * 38.0, 9.0)) * 0.09;
	float edge = 1.0 - tear * smoothstep(0.40, 1.0, uv.x);
	float split = smoothstep(0.012, 0.0, abs(uv.y - 0.56)) * smoothstep(0.50, 0.62, uv.x);
	if (uv.x > edge - split * 0.5) discard;
	// worn, nibbled bottom and top edges
	float bottom = 0.03 + 0.11 * vnoise(vec2(uv.x * 8.0, 5.0)) * smoothstep(0.25, 1.0, uv.x);
	float top = 0.012 * vnoise(vec2(uv.x * 20.0, 17.0));
	if (uv.y > 1.0 - bottom || uv.y < top) discard;
	// moth holes and rot, mostly out on the fly
	float holes = vnoise(uv * vec2(15.0, 8.0) + 40.0);
	if (holes > 0.80 + 0.2 * (1.0 - smoothstep(0.3, 0.9, uv.x))) discard;

	// royal standard: amber field, a broad gold band through the middle, a gold hoist bar
	vec3 col = amber.rgb;
	float band = step(0.34, uv.y) * step(uv.y, 0.66);
	if (band > 0.5 || uv.x < 0.07) col = gold.rgb;

	// weathering: sun-bleach towards a dull wash, then soot and salt stains, heaviest at the fly and bottom
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(luma * 0.8), 0.22) * 0.88;                                  // faded, but still amber
	float bleach = vnoise(uv * vec2(6.0, 3.5) + 7.0);
	col = mix(col, col * vec3(1.12, 1.04, 0.80), smoothstep(0.55, 0.9, bleach) * 0.6);   // sun-bleached patches
	float soot = vnoise(vec2(uv.x * 5.0, uv.y * 2.0) + 21.0) * 0.6 + vnoise(uv * 22.0) * 0.4;
	col *= 1.0 - 0.55 * smoothstep(0.45, 0.85, soot) * (0.4 + 0.6 * uv.y);          // dark grime, worse low down
	float streak = vnoise(vec2(uv.x * 34.0, uv.y * 1.2 + 2.0));                      // rain streaks running down
	col *= 1.0 - 0.28 * smoothstep(0.6, 0.9, streak) * (0.3 + uv.y);
	col = mix(col, ink.rgb * 1.6, smoothstep(0.82, 1.0, uv.x) * 0.35);               // scorched, frayed fly

	// outline just inside every edge (broken where the cloth has worn away)
	float d = min(min(uv.x, edge - uv.x) * flag_w, min(uv.y, 1.0 - bottom - uv.y) * flag_h);
	if (d < 0.26 && vnoise(uv * vec2(30.0, 18.0) + 3.0) > 0.28) col = ink.rgb;
	// flat two-step shading: hard-edged shadow shapes in the folds
	col *= v_fold > 0.45 ? 0.72 : 1.0;
	ALBEDO = col;
}"


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.20, 0.15, 0.10)
	wood.roughness = 0.95
	var brass := StandardMaterial3D.new()
	brass.albedo_color = GOLD
	brass.roughness = 0.6
	brass.metallic = 0.4

	_add_cylinder("Pole", 0.28, 0.17, pole_height + 1.5, Vector3(0.0, (pole_height - 1.5) * 0.5, 0.0), wood)
	_add_cylinder("Crosspiece", 0.1, 0.1, flag_size.x + 0.6, Vector3(flag_size.x * 0.5 + 0.2, pole_height - 0.6, 0.0), wood, Vector3(0, 0, 90))
	var ball := MeshInstance3D.new()
	ball.name = "Finial"
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	ball.mesh = sphere
	ball.material_override = brass
	ball.position = Vector3(0.0, pole_height + 0.9, 0.0)
	add_child(ball)

	var sh := Shader.new()
	sh.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	# the exact style-guide hex values (converted from sRGB by the shader's source_color hint)
	mat.set_shader_parameter("amber", AMBER)
	mat.set_shader_parameter("gold", GOLD)
	mat.set_shader_parameter("ink", AMBER.darkened(0.7))
	mat.set_shader_parameter("flag_w", flag_size.x)
	mat.set_shader_parameter("flag_h", flag_size.y)
	var plane := _flag_mesh()
	var flag := MeshInstance3D.new()
	flag.name = "Standard"
	flag.mesh = plane
	flag.material_override = mat
	flag.position = Vector3(0.2, pole_height - 0.7, 0.0)
	flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flag)


func _add_cylinder(node_name: String, r_top: float, r_bottom: float, height: float, pos: Vector3, mat: Material, rot_deg := Vector3.ZERO) -> void:
	var m := MeshInstance3D.new()
	m.name = node_name
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = height
	c.radial_segments = 8
	m.mesh = c
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot_deg
	add_child(m)


## A subdivided plane hanging from the pole: x runs along the fly, y down from the top edge.
func _flag_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 32
	var ny := 12
	for j in ny:
		for i in nx:
			var u0 := float(i) / nx
			var u1 := float(i + 1) / nx
			var v0 := float(j) / ny
			var v1 := float(j + 1) / ny
			var p00 := Vector3(u0 * flag_size.x, -v0 * flag_size.y, 0.0)
			var p10 := Vector3(u1 * flag_size.x, -v0 * flag_size.y, 0.0)
			var p01 := Vector3(u0 * flag_size.x, -v1 * flag_size.y, 0.0)
			var p11 := Vector3(u1 * flag_size.x, -v1 * flag_size.y, 0.0)
			for t in [[p00, p10, p11, Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1)],
					[p00, p11, p01, Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1)]]:
				for k in 3:
					st.set_uv(t[3 + k])
					st.set_normal(Vector3(0, 0, 1))
					st.add_vertex(t[k])
	return st.commit()
