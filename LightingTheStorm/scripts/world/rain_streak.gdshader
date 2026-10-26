// rain_streak.gdshader - the material of the rain streaks and the splash specks (Lighthouse finish, rain).
// It looks like the StandardMaterial3D it replaced (unshaded, alpha blended, a billboard), with one addition: a fragment that lies
// inside a RainShelter volume (the lighthouse's interior air) is discarded. GPU particle collision hides a drop only a frame or
// two AFTER it passes into a collider (up to about 0.9 m at 35 m/s, tools/probe_rain_heightfield.gd), so under a roof with the
// ceiling a metre below it (the attic, the lamp-room dome) drops were drawn indoors. A test at draw time has no latency.
// Volumes are boxes turned about the vertical axis only: vol_a = (centre xyz, half x), vol_b = (axis x, axis z, half y, half z),
// where (axis x, axis z) is the box's local x axis in the world's xz plane.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform vec4 albedo : source_color = vec4(0.1, 0.1, 0.1, 0.2);
uniform bool fixed_y = true;        // true: a streak that turns about the vertical to face the camera; false: a particle billboard (the specks)
uniform int vol_n = 0;
uniform vec4 vol_a[32];
uniform vec4 vol_b[32];

varying vec3 wpos;

void vertex() {
	if (fixed_y) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], MODEL_MATRIX[1], normalize(vec4(cross(INV_VIEW_MATRIX[0].xyz, MODEL_MATRIX[1].xyz), 0.0)), MODEL_MATRIX[3]);
	} else {
		mat4 m = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = VIEW_MATRIX * m * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	}
}

void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	for (int i = 0; i < 32; i++) {
		if (i >= vol_n) {
			break;
		}
		vec3 d = w - vol_a[i].xyz;
		vec2 ax = vol_b[i].xy;
		float lx = dot(d.xz, ax);
		float lz = dot(d.xz, vec2(-ax.y, ax.x));
		if (abs(lx) <= vol_a[i].w && abs(d.y) <= vol_b[i].z && abs(lz) <= vol_b[i].w) {
			discard;
		}
	}
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
}
