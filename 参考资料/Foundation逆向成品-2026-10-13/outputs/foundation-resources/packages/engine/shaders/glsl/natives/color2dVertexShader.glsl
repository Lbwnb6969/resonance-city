

in vec2 attribPosition;
uniform mat4 uniMvp;

void main()
{
	gl_Position = uniMvp * vec4( attribPosition, 0.0f, 1.0f );
}