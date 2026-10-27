
in vec2 attribPosition;
in vec2 attribUv;

uniform mat4 uniMvp;
uniform vec2 uniTexelSize;

out vec2 varUv;
out vec2 rcpFrame;

void main()
{
	gl_Position = uniMvp * vec4(attribPosition, 0.0f, 1.0f);

	rcpFrame = uniTexelSize;
	varUv = attribUv.xy;
}