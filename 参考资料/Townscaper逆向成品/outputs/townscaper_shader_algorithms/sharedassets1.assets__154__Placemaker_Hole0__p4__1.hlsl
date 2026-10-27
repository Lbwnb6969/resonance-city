// Register-explicit recovered HLSL. Not original source.
// Placemaker/Hole0 ps_4_0 variant []
// Source SHA256 faaa8f6c5d73390ab4e0d289e363a185e3f41889cd6428ad69603998222d28e7
struct Input {
    float4 v0_0: SV_POSITION;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 out_o0;
    uint4 v0;
    v0.xyzw = asuint(input.v0_0);
    uint4 value_1 = uint4(0x3f000000u, 0x3f000000u, 0x3f000000u, 0x3f000000u); // mov o0.xyzw, l(0.500000,0.500000,0.500000,0.500000)
    out_o0.xyzw = value_1.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
