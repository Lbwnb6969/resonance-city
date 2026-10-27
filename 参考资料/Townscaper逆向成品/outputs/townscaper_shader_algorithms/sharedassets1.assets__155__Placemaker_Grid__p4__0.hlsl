// Register-explicit recovered HLSL. Not original source.
// Placemaker/Grid vs_4_0 variant []
// Source SHA256 9a2d8d492330881e40c04e4bb2f0441298e96541012641c4113c645ee353092a
// b0: $Globals 688 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[25].x = _GridBorderMin rows=1 cols=3 byte_offset=400
// cb0[26].x = _GridBorderMax rows=1 cols=3 byte_offset=416
// cb0[27].x = _GridViewMin rows=1 cols=3 byte_offset=432
// cb0[28].x = _GridViewMax rows=1 cols=3 byte_offset=448
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[29]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
// temporary registers: 2
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float2 v2_0: TEXCOORD1;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float2 o1_0: TEXCOORD0;
    float2 o1_1: TEXCOORD1;
    float2 o2_0: TEXCOORD2;
    float2 o2_1: TEXCOORD3;
    float4 o3_0: COLOR0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 out_o3;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    uint4 value_1 = asuint(asfloat(cb2[18].xyzw) * asfloat(uint4(0x3d23d70au, 0x3d23d70au, 0x3d23d70au, 0x3d23d70au))); // mul r0.xyzw, cb2[18].xyzw, l(0.040000, 0.040000, 0.040000, 0.040000)
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xzwx)); // mul r1.xyz, v0.yyyy, cb1[1].xzwx
    r1.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb1[0].xzwx), asfloat(v0.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb1[0].xzwx, v0.xxxx, r1.xyzx
    r1.xyz = value_3.xyz;
    uint4 value_4 = asuint(mad(asfloat(cb1[2].xzwx), asfloat(v0.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb1[2].xzwx, v0.zzzz, r1.xyzx
    r1.xyz = value_4.xyz;
    uint4 value_5 = asuint(mad(asfloat(cb1[3].xzwx), asfloat(v0.wwww), asfloat(r1.xyzx))); // mad r1.xyz, cb1[3].xzwx, v0.wwww, r1.xyzx
    r1.xyz = value_5.xyz;
    uint4 value_6 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r1.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[17].xyzw, r1.xxxx, r0.xyzw
    r0.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r1.yyyy), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[19].xyzw, r1.yyyy, r0.xyzw
    r0.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(asfloat(r0.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r0.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(asfloat(v1.xyxx) + asfloat(asuint(-asfloat(cb0[25].xyxx)))); // add r0.xy, v1.xyxx, -cb0[25].xyxx
    r0.xy = value_9.xy;
    uint4 value_10 = asuint(min(asfloat(r0.yyyy), asfloat(r0.xxxx))); // min r0.x, r0.y, r0.x
    r0.x = value_10.x;
    uint4 value_11 = asuint(asfloat(asuint(-asfloat(v1.yyyy))) + asfloat(asuint(-asfloat(v1.xxxx)))); // add r0.y, -v1.y, -v1.x
    r0.y = value_11.y;
    uint4 value_12 = asuint(asfloat(r0.yyyy) + asfloat(asuint(-asfloat(cb0[25].zzzz)))); // add r0.z, r0.y, -cb0[25].z
    r0.z = value_12.z;
    uint4 value_13 = asuint(min(asfloat(r0.zzzz), asfloat(r0.xxxx))); // min r0.x, r0.z, r0.x
    r0.x = value_13.x;
    uint4 value_14 = asuint(asfloat(asuint(-asfloat(v1.xxxy))) + asfloat(cb0[26].xxxy)); // add r0.zw, -v1.xxxy, cb0[26].xxxy
    r0.zw = value_14.zw;
    uint4 value_15 = asuint(min(asfloat(r0.zzzz), asfloat(r0.xxxx))); // min r0.x, r0.z, r0.x
    r0.x = value_15.x;
    uint4 value_16 = asuint(min(asfloat(r0.wwww), asfloat(r0.xxxx))); // min r0.x, r0.w, r0.x
    r0.x = value_16.x;
    uint4 value_17 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(cb0[26].zzzz)); // add r0.z, -r0.y, cb0[26].z
    r0.z = value_17.z;
    uint4 value_18 = asuint(saturate(asfloat(asuint(min(asfloat(r0.zzzz), asfloat(r0.xxxx)))))); // min_sat r0.x, r0.z, r0.x
    r0.x = value_18.x;
    uint4 value_19 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_19.x;
    uint4 value_20 = asuint(max(asfloat(asuint(abs(asfloat(v2.yyyy)))), asfloat(asuint(abs(asfloat(v2.xxxx)))))); // max r0.z, |v2.y|, |v2.x|
    r0.z = value_20.z;
    uint4 value_21 = asuint(asfloat(r0.zzzz) * asfloat(r0.xxxx)); // mul o1.x, r0.z, r0.x
    out_o1.x = value_21.x;
    uint4 value_22 = v2.xxxy; // mov o1.zw, v2.xxxy
    out_o1.zw = value_22.zw;
    uint4 value_23 = r0.zzzz; // mov o1.y, r0.z
    out_o1.y = value_23.y;
    uint4 value_24 = asuint(asfloat(cb2[10].xxxy) * asfloat(uint4(0x3d23d70au, 0x0u, 0x0u, 0x3d23d70au))); // mul r0.xw, cb2[10].xxxy, l(0.040000, 0.000000, 0.000000, 0.040000)
    r0.xw = value_24.xw;
    uint4 value_25 = asuint(mad(asfloat(cb2[9].xxxy), asfloat(r1.xxxx), asfloat(r0.xxxw))); // mad r0.xw, cb2[9].xxxy, r1.xxxx, r0.xxxw
    r0.xw = value_25.xw;
    uint4 value_26 = asuint(mad(asfloat(cb2[11].xxxy), asfloat(r1.yyyy), asfloat(r0.xxxw))); // mad r0.xw, cb2[11].xxxy, r1.yyyy, r0.xxxw
    r0.xw = value_26.xw;
    uint4 value_27 = asuint(mad(asfloat(cb2[12].xyxx), asfloat(r1.zzzz), asfloat(r0.xwxx))); // mad o2.xy, cb2[12].xyxx, r1.zzzz, r0.xwxx
    out_o2.xy = value_27.xy;
    uint4 value_28 = asuint(asfloat(v1.xxxy) + asfloat(asuint(-asfloat(cb0[27].xxxy)))); // add r0.xw, v1.xxxy, -cb0[27].xxxy
    r0.xw = value_28.xw;
    uint4 value_29 = asuint(min(asfloat(r0.wwww), asfloat(r0.xxxx))); // min r0.x, r0.w, r0.x
    r0.x = value_29.x;
    uint4 value_30 = asuint(asfloat(r0.yyyy) + asfloat(asuint(-asfloat(cb0[27].zzzz)))); // add r0.w, r0.y, -cb0[27].z
    r0.w = value_30.w;
    uint4 value_31 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(cb0[28].zzzz)); // add r0.y, -r0.y, cb0[28].z
    r0.y = value_31.y;
    uint4 value_32 = asuint(min(asfloat(r0.wwww), asfloat(r0.xxxx))); // min r0.x, r0.w, r0.x
    r0.x = value_32.x;
    uint4 value_33 = asuint(asfloat(asuint(-asfloat(v1.xyxx))) + asfloat(cb0[28].xyxx)); // add r1.xy, -v1.xyxx, cb0[28].xyxx
    r1.xy = value_33.xy;
    uint4 value_34 = asuint(min(asfloat(r0.xxxx), asfloat(r1.xxxx))); // min r0.x, r0.x, r1.x
    r0.x = value_34.x;
    uint4 value_35 = asuint(min(asfloat(r1.yyyy), asfloat(r0.xxxx))); // min r0.x, r1.y, r0.x
    r0.x = value_35.x;
    uint4 value_36 = asuint(min(asfloat(r0.yyyy), asfloat(r0.xxxx))); // min r0.x, r0.y, r0.x
    r0.x = value_36.x;
    uint4 value_37 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))))); // add_sat r0.x, r0.x, l(1.000000)
    r0.x = value_37.x;
    uint4 value_38 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_38.x;
    uint4 value_39 = asuint(asfloat(r0.zzzz) * asfloat(r0.xxxx)); // mul o2.z, r0.z, r0.x
    out_o2.z = value_39.z;
    uint4 value_40 = r0.zzzz; // mov o2.w, r0.z
    out_o2.w = value_40.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xy);
    result.o1_1 = asfloat(out_o1.zw);
    result.o2_0 = asfloat(out_o2.xy);
    result.o2_1 = asfloat(out_o2.zw);
    result.o3_0 = asfloat(out_o3.xyzw);
    return result;
}
