// Register-explicit recovered HLSL. Not original source.
// Placemaker/Window ps_4_0 variant []
// Source SHA256 7f10a105addebaaa37c44b33dc67f6a66820c94a99bb1a077177d453f1bb3ebe
// b0: $Globals 688 bytes
// cb0[11].x = _RoofColor rows=1 cols=4 byte_offset=176
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb0[18].x = _Dim rows=1 cols=4 byte_offset=288
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[40].x = _MainTex_TexelSize rows=1 cols=4 byte_offset=640
// t0 / s1 = _TypeTex
// t1 / s2 = _MainTex
// t2 / s0 = _MaterialTex
cbuffer Buffer0:register(b0) { uint4 cb0[41]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
SamplerState s2:register(s2);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
Texture2D<float4> t2:register(t2);
// temporary registers: 4
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD2;
    float2 v1_0: TEXCOORD1;
    float4 v2_0: SV_POSITION;
    float4 v3_0: COLOR0;
    float4 v4_0: COLOR1;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 r3;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    uint4 v4;
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xy = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    v4.xyzw = asuint(input.v4_0);
    uint4 value_1 = asuint(ddx(asfloat(v0.zwzz))); // deriv_rtx r0.xy, v0.zwzz
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(ddy(asfloat(v0.zzzw))); // deriv_rty r0.zw, v0.zzzw
    r0.zw = value_2.zw;
    uint4 value_3 = asuint(asfloat(asuint(abs(asfloat(r0.zwzz)))) + asfloat(asuint(abs(asfloat(r0.xyxx))))); // add r0.xy, |r0.zwzz|, |r0.xyxx|
    r0.xy = value_3.xy;
    uint4 value_4 = asuint(asfloat(r0.yyyy) + asfloat(r0.xxxx)); // add r0.x, r0.y, r0.x
    r0.x = value_4.x;
    uint4 value_5 = asuint(asfloat(uint4(0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u)) / asfloat(r0.xxxx)); // div r0.x, l(0.003000), r0.x
    r0.x = value_5.x;
    uint4 value_6 = asuint(mad(asfloat(v1.xyxy), asfloat(cb0[40].xyxy), asfloat(v0.xyxy))); // mad r1.xyzw, v1.xyxy, cb0[40].xyxy, v0.xyxy
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(asfloat(r1.zzwz) * asfloat(cb0[40].zzwz)); // mul r0.yz, r1.zzwz, cb0[40].zzwz
    r0.yz = value_7.yz;
    uint4 value_8 = asuint(ddx(asfloat(r0.yzyy))); // deriv_rtx r2.xy, r0.yzyy
    r2.xy = value_8.xy;
    uint4 value_9 = asuint(ddy(asfloat(r0.yyyz))); // deriv_rty r2.zw, r0.yyyz
    r2.zw = value_9.zw;
    uint4 value_10 = asuint(dot(asfloat(r2.xzxx).xy, asfloat(r2.xzxx).xy)).xxxx; // dp2 r0.y, r2.xzxx, r2.xzxx
    r0.y = value_10.y;
    uint4 value_11 = asuint(dot(asfloat(r2.ywyy).xy, asfloat(r2.ywyy).xy)).xxxx; // dp2 r0.z, r2.ywyy, r2.ywyy
    r0.z = value_11.z;
    uint4 value_12 = asuint(sqrt(asfloat(r0.yzyy))); // sqrt r2.xy, r0.yzyy
    r2.xy = value_12.xy;
    uint4 value_13 = asuint(max(asfloat(r2.xxyx), asfloat(uint4(0x0u, 0x3727c5acu, 0x3727c5acu, 0x0u)))); // max r0.yz, r2.xxyx, l(0.000000, 0.000010, 0.000010, 0.000000)
    r0.yz = value_13.yz;
    uint4 value_14 = asuint(min(asfloat(r0.yyzy), asfloat(uint4(0x0u, 0x47c35000u, 0x47c35000u, 0x0u)))); // min r0.yz, r0.yyzy, l(0.000000, 100000.000000, 100000.000000, 0.000000)
    r0.yz = value_14.yz;
    uint4 value_15 = asuint(mad(asfloat(r1.xyzw), asfloat(cb0[40].zwzw), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3f000000u, 0x3f000000u)))); // mad r2.xyzw, r1.xyzw, cb0[40].zwzw, l(1.500000, 1.500000, 0.500000, 0.500000)
    r2.xyzw = value_15.xyzw;
    uint4 value_16 = asuint(floor(asfloat(asuint(abs(asfloat(r1.zzzz)))))); // round_ni r0.w, |r1.z|
    r0.w = value_16.w;
    uint4 value_17 = asuint(asfloat(r0.wwww) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.w, r0.w, l(0.500000)
    r0.w = value_17.w;
    uint4 value_18 = asuint(asfloat(r0.wwww) * asfloat(cb0[15].xxxx)); // mul r1.x, r0.w, cb0[15].x
    r1.x = value_18.x;
    uint4 value_19 = asuint(asfloat(r2.xyzw) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r2.xyzw, r2.xyzw, l(0.500000, 0.500000, 0.500000, 0.500000)
    r2.xyzw = value_19.xyzw;
    uint4 value_20 = asuint(frac(asfloat(r2.xxxy))); // frc r1.zw, r2.xxxy
    r1.zw = value_20.zw;
    uint4 value_21 = asuint(floor(asfloat(r2.xyzw))); // round_ni r2.xyzw, r2.xyzw
    r2.xyzw = value_21.xyzw;
    uint4 value_22 = asuint(mad(asfloat(r2.xyzw), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf000000u, 0xbf000000u, 0x3f000000u, 0x3f000000u)))); // mad r2.xyzw, r2.xyzw, l(2.000000, 2.000000, 2.000000, 2.000000), l(-0.500000, -0.500000, 0.500000, 0.500000)
    r2.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(mad(asfloat(r1.zzzw), asfloat(uint4(0x0u, 0x0u, 0x40000000u, 0x40000000u)), asfloat(uint4(0x0u, 0x0u, 0xbf800000u, 0xbf800000u)))); // mad r1.zw, r1.zzzw, l(0.000000, 0.000000, 2.000000, 2.000000), l(0.000000, 0.000000, -1.000000, -1.000000)
    r1.zw = value_23.zw;
    uint4 value_24 = asuint(asfloat(asuint(abs(asfloat(r1.zzwz)))) / asfloat(r0.yyzy)); // div r0.yz, |r1.zzwz|, r0.yyzy
    r0.yz = value_24.yz;
    uint4 value_25 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(r0.yzyy)); // add r0.xy, -r0.xxxx, r0.yzyy
    r0.xy = value_25.xy;
    uint4 value_26 = asuint(asfloat(cb0[19].zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.z, cb0[19].z, l(-1.000000)
    r0.z = value_26.z;
    uint4 value_27 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r0.zzzz))), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x0u, 0x0u)), asfloat(r0.xyxx)))))); // mad_sat r0.xy, -r0.zzzz, l(0.500000, 0.500000, 0.000000, 0.000000), r0.xyxx
    r0.xy = value_27.xy;
    uint4 value_28 = asuint(asfloat(asuint(-asfloat(r2.xxxy))) + asfloat(r2.zzzw)); // add r0.zw, -r2.xxxy, r2.zzzw
    r0.zw = value_28.zw;
    uint4 value_29 = asuint(mad(asfloat(r0.xyxx), asfloat(r0.zwzz), asfloat(r2.xyxx))); // mad r0.xy, r0.xyxx, r0.zwzz, r2.xyxx
    r0.xy = value_29.xy;
    uint4 value_30 = asuint(asfloat(r0.xyxx) * asfloat(cb0[40].xyxx)); // mul r0.xy, r0.xyxx, cb0[40].xyxx
    r0.xy = value_30.xy;
    uint4 value_31 = asuint(t0.SampleLevel(s1, asfloat(r0.xyxx).xy, asfloat(cb0[18].xxxx).x)).xyzw; // sample_l r2.xyzw, r0.xyxx, t0.xyzw, s1, cb0[18].x
    r2.xyzw = value_31.xyzw;
    uint4 value_32 = asuint(t1.SampleLevel(s2, asfloat(r0.xyxx).xy, asfloat(cb0[18].xxxx).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t1.xyzw, s2, cb0[18].x
    r0.xyzw = value_32.xyzw;
    uint4 value_33 = asuint(asfloat(r2.yyyy) * asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x3fb33333u))); // mul r1.z, r2.y, l(1.400000)
    r1.z = value_33.z;
    uint4 value_34 = uint4(0x3e800000u, 0x3e800000u, 0x3e800000u, 0x3e800000u); // mov r1.y, l(0.250000)
    r1.y = value_34.y;
    uint4 value_35 = asuint(t2.SampleLevel(s0, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r1.xyxx, t2.xyzw, s0, l(0.000000)
    r2.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(asfloat(asuint(-asfloat(r2.xyxz))) + asfloat(cb0[11].xyxz)); // add r1.xyw, -r2.xyxz, cb0[11].xyxz
    r1.xyw = value_36.xyw;
    uint4 value_37 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.zzzz), asfloat(r1.xywx), asfloat(r2.xyzx)))))); // mad_sat r2.xyz, r1.zzzz, r1.xywx, r2.xyzx
    r2.xyz = value_37.xyz;
    uint4 value_38 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.x, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.x = value_38.x;
    uint4 value_39 = asuint(asfloat(r0.wwww) + asfloat(r0.wwww)); // add r1.y, r0.w, r0.w
    r1.y = value_39.y;
    uint4 value_40 = asuint(saturate(asfloat(r1.yyyy))); // mov_sat r1.y, r1.y
    r1.y = value_40.y;
    uint4 value_41 = asuint(asfloat(r1.xxxy) + asfloat(r2.xyzw)); // add r3.xyzw, r1.xxxy, r2.xyzw
    r3.xyzw = value_41.xyzw;
    uint4 value_42 = asuint(asfloat(r3.xyzw) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r3.xyzw, r3.xyzw, l(-0.500000, -0.500000, -0.500000, -0.500000)
    r3.xyzw = value_42.xyzw;
    uint4 value_43 = asuint(max(asfloat(r3.xyzw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r3.xyzw, r3.xyzw, l(0.000000, 0.000000, 0.000000, 0.000000)
    r3.xyzw = value_43.xyzw;
    uint4 value_44 = asuint(asfloat(asuint(-asfloat(r2.xyzw))) + asfloat(r3.xyzw)); // add r3.xyzw, -r2.xyzw, r3.xyzw
    r3.xyzw = value_44.xyzw;
    uint4 value_45 = asuint(mad(asfloat(r1.yyyy), asfloat(r3.xyzw), asfloat(r2.xyzw))); // mad r2.xyzw, r1.yyyy, r3.xyzw, r2.xyzw
    r2.xyzw = value_45.xyzw;
    uint4 value_46 = asuint(saturate(asfloat(asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))))))); // mad_sat r1.x, r0.w, l(2.000000), l(-1.000000)
    r1.x = value_46.x;
    uint4 value_47 = asuint(asfloat(r1.xxxx) * asfloat(v4.wwww)); // mul r1.x, r1.x, v4.w
    r1.x = value_47.x;
    uint4 value_48 = r1.yyyy; // mov r0.w, r1.y
    r0.w = value_48.w;
    uint4 value_49 = asuint(asfloat(asuint(-asfloat(r2.xyzw))) + asfloat(r0.xyzw)); // add r0.xyzw, -r2.xyzw, r0.xyzw
    r0.xyzw = value_49.xyzw;
    uint4 value_50 = asuint(mad(asfloat(r1.yyyy), asfloat(r0.xyzw), asfloat(r2.xyzw))); // mad r0.xyzw, r1.yyyy, r0.xyzw, r2.xyzw
    r0.xyzw = value_50.xyzw;
    uint4 value_51 = asuint(asfloat(r0.xxyz) + asfloat(uint4(0x0u, 0xbf333333u, 0xbf333333u, 0xbf333333u))); // add r1.yzw, r0.xxyz, l(0.000000, -0.700000, -0.700000, -0.700000)
    r1.yzw = value_51.yzw;
    uint4 value_52 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r1.yyzw), asfloat(uint4(0x0u, 0x3f333333u, 0x3f333333u, 0x3f333333u)))); // mad r1.yzw, cb0[29].xxxx, r1.yyzw, l(0.000000, 0.700000, 0.700000, 0.700000)
    r1.yzw = value_52.yzw;
    uint4 value_53 = asuint(asfloat(r1.zwyz) * asfloat(r1.yzwy)); // mul r2.xyz, r1.zwyz, r1.yzwy
    r2.xyz = value_53.xyz;
    uint4 value_54 = asuint(mad(asfloat(asuint(-asfloat(r2.xxyz))), asfloat(uint4(0x0u, 0x3e99999au, 0x3e99999au, 0x3e99999au)), asfloat(r1.yyzw))); // mad r1.yzw, -r2.xxyz, l(0.000000, 0.300000, 0.300000, 0.300000), r1.yyzw
    r1.yzw = value_54.yzw;
    uint4 value_55 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.300000, 0.300000, 0.300000, 0.000000)
    r2.xyz = value_55.xyz;
    uint4 value_56 = asuint(asfloat(v3.xyzx) * asfloat(uint4(0x3fa66666u, 0x3fa66666u, 0x3fa66666u, 0x0u))); // mul r3.xyz, v3.xyzx, l(1.300000, 1.300000, 1.300000, 0.000000)
    r3.xyz = value_56.xyz;
    uint4 value_57 = asuint(mad(asfloat(r3.xxyz), asfloat(r1.yyzw), asfloat(r2.xxyz))); // mad r1.yzw, r3.xxyz, r1.yyzw, r2.xxyz
    r1.yzw = value_57.yzw;
    uint4 value_58 = asuint(dot(asfloat(r1.yzwy).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r2.x, r1.yzwy, l(0.200000, 0.700000, 0.100000, 0.000000)
    r2.x = value_58.x;
    uint4 value_59 = asuint(asfloat(asuint(-asfloat(r2.xxxx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r2.y, -r2.x, l(0.600000)
    r2.y = value_59.y;
    uint4 value_60 = asuint(asfloat(asuint(-asfloat(r2.yyyy))) + asfloat(r2.xxxx)); // add r2.x, -r2.y, r2.x
    r2.x = value_60.x;
    uint4 value_61 = asuint(mad(asfloat(r2.xxxx), asfloat(uint4(0x0u, 0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu)), asfloat(r1.yyzw))); // mad r1.yzw, r2.xxxx, l(0.000000, 0.100000, 0.100000, 0.100000), r1.yyzw
    r1.yzw = value_61.yzw;
    uint4 value_62 = asuint(asfloat(asuint(-asfloat(r1.yzwy))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r1.yzwy, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_62.xyz;
    uint4 value_63 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r1.yzwy))); // mad r0.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r1.yzwy
    r0.xyz = value_63.xyz;
    uint4 value_64 = asuint(asfloat(asuint(-asfloat(r0.xyzw))) + asfloat(v4.xyzw)); // add r2.xyzw, -r0.xyzw, v4.xyzw
    r2.xyzw = value_64.xyzw;
    uint4 value_65 = asuint(mad(asfloat(r1.xxxx), asfloat(r2.xyzw), asfloat(r0.xyzw))); // mad o0.xyzw, r1.xxxx, r2.xyzw, r0.xyzw
    out_o0.xyzw = value_65.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
