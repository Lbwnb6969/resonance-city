// Register-explicit recovered HLSL. Not original source.
// Placemaker/Water ps_4_0 variant []
// Source SHA256 9a76659a33fd023b2bd7956b395f912f58b3e395255fa6c569d22642ffae6b6c
// b0: UnityPerCamera 144 bytes
// cb0[0].x = _Time rows=1 cols=4 byte_offset=0
cbuffer Buffer0:register(b0) { uint4 cb0[1]; };
// temporary registers: 1
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
    uint4 value_1 = asuint(mad(asfloat(asuint(-asfloat(cb0[0].yyyy))), asfloat(uint4(0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu, 0x3ecccccdu)), asfloat(v0.yyyy))); // mad r0.x, -cb0[0].y, l(0.400000), v0.y
    r0.x = value_1.x;
    uint4 value_2 = asuint(asfloat(r0.xxxx) + asfloat(v0.zzzz)); // add r0.x, r0.x, v0.z
    r0.x = value_2.x;
    uint4 value_3 = asuint(frac(asfloat(r0.xxxx))); // frc r0.y, r0.x
    r0.y = value_3.y;
    uint4 value_4 = asuint(asfloat(asuint(-asfloat(v0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.z, -v0.x, l(1.000000)
    r0.z = value_4.z;
    uint4 value_5 = asuint(asfloat(r0.zzzz) + asfloat(v3.wwww)); // add r0.w, r0.z, v3.w
    r0.w = value_5.w;
    uint4 value_6 = asuint(asfloat(r0.zzzz) * asfloat(r0.zzzz)); // mul r0.z, r0.z, r0.z
    r0.z = value_6.z;
    uint4 value_7 = asuint(asfloat(r0.zzzz) * asfloat(r0.zzzz)); // mul r0.z, r0.z, r0.z
    r0.z = value_7.z;
    uint4 value_8 = asuint(asfloat(r0.yyyw) + asfloat(uint4(0x0u, 0xbf000000u, 0x0u, 0xbf666666u))); // add r0.yw, r0.yyyw, l(0.000000, -0.500000, 0.000000, -0.900000)
    r0.yw = value_8.yw;
    uint4 value_9 = asuint(asfloat(r0.zzzw) * asfloat(uint4(0x0u, 0x0u, 0x3f4ccccdu, 0x3fb33333u))); // mul r0.zw, r0.zzzw, l(0.000000, 0.000000, 0.800000, 1.400000)
    r0.zw = value_9.zw;
    uint4 value_10 = asuint(mad(asfloat(asuint(abs(asfloat(r0.yyyy)))), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(r0.wwww))); // mad r0.y, |r0.y|, l(2.000000), r0.w
    r0.y = value_10.y;
    uint4 value_11 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(r0.wwww))); // mad r0.x, r0.x, l(2.000000), r0.w
    r0.x = value_11.x;
    uint4 value_12 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbf8ccccdu, 0xbf8ccccdu, 0xbf8ccccdu, 0xbf8ccccdu))); // add r0.y, r0.y, l(-1.100000)
    r0.y = value_12.y;
    uint4 value_13 = asuint(ddx(asfloat(r0.xxxx))); // deriv_rtx r0.w, r0.x
    r0.w = value_13.w;
    uint4 value_14 = asuint(ddy(asfloat(r0.xxxx))); // deriv_rty r0.x, r0.x
    r0.x = value_14.x;
    uint4 value_15 = asuint(asfloat(asuint(abs(asfloat(r0.xxxx)))) + asfloat(asuint(abs(asfloat(r0.wwww))))); // add r0.x, |r0.x|, |r0.w|
    r0.x = value_15.x;
    uint4 value_16 = asuint(saturate(asfloat(asuint(asfloat(r0.yyyy) / asfloat(r0.xxxx))))); // div_sat r0.x, r0.y, r0.x
    r0.x = value_16.x;
    uint4 value_17 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0xbc23d70au, 0xbc23d70au, 0xbc23d70au, 0xbc23d70au))); // add r0.y, r0.x, l(-0.010000)
    r0.y = value_17.y;
    uint4 value_18 = r0.xxxx; // mov o0.w, r0.x
    out_o0.w = value_18.w;
    uint4 value_19 = ((asfloat(r0.yyyy) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.x, r0.y, l(0.000000)
    r0.x = value_19.x;
    if (r0.xxxx.x != 0u) discard; // discard_nz r0.x
    uint4 value_21 = asuint(asfloat(v3.xyxz) + asfloat(asuint(-asfloat(v4.xyxz)))); // add r0.xyw, v3.xyxz, -v4.xyxz
    r0.xyw = value_21.xyw;
    uint4 value_22 = asuint(mad(asfloat(r0.zzzz), asfloat(r0.xywx), asfloat(v4.xyzx))); // mad o0.xyz, r0.zzzz, r0.xywx, v4.xyzx
    out_o0.xyz = value_22.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
