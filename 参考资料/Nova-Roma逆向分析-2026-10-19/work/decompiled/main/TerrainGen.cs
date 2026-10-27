using System;
using System.Collections.Generic;
using System.Linq;
using Code;
using Rewired.Utils.Libraries.TinyJson;
using Sirenix.OdinInspector;
using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Serialization;

public class TerrainGen : MonoBehaviour
{
	public delegate void OnChunkUpdate(TerrainChunk chunk);

	[BurstCompile]
	public struct BurstTextureCopy : IJobParallelFor
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<Color> From;

		public NativeArray<Color> To;

		public void Execute(int ind)
		{
			To[ind] = From[ind];
		}
	}

	[Serializable]
	public struct HeightModifier
	{
		public byte isEnabled;

		public Vector2 threshold;

		public float heightPoints;

		public byte doNormal;

		public byte isReverse;
	}

	public struct FertilityCell
	{
		public int x;

		public int z;

		public int landmass;

		public int gradeLandmass;

		public float height;

		public float landDist;

		public float dynamicWaterDist;
	}

	[BurstCompile]
	public struct LandmassHeightDistanceJob : IJobFor
	{
		public NativeArray<FertilityCell> FertilityCells;

		public NativeArray<Vector4> LandmassHeightDistance;

		public void Execute(int index)
		{
			FertilityCell fertilityCell = FertilityCells[index];
			if (fertilityCell.landmass != -1)
			{
				Vector4 value = LandmassHeightDistance[fertilityCell.landmass];
				if (value.z > fertilityCell.landDist)
				{
					value.z = fertilityCell.landDist;
				}
				if (value.w < fertilityCell.landDist)
				{
					value.w = fertilityCell.landDist;
				}
				LandmassHeightDistance[fertilityCell.landmass] = value;
			}
		}
	}

	[BurstCompile]
	public struct AggregateFertilityInformationJob : IJobFor
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<Color> DynamicWaterDistance;

		[Unity.Collections.ReadOnly]
		public NativeArray<half4> LandDistance;

		[Unity.Collections.ReadOnly]
		public NativeArray<float> CellHeights;

		[Unity.Collections.ReadOnly]
		public int GridWidth;

		public NativeArray<FertilityCell> FertilityCells;

		public void Execute(int index)
		{
			FertilityCell value = FertilityCells[index];
			if (value.gradeLandmass != -1)
			{
				value.dynamicWaterDist = DynamicWaterDistance[index].r;
				int num = 5;
				int index2 = value.z * num * (GridWidth * num) + value.x * num;
				value.landDist = Mathf.Max(0f - (float)LandDistance[index2].x, 0f) / (float)num;
				int index3 = (value.z * 2 + 1) * (GridWidth * 2 + 1) + (value.x * 2 + 1);
				value.height = CellHeights[index3];
				FertilityCells[index] = value;
			}
		}
	}

	[BurstCompile]
	public struct FertilityJob : IJobFor
	{
		[Unity.Collections.ReadOnly]
		public int GridWidth;

		[Unity.Collections.ReadOnly]
		public float NoisePoints;

		[Unity.Collections.ReadOnly]
		public bool EnableModifiers;

		[Unity.Collections.ReadOnly]
		public bool EnableHeightModifiers;

		[Unity.Collections.ReadOnly]
		public NativeArray<HeightModifier> HeightModifiers;

		[Unity.Collections.ReadOnly]
		public bool EnableRiverModifiers;

		[Unity.Collections.ReadOnly]
		public int RiverInterpolationMethod;

		[Unity.Collections.ReadOnly]
		public float LandDistanceOffset;

		[Unity.Collections.ReadOnly]
		public float WaterCloseRadius;

		[Unity.Collections.ReadOnly]
		public float WaterFarRadius;

		[Unity.Collections.ReadOnly]
		public float WaterClosePoints;

		[Unity.Collections.ReadOnly]
		public float WaterFarPoints;

		[Unity.Collections.ReadOnly]
		public float VeryFertileThreshold;

		[Unity.Collections.ReadOnly]
		public float FertileThreshold;

		[Unity.Collections.ReadOnly]
		public float CurrentTime;

		[Unity.Collections.ReadOnly]
		public float BlendTime;

		[Unity.Collections.ReadOnly]
		public bool doInstantBlend;

		[Unity.Collections.ReadOnly]
		public NativeArray<float> FertilityNoise;

		[Unity.Collections.ReadOnly]
		public NativeArray<Vector4> LandmassHeightDistance;

		[Unity.Collections.ReadOnly]
		public NativeArray<FertilityCell> FertilityCells;

		public NativeArray<Vector2> CurrFertilityColors;

		public NativeArray<Vector4> CurrBlendWeights;

		public NativeArray<Vector4> PrevBlendWeights;

		public NativeArray<float> FertilityBlendEndTimes;

		public NativeArray<int> RawFertility;

		public NativeArray<bool> IsFertilityDirty;

		public NativeArray<int> CurrentTileTextureIndices;

		private static Vector4 OneHotBlendWeights(int tileTextureIdx)
		{
			return tileTextureIdx switch
			{
				0 => new Vector4(1f, 0f, 0f, 0f), 
				1 => new Vector4(0f, 1f, 0f, 0f), 
				2 => new Vector4(0f, 0f, 1f, 0f), 
				3 => new Vector4(0f, 0f, 0f, 1f), 
				_ => Vector4.zero, 
			};
		}

		public void Execute(int index)
		{
			FertilityCell fCell = FertilityCells[index];
			int num = 0;
			int num2 = 2;
			if (fCell.gradeLandmass != -1)
			{
				int index2 = (fCell.z * 2 + 1) * (GridWidth * 2 + 1) + (fCell.x * 2 + 1);
				float num3 = FertilityNoise[index2] * NoisePoints;
				if (EnableModifiers)
				{
					if (EnableHeightModifiers)
					{
						for (int i = 0; i < HeightModifiers.Length; i++)
						{
							num3 += HeightModifierPoints(HeightModifiers[i], fCell.height);
						}
					}
					if (EnableRiverModifiers)
					{
						num3 += RiverModifierPoints(fCell, LandmassHeightDistance[fCell.gradeLandmass], LandDistanceOffset, RiverInterpolationMethod, WaterCloseRadius, WaterFarRadius, WaterClosePoints, WaterFarPoints);
					}
				}
				if (num3 >= VeryFertileThreshold)
				{
					num2 = 1;
					num = 2;
				}
				else if (num3 >= FertileThreshold)
				{
					num2 = 0;
					num = 1;
				}
			}
			int num4 = CurrentTileTextureIndices[index];
			if (num4 < 0 || doInstantBlend)
			{
				num4 = num2;
			}
			IsFertilityDirty[index] = num4 != num2;
			Vector2 value = CurrFertilityColors[index];
			value.x = num2;
			value.y = (doInstantBlend ? 0f : (CurrentTime + BlendTime));
			CurrFertilityColors[index] = value;
			PrevBlendWeights[index] = OneHotBlendWeights(num4);
			CurrBlendWeights[index] = OneHotBlendWeights(num2);
			FertilityBlendEndTimes[index] = value.y;
			CurrentTileTextureIndices[index] = num2;
			RawFertility[index] = ((fCell.landmass != -1) ? num : 0);
		}
	}

	[BurstCompile]
	public struct TerritoryTextureJob : IJobParallelFor
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<TerritoryCell> InputTerritoryCells;

		[Unity.Collections.ReadOnly]
		public NativeArray<float> InputWaterCells;

		[Unity.Collections.ReadOnly]
		public NativeArray<Color> InputDynamicWaterDistance;

		public NativeArray<Vector2> Output;

		[Unity.Collections.ReadOnly]
		public int MODE;

		[Unity.Collections.ReadOnly]
		public int gridWidth;

		[Unity.Collections.ReadOnly]
		public int gridHeight;

		[Unity.Collections.ReadOnly]
		public int landmass;

		public void Execute(int index)
		{
			TerritoryCell territoryCell = InputTerritoryCells[index];
			Vector2 value = Output[index];
			ref float x = ref value.x;
			ref float y = ref value.y;
			float num = 0.65f;
			x = 0f;
			y = num;
			if (territoryCell.landmass == landmass)
			{
				switch (MODE)
				{
				case 2:
				case 4:
				case 8:
				{
					if (territoryCell.type != TerrainType.None && territoryCell.type != TerrainType.Obstruction)
					{
						break;
					}
					bool flag3 = false;
					for (int num15 = -1; num15 <= 1; num15++)
					{
						for (int num16 = -1; num16 <= 1; num16++)
						{
							if (num15 == 0 || num16 == 0)
							{
								int index4 = territoryCell.x + num15 + (territoryCell.z + num16) * gridWidth;
								int terrainResourceID = InputTerritoryCells[index4].terrainResourceID;
								if (terrainResourceID != -1 && (MODE != 2 || terrainResourceID == 2) && (MODE != 4 || terrainResourceID == 5) && (MODE != 8 || terrainResourceID == 14))
								{
									flag3 = true;
									break;
								}
							}
						}
						if (flag3)
						{
							break;
						}
					}
					if (flag3)
					{
						value.x = 1f;
						value.y = 0f;
					}
					break;
				}
				case 1:
					if (territoryCell.type == TerrainType.None && InputDynamicWaterDistance[territoryCell.x + territoryCell.z * gridWidth].r < 4f)
					{
						value.x = 1f;
						value.y = 0f;
					}
					break;
				case 3:
				{
					if (territoryCell.type != TerrainType.None)
					{
						break;
					}
					bool flag = false;
					for (int n = -1; n <= 1; n++)
					{
						for (int num10 = -1; num10 <= 1; num10++)
						{
							int index3 = territoryCell.x + n + (territoryCell.z + num10) * gridWidth;
							if (InputTerritoryCells[index3].type == TerrainType.Water)
							{
								flag = true;
								break;
							}
						}
						if (flag)
						{
							break;
						}
					}
					if (flag)
					{
						value.x = 1f;
						value.y = 0f;
					}
					break;
				}
				case 5:
					value.x = 1f;
					value.y = 0f;
					break;
				case 6:
					if (territoryCell.roadCoverage > 0)
					{
						value.x = 1f;
						value.y = 0f;
					}
					break;
				case 7:
				{
					if (territoryCell.type != TerrainType.None || InputWaterCells[index] > 0f)
					{
						break;
					}
					if (InputDynamicWaterDistance[index].r < 4f)
					{
						value.x = 1f;
						value.y = 0f;
						break;
					}
					bool flag = false;
					for (int num11 = -1; num11 <= 1; num11++)
					{
						for (int num12 = -1; num12 <= 1; num12++)
						{
							if ((num11 != 0 || num12 != 0) && !(InputDynamicWaterDistance[num11 + territoryCell.x + (num12 + territoryCell.z) * gridWidth].r >= 4f))
							{
								flag = true;
								break;
							}
						}
						if (flag)
						{
							break;
						}
					}
					if (flag)
					{
						value.x = 1f;
						value.y = 0f;
						break;
					}
					for (int num13 = -3; num13 <= 3; num13++)
					{
						for (int num14 = -3; num14 <= 3; num14++)
						{
							if (InputTerritoryCells[territoryCell.x + num13 + (territoryCell.z + num14) * gridWidth].type == TerrainType.Water)
							{
								flag = true;
								break;
							}
						}
						if (flag)
						{
							break;
						}
					}
					if (flag)
					{
						value.x = 1f;
						value.y = 0f;
					}
					break;
				}
				case 9:
				{
					if (territoryCell.type != TerrainType.None)
					{
						break;
					}
					bool flag = false;
					for (int i = -1; i <= 1; i++)
					{
						for (int j = -1; j <= 1; j++)
						{
							if ((i == 0 && j == 0) || (i != 0 && j != 0))
							{
								continue;
							}
							int index2 = territoryCell.x + i + (territoryCell.z + j) * gridWidth;
							if (InputTerritoryCells[index2].type != TerrainType.Water)
							{
								continue;
							}
							goto IL_042e;
						}
						continue;
						IL_042e:
						flag = true;
						break;
					}
					if (!flag)
					{
						break;
					}
					bool flag2 = false;
					Vector3 a = new Vector3((float)territoryCell.x + 0.5f, 0f, (float)territoryCell.z + 0.5f);
					Vector3 b = default;
					float num2 = 36f;
					int num3 = Mathff.Clamp(territoryCell.x - 6, 0, gridWidth - 1);
					int num4 = Mathff.Clamp(territoryCell.x + 6, 0, gridWidth - 1);
					int num5 = Mathff.Clamp(territoryCell.z - 6, 0, gridHeight - 1);
					int num6 = Mathff.Clamp(territoryCell.z + 6, 0, gridHeight - 1);
					for (int k = num3; k <= num4; k++)
					{
						int num7 = num5;
						while (num7 <= num6)
						{
							b.x = k;
							b.z = num7;
							float num8 = float.MaxValue;
							for (int l = 0; l <= 1; l++)
							{
								for (int m = 0; m <= 1; m++)
								{
									b.x = k + l;
									b.z = num7 + m;
									float num9 = Mathff.DistSqrdXZ(a, b);
									if (num9 < num8)
									{
										num8 = num9;
									}
								}
							}
							if (!InputTerritoryCells[k + num7 * gridWidth].hasFish || num8 > num2)
							{
								num7++;
								continue;
							}
							goto IL_0584;
						}
						continue;
						IL_0584:
						flag2 = true;
						break;
					}
					if (flag2)
					{
						value.x = 1f;
						value.y = 0f;
					}
					break;
				}
				}
			}
			Output[index] = value;
		}
	}

	public struct TerritoryCell
	{
		public int landmass;

		public int x;

		public int z;

		public int roadCoverage;

		public TerrainType type;

		public bool hasFish;

		public int terrainResourceID;
	}

	[BurstCompile]
	public struct CreateMeshesParallelJob : IJobParallelFor
	{
		public struct VertexData
		{
			public Vector3 pos;

			public Vector3 normal;

			public Vector2 uv;
		}

		[Unity.Collections.ReadOnly]
		public NativeArray<VertexAttributeDescriptor> attributes;

		public Mesh.MeshDataArray meshDataArray;

		public NativeArray<int> xSize;

		public NativeArray<int> zSize;

		public NativeArray<Vector2> uvStart;

		public NativeArray<Vector2> uvEnd;

		private static readonly int[] _VertDirections = new int[48]
		{
			0, 0, 0, -1, -1, 0, -1, -1, -1, 0,
			0, -1, 0, 0, 1, 0, 0, -1, 1, -1,
			0, -1, 1, 0, 0, 0, 0, 1, 1, 0,
			1, 1, 1, 0, 0, 1, 0, 0, -1, 0,
			0, 1, -1, 1, 0, 1, -1, 0
		};

		public void Execute(int ind)
		{
			Mesh.MeshData meshData = meshDataArray[ind];
			int num = xSize[ind];
			int num2 = zSize[ind];
			Vector2 vector = uvStart[ind];
			Vector2 vector2 = uvEnd[ind];
			int num3 = num * 2 + 1;
			int num4 = num2 * 2 + 1;
			int vertexCount = num3 * num4;
			meshData.SetVertexBufferParams(vertexCount, attributes);
			NativeArray<VertexData> vertexData = meshData.GetVertexData<VertexData>();
			for (int i = 0; i < num4; i++)
			{
				for (int j = 0; j < num3; j++)
				{
					float x = (float)j / 2f;
					float z = (float)i / 2f;
					int index = j + i * num3;
					VertexData value = vertexData[index];
					Vector3 pos = value.pos;
					pos.x = x;
					pos.y = 0f;
					pos.z = z;
					value.pos = pos;
					Vector2 uv = value.uv;
					uv.x = Mathf.Lerp(vector.x, vector2.x, (float)j / (float)(num3 - 1));
					uv.y = Mathf.Lerp(vector.y, vector2.y, (float)i / (float)(num4 - 1));
					value.uv = uv;
					value.normal = new Vector3(0f, 1f, 0f);
					vertexData[index] = value;
				}
			}
			meshData.SetIndexBufferParams(num * num2 * 24, IndexFormat.UInt16);
			NativeArray<ushort> indexData = meshData.GetIndexData<ushort>();
			int num5 = 0;
			for (int k = 1; k < num3; k += 2)
			{
				for (int l = 1; l < num4; l += 2)
				{
					for (int m = 0; m < _VertDirections.Length / 2; m++)
					{
						indexData[num5] = (ushort)(k + l * num3 + (_VertDirections[m * 2] + _VertDirections[m * 2 + 1] * num3));
						num5++;
					}
				}
			}
			meshData.subMeshCount = 1;
			meshData.SetSubMesh(0, new SubMeshDescriptor(0, indexData.Length));
		}
	}

	private struct ChunksThatNeedMeshes
	{
		public TerrainChunk chunk;

		public int sizeX;

		public int sizeZ;

		public Vector2 uvStart;

		public Vector2 uvEnd;
	}

	[BurstCompile]
	public struct UpdateTextureParallelJob : IJobParallelFor
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<float> HeightMap;

		public NativeArray<float> SmoothedHeightMap;

		public int Width;

		public int Height;

		public void Execute(int ind)
		{
			int num = ind % Width;
			int num2 = ind / Width;
			float num3 = HeightMap[ind];
			float num4 = 0f;
			float num5 = 0f;
			for (int i = -3; i <= 3; i++)
			{
				for (int j = -3; j <= 3; j++)
				{
					int num6 = num + j;
					int num7 = num2 + i;
					if (num6 >= 0 && num6 < Width && num7 >= 0 && num7 < Height)
					{
						float num8 = HeightMap[num7 * Width + num6];
						float num9 = j * j + i * i;
						float num10 = num8 - num3;
						float num11 = Mathf.Exp((0f - num9) / 4.5f - num10 * num10 / 0.125f);
						num4 += num8 * num11;
						num5 += num11;
					}
				}
			}
			SmoothedHeightMap[ind] = num4 / num5;
		}
	}

	private struct Offset
	{
		public int x;

		public int z;
	}

	public delegate bool SkipCell(float y);

	[BurstCompile]
	public struct SmoothYLessThanWaterTestThresholdParallelJob : IJob
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<float> In;

		public NativeArray<float> Out;

		public int xSize;

		public int zSize;

		public int radius;

		public int sx;

		public int sz;

		public int ex;

		public int ez;

		public float minHeight;

		public float maxHeight;

		public int meshWidth;

		public float waterHeightTestThresold;

		public bool SkipFunction(float y)
		{
			return y < waterHeightTestThresold;
		}

		public void Execute()
		{
			int num = xSize * 2 + 1;
			int num2 = zSize * 2 + 1;
			for (int i = 0; i < num2; i++)
			{
				for (int j = 0; j < num; j++)
				{
					float y = In[j + i * meshWidth];
					if (!SkipFunction(y))
					{
						continue;
					}
					int num3 = Mathff.Clamp(j - radius, 0, num - 1);
					int num4 = Mathff.Clamp(j + radius, 0, num - 1);
					int num5 = Mathff.Clamp(i - radius, 0, num2 - 1);
					int num6 = Mathff.Clamp(i + radius, 0, num2 - 1);
					float num7 = 0f;
					float num8 = 0f;
					for (int k = num5; k <= num6; k++)
					{
						for (int l = num3; l <= num4; l++)
						{
							float num9 = In[l + k * meshWidth];
							num8 += num9;
							num7++;
						}
					}
					num8 /= num7;
					float num10 = num8;
					if (num10 > maxHeight)
					{
						num10 = maxHeight;
					}
					if (num10 < minHeight)
					{
						num10 = minHeight;
					}
					int num11 = i * num + j;
					if (num11 >= 0 && num11 < Out.Length)
					{
						Out[num11] = num10;
					}
				}
			}
		}
	}

	[BurstCompile]
	public struct SmoothYGreaterThanWaterTestThresholdParallelJob : IJob
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<float> In;

		public NativeArray<float> Out;

		public int xSize;

		public int zSize;

		public int radius;

		public float minHeight;

		public float maxHeight;

		public int meshWidth;

		public float waterHeightTestThresold;

		public bool SkipFunction(float y)
		{
			return y > waterHeightTestThresold;
		}

		public void Execute()
		{
			int num = xSize * 2 + 1;
			int num2 = zSize * 2 + 1;
			for (int i = 0; i < num2; i++)
			{
				for (int j = 0; j < num; j++)
				{
					float y = In[j + i * meshWidth];
					if (!SkipFunction(y))
					{
						continue;
					}
					int num3 = Mathff.Clamp(j - radius, 0, num - 1);
					int num4 = Mathff.Clamp(j + radius, 0, num - 1);
					int num5 = Mathff.Clamp(i - radius, 0, num2 - 1);
					int num6 = Mathff.Clamp(i + radius, 0, num2 - 1);
					float num7 = 0f;
					float num8 = 0f;
					for (int k = num5; k <= num6; k++)
					{
						for (int l = num3; l <= num4; l++)
						{
							float num9 = In[l + k * meshWidth];
							num8 += num9;
							num7++;
						}
					}
					num8 /= num7;
					float num10 = num8;
					if (num10 > maxHeight)
					{
						num10 = maxHeight;
					}
					if (num10 < minHeight)
					{
						num10 = minHeight;
					}
					int num11 = i * num + j;
					if (num11 >= 0 && num11 < Out.Length)
					{
						Out[num11] = num10;
					}
				}
			}
		}
	}

	[BurstCompile]
	public struct SmoothYGreaterThanWaterHeightParallelJob : IJob
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<float> In;

		public NativeArray<float> Out;

		public int xSize;

		public int zSize;

		public int radius;

		public float minHeight;

		public float maxHeight;

		public int meshWidth;

		public float waterHeight;

		public bool SkipFunction(float y)
		{
			return y > waterHeight;
		}

		public void Execute()
		{
			int num = xSize * 2 + 1;
			int num2 = zSize * 2 + 1;
			for (int i = 0; i < num2; i++)
			{
				for (int j = 0; j < num; j++)
				{
					float y = In[j + i * meshWidth];
					if (!SkipFunction(y))
					{
						continue;
					}
					int num3 = Mathff.Clamp(j - radius, 0, num - 1);
					int num4 = Mathff.Clamp(j + radius, 0, num - 1);
					int num5 = Mathff.Clamp(i - radius, 0, num2 - 1);
					int num6 = Mathff.Clamp(i + radius, 0, num2 - 1);
					float num7 = 0f;
					float num8 = 0f;
					for (int k = num5; k <= num6; k++)
					{
						for (int l = num3; l <= num4; l++)
						{
							float num9 = In[l + k * meshWidth];
							num8 += num9;
							num7++;
						}
					}
					num8 /= num7;
					float num10 = num8;
					if (num10 > maxHeight)
					{
						num10 = maxHeight;
					}
					if (num10 < minHeight)
					{
						num10 = minHeight;
					}
					int num11 = i * num + j;
					if (num11 >= 0 && num11 < Out.Length)
					{
						Out[num11] = num10;
					}
				}
			}
		}
	}

	public struct MountainData
	{
		public enum Size
		{
			Large,
			Medium,
			Small
		}

		public enum Type
		{
			Interior,
			Exterior,
			Corner,
			Edge,
			None
		}

		public Type type;

		public Size size;

		public Vector3 pos;

		public Vector3 landDir;

		public Vector3 waterDir;

		public int waterEdges;

		public int landEdges;

		public float area;

		public float radius;

		public int landmassIdx;

		public int posIdx;

		public int groupId;

		public int idx;
	}

	[Serializable]
	public struct MountainPlacerData
	{
		public List<MountainPlacer> mountains;
	}

	[Serializable]
	public class FertilitySplotData
	{
		public enum Rate
		{
			Absolute,
			Per1000
		}

		public int radius;

		public int rate;

		public Rate rateType;

		public int fertilityValue;
	}

	[Serializable]
	public struct PlacedSplots
	{
		public int radius;

		public SerializableVector3 pos;
	}

	public struct GrassTileChange
	{
		public Cell cell;

		public float forHowLong;

		public bool forceChange;
	}

	[BurstCompile]
	public struct PopulateRaycastCommandsJob : IJobParallelFor
	{
		public NativeArray<RaycastCommand> RaycastCommands;

		public int LayerMask;

		public int MeshWidth;

		private static readonly Vector3 DownVector = Vector3.down;

		public void Execute(int ind)
		{
			RaycastCommand value = RaycastCommands[ind];
			int num = ind % MeshWidth;
			int num2 = ind / MeshWidth;
			QueryParameters queryParameters = QueryParameters.Default;
			queryParameters.hitBackfaces = false;
			queryParameters.hitMultipleFaces = false;
			queryParameters.layerMask = LayerMask;
			value.queryParameters = queryParameters;
			value.from = new Vector3((float)num * 0.5f, 100f, (float)num2 * 0.5f);
			value.direction = DownVector;
			value.distance = 150f;
			value.physicsScene = Physics.defaultPhysicsScene;
			RaycastCommands[ind] = value;
		}
	}

	[BurstCompile]
	public struct BuildObstructionMapJob : IJobParallelFor
	{
		[Unity.Collections.ReadOnly]
		public NativeArray<float> HeightField;

		public NativeArray<RaycastHit> HitResults;

		public NativeArray<float> ObstructionField;

		[Unity.Collections.ReadOnly]
		public float WaterHeight;

		public NativeArray<float> MountainObstructionField;

		public void Execute(int ind)
		{
			RaycastHit raycastHit = HitResults[ind];
			float num = Mathf.Max(0f, raycastHit.point.y - HeightField[ind]);
			ObstructionField[ind] = num;
			MountainObstructionField[ind] = ((raycastHit.point.y <= WaterHeight) ? 0f : num);
		}
	}

	public static TerrainGen inst;

	public Material TerrainFlatMaterial;

	public Material TerrainMaterial;

	[FormerlySerializedAs("WaterMaterial")]
	public Material DynamicWaterMaterial;

	public Material DynamicLavaMaterial;

	public GameObject chunkPrefab;

	public List<TerrainChunk> terrainChunks;

	public List<TerrainChunk> waterChunks;

	public List<TerrainChunk> lavaChunks;

	public int chunkSize;

	private int chunkSizeMesh;

	public const int BarrenFertility = 0;

	public const int FertileFertility = 1;

	public const int VeryFertileFertility = 2;

	private const int TileFertileTextureIdx = 0;

	private const int TileVeryFertileTextureIdx = 1;

	private const int TileBarrenTextureIdx = 2;

	public TerrainSkinConfiguration defaultSkin;

	[FormerlySerializedAs("roadTexture")]
	public Texture2D roadLocationTexture;

	public Texture2D temporaryTerrainEffectsTexture;

	public Texture2D grassVisibilityTexture;

	public TerrainSkirt terrainSkirt;

	public float OverlayFadeTime = 0.15f;

	private Texture2D territoryTexture;

	public Texture2D terrainHeightMap;

	public Texture2D terrainHeightMapSmoothed;

	public Texture2D terrainHeightMapPreview;

	private Color[] overlayPixels;

	private Texture2D overlayTexture;

	public Color[] tempPixels;

	public int MaxOceanThickness = 6;

	public int MinOceanThickness = 1;

	public float noiseIntensity = 0.01f;

	public float perlinExperiment;

	public static float waterHeightDeep = -5f;

	public static float waterHeightShallow = -0.5f;

	public static float waterHeightMoat = -0.4f;

	public static float waterHeightTestThresold = -0.25f;

	public static float SeaLevel = -0.24f;

	public TerrainResource TerrainResourceStone;

	public TerrainResource TerrainResourceMarble;

	public TerrainResource TerrainResourceIron;

	private Color[] pixels;

	private Color[] terrainPixels;

	private int xSize;

	private int zSize;

	private int vertWidth;

	private int vertHeight;

	private Transform waterTransform;

	private Material staticWaterMaterial;

	public static OnChunkUpdate onChunkUpdate;

	private int chunkWidth;

	private GlobalKeyword gridKeyword;

	private GlobalKeyword territoryKeyword;

	private GlobalKeyword topologyKeyword;

	private TerrainSkinConfiguration currSkin;

	private TerrainSkinConfiguration nextSkin;

	private bool skinBlendDo;

	private float skinBlendDuration;

	private float skinBlendT;

	public RenderTexture terrainColorRenderTexture;

	private ArrayExt<Building> buildingsInOverlay = new ArrayExt<Building>(2500);

	public static bool alwaysSnapDecorations;

	public static bool suppressEditModeGrid;

	private float gridFade;

	private float pulseTime;

	public AnimationCurve pulseCurve;

	private bool startPulse;

	private float territoryFade;

	private float topologyFade;

	public bool showTopology;

	private const float TerrainDisabledGray = 0.65f;

	private const float TerrainInactiveGray = 0.35f;

	public bool peekUnderDynamicWater;

	public bool editTerrainSimulate;

	private float editTerrainShowFade;

	public static bool DoFertilityUpdate = false;

	public static bool DoFertilityInstantBlend = false;

	private JobHandle fertilityJob;

	public bool EnableInstantUpdate;

	public bool EnableModifiers = true;

	public float VeryFertileThreshold = 9f;

	public float FertileThreshold = 6f;

	public float NoisePoints = 10f;

	public float fertilityMaxUpdateTime = 20f;

	[NonSerialized]
	private float fertilityCurrUpdateTime;

	public float FertilityBlendDuration = 20f;

	[NonSerialized]
	public float FertilityBlendTime;

	[NonSerialized]
	public Texture2D currFertilityTexture;

	[NonSerialized]
	public Texture2D currBlendWeightsTexture;

	[NonSerialized]
	public Texture2D prevBlendWeightsTexture;

	[NonSerialized]
	public Texture2D fertilityBlendEndTexture;

	public float fertilityNoiseHigh;

	public float fertilityNoiseLow;

	public bool EnableTextures;

	public Texture2D HighNoiseTexture;

	public Texture2D LowNoiseTexture;

	public Texture2D NoiseTexture;

	public bool EnableHeightModifiers = true;

	public bool DoHeightModUpdates;

	public HeightModifier[] HeightModifiers;

	private NativeArray<HeightModifier> RawHeightModifiers;

	public bool EnableRiverModifiers = true;

	public float WaterCloseRadius = 5f;

	public float WaterFarRadius = 2f;

	public float LandDistanceOffset = 0.8f;

	public int RiverInterpolationMethod;

	public float WaterClosePoints = 10f;

	public float WaterFarPoints = 5f;

	private ValueDropdownList<int> InterpolationMethods = new ValueDropdownList<int>
	{
		{ "Linear", 0 },
		{ "Square", 1 },
		{ "Square Root", 2 }
	};

	private NativeArray<float> FertilityNoise;

	[NonSerialized]
	public float[] RawFertilityNoise;

	[NonSerialized]
	public bool isFertilityNoiseDirty;

	private NativeArray<float> CellHeights;

	private NativeArray<Vector4> LandmassHeightDistance;

	private NativeArray<FertilityCell> FertilityCells;

	[NonSerialized]
	public int[] Fertility;

	private NativeArray<int> RawFertility;

	private NativeArray<bool> IsFertilityDirty;

	private NativeArray<int> CurrentTileTextureIndices;

	public NativeArray<TerritoryCell> TerritoryCells;

	public NativeArray<float> SimplifiedWaterGrid;

	public Timer TerrainTextureUpdate = new Timer(0.1f);

	public bool isTerritoryTextureDirty;

	private JobHandle CurrentTerritoryTextureJob;

	private bool isInitialTextureComplete = true;

	private int currTerritoryLandmass = -1;

	private int currTerritoryMode = -1;

	private int prevTerritoryMode = -1;

	public const int DEFAULT_TERRITORY_MODE = 0;

	public const int BRIDGE_TERRITORY_MODE = 1;

	public const int STONE_QUARRY_TERRITORY_MODE = 2;

	public const int DOCK_TERRITORY_MODE = 3;

	public const int IRON_TERRITORY_MODE = 4;

	public const int LANDMASS_TERRITORY_MODE = 5;

	public const int ROAD_COVERAGE_TERRITORY_MODE = 6;

	public const int CLAYPIT_TERRITORY_MODE = 7;

	public const int MARBLE_QUARRY_TERRITORY_MODE = 8;

	public const int FISHING_HUT_TERRITORY_MODE = 9;

	private static Cell[] neighbourScratch = new Cell[8];

	public HashSet<Cell> dirtyTerritoryCells = new HashSet<Cell>(64);

	internal float[] heightCache;

	internal float[] originalHeightCache;

	internal float[] bridgeHeightCache;

	internal float[] framePatchMap;

	public bool patchMapDirty = true;

	internal float[] waterObstructionField;

	internal float[] mountainObstructionField;

	private float[,] scratchMap = new float[5, 5];

	private bool[] buildingsInOverlayMap;

	private Offset[] smoothOffsets = new Offset[8]
	{
		new Offset
		{
			x = 1,
			z = 0
		},
		new Offset
		{
			x = -1,
			z = 0
		},
		new Offset
		{
			x = 0,
			z = 1
		},
		new Offset
		{
			x = 0,
			z = -1
		},
		new Offset
		{
			x = 1,
			z = 1
		},
		new Offset
		{
			x = -1,
			z = 1
		},
		new Offset
		{
			x = 1,
			z = -1
		},
		new Offset
		{
			x = -1,
			z = -1
		}
	};

	private NativeArray<float> InputHeightCacheNativeArrayForSmoothing;

	private NativeArray<float> OutputHeightCacheNativeArrayForSmoothing;

	public MapGenTest mapGen;

	public float heightFreqA = 25f;

	public float heightFreqB = 50f;

	public float oceanThreshold = 0.5f;

	public int maxWaterPerLandmass = 3;

	public float MinInternalSize = 50f;

	public float MaxInternalSize = 75f;

	private List<MountainData> mountainPositions = new List<MountainData>();

	[NonSerialized]
	public bool[] modifiedTerrain;

	public ArrayExt<Vector4>[] islandInteriorBounds;

	public int bumpRadius = 2;

	public int bumpStepSize = 3;

	public float bumpDepth = 0.3f;

	public List<Mesh> mountainRockMeshes = new List<Mesh>();

	[NonSerialized]
	public Transform mountainContainer;

	public List<MountainPlacerData> centerMountains;

	public List<MountainPlacerData> exteriorMountains;

	public List<MountainPlacerData> interiorMountains;

	public List<MountainPlacerData> cornerMountains;

	public List<MountainPlacerData> edgeMountains;

	[NonSerialized]
	public List<GameObject> mountainRocks = new List<GameObject>();

	[NonSerialized]
	public int centerMountainsStart;

	private Cell[] scratchCells = new Cell[8];

	private Vector3[] triangle = new Vector3[3];

	public Color[] terrainPixelsPreview;

	private Vector3 down = Vector3.down;

	private Vector3 up = Vector3.up;

	private Vector3[] _triangle = new Vector3[3];

	private bool[] dirtyVertMap;

	private ArrayExt<int> dirtyVertList = new ArrayExt<int>(1000);

	private HashSet<int> dirtyCellsForFreeResources = new HashSet<int>();

	[DoNotSerialize]
	public float grassEffectTimeCode;

	public ArrayExt<GrassTileChange> pendingGrassTiles = new ArrayExt<GrassTileChange>(1000);

	[DoNotSerialize]
	public float tempEffectTimeCode;

	public Vector3 landAveragedWorldCenter;

	public Vector3 landWorldMin;

	public Vector3 landWorldMax;

	public const int TEMPEFFECT_DISTURBED_DIRT = 1;

	public TerrainResource GetTerrainResourcePrefabOfType(int rID)
	{
		return rID switch
		{
			2 => TerrainResourceStone, 
			14 => TerrainResourceMarble, 
			5 => TerrainResourceIron, 
			_ => null, 
		};
	}

	private void Awake()
	{
		inst = this;
		SetSkin(defaultSkin);
		chunkSizeMesh = chunkSize * 2;
	}

	private void Start()
	{
		waterTransform = UnityEngine.Object.FindAnyObjectByType<Water>().transform;
		staticWaterMaterial = waterTransform.GetComponent<MeshRenderer>().material;
		Water.inst.NewWaterDistanceField += OnNewWaterDistanceField;
		DynamicWater.inst.NewWaterHeightMap += OnNewWaterHeightMap;
		DynamicLava.inst.NewWaterHeightMap += OnNewLavaHeightMap;
		gridKeyword = GlobalKeyword.Create("_GRID_ON");
		territoryKeyword = GlobalKeyword.Create("_TERRITORY_ON");
		topologyKeyword = GlobalKeyword.Create("_TOPOLOGY_ON");
		Shader.SetKeyword(in gridKeyword, value: false);
		Shader.SetKeyword(in territoryKeyword, value: false);
		Shader.SetKeyword(in topologyKeyword, value: false);
		UpdateFertilityHeightModifiers();
	}

	private void OnDestroy()
	{
		if (!CurrentTerritoryTextureJob.IsCompleted)
		{
			CurrentTerritoryTextureJob.Complete();
		}
		if (TerritoryCells.IsCreated)
		{
			TerritoryCells.Dispose();
		}
		if (SimplifiedWaterGrid.IsCreated)
		{
			SimplifiedWaterGrid.Dispose();
		}
		if (FertilityNoise.IsCreated)
		{
			FertilityNoise.Dispose();
		}
		if (FertilityCells.IsCreated)
		{
			FertilityCells.Dispose();
		}
		if (LandmassHeightDistance.IsCreated)
		{
			LandmassHeightDistance.Dispose();
		}
		if (CellHeights.IsCreated)
		{
			CellHeights.Dispose();
		}
		if (RawFertility.IsCreated)
		{
			RawFertility.Dispose();
		}
		if (IsFertilityDirty.IsCreated)
		{
			IsFertilityDirty.Dispose();
		}
		if (CurrentTileTextureIndices.IsCreated)
		{
			CurrentTileTextureIndices.Dispose();
		}
		if (RawHeightModifiers.IsCreated)
		{
			RawHeightModifiers.Dispose();
		}
	}

	private void OnNewWaterHeightMap(object sender, DynamicWater.NewWaterHeightMapEvent e)
	{
		inst.DynamicWaterMaterial.SetTexture("_WaterHeightMap1", e.Texture1);
		inst.DynamicWaterMaterial.SetTexture("_WaterHeightMap2", e.Texture2);
		inst.staticWaterMaterial.SetTexture("_WaterHeightMap1", e.Texture1);
		inst.staticWaterMaterial.SetTexture("_WaterHeightMap2", e.Texture2);
		inst.DynamicWaterMaterial.SetTexture("_WaterFlow", e.Flow);
	}

	private void OnNewLavaHeightMap(object sender, DynamicLava.NewWaterHeightMapEvent e)
	{
		inst.DynamicLavaMaterial.SetTexture("_WaterHeightMap1", e.Texture1);
		inst.DynamicLavaMaterial.SetTexture("_WaterHeightMap2", e.Texture2);
	}

	private void OnNewWaterDistanceField(object sender, Water.NewDistanceFieldsEvent e)
	{
		inst.DynamicWaterMaterial.SetTexture("_DistanceField", e.SDFTexture);
		inst.TerrainMaterial.SetTexture("_TerrainDistanceField", e.SDFTexture);
	}

	public void SetSkin(TerrainSkinConfiguration skin)
	{
		currSkin = skin;
		TerrainMaterial.SetTexture("_TextureTex", currSkin.TextureArray);
		TerrainMaterial.SetFloatArray("_TextureScales", currSkin.Scales);
	}

	public void SetNextSkin(TerrainSkinConfiguration nSkin)
	{
		nextSkin = nSkin;
		TerrainMaterial.SetFloat("_SkinBlend", 0f);
		TerrainMaterial.SetTexture("_NextTex", nextSkin.TextureArray);
		TerrainMaterial.SetFloatArray("_NextTextureScales", nextSkin.Scales);
	}

	public void SetSummerSkin(TerrainSkinConfiguration nSkin)
	{
		TerrainMaterial.SetTexture("_SummerSkinTex", nSkin.TextureArray);
		TerrainMaterial.SetFloatArray("_SummerSkinScales", nSkin.Scales);
	}

	public void BlendInNextSkin(float duration)
	{
		skinBlendDo = true;
		skinBlendDuration = duration;
		skinBlendT = 0f;
	}

	public void RenderTerrainColors()
	{
		if (xSize != 0)
		{
			if (currSkin != null)
			{
				TerrainFlatMaterial.SetTexture("_TextureTex", currSkin.TextureArray);
				TerrainFlatMaterial.SetFloatArray("_TextureScales", currSkin.Scales);
			}
			if (nextSkin != null)
			{
				TerrainFlatMaterial.SetTexture("_NextTex", nextSkin.TextureArray);
				TerrainFlatMaterial.SetFloatArray("_NextTextureScales", nextSkin.Scales);
			}
			TerrainFlatMaterial.SetFloat("_OceanHeight", Water.inst.transform.position.y);
			Graphics.Blit(currFertilityTexture, terrainColorRenderTexture, TerrainFlatMaterial);
		}
	}

	public void GetGroundHeight(ref Vector3 pos)
	{
		pos.y = GetInterpolatedHeight(pos);
	}

	public void GetGroundHeight(ref SerializableVector3 pos)
	{
		pos.y = GetInterpolatedHeight(pos);
	}

	public float GetGroundHeight(float x, float z)
	{
		return GetInterpolatedHeight(new Vector3(x, 0f, z));
	}

	public void SetOverlayCircle(Vector3 s, float radius, Color col)
	{
		int num = (int)Mathf.Max(Mathf.Floor(s.x - radius), 0f);
		int num2 = (int)Mathf.Max(Mathf.Floor(s.z - radius), 0f);
		int num3 = (int)Mathf.Min(Mathf.Ceil(s.x + radius), World.inst.GridWidth - 1);
		int num4 = (int)Mathf.Min(Mathf.Ceil(s.z + radius), World.inst.GridHeight - 1);
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				if (cellData != null && World.inst.TileTouchingRadius(cellData, s, radius))
				{
					SetOverlayTileColor(i, j, col);
				}
			}
		}
		if (radius <= 0f)
		{
			SetOverlayTileColor((int)s.x, (int)s.z, col);
		}
		UpdateOverlayTextures();
	}

	public void RedrawOverlayCircle(Vector3 s, float radius, Color col)
	{
		ClearOverlay(updateToo: false);
		SetOverlayCircle(s, radius, col);
		FadeOverlay(1f);
	}

	public void SetOverlayPixelsToTransparent()
	{
		Util.Memset(overlayPixels, 0);
	}

	public void AddBuildingToOverlay(Building b)
	{
		buildingsInOverlay.Add(b);
	}

	public void ClearOverlay(bool updateToo)
	{
		if (!(overlayTexture == null))
		{
			Util.Memset(overlayPixels, 0);
			Util.Memset(buildingsInOverlayMap, 0);
			int i = 0;
			for (int count = buildingsInOverlay.Count; i < count; i++)
			{
				buildingsInOverlay.data[i].ClearInfoOverlay();
			}
			buildingsInOverlay.Clear();
			if (updateToo)
			{
				UpdateOverlayTextures();
			}
			else
			{
				overlayTexture.SetPixels(0, 0, xSize * 2, zSize * 2, overlayPixels);
			}
		}
	}

	public void FadeOverlay(float endFade)
	{
		Shader.SetGlobalFloat("_OverlayAlpha", endFade);
		TerrainMaterial.SetFloat("_OverlayAlpha", endFade);
		staticWaterMaterial.SetFloat("_OverlayAlpha", endFade);
	}

	public void UpdateTerrainDeformations()
	{
		dirtyCellsForFreeResources.Clear();
		for (int i = 0; i < dirtyVertList.Count; i++)
		{
			int num = dirtyVertList.data[i];
			dirtyVertMap[num] = false;
			if (!DynamicWater.inst.editTerrainSimulate || alwaysSnapDecorations)
			{
				FixDecorationHeight(DynamicWater.MapIndexMeshToWorld(num, xSize));
			}
			CollectAffectedCellsForVertex(num);
		}
		dirtyVertList.Clear();
		if (dirtyCellsForFreeResources.Count > 0 && !DynamicWater.inst.editTerrainSimulate)
		{
			FreeResourceSystem.inst.UpdateResourceHeightsForCells(dirtyCellsForFreeResources);
		}
		for (int j = 0; j < terrainChunks.Count; j++)
		{
			if (terrainChunks[j].dirtyVerts)
			{
				terrainChunks[j].FinalizeChanges();
				terrainChunks[j].dirtyVerts = false;
				onChunkUpdate?.Invoke(terrainChunks[j]);
				Selector.UpdateTextureForChunkHeights(terrainChunks[j]);
			}
		}
		Selector.TryApplyTexture();
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		Water.inst.PublishDynamicDistanceField();
		if (Water.inst.distanceDynamicWaterTextureFinished == null)
		{
			return;
		}
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		float deltaTime = Time.deltaTime;
		TerrainMaterial.SetFloat("_OceanHeight", Water.inst.transform.position.y);
		DynamicWaterMaterial.SetFloat("_OceanHeight", Water.inst.transform.position.y);
		staticWaterMaterial.SetFloat("_OceanHeight", Water.inst.transform.position.y);
		if (startPulse)
		{
			pulseTime += unscaledDeltaTime * 3f;
			if (pulseTime >= 1f)
			{
				startPulse = false;
			}
			float value = pulseCurve.Evaluate(Mathf.Clamp01(pulseTime)) * 0.25f;
			TerrainMaterial.SetFloat("_TerritoryPulse", value);
			staticWaterMaterial.SetFloat("_TerritoryPulse", value);
		}
		UpdateTerrainDeformations();
		Building building = GameUI.inst.CurrPlacementMode?.GetHoverBuilding();
		showTopology = false;
		if (building != null)
		{
			showTopology |= building.uniqueNameHash == World.waterTowerHash;
			showTopology |= building.uniqueNameHash == World.castellumaquaeHash;
			showTopology |= building.uniqueNameHash == World.bathReservoirHash;
			showTopology |= building.uniqueNameHash == World.waterOutletHash;
			showTopology |= building.uniqueNameHash == World.ironOreMillHash;
			showTopology |= building.uniqueNameHash == World.damHash;
			showTopology |= building.uniqueNameHash == World.spilloverHash;
		}
		showTopology |= GameUI.inst.AqueductCursorModeActive();
		if (showTopology)
		{
			topologyFade += unscaledDeltaTime * 4f;
		}
		else
		{
			topologyFade -= unscaledDeltaTime * 4f;
		}
		topologyFade = Mathf.Clamp01(topologyFade);
		Ray ray = PointingSystem.GetRay();
		if (Raycast(ray, out var hitInfo))
		{
			TerrainMaterial.SetFloat("_TopologyCursorY", hitInfo.point.y);
		}
		else
		{
			TerrainMaterial.SetFloat("_TopologyCursorY", -100f);
		}
		if (currTerritoryMode != -1)
		{
			if (CurrentTerritoryTextureJob.IsCompleted)
			{
				if (!isInitialTextureComplete)
				{
					isInitialTextureComplete = true;
				}
				if (isTerritoryTextureDirty)
				{
					isTerritoryTextureDirty = false;
					territoryTexture.Apply();
				}
			}
			if (TerrainTextureUpdate.Update(unscaledDeltaTime))
			{
				StartTerritoryTextureJob();
			}
		}
		if (currTerritoryMode == -1)
		{
			territoryFade -= unscaledDeltaTime * 4f;
		}
		else if (isInitialTextureComplete)
		{
			territoryFade += unscaledDeltaTime * 4f;
		}
		territoryFade = Mathf.Clamp01(territoryFade);
		if ((editTerrainSimulate && !suppressEditModeGrid) || peekUnderDynamicWater)
		{
			editTerrainShowFade += unscaledDeltaTime * 4f;
		}
		else
		{
			editTerrainShowFade -= unscaledDeltaTime * 4f;
		}
		editTerrainShowFade = Mathf.Clamp01(editTerrainShowFade);
		TerrainMaterial.SetFloat("_EditModeFade", editTerrainShowFade);
		DynamicWaterMaterial.SetFloat("_EditModeFade", editTerrainShowFade);
		TerrainMaterial.SetFloat("_TopologyFade", topologyFade);
		Shader.SetGlobalFloat("_GrassHide", topologyFade + editTerrainShowFade);
		if (topologyFade > 0f)
		{
			Shader.SetKeyword(in topologyKeyword, value: true);
		}
		else
		{
			Shader.SetKeyword(in topologyKeyword, value: false);
		}
		if (editTerrainShowFade > 0f)
		{
			Shader.SetKeyword(in gridKeyword, value: true);
		}
		else
		{
			Shader.SetKeyword(in gridKeyword, value: false);
		}
		if (territoryFade > 0f)
		{
			Shader.SetKeyword(in territoryKeyword, value: true);
		}
		else
		{
			Shader.SetKeyword(in territoryKeyword, value: false);
		}
		TerrainMaterial.SetFloat("_TerritoryFade", territoryFade);
		TerrainMaterial.SetFloat("_TerritoryYCutoff", waterTransform.position.y);
		staticWaterMaterial.SetFloat("_TerritoryFade", territoryFade);
		gridFade = Mathf.Clamp01(gridFade + (float)((GameUI.inst.CurrPlacementMode.IsPlacing() ? 1 : (-1)) * 4) * Time.unscaledDeltaTime);
		GridFade(gridFade);
		staticWaterMaterial.SetFloat("_GridFade", gridFade);
		if (skinBlendDo)
		{
			skinBlendT = Mathf.Clamp01(skinBlendT + deltaTime / skinBlendDuration);
			TerrainMaterial.SetFloat("_SkinBlend", skinBlendT);
			TerrainFlatMaterial.SetFloat("_SkinBlend", skinBlendT);
			if (skinBlendT >= 1f)
			{
				skinBlendDo = false;
				SetSkin(nextSkin);
				TerrainMaterial.SetFloat("_SkinBlend", 0f);
				TerrainFlatMaterial.SetFloat("_SkinBlend", 0f);
			}
		}
		tempEffectTimeCode += deltaTime;
		TerrainMaterial.SetFloat("_TempEffectTimeNow", tempEffectTimeCode);
		grassEffectTimeCode += deltaTime;
		for (int i = 0; i < TreeSystem.systems.Count; i++)
		{
			TreeSystem treeSystem = TreeSystem.systems[i];
			if (treeSystem.type == 1 && treeSystem.chunks != null)
			{
				for (int j = 0; j < treeSystem.chunks.Length; j++)
				{
					treeSystem.chunks[j].mat.SetFloat("_GrassTimeNow", grassEffectTimeCode);
				}
				treeSystem.animMaterial.SetFloat("_GrassTimeNow", grassEffectTimeCode);
			}
		}
		FertilityBlendTime += (editTerrainSimulate ? unscaledDeltaTime : deltaTime);
		TerrainMaterial.SetFloat("_FertilityBlendTime", FertilityBlendTime);
		TerrainFlatMaterial.SetFloat("_FertilityBlendTime", FertilityBlendTime);
		fertilityCurrUpdateTime += (editTerrainSimulate ? unscaledDeltaTime : deltaTime);
		if (!LoadSave.Loading && !Player.inst.resetting && (fertilityCurrUpdateTime >= fertilityMaxUpdateTime || ((EnableInstantUpdate || editTerrainSimulate) && fertilityCurrUpdateTime >= 0.2f) || DoFertilityUpdate))
		{
			bool doFertilityUpdate = DoFertilityUpdate;
			UpdateFertility();
			if (!doFertilityUpdate)
			{
				MilestoneManager.inst.CheckIrrigationMilestone();
			}
		}
	}

	private void LateUpdate()
	{
		if (LoadSave.Loading || !patchMapDirty)
		{
			return;
		}
		int num = World.inst.GridWidth * 2 + 1;
		DynamicWater.inst.UpdateWithPatchMap();
		DynamicLava.inst.UpdateWithPatchMap();
		for (int i = 0; i < framePatchMap.Length; i++)
		{
			if (framePatchMap[i] != 0f)
			{
				int x = i % num;
				int y = i / num;
				terrainHeightMap.SetPixel(x, y, new Color(terrainHeightMap.GetPixel(x, y).r + framePatchMap[i], 0f, 0f));
			}
		}
		terrainHeightMap.Apply();
		IJobParallelForExtensions.Schedule(new UpdateTextureParallelJob
		{
			HeightMap = terrainHeightMap.GetRawTextureData<float>(),
			SmoothedHeightMap = terrainHeightMapSmoothed.GetRawTextureData<float>(),
			Width = terrainHeightMap.width,
			Height = terrainHeightMap.height
		}, terrainHeightMap.width * terrainHeightMap.height, 64).Complete();
		terrainHeightMapSmoothed.Apply();
		ResetPatchMap();
	}

	private void FixDecorationHeight(int index)
	{
		World.inst.dryGrassSystem.SnapItemsToTerrain(index);
		World.inst.grassSystem.SnapItemsToTerrain(index);
		World.inst.bushesSystem.SnapItemsToTerrain(index);
		World.inst.treeSystem.SnapItemsToTerrain(index);
		World.inst.rockScatterSystem.SnapItemsToTerrain(index);
	}

	public void FixDecorationHeightsForAllCells()
	{
		int num = World.inst.GridWidth * World.inst.GridHeight;
		for (int i = 0; i < num; i++)
		{
			FixDecorationHeight(i);
		}
	}

	public void GridFade(float fade)
	{
		TerrainMaterial.SetFloat("_GridFade", fade);
	}

	public void PulseTerritory()
	{
		pulseTime = 0f;
		startPulse = true;
	}

	public void EditTerrainSimulateOn(bool on)
	{
		if (editTerrainSimulate && !on)
		{
			DoFertilityUpdate = (DoFertilityInstantBlend = true);
		}
		editTerrainSimulate = on;
	}

	public static float HeightModifierPoints(HeightModifier mod, float height)
	{
		if (mod.isEnabled == 0 || height < mod.threshold.x || height > mod.threshold.y)
		{
			return 0f;
		}
		if (mod.doNormal == 0)
		{
			return mod.heightPoints;
		}
		float num = Mathff.Clamp01(((height - mod.threshold.x) / (mod.threshold.y - mod.threshold.x) - mod.threshold.x) / (mod.threshold.y - mod.threshold.x));
		if (mod.isReverse != 1)
		{
			return num * mod.heightPoints;
		}
		return (1f - num) * mod.heightPoints;
	}

	public static float RiverModifierPoints(FertilityCell fCell, Vector4 LHD, float landDistanceOffset, int interpolationMethod, float closeRadius, float farRadius, float closePoints, float farPoints)
	{
		float num = (fCell.landDist - LHD.z) / (LHD.w - LHD.z);
		float num2 = Mathff.Max(0.175f, Mathff.Clamp01(landDistanceOffset - num) / landDistanceOffset);
		switch (interpolationMethod)
		{
		case 1:
			num2 *= num2;
			break;
		case 2:
			num2 = Mathf.Sqrt(num2);
			break;
		}
		if (fCell.dynamicWaterDist <= closeRadius * num2)
		{
			return closePoints;
		}
		if (fCell.dynamicWaterDist <= farRadius * num2)
		{
			return farPoints;
		}
		return 0f;
	}

	public float GetPaintNoiseForFertility(int x, int z, int fertility)
	{
		float num = fertility switch
		{
			1 => (FertileThreshold + VeryFertileThreshold) * 0.5f, 
			0 => FertileThreshold * 0.5f, 
			_ => VeryFertileThreshold + (VeryFertileThreshold - FertileThreshold) * 0.5f, 
		};
		float num2 = 0f;
		if (EnableModifiers)
		{
			if (EnableHeightModifiers)
			{
				float vertY = GetVertY(x * 2 + 1, z * 2 + 1);
				HeightModifier[] heightModifiers = HeightModifiers;
				foreach (HeightModifier mod in heightModifiers)
				{
					num2 += HeightModifierPoints(mod, vertY);
				}
			}
			FertilityCell fCell = FertilityCells[z * xSize + x];
			if (EnableRiverModifiers && fCell.gradeLandmass != -1)
			{
				num2 += RiverModifierPoints(fCell, LandmassHeightDistance[fCell.gradeLandmass], LandDistanceOffset, RiverInterpolationMethod, WaterCloseRadius, WaterFarRadius, WaterClosePoints, WaterFarPoints);
			}
		}
		return (num - num2) / NoisePoints;
	}

	private void UpdateFertilityHeightModifiers()
	{
		if (!RawHeightModifiers.IsCreated)
		{
			RawHeightModifiers = new NativeArray<HeightModifier>(HeightModifiers, Allocator.Persistent);
		}
		else if (RawHeightModifiers.Length != HeightModifiers.Length)
		{
			RawHeightModifiers.Dispose();
			RawHeightModifiers = new NativeArray<HeightModifier>(HeightModifiers, Allocator.Persistent);
		}
		else
		{
			RawHeightModifiers.CopyFrom(HeightModifiers);
		}
	}

	public void GenerateFertilityNoise()
	{
		if (!Application.isPlaying)
		{
			return;
		}
		isFertilityNoiseDirty = true;
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		Color[] array = null;
		Color[] array2 = null;
		Color[] array3 = null;
		if (EnableTextures)
		{
			if (HighNoiseTexture == null)
			{
				HighNoiseTexture = new Texture2D(num, num2, TextureFormat.RGFloat, mipChain: false);
				HighNoiseTexture.name = "TerrainHighNoise";
			}
			else if (HighNoiseTexture.width != num || HighNoiseTexture.height != num2)
			{
				HighNoiseTexture.Reinitialize(num, num2);
			}
			if (LowNoiseTexture == null)
			{
				LowNoiseTexture = new Texture2D(num, num2, TextureFormat.RGFloat, mipChain: false);
				LowNoiseTexture.name = "TerrainLowNoise";
			}
			else if (LowNoiseTexture.width != num || LowNoiseTexture.height != num2)
			{
				LowNoiseTexture.Reinitialize(num, num2);
			}
			if (NoiseTexture == null)
			{
				NoiseTexture = new Texture2D(num, num2, TextureFormat.RGFloat, mipChain: false);
				NoiseTexture.name = "TerrainNoise";
			}
			else if (NoiseTexture.width != num || NoiseTexture.height != num2)
			{
				NoiseTexture.Reinitialize(num, num2);
			}
			array = HighNoiseTexture.GetPixels();
			array2 = LowNoiseTexture.GetPixels();
			array3 = NoiseTexture.GetPixels();
		}
		else
		{
			HighNoiseTexture = null;
			LowNoiseTexture = null;
			NoiseTexture = null;
		}
		if (RawFertilityNoise == null || RawFertilityNoise.Length != num * num2)
		{
			RawFertilityNoise = new float[num * num2];
		}
		Color color = new Color(0f, 0f, 0f, 1f);
		float num3 = SRand.Range(0f, 500f);
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num2; j++)
			{
				int num4 = i + j * num;
				float num5 = Mathf.PerlinNoise((float)i / (float)num * fertilityNoiseHigh + num3, (float)j / (float)num * fertilityNoiseHigh + num3);
				float num6 = Mathf.PerlinNoise((float)i / (float)num * fertilityNoiseLow + num3, (float)j / (float)num * fertilityNoiseLow + num3);
				float num7 = Mathff.Clamp01((num5 + num6) / 2f);
				RawFertilityNoise[num4] = num7;
				if (EnableTextures)
				{
					color.r = num5;
					array[num4] = color;
					color.r = num6;
					array2[num4] = color;
					color.r = num7;
					array3[num4] = color;
				}
			}
		}
		if (EnableTextures)
		{
			HighNoiseTexture.SetPixels(array);
			HighNoiseTexture.Apply();
			LowNoiseTexture.SetPixels(array2);
			LowNoiseTexture.Apply();
			NoiseTexture.SetPixels(array3);
			NoiseTexture.Apply();
		}
	}

	public float GetFertilityNoiseForCell(int x, int z)
	{
		if (RawFertilityNoise == null)
		{
			return 0f;
		}
		int num = (z * 2 + 1) * (xSize * 2 + 1) + (x * 2 + 1);
		if (num < 0 || num >= RawFertilityNoise.Length)
		{
			return 0f;
		}
		return RawFertilityNoise[num];
	}

	public void SetFertilityNoiseForCell(int x, int z, float noise)
	{
		if (RawFertilityNoise != null)
		{
			int num = (z * 2 + 1) * (xSize * 2 + 1) + (x * 2 + 1);
			if (num >= 0 && num < RawFertilityNoise.Length)
			{
				RawFertilityNoise[num] = noise;
				isFertilityNoiseDirty = true;
				DoFertilityUpdate = true;
			}
		}
	}

	public void UpdateFertility(bool doInstantBlend = false)
	{
		NativeArray<Color> rawTextureData = Water.inst.distanceDynamicWaterTextureFinished.GetRawTextureData<Color>();
		if (rawTextureData.Length == World.inst.GridWidth * World.inst.GridHeight)
		{
			fertilityCurrUpdateTime = 0f;
			DoFertilityUpdate = false;
			doInstantBlend |= DoFertilityInstantBlend;
			DoFertilityInstantBlend = false;
			CellHeights.CopyFrom(heightCache);
			if (isFertilityNoiseDirty)
			{
				isFertilityNoiseDirty = false;
				FertilityNoise.CopyFrom(RawFertilityNoise);
			}
			for (int i = 0; i < LandmassHeightDistance.Length; i++)
			{
				LandmassHeightDistance[i] = new Vector4(float.MaxValue, float.MinValue, float.MaxValue, float.MinValue);
			}
			fertilityJob = IJobForExtensions.ScheduleParallel(new AggregateFertilityInformationJob
			{
				GridWidth = World.inst.GridWidth,
				DynamicWaterDistance = rawTextureData,
				LandDistance = Water.inst.distanceSDFTexture.GetRawTextureData<half4>(),
				CellHeights = CellHeights,
				FertilityCells = FertilityCells
			}, World.inst.GridWidth * World.inst.GridHeight, 512, default);
			fertilityJob.Complete();
			IJobForExtensions.Schedule(new LandmassHeightDistanceJob
			{
				FertilityCells = FertilityCells,
				LandmassHeightDistance = LandmassHeightDistance
			}, World.inst.GridWidth * World.inst.GridHeight, default).Complete();
			IJobForExtensions.ScheduleParallel(new FertilityJob
			{
				GridWidth = World.inst.GridWidth,
				NoisePoints = NoisePoints,
				EnableModifiers = EnableModifiers,
				EnableHeightModifiers = EnableHeightModifiers,
				HeightModifiers = RawHeightModifiers,
				EnableRiverModifiers = EnableRiverModifiers,
				RiverInterpolationMethod = RiverInterpolationMethod,
				LandDistanceOffset = LandDistanceOffset,
				WaterCloseRadius = ((SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.Drought) ? (WaterCloseRadius * 0.65f) : WaterCloseRadius),
				WaterFarRadius = ((SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.Drought) ? (WaterFarRadius * 0.4f) : WaterFarRadius),
				WaterClosePoints = WaterClosePoints,
				WaterFarPoints = WaterFarPoints,
				VeryFertileThreshold = VeryFertileThreshold,
				FertileThreshold = FertileThreshold,
				FertilityNoise = FertilityNoise,
				LandmassHeightDistance = LandmassHeightDistance,
				CurrentTime = FertilityBlendTime,
				BlendTime = FertilityBlendDuration,
				doInstantBlend = doInstantBlend,
				FertilityCells = FertilityCells,
				RawFertility = RawFertility,
				IsFertilityDirty = IsFertilityDirty,
				CurrentTileTextureIndices = CurrentTileTextureIndices,
				CurrFertilityColors = currFertilityTexture.GetRawTextureData<Vector2>(),
				CurrBlendWeights = currBlendWeightsTexture.GetRawTextureData<Vector4>(),
				PrevBlendWeights = prevBlendWeightsTexture.GetRawTextureData<Vector4>(),
				FertilityBlendEndTimes = fertilityBlendEndTexture.GetRawTextureData<float>()
			}, World.inst.GridWidth * World.inst.GridHeight, World.inst.GridWidth * World.inst.GridHeight / 8, fertilityJob).Complete();
			TerrainMaterial.SetFloat("_FertilityBlendDuration", doInstantBlend ? 0f : FertilityBlendDuration);
			TerrainFlatMaterial.SetFloat("_FertilityBlendDuration", doInstantBlend ? 0f : FertilityBlendDuration);
			currFertilityTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
			currBlendWeightsTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
			prevBlendWeightsTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
			fertilityBlendEndTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
			RawFertility.CopyTo(Fertility);
		}
	}

	private static Vector4 OneHotBlendWeightsFromTileIndex(int tileTextureIdx)
	{
		return tileTextureIdx switch
		{
			0 => new Vector4(1f, 0f, 0f, 0f), 
			1 => new Vector4(0f, 1f, 0f, 0f), 
			2 => new Vector4(0f, 0f, 1f, 0f), 
			3 => new Vector4(0f, 0f, 0f, 1f), 
			_ => Vector4.zero, 
		};
	}

	public bool RebuildBlendWeightTexturesFromCurrFertility()
	{
		bool result = false;
		NativeArray<Vector2> rawTextureData = currFertilityTexture.GetRawTextureData<Vector2>();
		NativeArray<Vector4> rawTextureData2 = currBlendWeightsTexture.GetRawTextureData<Vector4>();
		NativeArray<Vector4> rawTextureData3 = prevBlendWeightsTexture.GetRawTextureData<Vector4>();
		NativeArray<float> rawTextureData4 = fertilityBlendEndTexture.GetRawTextureData<float>();
		for (int i = 0; i < rawTextureData.Length; i++)
		{
			int num = Mathf.RoundToInt(rawTextureData[i].x);
			if (num > 3)
			{
				num = 2;
				rawTextureData[i] = new Vector2(num, rawTextureData[i].y);
				result = true;
			}
			Vector4 value = (rawTextureData2[i] = OneHotBlendWeightsFromTileIndex(num));
			rawTextureData3[i] = value;
			rawTextureData4[i] = rawTextureData[i].y;
			if (CurrentTileTextureIndices.IsCreated && i < CurrentTileTextureIndices.Length)
			{
				CurrentTileTextureIndices[i] = num;
			}
			if (IsFertilityDirty.IsCreated && i < IsFertilityDirty.Length)
			{
				IsFertilityDirty[i] = false;
			}
		}
		currFertilityTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
		currBlendWeightsTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
		prevBlendWeightsTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
		fertilityBlendEndTexture.Apply(updateMipmaps: false, makeNoLongerReadable: false);
		return result;
	}

	public void StartTerritoryTexture(int mode, int landmass)
	{
		isInitialTextureComplete = false;
		prevTerritoryMode = currTerritoryMode;
		currTerritoryMode = mode;
		currTerritoryLandmass = landmass;
		StartTerritoryTextureJob();
	}

	public void StopTerritoryTexture()
	{
		prevTerritoryMode = currTerritoryMode;
		currTerritoryMode = -1;
		currTerritoryLandmass = -1;
	}

	public void CompleteTerritoryTextureJob()
	{
		CurrentTerritoryTextureJob.Complete();
	}

	public void StartTerritoryTextureJob()
	{
		if (currTerritoryMode == -1)
		{
			return;
		}
		CurrentTerritoryTextureJob.Complete();
		SimplifiedWaterGrid.CopyFrom(DynamicWater.inst.simplifiedWaterGrid);
		int gridWidth = World.inst.GridWidth;
		foreach (Cell dirtyTerritoryCell in dirtyTerritoryCells)
		{
			if (dirtyTerritoryCell != null)
			{
				int num = dirtyTerritoryCell.x + dirtyTerritoryCell.z * gridWidth;
				TerritoryCell value = TerritoryCells[num];
				value.roadCoverage = dirtyTerritoryCell.GetRoadCoverage();
				value.hasFish = FishSystem.inst.fishCells[num].owners.Count > 0;
				TerritoryCells[num] = value;
			}
		}
		dirtyTerritoryCells.Clear();
		TerritoryTextureJob jobData = new TerritoryTextureJob
		{
			InputTerritoryCells = TerritoryCells,
			InputWaterCells = SimplifiedWaterGrid,
			InputDynamicWaterDistance = Water.inst.distanceDynamicWaterTextureFinished.GetRawTextureData<Color>(),
			Output = territoryTexture.GetRawTextureData<Vector2>(),
			MODE = currTerritoryMode,
			gridWidth = World.inst.GridWidth,
			gridHeight = World.inst.GridHeight,
			landmass = currTerritoryLandmass
		};
		isTerritoryTextureDirty = true;
		CurrentTerritoryTextureJob = IJobParallelForExtensions.Schedule(jobData, TerritoryCells.Length, 64);
	}

	public void RefreshCellLandmassCache()
	{
		CurrentTerritoryTextureJob.Complete();
		SetupTerrainGenCells(World.inst.GetCellsData());
		DoFertilityUpdate = true;
		DoFertilityInstantBlend = true;
	}

	private static int NeighbourLandmass(Cell c)
	{
		World.inst.GetNeighborCellsExtended(c, ref neighbourScratch);
		Cell[] array = neighbourScratch;
		foreach (Cell cell in array)
		{
			if (cell != null && cell.landMassIdx != -1 && cell.Type != TerrainType.Water)
			{
				return cell.landMassIdx;
			}
		}
		return -1;
	}

	public void SetupTerrainGenCells(Cell[] cellData)
	{
		dirtyTerritoryCells.Clear();
		if (Fertility == null || Fertility.Length != cellData.Length)
		{
			Fertility = new int[cellData.Length];
		}
		if (!RawFertility.IsCreated)
		{
			RawFertility = new NativeArray<int>(cellData.Length, Allocator.Persistent);
		}
		else if (RawFertility.Length != cellData.Length)
		{
			RawFertility.Dispose();
			RawFertility = new NativeArray<int>(cellData.Length, Allocator.Persistent);
		}
		if (!IsFertilityDirty.IsCreated)
		{
			IsFertilityDirty = new NativeArray<bool>(cellData.Length, Allocator.Persistent);
		}
		else if (IsFertilityDirty.Length != cellData.Length)
		{
			IsFertilityDirty.Dispose();
			IsFertilityDirty = new NativeArray<bool>(cellData.Length, Allocator.Persistent);
		}
		if (!CurrentTileTextureIndices.IsCreated)
		{
			CurrentTileTextureIndices = new NativeArray<int>(cellData.Length, Allocator.Persistent);
		}
		else if (CurrentTileTextureIndices.Length != cellData.Length)
		{
			CurrentTileTextureIndices.Dispose();
			CurrentTileTextureIndices = new NativeArray<int>(cellData.Length, Allocator.Persistent);
		}
		for (int i = 0; i < CurrentTileTextureIndices.Length; i++)
		{
			CurrentTileTextureIndices[i] = -1;
		}
		if (!LandmassHeightDistance.IsCreated)
		{
			LandmassHeightDistance = new NativeArray<Vector4>(World.inst.NumLandMasses, Allocator.Persistent);
		}
		else if (LandmassHeightDistance.Length != World.inst.NumLandMasses)
		{
			LandmassHeightDistance.Dispose();
			LandmassHeightDistance = new NativeArray<Vector4>(World.inst.NumLandMasses, Allocator.Persistent);
		}
		for (int j = 0; j < cellData.Length; j++)
		{
			Cell cell = cellData[j];
			TerritoryCell value = new TerritoryCell
			{
				landmass = cell.landMassIdx,
				x = cell.x,
				z = cell.z,
				roadCoverage = cell.GetRoadCoverage(),
				hasFish = (FishSystem.inst.fishCells[j].owners.Count > 0),
				type = cell.Type,
				terrainResourceID = ((cell.terrainResource != null) ? cell.terrainResource.resourceID : (-1))
			};
			FertilityCell value2 = new FertilityCell
			{
				landmass = cell.landMassIdx,
				gradeLandmass = ((cell.landMassIdx != -1) ? cell.landMassIdx : NeighbourLandmass(cell)),
				x = cell.x,
				z = cell.z
			};
			TerritoryCells[j] = value;
			FertilityCells[j] = value2;
		}
		Util.Memset(Fertility, 0);
	}

	public void UpdateCursorPosition(Vector4 packedCursorInfo)
	{
		TerrainMaterial.SetVector("_Cursor", packedCursorInfo);
		staticWaterMaterial.SetVector("_Cursor", packedCursorInfo);
	}

	public void UpdateCursorColor(Color color)
	{
		TerrainMaterial.SetColor("_CursorColor", color);
		staticWaterMaterial.SetColor("_CursorColor", color);
	}

	public void UpdateDimensions()
	{
		Vector4 value = new Vector4(transform.position.x, transform.position.z, World.inst.GridWidth, World.inst.GridHeight);
		Shader.SetGlobalVector("_TerrainDimensions", value);
	}

	public void ResetPatchMap()
	{
		if (patchMapDirty)
		{
			Array.Clear(framePatchMap, 0, framePatchMap.Length);
			patchMapDirty = false;
		}
	}

	public void CaptureOriginalHeights()
	{
		if (heightCache != null)
		{
			originalHeightCache = new float[heightCache.Length];
			Array.Copy(heightCache, originalHeightCache, heightCache.Length);
		}
	}

	public void SetBridgeHeight(int meshX, int meshZ, float walkHeight)
	{
		if (bridgeHeightCache != null && heightCache != null && meshX >= 0 && meshZ >= 0 && meshX < World.MeshWidth && meshZ < World.MeshHeight)
		{
			int num = meshZ * World.MeshWidth + meshX;
			float num2 = heightCache[num];
			float num3 = Mathf.Max(0f, walkHeight - num2);
			bridgeHeightCache[num] = num3;
		}
	}

	public void ClearBridgeHeight(int meshX, int meshZ)
	{
		if (bridgeHeightCache != null && meshX >= 0 && meshZ >= 0 && meshX < World.MeshWidth && meshZ < World.MeshHeight)
		{
			bridgeHeightCache[meshZ * World.MeshWidth + meshX] = 0f;
		}
	}

	public void RecalcWaterObstructionForArea(int startX, int startZ, int sizeX, int sizeZ)
	{
		int num = startX * 2;
		int num2 = startZ * 2;
		int num3 = sizeX * 2 + 1;
		int num4 = sizeZ * 2 + 1;
		if (scratchMap.GetLength(0) < num3 || scratchMap.GetLength(1) < num4)
		{
			scratchMap = new float[num3, num4];
		}
		for (int i = 0; i < num3; i++)
		{
			for (int j = 0; j < num4; j++)
			{
				float x = (float)(num + i) * 0.5f;
				float z = (float)(num2 + j) * 0.5f;
				RaycastHit hitInfo;
				if (i == 0 || i == num3 - 1 || j == 0 || j == num4 - 1)
				{
					scratchMap[i, j] = waterObstructionField[(num2 + j) * (World.inst.GridWidth * 2 + 1) + (num + i)];
				}
				else if (Physics.Raycast(new Ray(new Vector3(x, 100f, z), Vector3.down), out hitInfo, 150f, LayerMask.GetMask("Terrain")))
				{
					float num5 = Mathf.Max(0f, hitInfo.point.y - inst.GetInterpolatedHeight(hitInfo.point));
					scratchMap[i, j] = num5;
				}
			}
		}
		for (int k = startX; k < startX + sizeX; k++)
		{
			for (int l = startZ; l < startZ + sizeZ; l++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(k, l);
				bool flag = false;
				if (DamProjectManager.inst.IsCellPartOfProject(cellDataUnsafe, out var project) && project.cachedWaterObstructionPointsIndex != null)
				{
					for (int m = 0; m < project.cachedWaterObstructionPointsIndex.Length; m++)
					{
						if (project.cachedWaterObstructionPointsIndex[m] == cellDataUnsafe.index)
						{
							Vector3[] array = project.cachedWaterObstructionPoints[m];
							for (int n = 0; n < array.Length; n++)
							{
								Vector3 p = array[n];
								Vector2Int vector2Int = new Vector2Int(Mathf.RoundToInt(p.x * 2f), Mathf.RoundToInt(p.z * 2f));
								int num6 = vector2Int.x - num;
								int num7 = vector2Int.y - num2;
								scratchMap[num6, num7] = Mathf.Max(scratchMap[num6, num7], p.y - inst.GetInterpolatedHeight(p));
							}
							flag = true;
							break;
						}
					}
				}
				if (flag)
				{
					continue;
				}
				BlockBuilding blockBuilding = null;
				for (int num8 = cellDataUnsafe.OccupyingStructure.Count - 1; num8 >= 0; num8--)
				{
					BlockBuilding component = cellDataUnsafe.OccupyingStructure[num8].GetComponent<BlockBuilding>();
					if (component != null && !component.ignoreForLayout && component.b.IsBuilt())
					{
						blockBuilding = component;
						break;
					}
				}
				if (blockBuilding != null)
				{
					BlockBuilding blockBuilding2 = blockBuilding;
					int waterObstructionWorldPointCount = blockBuilding2.waterObstructionWorldPointCount;
					Vector3[] waterObstructionWorldPoints = blockBuilding2.waterObstructionWorldPoints;
					Transform[] waterObstructionActive = blockBuilding2.WaterObstructionActive;
					int num9 = ((waterObstructionWorldPointCount > 0) ? waterObstructionWorldPointCount : (waterObstructionActive?.Length ?? 0));
					for (int num10 = 0; num10 < num9; num10++)
					{
						Vector3 p2 = ((waterObstructionWorldPointCount > 0) ? waterObstructionWorldPoints[num10] : waterObstructionActive[num10].position);
						Vector2Int vector2Int2 = new Vector2Int(Mathf.RoundToInt(p2.x * 2f), Mathf.RoundToInt(p2.z * 2f));
						int num11 = vector2Int2.x - num;
						int num12 = vector2Int2.y - num2;
						scratchMap[num11, num12] = Mathf.Max(scratchMap[num11, num12], p2.y - inst.GetInterpolatedHeight(p2));
					}
				}
				Building building = cellDataUnsafe.StructureFind<Spillover>();
				if (building != null && (building.IsBuilt() || !LoadSave.Loading))
				{
					Spillover component2 = building.GetComponent<Spillover>();
					int meshIndexForDoor = component2.meshIndexForDoor;
					int num13 = meshIndexForDoor % World.MeshWidth - num;
					int num14 = meshIndexForDoor / World.MeshWidth - num2;
					scratchMap[num13, num14] = component2.obstructionHeight;
				}
			}
		}
		DynamicWater.inst.dynamicWaterJobHandle.Complete();
		for (int num15 = 0; num15 < num3; num15++)
		{
			for (int num16 = 0; num16 < num4; num16++)
			{
				int index = num + num15 + (num2 + num16) * World.MeshWidth;
				int num17 = num + num15 + (num2 + num16) * (World.inst.GridWidth * 2 + 1);
				float num18 = waterObstructionField[num17];
				float num19 = scratchMap[num15, num16];
				float num20 = Mathf.Max(0f, num19 - num18);
				DynamicWater.WaterCell value = DynamicWater.inst.waterGrid[index];
				value.waterAmount -= num20;
				if (value.waterAmount < 0f)
				{
					value.waterAmount = 0f;
				}
				DynamicWater.inst.waterGrid[index] = value;
				waterObstructionField[num17] = num19;
			}
		}
	}

	public void InitializeTerrainMeshes(int xSize, int zSize)
	{
		this.xSize = xSize;
		this.zSize = zSize;
		if (territoryTexture == null)
		{
			currFertilityTexture = new Texture2D(xSize, zSize, TextureFormat.RGFloat, mipChain: false, linear: false);
			currFertilityTexture.name = "TerrainFertilityCurrent";
			currFertilityTexture.filterMode = FilterMode.Point;
			currFertilityTexture.wrapMode = TextureWrapMode.Clamp;
			currBlendWeightsTexture = new Texture2D(xSize, zSize, TextureFormat.RGBAFloat, mipChain: false, linear: true);
			currBlendWeightsTexture.name = "TerrainBlendWeightsCurrent";
			currBlendWeightsTexture.filterMode = FilterMode.Bilinear;
			currBlendWeightsTexture.wrapMode = TextureWrapMode.Clamp;
			prevBlendWeightsTexture = new Texture2D(xSize, zSize, TextureFormat.RGBAFloat, mipChain: false, linear: true);
			prevBlendWeightsTexture.name = "TerrainBlendWeightsPrevious";
			prevBlendWeightsTexture.filterMode = FilterMode.Bilinear;
			prevBlendWeightsTexture.wrapMode = TextureWrapMode.Clamp;
			fertilityBlendEndTexture = new Texture2D(xSize, zSize, TextureFormat.RFloat, mipChain: false, linear: true);
			fertilityBlendEndTexture.name = "TerrainBlendEnd";
			fertilityBlendEndTexture.filterMode = FilterMode.Point;
			fertilityBlendEndTexture.wrapMode = TextureWrapMode.Clamp;
			terrainColorRenderTexture = new RenderTexture(xSize, zSize, 0, GraphicsFormat.R32G32B32A32_SFloat);
			terrainColorRenderTexture.name = "TerrainColorRT";
			terrainColorRenderTexture.filterMode = FilterMode.Bilinear;
			territoryTexture = new Texture2D(xSize, zSize, TextureFormat.RGFloat, mipChain: false);
			territoryTexture.name = "TerritoryTexture";
			territoryTexture.filterMode = FilterMode.Point;
			overlayTexture = new Texture2D(xSize * 2, zSize * 2, TextureFormat.ARGB32, mipChain: false);
			overlayTexture.name = "TerrainOverlay";
			overlayTexture.filterMode = FilterMode.Point;
			roadLocationTexture = new Texture2D(xSize, zSize, TextureFormat.ARGB32, mipChain: false);
			roadLocationTexture.name = "RoadLocationTexture";
			roadLocationTexture.filterMode = FilterMode.Bilinear;
			temporaryTerrainEffectsTexture = new Texture2D(xSize, zSize, TextureFormat.RGFloat, mipChain: false);
			temporaryTerrainEffectsTexture.name = "TerrainEffectsTemp";
			temporaryTerrainEffectsTexture.filterMode = FilterMode.Point;
			grassVisibilityTexture = new Texture2D(xSize * 2 + 1, zSize * 2 + 1, TextureFormat.RFloat, mipChain: false);
			grassVisibilityTexture.name = "GrassVisibility";
			grassVisibilityTexture.filterMode = FilterMode.Point;
			terrainHeightMap = new Texture2D(xSize * 2 + 1, zSize * 2 + 1, TextureFormat.RFloat, mipChain: false);
			terrainHeightMap.name = "TerrainHeightMap";
			terrainHeightMap.filterMode = FilterMode.Bilinear;
			terrainHeightMap.wrapMode = TextureWrapMode.Clamp;
			terrainHeightMapSmoothed = new Texture2D(xSize * 2 + 1, zSize * 2 + 1, TextureFormat.RFloat, mipChain: false);
			terrainHeightMapSmoothed.name = "TerrainHeightMapSmoothed";
			terrainHeightMapSmoothed.filterMode = FilterMode.Bilinear;
			terrainHeightMapSmoothed.wrapMode = TextureWrapMode.Clamp;
			terrainHeightMapPreview = new Texture2D(xSize * 2 + 1, zSize * 2 + 1, TextureFormat.RFloat, mipChain: false);
			terrainHeightMapPreview.name = "TerrainHeightMapPreview";
			terrainHeightMapPreview.filterMode = FilterMode.Bilinear;
			terrainHeightMapPreview.wrapMode = TextureWrapMode.Clamp;
		}
		else
		{
			currFertilityTexture.Reinitialize(xSize, zSize);
			if (currBlendWeightsTexture == null)
			{
				currBlendWeightsTexture = new Texture2D(xSize, zSize, TextureFormat.RGBAFloat, mipChain: false, linear: true);
				currBlendWeightsTexture.name = "TerrainBlendWeightsCurrent";
			}
			else
			{
				currBlendWeightsTexture.Reinitialize(xSize, zSize, TextureFormat.RGBAFloat, hasMipMap: false);
			}
			currBlendWeightsTexture.filterMode = FilterMode.Bilinear;
			currBlendWeightsTexture.wrapMode = TextureWrapMode.Clamp;
			if (prevBlendWeightsTexture == null)
			{
				prevBlendWeightsTexture = new Texture2D(xSize, zSize, TextureFormat.RGBAFloat, mipChain: false, linear: true);
				prevBlendWeightsTexture.name = "TerrainBlendWeightsPrevious";
			}
			else
			{
				prevBlendWeightsTexture.Reinitialize(xSize, zSize, TextureFormat.RGBAFloat, hasMipMap: false);
			}
			prevBlendWeightsTexture.filterMode = FilterMode.Bilinear;
			prevBlendWeightsTexture.wrapMode = TextureWrapMode.Clamp;
			if (fertilityBlendEndTexture == null)
			{
				fertilityBlendEndTexture = new Texture2D(xSize, zSize, TextureFormat.RFloat, mipChain: false, linear: true);
				fertilityBlendEndTexture.name = "TerrainBlendEnd";
			}
			else
			{
				fertilityBlendEndTexture.Reinitialize(xSize, zSize, TextureFormat.RFloat, hasMipMap: false);
			}
			fertilityBlendEndTexture.filterMode = FilterMode.Point;
			fertilityBlendEndTexture.wrapMode = TextureWrapMode.Clamp;
			terrainColorRenderTexture.Release();
			terrainColorRenderTexture.width = xSize;
			terrainColorRenderTexture.height = zSize;
			terrainColorRenderTexture.Create();
			territoryTexture.Reinitialize(xSize, zSize);
			overlayTexture.Reinitialize(xSize * 2, zSize * 2);
			roadLocationTexture.Reinitialize(xSize, zSize);
			temporaryTerrainEffectsTexture.Reinitialize(xSize, zSize);
			grassVisibilityTexture.Reinitialize(xSize * 2 + 1, zSize * 2 + 1);
			terrainHeightMap.Reinitialize(xSize * 2 + 1, zSize * 2 + 1);
			terrainHeightMapSmoothed.Reinitialize(xSize * 2 + 1, zSize * 2 + 1);
			terrainHeightMapPreview.Reinitialize(xSize * 2 + 1, zSize * 2 + 1);
		}
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		dirtyVertMap = new bool[(xSize * 2 + 1) * (zSize * 2 + 1)];
		dirtyVertList.Clear();
		Shader.SetGlobalTexture("_TerrainHeightMap", terrainHeightMap);
		Shader.SetGlobalTexture("_TerrainHeightMapSmoothed", terrainHeightMapSmoothed);
		Shader.SetGlobalTexture("_TerrainHeightMapPreview", terrainHeightMapPreview);
		Color[] array = new Color[xSize * zSize];
		overlayPixels = new Color[xSize * 2 * zSize * 2];
		Color[] array2 = new Color[xSize * zSize];
		buildingsInOverlayMap = new bool[xSize * zSize];
		_ = Color.clear;
		_ = Color.white;
		Util.Memset(array2, 0);
		Util.Memset(array, byte.MaxValue);
		Util.Memset(overlayPixels, 0);
		territoryTexture.SetPixels(0, 0, xSize, zSize, array);
		overlayTexture.SetPixels(0, 0, xSize * 2, zSize * 2, overlayPixels);
		grassVisibilityTexture.SetPixels(0, 0, xSize * 2, zSize * 2, overlayPixels);
		roadLocationTexture.SetPixels(0, 0, xSize, zSize, array2);
		temporaryTerrainEffectsTexture.SetPixels(0, 0, xSize, zSize, array2);
		territoryTexture.Apply();
		overlayTexture.Apply();
		roadLocationTexture.Apply();
		temporaryTerrainEffectsTexture.Apply();
		grassVisibilityTexture.Apply();
		terrainPixels = terrainHeightMap.GetPixels();
		terrainPixelsPreview = terrainHeightMapPreview.GetPixels();
		for (int i = 0; i < num * num2; i++)
		{
			terrainPixelsPreview[i].r = 0f;
			terrainPixelsPreview[i].g = 0f;
			terrainPixelsPreview[i].b = 0f;
			terrainPixelsPreview[i].a = 0f;
		}
		terrainHeightMapPreview.SetPixels(terrainPixelsPreview);
		terrainHeightMapSmoothed.SetPixels(terrainPixelsPreview);
		terrainHeightMapPreview.Apply();
		if (!TerritoryCells.IsCreated)
		{
			TerritoryCells = new NativeArray<TerritoryCell>(xSize * zSize, Allocator.Persistent);
		}
		else if (TerritoryCells.Length != xSize * zSize)
		{
			TerritoryCells.Dispose();
			TerritoryCells = new NativeArray<TerritoryCell>(xSize * zSize, Allocator.Persistent);
		}
		if (!SimplifiedWaterGrid.IsCreated)
		{
			SimplifiedWaterGrid = new NativeArray<float>(xSize * zSize, Allocator.Persistent);
		}
		else if (SimplifiedWaterGrid.Length != xSize * zSize)
		{
			SimplifiedWaterGrid.Dispose();
			SimplifiedWaterGrid = new NativeArray<float>(xSize * zSize, Allocator.Persistent);
		}
		if (!FertilityNoise.IsCreated)
		{
			FertilityNoise = new NativeArray<float>(num * num2, Allocator.Persistent);
		}
		else if (FertilityNoise.Length != num * num2)
		{
			FertilityNoise.Dispose();
			FertilityNoise = new NativeArray<float>(num * num2, Allocator.Persistent);
		}
		if (!FertilityCells.IsCreated)
		{
			FertilityCells = new NativeArray<FertilityCell>(xSize * zSize, Allocator.Persistent);
		}
		else if (FertilityCells.Length != xSize * zSize)
		{
			FertilityCells.Dispose();
			FertilityCells = new NativeArray<FertilityCell>(xSize * zSize, Allocator.Persistent);
		}
		if (!CellHeights.IsCreated)
		{
			CellHeights = new NativeArray<float>(num * num2, Allocator.Persistent);
		}
		else if (CellHeights.Length != num * num2)
		{
			CellHeights.Dispose();
			CellHeights = new NativeArray<float>(num * num2, Allocator.Persistent);
		}
		GenerateFertilityNoise();
		foreach (TerrainChunk terrainChunk in terrainChunks)
		{
			if ((bool)terrainChunk)
			{
				UnityEngine.Object.DestroyImmediate(terrainChunk.gameObject);
			}
		}
		foreach (TerrainChunk waterChunk in waterChunks)
		{
			if ((bool)waterChunk)
			{
				UnityEngine.Object.DestroyImmediate(waterChunk.gameObject);
			}
		}
		foreach (TerrainChunk lavaChunk in lavaChunks)
		{
			if ((bool)lavaChunk)
			{
				UnityEngine.Object.DestroyImmediate(lavaChunk.gameObject);
			}
		}
		terrainChunks.Clear();
		waterChunks.Clear();
		lavaChunks.Clear();
		heightCache = new float[(xSize * 2 + 1) * (zSize * 2 + 1)];
		bridgeHeightCache = new float[heightCache.Length];
		framePatchMap = new float[(xSize * 2 + 1) * (zSize * 2 + 1)];
		waterObstructionField = new float[(xSize * 2 + 1) * (zSize * 2 + 1)];
		mountainObstructionField = new float[(xSize * 2 + 1) * (zSize * 2 + 1)];
		List<ChunksThatNeedMeshes> list = new List<ChunksThatNeedMeshes>();
		List<ChunksThatNeedMeshes> list2 = new List<ChunksThatNeedMeshes>();
		chunkWidth = Mathf.CeilToInt((float)xSize / (float)chunkSize);
		for (int j = 0; j < zSize; j += chunkSize)
		{
			for (int k = 0; k < xSize; k += chunkSize)
			{
				TerrainChunk component = UnityEngine.Object.Instantiate(chunkPrefab).GetComponent<TerrainChunk>();
				component.transform.SetParent(transform, worldPositionStays: false);
				component.name = "Chunk[" + k / chunkSize + "-" + j / chunkSize + "]";
				int num3 = Mathf.Min(chunkSize, xSize - k);
				int num4 = Mathf.Min(chunkSize, zSize - j);
				Vector2 uvStart = new Vector2((float)k / (float)xSize, (float)j / (float)zSize);
				Vector2 uvEnd = new Vector2((float)(k + num3) / (float)xSize, (float)(j + num4) / (float)zSize);
				list.Add(new ChunksThatNeedMeshes
				{
					chunk = component,
					sizeX = num3,
					sizeZ = num4,
					uvStart = uvStart,
					uvEnd = uvEnd
				});
				component.transform.position = new Vector3(k, 0f, j);
				component.Init(k * 2, j * 2, num3, num4, uvStart, uvEnd);
				component.meshRenderer.sharedMaterial = TerrainMaterial;
				component.meshRenderer.shadowCastingMode = ShadowCastingMode.On;
				component.gameObject.layer = LayerMask.NameToLayer("Terrain");
				terrainChunks.Add(component);
				TerrainChunk component2 = UnityEngine.Object.Instantiate(chunkPrefab).GetComponent<TerrainChunk>();
				component2.transform.SetParent(transform, worldPositionStays: false);
				component2.name = "WaterChunk[" + k / chunkSize + "-" + j / chunkSize + "]";
				int num5 = Mathf.Min(chunkSize, xSize - k);
				int num6 = Mathf.Min(chunkSize, zSize - j);
				Vector2 uvStart2 = new Vector2((float)k / (float)xSize, (float)j / (float)zSize);
				Vector2 uvEnd2 = new Vector2((float)(k + num5) / (float)xSize, (float)(j + num6) / (float)zSize);
				list2.Add(new ChunksThatNeedMeshes
				{
					chunk = component2,
					sizeX = num5,
					sizeZ = num6
				});
				component2.transform.position = new Vector3(k, -0f, j);
				component2.Init(k * 2, j * 2, num5, num6, uvStart2, uvEnd2);
				component2.meshRenderer.sharedMaterial = DynamicWaterMaterial;
				component2.meshRenderer.shadowCastingMode = ShadowCastingMode.Off;
				component2.gameObject.layer = LayerMask.NameToLayer("Default");
				waterChunks.Add(component2);
				TerrainChunk component3 = UnityEngine.Object.Instantiate(chunkPrefab).GetComponent<TerrainChunk>();
				component3.transform.SetParent(transform, worldPositionStays: false);
				component3.name = "LavaChunk[" + k / chunkSize + "-" + j / chunkSize + "]";
				int num7 = Mathf.Min(chunkSize, xSize - k);
				int num8 = Mathf.Min(chunkSize, zSize - j);
				Vector2 uvStart3 = new Vector2((float)k / (float)xSize, (float)j / (float)zSize);
				Vector2 uvEnd3 = new Vector2((float)(k + num7) / (float)xSize, (float)(j + num8) / (float)zSize);
				list2.Add(new ChunksThatNeedMeshes
				{
					chunk = component3,
					sizeX = num7,
					sizeZ = num8
				});
				component3.transform.position = new Vector3(k, -0f, j);
				component3.Init(k * 2, j * 2, num7, num8, uvStart3, uvEnd3);
				component3.meshRenderer.sharedMaterial = DynamicLavaMaterial;
				component3.meshRenderer.shadowCastingMode = ShadowCastingMode.Off;
				component3.gameObject.layer = LayerMask.NameToLayer("Default");
				component3.meshRenderer.enabled = false;
				lavaChunks.Add(component3);
			}
		}
		list.Insert(0, list2[0]);
		Mesh.MeshDataArray meshDataArray = Mesh.AllocateWritableMeshData(list.Count);
		Mesh mesh = null;
		CreateMeshesParallelJob jobData = new CreateMeshesParallelJob
		{
			meshDataArray = meshDataArray,
			attributes = new NativeArray<VertexAttributeDescriptor>(3, Allocator.TempJob)
		};
		jobData.attributes[0] = new VertexAttributeDescriptor(VertexAttribute.Position, VertexAttributeFormat.Float32, 3, 0);
		jobData.attributes[1] = new VertexAttributeDescriptor(VertexAttribute.Normal);
		jobData.attributes[2] = new VertexAttributeDescriptor(VertexAttribute.TexCoord0, VertexAttributeFormat.Float32, 2);
		jobData.xSize = new NativeArray<int>(list.Count, Allocator.TempJob);
		jobData.zSize = new NativeArray<int>(list.Count, Allocator.TempJob);
		jobData.uvStart = new NativeArray<Vector2>(list.Count, Allocator.TempJob);
		jobData.uvEnd = new NativeArray<Vector2>(list.Count, Allocator.TempJob);
		jobData.xSize.CopyFrom(list.Select((ChunksThatNeedMeshes x) => x.sizeX).ToArray());
		jobData.zSize.CopyFrom(list.Select((ChunksThatNeedMeshes x) => x.sizeZ).ToArray());
		jobData.uvStart.CopyFrom(list.Select((ChunksThatNeedMeshes x) => x.uvStart).ToArray());
		jobData.uvEnd.CopyFrom(list.Select((ChunksThatNeedMeshes x) => x.uvEnd).ToArray());
		IJobParallelForExtensions.Schedule(jobData, list.Count, 1).Complete();
		Mesh[] array3 = list.Select((ChunksThatNeedMeshes x) => x.chunk.GetComponent<MeshFilter>().mesh).ToArray();
		Mesh.ApplyAndDisposeWritableMeshData(jobData.meshDataArray, array3);
		mesh = array3[0];
		jobData.attributes.Dispose();
		jobData.xSize.Dispose();
		jobData.zSize.Dispose();
		jobData.uvStart.Dispose();
		jobData.uvEnd.Dispose();
		foreach (ChunksThatNeedMeshes item in list)
		{
			item.chunk.UpdateCPUVerts();
		}
		foreach (ChunksThatNeedMeshes item2 in list2)
		{
			item2.chunk.GetComponent<MeshFilter>().sharedMesh = mesh;
		}
		UpdateTextures();
		UpdateDimensions();
	}

	public void SetTerrainPixelColor(int x, int z, int type)
	{
		pixels[x + z * xSize] = new Color((float)type / 255f, 0f, 0f);
	}

	public void SetOverlayTileColorNoBuilding(int x, int z, Color col)
	{
		int num = x * 2;
		int num2 = z * 2;
		int num3 = xSize * 2;
		int num4 = num3 * num2;
		int num5 = num3 * (num2 + 1);
		overlayPixels[num4 + num] = col;
		overlayPixels[num4 + (num + 1)] = col;
		overlayPixels[num5 + num] = col;
		overlayPixels[num5 + (num + 1)] = col;
	}

	public void SetOverlayTileColor(int x, int z, Color col)
	{
		int num = x * 2;
		int num2 = z * 2;
		int num3 = xSize * 2;
		int num4 = num3 * num2;
		int num5 = num3 * (num2 + 1);
		overlayPixels[num4 + num] = col;
		overlayPixels[num4 + (num + 1)] = col;
		overlayPixels[num5 + num] = col;
		overlayPixels[num5 + (num + 1)] = col;
		Cell cellData = World.inst.GetCellData(x, z);
		if (cellData != null)
		{
			for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
			{
				cellData.OccupyingStructure[i].SetInfoColor(col * 0.5f);
				AddBuildingToOverlay(cellData.OccupyingStructure[i]);
			}
		}
	}

	public void SetOverlayTileColorOverlapCheck(int x, int z, Cell cell, Color cellCol, Color buildingCol, bool applyBuildingMaterial = true)
	{
		int num = x * 2;
		int num2 = z * 2;
		int num3 = xSize * 2;
		int num4 = num3 * num2;
		int num5 = num3 * (num2 + 1);
		overlayPixels[num4 + num] = cellCol;
		overlayPixels[num4 + (num + 1)] = cellCol;
		overlayPixels[num5 + num] = cellCol;
		overlayPixels[num5 + (num + 1)] = cellCol;
		bool flag = buildingsInOverlayMap[cell.index];
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			cell.OccupyingStructure[i].SetInfoColor(buildingCol, applyBuildingMaterial);
			if (!flag)
			{
				AddBuildingToOverlay(cell.OccupyingStructure[i]);
			}
		}
		buildingsInOverlayMap[cell.index] = true;
	}

	public void SetOverlayBuildingColorOverlapCheck(int x, int z, Cell cell, Color buildingCol, bool applyBuildingMaterial = true)
	{
		bool flag = buildingsInOverlayMap[cell.index];
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			cell.OccupyingStructure[i].SetInfoColor(buildingCol, applyBuildingMaterial);
			if (!flag)
			{
				AddBuildingToOverlay(cell.OccupyingStructure[i]);
			}
		}
		buildingsInOverlayMap[cell.index] = true;
	}

	public Color GetOverlayTileColor(int x, int z)
	{
		return overlayPixels[xSize * 2 * z * 2 + x * 2];
	}

	public void SetOverlayPixelColor(int x, int z, Color col)
	{
		overlayPixels[xSize * 2 * z + x] = col;
	}

	public Color GetOverlayPixelColor(int x, int z)
	{
		return overlayPixels[xSize * 2 * z + x];
	}

	public void SetFOWTexture(Texture2D fowTex)
	{
		TerrainMaterial.SetTexture("_FOWTex", fowTex);
	}

	public void UpdateTextures()
	{
		TerrainMaterial.SetTexture("_CurrBlendWeightsTex", currBlendWeightsTexture);
		TerrainMaterial.SetTexture("_PrevBlendWeightsTex", prevBlendWeightsTexture);
		TerrainMaterial.SetTexture("_FertilityBlendEndTex", fertilityBlendEndTexture);
		TerrainFlatMaterial.SetTexture("_CurrBlendWeightsTex", currBlendWeightsTexture);
		TerrainFlatMaterial.SetTexture("_PrevBlendWeightsTex", prevBlendWeightsTexture);
		TerrainFlatMaterial.SetTexture("_FertilityBlendEndTex", fertilityBlendEndTexture);
		TerrainMaterial.SetTexture("_RoadTex", roadLocationTexture);
		TerrainMaterial.SetTexture("_TempEffectTex", temporaryTerrainEffectsTexture);
		TerrainMaterial.SetTexture("_TerritoryTex", territoryTexture);
		staticWaterMaterial.SetTexture("_TerritoryTex", territoryTexture);
		for (int i = 0; i < TreeSystem.systems.Count; i++)
		{
			TreeSystem treeSystem = TreeSystem.systems[i];
			if (treeSystem.type == 1 && treeSystem.chunks != null)
			{
				for (int j = 0; j < treeSystem.chunks.Length; j++)
				{
					treeSystem.chunks[j].mat.SetTexture("_GrassVisibilityTex", grassVisibilityTexture);
				}
				treeSystem.animMaterial.SetTexture("_GrassVisibilityTex", grassVisibilityTexture);
			}
		}
		RebuildTerrainMap();
		RenderTerrainColors();
	}

	public static void RebuildTerrainMap()
	{
		if (inst.patchMapDirty)
		{
			if (DynamicWater.inst != null && DynamicWater.inst.waterHeightMap1 != null)
			{
				DynamicWater.inst.UpdateWithPatchMap();
				DynamicLava.inst.UpdateWithPatchMap();
			}
			inst.ResetPatchMap();
		}
		for (int i = 0; i < inst.heightCache.Length; i++)
		{
			inst.terrainPixels[i].r = inst.heightCache[i];
		}
		inst.terrainHeightMap.SetPixels(inst.terrainPixels);
		inst.terrainHeightMap.Apply();
		IJobParallelForExtensions.Schedule(new UpdateTextureParallelJob
		{
			HeightMap = inst.terrainHeightMap.GetRawTextureData<float>(),
			SmoothedHeightMap = inst.terrainHeightMapSmoothed.GetRawTextureData<float>(),
			Width = inst.terrainHeightMap.width,
			Height = inst.terrainHeightMap.height
		}, inst.terrainHeightMap.width * inst.terrainHeightMap.height, 64).Complete();
		inst.terrainHeightMapSmoothed.Apply();
	}

	public void UpdateOverlayTextures(float checkerSize = 8f, float lowOpacity = 0.65f, float highOpacity = 0.9f)
	{
		overlayTexture.SetPixels(0, 0, xSize * 2, zSize * 2, overlayPixels);
		overlayTexture.Apply();
		Shader.SetGlobalTexture("_OverlayTex", overlayTexture);
		TerrainMaterial.SetTexture("_OverlayTex", overlayTexture);
		TerrainMaterial.SetFloat("_CheckerSize", checkerSize);
		TerrainMaterial.SetFloat("_CheckerOpacityHigh", highOpacity);
		TerrainMaterial.SetFloat("_CheckerOpacityLow", lowOpacity);
		staticWaterMaterial.SetTexture("_OverlayTex", overlayTexture);
	}

	public void FinalizeChanges()
	{
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num2; j++)
			{
				SetVert(i, j, GetVertY(i, j), bakeDown: true);
			}
		}
		foreach (TerrainChunk terrainChunk in terrainChunks)
		{
			terrainChunk.FinalizeChanges();
			terrainChunk.dirtyVerts = false;
			Selector.UpdateTextureForChunkHeights(terrainChunk);
		}
		UpdateTextures();
	}

	public void MakeCrater(int cx, int cz, int innerRadius, int outerRadius, float depth)
	{
		cx = cx * 2 + 1;
		cz = cz * 2 + 1;
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		innerRadius *= 2;
		outerRadius *= 2;
		int num3 = Mathff.Clamp(cx - outerRadius, 0, num - 1);
		int num4 = Mathff.Clamp(cx + outerRadius, 0, num - 1);
		int num5 = Mathff.Clamp(cz - outerRadius, 0, num2 - 1);
		int num6 = Mathff.Clamp(cz + outerRadius, 0, num2 - 1);
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num5; j <= num6; j++)
			{
				float num7 = Mathff.DistXZ(new Vector3(i, 0f, j), new Vector3(cx, 0f, cz));
				float num8 = num7 / (float)innerRadius;
				if (num8 <= 1f)
				{
					float num9 = Mathf.Lerp(-0.5f, 0.25f, Mathf.Pow(num8, 4f)) * depth;
					SetVert(i, j, GetVertY(i, j) + num9);
					continue;
				}
				float num10 = ((float)outerRadius - num7) / (float)(outerRadius - innerRadius);
				if (num10 >= 0f && num10 <= 1f)
				{
					float num11 = Mathf.SmoothStep(0f, 0.25f, Mathf.Clamp01(num10)) * depth;
					SetVert(i, j, GetVertY(i, j) + num11);
				}
			}
		}
	}

	public void MakeSquareDepression(float cx, float cz, int offsetX, int offsetZ, int radiusMeshSpace, float depth, float minDepth = -0.23f)
	{
		cx = cx * 2f + 1f;
		cz = cz * 2f + 1f;
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		cx += (float)offsetX;
		cz += (float)offsetZ;
		int num3 = (int)Mathff.Clamp(cx - (float)radiusMeshSpace, 0f, num - 1);
		int num4 = (int)Mathff.Clamp(cx + (float)radiusMeshSpace, 0f, num - 1);
		int num5 = (int)Mathff.Clamp(cz - (float)radiusMeshSpace, 0f, num2 - 1);
		int num6 = (int)Mathff.Clamp(cz + (float)radiusMeshSpace, 0f, num2 - 1);
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num5; j <= num6; j++)
			{
				SetVert(i, j, Mathff.Max(GetVertY(i, j) - depth, minDepth), bakeDown: true);
			}
		}
	}

	public void MakeBump(int cx, int cz, int radius, float depth)
	{
		cx = cx * 2 + 1;
		cz = cz * 2 + 1;
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		radius *= 2;
		int num3 = Mathff.Clamp(cx - radius * 2, 0, num - 1);
		int num4 = Mathff.Clamp(cx + radius * 2, 0, num - 1);
		int num5 = Mathff.Clamp(cz - radius * 2, 0, num2 - 1);
		int num6 = Mathff.Clamp(cz + radius * 2, 0, num2 - 1);
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num5; j <= num6; j++)
			{
				float t = Mathff.DistXZ(new Vector3(i, 0f, j), new Vector3(cx, 0f, cz)) / (float)radius;
				float num7 = Mathf.SmoothStep(1f, 0f, t) * depth;
				SetVert(i, j, GetVertY(i, j) + num7);
			}
		}
	}

	public void AddShape()
	{
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num2; j++)
			{
				SetVert(i, j, GetVertY(i, j), bakeDown: true);
			}
		}
	}

	public void Smooth()
	{
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		for (int i = 1; i < num - 1; i++)
		{
			for (int j = 1; j < num2 - 1; j++)
			{
				float vertY = GetVertY(i, j);
				if (!(vertY <= waterHeightTestThresold))
				{
					float num3 = vertY;
					for (int k = 0; k < smoothOffsets.Length; k++)
					{
						num3 += GetVertY(i + smoothOffsets[k].x, j + smoothOffsets[k].z);
					}
					num3 /= (float)smoothOffsets.Length + 1f;
					SetVert(i, j, num3);
				}
			}
		}
	}

	public void SmoothRadius(int radius, float minHeight, float maxHeight)
	{
	}

	public void SmoothRadiusYLessThanWaterTestThreshold(int radius, float minHeight = float.MinValue, float maxHeight = float.MaxValue)
	{
		InputHeightCacheNativeArrayForSmoothing = new NativeArray<float>(heightCache, Allocator.TempJob);
		OutputHeightCacheNativeArrayForSmoothing = new NativeArray<float>(heightCache, Allocator.TempJob);
		new SmoothYLessThanWaterTestThresholdParallelJob
		{
			In = InputHeightCacheNativeArrayForSmoothing,
			Out = OutputHeightCacheNativeArrayForSmoothing,
			radius = radius,
			minHeight = minHeight,
			maxHeight = maxHeight,
			xSize = xSize,
			zSize = zSize,
			meshWidth = World.MeshWidth,
			waterHeightTestThresold = waterHeightTestThresold
		}.Schedule().Complete();
		OutputHeightCacheNativeArrayForSmoothing.CopyTo(heightCache);
		InputHeightCacheNativeArrayForSmoothing.Dispose();
		OutputHeightCacheNativeArrayForSmoothing.Dispose();
	}

	public void SmoothRadiusYGreaterThanWaterTestThreshold(int radius, float minHeight = float.MinValue, float maxHeight = float.MaxValue)
	{
		InputHeightCacheNativeArrayForSmoothing = new NativeArray<float>(heightCache, Allocator.TempJob);
		OutputHeightCacheNativeArrayForSmoothing = new NativeArray<float>(heightCache, Allocator.TempJob);
		new SmoothYGreaterThanWaterTestThresholdParallelJob
		{
			In = InputHeightCacheNativeArrayForSmoothing,
			Out = OutputHeightCacheNativeArrayForSmoothing,
			radius = radius,
			minHeight = minHeight,
			maxHeight = maxHeight,
			xSize = xSize,
			zSize = zSize,
			meshWidth = World.MeshWidth,
			waterHeightTestThresold = waterHeightTestThresold
		}.Schedule().Complete();
		OutputHeightCacheNativeArrayForSmoothing.CopyTo(heightCache);
		InputHeightCacheNativeArrayForSmoothing.Dispose();
		OutputHeightCacheNativeArrayForSmoothing.Dispose();
	}

	public void SmoothRadiusFunctionYGreaterThanWaterHeight(int radius, float minHeight = float.MinValue, float maxHeight = float.MaxValue)
	{
		InputHeightCacheNativeArrayForSmoothing = new NativeArray<float>(heightCache, Allocator.TempJob);
		OutputHeightCacheNativeArrayForSmoothing = new NativeArray<float>(heightCache, Allocator.TempJob);
		new SmoothYGreaterThanWaterHeightParallelJob
		{
			In = InputHeightCacheNativeArrayForSmoothing,
			Out = OutputHeightCacheNativeArrayForSmoothing,
			radius = radius,
			minHeight = minHeight,
			maxHeight = maxHeight,
			xSize = xSize,
			zSize = zSize,
			meshWidth = World.MeshWidth,
			waterHeight = Water.inst.transform.position.y
		}.Schedule().Complete();
		OutputHeightCacheNativeArrayForSmoothing.CopyTo(heightCache);
		InputHeightCacheNativeArrayForSmoothing.Dispose();
		OutputHeightCacheNativeArrayForSmoothing.Dispose();
	}

	public void AddNoise(Cell c)
	{
		int meshX = c.x * 2 + 1;
		int meshZ = c.z * 2 + 1;
		SetVert(meshX, meshZ, GetVertY(meshX, meshZ) + SRand.Range(0f - noiseIntensity, noiseIntensity), bakeDown: true);
	}

	public void AddNoise()
	{
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		int num3 = xSize * 2 + 1;
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num2; j++)
			{
				_ = heightCache[j * num3 + i];
				SetVert(i, j, GetVertY(i, j) + SRand.Range(0f - noiseIntensity, noiseIntensity));
			}
		}
	}

	public void GenerateWater(World.MapSize size)
	{
		World.MapBias generatedMapsBias = World.inst.generatedMapsBias;
		int num = 5;
		int num2 = World.inst.GridWidth - num * 2;
		int num3 = World.inst.GridHeight - num * 2;
		bool[] oceanTiles = new bool[num2 * num3];
		int[] landmassIdx = new int[num2 * num3];
		float[] height = new float[num2 * num3];
		islandInteriorBounds = null;
		int num4 = SRand.Range(1, 2);
		if (generatedMapsBias == World.MapBias.Island)
		{
			if (size == World.MapSize.Small)
			{
				num4 = 2;
			}
			if (size == World.MapSize.Medium)
			{
				num4 = SRand.Range(2, 4);
			}
			if (size == World.MapSize.Large)
			{
				num4 = SRand.Range(3, 6);
			}
		}
		new List<Vector3>();
		mountainPositions.Clear();
		mapGen.GenerateNewMap(num2, num3, ref oceanTiles, ref landmassIdx, ref height, ref mountainPositions, ref islandInteriorBounds, World.inst.mapSizeDefs[(int)size].DesiredTiles, num4, doLakes: false);
		for (int i = 0; i < World.inst.GridHeight; i++)
		{
			for (int j = 0; j < num; j++)
			{
				SetWaterTile(j, i);
				SetTileHeight(World.inst.GetCellData(j, i), -4f);
			}
			for (int k = World.inst.GridWidth - num; k < World.inst.GridWidth; k++)
			{
				SetWaterTile(k, i);
				SetTileHeight(World.inst.GetCellData(k, i), -4f);
			}
		}
		for (int l = 0; l < World.inst.GridWidth; l++)
		{
			for (int m = 0; m < num; m++)
			{
				SetWaterTile(l, m);
				SetTileHeight(World.inst.GetCellData(l, m), -4f);
			}
			for (int n = World.inst.GridHeight - num; n < World.inst.GridHeight; n++)
			{
				SetWaterTile(l, n);
				SetTileHeight(World.inst.GetCellData(l, n), -4f);
			}
		}
		for (int num5 = 0; num5 < num3; num5++)
		{
			for (int num6 = 0; num6 < num2; num6++)
			{
				if (oceanTiles[num5 * num2 + num6])
				{
					SetWaterTile(num6 + num, num5 + num, modifyHeight: false);
				}
				Cell cellData = World.inst.GetCellData(num6 + num, num5 + num);
				cellData.landMassIdx = landmassIdx[num5 * num2 + num6];
				SetTileHeight(cellData, 0.1f + height[num5 * num2 + num6]);
			}
		}
		SmoothRadiusYGreaterThanWaterTestThreshold(8, 0f);
		World.inst.InitLandmassData(num4);
		if (mountainContainer == null)
		{
			mountainContainer = new GameObject("Mountain Container").transform;
		}
		MountainPlacerWater.mountainWaterPositions.ClearFast();
		if (modifiedTerrain == null || modifiedTerrain.Length != World.inst.GridWidth * World.inst.GridHeight)
		{
			modifiedTerrain = new bool[World.inst.GridWidth * World.inst.GridHeight];
		}
		else
		{
			for (int num7 = 0; num7 < modifiedTerrain.Length; num7++)
			{
				modifiedTerrain[num7] = false;
			}
		}
		for (int num8 = 0; num8 < num4; num8++)
		{
			if (num8 >= MountainPlacerWater.mountainWaterPositions.Count)
			{
				MountainPlacerWater.mountainWaterPositions.Add(new ArrayExt<Vector3>(8));
			}
			else
			{
				MountainPlacerWater.mountainWaterPositions.data[num8].ClearFast();
			}
		}
		int num9 = 1;
		Vector3 dir = Vector3.zero;
		Vector3 pos = Vector3.zero;
		float area;
		int landmassIdx2;
		int groupCount;
		while (GetGroup(mountainPositions, num9, ref pos, ref dir, out area, out landmassIdx2, out groupCount))
		{
			num9++;
			int index = (int)(mapGen.GetMountainSizeFromArea(area) + 1);
			if (groupCount >= 3)
			{
				index = 0;
			}
			MountainPlacer mountainPlacer = UnityEngine.Object.Instantiate(edgeMountains[index].mountains[SRand.Range(0, edgeMountains[index].mountains.Count)], mountainContainer);
			Vector3 mPos = pos;
			mPos.y = 0f;
			if (!mountainPlacer.ShiftToShore(dir, ref mPos))
			{
				UnityEngine.Object.Destroy(mountainPlacer.gameObject);
				continue;
			}
			mountainPlacer.transform.position = mPos;
			if (mountainPlacer.Init(mPos, Quaternion.LookRotation(dir), landmassIdx2))
			{
				mountainRocks.Add(mountainPlacer.gameObject);
			}
		}
		for (int num10 = 0; num10 < mountainPositions.Count; num10++)
		{
			MountainData mountainData = mountainPositions[num10];
			MountainPlacer mountainPlacer2 = null;
			for (int num11 = (int)mountainData.size; num11 <= 2; num11++)
			{
				bool flag = false;
				int num12 = -1;
				int num13 = -1;
				int num14 = 0;
				do
				{
					if (mountainData.type == MountainData.Type.Exterior || mountainData.type == MountainData.Type.None)
					{
						flag = true;
						break;
					}
					if (mountainData.type == MountainData.Type.Interior)
					{
						Cell cellData2 = World.inst.GetCellData(mountainData.pos);
						if (cellData2 == null || cellData2.Type == TerrainType.Water || SRand.Range(0, 100) < 50)
						{
							flag = true;
							break;
						}
						if (num12 == -1)
						{
							num13 = interiorMountains[num11].mountains.Count;
							num12 = SRand.Range(0, num13);
						}
						mountainPlacer2 = interiorMountains[num11].mountains[num12];
					}
					else
					{
						if (mountainData.type != MountainData.Type.Corner)
						{
							flag = true;
							break;
						}
						if (num12 == -1)
						{
							num13 = cornerMountains[num11].mountains.Count;
							num12 = SRand.Range(0, num13);
						}
						mountainPlacer2 = cornerMountains[num11].mountains[num12];
					}
					num12 = (num12 + 1) % num13;
					num14++;
					if (!(mountainPlacer2 == null))
					{
						MountainPlacer mountainPlacer3 = UnityEngine.Object.Instantiate(mountainPlacer2, mountainContainer);
						Vector3 mPos2 = mountainPositions[num10].pos;
						mPos2.y = 0f;
						if (mountainPlacer3.doShiftToShore && !mountainPlacer3.ShiftToShore(mountainData.landDir, ref mPos2))
						{
							UnityEngine.Object.Destroy(mountainPlacer3.gameObject);
						}
						else if (mountainPlacer3.Init(mPos2, Quaternion.LookRotation(mountainPositions[num10].landDir), mountainData.landmassIdx))
						{
							mountainRocks.Add(mountainPlacer3.gameObject);
							flag = true;
						}
					}
				}
				while (num14 < num13 && !flag);
				if (flag)
				{
					break;
				}
			}
		}
		for (int num15 = 0; num15 < islandInteriorBounds.Length; num15++)
		{
			ArrayExt<Vector4> arrayExt = islandInteriorBounds[num15];
			for (int num16 = 0; num16 < arrayExt.Count; num16++)
			{
				float num17 = arrayExt.data[num16].y - arrayExt.data[num16].x;
				float num18 = arrayExt.data[num16].w - arrayExt.data[num16].z;
				if (num17 >= MaxInternalSize && num18 >= MinInternalSize)
				{
					Vector4 vector = arrayExt.data[num16];
					Vector4 item = arrayExt.data[num16];
					item.x = vector.x + num17 / 2f;
					vector.y = item.x;
					islandInteriorBounds[num15].data[num16] = vector;
					islandInteriorBounds[num15].Add(item);
				}
				else if (num17 >= MinInternalSize && num18 >= MaxInternalSize)
				{
					Vector4 vector2 = arrayExt.data[num16];
					Vector4 item2 = arrayExt.data[num16];
					item2.z = vector2.z + num18 / 2f;
					vector2.w = item2.z;
					islandInteriorBounds[num15].data[num16] = vector2;
					islandInteriorBounds[num15].Add(item2);
				}
			}
		}
		ArrayExt<int>[] array = new ArrayExt<int>[centerMountains.Count];
		for (int num19 = 0; num19 < array.Length; num19++)
		{
			array[num19] = new ArrayExt<int>(8);
		}
		centerMountainsStart = mountainRocks.Count;
		for (int num20 = 0; num20 < islandInteriorBounds.Length; num20++)
		{
			ArrayExt<Vector4> arrayExt2 = islandInteriorBounds[num20];
			for (int num21 = 0; num21 < array.Length; num21++)
			{
				array[num21].ClearFast();
			}
			for (int num22 = 0; num22 < arrayExt2.Count; num22++)
			{
				Vector4 vector3 = arrayExt2.data[num22];
				float num23 = (vector3[1] - vector3[0]) * (vector3[3] - vector3[2]);
				DebugEx.DrawBoxXZ(vector3.x, vector3.y, vector3.z, vector3.w, 1f, Color.magenta, 10f);
				int num24 = 0;
				if (num23 < 1000f && num23 > 150f)
				{
					num24 = 1;
				}
				else if (num23 <= 150f)
				{
					num24 = 2;
				}
				for (int num25 = num24; num25 < centerMountains.Count; num25++)
				{
					int num26 = SRand.Range(0, centerMountains[num25].mountains.Count);
					bool flag2 = false;
					for (int num27 = 0; num27 < centerMountains[num25].mountains.Count; num27++)
					{
						int num28 = (num26 + num27) % centerMountains[num25].mountains.Count;
						if (!array[num25].Contains(num28))
						{
							MountainPlacer mountainPlacer4 = UnityEngine.Object.Instantiate(centerMountains[num25].mountains[num28], mountainContainer);
							float num29 = vector3.y - vector3.x;
							float num30 = vector3.w - vector3.z;
							Vector3 vector4 = ((!(num29 > num30)) ? new Vector3(vector3.x + num29 / 2f, 0f, Mathff.Lerp(vector3.z, vector3.w, SRand.Range(0.1f, 0.9f))) : new Vector3(Mathff.Lerp(vector3.x, vector3.y, SRand.Range(0.1f, 0.9f)), 0f, vector3.z + num30 / 2f));
							DebugEx.DrawCircleXZ(vector4, 1f, Color.magenta, 16f, 10f);
							mountainPlacer4.transform.position = vector4;
							if (mountainPlacer4.Init(vector4, num20))
							{
								array[num25].Add(num28);
								mountainRocks.Add(mountainPlacer4.gameObject);
								flag2 = true;
								break;
							}
						}
					}
					if (flag2)
					{
						break;
					}
				}
			}
		}
		for (int num31 = 0; num31 < mountainRocks.Count; num31++)
		{
			mountainRocks[num31].GetComponent<MountainPlacer>().SubtractTerrain();
		}
		int targetAmt = 3;
		switch (World.inst.mapRiverAmount)
		{
		case World.MapRiverAmount.High:
		{
			int num32 = 0;
			for (int num33 = 0; num33 < MountainPlacerWater.mountainWaterPositions.Count; num33++)
			{
				num32 += MountainPlacerWater.mountainWaterPositions.data[num33].Count;
			}
			targetAmt = Mathff.Max((int)((float)num32 * 0.75f), 4);
			break;
		}
		case World.MapRiverAmount.VeryHigh:
			targetAmt = 999;
			break;
		}
		MountainPlacerWater.ProcessMountainWater(targetAmt, islandInteriorBounds);
		Physics.SyncTransforms();
	}

	private bool GetGroup(List<MountainData> data, int groupIdx, ref Vector3 pos, ref Vector3 dir, out float area, out int landmassIdx, out int groupCount)
	{
		landmassIdx = -1;
		area = 0f;
		pos.x = (pos.y = (pos.z = 0f));
		dir.x = (dir.y = (dir.z = 0f));
		groupCount = 0;
		for (int i = 0; i < data.Count; i++)
		{
			if (data[i].groupId == groupIdx && data[i].type == MountainData.Type.Edge)
			{
				if (landmassIdx == -1)
				{
					landmassIdx = data[i].landmassIdx;
				}
				pos += data[i].pos;
				dir += data[i].landDir;
				area += data[i].area;
				groupCount++;
			}
		}
		if (groupCount > 0)
		{
			pos /= (float)groupCount;
			dir /= (float)groupCount;
			return true;
		}
		return false;
	}

	private void MakeOcean(Direction dir)
	{
		float value = UnityEngine.Random.value;
		if (dir == Direction.South || dir == Direction.North)
		{
			for (int i = 0; i < xSize; i++)
			{
				int num = Mathf.FloorToInt(Mathf.PerlinNoise(value + (float)i / (float)xSize, 0f) * (float)(MaxOceanThickness - MinOceanThickness)) + MinOceanThickness;
				for (int j = 0; j < num; j++)
				{
					SetWaterTile(i, (dir == Direction.South) ? (zSize - j - 1) : j);
				}
			}
		}
		if (dir != Direction.West && dir != Direction.East)
		{
			return;
		}
		for (int k = 0; k < zSize; k++)
		{
			int num2 = Mathf.FloorToInt(Mathf.PerlinNoise(value + (float)k / (float)zSize, 0f) * (float)(MaxOceanThickness - MinOceanThickness)) + MinOceanThickness;
			for (int l = 0; l < num2; l++)
			{
				SetWaterTile((dir == Direction.East) ? (xSize - l - 1) : l, k);
			}
		}
	}

	public void SetFertileTile(int x, int z, int fertility)
	{
	}

	public void ClearMountains()
	{
		for (int i = 0; i < mountainRocks.Count; i++)
		{
			UnityEngine.Object.DestroyImmediate(mountainRocks[i].gameObject);
		}
		mountainRocks.Clear();
	}

	public void SetWaterTile(int x, int z, bool modifyHeight = true)
	{
		int num = x * 2 + 1;
		int num2 = z * 2 + 1;
		Cell cellData = World.inst.GetCellData(x, z);
		if (cellData.Type == TerrainType.Water || !ValidGridPos(x, z))
		{
			return;
		}
		cellData.Type = TerrainType.Water;
		if (modifyHeight)
		{
			SetVert(num, num2, waterHeightDeep);
			TryConnect(x, z, Direction.North);
			TryConnect(x, z, Direction.East);
			TryConnect(x, z, Direction.South);
			TryConnect(x, z, Direction.West);
			if (IsVertIsland(num - 1, num2 - 1))
			{
				SetVert(num - 1, num2 - 1, GetPerlinInGrid(num - 1, num2 - 1));
			}
			if (IsVertIsland(num + 1, num2 + 1))
			{
				SetVert(num + 1, num2 + 1, GetPerlinInGrid(num + 1, num2 + 1));
			}
			if (IsVertIsland(num - 1, num2 + 1))
			{
				SetVert(num - 1, num2 + 1, GetPerlinInGrid(num - 1, num2 + 1));
			}
			if (IsVertIsland(num + 1, num2 - 1))
			{
				SetVert(num + 1, num2 - 1, GetPerlinInGrid(num + 1, num2 - 1));
			}
		}
	}

	public float GetPerlinInGrid(int x, int z)
	{
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		return (Mathf.PerlinNoise((float)x / (float)num * 10f, (float)z / (float)num2 * 10f) - 1f) * 10f - 3f;
	}

	public void SetLandTile(int x, int z)
	{
		int num = x * 2 + 1;
		int num2 = z * 2 + 1;
		SetVert(num - 1, num2 - 1, 0f, bakeDown: true);
		SetVert(num, num2 - 1, 0f, bakeDown: true);
		SetVert(num + 1, num2 - 1, 0f, bakeDown: true);
		SetVert(num - 1, num2, 0f, bakeDown: true);
		SetVert(num, num2, 0f, bakeDown: true);
		SetVert(num + 1, num2, 0f, bakeDown: true);
		SetVert(num - 1, num2 + 1, 0f, bakeDown: true);
		SetVert(num, num2 + 1, 0f, bakeDown: true);
		SetVert(num + 1, num2 + 1, 0f, bakeDown: true);
	}

	private bool IsVertIsland(int gridX, int gridZ)
	{
		VertOutOfBounds(gridX, gridZ);
		if (!VertOutOfBounds(gridX, gridZ) && GetVertY(gridX, gridZ) == 0f)
		{
			if (!VertOutOfBounds(gridX - 1, gridZ) && GetVertY(gridX - 1, gridZ) > waterHeightTestThresold)
			{
				return false;
			}
			if (!VertOutOfBounds(gridX + 1, gridZ) && GetVertY(gridX + 1, gridZ) > waterHeightTestThresold)
			{
				return false;
			}
			if (!VertOutOfBounds(gridX, gridZ - 1) && GetVertY(gridX, gridZ - 1) > waterHeightTestThresold)
			{
				return false;
			}
			if (!VertOutOfBounds(gridX, gridZ + 1) && GetVertY(gridX, gridZ + 1) > waterHeightTestThresold)
			{
				return false;
			}
			return true;
		}
		return false;
	}

	private void TryConnect(int x, int z, Direction dir)
	{
		int num = 0;
		int num2 = 0;
		if (dir == Direction.North)
		{
			num = -1;
			num2 = 0;
		}
		if (dir == Direction.South)
		{
			num = 1;
			num2 = 0;
		}
		if (dir == Direction.East)
		{
			num = 0;
			num2 = 1;
		}
		if (dir == Direction.West)
		{
			num = 0;
			num2 = -1;
		}
		bool flag = false;
		if (!ValidGridPos(x + num, z + num2))
		{
			flag = true;
		}
		else if (IsWaterTile(x + num, z + num2))
		{
			flag = true;
		}
		if (flag)
		{
			int num3 = x * 2 + 1;
			int num4 = z * 2 + 1;
			SetVert(num3 + num, num4 + num2, GetPerlinInGrid(num3 + num, num4 + num2));
		}
	}

	private bool VertOutOfBounds(int gridX, int gridZ)
	{
		if (gridX >= 0 && gridX <= xSize * 2 && gridZ >= 0)
		{
			return gridZ > zSize * 2;
		}
		return true;
	}

	public bool IsWaterTile(int x, int z)
	{
		if (ValidGridPos(x, z))
		{
			int meshX = x * 2 + 1;
			int meshZ = z * 2 + 1;
			return GetVertY(meshX, meshZ) <= waterHeightTestThresold;
		}
		return true;
	}

	private bool ValidGridPos(int x, int z)
	{
		if (x >= 0 && x < xSize && z >= 0)
		{
			return z < zSize;
		}
		return false;
	}

	public void SoftDepressTile(Cell cell, float depressAmount)
	{
		int num = cell.x * 2 + 1;
		int num2 = cell.z * 2 + 1;
		SetVert(num, num2, heightCache[num + num2 * (xSize * 2 + 1)] + depressAmount, bakeDown: true);
		SetVert(num + 1, num2, heightCache[num + 1 + num2 * (xSize * 2 + 1)] + depressAmount / 2f, bakeDown: true);
		SetVert(num + 1, num2 + 1, heightCache[num + 1 + (num2 + 1) * (xSize * 2 + 1)] + depressAmount / 4f, bakeDown: true);
		SetVert(num, num2 + 1, heightCache[num + (num2 + 1) * (xSize * 2 + 1)] + depressAmount / 2f, bakeDown: true);
		SetVert(num - 1, num2 + 1, heightCache[num - 1 + (num2 + 1) * (xSize * 2 + 1)] + depressAmount / 4f, bakeDown: true);
		SetVert(num - 1, num2, heightCache[num - 1 + num2 * (xSize * 2 + 1)] + depressAmount / 2f, bakeDown: true);
		SetVert(num - 1, num2 - 1, heightCache[num - 1 + (num2 - 1) * (xSize * 2 + 1)] + depressAmount / 4f, bakeDown: true);
		SetVert(num, num2 - 1, heightCache[num + (num2 - 1) * (xSize * 2 + 1)] + depressAmount / 2f, bakeDown: true);
		SetVert(num + 1, num2 - 1, heightCache[num + 1 + (num2 - 1) * (xSize * 2 + 1)] + depressAmount / 4f, bakeDown: true);
	}

	public void SoftDepressMesh(int x, int z, float strength)
	{
		SetVert(x, z, heightCache[x + z * (xSize * 2 + 1)] + strength, bakeDown: true);
		SetVert(x + 1, z, heightCache[x + 1 + z * (xSize * 2 + 1)] + strength / 2f, bakeDown: true);
		SetVert(x + 1, z + 1, heightCache[x + 1 + (z + 1) * (xSize * 2 + 1)] + strength / 4f, bakeDown: true);
		SetVert(x, z + 1, heightCache[x + (z + 1) * (xSize * 2 + 1)] + strength / 2f, bakeDown: true);
		SetVert(x - 1, z + 1, heightCache[x - 1 + (z + 1) * (xSize * 2 + 1)] + strength / 4f, bakeDown: true);
		SetVert(x - 1, z, heightCache[x - 1 + z * (xSize * 2 + 1)] + strength / 2f, bakeDown: true);
		SetVert(x - 1, z - 1, heightCache[x - 1 + (z - 1) * (xSize * 2 + 1)] + strength / 4f, bakeDown: true);
		SetVert(x, z - 1, heightCache[x + (z - 1) * (xSize * 2 + 1)] + strength / 2f, bakeDown: true);
		SetVert(x + 1, z - 1, heightCache[x + 1 + (z - 1) * (xSize * 2 + 1)] + strength / 4f, bakeDown: true);
	}

	public void SetBakedTileHeight(int cx, int cz, float height)
	{
		int num = cx * 2 + 1;
		int num2 = cz * 2 + 1;
		SetVert(num, num2, height, bakeDown: true);
		SetVert(num + 1, num2, height, bakeDown: true);
		SetVert(num + 1, num2 + 1, height, bakeDown: true);
		SetVert(num, num2 + 1, height, bakeDown: true);
		SetVert(num - 1, num2 + 1, height, bakeDown: true);
		SetVert(num - 1, num2, height, bakeDown: true);
		SetVert(num - 1, num2 - 1, height, bakeDown: true);
		SetVert(num, num2 - 1, height, bakeDown: true);
		SetVert(num + 1, num2 - 1, height, bakeDown: true);
	}

	public void SetAverageTileHeight(int cx, int cz, float percent)
	{
		int num = cx * 2 + 1;
		int num2 = cz * 2 + 1;
		float num3 = 0f;
		num3 += GetVertY(num, num2);
		num3 += GetVertY(num + 1, num2);
		num3 += GetVertY(num + 1, num2 + 1);
		num3 += GetVertY(num, num2 + 1);
		num3 += GetVertY(num - 1, num2 + 1);
		num3 += GetVertY(num - 1, num2);
		num3 += GetVertY(num - 1, num2 - 1);
		num3 += GetVertY(num, num2 - 1);
		num3 += GetVertY(num + 1, num2 - 1);
		num3 /= 9f;
		SetVert(num, num2, Mathf.Lerp(GetVertY(num, num2), num3, percent), bakeDown: true);
		SetVert(num + 1, num2, Mathf.Lerp(GetVertY(num + 1, num2), num3, percent), bakeDown: true);
		SetVert(num + 1, num2 + 1, Mathf.Lerp(GetVertY(num + 1, num2 + 1), num3, percent), bakeDown: true);
		SetVert(num, num2 + 1, Mathf.Lerp(GetVertY(num, num2 + 1), num3, percent), bakeDown: true);
		SetVert(num - 1, num2 + 1, Mathf.Lerp(GetVertY(num - 1, num2 + 1), num3, percent), bakeDown: true);
		SetVert(num - 1, num2, Mathf.Lerp(GetVertY(num - 1, num2), num3, percent), bakeDown: true);
		SetVert(num - 1, num2 - 1, Mathf.Lerp(GetVertY(num - 1, num2 - 1), num3, percent), bakeDown: true);
		SetVert(num, num2 - 1, Mathf.Lerp(GetVertY(num, num2 - 1), num3, percent), bakeDown: true);
		SetVert(num + 1, num2 - 1, Mathf.Lerp(GetVertY(num + 1, num2 - 1), num3, percent), bakeDown: true);
	}

	public void SetAverageTileHeight(int cx, int cz, float percent, float maxHeight)
	{
		int num = cx * 2 + 1;
		int num2 = cz * 2 + 1;
		float num3 = 0f;
		num3 += GetVertY(num, num2);
		num3 += GetVertY(num + 1, num2);
		num3 += GetVertY(num + 1, num2 + 1);
		num3 += GetVertY(num, num2 + 1);
		num3 += GetVertY(num - 1, num2 + 1);
		num3 += GetVertY(num - 1, num2);
		num3 += GetVertY(num - 1, num2 - 1);
		num3 += GetVertY(num, num2 - 1);
		num3 += GetVertY(num + 1, num2 - 1);
		num3 /= 9f;
		SetVert(num, num2, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num, num2), num3, percent)), bakeDown: true);
		SetVert(num + 1, num2, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num + 1, num2), num3, percent)), bakeDown: true);
		SetVert(num + 1, num2 + 1, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num + 1, num2 + 1), num3, percent)), bakeDown: true);
		SetVert(num, num2 + 1, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num, num2 + 1), num3, percent)), bakeDown: true);
		SetVert(num - 1, num2 + 1, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num - 1, num2 + 1), num3, percent)), bakeDown: true);
		SetVert(num - 1, num2, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num - 1, num2), num3, percent)), bakeDown: true);
		SetVert(num - 1, num2 - 1, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num - 1, num2 - 1), num3, percent)), bakeDown: true);
		SetVert(num, num2 - 1, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num, num2 - 1), num3, percent)), bakeDown: true);
		SetVert(num + 1, num2 - 1, Mathff.Min(maxHeight, Mathf.Lerp(GetVertY(num + 1, num2 - 1), num3, percent)), bakeDown: true);
	}

	public void SetTileHeight(Cell cell, float height)
	{
		int num = cell.x * 2 + 1;
		int num2 = cell.z * 2 + 1;
		int num3 = xSize * 2 + 1;
		int num4 = zSize * 2 + 1;
		if (num >= 0 && num < num3 && num2 >= 0 && num2 < num4)
		{
			heightCache[num2 * num3 + num] = height;
		}
		if (num + 1 >= 0 && num + 1 < num3 && num2 >= 0 && num2 < num4)
		{
			heightCache[num2 * num3 + (num + 1)] = height;
		}
		if (num + 1 >= 0 && num + 1 < num3 && num2 + 1 >= 0 && num2 + 1 < num4)
		{
			heightCache[(num2 + 1) * num3 + (num + 1)] = height;
		}
		if (num >= 0 && num < num3 && num2 + 1 >= 0 && num2 + 1 < num4)
		{
			heightCache[(num2 + 1) * num3 + num] = height;
		}
		if (num - 1 >= 0 && num - 1 < num3 && num2 + 1 >= 0 && num2 + 1 < num4)
		{
			heightCache[(num2 + 1) * num3 + (num - 1)] = height;
		}
		if (num - 1 >= 0 && num - 1 < num3 && num2 >= 0 && num2 < num4)
		{
			heightCache[num2 * num3 + (num - 1)] = height;
		}
		if (num - 1 >= 0 && num - 1 < num3 && num2 - 1 >= 0 && num2 - 1 < num4)
		{
			heightCache[(num2 - 1) * num3 + (num - 1)] = height;
		}
		if (num >= 0 && num < num3 && num2 - 1 >= 0 && num2 - 1 < num4)
		{
			heightCache[(num2 - 1) * num3 + num] = height;
		}
		if (num + 1 >= 0 && num + 1 < num3 && num2 - 1 >= 0 && num2 - 1 < num4)
		{
			heightCache[(num2 - 1) * num3 + (num + 1)] = height;
		}
	}

	public float GetHeight(Vector3 p)
	{
		int meshX = (int)p.x * 2 + 1;
		int meshZ = (int)p.z * 2 + 1;
		return GetVertY(meshX, meshZ);
	}

	public void GetTriangleAtPoint_Water(float x, float z, ref Vector3[] triangle)
	{
		float num = (int)x * 2;
		float num2 = (int)z * 2;
		float num3 = x - (float)(int)x;
		float num4 = z - (float)(int)z;
		if (num3 > 0.5f)
		{
			if (num4 > 0.5f)
			{
				if (num4 > num3)
				{
					triangle[0].x = num + 1f;
					triangle[0].z = num2 + 1f;
					triangle[1].x = num + 1f;
					triangle[1].z = num2 + 2f;
					triangle[2].x = num + 2f;
					triangle[2].z = num2 + 2f;
				}
				else
				{
					triangle[0].x = num + 1f;
					triangle[0].z = num2 + 1f;
					triangle[1].x = num + 2f;
					triangle[1].z = num2 + 2f;
					triangle[2].x = num + 2f;
					triangle[2].z = num2 + 1f;
				}
			}
			else if (num4 + (num3 - 0.5f) > 0.5f)
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num + 2f;
				triangle[1].z = num2 + 1f;
				triangle[2].x = num + 2f;
				triangle[2].z = num2;
			}
			else
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num + 2f;
				triangle[1].z = num2;
				triangle[2].x = num + 1f;
				triangle[2].z = num2;
			}
		}
		else if (num4 > 0.5f)
		{
			if (num4 - 0.5f + num3 > 0.5f)
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num;
				triangle[1].z = num2 + 2f;
				triangle[2].x = num + 1f;
				triangle[2].z = num2 + 2f;
			}
			else
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num;
				triangle[1].z = num2 + 1f;
				triangle[2].x = num;
				triangle[2].z = num2 + 2f;
			}
		}
		else if (num4 > num3)
		{
			triangle[0].x = num + 1f;
			triangle[0].z = num2 + 1f;
			triangle[1].x = num;
			triangle[1].z = num2;
			triangle[2].x = num;
			triangle[2].z = num2 + 1f;
		}
		else
		{
			triangle[0].x = num + 1f;
			triangle[0].z = num2 + 1f;
			triangle[1].x = num + 1f;
			triangle[1].z = num2;
			triangle[2].x = num;
			triangle[2].z = num2;
		}
		for (int i = 0; i < triangle.Length; i++)
		{
			triangle[i].y = DynamicWater.inst.currentWaterHeightMap.GetPixel((int)triangle[i].x, (int)triangle[i].z).r;
			triangle[i].x *= 0.5f;
			triangle[i].z *= 0.5f;
		}
	}

	public void GetTriangleAtPointBridge(float x, float z, ref Vector3[] triangle)
	{
		float num = (int)x * 2;
		float num2 = (int)z * 2;
		float num3 = x - (float)(int)x;
		float num4 = z - (float)(int)z;
		if (num3 > 0.5f)
		{
			if (num4 > 0.5f)
			{
				if (num4 > num3)
				{
					triangle[0].x = num + 1f;
					triangle[0].z = num2 + 1f;
					triangle[1].x = num + 1f;
					triangle[1].z = num2 + 2f;
					triangle[2].x = num + 2f;
					triangle[2].z = num2 + 2f;
				}
				else
				{
					triangle[0].x = num + 1f;
					triangle[0].z = num2 + 1f;
					triangle[1].x = num + 2f;
					triangle[1].z = num2 + 2f;
					triangle[2].x = num + 2f;
					triangle[2].z = num2 + 1f;
				}
			}
			else if (num4 + (num3 - 0.5f) > 0.5f)
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num + 2f;
				triangle[1].z = num2 + 1f;
				triangle[2].x = num + 2f;
				triangle[2].z = num2;
			}
			else
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num + 2f;
				triangle[1].z = num2;
				triangle[2].x = num + 1f;
				triangle[2].z = num2;
			}
		}
		else if (num4 > 0.5f)
		{
			if (num4 - 0.5f + num3 > 0.5f)
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num;
				triangle[1].z = num2 + 2f;
				triangle[2].x = num + 1f;
				triangle[2].z = num2 + 2f;
			}
			else
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num;
				triangle[1].z = num2 + 1f;
				triangle[2].x = num;
				triangle[2].z = num2 + 2f;
			}
		}
		else if (num4 > num3)
		{
			triangle[0].x = num + 1f;
			triangle[0].z = num2 + 1f;
			triangle[1].x = num;
			triangle[1].z = num2;
			triangle[2].x = num;
			triangle[2].z = num2 + 1f;
		}
		else
		{
			triangle[0].x = num + 1f;
			triangle[0].z = num2 + 1f;
			triangle[1].x = num + 1f;
			triangle[1].z = num2;
			triangle[2].x = num;
			triangle[2].z = num2;
		}
		bool flag = false;
		float num5 = float.MinValue;
		for (int i = 0; i < triangle.Length; i++)
		{
			float vertYBridge = GetVertYBridge((int)triangle[i].x, (int)triangle[i].z);
			float vertY = GetVertY((int)triangle[i].x, (int)triangle[i].z);
			triangle[i].y = vertYBridge + vertY;
			triangle[i].x *= 0.5f;
			triangle[i].z *= 0.5f;
			if (vertYBridge > 0f)
			{
				flag = true;
			}
			if (triangle[i].y > num5)
			{
				num5 = triangle[i].y;
			}
		}
		if (flag)
		{
			for (int j = 0; j < triangle.Length; j++)
			{
				triangle[j].y = num5;
			}
		}
	}

	public void GetTriangleAtPoint(float x, float z, ref Vector3[] triangle)
	{
		float num = (int)x * 2;
		float num2 = (int)z * 2;
		float num3 = x - (float)(int)x;
		float num4 = z - (float)(int)z;
		if (num3 > 0.5f)
		{
			if (num4 > 0.5f)
			{
				if (num4 > num3)
				{
					triangle[0].x = num + 1f;
					triangle[0].z = num2 + 1f;
					triangle[1].x = num + 1f;
					triangle[1].z = num2 + 2f;
					triangle[2].x = num + 2f;
					triangle[2].z = num2 + 2f;
				}
				else
				{
					triangle[0].x = num + 1f;
					triangle[0].z = num2 + 1f;
					triangle[1].x = num + 2f;
					triangle[1].z = num2 + 2f;
					triangle[2].x = num + 2f;
					triangle[2].z = num2 + 1f;
				}
			}
			else if (num4 + (num3 - 0.5f) > 0.5f)
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num + 2f;
				triangle[1].z = num2 + 1f;
				triangle[2].x = num + 2f;
				triangle[2].z = num2;
			}
			else
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num + 2f;
				triangle[1].z = num2;
				triangle[2].x = num + 1f;
				triangle[2].z = num2;
			}
		}
		else if (num4 > 0.5f)
		{
			if (num4 - 0.5f + num3 > 0.5f)
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num;
				triangle[1].z = num2 + 2f;
				triangle[2].x = num + 1f;
				triangle[2].z = num2 + 2f;
			}
			else
			{
				triangle[0].x = num + 1f;
				triangle[0].z = num2 + 1f;
				triangle[1].x = num;
				triangle[1].z = num2 + 1f;
				triangle[2].x = num;
				triangle[2].z = num2 + 2f;
			}
		}
		else if (num4 > num3)
		{
			triangle[0].x = num + 1f;
			triangle[0].z = num2 + 1f;
			triangle[1].x = num;
			triangle[1].z = num2;
			triangle[2].x = num;
			triangle[2].z = num2 + 1f;
		}
		else
		{
			triangle[0].x = num + 1f;
			triangle[0].z = num2 + 1f;
			triangle[1].x = num + 1f;
			triangle[1].z = num2;
			triangle[2].x = num;
			triangle[2].z = num2;
		}
		for (int i = 0; i < triangle.Length; i++)
		{
			triangle[i].y = GetVertY((int)triangle[i].x, (int)triangle[i].z);
			triangle[i].x *= 0.5f;
			triangle[i].z *= 0.5f;
		}
	}

	public static void GetTriangleAtPointStatic(NativeArray<float> heightCache, int worldWidth, float x, float z, out Vector3 tri1, out Vector3 tri2, out Vector3 tri3)
	{
		float num = (int)x * 2;
		float num2 = (int)z * 2;
		float num3 = x - (float)(int)x;
		float num4 = z - (float)(int)z;
		if (num3 > 0.5f)
		{
			if (num4 > 0.5f)
			{
				if (num4 > num3)
				{
					tri1.x = num + 1f;
					tri1.z = num2 + 1f;
					tri2.x = num + 1f;
					tri2.z = num2 + 2f;
					tri3.x = num + 2f;
					tri3.z = num2 + 2f;
				}
				else
				{
					tri1.x = num + 1f;
					tri1.z = num2 + 1f;
					tri2.x = num + 2f;
					tri2.z = num2 + 2f;
					tri3.x = num + 2f;
					tri3.z = num2 + 1f;
				}
			}
			else if (num4 + (num3 - 0.5f) > 0.5f)
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num + 2f;
				tri2.z = num2 + 1f;
				tri3.x = num + 2f;
				tri3.z = num2;
			}
			else
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num + 2f;
				tri2.z = num2;
				tri3.x = num + 1f;
				tri3.z = num2;
			}
		}
		else if (num4 > 0.5f)
		{
			if (num4 - 0.5f + num3 > 0.5f)
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num;
				tri2.z = num2 + 2f;
				tri3.x = num + 1f;
				tri3.z = num2 + 2f;
			}
			else
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num;
				tri2.z = num2 + 1f;
				tri3.x = num;
				tri3.z = num2 + 2f;
			}
		}
		else if (num4 > num3)
		{
			tri1.x = num + 1f;
			tri1.z = num2 + 1f;
			tri2.x = num;
			tri2.z = num2;
			tri3.x = num;
			tri3.z = num2 + 1f;
		}
		else
		{
			tri1.x = num + 1f;
			tri1.z = num2 + 1f;
			tri2.x = num + 1f;
			tri2.z = num2;
			tri3.x = num;
			tri3.z = num2;
		}
		tri1.y = GetVertYStatic(heightCache, worldWidth, (int)tri1.x, (int)tri1.z);
		tri2.y = GetVertYStatic(heightCache, worldWidth, (int)tri2.x, (int)tri2.z);
		tri3.y = GetVertYStatic(heightCache, worldWidth, (int)tri3.x, (int)tri3.z);
		tri1.x *= 0.5f;
		tri1.z *= 0.5f;
		tri2.x *= 0.5f;
		tri2.z *= 0.5f;
		tri3.x *= 0.5f;
		tri3.z *= 0.5f;
	}

	public static bool GetTriangleAtPointBridgeStatic(NativeArray<float> heightCache, NativeArray<float> bridgeCache, int worldWidth, float x, float z, out Vector3 tri1, out Vector3 tri2, out Vector3 tri3)
	{
		float num = (int)x * 2;
		float num2 = (int)z * 2;
		float num3 = x - (float)(int)x;
		float num4 = z - (float)(int)z;
		if (num3 > 0.5f)
		{
			if (num4 > 0.5f)
			{
				if (num4 > num3)
				{
					tri1.x = num + 1f;
					tri1.z = num2 + 1f;
					tri2.x = num + 1f;
					tri2.z = num2 + 2f;
					tri3.x = num + 2f;
					tri3.z = num2 + 2f;
				}
				else
				{
					tri1.x = num + 1f;
					tri1.z = num2 + 1f;
					tri2.x = num + 2f;
					tri2.z = num2 + 2f;
					tri3.x = num + 2f;
					tri3.z = num2 + 1f;
				}
			}
			else if (num4 + (num3 - 0.5f) > 0.5f)
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num + 2f;
				tri2.z = num2 + 1f;
				tri3.x = num + 2f;
				tri3.z = num2;
			}
			else
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num + 2f;
				tri2.z = num2;
				tri3.x = num + 1f;
				tri3.z = num2;
			}
		}
		else if (num4 > 0.5f)
		{
			if (num4 - 0.5f + num3 > 0.5f)
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num;
				tri2.z = num2 + 2f;
				tri3.x = num + 1f;
				tri3.z = num2 + 2f;
			}
			else
			{
				tri1.x = num + 1f;
				tri1.z = num2 + 1f;
				tri2.x = num;
				tri2.z = num2 + 1f;
				tri3.x = num;
				tri3.z = num2 + 2f;
			}
		}
		else if (num4 > num3)
		{
			tri1.x = num + 1f;
			tri1.z = num2 + 1f;
			tri2.x = num;
			tri2.z = num2;
			tri3.x = num;
			tri3.z = num2 + 1f;
		}
		else
		{
			tri1.x = num + 1f;
			tri1.z = num2 + 1f;
			tri2.x = num + 1f;
			tri2.z = num2;
			tri3.x = num;
			tri3.z = num2;
		}
		bool flag = false;
		float num5 = float.MinValue;
		float vertYStatic = GetVertYStatic(heightCache, worldWidth, (int)tri1.x, (int)tri1.z);
		float vertYStatic2 = GetVertYStatic(bridgeCache, worldWidth, (int)tri1.x, (int)tri1.z);
		tri1.y = vertYStatic + vertYStatic2;
		if (vertYStatic2 > 0f)
		{
			flag = true;
		}
		if (tri1.y > num5)
		{
			num5 = tri1.y;
		}
		float vertYStatic3 = GetVertYStatic(heightCache, worldWidth, (int)tri2.x, (int)tri2.z);
		float vertYStatic4 = GetVertYStatic(bridgeCache, worldWidth, (int)tri2.x, (int)tri2.z);
		tri2.y = vertYStatic3 + vertYStatic4;
		if (vertYStatic4 > 0f)
		{
			flag = true;
		}
		if (tri2.y > num5)
		{
			num5 = tri2.y;
		}
		float vertYStatic5 = GetVertYStatic(heightCache, worldWidth, (int)tri3.x, (int)tri3.z);
		float vertYStatic6 = GetVertYStatic(bridgeCache, worldWidth, (int)tri3.x, (int)tri3.z);
		tri3.y = vertYStatic5 + vertYStatic6;
		if (vertYStatic6 > 0f)
		{
			flag = true;
		}
		if (tri3.y > num5)
		{
			num5 = tri3.y;
		}
		if (flag)
		{
			tri1.y = num5;
			tri2.y = num5;
			tri3.y = num5;
		}
		tri1.x *= 0.5f;
		tri1.z *= 0.5f;
		tri2.x *= 0.5f;
		tri2.z *= 0.5f;
		tri3.x *= 0.5f;
		tri3.z *= 0.5f;
		return flag;
	}

	public float GetInterpolatedHeight_Water(Vector3 p)
	{
		GetTriangleAtPoint_Water(p.x, p.z, ref triangle);
		Vector3 input = Vector3.Cross(triangle[1] - triangle[0], triangle[2] - triangle[0]);
		input.NonAllocateNormalize();
		float num = 0f - Mathff.Dot(input, triangle[0]);
		p.y += 100f;
		float num2 = down.y * input.y;
		float num3 = (0f - Mathff.Dot(p, input) - num) / num2;
		return p.y + down.y * num3;
	}

	public float GetInterpolatedHeight_WithBridging(Vector3 p)
	{
		GetTriangleAtPointBridge(p.x, p.z, ref triangle);
		Vector3 input = Vector3.Cross(triangle[1] - triangle[0], triangle[2] - triangle[0]);
		input.NonAllocateNormalize();
		float num = 0f - Mathff.Dot(input, triangle[0]);
		p.y += 100f;
		float num2 = down.y * input.y;
		float num3 = (0f - Mathff.Dot(p, input) - num) / num2;
		return p.y + down.y * num3;
	}

	public float GetInterpolatedHeight(Vector3 p)
	{
		GetTriangleAtPoint(p.x, p.z, ref _triangle);
		float num = _triangle[1].x - _triangle[0].x;
		float num2 = _triangle[1].y - _triangle[0].y;
		float num3 = _triangle[1].z - _triangle[0].z;
		float num4 = _triangle[2].x - _triangle[0].x;
		float num5 = _triangle[2].y - _triangle[0].y;
		float num6 = _triangle[2].z - _triangle[0].z;
		float num7 = num2 * num6 - num3 * num5;
		float num8 = num3 * num4 - num * num6;
		float num9 = num * num5 - num2 * num4;
		float num10 = 0f - (num7 * _triangle[0].x + num8 * _triangle[0].y + num9 * _triangle[0].z);
		float num11 = p.y + 100f;
		float num12 = (0f - (num7 * p.x + num8 * num11 + num9 * p.z) - num10) / (0f - num8);
		return num11 - num12;
	}

	public static float GetInterpolatedHeightStatic(NativeArray<float> heightCache, int worldSizeX, Vector3 p)
	{
		GetTriangleAtPointStatic(heightCache, worldSizeX, p.x, p.z, out var tri, out var tri2, out var tri3);
		Vector3 input = Vector3.Cross(tri2 - tri, tri3 - tri);
		input.NonAllocateNormalize();
		float num = 0f - Mathff.Dot(input, tri);
		p.y += 100f;
		float num2 = Vector3.down.y * input.y;
		float num3 = (0f - Mathff.Dot(p, input) - num) / num2;
		return p.y + Vector3.down.y * num3;
	}

	public static float GetInterpolatedHeightStatic_WithBridging(NativeArray<float> heightCache, NativeArray<float> bridgeHeightCache, int worldSizeX, Vector3 p, out bool hitBridge)
	{
		hitBridge = GetTriangleAtPointBridgeStatic(heightCache, bridgeHeightCache, worldSizeX, p.x, p.z, out var tri, out var tri2, out var tri3);
		Vector3 input = Vector3.Cross(tri2 - tri, tri3 - tri);
		input.NonAllocateNormalize();
		float num = 0f - Mathff.Dot(input, tri);
		p.y += 100f;
		float num2 = Vector3.down.y * input.y;
		float num3 = (0f - Mathff.Dot(p, input) - num) / num2;
		return p.y + Vector3.down.y * num3;
	}

	public float GetInterpolatedHeightWithNormal(Vector3 p, out Vector3 normal)
	{
		GetTriangleAtPoint(p.x, p.z, ref triangle);
		float num = triangle[1].x - triangle[0].x;
		float num2 = triangle[1].y - triangle[0].y;
		float num3 = triangle[1].z - triangle[0].z;
		float num4 = triangle[2].x - triangle[0].x;
		float num5 = triangle[2].y - triangle[0].y;
		float num6 = triangle[2].z - triangle[0].z;
		normal.x = num2 * num6 - num3 * num5;
		normal.y = num3 * num4 - num * num6;
		normal.z = num * num5 - num2 * num4;
		float num7 = Mathf.Sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z);
		normal.x /= num7;
		normal.y /= num7;
		normal.z /= num7;
		float num8 = 0f - Mathff.Dot(normal, triangle[0]);
		p.y += 100f;
		float num9 = down.y * normal.y;
		float num10 = (0f - Mathff.Dot(p, normal) - num8) / num9;
		return p.y + down.y * num10;
	}

	public Vector3 GetNormal(float x, float z)
	{
		GetTriangleAtPoint(x, z, ref triangle);
		float num = triangle[1].x - triangle[0].x;
		float num2 = triangle[1].y - triangle[0].y;
		float num3 = triangle[1].z - triangle[0].z;
		float num4 = triangle[2].x - triangle[0].x;
		float num5 = triangle[2].y - triangle[0].y;
		float num6 = triangle[2].z - triangle[0].z;
		Vector3 result = default;
		result.x = num2 * num6 - num3 * num5;
		result.y = num3 * num4 - num * num6;
		result.z = num * num5 - num2 * num4;
		float num7 = Mathf.Sqrt(result.x * result.x + result.y * result.y + result.z * result.z);
		result.x /= num7;
		result.y /= num7;
		result.z /= num7;
		return result;
	}

	public float GetTileHeight(float x, float z)
	{
		return GetVertY((int)x * 2 + 1, (int)z * 2 + 1);
	}

	public float GetTileHeight(Cell cell)
	{
		int meshX = cell.x * 2 + 1;
		int meshZ = cell.z * 2 + 1;
		return GetVertY(meshX, meshZ);
	}

	public void ChangeVertY(int meshIndex, float relativeChange)
	{
		SetVert(meshIndex, GetVertYUnsafe(meshIndex) + relativeChange, bakeDown: true);
	}

	public void ChangeVertY(int meshX, int meshZ, float relativeChange)
	{
		int num = meshX + meshZ * (xSize * 2 + 1);
		SetVert(num, GetVertYUnsafe(num) + relativeChange, bakeDown: true);
	}

	public void SetVert(int meshIndex, float y, bool bakeDown = false)
	{
		SetVert(meshIndex % World.MeshWidth, meshIndex / World.MeshWidth, y, bakeDown);
	}

	private void CollectAffectedCellsForVertex(int meshIndex)
	{
		int num = xSize * 2 + 1;
		int num2 = meshIndex % num;
		int num3 = meshIndex / num;
		int num4 = (num2 - 1) / 2;
		int num5 = (num3 - 1) / 2;
		AddCellIfValid(num4, num5);
		bool flag = num2 % 2 == 0;
		bool flag2 = num3 % 2 == 0;
		if (flag && num4 > 0)
		{
			AddCellIfValid(num4 - 1, num5);
		}
		if (flag2 && num5 > 0)
		{
			AddCellIfValid(num4, num5 - 1);
		}
		if ((flag & flag2) && num4 > 0 && num5 > 0)
		{
			AddCellIfValid(num4 - 1, num5 - 1);
		}
	}

	private void AddCellIfValid(int x, int z)
	{
		if (x >= 0 && x < xSize && z >= 0 && z < zSize)
		{
			dirtyCellsForFreeResources.Add(z * xSize + x);
		}
	}

	public void SetVert(int meshX, int meshZ, float y, bool bakeDown = false)
	{
		if (meshX < 0 || meshX >= World.MeshWidth || meshZ < 0 || meshZ >= World.MeshHeight)
		{
			return;
		}
		int num = meshZ * (xSize * 2 + 1) + meshX;
		float num2 = y - heightCache[num];
		framePatchMap[num] += num2;
		heightCache[num] = y;
		patchMapDirty = true;
		if (!dirtyVertMap[num] && Mathf.Abs(num2) > 0.0001f)
		{
			dirtyVertMap[num] = true;
			dirtyVertList.Add(num);
		}
		if (!bakeDown)
		{
			return;
		}
		int num3 = 1 - meshX % (chunkSize * 2) % 2;
		int num4 = 1 - meshZ % (chunkSize * 2) % 2;
		if (num3 == 0 && num4 == 0)
		{
			TerrainChunk terrainChunk = terrainChunks[meshX / chunkSizeMesh + meshZ / chunkSizeMesh * chunkWidth];
			terrainChunk.verticies[meshX - terrainChunk.x + (meshZ - terrainChunk.z) * terrainChunk.MeshSizeX].y = y;
			terrainChunk.dirtyVerts = true;
			return;
		}
		for (int i = -num3; i <= num3; i += 2)
		{
			for (int j = -num4; j <= num4; j += 2)
			{
				int num5 = meshX + i;
				int num6 = meshZ + j;
				if (num5 >= 0 && num6 >= 0 && num5 < World.MeshWidth && num6 < World.MeshHeight)
				{
					TerrainChunk terrainChunk2 = terrainChunks[num5 / chunkSizeMesh + num6 / chunkSizeMesh * chunkWidth];
					terrainChunk2.verticies[meshX - terrainChunk2.x + (meshZ - terrainChunk2.z) * terrainChunk2.MeshSizeX].y = y;
					terrainChunk2.dirtyVerts = true;
				}
			}
		}
	}

	public float GetVertY(int meshX, int meshZ)
	{
		if (meshX >= 0 && meshX < xSize * 2 + 1 && meshZ >= 0 && meshZ < zSize * 2 + 1)
		{
			return heightCache[meshZ * (xSize * 2 + 1) + meshX];
		}
		return 0f;
	}

	public float GetVertYBridge(int meshX, int meshZ)
	{
		if (meshX >= 0 && meshX < xSize * 2 + 1 && meshZ >= 0 && meshZ < zSize * 2 + 1)
		{
			return bridgeHeightCache[meshZ * (xSize * 2 + 1) + meshX];
		}
		return 0f;
	}

	public static float GetVertYStatic(NativeArray<float> heightCache, int xSize, int meshX, int meshZ)
	{
		return heightCache[meshZ * (xSize * 2 + 1) + meshX];
	}

	public float GetVertYUnsafe(int index)
	{
		return heightCache[index];
	}

	public bool Raycast(Ray ray, out RaycastHit hitInfo)
	{
		hitInfo = default;
		hitInfo.distance = float.MaxValue;
		RaycastHit hitInfo2;
		for (int i = 0; i < terrainChunks.Count; i++)
		{
			if (terrainChunks[i].Raycast(ray, out hitInfo2) && hitInfo2.distance < hitInfo.distance)
			{
				hitInfo = hitInfo2;
			}
		}
		MeshCollider component = waterTransform.GetComponent<MeshCollider>();
		if (component != null && component.Raycast(ray, out hitInfo2, 10000f) && hitInfo2.distance < hitInfo.distance)
		{
			hitInfo = hitInfo2;
		}
		return hitInfo.distance != float.MaxValue;
	}

	internal void DoSplat(Texture2D splatTex, float cx, float cz, float rot, Vector3 scale)
	{
		Color[] array = splatTex.GetPixels();
		cx = cx * 2f + 1f;
		cz = cz * 2f + 1f;
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		float num3 = Mathf.Cos(rot);
		float num4 = Mathf.Sin(rot);
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num2; j++)
			{
				float num5 = (float)i - cx;
				float num6 = (float)j - cz;
				float num7 = num5 * (1f / scale.x);
				num6 *= 1f / scale.z;
				float num8 = num7 - (float)(splatTex.width / 2);
				num6 -= (float)(splatTex.height / 2);
				float num9 = num8 * num3 - num6 * num4;
				float num10 = num8 * num4 + num6 * num3;
				num9 += (float)(splatTex.width / 2);
				num10 += (float)(splatTex.height / 2);
				if (num9 >= 0f && num10 >= 0f && num9 < (float)splatTex.width && num10 < (float)splatTex.height)
				{
					float r = array[(int)num10 * splatTex.width + (int)num9].r;
					SetVert(i, j, r * scale.y);
				}
			}
		}
	}

	public void SetRoadTile(Cell cell, bool isWood, bool isStone)
	{
		roadLocationTexture.SetPixel(cell.x, cell.z, new Color(isWood ? 1 : 0, isStone ? 1 : 0, 0f, 0f));
		roadLocationTexture.Apply();
	}

	public void ClearGrassTile(Cell cell, float forHowLong = float.MaxValue)
	{
		pendingGrassTiles.Add(new GrassTileChange
		{
			cell = cell,
			forHowLong = forHowLong,
			forceChange = false
		});
	}

	public void ResetGrassTile(Cell cell, float forHowLong = float.MaxValue)
	{
		pendingGrassTiles.Add(new GrassTileChange
		{
			cell = cell,
			forHowLong = forHowLong,
			forceChange = true
		});
	}

	public void CalcAveragedWorldCenter()
	{
		float y = Water.inst.transform.position.y;
		landWorldMin = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
		landWorldMax = new Vector3(float.MinValue, float.MinValue, float.MinValue);
		int num = 0;
		int meshWidth = World.MeshWidth;
		int i = 0;
		for (int num2 = heightCache.Length; i < num2; i++)
		{
			float num3 = (float)(i % meshWidth) * 0.5f;
			float num4 = (float)(i / meshWidth) * 0.5f;
			float num5 = heightCache[i];
			if (num5 > y)
			{
				if (landWorldMin.x > num3)
				{
					landWorldMin.x = num3;
				}
				if (landWorldMin.y > num5)
				{
					landWorldMin.y = num5;
				}
				if (landWorldMin.z > num4)
				{
					landWorldMin.z = num4;
				}
				if (landWorldMin.x < num3)
				{
					landWorldMax.x = num3;
				}
				if (landWorldMin.y < num5)
				{
					landWorldMax.y = num5;
				}
				if (landWorldMin.z < num4)
				{
					landWorldMax.z = num4;
				}
				num++;
			}
		}
		landAveragedWorldCenter = (landWorldMin + landWorldMax) / 2f;
	}

	public void SetTempEffectTile(Cell cell, int effect, float forHowLong)
	{
		temporaryTerrainEffectsTexture.SetPixel(cell.x, cell.z, new Color(1f, tempEffectTimeCode + forHowLong, 0f, 0f));
		temporaryTerrainEffectsTexture.Apply();
	}

	public void ClearTempEffectTile(Cell cell)
	{
		temporaryTerrainEffectsTexture.SetPixel(cell.x, cell.z, new Color(1f, tempEffectTimeCode + 0f, 0f, 0f));
		temporaryTerrainEffectsTexture.Apply();
	}

	public void BuildNatureObstructionField()
	{
		int num = xSize * 2 + 1;
		int num2 = zSize * 2 + 1;
		NativeArray<RaycastHit> nativeArray = new NativeArray<RaycastHit>(num * num2, Allocator.TempJob);
		NativeArray<RaycastCommand> nativeArray2 = new NativeArray<RaycastCommand>(num * num2, Allocator.TempJob);
		NativeArray<float> obstructionField = new NativeArray<float>(num * num2, Allocator.TempJob);
		NativeArray<float> nativeArray3 = new NativeArray<float>(num * num2, Allocator.TempJob);
		NativeArray<float> heightField = new NativeArray<float>(num * num2, Allocator.TempJob);
		int mask = LayerMask.GetMask("Terrain");
		JobHandle dependsOn = IJobParallelForExtensions.Schedule(new PopulateRaycastCommandsJob
		{
			RaycastCommands = nativeArray2,
			LayerMask = mask,
			MeshWidth = num
		}, num * num2, 64);
		JobHandle dependsOn2 = RaycastCommand.ScheduleBatch(nativeArray2, nativeArray, 1, dependsOn);
		heightField.CopyFrom(inst.heightCache);
		IJobParallelForExtensions.Schedule(new BuildObstructionMapJob
		{
			HitResults = nativeArray,
			HeightField = heightField,
			ObstructionField = obstructionField,
			MountainObstructionField = nativeArray3,
			WaterHeight = Water.inst.transform.position.y
		}, num * num2, 64, dependsOn2).Complete();
		obstructionField.CopyTo(inst.waterObstructionField);
		nativeArray3.CopyTo(inst.mountainObstructionField);
		nativeArray.Dispose();
		nativeArray2.Dispose();
		obstructionField.Dispose();
		nativeArray3.Dispose();
		heightField.Dispose();
	}

	public void SetTerrainHighestY()
	{
		int num = xSize * 2 + 1;
		_ = zSize;
		float num2 = 0f;
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num; j++)
			{
				if (heightCache[i + num * j] > num2)
				{
					num2 = heightCache[i + num * j];
				}
			}
		}
		TerrainMaterial.SetFloat("_TopologyHighestY", num2);
		ScaleChunkBoundingBoxes(num2);
	}

	public void ScaleChunkBoundingBoxes(float height)
	{
		for (int i = 0; i < waterChunks.Count; i++)
		{
			waterChunks[i].meshRenderer.bounds = new Bounds(waterChunks[i].transform.position.xz() + new Vector3((float)chunkSize * 0.5f, height * 0.5f, (float)chunkSize * 0.5f), new Vector3(chunkSize, height, chunkSize));
		}
		for (int j = 0; j < lavaChunks.Count; j++)
		{
			lavaChunks[j].meshRenderer.bounds = new Bounds(lavaChunks[j].transform.position.xz() + new Vector3((float)chunkSize * 0.5f, height * 0.5f, (float)chunkSize * 0.5f), new Vector3(chunkSize, height, chunkSize));
		}
	}

	public Vector3 GetVertPosMesh(int index)
	{
		int num = index % World.MeshWidth;
		return new Vector3(z: (float)(index / World.MeshWidth) * 0.5f, x: (float)num * 0.5f, y: heightCache[index]);
	}

	public float GetLowestHeightInCell(int cx, int cz)
	{
		return GetLowestHeightInCell(World.inst.GetCellData(cx, cz));
	}

	public float GetLowestHeightInCell(Cell getCell)
	{
		int num = DynamicWater.MapIndexWorldToMesh(getCell.index, World.inst.GridWidth);
		return Mathf.Min(GetVertYUnsafe(num - 1 - World.MeshWidth), GetVertYUnsafe(num - World.MeshWidth), GetVertYUnsafe(num + 1 - World.MeshWidth), GetVertYUnsafe(num - 1), GetVertYUnsafe(num), GetVertYUnsafe(num + 1), GetVertYUnsafe(num - 1 + World.MeshWidth), GetVertYUnsafe(num + World.MeshWidth), GetVertYUnsafe(num + 1 + World.MeshWidth));
	}

	public float GetHighestHeightInCell(int cx, int cz)
	{
		return GetHighestHeightInCell(World.inst.GetCellData(cx, cz));
	}

	public float GetHighestHeightInCell(Cell getCell)
	{
		int num = DynamicWater.MapIndexWorldToMesh(getCell.index, World.inst.GridWidth);
		return Mathf.Max(GetVertYUnsafe(num - 1 - World.MeshWidth), GetVertYUnsafe(num - World.MeshWidth), GetVertYUnsafe(num + 1 - World.MeshWidth), GetVertYUnsafe(num - 1), GetVertYUnsafe(num), GetVertYUnsafe(num + 1), GetVertYUnsafe(num - 1 + World.MeshWidth), GetVertYUnsafe(num + World.MeshWidth), GetVertYUnsafe(num + 1 + World.MeshWidth));
	}

	internal void ApplyBuildingOverlayMaterial()
	{
		int i = 0;
		for (int count = buildingsInOverlay.Count; i < count; i++)
		{
			buildingsInOverlay.data[i].ApplyMaterialPropertyBlock();
		}
	}
}
