in vec2 uv;

uniform sampler2D uniTextureA;
uniform sampler2D uniTextureB;
uniform float uniWeight;
uniform int uniMipLevel;

out vec4 color;

void main()
{
	float w0 = 1- uniWeight;
	float w1 = uniWeight;
	
	color = textureLod(uniTextureA, uv, uniMipLevel) * w0 + textureLod(uniTextureB, uv, uniMipLevel) * w1;
}