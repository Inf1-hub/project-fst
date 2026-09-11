shader_type canvas_item;
render_mode unshaded;

// Impassable earth mass. Per-room low/high tones separate the levels' terrain read.
uniform vec3 earth_low = vec3(0.19, 0.21, 0.17);
uniform vec3 earth_high = vec3(0.33, 0.32, 0.26);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float grain = fract(sin(dot(floor(UV * 150.0), vec2(127.1,311.7))) * 43758.5453);
	float patches = smoothstep(0.24,0.62,dot(source.rgb,vec3(0.3,0.5,0.2)));
	vec3 earth = mix(earth_low, earth_high, patches);
	COLOR = vec4(mix(earth,source.rgb,0.16) + (grain-0.5)*0.035,1.0);
}
