// Register-explicit recovered HLSL. Not original source.
// PlacemakerUi/MultiFieldUi ps_4_0 variant []
// Source SHA256 e3c695328714597866dce55af402373679d46f62e46c836c80ea70c2f1d32779
// b0: $Globals 672 bytes
// b1: UnityPerCamera 144 bytes
// cb0[19].x = _AaLineBoth rows=1 cols=4 byte_offset=304
// cb0[40].x = _MainTex_TexelSize rows=1 cols=4 byte_offset=640
// cb1[5].x = _ProjectionParams rows=1 cols=4 byte_offset=80
// t0 / s0 = _MainTex
cbuffer Buffer0:register(b0) { uint4 cb0[41]; };
cbuffer Buffer1:register(b1) { uint4 cb1[6]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 4
struct Input {
    float2 v0_0: TEXCOORD0;
    float2 v0_1: TEXCOORD1;
    float2 v1_0: TEXCOORD2;
    float4 v2_0: SV_POSITION;
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
    v0.xy = asuint(input.v0_0);
    v0.zw = asuint(input.v0_1);
    v1.xy = asuint(input.v1_0);
    v2.xyzw = asuint(input.v2_0);
    v3.xyzw = asuint(input.v3_0);
    uint4 value_1 = ((asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)) < asfloat(cb1[5].xxxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.x, l(0.000000), cb1[5].x
    r0.x = value_1.x;
    uint4 value_2 = ((asfloat(cb1[5].xxxx) < asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // lt r0.y, cb1[5].x, l(0.000000)
    r0.y = value_2.y;
    uint4 value_3 = (r0.xxxx + asuint(-asint(r0.yyyy))); // iadd r0.x, r0.x, -r0.y
    r0.x = value_3.x;
    uint4 value_4 = asuint(float4(asint(r0.xxxx))); // itof r0.x, r0.x
    r0.x = value_4.x;
    uint4 value_5 = asuint(asfloat(r0.xxxx) * asfloat(v0.xyxx)); // mul r0.xy, r0.xxxx, v0.xyxx
    r0.xy = value_5.xy;
    uint4 value_6 = asuint(ddy(asfloat(r0.xyxx))); // deriv_rty r0.xy, r0.xyxx
    r0.xy = value_6.xy;
    uint4 value_7 = asuint(-asfloat(r0.xxxy)); // mov r0.zw, -r0.xxxy
    r0.zw = value_7.zw;
    uint4 value_8 = asuint(ddx(asfloat(v0.xyxx))); // deriv_rtx r0.xy, v0.xyxx
    r0.xy = value_8.xy;
    uint4 value_9 = asuint(dot(asfloat(r0.xzxx).xy, asfloat(r0.xzxx).xy)).xxxx; // dp2 r0.x, r0.xzxx, r0.xzxx
    r0.x = value_9.x;
    uint4 value_10 = asuint(dot(asfloat(r0.ywyy).xy, asfloat(r0.ywyy).xy)).xxxx; // dp2 r0.y, r0.ywyy, r0.ywyy
    r0.y = value_10.y;
    uint4 value_11 = asuint(sqrt(asfloat(r0.xyxx))); // sqrt r0.xy, r0.xyxx
    r0.xy = value_11.xy;
    uint4 value_12 = asuint(asfloat(r0.xyxx) * asfloat(cb0[40].zwzz)); // mul r0.xy, r0.xyxx, cb0[40].zwzz
    r0.xy = value_12.xy;
    uint4 value_13 = asuint(asfloat(r0.xyxx) * asfloat(uint4(0x3d000000u, 0x3d000000u, 0x0u, 0x0u))); // mul r0.xy, r0.xyxx, l(0.031250, 0.031250, 0.000000, 0.000000)
    r0.xy = value_13.xy;
    uint4 value_14 = asuint(max(asfloat(r0.yyyy), asfloat(r0.xxxx))); // max r0.x, r0.y, r0.x
    r0.x = value_14.x;
    uint4 value_15 = asuint(asfloat(asuint(-asfloat(v3.xxyz))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r0.yzw, -v3.xxyz, l(0.000000, 1.000000, 1.000000, 1.000000)
    r0.yzw = value_15.yzw;
    uint4 value_16 = asuint(saturate(asfloat(r0.yzwy))); // mov_sat r1.xyz, r0.yzwy
    r1.xyz = value_16.xyz;
    uint4 value_17 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u))); // add r2.xyz, -r1.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
    r2.xyz = value_17.xyz;
    uint4 value_18 = asuint(saturate(asfloat(asuint(mad(asfloat(r0.xxxx), asfloat(r2.xyzx), asfloat(r1.xyzx)))))); // mad_sat r2.xyz, r0.xxxx, r2.xyzx, r1.xyzx
    r2.xyz = value_18.xyz;
    uint4 value_19 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r1.xyzx), asfloat(r1.xyzx)))))); // mad_sat r1.xyz, -r0.xxxx, r1.xyzx, r1.xyzx
    r1.xyz = value_19.xyz;
    uint4 value_20 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(r2.xyzx)); // add r2.xyz, -r1.xyzx, r2.xyzx
    r2.xyz = value_20.xyz;
    uint4 value_21 = asuint(t0.Sample(s0, asfloat(v0.xyxx).xy)).xyzw; // sample r3.xyzw, v0.xyxx, t0.xyzw, s0
    r3.xyzw = value_21.xyzw;
    uint4 value_22 = asuint(asfloat(asuint(-asfloat(r1.xyzx))) + asfloat(r3.xyzx)); // add r1.xyz, -r1.xyzx, r3.xyzx
    r1.xyz = value_22.xyz;
    uint4 value_23 = asuint(saturate(asfloat(asuint(asfloat(r1.xyzx) / asfloat(r2.xyzx))))); // div_sat r1.xyz, r1.xyzx, r2.xyzx
    r1.xyz = value_23.xyz;
    uint4 value_24 = asuint(max(asfloat(r1.yyyy), asfloat(r1.xxxx))); // max r1.x, r1.y, r1.x
    r1.x = value_24.x;
    uint4 value_25 = asuint(max(asfloat(r1.zzzz), asfloat(r1.xxxx))); // max r1.x, r1.z, r1.x
    r1.x = value_25.x;
    uint4 value_26 = asuint(max(asfloat(asuint(abs(asfloat(v0.zzzz)))), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // max r1.y, |v0.z|, l(1.000000)
    r1.y = value_26.y;
    uint4 value_27 = asuint(asfloat(r0.xxxx) * asfloat(asuint(-asfloat(r1.yyyy)))); // mul r1.y, r0.x, -r1.y
    r1.y = value_27.y;
    uint4 value_28 = asuint(saturate(asfloat(asuint(mad(asfloat(r1.yyyy), asfloat(cb0[19].zzzz), asfloat(r0.yyzw)))))); // mad_sat r0.yzw, r1.yyyy, cb0[19].zzzz, r0.yyzw
    r0.yzw = value_28.yzw;
    uint4 value_29 = asuint(asfloat(asuint(-asfloat(r0.yyzw))) + asfloat(uint4(0x0u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.yzw, -r0.yyzw, l(0.000000, 1.000000, 1.000000, 1.000000)
    r1.yzw = value_29.yzw;
    uint4 value_30 = asuint(saturate(asfloat(asuint(mad(asfloat(r0.xxxx), asfloat(r1.yyzw), asfloat(r0.yyzw)))))); // mad_sat r1.yzw, r0.xxxx, r1.yyzw, r0.yyzw
    r1.yzw = value_30.yzw;
    uint4 value_31 = asuint(saturate(asfloat(asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r0.yzwy), asfloat(r0.yzwy)))))); // mad_sat r0.xyz, -r0.xxxx, r0.yzwy, r0.yzwy
    r0.xyz = value_31.xyz;
    uint4 value_32 = asuint(asfloat(asuint(-asfloat(r0.xxyz))) + asfloat(r1.yyzw)); // add r1.yzw, -r0.xxyz, r1.yyzw
    r1.yzw = value_32.yzw;
    uint4 value_33 = asuint(asfloat(asuint(-asfloat(r0.xyzx))) + asfloat(r3.xyzx)); // add r0.xyz, -r0.xyzx, r3.xyzx
    r0.xyz = value_33.xyz;
    uint4 value_34 = asuint(saturate(asfloat(asuint(asfloat(r0.xyzx) / asfloat(r1.yzwy))))); // div_sat r0.xyz, r0.xyzx, r1.yzwy
    r0.xyz = value_34.xyz;
    uint4 value_35 = asuint(max(asfloat(r0.yyyy), asfloat(r0.xxxx))); // max r0.x, r0.y, r0.x
    r0.x = value_35.x;
    uint4 value_36 = asuint(max(asfloat(r0.zzzz), asfloat(r0.xxxx))); // max r0.x, r0.z, r0.x
    r0.x = value_36.x;
    uint4 value_37 = asuint(min(asfloat(asuint(abs(asfloat(v0.zzzz)))), asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))); // min r0.y, |v0.z|, l(1.000000)
    r0.y = value_37.y;
    uint4 value_38 = asuint(asfloat(r0.yyyy) * asfloat(r0.xxxx)); // mul r0.x, r0.y, r0.x
    r0.x = value_38.x;
    uint4 value_39 = asuint(saturate(asfloat(v1.yyyy))); // mov_sat r0.y, v1.y
    r0.y = value_39.y;
    uint4 value_40 = ((asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)) >= asfloat(v0.zzzz)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.z, l(0.000000), v0.z
    r0.z = value_40.z;
    uint4 value_41 = (r0.zzzz & uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x0u)); // and r2.xyz, r0.zzzz, l(0x3f800000, 0x3f800000, 0x3f800000, 0)
    r2.xyz = value_41.xyz;
    uint4 value_42 = uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u); // mov r2.w, l(1.000000)
    r2.w = value_42.w;
    uint4 value_43 = asuint(mad(asfloat(asuint(-asfloat(r0.xxxx))), asfloat(r2.zzzw), asfloat(r0.yyyy))); // mad r3.xyzw, -r0.xxxx, r2.zzzw, r0.yyyy
    r3.xyzw = value_43.xyzw;
    uint4 value_44 = asuint(asfloat(r0.xxxx) * asfloat(r2.xyzw)); // mul r0.xyzw, r0.xxxx, r2.xyzw
    r0.xyzw = value_44.xyzw;
    uint4 value_45 = asuint(mad(asfloat(r1.xxxx), asfloat(r3.xyzw), asfloat(r0.xyzw))); // mad r0.xyzw, r1.xxxx, r3.xyzw, r0.xyzw
    r0.xyzw = value_45.xyzw;
    uint4 value_46 = asuint(asfloat(r0.xyzw) * asfloat(v3.wwww)); // mul o0.xyzw, r0.xyzw, v3.wwww
    out_o0.xyzw = value_46.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
