

in vec3 attribPosition;
in mediump vec2 attribUv;

uniform mat4 uniMvp;

out vec2 varTextCoord;

void main()
{
	vec4 varMvpPosition = uniMvp * vec4(attribPosition, 1.0f);
	gl_Position = varMvpPosition;
	varTextCoord = attribUv;
}