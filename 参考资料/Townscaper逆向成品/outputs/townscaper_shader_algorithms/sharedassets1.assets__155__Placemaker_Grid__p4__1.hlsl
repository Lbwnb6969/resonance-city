// Register-explicit recovered HLSL. Not original source.
// Placemaker/Grid ps_4_0 variant []
// Source SHA256 bdb090f5f7469bff120a42c0b90ffd1da93717c33f8ccba0ee31346a25c829e2
// b0: $Globals 688 bytes
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[42].x = _ShowGrid rows=1 cols=4 byte_offset=672
cbuffer Buffer0:register(b0) { uint4 cb0[43]; };
// temporary registers: 4
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
    float2 v1_1: TEXCOORD1;
    float2 v2_0: TEXCOORD2;
    float2 v2_1: TEXCOORD3;
    float4 v3_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 r3;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    uint4 v2;
    uint4 v3;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    v1.zw = asuint(input.v1_1);
    v2.xy = asuint(input.v2_0);
    v2.zw = asuint(input.v2_1);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = asuint(asfloat(v1.yyyy) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.x, v1.y, l(-0.500000)
    r0.x = value_1.x;
    uint4 value_2 = asuint(asfloat(asuint(abs(asfloat(r0.xxxx)))) + asfloat(uint4(0xbca3d70au, 0xbca3d70au, 0xbca3d70au, 0xbca3d70au))); // add r0.x, |r0.x|, l(-0.020000)
    r0.x = value_2.x;
    uint4 value_3 = asuint(ddx(asfloat(r0.xxxx))); // deriv_rtx r0.y, r0.x
    r0.y = value_3.y;
    uint4 value_4 = asuint(ddy(asfloat(r0.xxxx))); // deriv_rty r0.z, r0.x
    r0.z = value_4.z;
    uint4 value_5 = asuint(asfloat(asuint(abs(asfloat(r0.zzzz)))) + asfloat(asuint(abs(asfloat(r0.yyyy))))); // add r0.y, |r0.z|, |r0.y|
    r0.y = value_5.y;
    uint4 value_6 = asuint(asfloat(r0.xxxx) / asfloat(r0.yyyy)); // div r0.x, r0.x, r0.y
    r0.x = value_6.x;
    uint4 value_7 = asuint(saturate(asfloat(asuint(asfloat(v2.zzzz) / asfloat(v2.wwww))))); // div_sat r0.y, v2.z, v2.w
    r0.y = value_7.y;
    uint4 value_8 = asuint(ddx(asfloat(r0.yyyy))); // deriv_rtx r0.z, r0.y
    r0.z = value_8.z;
    uint4 value_9 = asuint(ddy(asfloat(r0.yyyy))); // deriv_rty r0.w, r0.y
    r0.w = value_9.w;
    uint4 value_10 = asuint(asfloat(asuint(abs(asfloat(r0.wwww)))) + asfloat(asuint(abs(asfloat(r0.zzzz))))); // add r0.z, |r0.w|, |r0.z|
    r0.z = value_10.z;
    uint4 value_11 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.w, r0.y, l(-0.500000)
    r0.w = value_11.w;
    uint4 value_12 = asuint(asfloat(r0.wwww) / asfloat(r0.zzzz)); // div r0.z, r0.w, r0.z
    r0.z = value_12.z;
    uint4 value_13 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxz) + asfloat(uint4(0xbf000000u, 0x0u, 0x0u, 0x3f800000u)))))); // add_sat r0.xw, r0.xxxz, l(-0.500000, 0.000000, 0.000000, 1.000000)
    r0.xw = value_13.xw;
    uint4 value_14 = asuint(asfloat(r0.wwww) * asfloat(cb0[42].zzzz)); // mul r0.w, r0.w, cb0[42].z
    r0.w = value_14.w;
    uint4 value_15 = asuint(asfloat(r0.xxxx) * asfloat(r0.wwww)); // mul r0.x, r0.x, r0.w
    r0.x = value_15.x;
    uint4 value_16 = asuint(saturate(asfloat(asuint(asfloat(cb0[19].zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u)))))); // add_sat r0.w, cb0[19].z, l(-1.000000)
    r0.w = value_16.w;
    uint4 value_17 = asuint(asfloat(r0.wwww) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.w, r0.w, l(0.500000)
    r0.w = value_17.w;
    uint4 value_18 = asuint(ddx(asfloat(v1.zwzz))); // deriv_rtx r1.xy, v1.zwzz
    r1.xy = value_18.xy;
    uint4 value_19 = asuint(ddy(asfloat(v1.zzzw))); // deriv_rty r1.zw, v1.zzzw
    r1.zw = value_19.zw;
    uint4 value_20 = asuint(asfloat(asuint(abs(asfloat(r1.zwzz)))) + asfloat(asuint(abs(asfloat(r1.xyxx))))); // add r1.xy, |r1.zwzz|, |r1.xyxx|
    r1.xy = value_20.xy;
    uint4 value_21 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r1.xxxy)); // div r1.zw, l(1.000000, 1.000000, 1.000000, 1.000000), r1.xxxy
    r1.zw = value_21.zw;
    uint4 value_22 = asuint(saturate(asfloat(asuint(asfloat(r1.xyxx) + asfloat(uint4(0xbdcccccdu, 0xbdcccccdu, 0x0u, 0x0u)))))); // add_sat r1.xy, r1.xyxx, l(-0.100000, -0.100000, 0.000000, 0.000000)
    r1.xy = value_22.xy;
    uint4 value_23 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(abs(asfloat(v1.zwzz)))), asfloat(r1.zwzz), asfloat(asuint(-asfloat(r0.wwww)))))))); // mad_sat r2.xy, |v1.zwzz|, r1.zwzz, -r0.wwww
    r2.xy = value_23.xy;
    uint4 value_24 = asuint(asfloat(asuint(-asfloat(r2.xyxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u))); // add r2.xy, -r2.xyxx, l(1.000000, 1.000000, 0.000000, 0.000000)
    r2.xy = value_24.xy;
    uint4 value_25 = asuint(asfloat(asuint(-asfloat(asuint(abs(asfloat(v1.zwzw)))))) + asfloat(uint4(0x3f7d70a4u, 0x3f7d70a4u, 0x3e99999au, 0x3e99999au))); // add r3.xyzw, -|v1.zwzw|, l(0.990000, 0.990000, 0.300000, 0.300000)
    r3.xyzw = value_25.xyzw;
    uint4 value_26 = asuint(saturate(asfloat(asuint(mad(asfloat(r3.wwwz), asfloat(r1.wwwz), asfloat(uint4(0x0u, 0x0u, 0x3f000000u, 0x3f000000u))))))); // mad_sat r2.zw, r3.wwwz, r1.wwwz, l(0.000000, 0.000000, 0.500000, 0.500000)
    r2.zw = value_26.zw;
    uint4 value_27 = asuint(saturate(asfloat(asuint(mad(asfloat(r3.xxxy), asfloat(r1.zzzw), asfloat(asuint(-asfloat(r0.wwww)))))))); // mad_sat r1.zw, r3.xxxy, r1.zzzw, -r0.wwww
    r1.zw = value_27.zw;
    uint4 value_28 = asuint(asfloat(asuint(-asfloat(r1.zzzw))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r1.zw, -r1.zzzw, l(0.000000, 0.000000, 1.000000, 1.000000)
    r1.zw = value_28.zw;
    uint4 value_29 = asuint(asfloat(r2.zwzz) * asfloat(r2.xyxx)); // mul r2.xy, r2.zwzz, r2.xyxx
    r2.xy = value_29.xy;
    uint4 value_30 = asuint(max(asfloat(r1.zzzw), asfloat(r2.xxxy))); // max r1.zw, r1.zzzw, r2.xxxy
    r1.zw = value_30.zw;
    uint4 value_31 = asuint(asfloat(asuint(-asfloat(r1.zwzz))) + asfloat(uint4(0x3e99999au, 0x3e99999au, 0x0u, 0x0u))); // add r2.xy, -r1.zwzz, l(0.300000, 0.300000, 0.000000, 0.000000)
    r2.xy = value_31.xy;
    uint4 value_32 = asuint(mad(asfloat(r1.xyxx), asfloat(r2.xyxx), asfloat(r1.zwzz))); // mad r1.xy, r1.xyxx, r2.xyxx, r1.zwzz
    r1.xy = value_32.xy;
    uint4 value_33 = asuint(max(asfloat(r1.yyyy), asfloat(r1.xxxx))); // max r0.w, r1.y, r1.x
    r0.w = value_33.w;
    uint4 value_34 = asuint(asfloat(r0.wwww) * asfloat(cb0[42].xxxx)); // mul r0.w, r0.w, cb0[42].x
    r0.w = value_34.w;
    uint4 value_35 = asuint(asfloat(r0.wwww) * asfloat(uint4(0x0u, 0x0u, 0x0u, 0x3ecccccdu))); // mul r1.xyzw, r0.wwww, l(0.000000, 0.000000, 0.000000, 0.400000)
    r1.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(mad(asfloat(r0.yyyy), asfloat(asuint(-asfloat(r1.zzzw))), asfloat(r1.xyzw))); // mad r1.xyzw, r0.yyyy, -r1.zzzw, r1.xyzw
    r1.xyzw = value_36.xyzw;
    uint4 value_37 = asuint(asfloat(asuint(-asfloat(r1.zzzw))) + asfloat(uint4(0x0u, 0x0u, 0x0u, 0x3f800000u))); // add r2.xyzw, -r1.zzzw, l(0.000000, 0.000000, 0.000000, 1.000000)
    r2.xyzw = value_37.xyzw;
    uint4 value_38 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzw), asfloat(r1.xyzw))); // mad r1.xyzw, r0.xxxx, r2.xyzw, r1.xyzw
    r1.xyzw = value_38.xyzw;
    uint4 value_39 = asuint(asfloat(asuint(-asfloat(r1.zzzw))) + asfloat(uint4(0x0u, 0x0u, 0x0u, 0x3f800000u))); // add r2.xyzw, -r1.zzzw, l(0.000000, 0.000000, 0.000000, 1.000000)
    r2.xyzw = value_39.xyzw;
    uint4 value_40 = asuint(saturate(asfloat(asuint(asfloat(v1.xxxx) / asfloat(v1.yyyy))))); // div_sat r0.x, v1.x, v1.y
    r0.x = value_40.x;
    uint4 value_41 = asuint(ddx(asfloat(r0.xxxx))); // deriv_rtx r0.y, r0.x
    r0.y = value_41.y;
    uint4 value_42 = asuint(ddy(asfloat(r0.xxxx))); // deriv_rty r0.w, r0.x
    r0.w = value_42.w;
    uint4 value_43 = asuint(asfloat(r0.xxxx) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0xbf000000u))); // add r0.x, r0.x, l(-0.500000)
    r0.x = value_43.x;
    uint4 value_44 = asuint(asfloat(asuint(abs(asfloat(r0.wwww)))) + asfloat(asuint(abs(asfloat(r0.yyyy))))); // add r0.y, |r0.w|, |r0.y|
    r0.y = value_44.y;
    uint4 value_45 = asuint(asfloat(r0.xxxx) / asfloat(r0.yyyy)); // div r0.x, r0.x, r0.y
    r0.x = value_45.x;
    uint4 value_46 = asuint(saturate(asfloat(asuint(asfloat(r0.xxxx) + asfloat(uint4(0x3fa66666u, 0x3fa66666u, 0x3fa66666u, 0x3fa66666u)))))); // add_sat r0.y, r0.x, l(1.300000)
    r0.y = value_46.y;
    uint4 value_47 = asuint(saturate(asfloat(r0.xxzx))); // mov_sat r0.xz, r0.xxzx
    r0.xz = value_47.xz;
    uint4 value_48 = asuint(asfloat(r0.yyyy) * asfloat(cb0[42].zzzz)); // mul r0.y, r0.y, cb0[42].z
    r0.y = value_48.y;
    uint4 value_49 = asuint(mad(asfloat(r0.yyyy), asfloat(r2.xyzw), asfloat(r1.xyzw))); // mad r1.xyzw, r0.yyyy, r2.xyzw, r1.xyzw
    r1.xyzw = value_49.xyzw;
    uint4 value_50 = asuint(mad(asfloat(r0.zzzz), asfloat(asuint(-asfloat(r1.zzzw))), asfloat(r1.xyzw))); // mad r1.xyzw, r0.zzzz, -r1.zzzw, r1.xyzw
    r1.xyzw = value_50.xyzw;
    uint4 value_51 = asuint(mad(asfloat(r0.xxxx), asfloat(asuint(-asfloat(r1.zzzw))), asfloat(r1.xyzw))); // mad o0.xyzw, r0.xxxx, -r1.zzzw, r1.xyzw
    out_o0.xyzw = value_51.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
