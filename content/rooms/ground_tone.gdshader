shader_type canvas_item;
render_mode unshaded;

// Per-room tone lets each level read distinctly while keeping ground contrast low
// enough that actors and attack warnings stay legible.
uniform vec3 base_tint = vec3(0.39, 0.40, 0.37);
uniform float stone_mix : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec4 stone = texture(TEXTURE, UV);
	COLOR = vec4(mix(base_tint, stone.rgb, stone_mix), stone.a);
}
