

in vec3 attribPosition;
uniform mat4 uniMvp;

out vec3 uv;

void main()
{
    vec4 pos = uniMvp * vec4(attribPosition, 1.0);
    gl_Position = pos.xyww * 0.99999;
    uv = attribPosition;
}
