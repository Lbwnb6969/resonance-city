float meadow_hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float meadow_noise(vec2 p) {
	vec2 cell = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(meadow_hash(cell),meadow_hash(cell+vec2(1.0,0.0)),f.x),mix(meadow_hash(cell+vec2(0.0,1.0)),meadow_hash(cell+vec2(1.0)),f.x),f.y);
}
vec3 meadow_color(vec2 at,vec3 low,vec3 high) {
	float field = meadow_noise(at*0.12)*0.82 + meadow_noise(at*0.31+7.3)*0.18;
	return mix(low,high,smoothstep(0.05,0.95,field));
}
