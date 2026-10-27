// Register-explicit recovered HLSL. Not original source.
// Hidden/ShadowBaker vs_4_0 variant []
// Source SHA256 5e516391bb5a98551d71fac24526932191ac541673f67195d18f387bc3ab4c52
// b0: $Globals 640 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[34]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
// temporary registers: 3
struct Input {
    float4 v0_0: POSITION0;
    float4 v1_0: TANGENT0;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float4 o1_0: COLOR0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 out_o0;
    uint4 out_o1;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    uint4 value_1 = asuint(asfloat(v1.yyyy) * asfloat(cb1[1].xyzx)); // mul r0.xyz, v1.yyyy, cb1[1].xyzx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v1.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb1[0].xyzx, v1.xxxx, r0.xyzx
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v1.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb1[2].xyzx, v1.zzzz, r0.xyzx
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(mad(asfloat(v1.wwww), asfloat(uint4(0xbcf5c28fu, 0xbcf5c28fu, 0xbcf5c28fu, 0xbcf5c28fu)), asfloat(uint4(0x3d23d70au, 0x3d23d70au, 0x3d23d70au, 0x3d23d70au)))); // mad r0.w, v1.w, l(-0.030000), l(0.040000)
    r0.w = value_4.w;
    uint4 value_5 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzw)); // mul r1.xyzw, v0.yyyy, cb1[1].xyzw
    r1.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb1[0].xyzw), asfloat(v0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb1[0].xyzw, v0.xxxx, r1.xyzw
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb1[2].xyzw), asfloat(v0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb1[2].xyzw, v0.zzzz, r1.xyzw
    r1.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(mad(asfloat(cb1[3].xyzw), asfloat(v0.wwww), asfloat(r1.xyzw))); // mad r1.xyzw, cb1[3].xyzw, v0.wwww, r1.xyzw
    r1.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(mad(asfloat(asuint(-asfloat(r0.xyzx))), asfloat(r0.wwww), asfloat(r1.xyzx))); // mad r0.xyz, -r0.xyzx, r0.wwww, r1.xyzx
    r0.xyz = value_9.xyz;
    uint4 value_10 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r2.xyzw, r0.yyyy, cb2[18].xyzw
    r2.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb2[17].xyzw, r0.xxxx, r2.xyzw
    r2.xyzw = value_11.xyzw;
    uint4 value_12 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r2.xyzw))); // mad r0.xyzw, cb2[19].xyzw, r0.zzzz, r2.xyzw
    r0.xyzw = value_12.xyzw;
    uint4 value_13 = asuint(asfloat(r0.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r0.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_13.xyzw;
    uint4 value_14 = asuint(asfloat(r1.yyyy) * asfloat(cb0[31].zzzz)); // mul r0.x, r1.y, cb0[31].z
    r0.x = value_14.x;
    uint4 value_15 = asuint(mad(asfloat(cb0[30].zzzz), asfloat(r1.xxxx), asfloat(r0.xxxx))); // mad r0.x, cb0[30].z, r1.x, r0.x
    r0.x = value_15.x;
    uint4 value_16 = asuint(mad(asfloat(cb0[32].zzzz), asfloat(r1.zzzz), asfloat(r0.xxxx))); // mad r0.x, cb0[32].z, r1.z, r0.x
    r0.x = value_16.x;
    uint4 value_17 = asuint(mad(asfloat(cb0[33].zzzz), asfloat(r1.wwww), asfloat(r0.xxxx))); // mad r0.x, cb0[33].z, r1.w, r0.x
    r0.x = value_17.x;
    uint4 value_18 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_18.x;
    uint4 value_19 = asuint(asfloat(r0.xxxx) * asfloat(v1.wwww)); // mul r0.xy, r0.xxxx, v1.wwww
    r0.xy = value_19.xy;
    uint4 value_20 = uint4(0x0u, 0x0u, 0x0u, 0x0u); // mov r0.zw, l(0,0,0,0)
    r0.zw = value_20.zw;
    uint4 value_21 = asuint(asfloat(asuint(-asfloat(r0.xyzw))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add o1.xyzw, -r0.xyzw, l(1.000000, 1.000000, 1.000000, 1.000000)
    out_o1.xyzw = value_21.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xyzw);
    return result;
}
