// Register-explicit recovered HLSL. Not original source.
// Placemaker/Border ps_4_0 variant []
// Source SHA256 0056d615339f5840cb430087288f66137892902fb8c09346bbfc1b901238af52
// b0: $Globals 656 bytes
// cb0[40].x = _Color rows=1 cols=4 byte_offset=640
// t0 / s0 = _MainTex
cbuffer Buffer0:register(b0) { uint4 cb0[41]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 1
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
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    uint4 value_1 = asuint(t0.Sample(s0, asfloat(v1.xyxx).xy)).xyzw; // sample r0.xyzw, v1.xyxx, t0.xyzw, s0
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(ddx(asfloat(r0.yyyy))); // deriv_rtx r0.x, r0.y
    r0.x = value_2.x;
    uint4 value_3 = asuint(ddy(asfloat(r0.yyyy))); // deriv_rty r0.z, r0.y
    r0.z = value_3.z;
    uint4 value_4 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0xbf333333u))); // add r0.y, r0.y, l(-0.700000)
    r0.y = value_4.y;
    uint4 value_5 = asuint(asfloat(asuint(abs(asfloat(r0.zzzz)))) + asfloat(asuint(abs(asfloat(r0.xxxx))))); // add r0.x, |r0.z|, |r0.x|
    r0.x = value_5.x;
    uint4 value_6 = asuint(asfloat(asuint(abs(asfloat(r0.yyyy)))) / asfloat(r0.xxxx)); // div r0.x, |r0.y|, r0.x
    r0.x = value_6.x;
    uint4 value_7 = asuint(min(asfloat(r0.xxxx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // min r0.x, r0.x, l(1.000000)
    r0.x = value_7.x;
    uint4 value_8 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_8.x;
    uint4 value_9 = asuint(asfloat(r0.xxxx) * asfloat(cb0[40].wwww)); // mul r0.x, r0.x, cb0[40].w
    r0.x = value_9.x;
    uint4 value_10 = asuint(asfloat(r0.xxxx) * asfloat(v2.wwww)); // mul o0.w, r0.x, v2.w
    out_o0.w = value_10.w;
    uint4 value_11 = cb0[40].xyzx; // mov o0.xyz, cb0[40].xyzx
    out_o0.xyz = value_11.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
