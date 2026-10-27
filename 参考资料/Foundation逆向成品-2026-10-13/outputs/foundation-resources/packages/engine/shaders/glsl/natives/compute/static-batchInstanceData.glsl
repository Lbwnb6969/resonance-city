
uniform int uniImpostorLodLevel;
uniform vec3 uniCameraPosition;

#if defined LOD_DEBUG
uniform bool uniLodDebugColorEnabled;
#endif // LOD_DEBUG

//------------------------------------------------------------------------
layout(std430, binding = BIND_INDEX_GLOBAL_DATA_BUFFER) readonly buffer globalDataBuffer
{
	uint totalCount;
	uint nextBaseInstance;
} inGlobalDataBuffer;

layout(std140, binding = BIND_INDEX_ENTITY_BUFFER) readonly buffer entitiesBuffer
{
	Entity entities[];
} inEntitiesBuffer;

layout(std140, binding = BIND_INDEX_ENTITY_REF_BUFFER) readonly buffer entityRefBuffer
{
	EntityRef instances[];
} inEntityRefBuffer;

//------------------------------------------------------------------------
layout(std140, binding = BIND_INDEX_INSTANCE_BUFFER) writeonly buffer instanceBuffer
{
	InstanceData instances[];
} outBuffer;

layout(std430, binding = BIND_INDEX_COMMAND_BUFFER) buffer commandBuffer
{
	// 1 draw command per mesh
	IndirectDrawCommand cmd[];
} outCommandBuffer;

//------------------------------------------------------------------------
void main()
{
	// TODO: send by uniform!!
#if defined(LOD_DEBUG)
	const uint uniLodDebugColor[6] = {
		0xffffffff,
		0xff00ff00,
		0xffff5050,
		0xff20ffff,
		0xff0000ff,
		0xff0000ff
	};
#endif // defined(LOD_DEBUG)

	// Read current global position for this thread
    ivec3 storePos = ivec3(gl_GlobalInvocationID.xyz);

	// Calculate the global number of threads (size) for this
	uint gWidth = gl_WorkGroupSize.x * gl_NumWorkGroups.x;
	uint gHeight = gl_WorkGroupSize.y * gl_NumWorkGroups.y;
	uint gDepth = gl_WorkGroupSize.z * gl_NumWorkGroups.z;
	uint gSize = gWidth * gHeight * gDepth;

	// Since we have 1D array we need to calculate offset.
	uint instanceId = (storePos.z * gHeight + storePos.y) * gWidth + storePos.x;

	if (instanceId < inGlobalDataBuffer.totalCount)
	{
		EntityRef entityRef = inEntityRefBuffer.instances[instanceId];
		uint cmdId = entityRef.meshId;

		Entity entity = inEntitiesBuffer.entities[entityRef.entityId];

		mat4 worldMatrix = mat4(
			entity.worldMatrix[0].x, entity.worldMatrix[0].y, entity.worldMatrix[0].z, 0,
			entity.worldMatrix[0].w, entity.worldMatrix[1].x, entity.worldMatrix[1].y, 0,
			entity.worldMatrix[1].z, entity.worldMatrix[1].w, entity.worldMatrix[2].x, 0,
			entity.worldMatrix[2].y, entity.worldMatrix[2].z, entity.worldMatrix[2].w, 1);

		uint baseInstance = outCommandBuffer.cmd[cmdId].baseInstance;
		uint index = baseInstance + atomicAdd(outCommandBuffer.cmd[cmdId].instanceCount, 1);
		bool impostor = (entityRef.lodLevel == uniImpostorLodLevel);

		InstanceData instanceData;

		if (impostor)
		{
			vec3 position = entity.worldMatrix[2].yzw;
			float scale = entity.worldMatrix[1].x; // Assume Scale is uniform, and object is only rotate around Y (UP)
			vec3 z = uniCameraPosition - position;
			z.y = 0;
			z = normalize(z) * scale;

			for (uint i = 0; i < 3; ++i)
			{
				instanceData.worldMatrix[i] = entity.worldMatrix[i];
			}

			instanceData.worldMatrix[0].x = -z.z;
			instanceData.worldMatrix[0].y = 0;
			instanceData.worldMatrix[0].z = z.x;

			instanceData.worldMatrix[0].w = 0;
			instanceData.worldMatrix[1].x = scale;
			instanceData.worldMatrix[1].y = 0;

			instanceData.worldMatrix[1].z = z.x;
			instanceData.worldMatrix[1].w = 0;
			instanceData.worldMatrix[2].x = z.z;

			instanceData.worldMatrix[2].yzw = position;

			for (uint i = 0; i < 3; ++i)
			{
				instanceData.prevWorldMatrix[i] = instanceData.worldMatrix[i];
			}

			instanceData.materialId = 0;
		}
		else
		{
			for (uint i = 0; i < 3; ++i)
			{
				instanceData.worldMatrix[i] = entity.worldMatrix[i];
				instanceData.prevWorldMatrix[i] = entity.worldMatrix[i];
			}

			instanceData.materialId = entityRef.materialId;
		}

		instanceData.color = entity.color;

#if defined(LOD_DEBUG)
		if (uniLodDebugColorEnabled)
		{
			instanceData.color = uniLodDebugColor[entityRef.lodLevel];
		}
#endif // defined(LOD_DEBUG)

		outBuffer.instances[index] = instanceData;
    }
}