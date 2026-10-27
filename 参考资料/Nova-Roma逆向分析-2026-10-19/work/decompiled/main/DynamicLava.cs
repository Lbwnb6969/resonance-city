using System;
using System.Collections.Generic;
using Code;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;

public class DynamicLava : MonoBehaviour
{
	[Serializable]
	public struct WaterCell
	{
		public int index;

		public float waterProductionRate;

		public float waterAmount;

		public float flux0;

		public float flux1;

		public float flux2;

		public float flux3;
	}

	public class NewWaterHeightMapEvent
	{
		public Texture2D Texture1 { get; }

		public Texture2D Texture2 { get; }

		public NewWaterHeightMapEvent(Texture2D texture1, Texture2D texture2)
		{
			Texture1 = texture1;
			Texture2 = texture2;
		}
	}

	public delegate void NewWaterHeightMapEventHandler(object sender, NewWaterHeightMapEvent e);

	private struct JobBatchTestData
	{
		public int amount;

		public int[] ticks;

		public int average;
	}

	public class WaterExtractionRequest
	{
		public int x;

		public int z;

		public float altitude;

		public RequestFulfillment callback;
	}

	public delegate float RequestFulfillment(float amountAvailable);

	[BurstCompile]
	public struct UpdateFluxParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<int> NeighborIndices4;

		[ReadOnly]
		public NativeArray<float> HeightMap;

		[ReadOnly]
		public NativeArray<float> ObstructionMap;

		[ReadOnly]
		public NativeArray<WaterCell> Input;

		public NativeArray<WaterCell> Output;

		public float DeltaTime;

		public float SourceAmount;

		public float A;

		public float Gravity;

		public float L;

		public float TerrainExaggeration;

		public float Viscosity;

		public float FluxClampThreshold;

		public int Width;

		public int Height;

		public void Execute(int ind)
		{
			int num = ind % Width;
			int num2 = ind / Width;
			if (num == 0 || num == Width - 1 || num2 == 0 || num2 == Height - 1)
			{
				return;
			}
			float num3 = HeightMap[ind] + ObstructionMap[ind];
			WaterCell waterCell = Input[ind];
			WaterCell value = waterCell;
			float num4 = waterCell.waterAmount + waterCell.waterProductionRate * DeltaTime;
			for (int i = 0; i < 4; i++)
			{
				int index = ind + NeighborIndices4[i];
				WaterCell waterCell2 = Input[index];
				float num5 = HeightMap[index] + ObstructionMap[index];
				float num6 = waterCell2.waterAmount + waterCell2.waterProductionRate * DeltaTime;
				float num7 = num3 + num4 - num5 - num6;
				num7 *= TerrainExaggeration;
				float num8 = 0f;
				switch (i)
				{
				case 0:
					num8 = waterCell.flux0;
					break;
				case 1:
					num8 = waterCell.flux1;
					break;
				case 2:
					num8 = waterCell.flux2;
					break;
				case 3:
					num8 = waterCell.flux3;
					break;
				}
				float num9 = Mathf.Max(0f, num8 + DeltaTime * A * (Gravity * num7 / L) / (1f + Viscosity));
				if (num9 < FluxClampThreshold)
				{
					num9 = 0f;
				}
				switch (i)
				{
				case 0:
					value.flux0 = num9;
					break;
				case 1:
					value.flux1 = num9;
					break;
				case 2:
					value.flux2 = num9;
					break;
				case 3:
					value.flux3 = num9;
					break;
				}
				float num10 = Math.Min(1f, num4 * L * L / ((value.flux0 + value.flux1 + value.flux2 + value.flux3) * DeltaTime));
				if (float.IsNaN(num10) || float.IsNegativeInfinity(num10))
				{
					num10 = 0f;
				}
				value.flux0 *= num10;
				value.flux1 *= num10;
				value.flux2 *= num10;
				value.flux3 *= num10;
				value.waterAmount = num4;
			}
			Output[ind] = value;
		}
	}

	[BurstCompile]
	public struct UpdateWaterHeightParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<int> NeighborIndices4;

		[ReadOnly]
		public NativeArray<WaterCell> Input;

		[ReadOnly]
		public NativeArray<float> HeightMap;

		[ReadOnly]
		public float OceanHeight;

		public NativeArray<WaterCell> Output;

		public NativeArray<float> DifferenceHeightMap;

		public NativeArray<Color> BurntTexture;

		public float DeltaTime;

		public float L;

		public float Evaporation;

		public int Width;

		public int Height;

		public void Execute(int ind)
		{
			int num = ind % Width;
			int num2 = ind / Width;
			if (num == 0 || num == Width - 1 || num2 == 0 || num2 == Height - 1)
			{
				return;
			}
			WaterCell value = Input[ind];
			float num3 = 0f;
			for (int i = 0; i < 4; i++)
			{
				int index = ind + NeighborIndices4[i];
				WaterCell waterCell = Input[index];
				switch (i)
				{
				case 0:
					num3 += waterCell.flux1;
					break;
				case 1:
					num3 += waterCell.flux0;
					break;
				case 2:
					num3 += waterCell.flux3;
					break;
				case 3:
					num3 += waterCell.flux2;
					break;
				}
			}
			float num4 = value.flux0 + value.flux1 + value.flux2 + value.flux3;
			float num5 = DeltaTime * (num3 - num4);
			float num6 = value.waterAmount + num5 / L * L;
			float num7 = Mathf.Min(num6, Evaporation * DeltaTime);
			float b = num6 - num7;
			value.waterAmount = Mathf.Max(0f, b);
			if (value.waterAmount + HeightMap[ind] < OceanHeight - 1f)
			{
				value.waterAmount = 0f;
			}
			Color value2 = BurntTexture[ind];
			value2.r = ((value.waterAmount > 0f) ? 30f : (value2.r - DeltaTime));
			BurntTexture[ind] = value2;
			DifferenceHeightMap[ind] = num7;
			Output[ind] = value;
		}
	}

	[BurstCompile]
	public struct UpdateTextureParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<WaterCell> Input;

		[ReadOnly]
		public NativeArray<float> HeightMap;

		[ReadOnly]
		public NativeArray<float> ObstructionMap;

		public NativeArray<Color> Texture;

		public float WaterMeshTuck;

		public float WaterMeshExtraHeight;

		public void Execute(int ind)
		{
			float num = HeightMap[ind];
			if (Input[ind].waterAmount > 0f)
			{
				num += Input[ind].waterAmount + WaterMeshExtraHeight;
				if (Input[ind].waterAmount > ObstructionMap[ind])
				{
					num += ObstructionMap[ind];
				}
			}
			else
			{
				num += WaterMeshTuck;
			}
			Texture[ind] = new Color(num, 0f, 0f);
		}
	}

	[BurstCompile]
	public struct BuildSimplifiedGridParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<WaterCell> Input;

		public NativeArray<float> SimplifiedGrid;

		public int Width;

		public int MapIndexWorldToMesh(int worldIndex, int worldWidth)
		{
			int num = worldIndex % worldWidth;
			int num2 = worldIndex / worldWidth;
			int num3 = num * 2 + 1;
			return (num2 * 2 + 1) * (worldWidth * 2 + 1) + num3;
		}

		public void Execute(int ind)
		{
			float num = 0f;
			int num2 = MapIndexWorldToMesh(ind, Width);
			for (int i = -1; i <= 1; i++)
			{
				for (int j = -1; j <= 1; j++)
				{
					num += Input[num2 + (i + j * Width)].waterAmount;
				}
			}
			num /= 9f;
			SimplifiedGrid[ind] = num;
		}
	}

	[BurstCompile]
	public struct InitWaterParallelJob : IJobParallelFor
	{
		[NativeDisableContainerSafetyRestriction]
		public NativeArray<Unity.Mathematics.Random> randomNumberGenerators;

		[NativeSetThreadIndex]
		private int threadId;

		public NativeArray<WaterCell> Input1;

		public NativeArray<Color> WaterHeightMap1;

		public NativeArray<Color> WaterHeightMap2;

		public void Execute(int ind)
		{
			_ = randomNumberGenerators[threadId];
			Input1[ind] = new WaterCell
			{
				index = ind
			};
			Color value = default;
			WaterHeightMap1[ind] = value;
			WaterHeightMap2[ind] = value;
		}
	}

	[Serializable]
	public class DynamicLavaSaveData : SaveClass<DynamicLava, DynamicLavaSaveData>
	{
		private WaterCell[] waterGrid;

		public override DynamicLavaSaveData Pack(DynamicLava w)
		{
			if (w.scheduled)
			{
				w.primaryJobHandle.Complete();
			}
			waterGrid = w.waterGrid.ToArray();
			return this;
		}

		public override DynamicLava Unpack(DynamicLava w)
		{
			if (w.scheduled)
			{
				w.primaryJobHandle.Complete();
			}
			w.waterGrid.CopyFrom(waterGrid);
			w.PrimeTextures();
			return w;
		}
	}

	public float[] simplifiedWaterGrid;

	public NativeArray<float> simplifiedWaterGridNative;

	public float[][] waterReadOnly = new float[2][];

	public NativeArray<WaterCell> waterGrid;

	public NativeArray<WaterCell> waterGridResult;

	public float[] DifferenceHeightMapLocal;

	public NativeArray<float> DifferenceHeightMapNativeArray;

	public NativeArray<float> localHeightMapCache;

	public NativeArray<float> localObstructionMapCache;

	public static DynamicLava inst;

	public GameObject gyserPrefab;

	public float sourceAmount = 10f;

	private NativeArray<Unity.Mathematics.Random> randomNumberGenerators;

	public int width;

	public int height;

	public Texture2D waterHeightMap1;

	public Texture2D waterHeightMap2;

	public Texture2D currentWaterHeightMap;

	public Texture2D burntMap;

	[HideInInspector]
	public Color[] heightMapPixels;

	private NativeArray<int> neighborIndices4;

	private int[] neighborWorldIndices8;

	private bool scheduled;

	private Timer simulationUpdate = new Timer(0.1f);

	public int jobInnerloopBatches = 64;

	public float A = 1f;

	public float Gravity = 9.81f;

	public float L = 1f;

	public float TerrainExaggeration = 1f;

	public float Evaporation = 0.1f;

	public float FluxThreshold = 1E-05f;

	public float TimeStep = 0.25f;

	public float Viscosity = 1f;

	public float FluxClampThreshold;

	public float WaterMeshExtraHeight = 0.1f;

	public float WaterMeshTuck = -0.1f;

	public float GeneratePrimeAmount = 0.2f;

	private List<WaterExtractionRequest> waterExtractionRequests = new List<WaterExtractionRequest>();

	public Material WaterSourceMaterial;

	public Material WaterSourceMaterialBlue;

	public Material WaterSourceMaterialGreen;

	public Mesh CubeMesh;

	private Timer clickedOnceTimer = new Timer(0.25f);

	public JobHandle primaryJobHandle;

	private JobHandle updateTextureHandle;

	private List<List<int>> paths = new List<List<int>>();

	private WaterCell[] tempWaterGrid;

	private int[] neighbors = new int[4];

	public bool isUpdateFrame { get; set; }

	public event NewWaterHeightMapEventHandler NewWaterHeightMap;

	private void Awake()
	{
		inst = this;
		randomNumberGenerators = new NativeArray<Unity.Mathematics.Random>(128, Allocator.Persistent);
		for (int i = 0; i < randomNumberGenerators.Length; i++)
		{
			randomNumberGenerators[i] = new Unity.Mathematics.Random((uint)SRand.Range(1, int.MaxValue));
		}
	}

	public void Reset()
	{
		if (inst != null)
		{
			inst = this;
		}
		clickedOnceTimer.Enabled = false;
		width = World.inst.GridWidth * 2 + 1;
		height = World.inst.GridHeight * 2 + 1;
		neighborWorldIndices8 = new int[8]
		{
			-World.inst.GridWidth,
			World.inst.GridWidth,
			-1,
			1,
			-World.inst.GridWidth - 1,
			-World.inst.GridWidth + 1,
			World.inst.GridWidth - 1,
			World.inst.GridWidth + 1
		};
		if (scheduled)
		{
			primaryJobHandle.Complete();
		}
		if (isUpdateFrame)
		{
			updateTextureHandle.Complete();
		}
		if (waterGrid.IsCreated)
		{
			waterGrid.Dispose();
		}
		if (waterGridResult.IsCreated)
		{
			waterGridResult.Dispose();
		}
		if (localHeightMapCache.IsCreated)
		{
			localHeightMapCache.Dispose();
		}
		if (localObstructionMapCache.IsCreated)
		{
			localObstructionMapCache.Dispose();
		}
		if (neighborIndices4.IsCreated)
		{
			neighborIndices4.Dispose();
		}
		if (simplifiedWaterGridNative.IsCreated)
		{
			simplifiedWaterGridNative.Dispose();
		}
		if (DifferenceHeightMapNativeArray.IsCreated)
		{
			DifferenceHeightMapNativeArray.Dispose();
		}
		waterGrid = new NativeArray<WaterCell>(width * height, Allocator.Persistent);
		waterGridResult = new NativeArray<WaterCell>(width * height, Allocator.Persistent);
		localHeightMapCache = new NativeArray<float>(width * height, Allocator.Persistent);
		localObstructionMapCache = new NativeArray<float>(width * height, Allocator.Persistent);
		DifferenceHeightMapNativeArray = new NativeArray<float>(width * height, Allocator.Persistent);
		DifferenceHeightMapLocal = new float[width * height];
		simplifiedWaterGrid = new float[World.inst.GridWidth * World.inst.GridHeight];
		simplifiedWaterGridNative = new NativeArray<float>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		waterReadOnly[0] = new float[width * height];
		waterReadOnly[1] = new float[width * height];
		neighborIndices4 = new NativeArray<int>(4, Allocator.Persistent);
		neighborIndices4[0] = -width;
		neighborIndices4[1] = width;
		neighborIndices4[2] = -1;
		neighborIndices4[3] = 1;
		if (waterHeightMap1 == null)
		{
			waterHeightMap1 = new Texture2D(width, height, TextureFormat.RGBAFloat, mipChain: false);
		}
		else
		{
			waterHeightMap1.Reinitialize(width, height, TextureFormat.RGBAFloat, hasMipMap: false);
		}
		waterHeightMap1.name = "LavaHeightMap1";
		waterHeightMap1.filterMode = FilterMode.Bilinear;
		waterHeightMap1.wrapMode = TextureWrapMode.Clamp;
		if (waterHeightMap2 == null)
		{
			waterHeightMap2 = new Texture2D(width, height, TextureFormat.RGBAFloat, mipChain: false);
		}
		else
		{
			waterHeightMap2.Reinitialize(width, height, TextureFormat.RGBAFloat, hasMipMap: false);
		}
		waterHeightMap2.name = "LavaHeightMap2";
		waterHeightMap2.filterMode = FilterMode.Bilinear;
		waterHeightMap2.wrapMode = TextureWrapMode.Clamp;
		if (burntMap == null)
		{
			burntMap = new Texture2D(width, height, TextureFormat.RGBAFloat, mipChain: false);
		}
		else
		{
			burntMap.Reinitialize(width, height, TextureFormat.RGBAFloat, hasMipMap: false);
		}
		burntMap.name = "LavaBurntMap";
		burntMap.filterMode = FilterMode.Bilinear;
		burntMap.wrapMode = TextureWrapMode.Clamp;
		heightMapPixels = new Color[width * height];
		IJobParallelForExtensions.Schedule(new InitWaterParallelJob
		{
			Input1 = waterGrid,
			WaterHeightMap1 = waterHeightMap1.GetRawTextureData<Color>(),
			WaterHeightMap2 = waterHeightMap2.GetRawTextureData<Color>(),
			randomNumberGenerators = randomNumberGenerators
		}, waterGrid.Length, 64).Complete();
		currentWaterHeightMap = waterHeightMap1;
		NewWaterHeightMap?.Invoke(this, new NewWaterHeightMapEvent(waterHeightMap1, waterHeightMap2));
		TerrainGen.inst.TerrainMaterial.SetTexture("_BurntLandMap", burntMap);
		WaterSourceMaterialBlue = UnityEngine.Object.Instantiate(WaterSourceMaterial);
		WaterSourceMaterialBlue.SetColor("_Color", Color.blue);
		WaterSourceMaterialGreen = UnityEngine.Object.Instantiate(WaterSourceMaterial);
		WaterSourceMaterialGreen.SetColor("_Color", Color.green);
		Shader.SetGlobalFloat("_DynamicLavaBlend", 0f);
	}

	public void OnDestroy()
	{
		if (scheduled)
		{
			primaryJobHandle.Complete();
		}
		waterGrid.Dispose();
		waterGridResult.Dispose();
		localHeightMapCache.Dispose();
		localObstructionMapCache.Dispose();
		neighborIndices4.Dispose();
		simplifiedWaterGridNative.Dispose();
		DifferenceHeightMapNativeArray.Dispose();
		randomNumberGenerators.Dispose();
	}

	public void CreateWaterSource(int index, float productionRate)
	{
		PlaceIndividualWaterSource(index, productionRate);
	}

	public void PlaceIndividualWaterSource(int index, float productionRate)
	{
		WaterCell value = waterGrid[index];
		value.waterProductionRate = productionRate;
		waterGrid[index] = value;
	}

	public void RemoveWaterSource(int index)
	{
		if (waterGrid.IsCreated)
		{
			RemoveIndividualWaterSource(index);
		}
	}

	public void RemoveIndividualWaterSource(int index)
	{
		WaterCell value = waterGrid[index];
		value.waterProductionRate = 0f;
		value.waterAmount = 0f;
		waterGrid[index] = value;
	}

	private void Update()
	{
		if (LoadSave.Loading || currentWaterHeightMap == null)
		{
			return;
		}
		if (simulationUpdate.Update(Time.deltaTime) || Input.GetKey(KeyCode.Home))
		{
			isUpdateFrame = true;
			if (scheduled)
			{
				primaryJobHandle.Complete();
				burntMap.Apply();
				for (int i = 0; i < waterExtractionRequests.Count; i++)
				{
					WaterExtractionRequest waterExtractionRequest = waterExtractionRequests[i];
					int index = waterExtractionRequest.z * width + waterExtractionRequest.x;
					WaterCell value = waterGrid[index];
					value.waterAmount -= waterExtractionRequests[i].callback(Mathf.Clamp(value.waterAmount + localHeightMapCache[index] - waterExtractionRequest.altitude, 0f, value.waterAmount));
					waterGrid[index] = value;
				}
				DifferenceHeightMapNativeArray.CopyTo(DifferenceHeightMapLocal);
				for (int j = 0; j < DifferenceHeightMapLocal.Length; j++)
				{
					if (DifferenceHeightMapLocal[j] != 0f)
					{
						int x = j % width;
						int z = j / width;
						TerrainGen.inst.SoftDepressMesh(x, z, DifferenceHeightMapLocal[j]);
					}
				}
				localObstructionMapCache.CopyFrom(TerrainGen.inst.waterObstructionField);
				localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
				UpdateTextureParallelJob jobData = new UpdateTextureParallelJob
				{
					Input = waterGrid,
					Texture = currentWaterHeightMap.GetRawTextureData<Color>(),
					HeightMap = localHeightMapCache,
					ObstructionMap = localObstructionMapCache,
					WaterMeshTuck = WaterMeshTuck,
					WaterMeshExtraHeight = WaterMeshExtraHeight
				};
				updateTextureHandle = IJobParallelForExtensions.Schedule(jobData, waterGrid.Length, 64);
				BuildSimplifiedGridParallelJob jobData2 = new BuildSimplifiedGridParallelJob
				{
					SimplifiedGrid = simplifiedWaterGridNative,
					Input = waterGrid,
					Width = World.inst.GridWidth
				};
				updateTextureHandle = IJobParallelForExtensions.Schedule(jobData2, World.inst.GridWidth * World.inst.GridHeight, 64, updateTextureHandle);
			}
		}
		DrawDebug();
	}

	public void UpdateWithPatchMap()
	{
		if (isUpdateFrame)
		{
			updateTextureHandle.Complete();
		}
		float[] framePatchMap = TerrainGen.inst.framePatchMap;
		for (int i = 0; i < framePatchMap.Length; i++)
		{
			if (framePatchMap[i] != 0f)
			{
				int x = i % width;
				int y = i / width;
				waterHeightMap1.SetPixel(x, y, new Color(waterHeightMap1.GetPixel(x, y).r + framePatchMap[i], 0f, 0f));
				waterHeightMap2.SetPixel(x, y, new Color(waterHeightMap2.GetPixel(x, y).r + framePatchMap[i], 0f, 0f));
			}
		}
		waterHeightMap1.Apply();
		waterHeightMap2.Apply();
	}

	public void LateUpdate()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		if (isUpdateFrame)
		{
			updateTextureHandle.Complete();
			isUpdateFrame = false;
			currentWaterHeightMap.Apply();
			if (waterHeightMap1 == currentWaterHeightMap)
			{
				currentWaterHeightMap = waterHeightMap2;
			}
			else
			{
				currentWaterHeightMap = waterHeightMap1;
			}
			simplifiedWaterGridNative.CopyTo(simplifiedWaterGrid);
			int num = simplifiedWaterGrid.Length;
			for (int i = 0; i < num; i++)
			{
				if (simplifiedWaterGrid[i] > 0f)
				{
					World.inst.treeSystem.DeleteTreesAt(i);
					World.inst.rockScatterSystem.DeleteTreesAt(i);
				}
			}
			scheduled = true;
			primaryJobHandle = StepSimulation();
		}
		float num2 = simulationUpdate.CurrTime / simulationUpdate.Duration;
		if (currentWaterHeightMap == waterHeightMap2)
		{
			num2 = 1f - num2;
		}
		Shader.SetGlobalFloat("_DynamicLavaBlend", Mathf.Clamp01(num2));
	}

	public void PrimeTextures()
	{
		localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
		for (int i = 0; i < waterGrid.Length; i++)
		{
			WaterCell waterCell = waterGrid[i];
			if (waterCell.waterAmount > 0f)
			{
				heightMapPixels[i] = new Color(waterCell.waterAmount + WaterMeshExtraHeight + localHeightMapCache[i], 0f, 0f);
			}
			else
			{
				heightMapPixels[i] = new Color(localHeightMapCache[i] + WaterMeshTuck, 0f, 0f);
			}
		}
		waterHeightMap1.SetPixels(heightMapPixels);
		waterHeightMap1.Apply();
		waterHeightMap2.SetPixels(heightMapPixels);
		waterHeightMap2.Apply();
		Shader.SetGlobalFloat("_DynamicLavaBlend", 0f);
		simulationUpdate.Reset();
	}

	public void Simulate(int frames)
	{
		for (int i = 0; i < frames; i++)
		{
			StepSimulation().Complete();
		}
		PrimeTextures();
	}

	public JobHandle StepSimulation()
	{
		localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
		localObstructionMapCache.CopyFrom(TerrainGen.inst.waterObstructionField);
		JobHandle dependsOn = IJobParallelForExtensions.Schedule(new UpdateFluxParallelJob
		{
			Width = width,
			Height = height,
			Input = waterGrid,
			Output = waterGridResult,
			HeightMap = localHeightMapCache,
			ObstructionMap = localObstructionMapCache,
			A = A,
			L = L,
			Gravity = Gravity,
			TerrainExaggeration = TerrainExaggeration,
			FluxClampThreshold = FluxClampThreshold,
			Viscosity = Viscosity,
			DeltaTime = TimeStep,
			NeighborIndices4 = neighborIndices4,
			SourceAmount = sourceAmount
		}, waterGrid.Length, jobInnerloopBatches);
		return IJobParallelForExtensions.Schedule(new UpdateWaterHeightParallelJob
		{
			Width = width,
			Height = height,
			Input = waterGridResult,
			Output = waterGrid,
			HeightMap = localHeightMapCache,
			OceanHeight = Water.inst.transform.position.y,
			Evaporation = Evaporation,
			DifferenceHeightMap = DifferenceHeightMapNativeArray,
			L = L,
			NeighborIndices4 = neighborIndices4,
			DeltaTime = TimeStep,
			BurntTexture = burntMap.GetRawTextureData<Color>()
		}, waterGrid.Length, jobInnerloopBatches, dependsOn);
	}

	private void Press3x3(int index, float amount)
	{
		for (int i = 0; i < 8; i++)
		{
			TerrainGen.inst.SoftDepressTile(World.inst.GetCellDataUnsafe((index + neighborWorldIndices8[i]) % waterGrid.Length), amount);
		}
		TerrainGen.inst.SoftDepressTile(World.inst.GetCellDataUnsafe(index), amount);
	}

	public WaterExtractionRequest AddWaterExtractionRequest(int x, int z, float altitude, RequestFulfillment callback)
	{
		WaterExtractionRequest waterExtractionRequest = new WaterExtractionRequest();
		waterExtractionRequest.x = x;
		waterExtractionRequest.z = z;
		waterExtractionRequest.altitude = altitude;
		waterExtractionRequest.callback = callback;
		waterExtractionRequests.Add(waterExtractionRequest);
		return waterExtractionRequest;
	}

	public void RemoveWaterExtractionRequest(WaterExtractionRequest req)
	{
		waterExtractionRequests.Remove(req);
	}

	public Vector3 GridPointerIntersection()
	{
		Ray ray = PointingSystem.GetRay();
		if (TerrainGen.inst.Raycast(ray, out var hitInfo))
		{
			return hitInfo.point;
		}
		new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		return World.inst.SnapToGrid2D(point);
	}

	public void CutRivers()
	{
		TerrainGen.inst.BuildNatureObstructionField();
		localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
		localObstructionMapCache.CopyFrom(TerrainGen.inst.waterObstructionField);
		tempWaterGrid = new WaterCell[waterGrid.Length];
		waterGrid.CopyTo(tempWaterGrid);
		paths = new List<List<int>>();
		for (int i = 0; i < tempWaterGrid.Length; i++)
		{
			if (!(tempWaterGrid[i].waterProductionRate <= 0f))
			{
				CutRiver(i);
			}
		}
	}

	private float Hueristic(int prev, int curr)
	{
		return localHeightMapCache[curr] + localObstructionMapCache[curr] - (localHeightMapCache[prev] + localObstructionMapCache[prev]);
	}

	private float Path(int prev, int curr)
	{
		return localHeightMapCache[curr] + localObstructionMapCache[curr] - (localHeightMapCache[prev] + localObstructionMapCache[prev]);
	}

	private int[] GetNeighbors(int node)
	{
		neighborIndices4.CopyTo(neighbors);
		for (int i = 0; i < 4; i++)
		{
			neighbors[i] += node;
		}
		return neighbors;
	}

	private bool FoundOcean(int i)
	{
		return localHeightMapCache[i] + localObstructionMapCache[i] < -1f;
	}

	public void CutRiver(int i)
	{
		List<int> list = new Astar<int>(Path, Hueristic, GetNeighbors).FindPath(i, FoundOcean);
		TerrainGen.inst.SoftDepressMesh(i % width, i / width, -0.4f);
		Vector3 pos = new Vector3((float)(i % width) / 2f, 0f, (float)(i / width) / 2f);
		TerrainGen.inst.GetGroundHeight(ref pos);
		Debug.DrawLine(pos, pos + Vector3.up, Color.magenta, 20f);
		foreach (int item in list)
		{
			WaterCell value = waterGrid[item];
			value.waterAmount = GeneratePrimeAmount;
			waterGrid[item] = value;
			TerrainGen.inst.SoftDepressMesh(item % width, item / width, -0.2f);
			pos = new Vector3((float)(item % width) / 2f, 0f, (float)(item / width) / 2f);
			TerrainGen.inst.GetGroundHeight(ref pos);
			Debug.DrawLine(pos, pos + Vector3.up, Color.magenta, 20f);
		}
	}

	public static int MapIndexWorldToMesh(int worldIndex, int worldWidth)
	{
		int num = worldIndex % worldWidth;
		int num2 = worldIndex / worldWidth;
		int num3 = num * 2 + 1;
		return (num2 * 2 + 1) * (worldWidth * 2 + 1) + num3;
	}

	public static int MapIndexMeshToWorld(int meshIndex, int worldWidth)
	{
		int num = meshIndex % (worldWidth * 2 + 1);
		int num2 = meshIndex / (worldWidth * 2 + 1);
		int num3 = (num - 1) / 2;
		return (num2 - 1) / 2 * worldWidth + num3;
	}

	public void DebugUpdate()
	{
		if (!Input.GetKey(KeyCode.F11))
		{
			return;
		}
		if (Input.GetMouseButton(0))
		{
			Vector3 worldPos = GridPointerIntersection();
			Cell cellData = World.inst.GetCellData(worldPos);
			Press3x3(cellData.index, 5f * Time.unscaledDeltaTime * (float)((!Input.GetKey(KeyCode.RightShift) && !Input.GetKey(KeyCode.LeftShift)) ? 1 : (-1)));
		}
		if (Input.GetMouseButtonDown(1))
		{
			primaryJobHandle.Complete();
			if (clickedOnceTimer.Enabled)
			{
				clickedOnceTimer.Enabled = false;
				Vector3 worldPos2 = GridPointerIntersection();
				Cell cellData2 = World.inst.GetCellData(worldPos2);
				if (cellData2 != null)
				{
					int index = MapIndexWorldToMesh(cellData2.index, World.inst.GridWidth);
					WaterCell waterCell = waterGrid[index];
					if (waterCell.waterProductionRate <= 0f)
					{
						CreateWaterSource(index, sourceAmount);
						if (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl))
						{
							CutRiver(waterCell.index);
						}
					}
					else
					{
						RemoveWaterSource(index);
					}
				}
			}
			else
			{
				clickedOnceTimer.Enabled = true;
				clickedOnceTimer.Reset();
			}
		}
		if (Input.GetMouseButtonDown(2))
		{
			primaryJobHandle.Complete();
			if (clickedOnceTimer.Enabled)
			{
				clickedOnceTimer.Enabled = false;
				Vector3 worldPos3 = GridPointerIntersection();
				Cell cellData3 = World.inst.GetCellData(worldPos3);
				if (cellData3 != null)
				{
					int lavaSource = MapIndexWorldToMesh(cellData3.index, World.inst.GridWidth);
					VolcanoManager.inst.CreateVolcano(lavaSource);
				}
			}
			else
			{
				clickedOnceTimer.Enabled = true;
				clickedOnceTimer.Reset();
			}
		}
		if (clickedOnceTimer.Update(Time.unscaledDeltaTime))
		{
			clickedOnceTimer.Enabled = false;
		}
	}

	public void DrawDebug()
	{
		if (!Input.GetKey(KeyCode.F11))
		{
			return;
		}
		ReadyForWrite();
		for (int i = 0; i < waterGrid.Length; i++)
		{
			WaterCell waterCell = waterGrid[i];
			float x = (float)(waterCell.index % width) / 2f;
			float z = (float)(waterCell.index / width) / 2f;
			if (waterCell.waterProductionRate > 0f)
			{
				Vector3 vector = new Vector3(x, TerrainGen.inst.GetVertYUnsafe(waterCell.index) + 0.01f, z);
				vector.y = TerrainGen.inst.GetInterpolatedHeight(vector);
				vector.y = localHeightMapCache[i];
				Matrix4x4 matrix = Matrix4x4.TRS(vector, Quaternion.identity, new Vector3(0.1f, waterCell.waterAmount, 0.1f));
				Graphics.DrawMesh(CubeMesh, matrix, WaterSourceMaterial, 0);
			}
			else if (waterCell.waterAmount > 0f)
			{
				Vector3 vector2 = new Vector3(x, TerrainGen.inst.GetVertYUnsafe(waterCell.index) + 0.01f, z);
				vector2.y = TerrainGen.inst.GetInterpolatedHeight(vector2);
				vector2.y = localHeightMapCache[i];
				Matrix4x4 matrix2 = Matrix4x4.TRS(vector2, Quaternion.identity, new Vector3(0.2f, waterCell.waterAmount, 0.2f));
				Graphics.DrawMesh(CubeMesh, matrix2, WaterSourceMaterialBlue, 0);
			}
		}
	}

	public void SetProduction(int index, float amount)
	{
		ReadyForWrite();
		WaterCell value = waterGrid[index];
		value.waterProductionRate = amount;
		waterGrid[index] = value;
	}

	public void ReadyForWrite()
	{
		updateTextureHandle.Complete();
		primaryJobHandle.Complete();
	}
}
