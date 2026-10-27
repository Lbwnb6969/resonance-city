uniform sampler2D uniMapDepth;

in vec2 var_attribUv;

void main(void) {

    vec4 texels;
    texels.x = texture(uniMapDepth, var_attribUv).x;
    texels.y = textureOffset(uniMapDepth, var_attribUv, ivec2(-1, 0)).x;
    texels.z = textureOffset(uniMapDepth, var_attribUv, ivec2(-1,-1)).x;
    texels.w = textureOffset(uniMapDepth, var_attribUv, ivec2( 0,-1)).x;
 
    float maxZ = max(max(texels.x, texels.y), max(texels.z, texels.w));
 
    vec3 extra;

    // Size of the texture at previous mip
    ivec2 uniMapDepthSize = textureSize(uniMapDepth, 0);

    // if we are reducing an odd-width texture then fetch the edge texels
    if (((uniMapDepthSize.x & 1) != 0) && (int(gl_FragCoord.x) == uniMapDepthSize.x-3)) {

        // if both edges are odd, fetch the top-left corner texel
        if (((uniMapDepthSize.y & 1) != 0) && (int(gl_FragCoord.y) == uniMapDepthSize.y-3)) {
            extra.z = textureOffset(uniMapDepth, var_attribUv, ivec2(1, 1)).x;
            maxZ = max(maxZ, extra.z);
        }

        extra.x = textureOffset(uniMapDepth, var_attribUv, ivec2(1,  0)).x;
        extra.y = textureOffset(uniMapDepth, var_attribUv, ivec2(1, -1)).x;

        maxZ = max(maxZ, max(extra.x, extra.y));
    } else
    // if we are reducing an odd-height texture then fetch the edge texels
    if (((uniMapDepthSize.y & 1) != 0) && (int(gl_FragCoord.y) == uniMapDepthSize.y-3)) {

        extra.x = textureOffset(uniMapDepth, var_attribUv, ivec2( 0, 1)).x;
        extra.y = textureOffset(uniMapDepth, var_attribUv, ivec2(-1, 1)).x;
        maxZ = max(maxZ, max(extra.x, extra.y));
    }

    gl_FragDepth = maxZ;
}