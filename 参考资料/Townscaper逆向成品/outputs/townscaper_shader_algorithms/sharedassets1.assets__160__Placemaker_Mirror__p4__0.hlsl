// Register-explicit recovered HLSL. Not original source.
// Placemaker/Mirror vs_4_0 variant []
// Source SHA256 acbe7b7019ad2812910af7e4eb85aac9eab1db39a1087cbfc2d0cddff0434475
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
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
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
// temporary registers: 8
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float3 v2_0: NORMAL0;
    float4 v3_0: TANGENT0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD2;
    float2 o1_0: TEXCOORD3;
    float2 o1_1: TEXCOORD4;
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
    v1.xy = asuint(input.v1_0);
    v2.xyz = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(asfloat(v1.yyyy) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.x, v1.y, l(0.500000)
    r0.x = value_1.x;
    uint4 value_2 = asuint(frac(asfloat(r0.xxxx))); // frc r0.x, r0.x
    r0.x = value_2.x;
    uint4 value_3 = asuint(asfloat(r0.xxxx) + asfloat(r0.xxxx)); // add o0.y, r0.x, r0.x
    out_o0.y = value_3.y;
    uint4 value_4 = asuint(asfloat(cb1[0].yyyy) * asfloat(uint4(0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu))); // mul r0.x, cb1[0].y, l(6.283185)
    r0.x = value_4.x;
    uint4 value_5 = ((asfloat(r0.xxxx) >= asfloat(asuint(-asfloat(r0.xxxx)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, r0.x, -r0.x
    r0.x = value_5.x;
    uint4 value_6 = ((r0.xxxx != 0u) ? uint4(0x40c90fdbu, 0x3e22f983u, 0x0u, 0x0u) : uint4(0xc0c90fdbu, 0xbe22f983u, 0x0u, 0x0u)); // movc r0.xy, r0.xxxx, l(6.283185,0.159155,0,0), l(-6.283185,-0.159155,0,0)
    r0.xy = value_6.xy;
    uint4 value_7 = asuint(asfloat(r0.yyyy) * asfloat(cb1[0].yyyy)); // mul r0.y, r0.y, cb1[0].y
    r0.y = value_7.y;
    uint4 value_8 = asuint(frac(asfloat(r0.yyyy))); // frc r0.y, r0.y
    r0.y = value_8.y;
    uint4 value_9 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzw)); // mul r1.xyzw, v0.yyyy, cb2[1].xyzw
    r1.xyzw = value_9.xyzw;
    uint4 value_10 = asuint(mad(asfloat(cb2[0].xyzw), asfloat(v0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[0].xyzw, v0.xxxx, r1.xyzw
    r1.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(mad(asfloat(cb2[2].xyzw), asfloat(v0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[2].xyzw, v0.zzzz, r1.xyzw
    r1.xyzw = value_11.xyzw;
    uint4 value_12 = asuint(mad(asfloat(cb2[3].xyzw), asfloat(v0.wwww), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[3].xyzw, v0.wwww, r1.xyzw
    r1.xyzw = value_12.xyzw;
    uint4 value_13 = asuint(saturate(asfloat(v3.wwww))); // mov_sat r0.z, v3.w
    r0.z = value_13.z;
    uint4 value_14 = asuint(mad(asfloat(r1.xyzx), asfloat(r0.zzzz), asfloat(asuint(-asfloat(cb0[22].xyzx))))); // mad r2.xyz, r1.xyzx, r0.zzzz, -cb0[22].xyzx
    r2.xyz = value_14.xyz;
    uint4 value_15 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r2.xyzx).xyz)).xxxx; // dp3 r0.w, r2.xyzx, r2.xyzx
    r0.w = value_15.w;
    uint4 value_16 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_16.w;
    uint4 value_17 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_17.w;
    uint4 value_18 = asuint(asfloat(r0.wwww) * asfloat(r2.xyzx)); // mul r2.xyz, r0.wwww, r2.xyzx
    r2.xyz = value_18.xyz;
    uint4 value_19 = asuint(asfloat(r2.xyzx) * asfloat(cb0[22].wwww)); // mul r3.xyz, r2.xyzx, cb0[22].wwww
    r3.xyz = value_19.xyz;
    uint4 value_20 = asuint(mad(asfloat(r1.yyyy), asfloat(r0.zzzz), asfloat(r3.yyyy))); // mad r0.w, r1.y, r0.z, r3.y
    r0.w = value_20.w;
    uint4 value_21 = asuint(min(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r0.w, r0.w, l(0.000000)
    r0.w = value_21.w;
    uint4 value_22 = asuint(mad(asfloat(r2.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r0.wwww))))); // mad r3.w, r2.y, cb0[22].w, -r0.w
    r3.w = value_22.w;
    uint4 value_23 = asuint(mad(asfloat(r1.xyzx), asfloat(r0.zzzz), asfloat(r3.xwzx))); // mad r2.xyz, r1.xyzx, r0.zzzz, r3.xwzx
    r2.xyz = value_23.xyz;
    uint4 value_24 = asuint(-asfloat(r2.yyyy)); // mov r2.w, -r2.y
    r2.w = value_24.w;
    uint4 value_25 = asuint(asfloat(r2.xzwx) + asfloat(asuint(-asfloat(cb1[4].xzyx)))); // add r3.xyz, r2.xzwx, -cb1[4].xzyx
    r3.xyz = value_25.xyz;
    uint4 value_26 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(r3.xyzx).xyz)).xxxx; // dp3 r0.w, r3.xyzx, r3.xyzx
    r0.w = value_26.w;
    uint4 value_27 = asuint(rsqrt(asfloat(r0.wwww))); // rsq r0.w, r0.w
    r0.w = value_27.w;
    uint4 value_28 = asuint(mad(asfloat(asuint(-asfloat(r3.xyzx))), asfloat(r0.wwww), asfloat(r2.xzwx))); // mad r3.xyz, -r3.xyzx, r0.wwww, r2.xzwx
    r3.xyz = value_28.xyz;
    uint4 value_29 = asuint(asfloat(r3.xyzx) * asfloat(uint4(0x40c00000u, 0x40c00000u, 0x40400000u, 0x0u))); // mul r3.xyz, r3.xyzx, l(6.000000, 6.000000, 3.000000, 0.000000)
    r3.xyz = value_29.xyz;
    uint4 value_30 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yyyy), asfloat(r3.xyxz))); // mad r0.xyw, r0.xxxx, r0.yyyy, r3.xyxz
    r0.xyw = value_30.xyw;
    uint4 value_31c = asuint(cos(asfloat(r0.wwww))); // sincos null, r2.w, r0.w
    r2.w = value_31c.w;
    uint4 value_32s = asuint(sin(asfloat(r0.xyxw))); // sincos r0.xyw, null, r0.xyxw
    r0.xyw = value_32s.xyw;
    uint4 value_33 = asuint(asfloat(r2.wwww) + asfloat(r0.yyyy)); // add r3.z, r2.w, r0.y
    r3.z = value_33.z;
    uint4 value_34 = asuint(asfloat(r0.wwww) + asfloat(r0.xxxx)); // add r3.x, r0.w, r0.x
    r3.x = value_34.x;
    uint4 value_35 = asuint(asfloat(asuint(abs(asfloat(r2.yyyy)))) * asfloat(r3.xzxx)); // mul r0.xy, |r2.yyyy|, r3.xzxx
    r0.xy = value_35.xy;
    uint4 value_36 = asuint(mad(asfloat(r0.xxxy), asfloat(uint4(0x0u, 0x3dcccccdu, 0x0u, 0x3dcccccdu)), asfloat(r2.xxxz))); // mad r3.yw, r0.xxxy, l(0.000000, 0.100000, 0.000000, 0.100000), r2.xxxz
    r3.yw = value_36.yw;
    uint4 value_37 = asuint(-asfloat(r2.yyyy)); // mov r3.xz, -r2.yyyy
    r3.xz = value_37.xz;
    uint4 value_38 = asuint(asfloat(r3.xxxx) * asfloat(cb3[10].xyxx)); // mul r0.xy, r3.xxxx, cb3[10].xyxx
    r0.xy = value_38.xy;
    uint4 value_39 = asuint(mad(asfloat(cb3[9].xyxx), asfloat(r3.yyyy), asfloat(r0.xyxx))); // mad r0.xy, cb3[9].xyxx, r3.yyyy, r0.xyxx
    r0.xy = value_39.xy;
    uint4 value_40 = asuint(mad(asfloat(cb3[11].xyxx), asfloat(r3.wwww), asfloat(r0.xyxx))); // mad r0.xy, cb3[11].xyxx, r3.wwww, r0.xyxx
    r0.xy = value_40.xy;
    uint4 value_41 = asuint(asfloat(r0.zzzz) * asfloat(r1.xyzw)); // mul r4.xyzw, r0.zzzz, r1.xyzw
    r4.xyzw = value_41.xyzw;
    uint4 value_42 = asuint(mad(asfloat(cb3[12].xxxy), asfloat(r4.wwww), asfloat(r0.xxxy))); // mad o0.zw, cb3[12].xxxy, r4.wwww, r0.xxxy
    out_o0.zw = value_42.zw;
    uint4 value_43 = v1.xxxx; // mov o0.x, v1.x
    out_o0.x = value_43.x;
    uint4 value_44 = asuint(saturate(asfloat(asuint(asfloat(r2.yyyy) * asfloat(uint4(0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu)))))); // mul_sat r0.x, r2.y, l(0.200000)
    r0.x = value_44.x;
    uint4 value_45 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_45.x;
    uint4 value_46 = asuint(asfloat(r0.xxxx) * asfloat(r0.xxxx)); // mul r0.x, r0.x, r0.x
    r0.x = value_46.x;
    uint4 value_47 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r0.xxxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.x, -r0.x, r0.x, l(1.000000)
    r0.x = value_47.x;
    uint4 value_48 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -r0.x, l(1.000000)
    r0.y = value_48.y;
    uint4 value_49 = asuint(mad(asfloat(r0.yyyy), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)), asfloat(r0.xxxx))); // mad o1.z, r0.y, l(0.500000), r0.x
    out_o1.z = value_49.z;
    uint4 value_50 = asuint(asfloat(r3.yzyw) + asfloat(asuint(-asfloat(cb1[4].xyxz)))); // add r0.xyw, r3.yzyw, -cb1[4].xyxz
    r0.xyw = value_50.xyw;
    uint4 value_51 = asuint(asfloat(r3.xxxx) * asfloat(cb3[18].xyzw)); // mul r5.xyzw, r3.xxxx, cb3[18].xyzw
    r5.xyzw = value_51.xyzw;
    uint4 value_52 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r3.yyyy), asfloat(r5.xyzw))); // mad r5.xyzw, cb3[17].xyzw, r3.yyyy, r5.xyzw
    r5.xyzw = value_52.xyzw;
    uint4 value_53 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r3.wwww), asfloat(r5.xyzw))); // mad r3.xyzw, cb3[19].xyzw, r3.wwww, r5.xyzw
    r3.xyzw = value_53.xyzw;
    uint4 value_54 = asuint(asfloat(r3.xyzw) + asfloat(cb3[20].xyzw)); // add o2.xyzw, r3.xyzw, cb3[20].xyzw
    out_o2.xyzw = value_54.xyzw;
    uint4 value_55 = asuint(dot(asfloat(r0.xywx).xyz, asfloat(r0.xywx).xyz)).xxxx; // dp3 r0.x, r0.xywx, r0.xywx
    r0.x = value_55.x;
    uint4 value_56 = asuint(rsqrt(asfloat(r0.xxxx))); // rsq r0.x, r0.x
    r0.x = value_56.x;
    uint4 value_57 = asuint(asfloat(r0.xxxx) * asfloat(r0.yyyy)); // mul r0.x, r0.x, r0.y
    r0.x = value_57.x;
    uint4 value_58 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul o1.w, r0.x, l(0.500000)
    out_o1.w = value_58.w;
    uint4 value_59 = ((asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)) >= asfloat(v1.xxxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, l(0.000000), v1.x
    r0.x = value_59.x;
    uint4 value_60 = ((r0.xxxx != 0u) ? uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u) : uint4(0x80000000u, 0x80000000u, 0x80000000u, 0x80000000u)); // movc r0.x, r0.x, l(-1.000000), l(-0.000000)
    r0.x = value_60.x;
    uint4 value_61 = asuint(asfloat(r0.xxxx) + asfloat(r2.yyyy)); // add o1.y, r0.x, r2.y
    out_o1.y = value_61.y;
    uint4 value_62 = uint4(0x0u, 0x0u, 0x0u, 0x0u); // mov o1.x, l(0)
    out_o1.x = value_62.x;
    uint4 value_63 = asuint(asfloat(v3.yyyy) * asfloat(cb2[1].xyxz)); // mul r0.xyw, v3.yyyy, cb2[1].xyxz
    r0.xyw = value_63.xyw;
    uint4 value_64 = asuint(mad(asfloat(cb2[0].xyxz), asfloat(v3.xxxx), asfloat(r0.xyxw))); // mad r0.xyw, cb2[0].xyxz, v3.xxxx, r0.xyxw
    r0.xyw = value_64.xyw;
    uint4 value_65 = asuint(mad(asfloat(cb2[2].xyxz), asfloat(v3.zzzz), asfloat(r0.xyxw))); // mad r0.xyw, cb2[2].xyxz, v3.zzzz, r0.xyxw
    r0.xyw = value_65.xyw;
    uint4 value_66 = asuint(mad(asfloat(r1.xyzx), asfloat(r0.zzzz), asfloat(r0.xywx))); // mad r1.xyz, r1.xyzx, r0.zzzz, r0.xywx
    r1.xyz = value_66.xyz;
    uint4 value_67 = asuint(asfloat(r1.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r1.xz, r1.xxzx, -cb0[3].xxyx
    r1.xz = value_67.xz;
    uint4 value_68 = asuint(asfloat(r1.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r1.yw, r1.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r1.yw = value_68.yw;
    uint4 value_69 = asuint(asfloat(r1.xxzx) * asfloat(cb0[2].zzzz)); // mul r1.xz, r1.xxzx, cb0[2].zzzz
    r1.xz = value_69.xz;
    uint4 value_70 = asuint(max(asfloat(r1.xxzx), asfloat(cb0[7].xxyx))); // max r1.xz, r1.xxzx, cb0[7].xxyx
    r1.xz = value_70.xz;
    uint4 value_71 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r2.xy, cb0[2].xyxx, -cb0[7].xyxx
    r2.xy = value_71.xy;
    uint4 value_72 = asuint(min(asfloat(r1.xxzx), asfloat(r2.xxyx))); // min r1.xz, r1.xxzx, r2.xxyx
    r1.xz = value_72.xz;
    uint4 value_73 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.z, r1.w, l(0.000000)
    r0.z = value_73.z;
    uint4 value_74 = asuint(saturate(asfloat(r1.yyyy))); // mov_sat r1.y, r1.y
    r1.y = value_74.y;
    uint4 value_75 = asuint(floor(asfloat(r0.zzzz))); // round_ni r1.w, r0.z
    r1.w = value_75.w;
    uint4 value_76 = asuint(frac(asfloat(r0.zzzz))); // frc r0.z, r0.z
    r0.z = value_76.z;
    uint4 value_77 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.z, r1.w
    r2.z = value_77.z;
    uint4 value_78 = (r2.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.w, r2.z, l(1)
    r2.w = value_78.w;
    uint4 value_79 = asuint(float4(asint(r2.wwww))); // itof r3.x, r2.w
    r3.x = value_79.x;
    uint4 value_80 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r3.y, cb0[2].w
    r3.y = value_80.y;
    uint4 value_81 = uint4(asfloat(r3.yyyy)); // ftou r3.y, r3.y
    r3.y = value_81.y;
    uint4 value_82 = asuint(float4(r3.yyyy)); // utof r3.z, r3.y
    r3.z = value_82.z;
    uint4 value_83 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r3.zzzz)); // div r3.z, l(1.000000, 1.000000, 1.000000, 1.000000), r3.z
    r3.z = value_83.z;
    uint4 value_84 = asuint(asfloat(r3.zzzz) * asfloat(r3.xxxx)); // mul r3.x, r3.z, r3.x
    r3.x = value_84.x;
    uint4 value_85 = asuint(int4(asfloat(r3.xxxx))); // ftoi r3.w, r3.x
    r3.w = value_85.w;
    uint4 value_86 = asuint(trunc(asfloat(r3.xxxx))); // round_z r3.x, r3.x
    r3.x = value_86.x;
    uint4 value_87 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.xxxx), asfloat(r1.zzzz))); // mad r5.y, cb0[2].y, r3.x, r1.z
    r5.y = value_87.y;
    uint4 value_88 = (asuint(-asint(r3.wwww)) * r3.yyyy + r2.wwww); // imad r2.w, -r3.w, r3.y, r2.w
    r2.w = value_88.w;
    uint4 value_89 = asuint(float4(r2.wwww)); // utof r2.w, r2.w
    r2.w = value_89.w;
    uint4 value_90 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.wwww), asfloat(r1.xxxx))); // mad r5.x, cb0[2].x, r2.w, r1.x
    r5.x = value_90.x;
    uint4 value_91 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_91.xyzw;
    uint4 value_92 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.w, r5.y, l(1.000000)
    r2.w = value_92.w;
    uint4 value_93 = (r2.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.w, r2.w, l(0x3f800000)
    r2.w = value_93.w;
    uint4 value_94 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_94.xyz;
    uint4 value_95 = asuint(mad(asfloat(r2.wwww), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r5.xyz, r2.wwww, r5.xyzx, r6.xyzx
    r5.xyz = value_95.xyz;
    uint4 value_96 = asuint(asfloat(r1.wwww) * asfloat(r3.zzzz)); // mul r1.w, r1.w, r3.z
    r1.w = value_96.w;
    uint4 value_97 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.w, r1.w
    r2.w = value_97.w;
    uint4 value_98 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_98.w;
    uint4 value_99 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r1.zzzz))); // mad r6.y, cb0[2].y, r1.w, r1.z
    r6.y = value_99.y;
    uint4 value_100 = (asuint(-asint(r2.wwww)) * r3.yyyy + r2.zzzz); // imad r1.z, -r2.w, r3.y, r2.z
    r1.z = value_100.z;
    uint4 value_101 = asuint(float4(r1.zzzz)); // utof r1.z, r1.z
    r1.z = value_101.z;
    uint4 value_102 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.zzzz), asfloat(r1.xxxx))); // mad r6.x, cb0[2].x, r1.z, r1.x
    r6.x = value_102.x;
    uint4 value_103 = asuint(t0.SampleLevel(s0, asfloat(r6.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r6.xyxx, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_103.xyzw;
    uint4 value_104 = ((asfloat(r6.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.x, r6.y, l(1.000000)
    r1.x = value_104.x;
    uint4 value_105 = (r1.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.x, r1.x, l(0x3f800000)
    r1.x = value_105.x;
    uint4 value_106 = asuint(asfloat(asuint(-asfloat(r7.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r6.xyz, -r7.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r6.xyz = value_106.xyz;
    uint4 value_107 = asuint(mad(asfloat(r1.xxxx), asfloat(r6.xxyz), asfloat(r7.xxyz))); // mad r1.xzw, r1.xxxx, r6.xxyz, r7.xxyz
    r1.xzw = value_107.xzw;
    uint4 value_108 = asuint(asfloat(asuint(-asfloat(r1.xzwx))) + asfloat(r5.xyzx)); // add r5.xyz, -r1.xzwx, r5.xyzx
    r5.xyz = value_108.xyz;
    uint4 value_109 = asuint(mad(asfloat(r0.zzzz), asfloat(r5.xxyz), asfloat(r1.xxzw))); // mad r1.xzw, r0.zzzz, r5.xxyz, r1.xxzw
    r1.xzw = value_109.xzw;
    uint4 value_110 = asuint(asfloat(r1.xxzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r1.xzw, r1.xxzw, -cb0[9].xxyz
    r1.xzw = value_110.xzw;
    uint4 value_111 = asuint(mad(asfloat(r1.yyyy), asfloat(r1.xzwx), asfloat(cb0[9].xyzx))); // mad r1.xyz, r1.yyyy, r1.xzwx, cb0[9].xyzx
    r1.xyz = value_111.xyz;
    uint4 value_112 = asuint(mad(asfloat(r0.xywx), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r4.xyzx))); // mad r5.xyz, r0.xywx, l(0.400000, 0.400000, 0.400000, 0.000000), r4.xyzx
    r5.xyz = value_112.xyz;
    uint4 value_113 = asuint(dot(asfloat(r0.xywx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.x, r0.xywx, -cb0[4].xyzx
    r0.x = value_113.x;
    uint4 value_114 = asuint(asfloat(r5.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0xbe99999au, 0x0u))); // add r0.yz, r5.yyyy, l(0.000000, 0.700000, -0.300000, 0.000000)
    r0.yz = value_114.yz;
    uint4 value_115 = asuint(asfloat(r5.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r2.zw, r5.xxxz, -cb0[3].xxxy
    r2.zw = value_115.zw;
    uint4 value_116 = asuint(asfloat(r2.zzzw) * asfloat(cb0[2].zzzz)); // mul r2.zw, r2.zzzw, cb0[2].zzzz
    r2.zw = value_116.zw;
    uint4 value_117 = asuint(max(asfloat(r2.zzzw), asfloat(cb0[7].xxxy))); // max r2.zw, r2.zzzw, cb0[7].xxxy
    r2.zw = value_117.zw;
    uint4 value_118 = asuint(min(asfloat(r2.xyxx), asfloat(r2.zwzz))); // min r2.xy, r2.xyxx, r2.zwzz
    r2.xy = value_118.xy;
    uint4 value_119 = asuint(max(asfloat(r0.zzzz), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.z, r0.z, l(0.000000)
    r0.z = value_119.z;
    uint4 value_120 = asuint(saturate(asfloat(r0.yyyy))); // mov_sat r0.y, r0.y
    r0.y = value_120.y;
    uint4 value_121 = asuint(floor(asfloat(r0.zzzz))); // round_ni r0.w, r0.z
    r0.w = value_121.w;
    uint4 value_122 = asuint(frac(asfloat(r0.zzzz))); // frc r0.z, r0.z
    r0.z = value_122.z;
    uint4 value_123 = asuint(int4(asfloat(r0.wwww))); // ftoi r1.w, r0.w
    r1.w = value_123.w;
    uint4 value_124 = asuint(asfloat(r3.zzzz) * asfloat(r0.wwww)); // mul r0.w, r3.z, r0.w
    r0.w = value_124.w;
    uint4 value_125 = (r1.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.z, r1.w, l(1)
    r2.z = value_125.z;
    uint4 value_126 = asuint(float4(asint(r2.zzzz))); // itof r2.w, r2.z
    r2.w = value_126.w;
    uint4 value_127 = asuint(asfloat(r3.zzzz) * asfloat(r2.wwww)); // mul r2.w, r3.z, r2.w
    r2.w = value_127.w;
    uint4 value_128 = asuint(int4(asfloat(r2.wwww))); // ftoi r3.x, r2.w
    r3.x = value_128.x;
    uint4 value_129 = asuint(trunc(asfloat(r2.wwww))); // round_z r2.w, r2.w
    r2.w = value_129.w;
    uint4 value_130 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r2.wwww), asfloat(r2.yyyy))); // mad r5.y, cb0[2].y, r2.w, r2.y
    r5.y = value_130.y;
    uint4 value_131 = (asuint(-asint(r3.xxxx)) * r3.yyyy + r2.zzzz); // imad r2.z, -r3.x, r3.y, r2.z
    r2.z = value_131.z;
    uint4 value_132 = asuint(float4(r2.zzzz)); // utof r2.z, r2.z
    r2.z = value_132.z;
    uint4 value_133 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r2.zzzz), asfloat(r2.xxxx))); // mad r5.x, cb0[2].x, r2.z, r2.x
    r5.x = value_133.x;
    uint4 value_134 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_134.xyzw;
    uint4 value_135 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.z, r5.y, l(1.000000)
    r2.z = value_135.z;
    uint4 value_136 = (r2.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r2.z, r2.z, l(0x3f800000)
    r2.z = value_136.z;
    uint4 value_137 = asuint(asfloat(asuint(-asfloat(r6.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r3.xzw, -r6.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r3.xzw = value_137.xzw;
    uint4 value_138 = asuint(mad(asfloat(r2.zzzz), asfloat(r3.xxzw), asfloat(r6.xxyz))); // mad r3.xzw, r2.zzzz, r3.xxzw, r6.xxyz
    r3.xzw = value_138.xzw;
    uint4 value_139 = asuint(int4(asfloat(r0.wwww))); // ftoi r2.z, r0.w
    r2.z = value_139.z;
    uint4 value_140 = asuint(trunc(asfloat(r0.wwww))); // round_z r0.w, r0.w
    r0.w = value_140.w;
    uint4 value_141 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r0.wwww), asfloat(r2.yyyy))); // mad r5.y, cb0[2].y, r0.w, r2.y
    r5.y = value_141.y;
    uint4 value_142 = (asuint(-asint(r2.zzzz)) * r3.yyyy + r1.wwww); // imad r0.w, -r2.z, r3.y, r1.w
    r0.w = value_142.w;
    uint4 value_143 = asuint(float4(r0.wwww)); // utof r0.w, r0.w
    r0.w = value_143.w;
    uint4 value_144 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.wwww), asfloat(r2.xxxx))); // mad r5.x, cb0[2].x, r0.w, r2.x
    r5.x = value_144.x;
    uint4 value_145 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r2.xyzw = value_145.xyzw;
    uint4 value_146 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.w, r5.y, l(1.000000)
    r0.w = value_146.w;
    uint4 value_147 = (r0.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.w, r0.w, l(0x3f800000)
    r0.w = value_147.w;
    uint4 value_148 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r2.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_148.xyz;
    uint4 value_149 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xyzx), asfloat(r2.xyzx))); // mad r2.xyz, r0.wwww, r5.xyzx, r2.xyzx
    r2.xyz = value_149.xyz;
    uint4 value_150 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(r3.xzwx)); // add r3.xyz, -r2.xyzx, r3.xzwx
    r3.xyz = value_150.xyz;
    uint4 value_151 = asuint(mad(asfloat(r0.zzzz), asfloat(r3.xyzx), asfloat(r2.xyzx))); // mad r2.xyz, r0.zzzz, r3.xyzx, r2.xyzx
    r2.xyz = value_151.xyz;
    uint4 value_152 = asuint(asfloat(r2.xyzx) + asfloat(asuint(-asfloat(cb0[9].xyzx)))); // add r2.xyz, r2.xyzx, -cb0[9].xyzx
    r2.xyz = value_152.xyz;
    uint4 value_153 = asuint(mad(asfloat(r0.yyyy), asfloat(r2.xxyz), asfloat(cb0[9].xxyz))); // mad r0.yzw, r0.yyyy, r2.xxyz, cb0[9].xxyz
    r0.yzw = value_153.yzw;
    uint4 value_154 = asuint(asfloat(r1.xyzx) * asfloat(r0.yzwy)); // mul r2.xyz, r1.xyzx, r0.yzwy
    r2.xyz = value_154.xyz;
    uint4 value_155 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r2.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_155.w;
    uint4 value_156 = asuint(mad(asfloat(r0.yyzw), asfloat(r1.xxyz), asfloat(asuint(-asfloat(r1.wwww))))); // mad r0.yzw, r0.yyzw, r1.xxyz, -r1.wwww
    r0.yzw = value_156.yzw;
    uint4 value_157 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r1.x, cb0[5].w, cb0[6].w
    r1.x = value_157.x;
    uint4 value_158 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r1.x, r1.x, l(0.500000)
    r1.x = value_158.x;
    uint4 value_159 = asuint(asfloat(r1.xxxx) * asfloat(cb0[29].xxxx)); // mul r1.x, r1.x, cb0[29].x
    r1.x = value_159.x;
    uint4 value_160 = asuint(mad(asfloat(r1.xxxx), asfloat(r0.yyzw), asfloat(r1.wwww))); // mad r0.yzw, r1.xxxx, r0.yyzw, r1.wwww
    r0.yzw = value_160.yzw;
    uint4 value_161 = asuint(asfloat(r4.yyyy) * asfloat(cb0[31].xyzx)); // mul r1.xyz, r4.yyyy, cb0[31].xyzx
    r1.xyz = value_161.xyz;
    uint4 value_162 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r4.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb0[30].xyzx, r4.xxxx, r1.xyzx
    r1.xyz = value_162.xyz;
    uint4 value_163 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r4.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb0[32].xyzx, r4.zzzz, r1.xyzx
    r1.xyz = value_163.xyz;
    uint4 value_164 = asuint(asfloat(r1.xyzx) + asfloat(cb0[33].xyzx)); // add r1.xyz, r1.xyzx, cb0[33].xyzx
    r1.xyz = value_164.xyz;
    uint4 value_165 = asuint(asfloat(r1.xyxx) * asfloat(cb0[39].zwzz)); // mul r2.xy, r1.xyxx, cb0[39].zwzz
    r2.xy = value_165.xy;
    uint4 value_166 = asuint(frac(asfloat(r2.xxxy))); // frc r2.zw, r2.xxxy
    r2.zw = value_166.zw;
    uint4 value_167 = asuint(asfloat(r0.xxxx) * asfloat(cb0[38].yyyy)); // mul r1.w, r0.x, cb0[38].y
    r1.w = value_167.w;
    uint4 value_168 = asuint(saturate(asfloat(r0.xxxx))); // mov_sat r0.x, r0.x
    r0.x = value_168.x;
    uint4 value_169 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_169.x;
    uint4 value_170 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r1.zzzz))); // mad r1.z, -r1.w, l(0.050000), r1.z
    r1.z = value_170.z;
    uint4 value_171 = r1.xyxx; // mov o4.xy, r1.xyxx
    out_o4.xy = value_171.xy;
    uint4 value_172 = asuint(asfloat(r1.zzzz) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r1.z, r1.z, l(-0.003922)
    r1.z = value_172.z;
    uint4 value_173 = asuint(asfloat(r2.xxxy) * asfloat(cb0[39].xxxy)); // mul r3.zw, r2.xxxy, cb0[39].xxxy
    r3.zw = value_173.zw;
    uint4 value_174 = asuint(mad(asfloat(r2.xyxx), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r3.xy, r2.xyxx, cb0[39].xyxx, cb0[39].xyxx
    r3.xy = value_174.xy;
    uint4 value_175 = asuint(t1.SampleLevel(s1, asfloat(r3.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r3.zyzz, t1.xyzw, s1, l(0.000000)
    r4.xyzw = value_175.xyzw;
    uint4 value_176 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r1.zzzz, -r4.xyzx
    r4.xyz = value_176.xyz;
    uint4 value_177 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r1.x, cb0[38].x, l(20.000000)
    r1.x = value_177.x;
    uint4 value_178 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r1.xxxx, r4.xyzx
    r4.xyz = value_178.xyz;
    uint4 value_179 = asuint(asfloat(asuint(-asfloat(r2.zwzz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r2.xy, -r2.zwzz, l(1.000000, 1.000000, 0.000000, 0.000000)
    r2.xy = value_179.xy;
    uint4 value_180 = asuint(asfloat(r2.xxxx) * asfloat(r4.xyzx)); // mul r4.xyz, r2.xxxx, r4.xyzx
    r4.xyz = value_180.xyz;
    uint4 value_181 = asuint(asfloat(r2.wwww) * asfloat(r4.xyzx)); // mul r4.xyz, r2.wwww, r4.xyzx
    r4.xyz = value_181.xyz;
    uint4 value_182 = asuint(t1.SampleLevel(s1, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r3.zwzz, t1.xyzw, s1, l(0.000000)
    r5.xyzw = value_182.xyzw;
    uint4 value_183 = asuint(t1.SampleLevel(s1, asfloat(r3.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r3.xwxx, t1.xyzw, s1, l(0.000000)
    r6.xyzw = value_183.xyzw;
    uint4 value_184 = asuint(t1.SampleLevel(s1, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.xyxx, t1.xyzw, s1, l(0.000000)
    r3.xyzw = value_184.xyzw;
    uint4 value_185 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r3.xyzx)))); // add r3.xyz, r1.zzzz, -r3.xyzx
    r3.xyz = value_185.xyz;
    uint4 value_186 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r3.xyzx))))); // mul_sat r3.xyz, r1.xxxx, r3.xyzx
    r3.xyz = value_186.xyz;
    uint4 value_187 = asuint(asfloat(r2.zzzz) * asfloat(r3.xyzx)); // mul r3.xyz, r2.zzzz, r3.xyzx
    r3.xyz = value_187.xyz;
    uint4 value_188 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r1.zzzz, -r6.xyzx
    r6.xyz = value_188.xyz;
    uint4 value_189 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r1.xxxx, r6.xyzx
    r6.xyz = value_189.xyz;
    uint4 value_190 = asuint(asfloat(r2.zzzz) * asfloat(r6.xyzx)); // mul r6.xyz, r2.zzzz, r6.xyzx
    r6.xyz = value_190.xyz;
    uint4 value_191 = asuint(asfloat(r1.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r1.zzzz, -r5.xyzx
    r5.xyz = value_191.xyz;
    uint4 value_192 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r1.xxxx, r5.xyzx
    r5.xyz = value_192.xyz;
    uint4 value_193 = asuint(asfloat(r2.xxxx) * asfloat(r5.xyzx)); // mul r5.xyz, r2.xxxx, r5.xyzx
    r5.xyz = value_193.xyz;
    uint4 value_194 = asuint(mad(asfloat(r5.xyzx), asfloat(r2.yyyy), asfloat(r4.xyzx))); // mad r4.xyz, r5.xyzx, r2.yyyy, r4.xyzx
    r4.xyz = value_194.xyz;
    uint4 value_195 = asuint(mad(asfloat(r6.xyzx), asfloat(r2.yyyy), asfloat(r4.xyzx))); // mad r2.xyz, r6.xyzx, r2.yyyy, r4.xyzx
    r2.xyz = value_195.xyz;
    uint4 value_196 = asuint(mad(asfloat(r3.xyzx), asfloat(r2.wwww), asfloat(r2.xyzx))); // mad r2.xyz, r3.xyzx, r2.wwww, r2.xyzx
    r2.xyz = value_196.xyz;
    uint4 value_197 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r1.x, r2.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r1.x = value_197.x;
    uint4 value_198 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.x, l(1.000000)
    r1.x = value_198.x;
    uint4 value_199 = asuint(asfloat(r0.xxxx) * asfloat(r0.xxxx)); // mul r1.y, r0.x, r0.x
    r1.y = value_199.y;
    uint4 value_200 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r1.yyyy), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r1.w, -r0.x, r1.y, l(1.000000)
    r1.w = value_200.w;
    uint4 value_201 = asuint(asfloat(r1.wwww) * asfloat(r1.xxxx)); // mul r0.x, r1.w, r1.x
    r0.x = value_201.x;
    uint4 value_202 = r1.zzzw; // mov o4.zw, r1.zzzw
    out_o4.zw = value_202.zw;
    uint4 value_203 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].wwww)); // mul r0.x, r0.x, cb0[5].w
    r0.x = value_203.x;
    uint4 value_204 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_204.xyz;
    uint4 value_205 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_205.xyz;
    uint4 value_206 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r0.xxxx, r2.xyzx, r1.xyzx
    r1.xyz = value_206.xyz;
    uint4 value_207 = asuint(asfloat(r0.xxxx) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.xxxx, cb0[5].xyzx
    r2.xyz = value_207.xyz;
    uint4 value_208 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_208.xyz;
    uint4 value_209 = asuint(mad(asfloat(r0.yyzw), asfloat(r1.xxyz), asfloat(r2.xxyz))); // mad r0.yzw, r0.yyzw, r1.xxyz, r2.xxyz
    r0.yzw = value_209.yzw;
    uint4 value_210 = asuint(asfloat(r0.yzwy) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add o3.xyz, r0.yzwy, l(0.100000, 0.100000, 0.100000, 0.000000)
    out_o3.xyz = value_210.xyz;
    uint4 value_211 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.y, cb0[5].w, -cb0[6].w
    r0.y = value_211.y;
    uint4 value_212 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yyyy), asfloat(cb0[6].wwww))); // mad o3.w, r0.x, r0.y, cb0[6].w
    out_o3.w = value_212.w;
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
