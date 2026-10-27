// Register-explicit recovered HLSL. Not original source.
// PlacemakerUi/TownPreviewUi ps_4_0 variant []
// Source SHA256 bb0c4ef29f5a1632ccfae93f11d963e621feafce04e75ed58257cd3ccdd0b862
// t0 / s0 = _MainTex
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 3
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float2 v1_0: TEXCOORD2;
    float2 v1_1: TEXCOORD3;
    float4 v2_0: SV_POSITION;
    float4 v3_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xy = asuint(input.v1_0);
    v1.zw = asuint(input.v1_1);
    v2.xyzw = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(mad(asfloat(v0.xyxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x0u, 0x0u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0x0u, 0x0u)))); // mad r0.xy, v0.xyxx, l(2.000000, 2.000000, 0.000000, 0.000000), l(-1.000000, -1.000000, 0.000000, 0.000000)
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(asfloat(r0.xyxx) * asfloat(r0.xyxx)); // mul r0.xy, r0.xyxx, r0.xyxx
    r0.xy = value_2.xy;
    uint4 value_3 = asuint(asfloat(r0.xyxx) * asfloat(r0.xyxx)); // mul r0.xy, r0.xyxx, r0.xyxx
    r0.xy = value_3.xy;
    uint4 value_4 = asuint(mad(asfloat(asuint(-asfloat(r0.xyxx))), asfloat(r0.xyxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u)))); // mad r0.xy, -r0.xyxx, r0.xyxx, l(1.000000, 1.000000, 0.000000, 0.000000)
    r0.xy = value_4.xy;
    uint4 value_5 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.z, r0.y, r0.x
    r0.z = value_5.z;
    uint4 value_6 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r0.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.x, -r0.x, r0.y, l(1.000000)
    r0.x = value_6.x;
    uint4 value_7 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu)))); // mad r0.x, r0.x, l(2.000000), l(-0.200000)
    r0.x = value_7.x;
    uint4 value_8 = asuint(t0.SampleBias(s0, asfloat(v0.xyxx).xy, asfloat(r0.xxxx).x)).xyzw; // sample_b r1.xyzw, v0.xyxx, t0.xyzw, s0, r0.x
    r1.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(mad(asfloat(r0.zzzz), asfloat(uint4(0x3e4cccccu, 0x3e4cccccu, 0x3d4cccd0u, 0x0u)), asfloat(uint4(0x3f4ccccdu, 0x3f4ccccdu, 0x3f733333u, 0x0u)))); // mad r0.xyz, r0.zzzz, l(0.200000, 0.200000, 0.050000, 0.000000), l(0.800000, 0.800000, 0.950000, 0.000000)
    r0.xyz = value_9.xyz;
    uint4 value_10 = asuint(asfloat(r0.xyzx) * asfloat(r1.xyzx)); // mul r2.xyz, r0.xyzx, r1.xyzx
    r2.xyz = value_10.xyz;
    uint4 value_11 = asuint(mad(asfloat(asuint(-asfloat(r1.xyzx))), asfloat(r0.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)))); // mad r0.xyz, -r1.xyzx, r0.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000)
    r0.xyz = value_11.xyz;
    uint4 value_12 = asuint(asfloat(asuint(-asfloat(v1.yyyy))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -v1.y, l(1.000000)
    r0.w = value_12.w;
    uint4 value_13 = asuint(mad(asfloat(r0.wwww), asfloat(r0.xyzx), asfloat(r2.xyzx))); // mad r1.xyz, r0.wwww, r0.xyzx, r2.xyzx
    r1.xyz = value_13.xyz;
    uint4 value_14 = asuint(asfloat(r1.xyzw) * asfloat(v3.xyzw)); // mul r0.xyzw, r1.xyzw, v3.xyzw
    r0.xyzw = value_14.xyzw;
    uint4 value_15 = asuint(asfloat(r0.wwww) * asfloat(r0.xyzx)); // mul o0.xyz, r0.wwww, r0.xyzx
    out_o0.xyz = value_15.xyz;
    uint4 value_16 = r0.wwww; // mov o0.w, r0.w
    out_o0.w = value_16.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
