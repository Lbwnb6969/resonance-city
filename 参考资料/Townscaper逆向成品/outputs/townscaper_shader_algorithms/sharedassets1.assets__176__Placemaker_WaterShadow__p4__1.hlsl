// Register-explicit recovered HLSL. Not original source.
// Placemaker/WaterShadow ps_4_0 variant []
// Source SHA256 27564a658bd519436c9a37eb91a6d3349d1f3a2e5a0cdd09f9aa57307045778d
// b0: $Globals 704 bytes
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// t0 / s0 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 5
struct Input {
    float4 v0_0: SV_POSITION;
    float4 v1_0: COLOR0;
    float2 v2_0: TEXCOORD0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 r3;
    uint4 r4;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    v0.xyzw = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    uint4 value_1 = asuint(asfloat(v2.xxxy) * asfloat(cb0[39].xxxy)); // mul r0.zw, v2.xxxy, cb0[39].xxxy
    r0.zw = value_1.zw;
    uint4 value_2 = asuint(mad(asfloat(v2.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r0.xy, v2.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r0.xy = value_2.xy;
    uint4 value_3 = asuint(t0.SampleLevel(s0, asfloat(r0.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r1.xyzw, r0.zyzz, t0.xyzw, s0, l(0.000000)
    r1.xyzw = value_3.xyzw;
    uint4 value_4 = ((asfloat(r1.xyzx) >= asfloat(uint4(0x3f7fbe77u, 0x3f7fbe77u, 0x3f7fbe77u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.xyz, r1.xyzx, l(0.999000, 0.999000, 0.999000, 0.000000)
    r1.xyz = value_4.xyz;
    uint4 value_5 = (r1.xyzx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)); // and r1.xyz, r1.xyzx, l(0x3f800000, 0x3f800000, 0x3f800000, 0)
    r1.xyz = value_5.xyz;
    uint4 value_6 = asuint(frac(asfloat(v2.xyxx))); // frc r2.xy, v2.xyxx
    r2.xy = value_6.xy;
    uint4 value_7 = asuint(asfloat(asuint(-asfloat(r2.xxxy))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r2.zw, -r2.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    r2.zw = value_7.zw;
    uint4 value_8 = asuint(asfloat(r1.xyzx) * asfloat(r2.zzzz)); // mul r1.xyz, r1.xyzx, r2.zzzz
    r1.xyz = value_8.xyz;
    uint4 value_9 = asuint(asfloat(r2.yyyy) * asfloat(r1.xyzx)); // mul r1.xyz, r2.yyyy, r1.xyzx
    r1.xyz = value_9.xyz;
    uint4 value_10 = asuint(t0.SampleLevel(s0, asfloat(r0.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r0.zwzz, t0.xyzw, s0, l(0.000000)
    r3.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(t0.SampleLevel(s0, asfloat(r0.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r0.xwxx, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_11.xyzw;
    uint4 value_12 = asuint(t0.SampleLevel(s0, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t0.xyzw, s0, l(0.000000)
    r0.xyzw = value_12.xyzw;
    uint4 value_13 = ((asfloat(r0.xyzx) >= asfloat(uint4(0x3f7fbe77u, 0x3f7fbe77u, 0x3f7fbe77u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.xyz, r0.xyzx, l(0.999000, 0.999000, 0.999000, 0.000000)
    r0.xyz = value_13.xyz;
    uint4 value_14 = (r0.xyzx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)); // and r0.xyz, r0.xyzx, l(0x3f800000, 0x3f800000, 0x3f800000, 0)
    r0.xyz = value_14.xyz;
    uint4 value_15 = asuint(asfloat(r2.xxxx) * asfloat(r0.xyzx)); // mul r0.xyz, r2.xxxx, r0.xyzx
    r0.xyz = value_15.xyz;
    uint4 value_16 = ((asfloat(r4.xyzx) >= asfloat(uint4(0x3f7fbe77u, 0x3f7fbe77u, 0x3f7fbe77u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r4.xyz, r4.xyzx, l(0.999000, 0.999000, 0.999000, 0.000000)
    r4.xyz = value_16.xyz;
    uint4 value_17 = (r4.xyzx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)); // and r4.xyz, r4.xyzx, l(0x3f800000, 0x3f800000, 0x3f800000, 0)
    r4.xyz = value_17.xyz;
    uint4 value_18 = asuint(asfloat(r2.xxxx) * asfloat(r4.xyzx)); // mul r4.xyz, r2.xxxx, r4.xyzx
    r4.xyz = value_18.xyz;
    uint4 value_19 = ((asfloat(r3.xyzx) >= asfloat(uint4(0x3f7fbe77u, 0x3f7fbe77u, 0x3f7fbe77u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.xyz, r3.xyzx, l(0.999000, 0.999000, 0.999000, 0.000000)
    r3.xyz = value_19.xyz;
    uint4 value_20 = (r3.xyzx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)); // and r3.xyz, r3.xyzx, l(0x3f800000, 0x3f800000, 0x3f800000, 0)
    r3.xyz = value_20.xyz;
    uint4 value_21 = asuint(asfloat(r2.zzzz) * asfloat(r3.xyzx)); // mul r3.xyz, r2.zzzz, r3.xyzx
    r3.xyz = value_21.xyz;
    uint4 value_22 = asuint(mad(asfloat(r3.xyzx), asfloat(r2.wwww), asfloat(r1.xyzx))); // mad r1.xyz, r3.xyzx, r2.wwww, r1.xyzx
    r1.xyz = value_22.xyz;
    uint4 value_23 = asuint(mad(asfloat(r4.xyzx), asfloat(r2.wwww), asfloat(r1.xyzx))); // mad r1.xyz, r4.xyzx, r2.wwww, r1.xyzx
    r1.xyz = value_23.xyz;
    uint4 value_24 = asuint(mad(asfloat(r0.xyzx), asfloat(r2.yyyy), asfloat(r1.xyzx))); // mad r0.xyz, r0.xyzx, r2.yyyy, r1.xyzx
    r0.xyz = value_24.xyz;
    uint4 value_25 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3ecccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.x, r0.xyzx, l(0.300000, 0.300000, 0.400000, 0.000000)
    r0.x = value_25.x;
    uint4 value_26 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -r0.x, l(1.000000)
    r0.y = value_26.y;
    uint4 value_27 = asuint(mad(asfloat(v1.xyzw), asfloat(r0.yyyy), asfloat(r0.xxxx))); // mad o0.xyzw, v1.xyzw, r0.yyyy, r0.xxxx
    out_o0.xyzw = value_27.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
