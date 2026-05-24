shader_type canvas_item;

uniform float segments = 8.0;
uniform float rotation_speed = 0.2;

void fragment() {
	vec2 centered = UV - vec2(0.5);

	float angle = atan(centered.y, centered.x);
	float radius = length(centered);

	float slice = 6.2831853 / segments;
	angle = mod(angle + TIME * rotation_speed, slice);
	angle = abs(angle - slice * 0.5);

	vec2 uv = vec2(cos(angle), sin(angle)) * radius + vec2(0.5);

	COLOR = texture(TEXTURE, uv);
}