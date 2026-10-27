// Register-explicit recovered HLSL. Not original source.
// Placemaker/ColorPick vs_4_0 variant []
// Source SHA256 6ea9b029201cbdf92ec06f5bc343db036795f6ecf40209f2628218fd2d7bfc6d
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
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s1 = _VoxelTex
// t1 / s0 = _AoTex
// t2 / s2 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
cbuffer Buffer1:register(b1) { uint4 cb1[5]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[21]; };
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
    float4 v3_0: COLOR0;
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
    uint4 value_1 = asuint(frac(asfloat(v1.xyxx))); // frc o0.xy, v1.xyxx
    out_o0.xy = value_1.xy;
    uint4 value_2 = asuint(asfloat(v3.xxxx) * asfloat(cb0[15].zzzz)); // mul o0.z, v3.x, cb0[15].z
    out_o0.z = value_2.z;
    uint4 value_3 = v3.wwww; // mov o0.w, v3.w
    out_o0.w = value_3.w;
    uint4 value_4 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzx)); // mul r0.xyz, v0.yyyy, cb2[1].xyzx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb2[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_5.xyz;
    uint4 value_6 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb2[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_6.xyz;
    uint4 value_7 = asuint(mad(asfloat(cb2[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb2[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_7.xyz;
    uint4 value_8 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb1[4].xyzx)))); // add r1.xyz, r0.xyzx, -cb1[4].xyzx
    r1.xyz = value_8.xyz;
    uint4 value_9 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.w, r1.xyzx, r1.xyzx
    r0.w = value_9.w;
    uint4 value_10 = asuint(rsqrt(asfloat(r0.wwww))); // rsq r0.w, r0.w
    r0.w = value_10.w;
    uint4 value_11 = asuint(asfloat(r0.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_11.xyz;
    uint4 value_12 = asuint(mad(asfloat(asuint(-asfloat(r1.xyzx))), asfloat(uint4(0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, -r1.xyzx, l(0.200000, 0.200000, 0.200000, 0.000000), r0.xyzx
    r0.xyz = value_12.xyz;
    uint4 value_13 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_13.xyz;
    uint4 value_14 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.w, r1.xyzx, r1.xyzx
    r0.w = value_14.w;
    uint4 value_15 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_15.w;
    uint4 value_16 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_16.w;
    uint4 value_17 = asuint(asfloat(r0.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_17.xyz;
    uint4 value_18 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r0.w, r1.y, cb0[22].w, r0.y
    r0.w = value_18.w;
    uint4 value_19 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_19.w;
    uint4 value_20 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r0.w
    r2.w = value_20.w;
    uint4 value_21 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_21.xz;
    uint4 value_22 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r1.xyz, r0.xyzx, r2.xwzx
    r1.xyz = value_22.xyz;
    uint4 value_23 = asuint(asfloat(r1.yyyy) * asfloat(cb3[18].xyzw)); // mul r2.xyzw, r1.yyyy, cb3[18].xyzw
    r2.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r1.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[17].xyzw, r1.xxxx, r2.xyzw
    r2.xyzw = value_24.xyzw;
    uint4 value_25 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r1.zzzz), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[19].xyzw, r1.zzzz, r2.xyzw
    r2.xyzw = value_25.xyzw;
    uint4 value_26 = asuint(asfloat(r2.xyzw) + asfloat(cb3[20].xyzw)); // add o1.xyzw, r2.xyzw, cb3[20].xyzw
    out_o1.xyzw = value_26.xyzw;
    uint4 value_27 = asuint(asfloat(r0.xzxz) + asfloat(asuint(-asfloat(cb0[3].xyxy)))); // add r2.xyzw, r0.xzxz, -cb0[3].xyxy
    r2.xyzw = value_27.xyzw;
    uint4 value_28 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.x, r0.y, l(-0.500000)
    r0.x = value_28.x;
    uint4 value_29 = asuint(max(asfloat(r0.xxxx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.x, r0.x, l(0.000000)
    r0.x = value_29.x;
    uint4 value_30 = asuint(asfloat(r2.xyzw) + asfloat(uint4(0x3ca3d70au, 0x0u, 0x0u, 0x3ca3d70au))); // add r3.xyzw, r2.xyzw, l(0.020000, 0.000000, 0.000000, 0.020000)
    r3.xyzw = value_30.xyzw;
    uint4 value_31 = asuint(asfloat(r2.zzwz) * asfloat(cb0[2].zzzz)); // mul r0.yz, r2.zzwz, cb0[2].zzzz
    r0.yz = value_31.yz;
    uint4 value_32 = asuint(max(asfloat(r0.yyzy), asfloat(cb0[7].xxyx))); // max r0.yz, r0.yyzy, cb0[7].xxyx
    r0.yz = value_32.yz;
    uint4 value_33 = asuint(asfloat(r3.xyzw) * asfloat(cb0[2].zzzz)); // mul r2.xyzw, r3.xyzw, cb0[2].zzzz
    r2.xyzw = value_33.xyzw;
    uint4 value_34 = asuint(max(asfloat(r2.xyzw), asfloat(cb0[7].xyxy))); // max r2.xyzw, r2.xyzw, cb0[7].xyxy
    r2.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r3.xy, cb0[2].xyxx, -cb0[7].xyxx
    r3.xy = value_35.xy;
    uint4 value_36 = asuint(min(asfloat(r2.xyzw), asfloat(r3.xyxy))); // min r2.xyzw, r2.xyzw, r3.xyxy
    r2.xyzw = value_36.xyzw;
    uint4 value_37 = asuint(floor(asfloat(r0.xxxx))); // round_ni r0.w, r0.x
    r0.w = value_37.w;
    uint4 value_38 = asuint(frac(asfloat(r0.xxxx))); // frc r0.x, r0.x
    r0.x = value_38.x;
    uint4 value_39 = asuint(int4(asfloat(r0.wwww))); // ftoi r1.w, r0.w
    r1.w = value_39.w;
    uint4 value_40 = (r1.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.z, r1.w, l(1)
    r3.z = value_40.z;
    uint4 value_41 = asuint(float4(asint(r3.zzzz))); // itof r3.w, r3.z
    r3.w = value_41.w;
    uint4 value_42 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r4.x, cb0[2].w
    r4.x = value_42.x;
    uint4 value_43 = uint4(asfloat(r4.xxxx)); // ftou r4.x, r4.x
    r4.x = value_43.x;
    uint4 value_44 = asuint(float4(r4.xxxx)); // utof r4.y, r4.x
    r4.y = value_44.y;
    uint4 value_45 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r4.yyyy)); // div r4.y, l(1.000000, 1.000000, 1.000000, 1.000000), r4.y
    r4.y = value_45.y;
    uint4 value_46 = asuint(asfloat(r3.wwww) * asfloat(r4.yyyy)); // mul r3.w, r3.w, r4.y
    r3.w = value_46.w;
    uint4 value_47 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.z, r3.w
    r4.z = value_47.z;
    uint4 value_48 = asuint(trunc(asfloat(r3.wwww))); // round_z r5.yw, r3.wwww
    r5.yw = value_48.yw;
    uint4 value_49 = (asuint(-asint(r4.zzzz)) * r4.xxxx + r3.zzzz); // imad r3.z, -r4.z, r4.x, r3.z
    r3.z = value_49.z;
    uint4 value_50 = asuint(float4(r3.zzzz)); // utof r5.xz, r3.zzzz
    r5.xz = value_50.xz;
    uint4 value_51 = asuint(mad(asfloat(r5.xyzw), asfloat(cb0[2].xyxy), asfloat(r2.xyzw))); // mad r6.xyzw, r5.xyzw, cb0[2].xyxy, r2.xyzw
    r6.xyzw = value_51.xyzw;
    uint4 value_52 = asuint(t0.SampleLevel(s1, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r6.xyxx, t0.xyzw, s1, l(0.000000)
    r7.xyzw = value_52.xyzw;
    uint4 value_53 = asuint(t0.SampleLevel(s1, asfloat(r6.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r6.zwzz, t0.xyzw, s1, l(0.000000)
    r6.xyzw = value_53.xyzw;
    uint4 value_54 = asuint(min(asfloat(r0.yyzy), asfloat(r3.xxyx))); // min r0.yz, r0.yyzy, r3.xxyx
    r0.yz = value_54.yz;
    uint4 value_55 = asuint(mad(asfloat(r5.xxxy), asfloat(cb0[2].xxxy), asfloat(r0.yyyz))); // mad r3.zw, r5.xxxy, cb0[2].xxxy, r0.yyyz
    r3.zw = value_55.zw;
    uint4 value_56 = asuint(t0.SampleLevel(s1, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t0.xyzw, s1, l(0.000000)
    r5.xyzw = value_56.xyzw;
    uint4 value_57 = asuint(asfloat(asuint(-asfloat(r5.wwww))) + asfloat(r7.wwww)); // add r3.z, -r5.w, r7.w
    r3.z = value_57.z;
    uint4 value_58 = asuint(asfloat(r3.zzzz) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r5.x, r3.z, l(50.000000)
    r5.x = value_58.x;
    uint4 value_59 = asuint(asfloat(asuint(-asfloat(r5.wwww))) + asfloat(r6.wwww)); // add r3.z, -r5.w, r6.w
    r3.z = value_59.z;
    uint4 value_60 = asuint(asfloat(r3.zzzz) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r5.z, r3.z, l(50.000000)
    r5.z = value_60.z;
    uint4 value_61 = asuint(asfloat(r0.wwww) * asfloat(r4.yyyy)); // mul r0.w, r0.w, r4.y
    r0.w = value_61.w;
    uint4 value_62 = asuint(int4(asfloat(r0.wwww))); // ftoi r3.z, r0.w
    r3.z = value_62.z;
    uint4 value_63 = asuint(trunc(asfloat(r0.wwww))); // round_z r6.yw, r0.wwww
    r6.yw = value_63.yw;
    uint4 value_64 = (asuint(-asint(r3.zzzz)) * r4.xxxx + r1.wwww); // imad r0.w, -r3.z, r4.x, r1.w
    r0.w = value_64.w;
    uint4 value_65 = asuint(float4(r0.wwww)); // utof r6.xz, r0.wwww
    r6.xz = value_65.xz;
    uint4 value_66 = asuint(mad(asfloat(r6.xyzw), asfloat(cb0[2].xyxy), asfloat(r2.xyzw))); // mad r2.xyzw, r6.xyzw, cb0[2].xyxy, r2.xyzw
    r2.xyzw = value_66.xyzw;
    uint4 value_67 = asuint(mad(asfloat(r6.zzwz), asfloat(cb0[2].xxyx), asfloat(r0.yyzy))); // mad r0.yz, r6.zzwz, cb0[2].xxyx, r0.yyzy
    r0.yz = value_67.yz;
    uint4 value_68 = asuint(t0.SampleLevel(s1, asfloat(r0.yzyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r0.yzyy, t0.xyzw, s1, l(0.000000)
    r6.xyzw = value_68.xyzw;
    uint4 value_69 = asuint(t0.SampleLevel(s1, asfloat(r2.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r2.xyxx, t0.xyzw, s1, l(0.000000)
    r7.xyzw = value_69.xyzw;
    uint4 value_70 = asuint(t0.SampleLevel(s1, asfloat(r2.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r2.zwzz, t0.xyzw, s1, l(0.000000)
    r2.xyzw = value_70.xyzw;
    uint4 value_71 = asuint(asfloat(asuint(-asfloat(r6.wwww))) + asfloat(r2.wwww)); // add r0.y, -r6.w, r2.w
    r0.y = value_71.y;
    uint4 value_72 = asuint(asfloat(r0.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r2.z, r0.y, l(50.000000)
    r2.z = value_72.z;
    uint4 value_73 = asuint(asfloat(asuint(-asfloat(r6.wwww))) + asfloat(r7.wwww)); // add r0.y, -r6.w, r7.w
    r0.y = value_73.y;
    uint4 value_74 = asuint(asfloat(r5.wwww) + asfloat(asuint(-asfloat(r6.wwww)))); // add r0.z, r5.w, -r6.w
    r0.z = value_74.z;
    uint4 value_75 = asuint(asfloat(r0.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r2.x, r0.y, l(50.000000)
    r2.x = value_75.x;
    uint4 value_76 = asuint(asfloat(asuint(-asfloat(r2.xxxz))) + asfloat(r5.xxxz)); // add r0.yw, -r2.xxxz, r5.xxxz
    r0.yw = value_76.yw;
    uint4 value_77 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yywy), asfloat(r2.xxzx))); // mad r2.xz, r0.xxxx, r0.yywy, r2.xxzx
    r2.xz = value_77.xz;
    uint4 value_78 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -r0.x, l(1.000000)
    r0.y = value_78.y;
    uint4 value_79 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.x, r0.y, r0.x
    r0.x = value_79.x;
    uint4 value_80 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul r0.x, r0.x, l(4.000000)
    r0.x = value_80.x;
    uint4 value_81 = asuint(asfloat(r0.xxxx) * asfloat(r0.zzzz)); // mul r2.y, r0.x, r0.z
    r2.y = value_81.y;
    uint4 value_82 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r0.xyz, r2.xyzx, l(0.200000, 0.200000, 0.200000, 0.000000), r1.xyzx
    r0.xyz = value_82.xyz;
    uint4 value_83 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r0.yw, r0.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r0.yw = value_83.yw;
    uint4 value_84 = asuint(asfloat(r0.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r0.xz, r0.xxzx, -cb0[3].xxyx
    r0.xz = value_84.xz;
    uint4 value_85 = asuint(asfloat(r0.xxzx) * asfloat(cb0[2].zzzz)); // mul r0.xz, r0.xxzx, cb0[2].zzzz
    r0.xz = value_85.xz;
    uint4 value_86 = asuint(max(asfloat(r0.xxzx), asfloat(cb0[7].xxyx))); // max r0.xz, r0.xxzx, cb0[7].xxyx
    r0.xz = value_86.xz;
    uint4 value_87 = asuint(min(asfloat(r3.xxyx), asfloat(r0.xxzx))); // min r0.xz, r3.xxyx, r0.xxzx
    r0.xz = value_87.xz;
    uint4 value_88 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_88.w;
    uint4 value_89 = asuint(saturate(asfloat(r0.yyyy))); // mov_sat r0.y, r0.y
    r0.y = value_89.y;
    uint4 value_90 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.w, r0.w
    r1.w = value_90.w;
    uint4 value_91 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_91.w;
    uint4 value_92 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.w, r1.w
    r2.w = value_92.w;
    uint4 value_93 = asuint(asfloat(r4.yyyy) * asfloat(r1.wwww)); // mul r1.w, r4.y, r1.w
    r1.w = value_93.w;
    uint4 value_94 = (r2.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.z, r2.w, l(1)
    r3.z = value_94.z;
    uint4 value_95 = asuint(float4(asint(r3.zzzz))); // itof r3.w, r3.z
    r3.w = value_95.w;
    uint4 value_96 = asuint(asfloat(r4.yyyy) * asfloat(r3.wwww)); // mul r3.w, r4.y, r3.w
    r3.w = value_96.w;
    uint4 value_97 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.z, r3.w
    r4.z = value_97.z;
    uint4 value_98 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_98.w;
    uint4 value_99 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r0.zzzz))); // mad r5.y, cb0[2].y, r3.w, r0.z
    r5.y = value_99.y;
    uint4 value_100 = (asuint(-asint(r4.zzzz)) * r4.xxxx + r3.zzzz); // imad r3.z, -r4.z, r4.x, r3.z
    r3.z = value_100.z;
    uint4 value_101 = asuint(float4(r3.zzzz)); // utof r3.z, r3.z
    r3.z = value_101.z;
    uint4 value_102 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.zzzz), asfloat(r0.xxxx))); // mad r5.x, cb0[2].x, r3.z, r0.x
    r5.x = value_102.x;
    uint4 value_103 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r6.xyzw = value_103.xyzw;
    uint4 value_104 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.z, r5.y, l(1.000000)
    r3.z = value_104.z;
    uint4 value_105 = (r3.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.z, r3.z, l(0x3f800000)
    r3.z = value_105.z;
    uint4 value_106 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_106.xyz;
    uint4 value_107 = asuint(mad(asfloat(r3.zzzz), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r5.xyz, r3.zzzz, r5.xyzx, r6.xyzx
    r5.xyz = value_107.xyz;
    uint4 value_108 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.z, r1.w
    r3.z = value_108.z;
    uint4 value_109 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_109.w;
    uint4 value_110 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r0.zzzz))); // mad r6.y, cb0[2].y, r1.w, r0.z
    r6.y = value_110.y;
    uint4 value_111 = (asuint(-asint(r3.zzzz)) * r4.xxxx + r2.wwww); // imad r0.z, -r3.z, r4.x, r2.w
    r0.z = value_111.z;
    uint4 value_112 = asuint(float4(r0.zzzz)); // utof r0.z, r0.z
    r0.z = value_112.z;
    uint4 value_113 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.zzzz), asfloat(r0.xxxx))); // mad r6.x, cb0[2].x, r0.z, r0.x
    r6.x = value_113.x;
    uint4 value_114 = asuint(t1.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r6.xyxx, t1.xyzw, s0, l(0.000000)
    r7.xyzw = value_114.xyzw;
    uint4 value_115 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, r6.y, l(1.000000)
    r0.x = value_115.x;
    uint4 value_116 = (r0.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.x, r0.x, l(0x3f800000)
    r0.x = value_116.x;
    uint4 value_117 = asuint(asfloat(asuint(-asfloat(r7.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r6.xyz, -r7.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r6.xyz = value_117.xyz;
    uint4 value_118 = asuint(mad(asfloat(r0.xxxx), asfloat(r6.xyzx), asfloat(r7.xyzx))); // mad r6.xyz, r0.xxxx, r6.xyzx, r7.xyzx
    r6.xyz = value_118.xyz;
    uint4 value_119 = asuint(asfloat(r5.xyzx) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r5.xyz, r5.xyzx, -r6.xyzx
    r5.xyz = value_119.xyz;
    uint4 value_120 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xxyz), asfloat(r6.xxyz))); // mad r0.xzw, r0.wwww, r5.xxyz, r6.xxyz
    r0.xzw = value_120.xzw;
    uint4 value_121 = asuint(asfloat(r0.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r0.xzw, r0.xxzw, -cb0[9].xxyz
    r0.xzw = value_121.xzw;
    uint4 value_122 = asuint(mad(asfloat(r0.yyyy), asfloat(r0.xzwx), asfloat(cb0[9].xyzx))); // mad r0.xyz, r0.yyyy, r0.xzwx, cb0[9].xyzx
    r0.xyz = value_122.xyz;
    uint4 value_123 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(r1.xyzx))); // mad r5.xyz, r2.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), r1.xyzx
    r5.xyz = value_123.xyz;
    uint4 value_124 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000)
    r2.xyz = value_124.xyz;
    uint4 value_125 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.w, r2.xyzx, -cb0[4].xyzx
    r0.w = value_125.w;
    uint4 value_126 = asuint(asfloat(r5.yyyy) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r2.xy, r5.yyyy, l(0.700000, -0.300000, 0.000000, 0.000000)
    r2.xy = value_126.xy;
    uint4 value_127 = asuint(asfloat(r5.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r2.zw, r5.xxxz, -cb0[3].xxxy
    r2.zw = value_127.zw;
    uint4 value_128 = asuint(asfloat(r2.zzzw) * asfloat(cb0[2].zzzz)); // mul r2.zw, r2.zzzw, cb0[2].zzzz
    r2.zw = value_128.zw;
    uint4 value_129 = asuint(max(asfloat(r2.zzzw), asfloat(cb0[7].xxxy))); // max r2.zw, r2.zzzw, cb0[7].xxxy
    r2.zw = value_129.zw;
    uint4 value_130 = asuint(min(asfloat(r3.xxxy), asfloat(r2.zzzw))); // min r2.zw, r3.xxxy, r2.zzzw
    r2.zw = value_130.zw;
    uint4 value_131 = asuint(max(asfloat(r2.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r2.y, l(0.000000)
    r1.w = value_131.w;
    uint4 value_132 = asuint(saturate(asfloat(r2.xxxx))); // mov_sat r2.x, r2.x
    r2.x = value_132.x;
    uint4 value_133 = asuint(floor(asfloat(r1.wwww))); // round_ni r2.y, r1.w
    r2.y = value_133.y;
    uint4 value_134 = asuint(frac(asfloat(r1.wwww))); // frc r1.w, r1.w
    r1.w = value_134.w;
    uint4 value_135 = asuint(int4(asfloat(r2.yyyy))); // ftoi r3.x, r2.y
    r3.x = value_135.x;
    uint4 value_136 = asuint(asfloat(r4.yyyy) * asfloat(r2.yyyy)); // mul r2.y, r4.y, r2.y
    r2.y = value_136.y;
    uint4 value_137 = (r3.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.y, r3.x, l(1)
    r3.y = value_137.y;
    uint4 value_138 = asuint(float4(asint(r3.yyyy))); // itof r3.z, r3.y
    r3.z = value_138.z;
    uint4 value_139 = asuint(asfloat(r4.yyyy) * asfloat(r3.zzzz)); // mul r3.z, r4.y, r3.z
    r3.z = value_139.z;
    uint4 value_140 = asuint(int4(asfloat(r3.zzzz))); // ftoi r3.w, r3.z
    r3.w = value_140.w;
    uint4 value_141 = asuint(trunc(asfloat(r3.zzzz))); // round_z r3.z, r3.z
    r3.z = value_141.z;
    uint4 value_142 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.zzzz), asfloat(r2.wwww))); // mad r5.y, cb0[2].y, r3.z, r2.w
    r5.y = value_142.y;
    uint4 value_143 = (asuint(-asint(r3.wwww)) * r4.xxxx + r3.yyyy); // imad r3.y, -r3.w, r4.x, r3.y
    r3.y = value_143.y;
    uint4 value_144 = asuint(float4(r3.yyyy)); // utof r3.y, r3.y
    r3.y = value_144.y;
    uint4 value_145 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.yyyy), asfloat(r2.zzzz))); // mad r5.x, cb0[2].x, r3.y, r2.z
    r5.x = value_145.x;
    uint4 value_146 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r6.xyzw = value_146.xyzw;
    uint4 value_147 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.y, r5.y, l(1.000000)
    r3.y = value_147.y;
    uint4 value_148 = (r3.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.y, r3.y, l(0x3f800000)
    r3.y = value_148.y;
    uint4 value_149 = asuint(asfloat(asuint(-asfloat(r6.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r4.yzw, -r6.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r4.yzw = value_149.yzw;
    uint4 value_150 = asuint(mad(asfloat(r3.yyyy), asfloat(r4.yyzw), asfloat(r6.xxyz))); // mad r3.yzw, r3.yyyy, r4.yyzw, r6.xxyz
    r3.yzw = value_150.yzw;
    uint4 value_151 = asuint(int4(asfloat(r2.yyyy))); // ftoi r4.y, r2.y
    r4.y = value_151.y;
    uint4 value_152 = asuint(trunc(asfloat(r2.yyyy))); // round_z r2.y, r2.y
    r2.y = value_152.y;
    uint4 value_153 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.yyyy), asfloat(r2.wwww))); // mad r5.y, cb0[2].y, r2.y, r2.w
    r5.y = value_153.y;
    uint4 value_154 = (asuint(-asint(r4.yyyy)) * r4.xxxx + r3.xxxx); // imad r2.y, -r4.y, r4.x, r3.x
    r2.y = value_154.y;
    uint4 value_155 = asuint(float4(r2.yyyy)); // utof r2.y, r2.y
    r2.y = value_155.y;
    uint4 value_156 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.yyyy), asfloat(r2.zzzz))); // mad r5.x, cb0[2].x, r2.y, r2.z
    r5.x = value_156.x;
    uint4 value_157 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r4.xyzw = value_157.xyzw;
    uint4 value_158 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.y, r5.y, l(1.000000)
    r2.y = value_158.y;
    uint4 value_159 = (r2.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.y, r2.y, l(0x3f800000)
    r2.y = value_159.y;
    uint4 value_160 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r4.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_160.xyz;
    uint4 value_161 = asuint(mad(asfloat(r2.yyyy), asfloat(r5.xxyz), asfloat(r4.xxyz))); // mad r2.yzw, r2.yyyy, r5.xxyz, r4.xxyz
    r2.yzw = value_161.yzw;
    uint4 value_162 = asuint(asfloat(asuint(-asfloat(r2.yzwy))) + asfloat(r3.yzwy)); // add r3.xyz, -r2.yzwy, r3.yzwy
    r3.xyz = value_162.xyz;
    uint4 value_163 = asuint(mad(asfloat(r1.wwww), asfloat(r3.xxyz), asfloat(r2.yyzw))); // mad r2.yzw, r1.wwww, r3.xxyz, r2.yyzw
    r2.yzw = value_163.yzw;
    uint4 value_164 = asuint(asfloat(r2.yyzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r2.yzw, r2.yyzw, -cb0[9].xxyz
    r2.yzw = value_164.yzw;
    uint4 value_165 = asuint(mad(asfloat(r2.xxxx), asfloat(r2.yzwy), asfloat(cb0[9].xyzx))); // mad r2.xyz, r2.xxxx, r2.yzwy, cb0[9].xyzx
    r2.xyz = value_165.xyz;
    uint4 value_166 = asuint(asfloat(r0.xyzx) * asfloat(r2.xyzx)); // mul r3.xyz, r0.xyzx, r2.xyzx
    r3.xyz = value_166.xyz;
    uint4 value_167 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_167.w;
    uint4 value_168 = asuint(mad(asfloat(r0.xyzx), asfloat(r2.xyzx), asfloat(asuint(-asfloat(r1.wwww))))); // mad r0.xyz, r0.xyzx, r2.xyzx, -r1.wwww
    r0.xyz = value_168.xyz;
    uint4 value_169 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r2.x, cb0[5].w, cb0[6].w
    r2.x = value_169.x;
    uint4 value_170 = asuint(saturate(asfloat(asuint(asfloat(r2.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r2.x, r2.x, l(0.500000)
    r2.x = value_170.x;
    uint4 value_171 = asuint(asfloat(r2.xxxx) * asfloat(cb0[29].xxxx)); // mul r2.x, r2.x, cb0[29].x
    r2.x = value_171.x;
    uint4 value_172 = asuint(mad(asfloat(r2.xxxx), asfloat(r0.xyzx), asfloat(r1.wwww))); // mad r0.xyz, r2.xxxx, r0.xyzx, r1.wwww
    r0.xyz = value_172.xyz;
    uint4 value_173 = asuint(asfloat(r1.yyyy) * asfloat(cb0[31].xyzx)); // mul r2.xyz, r1.yyyy, cb0[31].xyzx
    r2.xyz = value_173.xyz;
    uint4 value_174 = asuint(mad(asfloat(cb0[30].xyxz), asfloat(r1.xxxx), asfloat(r2.xyxz))); // mad r1.xyw, cb0[30].xyxz, r1.xxxx, r2.xyxz
    r1.xyw = value_174.xyw;
    uint4 value_175 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r1.zzzz), asfloat(r1.xywx))); // mad r1.xyz, cb0[32].xyzx, r1.zzzz, r1.xywx
    r1.xyz = value_175.xyz;
    uint4 value_176 = asuint(asfloat(r1.xyzx) + asfloat(cb0[33].xyzx)); // add r1.xyz, r1.xyzx, cb0[33].xyzx
    r1.xyz = value_176.xyz;
    uint4 value_177 = asuint(asfloat(r0.wwww) * asfloat(cb0[38].yyyy)); // mul r1.w, r0.w, cb0[38].y
    r1.w = value_177.w;
    uint4 value_178 = asuint(saturate(asfloat(r0.wwww))); // mov_sat r0.w, r0.w
    r0.w = value_178.w;
    uint4 value_179 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_179.w;
    uint4 value_180 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r1.zzzz))); // mad r1.z, -r1.w, l(0.050000), r1.z
    r1.z = value_180.z;
    uint4 value_181 = asuint(asfloat(r1.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r1.z, r1.z, l(-0.003922)
    r1.z = value_181.z;
    uint4 value_182 = asuint(asfloat(r1.xyxx) * asfloat(cb0[39].zwzz)); // mul r2.xy, r1.xyxx, cb0[39].zwzz
    r2.xy = value_182.xy;
    uint4 value_183 = r1.xyxx; // mov o3.xy, r1.xyxx
    out_o3.xy = value_183.xy;
    uint4 value_184 = asuint(asfloat(r2.xxxy) * asfloat(cb0[39].xxxy)); // mul r3.zw, r2.xxxy, cb0[39].xxxy
    r3.zw = value_184.zw;
    uint4 value_185 = asuint(mad(asfloat(r2.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r3.xy, r2.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r3.xy = value_185.xy;
    uint4 value_186 = asuint(frac(asfloat(r2.xyxx))); // frc r1.xy, r2.xyxx
    r1.xy = value_186.xy;
    uint4 value_187 = asuint(t2.SampleLevel(s2, asfloat(r3.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r3.zyzz, t2.xyzw, s2, l(0.000000)
    r2.xyzw = value_187.xyzw;
    uint4 value_188 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r2.xyzx)))); // add r2.xyz, r1.zzzz, -r2.xyzx
    r2.xyz = value_188.xyz;
    uint4 value_189 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r2.w, cb0[38].x, l(20.000000)
    r2.w = value_189.w;
    uint4 value_190 = asuint(saturate(asfloat(asuint(asfloat(r2.wwww) * asfloat(r2.xyzx))))); // mul_sat r2.xyz, r2.wwww, r2.xyzx
    r2.xyz = value_190.xyz;
    uint4 value_191 = asuint(asfloat(asuint(-asfloat(r1.xyxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r4.xy, -r1.xyxx, l(1.000000, 1.000000, 0.000000, 0.000000)
    r4.xy = value_191.xy;
    uint4 value_192 = asuint(asfloat(r2.xyzx) * asfloat(r4.xxxx)); // mul r2.xyz, r2.xyzx, r4.xxxx
    r2.xyz = value_192.xyz;
    uint4 value_193 = asuint(asfloat(r1.yyyy) * asfloat(r2.xyzx)); // mul r2.xyz, r1.yyyy, r2.xyzx
    r2.xyz = value_193.xyz;
    uint4 value_194 = asuint(t2.SampleLevel(s2, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t2.xyzw, s2, l(0.000000)
    r5.xyzw = value_194.xyzw;
    uint4 value_195 = asuint(t2.SampleLevel(s2, asfloat(r3.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r3.xwxx, t2.xyzw, s2, l(0.000000)
    r6.xyzw = value_195.xyzw;
    uint4 value_196 = asuint(t2.SampleLevel(s2, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.xyxx, t2.xyzw, s2, l(0.000000)
    r3.xyzw = value_196.xyzw;
    uint4 value_197 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r3.xyz, r1.zzzz, -r3.xyzx
    r3.xyz = value_197.xyz;
    uint4 value_198 = asuint(saturate(asfloat(asuint(asfloat(r2.wwww) * asfloat(r3.xyzx))))); // mul_sat r3.xyz, r2.wwww, r3.xyzx
    r3.xyz = value_198.xyz;
    uint4 value_199 = asuint(asfloat(r1.xxxx) * asfloat(r3.xyzx)); // mul r3.xyz, r1.xxxx, r3.xyzx
    r3.xyz = value_199.xyz;
    uint4 value_200 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r1.zzzz, -r6.xyzx
    r6.xyz = value_200.xyz;
    uint4 value_201 = asuint(saturate(asfloat(asuint(asfloat(r2.wwww) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r2.wwww, r6.xyzx
    r6.xyz = value_201.xyz;
    uint4 value_202 = asuint(asfloat(r1.xxxx) * asfloat(r6.xyzx)); // mul r6.xyz, r1.xxxx, r6.xyzx
    r6.xyz = value_202.xyz;
    uint4 value_203 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r1.zzzz, -r5.xyzx
    r5.xyz = value_203.xyz;
    uint4 value_204 = asuint(saturate(asfloat(asuint(asfloat(r2.wwww) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r2.wwww, r5.xyzx
    r5.xyz = value_204.xyz;
    uint4 value_205 = asuint(asfloat(r4.xxxx) * asfloat(r5.xxyz)); // mul r4.xzw, r4.xxxx, r5.xxyz
    r4.xzw = value_205.xzw;
    uint4 value_206 = asuint(mad(asfloat(r4.xzwx), asfloat(r4.yyyy), asfloat(r2.xyzx))); // mad r2.xyz, r4.xzwx, r4.yyyy, r2.xyzx
    r2.xyz = value_206.xyz;
    uint4 value_207 = asuint(mad(asfloat(r6.xyzx), asfloat(r4.yyyy), asfloat(r2.xyzx))); // mad r2.xyz, r6.xyzx, r4.yyyy, r2.xyzx
    r2.xyz = value_207.xyz;
    uint4 value_208 = asuint(mad(asfloat(r3.xyzx), asfloat(r1.yyyy), asfloat(r2.xyzx))); // mad r2.xyz, r3.xyzx, r1.yyyy, r2.xyzx
    r2.xyz = value_208.xyz;
    uint4 value_209 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r1.x, r2.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r1.x = value_209.x;
    uint4 value_210 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.x, l(1.000000)
    r1.x = value_210.x;
    uint4 value_211 = asuint(asfloat(r0.wwww) * asfloat(r0.wwww)); // mul r1.y, r0.w, r0.w
    r1.y = value_211.y;
    uint4 value_212 = asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(r1.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r1.w, -r0.w, r1.y, l(1.000000)
    r1.w = value_212.w;
    uint4 value_213 = asuint(asfloat(r1.wwww) * asfloat(r1.xxxx)); // mul r0.w, r1.w, r1.x
    r0.w = value_213.w;
    uint4 value_214 = r1.zzzw; // mov o3.zw, r1.zzzw
    out_o3.zw = value_214.zw;
    uint4 value_215 = asuint(asfloat(r0.wwww) * asfloat(cb0[5].wwww)); // mul r0.w, r0.w, cb0[5].w
    r0.w = value_215.w;
    uint4 value_216 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_216.xyz;
    uint4 value_217 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_217.xyz;
    uint4 value_218 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r0.wwww, r2.xyzx, r1.xyzx
    r1.xyz = value_218.xyz;
    uint4 value_219 = asuint(asfloat(r0.wwww) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.wwww, cb0[5].xyzx
    r2.xyz = value_219.xyz;
    uint4 value_220 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_220.xyz;
    uint4 value_221 = asuint(mad(asfloat(r0.xyzx), asfloat(r1.xyzx), asfloat(r2.xyzx))); // mad r0.xyz, r0.xyzx, r1.xyzx, r2.xyzx
    r0.xyz = value_221.xyz;
    uint4 value_222 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add o2.xyz, r0.xyzx, l(0.100000, 0.100000, 0.100000, 0.000000)
    out_o2.xyz = value_222.xyz;
    uint4 value_223 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.x, cb0[5].w, -cb0[6].w
    r0.x = value_223.x;
    uint4 value_224 = asuint(mad(asfloat(r0.wwww), asfloat(r0.xxxx), asfloat(cb0[6].wwww))); // mad o2.w, r0.w, r0.x, cb0[6].w
    out_o2.w = value_224.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xyzw);
    result.o2_0 = asfloat(out_o2.xyzw);
    result.o3_0 = asfloat(out_o3.xyzw);
    return result;
}
