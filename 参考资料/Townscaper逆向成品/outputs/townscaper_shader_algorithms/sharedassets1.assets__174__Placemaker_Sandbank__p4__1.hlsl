// Register-explicit recovered HLSL. Not original source.
// Placemaker/Sandbank ps_4_0 variant []
// Source SHA256 896e5db2461d692a3703447db63f1f50611f163157267edd66580d80516ead0e
// b0: $Globals 688 bytes
// cb0[5].x = _SunColor rows=1 cols=4 byte_offset=80
// cb0[6].x = _ShadowColor rows=1 cols=4 byte_offset=96
// cb0[8].x = _BgColor rows=1 cols=4 byte_offset=128
// cb0[12].x = _HouseTex_TexelSize rows=1 cols=4 byte_offset=192
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[39].x = _ShadowTex_TexelSize rows=1 cols=4 byte_offset=624
// t0 / s0 = _HouseTex
// t1 / s1 = _ShadowTex
cbuffer Buffer0:register(b0) { uint4 cb0[40]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 6
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float2 v1_0: TEXCOORD2;
    float2 v1_1: TEXCOORD3;
    float2 v2_0: TEXCOORD4;
    float4 v3_0: SV_POSITION;
    float4 v4_0: COLOR0;
    float4 v5_0: COLOR1;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 r3;
    uint4 r4;
    uint4 r5;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    uint4 v4;
    uint4 v5;
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xy = asuint(input.v1_0);
    v1.zw = asuint(input.v1_1);
    v2.xy = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    v4.xyzw = asuint(input.v4_0);
    v5.xyzw = asuint(input.v5_0);
    uint4 value_1 = asuint(ddx(asfloat(v0.zzzz))); // deriv_rtx r0.x, v0.z
    r0.x = value_1.x;
    uint4 value_2 = asuint(ddy(asfloat(v0.zzzz))); // deriv_rty r0.y, v0.z
    r0.y = value_2.y;
    uint4 value_3 = asuint(asfloat(asuint(abs(asfloat(r0.yyyy)))) + asfloat(asuint(abs(asfloat(r0.xxxx))))); // add r0.x, |r0.y|, |r0.x|
    r0.x = value_3.x;
    uint4 value_4 = asuint(asfloat(r0.xxxx) + asfloat(v0.zzzz)); // add r0.y, r0.x, v0.z
    r0.y = value_4.y;
    uint4 value_5 = ((asfloat(r0.yyyy) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.y, r0.y, l(0.000000)
    r0.y = value_5.y;
    if (r0.yyyy.x != 0u) discard; // discard_nz r0.y
    uint4 value_7 = asuint(asfloat(v5.xxyx) * asfloat(cb0[39].zzwz)); // mul r0.yz, v5.xxyx, cb0[39].zzwz
    r0.yz = value_7.yz;
    uint4 value_8 = asuint(asfloat(r0.yyyz) * asfloat(cb0[39].xxxy)); // mul r1.zw, r0.yyyz, cb0[39].xxxy
    r1.zw = value_8.zw;
    uint4 value_9 = asuint(mad(asfloat(r0.yzyy), asfloat(cb0[39].xyxx), asfloat(cb0[39].xyxx))); // mad r1.xy, r0.yzyy, cb0[39].xyxx, cb0[39].xyxx
    r1.xy = value_9.xy;
    uint4 value_10 = asuint(frac(asfloat(r0.yyzy))); // frc r0.yz, r0.yyzy
    r0.yz = value_10.yz;
    uint4 value_11 = asuint(t1.SampleLevel(s1, asfloat(r1.zyzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r1.zyzz, t1.xyzw, s1, l(0.000000)
    r2.xyzw = value_11.xyzw;
    uint4 value_12 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(v5.zzzz)); // add r2.xyz, -r2.xyzx, v5.zzzz
    r2.xyz = value_12.xyz;
    uint4 value_13 = asuint(asfloat(cb0[38].xxxx) * asfloat(uint4(0x41a00000u, 0x41a00000u, 0x41a00000u, 0x41a00000u))); // mul r0.w, cb0[38].x, l(20.000000)
    r0.w = value_13.w;
    uint4 value_14 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r2.xyzx))))); // mul_sat r2.xyz, r0.wwww, r2.xyzx
    r2.xyz = value_14.xyz;
    uint4 value_15 = asuint(asfloat(asuint(-asfloat(r0.yzyy))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r3.xy, -r0.yzyy, l(1.000000, 1.000000, 0.000000, 0.000000)
    r3.xy = value_15.xy;
    uint4 value_16 = asuint(asfloat(r2.xyzx) * asfloat(r3.xxxx)); // mul r2.xyz, r2.xyzx, r3.xxxx
    r2.xyz = value_16.xyz;
    uint4 value_17 = asuint(asfloat(r0.zzzz) * asfloat(r2.xyzx)); // mul r2.xyz, r0.zzzz, r2.xyzx
    r2.xyz = value_17.xyz;
    uint4 value_18 = asuint(t1.SampleLevel(s1, asfloat(r1.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r1.zwzz, t1.xyzw, s1, l(0.000000)
    r4.xyzw = value_18.xyzw;
    uint4 value_19 = asuint(t1.SampleLevel(s1, asfloat(r1.xwxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r1.xwxx, t1.xyzw, s1, l(0.000000)
    r5.xyzw = value_19.xyzw;
    uint4 value_20 = asuint(t1.SampleLevel(s1, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r1.xyzw, r1.xyxx, t1.xyzw, s1, l(0.000000)
    r1.xyzw = value_20.xyzw;
    uint4 value_21 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(v5.zzzz)); // add r1.xyz, -r1.xyzx, v5.zzzz
    r1.xyz = value_21.xyz;
    uint4 value_22 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r1.xyzx))))); // mul_sat r1.xyz, r0.wwww, r1.xyzx
    r1.xyz = value_22.xyz;
    uint4 value_23 = asuint(asfloat(r0.yyyy) * asfloat(r1.xyzx)); // mul r1.xyz, r0.yyyy, r1.xyzx
    r1.xyz = value_23.xyz;
    uint4 value_24 = asuint(asfloat(asuint(-asfloat(r5.xyzx))) + asfloat(v5.zzzz)); // add r5.xyz, -r5.xyzx, v5.zzzz
    r5.xyz = value_24.xyz;
    uint4 value_25 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r5.xyzx))))); // mul_sat r5.xyz, r0.wwww, r5.xyzx
    r5.xyz = value_25.xyz;
    uint4 value_26 = asuint(asfloat(r0.yyyy) * asfloat(r5.xyzx)); // mul r5.xyz, r0.yyyy, r5.xyzx
    r5.xyz = value_26.xyz;
    uint4 value_27 = asuint(asfloat(asuint(-asfloat(r4.xyzx))) + asfloat(v5.zzzz)); // add r4.xyz, -r4.xyzx, v5.zzzz
    r4.xyz = value_27.xyz;
    uint4 value_28 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(r4.xyzx))))); // mul_sat r4.xyz, r0.wwww, r4.xyzx
    r4.xyz = value_28.xyz;
    uint4 value_29 = asuint(asfloat(r3.xxxx) * asfloat(r4.xxyz)); // mul r3.xzw, r3.xxxx, r4.xxyz
    r3.xzw = value_29.xzw;
    uint4 value_30 = asuint(mad(asfloat(r3.xzwx), asfloat(r3.yyyy), asfloat(r2.xyzx))); // mad r2.xyz, r3.xzwx, r3.yyyy, r2.xyzx
    r2.xyz = value_30.xyz;
    uint4 value_31 = asuint(mad(asfloat(r5.xyzx), asfloat(r3.yyyy), asfloat(r2.xyzx))); // mad r2.xyz, r5.xyzx, r3.yyyy, r2.xyzx
    r2.xyz = value_31.xyz;
    uint4 value_32 = asuint(mad(asfloat(r1.xxyz), asfloat(r0.zzzz), asfloat(r2.xxyz))); // mad r0.yzw, r1.xxyz, r0.zzzz, r2.xxyz
    r0.yzw = value_32.yzw;
    uint4 value_33 = asuint(dot(asfloat(r0.yzwy).xyz, asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3e99999au, 0x0u)).xyz)).xxxx; // dp3 r0.y, r0.yzwy, l(0.350000, 0.350000, 0.300000, 0.000000)
    r0.y = value_33.y;
    uint4 value_34 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.y, -r0.y, l(1.000000)
    r0.y = value_34.y;
    uint4 value_35 = asuint(asfloat(r0.yyyy) * asfloat(v5.wwww)); // mul r0.y, r0.y, v5.w
    r0.y = value_35.y;
    uint4 value_36 = asuint(asfloat(r0.yyyy) * asfloat(cb0[5].wwww)); // mul r0.y, r0.y, cb0[5].w
    r0.y = value_36.y;
    uint4 value_37 = asuint(asfloat(cb0[6].xyzx) * asfloat(uint4(0x3fe66666u, 0x3fe66666u, 0x3fe66666u, 0x0u))); // mul r1.xyz, cb0[6].xyzx, l(1.800000, 1.800000, 1.800000, 0.000000)
    r1.xyz = value_37.xyz;
    uint4 value_38 = asuint(mad(asfloat(cb0[5].xyzx), asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x0u)), asfloat(asuint(-asfloat(r1.xyzx))))); // mad r2.xyz, cb0[5].xyzx, l(1.400000, 1.400000, 1.400000, 0.000000), -r1.xyzx
    r2.xyz = value_38.xyz;
    uint4 value_39 = asuint(mad(asfloat(r0.yyyy), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r0.yyyy, r2.xyzx, r1.xyzx
    r1.xyz = value_39.xyz;
    uint4 value_40 = asuint(asfloat(r0.yyyy) * asfloat(cb0[5].xyzx)); // mul r2.xyz, r0.yyyy, cb0[5].xyzx
    r2.xyz = value_40.xyz;
    uint4 value_41 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.400000, 0.400000, 0.400000, 0.000000)
    r2.xyz = value_41.xyz;
    uint4 value_42 = asuint(mad(asfloat(v4.xyzx), asfloat(r1.xyzx), asfloat(r2.xyzx))); // mad r1.xyz, v4.xyzx, r1.xyzx, r2.xyzx
    r1.xyz = value_42.xyz;
    uint4 value_43 = asuint(asfloat(r1.xyzx) + asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u))); // add r1.xyz, r1.xyzx, l(0.100000, 0.100000, 0.100000, 0.000000)
    r1.xyz = value_43.xyz;
    uint4 value_44 = asuint(asfloat(cb0[5].wwww) + asfloat(asuint(-asfloat(cb0[6].wwww)))); // add r0.z, cb0[5].w, -cb0[6].w
    r0.z = value_44.z;
    uint4 value_45 = asuint(mad(asfloat(r0.yyyy), asfloat(r0.zzzz), asfloat(cb0[6].wwww))); // mad r0.y, r0.y, r0.z, cb0[6].w
    r0.y = value_45.y;
    uint4 value_46 = asuint(asfloat(v0.xxxy) * asfloat(cb0[12].zzzw)); // mul r0.zw, v0.xxxy, cb0[12].zzzw
    r0.zw = value_46.zw;
    uint4 value_47 = asuint(ddx(asfloat(r0.zwzz))); // deriv_rtx r2.xy, r0.zwzz
    r2.xy = value_47.xy;
    uint4 value_48 = asuint(ddy(asfloat(r0.zzzw))); // deriv_rty r2.zw, r0.zzzw
    r2.zw = value_48.zw;
    uint4 value_49 = asuint(dot(asfloat(r2.xzxx).xy, asfloat(r2.xzxx).xy)).xxxx; // dp2 r0.z, r2.xzxx, r2.xzxx
    r0.z = value_49.z;
    uint4 value_50 = asuint(dot(asfloat(r2.ywyy).xy, asfloat(r2.ywyy).xy)).xxxx; // dp2 r0.w, r2.ywyy, r2.ywyy
    r0.w = value_50.w;
    uint4 value_51 = asuint(sqrt(asfloat(r0.zwzz))); // sqrt r2.xy, r0.zwzz
    r2.xy = value_51.xy;
    uint4 value_52 = asuint(max(asfloat(r2.xxxy), asfloat(uint4(0x0u, 0x0u, 0x3727c5acu, 0x3727c5acu)))); // max r0.zw, r2.xxxy, l(0.000000, 0.000000, 0.000010, 0.000010)
    r0.zw = value_52.zw;
    uint4 value_53 = asuint(min(asfloat(r0.zzzw), asfloat(uint4(0x0u, 0x0u, 0x47c35000u, 0x47c35000u)))); // min r0.zw, r0.zzzw, l(0.000000, 0.000000, 100000.000000, 100000.000000)
    r0.zw = value_53.zw;
    uint4 value_54 = asuint(mad(asfloat(v0.xyxy), asfloat(cb0[12].zwzw), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3f000000u, 0x3f000000u)))); // mad r2.xyzw, v0.xyxy, cb0[12].zwzw, l(1.500000, 1.500000, 0.500000, 0.500000)
    r2.xyzw = value_54.xyzw;
    uint4 value_55 = asuint(asfloat(r2.xyzw) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r2.xyzw, r2.xyzw, l(0.500000, 0.500000, 0.500000, 0.500000)
    r2.xyzw = value_55.xyzw;
    uint4 value_56 = asuint(frac(asfloat(r2.xyxx))); // frc r3.xy, r2.xyxx
    r3.xy = value_56.xy;
    uint4 value_57 = asuint(floor(asfloat(r2.xyzw))); // round_ni r2.xyzw, r2.xyzw
    r2.xyzw = value_57.xyzw;
    uint4 value_58 = asuint(mad(asfloat(r2.xyzw), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf000000u, 0xbf000000u, 0x3f000000u, 0x3f000000u)))); // mad r2.xyzw, r2.xyzw, l(2.000000, 2.000000, 2.000000, 2.000000), l(-0.500000, -0.500000, 0.500000, 0.500000)
    r2.xyzw = value_58.xyzw;
    uint4 value_59 = asuint(mad(asfloat(r3.xyxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x0u, 0x0u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0x0u, 0x0u)))); // mad r3.xy, r3.xyxx, l(2.000000, 2.000000, 0.000000, 0.000000), l(-1.000000, -1.000000, 0.000000, 0.000000)
    r3.xy = value_59.xy;
    uint4 value_60 = asuint(asfloat(asuint(abs(asfloat(r3.xxxy)))) / asfloat(r0.zzzw)); // div r0.zw, |r3.xxxy|, r0.zzzw
    r0.zw = value_60.zw;
    uint4 value_61 = asuint(ddx(asfloat(v1.xyxx))); // deriv_rtx r3.xy, v1.xyxx
    r3.xy = value_61.xy;
    uint4 value_62 = asuint(ddy(asfloat(v1.xxxy))); // deriv_rty r3.zw, v1.xxxy
    r3.zw = value_62.zw;
    uint4 value_63 = asuint(asfloat(asuint(abs(asfloat(r3.zwzz)))) + asfloat(asuint(abs(asfloat(r3.xyxx))))); // add r3.xy, |r3.zwzz|, |r3.xyxx|
    r3.xy = value_63.xy;
    uint4 value_64 = asuint(asfloat(r3.yyyy) + asfloat(r3.xxxx)); // add r1.w, r3.y, r3.x
    r1.w = value_64.w;
    uint4 value_65 = asuint(asfloat(uint4(0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u)) / asfloat(r1.wwww)); // div r1.w, l(0.003000), r1.w
    r1.w = value_65.w;
    uint4 value_66 = asuint(asfloat(r0.zzzw) + asfloat(asuint(-asfloat(r1.wwww)))); // add r0.zw, r0.zzzw, -r1.wwww
    r0.zw = value_66.zw;
    uint4 value_67 = asuint(asfloat(cb0[19].zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r1.w, cb0[19].z, l(-1.000000)
    r1.w = value_67.w;
    uint4 value_68 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x0u, 0x0u, 0x3f000000u, 0x3f000000u)), asfloat(r0.zzzw)))))); // mad_sat r0.zw, -r1.wwww, l(0.000000, 0.000000, 0.500000, 0.500000), r0.zzzw
    r0.zw = value_68.zw;
    uint4 value_69 = asuint(asfloat(asuint(-asfloat(r2.xxxy))) + asfloat(r2.zzzw)); // add r2.zw, -r2.xxxy, r2.zzzw
    r2.zw = value_69.zw;
    uint4 value_70 = asuint(mad(asfloat(r0.zzzw), asfloat(r2.zzzw), asfloat(r2.xxxy))); // mad r0.zw, r0.zzzw, r2.zzzw, r2.xxxy
    r0.zw = value_70.zw;
    uint4 value_71 = asuint(asfloat(r0.zzzw) * asfloat(cb0[12].xxxy)); // mul r0.zw, r0.zzzw, cb0[12].xxxy
    r0.zw = value_71.zw;
    uint4 value_72 = asuint(t0.Sample(s0, asfloat(r0.zwzz).xy)).xyzw; // sample r2.xyzw, r0.zwzz, t0.xyzw, s0
    r2.xyzw = value_72.xyzw;
    uint4 value_73 = asuint(asfloat(r2.xyzx) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0x0u))); // add r2.xyz, r2.xyzx, l(-1.000000, -1.000000, -1.000000, 0.000000)
    r2.xyz = value_73.xyz;
    uint4 value_74 = asuint(asfloat(v0.zzzz) + asfloat(uint4(0xbb03126fu, 0xbb03126fu, 0xbb03126fu, 0xbb03126fu))); // add r0.z, v0.z, l(-0.002000)
    r0.z = value_74.z;
    uint4 value_75 = asuint(asfloat(r0.zzzz) / asfloat(r0.xxxx)); // div r0.x, r0.z, r0.x
    r0.x = value_75.x;
    uint4 value_76 = asuint(saturate(asfloat(asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r0.xxxx))))); // add_sat r0.x, -r1.w, r0.x
    r0.x = value_76.x;
    uint4 value_77 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xxyz), asfloat(uint4(0x3e99999au, 0x0u, 0x3e99999au, 0x3e99999au)))); // mad r0.xzw, r0.xxxx, r2.xxyz, l(0.300000, 0.000000, 0.300000, 0.300000)
    r0.xzw = value_77.xzw;
    uint4 value_78 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r0.xxzw), asfloat(uint4(0x3f333333u, 0x0u, 0x3f333333u, 0x3f333333u)))); // mad r0.xzw, cb0[29].xxxx, r0.xxzw, l(0.700000, 0.000000, 0.700000, 0.700000)
    r0.xzw = value_78.xzw;
    uint4 value_79 = asuint(dot(asfloat(r0.xzwx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r0.xzwx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_79.w;
    uint4 value_80 = asuint(asfloat(r0.xzwx) + asfloat(asuint(-asfloat(r1.wwww)))); // add r2.xyz, r0.xzwx, -r1.wwww
    r2.xyz = value_80.xyz;
    uint4 value_81 = asuint(mad(asfloat(r0.yyyy), asfloat(r2.xyzx), asfloat(r1.wwww))); // mad r2.xyz, r0.yyyy, r2.xyzx, r1.wwww
    r2.xyz = value_81.xyz;
    uint4 value_82 = asuint(asfloat(r1.xyzx) * asfloat(r2.xyzx)); // mul r1.xyz, r1.xyzx, r2.xyzx
    r1.xyz = value_82.xyz;
    uint4 value_83 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.y, r1.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.y = value_83.y;
    uint4 value_84 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r1.w, -r0.y, l(0.600000)
    r1.w = value_84.w;
    uint4 value_85 = asuint(asfloat(r0.yyyy) + asfloat(asuint(-asfloat(r1.wwww)))); // add r0.y, r0.y, -r1.w
    r0.y = value_85.y;
    uint4 value_86 = asuint(mad(asfloat(r0.yyyy), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r0.yyyy, l(0.100000, 0.100000, 0.100000, 0.000000), r1.xyzx
    r1.xyz = value_86.xyz;
    uint4 value_87 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r1.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_87.xyz;
    uint4 value_88 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r1.xyzx
    r1.xyz = value_88.xyz;
    uint4 value_89 = asuint(asfloat(asuint(-asfloat(r0.xzwx))) + asfloat(r1.xyzx)); // add r1.xyz, -r0.xzwx, r1.xyzx
    r1.xyz = value_89.xyz;
    uint4 value_90 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r1.xyzx), asfloat(r0.xzwx))); // mad r0.xyz, cb0[29].yyyy, r1.xyzx, r0.xzwx
    r0.xyz = value_90.xyz;
    uint4 value_91 = asuint(asfloat(asuint(-asfloat(cb0[8].xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r1.xyz, -cb0[8].xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r1.xyz = value_91.xyz;
    uint4 value_92 = asuint(mad(asfloat(v2.yyyy), asfloat(r1.xyzx), asfloat(cb0[8].xyzx))); // mad r1.xyz, v2.yyyy, r1.xyzx, cb0[8].xyzx
    r1.xyz = value_92.xyz;
    uint4 value_93 = asuint(asfloat(r1.xyzx) + asfloat(uint4(0xbf000000u, 0xbf266666u, 0xbf333333u, 0x0u))); // add r1.xyz, r1.xyzx, l(-0.500000, -0.650000, -0.700000, 0.000000)
    r1.xyz = value_93.xyz;
    uint4 value_94 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r1.xyzx), asfloat(uint4(0x0u, 0x3e199998u, 0x3e4cccccu, 0x0u)))); // mad r2.xyz, cb0[29].yyyy, r1.xyzx, l(0.000000, 0.150000, 0.200000, 0.000000)
    r2.xyz = value_94.xyz;
    uint4 value_95 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r1.xyzx), asfloat(uint4(0x3f000000u, 0x3f266666u, 0x3f333333u, 0x0u)))); // mad r1.xyz, cb0[29].yyyy, r1.xyzx, l(0.500000, 0.650000, 0.700000, 0.000000)
    r1.xyz = value_95.xyz;
    uint4 value_96 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r2.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), r0.xyzx
    r0.xyz = value_96.xyz;
    uint4 value_97 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(r1.xyzx)); // add r1.xyz, -r0.xyzx, r1.xyzx
    r1.xyz = value_97.xyz;
    uint4 value_98 = asuint(asfloat(v2.xxxx) * asfloat(v2.xxxx)); // mul r0.w, v2.x, v2.x
    r0.w = value_98.w;
    uint4 value_99 = asuint(mad(asfloat(r0.wwww), asfloat(r1.xyzx), asfloat(r0.xyzx))); // mad o0.xyz, r0.wwww, r1.xyzx, r0.xyzx
    out_o0.xyz = value_99.xyz;
    uint4 value_100 = asuint(saturate(asfloat(asuint(mad(asfloat(v2.xxxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))))))); // mad_sat r0.x, v2.x, l(2.000000), l(-1.000000)
    r0.x = value_100.x;
    uint4 value_101 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0xc0800000u, 0xc0800000u, 0xc0800000u, 0xc0800000u)), asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u)))); // mad r0.x, r0.x, l(-4.000000), l(4.000000)
    r0.x = value_101.x;
    uint4 value_102 = asuint(min(asfloat(r0.xxxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // min o0.w, r0.x, l(1.000000)
    out_o0.w = value_102.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
