// exterior_wall_detail.gdshader - close-range stone for the lighthouse's walls (Lighthouse Finisher Agent, LHF-11).
// The exterior model has one baked 2048 px texture that turns to a soft smear within a few metres. This keeps that texture (so the
// silhouette and the distant look do not change) and, only close to the camera, lays real masonry over it: coursed blocks with
// joints and a bevel, a tint for each block, a small bump from the joints, dirty drip streaks and a damp, greener base. Stone only:
// the mask follows the texture's brightness, so the dark timber frames and the door stay as painted. The detail fades out between
// near_start and near_end metres, so nothing shimmers at distance.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec2 tower_centre = vec2(8.5, -4.9);   // world x, z of the tower's axis: the tower's courses follow its curve
uniform float tower_radius = 4.8;
uniform float ground_y = 10.58;                // world height of the ground at the walls
uniform float near_start = 5.0;
uniform float near_end = 22.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float bump : hint_range(0.0, 2.0) = 0.8;
uniform float surface_roughness : hint_range(0.0, 1.0) = 1.0;   // toon_look.gd lowers this so the toon step is crisp
uniform bool flat_albedo = false;                // the opening kit's stone: a plain colour instead of the baked atlas
uniform vec3 flat_col : source_color = vec3(0.62, 0.57, 0.48);
uniform float course_h = 0.32;
uniform float block_w = 0.64;

varying vec3 wpos;
varying vec3 wnorm;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	float dist = length(VERTEX);
	float near = (1.0 - smoothstep(near_start, near_end, dist)) * strength;
	// close up, the baked texture shows its pixel blocks: read a blurrier mip there, and let the masonry supply the detail
	vec3 base = flat_albedo ? flat_col : textureLod(albedo_tex, UV, near * 1.6).rgb * albedo_color.rgb;
	float luma = dot(base, vec3(0.299, 0.587, 0.114));
	float stone = flat_albedo ? 1.0 : smoothstep(0.28, 0.46, luma);   // dark timber and the door are not stone

	// where on the wall are we, in metres: round the tower, along a house wall, or across a roof
	vec2 rel = wpos.xz - tower_centre;
	vec2 q;
	if (length(rel) < tower_radius) {
		q = vec2(atan(rel.y, rel.x) * 3.7, wpos.y);
	} else if (abs(wnorm.y) > 0.7) {
		q = wpos.xz;
	} else if (abs(wnorm.x) > abs(wnorm.z)) {
		q = vec2(wpos.z, wpos.y);
	} else {
		q = vec2(wpos.x, wpos.y);
	}

	// coursed blocks: every other course shifted half a block, each course a little different
	float row = floor(q.y / course_h);
	float shift = mod(row, 2.0) * 0.5 * block_w + h21(vec2(row, 3.0)) * 0.25 * block_w;
	vec2 cell = vec2((q.x + shift) / block_w, q.y / course_h);
	vec2 id = floor(cell);
	vec2 f = fract(cell);
	vec2 e = min(f, 1.0 - f) * vec2(block_w, course_h);      // metres to the block's edge
	float edge = min(e.x, e.y);
	float joint = 1.0 - smoothstep(0.010, 0.030, edge);
	float bevel = smoothstep(0.0, 0.07, edge);
	float rnd = h21(id);
	float grain = vn(q * 14.0) - 0.5;
	float height = bevel * (0.75 + 0.25 * rnd) - joint * 0.5 + grain * 0.08;

	// dirt: vertical drips, and a damp greener base
	float drip = smoothstep(0.55, 0.95, vn(vec2(q.x * 4.0 + h21(vec2(floor(q.x * 0.5), 1.0)) * 9.0, q.y * 0.3)));
	float damp = smoothstep(ground_y + 2.6, ground_y + 0.3, wpos.y);

	vec3 col = base;
	if (flat_albedo) {
		// built stone has no baked weathering of its own: blotch it the way the baked wall is (large soft patches of lighter and darker, and a
		// dirtier band along the top and bottom of each panel), so a patch does not read as a clean cut-out in the old wall
		float blot = vn(q * 0.55 + vec2(3.1, 7.7)) * 0.6 + vn(q * 1.7) * 0.4;
		base *= 0.72 + 0.56 * blot;
	}
	float k = (flat_albedo ? 1.0 : near) * stone;
	col *= mix(1.0, 0.82 + 0.34 * rnd, k);
	col = mix(col, col * 0.42, joint * k * 0.9);
	col = mix(col, col * 0.68, drip * k * 0.55);
	col = mix(col, col * vec3(0.55, 0.68, 0.52), damp * k * 0.7);
	ALBEDO = col;
	ROUGHNESS = surface_roughness;

	// bump from the joints and the grain (screen-space derivatives, so any mapping works). `height` is in "units"; the relief is a few
	// centimetres, and the result is kept within 35 degrees of the surface normal so no joint ever turns black.
	float rel_m = height * 0.03 * bump * k;
	vec3 N = NORMAL;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	vec3 r1 = cross(dpdy, N);
	vec3 r2 = cross(N, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dFdx(rel_m) * r1 + dFdy(rel_m) * r2);
	vec3 Np = normalize(abs(det) * N - grad);
	NORMAL = normalize(mix(N, Np, 0.9));
	if (dot(NORMAL, N) < 0.82) { NORMAL = normalize(mix(N, NORMAL, 0.5)); }
}
