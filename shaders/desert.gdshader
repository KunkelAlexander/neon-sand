shader_type canvas_item;

uniform float strength = 5.0;
uniform float speed = 2.0;
uniform float scale = 20.0;

void fragment() {
	vec2 uv = UV;

	uv.x += sin((uv.y * scale) + TIME * speed) * TEXTURE_PIXEL_SIZE.x * strength;
	uv.y += cos((uv.x * scale) + TIME * speed) * TEXTURE_PIXEL_SIZE.y * strength;

	COLOR = texture(TEXTURE, uv);
}