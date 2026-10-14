shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform vec4 grass_low : source_color = vec4(0.42,0.54,0.38,1.0);
uniform vec4 grass_high : source_color = vec4(0.48,0.59,0.41,1.0);
uniform vec4 water_deep : source_color = vec4(0.38,0.61,0.56,1.0);
uniform vec4 water_shallow : source_color = vec4(0.46,0.63,0.52,1.0);
varying vec3 world_at;
#include "res://scripts/visual/shaders/creation_meadow_palette.gdshaderinc"
#include "res://scripts/visual/shaders/creation_shore_palette.gdshaderinc"
void vertex() { world_at = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 at = world_at.xz;
	float depth = max(0.0,-shore_distance(at));
	float grain = meadow_noise(at*2.1)*0.06+meadow_noise(at*0.45)*0.03;
	vec3 ground = shore_ground(at,meadow_color(at,grass_low.rgb,grass_high.rgb));
	vec3 bed = mix(bank_soil.rgb*0.64,water_shallow.rgb,smoothstep(0.03,0.27+grain,depth));
	vec3 water = mix(bed,water_deep.rgb,smoothstep(0.18,0.60+grain,depth));
	float ripples = sin(at.y*1.05+TIME*0.28)+sin(at.x*1.73-at.y*0.31-TIME*0.17);
	water *= 1.0+ripples*0.022;
	float crest = sin(at.y*3.2+sin(at.x*1.1+TIME*0.20)*1.2-TIME*0.32);
	float light = smoothstep(0.965,1.0,crest)*smoothstep(0.68,0.88,meadow_noise(at*0.57+vec2(TIME*0.012,0.0)));
	water += vec3(0.017,0.021,0.017)*light*smoothstep(0.25,0.7,depth);
	ALBEDO = mix(ground,water,smoothstep(0.01,0.13+grain,depth));
	ROUGHNESS = mix(1.0,0.68,smoothstep(0.24,0.8,depth));
}
