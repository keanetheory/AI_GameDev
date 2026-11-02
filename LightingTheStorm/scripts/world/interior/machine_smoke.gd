# machine_smoke.gd - very light, cel-banded smoke wisps rising from a machine (boiler firebox: orange; steam engine's exhaust: white/grey).
# Same look as fire_flame.gd: one spatial shader, unshaded, stepped bands (no smooth gradients), no particles and no lights. A few
# upright cards, each turned to face the camera about the vertical axis, each scrolling its own noise upward; the alpha is capped low
# so it stays a hint, never a cloud. coal_job.gd calls set_level(0..1): 0 hides it, 1 is the full (still faint) wisp.
# Origin = the mouth the smoke leaves. Build it with MachineSmoke.make(parent, name, position, "orange" | "grey").
extends Node3D

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float level : hint_range(0.0, 1.0) = 1.0;
uniform float seed = 0.0;
uniform float speed = 0.35;
uniform float max_alpha = 0.32;
uniform vec3 light_col : source_color = vec3(1.0, 0.72, 0.38);
uniform vec3 dark_col : source_color = vec3(0.85, 0.42, 0.12);
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	// turn about the vertical axis only, so the wisps stay upright whichever way the camera looks
	vec3 centre = MODEL_MATRIX[3].xyz;
	vec3 to_cam = INV_VIEW_MATRIX[3].xyz - centre;
	vec3 fwd = normalize(vec3(to_cam.x, 0.0, to_cam.z) + vec3(0.0001, 0.0, 0.0001));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), fwd));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right * sx, 0.0), vec4(0.0, sy, 0.0, 0.0), vec4(fwd, 0.0), vec4(centre, 1.0));
}
void fragment() {
	float y = 1.0 - UV.y;                           // 0 at the mouth, 1 at the top of the wisp
	float t = TIME * speed;
	float sway = (vn(vec2(y * 2.0 + seed, t * 0.7)) - 0.5) * 0.45 * y;   // the column wanders as it rises
	float dx = abs(UV.x - 0.5 + sway) * 2.0;
	float n = vn(vec2(UV.x * 2.6 + seed, y * 2.2 - t * 1.4)) * 0.65 + vn(vec2(UV.x * 6.0 - seed, y * 4.8 - t * 2.3)) * 0.35;
	float width = mix(0.35, 0.95, y);                // narrow at the mouth, spreading as it climbs
	float body = (1.0 - dx / width) * smoothstep(0.0, 0.12, y) * (1.0 - smoothstep(0.55, 1.0, y)) + (n - 0.5) * 0.7;
	float a = 0.0;
	vec3 c = dark_col;
	if (body > 0.2) { a = 0.55; }                    // stepped: a thin outer wisp ...
	if (body > 0.4) { a = 1.0; c = light_col; }      // ... and a denser core, nothing in between
	ALBEDO = c;
	ALPHA = a * max_alpha * level;
	if (ALPHA < 0.01) { discard; }
}
"""

const PALETTES := {
	"orange": {"light": Color(1.0, 0.74, 0.4), "dark": Color(0.9, 0.45, 0.12)},
	"grey": {"light": Color(0.93, 0.93, 0.91), "dark": Color(0.62, 0.63, 0.66)},
}

var tone := "orange"
var height := 1.1              # metres from the mouth to the top of the wisp
var width := 0.5
var _mats: Array[ShaderMaterial] = []
var _level := 1.0


static func make(parent: Node3D, nm: String, at: Vector3, tone_name: String, h := 1.1, w := 0.5) -> Node3D:
	var n := Node3D.new()
	n.set_script(load("res://scripts/world/interior/machine_smoke.gd"))
	n.name = nm
	n.tone = tone_name
	n.height = h
	n.width = w
	n.position = at
	parent.add_child(n)
	return n


func _ready() -> void:
	var sh := Shader.new()
	sh.code = SHADER
	var pal: Dictionary = PALETTES.get(tone, PALETTES["grey"])
	for i in 3:
		var q := QuadMesh.new()
		q.size = Vector2(width * (1.0 - 0.18 * i), height * (1.0 - 0.12 * i))
		var mi := MeshInstance3D.new()
		mi.name = "Wisp%d" % i
		mi.mesh = q
		mi.position = Vector3(0.05 * (i - 1), q.size.y * 0.5, 0.0)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("seed", 5.3 * i)
		m.set_shader_parameter("speed", 0.3 + 0.07 * i)
		m.set_shader_parameter("light_col", pal["light"])
		m.set_shader_parameter("dark_col", pal["dark"])
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_mats.append(m)
	set_level(_level)


## 0 = no smoke, 1 = the full (still very faint) wisp.
func set_level(f: float) -> void:
	_level = clampf(f, 0.0, 1.0)
	visible = _level > 0.01
	for m in _mats:
		m.set_shader_parameter("level", _level)
