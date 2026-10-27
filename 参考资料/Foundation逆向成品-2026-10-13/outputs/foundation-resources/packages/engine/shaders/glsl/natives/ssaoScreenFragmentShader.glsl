//------------------------------

//------------------------------
// inputs

//------------------------------
// uniforms

uniform sampler2D 	uniMapDiffuse;
uniform sampler2D 	uniMapOccluion;




//------------------------------

in vec2 gTexcoord;

//------------------------------
// out

out mediump vec4 fragColor;

void main()
{
	float occlusion = texture2D(uniMapOccluion, gTexcoord).x;
	fragColor = occlusion * texture2D( uniMapDiffuse, gTexcoord);
}