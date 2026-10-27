// Register-explicit recovered HLSL. Not original source.
// Placemaker/Voxel ps_4_0 variant []
// Source SHA256 d0699c6fcc984456ae0d38e64398493d3460aadb78da4e8f7b8133bcf42d7ac5
struct Input {
    float4 v0_0: SV_POSITION;
    float4 v1_0: COLOR0;
};
struct Output {
    float4 o0_0: SV_Target;
};
Output main(Input input) {
    uint4 out_o0;
    uint4 v0;
    uint4 v1;
    v0.xyzw = asuint(input.v0_0);
    v1.xyzw = asuint(input.v1_0);
    uint4 value_1 = v1.xyzw; // mov o0.xyzw, v1.xyzw
    out_o0.xyzw = value_1.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
