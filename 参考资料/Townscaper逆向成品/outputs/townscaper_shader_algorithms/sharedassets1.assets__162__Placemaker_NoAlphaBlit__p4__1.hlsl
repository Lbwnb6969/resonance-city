// Register-explicit recovered HLSL. Not original source.
// Placemaker/NoAlphaBlit ps_4_0 variant []
// Source SHA256 cc6b260a638026ab135ab2927392b0a85b22ff3b9277629b19b08b85c8b7dbd3
// t0 / s0 = _MainTex
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 1
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
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
    v1.xy = asuint(input.v1_0);
    uint4 value_1 = asuint(t0.Sample(s0, asfloat(v1.xyxx).xy)).xyzw; // sample r0.xyzw, v1.xyxx, t0.xyzw, s0
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = r0.xyzx; // mov o0.xyz, r0.xyzx
    out_o0.xyz = value_2.xyz;
    uint4 value_3 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov o0.w, l(1.000000)
    out_o0.w = value_3.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
