// Register-explicit recovered HLSL. Not original source.
// Placemaker/FlipVertically ps_4_0 variant ['FLIP']
// Source SHA256 237bbcc8c5f698b54ccd44273f98b257e72541a12373575a02554c1434fbb1a2
// t0 / s0 = _MainTex
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 1
struct Input {
    float2 v0_0: TEXCOORD0;
    float4 v1_0: SV_POSITION;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    v0.xy = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    uint4 value_1 = asuint(mad(asfloat(v0.xyxx), asfloat(uint4(0x3f800000u, 0xbf800000u, 0x0u, 0x0u)), asfloat(uint4(0x0u, 0x3f800000u, 0x0u, 0x0u)))); // mad r0.xy, v0.xyxx, l(1.000000, -1.000000, 0.000000, 0.000000), l(0.000000, 1.000000, 0.000000, 0.000000)
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(t0.Sample(s0, asfloat(r0.xyxx).xy)).xyzw; // sample r0.xyzw, r0.xyxx, t0.xyzw, s0
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = r0.xyzx; // mov o0.xyz, r0.xyzx
    out_o0.xyz = value_3.xyz;
    uint4 value_4 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov o0.w, l(1.000000)
    out_o0.w = value_4.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
