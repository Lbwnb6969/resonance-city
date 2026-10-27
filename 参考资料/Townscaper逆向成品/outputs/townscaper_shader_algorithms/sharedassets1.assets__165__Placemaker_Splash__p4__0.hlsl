// Register-explicit recovered HLSL. Not original source.
// Placemaker/Splash vs_4_0 variant []
// Source SHA256 d894c685036be1cab99d1f7d61c9610effdfc9303fd0e40a0857f8b0879f75ed
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
// cb1[0].x = _Time rows=1 cols=4 byte_offset=0
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
// temporary registers: 10
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
    uint4 r8;
    uint4 r9;
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
    uint4 value_2 = v3.xxxx; // mov o0.z, v3.x
    out_o0.z = value_2.z;
    uint4 value_3 = asuint(asfloat(cb1[0].yyyy) * asfloat(uint4(0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu))); // mul r0.x, cb1[0].y, l(6.283185)
    r0.x = value_3.x;
    uint4 value_4 = ((asfloat(r0.xxxx) >= asfloat(asuint(-asfloat(r0.xxxx)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, r0.x, -r0.x
    r0.x = value_4.x;
    uint4 value_5 = ((r0.xxxx != 0u) ? uint4(0x40c90fdbu, 0x3e22f983u, 0x0u, 0x0u) : uint4(0xc0c90fdbu, 0xbe22f983u, 0x0u, 0x0u)); // movc r0.xy, r0.xxxx, l(6.283185,0.159155,0,0), l(-6.283185,-0.159155,0,0)
    r0.xy = value_5.xy;
    uint4 value_6 = asuint(asfloat(r0.yyyy) * asfloat(cb1[0].yyyy)); // mul r0.y, r0.y, cb1[0].y
    r0.y = value_6.y;
    uint4 value_7 = asuint(frac(asfloat(r0.yyyy))); // frc r0.y, r0.y
    r0.y = value_7.y;
    uint4 value_8 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzx)); // mul r1.xyz, v0.yyyy, cb2[1].xyzx
    r1.xyz = value_8.xyz;
    uint4 value_9 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v0.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb2[0].xyzx, v0.xxxx, r1.xyzx
    r1.xyz = value_9.xyz;
    uint4 value_10 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v0.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb2[2].xyzx, v0.zzzz, r1.xyzx
    r1.xyz = value_10.xyz;
    uint4 value_11 = asuint(mad(asfloat(cb2[3].xyzx), asfloat(v0.wwww), asfloat(r1.xyzx))); // mad r1.xyz, cb2[3].xyzx, v0.wwww, r1.xyzx
    r1.xyz = value_11.xyz;
    uint4 value_12 = asuint(asfloat(r1.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r2.xyz, r1.xyzx, -cb0[22].xyzx
    r2.xyz = value_12.xyz;
    uint4 value_13 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r2.xyzx).xyz)).xxxx; // dp3 r0.z, r2.xyzx, r2.xyzx
    r0.z = value_13.z;
    uint4 value_14 = asuint(asfloat(asuint(-asfloat(r0.zzzz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.z, -r0.z, l(1.000000)
    r0.z = value_14.z;
    uint4 value_15 = asuint(max(asfloat(r0.zzzz), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.z, r0.z, l(0.000000)
    r0.z = value_15.z;
    uint4 value_16 = asuint(asfloat(r0.zzzz) * asfloat(r2.xyzx)); // mul r2.xyz, r0.zzzz, r2.xyzx
    r2.xyz = value_16.xyz;
    uint4 value_17 = asuint(mad(asfloat(r2.yyyy), asfloat(cb0[22].wwww), asfloat(r1.yyyy))); // mad r0.z, r2.y, cb0[22].w, r1.y
    r0.z = value_17.z;
    uint4 value_18 = asuint(min(asfloat(r0.zzzz), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.z, r0.z, l(0.000000)
    r0.z = value_18.z;
    uint4 value_19 = asuint(mad(asfloat(r2.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.zzzz))))); // mad r3.w, r2.y, cb0[22].w, -r0.z
    r3.w = value_19.w;
    uint4 value_20 = asuint(asfloat(r2.xxzx) * asfloat(cb0[22].wwww)); // mul r3.xz, r2.xxzx, cb0[22].wwww
    r3.xz = value_20.xz;
    uint4 value_21 = asuint(asfloat(r1.xyzx) + asfloat(r3.xwzx)); // add r1.xyz, r1.xyzx, r3.xwzx
    r1.xyz = value_21.xyz;
    uint4 value_22 = asuint(-asfloat(r1.yyyy)); // mov r1.w, -r1.y
    r1.w = value_22.w;
    uint4 value_23 = asuint(asfloat(r1.xzwx) + asfloat(asuint(-asfloat(cb1[4].xzyx)))); // add r2.xyz, r1.xzwx, -cb1[4].xzyx
    r2.xyz = value_23.xyz;
    uint4 value_24 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r2.xyzx).xyz)).xxxx; // dp3 r0.z, r2.xyzx, r2.xyzx
    r0.z = value_24.z;
    uint4 value_25 = asuint(rsqrt(asfloat(r0.zzzz))); // rsq r0.z, r0.z
    r0.z = value_25.z;
    uint4 value_26 = asuint(mad(asfloat(asuint(-asfloat(r2.xyzx))), asfloat(r0.zzzz), asfloat(r1.xzwx))); // mad r2.xyz, -r2.xyzx, r0.zzzz, r1.xzwx
    r2.xyz = value_26.xyz;
    uint4 value_27 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x40c00000u, 0x40c00000u, 0x40400000u, 0x0u))); // mul r2.xyz, r2.xyzx, l(6.000000, 6.000000, 3.000000, 0.000000)
    r2.xyz = value_27.xyz;
    uint4 value_28 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yyyy), asfloat(r2.xyzx))); // mad r0.xyz, r0.xxxx, r0.yyyy, r2.xyzx
    r0.xyz = value_28.xyz;
    uint4 value_29c = asuint(cos(asfloat(r0.zzzz))); // sincos null, r0.w, r0.z
    r0.w = value_29c.w;
    uint4 value_30s = asuint(sin(asfloat(r0.xyzx))); // sincos r0.xyz, null, r0.xyzx
    r0.xyz = value_30s.xyz;
    uint4 value_31 = asuint(asfloat(r0.zzwz) + asfloat(r0.xxyx)); // add r2.xz, r0.zzwz, r0.xxyx
    r2.xz = value_31.xz;
    uint4 value_32 = asuint(asfloat(asuint(abs(asfloat(r1.yyyy)))) * asfloat(r2.xzxx)); // mul r0.xy, |r1.yyyy|, r2.xzxx
    r0.xy = value_32.xy;
    uint4 value_33 = asuint(mad(asfloat(r0.xxyx), asfloat(uint4(0x3d4ccccdu, 0x0u, 0x3d4ccccdu, 0x0u)), asfloat(r1.xxzx))); // mad r0.xz, r0.xxyx, l(0.050000, 0.000000, 0.050000, 0.000000), r1.xxzx
    r0.xz = value_33.xz;
    uint4 value_34 = asuint(-asfloat(r1.yyyy)); // mov r0.y, -r1.y
    r0.y = value_34.y;
    uint4 value_35 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(r0.xyzx)); // add r0.xyz, -r1.xyzx, r0.xyzx
    r0.xyz = value_35.xyz;
    uint4 value_36 = ((asfloat(v1.xxxx) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.w, v1.x, l(1.000000)
    r0.w = value_36.w;
    uint4 value_37 = (r0.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.w, r0.w, l(0x3f800000)
    r1.w = value_37.w;
    uint4 value_38 = asuint(mad(asfloat(r1.wwww), asfloat(r0.xyzx), asfloat(r1.xyzx))); // mad r0.xyz, r1.wwww, r0.xyzx, r1.xyzx
    r0.xyz = value_38.xyz;
    uint4 value_39 = asuint(asfloat(r0.yyyy) * asfloat(cb3[18].xyzw)); // mul r2.xyzw, r0.yyyy, cb3[18].xyzw
    r2.xyzw = value_39.xyzw;
    uint4 value_40 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r0.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[17].xyzw, r0.xxxx, r2.xyzw
    r2.xyzw = value_40.xyzw;
    uint4 value_41 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r0.zzzz), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[19].xyzw, r0.zzzz, r2.xyzw
    r2.xyzw = value_41.xyzw;
    uint4 value_42 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb1[4].xyzx)))); // add r0.xyz, r0.xyzx, -cb1[4].xyzx
    r0.xyz = value_42.xyz;
    uint4 value_43 = asuint(asfloat(r2.xyzw) + asfloat(cb3[20].xyzw)); // add o1.xyzw, r2.xyzw, cb3[20].xyzw
    out_o1.xyzw = value_43.xyzw;
    uint4 value_44 = asuint(asfloat(r1.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r2.xy, r1.xzxx, -cb0[3].xyxx
    r2.xy = value_44.xy;
    uint4 value_45 = asuint(asfloat(r2.xyxx) * asfloat(cb0[2].zzzz)); // mul r2.xy, r2.xyxx, cb0[2].zzzz
    r2.xy = value_45.xy;
    uint4 value_46 = asuint(max(asfloat(r2.xyxx), asfloat(cb0[7].xyxx))); // max r2.xy, r2.xyxx, cb0[7].xyxx
    r2.xy = value_46.xy;
    uint4 value_47 = asuint(asfloat(cb0[2].xxxy) + asfloat(asuint(-asfloat(cb0[7].xxxy)))); // add r2.zw, cb0[2].xxxy, -cb0[7].xxxy
    r2.zw = value_47.zw;
    uint4 value_48 = asuint(min(asfloat(r2.zwzz), asfloat(r2.xyxx))); // min r2.xy, r2.zwzz, r2.xyxx
    r2.xy = value_48.xy;
    uint4 value_49 = asuint(asfloat(r1.yyyy) + asfloat(uint4(0x3f8ccccdu, 0x3fd9999au, 0x3dccccceu, 0x3f333333u))); // add r3.xyzw, r1.yyyy, l(1.100000, 1.700000, 0.100000, 0.700000)
    r3.xyzw = value_49.xyzw;
    uint4 value_50 = asuint(max(asfloat(r3.zzzw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r2.zw, r3.zzzw, l(0.000000, 0.000000, 0.000000, 0.000000)
    r2.zw = value_50.zw;
    uint4 value_51 = asuint(saturate(asfloat(r3.xyxx))); // mov_sat r3.xy, r3.xyxx
    r3.xy = value_51.xy;
    uint4 value_52 = asuint(floor(asfloat(r2.zzzw))); // round_ni r3.zw, r2.zzzw
    r3.zw = value_52.zw;
    uint4 value_53 = asuint(frac(asfloat(r2.zzzw))); // frc r2.zw, r2.zzzw
    r2.zw = value_53.zw;
    uint4 value_54 = asuint(int4(asfloat(r3.zwzz))); // ftoi r4.xy, r3.zwzz
    r4.xy = value_54.xy;
    uint4 value_55 = (r4.xxxy + uint4(0x0u, 0x0u, 0x1u, 0x1u)); // iadd r4.zw, r4.xxxy, l(0, 0, 1, 1)
    r4.zw = value_55.zw;
    uint4 value_56 = asuint(float4(asint(r4.zwzz))); // itof r5.xy, r4.zwzz
    r5.xy = value_56.xy;
    uint4 value_57 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r5.z, cb0[2].w
    r5.z = value_57.z;
    uint4 value_58 = uint4(asfloat(r5.zzzz)); // ftou r5.z, r5.z
    r5.z = value_58.z;
    uint4 value_59 = asuint(float4(r5.zzzz)); // utof r5.w, r5.z
    r5.w = value_59.w;
    uint4 value_60 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r5.wwww)); // div r5.w, l(1.000000, 1.000000, 1.000000, 1.000000), r5.w
    r5.w = value_60.w;
    uint4 value_61 = asuint(asfloat(r5.wwww) * asfloat(r5.xyxx)); // mul r5.xy, r5.wwww, r5.xyxx
    r5.xy = value_61.xy;
    uint4 value_62 = asuint(asfloat(r3.zzzw) * asfloat(r5.wwww)); // mul r3.zw, r3.zzzw, r5.wwww
    r3.zw = value_62.zw;
    uint4 value_63 = asuint(int4(asfloat(r5.xyxx))); // ftoi r6.xy, r5.xyxx
    r6.xy = value_63.xy;
    uint4 value_64 = asuint(trunc(asfloat(r5.xyxx))); // round_z r5.xy, r5.xyxx
    r5.xy = value_64.xy;
    uint4 value_65 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r5.xxxy), asfloat(r2.yyyy))); // mad r7.zw, cb0[2].yyyy, r5.xxxy, r2.yyyy
    r7.zw = value_65.zw;
    uint4 value_66 = (asuint(-asint(r6.xxxy)) * r5.zzzz + r4.zzzw); // imad r4.zw, -r6.xxxy, r5.zzzz, r4.zzzw
    r4.zw = value_66.zw;
    uint4 value_67 = asuint(float4(r4.zzzw)); // utof r4.zw, r4.zzzw
    r4.zw = value_67.zw;
    uint4 value_68 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r4.zwzz), asfloat(r2.xxxx))); // mad r7.xy, cb0[2].xxxx, r4.zwzz, r2.xxxx
    r7.xy = value_68.xy;
    uint4 value_69 = asuint(t0.SampleLevel(s0, asfloat(r7.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r7.xzxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_69.xyzw;
    uint4 value_70 = asuint(t0.SampleLevel(s0, asfloat(r7.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r7.ywyy, t0.xyzw, s0, l(0.000000)
    r8.xyzw = value_70.xyzw;
    uint4 value_71 = ((asfloat(r7.zzzw) >= asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r4.zw, r7.zzzw, l(0.000000, 0.000000, 1.000000, 1.000000)
    r4.zw = value_71.zw;
    uint4 value_72 = (r4.zzzw & uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u)); // and r4.zw, r4.zzzw, l(0, 0, 0x3f800000, 0x3f800000)
    r4.zw = value_72.zw;
    uint4 value_73 = asuint(asfloat(asuint(-asfloat(r6.xyxz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x3f800000u))); // add r5.xyw, -r6.xyxz, l(1.000000, 1.000000, 0.000000, 1.000000)
    r5.xyw = value_73.xyw;
    uint4 value_74 = asuint(mad(asfloat(r4.zzzz), asfloat(r5.xyxw), asfloat(r6.xyxz))); // mad r5.xyw, r4.zzzz, r5.xyxw, r6.xyxz
    r5.xyw = value_74.xyw;
    uint4 value_75 = asuint(int4(asfloat(r3.zwzz))); // ftoi r6.xy, r3.zwzz
    r6.xy = value_75.xy;
    uint4 value_76 = asuint(trunc(asfloat(r3.zzzw))); // round_z r3.zw, r3.zzzw
    r3.zw = value_76.zw;
    uint4 value_77 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.zzzw), asfloat(r2.yyyy))); // mad r7.zw, cb0[2].yyyy, r3.zzzw, r2.yyyy
    r7.zw = value_77.zw;
    uint4 value_78 = (asuint(-asint(r6.xxxy)) * r5.zzzz + r4.xxxy); // imad r3.zw, -r6.xxxy, r5.zzzz, r4.xxxy
    r3.zw = value_78.zw;
    uint4 value_79 = asuint(float4(r3.zzzw)); // utof r3.zw, r3.zzzw
    r3.zw = value_79.zw;
    uint4 value_80 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.zwzz), asfloat(r2.xxxx))); // mad r7.xy, cb0[2].xxxx, r3.zwzz, r2.xxxx
    r7.xy = value_80.xy;
    uint4 value_81 = asuint(t0.SampleLevel(s0, asfloat(r7.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r7.xzxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_81.xyzw;
    uint4 value_82 = asuint(t0.SampleLevel(s0, asfloat(r7.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r9.xyzw, r7.ywyy, t0.xyzw, s0, l(0.000000)
    r9.xyzw = value_82.xyzw;
    uint4 value_83 = ((asfloat(r7.zwzz) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.xy, r7.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
    r2.xy = value_83.xy;
    uint4 value_84 = (r2.xyxx & uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u)); // and r2.xy, r2.xyxx, l(0x3f800000, 0x3f800000, 0, 0)
    r2.xy = value_84.xy;
    uint4 value_85 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_85.xyz;
    uint4 value_86 = asuint(mad(asfloat(r2.xxxx), asfloat(r4.xyzx), asfloat(r6.xyzx))); // mad r4.xyz, r2.xxxx, r4.xyzx, r6.xyzx
    r4.xyz = value_86.xyz;
    uint4 value_87 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(r5.xywx)); // add r5.xyz, -r4.xyzx, r5.xywx
    r5.xyz = value_87.xyz;
    uint4 value_88 = asuint(mad(asfloat(r2.zzzz), asfloat(r5.xyzx), asfloat(r4.xyzx))); // mad r4.xyz, r2.zzzz, r5.xyzx, r4.xyzx
    r4.xyz = value_88.xyz;
    uint4 value_89 = asuint(asfloat(r4.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r4.xyz, r4.xyzx, -cb0[9].xyzx
    r4.xyz = value_89.xyz;
    uint4 value_90 = asuint(mad(asfloat(r3.xxxx), asfloat(r4.xxyz), asfloat(cb0[9].xxyz))); // mad r3.xzw, r3.xxxx, r4.xxyz, cb0[9].xxyz
    r3.xzw = value_90.xzw;
    uint4 value_91 = asuint(asfloat(asuint(-asfloat(r8.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r8.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_91.xyz;
    uint4 value_92 = asuint(mad(asfloat(r4.wwww), asfloat(r4.xyzx), asfloat(r8.xyzx))); // mad r4.xyz, r4.wwww, r4.xyzx, r8.xyzx
    r4.xyz = value_92.xyz;
    uint4 value_93 = asuint(asfloat(asuint(-asfloat(r9.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r9.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_93.xyz;
    uint4 value_94 = asuint(mad(asfloat(r2.yyyy), asfloat(r5.xyzx), asfloat(r9.xyzx))); // mad r2.xyz, r2.yyyy, r5.xyzx, r9.xyzx
    r2.xyz = value_94.xyz;
    uint4 value_95 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(r4.xyzx)); // add r4.xyz, -r2.xyzx, r4.xyzx
    r4.xyz = value_95.xyz;
    uint4 value_96 = asuint(mad(asfloat(r2.wwww), asfloat(r4.xyzx), asfloat(r2.xyzx))); // mad r2.xyz, r2.wwww, r4.xyzx, r2.xyzx
    r2.xyz = value_96.xyz;
    uint4 value_97 = asuint(asfloat(r2.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r2.xyz, r2.xyzx, -cb0[9].xyzx
    r2.xyz = value_97.xyz;
    uint4 value_98 = asuint(mad(asfloat(r3.yyyy), asfloat(r2.xyzx), asfloat(cb0[9].xyzx))); // mad r2.xyz, r3.yyyy, r2.xyzx, cb0[9].xyzx
    r2.xyz = value_98.xyz;
    uint4 value_99 = asuint(asfloat(r2.xyzx) * asfloat(r3.xzwx)); // mul r4.xyz, r2.xyzx, r3.xzwx
    r4.xyz = value_99.xyz;
    uint4 value_100 = asuint(dot(asfloat(r4.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r2.w, r4.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r2.w = value_100.w;
    uint4 value_101 = asuint(mad(asfloat(r3.xzwx), asfloat(r2.xyzx), asfloat(asuint(-asfloat(r2.wwww))))); // mad r2.xyz, r3.xzwx, r2.xyzx, -r2.wwww
    r2.xyz = value_101.xyz;
    uint4 value_102 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r3.x, cb0[5].w, cb0[6].w
    r3.x = value_102.x;
    uint4 value_103 = asuint(saturate(asfloat(asuint(asfloat(r3.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r3.x, r3.x, l(0.500000)
    r3.x = value_103.x;
    uint4 value_104 = asuint(asfloat(r3.xxxx) * asfloat(cb0[29].xxxx)); // mul r3.x, r3.x, cb0[29].x
    r3.x = value_104.x;
    uint4 value_105 = asuint(mad(asfloat(r3.xxxx), asfloat(r2.xyzx), asfloat(r2.wwww))); // mad r2.xyz, r3.xxxx, r2.xyzx, r2.wwww
    r2.xyz = value_105.xyz;
    uint4 value_106 = asuint(asfloat(r1.yyyy) * asfloat(cb0[31].xyzx)); // mul r3.xyz, r1.yyyy, cb0[31].xyzx
    r3.xyz = value_106.xyz;
    uint4 value_107 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r1.xxxx), asfloat(r3.xyzx))); // mad r3.xyz, cb0[30].xyzx, r1.xxxx, r3.xyzx
    r3.xyz = value_107.xyz;
    uint4 value_108 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r1.zzzz), asfloat(r3.xyzx))); // mad r1.xyz, cb0[32].xyzx, r1.zzzz, r3.xyzx
    r1.xyz = value_108.xyz;
    uint4 value_109 = asuint(asfloat(r1.xyzx) + asfloat(cb0[33].xyzx)); // add r1.xyz, r1.xyzx, cb0[33].xyzx
    r1.xyz = value_109.xyz;
    uint4 value_110 = asuint(asfloat(r1.xyxx) * asfloat(cb0[39].zwzz)); // mul r1.xy, r1.xyxx, cb0[39].zwzz
    r1.xy = value_110.xy;
    uint4 value_111 = asuint(frac(asfloat(r1.xyxx))); // frc r3.xy, r1.xyxx
    r3.xy = value_111.xy;
    uint4 value_112 = asuint(asfloat(asuint(-asfloat(r3.xxxy))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r3.zw, -r3.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    r3.zw = value_112.zw;
    uint4 value_113 = asuint(asfloat(asuint(-asfloat(cb0[4].yyyy))) * asfloat(cb0[38].yyyy)); // mul r2.w, -cb0[4].y, cb0[38].y
    r2.w = value_113.w;
    uint4 value_114 = asuint(mad(asfloat(asuint(-asfloat(r2.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r1.zzzz))); // mad r1.z, -r2.w, l(0.050000), r1.z
    r1.z = value_114.z;
    uint4 value_115 = asuint(asfloat(r1.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r1.z, r1.z, l(-0.003922)
    r1.z = value_115.z;
    uint4 value_116 = asuint(asfloat(r1.xxxy) * asfloat(cb0[39].xxxy)); // mul r4.zw, r1.xxxy, cb0[39].xxxy
    r4.zw = value_116.zw;
    uint4 value_117 = asuint(mad(asfloat(r1.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r4.xy, r1.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r4.xy = value_117.xy;
    uint4 value_118 = asuint(t1.SampleLevel(s1, asfloat(r4.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.zyzz, t1.xyzw, s1, l(0.000000)
    r5.xyzw = value_118.xyzw;
    uint4 value_119 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r1.zzzz, -r5.xyzx
    r5.xyz = value_119.xyz;
    uint4 value_120 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r1.x, cb0[38].x, l(20.000000)
    r1.x = value_120.x;
    uint4 value_121 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r1.xxxx, r5.xyzx
    r5.xyz = value_121.xyz;
    uint4 value_122 = asuint(asfloat(r3.zzzz) * asfloat(r5.xyzx)); // mul r5.xyz, r3.zzzz, r5.xyzx
    r5.xyz = value_122.xyz;
    uint4 value_123 = asuint(asfloat(r3.yyyy) * asfloat(r5.xyzx)); // mul r5.xyz, r3.yyyy, r5.xyzx
    r5.xyz = value_123.xyz;
    uint4 value_124 = asuint(t1.SampleLevel(s1, asfloat(r4.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r4.zwzz, t1.xyzw, s1, l(0.000000)
    r6.xyzw = value_124.xyzw;
    uint4 value_125 = asuint(t1.SampleLevel(s1, asfloat(r4.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r4.xwxx, t1.xyzw, s1, l(0.000000)
    r7.xyzw = value_125.xyzw;
    uint4 value_126 = asuint(t1.SampleLevel(s1, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r4.xyxx, t1.xyzw, s1, l(0.000000)
    r4.xyzw = value_126.xyzw;
    uint4 value_127 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r1.zzzz, -r4.xyzx
    r4.xyz = value_127.xyz;
    uint4 value_128 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r1.xxxx, r4.xyzx
    r4.xyz = value_128.xyz;
    uint4 value_129 = asuint(asfloat(r3.xxxx) * asfloat(r4.xyzx)); // mul r4.xyz, r3.xxxx, r4.xyzx
    r4.xyz = value_129.xyz;
    uint4 value_130 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r7.xyzx)))); // add r7.xyz, r1.zzzz, -r7.xyzx
    r7.xyz = value_130.xyz;
    uint4 value_131 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r1.zzzz, -r6.xyzx
    r6.xyz = value_131.xyz;
    uint4 value_132 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r1.xxxx, r6.xyzx
    r6.xyz = value_132.xyz;
    uint4 value_133 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r7.xyzx))))); // mul_sat r1.xyz, r1.xxxx, r7.xyzx
    r1.xyz = value_133.xyz;
    uint4 value_134 = asuint(asfloat(r3.xxxx) * asfloat(r1.xyzx)); // mul r1.xyz, r3.xxxx, r1.xyzx
    r1.xyz = value_134.xyz;
    uint4 value_135 = asuint(asfloat(r3.zzzz) * asfloat(r6.xyzx)); // mul r6.xyz, r3.zzzz, r6.xyzx
    r6.xyz = value_135.xyz;
    uint4 value_136 = asuint(mad(asfloat(r6.xyzx), asfloat(r3.wwww), asfloat(r5.xyzx))); // mad r5.xyz, r6.xyzx, r3.wwww, r5.xyzx
    r5.xyz = value_136.xyz;
    uint4 value_137 = asuint(mad(asfloat(r1.xyzx), asfloat(r3.wwww), asfloat(r5.xyzx))); // mad r1.xyz, r1.xyzx, r3.wwww, r5.xyzx
    r1.xyz = value_137.xyz;
    uint4 value_138 = asuint(mad(asfloat(r4.xyzx), asfloat(r3.yyyy), asfloat(r1.xyzx))); // mad r1.xyz, r4.xyzx, r3.yyyy, r1.xyzx
    r1.xyz = value_138.xyz;
    uint4 value_139 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r1.x, r1.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r1.x = value_139.x;
    uint4 value_140 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.x, l(1.000000)
    r1.x = value_140.x;
    uint4 value_141 = asuint(saturate(asfloat(asuint(-asfloat(cb0[4].yyyy))))); // mov_sat r1.y, -cb0[4].y
    r1.y = value_141.y;
    uint4 value_142 = asuint(asfloat(asuint(-asfloat(r1.yyyy))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.y, -r1.y, l(1.000000)
    r1.y = value_142.y;
    uint4 value_143 = asuint(asfloat(r1.yyyy) * asfloat(r1.yyyy)); // mul r1.z, r1.y, r1.y
    r1.z = value_143.z;
    uint4 value_144 = asuint(mad(asfloat(asuint(-asfloat(r1.yyyy))), asfloat(r1.zzzz), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r1.y, -r1.y, r1.z, l(1.000000)
    r1.y = value_144.y;
    uint4 value_145 = asuint(asfloat(r1.yyyy) * asfloat(r1.xxxx)); // mul r1.x, r1.y, r1.x
    r1.x = value_145.x;
    uint4 value_146 = asuint(asfloat(r1.xxxx) * asfloat(cb0[5].wwww)); // mul r1.x, r1.x, cb0[5].w
    r1.x = value_146.x;
    uint4 value_147 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r3.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r3.xyz = value_147.xyz;
    uint4 value_148 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r3.xyzx))))); // mad r4.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r3.xyzx
    r4.xyz = value_148.xyz;
    uint4 value_149 = asuint(mad(asfloat(r1.xxxx), asfloat(r4.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r1.xxxx, r4.xyzx, r3.xyzx
    r3.xyz = value_149.xyz;
    uint4 value_150 = asuint(asfloat(r1.xxxx) * asfloat(cb0[5].xyzx)); // mul r4.xyz, r1.xxxx, cb0[5].xyzx
    r4.xyz = value_150.xyz;
    uint4 value_151 = asuint(asfloat(r4.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r4.xyz, r4.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r4.xyz = value_151.xyz;
    uint4 value_152 = asuint(mad(asfloat(r2.xyzx), asfloat(r3.xyzx), asfloat(r4.xyzx))); // mad r2.xyz, r2.xyzx, r3.xyzx, r4.xyzx
    r2.xyz = value_152.xyz;
    uint4 value_153 = asuint(asfloat(r2.xyzx) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add r2.xyz, r2.xyzx, l(0.100000, 0.100000, 0.100000, 0.000000)
    r2.xyz = value_153.xyz;
    uint4 value_154 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r1.y, cb0[5].w, -cb0[6].w
    r1.y = value_154.y;
    uint4 value_155 = asuint(mad(asfloat(r1.xxxx), asfloat(r1.yyyy), asfloat(cb0[6].wwww))); // mad r1.x, r1.x, r1.y, cb0[6].w
    r1.x = value_155.x;
    uint4 value_156 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x3e99999au)), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x3f333333u)))); // mad r1.y, cb0[29].x, l(0.300000), l(0.700000)
    r1.y = value_156.y;
    uint4 value_157 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x3f800000u, 0xb2000000u, 0x0u, 0x0u))); // mul r3.xy, r1.yyyy, l(1.000000, -0.000000, 0.000000, 0.000000)
    r3.xy = value_157.xy;
    uint4 value_158 = asuint(mad(asfloat(r1.xxxx), asfloat(r3.yyyy), asfloat(r3.xxxx))); // mad r1.x, r1.x, r3.y, r3.x
    r1.x = value_158.x;
    uint4 value_159 = asuint(asfloat(r2.xyzx) * asfloat(r1.xxxx)); // mul r2.xyz, r2.xyzx, r1.xxxx
    r2.xyz = value_159.xyz;
    uint4 value_160 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.x, r2.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.x = value_160.x;
    uint4 value_161 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r1.z, -r1.x, l(0.600000)
    r1.z = value_161.z;
    uint4 value_162 = asuint(asfloat(asuint(-asfloat(r1.zzzz))) + asfloat(r1.xxxx)); // add r1.x, -r1.z, r1.x
    r1.x = value_162.x;
    uint4 value_163 = asuint(mad(asfloat(r1.xxxx), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r2.xyzx))); // mad r2.xyz, r1.xxxx, l(0.100000, 0.100000, 0.100000, 0.000000), r2.xyzx
    r2.xyz = value_163.xyz;
    uint4 value_164 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r3.xyz, -r2.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r3.xyz = value_164.xyz;
    uint4 value_165 = asuint(mad(asfloat(r3.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r2.xyzx))); // mad r2.xyz, r3.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r2.xyzx
    r2.xyz = value_165.xyz;
    uint4 value_166 = asuint(asfloat(asuint(-asfloat(r1.yyyy))) + asfloat(r2.xyzx)); // add r2.xyz, -r1.yyyy, r2.xyzx
    r2.xyz = value_166.xyz;
    uint4 value_167 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r2.xyzx), asfloat(r1.yyyy))); // mad r1.xyz, cb0[29].yyyy, r2.xyzx, r1.yyyy
    r1.xyz = value_167.xyz;
    uint4 value_168 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(r0.xyzx).xyz)).xxxx; // dp3 r0.x, r0.xyzx, r0.xyzx
    r0.x = value_168.x;
    uint4 value_169 = asuint(rsqrt(asfloat(r0.xxxx))); // rsq r0.x, r0.x
    r0.x = value_169.x;
    uint4 value_170 = asuint(asfloat(r0.xxxx) * asfloat(r0.yyyy)); // mul r0.x, r0.x, r0.y
    r0.x = value_170.x;
    uint4 value_171 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.y, r0.x, l(0.500000)
    r0.y = value_171.y;
    uint4 value_172 = asuint(asfloat(asuint(-asfloat(cb0[8].xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r2.xyz, -cb0[8].xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r2.xyz = value_172.xyz;
    uint4 value_173 = asuint(mad(asfloat(r0.yyyy), asfloat(r2.xyzx), asfloat(cb0[8].xyzx))); // mad r3.xyz, r0.yyyy, r2.xyzx, cb0[8].xyzx
    r3.xyz = value_173.xyz;
    uint4 value_174 = asuint(asfloat(r3.xyzx) + asfloat(uint4(0xbf000000u, 0xbf266666u, 0xbf333333u, 0x0u))); // add r3.xyz, r3.xyzx, l(-0.500000, -0.650000, -0.700000, 0.000000)
    r3.xyz = value_174.xyz;
    uint4 value_175 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r3.xyzx), asfloat(uint4(0x3f000000u, 0x3f266666u, 0x3f333333u, 0x0u)))); // mad r3.xyz, cb0[29].yyyy, r3.xyzx, l(0.500000, 0.650000, 0.700000, 0.000000)
    r3.xyz = value_175.xyz;
    uint4 value_176 = asuint(asfloat(r1.xyzx) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r1.xyz, r1.xyzx, -r3.xyzx
    r1.xyz = value_176.xyz;
    uint4 value_177 = asuint(mad(asfloat(v3.xxxx), asfloat(r1.xyzx), asfloat(r3.xyzx))); // mad r1.xyz, v3.xxxx, r1.xyzx, r3.xyzx
    r1.xyz = value_177.xyz;
    uint4 value_178 = asuint(asfloat(asuint(-asfloat(v3.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.z, -v3.x, l(1.000000)
    r0.z = value_178.z;
    uint4 value_179 = asuint(asfloat(r0.zzzz) * asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // mul r0.z, r0.z, l(1.000000)
    r0.z = value_179.z;
    uint4 value_180 = ((r0.wwww != 0u) ? uint4(0x0u, 0x0u, 0x0u, 0x0u) : r0.zzzz); // movc r0.z, r0.w, l(0), r0.z
    r0.z = value_180.z;
    uint4 value_181 = asuint(asfloat(r0.zzzz) + asfloat(r1.wwww)); // add r0.z, r0.z, r1.w
    r0.z = value_181.z;
    uint4 value_182 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov r0.x, l(1.000000)
    r0.x = value_182.x;
    uint4 value_183 = asuint(asfloat(r0.zzzz) * asfloat(r0.xyxx)); // mul r0.xy, r0.zzzz, r0.xyxx
    r0.xy = value_183.xy;
    uint4 value_184 = asuint(mad(asfloat(r0.yyyy), asfloat(r2.xxyz), asfloat(cb0[8].xxyz))); // mad r0.yzw, r0.yyyy, r2.xxyz, cb0[8].xxyz
    r0.yzw = value_184.yzw;
    uint4 value_185 = asuint(asfloat(r0.xxxx) * asfloat(r0.xxxx)); // mul r0.x, r0.x, r0.x
    r0.x = value_185.x;
    uint4 value_186 = asuint(asfloat(r0.yyzw) + asfloat(uint4(0x0u, 0xbf000000u, 0xbf266666u, 0xbf333333u))); // add r0.yzw, r0.yyzw, l(0.000000, -0.500000, -0.650000, -0.700000)
    r0.yzw = value_186.yzw;
    uint4 value_187 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.yzwy), asfloat(uint4(0x0u, 0x3e199998u, 0x3e4cccccu, 0x0u)))); // mad r2.xyz, cb0[29].yyyy, r0.yzwy, l(0.000000, 0.150000, 0.200000, 0.000000)
    r2.xyz = value_187.xyz;
    uint4 value_188 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.yyzw), asfloat(uint4(0x0u, 0x3f000000u, 0x3f266666u, 0x3f333333u)))); // mad r0.yzw, cb0[29].yyyy, r0.yyzw, l(0.000000, 0.500000, 0.650000, 0.700000)
    r0.yzw = value_188.yzw;
    uint4 value_189 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r2.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), r1.xyzx
    r1.xyz = value_189.xyz;
    uint4 value_190 = asuint(asfloat(r0.yyzw) + asfloat(asuint(-asfloat(r1.xxyz)))); // add r0.yzw, r0.yyzw, -r1.xxyz
    r0.yzw = value_190.yzw;
    uint4 value_191 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yzwy), asfloat(r1.xyzx))); // mad o2.xyz, r0.xxxx, r0.yzwy, r1.xyzx
    out_o2.xyz = value_191.xyz;
    uint4 value_192 = v3.wwww; // mov o2.w, v3.w
    out_o2.w = value_192.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xyzw);
    result.o2_0 = asfloat(out_o2.xyzw);
    result.o3_0 = asfloat(out_o3.xyzw);
    return result;
}
