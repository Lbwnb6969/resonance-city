// Register-explicit recovered HLSL. Not original source.
// Placemaker/Door ps_4_0 variant []
// Source SHA256 d702b8b4e087f3365504ff3ef44f42a8413e0be61b7459e59c906db7677cc860
// b0: $Globals 672 bytes
// cb0[12].x = _HouseTex_TexelSize rows=1 cols=4 byte_offset=192
// cb0[18].x = _Dim rows=1 cols=4 byte_offset=288
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[29].x = _ShadingTexLightStack rows=1 cols=4 byte_offset=464
// t0 / s1 = _HouseTex
// t1 / s0 = _HouseTypeTex
cbuffer Buffer0:register(b0) { uint4 cb0[30]; };
SamplerState s0:register(s0);
SamplerState s1:register(s1);
Texture2D<float4> t0:register(t0);
Texture2D<float4> t1:register(t1);
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
    uint4 value_1 = asuint(ddx(asfloat(v1.xyxx))); // deriv_rtx r0.xy, v1.xyxx
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(ddy(asfloat(v1.xxxy))); // deriv_rty r0.zw, v1.xxxy
    r0.zw = value_2.zw;
    uint4 value_3 = asuint(asfloat(asuint(abs(asfloat(r0.zwzz)))) + asfloat(asuint(abs(asfloat(r0.xyxx))))); // add r0.xy, |r0.zwzz|, |r0.xyxx|
    r0.xy = value_3.xy;
    uint4 value_4 = asuint(asfloat(r0.yyyy) + asfloat(r0.xxxx)); // add r0.x, r0.y, r0.x
    r0.x = value_4.x;
    uint4 value_5 = asuint(asfloat(uint4(0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u, 0x3b449ba6u)) / asfloat(r0.xxxx)); // div r0.x, l(0.003000), r0.x
    r0.x = value_5.x;
    uint4 value_6 = asuint(asfloat(v0.xxyx) * asfloat(cb0[12].zzwz)); // mul r0.yz, v0.xxyx, cb0[12].zzwz
    r0.yz = value_6.yz;
    uint4 value_7 = asuint(ddx(asfloat(r0.yyzz))); // deriv_rtx r1.xyzw, r0.yyzz
    r1.xyzw = value_7.xyzw;
    uint4 value_8 = asuint(ddy(asfloat(r0.yzyz))); // deriv_rty r2.xyzw, r0.yzyz
    r2.xyzw = value_8.xyzw;
    uint4 value_9 = asuint(asfloat(asuint(abs(asfloat(r1.yywy)))) + asfloat(asuint(abs(asfloat(r2.zzwz))))); // add r0.yz, |r1.yywy|, |r2.zzwz|
    r0.yz = value_9.yz;
    uint4 value_10 = r2.xxxy; // mov r1.yw, r2.xxxy
    r1.yw = value_10.yw;
    uint4 value_11 = asuint(min(asfloat(r0.zzzz), asfloat(r0.yyyy))); // min r0.y, r0.z, r0.y
    r0.y = value_11.y;
    uint4 value_12 = asuint(saturate(asfloat(asuint(mad(asfloat(r0.yyyy), asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))))))); // mad_sat r0.y, r0.y, l(0.600000), l(-1.000000)
    r0.y = value_12.y;
    uint4 value_13 = asuint(mad(asfloat(r0.yyyy), asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0xbf333333u)), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // mad r0.y, r0.y, l(-0.700000), l(1.000000)
    r0.y = value_13.y;
    uint4 value_14 = asuint(dot(asfloat(r1.xyxx).xy, asfloat(r1.xyxx).xy)).xxxx; // dp2 r0.z, r1.xyxx, r1.xyxx
    r0.z = value_14.z;
    uint4 value_15 = asuint(dot(asfloat(r1.zwzz).xy, asfloat(r1.zwzz).xy)).xxxx; // dp2 r0.w, r1.zwzz, r1.zwzz
    r0.w = value_15.w;
    uint4 value_16 = asuint(sqrt(asfloat(r0.zwzz))); // sqrt r1.xy, r0.zwzz
    r1.xy = value_16.xy;
    uint4 value_17 = asuint(max(asfloat(r1.xxxy), asfloat(uint4(0x0u, 0x0u, 0x3727c5acu, 0x3727c5acu)))); // max r0.zw, r1.xxxy, l(0.000000, 0.000000, 0.000010, 0.000010)
    r0.zw = value_17.zw;
    uint4 value_18 = asuint(min(asfloat(r0.zzzw), asfloat(uint4(0x0u, 0x0u, 0x47c35000u, 0x47c35000u)))); // min r0.zw, r0.zzzw, l(0.000000, 0.000000, 100000.000000, 100000.000000)
    r0.zw = value_18.zw;
    uint4 value_19 = asuint(mad(asfloat(v0.xyxy), asfloat(cb0[12].zwzw), asfloat(uint4(0x3fc00000u, 0x3fc00000u, 0x3f000000u, 0x3f000000u)))); // mad r1.xyzw, v0.xyxy, cb0[12].zwzw, l(1.500000, 1.500000, 0.500000, 0.500000)
    r1.xyzw = value_19.xyzw;
    uint4 value_20 = asuint(asfloat(r1.xyzw) * asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // mul r1.xyzw, r1.xyzw, l(0.500000, 0.500000, 0.500000, 0.500000)
    r1.xyzw = value_20.xyzw;
    uint4 value_21 = asuint(frac(asfloat(r1.xyxx))); // frc r2.xy, r1.xyxx
    r2.xy = value_21.xy;
    uint4 value_22 = asuint(floor(asfloat(r1.xyzw))); // round_ni r1.xyzw, r1.xyzw
    r1.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(mad(asfloat(r1.xyzw), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x40000000u)), asfloat(uint4(0xbf000000u, 0xbf000000u, 0x3f000000u, 0x3f000000u)))); // mad r1.xyzw, r1.xyzw, l(2.000000, 2.000000, 2.000000, 2.000000), l(-0.500000, -0.500000, 0.500000, 0.500000)
    r1.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(mad(asfloat(r2.xyxx), asfloat(uint4(0x40000000u, 0x40000000u, 0x0u, 0x0u)), asfloat(uint4(0xbf800000u, 0xbf800000u, 0x0u, 0x0u)))); // mad r2.xy, r2.xyxx, l(2.000000, 2.000000, 0.000000, 0.000000), l(-1.000000, -1.000000, 0.000000, 0.000000)
    r2.xy = value_24.xy;
    uint4 value_25 = asuint(asfloat(asuint(abs(asfloat(r2.xxxy)))) / asfloat(r0.zzzw)); // div r0.zw, |r2.xxxy|, r0.zzzw
    r0.zw = value_25.zw;
    uint4 value_26 = asuint(asfloat(asuint(-asfloat(r0.xxxx))) + asfloat(r0.zzwz)); // add r0.xz, -r0.xxxx, r0.zzwz
    r0.xz = value_26.xz;
    uint4 value_27 = asuint(asfloat(cb0[19].zzzz) + asfloat(uint4(0xbf800000u, 0xbf800000u, 0xbf800000u, 0xbf800000u))); // add r0.w, cb0[19].z, l(-1.000000)
    r0.w = value_27.w;
    uint4 value_28 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r0.wwww))), asfloat(uint4(0x3f000000u, 0x0u, 0x3f000000u, 0x0u)), asfloat(r0.xxzx)))))); // mad_sat r0.xz, -r0.wwww, l(0.500000, 0.000000, 0.500000, 0.000000), r0.xxzx
    r0.xz = value_28.xz;
    uint4 value_29 = asuint(asfloat(asuint(-asfloat(r1.xxxy))) + asfloat(r1.zzzw)); // add r1.zw, -r1.xxxy, r1.zzzw
    r1.zw = value_29.zw;
    uint4 value_30 = asuint(mad(asfloat(r0.xxzx), asfloat(r1.zzwz), asfloat(r1.xxyx))); // mad r0.xz, r0.xxzx, r1.zzwz, r1.xxyx
    r0.xz = value_30.xz;
    uint4 value_31 = asuint(asfloat(r0.xxzx) * asfloat(cb0[12].xxyx)); // mul r0.xz, r0.xxzx, cb0[12].xxyx
    r0.xz = value_31.xz;
    uint4 value_32 = ((asfloat(r0.xxxx) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.w, r0.x, l(0.000000)
    r0.w = value_32.w;
    if (r0.wwww.x != 0u) discard; // discard_nz r0.w
    uint4 value_34 = asuint(t0.SampleLevel(s1, asfloat(r0.xzxx).xy, asfloat(cb0[18].xxxx).x)).xyzw; // sample_l r1.xyzw, r0.xzxx, t0.xyzw, s1, cb0[18].x
    r1.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(t1.SampleLevel(s0, asfloat(r0.xzxx).xy, asfloat(cb0[18].xxxx).x)).xyzw; // sample_l r2.xyzw, r0.xzxx, t1.xyzw, s0, cb0[18].x
    r2.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(asfloat(asuint(-asfloat(r2.zzzz))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.x, -r2.z, l(1.000000)
    r0.x = value_36.x;
    uint4 value_37 = asuint(asfloat(r0.xxxx) * asfloat(uint4(0x3f800000u, 0x0u, 0x3f4ccccdu, 0x0u))); // mul r0.xzw, r0.xxxx, l(1.000000, 0.000000, 0.800000, 0.000000)
    r0.xzw = value_37.xzw;
    uint4 value_38 = asuint(asfloat(r0.yyyy) * asfloat(r1.wwww)); // mul r0.y, r0.y, r1.w
    r0.y = value_38.y;
    uint4 value_39 = asuint(mad(asfloat(v1.zzzz), asfloat(uint4(0xbe4cccccu, 0xbeccccccu, 0xbf400000u, 0x0u)), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)))); // mad r2.xyz, v1.zzzz, l(-0.200000, -0.400000, -0.750000, 0.000000), l(1.000000, 1.000000, 1.000000, 0.000000)
    r2.xyz = value_39.xyz;
    uint4 value_40 = asuint(asfloat(r1.xyzx) * asfloat(r2.xyzx)); // mul r3.xyz, r1.xyzx, r2.xyzx
    r3.xyz = value_40.xyz;
    uint4 value_41 = asuint(dot(asfloat(r3.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r2.w, r3.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r2.w = value_41.w;
    uint4 value_42 = asuint(asfloat(r2.wwww) + asfloat(v4.xyzx)); // add r3.xyz, r2.wwww, v4.xyzx
    r3.xyz = value_42.xyz;
    uint4 value_43 = asuint(asfloat(r3.xyzx) + asfloat(uint4(0xbf000000u, 0xbf000000u, 0xbf000000u, 0x0u))); // add r3.xyz, r3.xyzx, l(-0.500000, -0.500000, -0.500000, 0.000000)
    r3.xyz = value_43.xyz;
    uint4 value_44 = asuint(max(asfloat(r3.xyzx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r3.xyz, r3.xyzx, l(0.000000, 0.000000, 0.000000, 0.000000)
    r3.xyz = value_44.xyz;
    uint4 value_45 = asuint(asfloat(r3.xyzx) + asfloat(asuint(-asfloat(v4.xyzx)))); // add r3.xyz, r3.xyzx, -v4.xyzx
    r3.xyz = value_45.xyz;
    uint4 value_46 = asuint(mad(asfloat(r0.yyyy), asfloat(r3.xyzx), asfloat(v4.xyzx))); // mad r3.xyz, r0.yyyy, r3.xyzx, v4.xyzx
    r3.xyz = value_46.xyz;
    uint4 value_47 = asuint(mad(asfloat(r1.xyzx), asfloat(r2.xyzx), asfloat(asuint(-asfloat(r3.xyzx))))); // mad r1.xyz, r1.xyzx, r2.xyzx, -r3.xyzx
    r1.xyz = value_47.xyz;
    uint4 value_48 = asuint(mad(asfloat(r0.yyyy), asfloat(r1.xyzx), asfloat(r3.xyzx))); // mad r1.xyz, r0.yyyy, r1.xyzx, r3.xyzx
    r1.xyz = value_48.xyz;
    uint4 value_49 = asuint(asfloat(r1.xyzx) + asfloat(uint4(0xbf333333u, 0xbf333333u, 0xbf333333u, 0x0u))); // add r1.xyz, r1.xyzx, l(-0.700000, -0.700000, -0.700000, 0.000000)
    r1.xyz = value_49.xyz;
    uint4 value_50 = asuint(mad(asfloat(cb0[29].xxxx), asfloat(r1.xyzx), asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x0u)))); // mad r1.xyz, cb0[29].xxxx, r1.xyzx, l(0.700000, 0.700000, 0.700000, 0.000000)
    r1.xyz = value_50.xyz;
    uint4 value_51 = asuint(mad(asfloat(r1.wwww), asfloat(uint4(0x3e4cccccu, 0x3e4cccccu, 0x3e4cccccu, 0x3e4cccccu)), asfloat(uint4(0x3f4ccccdu, 0x3f4ccccdu, 0x3f4ccccdu, 0x3f4ccccdu)))); // mad r0.y, r1.w, l(0.200000), l(0.800000)
    r0.y = value_51.y;
    uint4 value_52 = asuint(dot(asfloat(r1.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r1.w, r1.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r1.w = value_52.w;
    uint4 value_53 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r1.xyzx)); // add r2.xyz, -r1.wwww, r1.xyzx
    r2.xyz = value_53.xyz;
    uint4 value_54 = asuint(mad(asfloat(v3.wwww), asfloat(r2.xyzx), asfloat(r1.wwww))); // mad r2.xyz, v3.wwww, r2.xyzx, r1.wwww
    r2.xyz = value_54.xyz;
    uint4 value_55 = asuint(asfloat(v1.zzzz) * asfloat(uint4(0x3f19999au, 0x3dcccccdu, 0x0u, 0x0u))); // mul r3.xyz, v1.zzzz, l(0.600000, 0.100000, 0.000000, 0.000000)
    r3.xyz = value_55.xyz;
    uint4 value_56 = asuint(mad(asfloat(v3.xyzx), asfloat(r0.yyyy), asfloat(r3.xyzx))); // mad r3.xyz, v3.xyzx, r0.yyyy, r3.xyzx
    r3.xyz = value_56.xyz;
    uint4 value_57 = asuint(asfloat(r2.xyzx) * asfloat(r3.xyzx)); // mul r2.xyz, r2.xyzx, r3.xyzx
    r2.xyz = value_57.xyz;
    uint4 value_58 = asuint(dot(asfloat(r2.xyzx).xyz, asfloat(uint4(0x3e4ccccdu, 0x3f333333u, 0x3dcccccdu, 0x0u)).xyz)).xxxx; // dp3 r0.y, r2.xyzx, l(0.200000, 0.700000, 0.100000, 0.000000)
    r0.y = value_58.y;
    uint4 value_59 = asuint(asfloat(asuint(-asfloat(r0.yyyy))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x3f19999au))); // add r1.w, -r0.y, l(0.600000)
    r1.w = value_59.w;
    uint4 value_60 = asuint(asfloat(r0.yyyy) + asfloat(asuint(-asfloat(r1.wwww)))); // add r0.y, r0.y, -r1.w
    r0.y = value_60.y;
    uint4 value_61 = asuint(mad(asfloat(r0.yyyy), asfloat(uint4(0x3dcccccdu, 0x3dcccccdu, 0x3dcccccdu, 0x0u)), asfloat(r2.xyzx))); // mad r2.xyz, r0.yyyy, l(0.100000, 0.100000, 0.100000, 0.000000), r2.xyzx
    r2.xyz = value_61.xyz;
    uint4 value_62 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(uint4(0x3f19999au, 0x3f19999au, 0x3f19999au, 0x0u))); // add r3.xyz, -r2.xyzx, l(0.600000, 0.600000, 0.600000, 0.000000)
    r3.xyz = value_62.xyz;
    uint4 value_63 = asuint(mad(asfloat(r3.xyzx), asfloat(uint4(0xbe4ccccdu, 0xbd4ccccdu, 0x3e4ccccdu, 0x0u)), asfloat(r2.xyzx))); // mad r2.xyz, r3.xyzx, l(-0.200000, -0.050000, 0.200000, 0.000000), r2.xyzx
    r2.xyz = value_63.xyz;
    uint4 value_64 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(r2.xyzx)); // add r2.xyz, -r1.xyzx, r2.xyzx
    r2.xyz = value_64.xyz;
    uint4 value_65 = asuint(mad(asfloat(cb0[29].yyyy), asfloat(r2.xyzx), asfloat(r1.xyzx))); // mad r1.xyz, cb0[29].yyyy, r2.xyzx, r1.xyzx
    r1.xyz = value_65.xyz;
    uint4 value_66 = asuint(mad(asfloat(r0.xzwx), asfloat(v1.zzzz), asfloat(r1.xyzx))); // mad o0.xyz, r0.xzwx, v1.zzzz, r1.xyzx
    out_o0.xyz = value_66.xyz;
    uint4 value_67 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov o0.w, l(1.000000)
    out_o0.w = value_67.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
