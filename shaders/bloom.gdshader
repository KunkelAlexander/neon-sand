shader_type canvas_item;

uniform float glowThreshold = 0.3;
uniform float glowRadius = 3.0;
uniform float glowIntensity = 1.6;

uniform float saturation = 1.8;
uniform float highlightBoost = 1.7;
uniform float contrast = 1.2;
vec3 saturate_color(vec3 c, float amount) {
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luma), c, amount);
}

vec3 screen_blend(vec3 base, vec3 add) {
	return base + add - base * add;
}
vec3 sample_glow(sampler2D tex, vec2 uv, vec2 px) {
	vec3 c = texture(tex, uv).rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));

	float glowMask = smoothstep(glowThreshold, 1.2, luma);

	// boost color instead of whitening
	c = saturate_color(c, 1.5);

	return c * glowMask;
}
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * glowRadius;

	vec3 glow = vec3(0.0);

	glow += sample_glow(TEXTURE, UV + px * vec2(-1,-1), px);
	glow += sample_glow(TEXTURE, UV + px * vec2(-1, 0), px);
	glow += sample_glow(TEXTURE, UV + px * vec2(-1, 1), px);
	glow += sample_glow(TEXTURE, UV + px * vec2( 0,-1), px);
	glow += sample_glow(TEXTURE, UV, px) * 2.0;
	glow += sample_glow(TEXTURE, UV + px * vec2( 0, 1), px);
	glow += sample_glow(TEXTURE, UV + px * vec2( 1,-1), px);
	glow += sample_glow(TEXTURE, UV + px * vec2( 1, 0), px);
	glow += sample_glow(TEXTURE, UV + px * vec2( 1, 1), px);

	glow /= 10.0;
	glow *= glowIntensity;

	vec3 col = texture(TEXTURE, UV).rgb;

	// highlight punch
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	float highlight = smoothstep(0.4, 1.0, luma);
	col *= mix(1.0, highlightBoost, highlight);

	// glow using screen blend (comic look)
	col = screen_blend(col, glow);

	// contrast curve
	col = pow(col, vec3(contrast));

	// post saturation (VERY IMPORTANT)
	col = saturate_color(col, saturation);

	COLOR = vec4(col, 1.0);
}
