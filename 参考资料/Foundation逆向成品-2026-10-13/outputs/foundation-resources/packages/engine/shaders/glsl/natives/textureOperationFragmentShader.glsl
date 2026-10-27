
//------------------------------
// inputs

in mediump vec4 varMvpPosition;

//------------------------------
// uniforms

uniform sampler2D uniTextureA;
uniform sampler2D uniTextureB;
uniform sampler2D uniTextureC;
uniform mediump int uniHasClamp;
uniform mediump vec3 uniClampValue;

// OPERATION_HEIGHTMAP_TO_NORMAL_MAP
uniform mediump vec2 uniMinMaxHeight;
uniform mediump vec2 uniTileSize;
uniform mediump vec2 uniTexelSize;

//------------------------------
// out

out mediump vec4 fragColor;

void main()
{
	// remap vertex position range [-1;1] to texture coordinate range [0;1]
	mediump vec2 textCoor = varMvpPosition.xy * 0.5 + 0.5;

	#if defined(OPERATION_ADD)

		mediump vec4 a = texture2D(uniTextureA, textCoor);
		mediump vec4 b = texture2D(uniTextureB, textCoor);

		mediump vec4 finalColor = a + b;
		finalColor.a = a.a;

		if (uniHasClamp != 0)
		{
			finalColor.rgb = min(finalColor.rgb, uniClampValue);
		}

	#elif defined(OPERATION_SUBTRACT)

		mediump vec4 a = texture2D(uniTextureA, textCoor);
		mediump vec4 b = texture2D(uniTextureB, textCoor);

		mediump vec4 finalColor = a - b;
		finalColor.a = a.a;

		if (uniHasClamp != 0)
		{
			finalColor.rgb = max(finalColor.rgb, uniClampValue);
		}

	#elif defined(OPERATION_INVERT)

		mediump vec4 a = texture2D(uniTextureA, textCoor);
		mediump vec4 finalColor = 1.0 - a;
		finalColor.a = a.a;

	#elif defined(OPERATION_SCALE)

		mediump vec4 finalColor = texture2D(uniTextureA, textCoor);

	#elif defined(OPERATION_MERGE_RGB)

		mediump vec4 finalColor = vec4(
			texture2D(uniTextureA, textCoor).r,
			texture2D(uniTextureB, textCoor).r,
			texture2D(uniTextureC, textCoor).r,
			1.0
		);

	#elif defined(OPERATION_HEIGHTMAP_TO_NORMAL_MAP)

		mediump float heightRange = uniMinMaxHeight.y - uniMinMaxHeight.x;
		mediump float texelWidth = uniTexelSize.x;
		mediump float texelHeight = uniTexelSize.y;

		mediump float height = texture2D(uniTextureA, textCoor).r * heightRange;
		mediump float leftHeight = texture2D(uniTextureA, vec2(clamp(textCoor.x - texelWidth, 0, 1), textCoor.y)).r * heightRange;
		mediump float rightHeight = texture2D(uniTextureA, vec2(clamp(textCoor.x + texelWidth, 0, 1), textCoor.y)).r * heightRange;
		mediump float forwardHeight = texture2D(uniTextureA, vec2(textCoor.x, clamp(textCoor.y + texelHeight, 0, 1))).r * heightRange;
		mediump float backwardHeight = texture2D(uniTextureA, vec2(textCoor.x, clamp(textCoor.y - texelHeight, 0, 1))).r * heightRange;

		vec3 left = vec3(		-uniTileSize.x, 	leftHeight - height, 		0);
		vec3 right = vec3(		uniTileSize.x, 		rightHeight - height, 		0);
		vec3 forward = vec3(	0, 					forwardHeight - height, 	uniTileSize.y);
		vec3 backward = vec3(	0, 					backwardHeight - height, 	-uniTileSize.y);

		vec3 normal = cross(left, forward) + cross(forward, right) + cross(right, backward) + cross(backward, left);
		normal = normalize(normal);

		mediump vec4 finalColor = vec4((normal + 1) * 0.5f, 1.0);

	#endif


	fragColor = finalColor;
}