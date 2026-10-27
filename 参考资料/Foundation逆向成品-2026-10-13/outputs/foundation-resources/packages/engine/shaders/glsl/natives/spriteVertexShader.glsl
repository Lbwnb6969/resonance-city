attribute vec2 attribPosition;
attribute vec2 attribTextCoor;

uniform mat4 uniMvp;

varying vec2 varTextCoord;

void main()
{
	gl_Position = uniMvp * vec4(attribPosition, 0.0, 1.0);
	varTextCoord = attribTextCoor;
}