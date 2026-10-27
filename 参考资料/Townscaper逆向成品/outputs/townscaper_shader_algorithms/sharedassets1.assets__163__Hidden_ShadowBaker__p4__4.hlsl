// Register-explicit recovered HLSL. Not original source.
// Hidden/ShadowBaker ps_4_0 variant []
// Source SHA256 4a6bd76ac89a3a27039546ce6549579bb464fcb1ecece925edada4727aca2a94
// temporary registers: 1
struct Input {
    float4 v0_0: SV_POSITION;
    float4 v1_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    uint4 value_1 = ((asfloat(uint4(0x40000000u, 0x3f000000u, 0x3ecccccdu, 0x0u)) >= asfloat(v1.yyyy)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.xyz, l(2.000000, 0.500000, 0.400000, 0.000000), v1.yyyy
    r0.xyz = value_1.xyz;
    uint4 value_2 = (r0.xyzx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)); // and r0.xyz, r0.xyzx, l(0x3f800000, 0x3f800000, 0x3f800000, 0)
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(asfloat(r0.xyzx) * asfloat(v1.xxxx)); // mul r0.xyz, r0.xyzx, v1.xxxx
    r0.xyz = value_3.xyz;
    uint4 value_4 = uint4(0x0u, 0x0u, 0x0u, 0x0u); // mov r0.w, l(0)
    r0.w = value_4.w;
    uint4 value_5 = asuint(asfloat(asuint(-asfloat(r0.xyzw))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add o0.xyzw, -r0.xyzw, l(1.000000, 1.000000, 1.000000, 1.000000)
    out_o0.xyzw = value_5.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
