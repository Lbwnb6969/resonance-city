
layout(location = 0) uniform int uniTotalLocalSize;
layout(location = 1) uniform int uniCommandCount;

//------------------------------------------------------------------------
struct IndirectDispatchCommand
{
    uint num_groups_x;
    uint num_groups_y;
    uint num_groups_z;
    uint padding;
};

//------------------------------------------------------------------------
layout(std430, binding = 0) readonly buffer globalBuffer
{
	uint totalCount;
	uint nextBaseInstance;
} inGlobalBuffer;

layout(std430, binding = 1) writeonly buffer dispatchIndirectCommand
{
    IndirectDispatchCommand command[];
} outDispatchIndirectCommand;

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

	if (id < uniCommandCount)
	{
        IndirectDispatchCommand command;

        command.num_groups_x = int(ceil(inGlobalBuffer.totalCount / float(uniTotalLocalSize)));
        command.num_groups_y = 1;
        command.num_groups_z = 1;

        outDispatchIndirectCommand.command[id] = command;
    }
}