uniform sampler2D water_field : filter_linear, repeat_disable;
uniform vec4 bank_soil : source_color = vec4(0.55,0.56,0.40,1.0);
float shore_distance(vec2 at) {
	return texture(water_field,(at-vec2(-30.0,-28.0))/vec2(60.0,56.0)).r;
}
vec3 shore_ground(vec2 at,vec3 grass) {
	float distance = shore_distance(at);
	float drift = meadow_noise(at*0.85)*0.12;
	float wet = 1.0-smoothstep(0.02,0.35+drift,distance);
	return mix(grass,bank_soil.rgb,wet*0.24);
}
