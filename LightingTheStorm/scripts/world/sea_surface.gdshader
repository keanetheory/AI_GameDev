// sea_surface.gdshader - the sea's surface: wave shape (vertex) and a cel-shaded storm look (fragment). Wave Creator Agent, WAV-15.
//
// SHAPE: the two vertex lines below MUST match Sea.wave_height() in sea.gd (the boat rides exactly this surface). Do not change
// them without changing wave_height() too. Everything in fragment() is paint: it never moves the surface, so the boat and the
// wave tests are unaffected.
//
// LOOK (reference: GERFramework/reference/sea/, a storm sea filmed from a ship): deep navy troughs; the faces of the waves turn
// translucent teal and cyan where light passes through them; long white foam streaks run along the crests and trail down the
// faces; a pale spray haze lifts off the tops. Here that is drawn flat, as bands with hard edges (gritty dark cel-shaded: hard-
// edged shadow shapes, ink-dark outlines, muted palette; Docs/Lore Build/world/style_guide.md), with the foam as flat shapes
// outlined in the trough colour. Every colour and threshold is a uniform, set from data/world/wave_spec.json ("look") and by sea
// state (more foam and brighter faces as the sea rises).
shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_back, shadows_disabled;   // the 10 m mesh is far too coarse to shadow itself without triangular blotches

uniform float wave_t = 0.0;
uniform float amp = 1.0;
uniform float k_scale = 1.0;
uniform vec4 shelter_pos[4];
uniform float shelter_factor[4];

// ---- the look (data/world/wave_spec.json "look") ----
uniform vec3 trough_col : source_color = vec3(0.012, 0.035, 0.075);   // deep navy
uniform vec3 body_col   : source_color = vec3(0.02, 0.09, 0.17);      // mid blue
uniform vec3 face_col   : source_color = vec3(0.04, 0.24, 0.30);      // the translucent teal of a wave's face
uniform vec3 crest_col  : source_color = vec3(0.17, 0.46, 0.50);      // pale cyan where the crest is thin
uniform vec3 foam_col   : source_color = vec3(0.72, 0.76, 0.79);      // silver foam (style guide: #B9BEC4, the moon colour)
uniform vec3 ink_col    : source_color = vec3(0.01, 0.02, 0.04);      // the outline round the foam
uniform float foam_amount = 0.5;       // 0 none .. 1 storm: set from the sea state
uniform float face_amount = 0.5;       // how much of each wave face shows the teal
uniform float band_softness = 0.03;    // the width of a foam edge: small = hard cel edge
uniform float water_softness = 0.11;   // the width of the water colour bands' edges: wider so the colours blend rather than block
uniform float streak_scale = 0.35;     // foam streak detail
uniform vec2 wind_dir = vec2(1.0, 0.2);
uniform float foam_dim = 1.0;          // 0..1 darkens the whites and pale crests as the moon is eclipsed (set by the lighting rig)
uniform float brightness = 1.0;        // the Lighting agent's exposure for the phase (1 = as designed)

varying float v_f;         // the dock-shelter amplitude factor at this vertex (smooth)
varying vec3 v_world;

void vertex() {
	float f = 1.0;
	for (int i = 0; i < 4; i++) {
		float d = distance(VERTEX.xz, shelter_pos[i].xy);
		f = min(f, mix(shelter_factor[i], 1.0, smoothstep(shelter_pos[i].z, shelter_pos[i].w, d)));
	}
	float pa = VERTEX.x * 0.15 * k_scale + wave_t * 1.2;
	float pb = VERTEX.z * 0.11 * k_scale + wave_t * 0.9;
	VERTEX.y += (sin(pa) * 0.35 + sin(pb) * 0.3) * amp * f;
	// paint-only: the surface slope, for the toon lighting
	vec2 g = vec2(cos(pa) * 0.15 * k_scale * 0.35, cos(pb) * 0.11 * k_scale * 0.3) * amp * f;
	NORMAL = normalize(vec3(-g.x, 1.0, -g.y));
	v_f = f;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// gradient (Perlin-style) noise with a quintic fade: value noise showed its square lattice as angular cells once cut by hard cel edges
vec2 grad2(vec2 i) {
	float a = hash21(i) * 6.2831853;
	return vec2(cos(a), sin(a));
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = dot(grad2(i), f);
	float b = dot(grad2(i + vec2(1, 0)), f - vec2(1, 0));
	float c = dot(grad2(i + vec2(0, 1)), f - vec2(0, 1));
	float d = dot(grad2(i + vec2(1, 1)), f - vec2(1, 1));
	return 0.5 + 0.95 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		s += a * (vnoise(p) - 0.5);
		p = rot * p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return clamp(s * 1.6 + 0.5, 0.0, 1.0);
}

// a hard-edged step: 0 below e, 1 above, with a short smooth edge so it does not shimmer
float cel(float x, float e) {
	return smoothstep(e - band_softness, e + band_softness, x);
}

// the same for the water colours, with a much softer edge
float blend(float x, float e) {
	return smoothstep(e - water_softness, e + water_softness, x);
}

void fragment() {
	vec2 wp = v_world.xz;
	// the same two sines as the vertex shader, evaluated per pixel so the bands follow the wave smoothly (the mesh quads are 10 m)
	float pa = wp.x * 0.15 * k_scale + wave_t * 1.2;
	float pb = wp.y * 0.11 * k_scale + wave_t * 0.9;
	float v_h = (sin(pa) * 0.35 + sin(pb) * 0.3) / 0.65;
	vec2 v_grad = vec2(cos(pa) * 0.15 * k_scale * 0.35, cos(pb) * 0.11 * k_scale * 0.3) * amp * v_f;
	// foam and spray patterns slide with the swell; streaks are long along the wind (the crests' direction)
	vec2 wd = normalize(wind_dir);
	vec2 across = vec2(-wd.y, wd.x);
	vec2 q = vec2(dot(wp, wd), dot(wp, across));
	vec2 drift = wd * wave_t * 1.6;
	float streak = fbm(vec2((q.x - dot(drift, wd)) * streak_scale * 0.35, q.y * streak_scale * 2.4));   // long along the wind
	float cell = fbm(wp * streak_scale * 1.3 - drift * 0.6);                                              // broken patches

	// how much this part of the surface faces the "light" side of the wave: a wave face leaning toward the wind lets light
	// through (teal); the back of it and the trough stay navy
	float facing = dot(normalize(v_grad + vec2(0.0001)), wd) * clamp(length(v_grad) * 6.0, 0.0, 1.0);
	// fine surface detail: the base swell is ~40 m long, far too big for the small teal patches and streaks of a real sea, so a
	// noise of short chop rides on it (paint only)
	float chop = fbm(q * vec2(0.09, 0.22) - vec2(dot(drift, wd) * 0.09, 0.0)) - 0.5;
	float chop2 = vnoise(wp * 0.7 + drift * 0.5) - 0.5;
	float lit = clamp(v_h * (0.22 + 0.28 * face_amount) + 0.5 + facing * 0.35 * face_amount + chop * (0.45 + 0.35 * face_amount) + chop2 * 0.12, 0.0, 1.0);

	// ---- the colour bands: trough / body / face / crest ----
	vec3 col = trough_col;
	col = mix(col, body_col, blend(lit, 0.40));
	col = mix(col, face_col, blend(lit, 0.74 - 0.18 * face_amount));
	col = mix(col, crest_col, blend(lit, 0.92 - 0.14 * face_amount));

	// ---- the foam: flat shapes, each outlined in ink ----
	// crest foam: where the surface is high, broken up by the noise
	float crest_f = lit + (cell - 0.5) * 0.45;
	float foam_a = cel(crest_f, 1.12 - 0.20 * foam_amount);
	// streaks: long thin lines trailing off the crests, thickest in a heavy sea
	float st_f = streak + (lit - 0.5) * 0.35;
	float foam_b = cel(st_f, 0.90 - 0.16 * foam_amount) * step(0.42, lit) * foam_amount;
	float foam = max(foam_a * min(1.0, foam_amount * 1.6 + 0.12), foam_b);
	// the ink outline: a band just outside each foam shape, darker than the water
	float outer_a = cel(crest_f, 1.12 - 0.20 * foam_amount - 0.05);
	float outer_b = cel(st_f, 0.90 - 0.16 * foam_amount - 0.04) * step(0.42, lit) * foam_amount;
	float outline = max(outer_a * min(1.0, foam_amount * 1.6 + 0.12), outer_b) * (1.0 - foam);
	col = mix(col, ink_col, outline * 0.85);
	col = mix(col, foam_col * foam_dim, foam);

	// the lighting normal per pixel (the vertex normal is interpolated across 10 m quads and made the toon bands triangular)
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(vec3(-v_grad.x, 1.0, -v_grad.y)), 0.0)).xyz);
	ALBEDO = col * brightness;
	ROUGHNESS = 0.55;
	METALLIC = 0.0;
	SPECULAR = 0.25;
}
