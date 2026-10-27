
in vec2 attribPosition;
in vec2 attribUv;

uniform mat4 uniMvp;

out vec2 varUv;

void main()
{
	gl_Position = uniMvp * vec4(attribPosition, 0.0f, 1.0f);
	varUv = attribUv.xy;
}