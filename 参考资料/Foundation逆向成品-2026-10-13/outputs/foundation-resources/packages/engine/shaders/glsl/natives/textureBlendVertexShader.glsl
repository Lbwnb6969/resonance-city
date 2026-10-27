

in vec3 attribPosition;
//uniform mat4 uniMvp;

out vec2 uv;

void main()
{
    gl_Position = /*uniMvp **/ vec4(attribPosition, 1.0);
    uv = attribPosition.xy * 0.5 + 0.5;
}
