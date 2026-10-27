
//------------------------------
// inputs

in mediump vec4 varMvpPosition;

#if defined(RASTERIZATION_DIFFUSE_SHADING)
	in mediump vec3 varNormal;
#endif

//------------------------------
// uniforms

#if defined(RASTERIZATION_DIFFUSE_SHADING)
	uniform vec3 uniLightDir;
#endif

//------------------------------
// out

out mediump vec4 fragColor;

void main()
{
	#if defined(RASTERIZATION_DIFFUSE_SHADING)
		float diffuseStrenght = max(dot(varNormal, uniLightDir), 0.0);
		fragColor = vec4(vec3(diffuseStrenght), 1);
	#elif defined(RASTERIZATION_HEIGHTMAP)
		vec4 finalColor = vec4(vec3(varMvpPosition.z), 1);
		fragColor = finalColor;
	#endif
}