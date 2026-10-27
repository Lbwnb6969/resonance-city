// Register-explicit recovered HLSL. Not original source.
// Placemaker/HoverHightlight vs_4_0 variant []
// Source SHA256 8b26335777c8d72fa78b523d2fa4bf216f585bf2639f158a51b54ce0516aa4d6
// b0: $Globals 720 bytes
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
    float3 v1_0: NORMAL0;
    float2 v2_0: TEXCOORD0;
    float2 v3_0: TEXCOORD1;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float4 o1_0: TANGENT0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 out_o0;
    uint4 out_o1;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xyzw = asuint(input.v0_0);
    v1.xyz = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    v3.xy = asuint(input.v3_0);
    uint4 value_1 = asuint(mad(asfloat(v1.xyzx), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(v0.xyzx))); // mad r0.xyz, v1.xyzx, l(0.100000, 0.100000, 0.100000, 0.000000), v0.xyzx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(asfloat(r0.yyyy) * asfloat(cb1[1].xyzx)); // mul r1.xyz, r0.yyyy, cb1[1].xyzx
    r1.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb1[0].xyxz), asfloat(r0.xxxx), asfloat(r1.xyxz))); // mad r0.xyw, cb1[0].xyxz, r0.xxxx, r1.xyxz
    r0.xyw = value_3.xyw;
    uint4 value_4 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(r0.zzzz), asfloat(r0.xywx))); // mad r0.xyz, cb1[2].xyzx, r0.zzzz, r0.xywx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(mad(asfloat(cb1[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb1[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_5.xyz;
    uint4 value_6 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_6.xyz;
    uint4 value_7 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.w, r1.xyzx, r1.xyzx
    r0.w = value_7.w;
    uint4 value_8 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_8.w;
    uint4 value_9 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_9.w;
    uint4 value_10 = asuint(asfloat(r0.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_10.xyz;
    uint4 value_11 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r0.w, r1.y, cb0[22].w, r0.y
    r0.w = value_11.w;
    uint4 value_12 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_12.w;
    uint4 value_13 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r0.w
    r2.w = value_13.w;
    uint4 value_14 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_14.xz;
    uint4 value_15 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r0.xyz, r0.xyzx, r2.xwzx
    r0.xyz = value_15.xyz;
    uint4 value_16 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_16.xyzw;
    uint4 value_17 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_17.xyzw;
    uint4 value_18 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r0.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r0.xyzw = value_18.xyzw;
    uint4 value_19 = asuint(asfloat(r0.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r0.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_19.xyzw;
    uint4 value_20 = v2.xyxx; // mov r0.xy, v2.xyxx
    r0.xy = value_20.xy;
    uint4 value_21 = v3.xxxx; // mov r0.z, v3.x
    r0.z = value_21.z;
    uint4 value_22 = asuint(mad(asfloat(asuint(-asfloat(asuint(abs(asfloat(r0.xyzx)))))), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x0u)), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)))); // mad o1.xyz, -|r0.xyzx|, l(2.000000, 2.000000, 2.000000, 0.000000), l(1.000000, 1.000000, 1.000000, 0.000000)
    out_o1.xyz = value_22.xyz;
    uint4 value_23 = v3.yyyy; // mov o1.w, v3.y
    out_o1.w = value_23.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xyzw);
    return result;
}
