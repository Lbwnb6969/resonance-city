// Register-explicit recovered HLSL. Not original source.
// Hidden/MarchingSquaresColorBlit ps_4_0 variant []
// Source SHA256 b5c0aaf65929585f62f800818376190ffc06ab81eb50d8d45f5c8dcfd2146e1f
// b0: $Globals 656 bytes
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// t0 / s1 = _MainTex
// t1 / s0 = _MaterialTex
cbuffer Buffer0:register(b0) { uint4 cb0[16]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
// temporary registers: 3
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
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
    v1.xy = asuint(input.v1_0);
    uint4 value_1 = asuint(t0.Sample(s1, asfloat(v1.xyxx).xy)).xyzw; // sample r0.xyzw, v1.xyxx, t0.xyzw, s1
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x41880000u, 0x41880000u, 0x41880000u, 0x41880000u))); // mul r0.x, r0.x, l(17.000000)
    r0.x = value_2.x;
    uint4 value_3 = asuint(floor(asfloat(r0.xxxx))); // round_ni r0.x, r0.x
    r0.x = value_3.x;
    uint4 value_4 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.x, r0.x, l(0.500000)
    r0.x = value_4.x;
    uint4 value_5 = asuint(asfloat(r0.xxxx) * asfloat(cb0[15].xxxx)); // mul r0.x, r0.x, cb0[15].x
    r0.x = value_5.x;
    uint4 value_6 = asuint(asfloat(cb0[15].yyyy) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.y, cb0[15].y, l(0.500000)
    r0.y = value_6.y;
    uint4 value_7 = asuint(t1.SampleLevel(s0, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r1.xyzw, r0.xyxx, t1.xyzw, s0, l(0.000000)
    r1.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(asfloat(r1.xyzx) * asfloat(uint4(0x3f4ccccdu, 0x3f4ccccdu, 0x3f4ccccdu, 0x0u))); // mul r1.xyz, r1.xyzx, l(0.800000, 0.800000, 0.800000, 0.000000)
    r1.xyz = value_8.xyz;
    uint4 value_9 = uint4(0x0u, 0x0u, 0x0u, 0x0u); // mov r1.w, l(0)
    r1.w = value_9.w;
    uint4 value_10 = asuint(asfloat(asuint(-asfloat(r1.xyzw))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r2.xyzw, -r1.xyzw, l(1.000000, 1.000000, 1.000000, 1.000000)
    r2.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xyzw), asfloat(r1.xyzw))); // mad o0.xyzw, r0.wwww, r2.xyzw, r1.xyzw
    out_o0.xyzw = value_11.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
