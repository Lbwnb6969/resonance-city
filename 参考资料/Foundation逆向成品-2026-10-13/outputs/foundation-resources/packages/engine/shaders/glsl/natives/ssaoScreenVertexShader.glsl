

in vec3 attribPosition;
in vec2 attribTextCoor;

uniform mat4 uniMvp;

//out vec2 varTextCoord;
out mediump vec4 varMvpPosition;

void main()
{
	varMvpPosition = uniMvp * vec4( attribPosition, 1.0f );
	gl_Position = varMvpPosition;
	//varTextCoord = attribTextCoor;
}