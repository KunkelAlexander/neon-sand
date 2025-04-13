shader_type canvas_item;
uniform sampler2D sand_texture;
uniform sampler2D sand_colors;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
// Glow controls
uniform float glow_intensity = 5; // High intensity for that sun-like brilliance
uniform float glow_extend = 4.0;    // How far the glow extends in pixels
uniform float sparkle_speed = 2.0;  // Speed of sparkle animation
uniform float sparkle_amount = 0.3; // Amount of sparkle effect

void fragment() {
    // Get the original color
    float sand_type = texture(sand_texture, UV).r / 3.0 * 255.0;
    float palette_width = float(textureSize(sand_colors, 0).x);
    float x = (sand_type * (palette_width - 1.0) + 0.5) / palette_width;
    vec4 original_color = texture(sand_colors, vec2(x, 0.5));

    // Calculate size of a pixel in UV coordinates
    vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));

    // Accumulate glow
    vec4 glow_sum = vec4(0.0);
    float weight_sum = 0.0;

    // Larger sampling radius for extended glow
    for (float i = -glow_extend; i <= glow_extend; i += 1.0) {
        for (float j = -glow_extend; j <= glow_extend; j += 1.0) {
            // Skip the center pixel (we'll add it separately)
            if (i == 0.0 && j == 0.0) continue;

            vec2 offset = vec2(i, j) * pixel_size;
            float dist = length(vec2(i, j)) / glow_extend;

            // Inverse square falloff for a sun-like glow
            float weight = 1.0 / (1.0 + dist * dist * 8.0);

            // Sample adjacent sand pixels
            float adjacent_sand_type = texture(sand_texture, UV + offset).r / 3.0 * 255.0;
            if (adjacent_sand_type > 0.0) { // Only sample actual sand particles
                float adjacent_x = (adjacent_sand_type * (palette_width - 1.0) + 0.5) / palette_width;
                vec4 adjacent_color = texture(sand_colors, vec2(adjacent_x, 0.5));

                // Add to glow with weight
                glow_sum += adjacent_color * weight;
                weight_sum += weight;
            }
        }
    }

    // Normalize glow
    vec4 glow_color = vec4(0.0);
    if (weight_sum > 0.0) {
        glow_color = glow_sum / weight_sum;
    }

    // Add time-based sparkle effect
    float sparkle = sin(TIME * sparkle_speed + UV.x * 20.0) * sin(TIME * sparkle_speed * 0.7 + UV.y * 15.0);
    sparkle = pow(max(0.0, sparkle), 3.0) * sparkle_amount; // Make sparkle more pronounced

    // Base color
    vec4 final_color = original_color;

    // Add glow only if this is a sand particle
    if (sand_type > 10.0) {
        // Amplify original colors for the glow
        vec3 glow = glow_color.rgb * glow_intensity;

        // Add extra brightness to simulate sun-like intensity
        final_color.rgb += glow;

        // Add sparkle
        final_color.rgb += sparkle * original_color.rgb * 2.0;

        // HDR-like effect: colors can go above 1.0 for that brilliant look
        // (will be clamped by the renderer, but creates that intense bright center)
    }
    else {
        // If not a sand particle, still add some ambient glow from nearby particles
        final_color.rgb += glow_color.rgb * glow_intensity * 0.3;
    }

    // Output the final color
    COLOR = final_color;
}