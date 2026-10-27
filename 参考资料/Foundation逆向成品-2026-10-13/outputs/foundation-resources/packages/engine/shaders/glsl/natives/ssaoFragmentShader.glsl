
//------------------------------
#define SSAO 1

//------------------------------
// uniforms
/*
uniform mediump mat4 		uniViewInverse;
uniform mediump mat4 		uniProjInverse;
uniform mediump mat4 		uniVpInverse;

uniform mediump vec3 		uniCameraPosition;

uniform mediump vec2		uniTexelSize;
uniform mediump int			uniSampleSize;
*/

//===============================================================================
// IMPORT FROM ssao_simple.frag
//===============================================================================


// uniform textures
uniform sampler2D uniMapDepth;
uniform sampler2D uniMapNormal;
uniform sampler2D uniMapNoise;

// uniform values
//uniform mediump mat4 uniProjInverse;
uniform mediump mat4 uniVpInverse;


uniform mediump vec2 uniTexelSize;
uniform mediump vec2  uniNoiseTexelSize;

uniform mediump float uniOccluderBias;
uniform mediump float uniSsaoRadius;
uniform mediump float uniIntensity;
uniform mediump vec2 uniSsaoMinMaxRadius;
uniform mediump vec2  uniAttenuation;

uniform mediump float uniCamNear;
uniform mediump float uniCamFar;

// input
//in mediump vec3 gColor;
in vec2 var_attribUv;

out mediump vec4 fragColor;

//------------------------------
// functions

//------------------------------
vec3 getNormal(in vec2 _uv)
{
	return normalize(texture2D(uniMapNormal, _uv).xyz * 2.0 - 1.0);
}

//------------------------------
vec2 getRandom(in vec2 _uv)
{
	return normalize(texture2D(uniMapNoise, _uv / uniTexelSize * uniNoiseTexelSize).xy * 2 - 1.0);
}

//------------------------------
// Get View Space Position from the depth buffer
// https://mynameismjp.wordpress.com/2009/03/10/reconstructing-position-from-depth/
vec3 positionFromDepth(vec2 _uv)
{
	// Get the depth value for this pixel
	float z = texture2D(uniMapDepth, _uv).x * 2.0 - 1.0;

    // Get x/w and y/w from the viewport position
    vec4 screenPosition = vec4(_uv * 2 - 1, z, 1.0);

    // Transform by the inverse projection matrix
    vec4 position = uniVpInverse * screenPosition;

    // Divide by w to get the view-space position
    return position.xyz / position.w;
}

//------------------------------
float random(vec2 _co)
{
    return fract(sin(dot(_co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

//------------------------------
float evalOcclusion(vec3 _position, vec3 _normal, vec2 _uv)
{
	_uv = clamp(_uv, vec2(0), vec2(0.999));

	vec3 evalPos = positionFromDepth(_uv);
	vec3 evalDir = evalPos - _position;
	// occlusion factor
	float bias = uniOccluderBias;// 0.15

	float occ = max(dot(normalize(evalDir), _normal) - bias, 0.0);
	// Attenuation
	float dist = length(evalDir);
	float att1 = uniAttenuation.x; // 1
	float att2 = uniAttenuation.y; // 0.5
	float attenuation = 1.0 / (att1 + (att2 * dist * dist));
	return occ * attenuation;
}

//-----------------------------
// Linearise Depth
float getLinearDepth(vec2 _uv)
{
	float z_b = texture2D(uniMapDepth, _uv).x;
	float z_n = 2.0 * z_b - 1.0;
	float z_e = 2.0 * uniCamNear * uniCamFar / (uniCamFar + uniCamNear - z_n * (uniCamFar - uniCamNear));
	//float z_e = 2.0 * uniCamFar * uniCamNear / (uniCamNear + uniCamFar - z_n * (uniCamNear - uniCamFar));

	return z_e;
}

//------------------------------
// Main
void main()
{
	vec2 uv = var_attribUv;
	vec3 posViewSpace	= positionFromDepth(uv);
	vec2 randVec2		= getRandom(uv);
	vec3 normal			= getNormal(uv);
	//vec3 normalSample	= getNormal(uv);
	//vec3 normal		= normalSample.xyz;
	//float outputcoef	= normalSample.w;

	float z = getLinearDepth(uv);

	// Sample neighbouring pixels
	vec2 kernel[4];
	kernel[0] = vec2(0.0, 1.0);  // top
	kernel[1] = vec2(1.0, 0.0);  // right
	kernel[2] = vec2(0.0, -1.0); // bottom2
	kernel[3] = vec2(-1.0, 0.0); // left


	// Sample from 16 pixels, which should be enough to appromixate a result. You can
	// sample from more pixels, but it comes at the cost of performance.
	float occlusion = 0.0;

	float radius = uniSsaoRadius;
	float kernelRadius = clamp(radius / z, uniSsaoMinMaxRadius.x, uniSsaoMinMaxRadius.y);
	const float Sin45 = 0.707107; // 45 degrees = sin(PI / 4)
	for (int i = 0; i < 4; ++i)
	{
		vec2 k1 = reflect(kernel[i], randVec2);

		vec2 k2 = vec2(k1.x * Sin45 - k1.y * Sin45,
					   k1.x * Sin45 + k1.y * Sin45);

		//k1 *= uniTexelSize;
		//k2 *= uniTexelSize;

		occlusion += evalOcclusion(posViewSpace, normal, uv + k1 * kernelRadius);
		occlusion += evalOcclusion(posViewSpace, normal, uv + k2 * kernelRadius * 0.75);
		occlusion += evalOcclusion(posViewSpace, normal, uv + k1 * kernelRadius * 0.5);
		occlusion += evalOcclusion(posViewSpace, normal, uv + k2 * kernelRadius * 0.25);
	}

	// Average and clamp ambient occlusion
	occlusion /= 16;
	occlusion *= uniIntensity;
	occlusion = 1.0 - clamp(occlusion, 0, 1);
	occlusion *= occlusion;

	//occlusion = 1;
	//occlusion = 1.0 - z;// < 0.9 ? 0.0 : (1.0f - z) * 10;
	//fragColor = texture2D(uniMapNoise, uv);

	fragColor = vec4(occlusion);
	//fragColor = vec4(z / 50);
	//fragColor = vec4(normal, 1); // TMP DEBG

	//fragColor = normalSample;
	//fragColor.xyz = positionFromDepth(uv).xyz;
}