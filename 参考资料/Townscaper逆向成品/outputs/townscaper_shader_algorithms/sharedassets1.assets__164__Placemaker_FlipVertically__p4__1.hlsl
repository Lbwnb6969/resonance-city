// Register-explicit recovered HLSL. Not original source.
// Placemaker/FlipVertically vs_4_0 variant ['FLIP']
// Source SHA256 b4d31df5bf287644baa484a93248dfec353f15830cbfb3bf33ffcf13f264d5d8
// b0: $Globals 48 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[2].x = _MainTex_ST rows=1 cols=4 byte_offset=32
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[3]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
// temporary registers: 2
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float4 o1_0: SV_POSITION;
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
    uint4 value_1 = asuint(mad(asfloat(v1.xyxx), asfloat(cb0[2].xyxx), asfloat(cb0[2].zwzz))); // mad o0.xy, v1.xyxx, cb0[2].xyxx, cb0[2].zwzz
    out_o0.xy = value_1.xy;
    uint4 value_2 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb1[1].xyzw
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb1[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb1[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(asfloat(r0.xyzw) + asfloat(cb1[3].xyzw)); // add r0.xyzw, r0.xyzw, cb1[3].xyzw
    r0.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r1.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(mad(asfloat(cb2[20].xyzw), asfloat(r0.wwww), asfloat(r1.xyzw))); // mad o1.xyzw, cb2[20].xyzw, r0.wwww, r1.xyzw
    out_o1.xyzw = value_9.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o1_0 = asfloat(out_o1.xyzw);
    return result;
}
