shader_type canvas_item;
render_mode unshaded;

// All placement is authored per illustration. No screen-wide camera distortion.
uniform float clock = 0.0;
uniform float motion = 1.0;
uniform vec4 water_rects[4];
uniform int water_count = 0;
uniform vec4 water_exclusions[8];
uniform int exclusion_count = 0;
uniform float water_strength = 0.0015;
uniform vec4 fog_rects[3];
uniform int fog_count = 0;
uniform float fog_opacity = 0.11;
uniform vec3 fog_tint = vec3(0.62, 0.70, 0.71);
uniform vec4 lamp_rects[8];
uniform int lamp_count = 0;
uniform vec4 mechanism_rects[4];
uniform vec4 mechanism_params[4]; // x/y displacement amplitude, speed, phase
uniform int mechanism_count = 0;

float rectangle_mask(vec2 uv, vec4 region, float softness) {
	vec2 local = (uv - region.xy) / max(region.zw, vec2(0.0001));
	return smoothstep(0.0, softness, local.x) * smoothstep(0.0, softness, local.y)
		* smoothstep(0.0, softness, 1.0-local.x) * smoothstep(0.0, softness, 1.0-local.y);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),u.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),u.x),u.y);
}

float cloud(vec2 p) {
	return noise(p)*0.58 + noise(p*2.13+4.2)*0.27 + noise(p*4.31-6.7)*0.15;
}

void fragment() {
	vec2 warped = UV;
	float water_mask = 0.0;
	for (int i=0;i<4;i++) {
		if (i >= water_count) { break; }
		water_mask = max(water_mask, rectangle_mask(UV, water_rects[i], 0.14));
	}
	for (int i=0;i<8;i++) {
		if (i >= exclusion_count) { break; }
		water_mask *= 1.0 - rectangle_mask(UV, water_exclusions[i], 0.08);
	}
	float ripples = sin(UV.y*246.0-clock*1.15+sin(UV.x*16.0+clock*0.31))*0.68
		+ sin(UV.y*487.0+clock*0.77+UV.x*31.0)*0.32;
	warped.x += motion * water_mask * water_strength * ripples;
	warped.y += motion * water_mask * water_strength * 0.19 * sin(UV.x*46.0-clock*0.82);
	for (int i=0;i<4;i++) {
		if (i >= mechanism_count) { break; }
		vec4 region = mechanism_rects[i];
		vec4 spec = mechanism_params[i];
		float mask = rectangle_mask(UV, region, 0.24);
		float wave = sin(clock*spec.z + spec.w);
		warped += motion * mask * spec.xy * wave;
	}
	vec4 result = texture(TEXTURE, warped);
	// Narrow shimmering highlights follow the existing bright reflections.
	float luminance = dot(result.rgb, vec3(0.2126,0.7152,0.0722));
	float glint = pow(max(0.0, sin(UV.y*370.0 + clock*1.1 + noise(UV*14.0)*4.0)), 10.0);
	result.rgb += motion * water_mask * glint * smoothstep(0.24,0.76,luminance) * vec3(0.028,0.038,0.039);
	for (int i=0;i<8;i++) {
		if (i >= lamp_count) { break; }
		vec4 lamp = lamp_rects[i];
		vec2 d = (UV-lamp.xy)/max(lamp.zw,vec2(0.001));
		float halo = exp(-dot(d,d)*3.3);
		float shimmer = 0.63 + 0.14*sin(clock*2.1+float(i)*2.17) + 0.07*sin(clock*5.9+float(i)*1.51);
		result.rgb += motion * halo * shimmer * vec3(0.09,0.052,0.018);
	}
	for (int i=0;i<3;i++) {
		if (i >= fog_count) { break; }
		vec4 region = fog_rects[i];
		float mask = rectangle_mask(UV,region,0.35);
		vec2 p = vec2(UV.x*5.0-clock*0.035, UV.y*19.0+clock*0.008);
		float vapor = smoothstep(0.30,0.78,cloud(p+float(i)*3.41));
		float alpha = motion * mask * vapor * fog_opacity;
		result.rgb = mix(result.rgb,fog_tint,alpha);
	}
	COLOR = result;
}
