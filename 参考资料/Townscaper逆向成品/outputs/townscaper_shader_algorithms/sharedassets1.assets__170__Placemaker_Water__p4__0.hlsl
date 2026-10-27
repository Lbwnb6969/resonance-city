// Register-explicit recovered HLSL. Not original source.
// Placemaker/Water vs_4_0 variant []
// Source SHA256 6b78dbf6aa2301ebee35c29b01bde25d0f4dabcd4add71428e226253bff5faf2
// b0: $Globals 688 bytes
// b1: UnityPerCamera 144 bytes
// b2: UnityPerDraw 176 bytes
// b3: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[4].x = _SunDir rows=1 cols=3 byte_offset=64
// cb0[5].x = _SunColor rows=1 cols=4 byte_offset=80
// cb0[6].x = _ShadowColor rows=1 cols=4 byte_offset=96
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[8].x = _BgColor rows=1 cols=4 byte_offset=128
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _AoTex
// t1 / s1 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
cbuffer Buffer1:register(b1) { uint4 cb1[5]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[21]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 11
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: NORMAL0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD1;
    float2 o1_0: TEXCOORD2;
    float4 o2_0: SV_POSITION;
    float4 o3_0: COLOR0;
    float4 o4_0: COLOR1;
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
    uint4 r8;
    uint4 r9;
    uint4 r10;
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 out_o3;
    uint4 out_o4;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xyz = asuint(input.v2_0);
    uint4 value_1 = asuint(frac(asfloat(v1.xxxx))); // frc r0.x, v1.x
    r0.x = value_1.x;
    uint4 value_2 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul o0.z, r0.x, l(4.000000)
    out_o0.z = value_2.z;
    uint4 value_3 = v1.yyyy; // mov o0.w, v1.y
    out_o0.w = value_3.w;
    uint4 value_4 = asuint(asfloat(v1.yyyy) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, v1.y, l(1.000000)
    r0.x = value_4.x;
    uint4 value_5 = asuint(floor(asfloat(v1.xxxx))); // round_ni r0.y, v1.x
    r0.y = value_5.y;
    uint4 value_6 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -r0.y, l(1.000000)
    r0.y = value_6.y;
    uint4 value_7 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul o0.y, r0.y, r0.x
    out_o0.y = value_7.y;
    uint4 value_8 = r0.yyyy; // mov o0.x, r0.y
    out_o0.x = value_8.x;
    uint4 value_9 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xxyz)); // mul r0.xzw, v0.yyyy, cb2[1].xxyz
    r0.xzw = value_9.xzw;
    uint4 value_10 = asuint(mad(asfloat(cb2[0].xxyz), asfloat(v0.xxxx), asfloat(r0.xxzw))); // mad r0.xzw, cb2[0].xxyz, v0.xxxx, r0.xxzw
    r0.xzw = value_10.xzw;
    uint4 value_11 = asuint(mad(asfloat(cb2[2].xxyz), asfloat(v0.zzzz), asfloat(r0.xxzw))); // mad r0.xzw, cb2[2].xxyz, v0.zzzz, r0.xxzw
    r0.xzw = value_11.xzw;
    uint4 value_12 = asuint(mad(asfloat(cb2[3].xxyz), asfloat(v0.wwww), asfloat(r0.xxzw))); // mad r0.xzw, cb2[3].xxyz, v0.wwww, r0.xxzw
    r0.xzw = value_12.xzw;
    uint4 value_13 = asuint(asfloat(r0.xzwx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xzwx, -cb0[22].xyzx
    r1.xyz = value_13.xyz;
    uint4 value_14 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r1.w, r1.xyzx, r1.xyzx
    r1.w = value_14.w;
    uint4 value_15 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.w, l(1.000000)
    r1.w = value_15.w;
    uint4 value_16 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r1.w, l(0.000000)
    r1.w = value_16.w;
    uint4 value_17 = asuint(asfloat(r1.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r1.wwww, r1.xyzx
    r1.xyz = value_17.xyz;
    uint4 value_18 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.zzzz))); // mad r1.w, r1.y, cb0[22].w, r0.z
    r1.w = value_18.w;
    uint4 value_19 = asuint(min(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r1.w, r1.w, l(0.000000)
    r1.w = value_19.w;
    uint4 value_20 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r1.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r1.w
    r2.w = value_20.w;
    uint4 value_21 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_21.xz;
    uint4 value_22 = asuint(asfloat(r0.xzwx) + asfloat(r2.xwzx)); // add r1.xyz, r0.xzwx, r2.xwzx
    r1.xyz = value_22.xyz;
    uint4 value_23 = asuint(mad(asfloat(asuint(-asfloat(r0.yyyy))), asfloat(uint4(0x3c23d70au, 0x3c23d70au, 0x3c23d70au, 0x3c23d70au)), asfloat(r1.yyyy))); // mad r1.w, -r0.y, l(0.010000), r1.y
    r1.w = value_23.w;
    uint4 value_24 = asuint(asfloat(r1.xwzx) + asfloat(asuint(-asfloat(cb1[4].xyzx)))); // add r0.xyz, r1.xwzx, -cb1[4].xyzx
    r0.xyz = value_24.xyz;
    uint4 value_25 = asuint(asfloat(r1.wwww) * asfloat(cb3[18].xyzw)); // mul r2.xyzw, r1.wwww, cb3[18].xyzw
    r2.xyzw = value_25.xyzw;
    uint4 value_26 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r1.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[17].xyzw, r1.xxxx, r2.xyzw
    r2.xyzw = value_26.xyzw;
    uint4 value_27 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r1.zzzz), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[19].xyzw, r1.zzzz, r2.xyzw
    r2.xyzw = value_27.xyzw;
    uint4 value_28 = asuint(asfloat(r2.xyzw) + asfloat(cb3[20].xyzw)); // add o2.xyzw, r2.xyzw, cb3[20].xyzw
    out_o2.xyzw = value_28.xyzw;
    uint4 value_29 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(r0.xyzx).xyz)).xxxx; // dp3 r0.x, r0.xyzx, r0.xyzx
    r0.x = value_29.x;
    uint4 value_30 = asuint(rsqrt(asfloat(r0.xxxx))); // rsq r0.x, r0.x
    r0.x = value_30.x;
    uint4 value_31 = asuint(asfloat(r0.xxxx) * asfloat(r0.yyyy)); // mul r0.x, r0.x, r0.y
    r0.x = value_31.x;
    uint4 value_32 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x0u, 0x0u))); // mul o1.xy, r0.xxxx, l(0.500000, 0.500000, 0.000000, 0.000000)
    out_o1.xy = value_32.xy;
    uint4 value_33 = asuint(asfloat(r1.yyyy) * asfloat(cb0[31].xyzx)); // mul r0.xyz, r1.yyyy, cb0[31].xyzx
    r0.xyz = value_33.xyz;
    uint4 value_34 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r1.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb0[30].xyzx, r1.xxxx, r0.xyzx
    r0.xyz = value_34.xyz;
    uint4 value_35 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r1.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb0[32].xyzx, r1.zzzz, r0.xyzx
    r0.xyz = value_35.xyz;
    uint4 value_36 = asuint(asfloat(r0.xyzx) + asfloat(cb0[33].xyzx)); // add r0.xyz, r0.xyzx, cb0[33].xyzx
    r0.xyz = value_36.xyz;
    uint4 value_37 = asuint(asfloat(r0.xyxx) * asfloat(cb0[39].zwzz)); // mul r0.xy, r0.xyxx, cb0[39].zwzz
    r0.xy = value_37.xy;
    uint4 value_38 = asuint(frac(asfloat(r0.xyxx))); // frc r2.xy, r0.xyxx
    r2.xy = value_38.xy;
    uint4 value_39 = asuint(asfloat(asuint(-asfloat(r2.xxxy))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r2.zw, -r2.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    r2.zw = value_39.zw;
    uint4 value_40 = asuint(asfloat(asuint(-asfloat(cb0[4].yyyy))) * asfloat(cb0[38].yyyy)); // mul r0.w, -cb0[4].y, cb0[38].y
    r0.w = value_40.w;
    uint4 value_41 = asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r0.zzzz))); // mad r0.z, -r0.w, l(0.050000), r0.z
    r0.z = value_41.z;
    uint4 value_42 = asuint(asfloat(r0.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r0.z, r0.z, l(-0.003922)
    r0.z = value_42.z;
    uint4 value_43 = asuint(asfloat(r0.xxxy) * asfloat(cb0[39].xxxy)); // mul r3.zw, r0.xxxy, cb0[39].xxxy
    r3.zw = value_43.zw;
    uint4 value_44 = asuint(mad(asfloat(r0.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r3.xy, r0.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r3.xy = value_44.xy;
    uint4 value_45 = asuint(t1.SampleLevel(s1, asfloat(r3.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.zyzz, t1.xyzw, s1, l(0.000000)
    r4.xyzw = value_45.xyzw;
    uint4 value_46 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r4.xyxz)))); // add r0.xyw, r0.zzzz, -r4.xyxz
    r0.xyw = value_46.xyw;
    uint4 value_47 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r1.w, cb0[38].x, l(20.000000)
    r1.w = value_47.w;
    uint4 value_48 = asuint(saturate(asfloat(asuint(asfloat(r0.xyxw) * asfloat(r1.wwww))))); // mul_sat r0.xyw, r0.xyxw, r1.wwww
    r0.xyw = value_48.xyw;
    uint4 value_49 = asuint(asfloat(r2.zzzz) * asfloat(r0.xyxw)); // mul r0.xyw, r2.zzzz, r0.xyxw
    r0.xyw = value_49.xyw;
    uint4 value_50 = asuint(asfloat(r2.yyyy) * asfloat(r0.xyxw)); // mul r0.xyw, r2.yyyy, r0.xyxw
    r0.xyw = value_50.xyw;
    uint4 value_51 = asuint(t1.SampleLevel(s1, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.zwzz, t1.xyzw, s1, l(0.000000)
    r4.xyzw = value_51.xyzw;
    uint4 value_52 = asuint(t1.SampleLevel(s1, asfloat(r3.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.xwxx, t1.xyzw, s1, l(0.000000)
    r5.xyzw = value_52.xyzw;
    uint4 value_53 = asuint(t1.SampleLevel(s1, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.xyxx, t1.xyzw, s1, l(0.000000)
    r3.xyzw = value_53.xyzw;
    uint4 value_54 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r3.xyz, r0.zzzz, -r3.xyzx
    r3.xyz = value_54.xyz;
    uint4 value_55 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(r3.xyzx))))); // mul_sat r3.xyz, r1.wwww, r3.xyzx
    r3.xyz = value_55.xyz;
    uint4 value_56 = asuint(asfloat(r2.xxxx) * asfloat(r3.xyzx)); // mul r3.xyz, r2.xxxx, r3.xyzx
    r3.xyz = value_56.xyz;
    uint4 value_57 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r0.zzzz, -r5.xyzx
    r5.xyz = value_57.xyz;
    uint4 value_58 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r0.zzzz, -r4.xyzx
    r4.xyz = value_58.xyz;
    uint4 value_59 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r1.wwww, r4.xyzx
    r4.xyz = value_59.xyz;
    uint4 value_60 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r1.wwww, r5.xyzx
    r5.xyz = value_60.xyz;
    uint4 value_61 = asuint(asfloat(r2.xxxx) * asfloat(r5.xyzx)); // mul r5.xyz, r2.xxxx, r5.xyzx
    r5.xyz = value_61.xyz;
    uint4 value_62 = asuint(asfloat(r2.zzzz) * asfloat(r4.xyzx)); // mul r4.xyz, r2.zzzz, r4.xyzx
    r4.xyz = value_62.xyz;
    uint4 value_63 = asuint(mad(asfloat(r4.xyzx), asfloat(r2.wwww), asfloat(r0.xywx))); // mad r0.xyz, r4.xyzx, r2.wwww, r0.xywx
    r0.xyz = value_63.xyz;
    uint4 value_64 = asuint(mad(asfloat(r5.xyzx), asfloat(r2.wwww), asfloat(r0.xyzx))); // mad r0.xyz, r5.xyzx, r2.wwww, r0.xyzx
    r0.xyz = value_64.xyz;
    uint4 value_65 = asuint(mad(asfloat(r3.xyzx), asfloat(r2.yyyy), asfloat(r0.xyzx))); // mad r0.xyz, r3.xyzx, r2.yyyy, r0.xyzx
    r0.xyz = value_65.xyz;
    uint4 value_66 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r0.x, r0.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r0.x = value_66.x;
    uint4 value_67 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_67.x;
    uint4 value_68 = asuint(saturate(asfloat(asuint(-asfloat(cb0[4].yyyy))))); // mov_sat r0.y, -cb0[4].y
    r0.y = value_68.y;
    uint4 value_69 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -r0.y, l(1.000000)
    r0.y = value_69.y;
    uint4 value_70 = asuint(asfloat(r0.yyyy) * asfloat(r0.yyyy)); // mul r0.z, r0.y, r0.y
    r0.z = value_70.z;
    uint4 value_71 = asuint(mad(asfloat(asuint(-asfloat(r0.yyyy))), asfloat(r0.zzzz), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.y, -r0.y, r0.z, l(1.000000)
    r0.y = value_71.y;
    uint4 value_72 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.x, r0.y, r0.x
    r0.x = value_72.x;
    uint4 value_73 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].wwww)); // mul r0.x, r0.x, cb0[5].w
    r0.x = value_73.x;
    uint4 value_74 = asuint(asfloat(cb0[6].xxyz) * asfloat(uint4(0x0u, 0x3fe66666u, 0x3fe66666u, 0x3fe66666u))); // mul r0.yzw, cb0[6].xxyz, l(0.000000, 1.800000, 1.800000, 1.800000)
    r0.yzw = value_74.yzw;
    uint4 value_75 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r0.yzwy))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r0.yzwy
    r2.xyz = value_75.xyz;
    uint4 value_76 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xxyz), asfloat(r0.yyzw))); // mad r0.yzw, r0.xxxx, r2.xxyz, r0.yyzw
    r0.yzw = value_76.yzw;
    uint4 value_77 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.xxxx, cb0[5].xyzx
    r2.xyz = value_77.xyz;
    uint4 value_78 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_78.xyz;
    uint4 value_79 = asuint(asfloat(r1.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r3.xy, r1.xzxx, -cb0[3].xyxx
    r3.xy = value_79.xy;
    uint4 value_80 = asuint(asfloat(r3.xyxx) * asfloat(cb0[2].zzzz)); // mul r3.xy, r3.xyxx, cb0[2].zzzz
    r3.xy = value_80.xy;
    uint4 value_81 = asuint(max(asfloat(r3.xxxy), asfloat(cb0[7].xxxy))); // max r3.zw, r3.xxxy, cb0[7].xxxy
    r3.zw = value_81.zw;
    uint4 value_82 = asuint(t0.SampleLevel(s0, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.xyxx, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_82.xyzw;
    uint4 value_83 = r4.xxxx; // mov o3.w, r4.x
    out_o3.w = value_83.w;
    uint4 value_84 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r3.xy, cb0[2].xyxx, -cb0[7].xyxx
    r3.xy = value_84.xy;
    uint4 value_85 = asuint(min(asfloat(r3.xyxx), asfloat(r3.zwzz))); // min r3.xy, r3.xyxx, r3.zwzz
    r3.xy = value_85.xy;
    uint4 value_86 = asuint(asfloat(r1.yyyy) + asfloat(uint4(0x3f8ccccdu, 0x3fd9999au, 0x3dccccceu, 0x3f333333u))); // add r4.xyzw, r1.yyyy, l(1.100000, 1.700000, 0.100000, 0.700000)
    r4.xyzw = value_86.xyzw;
    uint4 value_87 = asuint(asfloat(r1.xyzx) + asfloat(asuint(-asfloat(cb1[4].xyzx)))); // add r1.xyz, r1.xyzx, -cb1[4].xyzx
    r1.xyz = value_87.xyz;
    uint4 value_88 = asuint(max(asfloat(r4.zzzw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r3.zw, r4.zzzw, l(0.000000, 0.000000, 0.000000, 0.000000)
    r3.zw = value_88.zw;
    uint4 value_89 = asuint(saturate(asfloat(r4.xyxx))); // mov_sat r4.xy, r4.xyxx
    r4.xy = value_89.xy;
    uint4 value_90 = asuint(floor(asfloat(r3.zzzw))); // round_ni r4.zw, r3.zzzw
    r4.zw = value_90.zw;
    uint4 value_91 = asuint(frac(asfloat(r3.zzzw))); // frc r3.zw, r3.zzzw
    r3.zw = value_91.zw;
    uint4 value_92 = asuint(int4(asfloat(r4.zwzz))); // ftoi r5.xy, r4.zwzz
    r5.xy = value_92.xy;
    uint4 value_93 = (r5.xxxy + uint4(0x0u, 0x0u, 0x1u, 0x1u)); // iadd r5.zw, r5.xxxy, l(0, 0, 1, 1)
    r5.zw = value_93.zw;
    uint4 value_94 = asuint(float4(asint(r5.zwzz))); // itof r6.xy, r5.zwzz
    r6.xy = value_94.xy;
    uint4 value_95 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r1.w, cb0[2].w
    r1.w = value_95.w;
    uint4 value_96 = uint4(asfloat(r1.wwww)); // ftou r1.w, r1.w
    r1.w = value_96.w;
    uint4 value_97 = asuint(float4(r1.wwww)); // utof r2.w, r1.w
    r2.w = value_97.w;
    uint4 value_98 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r2.wwww)); // div r2.w, l(1.000000, 1.000000, 1.000000, 1.000000), r2.w
    r2.w = value_98.w;
    uint4 value_99 = asuint(asfloat(r2.wwww) * asfloat(r6.xyxx)); // mul r6.xy, r2.wwww, r6.xyxx
    r6.xy = value_99.xy;
    uint4 value_100 = asuint(asfloat(r2.wwww) * asfloat(r4.zzzw)); // mul r4.zw, r2.wwww, r4.zzzw
    r4.zw = value_100.zw;
    uint4 value_101 = asuint(int4(asfloat(r6.xxxy))); // ftoi r6.zw, r6.xxxy
    r6.zw = value_101.zw;
    uint4 value_102 = asuint(trunc(asfloat(r6.xyxx))); // round_z r6.xy, r6.xyxx
    r6.xy = value_102.xy;
    uint4 value_103 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r6.xxxy), asfloat(r3.yyyy))); // mad r7.zw, cb0[2].yyyy, r6.xxxy, r3.yyyy
    r7.zw = value_103.zw;
    uint4 value_104 = (asuint(-asint(r6.zzzw)) * r1.wwww + r5.zzzw); // imad r5.zw, -r6.zzzw, r1.wwww, r5.zzzw
    r5.zw = value_104.zw;
    uint4 value_105 = asuint(float4(r5.zzzw)); // utof r5.zw, r5.zzzw
    r5.zw = value_105.zw;
    uint4 value_106 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r5.zwzz), asfloat(r3.xxxx))); // mad r7.xy, cb0[2].xxxx, r5.zwzz, r3.xxxx
    r7.xy = value_106.xy;
    uint4 value_107 = asuint(t0.SampleLevel(s0, asfloat(r7.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r7.xzxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_107.xyzw;
    uint4 value_108 = asuint(t0.SampleLevel(s0, asfloat(r7.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r7.ywyy, t0.xyzw, s0, l(0.000000)
    r8.xyzw = value_108.xyzw;
    uint4 value_109 = ((asfloat(r7.zzzw) >= asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r5.zw, r7.zzzw, l(0.000000, 0.000000, 1.000000, 1.000000)
    r5.zw = value_109.zw;
    uint4 value_110 = (r5.zzzw & uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u)); // and r5.zw, r5.zzzw, l(0, 0, 0x3f800000, 0x3f800000)
    r5.zw = value_110.zw;
    uint4 value_111 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r7.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r7.xyz = value_111.xyz;
    uint4 value_112 = asuint(mad(asfloat(r5.zzzz), asfloat(r7.xyzx), asfloat(r6.xyzx))); // mad r6.xyz, r5.zzzz, r7.xyzx, r6.xyzx
    r6.xyz = value_112.xyz;
    uint4 value_113 = asuint(int4(asfloat(r4.zwzz))); // ftoi r7.xy, r4.zwzz
    r7.xy = value_113.xy;
    uint4 value_114 = asuint(trunc(asfloat(r4.zzzw))); // round_z r4.zw, r4.zzzw
    r4.zw = value_114.zw;
    uint4 value_115 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r4.zzzw), asfloat(r3.yyyy))); // mad r9.zw, cb0[2].yyyy, r4.zzzw, r3.yyyy
    r9.zw = value_115.zw;
    uint4 value_116 = (asuint(-asint(r7.xxxy)) * r1.wwww + r5.xxxy); // imad r4.zw, -r7.xxxy, r1.wwww, r5.xxxy
    r4.zw = value_116.zw;
    uint4 value_117 = asuint(float4(r4.zzzw)); // utof r4.zw, r4.zzzw
    r4.zw = value_117.zw;
    uint4 value_118 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r4.zwzz), asfloat(r3.xxxx))); // mad r9.xy, cb0[2].xxxx, r4.zwzz, r3.xxxx
    r9.xy = value_118.xy;
    uint4 value_119 = asuint(t0.SampleLevel(s0, asfloat(r9.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r9.xzxx, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_119.xyzw;
    uint4 value_120 = asuint(t0.SampleLevel(s0, asfloat(r9.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r10.xyzw, r9.ywyy, t0.xyzw, s0, l(0.000000)
    r10.xyzw = value_120.xyzw;
    uint4 value_121 = ((asfloat(r9.zwzz) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.xy, r9.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
    r3.xy = value_121.xy;
    uint4 value_122 = (r3.xyxx & uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u)); // and r3.xy, r3.xyxx, l(0x3f800000, 0x3f800000, 0, 0)
    r3.xy = value_122.xy;
    uint4 value_123 = asuint(asfloat(asuint(-asfloat(r7.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r7.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_123.xyz;
    uint4 value_124 = asuint(mad(asfloat(r3.xxxx), asfloat(r5.xyzx), asfloat(r7.xyzx))); // mad r5.xyz, r3.xxxx, r5.xyzx, r7.xyzx
    r5.xyz = value_124.xyz;
    uint4 value_125 = asuint(asfloat(asuint(-asfloat(r5.xyzx))) + asfloat(r6.xyzx)); // add r6.xyz, -r5.xyzx, r6.xyzx
    r6.xyz = value_125.xyz;
    uint4 value_126 = asuint(mad(asfloat(r3.zzzz), asfloat(r6.xyzx), asfloat(r5.xyzx))); // mad r5.xyz, r3.zzzz, r6.xyzx, r5.xyzx
    r5.xyz = value_126.xyz;
    uint4 value_127 = asuint(asfloat(r5.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r5.xyz, r5.xyzx, -cb0[9].xyzx
    r5.xyz = value_127.xyz;
    uint4 value_128 = asuint(mad(asfloat(r4.xxxx), asfloat(r5.xxyz), asfloat(cb0[9].xxyz))); // mad r4.xzw, r4.xxxx, r5.xxyz, cb0[9].xxyz
    r4.xzw = value_128.xzw;
    uint4 value_129 = asuint(asfloat(asuint(-asfloat(r8.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r8.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_129.xyz;
    uint4 value_130 = asuint(mad(asfloat(r5.wwww), asfloat(r5.xyzx), asfloat(r8.xyzx))); // mad r5.xyz, r5.wwww, r5.xyzx, r8.xyzx
    r5.xyz = value_130.xyz;
    uint4 value_131 = asuint(asfloat(asuint(-asfloat(r10.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r6.xyz, -r10.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r6.xyz = value_131.xyz;
    uint4 value_132 = asuint(mad(asfloat(r3.yyyy), asfloat(r6.xyzx), asfloat(r10.xyzx))); // mad r3.xyz, r3.yyyy, r6.xyzx, r10.xyzx
    r3.xyz = value_132.xyz;
    uint4 value_133 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(r5.xyzx)); // add r5.xyz, -r3.xyzx, r5.xyzx
    r5.xyz = value_133.xyz;
    uint4 value_134 = asuint(mad(asfloat(r3.wwww), asfloat(r5.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r3.wwww, r5.xyzx, r3.xyzx
    r3.xyz = value_134.xyz;
    uint4 value_135 = asuint(asfloat(r3.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r3.xyz, r3.xyzx, -cb0[9].xyzx
    r3.xyz = value_135.xyz;
    uint4 value_136 = asuint(mad(asfloat(r4.yyyy), asfloat(r3.xyzx), asfloat(cb0[9].xyzx))); // mad r3.xyz, r4.yyyy, r3.xyzx, cb0[9].xyzx
    r3.xyz = value_136.xyz;
    uint4 value_137 = asuint(asfloat(r3.xyzx) * asfloat(r4.xzwx)); // mul r5.xyz, r3.xyzx, r4.xzwx
    r5.xyz = value_137.xyz;
    uint4 value_138 = asuint(dot(asfloat(r5.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r5.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_138.w;
    uint4 value_139 = asuint(mad(asfloat(r4.xzwx), asfloat(r3.xyzx), asfloat(asuint(-asfloat(r1.wwww))))); // mad r3.xyz, r4.xzwx, r3.xyzx, -r1.wwww
    r3.xyz = value_139.xyz;
    uint4 value_140 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r2.w, cb0[5].w, cb0[6].w
    r2.w = value_140.w;
    uint4 value_141 = asuint(saturate(asfloat(asuint(asfloat(r2.wwww) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r2.w, r2.w, l(0.500000)
    r2.w = value_141.w;
    uint4 value_142 = asuint(asfloat(r2.wwww) * asfloat(cb0[29].xxxx)); // mul r2.w, r2.w, cb0[29].x
    r2.w = value_142.w;
    uint4 value_143 = asuint(mad(asfloat(r2.wwww), asfloat(r3.xyzx), asfloat(r1.wwww))); // mad r3.xyz, r2.wwww, r3.xyzx, r1.wwww
    r3.xyz = value_143.xyz;
    uint4 value_144 = asuint(mad(asfloat(r3.xxyz), asfloat(r0.yyzw), asfloat(r2.xxyz))); // mad r0.yzw, r3.xxyz, r0.yyzw, r2.xxyz
    r0.yzw = value_144.yzw;
    uint4 value_145 = asuint(asfloat(r0.yyzw) + asfloat(uint4(0x0u, 0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu))); // add r0.yzw, r0.yyzw, l(0.000000, 0.100000, 0.100000, 0.100000)
    r0.yzw = value_145.yzw;
    uint4 value_146 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r1.w, cb0[5].w, -cb0[6].w
    r1.w = value_146.w;
    uint4 value_147 = asuint(mad(asfloat(r0.xxxx), asfloat(r1.wwww), asfloat(cb0[6].wwww))); // mad r0.x, r0.x, r1.w, cb0[6].w
    r0.x = value_147.x;
    uint4 value_148 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x3e99999au)), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x3f333333u)))); // mad r1.w, cb0[29].x, l(0.300000), l(0.700000)
    r1.w = value_148.w;
    uint4 value_149 = asuint(asfloat(r1.wwww) * asfloat(uint4(0x3f800000u, 0x32000000u, 0x0u, 0x0u))); // mul r2.xy, r1.wwww, l(1.000000, 0.000000, 0.000000, 0.000000)
    r2.xy = value_149.xy;
    uint4 value_150 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.yyyy), asfloat(r2.xxxx))); // mad r0.x, r0.x, r2.y, r2.x
    r0.x = value_150.x;
    uint4 value_151 = asuint(asfloat(r0.yzwy) * asfloat(r0.xxxx)); // mul r0.xyz, r0.yzwy, r0.xxxx
    r0.xyz = value_151.xyz;
    uint4 value_152 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_152.w;
    uint4 value_153 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r2.x, -r0.w, l(0.600000)
    r2.x = value_153.x;
    uint4 value_154 = asuint(asfloat(r0.wwww) + asfloat(asuint(-asfloat(r2.xxxx)))); // add r0.w, r0.w, -r2.x
    r0.w = value_154.w;
    uint4 value_155 = asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r0.wwww, l(0.100000, 0.100000, 0.100000, 0.000000), r0.xyzx
    r0.xyz = value_155.xyz;
    uint4 value_156 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r0.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_156.xyz;
    uint4 value_157 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r0.xyzx
    r0.xyz = value_157.xyz;
    uint4 value_158 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r0.xyzx)); // add r0.xyz, -r1.wwww, r0.xyzx
    r0.xyz = value_158.xyz;
    uint4 value_159 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.xyzx), asfloat(r1.wwww))); // mad o3.xyz, cb0[29].yyyy, r0.xyzx, r1.wwww
    out_o3.xyz = value_159.xyz;
    uint4 value_160 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.x, r1.xyzx, r1.xyzx
    r0.x = value_160.x;
    uint4 value_161 = asuint(rsqrt(asfloat(r0.xxxx))); // rsq r0.x, r0.x
    r0.x = value_161.x;
    uint4 value_162 = asuint(asfloat(r0.xxxx) * asfloat(r1.yyyy)); // mul r0.x, r0.x, r1.y
    r0.x = value_162.x;
    uint4 value_163 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.x, r0.x, l(0.500000)
    r0.x = value_163.x;
    uint4 value_164 = asuint(asfloat(asuint(-asfloat(cb0[8].xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.yzw, -cb0[8].xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r0.yzw = value_164.yzw;
    uint4 value_165 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yzwy), asfloat(cb0[8].xyzx))); // mad r0.xyz, r0.xxxx, r0.yzwy, cb0[8].xyzx
    r0.xyz = value_165.xyz;
    uint4 value_166 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0xbf000000u, 0xbf266666u, 0xbf333333u, 0x0u))); // add r0.xyz, r0.xyzx, l(-0.500000, -0.650000, -0.700000, 0.000000)
    r0.xyz = value_166.xyz;
    uint4 value_167 = asuint(asfloat(cb0[8].wwww) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.w, cb0[8].w, l(-1.000000)
    r0.w = value_167.w;
    uint4 value_168 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.xyzw), asfloat(uint4(0x3f000000u, 0x3f266666u, 0x3f333333u, 0x3f800000u)))); // mad o4.xyzw, cb0[29].yyyy, r0.xyzw, l(0.500000, 0.650000, 0.700000, 1.000000)
    out_o4.xyzw = value_168.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xy);
    result.o2_0 = asfloat(out_o2.xyzw);
    result.o3_0 = asfloat(out_o3.xyzw);
    result.o4_0 = asfloat(out_o4.xyzw);
    return result;
}
