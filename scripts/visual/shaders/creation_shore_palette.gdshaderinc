#include "res://scripts/visual/shaders/creation_tiled_field.gdshaderinc"
#include "res://scripts/visual/shaders/creation_valley_river.gdshaderinc"
uniform bool scenery_river = false;
uniform sampler2DArray water_field : filter_linear, repeat_disable;
uniform vec4 water_world_rect = vec4(-48.0,-48.0,96.0,96.0);
uniform vec4 bank_soil : source_color = vec4(0.55,0.56,0.40,1.0);
uniform sampler2D bank_sand : source_color, filter_linear_mipmap, repeat_enable;
uniform bool bank_sand_enabled = false;
uniform vec4 bank_sand_tint : source_color = vec4(0.60,0.57,0.46,1.0);
uniform float shore_water_level=-.16;
float shore_distance(vec2 at) {
	if (scenery_river) { return abs(at.x-valley_river_x(at.y,water_world_rect.y+water_world_rect.w))-2.3; }
	return tiled_field_sample(water_field,(at-water_world_rect.xy)/water_world_rect.zw).r;
}
float shore_sand_cover(vec3 at,float distance) {
	// Narrow beaches follow the actual bank elevation. Raised land stays dry.
	float width=.24+(meadow_noise(at.xz*.85)-.5)*.34+(meadow_noise(at.xz*3.1)-.5)*.06;
	return (1.-smoothstep(-.04,width,distance))*(1.-smoothstep(.035,.14,at.y-shore_water_level));
}
vec3 shore_ground(vec3 world,vec3 grass) {
	vec2 at=world.xz;
	float distance = shore_distance(at);
	float wet = (1.0-smoothstep(-.04,.23,distance))*(1.-smoothstep(.015,.11,world.y-shore_water_level));
	vec3 old_bank = mix(grass,bank_soil.rgb,wet*0.24);
	float pixel_coverage = clamp(fwidth(distance),0.0,.10);
	// Far land takes the original path. Width/height thresholds are metres.
	if (!bank_sand_enabled || distance>.60) { return old_bank; }
	vec4 sand = texture(bank_sand,at*0.34);
	vec3 mean_sample = OUTPUT_IS_SRGB ? vec3(.451,.384,.290) : vec3(.171,.122,.068);
	vec3 dry_sand = bank_sand_tint.rgb*mix(vec3(1.0),sand.rgb/mean_sample,.50);
	float wet_line = wet;
	vec3 shore = dry_sand*mix(1.0,.69,wet_line);
	float edge = shore_sand_cover(world,distance);
	// Foundation terrain.fragment: max(height+mask)-blendSmooth, then
	// positive normalized weights. Recovered texture alpha is layer height.
	float sand_height = (sand.a-.5)*.16;
	float grass_height = (meadow_noise(at*2.4)-.5)*.04;
	// Townscaper Sandbank uses screen derivatives to soften its edge. We use
	// them only for pixel coverage; the actual shore width remains metric.
	float softness = .18+pixel_coverage;
	float offset = max(edge+sand_height,1.0-edge+grass_height)-softness;
	float sw = max(edge+sand_height-offset,0.0);
	float gw = max(1.0-edge+grass_height-offset,0.0);
	return (shore*sw+old_bank*gw)/(sw+gw);
}
