
in vec3 attribPosition;

#if defined(RASTERIZATION_DIFFUSE_SHADING)
	in vec3 attribNormal;
#endif

uniform mat4 uniMvp;
out mediump vec4 varMvpPosition;

#if defined(RASTERIZATION_DIFFUSE_SHADING)
	out mediump vec3 varNormal;
#endif

void main()
{
	varMvpPosition = uniMvp * vec4(attribPosition.xyz, 1.0f);
	vec4 screenPosition = varMvpPosition;
	screenPosition.z = 0; // force rendering flat geometry, height value (z) is only used in fragment through varMvpPosition.z
	gl_Position = screenPosition;

	#if defined(RASTERIZATION_DIFFUSE_SHADING)
		varNormal = attribNormal;
	#endif
}