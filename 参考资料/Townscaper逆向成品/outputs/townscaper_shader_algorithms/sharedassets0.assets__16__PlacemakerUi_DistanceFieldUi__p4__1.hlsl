// Register-explicit recovered HLSL. Not original source.
// PlacemakerUi/DistanceFieldUi vs_4_0 variant ['_MODE_MONOCHROME']
// Source SHA256 4b92e19a8a87e6420ae1d95db523595731c6f4abc020fddf6c279cef37a11f60
// b0: UnityPerDraw 176 bytes
// b1: UnityPerFrame 368 bytes
// cb0[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb1[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[4]; };
cbuffer Buffer1:register(b1) { uint4 cb1[21]; };
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
    uint4 value_1 = asuint(frac(asfloat(v1.xyxx))); // frc o0.xy, v1.xyxx
    out_o0.xy = value_1.xy;
    uint4 value_2 = asuint(asfloat(v2.xxxy) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add o0.zw, v2.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    out_o0.zw = value_2.zw;
    uint4 value_3 = asuint(asfloat(v3.xyxx) + asfloat(uint4(0x3f000000u, 0x3f800000u, 0x0u, 0x0u))); // add o1.xy, v3.xyxx, l(0.500000, 1.000000, 0.000000, 0.000000)
    out_o1.xy = value_3.xy;
    uint4 value_4 = asuint(saturate(asfloat(v5.zzzz))); // mov_sat o2.x, v5.z
    out_o2.x = value_4.x;
    uint4 value_5 = v0.xxxy; // mov o2.zw, v0.xxxy
    out_o2.zw = value_5.zw;
    uint4 value_6 = asuint(asfloat(v0.yyyy) * asfloat(cb0[1].xyzx)); // mul r0.xyz, v0.yyyy, cb0[1].xyzx
    r0.xyz = value_6.xyz;
    uint4 value_7 = asuint(mad(asfloat(cb0[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb0[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_7.xyz;
    uint4 value_8 = asuint(mad(asfloat(cb0[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb0[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_8.xyz;
    uint4 value_9 = asuint(mad(asfloat(cb0[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb0[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_9.xyz;
    uint4 value_10 = asuint(asfloat(r0.yyyy) * asfloat(cb1[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb1[18].xyzw
    r1.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(mad(asfloat(cb1[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb1[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_11.xyzw;
    uint4 value_12 = asuint(mad(asfloat(cb1[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r0.xyzw, cb1[19].xyzw, r0.zzzz, r1.xyzw
    r0.xyzw = value_12.xyzw;
    uint4 value_13 = asuint(asfloat(r0.xyzw) + asfloat(cb1[20].xyzw)); // add o3.xyzw, r0.xyzw, cb1[20].xyzw
    out_o3.xyzw = value_13.xyzw;
    uint4 value_14 = asuint(saturate(asfloat(asuint(asfloat(v5.zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u)))))); // add_sat r0.x, v5.z, l(-1.000000)
    r0.x = value_14.x;
    uint4 value_15 = asuint(asfloat(r0.xxxx) + asfloat(v4.xyzx)); // add o4.xyz, r0.xxxx, v4.xyzx
    out_o4.xyz = value_15.xyz;
    uint4 value_16 = v4.wwww; // mov o4.w, v4.w
    out_o4.w = value_16.w;
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
