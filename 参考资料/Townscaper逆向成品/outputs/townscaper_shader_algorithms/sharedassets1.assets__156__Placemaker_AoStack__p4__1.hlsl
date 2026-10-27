// Register-explicit recovered HLSL. Not original source.
// Placemaker/AoStack ps_4_0 variant []
// Source SHA256 100351425de98af27657cbe20564c1aabdbc6990ed0b393b0b1ed92bf1c1812d
// b0: $Globals 672 bytes
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb0[41].x = _Color rows=1 cols=4 byte_offset=656
// t0 / s0 = _MainTex
cbuffer Buffer0:register(b0) { uint4 cb0[42]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 1
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
    float2 v1_1: TEXCOORD1;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v1.zw = asuint(input.v1_1);
    uint4 value_1 = asuint(ddx(asfloat(v1.zwzz))); // deriv_rtx r0.xy, v1.zwzz
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(ddy(asfloat(v1.zzzw))); // deriv_rty r0.zw, v1.zzzw
    r0.zw = value_2.zw;
    uint4 value_3 = asuint(asfloat(asuint(abs(asfloat(r0.zwzz)))) + asfloat(asuint(abs(asfloat(r0.xyxx))))); // add r0.xy, |r0.zwzz|, |r0.xyxx|
    r0.xy = value_3.xy;
    uint4 value_4 = asuint(asfloat(v1.zzzw) + asfloat(uint4(0x0u, 0x0u, 0xbf000000u, 0xbf000000u))); // add r0.zw, v1.zzzw, l(0.000000, 0.000000, -0.500000, -0.500000)
    r0.zw = value_4.zw;
    uint4 value_5 = asuint(mad(asfloat(cb0[29].zzzz), asfloat(uint4(0x0u, 0x0u, 0x3f000000u, 0x3f000000u)), asfloat(asuint(-asfloat(asuint(abs(asfloat(r0.zzzw)))))))); // mad r0.zw, cb0[29].zzzz, l(0.000000, 0.000000, 0.500000, 0.500000), -|r0.zzzw|
    r0.zw = value_5.zw;
    uint4 value_6 = asuint(saturate(asfloat(asuint(asfloat(r0.zwzz) / asfloat(r0.xyxx))))); // div_sat r0.xy, r0.zwzz, r0.xyxx
    r0.xy = value_6.xy;
    uint4 value_7 = asuint(min(asfloat(r0.yyyy), asfloat(r0.xxxx))); // min r0.x, r0.y, r0.x
    r0.x = value_7.x;
    uint4 value_8 = ((asfloat(cb0[29].zzzz) < asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.y, cb0[29].z, l(1.000000)
    r0.y = value_8.y;
    uint4 value_9 = ((r0.yyyy != 0u) ? r0.xxxx : uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // movc r0.x, r0.y, r0.x, l(1.000000)
    r0.x = value_9.x;
    uint4 value_10 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0xbc23d70au, 0xbc23d70au, 0xbc23d70au, 0xbc23d70au))); // add r0.y, r0.x, l(-0.010000)
    r0.y = value_10.y;
    uint4 value_11 = r0.xxxx; // mov o0.w, r0.x
    out_o0.w = value_11.w;
    uint4 value_12 = ((asfloat(r0.yyyy) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.x, r0.y, l(0.000000)
    r0.x = value_12.x;
    if (r0.xxxx.x != 0u) discard; // discard_nz r0.x
    uint4 value_14 = asuint(t0.Sample(s0, asfloat(v1.xyxx).xy)).xyzw; // sample r0.xyzw, v1.xyxx, t0.xyzw, s0
    r0.xyzw = value_14.xyzw;
    uint4 value_15 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0x0u))); // add r0.xyz, r0.xyzx, l(-1.000000, -1.000000, -1.000000, 0.000000)
    r0.xyz = value_15.xyz;
    uint4 value_16 = asuint(mad(asfloat(cb0[41].wwww), asfloat(r0.xyzx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)))); // mad o0.xyz, cb0[41].wwww, r0.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    out_o0.xyz = value_16.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
