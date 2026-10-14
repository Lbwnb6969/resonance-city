shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec4 road_low : source_color = vec4(0.62,0.56,0.44,1.0);
uniform vec4 road_high : source_color = vec4(0.72,0.66,0.53,1.0);
varying vec3 world_at;
float hash_point(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float field(vec2 p) {
	vec2 f = fract(p); vec2 at = floor(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash_point(at),hash_point(at+vec2(1.0,0.0)),f.x),mix(hash_point(at+vec2(0.0,1.0)),hash_point(at+vec2(1.0)),f.x),f.y);
}
void vertex() { world_at = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float grain = field(world_at.xz*2.2)*0.72+field(world_at.xz*12.0)*0.28;
	ALBEDO = mix(road_low.rgb,road_high.rgb,grain);
	ROUGHNESS = 1.0;
}
