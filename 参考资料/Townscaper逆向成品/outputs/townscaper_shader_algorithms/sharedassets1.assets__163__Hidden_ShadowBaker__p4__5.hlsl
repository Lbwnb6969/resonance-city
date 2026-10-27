// Register-explicit recovered HLSL. Not original source.
// Hidden/ShadowBaker vs_4_0 variant []
// Source SHA256 da5a28e8268b807f9e9c702fa1b3332a7f13528b831d1eecd4e9f6b0e28b02a6
// b0: $Globals 640 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[34]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
// temporary registers: 2
struct Input {
    float4 v0_0: POSITION0;
    float3 v1_0: NORMAL0;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float4 o1_0: COLOR0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 out_o1;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xyz = asuint(input.v1_0);
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb1[1].xyzw
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(mad(asfloat(cb1[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb1[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb1[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r1.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(asfloat(r1.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r1.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(asfloat(r0.yyyy) * asfloat(cb0[31].zzzz)); // mul r0.y, r0.y, cb0[31].z
    r0.y = value_9.y;
    uint4 value_10 = asuint(mad(asfloat(cb0[30].zzzz), asfloat(r0.xxxx), asfloat(r0.yyyy))); // mad r0.x, cb0[30].z, r0.x, r0.y
    r0.x = value_10.x;
    uint4 value_11 = asuint(mad(asfloat(cb0[32].zzzz), asfloat(r0.zzzz), asfloat(r0.xxxx))); // mad r0.x, cb0[32].z, r0.z, r0.x
    r0.x = value_11.x;
    uint4 value_12 = asuint(mad(asfloat(cb0[33].zzzz), asfloat(r0.wwww), asfloat(r0.xxxx))); // mad o1.x, cb0[33].z, r0.w, r0.x
    out_o1.x = value_12.x;
    uint4 value_13 = uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov o1.yzw, l(0,1.000000,1.000000,1.000000)
    out_o1.yzw = value_13.yzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xyzw);
    return result;
}
