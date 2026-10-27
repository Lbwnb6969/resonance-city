// Register-explicit recovered HLSL. Not original source.
// Placemaker/Shade ps_4_0 variant []
// Source SHA256 081ab8abf34de41fddbc61caa80e8008fb9b9581401e77869c8275a648d7e51d
// b0: $Globals 704 bytes
// cb0[42].x = _Color rows=1 cols=4 byte_offset=672
cbuffer Buffer0:register(b0) { uint4 cb0[43]; };
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
    uint4 value_1 = cb0[42].xyzw; // mov o0.xyzw, cb0[42].xyzw
    out_o0.xyzw = value_1.xyzw;
    // ret: return all declared output registers below.
    Output result;
    result.o0_0 = asfloat(out_o0.xyzw);
    return result;
}
