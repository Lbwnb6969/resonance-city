// Register-explicit recovered HLSL. Not original source.
// Placemaker/Skybox ps_4_0 variant []
// Source SHA256 3bbfed45044bb67ab078eaa75ce2ec8d81aa35e773f550d42aa6c777de73e80c
// b0: $Globals 656 bytes
// b1: UnityPerCamera 144 bytes
// cb0[8].x = _BgColor rows=1 cols=4 byte_offset=128
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb1[0].x = _Time rows=1 cols=4 byte_offset=0
// t0 / s0 = _MainTex
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
cbuffer Buffer1:register(b1) { uint4 cb1[1]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 2
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
    float4 v2_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    uint4 value_1 = asuint(mad(asfloat(cb1[0].yyyy), asfloat(uint4(0x3b54abbeu, 0x3b54abbeu, 0x3b54abbeu, 0x3b54abbeu)), asfloat(v1.xxxx))); // mad r0.x, cb1[0].y, l(0.003245), v1.x
    r0.x = value_1.x;
    uint4 value_2 = asuint(asfloat(r0.xxxx) + asfloat(v1.yyyy)); // add r0.x, r0.x, v1.y
    r0.x = value_2.x;
    uint4 value_3 = asuint(frac(asfloat(r0.xxxx))); // frc r0.x, r0.x
    r0.x = value_3.x;
    uint4 value_4 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u)))); // mad r0.x, r0.x, l(2.000000), l(-1.000000)
    r0.x = value_4.x;
    uint4 value_5 = asuint(saturate(asfloat(asuint(asfloat(v1.yyyy) * asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x3f333333u)))))); // mul_sat r1.y, v1.y, l(0.700000)
    r1.y = value_5.y;
    uint4 value_6 = asuint(asfloat(cb1[0].yyyy) * asfloat(uint4(0x0u, 0x3ba3d70au, 0x3b03126fu, 0x3bfa72f8u))); // mul r0.yzw, cb1[0].yyyy, l(0.000000, 0.005000, 0.002000, 0.007643)
    r0.yzw = value_6.yzw;
    uint4 value_7 = asuint(mad(asfloat(v1.xxxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(r0.yyyy))); // mad r0.y, v1.x, l(2.000000), r0.y
    r0.y = value_7.y;
    uint4 value_8 = asuint(frac(asfloat(r0.yyyy))); // frc r1.x, r0.y
    r1.x = value_8.x;
    uint4 value_9 = asuint(t0.SampleLevel(s0, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r1.xyzw, r1.xyxx, t0.xyzw, s0, l(0.000000)
    r1.xyzw = value_9.xyzw;
    uint4 value_10 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(r1.zzzz)); // add r0.y, -r1.x, r1.z
    r0.y = value_10.y;
    uint4 value_11 = asuint(mad(asfloat(asuint(abs(asfloat(r0.xxxx)))), asfloat(r0.yyyy), asfloat(r1.xxxx))); // mad r0.x, |r0.x|, r0.y, r1.x
    r0.x = value_11.x;
    uint4 value_12 = asuint(asfloat(r1.xxxx) + asfloat(uint4(0xbf19999au, 0xbf19999au, 0xbf19999au, 0xbf19999au))); // add r0.y, r1.x, l(-0.600000)
    r0.y = value_12.y;
    uint4 value_13 = asuint(asfloat(r0.yyyy) * asfloat(v1.yyyy)); // mul r0.y, r0.y, v1.y
    r0.y = value_13.y;
    uint4 value_14 = asuint(mad(asfloat(r0.yyyy), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x3e99999au)), asfloat(v1.yyyy))); // mad r0.y, r0.y, l(0.300000), v1.y
    r0.y = value_14.y;
    uint4 value_15 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.x, r0.x, l(-0.500000)
    r0.x = value_15.x;
    uint4 value_16 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu)), asfloat(v1.xxxx))); // mad r0.x, r0.x, l(0.100000), v1.x
    r0.x = value_16.x;
    uint4 value_17 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0xc0400000u, 0xc0400000u, 0xc0400000u, 0xc0400000u)), asfloat(r0.wwww))); // mad r0.w, r0.x, l(-3.000000), r0.w
    r0.w = value_17.w;
    uint4 value_18 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0xc0400000u, 0xc0400000u, 0xc0400000u, 0xc0400000u)), asfloat(asuint(-asfloat(r0.zzzz))))); // mad r0.x, r0.x, l(-3.000000), -r0.z
    r0.x = value_18.x;
    uint4 value_19 = asuint(frac(asfloat(r0.xxxx))); // frc r1.x, r0.x
    r1.x = value_19.x;
    uint4 value_20 = asuint(asfloat(r0.yyyy) + asfloat(r0.wwww)); // add r0.x, r0.y, r0.w
    r0.x = value_20.x;
    uint4 value_21 = asuint(frac(asfloat(r0.xxxx))); // frc r0.x, r0.x
    r0.x = value_21.x;
    uint4 value_22 = asuint(mad(asfloat(r0.xxxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u)))); // mad r0.x, r0.x, l(2.000000), l(-1.000000)
    r0.x = value_22.x;
    uint4 value_23 = asuint(saturate(asfloat(r0.yyyy))); // mov_sat r1.y, r0.y
    r1.y = value_23.y;
    uint4 value_24 = asuint(t0.SampleLevel(s0, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r1.xyzw, r1.xyxx, t0.xyzw, s0, l(0.000000)
    r1.xyzw = value_24.xyzw;
    uint4 value_25 = asuint(asfloat(asuint(-asfloat(r1.zzzz))) + asfloat(r1.xxxx)); // add r0.z, -r1.z, r1.x
    r0.z = value_25.z;
    uint4 value_26 = asuint(mad(asfloat(asuint(abs(asfloat(r0.xxxx)))), asfloat(r0.zzzz), asfloat(r1.zzzz))); // mad r0.x, |r0.x|, r0.z, r1.z
    r0.x = value_26.x;
    uint4 value_27 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.x, r0.y, r0.x
    r0.x = value_27.x;
    uint4 value_28 = asuint(asfloat(cb0[8].wwww) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0xbf333333u))); // add r0.y, cb0[8].w, l(-0.700000)
    r0.y = value_28.y;
    uint4 value_29 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.yyyy), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x3f333333u)))); // mad r0.y, cb0[29].y, r0.y, l(0.700000)
    r0.y = value_29.y;
    uint4 value_30 = asuint(asfloat(r0.yyyy) + asfloat(asuint(-asfloat(v2.xxyz)))); // add r0.yzw, r0.yyyy, -v2.xxyz
    r0.yzw = value_30.yzw;
    uint4 value_31 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yzwy), asfloat(v2.xyzx))); // mad o0.xyz, r0.xxxx, r0.yzwy, v2.xyzx
    out_o0.xyz = value_31.xyz;
    uint4 value_32 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov o0.w, l(1.000000)
    out_o0.w = value_32.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
