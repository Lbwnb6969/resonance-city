// Register-explicit recovered HLSL. Not original source.
// Placemaker/Fence vs_4_0 variant []
// Source SHA256 046210a7097faa60ba3ddb3e3f8754e017079f76c1a36a12e81e92403fda1095
// b0: $Globals 656 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[4].x = _SunDir rows=1 cols=3 byte_offset=64
// cb0[5].x = _SunColor rows=1 cols=4 byte_offset=80
// cb0[6].x = _ShadowColor rows=1 cols=4 byte_offset=96
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s1 = _VoxelTex
// t1 / s0 = _AoTex
// t2 / s2 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
SamplerState s2:register(s2);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
Texture2D<float4> t2:register(t2);
// temporary registers: 8
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: NORMAL0;
    float4 v3_0: TANGENT0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD1;
    float4 o1_0: SV_POSITION;
    float4 o2_0: COLOR0;
    float4 o3_0: COLOR1;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 r3;
    uint4 r4;
    uint4 r5;
    uint4 r6;
    uint4 r7;
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 out_o3;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xyz = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = v1.xyxx; // mov o0.xy, v1.xyxx
    out_o0.xy = value_1.xy;
    uint4 value_2 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb1[1].xyzw
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb1[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb1[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(mad(asfloat(cb1[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_6.xyz;
    uint4 value_7 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r1.w, r1.xyzx, r1.xyzx
    r1.w = value_7.w;
    uint4 value_8 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.w, l(1.000000)
    r1.w = value_8.w;
    uint4 value_9 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r1.w, l(0.000000)
    r1.w = value_9.w;
    uint4 value_10 = asuint(asfloat(r1.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r1.wwww, r1.xyzx
    r1.xyz = value_10.xyz;
    uint4 value_11 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r1.w, r1.y, cb0[22].w, r0.y
    r1.w = value_11.w;
    uint4 value_12 = asuint(min(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r1.w, r1.w, l(0.000000)
    r1.w = value_12.w;
    uint4 value_13 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r1.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r1.w
    r2.w = value_13.w;
    uint4 value_14 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_14.xz;
    uint4 value_15 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r1.xyz, r0.xyzx, r2.xwzx
    r1.xyz = value_15.xyz;
    uint4 value_16 = asuint(asfloat(r1.yyyy) * asfloat(cb2[10].xyxx)); // mul r2.xy, r1.yyyy, cb2[10].xyxx
    r2.xy = value_16.xy;
    uint4 value_17 = asuint(mad(asfloat(cb2[9].xyxx), asfloat(r1.xxxx), asfloat(r2.xyxx))); // mad r2.xy, cb2[9].xyxx, r1.xxxx, r2.xyxx
    r2.xy = value_17.xy;
    uint4 value_18 = asuint(mad(asfloat(cb2[11].xyxx), asfloat(r1.zzzz), asfloat(r2.xyxx))); // mad r2.xy, cb2[11].xyxx, r1.zzzz, r2.xyxx
    r2.xy = value_18.xy;
    uint4 value_19 = asuint(mad(asfloat(cb2[12].xxxy), asfloat(r0.wwww), asfloat(r2.xxxy))); // mad o0.zw, cb2[12].xxxy, r0.wwww, r2.xxxy
    out_o0.zw = value_19.zw;
    uint4 value_20 = asuint(asfloat(r1.yyyy) * asfloat(cb2[18].xyzw)); // mul r2.xyzw, r1.yyyy, cb2[18].xyzw
    r2.xyzw = value_20.xyzw;
    uint4 value_21 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r1.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb2[17].xyzw, r1.xxxx, r2.xyzw
    r2.xyzw = value_21.xyzw;
    uint4 value_22 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r1.zzzz), asfloat(r2.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r1.zzzz, r2.xyzw
    r1.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(asfloat(r1.xyzw) + asfloat(cb2[20].xyzw)); // add o1.xyzw, r1.xyzw, cb2[20].xyzw
    out_o1.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(asfloat(r0.xzxz) + asfloat(asuint(-asfloat(cb0[3].xyxy)))); // add r1.xyzw, r0.xzxz, -cb0[3].xyxy
    r1.xyzw = value_24.xyzw;
    uint4 value_25 = asuint(asfloat(r1.xyzw) + asfloat(uint4(0x3ca3d70au, 0x0u, 0x0u, 0x3ca3d70au))); // add r2.xyzw, r1.xyzw, l(0.020000, 0.000000, 0.000000, 0.020000)
    r2.xyzw = value_25.xyzw;
    uint4 value_26 = asuint(asfloat(r1.zwzz) * asfloat(cb0[2].zzzz)); // mul r1.xy, r1.zwzz, cb0[2].zzzz
    r1.xy = value_26.xy;
    uint4 value_27 = asuint(max(asfloat(r1.xyxx), asfloat(cb0[7].xyxx))); // max r1.xy, r1.xyxx, cb0[7].xyxx
    r1.xy = value_27.xy;
    uint4 value_28 = asuint(asfloat(r2.xyzw) * asfloat(cb0[2].zzzz)); // mul r2.xyzw, r2.xyzw, cb0[2].zzzz
    r2.xyzw = value_28.xyzw;
    uint4 value_29 = asuint(max(asfloat(r2.xyzw), asfloat(cb0[7].xyxy))); // max r2.xyzw, r2.xyzw, cb0[7].xyxy
    r2.xyzw = value_29.xyzw;
    uint4 value_30 = asuint(asfloat(cb0[2].xxxy) + asfloat(asuint(-asfloat(cb0[7].xxxy)))); // add r1.zw, cb0[2].xxxy, -cb0[7].xxxy
    r1.zw = value_30.zw;
    uint4 value_31 = asuint(min(asfloat(r1.zwzw), asfloat(r2.xyzw))); // min r2.xyzw, r1.zwzw, r2.xyzw
    r2.xyzw = value_31.xyzw;
    uint4 value_32 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.w, r0.y, l(-0.500000)
    r0.w = value_32.w;
    uint4 value_33 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_33.w;
    uint4 value_34 = asuint(floor(asfloat(r0.wwww))); // round_ni r3.x, r0.w
    r3.x = value_34.x;
    uint4 value_35 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_35.w;
    uint4 value_36 = asuint(int4(asfloat(r3.xxxx))); // ftoi r3.y, r3.x
    r3.y = value_36.y;
    uint4 value_37 = (r3.yyyy + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.z, r3.y, l(1)
    r3.z = value_37.z;
    uint4 value_38 = asuint(float4(asint(r3.zzzz))); // itof r3.w, r3.z
    r3.w = value_38.w;
    uint4 value_39 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r4.x, cb0[2].w
    r4.x = value_39.x;
    uint4 value_40 = uint4(asfloat(r4.xxxx)); // ftou r4.x, r4.x
    r4.x = value_40.x;
    uint4 value_41 = asuint(float4(r4.xxxx)); // utof r4.y, r4.x
    r4.y = value_41.y;
    uint4 value_42 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r4.yyyy)); // div r4.y, l(1.000000, 1.000000, 1.000000, 1.000000), r4.y
    r4.y = value_42.y;
    uint4 value_43 = asuint(asfloat(r3.xxxw) * asfloat(r4.yyyy)); // mul r3.xw, r3.xxxw, r4.yyyy
    r3.xw = value_43.xw;
    uint4 value_44 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.z, r3.w
    r4.z = value_44.z;
    uint4 value_45 = asuint(trunc(asfloat(r3.wwww))); // round_z r5.yw, r3.wwww
    r5.yw = value_45.yw;
    uint4 value_46 = (asuint(-asint(r4.zzzz)) * r4.xxxx + r3.zzzz); // imad r3.z, -r4.z, r4.x, r3.z
    r3.z = value_46.z;
    uint4 value_47 = asuint(float4(r3.zzzz)); // utof r5.xz, r3.zzzz
    r5.xz = value_47.xz;
    uint4 value_48 = asuint(mad(asfloat(r5.xyzw), asfloat(cb0[2].xyxy), asfloat(r2.xyzw))); // mad r6.xyzw, r5.xyzw, cb0[2].xyxy, r2.xyzw
    r6.xyzw = value_48.xyzw;
    uint4 value_49 = asuint(t0.SampleLevel(s1, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r6.xyxx, t0.xyzw, s1, l(0.000000)
    r7.xyzw = value_49.xyzw;
    uint4 value_50 = asuint(t0.SampleLevel(s1, asfloat(r6.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r6.zwzz, t0.xyzw, s1, l(0.000000)
    r6.xyzw = value_50.xyzw;
    uint4 value_51 = asuint(min(asfloat(r1.zwzz), asfloat(r1.xyxx))); // min r1.xy, r1.zwzz, r1.xyxx
    r1.xy = value_51.xy;
    uint4 value_52 = asuint(mad(asfloat(r5.xxxy), asfloat(cb0[2].xxxy), asfloat(r1.xxxy))); // mad r3.zw, r5.xxxy, cb0[2].xxxy, r1.xxxy
    r3.zw = value_52.zw;
    uint4 value_53 = asuint(t0.SampleLevel(s1, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t0.xyzw, s1, l(0.000000)
    r5.xyzw = value_53.xyzw;
    uint4 value_54 = asuint(asfloat(asuint(-asfloat(r5.wwww))) + asfloat(r7.wwww)); // add r3.z, -r5.w, r7.w
    r3.z = value_54.z;
    uint4 value_55 = asuint(asfloat(r3.zzzz) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r5.x, r3.z, l(50.000000)
    r5.x = value_55.x;
    uint4 value_56 = asuint(asfloat(asuint(-asfloat(r5.wwww))) + asfloat(r6.wwww)); // add r3.z, -r5.w, r6.w
    r3.z = value_56.z;
    uint4 value_57 = asuint(asfloat(r3.zzzz) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r5.z, r3.z, l(50.000000)
    r5.z = value_57.z;
    uint4 value_58 = asuint(int4(asfloat(r3.xxxx))); // ftoi r3.z, r3.x
    r3.z = value_58.z;
    uint4 value_59 = asuint(trunc(asfloat(r3.xxxx))); // round_z r6.yw, r3.xxxx
    r6.yw = value_59.yw;
    uint4 value_60 = (asuint(-asint(r3.zzzz)) * r4.xxxx + r3.yyyy); // imad r3.x, -r3.z, r4.x, r3.y
    r3.x = value_60.x;
    uint4 value_61 = asuint(float4(r3.xxxx)); // utof r6.xz, r3.xxxx
    r6.xz = value_61.xz;
    uint4 value_62 = asuint(mad(asfloat(r6.xyzw), asfloat(cb0[2].xyxy), asfloat(r2.xyzw))); // mad r2.xyzw, r6.xyzw, cb0[2].xyxy, r2.xyzw
    r2.xyzw = value_62.xyzw;
    uint4 value_63 = asuint(mad(asfloat(r6.zwzz), asfloat(cb0[2].xyxx), asfloat(r1.xyxx))); // mad r1.xy, r6.zwzz, cb0[2].xyxx, r1.xyxx
    r1.xy = value_63.xy;
    uint4 value_64 = asuint(t0.SampleLevel(s1, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r1.xyxx, t0.xyzw, s1, l(0.000000)
    r3.xyzw = value_64.xyzw;
    uint4 value_65 = asuint(t0.SampleLevel(s1, asfloat(r2.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r2.xyxx, t0.xyzw, s1, l(0.000000)
    r6.xyzw = value_65.xyzw;
    uint4 value_66 = asuint(t0.SampleLevel(s1, asfloat(r2.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r2.zwzz, t0.xyzw, s1, l(0.000000)
    r2.xyzw = value_66.xyzw;
    uint4 value_67 = asuint(asfloat(asuint(-asfloat(r3.wwww))) + asfloat(r2.wwww)); // add r1.x, -r3.w, r2.w
    r1.x = value_67.x;
    uint4 value_68 = asuint(asfloat(r1.xxxx) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r2.z, r1.x, l(50.000000)
    r2.z = value_68.z;
    uint4 value_69 = asuint(asfloat(asuint(-asfloat(r3.wwww))) + asfloat(r6.wwww)); // add r1.x, -r3.w, r6.w
    r1.x = value_69.x;
    uint4 value_70 = asuint(asfloat(asuint(-asfloat(r3.wwww))) + asfloat(r5.wwww)); // add r1.y, -r3.w, r5.w
    r1.y = value_70.y;
    uint4 value_71 = asuint(asfloat(r1.xxxx) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r2.x, r1.x, l(50.000000)
    r2.x = value_71.x;
    uint4 value_72 = asuint(asfloat(asuint(-asfloat(r2.xxxz))) + asfloat(r5.xxxz)); // add r2.yw, -r2.xxxz, r5.xxxz
    r2.yw = value_72.yw;
    uint4 value_73 = asuint(mad(asfloat(r0.wwww), asfloat(r2.yywy), asfloat(r2.xxzx))); // mad r2.xz, r0.wwww, r2.yywy, r2.xxzx
    r2.xz = value_73.xz;
    uint4 value_74 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r0.w, l(1.000000)
    r1.x = value_74.x;
    uint4 value_75 = asuint(asfloat(r0.wwww) * asfloat(r1.xxxx)); // mul r0.w, r0.w, r1.x
    r0.w = value_75.w;
    uint4 value_76 = asuint(asfloat(r0.wwww) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul r0.w, r0.w, l(4.000000)
    r0.w = value_76.w;
    uint4 value_77 = asuint(asfloat(r0.wwww) * asfloat(r1.yyyy)); // mul r2.y, r0.w, r1.y
    r2.y = value_77.y;
    uint4 value_78 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r3.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000), r0.xyzx
    r3.xyz = value_78.xyz;
    uint4 value_79 = asuint(asfloat(r0.xyzx) + asfloat(r2.xyzx)); // add r2.xyz, r0.xyzx, r2.xyzx
    r2.xyz = value_79.xyz;
    uint4 value_80 = asuint(asfloat(r3.yyyy) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r1.xy, r3.yyyy, l(0.700000, -0.300000, 0.000000, 0.000000)
    r1.xy = value_80.xy;
    uint4 value_81 = asuint(asfloat(r3.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r3.xy, r3.xzxx, -cb0[3].xyxx
    r3.xy = value_81.xy;
    uint4 value_82 = asuint(asfloat(r3.xyxx) * asfloat(cb0[2].zzzz)); // mul r3.xy, r3.xyxx, cb0[2].zzzz
    r3.xy = value_82.xy;
    uint4 value_83 = asuint(max(asfloat(r3.xyxx), asfloat(cb0[7].xyxx))); // max r3.xy, r3.xyxx, cb0[7].xyxx
    r3.xy = value_83.xy;
    uint4 value_84 = asuint(min(asfloat(r1.zwzz), asfloat(r3.xyxx))); // min r3.xy, r1.zwzz, r3.xyxx
    r3.xy = value_84.xy;
    uint4 value_85 = asuint(max(asfloat(r1.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r1.y, l(0.000000)
    r0.w = value_85.w;
    uint4 value_86 = asuint(saturate(asfloat(r1.xxxx))); // mov_sat r1.x, r1.x
    r1.x = value_86.x;
    uint4 value_87 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.y, r0.w
    r1.y = value_87.y;
    uint4 value_88 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_88.w;
    uint4 value_89 = asuint(int4(asfloat(r1.yyyy))); // ftoi r2.w, r1.y
    r2.w = value_89.w;
    uint4 value_90 = asuint(asfloat(r4.yyyy) * asfloat(r1.yyyy)); // mul r1.y, r4.y, r1.y
    r1.y = value_90.y;
    uint4 value_91 = (r2.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.z, r2.w, l(1)
    r3.z = value_91.z;
    uint4 value_92 = asuint(float4(asint(r3.zzzz))); // itof r3.w, r3.z
    r3.w = value_92.w;
    uint4 value_93 = asuint(asfloat(r4.yyyy) * asfloat(r3.wwww)); // mul r3.w, r4.y, r3.w
    r3.w = value_93.w;
    uint4 value_94 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.z, r3.w
    r4.z = value_94.z;
    uint4 value_95 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_95.w;
    uint4 value_96 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r3.yyyy))); // mad r5.y, cb0[2].y, r3.w, r3.y
    r5.y = value_96.y;
    uint4 value_97 = (asuint(-asint(r4.zzzz)) * r4.xxxx + r3.zzzz); // imad r3.z, -r4.z, r4.x, r3.z
    r3.z = value_97.z;
    uint4 value_98 = asuint(float4(r3.zzzz)); // utof r3.z, r3.z
    r3.z = value_98.z;
    uint4 value_99 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.zzzz), asfloat(r3.xxxx))); // mad r5.x, cb0[2].x, r3.z, r3.x
    r5.x = value_99.x;
    uint4 value_100 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r6.xyzw = value_100.xyzw;
    uint4 value_101 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.z, r5.y, l(1.000000)
    r3.z = value_101.z;
    uint4 value_102 = (r3.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.z, r3.z, l(0x3f800000)
    r3.z = value_102.z;
    uint4 value_103 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_103.xyz;
    uint4 value_104 = asuint(mad(asfloat(r3.zzzz), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r5.xyz, r3.zzzz, r5.xyzx, r6.xyzx
    r5.xyz = value_104.xyz;
    uint4 value_105 = asuint(int4(asfloat(r1.yyyy))); // ftoi r3.z, r1.y
    r3.z = value_105.z;
    uint4 value_106 = asuint(trunc(asfloat(r1.yyyy))); // round_z r1.y, r1.y
    r1.y = value_106.y;
    uint4 value_107 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.yyyy), asfloat(r3.yyyy))); // mad r6.y, cb0[2].y, r1.y, r3.y
    r6.y = value_107.y;
    uint4 value_108 = (asuint(-asint(r3.zzzz)) * r4.xxxx + r2.wwww); // imad r1.y, -r3.z, r4.x, r2.w
    r1.y = value_108.y;
    uint4 value_109 = asuint(float4(r1.yyyy)); // utof r1.y, r1.y
    r1.y = value_109.y;
    uint4 value_110 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.yyyy), asfloat(r3.xxxx))); // mad r6.x, cb0[2].x, r1.y, r3.x
    r6.x = value_110.x;
    uint4 value_111 = asuint(t1.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r6.xyxx, t1.xyzw, s0, l(0.000000)
    r3.xyzw = value_111.xyzw;
    uint4 value_112 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.y, r6.y, l(1.000000)
    r1.y = value_112.y;
    uint4 value_113 = (r1.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.y, r1.y, l(0x3f800000)
    r1.y = value_113.y;
    uint4 value_114 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r6.xyz, -r3.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r6.xyz = value_114.xyz;
    uint4 value_115 = asuint(mad(asfloat(r1.yyyy), asfloat(r6.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r1.yyyy, r6.xyzx, r3.xyzx
    r3.xyz = value_115.xyz;
    uint4 value_116 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(r5.xyzx)); // add r5.xyz, -r3.xyzx, r5.xyzx
    r5.xyz = value_116.xyz;
    uint4 value_117 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r0.wwww, r5.xyzx, r3.xyzx
    r3.xyz = value_117.xyz;
    uint4 value_118 = asuint(asfloat(r3.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r3.xyz, r3.xyzx, -cb0[9].xyzx
    r3.xyz = value_118.xyz;
    uint4 value_119 = asuint(mad(asfloat(r1.xxxx), asfloat(r3.xyzx), asfloat(cb0[9].xyzx))); // mad r3.xyz, r1.xxxx, r3.xyzx, cb0[9].xyzx
    r3.xyz = value_119.xyz;
    uint4 value_120 = asuint(asfloat(r2.yyyy) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r1.xy, r2.yyyy, l(0.700000, -0.300000, 0.000000, 0.000000)
    r1.xy = value_120.xy;
    uint4 value_121 = asuint(asfloat(r2.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r2.xy, r2.xzxx, -cb0[3].xyxx
    r2.xy = value_121.xy;
    uint4 value_122 = asuint(asfloat(r2.xyxx) * asfloat(cb0[2].zzzz)); // mul r2.xy, r2.xyxx, cb0[2].zzzz
    r2.xy = value_122.xy;
    uint4 value_123 = asuint(max(asfloat(r2.xyxx), asfloat(cb0[7].xyxx))); // max r2.xy, r2.xyxx, cb0[7].xyxx
    r2.xy = value_123.xy;
    uint4 value_124 = asuint(min(asfloat(r1.zzzw), asfloat(r2.xxxy))); // min r1.zw, r1.zzzw, r2.xxxy
    r1.zw = value_124.zw;
    uint4 value_125 = asuint(max(asfloat(r1.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r1.y, l(0.000000)
    r0.w = value_125.w;
    uint4 value_126 = asuint(saturate(asfloat(r1.xxxx))); // mov_sat r1.x, r1.x
    r1.x = value_126.x;
    uint4 value_127 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.y, r0.w
    r1.y = value_127.y;
    uint4 value_128 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_128.w;
    uint4 value_129 = asuint(int4(asfloat(r1.yyyy))); // ftoi r2.x, r1.y
    r2.x = value_129.x;
    uint4 value_130 = asuint(asfloat(r4.yyyy) * asfloat(r1.yyyy)); // mul r1.y, r4.y, r1.y
    r1.y = value_130.y;
    uint4 value_131 = (r2.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.y, r2.x, l(1)
    r2.y = value_131.y;
    uint4 value_132 = asuint(float4(asint(r2.yyyy))); // itof r2.z, r2.y
    r2.z = value_132.z;
    uint4 value_133 = asuint(asfloat(r4.yyyy) * asfloat(r2.zzzz)); // mul r2.z, r4.y, r2.z
    r2.z = value_133.z;
    uint4 value_134 = asuint(int4(asfloat(r2.zzzz))); // ftoi r2.w, r2.z
    r2.w = value_134.w;
    uint4 value_135 = asuint(trunc(asfloat(r2.zzzz))); // round_z r2.z, r2.z
    r2.z = value_135.z;
    uint4 value_136 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.zzzz), asfloat(r1.wwww))); // mad r5.y, cb0[2].y, r2.z, r1.w
    r5.y = value_136.y;
    uint4 value_137 = (asuint(-asint(r2.wwww)) * r4.xxxx + r2.yyyy); // imad r2.y, -r2.w, r4.x, r2.y
    r2.y = value_137.y;
    uint4 value_138 = asuint(float4(r2.yyyy)); // utof r2.y, r2.y
    r2.y = value_138.y;
    uint4 value_139 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.yyyy), asfloat(r1.zzzz))); // mad r5.x, cb0[2].x, r2.y, r1.z
    r5.x = value_139.x;
    uint4 value_140 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r6.xyzw = value_140.xyzw;
    uint4 value_141 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.y, r5.y, l(1.000000)
    r2.y = value_141.y;
    uint4 value_142 = (r2.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.y, r2.y, l(0x3f800000)
    r2.y = value_142.y;
    uint4 value_143 = asuint(asfloat(asuint(-asfloat(r6.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r4.yzw, -r6.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r4.yzw = value_143.yzw;
    uint4 value_144 = asuint(mad(asfloat(r2.yyyy), asfloat(r4.yyzw), asfloat(r6.xxyz))); // mad r2.yzw, r2.yyyy, r4.yyzw, r6.xxyz
    r2.yzw = value_144.yzw;
    uint4 value_145 = asuint(int4(asfloat(r1.yyyy))); // ftoi r3.w, r1.y
    r3.w = value_145.w;
    uint4 value_146 = asuint(trunc(asfloat(r1.yyyy))); // round_z r1.y, r1.y
    r1.y = value_146.y;
    uint4 value_147 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.yyyy), asfloat(r1.wwww))); // mad r5.y, cb0[2].y, r1.y, r1.w
    r5.y = value_147.y;
    uint4 value_148 = (asuint(-asint(r3.wwww)) * r4.xxxx + r2.xxxx); // imad r1.y, -r3.w, r4.x, r2.x
    r1.y = value_148.y;
    uint4 value_149 = asuint(float4(r1.yyyy)); // utof r1.y, r1.y
    r1.y = value_149.y;
    uint4 value_150 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.yyyy), asfloat(r1.zzzz))); // mad r5.x, cb0[2].x, r1.y, r1.z
    r5.x = value_150.x;
    uint4 value_151 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r4.xyzw = value_151.xyzw;
    uint4 value_152 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.y, r5.y, l(1.000000)
    r1.y = value_152.y;
    uint4 value_153 = (r1.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.y, r1.y, l(0x3f800000)
    r1.y = value_153.y;
    uint4 value_154 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r4.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_154.xyz;
    uint4 value_155 = asuint(mad(asfloat(r1.yyyy), asfloat(r5.xxyz), asfloat(r4.xxyz))); // mad r1.yzw, r1.yyyy, r5.xxyz, r4.xxyz
    r1.yzw = value_155.yzw;
    uint4 value_156 = asuint(asfloat(asuint(-asfloat(r1.yzwy))) + asfloat(r2.yzwy)); // add r2.xyz, -r1.yzwy, r2.yzwy
    r2.xyz = value_156.xyz;
    uint4 value_157 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xxyz), asfloat(r1.yyzw))); // mad r1.yzw, r0.wwww, r2.xxyz, r1.yyzw
    r1.yzw = value_157.yzw;
    uint4 value_158 = asuint(asfloat(r1.yyzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r1.yzw, r1.yyzw, -cb0[9].xxyz
    r1.yzw = value_158.yzw;
    uint4 value_159 = asuint(mad(asfloat(r1.xxxx), asfloat(r1.yzwy), asfloat(cb0[9].xyzx))); // mad r1.xyz, r1.xxxx, r1.yzwy, cb0[9].xyzx
    r1.xyz = value_159.xyz;
    uint4 value_160 = asuint(asfloat(r1.xyzx) * asfloat(r3.xyzx)); // mul r2.xyz, r1.xyzx, r3.xyzx
    r2.xyz = value_160.xyz;
    uint4 value_161 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r2.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_161.w;
    uint4 value_162 = asuint(mad(asfloat(r3.xyzx), asfloat(r1.xyzx), asfloat(asuint(-asfloat(r0.wwww))))); // mad r1.xyz, r3.xyzx, r1.xyzx, -r0.wwww
    r1.xyz = value_162.xyz;
    uint4 value_163 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r1.w, cb0[5].w, cb0[6].w
    r1.w = value_163.w;
    uint4 value_164 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r1.w, r1.w, l(0.500000)
    r1.w = value_164.w;
    uint4 value_165 = asuint(asfloat(r1.wwww) * asfloat(cb0[29].xxxx)); // mul r1.w, r1.w, cb0[29].x
    r1.w = value_165.w;
    uint4 value_166 = asuint(mad(asfloat(r1.wwww), asfloat(r1.xyzx), asfloat(r0.wwww))); // mad r1.xyz, r1.wwww, r1.xyzx, r0.wwww
    r1.xyz = value_166.xyz;
    uint4 value_167 = asuint(asfloat(r0.yyyy) * asfloat(cb0[31].xyzx)); // mul r2.xyz, r0.yyyy, cb0[31].xyzx
    r2.xyz = value_167.xyz;
    uint4 value_168 = asuint(mad(asfloat(cb0[30].xyxz), asfloat(r0.xxxx), asfloat(r2.xyxz))); // mad r0.xyw, cb0[30].xyxz, r0.xxxx, r2.xyxz
    r0.xyw = value_168.xyw;
    uint4 value_169 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r0.zzzz), asfloat(r0.xywx))); // mad r0.xyz, cb0[32].xyzx, r0.zzzz, r0.xywx
    r0.xyz = value_169.xyz;
    uint4 value_170 = asuint(asfloat(r0.xyzx) + asfloat(cb0[33].xyzx)); // add r0.xyz, r0.xyzx, cb0[33].xyzx
    r0.xyz = value_170.xyz;
    uint4 value_171 = asuint(asfloat(r0.xyxx) * asfloat(cb0[39].zwzz)); // mul r2.xy, r0.xyxx, cb0[39].zwzz
    r2.xy = value_171.xy;
    uint4 value_172 = asuint(frac(asfloat(r2.xxxy))); // frc r2.zw, r2.xxxy
    r2.zw = value_172.zw;
    uint4 value_173 = asuint(asfloat(v2.yyyy) * asfloat(cb1[1].xyzx)); // mul r3.xyz, v2.yyyy, cb1[1].xyzx
    r3.xyz = value_173.xyz;
    uint4 value_174 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v2.xxxx), asfloat(r3.xyzx))); // mad r3.xyz, cb1[0].xyzx, v2.xxxx, r3.xyzx
    r3.xyz = value_174.xyz;
    uint4 value_175 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v2.zzzz), asfloat(r3.xyzx))); // mad r3.xyz, cb1[2].xyzx, v2.zzzz, r3.xyzx
    r3.xyz = value_175.xyz;
    uint4 value_176 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.w, r3.xyzx, -cb0[4].xyzx
    r0.w = value_176.w;
    uint4 value_177 = asuint(asfloat(r0.wwww) * asfloat(cb0[38].yyyy)); // mul r1.w, r0.w, cb0[38].y
    r1.w = value_177.w;
    uint4 value_178 = asuint(saturate(asfloat(r0.wwww))); // mov_sat r0.w, r0.w
    r0.w = value_178.w;
    uint4 value_179 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_179.w;
    uint4 value_180 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r0.zzzz))); // mad r0.z, -r1.w, l(0.050000), r0.z
    r0.z = value_180.z;
    uint4 value_181 = r0.xyxx; // mov o3.xy, r0.xyxx
    out_o3.xy = value_181.xy;
    uint4 value_182 = asuint(asfloat(r0.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r3.z, r0.z, l(-0.003922)
    r3.z = value_182.z;
    uint4 value_183 = asuint(asfloat(r2.xxxy) * asfloat(cb0[39].xxxy)); // mul r4.zw, r2.xxxy, cb0[39].xxxy
    r4.zw = value_183.zw;
    uint4 value_184 = asuint(mad(asfloat(r2.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r4.xy, r2.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r4.xy = value_184.xy;
    uint4 value_185 = asuint(t2.SampleLevel(s2, asfloat(r4.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.zyzz, t2.xyzw, s2, l(0.000000)
    r5.xyzw = value_185.xyzw;
    uint4 value_186 = asuint(asfloat(r3.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r0.xyz, r3.zzzz, -r5.xyzx
    r0.xyz = value_186.xyz;
    uint4 value_187 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r1.w, cb0[38].x, l(20.000000)
    r1.w = value_187.w;
    uint4 value_188 = asuint(saturate(asfloat(asuint(asfloat(r0.xyzx) * asfloat(r1.wwww))))); // mul_sat r0.xyz, r0.xyzx, r1.wwww
    r0.xyz = value_188.xyz;
    uint4 value_189 = asuint(asfloat(asuint(-asfloat(r2.zwzz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r2.xy, -r2.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
    r2.xy = value_189.xy;
    uint4 value_190 = asuint(asfloat(r0.xyzx) * asfloat(r2.xxxx)); // mul r0.xyz, r0.xyzx, r2.xxxx
    r0.xyz = value_190.xyz;
    uint4 value_191 = asuint(asfloat(r2.wwww) * asfloat(r0.xyzx)); // mul r0.xyz, r2.wwww, r0.xyzx
    r0.xyz = value_191.xyz;
    uint4 value_192 = asuint(t2.SampleLevel(s2, asfloat(r4.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.zwzz, t2.xyzw, s2, l(0.000000)
    r5.xyzw = value_192.xyzw;
    uint4 value_193 = asuint(t2.SampleLevel(s2, asfloat(r4.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r4.xwxx, t2.xyzw, s2, l(0.000000)
    r6.xyzw = value_193.xyzw;
    uint4 value_194 = asuint(t2.SampleLevel(s2, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r4.xyxx, t2.xyzw, s2, l(0.000000)
    r4.xyzw = value_194.xyzw;
    uint4 value_195 = asuint(asfloat(r3.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r3.zzzz, -r4.xyzx
    r4.xyz = value_195.xyz;
    uint4 value_196 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r1.wwww, r4.xyzx
    r4.xyz = value_196.xyz;
    uint4 value_197 = asuint(asfloat(r2.zzzz) * asfloat(r4.xyzx)); // mul r4.xyz, r2.zzzz, r4.xyzx
    r4.xyz = value_197.xyz;
    uint4 value_198 = asuint(asfloat(r3.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r3.zzzz, -r6.xyzx
    r6.xyz = value_198.xyz;
    uint4 value_199 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r1.wwww, r6.xyzx
    r6.xyz = value_199.xyz;
    uint4 value_200 = asuint(asfloat(r2.zzzz) * asfloat(r6.xyzx)); // mul r6.xyz, r2.zzzz, r6.xyzx
    r6.xyz = value_200.xyz;
    uint4 value_201 = asuint(asfloat(r3.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r3.zzzz, -r5.xyzx
    r5.xyz = value_201.xyz;
    uint4 value_202 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r1.wwww, r5.xyzx
    r5.xyz = value_202.xyz;
    uint4 value_203 = asuint(asfloat(r2.xxxx) * asfloat(r5.xyzx)); // mul r5.xyz, r2.xxxx, r5.xyzx
    r5.xyz = value_203.xyz;
    uint4 value_204 = asuint(mad(asfloat(r5.xyzx), asfloat(r2.yyyy), asfloat(r0.xyzx))); // mad r0.xyz, r5.xyzx, r2.yyyy, r0.xyzx
    r0.xyz = value_204.xyz;
    uint4 value_205 = asuint(mad(asfloat(r6.xyzx), asfloat(r2.yyyy), asfloat(r0.xyzx))); // mad r0.xyz, r6.xyzx, r2.yyyy, r0.xyzx
    r0.xyz = value_205.xyz;
    uint4 value_206 = asuint(mad(asfloat(r4.xyzx), asfloat(r2.wwww), asfloat(r0.xyzx))); // mad r0.xyz, r4.xyzx, r2.wwww, r0.xyzx
    r0.xyz = value_206.xyz;
    uint4 value_207 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r0.x, r0.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r0.x = value_207.x;
    uint4 value_208 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_208.x;
    uint4 value_209 = asuint(asfloat(r0.wwww) * asfloat(r0.wwww)); // mul r0.y, r0.w, r0.w
    r0.y = value_209.y;
    uint4 value_210 = asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(r0.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r3.w, -r0.w, r0.y, l(1.000000)
    r3.w = value_210.w;
    uint4 value_211 = asuint(asfloat(r0.xxxx) * asfloat(r3.wwww)); // mul r0.x, r0.x, r3.w
    r0.x = value_211.x;
    uint4 value_212 = r3.zzzw; // mov o3.zw, r3.zzzw
    out_o3.zw = value_212.zw;
    uint4 value_213 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].wwww)); // mul r0.x, r0.x, cb0[5].w
    r0.x = value_213.x;
    uint4 value_214 = asuint(asfloat(cb0[6].xxyz) * asfloat(uint4(0x0u, 0x3fe66666u, 0x3fe66666u, 0x3fe66666u))); // mul r0.yzw, cb0[6].xxyz, l(0.000000, 1.800000, 1.800000, 1.800000)
    r0.yzw = value_214.yzw;
    uint4 value_215 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r0.yzwy))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r0.yzwy
    r2.xyz = value_215.xyz;
    uint4 value_216 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xxyz), asfloat(r0.yyzw))); // mad r0.yzw, r0.xxxx, r2.xxyz, r0.yyzw
    r0.yzw = value_216.yzw;
    uint4 value_217 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.xxxx, cb0[5].xyzx
    r2.xyz = value_217.xyz;
    uint4 value_218 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_218.xyz;
    uint4 value_219 = asuint(mad(asfloat(r1.xxyz), asfloat(r0.yyzw), asfloat(r2.xxyz))); // mad r0.yzw, r1.xxyz, r0.yyzw, r2.xxyz
    r0.yzw = value_219.yzw;
    uint4 value_220 = asuint(asfloat(r0.yzwy) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add o2.xyz, r0.yzwy, l(0.100000, 0.100000, 0.100000, 0.000000)
    out_o2.xyz = value_220.xyz;
    uint4 value_221 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.y, cb0[5].w, -cb0[6].w
    r0.y = value_221.y;
    uint4 value_222 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yyyy), asfloat(cb0[6].wwww))); // mad o2.w, r0.x, r0.y, cb0[6].w
    out_o2.w = value_222.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xyzw);
    result.o2_0 = asfloat(out_o2.xyzw);
    result.o3_0 = asfloat(out_o3.xyzw);
    return result;
}
