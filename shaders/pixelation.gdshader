shader_type canvas_item;

uniform float pixel_size = 6.0;

void fragment() {
	vec2 uv = UV;

	vec2 pixel_count = 1.0 / TEXTURE_PIXEL_SIZE / pixel_size;
	vec2 snapped_uv = floor(uv * pixel_count) / pixel_count;

	COLOR = texture(TEXTURE, snapped_uv);
}