// Register-explicit recovered HLSL. Not original source.
// Placemaker/Skybox vs_4_0 variant []
// Source SHA256 40e26863a4127f4539028da8e8b6c85a07ad8792d29343b15390f60ce0a135a2
// b0: $Globals 656 bytes
// b1: UnityPerCamera 144 bytes
// b2: UnityPerFrame 368 bytes
// cb0[8].x = _BgColor rows=1 cols=4 byte_offset=128
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// cb1[4].x = _WorldSpaceCameraPos rows=1 cols=3 byte_offset=64
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
cbuffer Buffer1:register(b1) { uint4 cb1[5]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
// temporary registers: 3
struct Input {
    float4 v0_0: POSITION0;
    float3 v1_0: NORMAL0;
    float2 v2_0: TEXCOORD0;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float2 o1_0: TEXCOORD0;
    float3 o2_0: TEXCOORD1;
    float4 o3_0: COLOR0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 out_o3;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    v0.xyzw = asuint(input.v0_0);
    v1.xyz = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    uint4 value_1 = v1.xxzx; // mov r0.xz, v1.xxzx
    r0.xz = value_1.xz;
    uint4 value_2 = uint4(0xbdf5c28fu, 0xbdf5c28fu, 0xbdf5c28fu, 0xbdf5c28fu); // mov r0.y, l(-0.120000)
    r0.y = value_2.y;
    uint4 value_3 = asuint(mad(asfloat(r0.xyzx), asfloat(uint4(0x41200000u, 0x41200000u, 0x41200000u, 0x0u)), asfloat(cb1[4].xyzx))); // mad r1.xyz, r0.xyzx, l(10.000000, 10.000000, 10.000000, 0.000000), cb1[4].xyzx
    r1.xyz = value_3.xyz;
    uint4 value_4 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(r0.xyzx).xyz)).xxxx; // dp3 r0.x, r0.xyzx, r0.xyzx
    r0.x = value_4.x;
    uint4 value_5 = asuint(rsqrt(asfloat(r0.xxxx))); // rsq r0.x, r0.x
    r0.x = value_5.x;
    uint4 value_6 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0xbd75c28fu, 0xbd75c28fu, 0xbd75c28fu, 0xbd75c28fu))); // mul r0.x, r0.x, l(-0.060000)
    r0.x = value_6.x;
    uint4 value_7 = asuint(asfloat(r1.yyyy) * asfloat(cb2[18].xyzw)); // mul r2.xyzw, r1.yyyy, cb2[18].xyzw
    r2.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r1.xxxx), asfloat(r2.xyzw))); // mad r2.xyzw, cb2[17].xyzw, r1.xxxx, r2.xyzw
    r2.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r1.zzzz), asfloat(r2.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r1.zzzz, r2.xyzw
    r1.xyzw = value_9.xyzw;
    uint4 value_10 = asuint(asfloat(r1.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r1.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_10.xyzw;
    uint4 value_11 = asuint(asfloat(asuint(-asfloat(cb0[8].xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.yzw, -cb0[8].xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r0.yzw = value_11.yzw;
    uint4 value_12 = asuint(mad(asfloat(r0.xxxx), asfloat(r0.yzwy), asfloat(cb0[8].xyzx))); // mad r0.xyz, r0.xxxx, r0.yzwy, cb0[8].xyzx
    r0.xyz = value_12.xyz;
    uint4 value_13 = asuint(asfloat(r0.xyzx) + asfloat(uint4(0xbf000000u, 0xbf266666u, 0xbf333333u, 0x0u))); // add r0.xyz, r0.xyzx, l(-0.500000, -0.650000, -0.700000, 0.000000)
    r0.xyz = value_13.xyz;
    uint4 value_14 = asuint(asfloat(cb0[8].wwww) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.w, cb0[8].w, l(-1.000000)
    r0.w = value_14.w;
    uint4 value_15 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r0.xyzw), asfloat(uint4(0x3f000000u, 0x3f266666u, 0x3f333333u, 0x3f800000u)))); // mad o3.xyzw, cb0[29].yyyy, r0.xyzw, l(0.500000, 0.650000, 0.700000, 1.000000)
    out_o3.xyzw = value_15.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xy);
    result.o2_0 = asfloat(out_o2.xyz);
    result.o3_0 = asfloat(out_o3.xyzw);
    return result;
}
