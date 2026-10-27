
//------------------------------
#define WINDOW_HALF_SIZE 3
#define WINDOW_SIZE ( WINDOW_HALF_SIZE * 2 + 1 )

//------------------------------
// inputs

//in vec2 varTextCoord;
in mediump vec4 varMvpPosition;

//------------------------------
// uniforms

uniform sampler2D 	uniMapDiffuse;
uniform sampler2D 	uniMapSpecular;
uniform sampler2D 	uniMapNormal;
uniform sampler2D 	uniMapHeight;
uniform sampler2D 	uniMapGlow;
uniform sampler2D 	uniMapOcclusion;

uniform mediump mat4 		uniViewInverse;
uniform mediump mat4 		uniProjInverse;
uniform mediump mat4 		uniVpInverse;

uniform mediump vec3 		uniCameraPosition;

uniform mediump float 		uniBlurKernel[BLUR_KERNEL_SIZE];
uniform int 				uniKernelHalfSize;

#ifdef ENABLE_DOF
uniform sampler2D 	uniMapDofValues;
uniform sampler2D 	uniMapDofColorBlured;
#endif

#ifndef LIGHT_NONE
uniform mediump vec3 		uniLightColor;
uniform mediump float 		uniLightShinniness;
uniform	mediump vec3 		uniLightSpecularColor;
uniform	mediump float 		uniLightSpecularIntensity;
#elif defined(ENABLE_DEFERRED_RENDERING)
uniform mediump vec3 		uniAmbientColor;
#endif

#if defined(ENABLE_V_BI_DEPTH) || defined(ENABLE_H_BI_DEPTH)
uniform sampler2D 			uniMapDepth;
uniform float				uniCamNear;
uniform float				uniCamFar;
#endif

#ifdef MAP_SHADOW
uniform sampler2D 	uniMapShadow;
uniform mediump mat4 		uniSpace2texture;
uniform mediump float 		uniShadowTexelSize;
#endif

#if defined(LIGHT_DIRECTIONAL) || defined( LIGHT_SPOT)
uniform mediump vec3 		uniLightDir;
#endif

#if ! defined(LIGHT_NONE) && ! defined(LIGHT_DIRECTIONAL)
uniform mediump vec3 		uniLightPos;
uniform mediump float 		uniLightConstantAttenuation;
uniform mediump float 		uniLightLinearAttenuation;
uniform mediump float 		uniLightQuadraticAttenuation;
#endif

#ifdef LIGHT_SPOT
uniform mediump float 		uniLightCutOff;
#endif


uniform mediump vec2		uniTexelSize;
uniform mediump int			uniSampleSize;


//------------------------------

#ifdef ENABLE_MRT
	//*
	out vec4 FRAG_COLOR;
	out vec4 FRAG_NORMALS;
	out vec4 FRAG_GLOW;
	out vec4 FRAG_DOF;//*/
	/*
	#define FRAG_COLOR 		gl_FragData[0]
	#define FRAG_NORMALS	gl_FragData[1]
	#define FRAG_GLOW 		gl_FragData[1]
	#define FRAG_DOF 		gl_FragData[3] //*/
#else
	#define FRAG_COLOR fragColor
#endif

#define BI_DEPTH_MAX_DEPTH_OFFSET 0.1

//------------------------------
// out

out mediump vec4 fragColor;

void main()
{
	mediump vec2 textCoor = ( varMvpPosition.xy / varMvpPosition.w ) * 0.5 + 0.5;

	#ifdef ENABLE_DEFERRED_RENDERING

		// compute world position
		mediump float z = texture2D( uniMapHeight, textCoor ).x;
		gl_FragDepth = z;

		#ifdef LIGHT_NONE
			mediump vec4 finalColor = texture2D( uniMapDiffuse, textCoor );
			finalColor = vec4( finalColor.xyz * uniAmbientColor, finalColor.w );
		#else
			// compute world normal
			mediump vec3 normal = texture2D( uniMapNormal, textCoor ).xyz * 2.0;

			mediump vec3 finalColor3 = vec3( 0.0 );

			// there is a normal
			if( length( normal ) > 0.2f )
			{
				normal = normal - vec3( 1.0 );
				//normal = ( uniViewInverse * vec4( normal, 0.0 ) ).xyz;

				// compute world position
				z = z * 2 - 1.0;
				mediump vec4 position = vec4( varMvpPosition.xy / varMvpPosition.w, z, 1.0 );
				position = uniVpInverse * position;
				position = position / position.w;
				//gl_FragDepth = z * 0.5 + 0.5;

				// camera position
				mediump vec3 cameraDirection = normalize( uniCameraPosition - position.xyz );

				// diffuse & specular colors
				mediump vec3 diffuse = texture2D( uniMapDiffuse, textCoor ).xyz;
				mediump vec3 specular = texture2D( uniMapSpecular, textCoor ).xyz;

				#ifdef LIGHT_DIRECTIONAL
					mediump vec3 lightDirection = uniLightDir;
					float attenuation = 1.0f;
				#else
					mediump vec3 lightDirection = position.xyz - uniLightPos;
					mediump float lightDistance = length( lightDirection );
					lightDirection = normalize( lightDirection );
					mediump float attenuation = clamp( 1.0 / ( uniLightConstantAttenuation + uniLightLinearAttenuation * lightDistance + uniLightQuadraticAttenuation * lightDistance * lightDistance ), 0.0, 1.0 );
				#endif

				#ifdef LIGHT_SPOT
					mediump float cosAngle = dot( lightDirection, -uniLightDir );
					attenuation = attenuation * clamp( ( cosAngle - uniLightCutOff ) / 0.1, 0.0, 1.0 );
				#endif

				mediump vec3 reflect = reflect( lightDirection, normal );
				// compute lightning
				mediump float ligthing = max( 0, -dot( normal, lightDirection ) );
				mediump float specularLighting = pow( max( 0, dot( reflect, normalize( cameraDirection ) ) ), uniLightShinniness ) * uniLightSpecularIntensity;


				finalColor3 = ( uniLightColor * diffuse * ligthing + specularLighting * uniLightSpecularColor * specular ) * attenuation ;


				/*finalColor3.r = clamp( finalColor3.r, 0.0, 0.1 );
				finalColor3.g = clamp( finalColor3.g, 0.0, 0.1 );
				finalColor3.b = clamp( finalColor3.b, 0.0, 0.1 );*/

				//finalColor3 = normal;

				#ifdef MAP_SHADOW
				{
					mediump vec4 shadowTexCoordAdjust = uniSpace2texture * position;
					shadowTexCoordAdjust = shadowTexCoordAdjust / shadowTexCoordAdjust.w;

					// Used to lower moiré pattern and self-shadowing
					mediump float z = shadowTexCoordAdjust.z + 0.004;

					mediump float shadow = 0.0;

					mediump float textX = shadowTexCoordAdjust.x / uniShadowTexelSize;
					mediump float textY = shadowTexCoordAdjust.y / uniShadowTexelSize;
					mediump float wx = ( textX - floor( textX ) ) * 2.0 - 1.0;
					mediump float wy = ( textY - floor( textY ) ) * 2.0 - 1.0;

					if( finalColor3 != vec3( 0 ) )
					{
						float dx, dy, d;
						float weight = 0.0;

						for( int x = 0; x < WINDOW_SIZE; ++ x )
						{
							for( int y = 0; y < WINDOW_SIZE; ++ y )
							{
								dx = float( x - WINDOW_HALF_SIZE );
								dy = float( y - WINDOW_HALF_SIZE );
								d = 1.0 / ( abs( dx - wx ) + abs( dy - wy ) + 1.0 );
								shadow += texture2D( uniMapShadow, vec2( shadowTexCoordAdjust.x + dx * uniShadowTexelSize, shadowTexCoordAdjust.y + dy * uniShadowTexelSize ) ).r < z ? 0.0 : d;
								weight += d;
							}
						}

						shadow /= weight;
					}

					finalColor3 *= shadow;
				}
				#endif
			}

			#ifdef LIGHT_POINT
				//finalColor3 = uniLightColor * 0.05;
			#endif


			mediump vec4 finalColor = vec4( finalColor3, 1.0 );
			//vec4 finalColor = vec4( 0.0, 0.0, 0.0, 1.0 );
		#endif

		#ifdef ENABLE_GLOW
			#ifdef LIGHT_POINT
				FRAG_GLOW = vec4( 0, 0, 0, 1 );
			#else
				mediump vec4 glowColor = texture2D( uniMapGlow, textCoor );
				glowColor.a = 1.0;
				FRAG_GLOW = glowColor;
			#endif
		#endif

	#elif defined(ENABLE_V_BLUR)

		mediump vec4 finalColor = vec4(0.0);

	    // blur in y (vertical)
		for (int i = 0; i <= uniKernelHalfSize; ++i)
		{
			finalColor += texture2D(uniMapDiffuse, vec2(clamp(textCoor.x - i * uniTexelSize.x, 0, 1), textCoor.y)) * uniBlurKernel[i];
		}

		for (int i = 1; i <= uniKernelHalfSize; ++i)
		{
			finalColor += texture2D(uniMapDiffuse, vec2(clamp(textCoor.x + i * uniTexelSize.x, 0, 1), textCoor.y)) * uniBlurKernel[i];
		}

		finalColor.a = 1.0;

	#elif defined(ENABLE_H_BLUR)

		mediump vec4 finalColor = vec4(0.0);

	   // blur in x (horizontal)
		for (int i = 0; i <= uniKernelHalfSize; ++i)
		{
			finalColor += texture2D(uniMapDiffuse, vec2(textCoor.x, clamp(textCoor.y - i * uniTexelSize.y, 0, 1))) * uniBlurKernel[i];
		}

		for (int i = 1; i <= uniKernelHalfSize; ++i)
		{
			finalColor += texture2D(uniMapDiffuse, vec2(textCoor.x, clamp(textCoor.y + i * uniTexelSize.y, 0, 1))) * uniBlurKernel[i];
		}

	    finalColor.a = 1.0;

	#elif defined(ENABLE_V_MAX)

		mediump vec4 finalColor = vec4(0.0);

		for (int i = -uniKernelHalfSize; i <= uniKernelHalfSize; ++i)
		{
			//float w = 1 - float(abs(i)) / (uniKernelHalfSize + 1);
			//finalColor = max(finalColor, texture2D(uniMapDiffuse, vec2(clamp(textCoor.x + i * uniTexelSize.x, 0, 1), textCoor.y)) * w);
			finalColor = max(finalColor, texture2D(uniMapDiffuse, vec2(clamp(textCoor.x + i * uniTexelSize.x, 0, 1), textCoor.y)));
		}

		finalColor.a = 1.0;

	#elif defined(ENABLE_H_MAX)

		mediump vec4 finalColor = vec4(0.0);

		for (int i = -uniKernelHalfSize; i <= uniKernelHalfSize; ++i)
		{
			//float w = 1 - float(abs(i)) / (uniKernelHalfSize + 1);
			//finalColor = max(finalColor, texture2D(uniMapDiffuse, vec2(textCoor.x, clamp(textCoor.y + i * uniTexelSize.y, 0, 1))) * w);
			finalColor = max(finalColor, texture2D(uniMapDiffuse, vec2(textCoor.x, clamp(textCoor.y + i * uniTexelSize.y, 0, 1))));
		}

		finalColor.a = 1.0;


	#elif defined(ENABLE_V_BI_DEPTH)

		mediump vec4 finalColor = texture2D(uniMapDiffuse, textCoor) * uniBlurKernel[0];
		float w = uniBlurKernel[0];

		float z_b = texture2D(uniMapDepth, textCoor).x;
		float z_n = 2.0 * z_b - 1.0;
		float z_ref = 2.0 * uniCamNear * uniCamFar / (uniCamFar + uniCamNear - z_n * (uniCamFar - uniCamNear));

	    // blur in y (vertical)
		for (int i = 1; i <= uniKernelHalfSize; ++i)
		{
			vec2 uv = vec2(clamp(textCoor.x - i * uniTexelSize.x, 0, 1), textCoor.y);

			z_b = texture2D(uniMapDepth, uv).x;
			z_n = 2.0 * z_b - 1.0;
			float z_e = 2.0 * uniCamNear * uniCamFar / (uniCamFar + uniCamNear - z_n * (uniCamFar - uniCamNear));

			float factor = 1.0 - step(BI_DEPTH_MAX_DEPTH_OFFSET, abs(z_e - z_ref));
			//if (abs(z_e - z_ref) > 0.1)
			//{
			//	break;
			//}

			finalColor += texture2D(uniMapDiffuse, uv) * uniBlurKernel[i] * factor;
			w += uniBlurKernel[i] * factor;
		}

		for (int i = 1; i <= uniKernelHalfSize; ++i)
		{
			vec2 uv = vec2(clamp(textCoor.x + i * uniTexelSize.x, 0, 1), textCoor.y);

			z_b = texture2D(uniMapDepth, uv).x;
			z_n = 2.0 * z_b - 1.0;
			float z_e = 2.0 * uniCamNear * uniCamFar / (uniCamFar + uniCamNear - z_n * (uniCamFar - uniCamNear));

			float factor = 1.0 - step(BI_DEPTH_MAX_DEPTH_OFFSET, abs(z_e - z_ref));
			//if (abs(z_e - z_ref) > 0.1)
			//{
			//	break;
			//}

			finalColor += texture2D(uniMapDiffuse, uv) * uniBlurKernel[i] * factor;
			w += uniBlurKernel[i] * factor;
		}

		finalColor.rgba /= w;

	#elif defined(ENABLE_H_BI_DEPTH)

		mediump vec4 finalColor = texture2D(uniMapDiffuse, textCoor) * uniBlurKernel[0];
		float w = uniBlurKernel[0];

		float z_b = texture2D(uniMapDepth, textCoor).x;
		float z_n = 2.0 * z_b - 1.0;
		float z_ref = 2.0 * uniCamNear * uniCamFar / (uniCamFar + uniCamNear - z_n * (uniCamFar - uniCamNear));

		// blur in x (horizontal)
		for (int i = 1; i <= uniKernelHalfSize; ++i)
		{
			vec2 uv = vec2(textCoor.x, clamp(textCoor.y - i * uniTexelSize.y, 0, 1));

			z_b = texture2D(uniMapDepth, uv).x;
			z_n = 2.0 * z_b - 1.0;
			float z_e = 2.0 * uniCamNear * uniCamFar / (uniCamFar + uniCamNear - z_n * (uniCamFar - uniCamNear));

			float factor = 1.0 - step(BI_DEPTH_MAX_DEPTH_OFFSET, abs(z_e - z_ref));
			//if (abs(z_e - z_ref) > 0.1)
			//{
			//	break;
			//}

			finalColor += texture2D(uniMapDiffuse, uv) * uniBlurKernel[i] * factor;
			w += uniBlurKernel[i] * factor;
		}

		for (int i = 1; i <= uniKernelHalfSize; ++i)
		{
			vec2 uv = vec2(textCoor.x, clamp(textCoor.y + i * uniTexelSize.y, 0, 1));

			z_b = texture2D(uniMapDepth, uv).x;
			z_n = 2.0 * z_b - 1.0;
			float z_e = 2.0 * uniCamNear * uniCamFar / (uniCamFar + uniCamNear - z_n * (uniCamFar - uniCamNear));

			float factor = 1.0 - step(BI_DEPTH_MAX_DEPTH_OFFSET, abs(z_e - z_ref));
			//if (abs(z_e - z_ref) > 0.1)
			//{
			//	break;
			//}

			finalColor += texture2D(uniMapDiffuse, uv) * uniBlurKernel[i] * factor;
			w += uniBlurKernel[i] * factor;
		}

		finalColor.rgba /= w;
	#else
		mediump vec4 finalColor = texture2D( uniMapDiffuse, textCoor );

		#ifdef ENABLE_GLOW
			mediump vec4 glowColor = texture2D( uniMapGlow, textCoor );
			//glowColor.a = 1.0;
			FRAG_GLOW = glowColor;
			//FRAG_GLOW = vec4( 1.0 );
		#endif

		#ifdef ENABLE_DOF
			mediump float dof = texture2D( uniMapDofValues, textCoor ).r;
			mediump vec4 bluredColor = texture2D( uniMapDofColorBlured, textCoor );
			finalColor = bluredColor * dof + finalColor * ( 1.0 - dof );
		#endif

	#endif

	#ifdef ENABLE_POST_BLEND_MULTIPLY
		finalColor.rgb *= texture2D(uniMapNormal, textCoor).rgb; // NB: texture to multiply is stored in NORMAL channel
	#endif

	FRAG_COLOR = finalColor;
}