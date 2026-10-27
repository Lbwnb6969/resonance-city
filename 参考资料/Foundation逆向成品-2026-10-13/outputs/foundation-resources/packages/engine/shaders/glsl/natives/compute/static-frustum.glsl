
//------------------------------------------------------------------------
uniform vec4 uniPlane[12];
uniform int uniPlaneCount;
uniform vec3 uniCameraPosition;

uniform int uniEntityCount;
uniform int uniMaxLodLevel;
uniform float uniLodDistance[MAX_LOD_COUNT];

uniform bool uniIsShadowPass;

//------------------------------------------------------------------------
layout(std430, binding = BIND_INDEX_BATCH_DATA_BUFFER) readonly buffer batchDataBuffer
{
	BatchData batch[];
} inBatchDataBuffer;

layout(std140, binding = BIND_INDEX_MODEL_BUFFER) readonly buffer modelBuffer
{
	Model models[];
} inModelBuffer;

layout(std430, binding = BIND_INDEX_MODEL_REDIRECT_BUFFER) readonly buffer modelIdRedirectBuffer
{
    uint redirect[];
} inModelIdRedirectBuffer;

layout(std140, binding = BIND_INDEX_ENTITY_BUFFER) readonly buffer entitiesBuffer
{
	Entity entities[];
} inEntitiesBuffer;

//------------------------------------------------------------------------
layout(std140, binding = BIND_INDEX_ENTITY_REF_BUFFER) writeonly buffer entityRefBuffer
{
	EntityRef instances[];
} outEntityRefBuffer;

//------------------------------------------------------------------------
layout(std430, binding = BIND_INDEX_INST_COUNTER_BUFFER) buffer countBuffer
{
    uint count[];
} outCountBuffer;

layout(std430, binding = BIND_INDEX_GLOBAL_DATA_BUFFER) buffer globalDataBuffer
{
	uint totalCount;
	uint nextBaseInstance;
} outGlobalDataBuffer;

layout(std430, binding = BIND_INDEX_BATCH_MATERIAL_INFO_BUFFER) buffer batchMaterialInfoBuffer
{
	BatchMaterialInfo batchMaterialInfo[];
} outBatchMaterialInfoBuffer;

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
	uint entityId = (storePos.z * gHeight + storePos.y) * gWidth + storePos.x;

	// --------------------------
	if (entityId < uniEntityCount)
	{
		Entity entity = inEntitiesBuffer.entities[entityId];

		uint globalModelId = entity.modelId;
		uint localModelId = inModelIdRedirectBuffer.redirect[globalModelId];
		Model model = inModelBuffer.models[globalModelId];

		mat4 worldMatrix = mat4(
			entity.worldMatrix[0].x, entity.worldMatrix[0].y, entity.worldMatrix[0].z, 0,
			entity.worldMatrix[0].w, entity.worldMatrix[1].x, entity.worldMatrix[1].y, 0,
			entity.worldMatrix[1].z, entity.worldMatrix[1].w, entity.worldMatrix[2].x, 0,
			entity.worldMatrix[2].y, entity.worldMatrix[2].z, entity.worldMatrix[2].w, 1);

		vec4 bbMin = worldMatrix * vec4(model.boundingBoxMin, 1);
		vec4 bbMax = worldMatrix * vec4(model.boundingBoxMax, 1);
		vec4 center = (bbMin + bbMax) * 0.5;
		center.w = 1;
		float radius = length((bbMax - bbMin).xyz) * 0.5;
		bool inFrustum = true;

		for (int i = 0; i < uniPlaneCount; ++i)
		{
			float distance = dot(center, uniPlane[i]);

			// Out of frustum
			if (distance + radius <= 0)
			{
				inFrustum = false;
				break;
			}
		}

		if (inFrustum)
		{
			// NB: use pivot for distance to match dynamic object distance calculation,
			// otherwise we can have z-fighting between different LOD levels of the same model during highlight draw
			// (or any composition that mix static & dynamic draw)
			vec3 pivot = worldMatrix[3].xyz;
			float distance = length(pivot - uniCameraPosition);
			uint maxLodLevel = model.maxLodLevelAndBatchId & 0xffffu;	// lower half
			uint batchId = model.maxLodLevelAndBatchId >> 16;        	// upper half

			if (distance < uniLodDistance[min(maxLodLevel, uniMaxLodLevel)] && distance < model.maxDistance)
			{
				BatchData batchData = inBatchDataBuffer.batch[batchId];

				// Find appropriate LOD level
				int lod = 0;
				for (; distance > uniLodDistance[lod] && lod < batchData.lodCount - 1; ++lod)
				{}

				uint meshId = batchData.commandOffset + localModelId + lod * batchData.modelCount;
				uint materialId = (batchData.lodMaterialCount == 1 ? entity.materialId : (entity.materialId * batchData.lodMaterialCount + lod));

				if (!uniIsShadowPass)
				{
					uint globalMaterialId = batchData.globalMaterialIdOffset + materialId;
					float closestDistance = max(0, distance - radius);
					float uvScale = model.uvDensity * closestDistance;
					atomicMin(outBatchMaterialInfoBuffer.batchMaterialInfo[globalMaterialId].m_minUvScale, floatBitsToUint(uvScale));
				}

				// Increment mesh instance count
				atomicAdd(outCountBuffer.count[meshId], 1);

				// Increment total mesh instance count
				uint index = atomicAdd(outGlobalDataBuffer.totalCount, 1);

				EntityRef entityRef;
				entityRef.meshId = meshId;
				entityRef.materialId = materialId;
				entityRef.entityId = entityId;
				entityRef.lodLevel = lod;

				outEntityRefBuffer.instances[index] = entityRef;
			}
		}
	}
}
