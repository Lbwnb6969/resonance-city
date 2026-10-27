using System.Collections.Generic;
using Assets;
using Sirenix.OdinInspector;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class TreeSystem : MonoBehaviour
{
	public class TreeCellData
	{
		public int[] TreeIds;

		public int TreeAmount;

		public TreeCellData(int itemNum)
		{
			TreeIds = new int[itemNum];
			for (int i = 0; i < itemNum; i++)
			{
				TreeIds[i] = -1;
			}
		}

		public void AddTreeId(int idx)
		{
			for (int i = 0; i < TreeIds.Length; i++)
			{
				if (TreeIds[i] == -1)
				{
					TreeAmount++;
					TreeIds[i] = idx;
					break;
				}
			}
		}

		public void RemoveTreeId(int idx)
		{
			for (int i = 0; i < TreeIds.Length; i++)
			{
				if (TreeIds[i] == idx)
				{
					TreeIds[i] = -1;
					TreeAmount--;
				}
			}
		}

		public void ReplaceTreeIdx(int old, int newId)
		{
			for (int i = 0; i < TreeIds.Length; i++)
			{
				if (TreeIds[i] == old)
				{
					TreeIds[i] = newId;
				}
			}
		}

		public int FirstTree()
		{
			for (int i = 0; i < TreeIds.Length; i++)
			{
				if (TreeIds[i] != -1)
				{
					return TreeIds[i];
				}
			}
			return -1;
		}
	}

	public class Chunk
	{
		public int x;

		public int z;

		public NativeArray<Matrix4x4> matrices;

		public TreeData[] itemData;

		public NativeArray<uint> meshIdxs;

		public ComputeBuffer matrixBuffer;

		public ComputeBuffer meshIdxBuffer;

		public ComputeBuffer argsBuffer;

		public Material mat;

		public Material maskMaterial;

		public uint[] args;

		public bool isDirty;

		public int itemCount;

		public CullingGroup cullingGroup;

		private BoundingSphere[] spheres = new BoundingSphere[1];

		private MaterialPropertyBlock propertyBlock = new MaterialPropertyBlock();

		private bool visible;

		public Chunk(int _x, int _z, int chunkSize, int maxTreesPerChunk, Mesh mesh, Material material, float LODCutoffDist)
		{
			matrices = new NativeArray<Matrix4x4>(maxTreesPerChunk, Allocator.Persistent);
			meshIdxs = new NativeArray<uint>(maxTreesPerChunk, Allocator.Persistent);
			itemData = new TreeData[maxTreesPerChunk];
			matrixBuffer = new ComputeBuffer(maxTreesPerChunk, 64);
			ComputeBufferNaming.SetName(matrixBuffer, $"TreeChunk_{_x}_{_z}_MatrixBuffer");
			matrixBuffer.SetData(matrices);
			meshIdxBuffer = new ComputeBuffer(maxTreesPerChunk, 4);
			ComputeBufferNaming.SetName(meshIdxBuffer, $"TreeChunk_{_x}_{_z}_MeshIndexBuffer");
			meshIdxBuffer.SetData(meshIdxs);
			mat = Object.Instantiate(material);
			mat.SetBuffer("matrixBuffer", matrixBuffer);
			mat.SetBuffer("meshIdxBuffer", meshIdxBuffer);
			mat.SetFloat("_LODCutoffDist", LODCutoffDist);
			maskMaterial = Object.Instantiate(TreeSystem.maskMaterial);
			maskMaterial.SetBuffer("matrixBuffer", matrixBuffer);
			maskMaterial.SetBuffer("meshIdxBuffer", meshIdxBuffer);
			args = new uint[5];
			args[0] = ((mesh != null) ? mesh.GetIndexCount(0) : 0u);
			args[1] = (uint)matrices.Length;
			args[2] = ((mesh != null) ? mesh.GetIndexStart(0) : 0u);
			args[3] = ((mesh != null) ? mesh.GetBaseVertex(0) : 0u);
			args[4] = 0u;
			argsBuffer = new ComputeBuffer(1, args.Length * 4, ComputeBufferType.DrawIndirect);
			ComputeBufferNaming.SetName(argsBuffer, $"TreeChunk_{_x}_{_z}_ArgsBuffer");
			argsBuffer.SetData(args);
			x = _x;
			z = _z;
			cullingGroup = new CullingGroup();
			cullingGroup.onStateChanged = StateChangedMethod;
			cullingGroup.SetBoundingSpheres(spheres);
			cullingGroup.SetBoundingSphereCount(1);
			cullingGroup.targetCamera = Cam.inst.cam;
			spheres[0] = new BoundingSphere(new Vector3((float)x + (float)chunkSize * 0.5f, chunkSize / 4, (float)z + (float)chunkSize * 0.5f), (float)chunkSize * 0.5f * Mathf.Sqrt(2f));
			isDirty = true;
		}

		public void Destroy()
		{
			if (matrices.IsCreated)
			{
				matrices.Dispose();
			}
			if (meshIdxs.IsCreated)
			{
				meshIdxs.Dispose();
			}
			if (matrixBuffer != null)
			{
				matrixBuffer.Dispose();
				matrixBuffer = null;
			}
			if (meshIdxBuffer != null)
			{
				meshIdxBuffer.Dispose();
				meshIdxBuffer = null;
			}
			if (argsBuffer != null)
			{
				argsBuffer.Dispose();
				argsBuffer = null;
			}
			itemData = null;
			if (cullingGroup != null)
			{
				cullingGroup.Dispose();
				cullingGroup = null;
			}
		}

		public void StateChangedMethod(CullingGroupEvent evt)
		{
			visible = evt.isVisible;
		}

		internal void SetItem(TreeCellData cell, Vector3 pos, Vector3 scale, Quaternion rot, int mIdx = -1)
		{
			int num = itemCount;
			itemData[num].pos = pos;
			itemData[num].scale = scale;
			itemData[num].rotation = rot;
			itemData[num].owner = cell;
			meshIdxs[num] = (uint)((mIdx == -1) ? SRand.Range(0, 5) : mIdx);
			matrices[num] = Matrix4x4.TRS(pos, rot, scale);
			cell.AddTreeId(num);
			itemCount++;
			isDirty = true;
		}

		internal void UpdateItemPosition(int idx, Vector3 pos)
		{
			itemData[idx].pos = pos;
			matrices[idx] = Matrix4x4.TRS(pos, itemData[idx].rotation, itemData[idx].scale);
			isDirty = true;
		}

		internal void DrawItems(Mesh treeMesh, Material material, bool doShadows, float LODCutoffDistSqrd)
		{
			if (itemCount > 0 && (visible || forceVisibleAll) && (Mathff.DistSqrd(spheres[0].position, Cam.inst.CamPos) < LODCutoffDistSqrd || forceVisibleAll))
			{
				mat.SetBuffer("matrixBuffer", matrixBuffer);
				mat.SetBuffer("meshIdxBuffer", meshIdxBuffer);
				if (isDirty)
				{
					args[1] = (uint)itemCount;
					matrixBuffer.SetData(matrices, 0, 0, itemCount);
					meshIdxBuffer.SetData(meshIdxs, 0, 0, itemCount);
					argsBuffer.SetData(args);
					isDirty = false;
				}
				Graphics.DrawMeshInstancedIndirect(treeMesh, 0, mat, bounds, argsBuffer, 0, null, doShadows ? ShadowCastingMode.On : ShadowCastingMode.Off);
			}
		}

		internal void DrawItemsWithCommandBuffer(CommandBuffer commandBuffer, Mesh treeMesh, int shaderPass = -1)
		{
			if (itemCount > 0 && (visible || forceVisibleAll))
			{
				if (isDirty)
				{
					args[1] = (uint)itemCount;
					matrixBuffer.SetData(matrices, 0, 0, itemCount);
					meshIdxBuffer.SetData(meshIdxs, 0, 0, itemCount);
					argsBuffer.SetData(args);
					isDirty = false;
				}
				commandBuffer.DrawMeshInstancedIndirect(treeMesh, 0, maskMaterial, shaderPass, argsBuffer, 0, null);
			}
		}

		internal uint RemoveItem(int idx)
		{
			int num = itemCount - 1;
			itemData[idx].pos = itemData[num].pos;
			itemData[idx].scale = itemData[num].scale;
			itemData[idx].rotation = itemData[num].rotation;
			if (itemData[idx].owner != null)
			{
				itemData[idx].owner.RemoveTreeId(idx);
			}
			if (itemData[num].owner != null)
			{
				itemData[num].owner.ReplaceTreeIdx(num, idx);
			}
			itemData[idx].owner = itemData[num].owner;
			uint result = meshIdxs[idx];
			meshIdxs[idx] = meshIdxs[num];
			matrices[idx] = Matrix4x4.TRS(itemData[idx].pos, itemData[idx].rotation, itemData[idx].scale);
			itemCount--;
			isDirty = true;
			return result;
		}
	}

	public struct AnimTreeData
	{
		public Quaternion rotation;

		public Vector3 pos;

		public Vector3 scale;

		public Cell cell;

		public bool inUse;

		public float time;
	}

	public struct TreeData
	{
		public Quaternion rotation;

		public Vector3 pos;

		public Vector3 scale;

		public int matrixList;

		public int matrixIdx;

		public TreeCellData owner;
	}

	private struct FallAnimData
	{
		public float startRot;

		public float endRot;

		public float startY;

		public float endY;

		public int phase;
	}

	private struct ShakeAnimData
	{
		public float time;

		public Vector3 startAngles;

		public int rand;

		public Cell cell;
	}

	public static bool forceVisibleAll = false;

	public static Material maskMaterial;

	private static Bounds bounds = new Bounds(new Vector3(0f, 0f, 0f), new Vector3(500f, 500f, 500f));

	public int type;

	public const int TYPE_TREE = 0;

	public const int TYPE_GRASS = 1;

	public const int TYPE_ROCK = 2;

	public static ValueDropdownList<int> ValueDropdown = new ValueDropdownList<int>
	{
		{ "Tree", 0 },
		{ "Grass", 1 },
		{ "Rock", 2 }
	};

	public static List<TreeSystem> systems = new List<TreeSystem>();

	public float itemRadius = 0.2f;

	private TreeCellData[] cellData;

	public int chunkSize = 30;

	public Chunk[] chunks;

	private int numChunksX;

	private int numChunksZ;

	public int itemsPerCell = 3;

	public Mesh treeMesh;

	public Material material;

	private MaterialPropertyBlock animPropertyBlock;

	private NativeArray<Matrix4x4> animMatrices;

	private NativeArray<uint> animMeshIdxs;

	private AnimTreeData[] animTreeData = new AnimTreeData[512];

	private ComputeBuffer animMatrixBuffer;

	private ComputeBuffer animMeshIdxBuffer;

	private ComputeBuffer animArgsBuffer;

	public Material animMaterial;

	public Material animMaskMaterial;

	private uint[] animArgs = new uint[5];

	private List<Matrix4x4[]> matrices = new List<Matrix4x4[]>();

	private TreeData invalidData;

	private List<Vector3> cellOffsets = new List<Vector3>();

	public MinMax heightOffset;

	public float placementHalfWidth = 0.4f;

	public float newGrowthTime = 15f;

	private ArrayExt<int> growAnimIdx = new ArrayExt<int>(200);

	private ArrayExt<Vector3> growSize = new ArrayExt<Vector3>(200);

	private ArrayExt<uint> growMeshIdx = new ArrayExt<uint>(200);

	public MinMax xScale = new MinMax(1f, 1.5f);

	public MinMax yScale = new MinMax(1f, 1.5f);

	public MinMax zScale = new MinMax(1f, 1.5f);

	public bool alignToTerrain;

	private Vector3 up = new Vector3(0f, 1f, 0f);

	public bool fullyRandomRotation;

	public float uniformScaleBlend;

	private ArrayExt<FallAnimData> fallAnimData = new ArrayExt<FallAnimData>(200);

	private ArrayExt<int> fallAnimIdx = new ArrayExt<int>(200);

	private float flowerScale;

	public bool castShadows = true;

	public float LODCutoffDist = 9999f;

	private ArrayExt<int> shakeAnimIdx = new ArrayExt<int>(200);

	private ArrayExt<ShakeAnimData> shakeAnimData = new ArrayExt<ShakeAnimData>(200);

	public float magnitude = 10f;

	public float freq = 5f;

	private bool visible = true;

	private void GenerateOffsets()
	{
		cellOffsets.Clear();
		bool flag = false;
		Vector3 vector = default;
		while (true)
		{
			int num = 25;
			do
			{
				vector.x = SRand.Range(0f - placementHalfWidth, placementHalfWidth);
				vector.z = SRand.Range(0f - placementHalfWidth, placementHalfWidth);
				vector.y = 0f;
				flag = false;
				for (int i = 0; i < cellOffsets.Count; i++)
				{
					if (Mathff.DistSqrd(cellOffsets[i], vector) < itemRadius * itemRadius)
					{
						flag = true;
					}
				}
				num--;
			}
			while (flag && num > 0);
			if (num > 0)
			{
				cellOffsets.Add(vector);
				continue;
			}
			break;
		}
	}

	private void Start()
	{
		maskMaterial = Resources.Load<Material>("TreeSystemMaskMaterial");
		animPropertyBlock = new MaterialPropertyBlock();
		Quaternion identity = Quaternion.identity;
		for (int i = 0; i < animTreeData.Length; i++)
		{
			animTreeData[i].rotation = identity;
		}
		animMatrices = new NativeArray<Matrix4x4>(512, Allocator.Persistent);
		animMeshIdxs = new NativeArray<uint>(512, Allocator.Persistent);
		animMatrixBuffer = new ComputeBuffer(512, 64);
		ComputeBufferNaming.SetName(animMatrixBuffer, "TreeSystem_AnimMatrixBuffer");
		animMatrixBuffer.SetData(animMatrices);
		animMeshIdxBuffer = new ComputeBuffer(512, 4);
		ComputeBufferNaming.SetName(animMeshIdxBuffer, "TreeSystem_AnimMeshIndexBuffer");
		animMeshIdxBuffer.SetData(animMeshIdxs);
		animMaterial = Object.Instantiate(material);
		animMaterial.SetBuffer("matrixBuffer", animMatrixBuffer);
		animMaterial.SetBuffer("meshIdxBuffer", animMeshIdxBuffer);
		animMaskMaterial = Object.Instantiate(maskMaterial);
		animMaskMaterial.SetBuffer("matrixBuffer", animMatrixBuffer);
		animMaskMaterial.SetBuffer("meshIdxBuffer", animMeshIdxBuffer);
		animArgs = new uint[5];
		animArgs[0] = ((treeMesh != null) ? treeMesh.GetIndexCount(0) : 0u);
		animArgs[1] = (uint)animMatrices.Length;
		animArgs[2] = ((treeMesh != null) ? treeMesh.GetIndexStart(0) : 0u);
		animArgs[3] = ((treeMesh != null) ? treeMesh.GetBaseVertex(0) : 0u);
		animArgs[4] = 0u;
		animArgsBuffer = new ComputeBuffer(1, animArgs.Length * 4, ComputeBufferType.DrawIndirect);
		ComputeBufferNaming.SetName(animArgsBuffer, "TreeSystem_AnimArgsBuffer");
		animArgsBuffer.SetData(animArgs);
		systems.Add(this);
	}

	public TreeCellData GetTreeCellDataAt(int x, int z)
	{
		int num = z * World.inst.GridWidth + x;
		if (!cellData.IsNull() && x >= 0 && x < World.inst.GridWidth && z >= 0 && z < World.inst.GridHeight)
		{
			return cellData[num];
		}
		return null;
	}

	internal float EstimateTreeDensity(int x, int z)
	{
		int num = x / chunkSize;
		int num2 = z / chunkSize;
		int num3 = 1;
		int num4 = chunks[num2 * numChunksX + num].itemCount;
		if (num2 < numChunksZ - 1)
		{
			num4 += chunks[(num2 + 1) * numChunksX + num].itemCount;
			num3++;
		}
		if (num2 > 0)
		{
			num4 += chunks[(num2 - 1) * numChunksX + num].itemCount;
			num3++;
		}
		if (num < numChunksX - 1)
		{
			num4 += chunks[num2 * numChunksX + (num + 1)].itemCount;
			num3++;
		}
		if (num > 0)
		{
			num4 += chunks[num2 * numChunksX + (num - 1)].itemCount;
			num3++;
		}
		if (num2 < numChunksZ - 1 && num > 0)
		{
			num4 += chunks[(num2 + 1) * numChunksX + (num - 1)].itemCount;
			num3++;
		}
		if (num2 < numChunksZ - 1 && num < numChunksX - 1)
		{
			num4 += chunks[(num2 + 1) * numChunksX + (num + 1)].itemCount;
			num3++;
		}
		if (num2 > 0 && num > 0)
		{
			num4 += chunks[(num2 - 1) * numChunksX + (num - 1)].itemCount;
			num3++;
		}
		if (num2 > 0 && num < numChunksX - 1)
		{
			num4 += chunks[(num2 - 1) * numChunksX + (num + 1)].itemCount;
			num3++;
		}
		return (float)num4 / (float)itemsPerCell / (float)(num3 * chunkSize * chunkSize);
	}

	private void InitChunks()
	{
		numChunksX = World.inst.GridWidth / chunkSize + 1;
		numChunksZ = World.inst.GridHeight / chunkSize + 1;
		Vector3 one = Vector3.one;
		Quaternion identity = Quaternion.identity;
		chunks = new Chunk[numChunksX * numChunksZ];
		for (int i = 0; i < numChunksZ; i++)
		{
			for (int j = 0; j < numChunksX; j++)
			{
				Chunk chunk = new Chunk(j * chunkSize, i * chunkSize, chunkSize, chunkSize * chunkSize * itemsPerCell, treeMesh, material, LODCutoffDist);
				for (int k = 0; k < chunk.itemData.Length; k++)
				{
					chunk.itemData[k].pos.x = chunk.x;
					chunk.itemData[k].pos.y = 0f;
					chunk.itemData[k].pos.x = chunk.z;
					chunk.itemData[k].scale = one;
					chunk.itemData[k].rotation = identity;
				}
				chunks[i * numChunksX + j] = chunk;
			}
		}
	}

	private void UpdateAnimMatrixFor(int i)
	{
		animMatrices[i] = Matrix4x4.TRS(animTreeData[i].pos, animTreeData[i].rotation, animTreeData[i].scale);
	}

	internal int GetFirstItem(Cell cell)
	{
		return cellData[cell.index].FirstTree();
	}

	internal int ItemAmount(Cell cellToChop)
	{
		return cellData[cellToChop.index].TreeAmount;
	}

	internal int ItemAmountIncludeAnimatingTrees(Cell cellToChop)
	{
		AnimIdxCount(cellToChop, out var _, out var animatingTrees);
		return cellData[cellToChop.index].TreeAmount + animatingTrees;
	}

	internal float GetAnimTreeProgress(Cell cell)
	{
		for (int i = 0; i < animTreeData.Length; i++)
		{
			if (animTreeData[i].inUse && animTreeData[i].cell == cell)
			{
				return animTreeData[i].time / newGrowthTime;
			}
		}
		return 0f;
	}

	internal int ItemAmount(int idx)
	{
		return cellData[idx].TreeAmount;
	}

	public TreeData GetItem(Cell cell, int idx)
	{
		return GetItem(cell.x, cell.z, idx);
	}

	public TreeData GetItem(int x, int z, int idx)
	{
		if (idx == -1)
		{
			return invalidData;
		}
		int num = x / chunkSize;
		int num2 = z / chunkSize;
		return chunks[num2 * numChunksX + num].itemData[idx];
	}

	public Chunk GetChunk(int x, int z)
	{
		int num = x / chunkSize;
		int num2 = z / chunkSize;
		return chunks[num2 * numChunksX + num];
	}

	public void TryInit()
	{
		if (cellData == null)
		{
			cellData = new TreeCellData[World.inst.GridWidth * World.inst.GridHeight];
			for (int i = 0; i < cellData.Length; i++)
			{
				cellData[i] = new TreeCellData(itemsPerCell);
			}
			InitChunks();
		}
	}

	public Vector3 GetPosForNewItem(Cell cell, float sY, out Vector3 normal)
	{
		int num = cell.x / chunkSize;
		int num2 = cell.z / chunkSize;
		Chunk chunk = chunks[num2 * numChunksX + num];
		TreeCellData treeCellData = cellData[cell.index];
		int num3 = 10;
		Vector3 vector = default;
		do
		{
			int index = SRand.Range(0, cellOffsets.Count);
			float num4 = cellOffsets[index].x;
			if (cell.x % 2 != 0)
			{
				num4 *= -1f;
			}
			vector.x = (float)cell.x + 0.5f + num4;
			vector.y = 0f;
			float num5 = cellOffsets[index].z;
			if (cell.z % 2 != 0)
			{
				num5 *= -1f;
			}
			vector.z = (float)cell.z + 0.5f + num5;
			bool flag = false;
			for (int i = 0; i < treeCellData.TreeAmount; i++)
			{
				int num6 = treeCellData.TreeIds[i];
				if (num6 != -1)
				{
					TreeData treeData = chunk.itemData[num6];
					if (Mathff.Abs(treeData.pos.x - vector.x) < 0.01f && Mathff.Abs(treeData.pos.z - vector.z) < 0.01f)
					{
						flag = true;
						break;
					}
				}
			}
			if (!flag)
			{
				break;
			}
			num3--;
		}
		while (num3 > 0);
		vector.y = TerrainGen.inst.GetInterpolatedHeightWithNormal(vector, out normal) + heightOffset.Rand() * (sY / yScale.Max - yScale.Min);
		return vector;
	}

	public int AnimCount(Cell cell)
	{
		int num = 0;
		for (int i = 0; i < animTreeData.Length; i++)
		{
			if (animTreeData[i].cell == cell)
			{
				num++;
			}
		}
		return num;
	}

	private void AnimIdxCount(Cell cell, out int freeIdx, out int animatingTrees)
	{
		freeIdx = -1;
		animatingTrees = 0;
		for (int i = 0; i < animTreeData.Length; i++)
		{
			if (!animTreeData[i].inUse)
			{
				freeIdx = i;
			}
			else if (animTreeData[i].cell == cell)
			{
				animatingTrees++;
			}
		}
	}

	private void UpdateGrowAnims(float dt)
	{
		for (int i = 0; i < growAnimIdx.Count; i++)
		{
			int num = growAnimIdx.data[i];
			animTreeData[num].time += dt;
			float num2 = animTreeData[num].time / newGrowthTime;
			Vector3 scale = Vector3.Lerp(Vector3.zero, growSize.data[i], num2);
			animTreeData[num].scale = scale;
			UpdateAnimMatrixFor(num);
			if (num2 >= 1f)
			{
				SetItem(animTreeData[num].cell, animTreeData[num].pos, animTreeData[num].scale, animTreeData[num].rotation, (int)growMeshIdx.data[i]);
				ResetAnimData(num);
				growAnimIdx.RemoveAtSwap(i);
				growSize.RemoveAtSwap(i);
				growMeshIdx.RemoveAtSwap(i);
				i--;
			}
		}
	}

	public void GrowTree(Cell cell, Vector3 pos)
	{
		int freeIdx = -1;
		int animatingTrees = 0;
		AnimIdxCount(cell, out freeIdx, out animatingTrees);
		if (ItemAmount(cell) + animatingTrees < itemsPerCell)
		{
			Vector3 scaleForNewItem = GetScaleForNewItem();
			TerrainGen.inst.GetInterpolatedHeightWithNormal(pos, out var normal);
			Quaternion rotationForNewItem = GetRotationForNewItem(pos, normal);
			if (freeIdx != -1)
			{
				animTreeData[freeIdx].pos = pos;
				animTreeData[freeIdx].rotation = rotationForNewItem;
				animTreeData[freeIdx].cell = cell;
				animTreeData[freeIdx].inUse = true;
				animTreeData[freeIdx].time = 0f;
				growAnimIdx.Add(freeIdx);
				growSize.Add(scaleForNewItem);
				uint num = (uint)SRand.Range(0, 5);
				growMeshIdx.Add(num);
				animMeshIdxs[freeIdx] = num;
			}
			else
			{
				SetItem(cell, pos, scaleForNewItem, rotationForNewItem);
			}
		}
	}

	public void GrowTree(Cell cell)
	{
		int freeIdx = -1;
		int animatingTrees = 0;
		AnimIdxCount(cell, out freeIdx, out animatingTrees);
		if (ItemAmount(cell) + animatingTrees < itemsPerCell)
		{
			Vector3 scaleForNewItem = GetScaleForNewItem();
			Vector3 posForNewItem = GetPosForNewItem(cell, scaleForNewItem.y, out var normal);
			Quaternion rotationForNewItem = GetRotationForNewItem(posForNewItem, normal);
			if (freeIdx != -1)
			{
				animTreeData[freeIdx].pos = posForNewItem;
				animTreeData[freeIdx].rotation = rotationForNewItem;
				animTreeData[freeIdx].cell = cell;
				animTreeData[freeIdx].inUse = true;
				animTreeData[freeIdx].time = 0f;
				growAnimIdx.Add(freeIdx);
				growSize.Add(scaleForNewItem);
				uint num = (uint)SRand.Range(0, 5);
				growMeshIdx.Add(num);
				animMeshIdxs[freeIdx] = num;
			}
			else
			{
				SetItem(cell, posForNewItem, scaleForNewItem, rotationForNewItem);
			}
		}
	}

	private void ResetAnimData(int idx)
	{
		animTreeData[idx].cell = null;
		animTreeData[idx].inUse = false;
		animTreeData[idx].scale = Vector3.zero;
		animTreeData[idx].time = 0f;
		UpdateAnimMatrixFor(idx);
	}

	private Vector3 GetScaleForNewItem()
	{
		Vector3 vector = new Vector3(xScale.Rand(), yScale.Rand(), zScale.Rand());
		if (uniformScaleBlend > 0f)
		{
			float num = (vector.x + vector.y + vector.z) / 3f;
			return Vector3.Lerp(vector, new Vector3(num, num, num), uniformScaleBlend);
		}
		return vector;
	}

	private Quaternion GetRotationForNewItem(Vector3 pos, Vector3 normal)
	{
		if (!fullyRandomRotation)
		{
			Vector3 toDirection = up;
			if (alignToTerrain)
			{
				toDirection = normal;
			}
			return Quaternion.FromToRotation(up, toDirection) * Quaternion.Euler(0f, SRand.value * 35f + (float)(SRand.Range(0, 3) * 45), 0f);
		}
		return Quaternion.Euler(SRand.Range(0, 180), SRand.Range(0, 180), SRand.Range(0, 180));
	}

	public void PlaceItem(Cell cell, bool ignoreWater = false, bool allowOnMountains = false)
	{
		if ((ignoreWater || (!(DynamicWater.inst.simplifiedWaterGrid[cell.index] > 0f) && cell.Type != TerrainType.Water)) && (cell.Type == TerrainType.None || (allowOnMountains && cell.Type == TerrainType.Obstruction)))
		{
			Vector3 scaleForNewItem = GetScaleForNewItem();
			Vector3 posForNewItem = GetPosForNewItem(cell, scaleForNewItem.y, out var normal);
			Quaternion rotationForNewItem = GetRotationForNewItem(posForNewItem, normal);
			if (fullyRandomRotation || !(Vector3.Dot((rotationForNewItem * up).normalized, up) < 0.33f))
			{
				SetItem(cell, posForNewItem, scaleForNewItem, rotationForNewItem);
			}
		}
	}

	public void SetItem(Cell cell, Vector3 pos, Vector3 scale, Quaternion rot, int mIdx = -1)
	{
		if (!cell.Busy && cellData[cell.index].TreeAmount < itemsPerCell)
		{
			int num = cell.x / chunkSize;
			int num2 = cell.z / chunkSize;
			chunks[num2 * numChunksX + num].SetItem(cellData[cell.index], pos, scale, rot, mIdx);
		}
	}

	public void SnapItemsToTerrain(Cell cell)
	{
		int num = cell.x / chunkSize;
		int num2 = cell.z / chunkSize;
		Chunk chunk = chunks[num2 * numChunksX + num];
		TreeCellData treeCellData = cellData[cell.index];
		for (int i = 0; i < treeCellData.TreeAmount; i++)
		{
			int num3 = treeCellData.TreeIds[i];
			if (num3 != -1)
			{
				TreeData treeData = chunk.itemData[num3];
				treeData.pos.y = TerrainGen.inst.GetGroundHeight(treeData.pos.x, treeData.pos.z);
				chunk.UpdateItemPosition(num3, treeData.pos);
			}
		}
	}

	public void SnapItemsToTerrain(int index)
	{
		int num = index % World.inst.GridWidth / chunkSize;
		int num2 = index / World.inst.GridWidth / chunkSize;
		Chunk chunk = chunks[num2 * numChunksX + num];
		TreeCellData treeCellData = cellData[index];
		for (int i = 0; i < treeCellData.TreeAmount; i++)
		{
			int num3 = treeCellData.TreeIds[i];
			if (num3 != -1)
			{
				TreeData treeData = chunk.itemData[num3];
				treeData.pos.y = TerrainGen.inst.GetGroundHeight(treeData.pos.x, treeData.pos.z);
				chunk.UpdateItemPosition(num3, treeData.pos);
			}
		}
	}

	private void UpdateFallAnims(float dt)
	{
		for (int i = 0; i < fallAnimIdx.Count; i++)
		{
			int num = fallAnimIdx.data[i];
			animTreeData[num].time += dt;
			if (fallAnimData.data[i].phase == 0)
			{
				float num2 = animTreeData[num].time / 1.5f;
				float x = Mathff.EaseInCirc(fallAnimData.data[i].startRot, fallAnimData.data[i].endRot, num2);
				Vector3 eulerAngles = animTreeData[num].rotation.eulerAngles;
				eulerAngles.x = x;
				animTreeData[num].rotation = Quaternion.Euler(eulerAngles);
				UpdateAnimMatrixFor(num);
				if (num2 >= 1f)
				{
					animTreeData[num].time = 0f;
					fallAnimData.data[i].phase = 1;
				}
				continue;
			}
			float num3 = animTreeData[num].time / 6f;
			Vector3 pos = animTreeData[num].pos;
			pos.y = Mathff.Lerp(fallAnimData.data[i].startY, fallAnimData.data[i].endY, num3);
			animTreeData[num].pos = pos;
			UpdateAnimMatrixFor(num);
			if (num3 >= 1f)
			{
				fallAnimIdx.RemoveAtSwap(i);
				fallAnimData.RemoveAtSwap(i);
				i--;
				ResetAnimData(num);
			}
		}
	}

	public void FellTree(Cell cell, int idx)
	{
		TreeData item = GetItem(cell, idx);
		Vector3 pos = item.pos;
		Vector3 scale = item.scale;
		Quaternion rotation = item.rotation;
		AnimIdxCount(cell, out var freeIdx, out var _);
		uint value = RemoveTree(cell, idx);
		if (freeIdx != -1)
		{
			animMeshIdxs[freeIdx] = value;
			animTreeData[freeIdx].pos = pos;
			animTreeData[freeIdx].scale = scale;
			animTreeData[freeIdx].rotation = rotation;
			animTreeData[freeIdx].inUse = true;
			UpdateAnimMatrixFor(freeIdx);
			fallAnimIdx.Add(freeIdx);
			FallAnimData item2 = new FallAnimData
			{
				startRot = animTreeData[freeIdx].rotation.eulerAngles.x,
				endRot = animTreeData[freeIdx].rotation.eulerAngles.x + 90f,
				phase = 0,
				startY = animTreeData[freeIdx].pos.y,
				endY = animTreeData[freeIdx].pos.y - 0.6f
			};
			fallAnimData.Add(item2);
		}
		CheckDeforestMilestone();
	}

	public void DeleteTreesAt(Cell c)
	{
		TreeCellData treeCellData = cellData[c.index];
		if (treeCellData.TreeAmount == 0)
		{
			return;
		}
		for (int i = 0; i < treeCellData.TreeIds.Length; i++)
		{
			if (treeCellData.TreeIds[i] != -1)
			{
				RemoveTree(c, treeCellData.TreeIds[i]);
			}
			treeCellData.TreeIds[i] = -1;
		}
		treeCellData.TreeAmount = 0;
		CheckDeforestMilestone();
	}

	public void DeleteTreesAt(int index)
	{
		TreeCellData treeCellData = cellData[index];
		if (treeCellData.TreeAmount == 0)
		{
			return;
		}
		int x = index % World.inst.GridWidth;
		int z = index / World.inst.GridWidth;
		for (int i = 0; i < treeCellData.TreeIds.Length; i++)
		{
			if (treeCellData.TreeIds[i] != -1)
			{
				RemoveTreeIndex(x, z, treeCellData.TreeIds[i]);
			}
			treeCellData.TreeIds[i] = -1;
		}
		treeCellData.TreeAmount = 0;
		CheckDeforestMilestone();
	}

	public bool HasNoTrees()
	{
		if (chunks == null)
		{
			return true;
		}
		for (int i = 0; i < chunks.Length; i++)
		{
			if (chunks[i].itemCount > 0)
			{
				return false;
			}
		}
		return true;
	}

	private void CheckDeforestMilestone()
	{
		if (type == 0 && HasNoTrees())
		{
			TreeSystem treeSystem = ((this == World.inst.treeSystem) ? World.inst.coppiceTreeSystem : World.inst.treeSystem);
			if (!(treeSystem != null) || treeSystem.HasNoTrees())
			{
				MilestoneManager.inst.TryDeforestWorldMilestone();
			}
		}
	}

	public uint RemoveTree(Cell cell, int idx)
	{
		int num = cell.x / chunkSize;
		int num2 = cell.z / chunkSize;
		return chunks[num2 * numChunksX + num].RemoveItem(idx);
	}

	public void RemoveTreeIndex(int x, int z, int idx)
	{
		int num = x / chunkSize;
		int num2 = z / chunkSize;
		chunks[num2 * numChunksX + num].RemoveItem(idx);
	}

	public void FellAllTrees(Cell cell)
	{
		if (cell == null || cell.Busy)
		{
			return;
		}
		TreeCellData treeCellData = cellData[cell.index];
		for (int i = 0; i < treeCellData.TreeIds.Length; i++)
		{
			if (treeCellData.TreeIds[i] != -1)
			{
				FellTree(cell, treeCellData.TreeIds[i]);
			}
		}
	}

	public void Reset()
	{
		GenerateOffsets();
		cellData = null;
		if (chunks != null)
		{
			for (int i = 0; i < chunks.Length; i++)
			{
				chunks[i].Destroy();
			}
		}
		for (int j = 0; j < animTreeData.Length; j++)
		{
			ResetAnimData(j);
		}
		growAnimIdx.Clear();
		growSize.Clear();
		growMeshIdx.Clear();
		fallAnimIdx.Clear();
		fallAnimData.Clear();
		shakeAnimIdx.Clear();
		shakeAnimData.Clear();
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		UpdateGrowAnims(deltaTime);
		UpdateFallAnims(deltaTime);
		UpdateShakeAnims(deltaTime);
		if (SeasonManager.inst.CurrentSeason.id == 2 || SeasonManager.inst.CurrentSeason.id == 1)
		{
			flowerScale = Mathff.Clamp01(flowerScale - deltaTime * 0.125f);
		}
		else
		{
			flowerScale = Mathff.Clamp01(flowerScale + deltaTime * 0.05f);
		}
		Shader.SetGlobalFloat("_IgnoreLOD", forceVisibleAll ? 1 : 0);
		Shader.SetGlobalFloat("_FlowerScale", flowerScale);
		Shader.SetGlobalVector("_SnowColor", SeasonManager.inst.snowColor);
		DrawTrees();
	}

	private void DrawTrees()
	{
		if (chunks != null && (visible || forceVisibleAll))
		{
			float lODCutoffDistSqrd = LODCutoffDist * LODCutoffDist;
			for (int i = 0; i < chunks.Length; i++)
			{
				chunks[i].DrawItems(treeMesh, material, castShadows, lODCutoffDistSqrd);
			}
			animMaterial.SetBuffer("matrixBuffer", animMatrixBuffer);
			animMaterial.SetBuffer("meshIdxBuffer", animMeshIdxBuffer);
			animMatrixBuffer.SetData(animMatrices);
			animMeshIdxBuffer.SetData(animMeshIdxs);
			animArgsBuffer.SetData(animArgs);
			if (growAnimIdx.Count > 0)
			{
				Graphics.DrawMeshInstancedIndirect(treeMesh, 0, animMaterial, bounds, animArgsBuffer, 0, null, castShadows ? ShadowCastingMode.On : ShadowCastingMode.Off);
			}
		}
	}

	public void DrawWithCommandBuffer(CommandBuffer buffer, int shaderPass = -1)
	{
		if (Settings.inst.supportsInstancing)
		{
			for (int i = 0; i < chunks.Length; i++)
			{
				chunks[i].DrawItemsWithCommandBuffer(buffer, treeMesh, shaderPass);
			}
			animMatrixBuffer.SetData(animMatrices);
			animMeshIdxBuffer.SetData(animMeshIdxs);
			animArgsBuffer.SetData(animArgs);
			buffer.DrawMeshInstancedIndirect(treeMesh, 0, animMaskMaterial, shaderPass, animArgsBuffer, 0, null);
		}
	}

	private void UpdateShakeAnims(float dt)
	{
		for (int i = 0; i < shakeAnimIdx.Count; i++)
		{
			int num = shakeAnimIdx.data[i];
			shakeAnimData.data[i].time += dt;
			float num2 = shakeAnimData.data[i].time / 0.7f;
			int rand = shakeAnimData.data[i].rand;
			Vector3 startAngles = shakeAnimData.data[i].startAngles;
			startAngles.x += Mathf.Sin((float)rand + num2 * (freq + (float)rand * 0.25f) * (1f - num2) * (float)((rand % 2 == 0) ? 1 : (-1))) * ((magnitude + (float)rand * 0.25f) * (1f - num2) * (1f - num2));
			startAngles.z += Mathf.Cos((float)rand + num2 * (freq + (float)rand * 0.25f) * (1f - num2) * (float)((rand % 2 == 0) ? 1 : (-1))) * ((magnitude + (float)rand * 0.25f) * (1f - num2) * (1f - num2));
			int num3 = shakeAnimData.data[i].cell.x / chunkSize;
			int num4 = shakeAnimData.data[i].cell.z / chunkSize;
			TreeData treeData = chunks[num4 * numChunksX + num3].itemData[num];
			treeData.rotation.eulerAngles = startAngles;
			Chunk obj = chunks[num4 * numChunksX + num3];
			obj.matrices[num] = Matrix4x4.TRS(treeData.pos, treeData.rotation, treeData.scale);
			obj.isDirty = true;
			if (num2 >= 1f)
			{
				shakeAnimIdx.RemoveAt(i);
				shakeAnimData.RemoveAt(i);
				i--;
			}
		}
	}

	public void ShakeItem(Cell cell, int idx)
	{
		TreeData item = GetItem(cell, idx);
		shakeAnimIdx.Add(idx);
		ShakeAnimData item2 = new ShakeAnimData
		{
			time = 0f,
			startAngles = item.rotation.eulerAngles,
			rand = SRand.Range(0, 10),
			cell = cell
		};
		shakeAnimData.Add(item2);
	}

	private void OnDestroy()
	{
		Reset();
		if (animMatrices.IsCreated)
		{
			animMatrices.Dispose();
		}
		if (animMeshIdxs.IsCreated)
		{
			animMeshIdxs.Dispose();
		}
		if (animMaterial != null)
		{
			Object.Destroy(animMaterial);
			animMaterial = null;
		}
		if (animMaskMaterial != null)
		{
			Object.Destroy(animMaskMaterial);
			animMaskMaterial = null;
		}
		if (animMatrixBuffer != null)
		{
			animMatrixBuffer.Dispose();
			animMatrixBuffer = null;
		}
		if (animMeshIdxBuffer != null)
		{
			animMeshIdxBuffer.Dispose();
			animMeshIdxBuffer = null;
		}
		if (animArgsBuffer != null)
		{
			animArgsBuffer.Dispose();
			animArgsBuffer = null;
		}
		systems.Remove(this);
	}

	internal void SetVisible(bool v)
	{
		visible = v;
	}

	public void UpdateCullingCamera(Camera camera)
	{
		if (chunks == null)
		{
			return;
		}
		for (int i = 0; i < chunks.Length; i++)
		{
			if (chunks[i].cullingGroup != null)
			{
				chunks[i].cullingGroup.targetCamera = camera;
			}
		}
	}

	public static void UpdateAllSystemsCullingCamera(Camera camera)
	{
		for (int i = 0; i < systems.Count; i++)
		{
			systems[i].UpdateCullingCamera(camera);
		}
	}

	internal void ReplaceItems(int x, int z, int gridWidth)
	{
		int num = x / chunkSize;
		int num2 = z / chunkSize;
		Chunk chunk = chunks[num2 * numChunksX + num];
		int num3 = z * gridWidth + x;
		if (cellData[num3].TreeAmount <= 0)
		{
			return;
		}
		for (int i = 0; i < cellData[num3].TreeIds.Length; i++)
		{
			int num4 = cellData[num3].TreeIds[i];
			if (num4 != -1)
			{
				TreeData item = GetItem(x, z, num4);
				Vector3 pos = item.pos;
				pos.y = TerrainGen.inst.GetGroundHeight(item.pos.x, item.pos.z) + heightOffset.Rand() * (item.scale.y / yScale.Max - yScale.Min);
				chunk.UpdateItemPosition(num4, pos);
			}
		}
	}
}
