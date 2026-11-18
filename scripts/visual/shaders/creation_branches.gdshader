shader_type spatial;
render_mode diffuse_burley, specular_disabled;
#include "res://scripts/visual/shaders/creation_foliage_motion.gdshaderinc"
void vertex(){
	vec3 world=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
	VERTEX+=inverse(mat3(MODEL_MATRIX))*creation_foliage_offset(world,COLOR.a);
}
void fragment(){
	ALBEDO=COLOR.rgb;
	ROUGHNESS=1.;SPECULAR=0.;
}
