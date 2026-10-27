
uniform int uniDrawCommandCount;

layout(std430, binding = BIND_INDEX_COMMAND_BUFFER) writeonly buffer commandBuffer
{
	// 1 draw command per mesh
	IndirectDrawCommand cmd[];
} outCommandBuffer;

//------------------------------------------------------------------------
void main()
{
	// Read current global position for this thread
    ivec3 storePos = ivec3(gl_GlobalInvocationID.xyz);

	// Calculate the global number of threads (size) for this
	uint gWidth = gl_WorkGroupSize.x * gl_NumWorkGroups.x;
	uint gHeight = gl_WorkGroupSize.y * gl_NumWorkGroups.y;
	uint gDepth = gl_WorkGroupSize.z * gl_NumWorkGroups.z;
	uint gSize = gWidth * gHeight * gDepth;

	// Since we have 1D array we need to calculate offset.
	uint commandId = (storePos.z * gHeight + storePos.y) * gWidth + storePos.x;

	if (commandId < uniDrawCommandCount)
	{
        outCommandBuffer.cmd[commandId].instanceCount = 0;
    }
}