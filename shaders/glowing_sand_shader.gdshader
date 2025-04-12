shader_type canvas_item;

uniform sampler2D sand_texture;
uniform sampler2D sand_colors;

void fragment() {
	// Get the sand type at this pixel
	float sand_type =  texture(sand_texture, UV).r /3.0*255.0;

	float palette_width = float(textureSize(sand_colors, 0).x);
	float x = (sand_type  * (palette_width - 1.0) + 0.5) / palette_width;
	vec4 color = texture(sand_colors, vec2(x, 0.5));

	// Output the color
	COLOR = color;
	
	// Add after your current code
	float glow_strength = 0.5; // Adjust this value
	float glow_radius = 3.0; // Adjust this value

	vec4 glow = vec4(0.0);
	for(float i = -glow_radius; i <= glow_radius; i += 1.0) {
	    for(float j = -glow_radius; j <= glow_radius; j += 1.0) {
	        vec2 offset = vec2(i, j) / vec2(textureSize(sand_texture, 0));
	        float dist = length(vec2(i, j)) / glow_radius;
	        glow += texture(sand_texture, UV + offset) * (1.0 - dist) * glow_strength;
	    }
	}

	COLOR = mix(COLOR, glow, glow_strength);
}
