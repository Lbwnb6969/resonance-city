
uniform sampler2D uniMapDepth;

uniform float uniCamNear;
uniform float uniCamFar;

uniform vec2 uniAperture;
uniform vec2 uniPlaneInFocus;
uniform vec2 uniImageDistance;
uniform float uniDofMaxRadius;

// input
in vec2 varTextCoord;

out mediump vec4 fragColor;

//------------------------------
vec2 getCoc(float d)
{
	vec2 a = uniAperture; // aperture
	vec2 p = uniPlaneInFocus * 0.5; // plane in focus
	vec2 i = uniImageDistance; // image distance
	vec2 f = vec2(1) / (vec2(1) / p + vec2(1) / i); // focal length
	
	vec2 coc = a * f * (p - d) / (d * (p - f));
	return clamp(vec2(coc.x, -coc.y), vec2(0), vec2(uniDofMaxRadius));
}

//------------------------------
// Main
void main()
{
	float depth = (texture2D(uniMapDepth, varTextCoord).r - 0.5) * 2;
	float d = (uniCamNear * uniCamFar /(uniCamNear - uniCamFar)) / (depth - uniCamFar / (uniCamFar - uniCamNear));
	
	float cocNear = getCoc(d).x;
	fragColor = vec4(cocNear, cocNear, cocNear, 1);
}