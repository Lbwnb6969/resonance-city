// Register-explicit recovered HLSL. Not original source.
// Placemaker/Skybox ps_4_0 variant []
// Source SHA256 1a5ff35887bf850ccf3ef9c7c7a3d7536982464367ef5bbd26a36dece5689978
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: TEXCOORD1;
    float4 v3_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xyz = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = v3.xyzw; // mov o0.xyzw, v3.xyzw
    out_o0.xyzw = value_1.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
