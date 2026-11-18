#ifndef CREATION_PAINT_COLOR_INCLUDED
#define CREATION_PAINT_COLOR_INCLUDED
// Raw vertex paint and literal palette colors are authored in sRGB. Uniforms
// marked source_color already follow the renderer and must not enter here.
vec3 creation_paint_color(vec3 color) {
	if (OUTPUT_IS_SRGB) { return color; }
	return mix(color/12.92,pow((color+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),color));
}
#endif
