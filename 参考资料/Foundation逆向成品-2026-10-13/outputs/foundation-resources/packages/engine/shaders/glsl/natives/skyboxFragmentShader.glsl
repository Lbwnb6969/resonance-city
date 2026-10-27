in vec3 uv;
out vec4 outColor;

uniform samplerCube uniMapDiffuse; // skybox
uniform vec4 uniAmbientColor;
uniform vec4 uniColor;

void main()
{
	vec4 skyColor = texture(uniMapDiffuse, uv) * uniAmbientColor;
	vec3 color = skyColor.rgb * (1 - uniColor.a) + uniColor.rgb * uniColor.a;
    outColor = vec4(color, skyColor.a);
}