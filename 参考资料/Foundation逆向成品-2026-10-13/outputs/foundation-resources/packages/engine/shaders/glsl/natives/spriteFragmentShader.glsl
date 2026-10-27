varying vec2 varTextCoord;

uniform sampler2D uniMapDiffuse;
uniform vec4 uniColor;

out vec4 outColor;

void main()
{
	outColor = texture2D(uniMapDiffuse, varTextCoord) * uniColor;
}