// Register-explicit recovered HLSL. Not original source.
// Placemaker/Plants vs_4_0 variant []
// Source SHA256 b75222bcccd5530c8015d9ebc7a2a952e9f4046105f63d64647b8c038de04090
// b0: $Globals 672 bytes
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
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = _Time rows=1 cols=4 byte_offset=0
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
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
    uint4 value_1 = ((asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3fc00000u, 0x3fc00000u)) >= asfloat(v1.yyyy)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, l(1.500000), v1.y
    r0.x = value_1.x;
    uint4 value_2 = (r0.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and o0.w, r0.x, l(0x3f800000)
    out_o0.w = value_2.w;
    uint4 value_3 = asuint(frac(asfloat(v1.xyxx))); // frc o0.xy, v1.xyxx
    out_o0.xy = value_3.xy;
    uint4 value_4 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb2[1].xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(mad(asfloat(cb2[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb2[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb2[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_8.xyz;
    uint4 value_9 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r1.w, r1.xyzx, r1.xyzx
    r1.w = value_9.w;
    uint4 value_10 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.w, l(1.000000)
    r1.w = value_10.w;
    uint4 value_11 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r1.w, l(0.000000)
    r1.w = value_11.w;
    uint4 value_12 = asuint(asfloat(r1.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r1.wwww, r1.xyzx
    r1.xyz = value_12.xyz;
    uint4 value_13 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r1.w, r1.y, cb0[22].w, r0.y
    r1.w = value_13.w;
    uint4 value_14 = asuint(min(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r1.w, r1.w, l(0.000000)
    r1.w = value_14.w;
    uint4 value_15 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r1.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r1.w
    r2.w = value_15.w;
    uint4 value_16 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_16.xz;
    uint4 value_17 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r1.xyz, r0.xyzx, r2.xwzx
    r1.xyz = value_17.xyz;
    uint4 value_18 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(cb1[4].xyzx)); // add r2.xyz, -r1.xyzx, cb1[4].xyzx
    r2.xyz = value_18.xyz;
    uint4 value_19 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r2.xyzx).xyz)).xxxx; // dp3 r1.w, r2.xyzx, r2.xyzx
    r1.w = value_19.w;
    uint4 value_20 = asuint(rsqrt(asfloat(r1.wwww))); // rsq r1.w, r1.w
    r1.w = value_20.w;
    uint4 value_21 = asuint(asfloat(r1.wwww) * asfloat(r2.xyzx)); // mul r2.xyz, r1.wwww, r2.xyzx
    r2.xyz = value_21.xyz;
    uint4 value_22 = asuint(asfloat(v2.yyyy) * asfloat(cb2[1].xyzx)); // mul r3.xyz, v2.yyyy, cb2[1].xyzx
    r3.xyz = value_22.xyz;
    uint4 value_23 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v2.xxxx), asfloat(r3.xyzx))); // mad r3.xyz, cb2[0].xyzx, v2.xxxx, r3.xyzx
    r3.xyz = value_23.xyz;
    uint4 value_24 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v2.zzzz), asfloat(r3.xyzx))); // mad r3.xyz, cb2[2].xyzx, v2.zzzz, r3.xyzx
    r3.xyz = value_24.xyz;
    uint4 value_25 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(r3.xyzx).xyz)).xxxx; // dp3 r1.w, r3.xyzx, r3.xyzx
    r1.w = value_25.w;
    uint4 value_26 = asuint(rsqrt(asfloat(r1.wwww))); // rsq r1.w, r1.w
    r1.w = value_26.w;
    uint4 value_27 = asuint(asfloat(r1.wwww) * asfloat(r3.xyzx)); // mul r4.xyz, r1.wwww, r3.xyzx
    r4.xyz = value_27.xyz;
    uint4 value_28 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r4.xyzx).xyz)).xxxx; // dp3 r2.w, r2.xyzx, r4.xyzx
    r2.w = value_28.w;
    uint4 value_29 = asuint(mad(asfloat(asuint(-asfloat(r2.xyzx))), asfloat(r2.wwww), asfloat(r4.xyzx))); // mad r2.xyz, -r2.xyzx, r2.wwww, r4.xyzx
    r2.xyz = value_29.xyz;
    uint4 value_30 = asuint(saturate(asfloat(r2.wwww))); // mov_sat o0.z, r2.w
    out_o0.z = value_30.z;
    uint4 value_31 = asuint(asfloat(r0.yyyy) * asfloat(cb0[31].xyzx)); // mul r5.xyz, r0.yyyy, cb0[31].xyzx
    r5.xyz = value_31.xyz;
    uint4 value_32 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r0.xxxx), asfloat(r5.xyzx))); // mad r5.xyz, cb0[30].xyzx, r0.xxxx, r5.xyzx
    r5.xyz = value_32.xyz;
    uint4 value_33 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r0.zzzz), asfloat(r5.xyzx))); // mad r5.xyz, cb0[32].xyzx, r0.zzzz, r5.xyzx
    r5.xyz = value_33.xyz;
    uint4 value_34 = asuint(asfloat(r5.xyzx) + asfloat(cb0[33].xyzx)); // add r5.xyz, r5.xyzx, cb0[33].xyzx
    r5.xyz = value_34.xyz;
    uint4 value_35 = asuint(dot(asfloat(r4.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r2.w, r4.xyzx, -cb0[4].xyzx
    r2.w = value_35.w;
    uint4 value_36 = asuint(asfloat(r2.wwww) * asfloat(cb0[38].yyyy)); // mul r3.w, r2.w, cb0[38].y
    r3.w = value_36.w;
    uint4 value_37 = asuint(saturate(asfloat(r2.wwww))); // mov_sat r2.w, r2.w
    r2.w = value_37.w;
    uint4 value_38 = asuint(asfloat(asuint(-asfloat(r2.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r2.w, -r2.w, l(1.000000)
    r2.w = value_38.w;
    uint4 value_39 = asuint(mad(asfloat(asuint(-asfloat(r3.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r5.zzzz))); // mad r3.w, -r3.w, l(0.050000), r5.z
    r3.w = value_39.w;
    uint4 value_40 = asuint(asfloat(r3.wwww) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r5.z, r3.w, l(-0.003922)
    r5.z = value_40.z;
    uint4 value_41 = asuint(asfloat(r5.xyxx) * asfloat(cb0[39].zwzz)); // mul r6.xy, r5.xyxx, cb0[39].zwzz
    r6.xy = value_41.xy;
    uint4 value_42 = r5.xyxx; // mov o4.xy, r5.xyxx
    out_o4.xy = value_42.xy;
    uint4 value_43 = asuint(asfloat(r6.xxxy) * asfloat(cb0[39].xxxy)); // mul r7.zw, r6.xxxy, cb0[39].xxxy
    r7.zw = value_43.zw;
    uint4 value_44 = asuint(mad(asfloat(r6.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r7.xy, r6.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r7.xy = value_44.xy;
    uint4 value_45 = asuint(frac(asfloat(r6.xyxx))); // frc r5.xy, r6.xyxx
    r5.xy = value_45.xy;
    uint4 value_46 = asuint(t2.SampleLevel(s2, asfloat(r7.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r7.zyzz, t2.xyzw, s2, l(0.000000)
    r6.xyzw = value_46.xyzw;
    uint4 value_47 = asuint(asfloat(r5.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r5.zzzz, -r6.xyzx
    r6.xyz = value_47.xyz;
    uint4 value_48 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r3.w, cb0[38].x, l(20.000000)
    r3.w = value_48.w;
    uint4 value_49 = asuint(saturate(asfloat(asuint(asfloat(r3.wwww) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r3.wwww, r6.xyzx
    r6.xyz = value_49.xyz;
    uint4 value_50 = asuint(asfloat(asuint(-asfloat(r5.xyxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r8.xy, -r5.xyxx, l(1.000000, 1.000000, 0.000000, 0.000000)
    r8.xy = value_50.xy;
    uint4 value_51 = asuint(asfloat(r6.xyzx) * asfloat(r8.xxxx)); // mul r6.xyz, r6.xyzx, r8.xxxx
    r6.xyz = value_51.xyz;
    uint4 value_52 = asuint(asfloat(r5.yyyy) * asfloat(r6.xyzx)); // mul r6.xyz, r5.yyyy, r6.xyzx
    r6.xyz = value_52.xyz;
    uint4 value_53 = asuint(t2.SampleLevel(s2, asfloat(r7.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r9.xyzw, r7.zwzz, t2.xyzw, s2, l(0.000000)
    r9.xyzw = value_53.xyzw;
    uint4 value_54 = asuint(t2.SampleLevel(s2, asfloat(r7.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r10.xyzw, r7.xwxx, t2.xyzw, s2, l(0.000000)
    r10.xyzw = value_54.xyzw;
    uint4 value_55 = asuint(t2.SampleLevel(s2, asfloat(r7.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r7.xyxx, t2.xyzw, s2, l(0.000000)
    r7.xyzw = value_55.xyzw;
    uint4 value_56 = asuint(asfloat(r5.zzzz) + asfloat(asuint(-asfloat(r7.xyzx)))); // add r7.xyz, r5.zzzz, -r7.xyzx
    r7.xyz = value_56.xyz;
    uint4 value_57 = asuint(saturate(asfloat(asuint(asfloat(r3.wwww) * asfloat(r7.xyzx))))); // mul_sat r7.xyz, r3.wwww, r7.xyzx
    r7.xyz = value_57.xyz;
    uint4 value_58 = asuint(asfloat(r5.xxxx) * asfloat(r7.xyzx)); // mul r7.xyz, r5.xxxx, r7.xyzx
    r7.xyz = value_58.xyz;
    uint4 value_59 = asuint(asfloat(r5.zzzz) + asfloat(asuint(-asfloat(r10.xyzx)))); // add r10.xyz, r5.zzzz, -r10.xyzx
    r10.xyz = value_59.xyz;
    uint4 value_60 = asuint(saturate(asfloat(asuint(asfloat(r3.wwww) * asfloat(r10.xyzx))))); // mul_sat r10.xyz, r3.wwww, r10.xyzx
    r10.xyz = value_60.xyz;
    uint4 value_61 = asuint(asfloat(r5.xxxx) * asfloat(r10.xyzx)); // mul r10.xyz, r5.xxxx, r10.xyzx
    r10.xyz = value_61.xyz;
    uint4 value_62 = asuint(asfloat(r5.zzzz) + asfloat(asuint(-asfloat(r9.xyzx)))); // add r9.xyz, r5.zzzz, -r9.xyzx
    r9.xyz = value_62.xyz;
    uint4 value_63 = asuint(saturate(asfloat(asuint(asfloat(r3.wwww) * asfloat(r9.xyzx))))); // mul_sat r9.xyz, r3.wwww, r9.xyzx
    r9.xyz = value_63.xyz;
    uint4 value_64 = asuint(asfloat(r8.xxxx) * asfloat(r9.xxyz)); // mul r8.xzw, r8.xxxx, r9.xxyz
    r8.xzw = value_64.xzw;
    uint4 value_65 = asuint(mad(asfloat(r8.xzwx), asfloat(r8.yyyy), asfloat(r6.xyzx))); // mad r6.xyz, r8.xzwx, r8.yyyy, r6.xyzx
    r6.xyz = value_65.xyz;
    uint4 value_66 = asuint(mad(asfloat(r10.xyzx), asfloat(r8.yyyy), asfloat(r6.xyzx))); // mad r6.xyz, r10.xyzx, r8.yyyy, r6.xyzx
    r6.xyz = value_66.xyz;
    uint4 value_67 = asuint(mad(asfloat(r7.xyzx), asfloat(r5.yyyy), asfloat(r6.xyzx))); // mad r6.xyz, r7.xyzx, r5.yyyy, r6.xyzx
    r6.xyz = value_67.xyz;
    uint4 value_68 = asuint(dot(asfloat(r6.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r3.w, r6.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r3.w = value_68.w;
    uint4 value_69 = asuint(asfloat(asuint(-asfloat(r3.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r3.w, -r3.w, l(1.000000)
    r3.w = value_69.w;
    uint4 value_70 = asuint(asfloat(r2.wwww) * asfloat(r2.wwww)); // mul r4.w, r2.w, r2.w
    r4.w = value_70.w;
    uint4 value_71 = asuint(mad(asfloat(asuint(-asfloat(r2.wwww))), asfloat(r4.wwww), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r5.w, -r2.w, r4.w, l(1.000000)
    r5.w = value_71.w;
    uint4 value_72 = asuint(asfloat(r3.wwww) * asfloat(r5.wwww)); // mul r2.w, r3.w, r5.w
    r2.w = value_72.w;
    uint4 value_73 = r5.zzzw; // mov o4.zw, r5.zzzw
    out_o4.zw = value_73.zw;
    uint4 value_74 = asuint(asfloat(r2.wwww) * asfloat(cb0[5].wwww)); // mul r2.w, r2.w, cb0[5].w
    r2.w = value_74.w;
    uint4 value_75 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r3.w, cb0[5].w, -cb0[6].w
    r3.w = value_75.w;
    uint4 value_76 = asuint(mad(asfloat(r2.wwww), asfloat(r3.wwww), asfloat(cb0[6].wwww))); // mad r3.w, r2.w, r3.w, cb0[6].w
    r3.w = value_76.w;
    uint4 value_77 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x41000000u, 0x41000000u, 0x41000000u, 0x41000000u))); // mul r4.w, r1.y, l(8.000000)
    r4.w = value_77.w;
    uint4 value_78 = asuint(mad(asfloat(cb1[0].yyyy), asfloat(uint4(0x40e00000u, 0x40e00000u, 0x40e00000u, 0x40e00000u)), asfloat(r4.wwww))); // mad r4.w, cb1[0].y, l(7.000000), r4.w
    r4.w = value_78.w;
    uint4 value_79 = asuint(asfloat(r3.wwww) + asfloat(r4.wwww)); // add r4.w, r3.w, r4.w
    r4.w = value_79.w;
    uint4 value_80 = r3.wwww; // mov o3.w, r3.w
    out_o3.w = value_80.w;
    uint4 value_81 = asuint(floor(asfloat(v1.xxxx))); // round_ni r3.w, v1.x
    r3.w = value_81.w;
    uint4 value_82 = asuint(mad(asfloat(r3.wwww), asfloat(uint4(0x40400000u, 0x40400000u, 0x40400000u, 0x40400000u)), asfloat(r4.wwww))); // mad r3.w, r3.w, l(3.000000), r4.w
    r3.w = value_82.w;
    uint4 value_83 = asuint(asfloat(r3.wwww) * asfloat(uint4(0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu))); // mul r4.w, r3.w, l(6.283185)
    r4.w = value_83.w;
    uint4 value_84 = ((asfloat(r4.wwww) >= asfloat(asuint(-asfloat(r4.wwww)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r4.w, r4.w, -r4.w
    r4.w = value_84.w;
    uint4 value_85 = ((r4.wwww != 0u) ? uint4(0x40c90fdbu, 0x3e22f983u, 0x0u, 0x0u) : uint4(0xc0c90fdbu, 0xbe22f983u, 0x0u, 0x0u)); // movc r5.xy, r4.wwww, l(6.283185,0.159155,0,0), l(-6.283185,-0.159155,0,0)
    r5.xy = value_85.xy;
    uint4 value_86 = asuint(asfloat(r3.wwww) * asfloat(r5.yyyy)); // mul r3.w, r3.w, r5.y
    r3.w = value_86.w;
    uint4 value_87 = asuint(frac(asfloat(r3.wwww))); // frc r3.w, r3.w
    r3.w = value_87.w;
    uint4 value_88 = asuint(asfloat(r3.wwww) * asfloat(r5.xxxx)); // mul r3.w, r3.w, r5.x
    r3.w = value_88.w;
    uint4 value_89s = asuint(sin(asfloat(r3.wwww))); // sincos r3.w, null, r3.w
    r3.w = value_89s.w;
    uint4 value_90 = asuint(asfloat(r3.wwww) * asfloat(uint4(0x3ba3d70au, 0x3ba3d70au, 0x3ba3d70au, 0x3ba3d70au))); // mul r3.w, r3.w, l(0.005000)
    r3.w = value_90.w;
    uint4 value_91 = asuint(mad(asfloat(r3.wwww), asfloat(r4.yyyy), asfloat(r1.yyyy))); // mad r5.y, r3.w, r4.y, r1.y
    r5.y = value_91.y;
    uint4 value_92 = asuint(mad(asfloat(asuint(-asfloat(r3.wwww))), asfloat(r4.xxzx), asfloat(r1.xxzx))); // mad r5.xz, -r3.wwww, r4.xxzx, r1.xxzx
    r5.xz = value_92.xz;
    uint4 value_93 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0x3d23d70au, 0x3d23d70au, 0x3d23d70au, 0x0u)), asfloat(r5.xyzx))); // mad r1.xyz, r2.xyzx, l(0.040000, 0.040000, 0.040000, 0.000000), r5.xyzx
    r1.xyz = value_93.xyz;
    uint4 value_94 = asuint(asfloat(r1.yyyy) * asfloat(cb3[10].xyxx)); // mul r2.xy, r1.yyyy, cb3[10].xyxx
    r2.xy = value_94.xy;
    uint4 value_95 = asuint(mad(asfloat(cb3[9].xyxx), asfloat(r1.xxxx), asfloat(r2.xyxx))); // mad r2.xy, cb3[9].xyxx, r1.xxxx, r2.xyxx
    r2.xy = value_95.xy;
    uint4 value_96 = asuint(mad(asfloat(cb3[11].xyxx), asfloat(r1.zzzz), asfloat(r2.xyxx))); // mad r2.xy, cb3[11].xyxx, r1.zzzz, r2.xyxx
    r2.xy = value_96.xy;
    uint4 value_97 = asuint(mad(asfloat(cb3[12].xyxx), asfloat(r0.wwww), asfloat(r2.xyxx))); // mad o1.xy, cb3[12].xyxx, r0.wwww, r2.xyxx
    out_o1.xy = value_97.xy;
    uint4 value_98 = asuint(asfloat(r1.yyyy) * asfloat(cb3[18].xyzw)); // mul r4.xyzw, r1.yyyy, cb3[18].xyzw
    r4.xyzw = value_98.xyzw;
    uint4 value_99 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r1.xxxx), asfloat(r4.xyzw))); // mad r4.xyzw, cb3[17].xyzw, r1.xxxx, r4.xyzw
    r4.xyzw = value_99.xyzw;
    uint4 value_100 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r1.zzzz), asfloat(r4.xyzw))); // mad r4.xyzw, cb3[19].xyzw, r1.zzzz, r4.xyzw
    r4.xyzw = value_100.xyzw;
    uint4 value_101 = asuint(asfloat(r4.xyzw) + asfloat(cb3[20].xyzw)); // add o2.xyzw, r4.xyzw, cb3[20].xyzw
    out_o2.xyzw = value_101.xyzw;
    uint4 value_102 = asuint(asfloat(r0.xzxz) + asfloat(asuint(-asfloat(cb0[3].xyxy)))); // add r4.xyzw, r0.xzxz, -cb0[3].xyxy
    r4.xyzw = value_102.xyzw;
    uint4 value_103 = asuint(asfloat(r4.xyzw) + asfloat(uint4(0x3ca3d70au, 0x0u, 0x0u, 0x3ca3d70au))); // add r5.xyzw, r4.xyzw, l(0.020000, 0.000000, 0.000000, 0.020000)
    r5.xyzw = value_103.xyzw;
    uint4 value_104 = asuint(asfloat(r4.zwzz) * asfloat(cb0[2].zzzz)); // mul r1.xy, r4.zwzz, cb0[2].zzzz
    r1.xy = value_104.xy;
    uint4 value_105 = asuint(max(asfloat(r1.xyxx), asfloat(cb0[7].xyxx))); // max r1.xy, r1.xyxx, cb0[7].xyxx
    r1.xy = value_105.xy;
    uint4 value_106 = asuint(asfloat(r5.xyzw) * asfloat(cb0[2].zzzz)); // mul r4.xyzw, r5.xyzw, cb0[2].zzzz
    r4.xyzw = value_106.xyzw;
    uint4 value_107 = asuint(max(asfloat(r4.xyzw), asfloat(cb0[7].xyxy))); // max r4.xyzw, r4.xyzw, cb0[7].xyxy
    r4.xyzw = value_107.xyzw;
    uint4 value_108 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r2.xy, cb0[2].xyxx, -cb0[7].xyxx
    r2.xy = value_108.xy;
    uint4 value_109 = asuint(min(asfloat(r2.xyxy), asfloat(r4.xyzw))); // min r4.xyzw, r2.xyxy, r4.xyzw
    r4.xyzw = value_109.xyzw;
    uint4 value_110 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.w, r0.y, l(-0.500000)
    r0.w = value_110.w;
    uint4 value_111 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_111.w;
    uint4 value_112 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.z, r0.w
    r1.z = value_112.z;
    uint4 value_113 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_113.w;
    uint4 value_114 = asuint(int4(asfloat(r1.zzzz))); // ftoi r2.z, r1.z
    r2.z = value_114.z;
    uint4 value_115 = (r2.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.w, r2.z, l(1)
    r3.w = value_115.w;
    uint4 value_116 = asuint(float4(asint(r3.wwww))); // itof r5.x, r3.w
    r5.x = value_116.x;
    uint4 value_117 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r5.y, cb0[2].w
    r5.y = value_117.y;
    uint4 value_118 = uint4(asfloat(r5.yyyy)); // ftou r5.y, r5.y
    r5.y = value_118.y;
    uint4 value_119 = asuint(float4(r5.yyyy)); // utof r5.z, r5.y
    r5.z = value_119.z;
    uint4 value_120 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r5.zzzz)); // div r5.z, l(1.000000, 1.000000, 1.000000, 1.000000), r5.z
    r5.z = value_120.z;
    uint4 value_121 = asuint(asfloat(r5.zzzz) * asfloat(r5.xxxx)); // mul r5.x, r5.z, r5.x
    r5.x = value_121.x;
    uint4 value_122 = asuint(int4(asfloat(r5.xxxx))); // ftoi r5.w, r5.x
    r5.w = value_122.w;
    uint4 value_123 = asuint(trunc(asfloat(r5.xxxx))); // round_z r6.yw, r5.xxxx
    r6.yw = value_123.yw;
    uint4 value_124 = (asuint(-asint(r5.wwww)) * r5.yyyy + r3.wwww); // imad r3.w, -r5.w, r5.y, r3.w
    r3.w = value_124.w;
    uint4 value_125 = asuint(float4(r3.wwww)); // utof r6.xz, r3.wwww
    r6.xz = value_125.xz;
    uint4 value_126 = asuint(mad(asfloat(r6.xyzw), asfloat(cb0[2].xyxy), asfloat(r4.xyzw))); // mad r7.xyzw, r6.xyzw, cb0[2].xyxy, r4.xyzw
    r7.xyzw = value_126.xyzw;
    uint4 value_127 = asuint(t0.SampleLevel(s1, asfloat(r7.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r7.xyxx, t0.xyzw, s1, l(0.000000)
    r8.xyzw = value_127.xyzw;
    uint4 value_128 = asuint(t0.SampleLevel(s1, asfloat(r7.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r7.zwzz, t0.xyzw, s1, l(0.000000)
    r7.xyzw = value_128.xyzw;
    uint4 value_129 = asuint(min(asfloat(r1.xyxx), asfloat(r2.xyxx))); // min r1.xy, r1.xyxx, r2.xyxx
    r1.xy = value_129.xy;
    uint4 value_130 = asuint(mad(asfloat(r6.xxxy), asfloat(cb0[2].xxxy), asfloat(r1.xxxy))); // mad r5.xw, r6.xxxy, cb0[2].xxxy, r1.xxxy
    r5.xw = value_130.xw;
    uint4 value_131 = asuint(t0.SampleLevel(s1, asfloat(r5.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xwxx, t0.xyzw, s1, l(0.000000)
    r6.xyzw = value_131.xyzw;
    uint4 value_132 = asuint(asfloat(asuint(-asfloat(r6.wwww))) + asfloat(r8.wwww)); // add r3.w, -r6.w, r8.w
    r3.w = value_132.w;
    uint4 value_133 = asuint(asfloat(r3.wwww) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r6.x, r3.w, l(50.000000)
    r6.x = value_133.x;
    uint4 value_134 = asuint(asfloat(asuint(-asfloat(r6.wwww))) + asfloat(r7.wwww)); // add r3.w, -r6.w, r7.w
    r3.w = value_134.w;
    uint4 value_135 = asuint(asfloat(r3.wwww) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r6.z, r3.w, l(50.000000)
    r6.z = value_135.z;
    uint4 value_136 = asuint(asfloat(r1.zzzz) * asfloat(r5.zzzz)); // mul r1.z, r1.z, r5.z
    r1.z = value_136.z;
    uint4 value_137 = asuint(int4(asfloat(r1.zzzz))); // ftoi r3.w, r1.z
    r3.w = value_137.w;
    uint4 value_138 = asuint(trunc(asfloat(r1.zzzz))); // round_z r7.yw, r1.zzzz
    r7.yw = value_138.yw;
    uint4 value_139 = (asuint(-asint(r3.wwww)) * r5.yyyy + r2.zzzz); // imad r1.z, -r3.w, r5.y, r2.z
    r1.z = value_139.z;
    uint4 value_140 = asuint(float4(r1.zzzz)); // utof r7.xz, r1.zzzz
    r7.xz = value_140.xz;
    uint4 value_141 = asuint(mad(asfloat(r7.xyzw), asfloat(cb0[2].xyxy), asfloat(r4.xyzw))); // mad r4.xyzw, r7.xyzw, cb0[2].xyxy, r4.xyzw
    r4.xyzw = value_141.xyzw;
    uint4 value_142 = asuint(mad(asfloat(r7.zwzz), asfloat(cb0[2].xyxx), asfloat(r1.xyxx))); // mad r1.xy, r7.zwzz, cb0[2].xyxx, r1.xyxx
    r1.xy = value_142.xy;
    uint4 value_143 = asuint(t0.SampleLevel(s1, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r1.xyxx, t0.xyzw, s1, l(0.000000)
    r7.xyzw = value_143.xyzw;
    uint4 value_144 = asuint(t0.SampleLevel(s1, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r4.xyxx, t0.xyzw, s1, l(0.000000)
    r8.xyzw = value_144.xyzw;
    uint4 value_145 = asuint(t0.SampleLevel(s1, asfloat(r4.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r4.zwzz, t0.xyzw, s1, l(0.000000)
    r4.xyzw = value_145.xyzw;
    uint4 value_146 = asuint(asfloat(asuint(-asfloat(r7.wwww))) + asfloat(r4.wwww)); // add r1.x, -r7.w, r4.w
    r1.x = value_146.x;
    uint4 value_147 = asuint(asfloat(r1.xxxx) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r1.z, r1.x, l(50.000000)
    r1.z = value_147.z;
    uint4 value_148 = asuint(asfloat(asuint(-asfloat(r7.wwww))) + asfloat(r8.wwww)); // add r1.y, -r7.w, r8.w
    r1.y = value_148.y;
    uint4 value_149 = asuint(asfloat(r6.wwww) + asfloat(asuint(-asfloat(r7.wwww)))); // add r2.z, r6.w, -r7.w
    r2.z = value_149.z;
    uint4 value_150 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r1.x, r1.y, l(50.000000)
    r1.x = value_150.x;
    uint4 value_151 = asuint(asfloat(asuint(-asfloat(r1.xzxx))) + asfloat(r6.xzxx)); // add r4.xy, -r1.xzxx, r6.xzxx
    r4.xy = value_151.xy;
    uint4 value_152 = asuint(mad(asfloat(r0.wwww), asfloat(r4.xxyx), asfloat(r1.xxzx))); // mad r1.xz, r0.wwww, r4.xxyx, r1.xxzx
    r1.xz = value_152.xz;
    uint4 value_153 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r3.w, -r0.w, l(1.000000)
    r3.w = value_153.w;
    uint4 value_154 = asuint(asfloat(r0.wwww) * asfloat(r3.wwww)); // mul r0.w, r0.w, r3.w
    r0.w = value_154.w;
    uint4 value_155 = asuint(asfloat(r0.wwww) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul r0.w, r0.w, l(4.000000)
    r0.w = value_155.w;
    uint4 value_156 = asuint(asfloat(r0.wwww) * asfloat(r2.zzzz)); // mul r1.y, r0.w, r2.z
    r1.y = value_156.y;
    uint4 value_157 = asuint(mad(asfloat(r3.xyzx), asfloat(r1.wwww), asfloat(r1.xyzx))); // mad r1.xyz, r3.xyzx, r1.wwww, r1.xyzx
    r1.xyz = value_157.xyz;
    uint4 value_158 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r3.xyz, r1.xyzx, l(0.200000, 0.200000, 0.200000, 0.000000), r0.xyzx
    r3.xyz = value_158.xyz;
    uint4 value_159 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r1.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), r0.xyzx
    r0.xyz = value_159.xyz;
    uint4 value_160 = asuint(asfloat(r3.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r1.xy, r3.xzxx, -cb0[3].xyxx
    r1.xy = value_160.xy;
    uint4 value_161 = asuint(asfloat(r3.yyyy) + asfloat(uint4(0x0u, 0x0u, 0x3f333333u, 0xbe99999au))); // add r1.zw, r3.yyyy, l(0.000000, 0.000000, 0.700000, -0.300000)
    r1.zw = value_161.zw;
    uint4 value_162 = asuint(asfloat(r1.xyxx) * asfloat(cb0[2].zzzz)); // mul r1.xy, r1.xyxx, cb0[2].zzzz
    r1.xy = value_162.xy;
    uint4 value_163 = asuint(max(asfloat(r1.xyxx), asfloat(cb0[7].xyxx))); // max r1.xy, r1.xyxx, cb0[7].xyxx
    r1.xy = value_163.xy;
    uint4 value_164 = asuint(min(asfloat(r2.xyxx), asfloat(r1.xyxx))); // min r1.xy, r2.xyxx, r1.xyxx
    r1.xy = value_164.xy;
    uint4 value_165 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r1.w, l(0.000000)
    r0.w = value_165.w;
    uint4 value_166 = asuint(saturate(asfloat(r1.zzzz))); // mov_sat r1.z, r1.z
    r1.z = value_166.z;
    uint4 value_167 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.w, r0.w
    r1.w = value_167.w;
    uint4 value_168 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_168.w;
    uint4 value_169 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.z, r1.w
    r2.z = value_169.z;
    uint4 value_170 = asuint(asfloat(r5.zzzz) * asfloat(r1.wwww)); // mul r1.w, r5.z, r1.w
    r1.w = value_170.w;
    uint4 value_171 = (r2.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.x, r2.z, l(1)
    r3.x = value_171.x;
    uint4 value_172 = asuint(float4(asint(r3.xxxx))); // itof r3.y, r3.x
    r3.y = value_172.y;
    uint4 value_173 = asuint(asfloat(r5.zzzz) * asfloat(r3.yyyy)); // mul r3.y, r5.z, r3.y
    r3.y = value_173.y;
    uint4 value_174 = asuint(int4(asfloat(r3.yyyy))); // ftoi r3.z, r3.y
    r3.z = value_174.z;
    uint4 value_175 = asuint(trunc(asfloat(r3.yyyy))); // round_z r3.y, r3.y
    r3.y = value_175.y;
    uint4 value_176 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.yyyy), asfloat(r1.yyyy))); // mad r4.y, cb0[2].y, r3.y, r1.y
    r4.y = value_176.y;
    uint4 value_177 = (asuint(-asint(r3.zzzz)) * r5.yyyy + r3.xxxx); // imad r3.x, -r3.z, r5.y, r3.x
    r3.x = value_177.x;
    uint4 value_178 = asuint(float4(r3.xxxx)); // utof r3.x, r3.x
    r3.x = value_178.x;
    uint4 value_179 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.xxxx), asfloat(r1.xxxx))); // mad r4.x, cb0[2].x, r3.x, r1.x
    r4.x = value_179.x;
    uint4 value_180 = asuint(t1.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r4.xyxx, t1.xyzw, s0, l(0.000000)
    r3.xyzw = value_180.xyzw;
    uint4 value_181 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r4.y, l(1.000000)
    r3.w = value_181.w;
    uint4 value_182 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_182.w;
    uint4 value_183 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r3.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_183.xyz;
    uint4 value_184 = asuint(mad(asfloat(r3.wwww), asfloat(r4.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r3.wwww, r4.xyzx, r3.xyzx
    r3.xyz = value_184.xyz;
    uint4 value_185 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.w, r1.w
    r3.w = value_185.w;
    uint4 value_186 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_186.w;
    uint4 value_187 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r1.yyyy))); // mad r4.y, cb0[2].y, r1.w, r1.y
    r4.y = value_187.y;
    uint4 value_188 = (asuint(-asint(r3.wwww)) * r5.yyyy + r2.zzzz); // imad r1.y, -r3.w, r5.y, r2.z
    r1.y = value_188.y;
    uint4 value_189 = asuint(float4(r1.yyyy)); // utof r1.y, r1.y
    r1.y = value_189.y;
    uint4 value_190 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.yyyy), asfloat(r1.xxxx))); // mad r4.x, cb0[2].x, r1.y, r1.x
    r4.x = value_190.x;
    uint4 value_191 = asuint(t1.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r4.xyxx, t1.xyzw, s0, l(0.000000)
    r6.xyzw = value_191.xyzw;
    uint4 value_192 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.x, r4.y, l(1.000000)
    r1.x = value_192.x;
    uint4 value_193 = (r1.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.x, r1.x, l(0x3f800000)
    r1.x = value_193.x;
    uint4 value_194 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_194.xyz;
    uint4 value_195 = asuint(mad(asfloat(r1.xxxx), asfloat(r4.xyxz), asfloat(r6.xyxz))); // mad r1.xyw, r1.xxxx, r4.xyxz, r6.xyxz
    r1.xyw = value_195.xyw;
    uint4 value_196 = asuint(asfloat(asuint(-asfloat(r1.xywx))) + asfloat(r3.xyzx)); // add r3.xyz, -r1.xywx, r3.xyzx
    r3.xyz = value_196.xyz;
    uint4 value_197 = asuint(mad(asfloat(r0.wwww), asfloat(r3.xyxz), asfloat(r1.xyxw))); // mad r1.xyw, r0.wwww, r3.xyxz, r1.xyxw
    r1.xyw = value_197.xyw;
    uint4 value_198 = asuint(asfloat(r1.xyxw) + asfloat(asuint(-asfloat(cb0[9].xyxz)))); // add r1.xyw, r1.xyxw, -cb0[9].xyxz
    r1.xyw = value_198.xyw;
    uint4 value_199 = asuint(mad(asfloat(r1.zzzz), asfloat(r1.xywx), asfloat(cb0[9].xyzx))); // mad r1.xyz, r1.zzzz, r1.xywx, cb0[9].xyzx
    r1.xyz = value_199.xyz;
    uint4 value_200 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r0.yw, r0.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r0.yw = value_200.yw;
    uint4 value_201 = asuint(asfloat(r0.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r0.xz, r0.xxzx, -cb0[3].xxyx
    r0.xz = value_201.xz;
    uint4 value_202 = asuint(asfloat(r0.xxzx) * asfloat(cb0[2].zzzz)); // mul r0.xz, r0.xxzx, cb0[2].zzzz
    r0.xz = value_202.xz;
    uint4 value_203 = asuint(max(asfloat(r0.xxzx), asfloat(cb0[7].xxyx))); // max r0.xz, r0.xxzx, cb0[7].xxyx
    r0.xz = value_203.xz;
    uint4 value_204 = asuint(min(asfloat(r2.xxyx), asfloat(r0.xxzx))); // min r0.xz, r2.xxyx, r0.xxzx
    r0.xz = value_204.xz;
    uint4 value_205 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_205.w;
    uint4 value_206 = asuint(saturate(asfloat(r0.yyyy))); // mov_sat r0.y, r0.y
    r0.y = value_206.y;
    uint4 value_207 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.w, r0.w
    r1.w = value_207.w;
    uint4 value_208 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_208.w;
    uint4 value_209 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.x, r1.w
    r2.x = value_209.x;
    uint4 value_210 = asuint(asfloat(r5.zzzz) * asfloat(r1.wwww)); // mul r1.w, r5.z, r1.w
    r1.w = value_210.w;
    uint4 value_211 = (r2.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.y, r2.x, l(1)
    r2.y = value_211.y;
    uint4 value_212 = asuint(float4(asint(r2.yyyy))); // itof r2.z, r2.y
    r2.z = value_212.z;
    uint4 value_213 = asuint(asfloat(r5.zzzz) * asfloat(r2.zzzz)); // mul r2.z, r5.z, r2.z
    r2.z = value_213.z;
    uint4 value_214 = asuint(int4(asfloat(r2.zzzz))); // ftoi r3.x, r2.z
    r3.x = value_214.x;
    uint4 value_215 = asuint(trunc(asfloat(r2.zzzz))); // round_z r2.z, r2.z
    r2.z = value_215.z;
    uint4 value_216 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.zzzz), asfloat(r0.zzzz))); // mad r4.y, cb0[2].y, r2.z, r0.z
    r4.y = value_216.y;
    uint4 value_217 = (asuint(-asint(r3.xxxx)) * r5.yyyy + r2.yyyy); // imad r2.y, -r3.x, r5.y, r2.y
    r2.y = value_217.y;
    uint4 value_218 = asuint(float4(r2.yyyy)); // utof r2.y, r2.y
    r2.y = value_218.y;
    uint4 value_219 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.yyyy), asfloat(r0.xxxx))); // mad r4.x, cb0[2].x, r2.y, r0.x
    r4.x = value_219.x;
    uint4 value_220 = asuint(t1.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r4.xyxx, t1.xyzw, s0, l(0.000000)
    r3.xyzw = value_220.xyzw;
    uint4 value_221 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.y, r4.y, l(1.000000)
    r2.y = value_221.y;
    uint4 value_222 = (r2.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.y, r2.y, l(0x3f800000)
    r2.y = value_222.y;
    uint4 value_223 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r3.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_223.xyz;
    uint4 value_224 = asuint(mad(asfloat(r2.yyyy), asfloat(r4.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r2.yyyy, r4.xyzx, r3.xyzx
    r3.xyz = value_224.xyz;
    uint4 value_225 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.y, r1.w
    r2.y = value_225.y;
    uint4 value_226 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_226.w;
    uint4 value_227 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r0.zzzz))); // mad r4.y, cb0[2].y, r1.w, r0.z
    r4.y = value_227.y;
    uint4 value_228 = (asuint(-asint(r2.yyyy)) * r5.yyyy + r2.xxxx); // imad r0.z, -r2.y, r5.y, r2.x
    r0.z = value_228.z;
    uint4 value_229 = asuint(float4(r0.zzzz)); // utof r0.z, r0.z
    r0.z = value_229.z;
    uint4 value_230 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.zzzz), asfloat(r0.xxxx))); // mad r4.x, cb0[2].x, r0.z, r0.x
    r4.x = value_230.x;
    uint4 value_231 = asuint(t1.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.xyxx, t1.xyzw, s0, l(0.000000)
    r5.xyzw = value_231.xyzw;
    uint4 value_232 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, r4.y, l(1.000000)
    r0.x = value_232.x;
    uint4 value_233 = (r0.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.x, r0.x, l(0x3f800000)
    r0.x = value_233.x;
    uint4 value_234 = asuint(asfloat(asuint(-asfloat(r5.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r2.xyz, -r5.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r2.xyz = value_234.xyz;
    uint4 value_235 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzx), asfloat(r5.xyzx))); // mad r2.xyz, r0.xxxx, r2.xyzx, r5.xyzx
    r2.xyz = value_235.xyz;
    uint4 value_236 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(r3.xyzx)); // add r3.xyz, -r2.xyzx, r3.xyzx
    r3.xyz = value_236.xyz;
    uint4 value_237 = asuint(mad(asfloat(r0.wwww), asfloat(r3.xxyz), asfloat(r2.xxyz))); // mad r0.xzw, r0.wwww, r3.xxyz, r2.xxyz
    r0.xzw = value_237.xzw;
    uint4 value_238 = asuint(asfloat(r0.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r0.xzw, r0.xxzw, -cb0[9].xxyz
    r0.xzw = value_238.xzw;
    uint4 value_239 = asuint(mad(asfloat(r0.yyyy), asfloat(r0.xzwx), asfloat(cb0[9].xyzx))); // mad r0.xyz, r0.yyyy, r0.xzwx, cb0[9].xyzx
    r0.xyz = value_239.xyz;
    uint4 value_240 = asuint(asfloat(r0.xyzx) * asfloat(r1.xyzx)); // mul r2.xyz, r0.xyzx, r1.xyzx
    r2.xyz = value_240.xyz;
    uint4 value_241 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r2.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_241.w;
    uint4 value_242 = asuint(mad(asfloat(r1.xyzx), asfloat(r0.xyzx), asfloat(asuint(-asfloat(r0.wwww))))); // mad r0.xyz, r1.xyzx, r0.xyzx, -r0.wwww
    r0.xyz = value_242.xyz;
    uint4 value_243 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r1.x, cb0[5].w, cb0[6].w
    r1.x = value_243.x;
    uint4 value_244 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r1.x, r1.x, l(0.500000)
    r1.x = value_244.x;
    uint4 value_245 = asuint(asfloat(r1.xxxx) * asfloat(cb0[29].xxxx)); // mul r1.x, r1.x, cb0[29].x
    r1.x = value_245.x;
    uint4 value_246 = asuint(mad(asfloat(r1.xxxx), asfloat(r0.xyzx), asfloat(r0.wwww))); // mad r0.xyz, r1.xxxx, r0.xyzx, r0.wwww
    r0.xyz = value_246.xyz;
    uint4 value_247 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_247.xyz;
    uint4 value_248 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_248.xyz;
    uint4 value_249 = asuint(mad(asfloat(r2.wwww), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r2.wwww, r2.xyzx, r1.xyzx
    r1.xyz = value_249.xyz;
    uint4 value_250 = asuint(asfloat(r2.wwww) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r2.wwww, cb0[5].xyzx
    r2.xyz = value_250.xyz;
    uint4 value_251 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_251.xyz;
    uint4 value_252 = asuint(mad(asfloat(r0.xyzx), asfloat(r1.xyzx), asfloat(r2.xyzx))); // mad r0.xyz, r0.xyzx, r1.xyzx, r2.xyzx
    r0.xyz = value_252.xyz;
    uint4 value_253 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add o3.xyz, r0.xyzx, l(0.100000, 0.100000, 0.100000, 0.000000)
    out_o3.xyz = value_253.xyz;
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
