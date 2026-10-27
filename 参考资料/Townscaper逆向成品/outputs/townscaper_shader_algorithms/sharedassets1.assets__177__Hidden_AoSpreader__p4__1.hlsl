// Register-explicit recovered HLSL. Not original source.
// Hidden/AoSpreader ps_4_0 variant []
// Source SHA256 eff9d3ce98b45ca9b1ad804c57c6c980f120d243fff5c6365817119ac923cabe
// b0: $Globals 672 bytes
// cb0[2].x = _Tex3dUvSize rows=1 cols=4 byte_offset=32
// cb0[9].x = _GroundColor rows=1 cols=4 byte_offset=144
// t0 / s0 = _MainTex
cbuffer Buffer0:register(b0) { uint4 cb0[10]; };
SamplerState s0:register(s0);
Texture2D<float4> t0:register(t0);
// temporary registers: 9
struct Input {
    float4 v0_0: SV_POSITION;
    float2 v1_0: TEXCOORD0;
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
    uint4 r5;
    uint4 r6;
    uint4 r7;
    uint4 r8;
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xy = asuint(input.v1_0);
    uint4 value_1 = asuint(asfloat(v1.xyxx) / asfloat(cb0[2].xyxx)); // div r0.xy, v1.xyxx, cb0[2].xyxx
    r0.xy = value_1.xy;
    uint4 value_2 = asuint(floor(asfloat(r0.xyxx))); // round_ni r0.xy, r0.xyxx
    r0.xy = value_2.xy;
    uint4 value_3 = asuint(mad(asfloat(r0.yyyy), asfloat(cb0[2].wwww), asfloat(r0.xxxx))); // mad r0.x, r0.y, cb0[2].w, r0.x
    r0.x = value_3.x;
    uint4 value_4 = asuint(asfloat(v1.xxyx) * asfloat(cb0[2].xxyx)); // mul r0.yz, v1.xxyx, cb0[2].xxyx
    r0.yz = value_4.yz;
    uint4 value_5 = ((asfloat(r0.yyzy) >= asfloat(asuint(-asfloat(r0.yyzy)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r0.yz, r0.yyzy, -r0.yyzy
    r0.yz = value_5.yz;
    uint4 value_6 = ((r0.yyzy != 0u) ? cb0[2].xxyx : asuint(-asfloat(cb0[2].xxyx))); // movc r0.yz, r0.yyzy, cb0[2].xxyx, -cb0[2].xxyx
    r0.yz = value_6.yz;
    uint4 value_7 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r0.yzyy)); // div r1.xy, l(1.000000, 1.000000, 1.000000, 1.000000), r0.yzyy
    r1.xy = value_7.xy;
    uint4 value_8 = asuint(asfloat(r1.xyxx) * asfloat(v1.xyxx)); // mul r1.xy, r1.xyxx, v1.xyxx
    r1.xy = value_8.xy;
    uint4 value_9 = asuint(frac(asfloat(r1.xyxx))); // frc r1.xy, r1.xyxx
    r1.xy = value_9.xy;
    uint4 value_10 = uint4(0x0u, 0x0u, 0x0u, 0x0u); // mov r2.xyzw, l(0,0,0,0)
    r2.xyzw = value_10.xyzw;
    uint4 value_11 = uint4(0x0u, 0x0u, 0x0u, 0x0u); // mov r0.w, l(0)
    r0.w = value_11.w;
    uint4 value_12 = uint4(0xfffffffeu, 0xfffffffeu, 0xfffffffeu, 0xfffffffeu); // mov r1.z, l(-2)
    r1.z = value_12.z;
    while (true) {
        uint4 value_14 = ((asint(uint4(0x2u, 0x2u, 0x2u, 0x2u)) < asint(r1.zzzz)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ilt r1.w, l(2), r1.z
        r1.w = value_14.w;
        if (r1.wwww.x != 0u) break; // breakc_nz r1.w
        uint4 value_16 = asuint(float4(asint(r1.zzzz))); // itof r3.x, r1.z
        r3.x = value_16.x;
        uint4 value_17 = r2.xyzw; // mov r4.xyzw, r2.xyzw
        r4.xyzw = value_17.xyzw;
        uint4 value_18 = r0.wwww; // mov r1.w, r0.w
        r1.w = value_18.w;
        uint4 value_19 = uint4(0xfffffffeu, 0xfffffffeu, 0xfffffffeu, 0xfffffffeu); // mov r3.y, l(-2)
        r3.y = value_19.y;
        while (true) {
            uint4 value_21 = ((asint(uint4(0x2u, 0x2u, 0x2u, 0x2u)) < asint(r3.yyyy)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ilt r3.w, l(2), r3.y
            r3.w = value_21.w;
            if (r3.wwww.x != 0u) break; // breakc_nz r3.w
            uint4 value_23 = asuint(float4(asint(r3.yyyy))); // itof r3.z, r3.y
            r3.z = value_23.z;
            uint4 value_24 = asuint(asfloat(r3.xxzx) * asfloat(uint4(0x3f000000u, 0x0u, 0x3f000000u, 0x0u))); // mul r5.xz, r3.xxzx, l(0.500000, 0.000000, 0.500000, 0.000000)
            r5.xz = value_24.xz;
            uint4 value_25 = asuint(asfloat(r5.xxxz) * asfloat(cb0[2].zzzz)); // mul r3.zw, r5.xxxz, cb0[2].zzzz
            r3.zw = value_25.zw;
            uint4 value_26 = asuint(mad(asfloat(r0.yyyz), asfloat(r1.xxxy), asfloat(r3.zzzw))); // mad r3.zw, r0.yyyz, r1.xxxy, r3.zzzw
            r3.zw = value_26.zw;
            uint4 value_27 = asuint(max(asfloat(r3.zzzw), asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)))); // max r3.zw, r3.zzzw, l(0.000000, 0.000000, 0.000000, 0.000000)
            r3.zw = value_27.zw;
            uint4 value_28 = asuint(min(asfloat(r3.zzzw), asfloat(cb0[2].xxxy))); // min r3.zw, r3.zzzw, cb0[2].xxxy
            r3.zw = value_28.zw;
            uint4 value_29 = r4.xyzw; // mov r6.xyzw, r4.xyzw
            r6.xyzw = value_29.xyzw;
            uint4 value_30 = r1.wwww; // mov r5.w, r1.w
            r5.w = value_30.w;
            uint4 value_31 = uint4(0xffffffffu, 0xffffffffu, 0xffffffffu, 0xffffffffu); // mov r7.x, l(-1)
            r7.x = value_31.x;
            while (true) {
                uint4 value_33 = ((asint(uint4(0x1u, 0x1u, 0x1u, 0x1u)) < asint(r7.xxxx)) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ilt r7.y, l(1), r7.x
                r7.y = value_33.y;
                if (r7.yyyy.x != 0u) break; // breakc_nz r7.y
                uint4 value_35 = asuint(float4(asint(r7.xxxx))); // itof r5.y, r7.x
                r5.y = value_35.y;
                uint4 value_36 = asuint(asfloat(r0.xxxx) + asfloat(r5.yyyy)); // add r7.y, r0.x, r5.y
                r7.y = value_36.y;
                uint4 value_37 = asuint(asfloat(r7.yyyy) * asfloat(cb0[2].wwww)); // mul r7.z, r7.y, cb0[2].w
                r7.z = value_37.z;
                uint4 value_38 = ((asfloat(r7.zzzz) >= asfloat(asuint(-asfloat(r7.zzzz)))) ? uint4(0xffffffffu,0xffffffffu,0xffffffffu,0xffffffffu) : uint4(0u,0u,0u,0u)); // ge r7.z, r7.z, -r7.z
                r7.z = value_38.z;
                uint4 value_39 = ((r7.zzzz != 0u) ? cb0[2].wwww : asuint(-asfloat(cb0[2].wwww))); // movc r7.z, r7.z, cb0[2].w, -cb0[2].w
                r7.z = value_39.z;
                uint4 value_40 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r7.zzzz)); // div r7.w, l(1.000000, 1.000000, 1.000000, 1.000000), r7.z
                r7.w = value_40.w;
                uint4 value_41 = asuint(asfloat(r7.wwww) * asfloat(r7.yyyy)); // mul r7.w, r7.w, r7.y
                r7.w = value_41.w;
                uint4 value_42 = asuint(frac(asfloat(r7.wwww))); // frc r7.w, r7.w
                r7.w = value_42.w;
                uint4 value_43 = asuint(asfloat(r7.wwww) * asfloat(r7.zzzz)); // mul r7.z, r7.w, r7.z
                r7.z = value_43.z;
                uint4 value_44 = asuint(mad(asfloat(cb0[2].xxxx), asfloat(r7.zzzz), asfloat(r3.zzzz))); // mad r8.x, cb0[2].x, r7.z, r3.z
                r8.x = value_44.x;
                uint4 value_45 = asuint(asfloat(r7.yyyy) / asfloat(cb0[2].wwww)); // div r7.z, r7.y, cb0[2].w
                r7.z = value_45.z;
                uint4 value_46 = asuint(floor(asfloat(r7.zzzz))); // round_ni r7.z, r7.z
                r7.z = value_46.z;
                uint4 value_47 = asuint(mad(asfloat(cb0[2].yyyy), asfloat(r7.zzzz), asfloat(r3.wwww))); // mad r8.y, cb0[2].y, r7.z, r3.w
                r8.y = value_47.y;
                uint4 value_48 = asuint(dot(asfloat(r5.xyzx).xyz, asfloat(r5.xyzx).xyz)).xxxx; // dp3 r5.y, r5.xyzx, r5.xyzx
                r5.y = value_48.y;
                uint4 value_49 = asuint(sqrt(asfloat(r5.yyyy))); // sqrt r5.y, r5.y
                r5.y = value_49.y;
                uint4 value_50 = asuint(asfloat(r5.yyyy) + asfloat(uint4(0x3cf5c28fu, 0x3cf5c28fu, 0x3cf5c28fu, 0x3cf5c28fu))); // add r5.y, r5.y, l(0.030000)
                r5.y = value_50.y;
                uint4 value_51 = asuint(asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)) / asfloat(r5.yyyy)); // div r5.y, l(1.000000, 1.000000, 1.000000, 1.000000), r5.y
                r5.y = value_51.y;
                uint4 value_52 = asuint(t0.SampleLevel(s0, asfloat(r8.xyxx).xy, asfloat(uint4(0x0u, 0x0u, 0x0u, 0x0u)).x)).xyzw; // sample_l r8.xyzw, r8.xyxx, t0.xyzw, s0, l(0.000000)
                r8.xyzw = value_52.xyzw;
                uint4 value_53 = asuint(saturate(asfloat(asuint(asfloat(r7.yyyy) + asfloat(uint4(0x3f800000u, 0x3f800000u, 0x3f800000u, 0x3f800000u)))))); // add_sat r7.y, r7.y, l(1.000000)
                r7.y = value_53.y;
                uint4 value_54 = asuint(asfloat(r8.xyzw) + asfloat(asuint(-asfloat(cb0[9].xyzw)))); // add r8.xyzw, r8.xyzw, -cb0[9].xyzw
                r8.xyzw = value_54.xyzw;
                uint4 value_55 = asuint(mad(asfloat(r7.yyyy), asfloat(r8.xyzw), asfloat(cb0[9].xyzw))); // mad r8.xyzw, r7.yyyy, r8.xyzw, cb0[9].xyzw
                r8.xyzw = value_55.xyzw;
                uint4 value_56 = asuint(mad(asfloat(r8.xyzw), asfloat(r5.yyyy), asfloat(r6.xyzw))); // mad r6.xyzw, r8.xyzw, r5.yyyy, r6.xyzw
                r6.xyzw = value_56.xyzw;
                uint4 value_57 = asuint(asfloat(r5.yyyy) + asfloat(r5.wwww)); // add r5.w, r5.y, r5.w
                r5.w = value_57.w;
                uint4 value_58 = (r7.xxxx + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r7.x, r7.x, l(1)
                r7.x = value_58.x;
            }
            uint4 value_60 = r6.xyzw; // mov r4.xyzw, r6.xyzw
            r4.xyzw = value_60.xyzw;
            uint4 value_61 = r5.wwww; // mov r1.w, r5.w
            r1.w = value_61.w;
            uint4 value_62 = (r3.yyyy + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r3.y, r3.y, l(1)
            r3.y = value_62.y;
        }
        uint4 value_64 = r4.xyzw; // mov r2.xyzw, r4.xyzw
        r2.xyzw = value_64.xyzw;
        uint4 value_65 = r1.wwww; // mov r0.w, r1.w
        r0.w = value_65.w;
        uint4 value_66 = (r1.zzzz + uint4(0x1u, 0x1u, 0x1u, 0x1u)); // iadd r1.z, r1.z, l(1)
        r1.z = value_66.z;
    }
    uint4 value_68 = asuint(asfloat(r2.xyzw) / asfloat(r0.wwww)); // div r0.xyzw, r2.xyzw, r0.wwww
    r0.xyzw = value_68.xyzw;
    uint4 value_69 = asuint(asfloat(r0.xyzx) * asfloat(r0.xyzx)); // mul o0.xyz, r0.xyzx, r0.xyzx
    out_o0.xyz = value_69.xyz;
    uint4 value_70 = r0.wwww; // mov o0.w, r0.w
    out_o0.w = value_70.w;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
