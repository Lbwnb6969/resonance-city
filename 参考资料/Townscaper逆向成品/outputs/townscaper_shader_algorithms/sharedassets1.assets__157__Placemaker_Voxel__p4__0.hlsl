// Register-explicit recovered HLSL. Not original source.
// Placemaker/Voxel vs_4_0 variant []
// Source SHA256 cb76b87fb2aebccaf5928c7aeb9dae34215fc362efed2e2f6ec011074a08e26e
// b0: $Globals 640 bytes
// b1: UnityPerDraw 176 bytes
// b2: UnityPerFrame 368 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[3].x = _Tex3dWorldBounds rows=1 cols=4 byte_offset=48
// cb0[7].x = _AoTex_TexelSize rows=1 cols=4 byte_offset=112
// cb1[0].x = unity_ObjectToWorld rows=4 cols=4 byte_offset=0
// cb2[17].x = unity_MatrixVP rows=4 cols=4 byte_offset=272
// t0 / s0 = _VoxelTex
cbuffer Buffer0:register(b0) { uint4 cb0[8]; };
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
    uint4 value_1 = asuint(asfloat(v0.yyyy) * asfloat(cb1[1].xyzx)); // mul r0.xyz, v0.yyyy, cb1[1].xyzx
    r0.xyz = value_1.xyz;
    uint4 value_2 = asuint(mad(asfloat(cb1[0].xyzx), asfloat(v0.xxxx), asfloat(r0.xyzx))); // mad r0.xyz, cb1[0].xyzx, v0.xxxx, r0.xyzx
    r0.xyz = value_2.xyz;
    uint4 value_3 = asuint(mad(asfloat(cb1[2].xyzx), asfloat(v0.zzzz), asfloat(r0.xyzx))); // mad r0.xyz, cb1[2].xyzx, v0.zzzz, r0.xyzx
    r0.xyz = value_3.xyz;
    uint4 value_4 = asuint(mad(asfloat(cb1[3].xyzx), asfloat(v0.wwww), asfloat(r0.xyzx))); // mad r0.xyz, cb1[3].xyzx, v0.wwww, r0.xyzx
    r0.xyz = value_4.xyz;
    uint4 value_5 = asuint(asfloat(r0.yyyy) + asfloat(uint4(0xbe99999au, 0xbe99999au, 0xbe99999au, 0xbe99999au))); // add r0.w, r0.y, l(-0.300000)
    r0.w = value_5.w;
    uint4 value_6 = asuint(max(asfloat(r0.wwww), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r0.w, r0.w, l(0.000000)
    r0.w = value_6.w;
    uint4 value_7 = asuint(floor(asfloat(r0.wwww))); // round_ni r1.x, r0.w
    r1.x = value_7.x;
    uint4 value_8 = asuint(frac(asfloat(r0.wwww))); // frc r0.w, r0.w
    r0.w = value_8.w;
    uint4 value_9 = asuint(int4(asfloat(r1.xxxx))); // ftoi r1.y, r1.x
    r1.y = value_9.y;
    uint4 value_10 = (r1.yyyy + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r1.z, r1.y, l(1)
    r1.z = value_10.z;
    uint4 value_11 = asuint(float4(asint(r1.zzzz))); // itof r1.w, r1.z
    r1.w = value_11.w;
    uint4 value_12 = asuint(round(asfloat(cb0[2].wwww))); // round_ne r2.x, cb0[2].w
    r2.x = value_12.x;
    uint4 value_13 = uint4(asfloat(r2.xxxx)); // ftou r2.x, r2.x
    r2.x = value_13.x;
    uint4 value_14 = asuint(float4(r2.xxxx)); // utof r2.y, r2.x
    r2.y = value_14.y;
    uint4 value_15 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r2.yyyy)); // div r2.y, l(1.000000, 1.000000, 1.000000, 1.000000), r2.y
    r2.y = value_15.y;
    uint4 value_16 = asuint(asfloat(r1.xxxw) * asfloat(r2.yyyy)); // mul r1.xw, r1.xxxw, r2.yyyy
    r1.xw = value_16.xw;
    uint4 value_17 = asuint(int4(asfloat(r1.wwww))); // ftoi r2.y, r1.w
    r2.y = value_17.y;
    uint4 value_18 = asuint(trunc(asfloat(r1.wwww))); // round_z r3.yw, r1.wwww
    r3.yw = value_18.yw;
    uint4 value_19 = (asuint(-asint(r2.yyyy)) * r2.xxxx + r1.zzzz); // imad r1.z, -r2.y, r2.x, r1.z
    r1.z = value_19.z;
    uint4 value_20 = asuint(float4(r1.zzzz)); // utof r3.xz, r1.zzzz
    r3.xz = value_20.xz;
    uint4 value_21 = asuint(asfloat(r0.xzxz) + asfloat(asuint(-asfloat(cb0[3].xyxy)))); // add r4.xyzw, r0.xzxz, -cb0[3].xyxy
    r4.xyzw = value_21.xyzw;
    uint4 value_22 = asuint(asfloat(r4.xyzw) + asfloat(uint4(0x3ca3d70au, 0x0u, 0x0u, 0x3ca3d70au))); // add r5.xyzw, r4.xyzw, l(0.020000, 0.000000, 0.000000, 0.020000)
    r5.xyzw = value_22.xyzw;
    uint4 value_23 = asuint(asfloat(r4.zzzw) * asfloat(cb0[2].zzzz)); // mul r1.zw, r4.zzzw, cb0[2].zzzz
    r1.zw = value_23.zw;
    uint4 value_24 = asuint(max(asfloat(r1.zzzw), asfloat(cb0[7].xxxy))); // max r1.zw, r1.zzzw, cb0[7].xxxy
    r1.zw = value_24.zw;
    uint4 value_25 = asuint(asfloat(r5.xyzw) * asfloat(cb0[2].zzzz)); // mul r4.xyzw, r5.xyzw, cb0[2].zzzz
    r4.xyzw = value_25.xyzw;
    uint4 value_26 = asuint(max(asfloat(r4.xyzw), asfloat(cb0[7].xyxy))); // max r4.xyzw, r4.xyzw, cb0[7].xyxy
    r4.xyzw = value_26.xyzw;
    uint4 value_27 = asuint(asfloat(cb0[2].xyxy) + asfloat(asuint(-asfloat(cb0[7].xyxy)))); // add r5.xyzw, cb0[2].xyxy, -cb0[7].xyxy
    r5.xyzw = value_27.xyzw;
    uint4 value_28 = asuint(min(asfloat(r4.xyzw), asfloat(r5.xyzw))); // min r4.xyzw, r4.xyzw, r5.xyzw
    r4.xyzw = value_28.xyzw;
    uint4 value_29 = asuint(min(asfloat(r1.zzzw), asfloat(r5.xxxy))); // min r1.zw, r1.zzzw, r5.xxxy
    r1.zw = value_29.zw;
    uint4 value_30 = asuint(mad(asfloat(r3.xyzw), asfloat(cb0[2].xyxy), asfloat(r4.xyzw))); // mad r5.xyzw, r3.xyzw, cb0[2].xyxy, r4.xyzw
    r5.xyzw = value_30.xyzw;
    uint4 value_31 = asuint(mad(asfloat(r3.xxyx), asfloat(cb0[2].xxyx), asfloat(r1.zzwz))); // mad r2.yz, r3.xxyx, cb0[2].xxyx, r1.zzwz
    r2.yz = value_31.yz;
    uint4 value_32 = asuint(t0.SampleLevel(s0, asfloat(r2.yzyy).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r3.xyzw, r2.yzyy, t0.xyzw, s0, l(0.000000)
    r3.xyzw = value_32.xyzw;
    uint4 value_33 = asuint(t0.SampleLevel(s0, asfloat(r5.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r6.xyzw, r5.xyxx, t0.xyzw, s0, l(0.000000)
    r6.xyzw = value_33.xyzw;
    uint4 value_34 = asuint(t0.SampleLevel(s0, asfloat(r5.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r5.xyzw, r5.zwzz, t0.xyzw, s0, l(0.000000)
    r5.xyzw = value_34.xyzw;
    uint4 value_35 = asuint(asfloat(asuint(-asfloat(r3.wwww))) + asfloat(r5.wwww)); // add r2.y, -r3.w, r5.w
    r2.y = value_35.y;
    uint4 value_36 = asuint(asfloat(r2.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r3.z, r2.y, l(50.000000)
    r3.z = value_36.z;
    uint4 value_37 = asuint(asfloat(asuint(-asfloat(r3.wwww))) + asfloat(r6.wwww)); // add r2.y, -r3.w, r6.w
    r2.y = value_37.y;
    uint4 value_38 = asuint(asfloat(r2.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r3.x, r2.y, l(50.000000)
    r3.x = value_38.x;
    uint4 value_39 = asuint(int4(asfloat(r1.xxxx))); // ftoi r2.y, r1.x
    r2.y = value_39.y;
    uint4 value_40 = asuint(trunc(asfloat(r1.xxxx))); // round_z r5.yw, r1.xxxx
    r5.yw = value_40.yw;
    uint4 value_41 = (asuint(-asint(r2.yyyy)) * r2.xxxx + r1.yyyy); // imad r1.x, -r2.y, r2.x, r1.y
    r1.x = value_41.x;
    uint4 value_42 = asuint(float4(r1.xxxx)); // utof r5.xz, r1.xxxx
    r5.xz = value_42.xz;
    uint4 value_43 = asuint(mad(asfloat(r5.xyzw), asfloat(cb0[2].xyxy), asfloat(r4.xyzw))); // mad r2.xyzw, r5.xyzw, cb0[2].xyxy, r4.xyzw
    r2.xyzw = value_43.xyzw;
    uint4 value_44 = asuint(mad(asfloat(r5.zwzz), asfloat(cb0[2].xyxx), asfloat(r1.zwzz))); // mad r1.xy, r5.zwzz, cb0[2].xyxx, r1.zwzz
    r1.xy = value_44.xy;
    uint4 value_45 = asuint(t0.SampleLevel(s0, asfloat(r1.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r1.xyzw, r1.xyxx, t0.xyzw, s0, l(0.000000)
    r1.xyzw = value_45.xyzw;
    uint4 value_46 = asuint(t0.SampleLevel(s0, asfloat(r2.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r4.xyzw, r2.xyxx, t0.xyzw, s0, l(0.000000)
    r4.xyzw = value_46.xyzw;
    uint4 value_47 = asuint(t0.SampleLevel(s0, asfloat(r2.zwzz).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r2.xyzw, r2.zwzz, t0.xyzw, s0, l(0.000000)
    r2.xyzw = value_47.xyzw;
    uint4 value_48 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r2.wwww)); // add r1.y, -r1.w, r2.w
    r1.y = value_48.y;
    uint4 value_49 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r1.z, r1.y, l(50.000000)
    r1.z = value_49.z;
    uint4 value_50 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r4.wwww)); // add r1.y, -r1.w, r4.w
    r1.y = value_50.y;
    uint4 value_51 = asuint(asfloat(r1.yyyy) * asfloat(uint4(0x42480000u, 0x42480000u, 0x42480000u, 0x42480000u))); // mul r1.x, r1.y, l(50.000000)
    r1.x = value_51.x;
    uint4 value_52 = asuint(asfloat(asuint(-asfloat(r1.wwww))) + asfloat(r3.wwww)); // add r1.y, -r1.w, r3.w
    r1.y = value_52.y;
    uint4 value_53 = asuint(asfloat(asuint(-asfloat(r1.xzwx))) + asfloat(r3.xzwx)); // add r2.xyz, -r1.xzwx, r3.xzwx
    r2.xyz = value_53.xyz;
    uint4 value_54 = asuint(mad(asfloat(r0.wwww), asfloat(r2.xxyz), asfloat(r1.xxzw))); // mad r2.xzw, r0.wwww, r2.xxyz, r1.xxzw
    r2.xzw = value_54.xzw;
    uint4 value_55 = asuint(asfloat(asuint(-asfloat(r2.wwww))) + asfloat(uint4(0x3f333333u, 0x3f333333u, 0x3f333333u, 0x3f333333u))); // add r1.x, -r2.w, l(0.700000)
    r1.x = value_55.x;
    uint4 value_56 = asuint(asfloat(asuint(-asfloat(r0.wwww))) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u))); // add r1.z, -r0.w, l(1.000000)
    r1.z = value_56.z;
    uint4 value_57 = asuint(asfloat(r0.wwww) * asfloat(r1.zzzz)); // mul r0.w, r0.w, r1.z
    r0.w = value_57.w;
    uint4 value_58 = asuint(asfloat(r0.wwww) * asfloat(uint4(0x40800000u, 0x40800000u, 0x40800000u, 0x40800000u))); // mul r0.w, r0.w, l(4.000000)
    r0.w = value_58.w;
    uint4 value_59 = asuint(asfloat(r0.wwww) * asfloat(r1.yyyy)); // mul r2.y, r0.w, r1.y
    r2.y = value_59.y;
    uint4 value_60 = asuint(asfloat(r1.xxxx) * asfloat(r2.xyzx)); // mul r1.xyz, r1.xxxx, r2.xyzx
    r1.xyz = value_60.xyz;
    uint4 value_61 = r2.xyzw; // mov o1.xyzw, r2.xyzw
    out_o1.xyzw = value_61.xyzw;
    uint4 value_62 = asuint(mad(asfloat(r1.xyzx), asfloat(uint4(0x40000000u, 0x40000000u, 0x40000000u, 0x0u)), asfloat(r0.xyzx))); // mad r0.xyz, r1.xyzx, l(2.000000, 2.000000, 2.000000, 0.000000), r0.xyzx
    r0.xyz = value_62.xyz;
    uint4 value_63 = asuint(asfloat(r0.yyyy) * asfloat(cb2[18].xyzw)); // mul r1.xyzw, r0.yyyy, cb2[18].xyzw
    r1.xyzw = value_63.xyzw;
    uint4 value_64 = asuint(mad(asfloat(cb2[17].xyzw), asfloat(r0.xxxx), asfloat(r1.xyzw))); // mad r1.xyzw, cb2[17].xyzw, r0.xxxx, r1.xyzw
    r1.xyzw = value_64.xyzw;
    uint4 value_65 = asuint(mad(asfloat(cb2[19].xyzw), asfloat(r0.zzzz), asfloat(r1.xyzw))); // mad r0.xyzw, cb2[19].xyzw, r0.zzzz, r1.xyzw
    r0.xyzw = value_65.xyzw;
    uint4 value_66 = asuint(asfloat(r0.xyzw) + asfloat(cb2[20].xyzw)); // add o0.xyzw, r0.xyzw, cb2[20].xyzw
    out_o0.xyzw = value_66.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    result.o1_0 = asfloat(out_o1.xyzw);
    return result;
}
