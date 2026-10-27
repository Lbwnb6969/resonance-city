// Register-explicit recovered HLSL. Not original source.
// Placemaker/HoverHightlight ps_4_0 variant []
// Source SHA256 a1f09c92ace01758adc16359ebb7a99fce04e12bd7deecb069303897e4dfef44
// temporary registers: 3
struct Input {
    float4 v0_0: SV_POSITION;
    float4 v1_0: TANGENT0;
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
    v0.xyzw = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    uint4 value_1 = asuint(asfloat(v1.xywx) + asfloat(uint4(0xbd8f5c29u, 0xbd8f5c29u, 0xbdcccccdu, 0x0u))); // add r0.xyz, v1.xywx, l(-0.070000, -0.070000, -0.100000, 0.000000)
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(min(asfloat(r0.yyyy), asfloat(r0.xxxx))); // min r0.w, r0.y, r0.x
    r0.w = value_2.w;
    uint4 value_3 = ((asfloat(r0.wwww) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.w, r0.w, l(0.000000)
    r0.w = value_3.w;
    if (r0.wwww.x != 0u) discard; // discard_nz r0.w
    uint4 value_5 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.x, r0.y, r0.x
    r0.x = value_5.x;
    uint4 value_6 = asuint(asfloat(r0.xxxx) * asfloat(v1.zzzz)); // mul r0.x, r0.x, v1.z
    r0.x = value_6.x;
    uint4 value_7 = asuint(mad(asfloat(r0.xxxx), asfloat(v1.wwww), asfloat(uint4(0xbba3d70au, 0xbba3d70au, 0xbba3d70au, 0xbba3d70au)))); // mad r0.x, r0.x, v1.w, l(-0.005000)
    r0.x = value_7.x;
    uint4 value_8 = asuint(min(asfloat(r0.zzzz), asfloat(r0.xxxx))); // min r0.x, r0.z, r0.x
    r0.x = value_8.x;
    uint4 value_9 = asuint(ddx(asfloat(r0.xxxx))); // deriv_rtx r0.y, r0.x
    r0.y = value_9.y;
    uint4 value_10 = asuint(ddy(asfloat(r0.xxxx))); // deriv_rty r0.z, r0.x
    r0.z = value_10.z;
    uint4 value_11 = asuint(asfloat(asuint(abs(asfloat(r0.zzzz)))) + asfloat(asuint(abs(asfloat(r0.yyyy))))); // add r0.y, |r0.z|, |r0.y|
    r0.y = value_11.y;
    uint4 value_12 = asuint(asfloat(r0.xxxx) / asfloat(r0.yyyy)); // div r0.x, r0.x, r0.y
    r0.x = value_12.x;
    uint4 value_13 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u)))))); // add_sat r0.y, r0.x, l(-1.000000)
    r0.y = value_13.y;
    uint4 value_14 = asuint(saturate(asfloat(r0.xxxx))); // mov_sat r0.x, r0.x
    r0.x = value_14.x;
    uint4 value_15 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x3f800000u)), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)))); // mad r1.xyzw, r0.xxxx, l(0.000000, 0.000000, 0.000000, 1.000000), l(1.000000, 1.000000, 1.000000, 0.000000)
    r1.xyzw = value_15.xyzw;
    uint4 value_16 = asuint(asfloat(asuint(-asfloat(r1.zzzw))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3e4ccccdu))); // add r2.xyzw, -r1.zzzw, l(1.000000, 1.000000, 1.000000, 0.200000)
    r2.xyzw = value_16.xyzw;
    uint4 value_17 = asuint(mad(asfloat(r0.yyyy), asfloat(r2.xyzw), asfloat(r1.xyzw))); // mad o0.xyzw, r0.yyyy, r2.xyzw, r1.xyzw
    out_o0.xyzw = value_17.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
