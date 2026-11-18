shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform sampler2D leaf_mask : filter_linear_mipmap, repeat_disable;
uniform sampler2D flower_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool flower = false;
uniform float water_level = -0.16;
varying vec4 original_vertex_color;
varying vec3 world_position;
varying float instance_seed;
vec3 to_srgb(vec3 value) {
	return mix(12.92 * value, 1.055 * pow(max(value, vec3(0.0)), vec3(1.0/2.4)) - 0.055, step(vec3(0.0031308), value));
}
void vertex() {
	original_vertex_color = COLOR;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	instance_seed = INSTANCE_CUSTOM.x;
}
void fragment() {
	float mask = texture(leaf_mask, UV).r;
	// Even low-seed leaves retain the existing mask's characteristic open cleft.
 if (!flower && mask < mix(0.64, 0.82, instance_seed)) discard;
	vec3 linear_color = original_vertex_color.rgb;
 if (!flower) {
  vec2 p=UV-vec2(.5,.55);
  float radial=length(p);
  float spoke=abs(sin(atan(p.y,p.x)*6.0))*radial;
  float aa=max(fwidth(spoke),.001);
  float veins=1.0-smoothstep(.002-aa,.006+aa,spoke);
  float resolved=1.0-smoothstep(.015,.06,length(fwidth(UV)));
  // Quiet radial shading and filtered veins distinguish a floating leaf from turf.
  linear_color*=mix(.78,1.04,smoothstep(.02,.48,radial));
  linear_color*=1.0-veins*.12*resolved;
 }
 if (flower) {
		vec3 sampled = texture(flower_texture, world_position.xz * 0.1).rgb;
		if (OUTPUT_IS_SRGB) {
			sampled = mix(sampled/12.92,pow((sampled+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),sampled));
		}
		// Original height blends, relative to this game's actual water plane.
		float height = world_position.y - water_level;
		linear_color = mix(mix(sampled, vec3(0.25, 0.1, 0.2), 1.0 - smoothstep(0.05, 0.1, height)), original_vertex_color.rgb, 1.0 - smoothstep(-0.05, 0.05, height));
	}
	ALBEDO = OUTPUT_IS_SRGB ? to_srgb(linear_color) : linear_color;
	ROUGHNESS = 0.92;
}
