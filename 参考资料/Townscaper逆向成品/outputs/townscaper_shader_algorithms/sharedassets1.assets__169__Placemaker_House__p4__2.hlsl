// Register-explicit recovered HLSL. Not original source.
// Placemaker/House ps_4_0 variant []
// Source SHA256 7975b624020b6f02f6fdc00484aa5b4a7b87d86f02f41ce4b4e7a5175bee86fe
// b0: $Globals 656 bytes
// cb0[11].x = _RoofColor rows=1 cols=4 byte_offset=176
// cb0[12].x = _HouseTex_TexelSize rows=1 cols=4 byte_offset=192
// cb0[15].x = _MaterialTex_TexelSize rows=1 cols=4 byte_offset=240
// cb0[18].x = _Dim rows=1 cols=4 byte_offset=288
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// t0 / s1 = _HouseTex
// t1 / s0 = _HouseTypeTex
// t2 / s2 = _MaterialTex
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
SamplerState s2:register(s2);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
Texture2D<float4> t2:register(t2);
// temporary registers: 4
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float2 v1_0: TEXCOORD2;
    float2 v1_1: TEXCOORD3;
    float4 v2_0: SV_POSITION;
    float4 v3_0: COLOR0;
    float4 v4_0: COLOR1;
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
    uint4 v4;
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xy = asuint(input.v1_0);
    v1.zw = asuint(input.v1_1);
    v2.xyzw = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    v4.xyzw = asuint(input.v4_0);
    uint4 value_1 = asuint(ddx(asfloat(v1.xywx))); // deriv_rtx r0.xyz, v1.xywx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(ddy(asfloat(v1.xywx))); // deriv_rty r1.xyz, v1.xywx
    r1.xyz = value_2.xyz;
    uint4 value_3 = asuint(asfloat(asuint(abs(asfloat(r0.xyzx)))) + asfloat(asuint(abs(asfloat(r1.xyzx))))); // add r0.xyz, |r0.xyzx|, |r1.xyzx|
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(asfloat(r0.zzzz) + asfloat(v1.wwww)); // add r0.w, r0.z, v1.w
    r0.w = value_4.w;
    uint4 value_5 = ((asfloat(r0.wwww) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.w, r0.w, l(0.000000)
    r0.w = value_5.w;
    if (r0.wwww.x != 0u) discard; // discard_nz r0.w
    uint4 value_7 = asuint(asfloat(v0.xyxx) * asfloat(cb0[12].zwzz)); // mul r1.xy, v0.xyxx, cb0[12].zwzz
    r1.xy = value_7.xy;
    uint4 value_8 = asuint(ddx(asfloat(r1.xyxx))); // deriv_rtx r2.xy, r1.xyxx
    r2.xy = value_8.xy;
    uint4 value_9 = asuint(ddy(asfloat(r1.xxxy))); // deriv_rty r2.zw, r1.xxxy
    r2.zw = value_9.zw;
    uint4 value_10 = asuint(dot(asfloat(r2.xzxx).xy, asfloat(r2.xzxx).xy)).xxxx; // dp2 r0.w, r2.xzxx, r2.xzxx
    r0.w = value_10.w;
    uint4 value_11 = asuint(dot(asfloat(r2.ywyy).xy, asfloat(r2.ywyy).xy)).xxxx; // dp2 r1.x, r2.ywyy, r2.ywyy
    r1.x = value_11.x;
    uint4 value_12 = asuint(sqrt(asfloat(r1.xxxx))); // sqrt r1.y, r1.x
    r1.y = value_12.y;
    uint4 value_13 = asuint(sqrt(asfloat(r0.wwww))); // sqrt r1.x, r0.w
    r1.x = value_13.x;
    uint4 value_14 = asuint(max(asfloat(r1.xyxx), asfloat(uint4(0x3727c5acu, 0x3727c5acu, 0x0u, 0x0u)))); // max r1.xy, r1.xyxx, l(0.000010, 0.000010, 0.000000, 0.000000)
    r1.xy = value_14.xy;
    uint4 value_15 = asuint(min(asfloat(r1.xyxx), asfloat(uint4(0x47c35000u, 0x47c35000u, 0x0u, 0x0u)))); // min r1.xy, r1.xyxx, l(100000.000000, 100000.000000, 0.000000, 0.000000)
    r1.xy = value_15.xy;
    uint4 value_16 = asuint(mad(asfloat(v0.xyxy), asfloat(cb0[12].zwzw), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3f000000u, 0x3f000000u)))); // mad r2.xyzw, v0.xyxy, cb0[12].zwzw, l(1.500000, 1.500000, 0.500000, 0.500000)
    r2.xyzw = value_16.xyzw;
    uint4 value_17 = asuint(asfloat(r2.xyzw) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r2.xyzw, r2.xyzw, l(0.500000, 0.500000, 0.500000, 0.500000)
    r2.xyzw = value_17.xyzw;
    uint4 value_18 = asuint(frac(asfloat(r2.xxxy))); // frc r1.zw, r2.xxxy
    r1.zw = value_18.zw;
    uint4 value_19 = asuint(floor(asfloat(r2.xyzw))); // round_ni r2.xyzw, r2.xyzw
    r2.xyzw = value_19.xyzw;
    uint4 value_20 = asuint(mad(asfloat(r2.xyzw), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf000000u, 0xbf000000u, 0x3f000000u, 0x3f000000u)))); // mad r2.xyzw, r2.xyzw, l(2.000000, 2.000000, 2.000000, 2.000000), l(-0.500000, -0.500000, 0.500000, 0.500000)
    r2.xyzw = value_20.xyzw;
    uint4 value_21 = asuint(mad(asfloat(r1.zzzw), asfloat(uint4(0x0u, 0x0u, 0x40000000u, 0x40000000u)), asfloat(uint4(0x0u, 0x0u, 0xbf800000u, 0xbf800000u)))); // mad r1.zw, r1.zzzw, l(0.000000, 0.000000, 2.000000, 2.000000), l(0.000000, 0.000000, -1.000000, -1.000000)
    r1.zw = value_21.zw;
    uint4 value_22 = asuint(asfloat(asuint(abs(asfloat(r1.zwzz)))) / asfloat(r1.xyxx)); // div r1.xy, |r1.zwzz|, r1.xyxx
    r1.xy = value_22.xy;
    uint4 value_23 = asuint(asfloat(r0.yyyy) + asfloat(r0.xxxx)); // add r0.x, r0.y, r0.x
    r0.x = value_23.x;
    uint4 value_24 = asuint(asfloat(uint4(0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u)) / asfloat(r0.xxxx)); // div r0.x, l(0.003000), r0.x
    r0.x = value_24.x;
    uint4 value_25 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(r1.xyxx)); // add r0.xy, -r0.xxxx, r1.xyxx
    r0.xy = value_25.xy;
    uint4 value_26 = asuint(asfloat(cb0[19].zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.w, cb0[19].z, l(-1.000000)
    r0.w = value_26.w;
    uint4 value_27 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x0u, 0x0u)), asfloat(r0.xyxx)))))); // mad_sat r0.xy, -r0.wwww, l(0.500000, 0.500000, 0.000000, 0.000000), r0.xyxx
    r0.xy = value_27.xy;
    uint4 value_28 = asuint(asfloat(asuint(-asfloat(r2.xyxx))) + asfloat(r2.zwzz)); // add r1.xy, -r2.xyxx, r2.zwzz
    r1.xy = value_28.xy;
    uint4 value_29 = asuint(mad(asfloat(r0.xyxx), asfloat(r1.xyxx), asfloat(r2.xyxx))); // mad r0.xy, r0.xyxx, r1.xyxx, r2.xyxx
    r0.xy = value_29.xy;
    uint4 value_30 = asuint(asfloat(r0.xyxx) * asfloat(cb0[12].xyxx)); // mul r0.xy, r0.xyxx, cb0[12].xyxx
    r0.xy = value_30.xy;
    uint4 value_31 = asuint(t1.SampleLevel(s0, asfloat(r0.xyxx).xy, asfloat(cb0[18].xxxx).x)).xyzw; // sample_l r1.xyzw, r0.xyxx, t1.xyzw, s0, cb0[18].x
    r1.xyzw = value_31.xyzw;
    uint4 value_32 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x3fb33333u, 0x3fb33333u, 0x3fb33333u, 0x3fb33333u))); // mul r1.x, r1.y, l(1.400000)
    r1.x = value_32.x;
    uint4 value_33 = asuint(floor(asfloat(asuint(abs(asfloat(r0.xxxx)))))); // round_ni r1.y, |r0.x|
    r1.y = value_33.y;
    uint4 value_34 = asuint(t0.SampleLevel(s1, asfloat(r0.xyxx).xy, asfloat(cb0[18].xxxx).x)).xyzw; // sample_l r2.xyzw, r0.xyxx, t0.xyzw, s1, cb0[18].x
    r2.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(asfloat(r1.yyyy) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r0.x, r1.y, l(0.500000)
    r0.x = value_35.x;
    uint4 value_36 = asuint(asfloat(r0.xxxx) * asfloat(cb0[15].xxxx)); // mul r0.x, r0.x, cb0[15].x
    r0.x = value_36.x;
    uint4 value_37 = uint4(0x3e800000u, 0x3e800000u, 0x3e800000u, 0x3e800000u); // mov r0.y, l(0.250000)
    r0.y = value_37.y;
    uint4 value_38 = asuint(t2.SampleLevel(s2, asfloat(r0.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r0.xyxx, t2.xyzw, s2, l(0.000000)
    r3.xyzw = value_38.xyzw;
    uint4 value_39 = asuint(asfloat(asuint(-asfloat(r3.xxyz))) + asfloat(cb0[11].xxyz)); // add r1.yzw, -r3.xxyz, cb0[11].xxyz
    r1.yzw = value_39.yzw;
    uint4 value_40 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.xxxx), asfloat(r1.yzwy), asfloat(r3.xyzx)))))); // mad_sat r1.xyz, r1.xxxx, r1.yzwy, r3.xyzx
    r1.xyz = value_40.xyz;
    uint4 value_41 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.x, r2.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.x = value_41.x;
    uint4 value_42 = asuint(asfloat(r0.xxxx) + asfloat(r1.xyzx)); // add r3.xyz, r0.xxxx, r1.xyzx
    r3.xyz = value_42.xyz;
    uint4 value_43 = asuint(asfloat(r3.xyzx) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0x0u))); // add r3.xyz, r3.xyzx, l(-0.500000, -0.500000, -0.500000, 0.000000)
    r3.xyz = value_43.xyz;
    uint4 value_44 = asuint(max(asfloat(r3.xyzx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r3.xyz, r3.xyzx, l(0.000000, 0.000000, 0.000000, 0.000000)
    r3.xyz = value_44.xyz;
    uint4 value_45 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(r3.xyzx)); // add r3.xyz, -r1.xyzx, r3.xyzx
    r3.xyz = value_45.xyz;
    uint4 value_46 = asuint(mad(asfloat(r2.wwww), asfloat(r3.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r2.wwww, r3.xyzx, r1.xyzx
    r1.xyz = value_46.xyz;
    uint4 value_47 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(r2.xyzx)); // add r2.xyz, -r1.xyzx, r2.xyzx
    r2.xyz = value_47.xyz;
    uint4 value_48 = asuint(mad(asfloat(r2.wwww), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, r2.wwww, r2.xyzx, r1.xyzx
    r1.xyz = value_48.xyz;
    uint4 value_49 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x0u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0x0u)))); // mad r2.xyz, r1.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), l(-1.000000, -1.000000, -1.000000, 0.000000)
    r2.xyz = value_49.xyz;
    uint4 value_50 = asuint(ddx(asfloat(v0.zwzz))); // deriv_rtx r3.xy, v0.zwzz
    r3.xy = value_50.xy;
    uint4 value_51 = asuint(ddy(asfloat(v0.zzzw))); // deriv_rty r3.zw, v0.zzzw
    r3.zw = value_51.zw;
    uint4 value_52 = asuint(dot(asfloat(r3.xzxx).xy, asfloat(r3.xzxx).xy)).xxxx; // dp2 r0.x, r3.xzxx, r3.xzxx
    r0.x = value_52.x;
    uint4 value_53 = asuint(dot(asfloat(r3.ywyy).xy, asfloat(r3.ywyy).xy)).xxxx; // dp2 r0.y, r3.ywyy, r3.ywyy
    r0.y = value_53.y;
    uint4 value_54 = asuint(sqrt(asfloat(r0.xyxx))); // sqrt r3.xy, r0.xyxx
    r3.xy = value_54.xy;
    uint4 value_55 = ((asfloat(uint4(0x3a83126fu, 0x3a83126fu, 0x0u, 0x0u)) >= asfloat(r3.xyxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.xy, l(0.001000, 0.001000, 0.000000, 0.000000), r3.xyxx
    r0.xy = value_55.xy;
    uint4 value_56 = (r0.xyxx & uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x0u)); // and r0.xy, r0.xyxx, l(0x3f800000, 0x3f800000, 0, 0)
    r0.xy = value_56.xy;
    uint4 value_57 = asuint(asfloat(asuint(-asfloat(asuint(abs(asfloat(v0.zzzw)))))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r3.zw, -|v0.zzzw|, l(0.000000, 0.000000, 1.000000, 1.000000)
    r3.zw = value_57.zw;
    uint4 value_58 = asuint(asfloat(r3.zwzz) / asfloat(r3.xyxx)); // div r3.xy, r3.zwzz, r3.xyxx
    r3.xy = value_58.xy;
    uint4 value_59 = asuint(saturate(asfloat(asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(r3.xyxx))))); // add_sat r3.xy, -r0.wwww, r3.xyxx
    r3.xy = value_59.xy;
    uint4 value_60 = asuint(asfloat(asuint(-asfloat(r3.xxxy))) + asfloat(uint4(0x0u, 0x0u, 0x3f800000u, 0x3f800000u))); // add r3.zw, -r3.xxxy, l(0.000000, 0.000000, 1.000000, 1.000000)
    r3.zw = value_60.zw;
    uint4 value_61 = asuint(mad(asfloat(r0.xyxx), asfloat(r3.zwzz), asfloat(r3.xyxx))); // mad r0.xy, r0.xyxx, r3.zwzz, r3.xyxx
    r0.xy = value_61.xy;
    uint4 value_62 = asuint(min(asfloat(r0.yyyy), asfloat(r0.xxxx))); // min r0.x, r0.y, r0.x
    r0.x = value_62.x;
    uint4 value_63 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r0.x, l(1.000000)
    r0.x = value_63.x;
    uint4 value_64 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r0.x, r0.x, l(0.500000)
    r0.x = value_64.x;
    uint4 value_65 = asuint(max(asfloat(r0.xxxx), asfloat(v1.zzzz))); // max r0.x, r0.x, v1.z
    r0.x = value_65.x;
    uint4 value_66 = asuint(asfloat(r0.xxxx) * asfloat(cb0[18].yyyy)); // mul r0.x, r0.x, cb0[18].y
    r0.x = value_66.x;
    uint4 value_67 = asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzx), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)))); // mad r2.xyz, r0.xxxx, r2.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r2.xyz = value_67.xyz;
    uint4 value_68 = asuint(mad(asfloat(r1.xyzx), asfloat(r2.xyzx), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0x0u)))); // mad r1.xyz, r1.xyzx, r2.xyzx, l(-1.000000, -1.000000, -1.000000, 0.000000)
    r1.xyz = value_68.xyz;
    uint4 value_69 = asuint(asfloat(v1.wwww) + asfloat(uint4(0xbb03126fu, 0xbb03126fu, 0xbb03126fu, 0xbb03126fu))); // add r0.x, v1.w, l(-0.002000)
    r0.x = value_69.x;
    uint4 value_70 = asuint(asfloat(r0.xxxx) / asfloat(r0.zzzz)); // div r0.x, r0.x, r0.z
    r0.x = value_70.x;
    uint4 value_71 = asuint(saturate(asfloat(asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(r0.xxxx))))); // add_sat r0.x, -r0.w, r0.x
    r0.x = value_71.x;
    uint4 value_72 = asuint(mad(asfloat(r0.xxxx), asfloat(r1.xyzx), asfloat(uint4(0x3e99999au, 0x3e99999au, 0x3e99999au, 0x0u)))); // mad r0.xyz, r0.xxxx, r1.xyzx, l(0.300000, 0.300000, 0.300000, 0.000000)
    r0.xyz = value_72.xyz;
    uint4 value_73 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r0.xyzx), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x0u)))); // mad r0.xyz, cb0[29].xxxx, r0.xyzx, l(0.700000, 0.700000, 0.700000, 0.000000)
    r0.xyz = value_73.xyz;
    uint4 value_74 = asuint(dot(asfloat(r0.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r0.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_74.w;
    uint4 value_75 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(r0.xyzx)); // add r1.xyz, -r0.wwww, r0.xyzx
    r1.xyz = value_75.xyz;
    uint4 value_76 = asuint(mad(asfloat(v3.wwww), asfloat(r1.xyzx), asfloat(r0.wwww))); // mad r1.xyz, v3.wwww, r1.xyzx, r0.wwww
    r1.xyz = value_76.xyz;
    uint4 value_77 = asuint(asfloat(r1.xyzx) * asfloat(v3.xyzx)); // mul r1.xyz, r1.xyzx, v3.xyzx
    r1.xyz = value_77.xyz;
    uint4 value_78 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.w, r1.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.w = value_78.w;
    uint4 value_79 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r1.w, -r0.w, l(0.600000)
    r1.w = value_79.w;
    uint4 value_80 = asuint(asfloat(r0.wwww) + asfloat(asuint(-asfloat(r1.wwww)))); // add r0.w, r0.w, -r1.w
    r0.w = value_80.w;
    uint4 value_81 = asuint(mad(asfloat(r0.wwww), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r0.wwww, l(0.100000, 0.100000, 0.100000, 0.000000), r1.xyzx
    r1.xyz = value_81.xyz;
    uint4 value_82 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r2.xyz, -r1.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r2.xyz = value_82.xyz;
    uint4 value_83 = asuint(mad(asfloat(r2.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r1.xyzx))); // mad r1.xyz, r2.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r1.xyzx
    r1.xyz = value_83.xyz;
    uint4 value_84 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(r1.xyzx)); // add r1.xyz, -r0.xyzx, r1.xyzx
    r1.xyz = value_84.xyz;
    uint4 value_85 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r1.xyzx), asfloat(r0.xyzx))); // mad o0.xyz, cb0[29].yyyy, r1.xyzx, r0.xyzx
    out_o0.xyz = value_85.xyz;
    uint4 value_86 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov o0.w, l(1.000000)
    out_o0.w = value_86.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
