shader_type canvas_item;

uniform sampler2D sand_texture;
uniform sampler2D sand_colors;

void fragment() {
	    // Convert the texture size (ivec2) to a vec2 for floating point calculations.
    vec2 texSize = vec2(textureSize(sand_texture, 0));

    // Convert the normalized UV coordinate to texel space, snap to the grid and add 0.5 to sample from texel center.
    vec2 pixelCoords = floor(UV * texSize) + 0.5;
    vec2 snappedUV = pixelCoords / texSize;

    // Sample the sand type from the sand texture using adjusted UV coordinates.
    float sand_type = texture(sand_texture, snappedUV).r;
	
	vec4 color = texture(sand_colors, vec2(sand_type, 0.5));

	// Output the color
	COLOR = color;
}
