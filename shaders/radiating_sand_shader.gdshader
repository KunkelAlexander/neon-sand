shader_type canvas_item;

uniform sampler2D sand_texture;
uniform sampler2D sand_colors;

uniform float glow_strength = 2.0;  // brightness of glow
uniform float spread = 3.0;         // how far glow spreads (in pixels)
uniform float falloff = 10.0;        // how quickly glow fades with distance

void fragment() {
	vec2 tex_size = vec2(textureSize(sand_texture, 0));
	vec2 pixel_size = 1.0 / tex_size;

	vec4 accumulated = vec4(0.0);
	float total_weight = 0.0;

	// Sample a square kernel around current pixel
	for (int y = -int(spread); y <= int(spread); y++) {
		for (int x = -int(spread); x <= int(spread); x++) {
			vec2 offset = vec2(float(x), float(y));
			vec2 uv_offset = UV + offset * pixel_size;

			// Skip out-of-bounds UVs
			if (uv_offset.x < 0.0 || uv_offset.x > 1.0 || uv_offset.y < 0.0 || uv_offset.y > 1.0) {
				continue;
			}

			float sand_val = texture(sand_texture, uv_offset).r;
			if (sand_val > 0.0) {
				// Decode sand type and fetch color
				float sand_type = sand_val * 255.0 / 3.0;
				float palette_width = float(textureSize(sand_colors, 0).x);
				float x_coord = (sand_type * (palette_width - 1.0) + 0.5) / palette_width;
				vec4 sand_color = texture(sand_colors, vec2(x_coord, 0.5));

				// Weight based on distance
				float dist = length(offset);
				float weight = exp(-dist * falloff);

				accumulated += sand_color * weight;
				total_weight += weight;
			}
		}
	}

	// Final glow color
	vec4 glow = vec4(0.0);
	if (total_weight > 0.0) {
		glow = accumulated / total_weight * glow_strength;
	}

	COLOR = glow;
}
