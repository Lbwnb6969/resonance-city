in vec3 uv;

uniform sampler2D uniMapDepth;

void main()
{
    gl_FragDepth = texture(uniMapDepth, uv);
}