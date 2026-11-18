// Stable integer lattice corners, shared by mineral and timber surface grains.
float material_hash(vec2 cell) {
	uvec2 bits=uvec2(ivec2(cell));
	uint value=(bits.x*0x8da6b343u)^(bits.y*0xd8163841u);
	value^=value>>16u;value*=0x7feb352du;
	value^=value>>15u;value*=0x846ca68bu;value^=value>>16u;
	return float(value&0x00ffffffu)/16777216.0;
}
