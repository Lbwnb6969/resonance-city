shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec4 grass_low : source_color = vec4(0.42,0.54,0.38,1.0);
uniform vec4 grass_high : source_color = vec4(0.48,0.59,0.41,1.0);
varying vec3 world_at;
#include "res://scripts/visual/shaders/creation_meadow_palette.gdshaderinc"
void vertex() { world_at = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	ALBEDO = meadow_color(world_at.xz,grass_low.rgb,grass_high.rgb);
	ROUGHNESS = 1.0;
}
