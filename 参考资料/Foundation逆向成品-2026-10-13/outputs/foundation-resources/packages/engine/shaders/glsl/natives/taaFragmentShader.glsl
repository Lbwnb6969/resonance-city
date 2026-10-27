uniform sampler2D uniMapDiffuse;	// current frame
uniform sampler2D uniMapSpecular;	// previous frame (resolved)
uniform sampler2D uniMapNormal;		// motion vectors

uniform vec2 uniTexelSize;
uniform float uniPrevFrameWeight;

in vec2 varUv;
out vec4 outColor;

void main()
{
    vec2 velocity = texture2D(uniMapNormal, varUv).xy;
	vec2 prevousPixelPos = varUv - velocity * uniTexelSize;

	vec4 currentColor = texture2D(uniMapDiffuse, varUv);
	vec4 historyColor = texture2D(uniMapSpecular, prevousPixelPos);

	if (prevousPixelPos.x < 0 || prevousPixelPos.x > 1 || prevousPixelPos.y < 0 || prevousPixelPos.y > 1)
	{
		outColor = currentColor;
	}
	else
	{
		// Apply clamping on the history color
		vec4 NearColor0 = texture2D(uniMapDiffuse, varUv + vec2(uniTexelSize.x, 0));
		vec4 NearColor1 = texture2D(uniMapDiffuse, varUv + vec2(0, uniTexelSize.y));
		vec4 NearColor2 = texture2D(uniMapDiffuse, varUv + vec2(-uniTexelSize.x, 0));
		vec4 NearColor3 = texture2D(uniMapDiffuse, varUv + vec2(0, -uniTexelSize.y));

		vec4 BoxMin = min(currentColor, min(NearColor0, min(NearColor1, min(NearColor2, NearColor3))));
		vec4 BoxMax = max(currentColor, max(NearColor0, max(NearColor1, max(NearColor2, NearColor3))));

		//*
		historyColor = clamp(historyColor, BoxMin, BoxMax);
		vec4 modulationFactor = vec4(uniPrevFrameWeight);
		/*/
		vec4 distance = max(
			max(vec4(0), BoxMin - historyColor),
			max(vec4(0), historyColor - BoxMax));

		vec4 modulationFactor = mix(vec4(uniPrevFrameWeight), vec4(0.0), min(distance * 10.0, 1.0f));//*/

		outColor = mix(currentColor, historyColor, modulationFactor);
	}
}