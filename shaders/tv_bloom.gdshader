shader_type canvas_item;

uniform float glow_threshold = 0.55;
uniform float glow_softness = 0.25;
uniform float glow_radius = 6.0;
uniform float glow_intensity = 1.4;

uniform float curve_strength = 0.08;
uniform float scanline_strength = 0.12;
uniform float vignette_strength = 0.35;

uniform float saturation = 1.15;

vec2 curve_uv(vec2 uv) {
	vec2 centered = uv * 2.0 - 1.0;
	centered *= 1.0 + curve_strength * dot(centered, centered);
	return centered * 0.5 + 0.5;
}

float brightness(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 saturate_color(vec3 c, float amount) {
	float luma = brightness(c);
	return mix(vec3(luma), c, amount);
}

vec3 bright_part(vec3 c) {
	float b = brightness(c);
	float mask = smoothstep(
		glow_threshold,
		glow_threshold + glow_softness,
		b
	);

	return c * mask;
}

void fragment() {
	vec2 uv = curve_uv(UV);

	float inside =
		step(0.0, uv.x) *
		step(0.0, uv.y) *
		step(uv.x, 1.0) *
		step(uv.y, 1.0);

	vec2 safe_uv = clamp(uv, vec2(0.0), vec2(1.0));

	vec3 base = texture(TEXTURE, safe_uv).rgb;

	vec2 px = TEXTURE_PIXEL_SIZE * glow_radius;

	vec3 glow = vec3(0.0);
	float total = 0.0;

	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			vec2 offset = vec2(float(x), float(y));
			float dist = length(offset);
			float weight = exp(-dist * dist / 10.0);

			vec2 sample_uv = clamp(safe_uv + offset * px, vec2(0.0), vec2(1.0));
			vec3 sample_col = texture(TEXTURE, sample_uv).rgb;

			glow += bright_part(sample_col) * weight;
			total += weight;
		}
	}

	glow /= total;

	vec3 col = base + glow * glow_intensity;

	// Retro TV scanlines.
	float scanline = sin(UV.y / TEXTURE_PIXEL_SIZE.y * 3.14159);
	col *= 1.0 - scanline_strength * (1.0 - scanline);

	// CRT-style vignette.
	float dist = distance(UV, vec2(0.5));
	col *= 1.0 - smoothstep(0.3, 0.8, dist) * vignette_strength;

	col = saturate_color(col, saturation);

	// Black outside curved screen.
	col *= inside;

	COLOR = vec4(col, 1.0);
}