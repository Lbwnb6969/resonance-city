// Register-explicit recovered HLSL. Not original source.
// Placemaker/Carnival ps_4_0 variant []
// Source SHA256 073176c7630c7f9043571fa9cc23126ee0ae47daa33ec71a6f18b21482e13273
// b0: $Globals 704 bytes
// cb0[11].x = _RoofColor rows=1 cols=4 byte_offset=176
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb0[18].x = _Dim rows=1 cols=4 byte_offset=288
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[40].x = _MainTex_TexelSize rows=1 cols=4 byte_offset=640
// t0 / s1 = _MainTex
// t1 / s0 = _MaterialTex
cbuffer Buffer0:register(b0) { uint4 cb0[41]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 3
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float2 v1_0: TEXCOORD2;
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
    uint4 value_1 = asuint(asfloat(v0.xyxx) * asfloat(cb0[40].zwzz)); // mul r0.xy, v0.xyxx, cb0[40].zwzz
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(ddx(asfloat(r0.xyxx))); // deriv_rtx r1.xy, r0.xyxx
    r1.xy = value_2.xy;
    uint4 value_3 = asuint(ddy(asfloat(r0.xxxy))); // deriv_rty r1.zw, r0.xxxy
    r1.zw = value_3.zw;
    uint4 value_4 = asuint(dot(asfloat(r1.xzxx).xy, asfloat(r1.xzxx).xy)).xxxx; // dp2 r0.x, r1.xzxx, r1.xzxx
    r0.x = value_4.x;
    uint4 value_5 = asuint(dot(asfloat(r1.ywyy).xy, asfloat(r1.ywyy).xy)).xxxx; // dp2 r0.y, r1.ywyy, r1.ywyy
    r0.y = value_5.y;
    uint4 value_6 = asuint(sqrt(asfloat(r0.xyxx))); // sqrt r1.xy, r0.xyxx
    r1.xy = value_6.xy;
    uint4 value_7 = asuint(max(asfloat(r1.xyxx), asfloat(uint4(0x3727c5acu, 0x3727c5acu, 0x0u, 0x0u)))); // max r0.xy, r1.xyxx, l(0.000010, 0.000010, 0.000000, 0.000000)
    r0.xy = value_7.xy;
    uint4 value_8 = asuint(min(asfloat(r0.xyxx), asfloat(uint4(0x47c35000u, 0x47c35000u, 0x0u, 0x0u)))); // min r0.xy, r0.xyxx, l(100000.000000, 100000.000000, 0.000000, 0.000000)
    r0.xy = value_8.xy;
    uint4 value_9 = asuint(mad(asfloat(v0.xyxy), asfloat(cb0[40].zwzw), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3f000000u, 0x3f000000u)))); // mad r1.xyzw, v0.xyxy, cb0[40].zwzw, l(1.500000, 1.500000, 0.500000, 0.500000)
    r1.xyzw = value_9.xyzw;
    uint4 value_10 = asuint(asfloat(r1.xyzw) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r1.xyzw, r1.xyzw, l(0.500000, 0.500000, 0.500000, 0.500000)
    r1.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(frac(asfloat(r1.xxxy))); // frc r0.zw, r1.xxxy
    r0.zw = value_11.zw;
    uint4 value_12 = asuint(floor(asfloat(r1.xyzw))); // round_ni r1.xyzw, r1.xyzw
    r1.xyzw = value_12.xyzw;
    uint4 value_13 = asuint(mad(asfloat(r1.xyzw), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf000000u, 0xbf000000u, 0x3f000000u, 0x3f000000u)))); // mad r1.xyzw, r1.xyzw, l(2.000000, 2.000000, 2.000000, 2.000000), l(-0.500000, -0.500000, 0.500000, 0.500000)
    r1.xyzw = value_13.xyzw;
    uint4 value_14 = asuint(mad(asfloat(r0.zzzw), asfloat(uint4(0x0u, 0x0u, 0x40000000u, 0x40000000u)), asfloat(uint4(0x0u, 0x0u, 0xbf800000u, 0xbf800000u)))); // mad r0.zw, r0.zzzw, l(0.000000, 0.000000, 2.000000, 2.000000), l(0.000000, 0.000000, -1.000000, -1.000000)
    r0.zw = value_14.zw;
    uint4 value_15 = asuint(asfloat(asuint(abs(asfloat(r0.zwzz)))) / asfloat(r0.xyxx)); // div r0.xy, |r0.zwzz|, r0.xyxx
    r0.xy = value_15.xy;
    uint4 value_16 = asuint(ddx(asfloat(v1.xxxy))); // deriv_rtx r0.zw, v1.xxxy
    r0.zw = value_16.zw;
    uint4 value_17 = asuint(ddy(asfloat(v1.xyxx))); // deriv_rty r2.xy, v1.xyxx
    r2.xy = value_17.xy;
    uint4 value_18 = asuint(asfloat(asuint(abs(asfloat(r0.zzzw)))) + asfloat(asuint(abs(asfloat(r2.xxxy))))); // add r0.zw, |r0.zzzw|, |r2.xxxy|
    r0.zw = value_18.zw;
    uint4 value_19 = asuint(asfloat(r0.wwww) + asfloat(r0.zzzz)); // add r0.z, r0.w, r0.z
    r0.z = value_19.z;
    uint4 value_20 = asuint(asfloat(v0.wwww) / asfloat(r0.zzzz)); // div r0.z, v0.w, r0.z
    r0.z = value_20.z;
    uint4 value_21 = asuint(asfloat(asuint(-asfloat(r0.zzzz))) + asfloat(r0.xyxx)); // add r0.xy, -r0.zzzz, r0.xyxx
    r0.xy = value_21.xy;
    uint4 value_22 = asuint(asfloat(cb0[19].zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.z, cb0[19].z, l(-1.000000)
    r0.z = value_22.z;
    uint4 value_23 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r0.zzzz))), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x0u, 0x0u)), asfloat(r0.xyxx)))))); // mad_sat r0.xy, -r0.zzzz, l(0.500000, 0.500000, 0.000000, 0.000000), r0.xyxx
    r0.xy = value_23.xy;
    uint4 value_24 = asuint(asfloat(asuint(-asfloat(r1.xxxy))) + asfloat(r1.zzzw)); // add r0.zw, -r1.xxxy, r1.zzzw
    r0.zw = value_24.zw;
    uint4 value_25 = asuint(mad(asfloat(r0.xyxx), asfloat(r0.zwzz), asfloat(r1.xyxx))); // mad r0.xy, r0.xyxx, r0.zwzz, r1.xyxx
    r0.xy = value_25.xy;
    uint4 value_26 = asuint(asfloat(r0.xyxx) * asfloat(cb0[40].xyxx)); // mul r0.xy, r0.xyxx, cb0[40].xyxx
    r0.xy = value_26.xy;
    uint4 value_27 = asuint(t0.SampleLevel(s1, asfloat(r0.xyxx).xy, asfloat(cb0[18].xxxx).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t0.xyzw, s1, cb0[18].x
    r0.xyzw = value_27.xyzw;
    uint4 value_28 = asuint(asfloat(r0.wwww) + asfloat(uint4(0xbc23d70au, 0xbc23d70au, 0xbc23d70au, 0xbc23d70au))); // add r0.z, r0.w, l(-0.010000)
    r0.z = value_28.z;
    uint4 value_29 = ((asfloat(r0.zzzz) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.z, r0.z, l(0.000000)
    r0.z = value_29.z;
    if (r0.zzzz.x != 0u) discard; // discard_nz r0.z
    uint4 value_31 = asuint(floor(asfloat(asuint(abs(asfloat(v0.zzzz)))))); // round_ni r0.z, |v0.z|
    r0.z = value_31.z;
    uint4 value_32 = asuint(asfloat(r0.zzzz) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.z, r0.z, l(0.500000)
    r0.z = value_32.z;
    uint4 value_33 = asuint(asfloat(r0.zzzz) * asfloat(cb0[15].xxxx)); // mul r1.x, r0.z, cb0[15].x
    r1.x = value_33.x;
    uint4 value_34 = uint4(0x3e800000u, 0x3e800000u, 0x3e800000u, 0x3e800000u); // mov r1.y, l(0.250000)
    r1.y = value_34.y;
    uint4 value_35 = asuint(t1.SampleLevel(s0, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r1.xyzw, r1.xyxx, t1.xyzw, s0, l(0.000000)
    r1.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(cb0[11].xyzx)); // add r2.xyz, -r1.xyzx, cb0[11].xyzx
    r2.xyz = value_36.xyz;
    uint4 value_37 = asuint(saturate(asfloat(asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3eb33333u, 0x0u)), asfloat(r1.xyzx)))))); // mad_sat r1.xyz, r2.xyzx, l(0.350000, 0.350000, 0.350000, 0.000000), r1.xyzx
    r1.xyz = value_37.xyz;
    uint4 value_38 = asuint(mad(asfloat(r0.xxxx), asfloat(r1.xyzx), asfloat(r0.yyyy))); // mad r0.xyz, r0.xxxx, r1.xyzx, r0.yyyy
    r0.xyz = value_38.xyz;
    uint4 value_39 = r0.wwww; // mov o0.w, r0.w
    out_o0.w = value_39.w;
    uint4 value_40 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0x0u))); // add r0.xyz, r0.xyzx, l(-0.700000, -0.700000, -0.700000, 0.000000)
    r0.xyz = value_40.xyz;
    uint4 value_41 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r0.xyzx), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x0u)))); // mad r0.xyz, cb0[29].xxxx, r0.xyzx, l(0.700000, 0.700000, 0.700000, 0.000000)
    r0.xyz = value_41.xyz;
    uint4 value_42 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_42.w;
    uint4 value_43 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(r0.xyzx)); // add r1.xyz, -r0.wwww, r0.xyzx
    r1.xyz = value_43.xyz;
    uint4 value_44 = asuint(mad(asfloat(v3.wwww), asfloat(r1.xyzx), asfloat(r0.wwww))); // mad r1.xyz, v3.wwww, r1.xyzx, r0.wwww
    r1.xyz = value_44.xyz;
    uint4 value_45 = asuint(asfloat(r1.xyzx) * asfloat(v3.xyzx)); // mul r1.xyz, r1.xyzx, v3.xyzx
    r1.xyz = value_45.xyz;
    uint4 value_46 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r1.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_46.w;
    uint4 value_47 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r1.w, -r0.w, l(0.600000)
    r1.w = value_47.w;
    uint4 value_48 = asuint(asfloat(r0.wwww) + asfloat(asuint(-asfloat(r1.wwww)))); // add r0.w, r0.w, -r1.w
    r0.w = value_48.w;
    uint4 value_49 = asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r0.wwww, l(0.100000, 0.100000, 0.100000, 0.000000), r1.xyzx
    r1.xyz = value_49.xyz;
    uint4 value_50 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r1.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_50.xyz;
    uint4 value_51 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r1.xyzx
    r1.xyz = value_51.xyz;
    uint4 value_52 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(r1.xyzx)); // add r1.xyz, -r0.xyzx, r1.xyzx
    r1.xyz = value_52.xyz;
    uint4 value_53 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r1.xyzx), asfloat(r0.xyzx))); // mad o0.xyz, cb0[29].yyyy, r1.xyzx, r0.xyzx
    out_o0.xyz = value_53.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
