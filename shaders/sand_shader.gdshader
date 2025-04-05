shader_type canvas_item;

uniform sampler2D sand_texture;
uniform sampler2D sand_colors;

void fragment() {
	// Get the sand type at this pixel
	float sand_type =  texture(sand_texture, UV).r;
	
	float palette_width = float(textureSize(sand_colors, 0).x);
	float x = (sand_type * (palette_width - 1.0) + 0.5) / palette_width;
	vec4 color = texture(sand_colors, vec2(x, 0.5));
	
	// Output the color
	COLOR = color;
}
