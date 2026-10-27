// Register-explicit recovered HLSL. Not original source.
// PlacemakerUi/VignetteOverlay vs_4_0 variant []
// Source SHA256 a7321f1a1ffac32676babe9cc40fecb8aa7da679b8df535f3a9e220e2123323d
// b0: $Globals 720 bytes
// b1: UnityPerCamera 144 bytes
// b2: UnityPerDraw 176 bytes
// b3: UnityPerFrame 368 bytes
// cb0[40].x = _MainTex_TexelSize rows=1 cols=4 byte_offset=640
// cb0[41].x = _NoiseTex_TexelSize rows=1 cols=4 byte_offset=656
// cb0[43].x = _Rect rows=1 cols=4 byte_offset=688
// cb0[44].x = _Alpha rows=1 cols=1 byte_offset=704
// cb1[5].x = _ProjectionParams rows=1 cols=4 byte_offset=80
// cb2[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb3[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
cbuffer Buffer0:register(b0) { uint4 cb0[45]; };
cbuffer Buffer1:register(b1) { uint4 cb1[6]; };
cbuffer Buffer2:register(b2) { uint4 cb2[4]; };
cbuffer Buffer3:register(b3) { uint4 cb3[21]; };
// temporary registers: 2
struct Input {
    float4 v0_0: POSITION0;
    float2 v1_0: TEXCOORD0;
    float2 v2_0: TEXCOORD2;
    float4 v3_0: COLOR0;
};
struct Output {
    float2 o0_0: TEXCOORD0;
    float2 o0_1: TEXCOORD2;
    float4 o1_0: SV_POSITION;
    float4 o2_0: COLOR0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 out_o0;
    uint4 out_o1;
    uint4 out_o2;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v2.xy = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb2[1].xyzx)); // mul r0.xyz, v0.yyyy, cb2[1].xyzx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(mad(asfloat(cb2[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb2[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb2[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb2[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(mad(asfloat(cb2[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb2[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(asfloat(r0.yyyy) * asfloat(cb3[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb3[18].xyzw
    r1.xyzw = value_5.xyzw;
    uint4 value_6 = asuint(mad(asfloat(cb3[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb3[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_6.xyzw;
    uint4 value_7 = asuint(mad(asfloat(cb3[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r0.xyzw, cb3[19].xyzw, r0.zzzz, r1.xyzw
    r0.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(asfloat(r0.xyzw) + asfloat(cb3[20].xyzw)); // add r0.xyzw, r0.xyzw, cb3[20].xyzw
    r0.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(asfloat(r0.yyyy) * asfloat(cb1[5].xxxx)); // mul r1.x, r0.y, cb1[5].x
    r1.x = value_9.x;
    uint4 value_10 = asuint(asfloat(r1.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r1.w, r1.x, l(0.500000)
    r1.w = value_10.w;
    uint4 value_11 = asuint(asfloat(r0.xxwx) * asfloat(uint4(0x3f000000u, 0x0u, 0x3f000000u, 0x0u))); // mul r1.xz, r0.xxwx, l(0.500000, 0.000000, 0.500000, 0.000000)
    r1.xz = value_11.xz;
    uint4 value_12 = asuint(asfloat(r1.zzzz) + asfloat(r1.xwxx)); // add r1.xy, r1.zzzz, r1.xwxx
    r1.xy = value_12.xy;
    uint4 value_13 = asuint(asfloat(r1.xyxx) / asfloat(r0.wwww)); // div r1.xy, r1.xyxx, r0.wwww
    r1.xy = value_13.xy;
    uint4 value_14 = r0.xyzw; // mov o1.xyzw, r0.xyzw
    out_o1.xyzw = value_14.xyzw;
    uint4 value_15 = asuint(asfloat(r1.xxxy) * asfloat(cb0[41].zzzw)); // mul o0.zw, r1.xxxy, cb0[41].zzzw
    out_o0.zw = value_15.zw;
    uint4 value_16 = asuint(mad(asfloat(cb0[43].zwzz), asfloat(v1.xyxx), asfloat(cb0[43].xyxx))); // mad r0.xy, cb0[43].zwzz, v1.xyxx, cb0[43].xyxx
    r0.xy = value_16.xy;
    uint4 value_17 = asuint(asfloat(asuint(-asfloat(r0.xxxy))) + asfloat(uint4(0x0u, 0x0u, 0x3f000000u, 0x3f000000u))); // add r0.zw, -r0.xxxy, l(0.000000, 0.000000, 0.500000, 0.500000)
    r0.zw = value_17.zw;
    uint4 value_18 = asuint(mad(asfloat(cb0[40].xyxx), asfloat(r0.zwzz), asfloat(r0.xyxx))); // mad o0.xy, cb0[40].xyxx, r0.zwzz, r0.xyxx
    out_o0.xy = value_18.xy;
    uint4 value_19 = asuint(asfloat(v3.wwww) * asfloat(cb0[44].xxxx)); // mul o2.w, v3.w, cb0[44].x
    out_o2.w = value_19.w;
    uint4 value_20 = v3.xyzx; // mov o2.xyz, v3.xyzx
    out_o2.xyz = value_20.xyz;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xy);
    result.o0_1 = asfloat(out_o0.zw);
    result.o1_0 = asfloat(out_o1.xyzw);
    result.o2_0 = asfloat(out_o2.xyzw);
    return result;
}
