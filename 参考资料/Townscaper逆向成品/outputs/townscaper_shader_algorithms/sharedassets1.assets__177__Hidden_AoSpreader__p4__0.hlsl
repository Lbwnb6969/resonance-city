// Register-explicit recovered HLSL. Not original source.
// Hidden/AoSpreader vs_4_0 variant []
// Source SHA256 3d618cd3050096736e64b83519ca3891cf5eca2ef7b2a25e681d06709a798af5
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
};
struct Output {
    float4 o0_0: SV_POSITION;
    float2 o1_0: TEXCOORD0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 out_o1;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb0[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb0[1].xyzw
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(mad(asfloat(cb0[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb0[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb0[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb0[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(asfloat(r0.xyzw) + asfloat(cb0[3].xyzw)); // add r0.xyzw, r0.xyzw, cb0[3].xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(asfloat(r0.yyyy) * asfloat(cb1[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb1[18].xyzw
    r1.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb1[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb1[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb1[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb1[19].xyzw, r0.zzzz, r1.xyzw
    r1.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(mad(asfloat(cb1[20].xyzw), asfloat(r0.wwww), asfloat(r1.xyzw))); // mad o0.xyzw, cb1[20].xyzw, r0.wwww, r1.xyzw
    out_o0.xyzw = value_8.xyzw;
    uint4 value_9 = v1.xyxx; // mov o1.xy, v1.xyxx
    out_o1.xy = value_9.xy;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xy);
    return result;
}
