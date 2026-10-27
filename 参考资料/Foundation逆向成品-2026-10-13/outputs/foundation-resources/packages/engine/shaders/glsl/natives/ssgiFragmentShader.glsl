
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
uniform samplerCube uniMapPrefilteredEnvMap; // Irradiance cubemap
uniform sampler2D uniMapDiffuse;

uniform sampler2D uniMapSsgiHistory;	// previous frame (resolved)
uniform sampler2D uniMapPrevDepth;

// uniform values
uniform mediump mat4 uniViewInverse;
uniform mediump mat4 uniProjInverse;
uniform mediump mat4 uniV;

uniform mediump mat4 uniMatPrevView;
uniform mediump mat4 uniPrevMatProjection;
uniform mediump mat4 uniPrevMatViewInverse;

uniform mediump vec2 uniTexelSize;
uniform mediump vec2 uniNoiseTexelSize;

uniform mediump float uniOccluderBias;
uniform mediump float uniProjScale;
uniform mediump float uniIntensity;
uniform mediump vec2 uniSsaoMinMaxRadius;
uniform mediump vec2  uniAttenuation;

uniform mediump float uniCamNear;
uniform mediump float uniCamFar;
uniform mediump vec2 uniCameraJitter;

uniform mediump vec3 uniLightColor;
uniform	mediump mat4 uniSkyMatrix;

uniform bool uniMipmapOptimization;
uniform bool uniTemporalDenoising;

// Number of per-pixel hemisphere slices. This has a big performance cost and should be kept as low as possible.
uniform mediump int uniRotationCount;

// Number of samples taken along one side of a given hemisphere slice. The total number of samples taken per pixel is rotationCount * stepCount * 2.
// This has a big performance cost and should be kept as low as possible.
uniform mediump int uniStepCount;

// Power function applied to AO to make it appear darker/lighter.
uniform mediump float uniAOIntensity;

// Intensity of the indirect diffuse light.
uniform mediump float uniGIIntensity;

// Intensity of the ambient light coming from a fallback source.
uniform mediump float uniFallbackIntensity;

// Power function applied to ambient source to make it appear darker/lighter.
uniform mediump float uniFallbackPower;

// Controls samples distribution. Exp Factor is an exponent applied at each step get increasing step size over the distance.
uniform mediump float uniExpFactor;

//Increase thickness linearly over distance (avoid losing detail over the distance)
uniform bool uniLinearThickness;

//Makes the sample distance in view space instead of world-space (helps having more detail up close).
uniform bool uniScreenSpaceSampling;

// Constant thickness value of objects on the screen in world space. Allows light to pass behind surfaces past that thickness value.
uniform mediump float uniThickness;

// Effective sampling radius in world space. AO and GI can only have influence within that radius.
uniform mediump float uniRadius;

uniform mediump float uniHemisphereScaling;

//Number of samples per rotation taken in the ambient source. Higer number can give more correct ambient estimation, but is more taxing on performance.
uniform mediump int uniFallbackSampleCount;

// How much light backface surfaces emit.
uniform mediump float uniBackfaceLighting;

// input
//in mediump vec3 gColor;
in vec2 var_attribUv;
out vec4 outColor;

//#define NORMAL_APPROXIMATION
#define PI 3.14159265359
#define HALF_PI (PI/2.0)
#define MAX_RAY 32

//------------------------------
// functions

//------------------------------
vec3 getNormal(in vec2 _uv, int mip)
{
	return normalize(textureLod(uniMapNormal, _uv, mip).xyz * 2.0 - 1.0);
}

// //------------------------------
// vec2 getRandom(in vec2 _uv)
// {
// 	return normalize(texture2D(uniMapNoise, _uv / uniTexelSize * uniNoiseTexelSize).xy * 2 - 1.0);
// }

//------------------------------
// Get View Space Position from the depth buffer
// https://mynameismjp.wordpress.com/2009/03/10/reconstructing-position-from-depth/
vec3 positionFromDepthTexture(sampler2D _texture, vec2 _uv, int _mip)
{
	// Get the depth value for this pixel
	float z = textureLod(_texture, _uv, _mip).x * 2.0 - 1.0;

    // Get x/w and y/w from the viewport position
    vec4 screenPosition = vec4(_uv * 2 - 1, z, 1.0);

    // Transform by the inverse projection matrix
    vec4 position = uniProjInverse * screenPosition;

    // Divide by w to get the view-space position
    return position.xyz / position.w;
}

vec3 positionFromDepth(vec2 _uv, int _mip)
{
	return positionFromDepthTexture(uniMapDepth, _uv, _mip);
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

	vec3 evalPos = positionFromDepth(_uv, 0);
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

//-----------------------------
// From Activision GTAO paper: https://www.activision.com/cdn/research/s2016_pbs_activision_occlusion.pptx
float SpatialOffsets(vec2 uv)
{
	ivec2 position = ivec2(uv / uniTexelSize);
	return 0.25 * float((position.y - position.x) & 3);
}

//-----------------------------
// Interleaved gradient function from Jimenez 2014 http://goo.gl/eomGso
float GradientNoise(vec2 position)
{
	return fract(52.9829189 * fract(dot(position, vec2( 0.06711056, 0.00583715))));
}

//-----------------------------
// From http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
float rand(vec2 co)
{
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt = dot(co.xy, vec2(a, b));
    float sn = mod(dt, 3.14);
    return fract(sin(sn) * c);
}

vec2 GTAOFastAcos(vec2 x)
{
    vec2 outVal = -0.156583 * abs(x) + HALF_PI;
    outVal *= sqrt(1.0 - abs(x));
    return vec2(x.x >= 0 ? outVal.x : PI - outVal.x, x.y >= 0 ? outVal.y : PI - outVal.y);
}

float GTAOFastAcos(float x)
{
    float outVal = -0.156583 * abs(x) + HALF_PI;
    outVal *= sqrt(1.0 - abs(x));
    return x >= 0 ? outVal : PI - outVal;
}

float Luminance(vec3 linearRgb)
{
    return dot(linearRgb, vec3(0.2126729, 0.7151522, 0.0721750));
}

uint ComputeOccludedBitfield(float minHorizon, float maxHorizon, inout uint globalOccludedBitfield, out uint numOccludedZones)
{
    uint startHorizonInt = uint(minHorizon * float(MAX_RAY));
    uint angleHorizonInt = uint(round(clamp(maxHorizon-minHorizon, 0.0, 1.0) * float(MAX_RAY)));
    uint angleHorizonBitfield = angleHorizonInt > 0 ? (0xFFFFFFFF << angleHorizonInt) : 0;
    uint currentOccludedBitfield = angleHorizonBitfield << startHorizonInt;
    currentOccludedBitfield = currentOccludedBitfield & (~globalOccludedBitfield);
    globalOccludedBitfield = globalOccludedBitfield | currentOccludedBitfield;
    numOccludedZones = bitCount(currentOccludedBitfield);
    return currentOccludedBitfield;
}

vec3 HorizonSampling(bool directionIsRight, float radius, vec3 posVS, vec2 slideDir_TexelSize, float initialRayStep,
    vec2 uv, vec3 viewDir, vec3 normalVS, float n, inout uint globalOccludedBitfield, vec3 planeNormal, vec2 _ScreenSize, vec3 realTangent, vec3 projNN)
{
	float stepRadius = uniScreenSpaceSampling ? (radius * (_ScreenSize.x / 2)) / float(uniStepCount) : max((radius * uniProjScale) / posVS.z, float(uniStepCount));
    stepRadius /= (float(uniStepCount) + 1);
    float radiusVS = max(1, float(uniStepCount-1)) * stepRadius;
    float samplingDirection = directionIsRight ? 1 : -1;
    vec3 col = vec3(0.0);
    vec3 lastSamplePosVS = posVS;

	for (uint j = 0; j < uniStepCount; j++)
    {
        int mipLevelOffset = 0;

        if (uniMipmapOptimization)
        {
			mipLevelOffset = int(min((j + 0) / 2, 4));
        }

        float offset = pow(abs((stepRadius * (j + initialRayStep)) / radiusVS), uniExpFactor) * radiusVS;
        float minimumOffsetInPixels = mipLevelOffset + 1;//pow(2.0, mipLevelOffset);
        vec2 uvOffset = (slideDir_TexelSize ) * max(offset, minimumOffsetInPixels + j * minimumOffsetInPixels);
        vec2 sampleUV = uv + uvOffset * samplingDirection;

        if(sampleUV.x <= 0 || sampleUV.y <= 0 || sampleUV.x >= 1 || sampleUV.y >= 1)
            break;

        vec3 samplePosVS = positionFromDepth(sampleUV, mipLevelOffset);
        vec3 pixelToSample = normalize(samplePosVS - posVS);
        float linearThicknessMultiplier = uniLinearThickness ? clamp(samplePosVS.z / uniCamFar, 0.0, 1.0) * 100 : 1;
        vec3 pixelToSampleBackface = normalize((samplePosVS - (linearThicknessMultiplier * viewDir * uniThickness )) - posVS);

        vec2 frontBackHorizon = vec2(dot(pixelToSample, viewDir), dot(pixelToSampleBackface, viewDir));
        frontBackHorizon = GTAOFastAcos(clamp(frontBackHorizon, -1, 1));
        frontBackHorizon = clamp(((samplingDirection * -frontBackHorizon) - n + HALF_PI) / PI, 0.0, 1.0);
        frontBackHorizon = clamp(frontBackHorizon*(1.0+1.5*PI/float(MAX_RAY))-1.5*HALF_PI/float(MAX_RAY), 0.0, 1.0); // Remamp bitfield on one sector narrower hemisphere
        frontBackHorizon = directionIsRight ? frontBackHorizon.yx : frontBackHorizon.xy; // Front/Back get inverted depending on angle

		// vec3 halfVector = normalize(pixelToSample + pixelToSampleBackface);
		// float hvDotT = dot(halfVector, -realTangent);
		// vec2 frontBackHorizon = vec2(dot(pixelToSample, -realTangent), dot(pixelToSampleBackface, -realTangent));
		// vec2 frontBackNormal = vec2(dot(pixelToSample, projNN), dot(pixelToSampleBackface, projNN));
		// frontBackHorizon = vec2(frontBackNormal.x < 0 ? sign(hvDotT) : frontBackHorizon.x, frontBackNormal.y < 0 ? sign(hvDotT) : frontBackHorizon.y);
		// frontBackHorizon = (frontBackHorizon * uniHemisphereScaling * 0.5 + 0.5 * uniHemisphereScaling);
		// frontBackHorizon.xy = frontBackHorizon.x <= frontBackHorizon.y ? frontBackHorizon.xy : frontBackHorizon.yx;

        uint numOccludedZones;
        ComputeOccludedBitfield(frontBackHorizon.x, frontBackHorizon.y, globalOccludedBitfield, numOccludedZones);

        vec3 lightNormalVS = vec3(0.0);
        if(numOccludedZones > 0) // If a ray hit the sample, that sample is visible from shading point
        {
            vec3 lightColor = textureLod(uniMapDiffuse, sampleUV, mipLevelOffset).rgb;
            if(Luminance(lightColor) > 0.001) // Continue if there is light at that location (intensity > 0)
            {
                vec3 lightDirectionVS = normalize(pixelToSample);
                float normalDotLightDirection = clamp(dot(normalVS, lightDirectionVS), 0.0, 1.0);

                if (normalDotLightDirection > 0.001) // Continue if light is facing surface normal
                {
                    #ifdef NORMAL_APPROXIMATION
                    lightNormalVS = -samplingDirection * cross(normalize(samplePosVS-lastSamplePosVS), planeNormal);
                    #else
                    vec3 lightNormalWS = getNormal(sampleUV, mipLevelOffset);
                    lightNormalVS = normalize(( uniV * vec4( lightNormalWS, 0.0 ) ).xyz);
                    #endif

                    // Intensity of outgoing light in the direction of the shading point
                    float lightNormalDotLightDirection = dot(lightNormalVS, -lightDirectionVS);
                    lightNormalDotLightDirection = uniBackfaceLighting > 0 && dot(lightNormalVS, viewDir) > 0 ?
                        (sign(lightNormalDotLightDirection) < 0 ? abs(lightNormalDotLightDirection) * uniBackfaceLighting : abs(lightNormalDotLightDirection)) :
                        clamp(lightNormalDotLightDirection, 0.0, 1.0);

                    col.xyz += (float(numOccludedZones)/float(MAX_RAY)) * lightColor * normalDotLightDirection * lightNormalDotLightDirection;
                }
            }
        }
        lastSamplePosVS = samplePosVS;
	}

	return col;
}

//------------------------------
// Main
void main()
{
	vec2 uv = var_attribUv;
	vec3 posViewSpace	= positionFromDepth(uv, 0);
	//vec2 randVec2		= getRandom(uv);
	vec3 normal			= getNormal(uv, 0);

	vec3 viewDir = normalize(-posViewSpace);
	vec2 _ScreenParams = 1.0 / uniTexelSize;
	vec3 normalVS = ( uniV * vec4( normal, 0.0 ) ).xyz;
	normalVS = normalize(normalVS);
	vec3 posVS = posViewSpace;

    vec3 directLight = texture2D(uniMapDiffuse, uv).rgb;

	float noiseOffset = SpatialOffsets(uv + uniCameraJitter * uniTexelSize);
    float noiseDirection = GradientNoise(uv * _ScreenParams + uniCameraJitter);
    //float initialRayStep = fract(noiseOffset /*+ _TemporalOffsets*/) ;//+ (rand(uv) * 2.0 - 1.0) * 1.0 * float(_JitterSamples);

	float ao = 0;
	vec3 col = vec3(0.0);
	float sliceWeight = 0;
	vec3 ambient = vec3(0.0);

	for (int i = 0; i < uniRotationCount; i++)
    {
		float initialRayStep = fract(noiseOffset /*+ _TemporalOffsets*/ + GradientNoise(ivec2(uv * _ScreenParams)+i));
        float rotationAngle = (i + noiseDirection /*+ _TemporalDirections*/) * (PI / float(uniRotationCount));
        vec3 sliceDir = vec3(cos(rotationAngle), sin(rotationAngle), 0);
        vec2 slideDir_TexelSize = sliceDir.xy * (1.0 / _ScreenParams.xy);
        uint globalOccludedBitfield = 0;

		vec3 planeNormal = normalize(cross(sliceDir, viewDir));
        vec3 tangent = cross(viewDir, planeNormal);
        vec3 projectedNormal = normalVS - planeNormal * dot(normalVS, planeNormal);
		float projNLen = length(projectedNormal);
        vec3 projectedNormalNormalized = normalize(projectedNormal);
        vec3 realTangent = cross(projectedNormalNormalized, planeNormal);

		float cos_n = clamp(dot(projectedNormalNormalized, viewDir), -1, 1);
        float n = -sign(dot(projectedNormal, tangent)) * GTAOFastAcos(cos_n);

        col += HorizonSampling(true, uniRadius, posVS, slideDir_TexelSize, initialRayStep, uv, viewDir, normalVS, n, globalOccludedBitfield, planeNormal, _ScreenParams, realTangent, projectedNormalNormalized);
        col += HorizonSampling(false, uniRadius, posVS, slideDir_TexelSize, initialRayStep, uv, viewDir, normalVS, n, globalOccludedBitfield, planeNormal, _ScreenParams, realTangent, projectedNormalNormalized);

		// Bent normal generation
		uint globalOccludedBitfieldCopy = globalOccludedBitfield;
        for (uint j = 0; j < uniFallbackSampleCount; j++)
        {
            uint maskSize = MAX_RAY/uniFallbackSampleCount;
            uint mask = 0xFFFFFFFF << (MAX_RAY - maskSize);
            uint hitCount = bitCount(globalOccludedBitfieldCopy & mask);

            float cosine = (1.0 - ((float(j)+0.5) / float(uniFallbackSampleCount))) * 2.0 - 1.0;
            float angleCosine = GTAOFastAcos(cosine);
            vec3 rayDir = normalize(realTangent * cos(angleCosine) + normalVS * sin(angleCosine));
            vec3 rayDirWS = normalize(( uniViewInverse * vec4( rayDir, 0.0 ) ).xyz);
            vec3 NSky = (uniSkyMatrix * vec4(rayDirWS, 0)).xyz;
            ambient += clamp(texture(uniMapPrefilteredEnvMap, NSky).rgb, 0.0, 1.0) * float(maskSize - hitCount) / float(MAX_RAY) * uniLightColor;

			globalOccludedBitfieldCopy <<= maskSize;
		}

        ao += (float(bitCount(globalOccludedBitfield)) / float(MAX_RAY)) * projNLen;
		sliceWeight += projNLen;
	}

    ambient /= float(uniRotationCount) ;//* float(uniFallbackSampleCount);
    ambient = clamp(vec3(pow(ambient.x, uniFallbackPower), pow(ambient.y, uniFallbackPower), pow(ambient.z, uniFallbackPower)) * uniFallbackIntensity, 0.0, 1.0);

	ao /= sliceWeight;//float(uniRotationCount);
    ao = clamp(pow(1.0-clamp(ao*0.99, 0.0, 1.0), uniAOIntensity), 0.0, 1.0);

    col /= float(uniRotationCount);
    col *= uniGIIntensity;

	vec4 frameSSGI = vec4(ambient + col, 1.0);//vec4(ao, bentNormalWS.r, bentNormalWS.g, bentNormalWS.b);

	if (uniTemporalDenoising)
	{
		vec4 worldPosition = uniViewInverse * vec4(posViewSpace, 1);
		vec4 prevFrameScreenCoord = uniPrevMatProjection * uniMatPrevView * worldPosition;
		prevFrameScreenCoord.xyz /= prevFrameScreenCoord.w;
		prevFrameScreenCoord.xyz *= 0.5;
		prevFrameScreenCoord.xyz += 0.5;

		vec4 prevFrameWorldCoord = uniPrevMatViewInverse * vec4(positionFromDepthTexture(uniMapPrevDepth, prevFrameScreenCoord.xy, 0), 1);
		float d = distance(prevFrameWorldCoord.xyz, worldPosition.xyz) /10;

		//vec2 velocity = texture2D(uniMapPrevDepth, uv).xy;
		//vec2 prevousPixelPos = uv - velocity * uniTexelSize;
		vec2 prevousPixelPos = prevFrameScreenCoord.xy;
		vec4 historySSGI = texture2D(uniMapSsgiHistory, prevousPixelPos);

		if (prevousPixelPos.x < 0 || prevousPixelPos.x > 1 || prevousPixelPos.y < 0 || prevousPixelPos.y > 1 || distance(prevFrameWorldCoord.xyz, worldPosition.xyz) > max(posViewSpace.z / 200, 0.1))
		{
			outColor = frameSSGI;
		}
		else
		{
			float modulationFactor = 0.9;
			outColor = mix(frameSSGI, historySSGI, modulationFactor);
		}
	}
	else
	{
		outColor = frameSSGI;
	}
}