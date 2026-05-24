shader_type canvas_item;

uniform float curve_strength = 0.08;
uniform float scanline_strength = 0.12;
uniform float vignette_strength = 0.35;

vec2 curve_uv(vec2 uv) {
	vec2 centered = uv * 2.0 - 1.0;
	centered *= 1.0 + curve_strength * dot(centered, centered);
	return centered * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(UV);

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 col = texture(TEXTURE, uv).rgb;

		float scanline = sin(UV.y / TEXTURE_PIXEL_SIZE.y * 3.14159);
		col *= 1.0 - scanline_strength * (1.0 - scanline);

		float dist = distance(UV, vec2(0.5));
		col *= 1.0 - smoothstep(0.3, 0.8, dist) * vignette_strength;

		COLOR = vec4(col, 1.0);
	}
}