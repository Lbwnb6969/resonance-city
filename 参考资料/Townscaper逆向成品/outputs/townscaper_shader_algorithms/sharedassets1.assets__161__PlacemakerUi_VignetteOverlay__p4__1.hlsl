// Register-explicit recovered HLSL. Not original source.
// PlacemakerUi/VignetteOverlay ps_4_0 variant []
// Source SHA256 1f3dae3085916d51d20589bc1a26a725994fc263c4f9ea0630f9f3573132d551
// t0 / s0 = _MainTex
// t1 / s1 = _NoiseTex
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 2
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD2;
    float4 v1_0: SV_POSITION;
    float4 v2_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xyzw = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    uint4 value_1 = asuint(t1.Sample(s1, asfloat(v0.zwzz).xy)).xyzw; // sample r0.xyzw, v0.zwzz, t1.xyzw, s1
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(mad(asfloat(v0.zzzz), asfloat(uint4(0x40490fdbu, 0x40490fdbu, 0x40490fdbu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, v0.zzzz, l(3.141593, 3.141593, 3.141593, 0.000000), r0.xyzx
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(v0.wwww), asfloat(uint4(0x4116cbe4u, 0x4116cbe4u, 0x4116cbe4u, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, v0.wwww, l(9.424778, 9.424778, 9.424778, 0.000000), r0.xyzx
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(frac(asfloat(r0.xyzx))); // frc r0.xyz, r0.xyzx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_5.w;
    uint4 value_6 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(r0.wwww)); // add r1.xyz, -r0.xyzx, r0.wwww
    r1.xyz = value_6.xyz;
    uint4 value_7 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r1.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), r0.xyzx
    r0.xyz = value_7.xyz;
    uint4 value_8 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0x0u))); // add r0.xyz, r0.xyzx, l(-0.500000, -0.500000, -0.500000, 0.000000)
    r0.xyz = value_8.xyz;
    uint4 value_9 = asuint(t0.Sample(s0, asfloat(v0.xyxx).xy)).xyzw; // sample r1.xyzw, v0.xyxx, t0.xyzw, s0
    r1.xyzw = value_9.xyzw;
    uint4 value_10 = asuint(mad(asfloat(r0.xyzx), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r0.xyz, r0.xyzx, l(0.050000, 0.050000, 0.050000, 0.000000), r1.xyzx
    r0.xyz = value_10.xyz;
    uint4 value_11 = asuint(asfloat(r1.wwww) * asfloat(uint4(0x3f0ccccdu, 0x3f0ccccdu, 0x3f0ccccdu, 0x3f0ccccdu))); // mul r0.w, r1.w, l(0.550000)
    r0.w = value_11.w;
    uint4 value_12 = r0.wwww; // mov o0.w, r0.w
    out_o0.w = value_12.w;
    uint4 value_13 = asuint(mad(asfloat(r0.xyzx), asfloat(uint4(0x3f0ccccdu, 0x3f0ccccdu, 0x3f0ccccdu, 0x0u)), asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0x0u)))); // mad r0.xyz, r0.xyzx, l(0.550000, 0.550000, 0.550000, 0.000000), l(-0.500000, -0.500000, -0.500000, 0.000000)
    r0.xyz = value_13.xyz;
    uint4 value_14 = asuint(mad(asfloat(v2.wwww), asfloat(r0.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)))); // mad o0.xyz, v2.wwww, r0.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000)
    out_o0.xyz = value_14.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
