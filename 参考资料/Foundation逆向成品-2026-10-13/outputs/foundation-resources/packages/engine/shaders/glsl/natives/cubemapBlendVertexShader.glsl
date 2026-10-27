

in vec3 attribPosition;
//uniform mat4 uniMvp;

out vec3 uv;

void main()
{
    gl_Position = /*uniMvp **/ vec4(attribPosition, 1.0);
    uv = attribPosition;
}
