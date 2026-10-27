// Register-explicit recovered HLSL. Not original source.
// Placemaker/Ground vs_4_0 variant []
// Source SHA256 13410692d0684efe378d927fd53dc1cd61f5609845284241f9664a425925e58d
// b0: $Globals 688 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _AoTex
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 8
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float2 v2_0: TEXCOORD1;
    float3 v3_0: NORMAL0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD1;
    float2 o1_0: TEXCOORD2;
    float4 o2_0: SV_POSITION;
    float4 o3_0: COLOR0;
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
    v2.xy = asuint(input.v2_0);
    v3.xyz = asuint(input.v3_0);
    uint4 value_1 = asuint(asfloat(v1.yyyy) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.x, v1.y, l(0.500000)
    r0.x = value_1.x;
    uint4 value_2 = asuint(frac(asfloat(r0.xxxx))); // frc r0.x, r0.x
    r0.x = value_2.x;
    uint4 value_3 = asuint(asfloat(r0.xxxx) + asfloat(r0.xxxx)); // add o0.y, r0.x, r0.x
    out_o0.y = value_3.y;
    uint4 value_4 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzx)); // mul r0.xyz, v0.yyyy, cb1[1].xyzx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb1[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_5.xyz;
    uint4 value_6 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb1[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_6.xyz;
    uint4 value_7 = asuint(mad(asfloat(cb1[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb1[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_7.xyz;
    uint4 value_8 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_8.xyz;
    uint4 value_9 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r0.w, r1.xyzx, r1.xyzx
    r0.w = value_9.w;
    uint4 value_10 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_10.w;
    uint4 value_11 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_11.w;
    uint4 value_12 = asuint(asfloat(r0.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_12.xyz;
    uint4 value_13 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r0.w, r1.y, cb0[22].w, r0.y
    r0.w = value_13.w;
    uint4 value_14 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_14.w;
    uint4 value_15 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r0.w
    r2.w = value_15.w;
    uint4 value_16 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_16.xz;
    uint4 value_17 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r1.xyz, r0.xyzx, r2.xwzx
    r1.xyz = value_17.xyz;
    uint4 value_18 = asuint(asfloat(r1.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r2.xy, r1.xzxx, -cb0[3].xyxx
    r2.xy = value_18.xy;
    uint4 value_19 = asuint(asfloat(r2.xxxy) * asfloat(cb0[2].zzzz)); // mul o0.zw, r2.xxxy, cb0[2].zzzz
    out_o0.zw = value_19.zw;
    uint4 value_20 = v1.xxxx; // mov o0.x, v1.x
    out_o0.x = value_20.x;
    uint4 value_21 = asuint(asfloat(v1.yyyy) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.w, v1.y, l(0.500000)
    r0.w = value_21.w;
    uint4 value_22 = asuint(floor(asfloat(r0.wwww))); // round_ni r0.w, r0.w
    r0.w = value_22.w;
    uint4 value_23 = asuint(asfloat(r0.wwww) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.w, r0.w, l(0.500000)
    r0.w = value_23.w;
    uint4 value_24 = asuint(int4(asfloat(r0.wwww))); // ftoi r0.w, r0.w
    r0.w = value_24.w;
    uint4 value_25 = asuint(asint(r0.wwww) >> (uint4(0x1u, 0x1u, 0x1u, 0x1u) & 31u)); // ishr r2.x, r0.w, l(1)
    r2.x = value_25.x;
    uint4 value_26 = asuint(asint(r0.wwww) >> (uint4(0x2u, 0x2u, 0x2u, 0x2u) & 31u)); // ishr r2.y, r0.w, l(2)
    r2.y = value_26.y;
    uint4 value_27 = asuint(asint(r0.wwww) >> (uint4(0x3u, 0x3u, 0x3u, 0x3u) & 31u)); // ishr r2.z, r0.w, l(3)
    r2.z = value_27.z;
    uint4 value_28 = (r0.wwww & uint4(0x1u, 0x1u, 0x1u, 0x1u)); // and r0.w, r0.w, l(1)
    r0.w = value_28.w;
    uint4 value_29 = asuint(float4(asint(r0.wwww))); // itof r0.w, r0.w
    r0.w = value_29.w;
    uint4 value_30 = (r2.xyzx & uint4(0x1u, 0x1u, 0x1u, 0x0u)); // and r2.xyz, r2.xyzx, l(1, 1, 1, 0)
    r2.xyz = value_30.xyz;
    uint4 value_31 = asuint(float4(asint(r2.xyzx))); // itof r2.xyz, r2.xyzx
    r2.xyz = value_31.xyz;
    uint4 value_32 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(r2.xxxx)); // add o1.x, -r0.w, r2.x
    out_o1.x = value_32.x;
    uint4 value_33 = asuint(asfloat(r2.zzzz) + asfloat(asuint(-asfloat(r2.yyyy)))); // add o1.y, r2.z, -r2.y
    out_o1.y = value_33.y;
    uint4 value_34 = asuint(asfloat(r1.yyyy) * asfloat(cb2[18].xyzw)); // mul r2.xyzw, r1.yyyy, cb2[18].xyzw
    r2.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r1.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb2[17].xyzw, r1.xxxx, r2.xyzw
    r2.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r1.zzzz), asfloat(r2.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r1.zzzz, r2.xyzw
    r1.xyzw = value_36.xyzw;
    uint4 value_37 = asuint(asfloat(r1.xyzw) + asfloat(cb2[20].xyzw)); // add o2.xyzw, r1.xyzw, cb2[20].xyzw
    out_o2.xyzw = value_37.xyzw;
    uint4 value_38 = asuint(asfloat(r0.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r0.xz, r0.xxzx, -cb0[3].xxyx
    r0.xz = value_38.xz;
    uint4 value_39 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0x3f8ccccdu, 0x3fd9999au, 0x3dccccceu, 0x3f333333u))); // add r1.xyzw, r0.yyyy, l(1.100000, 1.700000, 0.100000, 0.700000)
    r1.xyzw = value_39.xyzw;
    uint4 value_40 = asuint(asfloat(r0.xzxx) * asfloat(cb0[2].zzzz)); // mul r0.xy, r0.xzxx, cb0[2].zzzz
    r0.xy = value_40.xy;
    uint4 value_41 = asuint(max(asfloat(r0.xyxx), asfloat(cb0[7].xyxx))); // max r0.xy, r0.xyxx, cb0[7].xyxx
    r0.xy = value_41.xy;
    uint4 value_42 = asuint(asfloat(cb0[2].xxxy) + asfloat(asuint(-asfloat(cb0[7].xxxy)))); // add r0.zw, cb0[2].xxxy, -cb0[7].xxxy
    r0.zw = value_42.zw;
    uint4 value_43 = asuint(min(asfloat(r0.zwzz), asfloat(r0.xyxx))); // min r0.xy, r0.zwzz, r0.xyxx
    r0.xy = value_43.xy;
    uint4 value_44 = asuint(max(asfloat(r1.zzzw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.zw, r1.zzzw, l(0.000000, 0.000000, 0.000000, 0.000000)
    r0.zw = value_44.zw;
    uint4 value_45 = asuint(saturate(asfloat(r1.xyxx))); // mov_sat r1.xy, r1.xyxx
    r1.xy = value_45.xy;
    uint4 value_46 = asuint(floor(asfloat(r0.zzzw))); // round_ni r1.zw, r0.zzzw
    r1.zw = value_46.zw;
    uint4 value_47 = asuint(frac(asfloat(r0.zzzw))); // frc r0.zw, r0.zzzw
    r0.zw = value_47.zw;
    uint4 value_48 = asuint(int4(asfloat(r1.zwzz))); // ftoi r2.xy, r1.zwzz
    r2.xy = value_48.xy;
    uint4 value_49 = (r2.xxxy + uint4(0x0u, 0x0u, 0x1u, 0x1u)); // iadd r2.zw, r2.xxxy, l(0, 0, 1, 1)
    r2.zw = value_49.zw;
    uint4 value_50 = asuint(float4(asint(r2.zwzz))); // itof r3.xy, r2.zwzz
    r3.xy = value_50.xy;
    uint4 value_51 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r3.z, cb0[2].w
    r3.z = value_51.z;
    uint4 value_52 = uint4(asfloat(r3.zzzz)); // ftou r3.z, r3.z
    r3.z = value_52.z;
    uint4 value_53 = asuint(float4(r3.zzzz)); // utof r3.w, r3.z
    r3.w = value_53.w;
    uint4 value_54 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r3.wwww)); // div r3.w, l(1.000000, 1.000000, 1.000000, 1.000000), r3.w
    r3.w = value_54.w;
    uint4 value_55 = asuint(asfloat(r3.wwww) * asfloat(r3.xyxx)); // mul r3.xy, r3.wwww, r3.xyxx
    r3.xy = value_55.xy;
    uint4 value_56 = asuint(asfloat(r1.zzzw) * asfloat(r3.wwww)); // mul r1.zw, r1.zzzw, r3.wwww
    r1.zw = value_56.zw;
    uint4 value_57 = asuint(int4(asfloat(r3.xyxx))); // ftoi r4.xy, r3.xyxx
    r4.xy = value_57.xy;
    uint4 value_58 = asuint(trunc(asfloat(r3.xyxx))); // round_z r3.xy, r3.xyxx
    r3.xy = value_58.xy;
    uint4 value_59 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.xxxy), asfloat(r0.yyyy))); // mad r5.zw, cb0[2].yyyy, r3.xxxy, r0.yyyy
    r5.zw = value_59.zw;
    uint4 value_60 = (asuint(-asint(r4.xxxy)) * r3.zzzz + r2.zzzw); // imad r2.zw, -r4.xxxy, r3.zzzz, r2.zzzw
    r2.zw = value_60.zw;
    uint4 value_61 = asuint(float4(r2.zzzw)); // utof r2.zw, r2.zzzw
    r2.zw = value_61.zw;
    uint4 value_62 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.zwzz), asfloat(r0.xxxx))); // mad r5.xy, cb0[2].xxxx, r2.zwzz, r0.xxxx
    r5.xy = value_62.xy;
    uint4 value_63 = asuint(t0.SampleLevel(s0, asfloat(r5.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r5.xzxx, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_63.xyzw;
    uint4 value_64 = asuint(t0.SampleLevel(s0, asfloat(r5.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.ywyy, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_64.xyzw;
    uint4 value_65 = ((asfloat(r5.zzzw) >= asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.zw, r5.zzzw, l(0.000000, 0.000000, 1.000000, 1.000000)
    r2.zw = value_65.zw;
    uint4 value_66 = (r2.zzzw & uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u)); // and r2.zw, r2.zzzw, l(0, 0, 0x3f800000, 0x3f800000)
    r2.zw = value_66.zw;
    uint4 value_67 = asuint(asfloat(asuint(-asfloat(r4.xyxz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x3f800000u))); // add r3.xyw, -r4.xyxz, l(1.000000, 1.000000, 0.000000, 1.000000)
    r3.xyw = value_67.xyw;
    uint4 value_68 = asuint(mad(asfloat(r2.zzzz), asfloat(r3.xywx), asfloat(r4.xyzx))); // mad r4.xyz, r2.zzzz, r3.xywx, r4.xyzx
    r4.xyz = value_68.xyz;
    uint4 value_69 = asuint(int4(asfloat(r1.zwzz))); // ftoi r3.xy, r1.zwzz
    r3.xy = value_69.xy;
    uint4 value_70 = asuint(trunc(asfloat(r1.zzzw))); // round_z r1.zw, r1.zzzw
    r1.zw = value_70.zw;
    uint4 value_71 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.zzzw), asfloat(r0.yyyy))); // mad r5.zw, cb0[2].yyyy, r1.zzzw, r0.yyyy
    r5.zw = value_71.zw;
    uint4 value_72 = (asuint(-asint(r3.xxxy)) * r3.zzzz + r2.xxxy); // imad r1.zw, -r3.xxxy, r3.zzzz, r2.xxxy
    r1.zw = value_72.zw;
    uint4 value_73 = asuint(float4(r1.zzzw)); // utof r1.zw, r1.zzzw
    r1.zw = value_73.zw;
    uint4 value_74 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.zwzz), asfloat(r0.xxxx))); // mad r5.xy, cb0[2].xxxx, r1.zwzz, r0.xxxx
    r5.xy = value_74.xy;
    uint4 value_75 = asuint(t0.SampleLevel(s0, asfloat(r5.xzxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r5.xzxx, t0.xyzw, s0, l(0.000000)
    r3.xyzw = value_75.xyzw;
    uint4 value_76 = asuint(t0.SampleLevel(s0, asfloat(r5.ywyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r5.ywyy, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_76.xyzw;
    uint4 value_77 = ((asfloat(r5.zwzz) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.xy, r5.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
    r0.xy = value_77.xy;
    uint4 value_78 = (r0.xyxx & uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u)); // and r0.xy, r0.xyxx, l(0x3f800000, 0x3f800000, 0, 0)
    r0.xy = value_78.xy;
    uint4 value_79 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r2.xyz, -r3.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r2.xyz = value_79.xyz;
    uint4 value_80 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r0.xxxx, r2.xyzx, r3.xyzx
    r3.xyz = value_80.xyz;
    uint4 value_81 = asuint(asfloat(asuint(-asfloat(r3.xyzw))) + asfloat(r4.xyzw)); // add r4.xyzw, -r3.xyzw, r4.xyzw
    r4.xyzw = value_81.xyzw;
    uint4 value_82 = asuint(mad(asfloat(r0.zzzz), asfloat(r4.xyzw), asfloat(r3.xyzw))); // mad r3.xyzw, r0.zzzz, r4.xyzw, r3.xyzw
    r3.xyzw = value_82.xyzw;
    uint4 value_83 = asuint(asfloat(r3.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r3.xyzw, r3.xyzw, -cb0[9].xyzw
    r3.xyzw = value_83.xyzw;
    uint4 value_84 = asuint(mad(asfloat(r1.xxxx), asfloat(r3.xyzw), asfloat(cb0[9].xyzw))); // mad r3.xyzw, r1.xxxx, r3.xyzw, cb0[9].xyzw
    r3.xyzw = value_84.xyzw;
    uint4 value_85 = asuint(asfloat(asuint(-asfloat(r6.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r1.xzw, -r6.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r1.xzw = value_85.xzw;
    uint4 value_86 = asuint(mad(asfloat(r2.wwww), asfloat(r1.xzwx), asfloat(r6.xyzx))); // mad r6.xyz, r2.wwww, r1.xzwx, r6.xyzx
    r6.xyz = value_86.xyz;
    uint4 value_87 = asuint(asfloat(asuint(-asfloat(r7.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r1.xzw, -r7.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r1.xzw = value_87.xzw;
    uint4 value_88 = asuint(mad(asfloat(r0.yyyy), asfloat(r1.xzwx), asfloat(r7.xyzx))); // mad r7.xyz, r0.yyyy, r1.xzwx, r7.xyzx
    r7.xyz = value_88.xyz;
    uint4 value_89 = asuint(asfloat(r6.xyzw) + asfloat(asuint(-asfloat(r7.xyzw)))); // add r2.xyzw, r6.xyzw, -r7.xyzw
    r2.xyzw = value_89.xyzw;
    uint4 value_90 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xyzw), asfloat(r7.xyzw))); // mad r0.xyzw, r0.wwww, r2.xyzw, r7.xyzw
    r0.xyzw = value_90.xyzw;
    uint4 value_91 = asuint(asfloat(r0.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r0.xyzw, r0.xyzw, -cb0[9].xyzw
    r0.xyzw = value_91.xyzw;
    uint4 value_92 = asuint(mad(asfloat(r1.yyyy), asfloat(r0.xyzw), asfloat(cb0[9].xyzw))); // mad r0.xyzw, r1.yyyy, r0.xyzw, cb0[9].xyzw
    r0.xyzw = value_92.xyzw;
    uint4 value_93 = asuint(mad(asfloat(r3.xyzx), asfloat(r0.xyzx), asfloat(uint4(0xbf4ccccdu, 0xbf4ccccdu, 0xbf4ccccdu, 0x0u)))); // mad r0.xyz, r3.xyzx, r0.xyzx, l(-0.800000, -0.800000, -0.800000, 0.000000)
    r0.xyz = value_93.xyz;
    uint4 value_94 = asuint(asfloat(r0.wwww) * asfloat(r3.wwww)); // mul r0.w, r0.w, r3.w
    r0.w = value_94.w;
    uint4 value_95 = r0.wwww; // mov o3.w, r0.w
    out_o3.w = value_95.w;
    uint4 value_96 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.xyzx), asfloat(uint4(0x3f4ccccdu, 0x3f4ccccdu, 0x3f4ccccdu, 0x0u)))); // mad o3.xyz, cb0[29].yyyy, r0.xyzx, l(0.800000, 0.800000, 0.800000, 0.000000)
    out_o3.xyz = value_96.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xy);
    result.o2_0 = asfloat(out_o2.xyzw);
    result.o3_0 = asfloat(out_o3.xyzw);
    return result;
}
