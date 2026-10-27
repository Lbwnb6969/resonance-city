// Register-explicit recovered HLSL. Not original source.
// Hidden/ShadowBaker vs_4_0 variant []
// Source SHA256 42b5cd6e5707b76bd5d83b132d8e2a9792f6c65eabb1023461d0a4d564d26233
// b0: $Globals 640 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb0[38].x = _ShadowRange rows=1 cols=4 byte_offset=608
// cb0[30].x = _WorldToShadow rows=4 cols=4 byte_offset=480
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _VoxelTex
cbuffer Buffer0:register(b0) { uint4 cb0[39]; };
cbuffer Buffer1:register(b1) { uint4 cb1[4]; };
cbuffer Buffer2:register(b2) { uint4 cb2[21]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 7
struct Input {
    float4 v0_0: POSITION0;
};
struct Output {
    float4 o0_0: SV_POSITION;
    float4 o1_0: COLOR0;
};
Output main(Input input) {
    uint4 r0;
    uint4 r1;
    uint4 r2;
    uint4 r3;
    uint4 r4;
    uint4 r5;
    uint4 r6;
    uint4 out_o0;
    uint4 out_o1;
    uint4 v0;
    v0.xyzw = asuint(input.v0_0);
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzw)); // mul r0.xyzw, v0.yyyy, cb1[1].xyzw
    r0.xyzw = value_1.xyzw;
    uint4 value_2 = asuint(mad(asfloat(cb1[0].xyzw), asfloat(v0.xxxx), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[0].xyzw, v0.xxxx, r0.xyzw
    r0.xyzw = value_2.xyzw;
    uint4 value_3 = asuint(mad(asfloat(cb1[2].xyzw), asfloat(v0.zzzz), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[2].xyzw, v0.zzzz, r0.xyzw
    r0.xyzw = value_3.xyzw;
    uint4 value_4 = asuint(mad(asfloat(cb1[3].xyzw), asfloat(v0.wwww), asfloat(r0.xyzw))); // mad r0.xyzw, cb1[3].xyzw, v0.wwww, r0.xyzw
    r0.xyzw = value_4.xyzw;
    uint4 value_5 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbe99999au, 0xbe99999au, 0xbe99999au, 0xbe99999au))); // add r1.x, r0.y, l(-0.300000)
    r1.x = value_5.x;
    uint4 value_6 = asuint(max(asfloat(r1.xxxx), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r1.x, r1.x, l(0.000000)
    r1.x = value_6.x;
    uint4 value_7 = asuint(floor(asfloat(r1.xxxx))); // round_ni r1.y, r1.x
    r1.y = value_7.y;
    uint4 value_8 = asuint(frac(asfloat(r1.xxxx))); // frc r1.x, r1.x
    r1.x = value_8.x;
    uint4 value_9 = asuint(int4(asfloat(r1.yyyy))); // ftoi r1.z, r1.y
    r1.z = value_9.z;
    uint4 value_10 = (r1.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r1.w, r1.z, l(1)
    r1.w = value_10.w;
    uint4 value_11 = asuint(float4(asint(r1.wwww))); // itof r2.x, r1.w
    r2.x = value_11.x;
    uint4 value_12 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r2.y, cb0[2].w
    r2.y = value_12.y;
    uint4 value_13 = uint4(asfloat(r2.yyyy)); // ftou r2.y, r2.y
    r2.y = value_13.y;
    uint4 value_14 = asuint(float4(r2.yyyy)); // utof r2.z, r2.y
    r2.z = value_14.z;
    uint4 value_15 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r2.zzzz)); // div r2.z, l(1.000000, 1.000000, 1.000000, 1.000000), r2.z
    r2.z = value_15.z;
    uint4 value_16 = asuint(asfloat(r2.zzzz) * asfloat(r2.xxxx)); // mul r2.x, r2.z, r2.x
    r2.x = value_16.x;
    uint4 value_17 = asuint(asfloat(r1.yyyy) * asfloat(r2.zzzz)); // mul r1.y, r1.y, r2.z
    r1.y = value_17.y;
    uint4 value_18 = asuint(int4(asfloat(r2.xxxx))); // ftoi r2.z, r2.x
    r2.z = value_18.z;
    uint4 value_19 = asuint(trunc(asfloat(r2.xxxx))); // round_z r3.yw, r2.xxxx
    r3.yw = value_19.yw;
    uint4 value_20 = (asuint(-asint(r2.zzzz)) * r2.yyyy + r1.wwww); // imad r1.w, -r2.z, r2.y, r1.w
    r1.w = value_20.w;
    uint4 value_21 = asuint(float4(r1.wwww)); // utof r3.xz, r1.wwww
    r3.xz = value_21.xz;
    uint4 value_22 = asuint(asfloat(r0.xzxz) + asfloat(asuint(-asfloat(cb0[3].xyxy)))); // add r4.xyzw, r0.xzxz, -cb0[3].xyxy
    r4.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(asfloat(r4.xyzw) + asfloat(uint4(0x3ca3d70au, 0x0u, 0x0u, 0x3ca3d70au))); // add r5.xyzw, r4.xyzw, l(0.020000, 0.000000, 0.000000, 0.020000)
    r5.xyzw = value_23.xyzw;
    uint4 value_24 = asuint(asfloat(r4.zzwz) * asfloat(cb0[2].zzzz)); // mul r2.xz, r4.zzwz, cb0[2].zzzz
    r2.xz = value_24.xz;
    uint4 value_25 = asuint(max(asfloat(r2.xxzx), asfloat(cb0[7].xxyx))); // max r2.xz, r2.xxzx, cb0[7].xxyx
    r2.xz = value_25.xz;
    uint4 value_26 = asuint(asfloat(r5.xyzw) * asfloat(cb0[2].zzzz)); // mul r4.xyzw, r5.xyzw, cb0[2].zzzz
    r4.xyzw = value_26.xyzw;
    uint4 value_27 = asuint(max(asfloat(r4.xyzw), asfloat(cb0[7].xyxy))); // max r4.xyzw, r4.xyzw, cb0[7].xyxy
    r4.xyzw = value_27.xyzw;
    uint4 value_28 = asuint(asfloat(cb0[2].xyxy) + asfloat(asuint(-asfloat(cb0[7].xyxy)))); // add r5.xyzw, cb0[2].xyxy, -cb0[7].xyxy
    r5.xyzw = value_28.xyzw;
    uint4 value_29 = asuint(min(asfloat(r4.xyzw), asfloat(r5.xyzw))); // min r4.xyzw, r4.xyzw, r5.xyzw
    r4.xyzw = value_29.xyzw;
    uint4 value_30 = asuint(min(asfloat(r2.xxzx), asfloat(r5.xxyx))); // min r2.xz, r2.xxzx, r5.xxyx
    r2.xz = value_30.xz;
    uint4 value_31 = asuint(mad(asfloat(r3.xyzw), asfloat(cb0[2].xyxy), asfloat(r4.xyzw))); // mad r5.xyzw, r3.xyzw, cb0[2].xyxy, r4.xyzw
    r5.xyzw = value_31.xyzw;
    uint4 value_32 = asuint(mad(asfloat(r3.xyxx), asfloat(cb0[2].xyxx), asfloat(r2.xzxx))); // mad r3.xy, r3.xyxx, cb0[2].xyxx, r2.xzxx
    r3.xy = value_32.xy;
    uint4 value_33 = asuint(t0.SampleLevel(s0, asfloat(r3.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xywz; // sample_l r3.xyzw, r3.xyxx, t0.xywz, s0, l(0.000000)
    r3.xyzw = value_33.xyzw;
    uint4 value_34 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(t0.SampleLevel(s0, asfloat(r5.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r5.zwzz, t0.xyzw, s0, l(0.000000)
    r5.xyzw = value_35.xyzw;
    uint4 value_36 = asuint(asfloat(asuint(-asfloat(r3.zzzz))) + asfloat(r5.wwww)); // add r1.w, -r3.z, r5.w
    r1.w = value_36.w;
    uint4 value_37 = asuint(asfloat(r1.wwww) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r3.y, r1.w, l(50.000000)
    r3.y = value_37.y;
    uint4 value_38 = asuint(asfloat(asuint(-asfloat(r3.zzzz))) + asfloat(r6.wwww)); // add r1.w, -r3.z, r6.w
    r1.w = value_38.w;
    uint4 value_39 = asuint(asfloat(r1.wwww) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r3.x, r1.w, l(50.000000)
    r3.x = value_39.x;
    uint4 value_40 = asuint(int4(asfloat(r1.yyyy))); // ftoi r1.w, r1.y
    r1.w = value_40.w;
    uint4 value_41 = asuint(trunc(asfloat(r1.yyyy))); // round_z r5.yw, r1.yyyy
    r5.yw = value_41.yw;
    uint4 value_42 = (asuint(-asint(r1.wwww)) * r2.yyyy + r1.zzzz); // imad r1.y, -r1.w, r2.y, r1.z
    r1.y = value_42.y;
    uint4 value_43 = asuint(float4(r1.yyyy)); // utof r5.xz, r1.yyyy
    r5.xz = value_43.xz;
    uint4 value_44 = asuint(mad(asfloat(r5.xyzw), asfloat(cb0[2].xyxy), asfloat(r4.xyzw))); // mad r4.xyzw, r5.xyzw, cb0[2].xyxy, r4.xyzw
    r4.xyzw = value_44.xyzw;
    uint4 value_45 = asuint(mad(asfloat(r5.zzwz), asfloat(cb0[2].xxyx), asfloat(r2.xxzx))); // mad r1.yz, r5.zzwz, cb0[2].xxyx, r2.xxzx
    r1.yz = value_45.yz;
    uint4 value_46 = asuint(t0.SampleLevel(s0, asfloat(r1.yzyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xywz; // sample_l r2.xyzw, r1.yzyy, t0.xywz, s0, l(0.000000)
    r2.xyzw = value_46.xyzw;
    uint4 value_47 = asuint(t0.SampleLevel(s0, asfloat(r4.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r4.xyxx, t0.xyzw, s0, l(0.000000)
    r5.xyzw = value_47.xyzw;
    uint4 value_48 = asuint(t0.SampleLevel(s0, asfloat(r4.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r4.zwzz, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_48.xyzw;
    uint4 value_49 = asuint(asfloat(asuint(-asfloat(r2.zzzz))) + asfloat(r4.wwww)); // add r1.y, -r2.z, r4.w
    r1.y = value_49.y;
    uint4 value_50 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r2.y, r1.y, l(50.000000)
    r2.y = value_50.y;
    uint4 value_51 = asuint(asfloat(asuint(-asfloat(r2.zzzz))) + asfloat(r5.wwww)); // add r1.y, -r2.z, r5.w
    r1.y = value_51.y;
    uint4 value_52 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r2.x, r1.y, l(50.000000)
    r2.x = value_52.x;
    uint4 value_53 = asuint(asfloat(asuint(-asfloat(r2.zzzz))) + asfloat(r3.zzzz)); // add r1.y, -r2.z, r3.z
    r1.y = value_53.y;
    uint4 value_54 = asuint(asfloat(asuint(-asfloat(r2.xyzx))) + asfloat(r3.xyzx)); // add r3.xyz, -r2.xyzx, r3.xyzx
    r3.xyz = value_54.xyz;
    uint4 value_55 = asuint(mad(asfloat(r1.xxxx), asfloat(r3.xyzx), asfloat(r2.xyzx))); // mad r2.xyz, r1.xxxx, r3.xyzx, r2.xyzx
    r2.xyz = value_55.xyz;
    uint4 value_56 = asuint(asfloat(asuint(-asfloat(r2.zzzz))) + asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u))); // add r1.z, -r2.z, l(0.500000)
    r1.z = value_56.z;
    uint4 value_57 = asuint(asfloat(asuint(-asfloat(r1.xxxx))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.w, -r1.x, l(1.000000)
    r1.w = value_57.w;
    uint4 value_58 = asuint(asfloat(r1.wwww) * asfloat(r1.xxxx)); // mul r1.x, r1.w, r1.x
    r1.x = value_58.x;
    uint4 value_59 = asuint(asfloat(r1.xxxx) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul r1.x, r1.x, l(4.000000)
    r1.x = value_59.x;
    uint4 value_60 = asuint(asfloat(r1.xxxx) * asfloat(r1.yyyy)); // mul r2.w, r1.x, r1.y
    r2.w = value_60.w;
    uint4 value_61 = asuint(mad(asfloat(r2.xwyx), asfloat(r1.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, r2.xwyx, r1.zzzz, r0.xyzx
    r0.xyz = value_61.xyz;
    uint4 value_62 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_62.xyzw;
    uint4 value_63 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_63.xyzw;
    uint4 value_64 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r1.xyzw = value_64.xyzw;
    uint4 value_65 = asuint(asfloat(r1.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r1.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_65.xyzw;
    uint4 value_66 = asuint(asfloat(r0.yyyy) * asfloat(cb0[31].zzzz)); // mul r0.y, r0.y, cb0[31].z
    r0.y = value_66.y;
    uint4 value_67 = asuint(mad(asfloat(cb0[30].zzzz), asfloat(r0.xxxx), asfloat(r0.yyyy))); // mad r0.x, cb0[30].z, r0.x, r0.y
    r0.x = value_67.x;
    uint4 value_68 = asuint(mad(asfloat(cb0[32].zzzz), asfloat(r0.zzzz), asfloat(r0.xxxx))); // mad r0.x, cb0[32].z, r0.z, r0.x
    r0.x = value_68.x;
    uint4 value_69 = asuint(mad(asfloat(cb0[33].zzzz), asfloat(r0.wwww), asfloat(r0.xxxx))); // mad r0.x, cb0[33].z, r0.w, r0.x
    r0.x = value_69.x;
    uint4 value_70 = asuint(mad(asfloat(cb0[38].yyyy), asfloat(uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u)), asfloat(r0.xxxx))); // mad o1.z, cb0[38].y, l(0.500000), r0.x
    out_o1.z = value_70.z;
    uint4 value_71 = uint4(0x3f800000u, 0x3f800000u, 0x0u, 0x3f800000u); // mov o1.xyw, l(1.000000,1.000000,0,1.000000)
    out_o1.xyw = value_71.xyw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xyzw);
    return result;
}
