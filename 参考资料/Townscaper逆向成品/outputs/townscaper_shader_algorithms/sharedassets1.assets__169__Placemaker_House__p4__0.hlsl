// Register-explicit recovered HLSL. Not original source.
// Placemaker/House vs_4_0 variant []
// Source SHA256 7019a95d0f487f408b559a78ff309702dac879b99389258c8a7a3a7fbe2fef7d
// b0: $Globals 656 bytes
// b1: UnityPerCamera 144 bytes
// b2: UnityPerCameraRare 352 bytes
// b3: UnityPerDraw 176 bytes
// b4: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[4].x = _SunDir rows=1 cols=3 byte_offset=64
// cb0[5].x = _SunColor rows=1 cols=4 byte_offset=80
// cb0[6].x = _ShadowColor rows=1 cols=4 byte_offset=96
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[18].x = _Dim rows=1 cols=4 byte_offset=288
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[40].x = _Culling rows=1 cols=1 byte_offset=640
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[6].x = _ScreenParams rows=1 cols=4 byte_offset=96
// cb2[10].x = unity_CameraInvProjection rows=4 cols=4 byte_offset=160
// cb3[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb4[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// cb4[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _AoTex
// t1 / s1 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[41]; };
cbuffer Buffer1:register(b1) { uint4 cb1[7]; };
cbuffer Buffer2:register(b2) { uint4 cb2[12]; };
cbuffer Buffer3:register(b3) { uint4 cb3[4]; };
cbuffer Buffer4:register(b4) { uint4 cb4[21]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 8
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: NORMAL0;
    float4 v3_0: TANGENT0;
    float4 v4_0: COLOR0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD1;
    float2 o1_0: TEXCOORD2;
    float2 o1_1: TEXCOORD3;
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
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 out_o3;
    uint4 out_o4;
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
    uint4 value_1 = asuint(asfloat(v1.yyyy) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.x, v1.y, l(0.500000)
    r0.x = value_1.x;
    uint4 value_2 = asuint(floor(asfloat(r0.xxxx))); // round_ni r0.x, r0.x
    r0.x = value_2.x;
    uint4 value_3 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.x, r0.x, l(0.500000)
    r0.x = value_3.x;
    uint4 value_4 = asuint(int4(asfloat(r0.xxxx))); // ftoi r0.x, r0.x
    r0.x = value_4.x;
    uint4 value_5 = asuint(asint(r0.xxxx) >> (uint4(0x1u, 0x1u, 0x1u, 0x1u) & 31u)); // ishr r1.x, r0.x, l(1)
    r1.x = value_5.x;
    uint4 value_6 = asuint(asint(r0.xxxx) >> (uint4(0x2u, 0x2u, 0x2u, 0x2u) & 31u)); // ishr r1.y, r0.x, l(2)
    r1.y = value_6.y;
    uint4 value_7 = asuint(asint(r0.xxxx) >> (uint4(0x3u, 0x3u, 0x3u, 0x3u) & 31u)); // ishr r1.z, r0.x, l(3)
    r1.z = value_7.z;
    uint4 value_8 = asuint(asint(r0.xxxx) >> (uint4(0x4u, 0x4u, 0x4u, 0x4u) & 31u)); // ishr r1.w, r0.x, l(4)
    r1.w = value_8.w;
    uint4 value_9 = (r0.xxxx & uint4(0x1u, 0x1u, 0x1u, 0x1u)); // and r0.x, r0.x, l(1)
    r0.x = value_9.x;
    uint4 value_10 = asuint(float4(asint(r0.xxxx))); // itof r0.x, r0.x
    r0.x = value_10.x;
    uint4 value_11 = (r1.xyzw & uint4(0x1u, 0x1u, 0x1u, 0x1u)); // and r1.xyzw, r1.xyzw, l(1, 1, 1, 1)
    r1.xyzw = value_11.xyzw;
    uint4 value_12 = asuint(float4(asint(r1.xyzw))); // itof r1.xyzw, r1.xyzw
    r1.xyzw = value_12.xyzw;
    uint4 value_13 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(r1.xxxx)); // add o0.z, -r0.x, r1.x
    out_o0.z = value_13.z;
    uint4 value_14 = asuint(asfloat(v1.yyyy) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.x, v1.y, l(0.500000)
    r0.x = value_14.x;
    uint4 value_15 = asuint(frac(asfloat(r0.xxxx))); // frc r0.x, r0.x
    r0.x = value_15.x;
    uint4 value_16 = asuint(asfloat(r0.xxxx) + asfloat(r0.xxxx)); // add o0.y, r0.x, r0.x
    out_o0.y = value_16.y;
    uint4 value_17 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r1.yyyy)))); // add o0.w, r1.z, -r1.y
    out_o0.w = value_17.w;
    uint4 value_18 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r1.w, l(1.000000)
    r0.x = value_18.x;
    uint4 value_19 = v1.xxxx; // mov o0.x, v1.x
    out_o0.x = value_19.x;
    uint4 value_20 = asuint(round(asfloat(v3.wwww))); // round_ne r0.y, v3.w
    r0.y = value_20.y;
    uint4 value_21 = asuint(int4(asfloat(r0.yyyy))); // ftoi r0.y, r0.y
    r0.y = value_21.y;
    uint4 value_22 = ((r0.yyyy != 0u) ? uint4(0x0u, 0x0u, 0x3f800000u, 0x0u) : uint4(0x0u, 0x3f800000u, 0x0u, 0x0u)); // movc r0.yz, r0.yyyy, l(0,0,1.000000,0), l(0,1.000000,0,0)
    r0.yz = value_22.yz;
    uint4 value_23 = ((asfloat(cb0[40].xxxx) == asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // eq r0.w, cb0[40].x, l(1.000000)
    r0.w = value_23.w;
    uint4 value_24 = ((r0.wwww != 0u) ? r0.zzzz : r0.yyyy); // movc r0.y, r0.w, r0.z, r0.y
    r0.y = value_24.y;
    uint4 value_25 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.z, r0.y, l(-0.500000)
    r0.z = value_25.z;
    uint4 value_26 = asuint(asfloat(r0.xxxx) * asfloat(r0.zzzz)); // mul r0.x, r0.x, r0.z
    r0.x = value_26.x;
    uint4 value_27 = asuint(asfloat(v3.yyyy) * asfloat(cb3[1].xyzx)); // mul r1.xyz, v3.yyyy, cb3[1].xyzx
    r1.xyz = value_27.xyz;
    uint4 value_28 = asuint(mad(asfloat(cb3[0].xyzx), asfloat(v3.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb3[0].xyzx, v3.xxxx, r1.xyzx
    r1.xyz = value_28.xyz;
    uint4 value_29 = asuint(mad(asfloat(cb3[2].xyzx), asfloat(v3.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb3[2].xyzx, v3.zzzz, r1.xyzx
    r1.xyz = value_29.xyz;
    uint4 value_30 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.z, r1.xyzx, r1.xyzx
    r0.z = value_30.z;
    uint4 value_31 = asuint(rsqrt(asfloat(r0.zzzz))); // rsq r0.z, r0.z
    r0.z = value_31.z;
    uint4 value_32 = asuint(asfloat(r0.zzzz) * asfloat(r1.xyzx)); // mul r1.xyz, r0.zzzz, r1.xyzx
    r1.xyz = value_32.xyz;
    uint4 value_33 = asuint(asfloat(cb1[6].wwww) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.z, cb1[6].w, l(-1.000000)
    r0.z = value_33.z;
    uint4 value_34 = asuint(asfloat(v0.yyyy) * asfloat(cb3[1].xyzw)); // mul r2.xyzw, v0.yyyy, cb3[1].xyzw
    r2.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(mad(asfloat(cb3[0].xyzw), asfloat(v0.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[0].xyzw, v0.xxxx, r2.xyzw
    r2.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(mad(asfloat(cb3[2].xyzw), asfloat(v0.zzzz), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[2].xyzw, v0.zzzz, r2.xyzw
    r2.xyzw = value_36.xyzw;
    uint4 value_37 = asuint(mad(asfloat(cb3[3].xyzw), asfloat(v0.wwww), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[3].xyzw, v0.wwww, r2.xyzw
    r2.xyzw = value_37.xyzw;
    uint4 value_38 = asuint(asfloat(r2.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r3.xyz, r2.xyzx, -cb0[22].xyzx
    r3.xyz = value_38.xyz;
    uint4 value_39 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(r3.xyzx).xyz)).xxxx; // dp3 r0.w, r3.xyzx, r3.xyzx
    r0.w = value_39.w;
    uint4 value_40 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_40.w;
    uint4 value_41 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_41.w;
    uint4 value_42 = asuint(asfloat(r0.wwww) * asfloat(r3.xyzx)); // mul r3.xyz, r0.wwww, r3.xyzx
    r3.xyz = value_42.xyz;
    uint4 value_43 = asuint(mad(asfloat(r3.yyyy), asfloat(cb0[22].wwww), asfloat(r2.yyyy))); // mad r0.w, r3.y, cb0[22].w, r2.y
    r0.w = value_43.w;
    uint4 value_44 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_44.w;
    uint4 value_45 = asuint(mad(asfloat(r3.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r4.w, r3.y, cb0[22].w, -r0.w
    r4.w = value_45.w;
    uint4 value_46 = asuint(asfloat(r3.xxzx) * asfloat(cb0[22].wwww)); // mul r4.xz, r3.xxzx, cb0[22].wwww
    r4.xz = value_46.xz;
    uint4 value_47 = asuint(asfloat(r2.xyzx) + asfloat(r4.xwzx)); // add r3.xyz, r2.xyzx, r4.xwzx
    r3.xyz = value_47.xyz;
    uint4 value_48 = asuint(asfloat(r3.yyyy) * asfloat(cb4[18].wwww)); // mul r0.w, r3.y, cb4[18].w
    r0.w = value_48.w;
    uint4 value_49 = asuint(mad(asfloat(cb4[17].wwww), asfloat(r3.xxxx), asfloat(r0.wwww))); // mad r0.w, cb4[17].w, r3.x, r0.w
    r0.w = value_49.w;
    uint4 value_50 = asuint(mad(asfloat(cb4[19].wwww), asfloat(r3.zzzz), asfloat(r0.wwww))); // mad r0.w, cb4[19].w, r3.z, r0.w
    r0.w = value_50.w;
    uint4 value_51 = asuint(asfloat(r0.wwww) + asfloat(cb4[20].wwww)); // add r0.w, r0.w, cb4[20].w
    r0.w = value_51.w;
    uint4 value_52 = asuint(asfloat(r0.wwww) * asfloat(cb2[11].yyyy)); // mul r0.w, r0.w, cb2[11].y
    r0.w = value_52.w;
    uint4 value_53 = asuint(asfloat(r0.zzzz) * asfloat(r0.wwww)); // mul r0.z, r0.z, r0.w
    r0.z = value_53.z;
    uint4 value_54 = asuint(asfloat(r0.zzzz) * asfloat(cb0[19].wwww)); // mul r0.z, r0.z, cb0[19].w
    r0.z = value_54.z;
    uint4 value_55 = asuint(asfloat(r0.zzzz) * asfloat(uint4(0x4019999au, 0x4019999au, 0x4019999au, 0x4019999au))); // mul r0.z, r0.z, l(2.400000)
    r0.z = value_55.z;
    uint4 value_56 = asuint(max(asfloat(r0.zzzz), asfloat(uint4(0x3c23d70au, 0x3c23d70au, 0x3c23d70au, 0x3c23d70au)))); // max r0.z, r0.z, l(0.010000)
    r0.z = value_56.z;
    uint4 value_57 = asuint(asfloat(r0.zzzz) * asfloat(cb0[18].yyyy)); // mul r0.z, r0.z, cb0[18].y
    r0.z = value_57.z;
    uint4 value_58 = asuint(asfloat(r0.zzzz) * asfloat(r1.xyzx)); // mul r1.xyz, r0.zzzz, r1.xyzx
    r1.xyz = value_58.xyz;
    uint4 value_59 = asuint(saturate(asfloat(asuint(asfloat(r3.yyyy) * asfloat(uint4(0x42c80000u, 0x42c80000u, 0x42c80000u, 0x42c80000u)))))); // mul_sat r0.z, r3.y, l(100.000000)
    r0.z = value_59.z;
    uint4 value_60 = asuint(asfloat(r0.zzzz) * asfloat(r1.xyzx)); // mul r1.xyz, r0.zzzz, r1.xyzx
    r1.xyz = value_60.xyz;
    uint4 value_61 = asuint(mad(asfloat(r1.xxyz), asfloat(r0.xxxx), asfloat(r3.xxyz))); // mad r0.xzw, r1.xxyz, r0.xxxx, r3.xxyz
    r0.xzw = value_61.xzw;
    uint4 value_62 = asuint(asfloat(r0.zzzz) * asfloat(cb4[10].xyxx)); // mul r1.xy, r0.zzzz, cb4[10].xyxx
    r1.xy = value_62.xy;
    uint4 value_63 = asuint(mad(asfloat(cb4[9].xyxx), asfloat(r0.xxxx), asfloat(r1.xyxx))); // mad r1.xy, cb4[9].xyxx, r0.xxxx, r1.xyxx
    r1.xy = value_63.xy;
    uint4 value_64 = asuint(mad(asfloat(cb4[11].xyxx), asfloat(r0.wwww), asfloat(r1.xyxx))); // mad r1.xy, cb4[11].xyxx, r0.wwww, r1.xyxx
    r1.xy = value_64.xy;
    uint4 value_65 = asuint(mad(asfloat(cb4[12].xyxx), asfloat(r2.wwww), asfloat(r1.xyxx))); // mad o1.xy, cb4[12].xyxx, r2.wwww, r1.xyxx
    out_o1.xy = value_65.xy;
    uint4 value_66 = ((asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)) >= asfloat(v1.xxxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.x, l(0.000000), v1.x
    r1.x = value_66.x;
    uint4 value_67 = (r1.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.x, r1.x, l(0x3f800000)
    r1.x = value_67.x;
    uint4 value_68 = asuint(asfloat(r0.zzzz) + asfloat(r1.xxxx)); // add o1.w, r0.z, r1.x
    out_o1.w = value_68.w;
    uint4 value_69 = asuint(asfloat(r3.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r1.xy, r3.xzxx, -cb0[3].xyxx
    r1.xy = value_69.xy;
    uint4 value_70 = asuint(asfloat(r3.yyyy) + asfloat(uint4(0x0u, 0x0u, 0x3f000000u, 0xbf000000u))); // add r1.zw, r3.yyyy, l(0.000000, 0.000000, 0.500000, -0.500000)
    r1.zw = value_70.zw;
    uint4 value_71 = asuint(asfloat(r1.xyxx) * asfloat(cb0[2].zzzz)); // mul r1.xy, r1.xyxx, cb0[2].zzzz
    r1.xy = value_71.xy;
    uint4 value_72 = asuint(max(asfloat(r1.xyxx), asfloat(cb0[7].xyxx))); // max r1.xy, r1.xyxx, cb0[7].xyxx
    r1.xy = value_72.xy;
    uint4 value_73 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r3.xy, cb0[2].xyxx, -cb0[7].xyxx
    r3.xy = value_73.xy;
    uint4 value_74 = asuint(min(asfloat(r1.xyxx), asfloat(r3.xyxx))); // min r1.xy, r1.xyxx, r3.xyxx
    r1.xy = value_74.xy;
    uint4 value_75 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r1.w, l(0.000000)
    r1.w = value_75.w;
    uint4 value_76 = asuint(saturate(asfloat(r1.zzzz))); // mov_sat r1.z, r1.z
    r1.z = value_76.z;
    uint4 value_77 = asuint(floor(asfloat(r1.wwww))); // round_ni r2.w, r1.w
    r2.w = value_77.w;
    uint4 value_78 = asuint(frac(asfloat(r1.wwww))); // frc r1.w, r1.w
    r1.w = value_78.w;
    uint4 value_79 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.z, r2.w
    r3.z = value_79.z;
    uint4 value_80 = (r3.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.w, r3.z, l(1)
    r3.w = value_80.w;
    uint4 value_81 = asuint(float4(asint(r3.wwww))); // itof r4.x, r3.w
    r4.x = value_81.x;
    uint4 value_82 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r4.y, cb0[2].w
    r4.y = value_82.y;
    uint4 value_83 = uint4(asfloat(r4.yyyy)); // ftou r4.y, r4.y
    r4.y = value_83.y;
    uint4 value_84 = asuint(float4(r4.yyyy)); // utof r4.z, r4.y
    r4.z = value_84.z;
    uint4 value_85 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r4.zzzz)); // div r4.z, l(1.000000, 1.000000, 1.000000, 1.000000), r4.z
    r4.z = value_85.z;
    uint4 value_86 = asuint(asfloat(r4.zzzz) * asfloat(r4.xxxx)); // mul r4.x, r4.z, r4.x
    r4.x = value_86.x;
    uint4 value_87 = asuint(int4(asfloat(r4.xxxx))); // ftoi r4.w, r4.x
    r4.w = value_87.w;
    uint4 value_88 = asuint(trunc(asfloat(r4.xxxx))); // round_z r4.x, r4.x
    r4.x = value_88.x;
    uint4 value_89 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r4.xxxx), asfloat(r1.yyyy))); // mad r5.y, cb0[2].y, r4.x, r1.y
    r5.y = value_89.y;
    uint4 value_90 = (asuint(-asint(r4.wwww)) * r4.yyyy + r3.wwww); // imad r3.w, -r4.w, r4.y, r3.w
    r3.w = value_90.w;
    uint4 value_91 = asuint(float4(r3.wwww)); // utof r3.w, r3.w
    r3.w = value_91.w;
    uint4 value_92 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.wwww), asfloat(r1.xxxx))); // mad r5.x, cb0[2].x, r3.w, r1.x
    r5.x = value_92.x;
    uint4 value_93 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r5.xyzw = value_93.xyzw;
    uint4 value_94 = asuint(asfloat(r2.wwww) * asfloat(r4.zzzz)); // mul r2.w, r2.w, r4.z
    r2.w = value_94.w;
    uint4 value_95 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.w, r2.w
    r3.w = value_95.w;
    uint4 value_96 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_96.w;
    uint4 value_97 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r1.yyyy))); // mad r5.y, cb0[2].y, r2.w, r1.y
    r5.y = value_97.y;
    uint4 value_98 = (asuint(-asint(r3.wwww)) * r4.yyyy + r3.zzzz); // imad r1.y, -r3.w, r4.y, r3.z
    r1.y = value_98.y;
    uint4 value_99 = asuint(float4(r1.yyyy)); // utof r1.y, r1.y
    r1.y = value_99.y;
    uint4 value_100 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.yyyy), asfloat(r1.xxxx))); // mad r5.x, cb0[2].x, r1.y, r1.x
    r5.x = value_100.x;
    uint4 value_101 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_101.xyzw;
    uint4 value_102 = asuint(asfloat(r5.wwww) + asfloat(asuint(-asfloat(r6.wwww)))); // add r1.x, r5.w, -r6.w
    r1.x = value_102.x;
    uint4 value_103 = asuint(mad(asfloat(r1.wwww), asfloat(r1.xxxx), asfloat(r6.wwww))); // mad r1.x, r1.w, r1.x, r6.w
    r1.x = value_103.x;
    uint4 value_104 = asuint(asfloat(r1.xxxx) + asfloat(asuint(-asfloat(cb0[9].wwww)))); // add r1.x, r1.x, -cb0[9].w
    r1.x = value_104.x;
    uint4 value_105 = asuint(mad(asfloat(r1.zzzz), asfloat(r1.xxxx), asfloat(cb0[9].wwww))); // mad r1.x, r1.z, r1.x, cb0[9].w
    r1.x = value_105.x;
    uint4 value_106 = asuint(asfloat(r0.yyyy) * asfloat(r1.xxxx)); // mul o1.z, r0.y, r1.x
    out_o1.z = value_106.z;
    uint4 value_107 = asuint(asfloat(r0.zzzz) * asfloat(cb4[18].xyzw)); // mul r1.xyzw, r0.zzzz, cb4[18].xyzw
    r1.xyzw = value_107.xyzw;
    uint4 value_108 = asuint(mad(asfloat(cb4[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb4[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_108.xyzw;
    uint4 value_109 = asuint(mad(asfloat(cb4[19].xyzw), asfloat(r0.wwww), asfloat(r1.xyzw))); // mad r0.xyzw, cb4[19].xyzw, r0.wwww, r1.xyzw
    r0.xyzw = value_109.xyzw;
    uint4 value_110 = asuint(asfloat(r0.xyzw) + asfloat(cb4[20].xyzw)); // add o2.xyzw, r0.xyzw, cb4[20].xyzw
    out_o2.xyzw = value_110.xyzw;
    uint4 value_111 = asuint(asfloat(v2.yyyy) * asfloat(cb3[1].xyzx)); // mul r0.xyz, v2.yyyy, cb3[1].xyzx
    r0.xyz = value_111.xyz;
    uint4 value_112 = asuint(mad(asfloat(cb3[0].xyzx), asfloat(v2.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb3[0].xyzx, v2.xxxx, r0.xyzx
    r0.xyz = value_112.xyz;
    uint4 value_113 = asuint(mad(asfloat(cb3[2].xyzx), asfloat(v2.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb3[2].xyzx, v2.zzzz, r0.xyzx
    r0.xyz = value_113.xyz;
    uint4 value_114 = asuint(mad(asfloat(r0.xyzx), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r2.xyzx))); // mad r1.xyz, r0.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000), r2.xyzx
    r1.xyz = value_114.xyz;
    uint4 value_115 = asuint(asfloat(r1.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r1.yw, r1.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r1.yw = value_115.yw;
    uint4 value_116 = asuint(asfloat(r1.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r1.xz, r1.xxzx, -cb0[3].xxyx
    r1.xz = value_116.xz;
    uint4 value_117 = asuint(asfloat(r1.xxzx) * asfloat(cb0[2].zzzz)); // mul r1.xz, r1.xxzx, cb0[2].zzzz
    r1.xz = value_117.xz;
    uint4 value_118 = asuint(max(asfloat(r1.xxzx), asfloat(cb0[7].xxyx))); // max r1.xz, r1.xxzx, cb0[7].xxyx
    r1.xz = value_118.xz;
    uint4 value_119 = asuint(min(asfloat(r3.xxyx), asfloat(r1.xxzx))); // min r1.xz, r3.xxyx, r1.xxzx
    r1.xz = value_119.xz;
    uint4 value_120 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r1.w, l(0.000000)
    r0.w = value_120.w;
    uint4 value_121 = asuint(saturate(asfloat(r1.yyyy))); // mov_sat r1.y, r1.y
    r1.y = value_121.y;
    uint4 value_122 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.w, r0.w
    r1.w = value_122.w;
    uint4 value_123 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_123.w;
    uint4 value_124 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.w, r1.w
    r2.w = value_124.w;
    uint4 value_125 = asuint(asfloat(r4.zzzz) * asfloat(r1.wwww)); // mul r1.w, r4.z, r1.w
    r1.w = value_125.w;
    uint4 value_126 = (r2.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.z, r2.w, l(1)
    r3.z = value_126.z;
    uint4 value_127 = asuint(float4(asint(r3.zzzz))); // itof r3.w, r3.z
    r3.w = value_127.w;
    uint4 value_128 = asuint(asfloat(r4.zzzz) * asfloat(r3.wwww)); // mul r3.w, r4.z, r3.w
    r3.w = value_128.w;
    uint4 value_129 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.x, r3.w
    r4.x = value_129.x;
    uint4 value_130 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_130.w;
    uint4 value_131 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r1.zzzz))); // mad r5.y, cb0[2].y, r3.w, r1.z
    r5.y = value_131.y;
    uint4 value_132 = (asuint(-asint(r4.xxxx)) * r4.yyyy + r3.zzzz); // imad r3.z, -r4.x, r4.y, r3.z
    r3.z = value_132.z;
    uint4 value_133 = asuint(float4(r3.zzzz)); // utof r3.z, r3.z
    r3.z = value_133.z;
    uint4 value_134 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.zzzz), asfloat(r1.xxxx))); // mad r5.x, cb0[2].x, r3.z, r1.x
    r5.x = value_134.x;
    uint4 value_135 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_135.xyzw;
    uint4 value_136 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.z, r5.y, l(1.000000)
    r3.z = value_136.z;
    uint4 value_137 = (r3.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.z, r3.z, l(0x3f800000)
    r3.z = value_137.z;
    uint4 value_138 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_138.xyz;
    uint4 value_139 = asuint(mad(asfloat(r3.zzzz), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r5.xyz, r3.zzzz, r5.xyzx, r6.xyzx
    r5.xyz = value_139.xyz;
    uint4 value_140 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.z, r1.w
    r3.z = value_140.z;
    uint4 value_141 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_141.w;
    uint4 value_142 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r1.zzzz))); // mad r6.y, cb0[2].y, r1.w, r1.z
    r6.y = value_142.y;
    uint4 value_143 = (asuint(-asint(r3.zzzz)) * r4.yyyy + r2.wwww); // imad r1.z, -r3.z, r4.y, r2.w
    r1.z = value_143.z;
    uint4 value_144 = asuint(float4(r1.zzzz)); // utof r1.z, r1.z
    r1.z = value_144.z;
    uint4 value_145 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.zzzz), asfloat(r1.xxxx))); // mad r6.x, cb0[2].x, r1.z, r1.x
    r6.x = value_145.x;
    uint4 value_146 = asuint(t0.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r6.xyxx, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_146.xyzw;
    uint4 value_147 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.x, r6.y, l(1.000000)
    r1.x = value_147.x;
    uint4 value_148 = (r1.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.x, r1.x, l(0x3f800000)
    r1.x = value_148.x;
    uint4 value_149 = asuint(asfloat(asuint(-asfloat(r7.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r6.xyz, -r7.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r6.xyz = value_149.xyz;
    uint4 value_150 = asuint(mad(asfloat(r1.xxxx), asfloat(r6.xxyz), asfloat(r7.xxyz))); // mad r1.xzw, r1.xxxx, r6.xxyz, r7.xxyz
    r1.xzw = value_150.xzw;
    uint4 value_151 = asuint(asfloat(asuint(-asfloat(r1.xzwx))) + asfloat(r5.xyzx)); // add r5.xyz, -r1.xzwx, r5.xyzx
    r5.xyz = value_151.xyz;
    uint4 value_152 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xxyz), asfloat(r1.xxzw))); // mad r1.xzw, r0.wwww, r5.xxyz, r1.xxzw
    r1.xzw = value_152.xzw;
    uint4 value_153 = asuint(asfloat(r1.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r1.xzw, r1.xxzw, -cb0[9].xxyz
    r1.xzw = value_153.xzw;
    uint4 value_154 = asuint(mad(asfloat(r1.yyyy), asfloat(r1.xzwx), asfloat(cb0[9].xyzx))); // mad r1.xyz, r1.yyyy, r1.xzwx, cb0[9].xyzx
    r1.xyz = value_154.xyz;
    uint4 value_155 = asuint(asfloat(r0.xyzx) + asfloat(r2.xyzx)); // add r5.xyz, r0.xyzx, r2.xyzx
    r5.xyz = value_155.xyz;
    uint4 value_156 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.x, r0.xyzx, -cb0[4].xyzx
    r0.x = value_156.x;
    uint4 value_157 = asuint(asfloat(r5.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0xbe99999au, 0x0u))); // add r0.yz, r5.yyyy, l(0.000000, 0.700000, -0.300000, 0.000000)
    r0.yz = value_157.yz;
    uint4 value_158 = asuint(asfloat(r5.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r3.zw, r5.xxxz, -cb0[3].xxxy
    r3.zw = value_158.zw;
    uint4 value_159 = asuint(asfloat(r3.zzzw) * asfloat(cb0[2].zzzz)); // mul r3.zw, r3.zzzw, cb0[2].zzzz
    r3.zw = value_159.zw;
    uint4 value_160 = asuint(max(asfloat(r3.zzzw), asfloat(cb0[7].xxxy))); // max r3.zw, r3.zzzw, cb0[7].xxxy
    r3.zw = value_160.zw;
    uint4 value_161 = asuint(min(asfloat(r3.xyxx), asfloat(r3.zwzz))); // min r3.xy, r3.xyxx, r3.zwzz
    r3.xy = value_161.xy;
    uint4 value_162 = asuint(max(asfloat(r0.zzzz), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.z, r0.z, l(0.000000)
    r0.z = value_162.z;
    uint4 value_163 = asuint(saturate(asfloat(r0.yyyy))); // mov_sat r0.y, r0.y
    r0.y = value_163.y;
    uint4 value_164 = asuint(floor(asfloat(r0.zzzz))); // round_ni r0.w, r0.z
    r0.w = value_164.w;
    uint4 value_165 = asuint(frac(asfloat(r0.zzzz))); // frc r0.z, r0.z
    r0.z = value_165.z;
    uint4 value_166 = asuint(int4(asfloat(r0.wwww))); // ftoi r1.w, r0.w
    r1.w = value_166.w;
    uint4 value_167 = asuint(asfloat(r4.zzzz) * asfloat(r0.wwww)); // mul r0.w, r4.z, r0.w
    r0.w = value_167.w;
    uint4 value_168 = (r1.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.w, r1.w, l(1)
    r2.w = value_168.w;
    uint4 value_169 = asuint(float4(asint(r2.wwww))); // itof r3.z, r2.w
    r3.z = value_169.z;
    uint4 value_170 = asuint(asfloat(r4.zzzz) * asfloat(r3.zzzz)); // mul r3.z, r4.z, r3.z
    r3.z = value_170.z;
    uint4 value_171 = asuint(int4(asfloat(r3.zzzz))); // ftoi r3.w, r3.z
    r3.w = value_171.w;
    uint4 value_172 = asuint(trunc(asfloat(r3.zzzz))); // round_z r3.z, r3.z
    r3.z = value_172.z;
    uint4 value_173 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.zzzz), asfloat(r3.yyyy))); // mad r5.y, cb0[2].y, r3.z, r3.y
    r5.y = value_173.y;
    uint4 value_174 = (asuint(-asint(r3.wwww)) * r4.yyyy + r2.wwww); // imad r2.w, -r3.w, r4.y, r2.w
    r2.w = value_174.w;
    uint4 value_175 = asuint(float4(r2.wwww)); // utof r2.w, r2.w
    r2.w = value_175.w;
    uint4 value_176 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.wwww), asfloat(r3.xxxx))); // mad r5.x, cb0[2].x, r2.w, r3.x
    r5.x = value_176.x;
    uint4 value_177 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_177.xyzw;
    uint4 value_178 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.w, r5.y, l(1.000000)
    r2.w = value_178.w;
    uint4 value_179 = (r2.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.w, r2.w, l(0x3f800000)
    r2.w = value_179.w;
    uint4 value_180 = asuint(asfloat(asuint(-asfloat(r6.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r4.xzw, -r6.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r4.xzw = value_180.xzw;
    uint4 value_181 = asuint(mad(asfloat(r2.wwww), asfloat(r4.xxzw), asfloat(r6.xxyz))); // mad r4.xzw, r2.wwww, r4.xxzw, r6.xxyz
    r4.xzw = value_181.xzw;
    uint4 value_182 = asuint(int4(asfloat(r0.wwww))); // ftoi r2.w, r0.w
    r2.w = value_182.w;
    uint4 value_183 = asuint(trunc(asfloat(r0.wwww))); // round_z r0.w, r0.w
    r0.w = value_183.w;
    uint4 value_184 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r0.wwww), asfloat(r3.yyyy))); // mad r5.y, cb0[2].y, r0.w, r3.y
    r5.y = value_184.y;
    uint4 value_185 = (asuint(-asint(r2.wwww)) * r4.yyyy + r1.wwww); // imad r0.w, -r2.w, r4.y, r1.w
    r0.w = value_185.w;
    uint4 value_186 = asuint(float4(r0.wwww)); // utof r0.w, r0.w
    r0.w = value_186.w;
    uint4 value_187 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.wwww), asfloat(r3.xxxx))); // mad r5.x, cb0[2].x, r0.w, r3.x
    r5.x = value_187.x;
    uint4 value_188 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r3.xyzw = value_188.xyzw;
    uint4 value_189 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.w, r5.y, l(1.000000)
    r0.w = value_189.w;
    uint4 value_190 = (r0.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.w, r0.w, l(0x3f800000)
    r0.w = value_190.w;
    uint4 value_191 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r3.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_191.xyz;
    uint4 value_192 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r0.wwww, r5.xyzx, r3.xyzx
    r3.xyz = value_192.xyz;
    uint4 value_193 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(r4.xzwx)); // add r4.xyz, -r3.xyzx, r4.xzwx
    r4.xyz = value_193.xyz;
    uint4 value_194 = asuint(mad(asfloat(r0.zzzz), asfloat(r4.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r0.zzzz, r4.xyzx, r3.xyzx
    r3.xyz = value_194.xyz;
    uint4 value_195 = asuint(asfloat(r3.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r3.xyz, r3.xyzx, -cb0[9].xyzx
    r3.xyz = value_195.xyz;
    uint4 value_196 = asuint(mad(asfloat(r0.yyyy), asfloat(r3.xxyz), asfloat(cb0[9].xxyz))); // mad r0.yzw, r0.yyyy, r3.xxyz, cb0[9].xxyz
    r0.yzw = value_196.yzw;
    uint4 value_197 = asuint(asfloat(r0.yzwy) * asfloat(r1.xyzx)); // mul r3.xyz, r0.yzwy, r1.xyzx
    r3.xyz = value_197.xyz;
    uint4 value_198 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_198.w;
    uint4 value_199 = asuint(mad(asfloat(r1.xxyz), asfloat(r0.yyzw), asfloat(asuint(-asfloat(r1.wwww))))); // mad r0.yzw, r1.xxyz, r0.yyzw, -r1.wwww
    r0.yzw = value_199.yzw;
    uint4 value_200 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r1.x, cb0[5].w, cb0[6].w
    r1.x = value_200.x;
    uint4 value_201 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r1.x, r1.x, l(0.500000)
    r1.x = value_201.x;
    uint4 value_202 = asuint(asfloat(r1.xxxx) * asfloat(cb0[29].xxxx)); // mul r1.x, r1.x, cb0[29].x
    r1.x = value_202.x;
    uint4 value_203 = asuint(mad(asfloat(r1.xxxx), asfloat(r0.yyzw), asfloat(r1.wwww))); // mad r0.yzw, r1.xxxx, r0.yyzw, r1.wwww
    r0.yzw = value_203.yzw;
    uint4 value_204 = asuint(asfloat(r2.yyyy) * asfloat(cb0[31].xyzx)); // mul r1.xyz, r2.yyyy, cb0[31].xyzx
    r1.xyz = value_204.xyz;
    uint4 value_205 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r2.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb0[30].xyzx, r2.xxxx, r1.xyzx
    r1.xyz = value_205.xyz;
    uint4 value_206 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r2.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb0[32].xyzx, r2.zzzz, r1.xyzx
    r1.xyz = value_206.xyz;
    uint4 value_207 = asuint(asfloat(r1.xyzx) + asfloat(cb0[33].xyzx)); // add r1.xyz, r1.xyzx, cb0[33].xyzx
    r1.xyz = value_207.xyz;
    uint4 value_208 = asuint(asfloat(r1.xyxx) * asfloat(cb0[39].zwzz)); // mul r2.xy, r1.xyxx, cb0[39].zwzz
    r2.xy = value_208.xy;
    uint4 value_209 = asuint(frac(asfloat(r2.xxxy))); // frc r2.zw, r2.xxxy
    r2.zw = value_209.zw;
    uint4 value_210 = asuint(asfloat(r0.xxxx) * asfloat(cb0[38].yyyy)); // mul r1.w, r0.x, cb0[38].y
    r1.w = value_210.w;
    uint4 value_211 = asuint(saturate(asfloat(r0.xxxx))); // mov_sat r0.x, r0.x
    r0.x = value_211.x;
    uint4 value_212 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_212.x;
    uint4 value_213 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r1.zzzz))); // mad r1.z, -r1.w, l(0.050000), r1.z
    r1.z = value_213.z;
    uint4 value_214 = r1.xyxx; // mov o4.xy, r1.xyxx
    out_o4.xy = value_214.xy;
    uint4 value_215 = asuint(asfloat(r1.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r1.z, r1.z, l(-0.003922)
    r1.z = value_215.z;
    uint4 value_216 = asuint(asfloat(r2.xxxy) * asfloat(cb0[39].xxxy)); // mul r3.zw, r2.xxxy, cb0[39].xxxy
    r3.zw = value_216.zw;
    uint4 value_217 = asuint(mad(asfloat(r2.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r3.xy, r2.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r3.xy = value_217.xy;
    uint4 value_218 = asuint(t1.SampleLevel(s1, asfloat(r3.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.zyzz, t1.xyzw, s1, l(0.000000)
    r4.xyzw = value_218.xyzw;
    uint4 value_219 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r1.zzzz, -r4.xyzx
    r4.xyz = value_219.xyz;
    uint4 value_220 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r1.x, cb0[38].x, l(20.000000)
    r1.x = value_220.x;
    uint4 value_221 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r1.xxxx, r4.xyzx
    r4.xyz = value_221.xyz;
    uint4 value_222 = asuint(asfloat(asuint(-asfloat(r2.zwzz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r2.xy, -r2.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
    r2.xy = value_222.xy;
    uint4 value_223 = asuint(asfloat(r2.xxxx) * asfloat(r4.xyzx)); // mul r4.xyz, r2.xxxx, r4.xyzx
    r4.xyz = value_223.xyz;
    uint4 value_224 = asuint(asfloat(r2.wwww) * asfloat(r4.xyzx)); // mul r4.xyz, r2.wwww, r4.xyzx
    r4.xyz = value_224.xyz;
    uint4 value_225 = asuint(t1.SampleLevel(s1, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t1.xyzw, s1, l(0.000000)
    r5.xyzw = value_225.xyzw;
    uint4 value_226 = asuint(t1.SampleLevel(s1, asfloat(r3.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r3.xwxx, t1.xyzw, s1, l(0.000000)
    r6.xyzw = value_226.xyzw;
    uint4 value_227 = asuint(t1.SampleLevel(s1, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.xyxx, t1.xyzw, s1, l(0.000000)
    r3.xyzw = value_227.xyzw;
    uint4 value_228 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r3.xyz, r1.zzzz, -r3.xyzx
    r3.xyz = value_228.xyz;
    uint4 value_229 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r3.xyzx))))); // mul_sat r3.xyz, r1.xxxx, r3.xyzx
    r3.xyz = value_229.xyz;
    uint4 value_230 = asuint(asfloat(r2.zzzz) * asfloat(r3.xyzx)); // mul r3.xyz, r2.zzzz, r3.xyzx
    r3.xyz = value_230.xyz;
    uint4 value_231 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r1.zzzz, -r6.xyzx
    r6.xyz = value_231.xyz;
    uint4 value_232 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r1.xxxx, r6.xyzx
    r6.xyz = value_232.xyz;
    uint4 value_233 = asuint(asfloat(r2.zzzz) * asfloat(r6.xyzx)); // mul r6.xyz, r2.zzzz, r6.xyzx
    r6.xyz = value_233.xyz;
    uint4 value_234 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r1.zzzz, -r5.xyzx
    r5.xyz = value_234.xyz;
    uint4 value_235 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r1.xxxx, r5.xyzx
    r5.xyz = value_235.xyz;
    uint4 value_236 = asuint(asfloat(r2.xxxx) * asfloat(r5.xyzx)); // mul r5.xyz, r2.xxxx, r5.xyzx
    r5.xyz = value_236.xyz;
    uint4 value_237 = asuint(mad(asfloat(r5.xyzx), asfloat(r2.yyyy), asfloat(r4.xyzx))); // mad r4.xyz, r5.xyzx, r2.yyyy, r4.xyzx
    r4.xyz = value_237.xyz;
    uint4 value_238 = asuint(mad(asfloat(r6.xyzx), asfloat(r2.yyyy), asfloat(r4.xyzx))); // mad r2.xyz, r6.xyzx, r2.yyyy, r4.xyzx
    r2.xyz = value_238.xyz;
    uint4 value_239 = asuint(mad(asfloat(r3.xyzx), asfloat(r2.wwww), asfloat(r2.xyzx))); // mad r2.xyz, r3.xyzx, r2.wwww, r2.xyzx
    r2.xyz = value_239.xyz;
    uint4 value_240 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r1.x, r2.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r1.x = value_240.x;
    uint4 value_241 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.x, l(1.000000)
    r1.x = value_241.x;
    uint4 value_242 = asuint(asfloat(r0.xxxx) * asfloat(r0.xxxx)); // mul r1.y, r0.x, r0.x
    r1.y = value_242.y;
    uint4 value_243 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r1.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r1.w, -r0.x, r1.y, l(1.000000)
    r1.w = value_243.w;
    uint4 value_244 = asuint(asfloat(r1.wwww) * asfloat(r1.xxxx)); // mul r0.x, r1.w, r1.x
    r0.x = value_244.x;
    uint4 value_245 = r1.zzzw; // mov o4.zw, r1.zzzw
    out_o4.zw = value_245.zw;
    uint4 value_246 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].wwww)); // mul r0.x, r0.x, cb0[5].w
    r0.x = value_246.x;
    uint4 value_247 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_247.xyz;
    uint4 value_248 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_248.xyz;
    uint4 value_249 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r0.xxxx, r2.xyzx, r1.xyzx
    r1.xyz = value_249.xyz;
    uint4 value_250 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.xxxx, cb0[5].xyzx
    r2.xyz = value_250.xyz;
    uint4 value_251 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_251.xyz;
    uint4 value_252 = asuint(mad(asfloat(r0.yyzw), asfloat(r1.xxyz), asfloat(r2.xxyz))); // mad r0.yzw, r0.yyzw, r1.xxyz, r2.xxyz
    r0.yzw = value_252.yzw;
    uint4 value_253 = asuint(asfloat(r0.yyzw) + asfloat(uint4(0x0u, 0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu))); // add r0.yzw, r0.yyzw, l(0.000000, 0.100000, 0.100000, 0.100000)
    r0.yzw = value_253.yzw;
    uint4 value_254 = asuint(asfloat(r0.yzwy) * asfloat(v4.xyzx)); // mul o3.xyz, r0.yzwy, v4.xyzx
    out_o3.xyz = value_254.xyz;
    uint4 value_255 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.y, cb0[5].w, -cb0[6].w
    r0.y = value_255.y;
    uint4 value_256 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yyyy), asfloat(cb0[6].wwww))); // mad o3.w, r0.x, r0.y, cb0[6].w
    out_o3.w = value_256.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xy);
    result.o1_1 = asfloat(out_o1.zw);
    result.o2_0 = asfloat(out_o2.xyzw);
    result.o3_0 = asfloat(out_o3.xyzw);
    result.o4_0 = asfloat(out_o4.xyzw);
    return result;
}
