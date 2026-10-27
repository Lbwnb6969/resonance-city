// Register-explicit recovered HLSL. Not original source.
// Placemaker/Splash ps_4_0 variant []
// Source SHA256 95a6c860ceaf16bc2481aa9a36d94601bed71577fc144d137d9006d24398b872
// t0 / s0 = _MainTex
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 1
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
    uint4 value_1 = asuint(t0.Sample(s0, asfloat(v0.xyxx).xy)).xyzw; // sample r0.xyzw, v0.xyxx, t0.xyzw, s0
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(ddx(asfloat(r0.wwww))); // deriv_rtx r0.x, r0.w
    r0.x = value_2.x;
    uint4 value_3 = asuint(ddy(asfloat(r0.wwww))); // deriv_rty r0.y, r0.w
    r0.y = value_3.y;
    uint4 value_4 = asuint(asfloat(asuint(abs(asfloat(r0.yyyy)))) + asfloat(asuint(abs(asfloat(r0.xxxx))))); // add r0.x, |r0.y|, |r0.x|
    r0.x = value_4.x;
    uint4 value_5 = asuint(saturate(asfloat(asuint(asfloat(asuint(-asfloat(v2.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))))); // add_sat r0.y, -v2.w, l(1.000000)
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
    uint4 value_18 = v2.xyzx; // mov o0.xyz, v2.xyzx
    out_o0.xyz = value_18.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
