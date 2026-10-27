
//#extension GL_NV_gpu_shader5 : require

//------------------------------------------------------------------------
// Mesh Model referenced by any World Entity
struct Model
{
	vec3 boundingBoxMin;
	float maxDistance;
	vec3 boundingBoxMax;
	float uvDensity;

	//int16_t maxLodLevel;
	//uint16_t batchId;
	uint maxLodLevelAndBatchId;
};

//------------------------------------------------------------------------
// Entity (Instance in the scene)
struct Entity
{
	vec4 worldMatrix[3];
	uint color;
	uint modelId;
	uint materialId;
	uint padding1;
};

//------------------------------------------------------------------------
// Batch Data - Data that will lead to a single batch multi instance draw
struct BatchData
{
	uint commandOffset;
	uint modelCount;
	uint lodCount;
	uint lodMaterialCount;
	uint globalMaterialIdOffset;
};

//------------------------------------------------------------------------
// Batch Material Info - Data for each material used to compute the required texture mipmap level
struct BatchMaterialInfo
{
	uint m_minUvScale; // float represented as uint
};

//------------------------------------------------------------------------
// Reference to a visible Entity, with specific LOD
struct EntityRef
{
	uint meshId;
	uint materialId;
	uint entityId;
	uint lodLevel;
};

//------------------------------------------------------------------------
// Instance Data forwarded to vertex shader
struct InstanceData
{
	vec4 worldMatrix[3];
	vec4 prevWorldMatrix[3];
	uint materialId;
	uint color;
};

//------------------------------------------------------------------------
struct IndirectDrawCommand
{
	uint count;
	uint instanceCount;
	uint firstIndex;
	uint baseVertex;
	uint baseInstance;
};

//------------------------------------------------------------------------
#define BIND_INDEX_MODEL_BUFFER 0				// frustum	|			|
#define BIND_INDEX_MODEL_REDIRECT_BUFFER 1		// frustum	|			|
#define BIND_INDEX_ENTITY_BUFFER 2				// frustum	|			| batch-inst
#define BIND_INDEX_ENTITY_REF_BUFFER 3			// frustum	|			| batch-inst
#define BIND_INDEX_INST_COUNTER_BUFFER 4		// frustum	| base-inst |
#define BIND_INDEX_BATCH_DATA_BUFFER 5			// frustum	| base-inst	|
#define BIND_INDEX_GLOBAL_DATA_BUFFER 6			// frustum	| base-inst	| batch-inst
#define BIND_INDEX_BATCH_MATERIAL_INFO_BUFFER 7	// frustum	|			| 

#define BIND_INDEX_COMMAND_BUFFER 0				// 			| base-inst	| batch-inst
#define BIND_INDEX_INSTANCE_BUFFER 1			// 			|			| batch-inst