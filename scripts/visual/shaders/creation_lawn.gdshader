shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform vec4 grass_low : source_color = vec4(0.42,0.54,0.38,1.0);
uniform vec4 grass_high : source_color = vec4(0.48,0.59,0.41,1.0);
uniform float detail = 1.0;
varying vec3 world_at;
varying float tip;
#include "res://scripts/visual/shaders/creation_meadow_palette.gdshaderinc"
#include "res://scripts/visual/shaders/creation_shore_palette.gdshaderinc"
void vertex() {
	world_at = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	tip = UV.y;
	VERTEX *= detail;
	VERTEX.x += sin(TIME*0.85+world_at.x*0.37+world_at.z*0.29)*0.012*tip*tip*detail;
}
void fragment() {
	NORMAL = normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
	ALBEDO = shore_ground(world_at.xz,meadow_color(world_at.xz,grass_low.rgb,grass_high.rgb))*(1.0+tip*0.035*detail);
	ROUGHNESS = 1.0;
}
