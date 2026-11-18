shader_type spatial;
render_mode blend_mix, diffuse_burley, specular_disabled, cull_disabled;
#include "res://scripts/visual/shaders/creation_safe_math.gdshaderinc"
varying vec3 world_at;
varying flat vec4 edge_a;
varying flat vec4 edge_b;
varying flat vec4 edge_c;
varying flat vec4 edge_middle;
varying float deck_amount;
#include "res://scripts/visual/shaders/creation_path_palette.gdshaderinc"
#include "res://scripts/visual/shaders/creation_meadow_palette.gdshaderinc"
#include "res://scripts/visual/shaders/creation_shore_palette.gdshaderinc"
#include "res://scripts/visual/shaders/creation_meadow_contact.gdshaderinc"
#include "res://scripts/visual/shaders/creation_window_bounce.gdshaderinc"
void vertex() {
	world_at = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	edge_a=vec4(UV,UV2);edge_b=CUSTOM0;edge_c=CUSTOM1;
	edge_middle=CUSTOM2;deck_amount=COLOR.r;
}
float edge_distance(vec2 at,vec4 edge) {
	vec2 delta=edge.zw-edge.xy;
	float t=clamp(dot(at-edge.xy,delta)/max(dot(delta,delta),.00000001),0.,1.);
	return length(at-edge.xy-delta*t);
}
void fragment() {
	EMISSION=window_ground_bounce(world_at.xz);
	// Evaluate metric distance at the pixel. Interpolated endpoint distances
	// form green wedges on the long triangles around overlapping curved caps.
	float distance=min(edge_distance(world_at.xz,edge_a),min(edge_distance(world_at.xz,edge_b),edge_distance(world_at.xz,edge_c)));
	distance=min(distance,edge_distance(world_at.xz,edge_middle));
	float across = clamp(distance/.16,0.0,1.0);
	float roots = .65*path_noise(world_at.xz*3.8)+.35*path_noise(world_at.xz*11.0);
	float fringe = clamp(across+(roots-.5)*.72*(4.0*across*(1.0-across)),0.0,1.0);
	float reveal = smoothstep(.06,.88,fringe);
	// Bridge decks keep their own material right to the parapet. The same
	// analytic water-derived visual field is shared with the natural shore.
	float dry_land = smoothstep(0.08,0.60,shore_distance(world_at.xz));
	vec3 grass = meadow_contact_color(world_at.xz,shore_ground(world_at,meadow_color(world_at.xz,PROJECTION_MATRIX)));
	vec3 earth = path_color(world_at.xz);
	vec3 loam = mix(earth*vec3(.77,.79,.74),grass,.22);
	ALBEDO = mix(grass,loam,smoothstep(.0,.43,fringe));
	ALPHA = (1.-reveal)*dry_land*(1.-deck_amount);
	vec3 normal = safe_normalize(mix(meadow_normal(world_at.xz),vec3(0.0,1.0,0.0),reveal));
	NORMAL = safe_normalize((VIEW_MATRIX*vec4(normal,0.0)).xyz);
	ROUGHNESS = 1.0;
}
