shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float grain = fract(sin(dot(floor(UV * 150.0), vec2(127.1,311.7))) * 43758.5453);
	float patches = smoothstep(0.24,0.62,dot(source.rgb,vec3(0.3,0.5,0.2)));
	vec3 earth = mix(vec3(0.19,0.21,0.17),vec3(0.33,0.32,0.26),patches);
	COLOR = vec4(mix(earth,source.rgb,0.16) + (grain-0.5)*0.035,1.0);
}
