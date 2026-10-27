// Register-explicit recovered HLSL. Not original source.
// PlacemakerUi/DistanceFieldUi ps_4_0 variant ['_MODE_ALPHA']
// Source SHA256 5fc215722665f75838367e5d32f4ef118511334317d64a49aa01db87ba251414
// b0: $Globals 688 bytes
// b1: UnityPerCamera 144 bytes
// cb0[8].x = _BgColor rows=1 cols=4 byte_offset=128
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[40].x = _MainTex_TexelSize rows=1 cols=4 byte_offset=640
// cb0[42].x = _ClipRect rows=1 cols=4 byte_offset=672
// cb1[5].x = _ProjectionParams rows=1 cols=4 byte_offset=80
// t0 / s0 = _MainTex
cbuffer Buffer0:register(b0) { uint4 cb0[43]; };
cbuffer Buffer1:register(b1) { uint4 cb1[6]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 5
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float2 v1_0: TEXCOORD2;
    float2 v1_1: TEXCOORD3;
    float2 v2_0: TEXCOORD5;
    float2 v2_1: TEXCOORD4;
    float4 v3_0: SV_POSITION;
    float4 v4_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 r3;
    uint4 r4;
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
    v2.xy = asuint(input.v2_0);
    v2.zw = asuint(input.v2_1);
    v3.xyzw = asuint(input.v3_0);
    v4.xyzw = asuint(input.v4_0);
    uint4 value_1 = ((asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)) >= asfloat(v0.zzzz)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.x, l(0.000000), v0.z
    r0.x = value_1.x;
    uint4 value_2 = ((r0.xxxx != 0u) ? uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u) : uint4(0x3c23d70au, 0x0u, 0x3c23d70au, 0x0u)); // movc r0.xyz, r0.xxxx, l(1.000000,1.000000,1.000000,0), l(0.010000,0,0.010000,0)
    r0.xyz = value_2.xyz;
    uint4 value_3 = ((asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)) < asfloat(cb1[5].xxxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r1.x, l(0.000000), cb1[5].x
    r1.x = value_3.x;
    uint4 value_4 = ((asfloat(cb1[5].xxxx) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r1.y, cb1[5].x, l(0.000000)
    r1.y = value_4.y;
    uint4 value_5 = (r1.xxxx + asuint(-asint(r1.yyyy))); // iadd r1.x, r1.x, -r1.y
    r1.x = value_5.x;
    uint4 value_6 = asuint(float4(asint(r1.xxxx))); // itof r1.x, r1.x
    r1.x = value_6.x;
    uint4 value_7 = asuint(asfloat(r1.xxxx) * asfloat(v0.xxyx)); // mul r1.yz, r1.xxxx, v0.xxyx
    r1.yz = value_7.yz;
    uint4 value_8 = asuint(ddy(asfloat(r1.yyzy))); // deriv_rty r1.yz, r1.yyzy
    r1.yz = value_8.yz;
    uint4 value_9 = asuint(-asfloat(r1.yyyz)); // mov r2.zw, -r1.yyyz
    r2.zw = value_9.zw;
    uint4 value_10 = asuint(ddx(asfloat(v0.xyxx))); // deriv_rtx r2.xy, v0.xyxx
    r2.xy = value_10.xy;
    uint4 value_11 = asuint(dot(asfloat(r2.xzxx).xy, asfloat(r2.xzxx).xy)).xxxx; // dp2 r1.y, r2.xzxx, r2.xzxx
    r1.y = value_11.y;
    uint4 value_12 = asuint(dot(asfloat(r2.ywyy).xy, asfloat(r2.ywyy).xy)).xxxx; // dp2 r1.z, r2.ywyy, r2.ywyy
    r1.z = value_12.z;
    uint4 value_13 = asuint(sqrt(asfloat(r1.yyzy))); // sqrt r1.yz, r1.yyzy
    r1.yz = value_13.yz;
    uint4 value_14 = asuint(asfloat(r1.yyzy) * asfloat(cb0[40].zzwz)); // mul r1.yz, r1.yyzy, cb0[40].zzwz
    r1.yz = value_14.yz;
    uint4 value_15 = asuint(asfloat(r1.zzzz) * asfloat(uint4(0x3d800000u, 0x3d800000u, 0x3d800000u, 0x3d800000u))); // mul r1.z, r1.z, l(0.062500)
    r1.z = value_15.z;
    uint4 value_16 = asuint(mad(asfloat(r1.yyyy), asfloat(uint4(0x3d800000u, 0x3d800000u, 0x3d800000u, 0x3d800000u)), asfloat(asuint(-asfloat(r1.zzzz))))); // mad r1.y, r1.y, l(0.062500), -r1.z
    r1.y = value_16.y;
    uint4 value_17 = asuint(t0.Sample(s0, asfloat(v0.xyxx).xy)).xyzw; // sample r2.xyzw, v0.xyxx, t0.xyzw, s0
    r2.xyzw = value_17.xyzw;
    uint4 value_18 = asuint(ddy(asfloat(r2.wwww))); // deriv_rty r1.w, r2.w
    r1.w = value_18.w;
    uint4 value_19 = asuint(ddx(asfloat(r2.wwww))); // deriv_rtx r3.x, r2.w
    r3.x = value_19.x;
    uint4 value_20 = asuint(asfloat(asuint(abs(asfloat(r1.wwww)))) + asfloat(asuint(abs(asfloat(r3.xxxx))))); // add r3.z, |r1.w|, |r3.x|
    r3.z = value_20.z;
    uint4 value_21 = ((asfloat(asuint(abs(asfloat(r1.wwww)))) == asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // eq r1.w, |r1.w|, l(0.000000)
    r1.w = value_21.w;
    uint4 value_22 = asuint(asfloat(asuint(abs(asfloat(r3.xxxx)))) / asfloat(r3.zzzz)); // div r3.z, |r3.x|, r3.z
    r3.z = value_22.z;
    uint4 value_23 = ((r1.wwww != 0u) ? uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u) : r3.zzzz); // movc r1.w, r1.w, l(1.000000), r3.z
    r1.w = value_23.w;
    uint4 value_24 = ((asfloat(asuint(abs(asfloat(r3.xxxx)))) == asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // eq r3.z, |r3.x|, l(0.000000)
    r3.z = value_24.z;
    uint4 value_25 = ((r3.zzzz != 0u) ? uint4(0x0u, 0x0u, 0x0u, 0x0u) : r1.wwww); // movc r1.w, r3.z, l(0), r1.w
    r1.w = value_25.w;
    uint4 value_26 = asuint(mad(asfloat(r1.wwww), asfloat(r1.yyyy), asfloat(r1.zzzz))); // mad r1.y, r1.w, r1.y, r1.z
    r1.y = value_26.y;
    uint4 value_27 = asuint(asfloat(r1.xxxx) * asfloat(r2.wwww)); // mul r1.x, r1.x, r2.w
    r1.x = value_27.x;
    uint4 value_28 = asuint(ddy(asfloat(r1.xxxx))); // deriv_rty r1.x, r1.x
    r1.x = value_28.x;
    uint4 value_29 = asuint(-asfloat(r1.xxxx)); // mov r3.y, -r1.x
    r3.y = value_29.y;
    uint4 value_30 = asuint(dot(asfloat(r3.xyxx).xy, asfloat(r3.xyxx).xy)).xxxx; // dp2 r1.x, r3.xyxx, r3.xyxx
    r1.x = value_30.x;
    uint4 value_31 = asuint(rsqrt(asfloat(r1.xxxx))); // rsq r1.x, r1.x
    r1.x = value_31.x;
    uint4 value_32 = asuint(asfloat(r1.xxxx) * asfloat(r3.xxyx)); // mul r1.xz, r1.xxxx, r3.xxyx
    r1.xz = value_32.xz;
    uint4 value_33 = asuint(asfloat(r1.zzzz) + asfloat(r1.zzzz)); // add r1.z, r1.z, r1.z
    r1.z = value_33.z;
    uint4 value_34 = asuint(mad(asfloat(r1.xxxx), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3fc00000u, 0x3fc00000u)), asfloat(r1.zzzz))); // mad r1.x, r1.x, l(1.500000), r1.z
    r1.x = value_34.x;
    uint4 value_35 = asuint(max(asfloat(asuint(abs(asfloat(v0.zzzz)))), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // max r1.z, |v0.z|, l(1.000000)
    r1.z = value_35.z;
    uint4 value_36 = asuint(asfloat(r1.zzzz) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r1.z, r1.z, l(0.500000)
    r1.z = value_36.z;
    uint4 value_37 = asuint(mad(asfloat(r1.xxxx), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3fc00000u, 0x3fc00000u)), asfloat(asuint(-asfloat(r1.zzzz))))); // mad r1.w, r1.x, l(1.500000), -r1.z
    r1.w = value_37.w;
    uint4 value_38 = asuint(mad(asfloat(r1.xxxx), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3fc00000u, 0x3fc00000u)), asfloat(r1.zzzz))); // mad r1.x, r1.x, l(1.500000), r1.z
    r1.x = value_38.x;
    uint4 value_39 = asuint(asfloat(r1.yyyy) * asfloat(r1.xxxw)); // mul r1.xw, r1.yyyy, r1.xxxw
    r1.xw = value_39.xw;
    uint4 value_40 = asuint(asfloat(asuint(-asfloat(v1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r3.x, -v1.x, l(1.000000)
    r3.x = value_40.x;
    uint4 value_41 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.wwww), asfloat(cb0[19].zzzz), asfloat(r3.xxxx)))))); // mad_sat r1.w, r1.w, cb0[19].z, r3.x
    r1.w = value_41.w;
    uint4 value_42 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r3.y, -r1.w, l(1.000000)
    r3.y = value_42.y;
    uint4 value_43 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.yyyy), asfloat(r3.yyyy), asfloat(r1.wwww)))))); // mad_sat r3.y, r1.y, r3.y, r1.w
    r3.y = value_43.y;
    uint4 value_44 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r1.yyyy))), asfloat(r1.wwww), asfloat(r1.wwww)))))); // mad_sat r1.w, -r1.y, r1.w, r1.w
    r1.w = value_44.w;
    uint4 value_45 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r3.yyyy)); // add r3.y, -r1.w, r3.y
    r3.y = value_45.y;
    uint4 value_46 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r2.wwww)); // add r1.w, -r1.w, r2.w
    r1.w = value_46.w;
    uint4 value_47 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) / asfloat(r3.yyyy))))); // div_sat r1.w, r1.w, r3.y
    r1.w = value_47.w;
    uint4 value_48 = asuint(saturate(asfloat(v0.wwww))); // mov_sat r3.y, v0.w
    r3.y = value_48.y;
    uint4 value_49 = asuint(asfloat(r1.wwww) * asfloat(r3.yyyy)); // mul r1.w, r1.w, r3.y
    r1.w = value_49.w;
    uint4 value_50 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov r0.w, l(1.000000)
    r0.w = value_50.w;
    uint4 value_51 = asuint(mad(asfloat(asuint(-asfloat(r1.wwww))), asfloat(uint4(0x3ca3d70bu, 0x0u, 0x3da3d70bu, 0x3e4ccccdu)), asfloat(r0.xyzw))); // mad r0.xyzw, -r1.wwww, l(0.020000, 0.000000, 0.080000, 0.200000), r0.xyzw
    r0.xyzw = value_51.xyzw;
    uint4 value_52 = asuint(asfloat(r1.wwww) * asfloat(uint4(0x3ca3d70bu, 0x0u, 0x3da3d70bu, 0x3e4ccccdu))); // mul r4.xyzw, r1.wwww, l(0.020000, 0.000000, 0.080000, 0.200000)
    r4.xyzw = value_52.xyzw;
    uint4 value_53 = asuint(asfloat(r1.yyyy) * asfloat(asuint(-asfloat(r1.zzzz)))); // mul r1.w, r1.y, -r1.z
    r1.w = value_53.w;
    uint4 value_54 = asuint(asfloat(r1.yyyy) * asfloat(r1.zzzz)); // mul r1.z, r1.y, r1.z
    r1.z = value_54.z;
    uint4 value_55 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.zzzz), asfloat(cb0[19].zzzz), asfloat(r3.xxxx)))))); // mad_sat r1.z, r1.z, cb0[19].z, r3.x
    r1.z = value_55.z;
    uint4 value_56 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.wwww), asfloat(cb0[19].zzzz), asfloat(r3.xxxx)))))); // mad_sat r1.w, r1.w, cb0[19].z, r3.x
    r1.w = value_56.w;
    uint4 value_57 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.xxxx), asfloat(cb0[19].zzzz), asfloat(r3.xxxx)))))); // mad_sat r1.x, r1.x, cb0[19].z, r3.x
    r1.x = value_57.x;
    uint4 value_58 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r3.x, -r1.w, l(1.000000)
    r3.x = value_58.x;
    uint4 value_59 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.yyyy), asfloat(r3.xxxx), asfloat(r1.wwww)))))); // mad_sat r3.x, r1.y, r3.x, r1.w
    r3.x = value_59.x;
    uint4 value_60 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r1.yyyy))), asfloat(r1.wwww), asfloat(r1.wwww)))))); // mad_sat r1.w, -r1.y, r1.w, r1.w
    r1.w = value_60.w;
    uint4 value_61 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r3.xxxx)); // add r3.x, -r1.w, r3.x
    r3.x = value_61.x;
    uint4 value_62 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r2.wwww)); // add r1.w, -r1.w, r2.w
    r1.w = value_62.w;
    uint4 value_63 = asuint(saturate(asfloat(asuint(asfloat(r1.wwww) / asfloat(r3.xxxx))))); // div_sat r1.w, r1.w, r3.x
    r1.w = value_63.w;
    uint4 value_64 = asuint(min(asfloat(asuint(abs(asfloat(v0.zzzz)))), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // min r3.x, |v0.z|, l(1.000000)
    r3.x = value_64.x;
    uint4 value_65 = asuint(asfloat(r1.wwww) * asfloat(r3.xxxx)); // mul r1.w, r1.w, r3.x
    r1.w = value_65.w;
    uint4 value_66 = asuint(mad(asfloat(r1.wwww), asfloat(r0.xyzw), asfloat(r4.xyzw))); // mad r0.xyzw, r1.wwww, r0.xyzw, r4.xyzw
    r0.xyzw = value_66.xyzw;
    uint4 value_67 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.x, l(1.000000)
    r1.w = value_67.w;
    uint4 value_68 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.yyyy), asfloat(r1.wwww), asfloat(r1.xxxx)))))); // mad_sat r1.w, r1.y, r1.w, r1.x
    r1.w = value_68.w;
    uint4 value_69 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r1.yyyy))), asfloat(r1.xxxx), asfloat(r1.xxxx)))))); // mad_sat r1.x, -r1.y, r1.x, r1.x
    r1.x = value_69.x;
    uint4 value_70 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(r1.wwww)); // add r1.w, -r1.x, r1.w
    r1.w = value_70.w;
    uint4 value_71 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(r2.wwww)); // add r1.x, -r1.x, r2.w
    r1.x = value_71.x;
    uint4 value_72 = asuint(saturate(asfloat(asuint(asfloat(r1.xxxx) / asfloat(r1.wwww))))); // div_sat r1.x, r1.x, r1.w
    r1.x = value_72.x;
    uint4 value_73 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.x, l(1.000000)
    r1.x = value_73.x;
    uint4 value_74 = asuint(saturate(asfloat(asuint(-asfloat(v0.wwww))))); // mov_sat r1.w, -v0.w
    r1.w = value_74.w;
    uint4 value_75 = asuint(asfloat(r1.wwww) * asfloat(r1.xxxx)); // mul r1.x, r1.w, r1.x
    r1.x = value_75.x;
    uint4 value_76 = asuint(mad(asfloat(r1.xxxx), asfloat(uint4(0xbe3851ebu, 0xbe4ccccdu, 0xbdf5c290u, 0x0u)), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)))); // mad r3.xyz, r1.xxxx, l(-0.180000, -0.200000, -0.120000, 0.000000), l(1.000000, 1.000000, 1.000000, 0.000000)
    r3.xyz = value_76.xyz;
    uint4 value_77 = asuint(asfloat(cb0[8].xyzx) * asfloat(uint4(0x3e4ccccdu, 0x3e4ccccdu, 0x3e4ccccdu, 0x0u))); // mul r4.xyz, cb0[8].xyzx, l(0.200000, 0.200000, 0.200000, 0.000000)
    r4.xyz = value_77.xyz;
    uint4 value_78 = asuint(mad(asfloat(r2.xyzx), asfloat(v4.xyzx), asfloat(asuint(-asfloat(r4.xyzx))))); // mad r2.xyz, r2.xyzx, v4.xyzx, -r4.xyzx
    r2.xyz = value_78.xyz;
    uint4 value_79 = asuint(mad(asfloat(v2.xxxx), asfloat(r2.xyzx), asfloat(r4.xyzx))); // mad r2.xyz, v2.xxxx, r2.xyzx, r4.xyzx
    r2.xyz = value_79.xyz;
    uint4 value_80 = asuint(asfloat(r2.xyzx) * asfloat(v1.yyyy)); // mul r2.xyz, r2.xyzx, v1.yyyy
    r2.xyz = value_80.xyz;
    uint4 value_81 = asuint(saturate(asfloat(asuint(asfloat(r3.xyzx) * asfloat(r2.xyzx))))); // mul_sat r3.xyz, r3.xyzx, r2.xyzx
    r3.xyz = value_81.xyz;
    uint4 value_82 = asuint(saturate(asfloat(v1.yyyy))); // mov_sat r3.w, v1.y
    r3.w = value_82.w;
    uint4 value_83 = asuint(asfloat(asuint(-asfloat(r0.xyzw))) + asfloat(r3.xyzw)); // add r3.xyzw, -r0.xyzw, r3.xyzw
    r3.xyzw = value_83.xyzw;
    uint4 value_84 = asuint(asfloat(asuint(-asfloat(r1.zzzz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.x, -r1.z, l(1.000000)
    r1.x = value_84.x;
    uint4 value_85 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.yyyy), asfloat(r1.xxxx), asfloat(r1.zzzz)))))); // mad_sat r1.x, r1.y, r1.x, r1.z
    r1.x = value_85.x;
    uint4 value_86 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r1.yyyy))), asfloat(r1.zzzz), asfloat(r1.zzzz)))))); // mad_sat r1.y, -r1.y, r1.z, r1.z
    r1.y = value_86.y;
    uint4 value_87 = asuint(asfloat(asuint(-asfloat(r1.yyyy))) + asfloat(r1.xxxx)); // add r1.x, -r1.y, r1.x
    r1.x = value_87.x;
    uint4 value_88 = asuint(asfloat(asuint(-asfloat(r1.yyyy))) + asfloat(r2.wwww)); // add r1.y, -r1.y, r2.w
    r1.y = value_88.y;
    uint4 value_89 = asuint(saturate(asfloat(asuint(asfloat(r1.yyyy) / asfloat(r1.xxxx))))); // div_sat r1.x, r1.y, r1.x
    r1.x = value_89.x;
    uint4 value_90 = asuint(mad(asfloat(r1.xxxx), asfloat(r3.xyzw), asfloat(r0.xyzw))); // mad r0.xyzw, r1.xxxx, r3.xyzw, r0.xyzw
    r0.xyzw = value_90.xyzw;
    uint4 value_91 = asuint(asfloat(r0.xyzw) * asfloat(v4.wwww)); // mul r0.xyzw, r0.xyzw, v4.wwww
    r0.xyzw = value_91.xyzw;
    uint4 value_92 = ((asfloat(v2.zwzz) >= asfloat(cb0[42].xyxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.xy, v2.zwzz, cb0[42].xyxx
    r1.xy = value_92.xy;
    uint4 value_93 = ((asfloat(cb0[42].zzzw) >= asfloat(v2.zzzw)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r1.zw, cb0[42].zzzw, v2.zzzw
    r1.zw = value_93.zw;
    uint4 value_94 = (r1.xyzw & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)); // and r1.xyzw, r1.xyzw, l(0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000)
    r1.xyzw = value_94.xyzw;
    uint4 value_95 = asuint(asfloat(r1.zwzz) * asfloat(r1.xyxx)); // mul r1.xy, r1.zwzz, r1.xyxx
    r1.xy = value_95.xy;
    uint4 value_96 = asuint(asfloat(r1.yyyy) * asfloat(r1.xxxx)); // mul r1.x, r1.y, r1.x
    r1.x = value_96.x;
    uint4 value_97 = asuint(asfloat(r0.xyzw) * asfloat(r1.xxxx)); // mul o0.xyzw, r0.xyzw, r1.xxxx
    out_o0.xyzw = value_97.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
