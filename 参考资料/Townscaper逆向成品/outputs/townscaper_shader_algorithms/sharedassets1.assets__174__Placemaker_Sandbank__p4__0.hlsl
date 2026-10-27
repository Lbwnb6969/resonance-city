// Register-explicit recovered HLSL. Not original source.
// Placemaker/Sandbank vs_4_0 variant []
// Source SHA256 0059b1ed122ad538ea3fec511137a027b8b134b7765b1f9a162b10c436e016d3
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
// cb0[22].x = _PressPosAmount rows=1 cols=4 byte_offset=352
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[41].x = _SandUv rows=1 cols=4 byte_offset=656
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = _Time rows=1 cols=4 byte_offset=0
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[9].x = unity_MatrixV rows=4 cols=4 byte_offset=144
// cb3[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _AoTex
cbuffer Buffer0:register(b0) { uint4 cb0[42]; };
cbuffer Buffer1:register(b1) { uint4 cb1[5]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[21]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
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
    float2 o2_0: TEXCOORD4;
    float4 o3_0: SV_POSITION;
    float4 o4_0: COLOR0;
    float4 o5_0: COLOR1;
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
    uint4 out_o5;
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
    uint4 value_1 = asuint(asfloat(asuint(abs(asfloat(v3.wwww)))) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.x, |v3.w|, l(-0.500000)
    r0.x = value_1.x;
    uint4 value_2 = asuint(mad(asfloat(r0.xxxx), asfloat(cb0[41].zzzz), asfloat(cb0[41].xxxx))); // mad o0.x, r0.x, cb0[41].z, cb0[41].x
    out_o0.x = value_2.x;
    uint4 value_3 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb2[1].xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb2[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(mad(asfloat(cb2[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb2[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb2[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(asfloat(r0.xyzx) + asfloat(asuint(-asfloat(cb0[22].xyzx)))); // add r1.xyz, r0.xyzx, -cb0[22].xyzx
    r1.xyz = value_7.xyz;
    uint4 value_8 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(r1.xyzx).xyz)).xxxx; // dp3 r1.w, r1.xyzx, r1.xyzx
    r1.w = value_8.w;
    uint4 value_9 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.w, l(1.000000)
    r1.w = value_9.w;
    uint4 value_10 = asuint(max(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.w, r1.w, l(0.000000)
    r1.w = value_10.w;
    uint4 value_11 = asuint(asfloat(r1.wwww) * asfloat(r1.xyzx)); // mul r1.xyz, r1.wwww, r1.xyzx
    r1.xyz = value_11.xyz;
    uint4 value_12 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(r0.yyyy))); // mad r1.w, r1.y, cb0[22].w, r0.y
    r1.w = value_12.w;
    uint4 value_13 = asuint(min(asfloat(r1.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // min r1.w, r1.w, l(0.000000)
    r1.w = value_13.w;
    uint4 value_14 = asuint(mad(asfloat(r1.yyyy), asfloat(cb0[22].wwww), asfloat(asuint(-asfloat(r1.wwww))))); // mad r2.w, r1.y, cb0[22].w, -r1.w
    r2.w = value_14.w;
    uint4 value_15 = asuint(asfloat(r1.xxzx) * asfloat(cb0[22].wwww)); // mul r2.xz, r1.xxzx, cb0[22].wwww
    r2.xz = value_15.xz;
    uint4 value_16 = asuint(asfloat(r0.xyzx) + asfloat(r2.xwzx)); // add r1.xyz, r0.xyzx, r2.xwzx
    r1.xyz = value_16.xyz;
    uint4 value_17 = r1.yyyy; // mov o0.z, r1.y
    out_o0.z = value_17.z;
    uint4 value_18 = asuint(asfloat(r0.yyyy) * asfloat(cb0[41].wwww)); // mul r2.x, r0.y, cb0[41].w
    r2.x = value_18.x;
    uint4 value_19 = asuint(mad(asfloat(r2.xxxx), asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u)), asfloat(cb0[41].yyyy))); // mad o0.y, r2.x, l(4.000000), cb0[41].y
    out_o0.y = value_19.y;
    uint4 value_20 = asuint(asfloat(cb1[0].yyyy) * asfloat(uint4(0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu, 0x40c90fdbu))); // mul r2.x, cb1[0].y, l(6.283185)
    r2.x = value_20.x;
    uint4 value_21 = ((asfloat(r2.xxxx) >= asfloat(asuint(-asfloat(r2.xxxx)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r2.x, r2.x, -r2.x
    r2.x = value_21.x;
    uint4 value_22 = ((r2.xxxx != 0u) ? uint4(0x40c90fdbu, 0x3e22f983u, 0x0u, 0x0u) : uint4(0xc0c90fdbu, 0xbe22f983u, 0x0u, 0x0u)); // movc r2.xy, r2.xxxx, l(6.283185,0.159155,0,0), l(-6.283185,-0.159155,0,0)
    r2.xy = value_22.xy;
    uint4 value_23 = asuint(asfloat(r2.yyyy) * asfloat(cb1[0].yyyy)); // mul r2.y, r2.y, cb1[0].y
    r2.y = value_23.y;
    uint4 value_24 = asuint(frac(asfloat(r2.yyyy))); // frc r2.y, r2.y
    r2.y = value_24.y;
    uint4 value_25 = asuint(-asfloat(r1.yyyy)); // mov r1.w, -r1.y
    r1.w = value_25.w;
    uint4 value_26 = asuint(asfloat(r1.xzwx) + asfloat(asuint(-asfloat(cb1[4].xzyx)))); // add r3.xyz, r1.xzwx, -cb1[4].xzyx
    r3.xyz = value_26.xyz;
    uint4 value_27 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(r3.xyzx).xyz)).xxxx; // dp3 r2.z, r3.xyzx, r3.xyzx
    r2.z = value_27.z;
    uint4 value_28 = asuint(rsqrt(asfloat(r2.zzzz))); // rsq r2.z, r2.z
    r2.z = value_28.z;
    uint4 value_29 = asuint(mad(asfloat(asuint(-asfloat(r3.xyzx))), asfloat(r2.zzzz), asfloat(r1.xzwx))); // mad r3.xyz, -r3.xyzx, r2.zzzz, r1.xzwx
    r3.xyz = value_29.xyz;
    uint4 value_30 = asuint(asfloat(r3.xyzx) * asfloat(uint4(0x40c00000u, 0x40c00000u, 0x40400000u, 0x0u))); // mul r3.xyz, r3.xyzx, l(6.000000, 6.000000, 3.000000, 0.000000)
    r3.xyz = value_30.xyz;
    uint4 value_31 = asuint(mad(asfloat(r2.xxxx), asfloat(r2.yyyy), asfloat(r3.xyzx))); // mad r2.xyz, r2.xxxx, r2.yyyy, r3.xyzx
    r2.xyz = value_31.xyz;
    uint4 value_32c = asuint(cos(asfloat(r2.zzzz))); // sincos null, r2.w, r2.z
    r2.w = value_32c.w;
    uint4 value_33s = asuint(sin(asfloat(r2.xyzx))); // sincos r2.xyz, null, r2.xyzx
    r2.xyz = value_33s.xyz;
    uint4 value_34 = asuint(asfloat(r2.zzwz) + asfloat(r2.xxyx)); // add r3.xz, r2.zzwz, r2.xxyx
    r3.xz = value_34.xz;
    uint4 value_35 = asuint(asfloat(asuint(abs(asfloat(r1.yyyy)))) * asfloat(r3.xzxx)); // mul r2.xy, |r1.yyyy|, r3.xzxx
    r2.xy = value_35.xy;
    uint4 value_36 = asuint(mad(asfloat(r2.xxyx), asfloat(uint4(0x3dcccccdu, 0x0u, 0x3dcccccdu, 0x0u)), asfloat(r1.xxzx))); // mad r2.xz, r2.xxyx, l(0.100000, 0.000000, 0.100000, 0.000000), r1.xxzx
    r2.xz = value_36.xz;
    uint4 value_37 = asuint(-asfloat(r1.yyyy)); // mov r2.y, -r1.y
    r2.y = value_37.y;
    uint4 value_38 = r0.wwww; // mov r1.w, r0.w
    r1.w = value_38.w;
    uint4 value_39 = r1.wwww; // mov r2.w, r1.w
    r2.w = value_39.w;
    uint4 value_40 = asuint(asfloat(asuint(-asfloat(r1.xyzw))) + asfloat(r2.xyzw)); // add r2.xyzw, -r1.xyzw, r2.xyzw
    r2.xyzw = value_40.xyzw;
    uint4 value_41 = ((asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)) >= asfloat(v3.wwww)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.w, l(0.000000), v3.w
    r0.w = value_41.w;
    uint4 value_42 = (r0.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.x, r0.w, l(0x3f800000)
    r3.x = value_42.x;
    uint4 value_43 = asuint(mad(asfloat(r3.xxxx), asfloat(r2.xyzw), asfloat(r1.xyzw))); // mad r1.xyzw, r3.xxxx, r2.xyzw, r1.xyzw
    r1.xyzw = value_43.xyzw;
    uint4 value_44 = asuint(asfloat(r1.yyyy) * asfloat(cb3[10].xyxx)); // mul r2.xy, r1.yyyy, cb3[10].xyxx
    r2.xy = value_44.xy;
    uint4 value_45 = asuint(mad(asfloat(cb3[9].xyxx), asfloat(r1.xxxx), asfloat(r2.xyxx))); // mad r2.xy, cb3[9].xyxx, r1.xxxx, r2.xyxx
    r2.xy = value_45.xy;
    uint4 value_46 = asuint(mad(asfloat(cb3[11].xyxx), asfloat(r1.zzzz), asfloat(r2.xyxx))); // mad r2.xy, cb3[11].xyxx, r1.zzzz, r2.xyxx
    r2.xy = value_46.xy;
    uint4 value_47 = asuint(mad(asfloat(cb3[12].xyxx), asfloat(r1.wwww), asfloat(r2.xyxx))); // mad o1.xy, cb3[12].xyxx, r1.wwww, r2.xyxx
    out_o1.xy = value_47.xy;
    uint4 value_48 = asuint(asfloat(r1.xxxz) * asfloat(uint4(0x0u, 0x0u, 0x3f000000u, 0x3f000000u))); // mul o1.zw, r1.xxxz, l(0.000000, 0.000000, 0.500000, 0.500000)
    out_o1.zw = value_48.zw;
    uint4 value_49 = asuint(asfloat(r1.xyzx) + asfloat(asuint(-asfloat(cb1[4].xyzx)))); // add r2.xyz, r1.xyzx, -cb1[4].xyzx
    r2.xyz = value_49.xyz;
    uint4 value_50 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(r2.xyzx).xyz)).xxxx; // dp3 r0.w, r2.xyzx, r2.xyzx
    r0.w = value_50.w;
    uint4 value_51 = asuint(rsqrt(asfloat(r0.wwww))); // rsq r0.w, r0.w
    r0.w = value_51.w;
    uint4 value_52 = asuint(asfloat(r0.wwww) * asfloat(r2.yyyy)); // mul r0.w, r0.w, r2.y
    r0.w = value_52.w;
    uint4 value_53 = asuint(asfloat(r3.xxxx) * asfloat(r0.wwww)); // mul r2.y, r3.x, r0.w
    r2.y = value_53.y;
    uint4 value_54 = asuint(saturate(asfloat(asuint(asfloat(r1.yyyy) * asfloat(uint4(0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu, 0xbe4ccccdu)))))); // mul_sat r0.w, r1.y, l(-0.200000)
    r0.w = value_54.w;
    uint4 value_55 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.w, -r0.w, l(1.000000)
    r0.w = value_55.w;
    uint4 value_56 = asuint(asfloat(r0.wwww) * asfloat(r0.wwww)); // mul r0.w, r0.w, r0.w
    r0.w = value_56.w;
    uint4 value_57 = asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(r0.wwww), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.w, -r0.w, r0.w, l(1.000000)
    r0.w = value_57.w;
    uint4 value_58 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r0.w, l(1.000000)
    r1.w = value_58.w;
    uint4 value_59 = asuint(mad(asfloat(r1.wwww), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)), asfloat(r0.wwww))); // mad r2.x, r1.w, l(0.500000), r0.w
    r2.x = value_59.x;
    uint4 value_60 = uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u); // mov r3.y, l(0.500000)
    r3.y = value_60.y;
    uint4 value_61 = asuint(asfloat(r2.xyxx) * asfloat(r3.xyxx)); // mul o2.xy, r2.xyxx, r3.xyxx
    out_o2.xy = value_61.xy;
    uint4 value_62 = asuint(asfloat(r1.yyyy) * asfloat(cb3[18].xyzw)); // mul r2.xyzw, r1.yyyy, cb3[18].xyzw
    r2.xyzw = value_62.xyzw;
    uint4 value_63 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r1.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb3[17].xyzw, r1.xxxx, r2.xyzw
    r2.xyzw = value_63.xyzw;
    uint4 value_64 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r1.zzzz), asfloat(r2.xyzw))); // mad r1.xyzw, cb3[19].xyzw, r1.zzzz, r2.xyzw
    r1.xyzw = value_64.xyzw;
    uint4 value_65 = asuint(asfloat(r1.xyzw) + asfloat(cb3[20].xyzw)); // add o3.xyzw, r1.xyzw, cb3[20].xyzw
    out_o3.xyzw = value_65.xyzw;
    uint4 value_66 = asuint(asfloat(v3.yyyy) * asfloat(cb2[1].xyzx)); // mul r1.xyz, v3.yyyy, cb2[1].xyzx
    r1.xyz = value_66.xyz;
    uint4 value_67 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v3.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb2[0].xyzx, v3.xxxx, r1.xyzx
    r1.xyz = value_67.xyz;
    uint4 value_68 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v3.zzzz), asfloat(r1.xyzx))); // mad r1.xyz, cb2[2].xyzx, v3.zzzz, r1.xyzx
    r1.xyz = value_68.xyz;
    uint4 value_69 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r2.xyz, r1.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000), r0.xyzx
    r2.xyz = value_69.xyz;
    uint4 value_70 = asuint(asfloat(r2.yyyy) + asfloat(uint4(0x0u, 0x3f333333u, 0x0u, 0xbe99999au))); // add r2.yw, r2.yyyy, l(0.000000, 0.700000, 0.000000, -0.300000)
    r2.yw = value_70.yw;
    uint4 value_71 = asuint(asfloat(r2.xxzx) + asfloat(asuint(-asfloat(cb0[3].xxyx)))); // add r2.xz, r2.xxzx, -cb0[3].xxyx
    r2.xz = value_71.xz;
    uint4 value_72 = asuint(asfloat(r2.xxzx) * asfloat(cb0[2].zzzz)); // mul r2.xz, r2.xxzx, cb0[2].zzzz
    r2.xz = value_72.xz;
    uint4 value_73 = asuint(max(asfloat(r2.xxzx), asfloat(cb0[7].xxyx))); // max r2.xz, r2.xxzx, cb0[7].xxyx
    r2.xz = value_73.xz;
    uint4 value_74 = asuint(max(asfloat(r2.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r2.w, l(0.000000)
    r0.w = value_74.w;
    uint4 value_75 = asuint(saturate(asfloat(r2.yyyy))); // mov_sat r2.y, r2.y
    r2.y = value_75.y;
    uint4 value_76 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.w, r0.w
    r1.w = value_76.w;
    uint4 value_77 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_77.w;
    uint4 value_78 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.w, r1.w
    r2.w = value_78.w;
    uint4 value_79 = (r2.wwww + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.x, r2.w, l(1)
    r3.x = value_79.x;
    uint4 value_80 = asuint(float4(asint(r3.xxxx))); // itof r3.y, r3.x
    r3.y = value_80.y;
    uint4 value_81 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r3.z, cb0[2].w
    r3.z = value_81.z;
    uint4 value_82 = uint4(asfloat(r3.zzzz)); // ftou r3.z, r3.z
    r3.z = value_82.z;
    uint4 value_83 = asuint(float4(r3.zzzz)); // utof r3.w, r3.z
    r3.w = value_83.w;
    uint4 value_84 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r3.wwww)); // div r3.w, l(1.000000, 1.000000, 1.000000, 1.000000), r3.w
    r3.w = value_84.w;
    uint4 value_85 = asuint(asfloat(r3.wwww) * asfloat(r3.yyyy)); // mul r3.y, r3.w, r3.y
    r3.y = value_85.y;
    uint4 value_86 = asuint(int4(asfloat(r3.yyyy))); // ftoi r4.x, r3.y
    r4.x = value_86.x;
    uint4 value_87 = asuint(trunc(asfloat(r3.yyyy))); // round_z r3.y, r3.y
    r3.y = value_87.y;
    uint4 value_88 = (asuint(-asint(r4.xxxx)) * r3.zzzz + r3.xxxx); // imad r3.x, -r4.x, r3.z, r3.x
    r3.x = value_88.x;
    uint4 value_89 = asuint(float4(r3.xxxx)); // utof r3.x, r3.x
    r3.x = value_89.x;
    uint4 value_90 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r4.xy, cb0[2].xyxx, -cb0[7].xyxx
    r4.xy = value_90.xy;
    uint4 value_91 = asuint(min(asfloat(r2.xxzx), asfloat(r4.xxyx))); // min r2.xz, r2.xxzx, r4.xxyx
    r2.xz = value_91.xz;
    uint4 value_92 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.xxxx), asfloat(r2.xxxx))); // mad r5.x, cb0[2].x, r3.x, r2.x
    r5.x = value_92.x;
    uint4 value_93 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.yyyy), asfloat(r2.zzzz))); // mad r5.y, cb0[2].y, r3.y, r2.z
    r5.y = value_93.y;
    uint4 value_94 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_94.xyzw;
    uint4 value_95 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.x, r5.y, l(1.000000)
    r3.x = value_95.x;
    uint4 value_96 = (r3.xxxx & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.x, r3.x, l(0x3f800000)
    r3.x = value_96.x;
    uint4 value_97 = asuint(asfloat(asuint(-asfloat(r6.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r6.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_97.xyz;
    uint4 value_98 = asuint(mad(asfloat(r3.xxxx), asfloat(r5.xyzx), asfloat(r6.xyzx))); // mad r6.xyz, r3.xxxx, r5.xyzx, r6.xyzx
    r6.xyz = value_98.xyz;
    uint4 value_99 = asuint(asfloat(r1.wwww) * asfloat(r3.wwww)); // mul r1.w, r1.w, r3.w
    r1.w = value_99.w;
    uint4 value_100 = asuint(int4(asfloat(r1.wwww))); // ftoi r3.x, r1.w
    r3.x = value_100.x;
    uint4 value_101 = asuint(trunc(asfloat(r1.wwww))); // round_z r1.w, r1.w
    r1.w = value_101.w;
    uint4 value_102 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r1.wwww), asfloat(r2.zzzz))); // mad r5.y, cb0[2].y, r1.w, r2.z
    r5.y = value_102.y;
    uint4 value_103 = (asuint(-asint(r3.xxxx)) * r3.zzzz + r2.wwww); // imad r1.w, -r3.x, r3.z, r2.w
    r1.w = value_103.w;
    uint4 value_104 = asuint(float4(r1.wwww)); // utof r1.w, r1.w
    r1.w = value_104.w;
    uint4 value_105 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.wwww), asfloat(r2.xxxx))); // mad r5.x, cb0[2].x, r1.w, r2.x
    r5.x = value_105.x;
    uint4 value_106 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r7.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r7.xyzw = value_106.xyzw;
    uint4 value_107 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.w, r5.y, l(1.000000)
    r1.w = value_107.w;
    uint4 value_108 = (r1.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.w, r1.w, l(0x3f800000)
    r1.w = value_108.w;
    uint4 value_109 = asuint(asfloat(asuint(-asfloat(r7.xxyz))) + asfloat(uint4(0x3f800000u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r2.xzw, -r7.xxyz, l(1.000000, 0.000000, 1.000000, 1.000000)
    r2.xzw = value_109.xzw;
    uint4 value_110 = asuint(mad(asfloat(r1.wwww), asfloat(r2.xzwx), asfloat(r7.xyzx))); // mad r7.xyz, r1.wwww, r2.xzwx, r7.xyzx
    r7.xyz = value_110.xyz;
    uint4 value_111 = asuint(asfloat(r6.xyzw) + asfloat(asuint(-asfloat(r7.xyzw)))); // add r5.xyzw, r6.xyzw, -r7.xyzw
    r5.xyzw = value_111.xyzw;
    uint4 value_112 = asuint(mad(asfloat(r0.wwww), asfloat(r5.xyzw), asfloat(r7.xyzw))); // mad r5.xyzw, r0.wwww, r5.xyzw, r7.xyzw
    r5.xyzw = value_112.xyzw;
    uint4 value_113 = asuint(asfloat(r5.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r5.xyzw, r5.xyzw, -cb0[9].xyzw
    r5.xyzw = value_113.xyzw;
    uint4 value_114 = asuint(mad(asfloat(r2.yyyy), asfloat(r5.xyzw), asfloat(cb0[9].xyzw))); // mad r2.xyzw, r2.yyyy, r5.xyzw, cb0[9].xyzw
    r2.xyzw = value_114.xyzw;
    uint4 value_115 = asuint(asfloat(r0.xyzx) + asfloat(r1.xyzx)); // add r5.xyz, r0.xyzx, r1.xyzx
    r5.xyz = value_115.xyz;
    uint4 value_116 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(asuint(-asfloat(cb0[4].xyzx))).xyz)).xxxx; // dp3 r0.w, r1.xyzx, -cb0[4].xyzx
    r0.w = value_116.w;
    uint4 value_117 = asuint(asfloat(r5.yyyy) + asfloat(uint4(0x3f333333u, 0xbe99999au, 0x0u, 0x0u))); // add r1.xy, r5.yyyy, l(0.700000, -0.300000, 0.000000, 0.000000)
    r1.xy = value_117.xy;
    uint4 value_118 = asuint(asfloat(r5.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r1.zw, r5.xxxz, -cb0[3].xxxy
    r1.zw = value_118.zw;
    uint4 value_119 = asuint(asfloat(r1.zzzw) * asfloat(cb0[2].zzzz)); // mul r1.zw, r1.zzzw, cb0[2].zzzz
    r1.zw = value_119.zw;
    uint4 value_120 = asuint(max(asfloat(r1.zzzw), asfloat(cb0[7].xxxy))); // max r1.zw, r1.zzzw, cb0[7].xxxy
    r1.zw = value_120.zw;
    uint4 value_121 = asuint(min(asfloat(r4.xxxy), asfloat(r1.zzzw))); // min r1.zw, r4.xxxy, r1.zzzw
    r1.zw = value_121.zw;
    uint4 value_122 = asuint(max(asfloat(r1.yyyy), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.y, r1.y, l(0.000000)
    r1.y = value_122.y;
    uint4 value_123 = asuint(saturate(asfloat(r1.xxxx))); // mov_sat r1.x, r1.x
    r1.x = value_123.x;
    uint4 value_124 = asuint(floor(asfloat(r1.yyyy))); // round_ni r3.x, r1.y
    r3.x = value_124.x;
    uint4 value_125 = asuint(frac(asfloat(r1.yyyy))); // frc r1.y, r1.y
    r1.y = value_125.y;
    uint4 value_126 = asuint(int4(asfloat(r3.xxxx))); // ftoi r3.y, r3.x
    r3.y = value_126.y;
    uint4 value_127 = asuint(asfloat(r3.wwww) * asfloat(r3.xxxx)); // mul r3.x, r3.w, r3.x
    r3.x = value_127.x;
    uint4 value_128 = (r3.yyyy + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r4.x, r3.y, l(1)
    r4.x = value_128.x;
    uint4 value_129 = asuint(float4(asint(r4.xxxx))); // itof r4.y, r4.x
    r4.y = value_129.y;
    uint4 value_130 = asuint(asfloat(r3.wwww) * asfloat(r4.yyyy)); // mul r3.w, r3.w, r4.y
    r3.w = value_130.w;
    uint4 value_131 = asuint(int4(asfloat(r3.wwww))); // ftoi r4.y, r3.w
    r4.y = value_131.y;
    uint4 value_132 = asuint(trunc(asfloat(r3.wwww))); // round_z r3.w, r3.w
    r3.w = value_132.w;
    uint4 value_133 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.wwww), asfloat(r1.wwww))); // mad r5.y, cb0[2].y, r3.w, r1.w
    r5.y = value_133.y;
    uint4 value_134 = (asuint(-asint(r4.yyyy)) * r3.zzzz + r4.xxxx); // imad r3.w, -r4.y, r3.z, r4.x
    r3.w = value_134.w;
    uint4 value_135 = asuint(float4(r3.wwww)); // utof r3.w, r3.w
    r3.w = value_135.w;
    uint4 value_136 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r3.wwww), asfloat(r1.zzzz))); // mad r5.x, cb0[2].x, r3.w, r1.z
    r5.x = value_136.x;
    uint4 value_137 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_137.xyzw;
    uint4 value_138 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r3.w, r5.y, l(1.000000)
    r3.w = value_138.w;
    uint4 value_139 = (r3.wwww & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r3.w, r3.w, l(0x3f800000)
    r3.w = value_139.w;
    uint4 value_140 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r4.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_140.xyz;
    uint4 value_141 = asuint(mad(asfloat(r3.wwww), asfloat(r5.xyzx), asfloat(r4.xyzx))); // mad r4.xyz, r3.wwww, r5.xyzx, r4.xyzx
    r4.xyz = value_141.xyz;
    uint4 value_142 = asuint(int4(asfloat(r3.xxxx))); // ftoi r3.w, r3.x
    r3.w = value_142.w;
    uint4 value_143 = asuint(trunc(asfloat(r3.xxxx))); // round_z r3.x, r3.x
    r3.x = value_143.x;
    uint4 value_144 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r3.xxxx), asfloat(r1.wwww))); // mad r5.y, cb0[2].y, r3.x, r1.w
    r5.y = value_144.y;
    uint4 value_145 = (asuint(-asint(r3.wwww)) * r3.zzzz + r3.yyyy); // imad r1.w, -r3.w, r3.z, r3.y
    r1.w = value_145.w;
    uint4 value_146 = asuint(float4(r1.wwww)); // utof r1.w, r1.w
    r1.w = value_146.w;
    uint4 value_147 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r1.wwww), asfloat(r1.zzzz))); // mad r5.x, cb0[2].x, r1.w, r1.z
    r5.x = value_147.x;
    uint4 value_148 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r3.xyzw = value_148.xyzw;
    uint4 value_149 = ((asfloat(r5.yyyy) >= asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.z, r5.y, l(1.000000)
    r1.z = value_149.z;
    uint4 value_150 = (r1.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.z, r1.z, l(0x3f800000)
    r1.z = value_150.z;
    uint4 value_151 = asuint(asfloat(asuint(-asfloat(r3.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r5.xyz, -r3.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r5.xyz = value_151.xyz;
    uint4 value_152 = asuint(mad(asfloat(r1.zzzz), asfloat(r5.xyzx), asfloat(r3.xyzx))); // mad r3.xyz, r1.zzzz, r5.xyzx, r3.xyzx
    r3.xyz = value_152.xyz;
    uint4 value_153 = asuint(asfloat(asuint(-asfloat(r3.xyzw))) + asfloat(r4.xyzw)); // add r4.xyzw, -r3.xyzw, r4.xyzw
    r4.xyzw = value_153.xyzw;
    uint4 value_154 = asuint(mad(asfloat(r1.yyyy), asfloat(r4.xyzw), asfloat(r3.xyzw))); // mad r3.xyzw, r1.yyyy, r4.xyzw, r3.xyzw
    r3.xyzw = value_154.xyzw;
    uint4 value_155 = asuint(asfloat(r3.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r3.xyzw, r3.xyzw, -cb0[9].xyzw
    r3.xyzw = value_155.xyzw;
    uint4 value_156 = asuint(mad(asfloat(r1.xxxx), asfloat(r3.xyzw), asfloat(cb0[9].xyzw))); // mad r1.xyzw, r1.xxxx, r3.xyzw, cb0[9].xyzw
    r1.xyzw = value_156.xyzw;
    uint4 value_157 = asuint(asfloat(r1.xyzw) * asfloat(r2.xyzw)); // mul r3.xyzw, r1.xyzw, r2.xyzw
    r3.xyzw = value_157.xyzw;
    uint4 value_158 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_158.w;
    uint4 value_159 = r3.wwww; // mov o4.w, r3.w
    out_o4.w = value_159.w;
    uint4 value_160 = asuint(mad(asfloat(r2.xyzx), asfloat(r1.xyzx), asfloat(asuint(-asfloat(r1.wwww))))); // mad r1.xyz, r2.xyzx, r1.xyzx, -r1.wwww
    r1.xyz = value_160.xyz;
    uint4 value_161 = asuint(asfloat(cb0[5].wwww) + asfloat(cb0[6].wwww)); // add r2.x, cb0[5].w, cb0[6].w
    r2.x = value_161.x;
    uint4 value_162 = asuint(saturate(asfloat(asuint(asfloat(r2.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)))))); // mul_sat r2.x, r2.x, l(0.500000)
    r2.x = value_162.x;
    uint4 value_163 = asuint(asfloat(r2.xxxx) * asfloat(cb0[29].xxxx)); // mul r2.x, r2.x, cb0[29].x
    r2.x = value_163.x;
    uint4 value_164 = asuint(mad(asfloat(r2.xxxx), asfloat(r1.xyzx), asfloat(r1.wwww))); // mad o4.xyz, r2.xxxx, r1.xyzx, r1.wwww
    out_o4.xyz = value_164.xyz;
    uint4 value_165 = asuint(asfloat(r0.yyyy) * asfloat(cb0[31].xyzx)); // mul r1.xyz, r0.yyyy, cb0[31].xyzx
    r1.xyz = value_165.xyz;
    uint4 value_166 = asuint(mad(asfloat(cb0[30].xyzx), asfloat(r0.xxxx), asfloat(r1.xyzx))); // mad r1.xyz, cb0[30].xyzx, r0.xxxx, r1.xyzx
    r1.xyz = value_166.xyz;
    uint4 value_167 = asuint(mad(asfloat(cb0[32].xyzx), asfloat(r0.zzzz), asfloat(r1.xyzx))); // mad r0.xyz, cb0[32].xyzx, r0.zzzz, r1.xyzx
    r0.xyz = value_167.xyz;
    uint4 value_168 = asuint(asfloat(r0.xyzx) + asfloat(cb0[33].xyzx)); // add r0.xyz, r0.xyzx, cb0[33].xyzx
    r0.xyz = value_168.xyz;
    uint4 value_169 = r0.xyxx; // mov o5.xy, r0.xyxx
    out_o5.xy = value_169.xy;
    uint4 value_170 = asuint(asfloat(r0.wwww) * asfloat(cb0[38].yyyy)); // mul r0.x, r0.w, cb0[38].y
    r0.x = value_170.x;
    uint4 value_171 = asuint(saturate(asfloat(r0.wwww))); // mov_sat r0.w, r0.w
    r0.w = value_171.w;
    uint4 value_172 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -r0.w, l(1.000000)
    r0.y = value_172.y;
    uint4 value_173 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(uint4(0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu, 0x3d4ccccdu)), asfloat(r0.zzzz))); // mad r0.x, -r0.x, l(0.050000), r0.z
    r0.x = value_173.x;
    uint4 value_174 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0xbb808081u, 0xbb808081u, 0xbb808081u, 0xbb808081u))); // add o5.z, r0.x, l(-0.003922)
    out_o5.z = value_174.z;
    uint4 value_175 = asuint(asfloat(r0.yyyy) * asfloat(r0.yyyy)); // mul r0.x, r0.y, r0.y
    r0.x = value_175.x;
    uint4 value_176 = asuint(mad(asfloat(asuint(-asfloat(r0.yyyy))), asfloat(r0.xxxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad o5.w, -r0.y, r0.x, l(1.000000)
    out_o5.w = value_176.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xy);
    result.o1_1 = asfloat(out_o1.zw);
    result.o2_0 = asfloat(out_o2.xy);
    result.o3_0 = asfloat(out_o3.xyzw);
    result.o4_0 = asfloat(out_o4.xyzw);
    result.o5_0 = asfloat(out_o5.xyzw);
    return result;
}
