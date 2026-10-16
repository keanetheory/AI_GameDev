// storm_sky.gdshader - the night sky for the lighting rig (lighting_rig.gd sets every uniform from
// data/world/lighting_spec.json). Look reference: the title splash screen - dense, billowing storm cloud
// whose edges catch the light, a big moon veiled by a few sparse clouds, and forked lightning that strobes
// the cloud around it.
shader_type sky;

uniform vec3 sky_zenith : source_color = vec3(0.02, 0.03, 0.06);
uniform vec3 sky_horizon : source_color = vec3(0.07, 0.09, 0.12);
uniform vec3 cloud_top : source_color = vec3(0.42, 0.42, 0.40);
uniform vec3 cloud_under : source_color = vec3(0.17, 0.23, 0.25);
uniform float coverage : hint_range(0.0, 1.0) = 0.5;
uniform float darkness : hint_range(0.0, 1.0) = 0.4;
uniform float drift = 3.0;                 // m/s, as a scroll speed for the cloud pattern
uniform vec2 wind_dir = vec2(0.6, 0.8);
uniform float cloud_scale = 1.1;

uniform vec3 moon_dir = vec3(0.0, 0.37, -0.93);   // direction TOWARDS the moon
uniform vec3 moon_colour : source_color = vec3(0.73, 0.75, 0.77);
uniform float moon_radius = 0.03;                  // angular radius of the disc, radians
uniform float moon_brightness = 1.6;
uniform float moon_gap = 0.0;                      // 1 = only sparse wisps cross the moon

uniform float flash = 0.0;                         // 0..1 the one scene-wide flash of a strike
uniform float strobe = 0.0;                        // 0..1 the flicker of the cloud around the strike
uniform float bolt_glow = 0.0;                     // 0..1 how bright the bolt's channel is right now
uniform vec3 flash_dir = vec3(0.0, 0.5, 0.8);      // centre of the strike
uniform vec3 flash_colour : source_color = vec3(0.73, 0.75, 0.77);
uniform vec3 glow_colour : source_color = vec3(0.12, 0.16, 0.27);   // the cooler glow round the bolt
// The bolt: up to 48 segments (a.xy, b.xy) in the tangent plane at flash_dir, `bolt_count` in use.
uniform vec4 bolt[48];
uniform int bolt_count = 0;
uniform vec3 bolt_t = vec3(1.0, 0.0, 0.0);         // tangent-plane axes for the bolt
uniform vec3 bolt_b = vec3(0.0, 1.0, 0.0);

uniform vec3 dark_dir = vec3(0.0, 0.0, 1.0);       // towards Saint Calder: kept in relative darkness

// The second, lower layer (RETURN only): darker, ragged, part-transparent, drifting slowly on its own
// heading. It sits in front of the storm and the bolt, crosses the moon freely, and lights through.
uniform float low_coverage : hint_range(0.0, 1.0) = 0.0;
uniform float low_opacity : hint_range(0.0, 1.0) = 0.0;
uniform float low_drift = 2.0;
uniform vec2 low_wind_dir = vec2(-0.85, 0.5);
uniform vec3 low_colour : source_color = vec3(0.05, 0.05, 0.06);

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < octaves; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

// Billowing cloud: rounded lumps (abs-noise "billow") over a broad shape. Returns the raw shape (0..~1).
float cloud_shape(vec2 uv, int octaves) {
	float broad = fbm(uv * 0.45, 3);
	float b = 0.0;
	float a = 0.5;
	vec2 p = uv;
	for (int i = 0; i < octaves; i++) {
		b += a * (1.0 - abs(noise(p) * 2.0 - 1.0));
		p = p * 2.1 + vec2(5.3, 11.7);
		a *= 0.5;
	}
	return broad * 0.55 + b * 0.55;
}

// How much cloud there is at a shape value, for the current coverage.
float cover(float shape) {
	float threshold = 1.0 - coverage;
	return smoothstep(threshold - 0.05, threshold + 0.18, shape);
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-8), 0.0, 1.0);
	return length(pa - ba * h);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float up = max(d.y, 0.0);
	bool cheap = AT_CUBEMAP_PASS;   // the reflection/ambient pass doesn't need the detail
	int oct = cheap ? 3 : 5;

	// sky gradient: some moon glow on the moon's side, darker over Saint Calder
	vec3 col = mix(sky_horizon, sky_zenith, pow(up, 0.5));
	vec3 md = normalize(moon_dir);
	float to_moon = max(dot(d, md), 0.0);
	col += moon_colour * (pow(to_moon, 8.0) * 0.12 + pow(to_moon, 120.0) * 0.25) * (1.0 - darkness * 0.5);
	col *= mix(1.0, 0.55, smoothstep(0.2, 0.9, dot(d, normalize(dark_dir))) * (1.0 - up));

	// the moon disc (drawn before the cloud so cloud can cross it)
	float ang = acos(clamp(dot(d, md), -1.0, 1.0));
	float disc = 1.0 - smoothstep(moon_radius * 0.94, moon_radius, ang);
	if (disc > 0.0) {
		vec2 m = d.xz * 220.0;
		float mottle = 0.8 + 0.2 * fbm(m, 4);
		col = mix(col, moon_colour * moon_brightness * mottle, disc);
	}

	// the strike's tangent plane, shared by the bolt and its glow
	vec3 fd = normalize(flash_dir);
	float facing = dot(d, fd);
	vec2 bp = vec2(0.0);
	if (facing > 0.0) {
		vec3 q = d / facing - fd;
		bp = vec2(dot(q, bolt_t), dot(q, bolt_b));
	}
	float local = facing > 0.0 ? exp(-dot(bp, bp) * 10.0) : 0.0;   // the cloud around the strike

	if (d.y > 0.0) {
		vec2 uv = d.xz / (d.y + 0.15) * cloud_scale + wind_dir * TIME * drift * 0.004;
		uv += (vec2(fbm(uv * 0.5 + 7.0, 3), fbm(uv * 0.5 + 21.0, 3)) - 0.5) * 1.2;   // churn
		float shape = cloud_shape(uv, oct);
		float dens = cover(shape);
		// across the moon the cloud thins to a few sparse wisps
		float veil = 1.0 - smoothstep(moon_radius * 1.5, moon_radius * 6.0, ang);
		float wisps = smoothstep(0.45, 0.8, fbm(uv * 3.0 + 3.0, 3));   // the few strands left across the moon
		dens *= mix(1.0, wisps * 0.6, veil * moon_gap);
		dens *= smoothstep(0.0, 0.12, d.y);   // thin into the haze at the horizon

		// self-shadowing: compare with the density a step towards the light, so the lit side of each
		// billow glows and the far side stays dark (the splash screen's bright cloud edges)
		vec2 to_light_moon = normalize(md.xz + vec2(1e-4)) * 0.06;
		float moon_edge = 0.0;
		float bolt_edge = 0.0;
		if (!cheap) {
			moon_edge = clamp((shape - cloud_shape(uv + to_light_moon, 3)) * 4.0, 0.0, 1.0);
			if (strobe > 0.001 || flash > 0.001) {
				vec2 to_bolt = normalize(fd.xz - d.xz + vec2(1e-4)) * 0.05;
				bolt_edge = clamp((shape - cloud_shape(uv + to_bolt, 3)) * 4.0, 0.0, 1.0);
			}
		}
		// relief: the tops of the billows catch a little light and the folds between them stay black,
		// so a full sky still reads as heaped cloud (the splash screen), not a flat grey sheet
		float relief = smoothstep(1.0 - coverage - 0.05, 1.0 - coverage + 0.55, shape);
		vec3 cloud = mix(cloud_under * 0.35, cloud_top, relief);
		cloud *= (1.0 - darkness * 0.7) * (0.35 + 0.9 * relief);
		// moonlight on the billows nearest the moon
		cloud += moon_colour * (moon_edge * 2.2 + 0.15) * pow(to_moon, 6.0) * (1.0 - darkness * 0.45);
		// lightning: the cloud round the strike lights from inside and its edges flare with each flicker
		float lit = strobe * local;
		cloud += mix(glow_colour, flash_colour, 0.4) * lit * (0.3 + relief * 2.2);
		cloud += flash_colour * lit * bolt_edge * 3.0;
		cloud += flash_colour * flash * 0.03 * relief;
		col = mix(col, cloud, dens);
	}

	// the forked bolt itself: a hot core and a cooler glow, visible only during the flickers
	if (!cheap && bolt_glow > 0.001 && facing > 0.0) {
		float dmin = 10.0;
		for (int i = 0; i < 48; i++) {
			if (i >= bolt_count) {
				break;
			}
			dmin = min(dmin, seg_dist(bp, bolt[i].xy, bolt[i].zw));
		}
		float core = 1.0 - smoothstep(0.0012, 0.0035, dmin);
		float halo = exp(-dmin * 70.0);
		col += (flash_colour * 1.6 * core + mix(glow_colour, flash_colour, 0.5) * halo * 0.8) * bolt_glow;
	}
	// the low layer, over everything above: lower, so it is projected on a nearer ceiling (bigger shapes)
	if (low_coverage > 0.001 && low_opacity > 0.001 && d.y > 0.0) {
		vec2 luv = d.xz / (d.y + 0.3) * 1.3 + low_wind_dir * TIME * low_drift * 0.003 + vec2(40.0, -13.0);
		luv += (vec2(fbm(luv * 0.5 + 3.0, 3), fbm(luv * 0.5 + 9.0, 3)) - 0.5) * 0.6;
		float lshape = fbm(luv, cheap ? 3 : 5);
		// coverage picks the share of the sky: separate ragged masses with clear sky between them
		float lt = mix(0.62, 0.36, low_coverage);
		float ldens = smoothstep(lt, lt + 0.07, lshape) * smoothstep(0.0, 0.1, d.y);
		float thick = smoothstep(lt + 0.04, lt + 0.2, lshape);   // ragged, thin edges let more through
		float alpha = ldens * low_opacity * (0.5 + 0.5 * thick) * 1.35;
		vec3 lc = low_colour * (0.5 + 0.6 * thick);
		// the side facing the moon catches a thin silver rim, so the layer reads apart from the storm above
		float rim = clamp((lshape - fbm(luv + normalize(md.xz + vec2(1e-4)) * 0.05, 3)) * 6.0, 0.0, 1.0);
		lc += moon_colour * rim * (1.0 - thick) * pow(to_moon, 3.0) * 0.35;
		// faint moonlight soaking through where it crosses the moon
		lc += moon_colour * pow(to_moon, 30.0) * (1.0 - thick) * 0.35;
		// lightning lights it through from behind: thin parts glow brightest, thick cores stay dark
		float through = strobe * local * (1.2 - thick * 0.85);
		lc += mix(glow_colour, flash_colour, 0.45) * through * 1.9;
		lc += flash_colour * flash * 0.02;
		col = mix(col, lc, clamp(alpha, 0.0, 0.92));
	}
	col += flash_colour * flash * 0.012;
	COLOR = col;
}
