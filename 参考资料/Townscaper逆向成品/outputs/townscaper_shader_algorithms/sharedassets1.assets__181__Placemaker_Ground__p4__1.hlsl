// Register-explicit recovered HLSL. Not original source.
// Placemaker/Ground ps_4_0 variant []
// Source SHA256 0bc9f8fada37ac668959dadc35c1b4a059c1079e8d015403dfdbdad89c55c814
// b0: $Globals 688 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[40].x = _MainTex_TexelSize rows=1 cols=4 byte_offset=640
// t0 / s1 = _MainTex
// t1 / s0 = _AoTex
cbuffer Buffer0:register(b0) { uint4 cb0[41]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 4
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float2 v1_0: TEXCOORD2;
    float4 v2_0: SV_POSITION;
    float4 v3_0: COLOR0;
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
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xy = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(asfloat(cb0[2].xyxx) + asfloat(asuint(-asfloat(cb0[7].xyxx)))); // add r0.xy, cb0[2].xyxx, -cb0[7].xyxx
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(max(asfloat(v0.zzzw), asfloat(cb0[7].xxxy))); // max r0.zw, v0.zzzw, cb0[7].xxxy
    r0.zw = value_2.zw;
    uint4 value_3 = asuint(min(asfloat(r0.xyxx), asfloat(r0.zwzz))); // min r0.xy, r0.xyxx, r0.zwzz
    r0.xy = value_3.xy;
    uint4 value_4 = asuint(t1.SampleLevel(s0, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t1.xyzw, s0, l(0.000000)
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(saturate(asfloat(asuint(asfloat(r0.wwww) * asfloat(uint4(0x3f8ccccdu, 0x3f8ccccdu, 0x3f8ccccdu, 0x3f8ccccdu)))))); // mul_sat r0.x, r0.w, l(1.100000)
    r0.x = value_5.x;
    uint4 value_6 = asuint(asfloat(r0.xxxx) * asfloat(r0.xxxx)); // mul r0.x, r0.x, r0.x
    r0.x = value_6.x;
    uint4 value_7 = asuint(asfloat(asuint(-asfloat(asuint(abs(asfloat(v1.xxyx)))))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r0.yz, -|v1.xxyx|, l(0.000000, 1.000000, 1.000000, 0.000000)
    r0.yz = value_7.yz;
    uint4 value_8 = asuint(asfloat(r0.xzxx) * asfloat(r0.xyxx)); // mul r0.xy, r0.xzxx, r0.xyxx
    r0.xy = value_8.xy;
    uint4 value_9 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.x, r0.y, r0.x
    r0.x = value_9.x;
    uint4 value_10 = asuint(asfloat(v0.xxyx) * asfloat(cb0[40].zzwz)); // mul r0.yz, v0.xxyx, cb0[40].zzwz
    r0.yz = value_10.yz;
    uint4 value_11 = asuint(asfloat(r0.yzyy) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x0u, 0x0u))); // mul r1.xy, r0.yzyy, l(0.500000, 0.500000, 0.000000, 0.000000)
    r1.xy = value_11.xy;
    uint4 value_12 = asuint(mad(asfloat(r0.yyzy), asfloat(uint4(0x0u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(uint4(0x0u, 0x3f400000u, 0x3f400000u, 0x0u)))); // mad r0.yz, r0.yyzy, l(0.000000, 0.500000, 0.500000, 0.000000), l(0.000000, 0.750000, 0.750000, 0.000000)
    r0.yz = value_12.yz;
    uint4 value_13 = asuint(ddx(asfloat(r1.xyxx))); // deriv_rtx r2.xy, r1.xyxx
    r2.xy = value_13.xy;
    uint4 value_14 = asuint(ddy(asfloat(r1.xxxy))); // deriv_rty r2.zw, r1.xxxy
    r2.zw = value_14.zw;
    uint4 value_15 = asuint(dot(asfloat(r2.xzxx).xy, asfloat(r2.xzxx).xy)).xxxx; // dp2 r0.w, r2.xzxx, r2.xzxx
    r0.w = value_15.w;
    uint4 value_16 = asuint(dot(asfloat(r2.ywyy).xy, asfloat(r2.ywyy).xy)).xxxx; // dp2 r1.x, r2.ywyy, r2.ywyy
    r1.x = value_16.x;
    uint4 value_17 = asuint(sqrt(asfloat(r1.xxxx))); // sqrt r1.y, r1.x
    r1.y = value_17.y;
    uint4 value_18 = asuint(sqrt(asfloat(r0.wwww))); // sqrt r1.x, r0.w
    r1.x = value_18.x;
    uint4 value_19 = asuint(asfloat(r1.xyxx) + asfloat(r1.xyxx)); // add r1.xy, r1.xyxx, r1.xyxx
    r1.xy = value_19.xy;
    uint4 value_20 = asuint(frac(asfloat(r0.yyyz))); // frc r1.zw, r0.yyyz
    r1.zw = value_20.zw;
    uint4 value_21 = asuint(floor(asfloat(r0.yyzy))); // round_ni r0.yz, r0.yyzy
    r0.yz = value_21.yz;
    uint4 value_22 = asuint(asfloat(r1.zzzw) + asfloat(uint4(0x0u, 0x0u, 0xbf000000u, 0xbf000000u))); // add r1.zw, r1.zzzw, l(0.000000, 0.000000, -0.500000, -0.500000)
    r1.zw = value_22.zw;
    uint4 value_23 = asuint(asfloat(r1.zwzz) / asfloat(r1.xyxx)); // div r1.xy, r1.zwzz, r1.xyxx
    r1.xy = value_23.xy;
    uint4 value_24 = asuint(saturate(asfloat(asuint(asfloat(r1.xyxx) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x0u, 0x0u)))))); // add_sat r1.xy, r1.xyxx, l(0.500000, 0.500000, 0.000000, 0.000000)
    r1.xy = value_24.xy;
    uint4 value_25 = asuint(asfloat(r0.yyzy) + asfloat(r1.xxyx)); // add r0.yz, r0.yyzy, r1.xxyx
    r0.yz = value_25.yz;
    uint4 value_26 = asuint(asfloat(r0.yyzy) + asfloat(uint4(0x0u, 0xbf400000u, 0xbf400000u, 0x0u))); // add r0.yz, r0.yyzy, l(0.000000, -0.750000, -0.750000, 0.000000)
    r0.yz = value_26.yz;
    uint4 value_27 = asuint(asfloat(r0.yyzy) * asfloat(cb0[40].xxyx)); // mul r0.yz, r0.yyzy, cb0[40].xxyx
    r0.yz = value_27.yz;
    uint4 value_28 = asuint(asfloat(r0.yyzy) + asfloat(r0.yyzy)); // add r0.yz, r0.yyzy, r0.yyzy
    r0.yz = value_28.yz;
    uint4 value_29 = asuint(t0.Sample(s1, asfloat(r0.yzyy).xy)).xyzw; // sample r1.xyzw, r0.yzyy, t0.xyzw, s1
    r1.xyzw = value_29.xyzw;
    uint4 value_30 = asuint(saturate(asfloat(asuint(asfloat(r1.xyzw) + asfloat(r1.xyzw))))); // add_sat r1.xyzw, r1.xyzw, r1.xyzw
    r1.xyzw = value_30.xyzw;
    uint4 value_31 = asuint(asfloat(asuint(-asfloat(r1.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.yzw, -r1.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r0.yzw = value_31.yzw;
    uint4 value_32 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yzwy), asfloat(r1.xyzx))); // mad r0.xyz, r0.xxxx, r0.yzwy, r1.xyzx
    r0.xyz = value_32.xyz;
    uint4 value_33 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0x0u))); // add r0.xyz, r0.xyzx, l(-0.700000, -0.700000, -0.700000, 0.000000)
    r0.xyz = value_33.xyz;
    uint4 value_34 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r0.xyzx), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x0u)))); // mad r0.xyz, cb0[29].xxxx, r0.xyzx, l(0.700000, 0.700000, 0.700000, 0.000000)
    r0.xyz = value_34.xyz;
    uint4 value_35 = asuint(asfloat(r0.yzxy) * asfloat(r0.xyzx)); // mul r2.xyz, r0.yzxy, r0.xyzx
    r2.xyz = value_35.xyz;
    uint4 value_36 = asuint(mad(asfloat(asuint(-asfloat(r2.xyzx))), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, -r2.xyzx, l(0.300000, 0.300000, 0.300000, 0.000000), r0.xyzx
    r0.xyz = value_36.xyz;
    uint4 value_37 = asuint(asfloat(r2.xyzx) * asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x0u))); // mul r2.xyz, r2.xyzx, l(0.300000, 0.300000, 0.300000, 0.000000)
    r2.xyz = value_37.xyz;
    uint4 value_38 = asuint(asfloat(v3.xyzx) * asfloat(uint4(0x3fa66666u, 0x3fa66666u, 0x3fa66666u, 0x0u))); // mul r3.xyz, v3.xyzx, l(1.300000, 1.300000, 1.300000, 0.000000)
    r3.xyz = value_38.xyz;
    uint4 value_39 = asuint(mad(asfloat(r3.xyzx), asfloat(r0.xyzx), asfloat(r2.xyzx))); // mad r0.xyz, r3.xyzx, r0.xyzx, r2.xyzx
    r0.xyz = value_39.xyz;
    uint4 value_40 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_40.w;
    uint4 value_41 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r2.x, -r0.w, l(0.600000)
    r2.x = value_41.x;
    uint4 value_42 = asuint(asfloat(r0.wwww) + asfloat(asuint(-asfloat(r2.xxxx)))); // add r0.w, r0.w, -r2.x
    r0.w = value_42.w;
    uint4 value_43 = asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r0.wwww, l(0.100000, 0.100000, 0.100000, 0.000000), r0.xyzx
    r0.xyz = value_43.xyz;
    uint4 value_44 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r0.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_44.xyz;
    uint4 value_45 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r0.xyzx))); // mad r1.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r0.xyzx
    r1.xyz = value_45.xyz;
    uint4 value_46 = asuint(saturate(asfloat(asuint(asfloat(r1.xyzw) * asfloat(uint4(0x3f8f5c29u, 0x3f8f5c29u, 0x3f8f5c29u, 0x3f8f5c29u)))))); // mul_sat o0.xyzw, r1.xyzw, l(1.120000, 1.120000, 1.120000, 1.120000)
    out_o0.xyzw = value_46.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
