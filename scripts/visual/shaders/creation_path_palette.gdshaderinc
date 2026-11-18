uniform vec4 road_low : source_color = vec4(0.48,0.395,0.29,1.0);
uniform vec4 road_high : source_color = vec4(0.72,0.635,0.49,1.0);
float path_hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float path_noise(vec2 p) {
	vec2 f = fract(p); vec2 at = floor(p); f = f*f*(3.0-2.0*f);
	return mix(mix(path_hash(at),path_hash(at+vec2(1.0,0.0)),f.x),mix(path_hash(at+vec2(0.0,1.0)),path_hash(at+vec2(1.0)),f.x),f.y);
}
vec3 path_color(vec2 at) {
	float grain = .58*path_noise(at*1.35)+.42*path_noise(at*5.1);
	vec3 earth = mix(road_low.rgb,road_high.rgb,.18+.72*grain);
	vec2 lattice = mat2(vec2(.8,.6),vec2(-.6,.8))*at*8.0;
	vec2 cell = floor(lattice);
	float seed = path_hash(cell);
	vec2 offset = (vec2(seed,path_hash(cell+19.7))-.5)*.40;
	vec2 local = (fract(lattice)-.5-offset)*vec2(.80,1.24);
	float size = mix(.085,.18,seed);
	float footprint = max(length(dFdx(lattice)),length(dFdy(lattice)));
	float aa = clamp(footprint*.5,.018,.18);
	float chip = (1.0-smoothstep(size-aa,size+aa,length(local)))*(1.0-smoothstep(.10,.45,footprint));
	return earth*(1.0+chip*mix(-.18,.21,seed));
}
