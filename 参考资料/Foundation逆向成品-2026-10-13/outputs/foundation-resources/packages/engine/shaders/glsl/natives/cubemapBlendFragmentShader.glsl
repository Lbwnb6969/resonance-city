in vec3 uv;

uniform samplerCube uniTextureA;
uniform samplerCube uniTextureB;
uniform float uniWeight;
uniform int uniMipLevel;

out vec4 color[6];

void main()
{
	vec3 dir[6];
	dir[0] = vec3( 1, -uv.y, -uv.x); 	// right
	dir[1] = vec3(-1, -uv.y, uv.x); 	// left
	dir[2] = vec3(uv.x,  1, uv.y); 		// top
	dir[3] = vec3(uv.x, -1, -uv.y); 	// bottom
	dir[4] = vec3(uv.x, -uv.y,  1); 	// back
	dir[5] = vec3(-uv.x, -uv.y, -1); 	// front

	float w0 = 1- uniWeight;
	float w1 = uniWeight;
	
	for (int i = 0; i < 6; ++i)
	{
		color[i] = textureLod(uniTextureA, dir[i], uniMipLevel) * w0 + textureLod(uniTextureB, dir[i], uniMipLevel) * w1;
	}
}