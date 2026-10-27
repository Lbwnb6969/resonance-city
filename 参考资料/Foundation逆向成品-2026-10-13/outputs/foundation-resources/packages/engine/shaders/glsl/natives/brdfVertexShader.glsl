
in vec3 attribPosition;
in vec2 attribUv;

uniform mat4 uniMvp;

out vec2 uv;

void main()
{
	uv = attribUv;
    gl_Position = uniMvp * vec4(attribPosition, 1.0);
}
