// Register-explicit recovered HLSL. Not original source.
// Placemaker/Dust ps_4_0 variant []
// Source SHA256 f2d9d61ef00e4689ed2d3612a0680ba827705cf8a1ac49b3783a4af0f2f679c2
// t0 / s0 = _MainTex
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 1
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float4 v1_0: SV_POSITION;
    float4 v2_0: COLOR0;
    float4 v3_0: COLOR1;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xyzw = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(t0.SampleLevel(s0, asfloat(v0.xyxx).xy, asfloat(v0.zzzz).x)).xyzw; // sample_l r0.xyzw, v0.xyxx, t0.xyzw, s0, v0.z
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(r0.xxxx)); // add r0.x, -r0.y, r0.x
    r0.x = value_2.x;
    uint4 value_3 = asuint(mad(asfloat(v0.wwww), asfloat(r0.xxxx), asfloat(r0.yyyy))); // mad r0.x, v0.w, r0.x, r0.y
    r0.x = value_3.x;
    uint4 value_4 = asuint(asfloat(r0.xxxx) * asfloat(v2.wwww)); // mul o0.w, r0.x, v2.w
    out_o0.w = value_4.w;
    uint4 value_5 = v2.xyzx; // mov o0.xyz, v2.xyzx
    out_o0.xyz = value_5.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
