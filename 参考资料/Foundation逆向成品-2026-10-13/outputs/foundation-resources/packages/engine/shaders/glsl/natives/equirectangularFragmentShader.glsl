in vec3 localPos;

out vec4 outColor;

uniform sampler2D equirectangularMap;

const vec2 invAtan = vec2(0.1591, 0.3183);

// ----------------------------------------------------------------------------
vec2 SampleSphericalMap(vec3 v)
{
    vec2 uv = vec2(atan(-v.x, v.z), asin(v.y));
    uv *= invAtan;
    uv += 0.5;
    return vec2(1-uv.x, uv.y);
}

// ----------------------------------------------------------------------------
void main()
{
    vec2 uv = SampleSphericalMap(normalize(localPos));
    outColor = texture(equirectangularMap, uv);
}