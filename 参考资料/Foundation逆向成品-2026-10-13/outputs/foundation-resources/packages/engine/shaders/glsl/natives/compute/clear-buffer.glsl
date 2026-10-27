
layout(location = 0) uniform int uniCount;

layout(std430, binding = 0) writeonly buffer intBuffer
{
	int data[];
} outIntBuffer;

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
	uint id = (storePos.z * gHeight + storePos.y) * gWidth + storePos.x;

	if (id < uniCount)
	{
        outIntBuffer.data[id] = 0;
    }
}