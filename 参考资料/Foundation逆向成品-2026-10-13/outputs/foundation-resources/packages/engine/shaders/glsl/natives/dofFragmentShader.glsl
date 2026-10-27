
uniform sampler2D uniMapDiffuse;
uniform sampler2D uniMapDepth;
uniform sampler2D uniMapNoise;
uniform sampler2D uniMapOcclusion;
uniform vec4 uniColor;

uniform float uniCamNear;
uniform float uniCamFar;

uniform vec2 uniTexelSize;

uniform vec2 uniAperture;
uniform vec2 uniPlaneInFocus;
uniform vec2 uniImageDistance;
uniform float uniDofMaxRadius;
uniform float uniDofQuality;

// input
in vec2 varTextCoord;

out mediump vec4 fragColor;

//------------------------------
vec2 getRandom(in vec2 _uv)
{
	return normalize(texture2D(uniMapNoise, _uv / uniTexelSize / 128).xy * 2.0 - 1.0);
}

//------------------------------
float getLinearDepth(float depth)
{
	return (uniCamNear * uniCamFar /(uniCamNear - uniCamFar)) / (depth - uniCamFar / (uniCamFar - uniCamNear));
}

//------------------------------
float readLinearDepth(vec2 uv)
{
	float depth = (texture2D(uniMapDepth, uv).r - 0.5) * 2;
	return getLinearDepth(depth);
}

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
	float d = getLinearDepth(depth);

	vec2 coc = getCoc(d);
	float cocNear = coc.x;
	float cocFar = coc.y;

	float cocNearMax = 0;
	if (uniAperture.x > 0)
		cocNearMax = texture2D(uniMapOcclusion, varTextCoord).r * uniDofMaxRadius;

	//fragColor = vec4(cocFar / uniDofMaxRadius, 0, 0, 1);
	//return;

	vec2 uv = varTextCoord;
	vec4 c = vec4(0);
	float count = 0;

	const float pi = 3.14159265359;

	vec4 c0 = texture2D(uniMapDiffuse, uv);
	c = c0;
	count += 1;

	float rnd = getRandom(uv).x;

	for (float i = 1; i <= cocFar; i += uniDofQuality)
	{
		int step = int(pi * i * 2 / uniDofQuality);

		for (int j = 0; j < step; ++j)
		{
			float angle = 2 * pi * j / step + rnd;

			vec2 uv2 = clamp(uv + vec2(cos(angle) * uniTexelSize.x * i, sin(angle) * uniTexelSize.y * i), vec2(0, 0), vec2(1, 1));

			float depth2 = (texture2D(uniMapDepth, uv2).r - 0.5) * 2;
			float d2 = getLinearDepth(depth2);
			float cocFarOther = getCoc(d2).y;

			c += texture2D(uniMapDiffuse, uv2) * cocFarOther;
			count += cocFarOther;
		}
	}

	if (cocNearMax > 1)
	{
		//fragColor = vec4(cocNearMax / uniDofMaxRadius, 0, 0, 1);
		//return;

		vec4 cBackup = c;

		for (float i = 1; i <= cocNearMax; i += uniDofQuality)
		{
			int step = int(pi * i * 2 / uniDofQuality);

			for (int j = 0; j < step; ++j)
			{
				float angle = 2 * pi * j / step + getRandom(uv).x;

				vec2 uv2 = clamp(uv + vec2(cos(angle) * uniTexelSize.x * i, sin(angle) * uniTexelSize.y * i), vec2(0, 0), vec2(1, 1));

				float depth2 = (texture2D(uniMapDepth, uv2).r - 0.5) * 2;
				float d2 = getLinearDepth(depth2);
				float cocOtherNear = getCoc(d2).x;
				//float cocOther = getCoc(d2).y;

				/*if (i <= cocOtherNear)
				{
					//fragColor = vec4(cocNearMax / uniDofMaxRadius, 0, 0, 1);
					//return;
					float w = 1 - i / uniDofMaxRadius;
					c2 += texture2D(uniMapDiffuse, uv2) * w;
					count2 += w;
				}*/
				/*else
				{
					c += cBackup;
				}*/

				c += texture2D(uniMapDiffuse, uv2);
				count += 1;

			}
		}

		//fragColor = c2 / count2;
		//return;
	}

	fragColor = c / count;
	return;
}