shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 stone = texture(TEXTURE, UV);
	// Compress ground contrast so actors and attack warnings remain readable.
	COLOR = vec4(mix(vec3(0.39, 0.40, 0.37), stone.rgb, 0.55), stone.a);
}
