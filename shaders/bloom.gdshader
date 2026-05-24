shader_type canvas_item;

uniform float glow_threshold = 0.55;
uniform float glow_softness = 0.25;
uniform float glow_radius = 6.0;
uniform float glow_intensity = 1.4;

uniform float base_intensity = 1.0;
uniform float saturation = 1.15;

vec3 saturate_color(vec3 c, float amount) {
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luma), c, amount);
}

float brightness(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
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
	vec3 base = texture(TEXTURE, UV).rgb;

	vec2 px = TEXTURE_PIXEL_SIZE * glow_radius;

	vec3 glow = vec3(0.0);
	float total = 0.0;

	// Wider, softer bloom kernel.
	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			vec2 offset = vec2(float(x), float(y));
			float dist = length(offset);

			float weight = exp(-dist * dist / 10.0);

			vec3 sample_col = texture(TEXTURE, UV + offset * px).rgb;
			glow += bright_part(sample_col) * weight;
			total += weight;
		}
	}

	glow /= total;

	// Keep original image readable.
	vec3 col = base * base_intensity;

	// Additive bloom: better for actual light/glow.
	col += glow * glow_intensity;

	col = saturate_color(col, saturation);

	COLOR = vec4(col, 1.0);
}