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
