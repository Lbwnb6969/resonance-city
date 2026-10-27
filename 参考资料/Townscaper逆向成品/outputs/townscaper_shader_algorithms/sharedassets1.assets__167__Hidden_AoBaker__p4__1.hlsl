// Register-explicit recovered HLSL. Not original source.
// Hidden/AoBaker ps_4_0 variant []
// Source SHA256 267d6ef03efd90b3cd2ac953e7750e259b3e595b28b2ecd5b71c468b66fda6f5
// b0: $Globals 672 bytes
// cb0[41].x = _Color rows=1 cols=4 byte_offset=656
// t0 / s0 = _MainTex
cbuffer Buffer0:register(b0) { uint4 cb0[42]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 1
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
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
    uint4 value_1 = asuint(t0.Sample(s0, asfloat(v1.xyxx).xy)).xyzw; // sample r0.xyzw, v1.xyxx, t0.xyzw, s0
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(asfloat(r0.xyzw) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.xyzw, r0.xyzw, l(-1.000000, -1.000000, -1.000000, -1.000000)
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb0[41].wwww), asfloat(r0.xyzw), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad o0.xyzw, cb0[41].wwww, r0.xyzw, l(1.000000, 1.000000, 1.000000, 1.000000)
    out_o0.xyzw = value_3.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
