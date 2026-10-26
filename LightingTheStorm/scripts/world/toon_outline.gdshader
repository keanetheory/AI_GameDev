// toon_outline.gdshader - a screen-space ink outline for the cel-shaded look (Lighthouse Finisher Agent, LHF-10).
// Drawn by a full-screen quad parented to the camera (toon_look.gd). An edge is where the depth is not a smooth plane (a silhouette
// or a step: the second difference of inverse depth is large; it is zero on any flat surface, however slanted) or where the surface
// normal turns sharply (a box's corner, the rim of a tread). The line is a dark navy ink, never pure black (style guide), and
// thickens a little with `thickness`. Forward+ only (it reads the depth and the normal-roughness buffers).
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_test_disabled, blend_mix;

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, repeat_disable, filter_nearest;
uniform vec4 ink : source_color = vec4(0.004, 0.006, 0.016, 1.0);   // near-black navy, not pure black (style guide)
uniform float thickness = 1.8;                    // pixels at 1080p; scales with the screen height
uniform float depth_threshold = 0.035;
uniform float normal_threshold = 0.62;            // cosine of the angle across which a crease is drawn
uniform float opacity = 1.0;
uniform vec3 mask_centre = vec3(4.9, 20.0, -4.2);   // the lighthouse, world space: lines are drawn only inside this cylinder
uniform float mask_radius = 12.0;
uniform float mask_half_height = 14.0;
uniform float fade_start = 40.0;                  // outlines fade out with distance, so far detail does not turn to noise
uniform float fade_end = 110.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float inv_depth(vec2 uv, mat4 inv_proj) {
	float d = textureLod(depth_tex, uv, 0.0).x;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	return 1.0 / max(-v.z, 0.001);
}

float view_dist(vec2 uv, mat4 inv_proj) {
	return 1.0 / max(inv_depth(uv, inv_proj), 1e-5);
}

void fragment() {
	vec2 px = vec2(thickness * (1080.0 / VIEWPORT_SIZE.y)) / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float ic = inv_depth(uv, INV_PROJECTION_MATRIX);
	float il = inv_depth(uv - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float ir = inv_depth(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float iu = inv_depth(uv - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float id = inv_depth(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float curv = max(abs(il + ir - 2.0 * ic), abs(iu + id - 2.0 * ic)) / max(ic, 1e-5);
	float e_depth = smoothstep(depth_threshold, depth_threshold * 2.0, curv);

	vec3 n0 = textureLod(normal_tex, uv, 0.0).xyz * 2.0 - 1.0;
	vec3 nl = textureLod(normal_tex, uv - vec2(px.x, 0.0), 0.0).xyz * 2.0 - 1.0;
	vec3 nr = textureLod(normal_tex, uv + vec2(px.x, 0.0), 0.0).xyz * 2.0 - 1.0;
	vec3 nu = textureLod(normal_tex, uv - vec2(0.0, px.y), 0.0).xyz * 2.0 - 1.0;
	vec3 nd = textureLod(normal_tex, uv + vec2(0.0, px.y), 0.0).xyz * 2.0 - 1.0;
	float cosmin = min(min(dot(n0, nl), dot(n0, nr)), min(dot(n0, nu), dot(n0, nd)));
	float e_norm = 1.0 - smoothstep(normal_threshold - 0.1, normal_threshold + 0.1, cosmin);

	float dist = view_dist(uv, INV_PROJECTION_MATRIX);
	float fade = 1.0 - smoothstep(fade_start, fade_end, dist);
	// where in the world is this pixel? only the lighthouse gets ink
	float dd = textureLod(depth_tex, uv, 0.0).x;
	vec4 vv = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, dd, 1.0);
	vec3 wp = (INV_VIEW_MATRIX * vec4(vv.xyz / vv.w, 1.0)).xyz;
	float inside = (1.0 - smoothstep(mask_radius, mask_radius + 4.0, length(wp.xz - mask_centre.xz))) * (1.0 - smoothstep(mask_half_height, mask_half_height + 3.0, abs(wp.y - mask_centre.y)));
	fade *= inside;
	float e = max(e_depth, e_norm) * fade;
	ALBEDO = ink.rgb;
	ALPHA = e * opacity;
}
