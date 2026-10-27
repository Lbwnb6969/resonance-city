using System;
using System.Collections.Generic;
using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;

public class FishSystem : InstanceSystemBehaviour
{
	public new class Owner
	{
		public int idx;
	}

	public struct Fish
	{
		public int vIdx;

		public float lastPosX;

		public float lastPosY;

		public float lastPosZ;

		public float x;

		public float z;

		public float angle;

		public float swimRadius;

		public float t;

		public float swimSpeed;

		public float life;

		public float dirChangeTime;

		public float3 scale;

		public quaternion lastRot;
	}

	public class FishCell
	{
		public ArrayExt<Owner> owners = new ArrayExt<Owner>(8);

		public int x;

		public int z;

		public float baseProbability;
	}

	public class VisibilityInfo
	{
		public Bounds bounds;

		public ArrayExt<Owner> owners = new ArrayExt<Owner>(1);
	}

	[Serializable]
	public class FishSplotData
	{
		public enum Rate
		{
			Absolute,
			Per1000
		}

		public int radius;

		public float rate;

		public Rate rateType;
	}

	private struct PlacedSplots
	{
		public int radius;

		public Vector3 pos;
	}

	[BurstCompile]
	public struct UpdateFish : IJob
	{
		[ReadOnly]
		public int fishCount;

		[ReadOnly]
		public float dt;

		[ReadOnly]
		public float totalTime;

		[ReadOnly]
		public float fishHeightY;

		[ReadOnly]
		public float sizeIncr;

		[ReadOnly]
		public float camScale;

		[ReadOnly]
		public float lifeDecr;

		[ReadOnly]
		public float3 fishMaxSize;

		[ReadOnly]
		public NativeArray<bool> isVisible;

		[WriteOnly]
		public NativeArray<float4x4> matrix;

		[WriteOnly]
		public NativeArray<int> toRemove;

		public NativeArray<Fish> fishes;

		public Unity.Mathematics.Random rand;

		public void Execute()
		{
			int index = 0;
			toRemove[0] = -1;
			for (int i = 0; i < fishCount; i++)
			{
				Fish value = fishes[i];
				if (isVisible[value.vIdx])
				{
					value.angle += dt * value.swimSpeed * 0.65f;
					float num = Mathf.Sin(totalTime + value.t);
					float num2 = value.swimRadius + num * 0.125f + 0.125f;
					float num3 = num * 0.25f;
					float3 translation = new float3(value.x + Mathf.Cos(value.angle) * num2, fishHeightY + num3, value.z + Mathf.Sin(value.angle) * num2);
					float3 forward = new float3(translation.x - value.lastPosX, translation.y - value.lastPosY, translation.z - value.lastPosZ);
					value.scale.x = Mathff.Clamp(value.scale.x + sizeIncr, 0f, fishMaxSize.x) * camScale;
					value.scale.y = Mathff.Clamp(value.scale.y + sizeIncr, 0f, fishMaxSize.y) * camScale;
					value.scale.z = Mathff.Clamp(value.scale.z + sizeIncr, 0f, fishMaxSize.z) * camScale;
					if (dt > 0f)
					{
						value.lastRot = quaternion.LookRotation(forward, Vector3.up);
					}
					matrix[i] = float4x4.TRS(translation, value.lastRot, value.scale);
					value.lastPosX = translation.x;
					value.lastPosY = translation.y;
					value.lastPosZ = translation.z;
					value.dirChangeTime -= dt;
					if (value.dirChangeTime < 0f)
					{
						value.dirChangeTime = rand.NextFloat(5f, 10f);
						value.swimSpeed *= -1f;
					}
					value.life -= lifeDecr;
					if (value.life < 0f)
					{
						toRemove[index++] = i;
						toRemove[index] = -1;
					}
					fishes[i] = value;
				}
			}
		}
	}

	[Serializable]
	public class FishSystemSaveData : SaveClass<FishSystem, FishSystemSaveData>
	{
		public int[] fishPerCell;

		public float[] probabilities;

		public override FishSystemSaveData Pack(FishSystem w)
		{
			fishPerCell = new int[World.inst.GridWidth * World.inst.GridHeight];
			probabilities = new float[World.inst.GridWidth * World.inst.GridHeight];
			for (int i = 0; i < w.fishCells.Length; i++)
			{
				fishPerCell[i] = w.fishCells[i].owners.Count;
				probabilities[i] = w.fishCells[i].baseProbability;
			}
			return this;
		}

		public override FishSystem Unpack(FishSystem w)
		{
			for (int i = 0; i < fishPerCell.Length; i++)
			{
				int x = i % World.inst.GridWidth;
				int z = i / World.inst.GridWidth;
				for (int j = 0; j < fishPerCell[i]; j++)
				{
					Owner owner = w.AddFish(x, z);
					w.GiveRandomAge(owner);
				}
				w.fishCells[i].baseProbability = probabilities[i];
				if (fishPerCell[i] > 0)
				{
					w.fishCells[i].baseProbability = 1f;
				}
			}
			return w;
		}
	}

	public static FishSystem inst;

	private const int MAX_FISH = 16384;

	public Material material;

	public Mesh mesh;

	private ComputeBuffer computeBuffer;

	private ComputeBuffer computeArgs;

	private uint[] args;

	private Plane[] frustum = new Plane[6];

	private float totalTime;

	public Owner[] owners;

	private int fishCount;

	private NativeArray<float4x4> nativeMatrix;

	private NativeArray<Fish> nativeFish;

	[NonSerialized]
	public FishCell[] fishCells;

	private int visResolution = 15;

	private int visWidth;

	private int visHeight;

	private VisibilityInfo[] visGrid;

	private NativeArray<bool> nativeIsVisible;

	private NativeArray<int> nativeToRemove;

	private Unity.Mathematics.Random rand;

	private bool initialized;

	private ArrayExt<Owner> toRemoveOwners = new ArrayExt<Owner>(64);

	private Bounds rBounds = new Bounds(new Vector3(0f, 0f, 0f), new Vector3(500f, 500f, 500f));

	private int tickX;

	private int tickZ;

	public float updateTime;

	private float cellsPerFrame;

	private ArrayExt<FishCell> scratchCells = new ArrayExt<FishCell>(9);

	public int MaxFishPerTile = 5;

	public float fishHeightY = -0.1f;

	private void Awake()
	{
		inst = this;
	}

	private void OnDestroy()
	{
		if (nativeFish.IsCreated)
		{
			nativeFish.Dispose();
		}
		if (nativeMatrix.IsCreated)
		{
			nativeMatrix.Dispose();
		}
		if (nativeToRemove.IsCreated)
		{
			nativeToRemove.Dispose();
		}
		if (nativeIsVisible.IsCreated)
		{
			nativeIsVisible.Dispose();
		}
		if (computeBuffer != null)
		{
			computeBuffer.Dispose();
		}
		if (computeArgs != null)
		{
			computeArgs.Dispose();
		}
	}

	public void Init()
	{
		Reset();
		initialized = true;
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		fishCells = new FishCell[gridWidth * gridHeight];
		for (int i = 0; i < gridHeight; i++)
		{
			for (int j = 0; j < gridWidth; j++)
			{
				int num = i * gridWidth + j;
				fishCells[num] = new FishCell
				{
					x = j,
					z = i,
					baseProbability = 0f
				};
			}
		}
		rand.InitState((uint)World.inst.seed);
		if (owners == null)
		{
			owners = new Owner[16384];
		}
		if (!nativeFish.IsCreated)
		{
			nativeFish = new NativeArray<Fish>(16384, Allocator.Persistent);
		}
		if (!nativeMatrix.IsCreated)
		{
			nativeMatrix = new NativeArray<float4x4>(16384, Allocator.Persistent);
		}
		if (!nativeToRemove.IsCreated)
		{
			nativeToRemove = new NativeArray<int>(100, Allocator.Persistent);
		}
		if (computeBuffer == null)
		{
			computeBuffer = new ComputeBuffer(16384, 64);
			ComputeBufferNaming.SetName(computeBuffer, "FishSystem_MatrixBuffer");
			computeBuffer.SetData(nativeMatrix);
			material.SetBuffer("matrixBuffer", computeBuffer);
		}
		if (args == null)
		{
			args = new uint[5];
			args[0] = ((mesh != null) ? mesh.GetIndexCount(0) : 0u);
			args[1] = 16384u;
			args[2] = ((mesh != null) ? mesh.GetIndexStart(0) : 0u);
			args[3] = ((mesh != null) ? mesh.GetBaseVertex(0) : 0u);
			args[4] = 0u;
		}
		if (computeArgs == null)
		{
			computeArgs = new ComputeBuffer(1, args.Length * 4, ComputeBufferType.DrawIndirect);
			ComputeBufferNaming.SetName(computeArgs, "FishSystem_ArgsBuffer");
			computeArgs.SetData(args);
		}
		visWidth = gridWidth / visResolution + 1;
		visHeight = gridHeight / visResolution + 1;
		visGrid = new VisibilityInfo[visWidth * visHeight];
		if (!nativeIsVisible.IsCreated)
		{
			nativeIsVisible = new NativeArray<bool>(visWidth * visHeight, Allocator.Persistent);
		}
		for (int k = 0; k < visHeight; k++)
		{
			for (int l = 0; l < visWidth; l++)
			{
				VisibilityInfo visibilityInfo = new VisibilityInfo();
				visGrid[k * visWidth + l] = visibilityInfo;
				Vector3 center = new Vector3((float)(l * visResolution) + (float)visResolution / 2f, 0f, (float)(k * visResolution) + (float)visResolution / 2f);
				Vector3 size = new Vector3(visResolution, 10f, visResolution);
				visibilityInfo.bounds = new Bounds(center, size);
			}
		}
	}

	public void Reset()
	{
		fishCells = null;
		fishCount = 0;
		if (nativeIsVisible.IsCreated)
		{
			nativeIsVisible.Dispose();
		}
	}

	public Owner AddFish(int x, int z)
	{
		if (fishCount >= 16384)
		{
			return null;
		}
		int num = fishCount;
		Owner owner = new Owner();
		owner.idx = num;
		owners[num] = owner;
		Fish value = new Fish
		{
			lastPosX = x,
			lastPosY = 0f,
			lastPosZ = z,
			x = (float)x + 0.5f,
			z = (float)z + 0.5f,
			swimSpeed = SRand.Range(1f, 2f)
		};
		if (SRand.Range(0f, 1f) > 0.5f)
		{
			value.swimRadius *= -1f;
		}
		value.dirChangeTime = SRand.Range(1f, 5f);
		value.t = SRand.Range(0f, 100f);
		value.swimRadius = SRand.Range(0.1f, 0.4f);
		value.life = SRand.Range(0.75f, 1f) * SeasonManager.inst.TimeInYear() * 3f;
		value.scale = new Vector3(0.3f, 0.3f, 0.55f) * 0.33f;
		value.vIdx = z / visResolution * visWidth + x / visResolution;
		fishCells[z * World.inst.GridWidth + x].owners.Add(owner);
		visGrid[value.vIdx].owners.Add(owner);
		nativeFish[num] = value;
		TerrainGen.inst.dirtyTerritoryCells.Add(World.inst.GetCellDataUnsafe(x, z));
		fishCount++;
		return owner;
	}

	private void RemoveFish(Owner owner)
	{
		Fish fish = nativeFish[owner.idx];
		visGrid[fish.vIdx].owners.RemoveSwap(owner);
		owners[fishCount - 1].idx = owner.idx;
		owners[owner.idx] = owners[fishCount - 1];
		nativeFish[owner.idx] = nativeFish[fishCount - 1];
		nativeMatrix[owner.idx] = nativeMatrix[fishCount - 1];
		TerrainGen.inst.dirtyTerritoryCells.Add(World.inst.GetCellData((int)fish.x, (int)fish.z));
		owners[fishCount - 1] = null;
		fishCount--;
	}

	public void ForceFish(int x, int z)
	{
		ForceClearFish(x, z);
		fishCells[z * World.inst.GridWidth + x].baseProbability = 1f;
		for (int i = 0; i < MaxFishPerTile; i++)
		{
			AddFish(x, z);
		}
	}

	public void ForceClearFish(int x, int z)
	{
		int num = z * World.inst.GridWidth + x;
		FishCell fishCell = fishCells[num];
		for (int i = 0; i < fishCell.owners.Count; i++)
		{
			Owner owner = fishCell.owners.data[i];
			RemoveFish(owner);
			fishCell.owners.RemoveSwap(owner);
		}
		fishCell.baseProbability = 0f;
		fishCells[num] = fishCell;
	}

	private float ProbabilityForCell(int x, int z, Cell[] cellData, int gridWidth)
	{
		int num = 6;
		int num2 = Mathff.Clamp(x - num, 0, World.inst.GridWidth - 1);
		int num3 = Mathff.Clamp(x + num, 0, World.inst.GridWidth - 1);
		int num4 = Mathff.Clamp(z - num, 0, World.inst.GridHeight - 1);
		int num5 = Mathff.Clamp(z + num, 0, World.inst.GridHeight - 1);
		scratchCells.Clear();
		int num6 = 0;
		int num7 = 0;
		for (int i = num4; i <= num5; i++)
		{
			int num8 = i * gridWidth;
			for (int j = num2; j <= num3; j++)
			{
				Cell cell = cellData[num8 + j];
				if (cell.Type != TerrainType.Water && cell.BottomSubStructure == null)
				{
					num6 += cell.GetFertility();
					num7++;
				}
			}
		}
		float num9 = 0f;
		if (num7 > 0)
		{
			num9 = 1f - Mathff.Clamp01((float)num6 / (float)num7);
			if (num9 > 0.1f)
			{
				num9 = 1f;
			}
		}
		return num9;
	}

	public void AddInitialFish()
	{
		World.inst.placedFish = true;
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		for (int i = 0; i < gridHeight; i++)
		{
			for (int j = 0; j < gridWidth; j++)
			{
				int num = i * gridWidth + j;
				int num2 = (int)((float)MaxFishPerTile * fishCells[num].baseProbability);
				for (int k = 0; k < num2; k++)
				{
					Owner owner = AddFish(j, i);
					if (owner != null)
					{
						GiveRandomAge(owner);
					}
				}
			}
		}
	}

	private bool ToCloseToPlacedSplots(Vector3 pos, float rad, List<PlacedSplots> splotData)
	{
		for (int i = 0; i < splotData.Count; i++)
		{
			if (Mathff.DistSqrdXZ(pos, splotData[i].pos) < (rad + (float)splotData[i].radius) * (rad + (float)splotData[i].radius))
			{
				return true;
			}
		}
		return false;
	}

	public void PlaceSplots(int lm, List<FishSplotData> splotData, ArrayExt<Cell> coastalCells)
	{
		if (coastalCells.Count == 0)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[lm];
		List<PlacedSplots> list = new List<PlacedSplots>();
		for (int i = 0; i < splotData.Count; i++)
		{
			int num = 0;
			if (splotData[i].rateType == FishSplotData.Rate.Absolute)
			{
				num = (int)splotData[i].rate;
			}
			else
			{
				float num2 = splotData[i].rate / 1000f;
				num = Mathf.CeilToInt((float)arrayExt.Count * num2);
			}
			float num3 = 1.5f;
			int radius = splotData[i].radius;
			float num4 = (float)radius * 0.7f;
			float num5 = (float)radius * num3 * ((float)radius * num3);
			Vector3 vector = new Vector3(gridWidth / 2, 0f, gridHeight / 2);
			for (int j = 0; j < num; j++)
			{
				int num6 = 10;
				Cell cell = coastalCells.RandomElement();
				cell = World.inst.GetCellDataClamped(cell.Center2D + (cell.Center2D - vector).normalized * SRand.Range(2, 4));
				Vector3 center2D = cell.Center2D;
				while (num6 > 0)
				{
					bool flag = ToCloseToPlacedSplots(center2D, radius, list);
					bool invalid = false;
					World.inst.ForEachTileInRadiusOrDone(cell.x, cell.z, 4, (int x, int z, Cell testCell) =>
					{
						if (testCell.Type == TerrainType.Obstruction)
						{
							invalid = true;
							return true;
						}
						return false;
					});
					if (!flag && ValidForFish(cell.x, cell.z) && !invalid)
					{
						break;
					}
					cell = coastalCells.RandomElement();
					cell = World.inst.GetCellDataClamped(cell.Center2D + (cell.Center2D - vector).normalized * SRand.Range(2, 4));
					center2D = cell.Center2D;
					num6--;
				}
				DebugEx.DrawCircleXZ(center2D, radius, Color.red, 8f, 5f);
				int num7 = (int)Mathff.Clamp(center2D.x - (float)radius * num3, 0f, gridWidth - 1);
				int num8 = (int)Mathff.Clamp(center2D.x + (float)radius * num3, 0f, gridWidth - 1);
				int num9 = (int)Mathff.Clamp(center2D.z - (float)radius * num3, 0f, gridHeight - 1);
				int num10 = (int)Mathff.Clamp(center2D.z + (float)radius * num3, 0f, gridHeight - 1);
				for (int num11 = num7; num11 <= num8; num11++)
				{
					for (int num12 = num9; num12 <= num10; num12++)
					{
						if (World.inst.GetCellDataUnsafe(num11, num12).Type != TerrainType.Water)
						{
							continue;
						}
						float num13 = (center2D.x - (float)num11) * (center2D.x - (float)num11) + (center2D.z - (float)num12) * (center2D.z - (float)num12);
						if (num13 <= num5)
						{
							float num14 = Mathf.Sqrt(num13);
							float value = 1f - (num14 - num4) / ((float)radius * num3 - num4);
							value = Mathf.Clamp01(value);
							if (SRand.value <= value)
							{
								fishCells[num12 * gridWidth + num11].baseProbability = 1f;
							}
						}
					}
				}
				list.Add(new PlacedSplots
				{
					pos = center2D,
					radius = radius
				});
			}
		}
	}

	private void GiveRandomAge(Owner owner)
	{
		Fish value = nativeFish[owner.idx];
		float num = SRand.Range(0f, 1f);
		value.life = num * SeasonManager.inst.TimeInYear() * 3f;
		value.scale = Vector3.Lerp(new Vector3(0.3f, 0.3f, 0.55f) * 0.33f, new Vector3(0.3f, 0.3f, 0.55f), num);
		nativeFish[owner.idx] = value;
	}

	private void Update()
	{
		if (LoadSave.Loading || !initialized)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		totalTime += deltaTime;
		float num = deltaTime;
		if (GameState.inst.CurrMode != GameState.inst.playingMode)
		{
			num = 0f;
		}
		int gridWidth = World.inst.GridWidth;
		_ = World.inst.GridHeight;
		Vector3 vector = new Vector3(0.3f, 0.3f, 0.55f) * 1f;
		float camScale = 1f + Mathf.Clamp((Cam.inst.dist - 15f) / 50f, 0f, 2.5f);
		float sizeIncr = num / (SeasonManager.inst.TimeInYear() * 3f);
		GeometryUtility.CalculateFrustumPlanes(Cam.inst.cam, frustum);
		if (visGrid != null)
		{
			for (int i = 0; i < visGrid.Length; i++)
			{
				nativeIsVisible[i] = GeometryUtility.TestPlanesAABB(frustum, visGrid[i].bounds);
			}
		}
		new UpdateFish
		{
			fishCount = fishCount,
			dt = deltaTime,
			totalTime = totalTime,
			fishHeightY = fishHeightY,
			sizeIncr = sizeIncr,
			camScale = camScale,
			lifeDecr = num,
			fishMaxSize = vector,
			isVisible = nativeIsVisible,
			matrix = nativeMatrix,
			fishes = nativeFish,
			rand = rand,
			toRemove = nativeToRemove
		}.Schedule().Complete();
		int j = 0;
		toRemoveOwners.ClearFast();
		for (; nativeToRemove[j] != -1; j++)
		{
			toRemoveOwners.Add(owners[nativeToRemove[j]]);
		}
		for (int k = 0; k < toRemoveOwners.Count; k++)
		{
			int idx = toRemoveOwners.data[k].idx;
			Fish fish = nativeFish[idx];
			Owner owner = owners[idx];
			int num2 = (int)fish.x;
			int num3 = (int)fish.z * gridWidth + num2;
			RemoveFish(owner);
			fishCells[num3].owners.RemoveSwap(owner);
		}
		UpdatePropagation();
	}

	private Vector3 Plane3Intersect(Plane p1, Plane p2, Plane p3)
	{
		return ((0f - p1.distance) * Vector3.Cross(p2.normal, p3.normal) + (0f - p2.distance) * Vector3.Cross(p3.normal, p1.normal) + (0f - p3.distance) * Vector3.Cross(p1.normal, p2.normal)) / Vector3.Dot(p1.normal, Vector3.Cross(p2.normal, p3.normal));
	}

	private void LateUpdate()
	{
		if (args != null)
		{
			args[1] = (uint)fishCount;
			material.SetBuffer("matrixBuffer", computeBuffer);
			if (fishCount > 0)
			{
				computeBuffer.SetData(nativeMatrix, 0, 0, fishCount);
			}
			computeArgs.SetData(args);
			Graphics.DrawMeshInstancedIndirect(mesh, 0, material, rBounds, computeArgs, 0, null, ShadowCastingMode.Off);
		}
	}

	public bool TryRemoveFish(FishCell cell)
	{
		if (cell.owners.Count <= 0)
		{
			return false;
		}
		Owner owner = cell.owners.Last();
		RemoveFish(owner);
		cell.owners.RemoveAtSwap(cell.owners.Count - 1);
		return true;
	}

	private void UpdatePropagation()
	{
		if (GameState.inst.CurrMode != GameState.inst.playingMode)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		float num = (float)fishCells.Length / updateTime;
		cellsPerFrame += num * deltaTime;
		tickX = Mathf.Clamp(tickX, 0, World.inst.GridWidth - 1);
		tickZ = Mathf.Clamp(tickZ, 0, World.inst.GridHeight - 1);
		while (cellsPerFrame > 0f)
		{
			TickPropagationForCell(tickX, tickZ);
			cellsPerFrame--;
			tickZ++;
			if (tickZ >= World.inst.GridHeight)
			{
				tickX++;
				tickZ = 0;
			}
			if (tickX >= World.inst.GridWidth)
			{
				tickX = 0;
				tickZ = 0;
			}
		}
	}

	public static bool ValidForFish(int x, int z)
	{
		Cell cellData = World.inst.GetCellData(x, z);
		if (cellData.Type == TerrainType.Water && cellData.SubStructure.Count == 0 && cellData.OccupyingStructure.Count == 0)
		{
			return true;
		}
		return false;
	}

	private void TickPropagationForCell(int x, int z)
	{
		if (!ValidForFish(x, z))
		{
			return;
		}
		FishCell fishCell = fishCells[z * World.inst.GridWidth + x];
		float num = (float)fishCell.owners.Count / (float)MaxFishPerTile * 0.7f;
		if (!(SRand.value < Mathff.Max(num, fishCell.baseProbability * 0.25f)))
		{
			return;
		}
		if ((!(SRand.value < num) && fishCell.owners.Count < MaxFishPerTile) || !(fishCell.baseProbability > 0f))
		{
			AddFish(x, z);
			return;
		}
		int num2 = Mathff.Clamp(x - 1, 0, World.inst.GridWidth - 1);
		int num3 = Mathff.Clamp(x + 1, 0, World.inst.GridWidth - 1);
		int num4 = Mathff.Clamp(z - 1, 0, World.inst.GridHeight - 1);
		int num5 = Mathff.Clamp(z + 1, 0, World.inst.GridHeight - 1);
		scratchCells.Clear();
		for (int i = num4; i <= num5; i++)
		{
			for (int j = num2; j <= num3; j++)
			{
				FishCell fishCell2 = fishCells[i * World.inst.GridWidth + j];
				if (fishCell2.owners.Count < MaxFishPerTile && ValidForFish(x, z) && !(fishCell2.baseProbability <= 0f))
				{
					scratchCells.Add(fishCell2);
				}
			}
		}
		if (scratchCells.Count <= 0)
		{
			return;
		}
		int num6 = 999;
		FishCell fishCell3 = null;
		for (int k = 0; k < scratchCells.Count; k++)
		{
			if (scratchCells.data[k].owners.Count < num6)
			{
				num6 = scratchCells.data[k].owners.Count;
				fishCell3 = scratchCells.data[k];
			}
		}
		if (SRand.value < 0.1f)
		{
			AddFish(fishCell3.x, fishCell3.z);
		}
	}
}
