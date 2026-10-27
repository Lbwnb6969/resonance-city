// Register-explicit recovered HLSL. Not original source.
// Placemaker/Hole0 vs_4_0 variant []
// Source SHA256 0836cbc22672bfa5833607c0c3cc38c1f6de259cbceceb145b58245774d500fa
// b0: $Globals 640 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[23]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
// temporary registers: 3
struct Input {
    float4 v0_0: POSITION0;
};
struct Output {
    float4 o0_0: SV_POSITION;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 out_o0;
    uint4 v0;
    v0.xyzw = asuint(input.v0_0);
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzx)); // mul r0.xyz, v0.yyyy, cb1[1].xyzx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb1[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb1[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(mad(asfloat(cb1[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb1[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_5.xyz;
    uint4 value_6 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.w, r1.xyzx, r1.xyzx
    r0.w = value_6.w;
    uint4 value_7 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_7.w;
    uint4 value_8 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_8.w;
    uint4 value_9 = asuint(asfloat(r0.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_9.xyz;
    uint4 value_10 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r0.w, r1.y, cb0[22].w, r0.y
    r0.w = value_10.w;
    uint4 value_11 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_11.w;
    uint4 value_12 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r0.w
    r2.w = value_12.w;
    uint4 value_13 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_13.xz;
    uint4 value_14 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r0.xyz, r0.xyzx, r2.xwzx
    r0.xyz = value_14.xyz;
    uint4 value_15 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_15.xyzw;
    uint4 value_16 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_16.xyzw;
    uint4 value_17 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r0.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r0.xyzw = value_17.xyzw;
    uint4 value_18 = asuint(asfloat(r0.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r0.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_18.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
