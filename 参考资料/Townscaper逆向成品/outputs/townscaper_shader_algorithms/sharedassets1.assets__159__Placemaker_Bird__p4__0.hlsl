// Register-explicit recovered HLSL. Not original source.
// Placemaker/Bird vs_4_0 variant []
// Source SHA256 6a49bc7dcc7e8f5d04591d98e1afcaa8f6fd5bf6d35a341060364e184bb7ddbf
// b0: $Globals 672 bytes
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
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = _Time rows=1 cols=4 byte_offset=0
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb1[6].x = _ScreenParams rows=1 cols=4 byte_offset=96
// cb2[10].x = unity_CameraInvProjection rows=4 cols=4 byte_offset=160
// cb3[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb4[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// cb4[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s1 = _VoxelTex
// t1 / s0 = _AoTex
// t2 / s2 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
cbuffer Buffer1:register(b1) { uint4 cb1[7]; };
cbuffer Buffer2:register(b2) { uint4 cb2[12]; };
cbuffer Buffer3:register(b3) { uint4 cb3[4]; };
cbuffer Buffer4:register(b4) { uint4 cb4[21]; };
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
    float2 v2_0: TEXCOORD1;
    float2 v3_0: TEXCOORD2;
    float3 v4_0: NORMAL0;
    float4 v5_0: TANGENT0;
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
    uint4 v4;
    uint4 v5;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    v3.xy = asuint(input.v3_0);
    v4.xyz = asuint(input.v4_0);
    v5.xyzw = asuint(input.v5_0);
    uint4 value_1 = asuint(floor(asfloat(v1.yyyy))); // round_ni r0.x, v1.y
    r0.x = value_1.x;
    uint4 value_2 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, r0.x, l(1.000000)
    r0.x = value_2.x;
    uint4 value_3 = asuint(asfloat(v0.yyyy) * asfloat(cb3[1].xyzw)); // mul r1.xyzw, v0.yyyy, cb3[1].xyzw
    r1.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb3[0].xyzw), asfloat(v0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb3[0].xyzw, v0.xxxx, r1.xyzw
    r1.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(mad(asfloat(cb3[2].xyzw), asfloat(v0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb3[2].xyzw, v0.zzzz, r1.xyzw
    r1.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb3[3].xyzw), asfloat(v0.wwww), asfloat(r1.xyzw))); // mad r1.xyzw, cb3[3].xyzw, v0.wwww, r1.xyzw
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(asfloat(r1.xxyz) + asfloat(asuint(-asfloat(cb0[22].xxyz)))); // add r0.yzw, r1.xxyz, -cb0[22].xxyz
    r0.yzw = value_7.yzw;
    uint4 value_8 = asuint(dot(asfloat(r0.yzwy).xyz, asfloat(r0.yzwy).xyz)).xxxx; // dp3 r2.x, r0.yzwy, r0.yzwy
    r2.x = value_8.x;
    uint4 value_9 = asuint(asfloat(asuint(-asfloat(r2.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r2.x, -r2.x, l(1.000000)
    r2.x = value_9.x;
    uint4 value_10 = asuint(max(asfloat(r2.xxxx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r2.x, r2.x, l(0.000000)
    r2.x = value_10.x;
    uint4 value_11 = asuint(asfloat(r0.yyzw) * asfloat(r2.xxxx)); // mul r0.yzw, r0.yyzw, r2.xxxx
    r0.yzw = value_11.yzw;
    uint4 value_12 = asuint(mad(asfloat(r0.zzzz), asfloat(cb0[22].wwww), asfloat(r1.yyyy))); // mad r2.x, r0.z, cb0[22].w, r1.y
    r2.x = value_12.x;
    uint4 value_13 = asuint(min(asfloat(r2.xxxx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r2.x, r2.x, l(0.000000)
    r2.x = value_13.x;
    uint4 value_14 = asuint(mad(asfloat(r0.zzzz), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r2.xxxx))))); // mad r2.w, r0.z, cb0[22].w, -r2.x
    r2.w = value_14.w;
    uint4 value_15 = asuint(asfloat(r0.yywy) * asfloat(cb0[22].wwww)); // mul r2.xz, r0.yywy, cb0[22].wwww
    r2.xz = value_15.xz;
    uint4 value_16 = asuint(asfloat(r1.xxyz) + asfloat(r2.xxwz)); // add r0.yzw, r1.xxyz, r2.xxwz
    r0.yzw = value_16.yzw;
    uint4 value_17 = asuint(mad(asfloat(r0.zzzz), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x3e99999au)), asfloat(cb1[0].yyyy))); // mad r2.x, r0.z, l(0.300000), cb1[0].y
    r2.x = value_17.x;
    uint4 value_18 = asuint(asfloat(r0.xxxx) * asfloat(r2.xxxx)); // mul r0.x, r0.x, r2.x
    r0.x = value_18.x;
    uint4 value_19 = asuint(asfloat(r0.zzzz) * asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x3e99999au))); // mul r2.x, r0.z, l(0.300000)
    r2.x = value_19.x;
    uint4 value_20 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0x40400000u, 0x40400000u, 0x40400000u, 0x40400000u)), asfloat(r2.xxxx))); // mad r0.x, r0.x, l(3.000000), r2.x
    r0.x = value_20.x;
    uint4 value_21 = asuint(mad(asfloat(asuint(-asfloat(v1.yyyy))), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)), asfloat(r0.xxxx))); // mad r0.x, -v1.y, l(0.500000), r0.x
    r0.x = value_21.x;
    uint4 value_22 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3f400000u, 0x3f000000u, 0x3e800000u, 0x0u))); // add r2.xyzw, r0.xxxx, l(0.750000, 0.500000, 0.250000, 0.000000)
    r2.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(asfloat(r2.xyzw) * asfloat(uint4(0x419de9e7u, 0x419de9e7u, 0x419de9e7u, 0x419de9e7u))); // mul r3.xyzw, r2.xyzw, l(19.739210, 19.739210, 19.739210, 19.739210)
    r3.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(asfloat(r2.xyzw) * asfloat(uint4(0x40490fdbu, 0x40490fdbu, 0x40490fdbu, 0x40490fdbu))); // mul r2.xyzw, r2.xyzw, l(3.141593, 3.141593, 3.141593, 3.141593)
    r2.xyzw = value_24.xyzw;
    uint4 value_25 = ((asfloat(r3.xyzw) >= asfloat(asuint(-asfloat(r3.xyzw)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.xyzw, r3.xyzw, -r3.xyzw
    r3.xyzw = value_25.xyzw;
    uint4 value_26 = ((r3.xyzw != 0u) ? uint4(0x3e22f983u, 0x3e22f983u, 0x3e22f983u, 0x3e22f983u) : uint4(0xbe22f983u, 0xbe22f983u, 0xbe22f983u, 0xbe22f983u)); // movc r4.xyzw, r3.xyzw, l(0.159155,0.159155,0.159155,0.159155), l(-0.159155,-0.159155,-0.159155,-0.159155)
    r4.xyzw = value_26.xyzw;
    uint4 value_27 = ((r3.xyzw != 0u) ? uint4(0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu) : uint4(0xc0c90fdbu, 0xc0c90fdbu, 0xc0c90fdbu, 0xc0c90fdbu)); // movc r3.xyzw, r3.xyzw, l(6.283185,6.283185,6.283185,6.283185), l(-6.283185,-6.283185,-6.283185,-6.283185)
    r3.xyzw = value_27.xyzw;
    uint4 value_28 = asuint(asfloat(r2.xyzw) * asfloat(r4.xyzw)); // mul r2.xyzw, r2.xyzw, r4.xyzw
    r2.xyzw = value_28.xyzw;
    uint4 value_29 = asuint(frac(asfloat(r2.xyzw))); // frc r2.xyzw, r2.xyzw
    r2.xyzw = value_29.xyzw;
    uint4 value_30 = asuint(asfloat(r2.xyzw) * asfloat(r3.xyzw)); // mul r2.xyzw, r2.xyzw, r3.xyzw
    r2.xyzw = value_30.xyzw;
    uint4 value_31s = asuint(sin(asfloat(r2.xyzw))); // sincos r2.xyzw, null, r2.xyzw
    r2.xyzw = value_31s.xyzw;
    uint4 value_32 = asuint(mad(asfloat(r2.xyzw), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)), asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u)))); // mad r2.xyzw, r2.xyzw, l(0.500000, 0.500000, 0.500000, 0.500000), l(-0.500000, -0.500000, -0.500000, -0.500000)
    r2.xyzw = value_32.xyzw;
    uint4 value_33 = ((asfloat(v1.xxxx) >= asfloat(uint4(0x40600000u, 0x3fc00000u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.xy, v1.xxxx, l(3.500000, 1.500000, 0.000000, 0.000000)
    r3.xy = value_33.xy;
    uint4 value_34 = ((r3.xxxx != 0u) ? uint4(0xbf800000u, 0x0u, 0x3f000000u, 0x0u) : uint4(0x80000000u, 0x3f800000u, 0x3f800000u, 0x0u)); // movc r4.xyz, r3.xxxx, l(-1.000000,0,0.500000,0), l(-0.000000,1.000000,1.000000,0)
    r4.xyz = value_34.xyz;
    uint4 value_35 = (r3.xyxx & uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u)); // and r3.xy, r3.xyxx, l(0x3f800000, 0x3f800000, 0, 0)
    r3.xy = value_35.xy;
    uint4 value_36 = asuint(asfloat(r2.xyzw) * asfloat(r4.zzzz)); // mul r2.xyzw, r2.xyzw, r4.zzzz
    r2.xyzw = value_36.xyzw;
    uint4 value_37 = asuint(asfloat(v5.yyyy) * asfloat(cb3[1].xyxy)); // mul r5.xyzw, v5.yyyy, cb3[1].xyxy
    r5.xyzw = value_37.xyzw;
    uint4 value_38 = asuint(mad(asfloat(cb3[0].xyxy), asfloat(v5.xxxx), asfloat(r5.xyzw))); // mad r5.xyzw, cb3[0].xyxy, v5.xxxx, r5.xyzw
    r5.xyzw = value_38.xyzw;
    uint4 value_39 = asuint(mad(asfloat(cb3[2].xyxy), asfloat(v5.zzzz), asfloat(r5.xyzw))); // mad r5.xyzw, cb3[2].xyxy, v5.zzzz, r5.xyzw
    r5.xyzw = value_39.xyzw;
    uint4 value_40 = asuint(asfloat(r5.zwzw) * asfloat(v2.xxyy)); // mul r6.xyzw, r5.zwzw, v2.xxyy
    r6.xyzw = value_40.xyzw;
    uint4 value_41 = asuint(asfloat(r5.xyzw) * asfloat(v3.xxyy)); // mul r5.xyzw, r5.xyzw, v3.xxyy
    r5.xyzw = value_41.xyzw;
    uint4 value_42 = asuint(mad(asfloat(r6.xxxy), asfloat(r2.xxxx), asfloat(r0.yyyz))); // mad r4.zw, r6.xxxy, r2.xxxx, r0.yyyz
    r4.zw = value_42.zw;
    uint4 value_43 = asuint(mad(asfloat(r6.zwzz), asfloat(r2.yyyy), asfloat(r4.zwzz))); // mad r2.xy, r6.zwzz, r2.yyyy, r4.zwzz
    r2.xy = value_43.xy;
    uint4 value_44 = asuint(mad(asfloat(r5.xyxx), asfloat(r2.zzzz), asfloat(r2.xyxx))); // mad r2.xy, r5.xyxx, r2.zzzz, r2.xyxx
    r2.xy = value_44.xy;
    uint4 value_45 = asuint(mad(asfloat(r5.zzwz), asfloat(r2.wwww), asfloat(r2.xxyx))); // mad r0.yz, r5.zzwz, r2.wwww, r2.xxyx
    r0.yz = value_45.yz;
    uint4 value_46 = asuint(asfloat(r0.zzzz) * asfloat(cb4[18].wwww)); // mul r0.x, r0.z, cb4[18].w
    r0.x = value_46.x;
    uint4 value_47 = asuint(mad(asfloat(cb4[17].wwww), asfloat(r0.yyyy), asfloat(r0.xxxx))); // mad r0.x, cb4[17].w, r0.y, r0.x
    r0.x = value_47.x;
    uint4 value_48 = asuint(mad(asfloat(cb4[19].wwww), asfloat(r0.wwww), asfloat(r0.xxxx))); // mad r0.x, cb4[19].w, r0.w, r0.x
    r0.x = value_48.x;
    uint4 value_49 = asuint(asfloat(r0.xxxx) + asfloat(cb4[20].wwww)); // add r0.x, r0.x, cb4[20].w
    r0.x = value_49.x;
    uint4 value_50 = asuint(asfloat(r0.xxxx) * asfloat(cb2[11].yyyy)); // mul r0.x, r0.x, cb2[11].y
    r0.x = value_50.x;
    uint4 value_51 = asuint(asfloat(cb1[6].wwww) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r2.x, cb1[6].w, l(-1.000000)
    r2.x = value_51.x;
    uint4 value_52 = asuint(asfloat(r0.xxxx) * asfloat(r2.xxxx)); // mul r0.x, r0.x, r2.x
    r0.x = value_52.x;
    uint4 value_53 = asuint(asfloat(r0.xxxx) * asfloat(cb0[19].wwww)); // mul r0.x, r0.x, cb0[19].w
    r0.x = value_53.x;
    uint4 value_54 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x4019999au, 0x4019999au, 0x4019999au, 0x4019999au))); // mul r0.x, r0.x, l(2.400000)
    r0.x = value_54.x;
    uint4 value_55 = asuint(max(asfloat(r0.xxxx), asfloat(uint4(0x3c23d70au, 0x3c23d70au, 0x3c23d70au, 0x3c23d70au)))); // max r0.x, r0.x, l(0.010000)
    r0.x = value_55.x;
    uint4 value_56 = asuint(asfloat(r0.xxxx) * asfloat(cb0[18].yyyy)); // mul r0.x, r0.x, cb0[18].y
    r0.x = value_56.x;
    uint4 value_57 = asuint(asfloat(v4.yyyy) * asfloat(cb3[1].xyzx)); // mul r2.xyz, v4.yyyy, cb3[1].xyzx
    r2.xyz = value_57.xyz;
    uint4 value_58 = asuint(mad(asfloat(cb3[0].xyzx), asfloat(v4.xxxx), asfloat(r2.xyzx))); // mad r2.xyz, cb3[0].xyzx, v4.xxxx, r2.xyzx
    r2.xyz = value_58.xyz;
    uint4 value_59 = asuint(mad(asfloat(cb3[2].xyzx), asfloat(v4.zzzz), asfloat(r2.xyzx))); // mad r2.xyz, cb3[2].xyzx, v4.zzzz, r2.xyzx
    r2.xyz = value_59.xyz;
    uint4 value_60 = asuint(asfloat(r0.xxxx) * asfloat(r2.xyzx)); // mul r5.xyz, r0.xxxx, r2.xyzx
    r5.xyz = value_60.xyz;
    uint4 value_61 = asuint(saturate(asfloat(asuint(asfloat(r0.zzzz) * asfloat(uint4(0x42c80000u, 0x42c80000u, 0x42c80000u, 0x42c80000u)))))); // mul_sat r0.x, r0.z, l(100.000000)
    r0.x = value_61.x;
    uint4 value_62 = asuint(asfloat(r0.xxxx) * asfloat(r5.xyzx)); // mul r5.xyz, r0.xxxx, r5.xyzx
    r5.xyz = value_62.xyz;
    uint4 value_63 = asuint(saturate(asfloat(asuint(asfloat(v5.wwww) + asfloat(v5.wwww))))); // add_sat r0.x, v5.w, v5.w
    r0.x = value_63.x;
    uint4 value_64 = asuint(mad(asfloat(r3.yyyy), asfloat(r4.yyyy), asfloat(uint4(0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu)))); // mad r2.w, r3.y, r4.y, l(-0.200000)
    r2.w = value_64.w;
    uint4 value_65 = asuint(asfloat(r0.xxxx) * asfloat(r2.wwww)); // mul r0.x, r0.x, r2.w
    r0.x = value_65.x;
    uint4 value_66 = asuint(mad(asfloat(r5.xyzx), asfloat(r0.xxxx), asfloat(r0.yzwy))); // mad r0.xyz, r5.xyzx, r0.xxxx, r0.yzwy
    r0.xyz = value_66.xyz;
    uint4 value_67 = asuint(asfloat(r0.yyyy) * asfloat(uint4(0xbcf5c28fu, 0xbcf5c28fu, 0xbcf5c28fu, 0xbcf5c28fu))); // mul r0.w, r0.y, l(-0.030000)
    r0.w = value_67.w;
    uint4 value_68 = asuint(asfloat(r3.xxxx) * asfloat(r2.xyzx)); // mul r5.xyz, r3.xxxx, r2.xyzx
    r5.xyz = value_68.xyz;
    uint4 value_69 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r2.x, r2.xyzx, -cb0[4].xyzx
    r2.x = value_69.x;
    uint4 value_70 = asuint(mad(asfloat(r5.xyzx), asfloat(r0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, r5.xyzx, r0.wwww, r0.xyzx
    r0.xyz = value_70.xyz;
    uint4 value_71 = asuint(-asfloat(r0.yyyy)); // mov r0.w, -r0.y
    r0.w = value_71.w;
    uint4 value_72 = asuint(asfloat(r0.xxzw) + asfloat(asuint(-asfloat(cb1[4].xxzy)))); // add r2.yzw, r0.xxzw, -cb1[4].xxzy
    r2.yzw = value_72.yzw;
    uint4 value_73 = asuint(dot(asfloat(r2.yzwy).xyz, asfloat(r2.yzwy).xyz)).xxxx; // dp3 r3.w, r2.yzwy, r2.yzwy
    r3.w = value_73.w;
    uint4 value_74 = asuint(rsqrt(asfloat(r3.wwww))); // rsq r3.w, r3.w
    r3.w = value_74.w;
    uint4 value_75 = asuint(mad(asfloat(asuint(-asfloat(r2.yyzw))), asfloat(r3.wwww), asfloat(r0.xxzw))); // mad r2.yzw, -r2.yyzw, r3.wwww, r0.xxzw
    r2.yzw = value_75.yzw;
    uint4 value_76 = asuint(asfloat(r2.yyzw) * asfloat(uint4(0x0u, 0x40c00000u, 0x40c00000u, 0x40400000u))); // mul r2.yzw, r2.yyzw, l(0.000000, 6.000000, 6.000000, 3.000000)
    r2.yzw = value_76.yzw;
    uint4 value_77 = asuint(asfloat(cb1[0].yyyy) * asfloat(uint4(0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu))); // mul r3.w, cb1[0].y, l(6.283185)
    r3.w = value_77.w;
    uint4 value_78 = ((asfloat(r3.wwww) >= asfloat(asuint(-asfloat(r3.wwww)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r3.w, -r3.w
    r3.w = value_78.w;
    uint4 value_79 = ((r3.wwww != 0u) ? uint4(0x0u, 0x0u, 0x40c90fdbu, 0x3e22f983u) : uint4(0x0u, 0x0u, 0xc0c90fdbu, 0xbe22f983u)); // movc r4.zw, r3.wwww, l(0,0,6.283185,0.159155), l(0,0,-6.283185,-0.159155)
    r4.zw = value_79.zw;
    uint4 value_80 = asuint(asfloat(r4.wwww) * asfloat(cb1[0].yyyy)); // mul r3.w, r4.w, cb1[0].y
    r3.w = value_80.w;
    uint4 value_81 = asuint(frac(asfloat(r3.wwww))); // frc r3.w, r3.w
    r3.w = value_81.w;
    uint4 value_82 = asuint(mad(asfloat(r4.zzzz), asfloat(r3.wwww), asfloat(r2.yyzw))); // mad r2.yzw, r4.zzzz, r3.wwww, r2.yyzw
    r2.yzw = value_82.yzw;
    uint4 value_83c = asuint(cos(asfloat(r2.wwww))); // sincos null, r3.w, r2.w
    r3.w = value_83c.w;
    uint4 value_84s = asuint(sin(asfloat(r2.yyzw))); // sincos r2.yzw, null, r2.yyzw
    r2.yzw = value_84s.yzw;
    uint4 value_85 = asuint(asfloat(r3.wwww) + asfloat(r2.zzzz)); // add r5.z, r3.w, r2.z
    r5.z = value_85.z;
    uint4 value_86 = asuint(asfloat(r2.wwww) + asfloat(r2.yyyy)); // add r5.x, r2.w, r2.y
    r5.x = value_86.x;
    uint4 value_87 = asuint(asfloat(asuint(abs(asfloat(r0.yyyy)))) * asfloat(r5.xxzx)); // mul r2.yz, |r0.yyyy|, r5.xxzx
    r2.yz = value_87.yz;
    uint4 value_88 = asuint(mad(asfloat(r2.yyzy), asfloat(uint4(0x3cf5c290u, 0x0u, 0x3cf5c290u, 0x0u)), asfloat(r0.xxzx))); // mad r5.xz, r2.yyzy, l(0.030000, 0.000000, 0.030000, 0.000000), r0.xxzx
    r5.xz = value_88.xz;
    uint4 value_89 = asuint(-asfloat(r0.yyyy)); // mov r5.y, -r0.y
    r5.y = value_89.y;
    uint4 value_90 = r1.wwww; // mov r0.w, r1.w
    r0.w = value_90.w;
    uint4 value_91 = r0.wwww; // mov r5.w, r0.w
    r5.w = value_91.w;
    uint4 value_92 = asuint(asfloat(asuint(-asfloat(r0.xyzw))) + asfloat(r5.xyzw)); // add r5.xyzw, -r0.xyzw, r5.xyzw
    r5.xyzw = value_92.xyzw;
    uint4 value_93 = asuint(mad(asfloat(r3.xxxx), asfloat(r5.xyzw), asfloat(r0.xyzw))); // mad r0.xyzw, r3.xxxx, r5.xyzw, r0.xyzw
    r0.xyzw = value_93.xyzw;
    uint4 value_94 = asuint(asfloat(r0.xxyz) + asfloat(asuint(-asfloat(cb1[4].xxyz)))); // add r2.yzw, r0.xxyz, -cb1[4].xxyz
    r2.yzw = value_94.yzw;
    uint4 value_95 = asuint(dot(asfloat(r2.yzwy).xyz, asfloat(r2.yzwy).xyz)).xxxx; // dp3 r1.w, r2.yzwy, r2.yzwy
    r1.w = value_95.w;
    uint4 value_96 = asuint(rsqrt(asfloat(r1.wwww))); // rsq r1.w, r1.w
    r1.w = value_96.w;
    uint4 value_97 = asuint(asfloat(r1.wwww) * asfloat(r2.zzzz)); // mul r1.w, r1.w, r2.z
    r1.w = value_97.w;
    uint4 value_98 = asuint(asfloat(r3.xxxx) * asfloat(r1.wwww)); // mul r2.w, r3.x, r1.w
    r2.w = value_98.w;
    uint4 value_99 = asuint(saturate(asfloat(asuint(asfloat(r0.yyyy) * asfloat(uint4(0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu)))))); // mul_sat r1.w, r0.y, l(-0.200000)
    r1.w = value_99.w;
    uint4 value_100 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.w, l(1.000000)
    r1.w = value_100.w;
    uint4 value_101 = asuint(asfloat(r1.wwww) * asfloat(r1.wwww)); // mul r1.w, r1.w, r1.w
    r1.w = value_101.w;
    uint4 value_102 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(r1.wwww), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r1.w, -r1.w, r1.w, l(1.000000)
    r1.w = value_102.w;
    uint4 value_103 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r2.y, -r1.w, l(1.000000)
    r2.y = value_103.y;
    uint4 value_104 = asuint(mad(asfloat(r2.yyyy), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)), asfloat(r1.wwww))); // mad r2.z, r2.y, l(0.500000), r1.w
    r2.z = value_104.z;
    uint4 value_105 = uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u); // mov r3.z, l(0.500000)
    r3.z = value_105.z;
    uint4 value_106 = asuint(asfloat(r2.zzzw) * asfloat(r3.xxxz)); // mul o0.zw, r2.zzzw, r3.xxxz
    out_o0.zw = value_106.zw;
    uint4 value_107 = asuint(frac(asfloat(v1.xyxx))); // frc o0.xy, v1.xyxx
    out_o0.xy = value_107.xy;
    uint4 value_108 = asuint(asfloat(r0.yyyy) * asfloat(cb4[10].xxyx)); // mul r2.yz, r0.yyyy, cb4[10].xxyx
    r2.yz = value_108.yz;
    uint4 value_109 = asuint(mad(asfloat(cb4[9].xxyx), asfloat(r0.xxxx), asfloat(r2.yyzy))); // mad r2.yz, cb4[9].xxyx, r0.xxxx, r2.yyzy
    r2.yz = value_109.yz;
    uint4 value_110 = asuint(mad(asfloat(cb4[11].xxyx), asfloat(r0.zzzz), asfloat(r2.yyzy))); // mad r2.yz, cb4[11].xxyx, r0.zzzz, r2.yyzy
    r2.yz = value_110.yz;
    uint4 value_111 = asuint(mad(asfloat(cb4[12].xyxx), asfloat(r0.wwww), asfloat(r2.yzyy))); // mad o1.xy, cb4[12].xyxx, r0.wwww, r2.yzyy
    out_o1.xy = value_111.xy;
    uint4 value_112 = asuint(asfloat(r4.yyyy) * asfloat(r3.yyyy)); // mul r0.w, r4.y, r3.y
    r0.w = value_112.w;
    uint4 value_113 = asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x41100000u, 0x41100000u, 0x41100000u, 0x41100000u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u)))); // mad r1.w, r0.w, l(9.000000), l(-1.000000)
    r1.w = value_113.w;
    uint4 value_114 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x41000000u, 0x41000000u, 0x41000000u, 0x41000000u))); // add r2.y, -r1.w, l(8.000000)
    r2.y = value_114.y;
    uint4 value_115 = asuint(mad(asfloat(r3.xxxx), asfloat(r2.yyyy), asfloat(r1.wwww))); // mad o1.w, r3.x, r2.y, r1.w
    out_o1.w = value_115.w;
    uint4 value_116 = asuint(saturate(asfloat(asuint(asfloat(v5.wwww) * asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3fc00000u, 0x3fc00000u)))))); // mul_sat r1.w, v5.w, l(1.500000)
    r1.w = value_116.w;
    uint4 value_117 = asuint(mad(asfloat(r1.wwww), asfloat(r0.wwww), asfloat(r4.xxxx))); // mad o1.z, r1.w, r0.w, r4.x
    out_o1.z = value_117.z;
    uint4 value_118 = asuint(asfloat(r0.yyyy) * asfloat(cb4[18].xyzw)); // mul r3.xyzw, r0.yyyy, cb4[18].xyzw
    r3.xyzw = value_118.xyzw;
    uint4 value_119 = asuint(mad(asfloat(cb4[17].xyzw), asfloat(r0.xxxx), asfloat(r3.xyzw))); // mad r3.xyzw, cb4[17].xyzw, r0.xxxx, r3.xyzw
    r3.xyzw = value_119.xyzw;
    uint4 value_120 = asuint(mad(asfloat(cb4[19].xyzw), asfloat(r0.zzzz), asfloat(r3.xyzw))); // mad r0.xyzw, cb4[19].xyzw, r0.zzzz, r3.xyzw
    r0.xyzw = value_120.xyzw;
    uint4 value_121 = asuint(asfloat(r0.xyzw) + asfloat(cb4[20].xyzw)); // add o2.xyzw, r0.xyzw, cb4[20].xyzw
    out_o2.xyzw = value_121.xyzw;
    uint4 value_122 = asuint(asfloat(r1.xzxz) + asfloat(asuint(-asfloat(cb0[3].xyxy)))); // add r0.xyzw, r1.xzxz, -cb0[3].xyxy
    r0.xyzw = value_122.xyzw;
    uint4 value_123 = asuint(asfloat(r0.xyzw) + asfloat(uint4(0x3ca3d70au, 0x0u, 0x0u, 0x3ca3d70au))); // add r3.xyzw, r0.xyzw, l(0.020000, 0.000000, 0.000000, 0.020000)
    r3.xyzw = value_123.xyzw;
    uint4 value_124 = asuint(asfloat(r0.zwzz) * asfloat(cb0[2].zzzz)); // mul r0.xy, r0.zwzz, cb0[2].zzzz
    r0.xy = value_124.xy;
    uint4 value_125 = asuint(max(asfloat(r0.xyxx), asfloat(cb0[7].xyxx))); // max r0.xy, r0.xyxx, cb0[7].xyxx
    r0.xy = value_125.xy;
    uint4 value_126 = asuint(asfloat(r3.xyzw) * asfloat(cb0[2].zzzz)); // mul r3.xyzw, r3.xyzw, cb0[2].zzzz
    r3.xyzw = value_126.xyzw;
    uint4 value_127 = asuint(max(asfloat(r3.xyzw), asfloat(cb0[7].xyxy))); // max r3.xyzw, r3.xyzw, cb0[7].xyxy
    r3.xyzw = value_127.xyzw;
    uint4 value_128 = asuint(asfloat(cb0[2].xxxy) + asfloat(asuint(-asfloat(cb0[7].xxxy)))); // add r0.zw, cb0[2].xxxy, -cb0[7].xxxy
    r0.zw = value_128.zw;
    uint4 value_129 = asuint(min(asfloat(r0.zwzw), asfloat(r3.xyzw))); // min r3.xyzw, r0.zwzw, r3.xyzw
    r3.xyzw = value_129.xyzw;
    uint4 value_130 = asuint(asfloat(r1.yyyy) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r1.w, r1.y, l(-0.500000)
    r1.w = value_130.w;
    uint4 value_131 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r1.w, l(0.000000)
    r1.w = value_131.w;
    uint4 value_132 = asuint(floor(asfloat(r1.wwww))); // round_ni r2.y, r1.w
    r2.y = value_132.y;
    uint4 value_133 = asuint(frac(asfloat(r1.wwww))); // frc r1.w, r1.w
    r1.w = value_133.w;
    uint4 value_134 = asuint(int4(asfloat(r2.yyyy))); // ftoi r2.z, r2.y
    r2.z = value_134.z;
    uint4 value_135 = (r2.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r2.w, r2.z, l(1)
    r2.w = value_135.w;
    uint4 value_136 = asuint(float4(asint(r2.wwww))); // itof r4.x, r2.w
    r4.x = value_136.x;
    uint4 value_137 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r4.z, cb0[2].w
    r4.z = value_137.z;
    uint4 value_138 = uint4(asfloat(r4.zzzz)); // ftou r4.z, r4.z
    r4.z = value_138.z;
    uint4 value_139 = asuint(float4(r4.zzzz)); // utof r4.w, r4.z
    r4.w = value_139.w;
    uint4 value_140 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r4.wwww)); // div r4.w, l(1.000000, 1.000000, 1.000000, 1.000000), r4.w
    r4.w = value_140.w;
    uint4 value_141 = asuint(asfloat(r4.wwww) * asfloat(r4.xxxx)); // mul r4.x, r4.w, r4.x
    r4.x = value_141.x;
    uint4 value_142 = asuint(int4(asfloat(r4.xxxx))); // ftoi r5.x, r4.x
    r5.x = value_142.x;
    uint4 value_143 = asuint(trunc(asfloat(r4.xxxx))); // round_z r6.yw, r4.xxxx
    r6.yw = value_143.yw;
    uint4 value_144 = (asuint(-asint(r5.xxxx)) * r4.zzzz + r2.wwww); // imad r2.w, -r5.x, r4.z, r2.w
    r2.w = value_144.w;
    uint4 value_145 = asuint(float4(r2.wwww)); // utof r6.xz, r2.wwww
    r6.xz = value_145.xz;
    uint4 value_146 = asuint(mad(asfloat(r6.xyzw), asfloat(cb0[2].xyxy), asfloat(r3.xyzw))); // mad r5.xyzw, r6.xyzw, cb0[2].xyxy, r3.xyzw
    r5.xyzw = value_146.xyzw;
    uint4 value_147 = asuint(t0.SampleLevel(s1, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r5.xyxx, t0.xyzw, s1, l(0.000000)
    r7.xyzw = value_147.xyzw;
    uint4 value_148 = asuint(t0.SampleLevel(s1, asfloat(r5.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r5.zwzz, t0.xyzw, s1, l(0.000000)
    r5.xyzw = value_148.xyzw;
    uint4 value_149 = asuint(min(asfloat(r0.zwzz), asfloat(r0.xyxx))); // min r0.xy, r0.zwzz, r0.xyxx
    r0.xy = value_149.xy;
    uint4 value_150 = asuint(mad(asfloat(r6.xyxx), asfloat(cb0[2].xyxx), asfloat(r0.xyxx))); // mad r5.xy, r6.xyxx, cb0[2].xyxx, r0.xyxx
    r5.xy = value_150.xy;
    uint4 value_151 = asuint(t0.SampleLevel(s1, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s1, l(0.000000)
    r6.xyzw = value_151.xyzw;
    uint4 value_152 = asuint(asfloat(asuint(-asfloat(r6.wwww))) + asfloat(r7.wwww)); // add r2.w, -r6.w, r7.w
    r2.w = value_152.w;
    uint4 value_153 = asuint(asfloat(r2.wwww) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r5.x, r2.w, l(50.000000)
    r5.x = value_153.x;
    uint4 value_154 = asuint(asfloat(r5.wwww) + asfloat(asuint(-asfloat(r6.wwww)))); // add r2.w, r5.w, -r6.w
    r2.w = value_154.w;
    uint4 value_155 = asuint(asfloat(r2.wwww) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r5.z, r2.w, l(50.000000)
    r5.z = value_155.z;
    uint4 value_156 = asuint(asfloat(r2.yyyy) * asfloat(r4.wwww)); // mul r2.y, r2.y, r4.w
    r2.y = value_156.y;
    uint4 value_157 = asuint(int4(asfloat(r2.yyyy))); // ftoi r2.w, r2.y
    r2.w = value_157.w;
    uint4 value_158 = asuint(trunc(asfloat(r2.yyyy))); // round_z r7.yw, r2.yyyy
    r7.yw = value_158.yw;
    uint4 value_159 = (asuint(-asint(r2.wwww)) * r4.zzzz + r2.zzzz); // imad r2.y, -r2.w, r4.z, r2.z
    r2.y = value_159.y;
    uint4 value_160 = asuint(float4(r2.yyyy)); // utof r7.xz, r2.yyyy
    r7.xz = value_160.xz;
    uint4 value_161 = asuint(mad(asfloat(r7.xyzw), asfloat(cb0[2].xyxy), asfloat(r3.xyzw))); // mad r3.xyzw, r7.xyzw, cb0[2].xyxy, r3.xyzw
    r3.xyzw = value_161.xyzw;
    uint4 value_162 = asuint(mad(asfloat(r7.zwzz), asfloat(cb0[2].xyxx), asfloat(r0.xyxx))); // mad r0.xy, r7.zwzz, cb0[2].xyxx, r0.xyxx
    r0.xy = value_162.xy;
    uint4 value_163 = asuint(t0.SampleLevel(s1, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r0.xyxx, t0.xyzw, s1, l(0.000000)
    r7.xyzw = value_163.xyzw;
    uint4 value_164 = asuint(t0.SampleLevel(s1, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r3.xyxx, t0.xyzw, s1, l(0.000000)
    r8.xyzw = value_164.xyzw;
    uint4 value_165 = asuint(t0.SampleLevel(s1, asfloat(r3.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r3.zwzz, t0.xyzw, s1, l(0.000000)
    r3.xyzw = value_165.xyzw;
    uint4 value_166 = asuint(asfloat(asuint(-asfloat(r7.wwww))) + asfloat(r3.wwww)); // add r0.x, -r7.w, r3.w
    r0.x = value_166.x;
    uint4 value_167 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r3.z, r0.x, l(50.000000)
    r3.z = value_167.z;
    uint4 value_168 = asuint(asfloat(asuint(-asfloat(r7.wwww))) + asfloat(r8.wwww)); // add r0.x, -r7.w, r8.w
    r0.x = value_168.x;
    uint4 value_169 = asuint(asfloat(r6.wwww) + asfloat(asuint(-asfloat(r7.wwww)))); // add r0.y, r6.w, -r7.w
    r0.y = value_169.y;
    uint4 value_170 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r3.x, r0.x, l(50.000000)
    r3.x = value_170.x;
    uint4 value_171 = asuint(asfloat(asuint(-asfloat(r3.xxzx))) + asfloat(r5.xxzx)); // add r2.yz, -r3.xxzx, r5.xxzx
    r2.yz = value_171.yz;
    uint4 value_172 = asuint(mad(asfloat(r1.wwww), asfloat(r2.yyzy), asfloat(r3.xxzx))); // mad r3.xz, r1.wwww, r2.yyzy, r3.xxzx
    r3.xz = value_172.xz;
    uint4 value_173 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r1.w, l(1.000000)
    r0.x = value_173.x;
    uint4 value_174 = asuint(asfloat(r0.xxxx) * asfloat(r1.wwww)); // mul r0.x, r0.x, r1.w
    r0.x = value_174.x;
    uint4 value_175 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul r0.x, r0.x, l(4.000000)
    r0.x = value_175.x;
    uint4 value_176 = asuint(asfloat(r0.xxxx) * asfloat(r0.yyyy)); // mul r3.y, r0.x, r0.y
    r3.y = value_176.y;
    uint4 value_177 = asuint(asfloat(r4.yyyy) * asfloat(r3.xxyz)); // mul r2.yzw, r4.yyyy, r3.xxyz
    r2.yzw = value_177.yzw;
    uint4 value_178 = asuint(mad(asfloat(r3.xyzx), asfloat(r4.yyyy), asfloat(r1.xyzx))); // mad r3.xyz, r3.xyzx, r4.yyyy, r1.xyzx
    r3.xyz = value_178.xyz;
    uint4 value_179 = asuint(mad(asfloat(r2.yyzw), asfloat(uint4(0x0u, 0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu)), asfloat(r1.xxyz))); // mad r2.yzw, r2.yyzw, l(0.000000, 0.400000, 0.400000, 0.400000), r1.xxyz
    r2.yzw = value_179.yzw;
    uint4 value_180 = asuint(asfloat(r2.zzzz) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r0.xy, r2.zzzz, l(0.700000, -0.300000, 0.000000, 0.000000)
    r0.xy = value_180.xy;
    uint4 value_181 = asuint(asfloat(r2.yywy) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r2.yz, r2.yywy, -cb0[3].xxyx
    r2.yz = value_181.yz;
    uint4 value_182 = asuint(asfloat(r2.yyzy) * asfloat(cb0[2].zzzz)); // mul r2.yz, r2.yyzy, cb0[2].zzzz
    r2.yz = value_182.yz;
    uint4 value_183 = asuint(max(asfloat(r2.yyzy), asfloat(cb0[7].xxyx))); // max r2.yz, r2.yyzy, cb0[7].xxyx
    r2.yz = value_183.yz;
    uint4 value_184 = asuint(min(asfloat(r0.zzwz), asfloat(r2.yyzy))); // min r2.yz, r0.zzwz, r2.yyzy
    r2.yz = value_184.yz;
    uint4 value_185 = asuint(max(asfloat(r0.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.y, r0.y, l(0.000000)
    r0.y = value_185.y;
    uint4 value_186 = asuint(saturate(asfloat(r0.xxxx))); // mov_sat r0.x, r0.x
    r0.x = value_186.x;
    uint4 value_187 = asuint(floor(asfloat(r0.yyyy))); // round_ni r1.w, r0.y
    r1.w = value_187.w;
    uint4 value_188 = asuint(frac(asfloat(r0.yyyy))); // frc r0.y, r0.y
    r0.y = value_188.y;
    uint4 value_189 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.w, r1.w
    r2.w = value_189.w;
    uint4 value_190 = asuint(asfloat(r4.wwww) * asfloat(r1.wwww)); // mul r1.w, r4.w, r1.w
    r1.w = value_190.w;
    uint4 value_191 = (r2.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.w, r2.w, l(1)
    r3.w = value_191.w;
    uint4 value_192 = asuint(float4(asint(r3.wwww))); // itof r4.x, r3.w
    r4.x = value_192.x;
    uint4 value_193 = asuint(asfloat(r4.wwww) * asfloat(r4.xxxx)); // mul r4.x, r4.w, r4.x
    r4.x = value_193.x;
    uint4 value_194 = asuint(int4(asfloat(r4.xxxx))); // ftoi r4.y, r4.x
    r4.y = value_194.y;
    uint4 value_195 = asuint(trunc(asfloat(r4.xxxx))); // round_z r4.x, r4.x
    r4.x = value_195.x;
    uint4 value_196 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r4.xxxx), asfloat(r2.zzzz))); // mad r5.y, cb0[2].y, r4.x, r2.z
    r5.y = value_196.y;
    uint4 value_197 = (asuint(-asint(r4.yyyy)) * r4.zzzz + r3.wwww); // imad r3.w, -r4.y, r4.z, r3.w
    r3.w = value_197.w;
    uint4 value_198 = asuint(float4(r3.wwww)); // utof r3.w, r3.w
    r3.w = value_198.w;
    uint4 value_199 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.wwww), asfloat(r2.yyyy))); // mad r5.x, cb0[2].x, r3.w, r2.y
    r5.x = value_199.x;
    uint4 value_200 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r6.xyzw = value_200.xyzw;
    uint4 value_201 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r5.y, l(1.000000)
    r3.w = value_201.w;
    uint4 value_202 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_202.w;
    uint4 value_203 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_203.xyz;
    uint4 value_204 = asuint(mad(asfloat(r3.wwww), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r5.xyz, r3.wwww, r5.xyzx, r6.xyzx
    r5.xyz = value_204.xyz;
    uint4 value_205 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.w, r1.w
    r3.w = value_205.w;
    uint4 value_206 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_206.w;
    uint4 value_207 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r2.zzzz))); // mad r4.y, cb0[2].y, r1.w, r2.z
    r4.y = value_207.y;
    uint4 value_208 = (asuint(-asint(r3.wwww)) * r4.zzzz + r2.wwww); // imad r1.w, -r3.w, r4.z, r2.w
    r1.w = value_208.w;
    uint4 value_209 = asuint(float4(r1.wwww)); // utof r1.w, r1.w
    r1.w = value_209.w;
    uint4 value_210 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.wwww), asfloat(r2.yyyy))); // mad r4.x, cb0[2].x, r1.w, r2.y
    r4.x = value_210.x;
    uint4 value_211 = asuint(t1.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r4.xyxx, t1.xyzw, s0, l(0.000000)
    r6.xyzw = value_211.xyzw;
    uint4 value_212 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.w, r4.y, l(1.000000)
    r1.w = value_212.w;
    uint4 value_213 = (r1.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.w, r1.w, l(0x3f800000)
    r1.w = value_213.w;
    uint4 value_214 = asuint(asfloat(asuint(-asfloat(r6.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r2.yzw, -r6.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r2.yzw = value_214.yzw;
    uint4 value_215 = asuint(mad(asfloat(r1.wwww), asfloat(r2.yyzw), asfloat(r6.xxyz))); // mad r2.yzw, r1.wwww, r2.yyzw, r6.xxyz
    r2.yzw = value_215.yzw;
    uint4 value_216 = asuint(asfloat(asuint(-asfloat(r2.yzwy))) + asfloat(r5.xyzx)); // add r5.xyz, -r2.yzwy, r5.xyzx
    r5.xyz = value_216.xyz;
    uint4 value_217 = asuint(mad(asfloat(r0.yyyy), asfloat(r5.xxyz), asfloat(r2.yyzw))); // mad r2.yzw, r0.yyyy, r5.xxyz, r2.yyzw
    r2.yzw = value_217.yzw;
    uint4 value_218 = asuint(asfloat(r2.yyzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r2.yzw, r2.yyzw, -cb0[9].xxyz
    r2.yzw = value_218.yzw;
    uint4 value_219 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.yyzw), asfloat(cb0[9].xxyz))); // mad r2.yzw, r0.xxxx, r2.yyzw, cb0[9].xxyz
    r2.yzw = value_219.yzw;
    uint4 value_220 = asuint(asfloat(r3.yyyy) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r0.xy, r3.yyyy, l(0.700000, -0.300000, 0.000000, 0.000000)
    r0.xy = value_220.xy;
    uint4 value_221 = asuint(asfloat(r3.xzxx) + asfloat(asuint(-asfloat(cb0[3].xyxx)))); // add r3.xy, r3.xzxx, -cb0[3].xyxx
    r3.xy = value_221.xy;
    uint4 value_222 = asuint(asfloat(r3.xyxx) * asfloat(cb0[2].zzzz)); // mul r3.xy, r3.xyxx, cb0[2].zzzz
    r3.xy = value_222.xy;
    uint4 value_223 = asuint(max(asfloat(r3.xyxx), asfloat(cb0[7].xyxx))); // max r3.xy, r3.xyxx, cb0[7].xyxx
    r3.xy = value_223.xy;
    uint4 value_224 = asuint(min(asfloat(r0.zzzw), asfloat(r3.xxxy))); // min r0.zw, r0.zzzw, r3.xxxy
    r0.zw = value_224.zw;
    uint4 value_225 = asuint(max(asfloat(r0.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.y, r0.y, l(0.000000)
    r0.y = value_225.y;
    uint4 value_226 = asuint(saturate(asfloat(r0.xxxx))); // mov_sat r0.x, r0.x
    r0.x = value_226.x;
    uint4 value_227 = asuint(floor(asfloat(r0.yyyy))); // round_ni r1.w, r0.y
    r1.w = value_227.w;
    uint4 value_228 = asuint(frac(asfloat(r0.yyyy))); // frc r0.y, r0.y
    r0.y = value_228.y;
    uint4 value_229 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.x, r1.w
    r3.x = value_229.x;
    uint4 value_230 = asuint(asfloat(r4.wwww) * asfloat(r1.wwww)); // mul r1.w, r4.w, r1.w
    r1.w = value_230.w;
    uint4 value_231 = (r3.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.y, r3.x, l(1)
    r3.y = value_231.y;
    uint4 value_232 = asuint(float4(asint(r3.yyyy))); // itof r3.z, r3.y
    r3.z = value_232.z;
    uint4 value_233 = asuint(asfloat(r4.wwww) * asfloat(r3.zzzz)); // mul r3.z, r4.w, r3.z
    r3.z = value_233.z;
    uint4 value_234 = asuint(int4(asfloat(r3.zzzz))); // ftoi r3.w, r3.z
    r3.w = value_234.w;
    uint4 value_235 = asuint(trunc(asfloat(r3.zzzz))); // round_z r3.z, r3.z
    r3.z = value_235.z;
    uint4 value_236 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.zzzz), asfloat(r0.wwww))); // mad r4.y, cb0[2].y, r3.z, r0.w
    r4.y = value_236.y;
    uint4 value_237 = (asuint(-asint(r3.wwww)) * r4.zzzz + r3.yyyy); // imad r3.y, -r3.w, r4.z, r3.y
    r3.y = value_237.y;
    uint4 value_238 = asuint(float4(r3.yyyy)); // utof r3.y, r3.y
    r3.y = value_238.y;
    uint4 value_239 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.yyyy), asfloat(r0.zzzz))); // mad r4.x, cb0[2].x, r3.y, r0.z
    r4.x = value_239.x;
    uint4 value_240 = asuint(t1.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.xyxx, t1.xyzw, s0, l(0.000000)
    r5.xyzw = value_240.xyzw;
    uint4 value_241 = ((asfloat(r4.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.y, r4.y, l(1.000000)
    r3.y = value_241.y;
    uint4 value_242 = (r3.yyyy & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.y, r3.y, l(0x3f800000)
    r3.y = value_242.y;
    uint4 value_243 = asuint(asfloat(asuint(-asfloat(r5.xyxz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x3f800000u))); // add r4.xyw, -r5.xyxz, l(1.000000, 1.000000, 0.000000, 1.000000)
    r4.xyw = value_243.xyw;
    uint4 value_244 = asuint(mad(asfloat(r3.yyyy), asfloat(r4.xxyw), asfloat(r5.xxyz))); // mad r3.yzw, r3.yyyy, r4.xxyw, r5.xxyz
    r3.yzw = value_244.yzw;
    uint4 value_245 = asuint(int4(asfloat(r1.wwww))); // ftoi r4.x, r1.w
    r4.x = value_245.x;
    uint4 value_246 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_246.w;
    uint4 value_247 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r0.wwww))); // mad r5.y, cb0[2].y, r1.w, r0.w
    r5.y = value_247.y;
    uint4 value_248 = (asuint(-asint(r4.xxxx)) * r4.zzzz + r3.xxxx); // imad r0.w, -r4.x, r4.z, r3.x
    r0.w = value_248.w;
    uint4 value_249 = asuint(float4(r0.wwww)); // utof r0.w, r0.w
    r0.w = value_249.w;
    uint4 value_250 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.wwww), asfloat(r0.zzzz))); // mad r5.x, cb0[2].x, r0.w, r0.z
    r5.x = value_250.x;
    uint4 value_251 = asuint(t1.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r5.xyxx, t1.xyzw, s0, l(0.000000)
    r4.xyzw = value_251.xyzw;
    uint4 value_252 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.z, r5.y, l(1.000000)
    r0.z = value_252.z;
    uint4 value_253 = (r0.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r0.z, r0.z, l(0x3f800000)
    r0.z = value_253.z;
    uint4 value_254 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r4.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_254.xyz;
    uint4 value_255 = asuint(mad(asfloat(r0.zzzz), asfloat(r5.xyzx), asfloat(r4.xyzx))); // mad r4.xyz, r0.zzzz, r5.xyzx, r4.xyzx
    r4.xyz = value_255.xyz;
    uint4 value_256 = asuint(asfloat(r3.yzwy) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r3.xyz, r3.yzwy, -r4.xyzx
    r3.xyz = value_256.xyz;
    uint4 value_257 = asuint(mad(asfloat(r0.yyyy), asfloat(r3.xxyz), asfloat(r4.xxyz))); // mad r0.yzw, r0.yyyy, r3.xxyz, r4.xxyz
    r0.yzw = value_257.yzw;
    uint4 value_258 = asuint(asfloat(r0.yyzw) + asfloat(asuint(-asfloat(cb0[9].xxyz)))); // add r0.yzw, r0.yyzw, -cb0[9].xxyz
    r0.yzw = value_258.yzw;
    uint4 value_259 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yzwy), asfloat(cb0[9].xyzx))); // mad r0.xyz, r0.xxxx, r0.yzwy, cb0[9].xyzx
    r0.xyz = value_259.xyz;
    uint4 value_260 = asuint(asfloat(r0.xyzx) * asfloat(r2.yzwy)); // mul r3.xyz, r0.xyzx, r2.yzwy
    r3.xyz = value_260.xyz;
    uint4 value_261 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_261.w;
    uint4 value_262 = asuint(mad(asfloat(r2.yzwy), asfloat(r0.xyzx), asfloat(asuint(-asfloat(r0.wwww))))); // mad r0.xyz, r2.yzwy, r0.xyzx, -r0.wwww
    r0.xyz = value_262.xyz;
    uint4 value_263 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r1.w, cb0[5].w, cb0[6].w
    r1.w = value_263.w;
    uint4 value_264 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r1.w, r1.w, l(0.500000)
    r1.w = value_264.w;
    uint4 value_265 = asuint(asfloat(r1.wwww) * asfloat(cb0[29].xxxx)); // mul r1.w, r1.w, cb0[29].x
    r1.w = value_265.w;
    uint4 value_266 = asuint(mad(asfloat(r1.wwww), asfloat(r0.xyzx), asfloat(r0.wwww))); // mad r0.xyz, r1.wwww, r0.xyzx, r0.wwww
    r0.xyz = value_266.xyz;
    uint4 value_267 = asuint(asfloat(r1.yyyy) * asfloat(cb0[31].xxyz)); // mul r2.yzw, r1.yyyy, cb0[31].xxyz
    r2.yzw = value_267.yzw;
    uint4 value_268 = asuint(mad(asfloat(cb0[30].xyxz), asfloat(r1.xxxx), asfloat(r2.yzyw))); // mad r1.xyw, cb0[30].xyxz, r1.xxxx, r2.yzyw
    r1.xyw = value_268.xyw;
    uint4 value_269 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r1.zzzz), asfloat(r1.xywx))); // mad r1.xyz, cb0[32].xyzx, r1.zzzz, r1.xywx
    r1.xyz = value_269.xyz;
    uint4 value_270 = asuint(asfloat(r1.xyzx) + asfloat(cb0[33].xyzx)); // add r1.xyz, r1.xyzx, cb0[33].xyzx
    r1.xyz = value_270.xyz;
    uint4 value_271 = asuint(asfloat(r1.xxyx) * asfloat(cb0[39].zzwz)); // mul r2.yz, r1.xxyx, cb0[39].zzwz
    r2.yz = value_271.yz;
    uint4 value_272 = asuint(frac(asfloat(r2.yzyy))); // frc r3.xy, r2.yzyy
    r3.xy = value_272.xy;
    uint4 value_273 = asuint(asfloat(r2.xxxx) * asfloat(cb0[38].yyyy)); // mul r0.w, r2.x, cb0[38].y
    r0.w = value_273.w;
    uint4 value_274 = asuint(saturate(asfloat(r2.xxxx))); // mov_sat r2.x, r2.x
    r2.x = value_274.x;
    uint4 value_275 = asuint(asfloat(asuint(-asfloat(r2.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r2.x, l(1.000000)
    r1.w = value_275.w;
    uint4 value_276 = asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r1.zzzz))); // mad r0.w, -r0.w, l(0.050000), r1.z
    r0.w = value_276.w;
    uint4 value_277 = r1.xyxx; // mov o4.xy, r1.xyxx
    out_o4.xy = value_277.xy;
    uint4 value_278 = asuint(asfloat(r0.wwww) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add r3.z, r0.w, l(-0.003922)
    r3.z = value_278.z;
    uint4 value_279 = asuint(asfloat(r2.yyyz) * asfloat(cb0[39].xxxy)); // mul r4.zw, r2.yyyz, cb0[39].xxxy
    r4.zw = value_279.zw;
    uint4 value_280 = asuint(mad(asfloat(r2.yzyy), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r4.xy, r2.yzyy, cb0[39].xyxx, cb0[39].xyxx
    r4.xy = value_280.xy;
    uint4 value_281 = asuint(t2.SampleLevel(s2, asfloat(r4.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r4.zyzz, t2.xyzw, s2, l(0.000000)
    r2.xyzw = value_281.xyzw;
    uint4 value_282 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(r3.zzzz)); // add r1.xyz, -r2.xyzx, r3.zzzz
    r1.xyz = value_282.xyz;
    uint4 value_283 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r0.w, cb0[38].x, l(20.000000)
    r0.w = value_283.w;
    uint4 value_284 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r1.xyzx))))); // mul_sat r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_284.xyz;
    uint4 value_285 = asuint(asfloat(asuint(-asfloat(r3.xyxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r2.xy, -r3.xyxx, l(1.000000, 1.000000, 0.000000, 0.000000)
    r2.xy = value_285.xy;
    uint4 value_286 = asuint(asfloat(r1.xyzx) * asfloat(r2.xxxx)); // mul r1.xyz, r1.xyzx, r2.xxxx
    r1.xyz = value_286.xyz;
    uint4 value_287 = asuint(asfloat(r3.yyyy) * asfloat(r1.xyzx)); // mul r1.xyz, r3.yyyy, r1.xyzx
    r1.xyz = value_287.xyz;
    uint4 value_288 = asuint(t2.SampleLevel(s2, asfloat(r4.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.zwzz, t2.xyzw, s2, l(0.000000)
    r5.xyzw = value_288.xyzw;
    uint4 value_289 = asuint(t2.SampleLevel(s2, asfloat(r4.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r4.xwxx, t2.xyzw, s2, l(0.000000)
    r6.xyzw = value_289.xyzw;
    uint4 value_290 = asuint(t2.SampleLevel(s2, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r4.xyxx, t2.xyzw, s2, l(0.000000)
    r4.xyzw = value_290.xyzw;
    uint4 value_291 = asuint(asfloat(r3.zzzz) + asfloat(asuint(-asfloat(r4.xyzx)))); // add r4.xyz, r3.zzzz, -r4.xyzx
    r4.xyz = value_291.xyz;
    uint4 value_292 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r0.wwww, r4.xyzx
    r4.xyz = value_292.xyz;
    uint4 value_293 = asuint(asfloat(r3.xxxx) * asfloat(r4.xyzx)); // mul r4.xyz, r3.xxxx, r4.xyzx
    r4.xyz = value_293.xyz;
    uint4 value_294 = asuint(asfloat(r3.zzzz) + asfloat(asuint(-asfloat(r6.xyzx)))); // add r6.xyz, r3.zzzz, -r6.xyzx
    r6.xyz = value_294.xyz;
    uint4 value_295 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r6.xyzx))))); // mul_sat r6.xyz, r0.wwww, r6.xyzx
    r6.xyz = value_295.xyz;
    uint4 value_296 = asuint(asfloat(r3.xxxx) * asfloat(r6.xyzx)); // mul r6.xyz, r3.xxxx, r6.xyzx
    r6.xyz = value_296.xyz;
    uint4 value_297 = asuint(asfloat(r3.zzzz) + asfloat(asuint(-asfloat(r5.xyzx)))); // add r5.xyz, r3.zzzz, -r5.xyzx
    r5.xyz = value_297.xyz;
    uint4 value_298 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r0.wwww, r5.xyzx
    r5.xyz = value_298.xyz;
    uint4 value_299 = asuint(asfloat(r2.xxxx) * asfloat(r5.xxyz)); // mul r2.xzw, r2.xxxx, r5.xxyz
    r2.xzw = value_299.xzw;
    uint4 value_300 = asuint(mad(asfloat(r2.xzwx), asfloat(r2.yyyy), asfloat(r1.xyzx))); // mad r1.xyz, r2.xzwx, r2.yyyy, r1.xyzx
    r1.xyz = value_300.xyz;
    uint4 value_301 = asuint(mad(asfloat(r6.xyzx), asfloat(r2.yyyy), asfloat(r1.xyzx))); // mad r1.xyz, r6.xyzx, r2.yyyy, r1.xyzx
    r1.xyz = value_301.xyz;
    uint4 value_302 = asuint(mad(asfloat(r4.xyzx), asfloat(r3.yyyy), asfloat(r1.xyzx))); // mad r1.xyz, r4.xyzx, r3.yyyy, r1.xyzx
    r1.xyz = value_302.xyz;
    uint4 value_303 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r0.w, r1.xyzx, l(0.350000, 0.350000, 0.300000, 0.000000)
    r0.w = value_303.w;
    uint4 value_304 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_304.w;
    uint4 value_305 = asuint(asfloat(r1.wwww) * asfloat(r1.wwww)); // mul r1.x, r1.w, r1.w
    r1.x = value_305.x;
    uint4 value_306 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(r1.xxxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r3.w, -r1.w, r1.x, l(1.000000)
    r3.w = value_306.w;
    uint4 value_307 = asuint(asfloat(r0.wwww) * asfloat(r3.wwww)); // mul r0.w, r0.w, r3.w
    r0.w = value_307.w;
    uint4 value_308 = r3.zzzw; // mov o4.zw, r3.zzzw
    out_o4.zw = value_308.zw;
    uint4 value_309 = asuint(asfloat(r0.wwww) * asfloat(cb0[5].wwww)); // mul r0.w, r0.w, cb0[5].w
    r0.w = value_309.w;
    uint4 value_310 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_310.xyz;
    uint4 value_311 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_311.xyz;
    uint4 value_312 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r0.wwww, r2.xyzx, r1.xyzx
    r1.xyz = value_312.xyz;
    uint4 value_313 = asuint(asfloat(r0.wwww) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.wwww, cb0[5].xyzx
    r2.xyz = value_313.xyz;
    uint4 value_314 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_314.xyz;
    uint4 value_315 = asuint(mad(asfloat(r0.xyzx), asfloat(r1.xyzx), asfloat(r2.xyzx))); // mad r0.xyz, r0.xyzx, r1.xyzx, r2.xyzx
    r0.xyz = value_315.xyz;
    uint4 value_316 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add o3.xyz, r0.xyzx, l(0.100000, 0.100000, 0.100000, 0.000000)
    out_o3.xyz = value_316.xyz;
    uint4 value_317 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.x, cb0[5].w, -cb0[6].w
    r0.x = value_317.x;
    uint4 value_318 = asuint(mad(asfloat(r0.wwww), asfloat(r0.xxxx), asfloat(cb0[6].wwww))); // mad o3.w, r0.w, r0.x, cb0[6].w
    out_o3.w = value_318.w;
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
