// Register-explicit recovered HLSL. Not original source.
// PlacemakerUi/DistanceFieldUi vs_4_0 variant ['_MODE_PALETTE']
// Source SHA256 59d81c2aac5d01105fc101350c7e6978bd46cecf975d42571f640bb7c4fc45cb
// b0: $Globals 688 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _MaterialTex
cbuffer Buffer0:register(b0) { uint4 cb0[16]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 2
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float2 v2_0: TEXCOORD1;
    float2 v3_0: TEXCOORD2;
    float4 v4_0: COLOR0;
    float3 v5_0: NORMAL0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD1;
    float2 o1_0: TEXCOORD2;
    float2 o1_1: TEXCOORD3;
    float2 o2_0: TEXCOORD5;
    float2 o2_1: TEXCOORD4;
    float4 o3_0: SV_POSITION;
    float4 o4_0: COLOR0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 out_o3;
    uint4 out_o4;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    uint4 v4;
    uint4 v5;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    v3.xy = asuint(input.v3_0);
    v4.xyzw = asuint(input.v4_0);
    v5.xyz = asuint(input.v5_0);
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzx)); // mul r0.xyz, v0.yyyy, cb1[1].xyzx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb1[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb1[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(mad(asfloat(cb1[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb1[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r0.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r0.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(asfloat(r0.xyzw) + asfloat(cb2[20].xyzw)); // add o3.xyzw, r0.xyzw, cb2[20].xyzw
    out_o3.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(frac(asfloat(v1.xyxx))); // frc o0.xy, v1.xyxx
    out_o0.xy = value_9.xy;
    uint4 value_10 = asuint(asfloat(v2.xxxy) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add o0.zw, v2.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    out_o0.zw = value_10.zw;
    uint4 value_11 = asuint(asfloat(v3.xyxx) + asfloat(uint4(0x3f000000u, 0x3f800000u, 0x0u, 0x0u))); // add o1.xy, v3.xyxx, l(0.500000, 1.000000, 0.000000, 0.000000)
    out_o1.xy = value_11.xy;
    uint4 value_12 = ((asfloat(v1.xxxx) >= asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, v1.x, l(0.000000)
    r0.x = value_12.x;
    if (r0.xxxx.x != 0u) {
        uint4 value_14 = asuint(floor(asfloat(asuint(abs(asfloat(v1.xxxx)))))); // round_ni r0.x, |v1.x|
        r0.x = value_14.x;
        uint4 value_15 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.x, r0.x, l(0.500000)
        r0.x = value_15.x;
        uint4 value_16 = asuint(asfloat(r0.xxxx) * asfloat(cb0[15].xxxx)); // mul r0.x, r0.x, cb0[15].x
        r0.x = value_16.x;
        uint4 value_17 = uint4(0x3e800000u, 0x3e800000u, 0x3e800000u, 0x3e800000u); // mov r0.y, l(0.250000)
        r0.y = value_17.y;
        uint4 value_18 = asuint(t0.SampleLevel(s0, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t0.xyzw, s0, l(0.000000)
        r0.xyzw = value_18.xyzw;
        uint4 value_19 = asuint(asfloat(r0.xyzw) * asfloat(v4.xyzw)); // mul r0.xyzw, r0.xyzw, v4.xyzw
        r0.xyzw = value_19.xyzw;
        uint4 value_20 = r0.wwww; // mov o4.w, r0.w
        out_o4.w = value_20.w;
    } else {
        uint4 value_22 = v4.xyzx; // mov r0.xyz, v4.xyzx
        r0.xyz = value_22.xyz;
        uint4 value_23 = v4.wwww; // mov o4.w, v4.w
        out_o4.w = value_23.w;
    }
    uint4 value_25 = asuint(saturate(asfloat(asuint(asfloat(v5.zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u)))))); // add_sat r0.w, v5.z, l(-1.000000)
    r0.w = value_25.w;
    uint4 value_26 = asuint(asfloat(r0.wwww) + asfloat(r0.xyzx)); // add o4.xyz, r0.wwww, r0.xyzx
    out_o4.xyz = value_26.xyz;
    uint4 value_27 = asuint(saturate(asfloat(v5.zzzz))); // mov_sat o2.x, v5.z
    out_o2.x = value_27.x;
    uint4 value_28 = v0.xxxy; // mov o2.zw, v0.xxxy
    out_o2.zw = value_28.zw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xy);
    result.o1_1 = asfloat(out_o1.zw);
    result.o2_0 = asfloat(out_o2.xy);
    result.o2_1 = asfloat(out_o2.zw);
    result.o3_0 = asfloat(out_o3.xyzw);
    result.o4_0 = asfloat(out_o4.xyzw);
    return result;
}
