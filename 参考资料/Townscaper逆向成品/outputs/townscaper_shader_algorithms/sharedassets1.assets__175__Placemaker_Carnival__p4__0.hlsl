// Register-explicit recovered HLSL. Not original source.
// Placemaker/Carnival vs_4_0 variant []
// Source SHA256 19f598f09b54928f8f0f8a6d2bbc05ce3e091aca2a5cf9d57259daa51241dd06
// b0: $Globals 704 bytes
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
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// cb3[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _AoTex
// t1 / s2 = _ShadowTex
// t2 / s1 = _VoxelTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
cbuffer Buffer1:register(b1) { uint4 cb1[1]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[21]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
SamplerState s2:register(s2);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
Texture2D<float4> t2:register(t2);
// temporary registers: 9
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: NORMAL0;
    float4 v3_0: TANGENT0;
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
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 out_o3;
    uint4 out_o4;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xyz = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(floor(asfloat(v1.yxyy))); // round_ni r0.xy, v1.yxyy
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(int4(asfloat(r0.xxxx))); // ftoi r0.x, r0.x
    r0.x = value_2.x;
    uint4 value_3 = asuint(asint(r0.xxxx) >> (uint4(0x1u, 0x1u, 0x1u, 0x1u) & 31u)); // ishr r1.x, r0.x, l(1)
    r1.x = value_3.x;
    uint4 value_4 = asuint(asint(r0.xxxx) >> (uint4(0x2u, 0x2u, 0x2u, 0x2u) & 31u)); // ishr r1.y, r0.x, l(2)
    r1.y = value_4.y;
    uint4 value_5 = (r0.xxxx & uint4(0x1u, 0x1u, 0x1u, 0x1u)); // and r0.x, r0.x, l(1)
    r0.x = value_5.x;
    uint4 value_6 = (r1.xxxy & uint4(0x0u, 0x0u, 0x1u, 0x1u)); // and r0.zw, r1.xxxy, l(0, 0, 1, 1)
    r0.zw = value_6.zw;
    uint4 value_7 = asuint(float4(asint(r0.xxzw))); // itof r0.xzw, r0.xxzw
    r0.xzw = value_7.xzw;
    uint4 value_8 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0xbbd4fdf4u, 0xbbd4fdf4u, 0xbbd4fdf4u, 0xbbd4fdf4u)), asfloat(uint4(0x3be56042u, 0x3be56042u, 0x3be56042u, 0x3be56042u)))); // mad r1.x, r0.x, l(-0.006500), l(0.007000)
    r1.x = value_8.x;
    uint4 value_9 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u))); // add r1.y, -r1.x, l(0.003000)
    r1.y = value_9.y;
    uint4 value_10 = asuint(mad(asfloat(r0.wwww), asfloat(r1.yyyy), asfloat(r1.xxxx))); // mad o0.w, r0.w, r1.y, r1.x
    out_o0.w = value_10.w;
    uint4 value_11 = asuint(asfloat(r0.zzzz) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.z, r0.z, l(-0.500000)
    r0.z = value_11.z;
    uint4 value_12 = asuint(frac(asfloat(v1.xyxx))); // frc o0.xy, v1.xyxx
    out_o0.xy = value_12.xy;
    uint4 value_13 = v1.xxxx; // mov o0.z, v1.x
    out_o0.z = value_13.z;
    uint4 value_14 = asuint(asfloat(v2.yyyy) * asfloat(cb2[1].xyzx)); // mul r1.xyz, v2.yyyy, cb2[1].xyzx
    r1.xyz = value_14.xyz;
    uint4 value_15 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v2.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb2[0].xyzx, v2.xxxx, r1.xyzx
    r1.xyz = value_15.xyz;
    uint4 value_16 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v2.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb2[2].xyzx, v2.zzzz, r1.xyzx
    r1.xyz = value_16.xyz;
    uint4 value_17 = asuint(asfloat(r0.zzzz) * asfloat(r1.xyzx)); // mul r2.xyz, r0.zzzz, r1.xyzx
    r2.xyz = value_17.xyz;
    uint4 value_18 = asuint(-asfloat(r2.xxxx)); // mov r2.w, -r2.x
    r2.w = value_18.w;
    uint4 value_19 = asuint(dot(asfloat(r2.zwzz).xy, asfloat(r2.zwzz).xy)).xxxx; // dp2 r0.z, r2.zwzz, r2.zwzz
    r0.z = value_19.z;
    uint4 value_20 = asuint(rsqrt(asfloat(r0.zzzz))); // rsq r0.z, r0.z
    r0.z = value_20.z;
    uint4 value_21 = asuint(asfloat(r0.zzzz) * asfloat(r2.zzzw)); // mul r0.zw, r0.zzzz, r2.zzzw
    r0.zw = value_21.zw;
    uint4 value_22 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzw)); // mul r3.xyzw, v0.yyyy, cb2[1].xyzw
    r3.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(mad(asfloat(cb2[0].xyzw), asfloat(v0.xxxx), asfloat(r3.xyzw))); // mad r3.xyzw, cb2[0].xyzw, v0.xxxx, r3.xyzw
    r3.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(mad(asfloat(cb2[2].xyzw), asfloat(v0.zzzz), asfloat(r3.xyzw))); // mad r3.xyzw, cb2[2].xyzw, v0.zzzz, r3.xyzw
    r3.xyzw = value_24.xyzw;
    uint4 value_25 = asuint(mad(asfloat(cb2[3].xyzw), asfloat(v0.wwww), asfloat(r3.xyzw))); // mad r3.xyzw, cb2[3].xyzw, v0.wwww, r3.xyzw
    r3.xyzw = value_25.xyzw;
    uint4 value_26 = asuint(dot(asfloat(r3.xzxx).xy, asfloat(r0.zwzz).xy)).xxxx; // dp2 r0.z, r3.xzxx, r0.zwzz
    r0.z = value_26.z;
    uint4 value_27 = asuint(asfloat(r0.zzzz) * asfloat(uint4(0x40c00000u, 0x40c00000u, 0x40c00000u, 0x40c00000u))); // mul r0.z, r0.z, l(6.000000)
    r0.z = value_27.z;
    uint4 value_28 = asuint(mad(asfloat(cb1[0].yyyy), asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u)), asfloat(r0.zzzz))); // mad r0.z, cb1[0].y, l(4.000000), r0.z
    r0.z = value_28.z;
    uint4 value_29 = asuint(asfloat(r3.xxxx) + asfloat(r0.zzzz)); // add r0.z, r3.x, r0.z
    r0.z = value_29.z;
    uint4 value_30 = asuint(asfloat(r3.zzzz) + asfloat(r0.zzzz)); // add r0.z, r3.z, r0.z
    r0.z = value_30.z;
    uint4 value_31 = asuint(asfloat(r0.zzzz) * asfloat(uint4(0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu))); // mul r0.w, r0.z, l(6.283185)
    r0.w = value_31.w;
    uint4 value_32 = ((asfloat(r0.wwww) >= asfloat(asuint(-asfloat(r0.wwww)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.w, r0.w, -r0.w
    r0.w = value_32.w;
    uint4 value_33 = ((r0.wwww != 0u) ? uint4(0x40c90fdbu, 0x3e22f983u, 0x0u, 0x0u) : uint4(0xc0c90fdbu, 0xbe22f983u, 0x0u, 0x0u)); // movc r4.xy, r0.wwww, l(6.283185,0.159155,0,0), l(-6.283185,-0.159155,0,0)
    r4.xy = value_33.xy;
    uint4 value_34 = asuint(asfloat(r0.zzzz) * asfloat(r4.yyyy)); // mul r0.z, r0.z, r4.y
    r0.z = value_34.z;
    uint4 value_35 = asuint(frac(asfloat(r0.zzzz))); // frc r0.z, r0.z
    r0.z = value_35.z;
    uint4 value_36 = asuint(asfloat(r0.zzzz) * asfloat(r4.xxxx)); // mul r0.z, r0.z, r4.x
    r0.z = value_36.z;
    uint4 value_37 = asuint(mad(asfloat(r0.yyyy), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x3e99999au)), asfloat(r0.zzzz))); // mad r0.y, r0.y, l(0.300000), r0.z
    r0.y = value_37.y;
    uint4 value_38s = asuint(sin(asfloat(r0.zzzz))); // sincos r0.z, null, r0.z
    r0.z = value_38s.z;
    uint4 value_39 = asuint(asfloat(r0.zzzz) * asfloat(r2.xyzx)); // mul r4.xyz, r0.zzzz, r2.xyzx
    r4.xyz = value_39.xyz;
    uint4 value_40c = asuint(cos(asfloat(r0.yyyy))); // sincos null, r0.y, r0.y
    r0.y = value_40c.y;
    uint4 value_41 = asuint(asfloat(r0.yyyy) * asfloat(r2.zzyw)); // mul r0.yzw, r0.yyyy, r2.zzyw
    r0.yzw = value_41.yzw;
    uint4 value_42 = asuint(asfloat(r3.yyyy) + asfloat(uint4(0x3f000000u, 0xbf000000u, 0x0u, 0x0u))); // add r2.xy, r3.yyyy, l(0.500000, -0.500000, 0.000000, 0.000000)
    r2.xy = value_42.xy;
    uint4 value_43 = asuint(max(asfloat(r2.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r2.y, l(0.000000)
    r1.w = value_43.w;
    uint4 value_44 = asuint(saturate(asfloat(r2.xxxx))); // mov_sat r2.x, r2.x
    r2.x = value_44.x;
    uint4 value_45 = asuint(floor(asfloat(r1.wwww))); // round_ni r2.y, r1.w
    r2.y = value_45.y;
    uint4 value_46 = asuint(frac(asfloat(r1.wwww))); // frc r1.w, r1.w
    r1.w = value_46.w;
    uint4 value_47 = asuint(int4(asfloat(r2.yyyy))); // ftoi r2.z, r2.y
    r2.z = value_47.z;
    uint4 value_48 = (r2.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.w, r2.z, l(1)
    r2.w = value_48.w;
    uint4 value_49 = asuint(float4(asint(r2.wwww))); // itof r4.w, r2.w
    r4.w = value_49.w;
    uint4 value_50 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r5.x, cb0[2].w
    r5.x = value_50.x;
    uint4 value_51 = uint4(asfloat(r5.xxxx)); // ftou r5.x, r5.x
    r5.x = value_51.x;
    uint4 value_52 = asuint(float4(r5.xxxx)); // utof r5.y, r5.x
    r5.y = value_52.y;
    uint4 value_53 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r5.yyyy)); // div r5.y, l(1.000000, 1.000000, 1.000000, 1.000000), r5.y
    r5.y = value_53.y;
    uint4 value_54 = asuint(asfloat(r4.wwww) * asfloat(r5.yyyy)); // mul r4.w, r4.w, r5.y
    r4.w = value_54.w;
    uint4 value_55 = asuint(int4(asfloat(r4.wwww))); // ftoi r5.z, r4.w
    r5.z = value_55.z;
    uint4 value_56 = asuint(trunc(asfloat(r4.wwww))); // round_z r4.w, r4.w
    r4.w = value_56.w;
    uint4 value_57 = (asuint(-asint(r5.zzzz)) * r5.xxxx + r2.wwww); // imad r2.w, -r5.z, r5.x, r2.w
    r2.w = value_57.w;
    uint4 value_58 = asuint(float4(r2.wwww)); // utof r2.w, r2.w
    r2.w = value_58.w;
    uint4 value_59 = asuint(asfloat(r3.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r5.zw, r3.xxxz, -cb0[3].xxxy
    r5.zw = value_59.zw;
    uint4 value_60 = asuint(asfloat(r5.zzzw) * asfloat(cb0[2].zzzz)); // mul r5.zw, r5.zzzw, cb0[2].zzzz
    r5.zw = value_60.zw;
    uint4 value_61 = asuint(max(asfloat(r5.zzzw), asfloat(cb0[7].xxxy))); // max r5.zw, r5.zzzw, cb0[7].xxxy
    r5.zw = value_61.zw;
    uint4 value_62 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r6.xy, cb0[2].xyxx, -cb0[7].xyxx
    r6.xy = value_62.xy;
    uint4 value_63 = asuint(min(asfloat(r5.zzzw), asfloat(r6.xxxy))); // min r5.zw, r5.zzzw, r6.xxxy
    r5.zw = value_63.zw;
    uint4 value_64 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.wwww), asfloat(r5.zzzz))); // mad r7.x, cb0[2].x, r2.w, r5.z
    r7.x = value_64.x;
    uint4 value_65 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r4.wwww), asfloat(r5.wwww))); // mad r7.y, cb0[2].y, r4.w, r5.w
    r7.y = value_65.y;
    uint4 value_66 = asuint(t2.SampleLevel(s1, asfloat(r7.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r7.xyxx, t2.xyzw, s1, l(0.000000)
    r7.xyzw = value_66.xyzw;
    uint4 value_67 = asuint(asfloat(r2.yyyy) * asfloat(r5.yyyy)); // mul r2.y, r2.y, r5.y
    r2.y = value_67.y;
    uint4 value_68 = asuint(int4(asfloat(r2.yyyy))); // ftoi r2.w, r2.y
    r2.w = value_68.w;
    uint4 value_69 = asuint(trunc(asfloat(r2.yyyy))); // round_z r2.y, r2.y
    r2.y = value_69.y;
    uint4 value_70 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.yyyy), asfloat(r5.wwww))); // mad r7.y, cb0[2].y, r2.y, r5.w
    r7.y = value_70.y;
    uint4 value_71 = (asuint(-asint(r2.wwww)) * r5.xxxx + r2.zzzz); // imad r2.y, -r2.w, r5.x, r2.z
    r2.y = value_71.y;
    uint4 value_72 = asuint(float4(r2.yyyy)); // utof r2.y, r2.y
    r2.y = value_72.y;
    uint4 value_73 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.yyyy), asfloat(r5.zzzz))); // mad r7.x, cb0[2].x, r2.y, r5.z
    r7.x = value_73.x;
    uint4 value_74 = asuint(t2.SampleLevel(s1, asfloat(r7.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r7.xyxx, t2.xyzw, s1, l(0.000000)
    r8.xyzw = value_74.xyzw;
    uint4 value_75 = asuint(asfloat(r7.wwww) + asfloat(asuint(-asfloat(r8.wwww)))); // add r2.y, r7.w, -r8.w
    r2.y = value_75.y;
    uint4 value_76 = asuint(mad(asfloat(r1.wwww), asfloat(r2.yyyy), asfloat(r8.wwww))); // mad r1.w, r1.w, r2.y, r8.w
    r1.w = value_76.w;
    uint4 value_77 = asuint(asfloat(r1.wwww) + asfloat(asuint(-asfloat(cb0[9].wwww)))); // add r1.w, r1.w, -cb0[9].w
    r1.w = value_77.w;
    uint4 value_78 = asuint(mad(asfloat(r2.xxxx), asfloat(r1.wwww), asfloat(cb0[9].wwww))); // mad r1.w, r2.x, r1.w, cb0[9].w
    r1.w = value_78.w;
    uint4 value_79 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.wwww), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))))))); // mad_sat r1.w, r1.w, l(2.000000), l(-1.000000)
    r1.w = value_79.w;
    uint4 value_80 = asuint(asfloat(r1.wwww) * asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu))); // mul r1.w, r1.w, l(0.050000)
    r1.w = value_80.w;
    uint4 value_81 = asuint(asfloat(r0.xxxx) * asfloat(r1.wwww)); // mul r0.x, r0.x, r1.w
    r0.x = value_81.x;
    uint4 value_82 = asuint(asfloat(r0.xxxx) * asfloat(r0.yyzw)); // mul r0.yzw, r0.xxxx, r0.yyzw
    r0.yzw = value_82.yzw;
    uint4 value_83 = asuint(mad(asfloat(r4.xyzx), asfloat(r0.xxxx), asfloat(r3.xyzx))); // mad r2.xyz, r4.xyzx, r0.xxxx, r3.xyzx
    r2.xyz = value_83.xyz;
    uint4 value_84 = asuint(mad(asfloat(r0.yzwy), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r2.xyzx))); // mad r0.xyz, r0.yzwy, l(0.400000, 0.400000, 0.400000, 0.000000), r2.xyzx
    r0.xyz = value_84.xyz;
    uint4 value_85 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r2.xyz, r0.xyzx, -cb0[22].xyzx
    r2.xyz = value_85.xyz;
    uint4 value_86 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r2.xyzx).xyz)).xxxx; // dp3 r0.w, r2.xyzx, r2.xyzx
    r0.w = value_86.w;
    uint4 value_87 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_87.w;
    uint4 value_88 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_88.w;
    uint4 value_89 = asuint(asfloat(r0.wwww) * asfloat(r2.xyzx)); // mul r2.xyz, r0.wwww, r2.xyzx
    r2.xyz = value_89.xyz;
    uint4 value_90 = asuint(mad(asfloat(r2.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r0.w, r2.y, cb0[22].w, r0.y
    r0.w = value_90.w;
    uint4 value_91 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_91.w;
    uint4 value_92 = asuint(mad(asfloat(r2.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r4.w, r2.y, cb0[22].w, -r0.w
    r4.w = value_92.w;
    uint4 value_93 = asuint(asfloat(r2.xxzx) * asfloat(cb0[22].wwww)); // mul r4.xz, r2.xxzx, cb0[22].wwww
    r4.xz = value_93.xz;
    uint4 value_94 = asuint(asfloat(r0.xyzx) + asfloat(r4.xwzx)); // add r0.xyz, r0.xyzx, r4.xwzx
    r0.xyz = value_94.xyz;
    uint4 value_95 = asuint(asfloat(r0.yyyy) * asfloat(cb3[10].xyxx)); // mul r2.xy, r0.yyyy, cb3[10].xyxx
    r2.xy = value_95.xy;
    uint4 value_96 = asuint(mad(asfloat(cb3[9].xyxx), asfloat(r0.xxxx), asfloat(r2.xyxx))); // mad r2.xy, cb3[9].xyxx, r0.xxxx, r2.xyxx
    r2.xy = value_96.xy;
    uint4 value_97 = asuint(mad(asfloat(cb3[11].xyxx), asfloat(r0.zzzz), asfloat(r2.xyxx))); // mad r2.xy, cb3[11].xyxx, r0.zzzz, r2.xyxx
    r2.xy = value_97.xy;
    uint4 value_98 = asuint(mad(asfloat(cb3[12].xyxx), asfloat(r3.wwww), asfloat(r2.xyxx))); // mad o1.xy, cb3[12].xyxx, r3.wwww, r2.xyxx
    out_o1.xy = value_98.xy;
    uint4 value_99 = asuint(asfloat(r0.yyyy) * asfloat(cb3[18].xyzw)); // mul r2.xyzw, r0.yyyy, cb3[18].xyzw
    r2.xyzw = value_99.xyzw;
    uint4 value_100 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r0.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[17].xyzw, r0.xxxx, r2.xyzw
    r2.xyzw = value_100.xyzw;
    uint4 value_101 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r0.zzzz), asfloat(r2.xyzw))); // mad r0.xyzw, cb3[19].xyzw, r0.zzzz, r2.xyzw
    r0.xyzw = value_101.xyzw;
    uint4 value_102 = asuint(asfloat(r0.xyzw) + asfloat(cb3[20].xyzw)); // add o2.xyzw, r0.xyzw, cb3[20].xyzw
    out_o2.xyzw = value_102.xyzw;
    uint4 value_103 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r3.xyzx))); // mad r0.xyz, r1.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000), r3.xyzx
    r0.xyz = value_103.xyz;
    uint4 value_104 = asuint(asfloat(r0.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r0.xz, r0.xxzx, -cb0[3].xxyx
    r0.xz = value_104.xz;
    uint4 value_105 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r0.yw, r0.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r0.yw = value_105.yw;
    uint4 value_106 = asuint(asfloat(r0.xxzx) * asfloat(cb0[2].zzzz)); // mul r0.xz, r0.xxzx, cb0[2].zzzz
    r0.xz = value_106.xz;
    uint4 value_107 = asuint(max(asfloat(r0.xxzx), asfloat(cb0[7].xxyx))); // max r0.xz, r0.xxzx, cb0[7].xxyx
    r0.xz = value_107.xz;
    uint4 value_108 = asuint(min(asfloat(r6.xxyx), asfloat(r0.xxzx))); // min r0.xz, r6.xxyx, r0.xxzx
    r0.xz = value_108.xz;
    uint4 value_109 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_109.w;
    uint4 value_110 = asuint(saturate(asfloat(r0.yyyy))); // mov_sat r0.y, r0.y
    r0.y = value_110.y;
    uint4 value_111 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.w, r0.w
    r1.w = value_111.w;
    uint4 value_112 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_112.w;
    uint4 value_113 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.x, r1.w
    r2.x = value_113.x;
    uint4 value_114 = asuint(asfloat(r5.yyyy) * asfloat(r1.wwww)); // mul r1.w, r5.y, r1.w
    r1.w = value_114.w;
    uint4 value_115 = (r2.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.y, r2.x, l(1)
    r2.y = value_115.y;
    uint4 value_116 = asuint(float4(asint(r2.yyyy))); // itof r2.z, r2.y
    r2.z = value_116.z;
    uint4 value_117 = asuint(asfloat(r5.yyyy) * asfloat(r2.zzzz)); // mul r2.z, r5.y, r2.z
    r2.z = value_117.z;
    uint4 value_118 = asuint(int4(asfloat(r2.zzzz))); // ftoi r2.w, r2.z
    r2.w = value_118.w;
    uint4 value_119 = asuint(trunc(asfloat(r2.zzzz))); // round_z r2.z, r2.z
    r2.z = value_119.z;
    uint4 value_120 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.zzzz), asfloat(r0.zzzz))); // mad r4.y, cb0[2].y, r2.z, r0.z
    r4.y = value_120.y;
    uint4 value_121 = (asuint(-asint(r2.wwww)) * r5.xxxx + r2.yyyy); // imad r2.y, -r2.w, r5.x, r2.y
    r2.y = value_121.y;
    uint4 value_122 = asuint(float4(r2.yyyy)); // utof r2.y, r2.y
    r2.y = value_122.y;
    uint4 value_123 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.yyyy), asfloat(r0.xxxx))); // mad r4.x, cb0[2].x, r2.y, r0.x
    r4.x = value_123.x;
    uint4 value_124 = asuint(t0.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r4.xyxx, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_124.xyzw;
    uint4 value_125 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.y, r4.y, l(1.000000)
    r2.y = value_125.y;
    uint4 value_126 = (r2.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.y, r2.y, l(0x3f800000)
    r2.y = value_126.y;
    uint4 value_127 = asuint(asfloat(asuint(-asfloat(r7.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r7.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_127.xyz;
    uint4 value_128 = asuint(mad(asfloat(r2.yyyy), asfloat(r4.xxyz), asfloat(r7.xxyz))); // mad r2.yzw, r2.yyyy, r4.xxyz, r7.xxyz
    r2.yzw = value_128.yzw;
    uint4 value_129 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.w, r1.w
    r3.w = value_129.w;
    uint4 value_130 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_130.w;
    uint4 value_131 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r0.zzzz))); // mad r4.y, cb0[2].y, r1.w, r0.z
    r4.y = value_131.y;
    uint4 value_132 = (asuint(-asint(r3.wwww)) * r5.xxxx + r2.xxxx); // imad r0.z, -r3.w, r5.x, r2.x
    r0.z = value_132.z;
    uint4 value_133 = asuint(float4(r0.zzzz)); // utof r0.z, r0.z
    r0.z = value_133.z;
    uint4 value_134 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.zzzz), asfloat(r0.xxxx))); // mad r4.x, cb0[2].x, r0.z, r0.x
    r4.x = value_134.x;
    uint4 value_135 = asuint(t0.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r4.xyxx, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_135.xyzw;
    uint4 value_136 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, r4.y, l(1.000000)
    r0.x = value_136.x;
    uint4 value_137 = (r0.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.x, r0.x, l(0x3f800000)
    r0.x = value_137.x;
    uint4 value_138 = asuint(asfloat(asuint(-asfloat(r7.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r7.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_138.xyz;
    uint4 value_139 = asuint(mad(asfloat(r0.xxxx), asfloat(r4.xyzx), asfloat(r7.xyzx))); // mad r4.xyz, r0.xxxx, r4.xyzx, r7.xyzx
    r4.xyz = value_139.xyz;
    uint4 value_140 = asuint(asfloat(r2.yzwy) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r2.xyz, r2.yzwy, -r4.xyzx
    r2.xyz = value_140.xyz;
    uint4 value_141 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xxyz), asfloat(r4.xxyz))); // mad r0.xzw, r0.wwww, r2.xxyz, r4.xxyz
    r0.xzw = value_141.xzw;
    uint4 value_142 = asuint(asfloat(r0.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r0.xzw, r0.xxzw, -cb0[9].xxyz
    r0.xzw = value_142.xzw;
    uint4 value_143 = asuint(mad(asfloat(r0.yyyy), asfloat(r0.xzwx), asfloat(cb0[9].xyzx))); // mad r0.xyz, r0.yyyy, r0.xzwx, cb0[9].xyzx
    r0.xyz = value_143.xyz;
    uint4 value_144 = asuint(asfloat(r1.xyzx) + asfloat(r3.xyzx)); // add r2.xyz, r1.xyzx, r3.xyzx
    r2.xyz = value_144.xyz;
    uint4 value_145 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.w, r1.xyzx, -cb0[4].xyzx
    r0.w = value_145.w;
    uint4 value_146 = asuint(asfloat(r2.yyyy) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r1.xy, r2.yyyy, l(0.700000, -0.300000, 0.000000, 0.000000)
    r1.xy = value_146.xy;
    uint4 value_147 = asuint(asfloat(r2.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r1.zw, r2.xxxz, -cb0[3].xxxy
    r1.zw = value_147.zw;
    uint4 value_148 = asuint(asfloat(r1.zzzw) * asfloat(cb0[2].zzzz)); // mul r1.zw, r1.zzzw, cb0[2].zzzz
    r1.zw = value_148.zw;
    uint4 value_149 = asuint(max(asfloat(r1.zzzw), asfloat(cb0[7].xxxy))); // max r1.zw, r1.zzzw, cb0[7].xxxy
    r1.zw = value_149.zw;
    uint4 value_150 = asuint(min(asfloat(r6.xxxy), asfloat(r1.zzzw))); // min r1.zw, r6.xxxy, r1.zzzw
    r1.zw = value_150.zw;
    uint4 value_151 = asuint(max(asfloat(r1.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.y, r1.y, l(0.000000)
    r1.y = value_151.y;
    uint4 value_152 = asuint(saturate(asfloat(r1.xxxx))); // mov_sat r1.x, r1.x
    r1.x = value_152.x;
    uint4 value_153 = asuint(floor(asfloat(r1.yyyy))); // round_ni r2.x, r1.y
    r2.x = value_153.x;
    uint4 value_154 = asuint(frac(asfloat(r1.yyyy))); // frc r1.y, r1.y
    r1.y = value_154.y;
    uint4 value_155 = asuint(int4(asfloat(r2.xxxx))); // ftoi r2.y, r2.x
    r2.y = value_155.y;
    uint4 value_156 = (r2.yyyy + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.z, r2.y, l(1)
    r2.z = value_156.z;
    uint4 value_157 = asuint(float4(asint(r2.zzzz))); // itof r2.w, r2.z
    r2.w = value_157.w;
    uint4 value_158 = asuint(asfloat(r5.yyyy) * asfloat(r2.xxxw)); // mul r2.xw, r5.yyyy, r2.xxxw
    r2.xw = value_158.xw;
    uint4 value_159 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.w, r2.w
    r3.w = value_159.w;
    uint4 value_160 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_160.w;
    uint4 value_161 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r1.wwww))); // mad r4.y, cb0[2].y, r2.w, r1.w
    r4.y = value_161.y;
    uint4 value_162 = (asuint(-asint(r3.wwww)) * r5.xxxx + r2.zzzz); // imad r2.z, -r3.w, r5.x, r2.z
    r2.z = value_162.z;
    uint4 value_163 = asuint(float4(r2.zzzz)); // utof r2.z, r2.z
    r2.z = value_163.z;
    uint4 value_164 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.zzzz), asfloat(r1.zzzz))); // mad r4.x, cb0[2].x, r2.z, r1.z
    r4.x = value_164.x;
    uint4 value_165 = asuint(t0.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r4.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_165.xyzw;
    uint4 value_166 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.z, r4.y, l(1.000000)
    r2.z = value_166.z;
    uint4 value_167 = (r2.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.z, r2.z, l(0x3f800000)
    r2.z = value_167.z;
    uint4 value_168 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_168.xyz;
    uint4 value_169 = asuint(mad(asfloat(r2.zzzz), asfloat(r4.xyzx), asfloat(r6.xyzx))); // mad r4.xyz, r2.zzzz, r4.xyzx, r6.xyzx
    r4.xyz = value_169.xyz;
    uint4 value_170 = asuint(int4(asfloat(r2.xxxx))); // ftoi r2.z, r2.x
    r2.z = value_170.z;
    uint4 value_171 = asuint(trunc(asfloat(r2.xxxx))); // round_z r2.x, r2.x
    r2.x = value_171.x;
    uint4 value_172 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.xxxx), asfloat(r1.wwww))); // mad r6.y, cb0[2].y, r2.x, r1.w
    r6.y = value_172.y;
    uint4 value_173 = (asuint(-asint(r2.zzzz)) * r5.xxxx + r2.yyyy); // imad r1.w, -r2.z, r5.x, r2.y
    r1.w = value_173.w;
    uint4 value_174 = asuint(float4(r1.wwww)); // utof r1.w, r1.w
    r1.w = value_174.w;
    uint4 value_175 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.wwww), asfloat(r1.zzzz))); // mad r6.x, cb0[2].x, r1.w, r1.z
    r6.x = value_175.x;
    uint4 value_176 = asuint(t0.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r6.xyxx, t0.xyzw, s0, l(0.000000)
    r2.xyzw = value_176.xyzw;
    uint4 value_177 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.z, r6.y, l(1.000000)
    r1.z = value_177.z;
    uint4 value_178 = (r1.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.z, r1.z, l(0x3f800000)
    r1.z = value_178.z;
    uint4 value_179 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r2.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_179.xyz;
    uint4 value_180 = asuint(mad(asfloat(r1.zzzz), asfloat(r5.xyzx), asfloat(r2.xyzx))); // mad r2.xyz, r1.zzzz, r5.xyzx, r2.xyzx
    r2.xyz = value_180.xyz;
    uint4 value_181 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(r4.xyzx)); // add r4.xyz, -r2.xyzx, r4.xyzx
    r4.xyz = value_181.xyz;
    uint4 value_182 = asuint(mad(asfloat(r1.yyyy), asfloat(r4.xxyz), asfloat(r2.xxyz))); // mad r1.yzw, r1.yyyy, r4.xxyz, r2.xxyz
    r1.yzw = value_182.yzw;
    uint4 value_183 = asuint(asfloat(r1.yyzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r1.yzw, r1.yyzw, -cb0[9].xxyz
    r1.yzw = value_183.yzw;
    uint4 value_184 = asuint(mad(asfloat(r1.xxxx), asfloat(r1.yzwy), asfloat(cb0[9].xyzx))); // mad r1.xyz, r1.xxxx, r1.yzwy, cb0[9].xyzx
    r1.xyz = value_184.xyz;
    uint4 value_185 = asuint(asfloat(r0.xyzx) * asfloat(r1.xyzx)); // mul r2.xyz, r0.xyzx, r1.xyzx
    r2.xyz = value_185.xyz;
    uint4 value_186 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r2.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_186.w;
    uint4 value_187 = asuint(mad(asfloat(r0.xyzx), asfloat(r1.xyzx), asfloat(asuint(-asfloat(r1.wwww))))); // mad r0.xyz, r0.xyzx, r1.xyzx, -r1.wwww
    r0.xyz = value_187.xyz;
    uint4 value_188 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r1.x, cb0[5].w, cb0[6].w
    r1.x = value_188.x;
    uint4 value_189 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r1.x, r1.x, l(0.500000)
    r1.x = value_189.x;
    uint4 value_190 = asuint(asfloat(r1.xxxx) * asfloat(cb0[29].xxxx)); // mul r1.x, r1.x, cb0[29].x
    r1.x = value_190.x;
    uint4 value_191 = asuint(mad(asfloat(r1.xxxx), asfloat(r0.xyzx), asfloat(r1.wwww))); // mad r0.xyz, r1.xxxx, r0.xyzx, r1.wwww
    r0.xyz = value_191.xyz;
    uint4 value_192 = asuint(asfloat(r3.yyyy) * asfloat(cb0[31].xyzx)); // mul r1.xyz, r3.yyyy, cb0[31].xyzx
    r1.xyz = value_192.xyz;
    uint4 value_193 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r3.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb0[30].xyzx, r3.xxxx, r1.xyzx
    r1.xyz = value_193.xyz;
    uint4 value_194 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r3.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb0[32].xyzx, r3.zzzz, r1.xyzx
    r1.xyz = value_194.xyz;
    uint4 value_195 = asuint(asfloat(r1.xyzx) + asfloat(cb0[33].xyzx)); // add r1.xyz, r1.xyzx, cb0[33].xyzx
    r1.xyz = value_195.xyz;
    uint4 value_196 = asuint(asfloat(r1.xyxx) * asfloat(cb0[39].zwzz)); // mul r2.xy, r1.xyxx, cb0[39].zwzz
    r2.xy = value_196.xy;
    uint4 value_197 = asuint(frac(asfloat(r2.xxxy))); // frc r2.zw, r2.xxxy
    r2.zw = value_197.zw;
    uint4 value_198 = asuint(asfloat(r0.wwww) * asfloat(cb0[38].yyyy)); // mul r1.w, r0.w, cb0[38].y
    r1.w = value_198.w;
    uint4 value_199 = asuint(saturate(asfloat(r0.wwww))); // mov_sat r0.w, r0.w
    r0.w = value_199.w;
    uint4 value_200 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_200.w;
    uint4 value_201 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r1.zzzz))); // mad r1.z, -r1.w, l(0.050000), r1.z
    r1.z = value_201.z;
    uint4 value_202 = r1.xyxx; // mov o4.xy, r1.xyxx
    out_o4.xy = value_202.xy;
    uint4 value_203 = asuint(asfloat(r1.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r1.z, r1.z, l(-0.003922)
    r1.z = value_203.z;
    uint4 value_204 = asuint(asfloat(r2.xxxy) * asfloat(cb0[39].xxxy)); // mul r3.zw, r2.xxxy, cb0[39].xxxy
    r3.zw = value_204.zw;
    uint4 value_205 = asuint(mad(asfloat(r2.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r3.xy, r2.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r3.xy = value_205.xy;
    uint4 value_206 = asuint(t1.SampleLevel(s2, asfloat(r3.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.zyzz, t1.xyzw, s2, l(0.000000)
    r4.xyzw = value_206.xyzw;
    uint4 value_207 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r1.zzzz, -r4.xyzx
    r4.xyz = value_207.xyz;
    uint4 value_208 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r1.x, cb0[38].x, l(20.000000)
    r1.x = value_208.x;
    uint4 value_209 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r1.xxxx, r4.xyzx
    r4.xyz = value_209.xyz;
    uint4 value_210 = asuint(asfloat(asuint(-asfloat(r2.zwzz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r2.xy, -r2.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
    r2.xy = value_210.xy;
    uint4 value_211 = asuint(asfloat(r2.xxxx) * asfloat(r4.xyzx)); // mul r4.xyz, r2.xxxx, r4.xyzx
    r4.xyz = value_211.xyz;
    uint4 value_212 = asuint(asfloat(r2.wwww) * asfloat(r4.xyzx)); // mul r4.xyz, r2.wwww, r4.xyzx
    r4.xyz = value_212.xyz;
    uint4 value_213 = asuint(t1.SampleLevel(s2, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t1.xyzw, s2, l(0.000000)
    r5.xyzw = value_213.xyzw;
    uint4 value_214 = asuint(t1.SampleLevel(s2, asfloat(r3.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r3.xwxx, t1.xyzw, s2, l(0.000000)
    r6.xyzw = value_214.xyzw;
    uint4 value_215 = asuint(t1.SampleLevel(s2, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.xyxx, t1.xyzw, s2, l(0.000000)
    r3.xyzw = value_215.xyzw;
    uint4 value_216 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r3.xyz, r1.zzzz, -r3.xyzx
    r3.xyz = value_216.xyz;
    uint4 value_217 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r3.xyzx))))); // mul_sat r3.xyz, r1.xxxx, r3.xyzx
    r3.xyz = value_217.xyz;
    uint4 value_218 = asuint(asfloat(r2.zzzz) * asfloat(r3.xyzx)); // mul r3.xyz, r2.zzzz, r3.xyzx
    r3.xyz = value_218.xyz;
    uint4 value_219 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r1.zzzz, -r6.xyzx
    r6.xyz = value_219.xyz;
    uint4 value_220 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r1.xxxx, r6.xyzx
    r6.xyz = value_220.xyz;
    uint4 value_221 = asuint(asfloat(r2.zzzz) * asfloat(r6.xyzx)); // mul r6.xyz, r2.zzzz, r6.xyzx
    r6.xyz = value_221.xyz;
    uint4 value_222 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r1.zzzz, -r5.xyzx
    r5.xyz = value_222.xyz;
    uint4 value_223 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r1.xxxx, r5.xyzx
    r5.xyz = value_223.xyz;
    uint4 value_224 = asuint(asfloat(r2.xxxx) * asfloat(r5.xyzx)); // mul r5.xyz, r2.xxxx, r5.xyzx
    r5.xyz = value_224.xyz;
    uint4 value_225 = asuint(mad(asfloat(r5.xyzx), asfloat(r2.yyyy), asfloat(r4.xyzx))); // mad r4.xyz, r5.xyzx, r2.yyyy, r4.xyzx
    r4.xyz = value_225.xyz;
    uint4 value_226 = asuint(mad(asfloat(r6.xyzx), asfloat(r2.yyyy), asfloat(r4.xyzx))); // mad r2.xyz, r6.xyzx, r2.yyyy, r4.xyzx
    r2.xyz = value_226.xyz;
    uint4 value_227 = asuint(mad(asfloat(r3.xyzx), asfloat(r2.wwww), asfloat(r2.xyzx))); // mad r2.xyz, r3.xyzx, r2.wwww, r2.xyzx
    r2.xyz = value_227.xyz;
    uint4 value_228 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r1.x, r2.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r1.x = value_228.x;
    uint4 value_229 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.x, l(1.000000)
    r1.x = value_229.x;
    uint4 value_230 = asuint(asfloat(r0.wwww) * asfloat(r0.wwww)); // mul r1.y, r0.w, r0.w
    r1.y = value_230.y;
    uint4 value_231 = asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(r1.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r1.w, -r0.w, r1.y, l(1.000000)
    r1.w = value_231.w;
    uint4 value_232 = asuint(asfloat(r1.wwww) * asfloat(r1.xxxx)); // mul r0.w, r1.w, r1.x
    r0.w = value_232.w;
    uint4 value_233 = r1.zzzw; // mov o4.zw, r1.zzzw
    out_o4.zw = value_233.zw;
    uint4 value_234 = asuint(asfloat(r0.wwww) * asfloat(cb0[5].wwww)); // mul r0.w, r0.w, cb0[5].w
    r0.w = value_234.w;
    uint4 value_235 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_235.xyz;
    uint4 value_236 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_236.xyz;
    uint4 value_237 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r0.wwww, r2.xyzx, r1.xyzx
    r1.xyz = value_237.xyz;
    uint4 value_238 = asuint(asfloat(r0.wwww) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.wwww, cb0[5].xyzx
    r2.xyz = value_238.xyz;
    uint4 value_239 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_239.xyz;
    uint4 value_240 = asuint(mad(asfloat(r0.xyzx), asfloat(r1.xyzx), asfloat(r2.xyzx))); // mad r0.xyz, r0.xyzx, r1.xyzx, r2.xyzx
    r0.xyz = value_240.xyz;
    uint4 value_241 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add o3.xyz, r0.xyzx, l(0.100000, 0.100000, 0.100000, 0.000000)
    out_o3.xyz = value_241.xyz;
    uint4 value_242 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.x, cb0[5].w, -cb0[6].w
    r0.x = value_242.x;
    uint4 value_243 = asuint(mad(asfloat(r0.wwww), asfloat(r0.xxxx), asfloat(cb0[6].wwww))); // mad o3.w, r0.w, r0.x, cb0[6].w
    out_o3.w = value_243.w;
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
