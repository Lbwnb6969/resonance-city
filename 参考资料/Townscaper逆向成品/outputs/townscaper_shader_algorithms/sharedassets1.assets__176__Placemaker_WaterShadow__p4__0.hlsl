// Register-explicit recovered HLSL. Not original source.
// Placemaker/WaterShadow vs_4_0 variant []
// Source SHA256 a90a1c08aee0b36942f6019c7ea5a48c959bcc2142c81c098ec348584b0e12b6
// b0: $Globals 704 bytes
// b1: UnityPerCamera 144 bytes
// b2: UnityPerDraw 176 bytes
// b3: UnityPerFrame 368 bytes
// cb0[5].x = _SunColor rows=1 cols=4 byte_offset=80
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
cbuffer Buffer1:register(b1) { uint4 cb1[5]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[21]; };
// temporary registers: 3
struct Input {
    float4 v0_0: POSITION0;
    float4 v1_0: TANGENT0;
    float2 v2_0: TEXCOORD0;
    float3 v3_0: NORMAL0;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float4 o1_0: COLOR0;
    float2 o2_0: TEXCOORD0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xyzw = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    v3.xyz = asuint(input.v3_0);
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb2[1].xyzw
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(mad(asfloat(cb2[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb2[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb2[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(cb1[4].xyzx)); // add r1.xyz, -r0.xyzx, cb1[4].xyzx
    r1.xyz = value_5.xyz;
    uint4 value_6 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r1.w, r1.xyzx, r1.xyzx
    r1.w = value_6.w;
    uint4 value_7 = asuint(rsqrt(asfloat(r1.wwww))); // rsq r1.w, r1.w
    r1.w = value_7.w;
    uint4 value_8 = asuint(asfloat(r1.wwww) * asfloat(r1.yxzy)); // mul r1.xyz, r1.wwww, r1.yxzy
    r1.xyz = value_8.xyz;
    uint4 value_9 = asuint(mad(asfloat(r1.yyxz), asfloat(uint4(0x0u, 0x3c23d70au, 0x3c23d70au, 0x3c23d70au)), asfloat(r0.xxyz))); // mad r1.yzw, r1.yyxz, l(0.000000, 0.010000, 0.010000, 0.010000), r0.xxyz
    r1.yzw = value_9.yzw;
    uint4 value_10 = asuint(saturate(asfloat(r1.xxxx))); // mov_sat r1.x, r1.x
    r1.x = value_10.x;
    uint4 value_11 = asuint(asfloat(r1.xxxx) * asfloat(cb0[5].wwww)); // mul r1.x, r1.x, cb0[5].w
    r1.x = value_11.x;
    uint4 value_12 = asuint(asfloat(r1.zzzz) * asfloat(cb3[18].xyzw)); // mul r2.xyzw, r1.zzzz, cb3[18].xyzw
    r2.xyzw = value_12.xyzw;
    uint4 value_13 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r1.yyyy), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[17].xyzw, r1.yyyy, r2.xyzw
    r2.xyzw = value_13.xyzw;
    uint4 value_14 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r1.wwww), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[19].xyzw, r1.wwww, r2.xyzw
    r2.xyzw = value_14.xyzw;
    uint4 value_15 = asuint(asfloat(r2.xyzw) + asfloat(cb3[20].xyzw)); // add o0.xyzw, r2.xyzw, cb3[20].xyzw
    out_o0.xyzw = value_15.xyzw;
    uint4 value_16 = asuint(asfloat(r0.yyyy) * asfloat(cb0[31].xxyz)); // mul r1.yzw, r0.yyyy, cb0[31].xxyz
    r1.yzw = value_16.yzw;
    uint4 value_17 = asuint(mad(asfloat(cb0[30].xxyz), asfloat(r0.xxxx), asfloat(r1.yyzw))); // mad r1.yzw, cb0[30].xxyz, r0.xxxx, r1.yyzw
    r1.yzw = value_17.yzw;
    uint4 value_18 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r0.zzzz), asfloat(r1.yzwy))); // mad r0.xyz, cb0[32].xyzx, r0.zzzz, r1.yzwy
    r0.xyz = value_18.xyz;
    uint4 value_19 = asuint(mad(asfloat(cb0[33].xyzx), asfloat(r0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb0[33].xyzx, r0.wwww, r0.xyzx
    r0.xyz = value_19.xyz;
    uint4 value_20 = asuint(saturate(asfloat(asuint(asfloat(asuint(-asfloat(r0.zzzz))) + asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)))))); // add_sat r0.z, -r0.z, l(2.000000)
    r0.z = value_20.z;
    uint4 value_21 = asuint(asfloat(r0.xyxx) * asfloat(cb0[39].zwzz)); // mul o2.xy, r0.xyxx, cb0[39].zwzz
    out_o2.xy = value_21.xy;
    uint4 value_22 = asuint(asfloat(r0.zzzz) * asfloat(r1.xxxx)); // mul r0.x, r0.z, r1.x
    r0.x = value_22.x;
    uint4 value_23 = asuint(asfloat(r0.xxxx) * asfloat(cb0[29].yyyy)); // mul r0.x, r0.x, cb0[29].y
    r0.x = value_23.x;
    uint4 value_24 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0xbe4cccccu, 0xbdccccd0u, 0x0u, 0x0u)), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad o1.xyzw, r0.xxxx, l(-0.200000, -0.100000, 0.000000, 0.000000), l(1.000000, 1.000000, 1.000000, 1.000000)
    out_o1.xyzw = value_24.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xyzw);
    result.o2_0 = asfloat(out_o2.xy);
    return result;
}
