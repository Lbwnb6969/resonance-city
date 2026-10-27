
in vec3 attribPosition;

uniform mat4 uniMvp;

out vec3 localPos;

void main()
{
	localPos = attribPosition;
    gl_Position = uniMvp * vec4(attribPosition, 1.0);
}
