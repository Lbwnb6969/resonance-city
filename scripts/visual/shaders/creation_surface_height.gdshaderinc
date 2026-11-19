uniform sampler2D terrain_height_field : filter_nearest, repeat_disable;
uniform bool terrain_height_enabled=false;
uniform vec4 terrain_height_rect=vec4(-48.,-48.,96.,96.);
uniform float terrain_height_step=.5;
float surface_vertex_height(ivec2 cell){
	return texelFetch(terrain_height_field,cell,0).r;
}
float terrain_surface_height(vec2 at){
	ivec2 last=textureSize(terrain_height_field,0)-ivec2(1);
	vec2 grid=(at-terrain_height_rect.xy)/terrain_height_step;
	ivec2 cell=clamp(ivec2(floor(grid)),ivec2(0),last-ivec2(1));
	vec2 f=clamp(grid-vec2(cell),vec2(0.),vec2(1.));
	float a=surface_vertex_height(cell),b=surface_vertex_height(cell+ivec2(1,0));
	float c=surface_vertex_height(cell+ivec2(1)),d=surface_vertex_height(cell+ivec2(0,1));
	// TerrainSurface and State both use the a-c diagonal, not bilinear quads.
	return f.x>=f.y ? a*(1.-f.x)+b*(f.x-f.y)+c*f.y : a*(1.-f.y)+c*f.x+d*(f.y-f.x);
}
vec3 terrain_vertex_normal(ivec2 cell, ivec2 last) {
	ivec2 dx=ivec2(1,0),dz=ivec2(0,1);
	float west=surface_vertex_height(max(cell-dx,ivec2(0)));
	float east=surface_vertex_height(min(cell+dx,last));
	float north=surface_vertex_height(max(cell-dz,ivec2(0)));
	float south=surface_vertex_height(min(cell+dz,last));
	return normalize(vec3(west-east,2.0*terrain_height_step,north-south));
}
vec3 terrain_surface_normal(vec2 at) {
	ivec2 last=textureSize(terrain_height_field,0)-ivec2(1);
	vec2 grid=(at-terrain_height_rect.xy)/terrain_height_step;
	ivec2 cell=clamp(ivec2(floor(grid)),ivec2(0),last-ivec2(1));
	vec2 part=clamp(grid-vec2(cell),vec2(0.0),vec2(1.0));
	bool lower=part.x>=part.y;
	vec3 first=terrain_vertex_normal(cell,last);
	vec3 diagonal=terrain_vertex_normal(cell+ivec2(1),last);
	vec3 corner=terrain_vertex_normal(cell+(lower ? ivec2(1,0) : ivec2(0,1)),last);
	return normalize(first*(1.0-max(part.x,part.y))+diagonal*min(part.x,part.y)+corner*abs(part.x-part.y));
}
