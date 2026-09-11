shader_type canvas_item;
varying vec2 world_at;
void vertex() { world_at = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 float a=fract(sin(dot(i,vec2(127.1,311.7)))*43758.5453);
 float b=fract(sin(dot(i+vec2(1,0),vec2(127.1,311.7)))*43758.5453);
 float c=fract(sin(dot(i+vec2(0,1),vec2(127.1,311.7)))*43758.5453);
 float d=fract(sin(dot(i+vec2(1,1),vec2(127.1,311.7)))*43758.5453);
 return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
void fragment() {
 vec4 stone=texture(TEXTURE,UV);
 float mud=smoothstep(.48,.82,noise(world_at/190.0))*0.36;
 vec3 base=mix(stone.rgb*.76,vec3(.20,.19,.16),mud);
 float stain=smoothstep(.79,.90,noise(world_at/105.0))*smoothstep(.37,.70,noise(world_at/21.0));
 base=mix(base,vec3(.19,.045,.026),stain*.30);
 COLOR=vec4(base,stone.a);
}
