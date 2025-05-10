shader_type canvas_item;

uniform sampler2D sand_texture;
uniform sampler2D sand_colors;

// Bloom effect parameters
uniform int bloom_size = 3;
uniform float bloom_separation = 3.0;
uniform float bloom_threshold = 0.4;
uniform float bloom_amount = 1.0;

void fragment() {
    // Convert the texture size (ivec2) to a vec2 for floating point calculations
    vec2 texSize = vec2(textureSize(sand_texture, 0));

    // Convert the normalized UV coordinate to texel space, snap to the grid and add 0.5 to sample from texel center
    vec2 pixelCoords = floor(UV * texSize) + 0.5;
    vec2 snappedUV = pixelCoords / texSize;

    // Sample the sand type from the sand texture using adjusted UV coordinates
    float sand_type = texture(sand_texture, snappedUV).r;
    vec4 color = texture(sand_colors, vec2(sand_type, 0.5));

    // Apply bloom effect
    vec4 bloomResult = vec4(0.0);
    float count = 0.0;

    // Loop through a kernel centered over the current fragment
    for (int i = -bloom_size; i <= bloom_size; ++i) {
        for (int j = -bloom_size; j <= bloom_size; ++j) {
            // Calculate UV for this sample
			vec2 offsetUV = (SCREEN_UV * texSize + vec2(float(i), float(j)) * bloom_separation) / texSize;

            // Sample the texture at this offset
            vec4 sampleColor = texture(TEXTURE, offsetUV);

            // Calculate brightness value
            float value = max(sampleColor.r, max(sampleColor.g, sampleColor.b));

            // Apply threshold
            if (value < bloom_threshold) {
                sampleColor = vec4(0.0);
            }

            // Add to the result
            bloomResult += sampleColor;
            count += 1.0;
        }
    }

    // Average the result
    bloomResult /= count;

    // Mix the original color with the bloom effect
    COLOR = color + mix(vec4(0.0), bloomResult, bloom_amount);
}