shader_type canvas_item;

void fragment() {
	vec2 uv = UV;

	uv.x = abs(uv.x - 0.5) * 2.0;

	COLOR = texture(TEXTURE, uv);
}