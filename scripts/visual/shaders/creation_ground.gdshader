shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec4 grass_low : source_color = vec4(0.43,0.53,0.35,1.0);
uniform vec4 grass_high : source_color = vec4(0.60,0.67,0.43,1.0);
varying vec3 world_at;
float hash_point(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float meadow_noise(vec2 p) {
	vec2 cell = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash_point(cell),hash_point(cell+vec2(1.0,0.0)),f.x),mix(hash_point(cell+vec2(0.0,1.0)),hash_point(cell+vec2(1.0)),f.x),f.y);
}
void vertex() { world_at = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float field = meadow_noise(world_at.xz*0.16)*0.63 + meadow_noise(world_at.xz*0.49+7.3)*0.27 + meadow_noise(world_at.xz*2.3)*0.10;
	ALBEDO = mix(grass_low.rgb,grass_high.rgb,smoothstep(0.15,0.88,field));
	ROUGHNESS = 1.0;
}
