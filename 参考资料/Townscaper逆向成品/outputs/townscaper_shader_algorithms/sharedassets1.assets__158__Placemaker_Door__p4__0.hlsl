// Register-explicit recovered HLSL. Not original source.
// Placemaker/Door vs_4_0 variant []
// Source SHA256 05d7e1488a578ea26f9cc4be07537d3fa729d0adb36be2f8e4fdd0b246de3409
// b0: $Globals 672 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[4].x = _SunDir rows=1 cols=3 byte_offset=64
// cb0[5].x = _SunColor rows=1 cols=4 byte_offset=80
// cb0[6].x = _ShadowColor rows=1 cols=4 byte_offset=96
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// cb0[13].x = _LampTex_TexelSize rows=1 cols=4 byte_offset=208
// cb0[14].x = _Lamp rows=1 cols=4 byte_offset=224
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// cb0[41].x = _Type rows=1 cols=1 byte_offset=656
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _AoTex
// t1 / s3 = _ShadowTex
// t2 / s1 = _LampTex
// t3 / s2 = _MaterialTex
cbuffer Buffer0:register(b0) { uint4 cb0[42]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
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
    float4 v1_0: TANGENT0;
    float2 v2_0: TEXCOORD0;
    float3 v3_0: NORMAL0;
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
    v0.xyzw = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    v3.xyz = asuint(input.v3_0);
    uint4 value_1 = asuint(asfloat(v2.xxxx) + asfloat(cb0[41].xxxx)); // add o0.x, v2.x, cb0[41].x
    out_o0.x = value_1.x;
    uint4 value_2 = v2.yyyy; // mov o0.y, v2.y
    out_o0.y = value_2.y;
    uint4 value_3 = asuint(floor(asfloat(v2.yxyy))); // round_ni r0.xy, v2.yxyy
    r0.xy = value_3.xy;
    uint4 value_4 = asuint(asfloat(r0.xyxx) * asfloat(uint4(0x40e00000u, 0x40a00000u, 0x0u, 0x0u))); // mul r0.xy, r0.xyxx, l(7.000000, 5.000000, 0.000000, 0.000000)
    r0.xy = value_4.xy;
    uint4 value_5 = asuint(asfloat(r0.yyyy) + asfloat(r0.xxxx)); // add r0.x, r0.y, r0.x
    r0.x = value_5.x;
    uint4 value_6 = asuint(asfloat(cb0[13].yyyy) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.y, cb0[13].y, l(0.500000)
    r0.y = value_6.y;
    uint4 value_7 = asuint(mad(asfloat(r0.xxxx), asfloat(cb0[13].yyyy), asfloat(r0.yyyy))); // mad r0.x, r0.x, cb0[13].y, r0.y
    r0.x = value_7.x;
    uint4 value_8 = asuint(frac(asfloat(r0.xxxx))); // frc r0.y, r0.x
    r0.y = value_8.y;
    uint4 value_9 = asuint(saturate(asfloat(cb0[14].xxxx))); // mov_sat r0.x, cb0[14].x
    r0.x = value_9.x;
    uint4 value_10 = asuint(t2.SampleLevel(s1, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t2.xyzw, s1, l(0.000000)
    r0.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(dot(asfloat(r0.xyxx).xy, asfloat(cb0[14].yzyy).xy)).xxxx; // dp2 r0.x, r0.xyxx, cb0[14].yzyy
    r0.x = value_11.x;
    uint4 value_12 = asuint(asfloat(asuint(-asfloat(cb0[5].wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -cb0[5].w, l(1.000000)
    r0.y = value_12.y;
    uint4 value_13 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul o1.z, r0.y, r0.x
    out_o1.z = value_13.z;
    uint4 value_14 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb1[1].xyzw
    r0.xyzw = value_14.xyzw;
    uint4 value_15 = asuint(mad(asfloat(cb1[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_15.xyzw;
    uint4 value_16 = asuint(mad(asfloat(cb1[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_16.xyzw;
    uint4 value_17 = asuint(mad(asfloat(cb1[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_17.xyzw;
    uint4 value_18 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_18.xyz;
    uint4 value_19 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r1.w, r1.xyzx, r1.xyzx
    r1.w = value_19.w;
    uint4 value_20 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.w, l(1.000000)
    r1.w = value_20.w;
    uint4 value_21 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r1.w, l(0.000000)
    r1.w = value_21.w;
    uint4 value_22 = asuint(asfloat(r1.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r1.wwww, r1.xyzx
    r1.xyz = value_22.xyz;
    uint4 value_23 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r1.w, r1.y, cb0[22].w, r0.y
    r1.w = value_23.w;
    uint4 value_24 = asuint(min(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r1.w, r1.w, l(0.000000)
    r1.w = value_24.w;
    uint4 value_25 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r1.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r1.w
    r2.w = value_25.w;
    uint4 value_26 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_26.xz;
    uint4 value_27 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r1.xyz, r0.xyzx, r2.xwzx
    r1.xyz = value_27.xyz;
    uint4 value_28 = asuint(asfloat(r1.yyyy) * asfloat(cb2[10].xyxx)); // mul r2.xy, r1.yyyy, cb2[10].xyxx
    r2.xy = value_28.xy;
    uint4 value_29 = asuint(mad(asfloat(cb2[9].xyxx), asfloat(r1.xxxx), asfloat(r2.xyxx))); // mad r2.xy, cb2[9].xyxx, r1.xxxx, r2.xyxx
    r2.xy = value_29.xy;
    uint4 value_30 = asuint(mad(asfloat(cb2[11].xyxx), asfloat(r1.zzzz), asfloat(r2.xyxx))); // mad r2.xy, cb2[11].xyxx, r1.zzzz, r2.xyxx
    r2.xy = value_30.xy;
    uint4 value_31 = asuint(mad(asfloat(cb2[12].xyxx), asfloat(r0.wwww), asfloat(r2.xyxx))); // mad o1.xy, cb2[12].xyxx, r0.wwww, r2.xyxx
    out_o1.xy = value_31.xy;
    uint4 value_32 = asuint(asfloat(r1.yyyy) * asfloat(cb2[18].xyzw)); // mul r2.xyzw, r1.yyyy, cb2[18].xyzw
    r2.xyzw = value_32.xyzw;
    uint4 value_33 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r1.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb2[17].xyzw, r1.xxxx, r2.xyzw
    r2.xyzw = value_33.xyzw;
    uint4 value_34 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r1.zzzz), asfloat(r2.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r1.zzzz, r2.xyzw
    r1.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(asfloat(r1.xyzw) + asfloat(cb2[20].xyzw)); // add o2.xyzw, r1.xyzw, cb2[20].xyzw
    out_o2.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(asfloat(v3.yyyy) * asfloat(cb1[1].xyzx)); // mul r1.xyz, v3.yyyy, cb1[1].xyzx
    r1.xyz = value_36.xyz;
    uint4 value_37 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v3.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb1[0].xyzx, v3.xxxx, r1.xyzx
    r1.xyz = value_37.xyz;
    uint4 value_38 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v3.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb1[2].xyzx, v3.zzzz, r1.xyzx
    r1.xyz = value_38.xyz;
    uint4 value_39 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r2.xyz, r1.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000), r0.xyzx
    r2.xyz = value_39.xyz;
    uint4 value_40 = asuint(asfloat(r2.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r2.yw, r2.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r2.yw = value_40.yw;
    uint4 value_41 = asuint(asfloat(r2.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r2.xz, r2.xxzx, -cb0[3].xxyx
    r2.xz = value_41.xz;
    uint4 value_42 = asuint(asfloat(r2.xxzx) * asfloat(cb0[2].zzzz)); // mul r2.xz, r2.xxzx, cb0[2].zzzz
    r2.xz = value_42.xz;
    uint4 value_43 = asuint(max(asfloat(r2.xxzx), asfloat(cb0[7].xxyx))); // max r2.xz, r2.xxzx, cb0[7].xxyx
    r2.xz = value_43.xz;
    uint4 value_44 = asuint(max(asfloat(r2.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r2.w, l(0.000000)
    r0.w = value_44.w;
    uint4 value_45 = asuint(saturate(asfloat(r2.yyyy))); // mov_sat r2.y, r2.y
    r2.y = value_45.y;
    uint4 value_46 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.w, r0.w
    r1.w = value_46.w;
    uint4 value_47 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_47.w;
    uint4 value_48 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.w, r1.w
    r2.w = value_48.w;
    uint4 value_49 = (r2.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.x, r2.w, l(1)
    r3.x = value_49.x;
    uint4 value_50 = asuint(float4(asint(r3.xxxx))); // itof r3.y, r3.x
    r3.y = value_50.y;
    uint4 value_51 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r3.z, cb0[2].w
    r3.z = value_51.z;
    uint4 value_52 = uint4(asfloat(r3.zzzz)); // ftou r3.z, r3.z
    r3.z = value_52.z;
    uint4 value_53 = asuint(float4(r3.zzzz)); // utof r3.w, r3.z
    r3.w = value_53.w;
    uint4 value_54 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r3.wwww)); // div r3.w, l(1.000000, 1.000000, 1.000000, 1.000000), r3.w
    r3.w = value_54.w;
    uint4 value_55 = asuint(asfloat(r3.wwww) * asfloat(r3.yyyy)); // mul r3.y, r3.w, r3.y
    r3.y = value_55.y;
    uint4 value_56 = asuint(int4(asfloat(r3.yyyy))); // ftoi r4.x, r3.y
    r4.x = value_56.x;
    uint4 value_57 = asuint(trunc(asfloat(r3.yyyy))); // round_z r3.y, r3.y
    r3.y = value_57.y;
    uint4 value_58 = (asuint(-asint(r4.xxxx)) * r3.zzzz + r3.xxxx); // imad r3.x, -r4.x, r3.z, r3.x
    r3.x = value_58.x;
    uint4 value_59 = asuint(float4(r3.xxxx)); // utof r3.x, r3.x
    r3.x = value_59.x;
    uint4 value_60 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r4.xy, cb0[2].xyxx, -cb0[7].xyxx
    r4.xy = value_60.xy;
    uint4 value_61 = asuint(min(asfloat(r2.xxzx), asfloat(r4.xxyx))); // min r2.xz, r2.xxzx, r4.xxyx
    r2.xz = value_61.xz;
    uint4 value_62 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.xxxx), asfloat(r2.xxxx))); // mad r5.x, cb0[2].x, r3.x, r2.x
    r5.x = value_62.x;
    uint4 value_63 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.yyyy), asfloat(r2.zzzz))); // mad r5.y, cb0[2].y, r3.y, r2.z
    r5.y = value_63.y;
    uint4 value_64 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_64.xyzw;
    uint4 value_65 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.x, r5.y, l(1.000000)
    r3.x = value_65.x;
    uint4 value_66 = (r3.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.x, r3.x, l(0x3f800000)
    r3.x = value_66.x;
    uint4 value_67 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_67.xyz;
    uint4 value_68 = asuint(mad(asfloat(r3.xxxx), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r5.xyz, r3.xxxx, r5.xyzx, r6.xyzx
    r5.xyz = value_68.xyz;
    uint4 value_69 = asuint(asfloat(r1.wwww) * asfloat(r3.wwww)); // mul r1.w, r1.w, r3.w
    r1.w = value_69.w;
    uint4 value_70 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.x, r1.w
    r3.x = value_70.x;
    uint4 value_71 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_71.w;
    uint4 value_72 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r2.zzzz))); // mad r6.y, cb0[2].y, r1.w, r2.z
    r6.y = value_72.y;
    uint4 value_73 = (asuint(-asint(r3.xxxx)) * r3.zzzz + r2.wwww); // imad r1.w, -r3.x, r3.z, r2.w
    r1.w = value_73.w;
    uint4 value_74 = asuint(float4(r1.wwww)); // utof r1.w, r1.w
    r1.w = value_74.w;
    uint4 value_75 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.wwww), asfloat(r2.xxxx))); // mad r6.x, cb0[2].x, r1.w, r2.x
    r6.x = value_75.x;
    uint4 value_76 = asuint(t0.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r6.xyxx, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_76.xyzw;
    uint4 value_77 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.w, r6.y, l(1.000000)
    r1.w = value_77.w;
    uint4 value_78 = (r1.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.w, r1.w, l(0x3f800000)
    r1.w = value_78.w;
    uint4 value_79 = asuint(asfloat(asuint(-asfloat(r7.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r2.xzw, -r7.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r2.xzw = value_79.xzw;
    uint4 value_80 = asuint(mad(asfloat(r1.wwww), asfloat(r2.xxzw), asfloat(r7.xxyz))); // mad r2.xzw, r1.wwww, r2.xxzw, r7.xxyz
    r2.xzw = value_80.xzw;
    uint4 value_81 = asuint(asfloat(asuint(-asfloat(r2.xzwx))) + asfloat(r5.xyzx)); // add r5.xyz, -r2.xzwx, r5.xyzx
    r5.xyz = value_81.xyz;
    uint4 value_82 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xxyz), asfloat(r2.xxzw))); // mad r2.xzw, r0.wwww, r5.xxyz, r2.xxzw
    r2.xzw = value_82.xzw;
    uint4 value_83 = asuint(asfloat(r2.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r2.xzw, r2.xxzw, -cb0[9].xxyz
    r2.xzw = value_83.xzw;
    uint4 value_84 = asuint(mad(asfloat(r2.yyyy), asfloat(r2.xzwx), asfloat(cb0[9].xyzx))); // mad r2.xyz, r2.yyyy, r2.xzwx, cb0[9].xyzx
    r2.xyz = value_84.xyz;
    uint4 value_85 = asuint(asfloat(r0.xyzx) + asfloat(r1.xyzx)); // add r5.xyz, r0.xyzx, r1.xyzx
    r5.xyz = value_85.xyz;
    uint4 value_86 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.w, r1.xyzx, -cb0[4].xyzx
    r0.w = value_86.w;
    uint4 value_87 = asuint(asfloat(r5.yyyy) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r1.xy, r5.yyyy, l(0.700000, -0.300000, 0.000000, 0.000000)
    r1.xy = value_87.xy;
    uint4 value_88 = asuint(asfloat(r5.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r1.zw, r5.xxxz, -cb0[3].xxxy
    r1.zw = value_88.zw;
    uint4 value_89 = asuint(asfloat(r1.zzzw) * asfloat(cb0[2].zzzz)); // mul r1.zw, r1.zzzw, cb0[2].zzzz
    r1.zw = value_89.zw;
    uint4 value_90 = asuint(max(asfloat(r1.zzzw), asfloat(cb0[7].xxxy))); // max r1.zw, r1.zzzw, cb0[7].xxxy
    r1.zw = value_90.zw;
    uint4 value_91 = asuint(min(asfloat(r4.xxxy), asfloat(r1.zzzw))); // min r1.zw, r4.xxxy, r1.zzzw
    r1.zw = value_91.zw;
    uint4 value_92 = asuint(max(asfloat(r1.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.y, r1.y, l(0.000000)
    r1.y = value_92.y;
    uint4 value_93 = asuint(saturate(asfloat(r1.xxxx))); // mov_sat r1.x, r1.x
    r1.x = value_93.x;
    uint4 value_94 = asuint(floor(asfloat(r1.yyyy))); // round_ni r2.w, r1.y
    r2.w = value_94.w;
    uint4 value_95 = asuint(frac(asfloat(r1.yyyy))); // frc r1.y, r1.y
    r1.y = value_95.y;
    uint4 value_96 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.x, r2.w
    r3.x = value_96.x;
    uint4 value_97 = asuint(asfloat(r3.wwww) * asfloat(r2.wwww)); // mul r2.w, r3.w, r2.w
    r2.w = value_97.w;
    uint4 value_98 = (r3.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.y, r3.x, l(1)
    r3.y = value_98.y;
    uint4 value_99 = asuint(float4(asint(r3.yyyy))); // itof r4.x, r3.y
    r4.x = value_99.x;
    uint4 value_100 = asuint(asfloat(r3.wwww) * asfloat(r4.xxxx)); // mul r3.w, r3.w, r4.x
    r3.w = value_100.w;
    uint4 value_101 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.x, r3.w
    r4.x = value_101.x;
    uint4 value_102 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_102.w;
    uint4 value_103 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r1.wwww))); // mad r5.y, cb0[2].y, r3.w, r1.w
    r5.y = value_103.y;
    uint4 value_104 = (asuint(-asint(r4.xxxx)) * r3.zzzz + r3.yyyy); // imad r3.y, -r4.x, r3.z, r3.y
    r3.y = value_104.y;
    uint4 value_105 = asuint(float4(r3.yyyy)); // utof r3.y, r3.y
    r3.y = value_105.y;
    uint4 value_106 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.yyyy), asfloat(r1.zzzz))); // mad r5.x, cb0[2].x, r3.y, r1.z
    r5.x = value_106.x;
    uint4 value_107 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_107.xyzw;
    uint4 value_108 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.y, r5.y, l(1.000000)
    r3.y = value_108.y;
    uint4 value_109 = (r3.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.y, r3.y, l(0x3f800000)
    r3.y = value_109.y;
    uint4 value_110 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r4.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_110.xyz;
    uint4 value_111 = asuint(mad(asfloat(r3.yyyy), asfloat(r5.xyzx), asfloat(r4.xyzx))); // mad r4.xyz, r3.yyyy, r5.xyzx, r4.xyzx
    r4.xyz = value_111.xyz;
    uint4 value_112 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.y, r2.w
    r3.y = value_112.y;
    uint4 value_113 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_113.w;
    uint4 value_114 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r1.wwww))); // mad r5.y, cb0[2].y, r2.w, r1.w
    r5.y = value_114.y;
    uint4 value_115 = (asuint(-asint(r3.yyyy)) * r3.zzzz + r3.xxxx); // imad r1.w, -r3.y, r3.z, r3.x
    r1.w = value_115.w;
    uint4 value_116 = asuint(float4(r1.wwww)); // utof r1.w, r1.w
    r1.w = value_116.w;
    uint4 value_117 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.wwww), asfloat(r1.zzzz))); // mad r5.x, cb0[2].x, r1.w, r1.z
    r5.x = value_117.x;
    uint4 value_118 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r3.xyzw = value_118.xyzw;
    uint4 value_119 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.z, r5.y, l(1.000000)
    r1.z = value_119.z;
    uint4 value_120 = (r1.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.z, r1.z, l(0x3f800000)
    r1.z = value_120.z;
    uint4 value_121 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r3.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_121.xyz;
    uint4 value_122 = asuint(mad(asfloat(r1.zzzz), asfloat(r5.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r1.zzzz, r5.xyzx, r3.xyzx
    r3.xyz = value_122.xyz;
    uint4 value_123 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(r4.xyzx)); // add r4.xyz, -r3.xyzx, r4.xyzx
    r4.xyz = value_123.xyz;
    uint4 value_124 = asuint(mad(asfloat(r1.yyyy), asfloat(r4.xxyz), asfloat(r3.xxyz))); // mad r1.yzw, r1.yyyy, r4.xxyz, r3.xxyz
    r1.yzw = value_124.yzw;
    uint4 value_125 = asuint(asfloat(r1.yyzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r1.yzw, r1.yyzw, -cb0[9].xxyz
    r1.yzw = value_125.yzw;
    uint4 value_126 = asuint(mad(asfloat(r1.xxxx), asfloat(r1.yzwy), asfloat(cb0[9].xyzx))); // mad r1.xyz, r1.xxxx, r1.yzwy, cb0[9].xyzx
    r1.xyz = value_126.xyz;
    uint4 value_127 = asuint(asfloat(r1.xyzx) * asfloat(r2.xyzx)); // mul r3.xyz, r1.xyzx, r2.xyzx
    r3.xyz = value_127.xyz;
    uint4 value_128 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_128.w;
    uint4 value_129 = asuint(mad(asfloat(r2.xyzx), asfloat(r1.xyzx), asfloat(asuint(-asfloat(r1.wwww))))); // mad r1.xyz, r2.xyzx, r1.xyzx, -r1.wwww
    r1.xyz = value_129.xyz;
    uint4 value_130 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r2.x, cb0[5].w, cb0[6].w
    r2.x = value_130.x;
    uint4 value_131 = asuint(saturate(asfloat(asuint(asfloat(r2.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r2.x, r2.x, l(0.500000)
    r2.x = value_131.x;
    uint4 value_132 = asuint(asfloat(r2.xxxx) * asfloat(cb0[29].xxxx)); // mul r2.x, r2.x, cb0[29].x
    r2.x = value_132.x;
    uint4 value_133 = asuint(mad(asfloat(r2.xxxx), asfloat(r1.xyzx), asfloat(r1.wwww))); // mad r1.xyz, r2.xxxx, r1.xyzx, r1.wwww
    r1.xyz = value_133.xyz;
    uint4 value_134 = asuint(asfloat(r0.yyyy) * asfloat(cb0[31].xyzx)); // mul r2.xyz, r0.yyyy, cb0[31].xyzx
    r2.xyz = value_134.xyz;
    uint4 value_135 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r0.xxxx), asfloat(r2.xyzx))); // mad r2.xyz, cb0[30].xyzx, r0.xxxx, r2.xyzx
    r2.xyz = value_135.xyz;
    uint4 value_136 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r0.zzzz), asfloat(r2.xyzx))); // mad r0.xyz, cb0[32].xyzx, r0.zzzz, r2.xyzx
    r0.xyz = value_136.xyz;
    uint4 value_137 = asuint(asfloat(r0.xyzx) + asfloat(cb0[33].xyzx)); // add r0.xyz, r0.xyzx, cb0[33].xyzx
    r0.xyz = value_137.xyz;
    uint4 value_138 = asuint(asfloat(r0.xyxx) * asfloat(cb0[39].zwzz)); // mul r0.xy, r0.xyxx, cb0[39].zwzz
    r0.xy = value_138.xy;
    uint4 value_139 = asuint(frac(asfloat(r0.xyxx))); // frc r2.xy, r0.xyxx
    r2.xy = value_139.xy;
    uint4 value_140 = asuint(asfloat(r0.wwww) * asfloat(cb0[38].yyyy)); // mul r1.w, r0.w, cb0[38].y
    r1.w = value_140.w;
    uint4 value_141 = asuint(saturate(asfloat(r0.wwww))); // mov_sat r0.w, r0.w
    r0.w = value_141.w;
    uint4 value_142 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_142.w;
    uint4 value_143 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r0.zzzz))); // mad r0.z, -r1.w, l(0.050000), r0.z
    r0.z = value_143.z;
    uint4 value_144 = asuint(asfloat(r0.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r0.z, r0.z, l(-0.003922)
    r0.z = value_144.z;
    uint4 value_145 = asuint(mad(asfloat(asuint(-asfloat(cb0[38].yyyy))), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu)), asfloat(r0.zzzz))); // mad r0.z, -cb0[38].y, l(0.100000), r0.z
    r0.z = value_145.z;
    uint4 value_146 = asuint(asfloat(r0.xxxy) * asfloat(cb0[39].xxxy)); // mul r3.zw, r0.xxxy, cb0[39].xxxy
    r3.zw = value_146.zw;
    uint4 value_147 = asuint(mad(asfloat(r0.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r3.xy, r0.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r3.xy = value_147.xy;
    uint4 value_148 = asuint(t1.SampleLevel(s3, asfloat(r3.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.zyzz, t1.xyzw, s3, l(0.000000)
    r4.xyzw = value_148.xyzw;
    uint4 value_149 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r0.zzzz, -r4.xyzx
    r4.xyz = value_149.xyz;
    uint4 value_150 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r0.x, cb0[38].x, l(20.000000)
    r0.x = value_150.x;
    uint4 value_151 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r0.xxxx, r4.xyzx
    r4.xyz = value_151.xyz;
    uint4 value_152 = asuint(asfloat(asuint(-asfloat(r2.xxxy))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r2.zw, -r2.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    r2.zw = value_152.zw;
    uint4 value_153 = asuint(asfloat(r2.zzzz) * asfloat(r4.xyzx)); // mul r4.xyz, r2.zzzz, r4.xyzx
    r4.xyz = value_153.xyz;
    uint4 value_154 = asuint(asfloat(r2.yyyy) * asfloat(r4.xyzx)); // mul r4.xyz, r2.yyyy, r4.xyzx
    r4.xyz = value_154.xyz;
    uint4 value_155 = asuint(t1.SampleLevel(s3, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t1.xyzw, s3, l(0.000000)
    r5.xyzw = value_155.xyzw;
    uint4 value_156 = asuint(t1.SampleLevel(s3, asfloat(r3.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r3.xwxx, t1.xyzw, s3, l(0.000000)
    r6.xyzw = value_156.xyzw;
    uint4 value_157 = asuint(t1.SampleLevel(s3, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.xyxx, t1.xyzw, s3, l(0.000000)
    r3.xyzw = value_157.xyzw;
    uint4 value_158 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r3.xyz, r0.zzzz, -r3.xyzx
    r3.xyz = value_158.xyz;
    uint4 value_159 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) * asfloat(r3.xyzx))))); // mul_sat r3.xyz, r0.xxxx, r3.xyzx
    r3.xyz = value_159.xyz;
    uint4 value_160 = asuint(asfloat(r2.xxxx) * asfloat(r3.xyzx)); // mul r3.xyz, r2.xxxx, r3.xyzx
    r3.xyz = value_160.xyz;
    uint4 value_161 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r0.zzzz, -r6.xyzx
    r6.xyz = value_161.xyz;
    uint4 value_162 = asuint(asfloat(r0.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r0.zzzz, -r5.xyzx
    r5.xyz = value_162.xyz;
    uint4 value_163 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r0.xxxx, r5.xyzx
    r5.xyz = value_163.xyz;
    uint4 value_164 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) * asfloat(r6.xyzx))))); // mul_sat r0.xyz, r0.xxxx, r6.xyzx
    r0.xyz = value_164.xyz;
    uint4 value_165 = asuint(asfloat(r2.xxxx) * asfloat(r0.xyzx)); // mul r0.xyz, r2.xxxx, r0.xyzx
    r0.xyz = value_165.xyz;
    uint4 value_166 = asuint(asfloat(r2.zzzz) * asfloat(r5.xyzx)); // mul r5.xyz, r2.zzzz, r5.xyzx
    r5.xyz = value_166.xyz;
    uint4 value_167 = asuint(mad(asfloat(r5.xyzx), asfloat(r2.wwww), asfloat(r4.xyzx))); // mad r4.xyz, r5.xyzx, r2.wwww, r4.xyzx
    r4.xyz = value_167.xyz;
    uint4 value_168 = asuint(mad(asfloat(r0.xyzx), asfloat(r2.wwww), asfloat(r4.xyzx))); // mad r0.xyz, r0.xyzx, r2.wwww, r4.xyzx
    r0.xyz = value_168.xyz;
    uint4 value_169 = asuint(mad(asfloat(r3.xyzx), asfloat(r2.yyyy), asfloat(r0.xyzx))); // mad r0.xyz, r3.xyzx, r2.yyyy, r0.xyzx
    r0.xyz = value_169.xyz;
    uint4 value_170 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r0.x, r0.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r0.x = value_170.x;
    uint4 value_171 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_171.x;
    uint4 value_172 = asuint(asfloat(r0.wwww) * asfloat(r0.wwww)); // mul r0.y, r0.w, r0.w
    r0.y = value_172.y;
    uint4 value_173 = asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(r0.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.y, -r0.w, r0.y, l(1.000000)
    r0.y = value_173.y;
    uint4 value_174 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.x, r0.y, r0.x
    r0.x = value_174.x;
    uint4 value_175 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].wwww)); // mul r0.x, r0.x, cb0[5].w
    r0.x = value_175.x;
    uint4 value_176 = asuint(asfloat(cb0[6].xxyz) * asfloat(uint4(0x0u, 0x3fe66666u, 0x3fe66666u, 0x3fe66666u))); // mul r0.yzw, cb0[6].xxyz, l(0.000000, 1.800000, 1.800000, 1.800000)
    r0.yzw = value_176.yzw;
    uint4 value_177 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r0.yzwy))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r0.yzwy
    r2.xyz = value_177.xyz;
    uint4 value_178 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xxyz), asfloat(r0.yyzw))); // mad r0.yzw, r0.xxxx, r2.xxyz, r0.yyzw
    r0.yzw = value_178.yzw;
    uint4 value_179 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.xxxx, cb0[5].xyzx
    r2.xyz = value_179.xyz;
    uint4 value_180 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_180.xyz;
    uint4 value_181 = asuint(mad(asfloat(r1.xxyz), asfloat(r0.yyzw), asfloat(r2.xxyz))); // mad r0.yzw, r1.xxyz, r0.yyzw, r2.xxyz
    r0.yzw = value_181.yzw;
    uint4 value_182 = asuint(asfloat(r0.yzwy) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add o3.xyz, r0.yzwy, l(0.100000, 0.100000, 0.100000, 0.000000)
    out_o3.xyz = value_182.xyz;
    uint4 value_183 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.y, cb0[5].w, -cb0[6].w
    r0.y = value_183.y;
    uint4 value_184 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yyyy), asfloat(cb0[6].wwww))); // mad o3.w, r0.x, r0.y, cb0[6].w
    out_o3.w = value_184.w;
    uint4 value_185 = asuint(floor(asfloat(asuint(abs(asfloat(v2.xxxx)))))); // round_ni r0.x, |v2.x|
    r0.x = value_185.x;
    uint4 value_186 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.x, r0.x, l(0.500000)
    r0.x = value_186.x;
    uint4 value_187 = asuint(asfloat(r0.xxxx) * asfloat(cb0[15].xxxx)); // mul r0.x, r0.x, cb0[15].x
    r0.x = value_187.x;
    uint4 value_188 = uint4(0x3e800000u, 0x3e800000u, 0x3e800000u, 0x3e800000u); // mov r0.y, l(0.250000)
    r0.y = value_188.y;
    uint4 value_189 = asuint(t3.SampleLevel(s2, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t3.xyzw, s2, l(0.000000)
    r0.xyzw = value_189.xyzw;
    uint4 value_190 = asuint(saturate(asfloat(r0.xyzx))); // mov_sat o4.xyz, r0.xyzx
    out_o4.xyz = value_190.xyz;
    uint4 value_191 = r0.wwww; // mov o4.w, r0.w
    out_o4.w = value_191.w;
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
