// Register-explicit recovered HLSL. Not original source.
// Placemaker/Window vs_4_0 variant []
// Source SHA256 ecbdd24604c8eb120d89a2d985201276dc4e6b801780c37488e70c643e6076b7
// b0: $Globals 688 bytes
// b1: UnityPerCamera 144 bytes
// b2: UnityPerDraw 176 bytes
// b3: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// t0 / s0 = _AoTex
// t1 / s1 = _VoxelTex
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
cbuffer Buffer1:register(b1) { uint4 cb1[5]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[13]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 17
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: NORMAL0;
    float4 v3_0: TANGENT0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD2;
    float2 o1_0: TEXCOORD1;
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
    uint4 r11;
    uint4 r12;
    uint4 r13;
    uint4 r14;
    uint4 r15;
    uint4 r16;
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
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb2[1].xyzw
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(mad(asfloat(cb2[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb2[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb2[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(asfloat(v2.yyyy) * asfloat(cb2[1].xyzx)); // mul r1.xyz, v2.yyyy, cb2[1].xyzx
    r1.xyz = value_5.xyz;
    uint4 value_6 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v2.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb2[0].xyzx, v2.xxxx, r1.xyzx
    r1.xyz = value_6.xyz;
    uint4 value_7 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v2.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb2[2].xyzx, v2.zzzz, r1.xyzx
    r1.xyz = value_7.xyz;
    uint4 value_8 = asuint(asfloat(v3.yyyy) * asfloat(cb2[1].xyzx)); // mul r2.xyz, v3.yyyy, cb2[1].xyzx
    r2.xyz = value_8.xyz;
    uint4 value_9 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v3.xxxx), asfloat(r2.xyzx))); // mad r2.xyz, cb2[0].xyzx, v3.xxxx, r2.xyzx
    r2.xyz = value_9.xyz;
    uint4 value_10 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v3.zzzz), asfloat(r2.xyzx))); // mad r2.xyz, cb2[2].xyzx, v3.zzzz, r2.xyzx
    r2.xyz = value_10.xyz;
    uint4 value_11 = asuint(asfloat(r2.xyzx) * asfloat(v3.wwww)); // mul r2.xyz, r2.xyzx, v3.wwww
    r2.xyz = value_11.xyz;
    uint4 value_12 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r3.xyz, r1.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000), r0.xyzx
    r3.xyz = value_12.xyz;
    uint4 value_13 = asuint(asfloat(r3.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r3.yw, r3.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r3.yw = value_13.yw;
    uint4 value_14 = asuint(max(asfloat(r3.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r3.w, l(0.000000)
    r1.w = value_14.w;
    uint4 value_15 = asuint(floor(asfloat(r1.wwww))); // round_ni r2.w, r1.w
    r2.w = value_15.w;
    uint4 value_16 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.w, r2.w
    r3.w = value_16.w;
    uint4 value_17 = (r3.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r4.x, r3.w, l(1)
    r4.x = value_17.x;
    uint4 value_18 = asuint(asfloat(r3.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r3.xz, r3.xxzx, -cb0[3].xxyx
    r3.xz = value_18.xz;
    uint4 value_19 = asuint(asfloat(r3.xxzx) * asfloat(cb0[2].zzzz)); // mul r3.xz, r3.xxzx, cb0[2].zzzz
    r3.xz = value_19.xz;
    uint4 value_20 = asuint(asfloat(cb0[2].xxyx) + asfloat(asuint(-asfloat(cb0[7].xxyx)))); // add r4.yz, cb0[2].xxyx, -cb0[7].xxyx
    r4.yz = value_20.yz;
    uint4 value_21 = asuint(max(asfloat(r3.xxzx), asfloat(cb0[7].xxyx))); // max r3.xz, r3.xxzx, cb0[7].xxyx
    r3.xz = value_21.xz;
    uint4 value_22 = asuint(min(asfloat(r4.yyzy), asfloat(r3.xxzx))); // min r3.xz, r4.yyzy, r3.xxzx
    r3.xz = value_22.xz;
    uint4 value_23 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r4.w, cb0[2].w
    r4.w = value_23.w;
    uint4 value_24 = uint4(asfloat(r4.wwww)); // ftou r4.w, r4.w
    r4.w = value_24.w;
    uint4 value_25 = asuint(float4(r4.wwww)); // utof r5.x, r4.w
    r5.x = value_25.x;
    uint4 value_26 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r5.xxxx)); // div r5.x, l(1.000000, 1.000000, 1.000000, 1.000000), r5.x
    r5.x = value_26.x;
    uint4 value_27 = asuint(asfloat(r2.wwww) * asfloat(r5.xxxx)); // mul r2.w, r2.w, r5.x
    r2.w = value_27.w;
    uint4 value_28 = asuint(int4(asfloat(r2.wwww))); // ftoi r5.y, r2.w
    r5.y = value_28.y;
    uint4 value_29 = asuint(float4(asint(r4.xxxx))); // itof r5.z, r4.x
    r5.z = value_29.z;
    uint4 value_30 = asuint(asfloat(r5.xxxx) * asfloat(r5.zzzz)); // mul r5.z, r5.x, r5.z
    r5.z = value_30.z;
    uint4 value_31 = asuint(int4(asfloat(r5.zzzz))); // ftoi r5.w, r5.z
    r5.w = value_31.w;
    uint4 value_32 = (asuint(-asint(r5.yyyy)) * r4.wwww + r3.wwww); // imad r3.w, -r5.y, r4.w, r3.w
    r3.w = value_32.w;
    uint4 value_33 = asuint(float4(r3.wwww)); // utof r3.w, r3.w
    r3.w = value_33.w;
    uint4 value_34 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.wwww), asfloat(r3.xxxx))); // mad r6.x, cb0[2].x, r3.w, r3.x
    r6.x = value_34.x;
    uint4 value_35 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_35.w;
    uint4 value_36 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r3.zzzz))); // mad r6.y, cb0[2].y, r2.w, r3.z
    r6.y = value_36.y;
    uint4 value_37 = (asuint(-asint(r5.wwww)) * r4.wwww + r4.xxxx); // imad r2.w, -r5.w, r4.w, r4.x
    r2.w = value_37.w;
    uint4 value_38 = asuint(float4(r2.wwww)); // utof r2.w, r2.w
    r2.w = value_38.w;
    uint4 value_39 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.wwww), asfloat(r3.xxxx))); // mad r7.x, cb0[2].x, r2.w, r3.x
    r7.x = value_39.x;
    uint4 value_40 = asuint(trunc(asfloat(r5.zzzz))); // round_z r2.w, r5.z
    r2.w = value_40.w;
    uint4 value_41 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r3.zzzz))); // mad r7.y, cb0[2].y, r2.w, r3.z
    r7.y = value_41.y;
    uint4 value_42 = asuint(t0.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r6.xyxx, t0.xyzw, s0, l(0.000000)
    r8.xyzw = value_42.xyzw;
    uint4 value_43 = asuint(t0.SampleLevel(s0, asfloat(r7.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r9.xyzw, r7.xyxx, t0.xyzw, s0, l(0.000000)
    r9.xyzw = value_43.xyzw;
    uint4 value_44 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.w, r6.y, l(1.000000)
    r2.w = value_44.w;
    uint4 value_45 = (r2.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.w, r2.w, l(0x3f800000)
    r2.w = value_45.w;
    uint4 value_46 = asuint(asfloat(asuint(-asfloat(r8.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r3.xzw, -r8.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r3.xzw = value_46.xzw;
    uint4 value_47 = asuint(mad(asfloat(r2.wwww), asfloat(r3.xzwx), asfloat(r8.xyzx))); // mad r8.xyz, r2.wwww, r3.xzwx, r8.xyzx
    r8.xyz = value_47.xyz;
    uint4 value_48 = ((asfloat(r7.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.w, r7.y, l(1.000000)
    r2.w = value_48.w;
    uint4 value_49 = (r2.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.w, r2.w, l(0x3f800000)
    r2.w = value_49.w;
    uint4 value_50 = asuint(asfloat(asuint(-asfloat(r9.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r3.xzw, -r9.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r3.xzw = value_50.xzw;
    uint4 value_51 = asuint(mad(asfloat(r2.wwww), asfloat(r3.xzwx), asfloat(r9.xyzx))); // mad r9.xyz, r2.wwww, r3.xzwx, r9.xyzx
    r9.xyz = value_51.xyz;
    uint4 value_52 = asuint(frac(asfloat(r1.wwww))); // frc r1.w, r1.w
    r1.w = value_52.w;
    uint4 value_53 = asuint(asfloat(asuint(-asfloat(r8.xyzw))) + asfloat(r9.xyzw)); // add r6.xyzw, -r8.xyzw, r9.xyzw
    r6.xyzw = value_53.xyzw;
    uint4 value_54 = asuint(mad(asfloat(r1.wwww), asfloat(r6.xyzw), asfloat(r8.xyzw))); // mad r6.xyzw, r1.wwww, r6.xyzw, r8.xyzw
    r6.xyzw = value_54.xyzw;
    uint4 value_55 = asuint(saturate(asfloat(r3.yyyy))); // mov_sat r3.y, r3.y
    r3.y = value_55.y;
    uint4 value_56 = asuint(asfloat(r6.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r6.xyzw, r6.xyzw, -cb0[9].xyzw
    r6.xyzw = value_56.xyzw;
    uint4 value_57 = asuint(mad(asfloat(r3.yyyy), asfloat(r6.xyzw), asfloat(cb0[9].xyzw))); // mad r3.xyzw, r3.yyyy, r6.xyzw, cb0[9].xyzw
    r3.xyzw = value_57.xyzw;
    uint4 value_58 = asuint(asfloat(r0.xxyz) + asfloat(r1.xxyz)); // add r5.yzw, r0.xxyz, r1.xxyz
    r5.yzw = value_58.yzw;
    uint4 value_59 = asuint(asfloat(r5.zzzz) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r6.xy, r5.zzzz, l(0.700000, -0.300000, 0.000000, 0.000000)
    r6.xy = value_59.xy;
    uint4 value_60 = asuint(max(asfloat(r6.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r6.y, l(0.000000)
    r1.w = value_60.w;
    uint4 value_61 = asuint(floor(asfloat(r1.wwww))); // round_ni r2.w, r1.w
    r2.w = value_61.w;
    uint4 value_62 = asuint(int4(asfloat(r2.wwww))); // ftoi r4.x, r2.w
    r4.x = value_62.x;
    uint4 value_63 = (r4.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r5.z, r4.x, l(1)
    r5.z = value_63.z;
    uint4 value_64 = asuint(asfloat(r5.yyyw) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r5.yw, r5.yyyw, -cb0[3].xxxy
    r5.yw = value_64.yw;
    uint4 value_65 = asuint(asfloat(r5.yyyw) * asfloat(cb0[2].zzzz)); // mul r5.yw, r5.yyyw, cb0[2].zzzz
    r5.yw = value_65.yw;
    uint4 value_66 = asuint(max(asfloat(r5.yyyw), asfloat(cb0[7].xxxy))); // max r5.yw, r5.yyyw, cb0[7].xxxy
    r5.yw = value_66.yw;
    uint4 value_67 = asuint(min(asfloat(r4.yyyz), asfloat(r5.yyyw))); // min r5.yw, r4.yyyz, r5.yyyw
    r5.yw = value_67.yw;
    uint4 value_68 = asuint(asfloat(r5.xxxx) * asfloat(r2.wwww)); // mul r2.w, r5.x, r2.w
    r2.w = value_68.w;
    uint4 value_69 = asuint(int4(asfloat(r2.wwww))); // ftoi r6.y, r2.w
    r6.y = value_69.y;
    uint4 value_70 = asuint(float4(asint(r5.zzzz))); // itof r6.z, r5.z
    r6.z = value_70.z;
    uint4 value_71 = asuint(asfloat(r5.xxxx) * asfloat(r6.zzzz)); // mul r6.z, r5.x, r6.z
    r6.z = value_71.z;
    uint4 value_72 = asuint(int4(asfloat(r6.zzzz))); // ftoi r6.w, r6.z
    r6.w = value_72.w;
    uint4 value_73 = (asuint(-asint(r6.yyyy)) * r4.wwww + r4.xxxx); // imad r4.x, -r6.y, r4.w, r4.x
    r4.x = value_73.x;
    uint4 value_74 = asuint(float4(r4.xxxx)); // utof r4.x, r4.x
    r4.x = value_74.x;
    uint4 value_75 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r4.xxxx), asfloat(r5.yyyy))); // mad r7.x, cb0[2].x, r4.x, r5.y
    r7.x = value_75.x;
    uint4 value_76 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_76.w;
    uint4 value_77 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r5.wwww))); // mad r7.y, cb0[2].y, r2.w, r5.w
    r7.y = value_77.y;
    uint4 value_78 = (asuint(-asint(r6.wwww)) * r4.wwww + r5.zzzz); // imad r2.w, -r6.w, r4.w, r5.z
    r2.w = value_78.w;
    uint4 value_79 = asuint(float4(r2.wwww)); // utof r2.w, r2.w
    r2.w = value_79.w;
    uint4 value_80 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.wwww), asfloat(r5.yyyy))); // mad r8.x, cb0[2].x, r2.w, r5.y
    r8.x = value_80.x;
    uint4 value_81 = asuint(trunc(asfloat(r6.zzzz))); // round_z r2.w, r6.z
    r2.w = value_81.w;
    uint4 value_82 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r5.wwww))); // mad r8.y, cb0[2].y, r2.w, r5.w
    r8.y = value_82.y;
    uint4 value_83 = asuint(t0.SampleLevel(s0, asfloat(r7.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r9.xyzw, r7.xyxx, t0.xyzw, s0, l(0.000000)
    r9.xyzw = value_83.xyzw;
    uint4 value_84 = asuint(t0.SampleLevel(s0, asfloat(r8.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r10.xyzw, r8.xyxx, t0.xyzw, s0, l(0.000000)
    r10.xyzw = value_84.xyzw;
    uint4 value_85 = ((asfloat(r7.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.w, r7.y, l(1.000000)
    r2.w = value_85.w;
    uint4 value_86 = (r2.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.w, r2.w, l(0x3f800000)
    r2.w = value_86.w;
    uint4 value_87 = asuint(asfloat(asuint(-asfloat(r9.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r5.yzw, -r9.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r5.yzw = value_87.yzw;
    uint4 value_88 = asuint(mad(asfloat(r2.wwww), asfloat(r5.yzwy), asfloat(r9.xyzx))); // mad r9.xyz, r2.wwww, r5.yzwy, r9.xyzx
    r9.xyz = value_88.xyz;
    uint4 value_89 = ((asfloat(r8.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.w, r8.y, l(1.000000)
    r2.w = value_89.w;
    uint4 value_90 = (r2.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.w, r2.w, l(0x3f800000)
    r2.w = value_90.w;
    uint4 value_91 = asuint(asfloat(asuint(-asfloat(r10.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r5.yzw, -r10.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r5.yzw = value_91.yzw;
    uint4 value_92 = asuint(mad(asfloat(r2.wwww), asfloat(r5.yzwy), asfloat(r10.xyzx))); // mad r10.xyz, r2.wwww, r5.yzwy, r10.xyzx
    r10.xyz = value_92.xyz;
    uint4 value_93 = asuint(frac(asfloat(r1.wwww))); // frc r1.w, r1.w
    r1.w = value_93.w;
    uint4 value_94 = asuint(asfloat(asuint(-asfloat(r9.xyzw))) + asfloat(r10.xyzw)); // add r7.xyzw, -r9.xyzw, r10.xyzw
    r7.xyzw = value_94.xyzw;
    uint4 value_95 = asuint(mad(asfloat(r1.wwww), asfloat(r7.xyzw), asfloat(r9.xyzw))); // mad r7.xyzw, r1.wwww, r7.xyzw, r9.xyzw
    r7.xyzw = value_95.xyzw;
    uint4 value_96 = asuint(saturate(asfloat(r6.xxxx))); // mov_sat r6.x, r6.x
    r6.x = value_96.x;
    uint4 value_97 = asuint(asfloat(r7.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r7.xyzw, r7.xyzw, -cb0[9].xyzw
    r7.xyzw = value_97.xyzw;
    uint4 value_98 = asuint(mad(asfloat(r6.xxxx), asfloat(r7.xyzw), asfloat(cb0[9].xyzw))); // mad r6.xyzw, r6.xxxx, r7.xyzw, cb0[9].xyzw
    r6.xyzw = value_98.xyzw;
    uint4 value_99 = asuint(asfloat(r3.wwww) * asfloat(r6.wwww)); // mul r1.w, r3.w, r6.w
    r1.w = value_99.w;
    uint4 value_100 = asuint(mad(asfloat(r3.xyzx), asfloat(r6.xyzx), asfloat(uint4(0xbf4ccccdu, 0xbf4ccccdu, 0xbf4ccccdu, 0x0u)))); // mad r3.xyz, r3.xyzx, r6.xyzx, l(-0.800000, -0.800000, -0.800000, 0.000000)
    r3.xyz = value_100.xyz;
    uint4 value_101 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r3.xyzx), asfloat(uint4(0x3f4ccccdu, 0x3f4ccccdu, 0x3f4ccccdu, 0x0u)))); // mad o3.xyz, cb0[29].yyyy, r3.xyzx, l(0.800000, 0.800000, 0.800000, 0.000000)
    out_o3.xyz = value_101.xyz;
    uint4 value_102 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r3.xyz, r0.xyzx, -cb0[22].xyzx
    r3.xyz = value_102.xyz;
    uint4 value_103 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(r3.xyzx).xyz)).xxxx; // dp3 r2.w, r3.xyzx, r3.xyzx
    r2.w = value_103.w;
    uint4 value_104 = asuint(asfloat(asuint(-asfloat(r2.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r2.w, -r2.w, l(1.000000)
    r2.w = value_104.w;
    uint4 value_105 = asuint(max(asfloat(r2.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r2.w, r2.w, l(0.000000)
    r2.w = value_105.w;
    uint4 value_106 = asuint(asfloat(r2.wwww) * asfloat(r3.xyzx)); // mul r3.xyz, r2.wwww, r3.xyzx
    r3.xyz = value_106.xyz;
    uint4 value_107 = asuint(asfloat(r3.xxzx) * asfloat(cb0[22].wwww)); // mul r3.xz, r3.xxzx, cb0[22].wwww
    r3.xz = value_107.xz;
    uint4 value_108 = asuint(mad(asfloat(r3.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r2.w, r3.y, cb0[22].w, r0.y
    r2.w = value_108.w;
    uint4 value_109 = asuint(min(asfloat(r2.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r2.w, r2.w, l(0.000000)
    r2.w = value_109.w;
    uint4 value_110 = asuint(mad(asfloat(r3.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r2.wwww))))); // mad r3.w, r3.y, cb0[22].w, -r2.w
    r3.w = value_110.w;
    uint4 value_111 = asuint(asfloat(r0.xyzx) + asfloat(r3.xwzx)); // add r0.xyz, r0.xyzx, r3.xwzx
    r0.xyz = value_111.xyz;
    uint4 value_112 = asuint(asfloat(r1.zxyz) * asfloat(r2.yzxy)); // mul r3.xyz, r1.zxyz, r2.yzxy
    r3.xyz = value_112.xyz;
    uint4 value_113 = asuint(mad(asfloat(r1.yzxy), asfloat(r2.zxyz), asfloat(asuint(-asfloat(r3.xyzx))))); // mad r3.xyz, r1.yzxy, r2.zxyz, -r3.xyzx
    r3.xyz = value_113.xyz;
    uint4 value_114 = asuint(asfloat(asuint(-asfloat(r0.xxyz))) + asfloat(cb1[4].xxyz)); // add r5.yzw, -r0.xxyz, cb1[4].xxyz
    r5.yzw = value_114.yzw;
    uint4 value_115 = asuint(dot(asfloat(r5.yzwy).xyz, asfloat(r5.yzwy).xyz)).xxxx; // dp3 r2.w, r5.yzwy, r5.yzwy
    r2.w = value_115.w;
    uint4 value_116 = asuint(rsqrt(asfloat(r2.wwww))); // rsq r2.w, r2.w
    r2.w = value_116.w;
    uint4 value_117 = asuint(asfloat(r2.wwww) * asfloat(r5.yyzw)); // mul r5.yzw, r2.wwww, r5.yyzw
    r5.yzw = value_117.yzw;
    uint4 value_118 = asuint(dot(asfloat(asuint(-asfloat(r5.yzwy))).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r2.w, -r5.yzwy, r1.xyzx
    r2.w = value_118.w;
    uint4 value_119 = asuint(asfloat(r2.wwww) + asfloat(r2.wwww)); // add r2.w, r2.w, r2.w
    r2.w = value_119.w;
    uint4 value_120 = asuint(mad(asfloat(r1.xyzx), asfloat(asuint(-asfloat(r2.wwww))), asfloat(asuint(-asfloat(r5.yzwy))))); // mad r6.xyz, r1.xyzx, -r2.wwww, -r5.yzwy
    r6.xyz = value_120.xyz;
    uint4 value_121 = asuint(dot(asfloat(r6.xyzx).xyz, asfloat(r6.xyzx).xyz)).xxxx; // dp3 r2.w, r6.xyzx, r6.xyzx
    r2.w = value_121.w;
    uint4 value_122 = asuint(rsqrt(asfloat(r2.wwww))); // rsq r2.w, r2.w
    r2.w = value_122.w;
    uint4 value_123 = asuint(asfloat(r2.wwww) * asfloat(r6.xyzx)); // mul r7.xyz, r2.wwww, r6.xyzx
    r7.xyz = value_123.xyz;
    uint4 value_124 = asuint(mad(asfloat(r6.xyzx), asfloat(r2.wwww), asfloat(uint4(0x40900000u, 0x40900000u, 0x40900000u, 0x0u)))); // mad r6.xyz, r6.xyzx, r2.wwww, l(4.500000, 4.500000, 4.500000, 0.000000)
    r6.xyz = value_124.xyz;
    uint4 value_125 = asuint(mad(asfloat(r1.yyyy), asfloat(uint4(0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu)), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3fc00000u, 0x3fc00000u)))); // mad r2.w, r1.y, l(0.200000), l(1.500000)
    r2.w = value_125.w;
    uint4 value_126 = asuint(asfloat(r2.wwww) * asfloat(cb0[9].xyzx)); // mul r8.xyz, r2.wwww, cb0[9].xyzx
    r8.xyz = value_126.xyz;
    uint4 value_127 = r8.xyzx; // mov r9.xyz, r8.xyzx
    r9.xyz = value_127.xyz;
    uint4 value_128 = r6.xyzx; // mov r10.xyz, r6.xyzx
    r10.xyz = value_128.xyz;
    uint4 value_129 = uint4(0x9u, 0x9u, 0x9u, 0x9u); // mov r2.w, l(9)
    r2.w = value_129.w;
    while (true) {
        uint4 value_131 = ((asint(r2.wwww) < asint(uint4(0x1u, 0x1u, 0x1u, 0x1u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ilt r3.w, r2.w, l(1)
        r3.w = value_131.w;
        if (r3.wwww.x != 0u) break; // breakc_nz r3.w
        uint4 value_133 = asuint(float4(asint(r2.wwww))); // itof r3.w, r2.w
        r3.w = value_133.w;
        uint4 value_134 = asuint(asfloat(r3.wwww) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r3.w, r3.w, l(0.500000)
        r3.w = value_134.w;
        uint4 value_135 = asuint(mad(asfloat(r7.xyzx), asfloat(r3.wwww), asfloat(r0.xyzx))); // mad r11.xyz, r7.xyzx, r3.wwww, r0.xyzx
        r11.xyz = value_135.xyz;
        uint4 value_136 = asuint(asfloat(r11.yyyy) + asfloat(uint4(0x3f000000u, 0xbf000000u, 0x0u, 0x0u))); // add r12.xy, r11.yyyy, l(0.500000, -0.500000, 0.000000, 0.000000)
        r12.xy = value_136.xy;
        uint4 value_137 = asuint(max(asfloat(r12.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r3.w, r12.y, l(0.000000)
        r3.w = value_137.w;
        uint4 value_138 = asuint(floor(asfloat(r3.wwww))); // round_ni r4.x, r3.w
        r4.x = value_138.x;
        uint4 value_139 = asuint(int4(asfloat(r4.xxxx))); // ftoi r6.w, r4.x
        r6.w = value_139.w;
        uint4 value_140 = (r6.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r7.w, r6.w, l(1)
        r7.w = value_140.w;
        uint4 value_141 = asuint(asfloat(r11.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r12.yz, r11.xxzx, -cb0[3].xxyx
        r12.yz = value_141.yz;
        uint4 value_142 = asuint(asfloat(r12.yyzy) * asfloat(cb0[2].zzzz)); // mul r12.yz, r12.yyzy, cb0[2].zzzz
        r12.yz = value_142.yz;
        uint4 value_143 = asuint(max(asfloat(r12.yyzy), asfloat(cb0[7].xxyx))); // max r12.yz, r12.yyzy, cb0[7].xxyx
        r12.yz = value_143.yz;
        uint4 value_144 = asuint(min(asfloat(r4.yyzy), asfloat(r12.yyzy))); // min r12.yz, r4.yyzy, r12.yyzy
        r12.yz = value_144.yz;
        uint4 value_145 = asuint(asfloat(r5.xxxx) * asfloat(r4.xxxx)); // mul r4.x, r5.x, r4.x
        r4.x = value_145.x;
        uint4 value_146 = asuint(int4(asfloat(r4.xxxx))); // ftoi r8.w, r4.x
        r8.w = value_146.w;
        uint4 value_147 = asuint(float4(asint(r7.wwww))); // itof r9.w, r7.w
        r9.w = value_147.w;
        uint4 value_148 = asuint(asfloat(r5.xxxx) * asfloat(r9.wwww)); // mul r9.w, r5.x, r9.w
        r9.w = value_148.w;
        uint4 value_149 = asuint(int4(asfloat(r9.wwww))); // ftoi r10.w, r9.w
        r10.w = value_149.w;
        uint4 value_150 = (asuint(-asint(r8.wwww)) * r4.wwww + r6.wwww); // imad r6.w, -r8.w, r4.w, r6.w
        r6.w = value_150.w;
        uint4 value_151 = asuint(float4(r6.wwww)); // utof r6.w, r6.w
        r6.w = value_151.w;
        uint4 value_152 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r6.wwww), asfloat(r12.yyyy))); // mad r13.x, cb0[2].x, r6.w, r12.y
        r13.x = value_152.x;
        uint4 value_153 = asuint(trunc(asfloat(r4.xxxx))); // round_z r4.x, r4.x
        r4.x = value_153.x;
        uint4 value_154 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r4.xxxx), asfloat(r12.zzzz))); // mad r13.y, cb0[2].y, r4.x, r12.z
        r13.y = value_154.y;
        uint4 value_155 = (asuint(-asint(r10.wwww)) * r4.wwww + r7.wwww); // imad r4.x, -r10.w, r4.w, r7.w
        r4.x = value_155.x;
        uint4 value_156 = asuint(float4(r4.xxxx)); // utof r4.x, r4.x
        r4.x = value_156.x;
        uint4 value_157 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r4.xxxx), asfloat(r12.yyyy))); // mad r14.x, cb0[2].x, r4.x, r12.y
        r14.x = value_157.x;
        uint4 value_158 = asuint(trunc(asfloat(r9.wwww))); // round_z r4.x, r9.w
        r4.x = value_158.x;
        uint4 value_159 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r4.xxxx), asfloat(r12.zzzz))); // mad r14.y, cb0[2].y, r4.x, r12.z
        r14.y = value_159.y;
        uint4 value_160 = asuint(t1.SampleLevel(s1, asfloat(r13.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r15.xyzw, r13.xyxx, t1.xyzw, s1, l(0.000000)
        r15.xyzw = value_160.xyzw;
        uint4 value_161 = asuint(t1.SampleLevel(s1, asfloat(r14.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r16.xyzw, r14.xyxx, t1.xyzw, s1, l(0.000000)
        r16.xyzw = value_161.xyzw;
        uint4 value_162 = ((asfloat(r13.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r4.x, r13.y, l(1.000000)
        r4.x = value_162.x;
        uint4 value_163 = (r4.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r4.x, r4.x, l(0x3f800000)
        r4.x = value_163.x;
        uint4 value_164 = asuint(asfloat(asuint(-asfloat(r15.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r12.yzw, -r15.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
        r12.yzw = value_164.yzw;
        uint4 value_165 = asuint(mad(asfloat(r4.xxxx), asfloat(r12.yzwy), asfloat(r15.xyzx))); // mad r15.xyz, r4.xxxx, r12.yzwy, r15.xyzx
        r15.xyz = value_165.xyz;
        uint4 value_166 = ((asfloat(r14.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r4.x, r14.y, l(1.000000)
        r4.x = value_166.x;
        uint4 value_167 = (r4.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r4.x, r4.x, l(0x3f800000)
        r4.x = value_167.x;
        uint4 value_168 = asuint(asfloat(asuint(-asfloat(r16.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r12.yzw, -r16.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
        r12.yzw = value_168.yzw;
        uint4 value_169 = asuint(mad(asfloat(r4.xxxx), asfloat(r12.yzwy), asfloat(r16.xyzx))); // mad r16.xyz, r4.xxxx, r12.yzwy, r16.xyzx
        r16.xyz = value_169.xyz;
        uint4 value_170 = asuint(frac(asfloat(r3.wwww))); // frc r3.w, r3.w
        r3.w = value_170.w;
        uint4 value_171 = asuint(asfloat(asuint(-asfloat(r15.xyzw))) + asfloat(r16.xyzw)); // add r13.xyzw, -r15.xyzw, r16.xyzw
        r13.xyzw = value_171.xyzw;
        uint4 value_172 = asuint(mad(asfloat(r3.wwww), asfloat(r13.xyzw), asfloat(r15.xyzw))); // mad r13.xyzw, r3.wwww, r13.xyzw, r15.xyzw
        r13.xyzw = value_172.xyzw;
        uint4 value_173 = asuint(saturate(asfloat(r12.xxxx))); // mov_sat r12.x, r12.x
        r12.x = value_173.x;
        uint4 value_174 = asuint(asfloat(r13.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r13.xyzw, r13.xyzw, -cb0[9].xyzw
        r13.xyzw = value_174.xyzw;
        uint4 value_175 = asuint(mad(asfloat(r12.xxxx), asfloat(r13.xyzw), asfloat(cb0[9].xyzw))); // mad r12.xyzw, r12.xxxx, r13.xyzw, cb0[9].xyzw
        r12.xyzw = value_175.xyzw;
        uint4 value_176 = asuint(asfloat(asuint(-asfloat(r12.xyzw))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r13.xyzw, -r12.xyzw, l(1.000000, 1.000000, 1.000000, 1.000000)
        r13.xyzw = value_176.xyzw;
        uint4 value_177 = asuint(max(asfloat(r13.wwww), asfloat(uint4(0x33d6bf95u, 0x33d6bf95u, 0x33d6bf95u, 0x33d6bf95u)))); // max r3.w, r13.w, l(0.000000)
        r3.w = value_177.w;
        uint4 value_178 = asuint(saturate(asfloat(asuint(asfloat(r13.xyzx) / asfloat(r3.wwww))))); // div_sat r12.xyz, r13.xyzx, r3.wwww
        r12.xyz = value_178.xyz;
        uint4 value_179 = asuint(asfloat(asuint(-asfloat(r12.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r12.xyz, -r12.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
        r12.xyz = value_179.xyz;
        uint4 value_180 = asuint(asfloat(r9.xyzx) + asfloat(asuint(-asfloat(r12.xyzx)))); // add r13.xyz, r9.xyzx, -r12.xyzx
        r13.xyz = value_180.xyz;
        uint4 value_181 = asuint(mad(asfloat(r12.wwww), asfloat(r13.xyzx), asfloat(r12.xyzx))); // mad r9.xyz, r12.wwww, r13.xyzx, r12.xyzx
        r9.xyz = value_181.xyz;
        uint4 value_182 = asuint(asfloat(r10.xyzx) + asfloat(asuint(-asfloat(r11.xyzx)))); // add r12.xyz, r10.xyzx, -r11.xyzx
        r12.xyz = value_182.xyz;
        uint4 value_183 = asuint(mad(asfloat(r12.wwww), asfloat(r12.xyzx), asfloat(r11.xyzx))); // mad r10.xyz, r12.wwww, r12.xyzx, r11.xyzx
        r10.xyz = value_183.xyz;
        uint4 value_184 = (r2.wwww + uint4(0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu)); // iadd r2.w, r2.w, l(-1)
        r2.w = value_184.w;
    }
    uint4 value_186 = asuint(mad(asfloat(r7.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu, 0x0u)), asfloat(r10.xyzx))); // mad r6.xyz, r7.xyzx, l(-0.200000, -0.200000, -0.200000, 0.000000), r10.xyzx
    r6.xyz = value_186.xyz;
    uint4 value_187 = asuint(asfloat(r6.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r6.yw, r6.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r6.yw = value_187.yw;
    uint4 value_188 = asuint(max(asfloat(r6.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r2.w, r6.w, l(0.000000)
    r2.w = value_188.w;
    uint4 value_189 = asuint(floor(asfloat(r2.wwww))); // round_ni r3.w, r2.w
    r3.w = value_189.w;
    uint4 value_190 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.x, r3.w
    r4.x = value_190.x;
    uint4 value_191 = (r4.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r6.w, r4.x, l(1)
    r6.w = value_191.w;
    uint4 value_192 = asuint(asfloat(r6.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r6.xz, r6.xxzx, -cb0[3].xxyx
    r6.xz = value_192.xz;
    uint4 value_193 = asuint(asfloat(r6.xxzx) * asfloat(cb0[2].zzzz)); // mul r6.xz, r6.xxzx, cb0[2].zzzz
    r6.xz = value_193.xz;
    uint4 value_194 = asuint(max(asfloat(r6.xxzx), asfloat(cb0[7].xxyx))); // max r6.xz, r6.xxzx, cb0[7].xxyx
    r6.xz = value_194.xz;
    uint4 value_195 = asuint(min(asfloat(r4.yyzy), asfloat(r6.xxzx))); // min r6.xz, r4.yyzy, r6.xxzx
    r6.xz = value_195.xz;
    uint4 value_196 = asuint(asfloat(r5.xxxx) * asfloat(r3.wwww)); // mul r3.w, r5.x, r3.w
    r3.w = value_196.w;
    uint4 value_197 = asuint(int4(asfloat(r3.wwww))); // ftoi r7.w, r3.w
    r7.w = value_197.w;
    uint4 value_198 = asuint(float4(asint(r6.wwww))); // itof r8.x, r6.w
    r8.x = value_198.x;
    uint4 value_199 = asuint(asfloat(r5.xxxx) * asfloat(r8.xxxx)); // mul r8.x, r5.x, r8.x
    r8.x = value_199.x;
    uint4 value_200 = asuint(int4(asfloat(r8.xxxx))); // ftoi r8.y, r8.x
    r8.y = value_200.y;
    uint4 value_201 = (asuint(-asint(r7.wwww)) * r4.wwww + r4.xxxx); // imad r4.x, -r7.w, r4.w, r4.x
    r4.x = value_201.x;
    uint4 value_202 = asuint(float4(r4.xxxx)); // utof r4.x, r4.x
    r4.x = value_202.x;
    uint4 value_203 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r4.xxxx), asfloat(r6.xxxx))); // mad r11.x, cb0[2].x, r4.x, r6.x
    r11.x = value_203.x;
    uint4 value_204 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_204.w;
    uint4 value_205 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r6.zzzz))); // mad r11.y, cb0[2].y, r3.w, r6.z
    r11.y = value_205.y;
    uint4 value_206 = (asuint(-asint(r8.yyyy)) * r4.wwww + r6.wwww); // imad r3.w, -r8.y, r4.w, r6.w
    r3.w = value_206.w;
    uint4 value_207 = asuint(float4(r3.wwww)); // utof r3.w, r3.w
    r3.w = value_207.w;
    uint4 value_208 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.wwww), asfloat(r6.xxxx))); // mad r12.x, cb0[2].x, r3.w, r6.x
    r12.x = value_208.x;
    uint4 value_209 = asuint(trunc(asfloat(r8.xxxx))); // round_z r3.w, r8.x
    r3.w = value_209.w;
    uint4 value_210 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r6.zzzz))); // mad r12.y, cb0[2].y, r3.w, r6.z
    r12.y = value_210.y;
    uint4 value_211 = asuint(t0.SampleLevel(s0, asfloat(r11.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r11.xyxx, t0.xyzw, s0, l(0.000000)
    r8.xyzw = value_211.xyzw;
    uint4 value_212 = asuint(t0.SampleLevel(s0, asfloat(r12.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r13.xyzw, r12.xyxx, t0.xyzw, s0, l(0.000000)
    r13.xyzw = value_212.xyzw;
    uint4 value_213 = ((asfloat(r11.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r11.y, l(1.000000)
    r3.w = value_213.w;
    uint4 value_214 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_214.w;
    uint4 value_215 = asuint(asfloat(asuint(-asfloat(r8.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r6.xzw, -r8.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r6.xzw = value_215.xzw;
    uint4 value_216 = asuint(mad(asfloat(r3.wwww), asfloat(r6.xxzw), asfloat(r8.xxyz))); // mad r6.xzw, r3.wwww, r6.xxzw, r8.xxyz
    r6.xzw = value_216.xzw;
    uint4 value_217 = ((asfloat(r12.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r12.y, l(1.000000)
    r3.w = value_217.w;
    uint4 value_218 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_218.w;
    uint4 value_219 = asuint(asfloat(asuint(-asfloat(r13.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r8.xyz, -r13.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r8.xyz = value_219.xyz;
    uint4 value_220 = asuint(mad(asfloat(r3.wwww), asfloat(r8.xyzx), asfloat(r13.xyzx))); // mad r8.xyz, r3.wwww, r8.xyzx, r13.xyzx
    r8.xyz = value_220.xyz;
    uint4 value_221 = asuint(frac(asfloat(r2.wwww))); // frc r2.w, r2.w
    r2.w = value_221.w;
    uint4 value_222 = asuint(asfloat(asuint(-asfloat(r6.xzwx))) + asfloat(r8.xyzx)); // add r8.xyz, -r6.xzwx, r8.xyzx
    r8.xyz = value_222.xyz;
    uint4 value_223 = asuint(mad(asfloat(r2.wwww), asfloat(r8.xxyz), asfloat(r6.xxzw))); // mad r6.xzw, r2.wwww, r8.xxyz, r6.xxzw
    r6.xzw = value_223.xzw;
    uint4 value_224 = asuint(saturate(asfloat(r6.yyyy))); // mov_sat r6.y, r6.y
    r6.y = value_224.y;
    uint4 value_225 = asuint(asfloat(r6.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r6.xzw, r6.xxzw, -cb0[9].xxyz
    r6.xzw = value_225.xzw;
    uint4 value_226 = asuint(mad(asfloat(r6.yyyy), asfloat(r6.xzwx), asfloat(cb0[9].xyzx))); // mad r6.xyz, r6.yyyy, r6.xzwx, cb0[9].xyzx
    r6.xyz = value_226.xyz;
    uint4 value_227 = asuint(mad(asfloat(r7.xyzx), asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0x0u)), asfloat(r10.xyzx))); // mad r7.xyz, r7.xyzx, l(-0.500000, -0.500000, -0.500000, 0.000000), r10.xyzx
    r7.xyz = value_227.xyz;
    uint4 value_228 = asuint(asfloat(r7.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r7.yw, r7.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r7.yw = value_228.yw;
    uint4 value_229 = asuint(max(asfloat(r7.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r2.w, r7.w, l(0.000000)
    r2.w = value_229.w;
    uint4 value_230 = asuint(floor(asfloat(r2.wwww))); // round_ni r3.w, r2.w
    r3.w = value_230.w;
    uint4 value_231 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.x, r3.w
    r4.x = value_231.x;
    uint4 value_232 = (r4.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r6.w, r4.x, l(1)
    r6.w = value_232.w;
    uint4 value_233 = asuint(asfloat(r7.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r7.xz, r7.xxzx, -cb0[3].xxyx
    r7.xz = value_233.xz;
    uint4 value_234 = asuint(asfloat(r7.xxzx) * asfloat(cb0[2].zzzz)); // mul r7.xz, r7.xxzx, cb0[2].zzzz
    r7.xz = value_234.xz;
    uint4 value_235 = asuint(max(asfloat(r7.xxzx), asfloat(cb0[7].xxyx))); // max r7.xz, r7.xxzx, cb0[7].xxyx
    r7.xz = value_235.xz;
    uint4 value_236 = asuint(min(asfloat(r4.yyzy), asfloat(r7.xxzx))); // min r4.yz, r4.yyzy, r7.xxzx
    r4.yz = value_236.yz;
    uint4 value_237 = asuint(asfloat(r5.xxxx) * asfloat(r3.wwww)); // mul r3.w, r5.x, r3.w
    r3.w = value_237.w;
    uint4 value_238 = asuint(int4(asfloat(r3.wwww))); // ftoi r7.x, r3.w
    r7.x = value_238.x;
    uint4 value_239 = asuint(float4(asint(r6.wwww))); // itof r7.z, r6.w
    r7.z = value_239.z;
    uint4 value_240 = asuint(asfloat(r5.xxxx) * asfloat(r7.zzzz)); // mul r5.x, r5.x, r7.z
    r5.x = value_240.x;
    uint4 value_241 = asuint(int4(asfloat(r5.xxxx))); // ftoi r7.z, r5.x
    r7.z = value_241.z;
    uint4 value_242 = (asuint(-asint(r7.xxxx)) * r4.wwww + r4.xxxx); // imad r4.x, -r7.x, r4.w, r4.x
    r4.x = value_242.x;
    uint4 value_243 = asuint(float4(r4.xxxx)); // utof r4.x, r4.x
    r4.x = value_243.x;
    uint4 value_244 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r4.xxxx), asfloat(r4.yyyy))); // mad r8.x, cb0[2].x, r4.x, r4.y
    r8.x = value_244.x;
    uint4 value_245 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_245.w;
    uint4 value_246 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r4.zzzz))); // mad r8.y, cb0[2].y, r3.w, r4.z
    r8.y = value_246.y;
    uint4 value_247 = (asuint(-asint(r7.zzzz)) * r4.wwww + r6.wwww); // imad r3.w, -r7.z, r4.w, r6.w
    r3.w = value_247.w;
    uint4 value_248 = asuint(float4(r3.wwww)); // utof r3.w, r3.w
    r3.w = value_248.w;
    uint4 value_249 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.wwww), asfloat(r4.yyyy))); // mad r4.x, cb0[2].x, r3.w, r4.y
    r4.x = value_249.x;
    uint4 value_250 = asuint(trunc(asfloat(r5.xxxx))); // round_z r3.w, r5.x
    r3.w = value_250.w;
    uint4 value_251 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r4.zzzz))); // mad r4.y, cb0[2].y, r3.w, r4.z
    r4.y = value_251.y;
    uint4 value_252 = asuint(t0.SampleLevel(s0, asfloat(r8.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r10.xyzw, r8.xyxx, t0.xyzw, s0, l(0.000000)
    r10.xyzw = value_252.xyzw;
    uint4 value_253 = asuint(t0.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r11.xyzw, r4.xyxx, t0.xyzw, s0, l(0.000000)
    r11.xyzw = value_253.xyzw;
    uint4 value_254 = ((asfloat(r8.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r8.y, l(1.000000)
    r3.w = value_254.w;
    uint4 value_255 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_255.w;
    uint4 value_256 = asuint(asfloat(asuint(-asfloat(r10.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r4.xzw, -r10.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r4.xzw = value_256.xzw;
    uint4 value_257 = asuint(mad(asfloat(r3.wwww), asfloat(r4.xxzw), asfloat(r10.xxyz))); // mad r4.xzw, r3.wwww, r4.xxzw, r10.xxyz
    r4.xzw = value_257.xzw;
    uint4 value_258 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r4.y, l(1.000000)
    r3.w = value_258.w;
    uint4 value_259 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_259.w;
    uint4 value_260 = asuint(asfloat(asuint(-asfloat(r11.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r7.xzw, -r11.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r7.xzw = value_260.xzw;
    uint4 value_261 = asuint(mad(asfloat(r3.wwww), asfloat(r7.xxzw), asfloat(r11.xxyz))); // mad r7.xzw, r3.wwww, r7.xxzw, r11.xxyz
    r7.xzw = value_261.xzw;
    uint4 value_262 = asuint(frac(asfloat(r2.wwww))); // frc r2.w, r2.w
    r2.w = value_262.w;
    uint4 value_263 = asuint(asfloat(asuint(-asfloat(r4.xxzw))) + asfloat(r7.xxzw)); // add r7.xzw, -r4.xxzw, r7.xxzw
    r7.xzw = value_263.xzw;
    uint4 value_264 = asuint(mad(asfloat(r2.wwww), asfloat(r7.xzwx), asfloat(r4.xzwx))); // mad r4.xyz, r2.wwww, r7.xzwx, r4.xzwx
    r4.xyz = value_264.xyz;
    uint4 value_265 = asuint(saturate(asfloat(r7.yyyy))); // mov_sat r7.y, r7.y
    r7.y = value_265.y;
    uint4 value_266 = asuint(asfloat(r4.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r4.xyz, r4.xyzx, -cb0[9].xyzx
    r4.xyz = value_266.xyz;
    uint4 value_267 = asuint(mad(asfloat(r7.yyyy), asfloat(r4.xyzx), asfloat(cb0[9].xyzx))); // mad r4.xyz, r7.yyyy, r4.xyzx, cb0[9].xyzx
    r4.xyz = value_267.xyz;
    uint4 value_268 = asuint(mad(asfloat(r6.xyzx), asfloat(r4.xyzx), asfloat(uint4(0xbf4ccccdu, 0xbf4ccccdu, 0xbf4ccccdu, 0x0u)))); // mad r4.xyz, r6.xyzx, r4.xyzx, l(-0.800000, -0.800000, -0.800000, 0.000000)
    r4.xyz = value_268.xyz;
    uint4 value_269 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r4.xyzx), asfloat(uint4(0x3f4ccccdu, 0x3f4ccccdu, 0x3f4ccccdu, 0x0u)))); // mad r4.xyz, cb0[29].yyyy, r4.xyzx, l(0.800000, 0.800000, 0.800000, 0.000000)
    r4.xyz = value_269.xyz;
    uint4 value_270 = asuint(asfloat(r9.xyzx) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0x0u))); // add r6.xyz, r9.xyzx, l(-0.700000, -0.700000, -0.700000, 0.000000)
    r6.xyz = value_270.xyz;
    uint4 value_271 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r6.xyzx), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x0u)))); // mad r6.xyz, cb0[29].xxxx, r6.xyzx, l(0.700000, 0.700000, 0.700000, 0.000000)
    r6.xyz = value_271.xyz;
    uint4 value_272 = asuint(asfloat(r4.xyzx) * asfloat(uint4(0x3fa66666u, 0x3fa66666u, 0x3fa66666u, 0x0u))); // mul r4.xyz, r4.xyzx, l(1.300000, 1.300000, 1.300000, 0.000000)
    r4.xyz = value_272.xyz;
    uint4 value_273 = asuint(asfloat(r6.yzxy) * asfloat(r6.xyzx)); // mul r7.xyz, r6.yzxy, r6.xyzx
    r7.xyz = value_273.xyz;
    uint4 value_274 = asuint(asfloat(r7.xyzx) * asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x0u))); // mul r8.xyz, r7.xyzx, l(0.300000, 0.300000, 0.300000, 0.000000)
    r8.xyz = value_274.xyz;
    uint4 value_275 = asuint(mad(asfloat(asuint(-asfloat(r7.xyzx))), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x0u)), asfloat(r6.xyzx))); // mad r6.xyz, -r7.xyzx, l(0.300000, 0.300000, 0.300000, 0.000000), r6.xyzx
    r6.xyz = value_275.xyz;
    uint4 value_276 = asuint(mad(asfloat(r4.xyzx), asfloat(r6.xyzx), asfloat(r8.xyzx))); // mad r4.xyz, r4.xyzx, r6.xyzx, r8.xyzx
    r4.xyz = value_276.xyz;
    uint4 value_277 = asuint(dot(asfloat(r4.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r2.w, r4.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r2.w = value_277.w;
    uint4 value_278 = asuint(asfloat(asuint(-asfloat(r2.wwww))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r3.w, -r2.w, l(0.600000)
    r3.w = value_278.w;
    uint4 value_279 = asuint(asfloat(r2.wwww) + asfloat(asuint(-asfloat(r3.wwww)))); // add r2.w, r2.w, -r3.w
    r2.w = value_279.w;
    uint4 value_280 = asuint(mad(asfloat(r2.wwww), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r4.xyzx))); // mad r4.xyz, r2.wwww, l(0.100000, 0.100000, 0.100000, 0.000000), r4.xyzx
    r4.xyz = value_280.xyz;
    uint4 value_281 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r6.xyz, -r4.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r6.xyz = value_281.xyz;
    uint4 value_282 = asuint(mad(asfloat(r6.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r4.xyzx))); // mad o4.xyz, r6.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r4.xyzx
    out_o4.xyz = value_282.xyz;
    uint4 value_283 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r5.yzwy).xyz)).xxxx; // dp3 r2.y, r2.xyzx, r5.yzwy
    r2.y = value_283.y;
    uint4 value_284 = asuint(dot(asfloat(asuint(-asfloat(r3.xyzx))).xyz, asfloat(r5.yzwy).xyz)).xxxx; // dp3 r2.z, -r3.xyzx, r5.yzwy
    r2.z = value_284.z;
    uint4 value_285 = asuint(asfloat(r2.yyzy) + asfloat(r2.yyzy)); // add r2.yz, r2.yyzy, r2.yyzy
    r2.yz = value_285.yz;
    uint4 value_286 = asuint(asfloat(r2.yyyy) * asfloat(asuint(-asfloat(v3.wwww)))); // mul r2.x, r2.y, -v3.w
    r2.x = value_286.x;
    uint4 value_287 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3c23d70au, 0x3c23d70au, 0x3c23d70au, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r1.xyzx, l(0.010000, 0.010000, 0.010000, 0.000000), r0.xyzx
    r0.xyz = value_287.xyz;
    uint4 value_288 = asuint(asfloat(r0.yyyy) * asfloat(cb3[10].xyxx)); // mul r1.xy, r0.yyyy, cb3[10].xyxx
    r1.xy = value_288.xy;
    uint4 value_289 = asuint(mad(asfloat(cb3[9].xyxx), asfloat(r0.xxxx), asfloat(r1.xyxx))); // mad r0.xy, cb3[9].xyxx, r0.xxxx, r1.xyxx
    r0.xy = value_289.xy;
    uint4 value_290 = asuint(mad(asfloat(cb3[11].xyxx), asfloat(r0.zzzz), asfloat(r0.xyxx))); // mad r0.xy, cb3[11].xyxx, r0.zzzz, r0.xyxx
    r0.xy = value_290.xy;
    uint4 value_291 = asuint(mad(asfloat(cb3[12].xxxy), asfloat(r0.wwww), asfloat(r0.xxxy))); // mad o0.zw, cb3[12].xxxy, r0.wwww, r0.xxxy
    out_o0.zw = value_291.zw;
    uint4 value_292 = v1.xyxx; // mov o0.xy, v1.xyxx
    out_o0.xy = value_292.xy;
    uint4 value_293 = uint4(0x0u, 0x0u, 0x0u, 0x0u); // mov o2.xyzw, l(0,0,0,0)
    out_o2.xyzw = value_293.xyzw;
    uint4 value_294 = r1.wwww; // mov o3.w, r1.w
    out_o3.w = value_294.w;
    uint4 value_295 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov o4.w, l(1.000000)
    out_o4.w = value_295.w;
    uint4 value_296 = r2.xzxx; // mov o1.xy, r2.xzxx
    out_o1.xy = value_296.xy;
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
