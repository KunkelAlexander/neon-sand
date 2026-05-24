shader_type canvas_item;

uniform float amount = 4.0;

void fragment() {
	vec2 offset = TEXTURE_PIXEL_SIZE * amount;

	float r = texture(TEXTURE, UV + offset).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, UV - offset).b;

	COLOR = vec4(r, g, b, 1.0);
}