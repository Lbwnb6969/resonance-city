in vec3 localPos;
out vec4 outColor;

uniform samplerCube environmentMap;
//uniform float N;

const float PI = 3.14159265359;
const float N = 0.01;

void main()
{
    // the sample direction equals the hemisphere's orientation
    vec3 normal = -normalize(vec3(localPos.x, localPos.y, -localPos.z));

    vec3 irradiance = vec3(0.0);

    vec3 up    = vec3(0.0, 1.0, 0.0);
	vec3 right = cross(up, normal);
	up         = cross(normal, right);

	float sampleDelta = 0.025;
	float nrSamples = 0.0;
	for(float phi = 0.0; phi < 2.0 * PI; phi += sampleDelta)
	{
		for(float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)
		{
			// spherical to cartesian (in tangent space)
			vec3 tangentSample = vec3(sin(theta) * cos(phi),  sin(theta) * sin(phi), cos(theta));
			// tangent space to world
			vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * normal;//N;

			//irradiance += texture(environmentMap, normal).rgb * cos(theta) * sin(theta);
			irradiance += texture(environmentMap, sampleVec).rgb * cos(theta) * sin(theta);
			nrSamples++;
		}
	}

	irradiance = PI * irradiance * (1.0 / float(nrSamples));
    outColor = vec4(irradiance, 1.0);
}