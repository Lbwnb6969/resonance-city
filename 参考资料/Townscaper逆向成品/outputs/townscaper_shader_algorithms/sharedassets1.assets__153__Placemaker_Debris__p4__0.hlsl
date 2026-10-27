// Register-explicit recovered HLSL. Not original source.
// Placemaker/Debris vs_4_0 variant []
// Source SHA256 168b28612871ecb1a3f2b2140dda2b88d4f4824787183fea6b199aa51bdeb536
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
// cb0[11].x = _RoofColor rows=1 cols=4 byte_offset=176
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[6].x = _ScreenParams rows=1 cols=4 byte_offset=96
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s3 = _MainTex
// t1 / s1 = _MaterialTex
// t2 / s0 = _AoTex
// t3 / s2 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
cbuffer Buffer1:register(b1) { uint4 cb1[7]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[21]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
SamplerState s2:register(s2);
SamplerState s3:register(s3);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
Texture2D<float4> t2:register(t2);
Texture2D<float4> t3:register(t3);
// temporary registers: 8
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: NORMAL0;
    float4 v3_0: TANGENT0;
    float4 v4_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float4 o1_0: COLOR0;
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
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    uint4 v4;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xyz = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    v4.xyzw = asuint(input.v4_0);
    uint4 value_1 = asuint(asfloat(v3.yyyy) * asfloat(cb2[1].xyzx)); // mul r0.xyz, v3.yyyy, cb2[1].xyzx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v3.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb2[0].xyzx, v3.xxxx, r0.xyzx
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v3.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb2[2].xyzx, v3.zzzz, r0.xyzx
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzx)); // mul r1.xyz, v0.yyyy, cb2[1].xyzx
    r1.xyz = value_4.xyz;
    uint4 value_5 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v0.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb2[0].xyzx, v0.xxxx, r1.xyzx
    r1.xyz = value_5.xyz;
    uint4 value_6 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v0.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb2[2].xyzx, v0.zzzz, r1.xyzx
    r1.xyz = value_6.xyz;
    uint4 value_7 = asuint(mad(asfloat(cb2[3].xyzx), asfloat(v0.wwww), asfloat(r1.xyzx))); // mad r1.xyz, cb2[3].xyzx, v0.wwww, r1.xyzx
    r1.xyz = value_7.xyz;
    uint4 value_8 = asuint(asfloat(r1.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r2.xyz, r1.xyzx, -cb0[22].xyzx
    r2.xyz = value_8.xyz;
    uint4 value_9 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r2.xyzx).xyz)).xxxx; // dp3 r0.w, r2.xyzx, r2.xyzx
    r0.w = value_9.w;
    uint4 value_10 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_10.w;
    uint4 value_11 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_11.w;
    uint4 value_12 = asuint(asfloat(r0.wwww) * asfloat(r2.xyzx)); // mul r2.xyz, r0.wwww, r2.xyzx
    r2.xyz = value_12.xyz;
    uint4 value_13 = asuint(mad(asfloat(r2.yyyy), asfloat(cb0[22].wwww), asfloat(r1.yyyy))); // mad r0.w, r2.y, cb0[22].w, r1.y
    r0.w = value_13.w;
    uint4 value_14 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_14.w;
    uint4 value_15 = asuint(mad(asfloat(r2.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r3.w, r2.y, cb0[22].w, -r0.w
    r3.w = value_15.w;
    uint4 value_16 = asuint(asfloat(r2.xxzx) * asfloat(cb0[22].wwww)); // mul r3.xz, r2.xxzx, cb0[22].wwww
    r3.xz = value_16.xz;
    uint4 value_17 = asuint(asfloat(r1.xyzx) + asfloat(r3.xwzx)); // add r1.xyz, r1.xyzx, r3.xwzx
    r1.xyz = value_17.xyz;
    uint4 value_18 = asuint(asfloat(r0.xyzx) + asfloat(r1.xyzx)); // add r2.xyz, r0.xyzx, r1.xyzx
    r2.xyz = value_18.xyz;
    uint4 value_19 = asuint(asfloat(r2.yyyy) * asfloat(cb3[18].xxxy)); // mul r2.yw, r2.yyyy, cb3[18].xxxy
    r2.yw = value_19.yw;
    uint4 value_20 = asuint(mad(asfloat(cb3[17].xyxx), asfloat(r2.xxxx), asfloat(r2.ywyy))); // mad r2.xy, cb3[17].xyxx, r2.xxxx, r2.ywyy
    r2.xy = value_20.xy;
    uint4 value_21 = asuint(mad(asfloat(cb3[19].xyxx), asfloat(r2.zzzz), asfloat(r2.xyxx))); // mad r2.xy, cb3[19].xyxx, r2.zzzz, r2.xyxx
    r2.xy = value_21.xy;
    uint4 value_22 = asuint(asfloat(r2.xyxx) + asfloat(cb3[20].xyxx)); // add r2.xy, r2.xyxx, cb3[20].xyxx
    r2.xy = value_22.xy;
    uint4 value_23 = asuint(asfloat(r1.yyyy) * asfloat(cb3[18].xyzw)); // mul r3.xyzw, r1.yyyy, cb3[18].xyzw
    r3.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r1.xxxx), asfloat(r3.xyzw))); // mad r3.xyzw, cb3[17].xyzw, r1.xxxx, r3.xyzw
    r3.xyzw = value_24.xyzw;
    uint4 value_25 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r1.zzzz), asfloat(r3.xyzw))); // mad r3.xyzw, cb3[19].xyzw, r1.zzzz, r3.xyzw
    r3.xyzw = value_25.xyzw;
    uint4 value_26 = asuint(asfloat(r3.xyzw) + asfloat(cb3[20].xyzw)); // add r3.xyzw, r3.xyzw, cb3[20].xyzw
    r3.xyzw = value_26.xyzw;
    uint4 value_27 = asuint(asfloat(r2.xyxx) + asfloat(asuint(-asfloat(r3.xyxx)))); // add r2.xy, r2.xyxx, -r3.xyxx
    r2.xy = value_27.xy;
    uint4 value_28 = asuint(asfloat(asuint(-asfloat(v3.wwww))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f000000u))); // add r2.zw, -v3.wwww, l(0.000000, 0.000000, 1.000000, 0.500000)
    r2.zw = value_28.zw;
    uint4 value_29 = asuint(asfloat(r3.wwww) * asfloat(r2.wwww)); // mul r0.w, r3.w, r2.w
    r0.w = value_29.w;
    uint4 value_30 = asuint(mad(asfloat(r2.zzzz), asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u)), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r1.w, r2.z, l(-0.500000), l(1.000000)
    r1.w = value_30.w;
    uint4 value_31 = asuint(asfloat(r0.wwww) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.w, r0.w, l(0.500000)
    r0.w = value_31.w;
    uint4 value_32 = asuint(asfloat(r0.wwww) / asfloat(cb1[6].yyyy)); // div r0.w, r0.w, cb1[6].y
    r0.w = value_32.w;
    uint4 value_33 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xyxx), asfloat(r3.xyxx))); // mad o0.xy, r0.wwww, r2.xyxx, r3.xyxx
    out_o0.xy = value_33.xy;
    uint4 value_34 = r3.zzzw; // mov o0.zw, r3.zzzw
    out_o0.zw = value_34.zw;
    uint4 value_35 = asuint(asfloat(v2.yyyy) * asfloat(cb2[1].xyzx)); // mul r2.xyz, v2.yyyy, cb2[1].xyzx
    r2.xyz = value_35.xyz;
    uint4 value_36 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v2.xxxx), asfloat(r2.xyzx))); // mad r2.xyz, cb2[0].xyzx, v2.xxxx, r2.xyzx
    r2.xyz = value_36.xyz;
    uint4 value_37 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v2.zzzz), asfloat(r2.xyzx))); // mad r2.xyz, cb2[2].xyzx, v2.zzzz, r2.xyzx
    r2.xyz = value_37.xyz;
    uint4 value_38 = asuint(asfloat(r0.xyzx) + asfloat(r2.xyzx)); // add r0.xyz, r0.xyzx, r2.xyzx
    r0.xyz = value_38.xyz;
    uint4 value_39 = asuint(mad(asfloat(r0.xyzx), asfloat(uint4(0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r2.xyz, r0.xyzx, l(0.200000, 0.200000, 0.200000, 0.000000), r1.xyzx
    r2.xyz = value_39.xyz;
    uint4 value_40 = asuint(asfloat(r2.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r2.xz, r2.xxzx, -cb0[3].xxyx
    r2.xz = value_40.xz;
    uint4 value_41 = asuint(asfloat(r2.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r2.yw, r2.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r2.yw = value_41.yw;
    uint4 value_42 = asuint(asfloat(r2.xxzx) * asfloat(cb0[2].zzzz)); // mul r2.xz, r2.xxzx, cb0[2].zzzz
    r2.xz = value_42.xz;
    uint4 value_43 = asuint(max(asfloat(r2.xxzx), asfloat(cb0[7].xxyx))); // max r2.xz, r2.xxzx, cb0[7].xxyx
    r2.xz = value_43.xz;
    uint4 value_44 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r3.xy, cb0[2].xyxx, -cb0[7].xyxx
    r3.xy = value_44.xy;
    uint4 value_45 = asuint(min(asfloat(r2.xxzx), asfloat(r3.xxyx))); // min r2.xz, r2.xxzx, r3.xxyx
    r2.xz = value_45.xz;
    uint4 value_46 = asuint(max(asfloat(r2.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r2.w, l(0.000000)
    r0.w = value_46.w;
    uint4 value_47 = asuint(saturate(asfloat(r2.yyyy))); // mov_sat r2.y, r2.y
    r2.y = value_47.y;
    uint4 value_48 = asuint(floor(asfloat(r0.wwww))); // round_ni r2.w, r0.w
    r2.w = value_48.w;
    uint4 value_49 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_49.w;
    uint4 value_50 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.z, r2.w
    r3.z = value_50.z;
    uint4 value_51 = (r3.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.w, r3.z, l(1)
    r3.w = value_51.w;
    uint4 value_52 = asuint(float4(asint(r3.wwww))); // itof r4.x, r3.w
    r4.x = value_52.x;
    uint4 value_53 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r4.y, cb0[2].w
    r4.y = value_53.y;
    uint4 value_54 = uint4(asfloat(r4.yyyy)); // ftou r4.y, r4.y
    r4.y = value_54.y;
    uint4 value_55 = asuint(float4(r4.yyyy)); // utof r4.z, r4.y
    r4.z = value_55.z;
    uint4 value_56 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r4.zzzz)); // div r4.z, l(1.000000, 1.000000, 1.000000, 1.000000), r4.z
    r4.z = value_56.z;
    uint4 value_57 = asuint(asfloat(r4.zzzz) * asfloat(r4.xxxx)); // mul r4.x, r4.z, r4.x
    r4.x = value_57.x;
    uint4 value_58 = asuint(int4(asfloat(r4.xxxx))); // ftoi r4.w, r4.x
    r4.w = value_58.w;
    uint4 value_59 = asuint(trunc(asfloat(r4.xxxx))); // round_z r4.x, r4.x
    r4.x = value_59.x;
    uint4 value_60 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r4.xxxx), asfloat(r2.zzzz))); // mad r5.y, cb0[2].y, r4.x, r2.z
    r5.y = value_60.y;
    uint4 value_61 = (asuint(-asint(r4.wwww)) * r4.yyyy + r3.wwww); // imad r3.w, -r4.w, r4.y, r3.w
    r3.w = value_61.w;
    uint4 value_62 = asuint(float4(r3.wwww)); // utof r3.w, r3.w
    r3.w = value_62.w;
    uint4 value_63 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.wwww), asfloat(r2.xxxx))); // mad r5.x, cb0[2].x, r3.w, r2.x
    r5.x = value_63.x;
    uint4 value_64 = asuint(t2.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t2.xyzw, s0, l(0.000000)
    r6.xyzw = value_64.xyzw;
    uint4 value_65 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r5.y, l(1.000000)
    r3.w = value_65.w;
    uint4 value_66 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_66.w;
    uint4 value_67 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_67.xyz;
    uint4 value_68 = asuint(mad(asfloat(r3.wwww), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r5.xyz, r3.wwww, r5.xyzx, r6.xyzx
    r5.xyz = value_68.xyz;
    uint4 value_69 = asuint(asfloat(r2.wwww) * asfloat(r4.zzzz)); // mul r2.w, r2.w, r4.z
    r2.w = value_69.w;
    uint4 value_70 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.w, r2.w
    r3.w = value_70.w;
    uint4 value_71 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_71.w;
    uint4 value_72 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r2.zzzz))); // mad r6.y, cb0[2].y, r2.w, r2.z
    r6.y = value_72.y;
    uint4 value_73 = (asuint(-asint(r3.wwww)) * r4.yyyy + r3.zzzz); // imad r2.z, -r3.w, r4.y, r3.z
    r2.z = value_73.z;
    uint4 value_74 = asuint(float4(r2.zzzz)); // utof r2.z, r2.z
    r2.z = value_74.z;
    uint4 value_75 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.zzzz), asfloat(r2.xxxx))); // mad r6.x, cb0[2].x, r2.z, r2.x
    r6.x = value_75.x;
    uint4 value_76 = asuint(t2.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r6.xyxx, t2.xyzw, s0, l(0.000000)
    r7.xyzw = value_76.xyzw;
    uint4 value_77 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.x, r6.y, l(1.000000)
    r2.x = value_77.x;
    uint4 value_78 = (r2.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.x, r2.x, l(0x3f800000)
    r2.x = value_78.x;
    uint4 value_79 = asuint(asfloat(asuint(-asfloat(r7.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r6.xyz, -r7.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r6.xyz = value_79.xyz;
    uint4 value_80 = asuint(mad(asfloat(r2.xxxx), asfloat(r6.xxyz), asfloat(r7.xxyz))); // mad r2.xzw, r2.xxxx, r6.xxyz, r7.xxyz
    r2.xzw = value_80.xzw;
    uint4 value_81 = asuint(asfloat(asuint(-asfloat(r2.xzwx))) + asfloat(r5.xyzx)); // add r5.xyz, -r2.xzwx, r5.xyzx
    r5.xyz = value_81.xyz;
    uint4 value_82 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xxyz), asfloat(r2.xxzw))); // mad r2.xzw, r0.wwww, r5.xxyz, r2.xxzw
    r2.xzw = value_82.xzw;
    uint4 value_83 = asuint(asfloat(r2.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r2.xzw, r2.xxzw, -cb0[9].xxyz
    r2.xzw = value_83.xzw;
    uint4 value_84 = asuint(mad(asfloat(r2.yyyy), asfloat(r2.xzwx), asfloat(cb0[9].xyzx))); // mad r2.xyz, r2.yyyy, r2.xzwx, cb0[9].xyzx
    r2.xyz = value_84.xyz;
    uint4 value_85 = asuint(mad(asfloat(r0.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(r1.xyzx))); // mad r5.xyz, r0.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), r1.xyzx
    r5.xyz = value_85.xyz;
    uint4 value_86 = asuint(asfloat(r0.xyzx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u))); // mul r0.xyz, r0.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000)
    r0.xyz = value_86.xyz;
    uint4 value_87 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.x, r0.xyzx, -cb0[4].xyzx
    r0.x = value_87.x;
    uint4 value_88 = asuint(asfloat(r5.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r0.yz, r5.xxzx, -cb0[3].xxyx
    r0.yz = value_88.yz;
    uint4 value_89 = asuint(asfloat(r5.yyyy) + asfloat(uint4(0x0u, 0x0u, 0x3f333333u, 0xbe99999au))); // add r3.zw, r5.yyyy, l(0.000000, 0.000000, 0.700000, -0.300000)
    r3.zw = value_89.zw;
    uint4 value_90 = asuint(asfloat(r0.yyzy) * asfloat(cb0[2].zzzz)); // mul r0.yz, r0.yyzy, cb0[2].zzzz
    r0.yz = value_90.yz;
    uint4 value_91 = asuint(max(asfloat(r0.yyzy), asfloat(cb0[7].xxyx))); // max r0.yz, r0.yyzy, cb0[7].xxyx
    r0.yz = value_91.yz;
    uint4 value_92 = asuint(min(asfloat(r3.xxyx), asfloat(r0.yyzy))); // min r0.yz, r3.xxyx, r0.yyzy
    r0.yz = value_92.yz;
    uint4 value_93 = asuint(max(asfloat(r3.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r3.w, l(0.000000)
    r0.w = value_93.w;
    uint4 value_94 = asuint(saturate(asfloat(r3.zzzz))); // mov_sat r3.z, r3.z
    r3.z = value_94.z;
    uint4 value_95 = asuint(floor(asfloat(r0.wwww))); // round_ni r2.w, r0.w
    r2.w = value_95.w;
    uint4 value_96 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_96.w;
    uint4 value_97 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.x, r2.w
    r3.x = value_97.x;
    uint4 value_98 = asuint(asfloat(r4.zzzz) * asfloat(r2.wwww)); // mul r2.w, r4.z, r2.w
    r2.w = value_98.w;
    uint4 value_99 = (r3.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.y, r3.x, l(1)
    r3.y = value_99.y;
    uint4 value_100 = asuint(float4(asint(r3.yyyy))); // itof r3.w, r3.y
    r3.w = value_100.w;
    uint4 value_101 = asuint(asfloat(r4.zzzz) * asfloat(r3.wwww)); // mul r3.w, r4.z, r3.w
    r3.w = value_101.w;
    uint4 value_102 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.x, r3.w
    r4.x = value_102.x;
    uint4 value_103 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_103.w;
    uint4 value_104 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r0.zzzz))); // mad r5.y, cb0[2].y, r3.w, r0.z
    r5.y = value_104.y;
    uint4 value_105 = (asuint(-asint(r4.xxxx)) * r4.yyyy + r3.yyyy); // imad r3.y, -r4.x, r4.y, r3.y
    r3.y = value_105.y;
    uint4 value_106 = asuint(float4(r3.yyyy)); // utof r3.y, r3.y
    r3.y = value_106.y;
    uint4 value_107 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.yyyy), asfloat(r0.yyyy))); // mad r5.x, cb0[2].x, r3.y, r0.y
    r5.x = value_107.x;
    uint4 value_108 = asuint(t2.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t2.xyzw, s0, l(0.000000)
    r6.xyzw = value_108.xyzw;
    uint4 value_109 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.y, r5.y, l(1.000000)
    r3.y = value_109.y;
    uint4 value_110 = (r3.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.y, r3.y, l(0x3f800000)
    r3.y = value_110.y;
    uint4 value_111 = asuint(asfloat(asuint(-asfloat(r6.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r4.xzw, -r6.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r4.xzw = value_111.xzw;
    uint4 value_112 = asuint(mad(asfloat(r3.yyyy), asfloat(r4.xxzw), asfloat(r6.xxyz))); // mad r4.xzw, r3.yyyy, r4.xxzw, r6.xxyz
    r4.xzw = value_112.xzw;
    uint4 value_113 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.y, r2.w
    r3.y = value_113.y;
    uint4 value_114 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_114.w;
    uint4 value_115 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r0.zzzz))); // mad r5.y, cb0[2].y, r2.w, r0.z
    r5.y = value_115.y;
    uint4 value_116 = (asuint(-asint(r3.yyyy)) * r4.yyyy + r3.xxxx); // imad r0.z, -r3.y, r4.y, r3.x
    r0.z = value_116.z;
    uint4 value_117 = asuint(float4(r0.zzzz)); // utof r0.z, r0.z
    r0.z = value_117.z;
    uint4 value_118 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.zzzz), asfloat(r0.yyyy))); // mad r5.x, cb0[2].x, r0.z, r0.y
    r5.x = value_118.x;
    uint4 value_119 = asuint(t2.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t2.xyzw, s0, l(0.000000)
    r6.xyzw = value_119.xyzw;
    uint4 value_120 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.y, r5.y, l(1.000000)
    r0.y = value_120.y;
    uint4 value_121 = (r0.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.y, r0.y, l(0x3f800000)
    r0.y = value_121.y;
    uint4 value_122 = asuint(asfloat(asuint(-asfloat(r6.xyxz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x3f800000u))); // add r3.xyw, -r6.xyxz, l(1.000000, 1.000000, 0.000000, 1.000000)
    r3.xyw = value_122.xyw;
    uint4 value_123 = asuint(mad(asfloat(r0.yyyy), asfloat(r3.xyxw), asfloat(r6.xyxz))); // mad r3.xyw, r0.yyyy, r3.xyxw, r6.xyxz
    r3.xyw = value_123.xyw;
    uint4 value_124 = asuint(asfloat(asuint(-asfloat(r3.xywx))) + asfloat(r4.xzwx)); // add r4.xyz, -r3.xywx, r4.xzwx
    r4.xyz = value_124.xyz;
    uint4 value_125 = asuint(mad(asfloat(r0.wwww), asfloat(r4.xxyz), asfloat(r3.xxyw))); // mad r0.yzw, r0.wwww, r4.xxyz, r3.xxyw
    r0.yzw = value_125.yzw;
    uint4 value_126 = asuint(asfloat(r0.yyzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r0.yzw, r0.yyzw, -cb0[9].xxyz
    r0.yzw = value_126.yzw;
    uint4 value_127 = asuint(mad(asfloat(r3.zzzz), asfloat(r0.yyzw), asfloat(cb0[9].xxyz))); // mad r0.yzw, r3.zzzz, r0.yyzw, cb0[9].xxyz
    r0.yzw = value_127.yzw;
    uint4 value_128 = asuint(asfloat(r0.yzwy) * asfloat(r2.xyzx)); // mul r3.xyz, r0.yzwy, r2.xyzx
    r3.xyz = value_128.xyz;
    uint4 value_129 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r2.w, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r2.w = value_129.w;
    uint4 value_130 = asuint(mad(asfloat(r2.xxyz), asfloat(r0.yyzw), asfloat(asuint(-asfloat(r2.wwww))))); // mad r0.yzw, r2.xxyz, r0.yyzw, -r2.wwww
    r0.yzw = value_130.yzw;
    uint4 value_131 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r2.x, cb0[5].w, cb0[6].w
    r2.x = value_131.x;
    uint4 value_132 = asuint(saturate(asfloat(asuint(asfloat(r2.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r2.x, r2.x, l(0.500000)
    r2.x = value_132.x;
    uint4 value_133 = asuint(asfloat(r2.xxxx) * asfloat(cb0[29].xxxx)); // mul r2.x, r2.x, cb0[29].x
    r2.x = value_133.x;
    uint4 value_134 = asuint(mad(asfloat(r2.xxxx), asfloat(r0.yyzw), asfloat(r2.wwww))); // mad r0.yzw, r2.xxxx, r0.yyzw, r2.wwww
    r0.yzw = value_134.yzw;
    uint4 value_135 = asuint(asfloat(r1.yyyy) * asfloat(cb0[31].xyzx)); // mul r2.xyz, r1.yyyy, cb0[31].xyzx
    r2.xyz = value_135.xyz;
    uint4 value_136 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r1.xxxx), asfloat(r2.xyzx))); // mad r2.xyz, cb0[30].xyzx, r1.xxxx, r2.xyzx
    r2.xyz = value_136.xyz;
    uint4 value_137 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r1.zzzz), asfloat(r2.xyzx))); // mad r1.xyz, cb0[32].xyzx, r1.zzzz, r2.xyzx
    r1.xyz = value_137.xyz;
    uint4 value_138 = asuint(asfloat(r1.xyzx) + asfloat(cb0[33].xyzx)); // add r1.xyz, r1.xyzx, cb0[33].xyzx
    r1.xyz = value_138.xyz;
    uint4 value_139 = asuint(asfloat(r1.xyxx) * asfloat(cb0[39].zwzz)); // mul r1.xy, r1.xyxx, cb0[39].zwzz
    r1.xy = value_139.xy;
    uint4 value_140 = asuint(frac(asfloat(r1.xyxx))); // frc r2.xy, r1.xyxx
    r2.xy = value_140.xy;
    uint4 value_141 = asuint(asfloat(r0.xxxx) * asfloat(cb0[38].yyyy)); // mul r2.z, r0.x, cb0[38].y
    r2.z = value_141.z;
    uint4 value_142 = asuint(saturate(asfloat(r0.xxxx))); // mov_sat r0.x, r0.x
    r0.x = value_142.x;
    uint4 value_143 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_143.x;
    uint4 value_144 = asuint(mad(asfloat(asuint(-asfloat(r2.zzzz))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r1.zzzz))); // mad r1.z, -r2.z, l(0.050000), r1.z
    r1.z = value_144.z;
    uint4 value_145 = asuint(asfloat(r1.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r1.z, r1.z, l(-0.003922)
    r1.z = value_145.z;
    uint4 value_146 = asuint(asfloat(r1.xxxy) * asfloat(cb0[39].xxxy)); // mul r3.zw, r1.xxxy, cb0[39].xxxy
    r3.zw = value_146.zw;
    uint4 value_147 = asuint(mad(asfloat(r1.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r3.xy, r1.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r3.xy = value_147.xy;
    uint4 value_148 = asuint(t3.SampleLevel(s2, asfloat(r3.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.zyzz, t3.xyzw, s2, l(0.000000)
    r4.xyzw = value_148.xyzw;
    uint4 value_149 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r1.zzzz, -r4.xyzx
    r4.xyz = value_149.xyz;
    uint4 value_150 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r1.x, cb0[38].x, l(20.000000)
    r1.x = value_150.x;
    uint4 value_151 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r1.xxxx, r4.xyzx
    r4.xyz = value_151.xyz;
    uint4 value_152 = asuint(asfloat(asuint(-asfloat(r2.xxxy))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r2.zw, -r2.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    r2.zw = value_152.zw;
    uint4 value_153 = asuint(asfloat(r2.zzzz) * asfloat(r4.xyzx)); // mul r4.xyz, r2.zzzz, r4.xyzx
    r4.xyz = value_153.xyz;
    uint4 value_154 = asuint(asfloat(r2.yyyy) * asfloat(r4.xyzx)); // mul r4.xyz, r2.yyyy, r4.xyzx
    r4.xyz = value_154.xyz;
    uint4 value_155 = asuint(t3.SampleLevel(s2, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t3.xyzw, s2, l(0.000000)
    r5.xyzw = value_155.xyzw;
    uint4 value_156 = asuint(t3.SampleLevel(s2, asfloat(r3.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r3.xwxx, t3.xyzw, s2, l(0.000000)
    r6.xyzw = value_156.xyzw;
    uint4 value_157 = asuint(t3.SampleLevel(s2, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.xyxx, t3.xyzw, s2, l(0.000000)
    r3.xyzw = value_157.xyzw;
    uint4 value_158 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r3.xyz, r1.zzzz, -r3.xyzx
    r3.xyz = value_158.xyz;
    uint4 value_159 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r3.xyzx))))); // mul_sat r3.xyz, r1.xxxx, r3.xyzx
    r3.xyz = value_159.xyz;
    uint4 value_160 = asuint(asfloat(r2.xxxx) * asfloat(r3.xyzx)); // mul r3.xyz, r2.xxxx, r3.xyzx
    r3.xyz = value_160.xyz;
    uint4 value_161 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r1.zzzz, -r6.xyzx
    r6.xyz = value_161.xyz;
    uint4 value_162 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r1.zzzz, -r5.xyzx
    r5.xyz = value_162.xyz;
    uint4 value_163 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r1.xxxx, r5.xyzx
    r5.xyz = value_163.xyz;
    uint4 value_164 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r6.xyzx))))); // mul_sat r1.xyz, r1.xxxx, r6.xyzx
    r1.xyz = value_164.xyz;
    uint4 value_165 = asuint(asfloat(r2.xxxx) * asfloat(r1.xyzx)); // mul r1.xyz, r2.xxxx, r1.xyzx
    r1.xyz = value_165.xyz;
    uint4 value_166 = asuint(asfloat(r2.zzzz) * asfloat(r5.xyzx)); // mul r5.xyz, r2.zzzz, r5.xyzx
    r5.xyz = value_166.xyz;
    uint4 value_167 = asuint(mad(asfloat(r5.xyzx), asfloat(r2.wwww), asfloat(r4.xyzx))); // mad r4.xyz, r5.xyzx, r2.wwww, r4.xyzx
    r4.xyz = value_167.xyz;
    uint4 value_168 = asuint(mad(asfloat(r1.xyzx), asfloat(r2.wwww), asfloat(r4.xyzx))); // mad r1.xyz, r1.xyzx, r2.wwww, r4.xyzx
    r1.xyz = value_168.xyz;
    uint4 value_169 = asuint(mad(asfloat(r3.xyzx), asfloat(r2.yyyy), asfloat(r1.xyzx))); // mad r1.xyz, r3.xyzx, r2.yyyy, r1.xyzx
    r1.xyz = value_169.xyz;
    uint4 value_170 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r1.x, r1.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r1.x = value_170.x;
    uint4 value_171 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.x, l(1.000000)
    r1.x = value_171.x;
    uint4 value_172 = asuint(asfloat(r0.xxxx) * asfloat(r0.xxxx)); // mul r1.y, r0.x, r0.x
    r1.y = value_172.y;
    uint4 value_173 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r1.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.x, -r0.x, r1.y, l(1.000000)
    r0.x = value_173.x;
    uint4 value_174 = asuint(asfloat(r0.xxxx) * asfloat(r1.xxxx)); // mul r0.x, r0.x, r1.x
    r0.x = value_174.x;
    uint4 value_175 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].wwww)); // mul r0.x, r0.x, cb0[5].w
    r0.x = value_175.x;
    uint4 value_176 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_176.xyz;
    uint4 value_177 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_177.xyz;
    uint4 value_178 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r0.xxxx, r2.xyzx, r1.xyzx
    r1.xyz = value_178.xyz;
    uint4 value_179 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.xxxx, cb0[5].xyzx
    r2.xyz = value_179.xyz;
    uint4 value_180 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_180.xyz;
    uint4 value_181 = asuint(mad(asfloat(r0.yyzw), asfloat(r1.xxyz), asfloat(r2.xxyz))); // mad r0.yzw, r0.yyzw, r1.xxyz, r2.xxyz
    r0.yzw = value_181.yzw;
    uint4 value_182 = asuint(asfloat(r0.yyzw) + asfloat(uint4(0x0u, 0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu))); // add r0.yzw, r0.yyzw, l(0.000000, 0.100000, 0.100000, 0.100000)
    r0.yzw = value_182.yzw;
    uint4 value_183 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r1.x, cb0[5].w, -cb0[6].w
    r1.x = value_183.x;
    uint4 value_184 = asuint(mad(asfloat(r0.xxxx), asfloat(r1.xxxx), asfloat(cb0[6].wwww))); // mad r0.x, r0.x, r1.x, cb0[6].w
    r0.x = value_184.x;
    uint4 value_185 = asuint(asfloat(v4.xxxx) * asfloat(cb0[15].zzzz)); // mul r1.x, v4.x, cb0[15].z
    r1.x = value_185.x;
    uint4 value_186 = asuint(floor(asfloat(asuint(abs(asfloat(r1.xxxx)))))); // round_ni r1.x, |r1.x|
    r1.x = value_186.x;
    uint4 value_187 = asuint(asfloat(r1.xxxx) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r1.x, r1.x, l(0.500000)
    r1.x = value_187.x;
    uint4 value_188 = asuint(asfloat(r1.xxxx) * asfloat(cb0[15].xxxx)); // mul r1.x, r1.x, cb0[15].x
    r1.x = value_188.x;
    uint4 value_189 = uint4(0x3e800000u, 0x3e800000u, 0x3e800000u, 0x3e800000u); // mov r1.y, l(0.250000)
    r1.y = value_189.y;
    uint4 value_190 = asuint(t1.SampleLevel(s1, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r1.xyxx, t1.xyzw, s1, l(0.000000)
    r2.xyzw = value_190.xyzw;
    uint4 value_191 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(cb0[11].xyzx)); // add r1.xyz, -r2.xyzx, cb0[11].xyzx
    r1.xyz = value_191.xyz;
    uint4 value_192 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3eb33333u, 0x0u)), asfloat(r2.xyzx)))))); // mad_sat r2.xyz, r1.xyzx, l(0.350000, 0.350000, 0.350000, 0.000000), r2.xyzx
    r2.xyz = value_192.xyz;
    uint4 value_193 = asuint(t0.SampleLevel(s3, asfloat(v1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, v1.xyxx, t0.xyzw, s3, l(0.000000)
    r3.xyzw = value_193.xyzw;
    uint4 value_194 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.x, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.x = value_194.x;
    uint4 value_195 = r3.wwww; // mov r1.y, r3.w
    r1.y = value_195.y;
    uint4 value_196 = asuint(asfloat(r1.xxxy) + asfloat(r2.xyzw)); // add r4.xyzw, r1.xxxy, r2.xyzw
    r4.xyzw = value_196.xyzw;
    uint4 value_197 = asuint(asfloat(r4.xyzw) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r4.xyzw, r4.xyzw, l(-0.500000, -0.500000, -0.500000, -0.500000)
    r4.xyzw = value_197.xyzw;
    uint4 value_198 = asuint(max(asfloat(r4.xyzw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r4.xyzw, r4.xyzw, l(0.000000, 0.000000, 0.000000, 0.000000)
    r4.xyzw = value_198.xyzw;
    uint4 value_199 = asuint(asfloat(asuint(-asfloat(r2.xyzw))) + asfloat(r4.xyzw)); // add r4.xyzw, -r2.xyzw, r4.xyzw
    r4.xyzw = value_199.xyzw;
    uint4 value_200 = asuint(mad(asfloat(r3.wwww), asfloat(r4.xyzw), asfloat(r2.xyzw))); // mad r2.xyzw, r3.wwww, r4.xyzw, r2.xyzw
    r2.xyzw = value_200.xyzw;
    uint4 value_201 = asuint(asfloat(asuint(-asfloat(r2.xyzw))) + asfloat(r3.xyzw)); // add r4.xyzw, -r2.xyzw, r3.xyzw
    r4.xyzw = value_201.xyzw;
    uint4 value_202 = asuint(mad(asfloat(r3.wwww), asfloat(r4.xyzw), asfloat(r2.xyzw))); // mad r2.xyzw, r3.wwww, r4.xyzw, r2.xyzw
    r2.xyzw = value_202.xyzw;
    uint4 value_203 = asuint(asfloat(r2.xyzx) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0x0u))); // add r1.xyz, r2.xyzx, l(-0.700000, -0.700000, -0.700000, 0.000000)
    r1.xyz = value_203.xyz;
    uint4 value_204 = r2.wwww; // mov o1.w, r2.w
    out_o1.w = value_204.w;
    uint4 value_205 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r1.xyzx), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x0u)))); // mad r1.xyz, cb0[29].xxxx, r1.xyzx, l(0.700000, 0.700000, 0.700000, 0.000000)
    r1.xyz = value_205.xyz;
    uint4 value_206 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r2.x, r1.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r2.x = value_206.x;
    uint4 value_207 = asuint(asfloat(r1.xxyz) + asfloat(asuint(-asfloat(r2.xxxx)))); // add r2.yzw, r1.xxyz, -r2.xxxx
    r2.yzw = value_207.yzw;
    uint4 value_208 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.yzwy), asfloat(r2.xxxx))); // mad r2.xyz, r0.xxxx, r2.yzwy, r2.xxxx
    r2.xyz = value_208.xyz;
    uint4 value_209 = asuint(asfloat(r0.yzwy) * asfloat(r2.xyzx)); // mul r0.xyz, r0.yzwy, r2.xyzx
    r0.xyz = value_209.xyz;
    uint4 value_210 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_210.w;
    uint4 value_211 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r2.x, -r0.w, l(0.600000)
    r2.x = value_211.x;
    uint4 value_212 = asuint(asfloat(r0.wwww) + asfloat(asuint(-asfloat(r2.xxxx)))); // add r0.w, r0.w, -r2.x
    r0.w = value_212.w;
    uint4 value_213 = asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r0.wwww, l(0.100000, 0.100000, 0.100000, 0.000000), r0.xyzx
    r0.xyz = value_213.xyz;
    uint4 value_214 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r0.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_214.xyz;
    uint4 value_215 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r0.xyzx
    r0.xyz = value_215.xyz;
    uint4 value_216 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(r0.xyzx)); // add r0.xyz, -r1.xyzx, r0.xyzx
    r0.xyz = value_216.xyz;
    uint4 value_217 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.xyzx), asfloat(r1.xyzx))); // mad r0.xyz, cb0[29].yyyy, r0.xyzx, r1.xyzx
    r0.xyz = value_217.xyz;
    uint4 value_218 = asuint(asfloat(r1.wwww) * asfloat(r0.xyzx)); // mul o1.xyz, r1.wwww, r0.xyzx
    out_o1.xyz = value_218.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xyzw);
    return result;
}
