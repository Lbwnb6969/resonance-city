#ifndef CREATION_FOLIAGE_MOTION
#define CREATION_FOLIAGE_MOTION
#include "res://scripts/visual/shaders/creation_wind.gdshaderinc"
uniform float wind_time_override=-1.;
uniform vec2 touch_at=vec2(0.0);
uniform float touch_time=10.0;
vec3 creation_foliage_offset(vec3 world,float height){
	float clock=wind_time_override<0.?TIME:wind_time_override;
	float touched=exp(-touch_time*3.0)*sin(touch_time*13.0)*(1.0-smoothstep(0.,2.5,length(world.xz-touch_at)));
	vec3 drift=creation_wind_offset(world.xz,clock,.047)+vec3(touched*.10,0.,touched*.06);
	return drift*(height*height);
}
#endif
