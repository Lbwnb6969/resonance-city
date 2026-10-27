// Register-explicit recovered HLSL. Not original source.
// Hidden/AoBaker vs_4_0 variant []
// Source SHA256 15a529d3e1a3ad7f39c8b2ea269cb5caae7d9f168c141efb2f240a3ef92363ea
// b0: $Globals 672 bytes
// b1: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb1[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[4]; };
cbuffer Buffer1:register(b1) { uint4 cb1[21]; };
// temporary registers: 2
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float2 o1_0: TEXCOORD0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 out_o1;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    uint4 value_1 = asuint(floor(asfloat(v0.yyyy))); // round_ni r0.x, v0.y
    r0.x = value_1.x;
    uint4 value_2 = asuint(int4(asfloat(r0.xxxx))); // ftoi r0.x, r0.x
    r0.x = value_2.x;
    uint4 value_3 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r0.y, cb0[2].w
    r0.y = value_3.y;
    uint4 value_4 = uint4(asfloat(r0.yyyy)); // ftou r0.y, r0.y
    r0.y = value_4.y;
    uint4 value_5q = (r0.xxxx / r0.yyyy); // udiv r0.z, null, r0.x, r0.y
    r0.z = value_5q.z;
    uint4 value_6 = asuint(float4(r0.zzzz)); // utof r0.z, r0.z
    r0.z = value_6.z;
    uint4 value_7 = asuint(int4(asfloat(r0.zzzz))); // ftoi r0.w, r0.z
    r0.w = value_7.w;
    uint4 value_8 = (asuint(-asint(r0.wwww)) * r0.yyyy + r0.xxxx); // imad r0.x, -r0.w, r0.y, r0.x
    r0.x = value_8.x;
    uint4 value_9 = asuint(float4(r0.xxxx)); // utof r0.x, r0.x
    r0.x = value_9.x;
    uint4 value_10 = asuint(asfloat(v0.xxxz) + asfloat(asuint(-asfloat(cb0[3].xxxy)))); // add r0.yw, v0.xxxz, -cb0[3].xxxy
    r0.yw = value_10.yw;
    uint4 value_11 = asuint(asfloat(r0.yyyw) * asfloat(cb0[2].zzzz)); // mul r0.yw, r0.yyyw, cb0[2].zzzz
    r0.yw = value_11.yw;
    uint4 value_12 = asuint(max(asfloat(r0.yyyw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.yw, r0.yyyw, l(0.000000, 0.000000, 0.000000, 0.000000)
    r0.yw = value_12.yw;
    uint4 value_13 = asuint(min(asfloat(r0.yyyw), asfloat(cb0[2].xxxy))); // min r0.yw, r0.yyyw, cb0[2].xxxy
    r0.yw = value_13.yw;
    uint4 value_14 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r0.xxxx), asfloat(r0.yyyy))); // mad r0.x, cb0[2].x, r0.x, r0.y
    r0.x = value_14.x;
    uint4 value_15 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r0.zzzz), asfloat(r0.wwww))); // mad r0.y, cb0[2].y, r0.z, r0.w
    r0.y = value_15.y;
    uint4 value_16 = asuint(asfloat(r0.yyyy) * asfloat(cb1[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb1[18].xyzw
    r1.xyzw = value_16.xyzw;
    uint4 value_17 = asuint(mad(asfloat(cb1[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r0.xyzw, cb1[17].xyzw, r0.xxxx, r1.xyzw
    r0.xyzw = value_17.xyzw;
    uint4 value_18 = asuint(asfloat(r0.xyzw) + asfloat(cb1[20].xyzw)); // add o0.xyzw, r0.xyzw, cb1[20].xyzw
    out_o0.xyzw = value_18.xyzw;
    uint4 value_19 = asuint(frac(asfloat(v1.xyxx))); // frc o1.xy, v1.xyxx
    out_o1.xy = value_19.xy;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xy);
    return result;
}
