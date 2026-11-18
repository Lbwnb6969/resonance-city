#include "res://scripts/visual/shaders/creation_safe_math.gdshaderinc"
// One meadow base for ground, blades, road fringes and shallow shore blends.
uniform vec4 grass_low : source_color = vec4(0.278,0.382,0.239,1.0);
uniform vec4 grass_mid : source_color = vec4(0.423,0.523,0.293,1.0);
uniform vec4 grass_high : source_color = vec4(0.598,0.633,0.354,1.0);
uniform float season_gold=0.0;
float meadow_hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
// Integer corners must agree whichever neighboring cell evaluates them.
// sin(dot(...)) amplifies float reassociation into visible boundary jumps.
float meadow_lattice_hash(ivec2 cell) {
	uvec2 bits=uvec2(cell);
	uint value=(bits.x*0x8da6b343u)^(bits.y*0xd8163841u);
	value^=value>>16u;value*=0x7feb352du;
	value^=value>>15u;value*=0x846ca68bu;value^=value>>16u;
	return float(value&0x00ffffffu)/16777216.0;
}
// Extracted Grass2 world_albedo_tint, sampled in the original 128 m mirrored
// domain. The mean exposure adapts our local meadow palette; this is not the
// original per-card palette texture or the separate base-bake gain.
uniform sampler2D grass2_world_tint : source_color, filter_linear_mipmap, repeat_enable;
uniform bool grass2_world_tint_enabled = false;
vec3 meadow_srgb_to_linear(vec3 value) {
	return mix(value/12.92,pow((value+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),value));
}
vec3 meadow_linear_to_srgb(vec3 value) {
	return mix(value*12.92,1.055*pow(value,vec3(1.0/2.4))-0.055,step(vec3(0.0031308),value));
}
vec3 meadow_world_tint_linear(vec2 at, vec3 local_linear) {
	if (!grass2_world_tint_enabled) { return local_linear; }
	vec2 uv = at/128.0+0.5;
	vec2 mirrored = mix(fract(uv),1.0-fract(uv),mod(floor(uv),2.0));
	vec3 tint = texture(grass2_world_tint,mirrored).rgb;
	// Compatibility shades in sRGB. The original Vulkan resolve is linear;
	// source_color is still needed for Forward+, but is not this conversion.
	if (OUTPUT_IS_SRGB) {
		tint = meadow_srgb_to_linear(tint);
	}
	vec3 mean_tint = vec3(0.3385393622,0.3378297793,0.3377306064);
	// Original card gain cancels against the luminance-matched local anchor.
	// Compress the baked broad light/dark field instead of drawing it as moss
	// blotches. Preserve its measured chroma separately from its luminance.
	vec3 relative = tint/mean_tint;
	float level = max(dot(relative,vec3(0.2126,0.7152,0.0722)),0.001);
	vec3 chroma = clamp(relative/level,vec3(0.9),vec3(1.1));
	float lightness = 1.0+clamp(log2(level),-1.0,1.0)*0.12;
	return local_linear*mix(vec3(1.0),chroma,0.28)*lightness;
}
float meadow_noise(vec2 p) {
	ivec2 cell = ivec2(floor(p)); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(meadow_lattice_hash(cell),meadow_lattice_hash(cell+ivec2(1,0)),f.x),mix(meadow_lattice_hash(cell+ivec2(0,1)),meadow_lattice_hash(cell+ivec2(1)),f.x),f.y);
}
vec3 meadow_color(vec2 at,mat4 projection) {
	vec3 low=grass_low.rgb,high=grass_high.rgb;
	float field = meadow_noise(at*0.055)*0.85 + meadow_noise(at*0.285+7.3)*0.15;
	float overview = projection[3][3] * smoothstep(28.0,68.0,2.0/abs(projection[1][1]));
	field = 0.5+(field-0.5)*mix(0.72,0.32,overview);
	float blend = smoothstep(0.18,0.86,field);
	vec3 middle = grass_mid.rgb;
	if (OUTPUT_IS_SRGB) {
		low=meadow_srgb_to_linear(low);middle=meadow_srgb_to_linear(middle);high=meadow_srgb_to_linear(high);
	}
	vec3 grass = mix(mix(low,middle,clamp(blend*2.0,0.0,1.0)),high,clamp(blend*2.0-1.0,0.0,1.0));
	float grain = meadow_noise(at*1.6+5.1)-0.5;
	grass=meadow_world_tint_linear(at,grass*(1.0+grain*0.012));
	grass=mix(grass,grass*vec3(1.28,.97,.64),season_gold*.65);
	return OUTPUT_IS_SRGB ? meadow_linear_to_srgb(grass) : grass;
}
// Tiny changes in the turf's light normal soften the flat plane. This is
// shading relief only; terrain geometry and all construction heights stay real.
float meadow_relief(vec2 at) {
	return meadow_noise(at*0.285+vec2(3.7,11.2))*0.045
		+ meadow_noise(at*1.45+vec2(8.1,2.4))*0.008;
}
vec3 meadow_normal(vec2 at) {
	float center = meadow_relief(at);
	float x = meadow_relief(at+vec2(0.10,0.0));
	float z = meadow_relief(at+vec2(0.0,0.10));
	return safe_normalize(vec3((center-x)*10.0,1.0,(center-z)*10.0));
}
