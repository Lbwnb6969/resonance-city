// Register-explicit recovered HLSL. Not original source.
// Placemaker/Dust vs_4_0 variant []
// Source SHA256 0177ee26a36fa97c123bee204d03d9a53582a7f38d89a09870127df155d5ef98
// b0: $Globals 688 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[5].x = _SunColor rows=1 cols=4 byte_offset=80
// cb0[6].x = _ShadowColor rows=1 cols=4 byte_offset=96
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _AoTex
// t1 / s1 = _VoxelTex
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 7
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
    uint4 value_1 = asuint(asfloat(v3.yyyy) * asfloat(v3.yyyy)); // mul r0.x, v3.y, v3.y
    r0.x = value_1.x;
    uint4 value_2 = asuint(asfloat(r0.xxxx) * asfloat(r0.xxxx)); // mul r0.x, r0.x, r0.x
    r0.x = value_2.x;
    uint4 value_3 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r0.xxxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.x, -r0.x, r0.x, l(1.000000)
    r0.x = value_3.x;
    uint4 value_4 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul o0.z, r0.x, l(4.000000)
    out_o0.z = value_4.z;
    uint4 value_5 = asuint(frac(asfloat(v1.xyxx))); // frc o0.xy, v1.xyxx
    out_o0.xy = value_5.xy;
    uint4 value_6 = v3.zzzz; // mov o0.w, v3.z
    out_o0.w = value_6.w;
    uint4 value_7 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzx)); // mul r0.xyz, v0.yyyy, cb1[1].xyzx
    r0.xyz = value_7.xyz;
    uint4 value_8 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb1[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_8.xyz;
    uint4 value_9 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb1[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_9.xyz;
    uint4 value_10 = asuint(mad(asfloat(cb1[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb1[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_10.xyz;
    uint4 value_11 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_11.xyz;
    uint4 value_12 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.w, r1.xyzx, r1.xyzx
    r0.w = value_12.w;
    uint4 value_13 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_13.w;
    uint4 value_14 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_14.w;
    uint4 value_15 = asuint(asfloat(r0.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_15.xyz;
    uint4 value_16 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r0.w, r1.y, cb0[22].w, r0.y
    r0.w = value_16.w;
    uint4 value_17 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_17.w;
    uint4 value_18 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r0.w
    r2.w = value_18.w;
    uint4 value_19 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_19.xz;
    uint4 value_20 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r0.xyz, r0.xyzx, r2.xwzx
    r0.xyz = value_20.xyz;
    uint4 value_21 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_21.xyzw;
    uint4 value_22 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r1.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(asfloat(r1.xyzw) + asfloat(cb2[20].xyzw)); // add o1.xyzw, r1.xyzw, cb2[20].xyzw
    out_o1.xyzw = value_24.xyzw;
    uint4 value_25 = asuint(asfloat(r0.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r0.xz, r0.xxzx, -cb0[3].xxyx
    r0.xz = value_25.xz;
    uint4 value_26 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0x3f333333u, 0x3f000000u, 0xbe99999au, 0xbf000000u))); // add r1.xyzw, r0.yyyy, l(0.700000, 0.500000, -0.300000, -0.500000)
    r1.xyzw = value_26.xyzw;
    uint4 value_27 = asuint(asfloat(r0.xzxx) * asfloat(cb0[2].zzzz)); // mul r0.xy, r0.xzxx, cb0[2].zzzz
    r0.xy = value_27.xy;
    uint4 value_28 = asuint(max(asfloat(r0.xyxx), asfloat(cb0[7].xyxx))); // max r0.xy, r0.xyxx, cb0[7].xyxx
    r0.xy = value_28.xy;
    uint4 value_29 = asuint(asfloat(cb0[2].xxxy) + asfloat(asuint(-asfloat(cb0[7].xxxy)))); // add r0.zw, cb0[2].xxxy, -cb0[7].xxxy
    r0.zw = value_29.zw;
    uint4 value_30 = asuint(min(asfloat(r0.zwzz), asfloat(r0.xyxx))); // min r0.xy, r0.zwzz, r0.xyxx
    r0.xy = value_30.xy;
    uint4 value_31 = asuint(max(asfloat(r1.zzzw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.zw, r1.zzzw, l(0.000000, 0.000000, 0.000000, 0.000000)
    r0.zw = value_31.zw;
    uint4 value_32 = asuint(saturate(asfloat(r1.xyxx))); // mov_sat r1.xy, r1.xyxx
    r1.xy = value_32.xy;
    uint4 value_33 = asuint(floor(asfloat(r0.zzzw))); // round_ni r1.zw, r0.zzzw
    r1.zw = value_33.zw;
    uint4 value_34 = asuint(frac(asfloat(r0.zzzw))); // frc r0.zw, r0.zzzw
    r0.zw = value_34.zw;
    uint4 value_35 = asuint(int4(asfloat(r1.zwzz))); // ftoi r2.xy, r1.zwzz
    r2.xy = value_35.xy;
    uint4 value_36 = (r2.xxxy + uint4(0x0u, 0x0u, 0x1u, 0x1u)); // iadd r2.zw, r2.xxxy, l(0, 0, 1, 1)
    r2.zw = value_36.zw;
    uint4 value_37 = asuint(float4(asint(r2.zwzz))); // itof r3.xy, r2.zwzz
    r3.xy = value_37.xy;
    uint4 value_38 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r3.z, cb0[2].w
    r3.z = value_38.z;
    uint4 value_39 = uint4(asfloat(r3.zzzz)); // ftou r3.z, r3.z
    r3.z = value_39.z;
    uint4 value_40 = asuint(float4(r3.zzzz)); // utof r3.w, r3.z
    r3.w = value_40.w;
    uint4 value_41 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r3.wwww)); // div r3.w, l(1.000000, 1.000000, 1.000000, 1.000000), r3.w
    r3.w = value_41.w;
    uint4 value_42 = asuint(asfloat(r3.wwww) * asfloat(r3.xyxx)); // mul r3.xy, r3.wwww, r3.xyxx
    r3.xy = value_42.xy;
    uint4 value_43 = asuint(asfloat(r1.zzzw) * asfloat(r3.wwww)); // mul r1.zw, r1.zzzw, r3.wwww
    r1.zw = value_43.zw;
    uint4 value_44 = asuint(int4(asfloat(r3.xyxx))); // ftoi r4.xy, r3.xyxx
    r4.xy = value_44.xy;
    uint4 value_45 = asuint(trunc(asfloat(r3.xyxx))); // round_z r3.xy, r3.xyxx
    r3.xy = value_45.xy;
    uint4 value_46 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.xxxy), asfloat(r0.yyyy))); // mad r5.zw, cb0[2].yyyy, r3.xxxy, r0.yyyy
    r5.zw = value_46.zw;
    uint4 value_47 = (asuint(-asint(r4.xxxy)) * r3.zzzz + r2.zzzw); // imad r2.zw, -r4.xxxy, r3.zzzz, r2.zzzw
    r2.zw = value_47.zw;
    uint4 value_48 = asuint(float4(r2.zzzw)); // utof r2.zw, r2.zzzw
    r2.zw = value_48.zw;
    uint4 value_49 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.zwzz), asfloat(r0.xxxx))); // mad r5.xy, cb0[2].xxxx, r2.zwzz, r0.xxxx
    r5.xy = value_49.xy;
    uint4 value_50 = asuint(t0.SampleLevel(s0, asfloat(r5.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r5.xzxx, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_50.xyzw;
    uint4 value_51 = asuint(t1.SampleLevel(s1, asfloat(r5.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.ywyy, t1.xyzw, s1, l(0.000000)
    r6.xyzw = value_51.xyzw;
    uint4 value_52 = ((asfloat(r5.zzzz) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.z, r5.z, l(1.000000)
    r2.z = value_52.z;
    uint4 value_53 = (r2.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.z, r2.z, l(0x3f800000)
    r2.z = value_53.z;
    uint4 value_54 = asuint(asfloat(asuint(-asfloat(r4.xyxz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x3f800000u))); // add r3.xyw, -r4.xyxz, l(1.000000, 1.000000, 0.000000, 1.000000)
    r3.xyw = value_54.xyw;
    uint4 value_55 = asuint(mad(asfloat(r2.zzzz), asfloat(r3.xyxw), asfloat(r4.xyxz))); // mad r3.xyw, r2.zzzz, r3.xyxw, r4.xyxz
    r3.xyw = value_55.xyw;
    uint4 value_56 = asuint(int4(asfloat(r1.zzzw))); // ftoi r2.zw, r1.zzzw
    r2.zw = value_56.zw;
    uint4 value_57 = asuint(trunc(asfloat(r1.zzzw))); // round_z r1.zw, r1.zzzw
    r1.zw = value_57.zw;
    uint4 value_58 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.zzzw), asfloat(r0.yyyy))); // mad r4.zw, cb0[2].yyyy, r1.zzzw, r0.yyyy
    r4.zw = value_58.zw;
    uint4 value_59 = (asuint(-asint(r2.zzzw)) * r3.zzzz + r2.xxxy); // imad r1.zw, -r2.zzzw, r3.zzzz, r2.xxxy
    r1.zw = value_59.zw;
    uint4 value_60 = asuint(float4(r1.zzzw)); // utof r1.zw, r1.zzzw
    r1.zw = value_60.zw;
    uint4 value_61 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.zwzz), asfloat(r0.xxxx))); // mad r4.xy, cb0[2].xxxx, r1.zwzz, r0.xxxx
    r4.xy = value_61.xy;
    uint4 value_62 = asuint(t0.SampleLevel(s0, asfloat(r4.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r4.xzxx, t0.xyzw, s0, l(0.000000)
    r2.xyzw = value_62.xyzw;
    uint4 value_63 = asuint(t1.SampleLevel(s1, asfloat(r4.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.ywyy, t1.xyzw, s1, l(0.000000)
    r5.xyzw = value_63.xyzw;
    uint4 value_64 = ((asfloat(r4.zzzz) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, r4.z, l(1.000000)
    r0.x = value_64.x;
    uint4 value_65 = (r0.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.x, r0.x, l(0x3f800000)
    r0.x = value_65.x;
    uint4 value_66 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r4.xyz, -r2.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r4.xyz = value_66.xyz;
    uint4 value_67 = asuint(mad(asfloat(r0.xxxx), asfloat(r4.xyzx), asfloat(r2.xyzx))); // mad r2.xyz, r0.xxxx, r4.xyzx, r2.xyzx
    r2.xyz = value_67.xyz;
    uint4 value_68 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(r3.xywx)); // add r3.xyz, -r2.xyzx, r3.xywx
    r3.xyz = value_68.xyz;
    uint4 value_69 = asuint(mad(asfloat(r0.zzzz), asfloat(r3.xyzx), asfloat(r2.xyzx))); // mad r0.xyz, r0.zzzz, r3.xyzx, r2.xyzx
    r0.xyz = value_69.xyz;
    uint4 value_70 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r0.xyz, r0.xyzx, -cb0[9].xyzx
    r0.xyz = value_70.xyz;
    uint4 value_71 = asuint(mad(asfloat(r1.xxxx), asfloat(r0.xyzx), asfloat(cb0[9].xyzx))); // mad r0.xyz, r1.xxxx, r0.xyzx, cb0[9].xyzx
    r0.xyz = value_71.xyz;
    uint4 value_72 = asuint(asfloat(r0.xxyz) * asfloat(r0.xxyz)); // mul r1.xzw, r0.xxyz, r0.xxyz
    r1.xzw = value_72.xzw;
    uint4 value_73 = asuint(dot(asfloat(r1.xzwx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.x, r1.xzwx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.x = value_73.x;
    uint4 value_74 = asuint(mad(asfloat(r0.xyzx), asfloat(r0.xyzx), asfloat(asuint(-asfloat(r1.xxxx))))); // mad r0.xyz, r0.xyzx, r0.xyzx, -r1.xxxx
    r0.xyz = value_74.xyz;
    uint4 value_75 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r1.z, cb0[5].w, cb0[6].w
    r1.z = value_75.z;
    uint4 value_76 = asuint(saturate(asfloat(asuint(asfloat(r1.zzzz) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r1.z, r1.z, l(0.500000)
    r1.z = value_76.z;
    uint4 value_77 = asuint(asfloat(r1.zzzz) * asfloat(cb0[29].xxxx)); // mul r1.z, r1.z, cb0[29].x
    r1.z = value_77.z;
    uint4 value_78 = asuint(mad(asfloat(r1.zzzz), asfloat(r0.xyzx), asfloat(r1.xxxx))); // mad r0.xyz, r1.zzzz, r0.xyzx, r1.xxxx
    r0.xyz = value_78.xyz;
    uint4 value_79 = asuint(asfloat(cb0[6].xxyz) * asfloat(uint4(0x3fe66666u, 0x0u, 0x3fe66666u, 0x3fe66666u))); // mul r1.xzw, cb0[6].xxyz, l(1.800000, 0.000000, 1.800000, 1.800000)
    r1.xzw = value_79.xzw;
    uint4 value_80 = asuint(mad(asfloat(r0.xyzx), asfloat(r1.xzwx), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)))); // mad r0.xyz, r0.xyzx, r1.xzwx, l(0.100000, 0.100000, 0.100000, 0.000000)
    r0.xyz = value_80.xyz;
    uint4 value_81 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(uint4(0xbdccccc8u, 0xbdccccc8u, 0xbdccccc8u, 0xbdccccc8u)), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x3f333333u)))); // mad r1.x, cb0[29].x, l(-0.100000), l(0.700000)
    r1.x = value_81.x;
    uint4 value_82 = asuint(asfloat(r1.xxxx) * asfloat(cb0[6].wwww)); // mul r1.z, r1.x, cb0[6].w
    r1.z = value_82.z;
    uint4 value_83 = asuint(asfloat(r1.zzzz) * asfloat(uint4(0x32000000u, 0x32000000u, 0x32000000u, 0x32000000u))); // mul r1.z, r1.z, l(0.000000)
    r1.z = value_83.z;
    uint4 value_84 = asuint(mad(asfloat(r1.xxxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)), asfloat(r1.zzzz))); // mad r1.z, r1.x, l(1.000000), r1.z
    r1.z = value_84.z;
    uint4 value_85 = asuint(asfloat(r0.xyzx) * asfloat(r1.zzzz)); // mul r0.xyz, r0.xyzx, r1.zzzz
    r0.xyz = value_85.xyz;
    uint4 value_86 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.z, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.z = value_86.z;
    uint4 value_87 = asuint(asfloat(asuint(-asfloat(r1.zzzz))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r1.w, -r1.z, l(0.600000)
    r1.w = value_87.w;
    uint4 value_88 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r1.zzzz)); // add r1.z, -r1.w, r1.z
    r1.z = value_88.z;
    uint4 value_89 = asuint(mad(asfloat(r1.zzzz), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r1.zzzz, l(0.100000, 0.100000, 0.100000, 0.000000), r0.xyzx
    r0.xyz = value_89.xyz;
    uint4 value_90 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r0.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_90.xyz;
    uint4 value_91 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r0.xyzx
    r0.xyz = value_91.xyz;
    uint4 value_92 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(r0.xyzx)); // add r0.xyz, -r1.xxxx, r0.xyzx
    r0.xyz = value_92.xyz;
    uint4 value_93 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.xyzx), asfloat(r1.xxxx))); // mad o2.xyz, cb0[29].yyyy, r0.xyzx, r1.xxxx
    out_o2.xyz = value_93.xyz;
    uint4 value_94 = asuint(asfloat(asuint(-asfloat(r5.wwww))) + asfloat(r6.wwww)); // add r0.x, -r5.w, r6.w
    r0.x = value_94.x;
    uint4 value_95 = asuint(mad(asfloat(r0.wwww), asfloat(r0.xxxx), asfloat(r5.wwww))); // mad r0.x, r0.w, r0.x, r5.w
    r0.x = value_95.x;
    uint4 value_96 = asuint(asfloat(r0.xxxx) + asfloat(asuint(-asfloat(cb0[9].wwww)))); // add r0.x, r0.x, -cb0[9].w
    r0.x = value_96.x;
    uint4 value_97 = asuint(mad(asfloat(r1.yyyy), asfloat(r0.xxxx), asfloat(cb0[9].wwww))); // mad r0.x, r1.y, r0.x, cb0[9].w
    r0.x = value_97.x;
    uint4 value_98 = asuint(asfloat(v3.zzzz) * asfloat(uint4(0x4148a8c1u, 0x4148a8c1u, 0x4148a8c1u, 0x4148a8c1u))); // mul r0.y, v3.z, l(12.541200)
    r0.y = value_98.y;
    uint4 value_99 = asuint(frac(asfloat(r0.yyyy))); // frc r0.y, r0.y
    r0.y = value_99.y;
    uint4 value_100 = asuint(asfloat(r0.yyyy) * asfloat(v3.wwww)); // mul r0.y, r0.y, v3.w
    r0.y = value_100.y;
    uint4 value_101 = asuint(asfloat(r0.xxxx) * asfloat(r0.yyyy)); // mul r0.x, r0.x, r0.y
    r0.x = value_101.x;
    uint4 value_102 = ((asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) >= asfloat(v1.xxxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.y, l(1.000000), v1.x
    r0.y = value_102.y;
    uint4 value_103 = (r0.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.y, r0.y, l(0x3f800000)
    r0.y = value_103.y;
    uint4 value_104 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul o2.w, r0.y, r0.x
    out_o2.w = value_104.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xyzw);
    result.o2_0 = asfloat(out_o2.xyzw);
    result.o3_0 = asfloat(out_o3.xyzw);
    return result;
}
