// Register-explicit recovered HLSL. Not original source.
// Placemaker/ColorPick ps_4_0 variant []
// Source SHA256 3d0a2732255eb630fb7dd2c1343857c9b243ea38c7462b888fccfcea280bec61
// b0: $Globals 688 bytes
// cb0[11].x = _RoofColor rows=1 cols=4 byte_offset=176
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// t0 / s1 = _MainTex
// t1 / s0 = _MaterialTex
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 3
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float4 v1_0: SV_POSITION;
    float4 v2_0: COLOR0;
    float4 v3_0: COLOR1;
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
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xyzw = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(t0.Sample(s1, asfloat(v0.xyxx).xy)).xyzw; // sample r0.xyzw, v0.xyxx, t0.xyzw, s1
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(ddx(asfloat(r0.wwww))); // deriv_rtx r0.x, r0.w
    r0.x = value_2.x;
    uint4 value_3 = asuint(ddy(asfloat(r0.wwww))); // deriv_rty r0.y, r0.w
    r0.y = value_3.y;
    uint4 value_4 = asuint(asfloat(asuint(abs(asfloat(r0.yyyy)))) + asfloat(asuint(abs(asfloat(r0.xxxx))))); // add r0.x, |r0.y|, |r0.x|
    r0.x = value_4.x;
    uint4 value_5 = asuint(saturate(asfloat(asuint(asfloat(asuint(-asfloat(v0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))))); // add_sat r0.y, -v0.w, l(1.000000)
    r0.y = value_5.y;
    uint4 value_6 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.z, -r0.y, l(1.000000)
    r0.z = value_6.z;
    uint4 value_7 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.zzzz), asfloat(r0.yyyy))); // mad r0.z, r0.x, r0.z, r0.y
    r0.z = value_7.z;
    uint4 value_8 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r0.yyyy), asfloat(r0.yyyy))); // mad r0.x, -r0.x, r0.y, r0.y
    r0.x = value_8.x;
    uint4 value_9 = asuint(max(asfloat(r0.xxxx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.x, r0.x, l(0.000000)
    r0.x = value_9.x;
    uint4 value_10 = asuint(min(asfloat(r0.zzzz), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // min r0.y, r0.z, l(1.000000)
    r0.y = value_10.y;
    uint4 value_11 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(r0.yyyy)); // add r0.y, -r0.x, r0.y
    r0.y = value_11.y;
    uint4 value_12 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(r0.wwww)); // add r0.x, -r0.x, r0.w
    r0.x = value_12.x;
    uint4 value_13 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) / asfloat(r0.yyyy))))); // div_sat r0.x, r0.x, r0.y
    r0.x = value_13.x;
    uint4 value_14 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0xbc23d70au, 0xbc23d70au, 0xbc23d70au, 0xbc23d70au))); // add r0.y, r0.x, l(-0.010000)
    r0.y = value_14.y;
    uint4 value_15 = r0.xxxx; // mov o0.w, r0.x
    out_o0.w = value_15.w;
    uint4 value_16 = ((asfloat(r0.yyyy) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.x, r0.y, l(0.000000)
    r0.x = value_16.x;
    if (r0.xxxx.x != 0u) discard; // discard_nz r0.x
    uint4 value_18 = asuint(floor(asfloat(asuint(abs(asfloat(v0.zzzz)))))); // round_ni r0.x, |v0.z|
    r0.x = value_18.x;
    uint4 value_19 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.x, r0.x, l(0.500000)
    r0.x = value_19.x;
    uint4 value_20 = asuint(asfloat(r0.xxxx) * asfloat(cb0[15].xxxx)); // mul r0.x, r0.x, cb0[15].x
    r0.x = value_20.x;
    uint4 value_21 = uint4(0x3e800000u, 0x3e800000u, 0x3e800000u, 0x3e800000u); // mov r0.y, l(0.250000)
    r0.y = value_21.y;
    uint4 value_22 = asuint(t1.SampleLevel(s0, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r0.xyzw, r0.xyxx, t1.xyzw, s0, l(0.000000)
    r0.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(cb0[11].xyzx)); // add r1.xyz, -r0.xyzx, cb0[11].xyzx
    r1.xyz = value_23.xyz;
    uint4 value_24 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3eb33333u, 0x3eb33333u, 0x3eb33333u, 0x0u)), asfloat(r0.xyzx)))))); // mad_sat r0.xyz, r1.xyzx, l(0.350000, 0.350000, 0.350000, 0.000000), r0.xyzx
    r0.xyz = value_24.xyz;
    uint4 value_25 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0x0u))); // add r0.xyz, r0.xyzx, l(-0.700000, -0.700000, -0.700000, 0.000000)
    r0.xyz = value_25.xyz;
    uint4 value_26 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r0.xyzx), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x0u)))); // mad r0.xyz, cb0[29].xxxx, r0.xyzx, l(0.700000, 0.700000, 0.700000, 0.000000)
    r0.xyz = value_26.xyz;
    uint4 value_27 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_27.w;
    uint4 value_28 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(r0.xyzx)); // add r1.xyz, -r0.wwww, r0.xyzx
    r1.xyz = value_28.xyz;
    uint4 value_29 = asuint(mad(asfloat(v2.wwww), asfloat(r1.xyzx), asfloat(r0.wwww))); // mad r1.xyz, v2.wwww, r1.xyzx, r0.wwww
    r1.xyz = value_29.xyz;
    uint4 value_30 = asuint(asfloat(r1.xyzx) * asfloat(v2.xyzx)); // mul r1.xyz, r1.xyzx, v2.xyzx
    r1.xyz = value_30.xyz;
    uint4 value_31 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r1.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_31.w;
    uint4 value_32 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r1.w, -r0.w, l(0.600000)
    r1.w = value_32.w;
    uint4 value_33 = asuint(asfloat(r0.wwww) + asfloat(asuint(-asfloat(r1.wwww)))); // add r0.w, r0.w, -r1.w
    r0.w = value_33.w;
    uint4 value_34 = asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r0.wwww, l(0.100000, 0.100000, 0.100000, 0.000000), r1.xyzx
    r1.xyz = value_34.xyz;
    uint4 value_35 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r1.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_35.xyz;
    uint4 value_36 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r1.xyzx
    r1.xyz = value_36.xyz;
    uint4 value_37 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(r1.xyzx)); // add r1.xyz, -r0.xyzx, r1.xyzx
    r1.xyz = value_37.xyz;
    uint4 value_38 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r1.xyzx), asfloat(r0.xyzx))); // mad o0.xyz, cb0[29].yyyy, r1.xyzx, r0.xyzx
    out_o0.xyz = value_38.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
