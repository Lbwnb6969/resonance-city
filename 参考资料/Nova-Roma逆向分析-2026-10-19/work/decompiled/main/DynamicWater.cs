using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using Code;
using Drawing;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;

public class DynamicWater : MonoBehaviour
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

		public float freshness;

		public byte isManMadeSource;
	}

	[Serializable]
	public struct SavedWaterSource
	{
		public int index;

		public float rate;
	}

	public struct Waterfall
	{
		public byte isWaterSource;

		public int index;

		public float directionX;

		public float directionZ;

		public float height;

		public float waterAmount;

		public byte isWaterfall;

		public byte justChanged;

		public int type;
	}

	public struct MeshRaycastSample
	{
		public int cellIndex;

		public Vector3 origin;

		public float maxDistance;

		public int layerMask;

		public Vector2 velocity;
	}

	public class NewWaterHeightMapEvent
	{
		public Texture2D Texture1 { get; }

		public Texture2D Texture2 { get; }

		public Texture2D Flow { get; }

		public NewWaterHeightMapEvent(Texture2D texture1, Texture2D texture2, Texture2D flow)
		{
			Texture1 = texture1;
			Texture2 = texture2;
			Flow = flow;
		}
	}

	public delegate void NewWaterHeightMapEventHandler(object sender, NewWaterHeightMapEvent e);

	private struct SourceContribution
	{
		public float rate;

		public bool natural;
	}

	public class WaterExtractionRequest
	{
		public class ExtractionPoint
		{
			public int index;

			public float altitude;
		}

		public ExtractionPoint[] extractionPoints;

		public float perStepBudget;

		public Action<float, float, int> onComplete;

		public bool active = true;
	}

	public class RiverCarveRecord
	{
		public int sourceIndex;

		public int[] verts;

		public float[] deltas;

		public float[] postCarveHeights;

		public List<int> path;
	}

	[Serializable]
	public class SavedRiverCarve
	{
		public int sourceIndex;

		public int[] verts;

		public float[] deltas;

		public float[] postCarveHeights;

		public List<int> path;

		public int strengthLevel;
	}

	public struct WaterRaycastHit
	{
		public bool hit;

		public Vector3 point;

		public Vector3 normal;

		public float distance;

		public float waterAmount;
	}

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

		public float FluxThreshold;

		public int Width;

		public int Height;

		public float ProduceWater;

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
			float waterAmount = waterCell.waterAmount;
			float num4 = 0f;
			float num5 = 0f;
			float num6 = 0f;
			float num7 = 0f;
			for (int i = 0; i < 4; i++)
			{
				int index = ind + NeighborIndices4[i];
				WaterCell waterCell2 = Input[index];
				float num8 = HeightMap[index] + ObstructionMap[index];
				float waterAmount2 = waterCell2.waterAmount;
				float num9 = num3 + waterAmount - num8 - waterAmount2;
				num9 *= TerrainExaggeration;
				float num10 = 0f;
				switch (i)
				{
				case 0:
					num10 = waterCell.flux0;
					break;
				case 1:
					num10 = waterCell.flux1;
					break;
				case 2:
					num10 = waterCell.flux2;
					break;
				case 3:
					num10 = waterCell.flux3;
					break;
				}
				float num11 = Mathf.Max(0f, num10 + DeltaTime * A * (Gravity * num9 / L));
				num11 *= 0.995f;
				switch (i)
				{
				case 0:
					num4 = num11;
					break;
				case 1:
					num5 = num11;
					break;
				case 2:
					num6 = num11;
					break;
				case 3:
					num7 = num11;
					break;
				}
			}
			float num12 = num4 + num5 + num6 + num7;
			float num13 = 1f;
			if (num12 > 0f)
			{
				num13 = Math.Min(1f, waterAmount * L * L / (num12 * DeltaTime));
			}
			if (float.IsNaN(num13) || float.IsNegativeInfinity(num13))
			{
				num13 = 0f;
			}
			value.flux0 = num4 * num13;
			value.flux1 = num5 * num13;
			value.flux2 = num6 * num13;
			value.flux3 = num7 * num13;
			value.waterAmount = waterAmount;
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

		public float DeltaTime;

		public float L;

		public float Evaporation;

		public float FreshnessDecay;

		public float FreshnessDiffusion;

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
			float num4 = 0f;
			float num5 = 0f;
			int num6 = 0;
			for (int i = 0; i < 4; i++)
			{
				int index = ind + NeighborIndices4[i];
				WaterCell waterCell = Input[index];
				float num7 = 0f;
				switch (i)
				{
				case 0:
					num7 = waterCell.flux1;
					break;
				case 1:
					num7 = waterCell.flux0;
					break;
				case 2:
					num7 = waterCell.flux3;
					break;
				case 3:
					num7 = waterCell.flux2;
					break;
				}
				num3 += num7;
				num4 += num7 * waterCell.freshness;
				if (waterCell.waterAmount > 0f)
				{
					num5 += waterCell.freshness;
					num6++;
				}
			}
			float num8 = value.flux0 + value.flux1 + value.flux2 + value.flux3;
			float num9 = DeltaTime * (num3 - num8);
			float num10 = value.waterAmount + num9 / (L * L);
			float waterAmount = value.waterAmount;
			float num11 = DeltaTime * num3 / (L * L);
			float num12 = waterAmount + num11;
			float num14;
			if (num12 > 1E-05f)
			{
				float num13 = ((num3 > 0f) ? (num4 / num3) : 0f);
				num14 = (waterAmount * value.freshness + num11 * num13) / num12;
			}
			else
			{
				num14 = 0f;
			}
			if (num3 + num8 > 0.1f)
			{
				num14 = 1f;
			}
			if (num6 > 0 && num10 > 0f)
			{
				float num15 = num5 / (float)num6;
				num14 += (num15 - num14) * FreshnessDiffusion;
			}
			float a = 1f / Mathf.Max(num10, 0.01f);
			num14 = Mathf.Max(0f, num14 - FreshnessDecay * Mathf.Min(a, 10f));
			float num16 = Mathf.Clamp01(1f - num14 * 2f);
			float num17 = Mathf.Lerp(Evaporation, 0f, Mathf.Clamp01(num10 - 0.5f)) * num16 * DeltaTime;
			float b = num10 - num17;
			value.waterAmount = Mathf.Max(0f, b);
			value.freshness = ((value.waterAmount > 0f) ? num14 : 0f);
			if (value.waterAmount + HeightMap[ind] < OceanHeight - 1f)
			{
				value.waterAmount = 0f;
			}
			Output[ind] = value;
		}
	}

	[BurstCompile]
	public struct AddWaterParallelJob : IJobParallelFor
	{
		public NativeArray<WaterCell> Input;

		public float DeltaTime;

		public int Width;

		public int Height;

		public float rainMul;

		public float ProduceWater;

		public void Execute(int ind)
		{
			int num = ind % Width;
			int num2 = ind / Width;
			if (num != 0 && num != Width - 1 && num2 != 0 && num2 != Height - 1)
			{
				WaterCell value = Input[ind];
				float num3 = value.waterProductionRate * DeltaTime * ProduceWater;
				float num4 = ((value.isManMadeSource != 0) ? 1f : (1f + rainMul));
				value.waterAmount += num3 * num4;
				if (value.waterProductionRate > 0f)
				{
					value.freshness = 1f;
				}
				Input[ind] = value;
			}
		}
	}

	[BurstCompile]
	public struct SumWaterParallelJob : IJob
	{
		public NativeArray<WaterCell> Input;

		public NativeArray<float> Output;

		public void Execute()
		{
			Output[1] = Output[0];
			Output[0] = 0f;
			for (int i = 0; i < Input.Length; i++)
			{
				Output[0] += Input[i].waterAmount;
			}
		}
	}

	[BurstCompile]
	public struct ExtractWaterJob : IJob
	{
		public NativeArray<WaterCell> Grid;

		[ReadOnly]
		public NativeArray<float> HeightMap;

		[ReadOnly]
		public NativeArray<float> ObstructionMap;

		[ReadOnly]
		public NativeArray<int> PointStart;

		[ReadOnly]
		public NativeArray<int> PointCount;

		[ReadOnly]
		public NativeArray<int> PointIndex;

		[ReadOnly]
		public NativeArray<float> PointAltitude;

		[ReadOnly]
		public NativeArray<float> Budget;

		public NativeArray<float> Extracted;

		public NativeArray<float> Available;

		public int RequestCount;

		public int Step;

		public void Execute()
		{
			for (int i = 0; i < RequestCount; i++)
			{
				float num = Budget[i];
				int num2 = PointStart[i];
				int num3 = num2 + PointCount[i];
				float num4 = 0f;
				for (int j = num2; j < num3; j++)
				{
					int num5 = PointIndex[j];
					if (num5 >= 0 && num5 < Grid.Length)
					{
						WaterCell value = Grid[num5];
						float num6 = math.clamp(value.waterAmount + HeightMap[num5] + ObstructionMap[num5] - PointAltitude[j], 0f, value.waterAmount);
						num4 += num6;
						if (num > 0f && num6 > 0f)
						{
							float num7 = math.min(num, num6);
							value.waterAmount -= num7;
							Grid[num5] = value;
							Extracted[i] += num7;
							num -= num7;
						}
					}
				}
				if (Step == 0)
				{
					Available[i] = num4;
				}
			}
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

		public NativeArray<Waterfall> WaterFallMap;

		public NativeArray<float> GrassTexture;

		[ReadOnly]
		public float GrassTimeNow;

		[ReadOnly]
		public int Width;

		[ReadOnly]
		public int Height;

		public NativeArray<Color> Texture;

		public float WaterMeshTuck;

		public float WaterMeshExtraHeight;

		public float Deep;

		public void Execute(int ind)
		{
			Waterfall value = WaterFallMap[ind];
			value.index = ind;
			value.isWaterSource = ((Input[ind].waterProductionRate > 0f) ? ((byte)1) : ((byte)0));
			value.height = 0f;
			value.waterAmount = Input[ind].waterAmount;
			value.directionX = 0f;
			value.directionZ = 0f;
			value.type = -1;
			if (Input[ind].waterAmount > 0f)
			{
				float num = HeightMap[ind] + ObstructionMap[ind] + Input[ind].waterAmount;
				float r = num + WaterMeshExtraHeight;
				Texture[ind] = new Color(r, 0f, 0f);
				float directionZ = Input[ind].flux1 - Input[ind].flux0;
				float directionX = Input[ind].flux3 - Input[ind].flux2;
				value.height = num;
				value.directionX = directionX;
				value.directionZ = directionZ;
				if (GrassTexture[ind] < GrassTimeNow + 30f)
				{
					GrassTexture[ind] = GrassTimeNow + 30f;
				}
			}
			else
			{
				int num2 = ind % Width;
				int num3 = ind / Width;
				bool flag = false;
				int num4 = 0;
				float num5 = 0f;
				float num6 = 0f;
				for (int i = -1; i <= 1; i++)
				{
					for (int j = -1; j <= 1; j++)
					{
						int num7 = num2 + i;
						int num8 = num3 + j;
						if (num7 < 0 || num7 >= Width || num8 < 0 || num8 >= Height)
						{
							continue;
						}
						int index = num7 + num8 * Width;
						flag |= Input[index].waterAmount > 0f;
						if (Input[index].waterAmount > 0f)
						{
							float num9 = HeightMap[index] + ObstructionMap[index] + Input[index].waterAmount + WaterMeshExtraHeight;
							if (num9 > num6)
							{
								num6 = num9;
							}
							num5 += num9;
							num4++;
						}
					}
				}
				num5 = (flag ? Mathf.Min(num6, HeightMap[ind] + ObstructionMap[ind]) : (HeightMap[ind] - Deep));
				Texture[ind] = new Color(num5, 0f, 0f);
			}
			WaterFallMap[ind] = value;
		}
	}

	[BurstCompile]
	public struct AverageWaterFallParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<Waterfall> In;

		public NativeArray<Waterfall> Out;

		public void Execute(int ind)
		{
			Waterfall value = In[ind];
			Vector2 zero = Vector2.zero;
			int num = 0;
			for (int i = -1; i <= 1; i++)
			{
				for (int j = -1; j <= 1; j++)
				{
					int num2 = ind + (i + j * 2);
					if (num2 > 0 && num2 < In.Length)
					{
						zero += new Vector2(In[num2].directionX, In[num2].directionZ);
					}
					num++;
				}
			}
			zero /= (float)num;
			value.directionX = zero.x;
			value.directionZ = zero.y;
			Out[ind] = value;
		}
	}

	[BurstCompile]
	public struct ExtractWaterFlowParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<Waterfall> In;

		[ReadOnly]
		public int WorldWidth;

		[ReadOnly]
		public float SeaLevel;

		public float WaterFlowThreshold;

		public NativeArray<float> WaterFlowMagnitude;

		public int MapIndexWorldToMesh(int worldIndex, int worldWidth)
		{
			int num = worldIndex % worldWidth;
			int num2 = worldIndex / worldWidth;
			int num3 = num * 2 + 1;
			return (num2 * 2 + 1) * (worldWidth * 2 + 1) + num3;
		}

		public void Execute(int index)
		{
			Waterfall waterfall = In[MapIndexWorldToMesh(index, WorldWidth)];
			if (waterfall.height < SeaLevel || waterfall.waterAmount <= 0f)
			{
				WaterFlowMagnitude[index] = 0f;
				return;
			}
			float magnitude = new Vector2(waterfall.directionX, waterfall.directionZ).magnitude;
			WaterFlowMagnitude[index] = ((magnitude > WaterFlowThreshold) ? magnitude : 0f);
		}
	}

	[BurstCompile]
	public struct UpdateWaterTopMovementParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<Waterfall> In;

		[ReadOnly]
		public NativeArray<WaterCell> WaterGrid;

		public NativeArray<Color> Texture;

		public float DT;

		public void Execute(int ind)
		{
			Vector2 vector = new Vector2(In[ind].directionX, In[ind].directionZ);
			Color value = Texture[ind];
			float num = value.r + vector.x * DT;
			float num2 = value.b + vector.y * DT;
			num = (num % 1f + 1f) % 1f;
			num2 = (num2 % 1f + 1f) % 1f;
			value.r = num;
			value.g = WaterGrid[ind].freshness;
			value.b = num2;
			Texture[ind] = value;
		}
	}

	[BurstCompile]
	public struct BuildSimplifiedGridParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<WaterCell> Input;

		public NativeArray<float> SimplifiedGrid;

		public NativeArray<bool> WaterTileChanges;

		public NativeArray<Color> WaterMaskColors;

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
			bool flag = false;
			bool flag2 = false;
			bool flag3 = false;
			bool flag4 = false;
			bool flag5 = false;
			bool flag6 = false;
			bool flag7 = false;
			bool flag8 = false;
			bool flag9 = false;
			int num3 = 0;
			int num4 = 0;
			for (int i = -1; i <= 1; i++)
			{
				for (int j = -1; j <= 1; j++)
				{
					float waterAmount = Input[num2 + (i + j * (Width * 2 + 1))].waterAmount;
					if (waterAmount > 0f)
					{
						num4++;
					}
					switch (num3)
					{
					case 0:
						flag = waterAmount > 0f;
						break;
					case 1:
						flag2 = waterAmount > 0f;
						break;
					case 2:
						flag3 = waterAmount > 0f;
						break;
					case 3:
						flag4 = waterAmount > 0f;
						break;
					case 4:
						flag5 = waterAmount > 0f;
						break;
					case 5:
						flag6 = waterAmount > 0f;
						break;
					case 6:
						flag7 = waterAmount > 0f;
						break;
					case 7:
						flag8 = waterAmount > 0f;
						break;
					case 8:
						flag9 = waterAmount > 0f;
						break;
					}
					num += waterAmount;
					num3++;
				}
			}
			if (flag5 && num4 >= 3)
			{
				num /= (float)num4;
			}
			else
			{
				num = ((!(flag & flag2 & flag3) && !(flag4 & flag5 & flag6) && !(flag7 & flag8 & flag9) && !(flag & flag4 & flag7) && !(flag2 & flag5 & flag8) && !(flag3 & flag6 & flag9)) ? 0f : (num / (float)num4));
			}
			float num5 = SimplifiedGrid[ind];
			int num6 = ind / Width;
			int num7 = ind % Width;
			SimplifiedGrid[ind] = num;
			WaterMaskColors[ind] = (((num7 == Width - 1 && num6 == 0) || num > 0f) ? Color.white : Color.black);
			WaterTileChanges[ind] = num5 > 0f != num > 0f;
		}
	}

	[BurstCompile]
	public struct CompressWaterTileChangedJob : IJob
	{
		public NativeArray<bool> WaterTileChanges;

		public NativeArray<int> WaterTileChangesCompressed;

		public NativeArray<int> Count;

		public void Execute()
		{
			for (int i = 0; i < WaterTileChanges.Length; i++)
			{
				if (WaterTileChanges[i])
				{
					WaterTileChangesCompressed[Count[0]++] = i;
				}
			}
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

		public NativeArray<Color> Texture;

		public NativeArray<Color> WaterHeightMap1;

		public NativeArray<Color> WaterHeightMap2;

		public void Execute(int ind)
		{
			Unity.Mathematics.Random value = randomNumberGenerators[threadId];
			Input1[ind] = new WaterCell
			{
				index = ind
			};
			Color value2 = default;
			WaterHeightMap1[ind] = value2;
			WaterHeightMap2[ind] = value2;
			value2.r = value.NextFloat(0f, 1f);
			value2.g = 0f;
			value2.b = value.NextFloat(0f, 1f);
			value2.a = 0f;
			randomNumberGenerators[threadId] = value;
			Texture[ind] = value2;
		}
	}

	[BurstCompile]
	public struct FilterWaterfallsArrayJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<Waterfall> WaterfallsIn;

		public NativeArray<Waterfall> WaterfallsOut;

		public int GridWidth;

		public float WaterfallThreshold0;

		public float WaterfallThreshold1;

		public Matrix4x4 worldToCameraMatrix;

		public Matrix4x4 projectionMatrix;

		public bool cullWithFrustum;

		public bool flagAllChanged;

		public void Execute(int ind)
		{
			Waterfall value = WaterfallsIn[ind];
			value.isWaterfall = 0;
			Waterfall waterfall;
			int num3;
			bool flag;
			if (value.waterAmount > 0f)
			{
				Vector2 normalized = new Vector2(value.directionX, value.directionZ).normalized;
				int num = Mathf.RoundToInt(normalized.x);
				int num2 = Mathf.RoundToInt(normalized.y);
				int index = ind + num + num2 * GridWidth;
				waterfall = WaterfallsIn[index];
				flag = false;
				if (cullWithFrustum)
				{
					Vector4 vector = new Vector4((float)(ind % GridWidth) / 2f, value.height, (float)(ind / GridWidth) / 2f, 1f);
					Vector4 vector2 = worldToCameraMatrix * vector;
					Vector4 vector3 = projectionMatrix * vector2;
					Vector4 vector4 = vector3 / vector3.w;
					vector4.x = vector4.x * 0.5f + 0.5f;
					vector4.y = vector4.y * 0.5f + 0.5f;
					vector4.z = 0f - vector2.z;
					float x = vector4.x;
					if (x >= -0.1f && x <= 1.1f)
					{
						x = vector4.y;
						if (x >= -0.1f && x <= 1.1f)
						{
							num3 = ((vector4.z >= 0f) ? 1 : 0);
							goto IL_0165;
						}
					}
					num3 = 0;
					goto IL_0165;
				}
				flag = true;
				goto IL_016c;
			}
			goto IL_01df;
			IL_01df:
			value.justChanged = 0;
			if (value.isWaterfall != WaterfallsIn[ind].isWaterfall || value.type != WaterfallsIn[ind].type)
			{
				value.justChanged = 1;
			}
			if (flagAllChanged)
			{
				value.justChanged = 1;
			}
			WaterfallsOut[ind] = value;
			return;
			IL_016c:
			if (flag && waterfall.waterAmount > 0f && value.isWaterSource == 0 && value.height > 0f)
			{
				if (value.height - waterfall.height > WaterfallThreshold0)
				{
					value.isWaterfall = 1;
					value.type = 0;
				}
				if (value.height - waterfall.height > WaterfallThreshold1)
				{
					value.isWaterfall = 1;
					value.type = 1;
				}
			}
			goto IL_01df;
			IL_0165:
			flag = (byte)num3 != 0;
			goto IL_016c;
		}
	}

	[BurstCompile]
	public struct CompressWaterfallDataJob : IJob
	{
		[ReadOnly]
		public NativeArray<Waterfall> WaterfallsIn;

		public NativeArray<Waterfall> WaterfallsOut;

		public NativeArray<Waterfall> WaterfallsChanged;

		public NativeArray<Waterfall> HasWater;

		public NativeArray<int> Count;

		public NativeArray<int> ChangedCount;

		public NativeArray<int> HasWaterCount;

		public void Execute()
		{
			int i = 0;
			for (int length = WaterfallsIn.Length; i < length; i++)
			{
				if (WaterfallsIn[i].waterAmount > 0f)
				{
					HasWater[HasWaterCount[0]++] = WaterfallsIn[i];
				}
				if (WaterfallsIn[i].isWaterfall != 0)
				{
					WaterfallsOut[Count[0]++] = WaterfallsIn[i];
				}
				if (WaterfallsIn[i].justChanged != 0)
				{
					WaterfallsChanged[ChangedCount[0]++] = WaterfallsIn[i];
				}
			}
		}
	}

	[BurstCompile]
	public struct RaycastWaterJob : IJobParallelFor
	{
		[ReadOnly]
		public float3 gridOrigin;

		[ReadOnly]
		public float tileSize;

		[ReadOnly]
		public int meshSizeX;

		[ReadOnly]
		public int meshSizeZ;

		[ReadOnly]
		public NativeArray<float> heights;

		[ReadOnly]
		public NativeArray<float> obstructionMap;

		[ReadOnly]
		public NativeArray<WaterCell> waterGrid;

		[ReadOnly]
		public NativeArray<float3> rayOriginWS;

		[ReadOnly]
		public NativeArray<float3> rayDirWS;

		public NativeArray<float> tHit;

		public NativeArray<float3> pHit;

		public NativeArray<float3> nHit;

		public int tilesX;

		public int tilesZ;

		public float tMaxGlobal;

		public float eps;

		public float waterMeshExtraHeight;

		public void Execute(int i)
		{
			float3 float5 = rayOriginWS[i];
			float3 float6 = rayDirWS[i];
			float2 float7 = math.float2(0f, 0f);
			float2 float8 = math.float2(tilesX, tilesZ);
			float3 bmin = math.float3(gridOrigin.x + float7.x * tileSize, -1E+09f, gridOrigin.z + float7.y * tileSize);
			float3 bmax = math.float3(gridOrigin.x + float8.x * tileSize, 1E+09f, gridOrigin.z + float8.y * tileSize);
			if (!RayAABB(float5, float6, bmin, bmax, out var t, out var t2))
			{
				tHit[i] = -1f;
				return;
			}
			t = math.max(0f, t);
			t2 = math.min(t2, tMaxGlobal);
			if (t > t2)
			{
				tHit[i] = -1f;
				return;
			}
			float3 float9 = float5 + float6 * t;
			float2 float10 = math.float2((float9.x - gridOrigin.x) / tileSize, (float9.z - gridOrigin.z) / tileSize);
			int num = (int)math.floor(float10.x);
			int num2 = (int)math.floor(float10.y);
			int num3 = ((float6.x > 0f) ? 1 : (-1));
			int num4 = ((float6.z > 0f) ? 1 : (-1));
			float num5 = ((float6.x != 0f) ? (1f / float6.x) : 1E+30f);
			float num6 = ((float6.z != 0f) ? (1f / float6.z) : 1E+30f);
			float num7 = (float)(num + ((num3 > 0) ? 1 : 0)) * tileSize + gridOrigin.x;
			float num8 = (float)(num2 + ((num4 > 0) ? 1 : 0)) * tileSize + gridOrigin.z;
			float num9 = (num7 - float9.x) * num5 + t;
			float num10 = (num8 - float9.z) * num6 + t;
			float num11 = math.abs(tileSize * num5);
			float num12 = math.abs(tileSize * num6);
			float bestT = 1E+30f;
			float3 bestP = math.float3(0);
			float3 bestN = math.float3(0);
			for (int j = 0; j < (tilesX + tilesZ) * 4; j++)
			{
				if ((uint)num < (uint)tilesX && (uint)num2 < (uint)tilesZ)
				{
					float num13 = math.min(num9, num10);
					int num14 = 2 * num + 1;
					int num15 = 2 * num2 + 1;
					if (num14 > 0 && num14 < meshSizeX - 1 && num15 > 0 && num15 < meshSizeZ - 1)
					{
						float3 waterVertex = GetWaterVertex(num14, num15);
						float3 waterVertex2 = GetWaterVertex(num14, num15 - 1);
						float3 waterVertex3 = GetWaterVertex(num14, num15 + 1);
						float3 waterVertex4 = GetWaterVertex(num14 + 1, num15);
						float3 waterVertex5 = GetWaterVertex(num14 - 1, num15);
						float3 waterVertex6 = GetWaterVertex(num14 + 1, num15 - 1);
						float3 waterVertex7 = GetWaterVertex(num14 - 1, num15 - 1);
						float3 waterVertex8 = GetWaterVertex(num14 + 1, num15 + 1);
						float3 waterVertex9 = GetWaterVertex(num14 - 1, num15 + 1);
						TestTri(float5, float6, waterVertex, waterVertex2, waterVertex5, ref bestT, ref bestP, ref bestN);
						TestTri(float5, float6, waterVertex7, waterVertex5, waterVertex2, ref bestT, ref bestP, ref bestN);
						TestTri(float5, float6, waterVertex, waterVertex4, waterVertex2, ref bestT, ref bestP, ref bestN);
						TestTri(float5, float6, waterVertex6, waterVertex2, waterVertex4, ref bestT, ref bestP, ref bestN);
						TestTri(float5, float6, waterVertex, waterVertex3, waterVertex4, ref bestT, ref bestP, ref bestN);
						TestTri(float5, float6, waterVertex8, waterVertex4, waterVertex3, ref bestT, ref bestP, ref bestN);
						TestTri(float5, float6, waterVertex, waterVertex5, waterVertex3, ref bestT, ref bestP, ref bestN);
						TestTri(float5, float6, waterVertex9, waterVertex3, waterVertex5, ref bestT, ref bestP, ref bestN);
						if (bestT >= t - eps && bestT <= num13 + eps)
						{
							break;
						}
					}
				}
				if (num9 < num10)
				{
					num += num3;
					t = num9;
					num9 += num11;
				}
				else
				{
					num2 += num4;
					t = num10;
					num10 += num12;
				}
				if (t > t2 || t > tMaxGlobal)
				{
					break;
				}
			}
			if (bestT < 1E+20f)
			{
				tHit[i] = bestT;
				pHit[i] = bestP;
				nHit[i] = math.normalize(bestN);
			}
			else
			{
				tHit[i] = -1f;
			}
		}

		private float3 GetWaterVertex(int x, int z)
		{
			return math.float3(gridOrigin.x + (float)x * 0.5f * tileSize, z: gridOrigin.z + (float)z * 0.5f * tileSize, y: SampleWaterHeight(x, z));
		}

		private float SampleWaterHeight(int x, int z)
		{
			int index = z * meshSizeX + x;
			float num = heights[index];
			float num2 = obstructionMap[index];
			float waterAmount = waterGrid[index].waterAmount;
			if (waterAmount > 0f)
			{
				return num + num2 + waterAmount + waterMeshExtraHeight;
			}
			float num3 = -1E+20f;
			for (int i = -1; i <= 1; i++)
			{
				int num4 = z + i;
				if ((uint)num4 >= (uint)meshSizeZ)
				{
					continue;
				}
				for (int j = -1; j <= 1; j++)
				{
					int num5 = x + j;
					if ((uint)num5 >= (uint)meshSizeX)
					{
						continue;
					}
					int index2 = num4 * meshSizeX + num5;
					float waterAmount2 = waterGrid[index2].waterAmount;
					if (waterAmount2 > 0f)
					{
						float num6 = heights[index2] + waterAmount2 + obstructionMap[index2];
						if (num6 > num3)
						{
							num3 = num6;
						}
					}
				}
			}
			return math.max(num3, num + num2);
		}

		private static bool RayAABB(float3 ro, float3 rd, float3 bmin, float3 bmax, out float t0, out float t1)
		{
			float3 float5 = 1f / (rd + math.float3(1E-30f));
			float3 x = (bmin - ro) * float5;
			float3 y = (bmax - ro) * float5;
			float3 x2 = math.min(x, y);
			float3 x3 = math.max(x, y);
			t0 = math.cmax(x2);
			t1 = math.cmin(x3);
			return t0 <= t1;
		}

		private static void TestTri(float3 ro, float3 rd, float3 a, float3 b, float3 c, ref float bestT, ref float3 bestP, ref float3 bestN)
		{
			float3 float5 = b - a;
			float3 float6 = c - a;
			float3 y = math.cross(rd, float6);
			float num = math.dot(float5, y);
			if (math.abs(num) < 1E-08f)
			{
				return;
			}
			float num2 = 1f / num;
			float3 x = ro - a;
			float num3 = math.dot(x, y) * num2;
			if (num3 < 0f || num3 > 1f)
			{
				return;
			}
			float3 y2 = math.cross(x, float5);
			float num4 = math.dot(rd, y2) * num2;
			if (!(num4 < 0f) && !(num3 + num4 > 1f))
			{
				float num5 = math.dot(float6, y2) * num2;
				if (num5 > 0f && num5 < bestT)
				{
					bestT = num5;
					bestP = ro + rd * num5;
					bestN = math.cross(float5, float6);
				}
			}
		}
	}

	[Serializable]
	public class DynamicWaterSaveData : SaveClass<DynamicWater, DynamicWaterSaveData>
	{
		[NonSerialized]
		public bool doTexturePriming = true;

		public WaterCell[] waterGrid;

		public SerializableVector3[] gyserPositions;

		public List<SavedWaterSource> savedSources;

		[NonSerialized]
		public object ledgerSnapshot;

		public List<SavedRiverCarve> savedRiverCarves;

		private float debugProduceWater;

		public float totalWater;

		[OnDeserializing]
		private void SetDefaults(StreamingContext context)
		{
			debugProduceWater = 1f;
		}

		public override DynamicWaterSaveData Pack(DynamicWater w)
		{
			w.dynamicWaterJobHandle.Complete();
			waterGrid = new WaterCell[w.waterGrid.Length];
			w.waterGrid.CopyTo(waterGrid);
			gyserPositions = new SerializableVector3[w.gysers.Count];
			for (int i = 0; i < gyserPositions.Length; i++)
			{
				gyserPositions[i] = w.gysers[i].transform.position;
			}
			debugProduceWater = w.debug_produceWater;
			totalWater = w.totalWater;
			savedSources = w.CollectPersistentSources();
			ledgerSnapshot = w.SnapshotLedger();
			savedRiverCarves = w.CollectRiverCarves();
			return this;
		}

		public override DynamicWater Unpack(DynamicWater w)
		{
			w.dynamicWaterJobHandle.Complete();
			bool flag = false;
			for (int i = 0; i < waterGrid.Length; i++)
			{
				if (waterGrid[i].freshness > 0f)
				{
					flag = true;
					break;
				}
			}
			if (!flag)
			{
				for (int j = 0; j < waterGrid.Length; j++)
				{
					if (waterGrid[j].waterAmount > 0f)
					{
						WaterCell waterCell = waterGrid[j];
						waterCell.freshness = 1f;
						waterGrid[j] = waterCell;
					}
				}
			}
			w.waterGrid.CopyFrom(waterGrid);
			if (ledgerSnapshot != null)
			{
				w.RestoreLedgerSnapshot(ledgerSnapshot);
			}
			else if (savedSources != null)
			{
				w.RestorePersistentSources(savedSources);
			}
			else
			{
				w.MigrateSourcesFromGrid();
			}
			w.RestoreRiverCarves(savedRiverCarves);
			if (gyserPositions != null && LoadSave.Loading)
			{
				for (int k = 0; k < gyserPositions.Length; k++)
				{
					w.PlaceSpringVisuals(gyserPositions[k]);
				}
			}
			w.debug_produceWater = debugProduceWater;
			w.totalWater = totalWater;
			if (doTexturePriming)
			{
				w.PrimeTextures();
			}
			return w;
		}
	}

	private class DeferWaterAdd
	{
		public Cell cell;

		public float amt;
	}

	public float[] simplifiedWaterGrid;

	public float[] simplifiedWaterFlowMagnitude;

	private float[] treeFloodExposure;

	public NativeArray<float> simplifiedWaterGridNative;

	public NativeArray<float> simplifiedWaterFlowMagnitudeNative;

	public NativeArray<float> simplifiedWaterFlowMagnitudeNativeCopy;

	public NativeArray<bool> waterTileChangesGridNative;

	public NativeArray<int> waterTileChangesCompressedGridNative;

	public float[][] waterReadOnly = new float[2][];

	public int[] waterTilesChanged;

	public int waterTilesChangedCount;

	public int hasWaterCount;

	public NativeArray<WaterCell> waterGrid;

	public NativeArray<WaterCell> waterGridCopy;

	public NativeArray<WaterCell> waterGridResult;

	public NativeArray<float> waterSumNative;

	public NativeArray<float> localHeightMapCache;

	public NativeArray<float> localObstructionMapCache;

	public NativeArray<float2> tileMinMaxCache;

	private bool useMinMaxCache = true;

	public Waterfall[] waterfallMap;

	public Waterfall[] waterfallChangeMap;

	public Waterfall[] hasWaterMap;

	public NativeArray<Waterfall> waterfallMapNativeArray;

	public NativeArray<Waterfall> waterfallMapNativeArray2;

	public NativeArray<Waterfall> waterfallMapNativeArray3;

	public NativeArray<Waterfall> waterfallChangesNative;

	public NativeArray<Waterfall> hasWaterNative;

	public bool forceResetWaterfalls;

	private readonly List<DynamicWaterMeshSource> meshSources = new List<DynamicWaterMeshSource>();

	private readonly List<MeshRaycastSample> meshRaycastSamples = new List<MeshRaycastSample>(256);

	private float lastFrameDeltaTime;

	public Texture2D waterMaskTexture;

	public float FlowSpeedScaler = 1f;

	public float MeshVelocityFluxScale = 1f;

	[Header("Tree Flood Damage")]
	public bool treeFloodDamageEnabled = true;

	public float treeFloodMinimumDepth = 0.05f;

	public float treeFloodExposureThreshold = 1.5f;

	public float treeFloodExposureRate = 1f;

	[Header("Debug Visualization")]
	public bool showObstructionDebug;

	public float obstructionDebugRadius = 15f;

	public static DynamicWater inst;

	public GameObject gyserPrefab;

	public float sourceAmount = 10f;

	private NativeArray<Unity.Mathematics.Random> randomNumberGenerators;

	public const float DynamicWaterThreshold = 0f;

	public float WaterFlowThreshold = 0.0001f;

	private float SimulationTimeAccumulator;

	public float SimulationTimeStep = 0.1f;

	public WaterfallParticleManager waterfallParticleManager;

	private const float MeshGridCellSize = 0.5f;

	public int width;

	public int height;

	public Texture2D waterHeightMap1;

	public Texture2D waterHeightMap2;

	public Texture2D currentWaterHeightMap;

	public Texture2D scratchWaterHeightMap;

	public Texture2D waterFlowMap;

	private NativeArray<int> compressWaterCount;

	private NativeArray<int> compressWaterCount2;

	private NativeArray<int> compressWaterfallChangedCount;

	private NativeArray<int> compressCellWithWaterCount;

	private CompressWaterfallDataJob compressWaterfallsArrayJob;

	private NativeArray<int> neighborIndices4;

	private int[] neighborWorldIndices8;

	private readonly Dictionary<int, Dictionary<object, SourceContribution>> sourceLedger = new Dictionary<int, Dictionary<object, SourceContribution>>();

	private static readonly object LegacySourceOwner = new object();

	internal List<GameObject> gysers = new List<GameObject>();

	public bool hasGoodData;

	public bool forceUpdate = true;

	public float Deep = 100f;

	public bool editTerrainSimulate;

	internal int damagedBuildings;

	internal Vector3 buildingDamageLoc;

	private float swapTime;

	public float totalWaterChange;

	public float totalWater;

	public bool waterSimulationStable;

	private RaycastHit[] obstructionDebugHits = new RaycastHit[10];

	public int jobInnerloopBatches = 64;

	public float rainMul = 1f;

	public float A = 1f;

	public float Gravity = 9.81f;

	public float L = 1f;

	public float TerrainExaggeration = 1f;

	public float Evaporation = 0.1f;

	[Header("Freshness (source-fed water resists evaporation)")]
	[Tooltip("Per-step decay multiplier for freshness. Lower = water stays fresh longer after losing its source.")]
	public float FreshnessDecayRate = 0.002f;

	[Tooltip("How quickly freshness spreads through connected water bodies regardless of flow. Higher = reservoirs stay fresh more uniformly.")]
	[Range(0f, 0.25f)]
	public float FreshnessDiffusionRate = 0.1f;

	public float FluxThreshold = 1E-05f;

	public float TimeStep = 0.25f;

	public float WaterMeshExtraHeight = 0.1f;

	public float WaterMeshTuck = -0.1f;

	public float GeneratePrimeAmount = 0.2f;

	public Material WaterSourceMaterial;

	public Material WaterSourceMaterialBlue;

	public Material WaterSourceMaterialGreen;

	public Mesh CubeMesh;

	private Timer clickedOnceTimer = new Timer(0.25f);

	public JobHandle dynamicWaterJobHandle;

	public float debug_produceWater = 1f;

	public float dirMangitudeThreshold = 0.5f;

	private float elapsedTime;

	public float WaterFallThreshold0 = 0.2f;

	public float WaterFallThreshold1 = 0.4f;

	private bool showDamageOverlay;

	private List<WaterExtractionRequest> waterExtractionRequests = new List<WaterExtractionRequest>();

	private bool extractionRequestsDirty = true;

	private NativeArray<int> erPointStart;

	private NativeArray<int> erPointCount;

	private NativeArray<int> erPointIndex;

	private NativeArray<float> erPointAltitude;

	private NativeArray<float> erBudget;

	private NativeArray<float> erExtracted;

	private NativeArray<float> erAvailable;

	private int erRequestCount;

	private readonly List<WaterExtractionRequest> scheduledExtractionRequests = new List<WaterExtractionRequest>();

	private int scheduledExtractionSteps;

	private List<List<int>> paths = new List<List<int>>();

	private WaterCell[] tempWaterGrid;

	private readonly Dictionary<int, RiverCarveRecord> riverCarveLedger = new Dictionary<int, RiverCarveRecord>();

	private float[] preCarveScratch;

	public const int CarveStrengthDefault = 2;

	private static readonly float[] CarveStrengthMultipliers = new float[5] { 0f, 0.5f, 1f, 1.5f, 2f };

	private readonly Dictionary<int, int> carveStrengthLevels = new Dictionary<int, int>();

	private int[] neighbors = new int[4];

	private ArrayExtRef<DeferWaterAdd> waterAddRequests = new ArrayExtRef<DeferWaterAdd>(10);

	public bool needPostSimulationProcessing { get; set; }

	public event NewWaterHeightMapEventHandler NewWaterHeightMap;

	private void Awake()
	{
		inst = this;
		randomNumberGenerators = new NativeArray<Unity.Mathematics.Random>(128, Allocator.Persistent);
		waterfallParticleManager = GetComponent<WaterfallParticleManager>();
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
		for (int i = 0; i < gysers.Count; i++)
		{
			UnityEngine.Object.Destroy(gysers[i]);
		}
		gysers.Clear();
		riverCarveLedger.Clear();
		carveStrengthLevels.Clear();
		clickedOnceTimer.Enabled = false;
		damagedBuildings = 0;
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
		dynamicWaterJobHandle.Complete();
		if (waterGrid.IsCreated)
		{
			waterGrid.Dispose();
		}
		if (waterGridResult.IsCreated)
		{
			waterGridResult.Dispose();
		}
		if (waterSumNative.IsCreated)
		{
			waterSumNative.Dispose();
		}
		if (localHeightMapCache.IsCreated)
		{
			localHeightMapCache.Dispose();
		}
		if (localObstructionMapCache.IsCreated)
		{
			localObstructionMapCache.Dispose();
		}
		if (tileMinMaxCache.IsCreated)
		{
			tileMinMaxCache.Dispose();
		}
		if (waterfallMapNativeArray.IsCreated)
		{
			waterfallMapNativeArray.Dispose();
		}
		if (waterfallMapNativeArray2.IsCreated)
		{
			waterfallMapNativeArray2.Dispose();
		}
		if (waterfallMapNativeArray3.IsCreated)
		{
			waterfallMapNativeArray3.Dispose();
		}
		if (neighborIndices4.IsCreated)
		{
			neighborIndices4.Dispose();
		}
		if (simplifiedWaterGridNative.IsCreated)
		{
			simplifiedWaterGridNative.Dispose();
		}
		if (waterGridCopy.IsCreated)
		{
			waterGridCopy.Dispose();
		}
		if (simplifiedWaterFlowMagnitudeNative.IsCreated)
		{
			simplifiedWaterFlowMagnitudeNative.Dispose();
		}
		if (simplifiedWaterFlowMagnitudeNativeCopy.IsCreated)
		{
			simplifiedWaterFlowMagnitudeNativeCopy.Dispose();
		}
		if (waterTileChangesGridNative.IsCreated)
		{
			waterTileChangesGridNative.Dispose();
		}
		if (waterTileChangesCompressedGridNative.IsCreated)
		{
			waterTileChangesCompressedGridNative.Dispose();
		}
		if (waterfallChangesNative.IsCreated)
		{
			waterfallChangesNative.Dispose();
		}
		if (hasWaterNative.IsCreated)
		{
			hasWaterNative.Dispose();
		}
		if (compressWaterCount.IsCreated)
		{
			compressWaterCount.Dispose();
		}
		if (compressWaterCount2.IsCreated)
		{
			compressWaterCount2.Dispose();
		}
		if (compressWaterfallChangedCount.IsCreated)
		{
			compressWaterfallChangedCount.Dispose();
		}
		if (compressCellWithWaterCount.IsCreated)
		{
			compressCellWithWaterCount.Dispose();
		}
		waterGrid = new NativeArray<WaterCell>(width * height, Allocator.Persistent);
		waterGridResult = new NativeArray<WaterCell>(width * height, Allocator.Persistent);
		waterGridCopy = new NativeArray<WaterCell>(width * height, Allocator.Persistent);
		sourceLedger.Clear();
		localHeightMapCache = new NativeArray<float>(width * height, Allocator.Persistent);
		localObstructionMapCache = new NativeArray<float>(width * height, Allocator.Persistent);
		tileMinMaxCache = new NativeArray<float2>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		waterfallMapNativeArray = new NativeArray<Waterfall>(width * height, Allocator.Persistent);
		waterfallMapNativeArray2 = new NativeArray<Waterfall>(width * height, Allocator.Persistent);
		waterfallMapNativeArray3 = new NativeArray<Waterfall>(width * height, Allocator.Persistent);
		compressWaterCount = new NativeArray<int>(1, Allocator.Persistent);
		compressWaterCount2 = new NativeArray<int>(1, Allocator.Persistent);
		compressWaterfallChangedCount = new NativeArray<int>(1, Allocator.Persistent);
		compressCellWithWaterCount = new NativeArray<int>(1, Allocator.Persistent);
		waterSumNative = new NativeArray<float>(2, Allocator.Persistent);
		waterSumNative[0] = 0f;
		waterSumNative[1] = 0f;
		waterfallMap = new Waterfall[width * height];
		waterfallChangeMap = new Waterfall[width * height];
		hasWaterMap = new Waterfall[width * height];
		waterfallChangesNative = new NativeArray<Waterfall>(width * height, Allocator.Persistent);
		hasWaterNative = new NativeArray<Waterfall>(width * height, Allocator.Persistent);
		waterfallParticleManager.Init(width * height);
		simplifiedWaterGrid = new float[World.inst.GridWidth * World.inst.GridHeight];
		simplifiedWaterFlowMagnitude = new float[World.inst.GridWidth * World.inst.GridHeight];
		simplifiedWaterGridNative = new NativeArray<float>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		simplifiedWaterFlowMagnitudeNative = new NativeArray<float>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		simplifiedWaterFlowMagnitudeNativeCopy = new NativeArray<float>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		waterTileChangesGridNative = new NativeArray<bool>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		waterTileChangesCompressedGridNative = new NativeArray<int>(World.inst.GridWidth * World.inst.GridHeight, Allocator.Persistent);
		waterReadOnly[0] = new float[width * height];
		waterReadOnly[1] = new float[width * height];
		waterTilesChanged = new int[World.inst.GridWidth * World.inst.GridHeight];
		waterTilesChangedCount = 0;
		treeFloodExposure = new float[World.inst.GridWidth * World.inst.GridHeight];
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
		waterHeightMap1.name = "WaterHeightMap1";
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
		waterHeightMap2.name = "WaterHeightMap2";
		waterHeightMap2.filterMode = FilterMode.Bilinear;
		waterHeightMap2.wrapMode = TextureWrapMode.Clamp;
		if (scratchWaterHeightMap == null)
		{
			scratchWaterHeightMap = new Texture2D(width, height, TextureFormat.RGBAFloat, mipChain: false);
		}
		else
		{
			scratchWaterHeightMap.Reinitialize(width, height, TextureFormat.RGBAFloat, hasMipMap: false);
		}
		scratchWaterHeightMap.name = "WaterHeightMapScratch";
		scratchWaterHeightMap.filterMode = FilterMode.Bilinear;
		scratchWaterHeightMap.wrapMode = TextureWrapMode.Clamp;
		if (waterFlowMap == null)
		{
			waterFlowMap = new Texture2D(width, height, TextureFormat.RGBAFloat, mipChain: false);
		}
		else
		{
			waterFlowMap.Reinitialize(width, height, TextureFormat.RGBAFloat, hasMipMap: false);
		}
		waterFlowMap.name = "WaterFlowMap";
		waterFlowMap.filterMode = FilterMode.Point;
		waterFlowMap.wrapMode = TextureWrapMode.Clamp;
		IJobParallelForExtensions.Schedule(new InitWaterParallelJob
		{
			Input1 = waterGrid,
			Texture = waterFlowMap.GetRawTextureData<Color>(),
			WaterHeightMap1 = waterHeightMap1.GetRawTextureData<Color>(),
			WaterHeightMap2 = waterHeightMap2.GetRawTextureData<Color>(),
			randomNumberGenerators = randomNumberGenerators
		}, waterGrid.Length, 64).Complete();
		waterFlowMap.Apply();
		currentWaterHeightMap = waterHeightMap1;
		NewWaterHeightMap?.Invoke(this, new NewWaterHeightMapEvent(waterHeightMap1, waterHeightMap2, waterFlowMap));
		WaterSourceMaterialBlue = UnityEngine.Object.Instantiate(WaterSourceMaterial);
		WaterSourceMaterialBlue.SetColor("_Color", Color.blue);
		WaterSourceMaterialGreen = UnityEngine.Object.Instantiate(WaterSourceMaterial);
		WaterSourceMaterialGreen.SetColor("_Color", Color.green);
		Shader.SetGlobalFloat("_DynamicWaterBlend", 0f);
		if (waterMaskTexture == null)
		{
			waterMaskTexture = new Texture2D(World.inst.GridWidth, World.inst.GridHeight, TextureFormat.RGBAFloat, mipChain: false);
			waterMaskTexture.name = "WaterMaskTexture";
		}
		else
		{
			waterMaskTexture.Reinitialize(World.inst.GridWidth, World.inst.GridHeight);
		}
		waterExtractionRequests.Clear();
		scheduledExtractionRequests.Clear();
		DisposeExtractionBuffers();
		extractionRequestsDirty = true;
		waterAddRequests.Clear();
	}

	public void OnDestroy()
	{
		dynamicWaterJobHandle.Complete();
		waterGrid.Dispose();
		waterGridResult.Dispose();
		waterGridCopy.Dispose();
		localHeightMapCache.Dispose();
		localObstructionMapCache.Dispose();
		neighborIndices4.Dispose();
		simplifiedWaterGridNative.Dispose();
		simplifiedWaterFlowMagnitudeNative.Dispose();
		simplifiedWaterFlowMagnitudeNativeCopy.Dispose();
		waterTileChangesGridNative.Dispose();
		waterTileChangesCompressedGridNative.Dispose();
		waterfallMapNativeArray.Dispose();
		waterfallMapNativeArray2.Dispose();
		waterfallMapNativeArray3.Dispose();
		compressWaterCount.Dispose();
		compressWaterCount2.Dispose();
		randomNumberGenerators.Dispose();
		waterfallChangesNative.Dispose();
		hasWaterNative.Dispose();
		compressWaterfallChangedCount.Dispose();
		compressCellWithWaterCount.Dispose();
		waterSumNative.Dispose();
		tileMinMaxCache.Dispose();
		DisposeExtractionBuffers();
	}

	public void CreateWaterSourceNewMap(Cell c, float productionRate)
	{
		CreateWaterSource(MapIndexWorldToMesh(c.index, World.inst.GridWidth), productionRate);
		PlaceSpringVisuals(c.Center3D);
	}

	public void SetWaterContribution(int index, object owner, float rate, bool natural)
	{
		if (waterGrid.IsCreated && index >= 0 && index < waterGrid.Length)
		{
			if (!sourceLedger.TryGetValue(index, out var value))
			{
				value = new Dictionary<object, SourceContribution>();
				sourceLedger[index] = value;
			}
			value[owner] = new SourceContribution
			{
				rate = rate,
				natural = natural
			};
			RecomputeSourceCell(index);
		}
	}

	public void ClearWaterContribution(int index, object owner)
	{
		if (waterGrid.IsCreated && index >= 0 && index < waterGrid.Length && sourceLedger.TryGetValue(index, out var value) && value.Remove(owner))
		{
			if (value.Count == 0)
			{
				sourceLedger.Remove(index);
				dynamicWaterJobHandle.Complete();
				RemoveIndividualWaterSource(index);
			}
			else
			{
				RecomputeSourceCell(index);
			}
		}
	}

	private void RecomputeSourceCell(int index)
	{
		if (!sourceLedger.TryGetValue(index, out var value))
		{
			return;
		}
		float num = 0f;
		float num2 = 0f;
		foreach (SourceContribution value3 in value.Values)
		{
			if (value3.natural)
			{
				num += value3.rate;
			}
			else
			{
				num2 += value3.rate;
			}
		}
		dynamicWaterJobHandle.Complete();
		WaterCell value2 = waterGrid[index];
		value2.waterProductionRate = num + num2;
		value2.isManMadeSource = (byte)((num <= 0f && num2 > 0f) ? 1u : 0u);
		waterGrid[index] = value2;
	}

	public void CreateWaterSource(int index, float productionRate, bool manMade = false)
	{
		SetWaterContribution(index, LegacySourceOwner, productionRate, !manMade);
	}

	public void PlaceSpringVisuals(Vector3 pos)
	{
		GameObject gameObject = UnityEngine.Object.Instantiate(gyserPrefab);
		gameObject.transform.position = pos;
		gameObject.transform.localRotation = Quaternion.Euler(0f, 5f * pos.x + pos.z * 5f, 0f);
		gysers.Add(gameObject);
	}

	public void RemoveWaterSource(int index)
	{
		if (waterGrid.IsCreated)
		{
			ClearWaterContribution(index, LegacySourceOwner);
		}
	}

	public void RemoveIndividualWaterSource(int index)
	{
		WaterCell value = waterGrid[index];
		value.waterProductionRate = 0f;
		value.waterAmount = 0f;
		value.isManMadeSource = 0;
		waterGrid[index] = value;
	}

	public List<SavedWaterSource> CollectPersistentSources()
	{
		List<SavedWaterSource> list = new List<SavedWaterSource>();
		foreach (KeyValuePair<int, Dictionary<object, SourceContribution>> item in sourceLedger)
		{
			float num = 0f;
			foreach (SourceContribution value in item.Value.Values)
			{
				if (value.natural)
				{
					num += value.rate;
				}
			}
			if (num > 0f)
			{
				list.Add(new SavedWaterSource
				{
					index = item.Key,
					rate = num
				});
			}
		}
		return list;
	}

	public void RestorePersistentSources(List<SavedWaterSource> sources)
	{
		ClearAllSourceFields();
		if (sources == null)
		{
			return;
		}
		foreach (SavedWaterSource source in sources)
		{
			SetWaterContribution(source.index, LegacySourceOwner, source.rate, natural: true);
		}
	}

	public void MigrateSourcesFromGrid()
	{
		sourceLedger.Clear();
		dynamicWaterJobHandle.Complete();
		for (int i = 0; i < waterGrid.Length; i++)
		{
			WaterCell value = waterGrid[i];
			if (!(value.waterProductionRate <= 0f))
			{
				if (value.isManMadeSource == 0)
				{
					SetWaterContribution(i, LegacySourceOwner, value.waterProductionRate, natural: true);
					continue;
				}
				value.waterProductionRate = 0f;
				value.isManMadeSource = 0;
				waterGrid[i] = value;
			}
		}
	}

	private void ClearAllSourceFields()
	{
		sourceLedger.Clear();
		dynamicWaterJobHandle.Complete();
		for (int i = 0; i < waterGrid.Length; i++)
		{
			WaterCell value = waterGrid[i];
			if (value.waterProductionRate != 0f || value.isManMadeSource != 0)
			{
				value.waterProductionRate = 0f;
				value.isManMadeSource = 0;
				waterGrid[i] = value;
			}
		}
	}

	public object SnapshotLedger()
	{
		Dictionary<int, Dictionary<object, SourceContribution>> dictionary = new Dictionary<int, Dictionary<object, SourceContribution>>(sourceLedger.Count);
		foreach (KeyValuePair<int, Dictionary<object, SourceContribution>> item in sourceLedger)
		{
			dictionary[item.Key] = new Dictionary<object, SourceContribution>(item.Value);
		}
		return dictionary;
	}

	public void RestoreLedgerSnapshot(object snapshot)
	{
		if (!(snapshot is Dictionary<int, Dictionary<object, SourceContribution>> dictionary))
		{
			return;
		}
		ClearAllSourceFields();
		foreach (KeyValuePair<int, Dictionary<object, SourceContribution>> item in dictionary)
		{
			sourceLedger[item.Key] = new Dictionary<object, SourceContribution>(item.Value);
			RecomputeSourceCell(item.Key);
		}
	}

	public void EditTerrainSimulateOn(bool on)
	{
		editTerrainSimulate = on;
	}

	public float WaterHeight(Cell cell)
	{
		float tileHeight = TerrainGen.inst.GetTileHeight(cell);
		float num = simplifiedWaterGrid[cell.index];
		return tileHeight + num;
	}

	public float SampleWaterAvailable(int meshIndex, float altitude)
	{
		dynamicWaterJobHandle.Complete();
		if (!waterGrid.IsCreated || meshIndex < 0 || meshIndex >= waterGrid.Length)
		{
			return 0f;
		}
		WaterCell waterCell = waterGrid[meshIndex];
		return Mathf.Clamp(waterCell.waterAmount + localHeightMapCache[meshIndex] + localObstructionMapCache[meshIndex] - altitude, 0f, waterCell.waterAmount);
	}

	public bool IsWater(int x, int z)
	{
		if (x < 0 || x > World.inst.GridWidth || z < 0 || z > World.inst.GridHeight)
		{
			return false;
		}
		return simplifiedWaterGrid[x + z * World.inst.GridWidth] > 0f;
	}

	public void LateUpdate()
	{
		if (LoadSave.Loading || currentWaterHeightMap == null)
		{
			return;
		}
		WaterFlowDiagnostics.Tick(Time.deltaTime);
		float num = (editTerrainSimulate ? Time.unscaledDeltaTime : Time.deltaTime);
		SimulationTimeAccumulator += num;
		elapsedTime += num;
		lastFrameDeltaTime = num;
		dynamicWaterJobHandle.Complete();
		waterFlowMap.Apply();
		if (needPostSimulationProcessing)
		{
			needPostSimulationProcessing = false;
			waterMaskTexture.Apply();
			currentWaterHeightMap.Apply();
			Water.inst.RenderDynamicWaterDistanceField(waterMaskTexture);
			float num2 = waterSumNative[0];
			float num3 = waterSumNative[0] - waterSumNative[1];
			totalWater = (totalWater * 19f + num2) / 20f;
			totalWaterChange = (totalWaterChange * 19f + num3) / 20f;
			waterSimulationStable = Mathf.Abs(totalWaterChange) < 0.01f;
			if (!GameUI.inst.TerrainWaterEditModeActive())
			{
				MilestoneManager.inst.CheckForDamSizes();
				MilestoneManager.inst.CheckFirstFunctionalDam();
			}
			for (int i = 0; i < scheduledExtractionRequests.Count; i++)
			{
				WaterExtractionRequest waterExtractionRequest = scheduledExtractionRequests[i];
				if (waterExtractionRequest.active)
				{
					waterExtractionRequest.onComplete?.Invoke(erExtracted[i], erAvailable[i], scheduledExtractionSteps);
				}
			}
			scheduledExtractionRequests.Clear();
			int gridWidth = World.inst.GridWidth;
			int j = 0;
			for (int count = TerrainGen.inst.pendingGrassTiles.Count; j < count; j++)
			{
				TerrainGen.GrassTileChange grassTileChange = TerrainGen.inst.pendingGrassTiles.data[j];
				MapIndexWorldToMesh(grassTileChange.cell.x + gridWidth * grassTileChange.cell.z, gridWidth);
				int num4 = grassTileChange.cell.x * 2 + 1;
				int num5 = grassTileChange.cell.z * 2 + 1;
				for (int k = -1; k <= 1; k++)
				{
					for (int l = -1; l <= 1; l++)
					{
						if (TerrainGen.inst.grassVisibilityTexture.GetPixel(num4 + k, num5 + l).r < TerrainGen.inst.grassEffectTimeCode + grassTileChange.forHowLong || grassTileChange.forceChange)
						{
							TerrainGen.inst.grassVisibilityTexture.SetPixel(num4 + k, num5 + l, new Color(Mathf.Clamp(TerrainGen.inst.grassEffectTimeCode + grassTileChange.forHowLong, 0f, float.MaxValue), 0f, 0f, 0f));
						}
					}
				}
			}
			TerrainGen.inst.pendingGrassTiles.Clear();
			TerrainGen.inst.grassVisibilityTexture.Apply();
			swapTime = Time.time;
			if (waterHeightMap1 == currentWaterHeightMap)
			{
				currentWaterHeightMap = waterHeightMap2;
			}
			else
			{
				currentWaterHeightMap = waterHeightMap1;
			}
			simplifiedWaterGridNative.CopyTo(simplifiedWaterGrid);
			waterGrid.CopyTo(waterGridCopy);
			simplifiedWaterFlowMagnitudeNative.CopyTo(simplifiedWaterFlowMagnitude);
			simplifiedWaterFlowMagnitudeNative.CopyTo(simplifiedWaterFlowMagnitudeNativeCopy);
			waterTileChangesCompressedGridNative.CopyTo(waterTilesChanged);
			waterTilesChangedCount = compressWaterCount2[0];
			for (int m = 0; m < waterTilesChangedCount; m++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(waterTilesChanged[m]);
				World.inst.rebakeCells.Add(cellDataUnsafe);
				if (!showDamageOverlay)
				{
					continue;
				}
				bool flag = false;
				for (int n = 0; n < cellDataUnsafe.OccupyingStructure.Count(); n++)
				{
					if (cellDataUnsafe.OccupyingStructure[n].TakesWaterDamage)
					{
						buildingDamageLoc = cellDataUnsafe.OccupyingStructure[n].Center();
						flag = true;
						break;
					}
				}
				if ((simplifiedWaterGrid[cellDataUnsafe.index] > 0f) & flag)
				{
					damagedBuildings++;
					TerrainGen.inst.SetOverlayTileColor(cellDataUnsafe.x, cellDataUnsafe.z, Color.red);
				}
				if (simplifiedWaterGrid[cellDataUnsafe.index] <= 0f)
				{
					if (flag)
					{
						damagedBuildings--;
					}
					TerrainGen.inst.SetOverlayTileColor(cellDataUnsafe.x, cellDataUnsafe.z, Color.clear);
				}
			}
			if (showDamageOverlay)
			{
				TerrainGen.inst.UpdateOverlayTextures();
			}
			if (!editTerrainSimulate)
			{
				hasWaterNative.CopyTo(hasWaterMap);
				hasWaterCount = compressCellWithWaterCount[0];
				ProcessTreeFloodDamage(lastFrameDeltaTime, gridWidth);
			}
			waterfallMapNativeArray3.CopyTo(waterfallMap);
			waterfallChangesNative.CopyTo(waterfallChangeMap);
			int num6 = 0;
			for (int num7 = compressWaterfallChangedCount[0]; num6 < num7; num6++)
			{
				waterfallParticleManager.ShowParticles(waterfallChangeMap[num6].index, waterfallChangeMap[num6].type, waterfallChangeMap[num6].isWaterfall != 0 && waterfallChangeMap[num6].type != -1);
			}
			int num8 = 0;
			for (int num9 = compressWaterCount[0]; num8 < num9; num8++)
			{
				Vector3 vertPosMesh = TerrainGen.inst.GetVertPosMesh(waterfallMap[num8].index);
				vertPosMesh.y = waterfallMap[num8].height;
				Quaternion rotation = Quaternion.LookRotation(new Vector3(waterfallMap[num8].directionX, 0f, waterfallMap[num8].directionZ), Vector3.up);
				waterfallParticleManager.UpdateTransform(waterfallMap[num8].index, vertPosMesh, rotation);
			}
			hasGoodData = true;
		}
		int num10 = Mathf.FloorToInt(SimulationTimeAccumulator / SimulationTimeStep);
		SimulationTimeAccumulator -= (float)num10 * SimulationTimeStep;
		float num11 = Time.time - swapTime;
		float num12 = 0f;
		num12 = ((!(currentWaterHeightMap == waterHeightMap1)) ? Mathf.Lerp(1f, 0f, num11 / SimulationTimeStep) : Mathf.Lerp(0f, 1f, num11 / SimulationTimeStep));
		Shader.SetGlobalFloat("_DynamicWaterBlend", Mathf.Clamp01(num12));
		Shader.SetGlobalFloat("_DynamicWaterDT", elapsedTime);
		if (Input.GetKey(KeyCode.Home) || (editTerrainSimulate && num10 == 0))
		{
			num10 = 1;
		}
		if (num10 > 4)
		{
			num10 = 4;
			Debug.LogWarning("DynamicWater: simulationUpdates > 4 per frame!");
		}
		if (num10 > 0 || forceUpdate)
		{
			if (forceUpdate)
			{
				forceUpdate = false;
			}
			needPostSimulationProcessing = true;
			dynamicWaterJobHandle = StepSimulationN(num10);
			UpdateTextureParallelJob jobData = new UpdateTextureParallelJob
			{
				Input = waterGrid,
				Texture = currentWaterHeightMap.GetRawTextureData<Color>(),
				HeightMap = localHeightMapCache,
				ObstructionMap = localObstructionMapCache,
				WaterMeshTuck = WaterMeshTuck,
				WaterMeshExtraHeight = WaterMeshExtraHeight,
				Width = World.MeshWidth,
				Height = World.MeshHeight,
				Deep = Deep,
				WaterFallMap = waterfallMapNativeArray,
				GrassTexture = TerrainGen.inst.grassVisibilityTexture.GetRawTextureData<float>(),
				GrassTimeNow = TerrainGen.inst.grassEffectTimeCode
			};
			dynamicWaterJobHandle = IJobParallelForExtensions.Schedule(jobData, waterGrid.Length, 64, dynamicWaterJobHandle);
			BuildSimplifiedGridParallelJob jobData2 = new BuildSimplifiedGridParallelJob
			{
				SimplifiedGrid = simplifiedWaterGridNative,
				WaterMaskColors = waterMaskTexture.GetRawTextureData<Color>(),
				WaterTileChanges = waterTileChangesGridNative,
				Input = waterGrid,
				Width = World.inst.GridWidth
			};
			dynamicWaterJobHandle = IJobParallelForExtensions.Schedule(jobData2, World.inst.GridWidth * World.inst.GridHeight, 64, dynamicWaterJobHandle);
			compressWaterCount2[0] = 0;
			CompressWaterTileChangedJob jobData3 = new CompressWaterTileChangedJob
			{
				WaterTileChanges = waterTileChangesGridNative,
				WaterTileChangesCompressed = waterTileChangesCompressedGridNative,
				Count = compressWaterCount2
			};
			dynamicWaterJobHandle = jobData3.Schedule(dynamicWaterJobHandle);
			AverageWaterFallParallelJob jobData4 = new AverageWaterFallParallelJob
			{
				In = waterfallMapNativeArray,
				Out = waterfallMapNativeArray2
			};
			dynamicWaterJobHandle = IJobParallelForExtensions.Schedule(jobData4, waterfallMapNativeArray.Length, 64, dynamicWaterJobHandle);
			ExtractWaterFlowParallelJob jobData5 = new ExtractWaterFlowParallelJob
			{
				In = waterfallMapNativeArray2,
				WaterFlowMagnitude = simplifiedWaterFlowMagnitudeNative,
				WorldWidth = World.inst.GridWidth,
				WaterFlowThreshold = WaterFlowThreshold,
				SeaLevel = Water.inst.transform.position.y
			};
			dynamicWaterJobHandle = IJobParallelForExtensions.Schedule(jobData5, World.inst.GridWidth * World.inst.GridHeight, 64, dynamicWaterJobHandle);
			UpdateWaterTopMovementParallelJob jobData6 = new UpdateWaterTopMovementParallelJob
			{
				In = waterfallMapNativeArray2,
				WaterGrid = waterGrid,
				Texture = waterFlowMap.GetRawTextureData<Color>(),
				DT = num * FlowSpeedScaler
			};
			dynamicWaterJobHandle = IJobParallelForExtensions.Schedule(jobData6, waterfallMapNativeArray.Length, 64, dynamicWaterJobHandle);
			FilterWaterfallsArrayJob jobData7 = new FilterWaterfallsArrayJob
			{
				WaterfallsIn = waterfallMapNativeArray2,
				WaterfallsOut = waterfallMapNativeArray,
				WaterfallThreshold0 = WaterFallThreshold0,
				WaterfallThreshold1 = WaterFallThreshold1,
				worldToCameraMatrix = Cam.inst.cam.worldToCameraMatrix,
				projectionMatrix = Cam.inst.cam.projectionMatrix,
				cullWithFrustum = false,
				flagAllChanged = forceResetWaterfalls,
				GridWidth = World.MeshWidth
			};
			forceResetWaterfalls = false;
			dynamicWaterJobHandle = IJobParallelForExtensions.Schedule(jobData7, waterfallMapNativeArray2.Length, 64, dynamicWaterJobHandle);
			compressWaterCount[0] = 0;
			compressWaterfallChangedCount[0] = 0;
			compressCellWithWaterCount[0] = 0;
			compressWaterfallsArrayJob = new CompressWaterfallDataJob
			{
				WaterfallsIn = waterfallMapNativeArray,
				WaterfallsOut = waterfallMapNativeArray3,
				WaterfallsChanged = waterfallChangesNative,
				HasWater = hasWaterNative,
				Count = compressWaterCount,
				ChangedCount = compressWaterfallChangedCount,
				HasWaterCount = compressCellWithWaterCount
			};
			dynamicWaterJobHandle = compressWaterfallsArrayJob.Schedule(dynamicWaterJobHandle);
		}
		else
		{
			UpdateWaterTopMovementParallelJob jobData8 = new UpdateWaterTopMovementParallelJob
			{
				In = waterfallMapNativeArray2,
				WaterGrid = waterGrid,
				Texture = waterFlowMap.GetRawTextureData<Color>(),
				DT = num * FlowSpeedScaler
			};
			dynamicWaterJobHandle = IJobParallelForExtensions.Schedule(jobData8, waterfallMapNativeArray.Length, 64);
		}
		if (showObstructionDebug)
		{
			DrawObstructionDebug();
		}
		JobHandle.ScheduleBatchedJobs();
	}

	private void DrawObstructionDebug()
	{
		RaycastHit closestRayHit = PointingSystem.GetClosestRayHit(obstructionDebugHits);
		if (closestRayHit.collider == null)
		{
			return;
		}
		Vector3 point = closestRayHit.point;
		int num = (int)(point.x * 2f);
		int num2 = (int)(point.z * 2f);
		int num3 = (int)(obstructionDebugRadius * 2f);
		int num4 = Mathf.Max(0, num - num3);
		int num5 = Mathf.Min(width - 1, num + num3);
		int num6 = Mathf.Max(0, num2 - num3);
		int num7 = Mathf.Min(height - 1, num2 + num3);
		float num8 = obstructionDebugRadius * obstructionDebugRadius;
		float3 size = new float3(0.06f, 0.06f, 0.06f);
		float[] waterObstructionField = TerrainGen.inst.waterObstructionField;
		float[] heightCache = TerrainGen.inst.heightCache;
		for (int i = num6; i <= num7; i++)
		{
			for (int j = num4; j <= num5; j++)
			{
				int num9 = j + i * width;
				float num10 = waterObstructionField[num9];
				if (Mathf.Abs(num10) < 0.001f)
				{
					continue;
				}
				float num11 = heightCache[num9];
				if (!(num10 + num11 <= 0.5f))
				{
					float num12 = (float)j / 2f;
					float num13 = (float)i / 2f;
					float num14 = num12 - point.x;
					float num15 = num13 - point.z;
					float num16 = num14 * num14 + num15 * num15;
					if (!(num16 > num8))
					{
						Color color = Color.Lerp(Color.green, Color.red, Mathf.Clamp01(num10 / 3f));
						color.a = Mathf.Lerp(1f, 0.15f, num16 / num8);
						Draw.ingame.SolidBox(new Vector3(num12, num11 + num10, num13), size, color);
					}
				}
			}
		}
		for (int k = num6; k < num7; k++)
		{
			for (int l = num4; l < num5; l++)
			{
				int num17 = l + k * width;
				int num18 = num17 + 1;
				int num19 = num17 + width;
				int num20 = num19 + 1;
				float num21 = waterObstructionField[num17];
				float num22 = waterObstructionField[num18];
				float num23 = waterObstructionField[num19];
				float num24 = waterObstructionField[num20];
				bool flag = Mathf.Abs(num21) > 0.001f;
				bool flag2 = Mathf.Abs(num22) > 0.001f;
				bool flag3 = Mathf.Abs(num23) > 0.001f;
				bool flag4 = Mathf.Abs(num24) > 0.001f;
				if (!flag && !flag2 && !flag3 && !flag4)
				{
					continue;
				}
				float num25 = (float)l / 2f;
				float num26 = (float)(l + 1) / 2f;
				float num27 = (float)k / 2f;
				float num28 = (float)(k + 1) / 2f;
				float num29 = (num25 + num26) * 0.5f;
				float num30 = (num27 + num28) * 0.5f;
				float num31 = num29 - point.x;
				float num32 = num30 - point.z;
				float num33 = num31 * num31 + num32 * num32;
				if (!(num33 > num8))
				{
					float num34 = heightCache[num17];
					float num35 = heightCache[num18];
					float num36 = heightCache[num19];
					float num37 = heightCache[num20];
					Vector3 vector = new Vector3(num25, num34 + num21, num27);
					Vector3 vector2 = new Vector3(num26, num35 + num22, num27);
					Vector3 vector3 = new Vector3(num25, num36 + num23, num28);
					Vector3 vector4 = new Vector3(num26, num37 + num24, num28);
					float a = Mathf.Lerp(0.6f, 0.1f, num33 / num8);
					int num38 = (flag ? 1 : 0) + (flag2 ? 1 : 0) + (flag3 ? 1 : 0) + (flag4 ? 1 : 0);
					float num39 = (flag ? num21 : 0f) + (flag2 ? num22 : 0f) + (flag3 ? num23 : 0f) + (flag4 ? num24 : 0f);
					Color color2 = Color.Lerp(Color.green, Color.red, Mathf.Clamp01(num39 / (float)num38 / 3f));
					color2.a = a;
					Draw.ingame.SolidTriangle(vector, vector2, vector3, color2);
					Draw.ingame.SolidTriangle(vector2, vector4, vector3, color2);
					Color black = Color.black;
					black.a = a;
					if (!flag)
					{
						Draw.ingame.SolidBox(vector, size, black);
					}
					if (!flag2)
					{
						Draw.ingame.SolidBox(vector2, size, black);
					}
					if (!flag3)
					{
						Draw.ingame.SolidBox(vector3, size, black);
					}
					if (!flag4)
					{
						Draw.ingame.SolidBox(vector4, size, black);
					}
				}
			}
		}
	}

	private void ProcessTreeFloodDamage(float deltaTime, int gridWidth)
	{
		if (!treeFloodDamageEnabled || treeFloodExposureThreshold <= 0f || treeFloodExposureRate <= 0f)
		{
			return;
		}
		if (treeFloodExposure == null || treeFloodExposure.Length != simplifiedWaterGrid.Length)
		{
			treeFloodExposure = new float[simplifiedWaterGrid.Length];
		}
		for (int i = 0; i < waterTilesChangedCount; i++)
		{
			int num = waterTilesChanged[i];
			if (num >= 0 && num < treeFloodExposure.Length && simplifiedWaterGrid[num] <= treeFloodMinimumDepth)
			{
				treeFloodExposure[num] = 0f;
			}
		}
		if (deltaTime <= 0f || hasWaterCount == 0)
		{
			return;
		}
		float num2 = deltaTime * treeFloodExposureRate;
		for (int j = 0; j < hasWaterCount; j++)
		{
			int num3 = MapIndexMeshToWorld(hasWaterMap[j].index, gridWidth);
			if (num3 < 0 || num3 >= treeFloodExposure.Length)
			{
				continue;
			}
			float num4 = simplifiedWaterGrid[num3] - treeFloodMinimumDepth;
			if (num4 <= 0f)
			{
				continue;
			}
			float num5 = treeFloodExposure[num3] + num4 * num2;
			if (num5 >= treeFloodExposureThreshold)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(num3);
				World.inst.treeSystem.DeleteTreesAt(num3);
				if (World.inst.rockScatterSystem.GetFirstItem(cellDataUnsafe) == -1 && cellDataUnsafe.busyObj != null && cellDataUnsafe.busyObj is ClearCutterJob job)
				{
					JobSystem.inst.RemoveJob(job);
				}
				num5 = 0f;
			}
			treeFloodExposure[num3] = num5;
		}
	}

	public void UpdateWithPatchMap()
	{
		if (needPostSimulationProcessing)
		{
			dynamicWaterJobHandle.Complete();
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

	public void PrimeTextures()
	{
		localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
		localObstructionMapCache.CopyFrom(TerrainGen.inst.waterObstructionField);
		NativeArray<Color> rawTextureData = waterHeightMap1.GetRawTextureData<Color>();
		IJobParallelForExtensions.Schedule(new UpdateTextureParallelJob
		{
			Input = waterGrid,
			Texture = rawTextureData,
			HeightMap = localHeightMapCache,
			ObstructionMap = localObstructionMapCache,
			WaterMeshTuck = WaterMeshTuck,
			WaterMeshExtraHeight = WaterMeshExtraHeight,
			Width = World.MeshWidth,
			Height = World.MeshHeight,
			Deep = Deep,
			WaterFallMap = waterfallMapNativeArray,
			GrassTexture = TerrainGen.inst.grassVisibilityTexture.GetRawTextureData<float>(),
			GrassTimeNow = float.MinValue
		}, waterGrid.Length, 64).Complete();
		waterHeightMap2.GetRawTextureData<Color>().CopyFrom(rawTextureData);
		waterHeightMap1.Apply();
		waterHeightMap2.Apply();
		currentWaterHeightMap = waterHeightMap1;
		Shader.SetGlobalFloat("_DynamicWaterBlend", 0f);
		SimulationTimeAccumulator = 0f;
		IJobParallelForExtensions.Schedule(new BuildSimplifiedGridParallelJob
		{
			SimplifiedGrid = simplifiedWaterGridNative,
			WaterMaskColors = waterMaskTexture.GetRawTextureData<Color>(),
			WaterTileChanges = waterTileChangesGridNative,
			Input = waterGrid,
			Width = World.inst.GridWidth
		}, World.inst.GridWidth * World.inst.GridHeight, 64).Complete();
		waterMaskTexture.Apply();
		Water.inst.RenderDynamicWaterDistanceField(waterMaskTexture, blocking: true);
		simplifiedWaterGridNative.CopyTo(simplifiedWaterGrid);
	}

	public void Simulate(int frames)
	{
		StepSimulationN(frames, runExtraction: false).Complete();
		PrimeTextures();
	}

	public JobHandle StepSimulationN(int times, bool runExtraction = true)
	{
		localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
		localObstructionMapCache.CopyFrom(TerrainGen.inst.waterObstructionField);
		ApplyMeshEmittersToSimulation(lastFrameDeltaTime);
		for (int i = 0; i < waterAddRequests.Count; i++)
		{
			int index = MapIndexWorldToMesh(waterAddRequests.data[i].cell.index, World.inst.GridWidth);
			WaterCell value = inst.waterGrid[index];
			value.waterAmount = waterAddRequests.data[i].amt;
			inst.waterGrid[index] = value;
		}
		waterAddRequests.Clear();
		bool flag = runExtraction && times > 0 && waterExtractionRequests.Count > 0;
		if (flag)
		{
			if (extractionRequestsDirty)
			{
				RebuildExtractionBuffers();
			}
			scheduledExtractionRequests.Clear();
			for (int j = 0; j < erRequestCount; j++)
			{
				WaterExtractionRequest waterExtractionRequest = waterExtractionRequests[j];
				erBudget[j] = Mathf.Max(0f, waterExtractionRequest.perStepBudget);
				erExtracted[j] = 0f;
				erAvailable[j] = 0f;
				scheduledExtractionRequests.Add(waterExtractionRequest);
			}
			scheduledExtractionSteps = times;
		}
		JobHandle jobHandle = default;
		for (int k = 0; k < times; k++)
		{
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
				DeltaTime = TimeStep,
				FluxThreshold = FluxThreshold,
				NeighborIndices4 = neighborIndices4,
				SourceAmount = sourceAmount,
				ProduceWater = debug_produceWater
			}, waterGrid.Length, jobInnerloopBatches, jobHandle);
			float evaporation = Evaporation;
			_ = SeasonManager.inst.CurrWeather;
			_ = 3;
			JobHandle dependsOn2 = IJobParallelForExtensions.Schedule(new UpdateWaterHeightParallelJob
			{
				Width = width,
				Height = height,
				Input = waterGridResult,
				Output = waterGrid,
				HeightMap = localHeightMapCache,
				OceanHeight = Water.inst.transform.position.y,
				Evaporation = evaporation,
				FreshnessDecay = FreshnessDecayRate,
				FreshnessDiffusion = FreshnessDiffusionRate,
				L = L,
				NeighborIndices4 = neighborIndices4,
				DeltaTime = TimeStep
			}, waterGrid.Length, jobInnerloopBatches, dependsOn);
			JobHandle jobHandle2 = IJobParallelForExtensions.Schedule(new AddWaterParallelJob
			{
				Input = waterGrid,
				DeltaTime = TimeStep,
				Width = width,
				Height = height,
				rainMul = Mathff.Max(rainMul * SeasonManager.inst.waterSourceMul, -1f),
				ProduceWater = debug_produceWater
			}, waterGrid.Length, jobInnerloopBatches, dependsOn2);
			JobHandle dependsOn3 = jobHandle2;
			if (flag)
			{
				dependsOn3 = new ExtractWaterJob
				{
					Grid = waterGrid,
					HeightMap = localHeightMapCache,
					ObstructionMap = localObstructionMapCache,
					PointStart = erPointStart,
					PointCount = erPointCount,
					PointIndex = erPointIndex,
					PointAltitude = erPointAltitude,
					Budget = erBudget,
					Extracted = erExtracted,
					Available = erAvailable,
					RequestCount = erRequestCount,
					Step = k
				}.Schedule(jobHandle2);
			}
			jobHandle = new SumWaterParallelJob
			{
				Input = waterGrid,
				Output = waterSumNative
			}.Schedule(dependsOn3);
		}
		return jobHandle;
	}

	private void ApplyMeshEmittersToSimulation(float frameDeltaTime)
	{
		for (int num = meshSources.Count - 1; num >= 0; num--)
		{
			if (meshSources[num] == null)
			{
				meshSources.RemoveAt(num);
			}
		}
		if (meshSources.Count == 0)
		{
			return;
		}
		meshRaycastSamples.Clear();
		int meshWidth = width;
		int meshHeight = height;
		for (int i = 0; i < meshSources.Count; i++)
		{
			DynamicWaterMeshSource dynamicWaterMeshSource = meshSources[i];
			if (!(dynamicWaterMeshSource == null) && dynamicWaterMeshSource.isActiveAndEnabled)
			{
				dynamicWaterMeshSource.SyncVelocity(frameDeltaTime);
				dynamicWaterMeshSource.CollectSamples(meshRaycastSamples, 0.5f, meshWidth, meshHeight);
			}
		}
		int count = meshRaycastSamples.Count;
		if (count == 0)
		{
			return;
		}
		NativeArray<RaycastCommand> commands = new NativeArray<RaycastCommand>(count, Allocator.TempJob);
		NativeArray<RaycastHit> results = new NativeArray<RaycastHit>(count, Allocator.TempJob);
		try
		{
			for (int j = 0; j < count; j++)
			{
				MeshRaycastSample meshRaycastSample = meshRaycastSamples[j];
				RaycastCommand value = commands[j];
				QueryParameters queryParameters = QueryParameters.Default;
				queryParameters.hitBackfaces = false;
				queryParameters.hitMultipleFaces = false;
				queryParameters.layerMask = ((meshRaycastSample.layerMask != 0) ? meshRaycastSample.layerMask : (-1));
				value.queryParameters = queryParameters;
				value.from = meshRaycastSample.origin;
				value.direction = Vector3.down;
				value.distance = Mathf.Max(meshRaycastSample.maxDistance, 0.01f);
				value.physicsScene = Physics.defaultPhysicsScene;
				value.maxHits = 1;
				commands[j] = value;
			}
			RaycastCommand.ScheduleBatch(commands, results, 1).Complete();
			for (int k = 0; k < count; k++)
			{
				RaycastHit raycastHit = results[k];
				if (!raycastHit.collider)
				{
					continue;
				}
				MeshRaycastSample meshRaycastSample2 = meshRaycastSamples[k];
				int cellIndex = meshRaycastSample2.cellIndex;
				if (cellIndex < 0 || cellIndex >= waterGrid.Length)
				{
					continue;
				}
				WaterCell value2 = waterGrid[cellIndex];
				bool flag = false;
				if (MeshVelocityFluxScale > 0f)
				{
					Vector2 velocity = meshRaycastSample2.velocity;
					if (velocity.x != 0f || velocity.y != 0f)
					{
						float num2 = ((frameDeltaTime > 0f) ? frameDeltaTime : SimulationTimeStep);
						if (num2 > 0f)
						{
							float num3 = MeshVelocityFluxScale * num2;
							if (velocity.x > 0f)
							{
								value2.flux3 += velocity.x * num3;
							}
							else if (velocity.x < 0f)
							{
								value2.flux2 += (0f - velocity.x) * num3;
							}
							if (velocity.y > 0f)
							{
								value2.flux1 += velocity.y * num3;
							}
							else if (velocity.y < 0f)
							{
								value2.flux0 += (0f - velocity.y) * num3;
							}
							flag = true;
						}
					}
				}
				float num4 = Mathf.Max(0f, raycastHit.point.y - localHeightMapCache[cellIndex]);
				if (num4 > value2.waterAmount)
				{
					value2.waterAmount = num4;
					flag = true;
				}
				if (flag)
				{
					waterGrid[cellIndex] = value2;
				}
			}
		}
		finally
		{
			if (commands.IsCreated)
			{
				commands.Dispose();
			}
			if (results.IsCreated)
			{
				results.Dispose();
			}
		}
	}

	public void RegisterMeshSource(DynamicWaterMeshSource source)
	{
		if (!(source == null) && !meshSources.Contains(source))
		{
			meshSources.Add(source);
		}
	}

	public void UnregisterMeshSource(DynamicWaterMeshSource source)
	{
		if (!(source == null))
		{
			meshSources.Remove(source);
		}
	}

	private void Press3x3(int index, float amount)
	{
		for (int i = 0; i < 8; i++)
		{
			TerrainGen.inst.SoftDepressTile(World.inst.GetCellDataUnsafe((index + neighborWorldIndices8[i]) % waterGrid.Length), amount);
		}
		TerrainGen.inst.SoftDepressTile(World.inst.GetCellDataUnsafe(index), amount);
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

	public void ShowDamageOverlay(bool show)
	{
		showDamageOverlay = show;
		damagedBuildings = 0;
	}

	public static int MapWorldPosToMeshIndex(Vector3 pos, int meshWidth)
	{
		double num = Math.Round(pos.x * 2f) / 2.0;
		double num2 = Math.Round(pos.z * 2f) / 2.0;
		return (int)(num * 2.0) + (int)(num2 * 2.0) * meshWidth;
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

	public WaterExtractionRequest AddWaterExtractionRequest(WaterExtractionRequest.ExtractionPoint[] extractionPoints, Action<float, float, int> onComplete)
	{
		WaterExtractionRequest waterExtractionRequest = new WaterExtractionRequest();
		waterExtractionRequest.extractionPoints = extractionPoints;
		waterExtractionRequest.onComplete = onComplete;
		waterExtractionRequests.Add(waterExtractionRequest);
		extractionRequestsDirty = true;
		return waterExtractionRequest;
	}

	public void RemoveWaterExtractionRequest(WaterExtractionRequest req)
	{
		if (req != null)
		{
			req.active = false;
		}
		waterExtractionRequests.Remove(req);
		extractionRequestsDirty = true;
	}

	private void RebuildExtractionBuffers()
	{
		DisposeExtractionBuffers();
		erRequestCount = waterExtractionRequests.Count;
		int num = 0;
		for (int i = 0; i < erRequestCount; i++)
		{
			num += waterExtractionRequests[i].extractionPoints.Length;
		}
		erPointStart = new NativeArray<int>(Mathf.Max(1, erRequestCount), Allocator.Persistent);
		erPointCount = new NativeArray<int>(Mathf.Max(1, erRequestCount), Allocator.Persistent);
		erBudget = new NativeArray<float>(Mathf.Max(1, erRequestCount), Allocator.Persistent);
		erExtracted = new NativeArray<float>(Mathf.Max(1, erRequestCount), Allocator.Persistent);
		erAvailable = new NativeArray<float>(Mathf.Max(1, erRequestCount), Allocator.Persistent);
		erPointIndex = new NativeArray<int>(Mathf.Max(1, num), Allocator.Persistent);
		erPointAltitude = new NativeArray<float>(Mathf.Max(1, num), Allocator.Persistent);
		int num2 = 0;
		for (int j = 0; j < erRequestCount; j++)
		{
			WaterExtractionRequest waterExtractionRequest = waterExtractionRequests[j];
			erPointStart[j] = num2;
			erPointCount[j] = waterExtractionRequest.extractionPoints.Length;
			for (int k = 0; k < waterExtractionRequest.extractionPoints.Length; k++)
			{
				erPointIndex[num2] = waterExtractionRequest.extractionPoints[k].index;
				erPointAltitude[num2] = waterExtractionRequest.extractionPoints[k].altitude;
				num2++;
			}
		}
		extractionRequestsDirty = false;
	}

	private void DisposeExtractionBuffers()
	{
		if (erPointStart.IsCreated)
		{
			erPointStart.Dispose();
		}
		if (erPointCount.IsCreated)
		{
			erPointCount.Dispose();
		}
		if (erPointIndex.IsCreated)
		{
			erPointIndex.Dispose();
		}
		if (erPointAltitude.IsCreated)
		{
			erPointAltitude.Dispose();
		}
		if (erBudget.IsCreated)
		{
			erBudget.Dispose();
		}
		if (erExtracted.IsCreated)
		{
			erExtracted.Dispose();
		}
		if (erAvailable.IsCreated)
		{
			erAvailable.Dispose();
		}
	}

	public void CutRivers()
	{
		localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
		localObstructionMapCache.CopyFrom(TerrainGen.inst.waterObstructionField);
		tempWaterGrid = new WaterCell[waterGrid.Length];
		waterGrid.CopyTo(tempWaterGrid);
		paths = new List<List<int>>();
		riverCarveLedger.Clear();
		carveStrengthLevels.Clear();
		for (int i = 0; i < tempWaterGrid.Length; i++)
		{
			if (!(tempWaterGrid[i].waterProductionRate <= 0f))
			{
				RecordCarve(i);
			}
		}
	}

	public int GetCarveStrength(int sourceIndex)
	{
		if (!carveStrengthLevels.TryGetValue(sourceIndex, out var value))
		{
			return 2;
		}
		return value;
	}

	public void SetCarveStrength(int sourceIndex, int level)
	{
		carveStrengthLevels[sourceIndex] = Mathf.Clamp(level, 0, CarveStrengthMultipliers.Length - 1);
	}

	public void MoveCarveStrength(int fromIndex, int toIndex)
	{
		if (fromIndex != toIndex && carveStrengthLevels.TryGetValue(fromIndex, out var value))
		{
			carveStrengthLevels.Remove(fromIndex);
			carveStrengthLevels[toIndex] = value;
		}
	}

	public void RemoveCarveStrength(int sourceIndex)
	{
		carveStrengthLevels.Remove(sourceIndex);
	}

	public RiverCarveRecord GetRiverCarve(int sourceIndex)
	{
		riverCarveLedger.TryGetValue(sourceIndex, out var value);
		return value;
	}

	public List<SavedRiverCarve> CollectRiverCarves()
	{
		List<SavedRiverCarve> list = new List<SavedRiverCarve>(riverCarveLedger.Count);
		foreach (KeyValuePair<int, RiverCarveRecord> item in riverCarveLedger)
		{
			RiverCarveRecord value = item.Value;
			list.Add(new SavedRiverCarve
			{
				sourceIndex = value.sourceIndex,
				verts = value.verts,
				deltas = value.deltas,
				postCarveHeights = value.postCarveHeights,
				path = value.path,
				strengthLevel = GetCarveStrength(value.sourceIndex)
			});
		}
		return list;
	}

	public void RestoreRiverCarves(List<SavedRiverCarve> saved)
	{
		riverCarveLedger.Clear();
		carveStrengthLevels.Clear();
		if (saved == null)
		{
			return;
		}
		for (int i = 0; i < saved.Count; i++)
		{
			SavedRiverCarve savedRiverCarve = saved[i];
			riverCarveLedger[savedRiverCarve.sourceIndex] = new RiverCarveRecord
			{
				sourceIndex = savedRiverCarve.sourceIndex,
				verts = savedRiverCarve.verts,
				deltas = savedRiverCarve.deltas,
				postCarveHeights = savedRiverCarve.postCarveHeights,
				path = savedRiverCarve.path
			};
			if (savedRiverCarve.strengthLevel != 2)
			{
				SetCarveStrength(savedRiverCarve.sourceIndex, savedRiverCarve.strengthLevel);
			}
		}
	}

	private RiverCarveRecord RecordCarve(int sourceIndex)
	{
		float[] heightCache = TerrainGen.inst.heightCache;
		if (preCarveScratch == null || preCarveScratch.Length != heightCache.Length)
		{
			preCarveScratch = new float[heightCache.Length];
		}
		Array.Copy(heightCache, preCarveScratch, heightCache.Length);
		List<int> path = CutRiver(sourceIndex);
		List<int> list = new List<int>();
		List<float> list2 = new List<float>();
		List<float> list3 = new List<float>();
		for (int i = 0; i < heightCache.Length; i++)
		{
			if (heightCache[i] != preCarveScratch[i])
			{
				list.Add(i);
				list2.Add(heightCache[i] - preCarveScratch[i]);
				list3.Add(heightCache[i]);
			}
		}
		RiverCarveRecord riverCarveRecord = new RiverCarveRecord
		{
			sourceIndex = sourceIndex,
			verts = list.ToArray(),
			deltas = list2.ToArray(),
			postCarveHeights = list3.ToArray(),
			path = path
		};
		riverCarveLedger[sourceIndex] = riverCarveRecord;
		return riverCarveRecord;
	}

	public RiverCarveRecord CarveRiverFromSourceForEdit(int sourceIndex)
	{
		dynamicWaterJobHandle.Complete();
		localHeightMapCache.CopyFrom(TerrainGen.inst.heightCache);
		localObstructionMapCache.CopyFrom(TerrainGen.inst.waterObstructionField);
		RiverCarveRecord result = RecordCarve(sourceIndex);
		TerrainGen.inst.UpdateTerrainDeformations();
		return result;
	}

	public RiverCarveRecord UndoRiverCarveForEdit(int sourceIndex)
	{
		if (!riverCarveLedger.TryGetValue(sourceIndex, out var value))
		{
			return null;
		}
		riverCarveLedger.Remove(sourceIndex);
		dynamicWaterJobHandle.Complete();
		TerrainGen terrainGen = TerrainGen.inst;
		for (int i = 0; i < value.verts.Length; i++)
		{
			int num = value.verts[i];
			if (value.postCarveHeights == null || !(Mathf.Abs(terrainGen.heightCache[num] - value.postCarveHeights[i]) > 0.001f))
			{
				terrainGen.SetVert(num, terrainGen.heightCache[num] - value.deltas[i], bakeDown: true);
			}
		}
		if (value.path != null)
		{
			for (int j = 0; j < value.path.Count; j++)
			{
				int num2 = value.path[j];
				if (!(terrainGen.heightCache[num2] < -1f) && !(waterGrid[num2].waterProductionRate > 0f))
				{
					WaterCell value2 = waterGrid[num2];
					value2.waterAmount = 0f;
					value2.flux0 = (value2.flux1 = (value2.flux2 = (value2.flux3 = 0f)));
					waterGrid[num2] = value2;
				}
			}
		}
		terrainGen.UpdateTerrainDeformations();
		return value;
	}

	public void ReapplyCarveRecord(int sourceIndex, RiverCarveRecord rec)
	{
		if (rec == null)
		{
			return;
		}
		dynamicWaterJobHandle.Complete();
		TerrainGen terrainGen = TerrainGen.inst;
		for (int i = 0; i < rec.verts.Length; i++)
		{
			int num = rec.verts[i];
			if (rec.postCarveHeights == null || !(Mathf.Abs(terrainGen.heightCache[num] - (rec.postCarveHeights[i] - rec.deltas[i])) > 0.001f))
			{
				terrainGen.SetVert(num, terrainGen.heightCache[num] + rec.deltas[i], bakeDown: true);
			}
		}
		riverCarveLedger[sourceIndex] = rec;
		terrainGen.UpdateTerrainDeformations();
	}

	public List<int> CutRiver(int i)
	{
		List<int> list = new Astar<int>(Path, Hueristic, GetNeighbors).FindPath(i, FoundOcean);
		float num = CarveStrengthMultipliers[GetCarveStrength(i)];
		float num2 = localHeightMapCache[i];
		bool large = false;
		Vector3 pos = new Vector3((float)(i % width) / 2f, 0f, (float)(i / width) / 2f);
		TerrainGen.inst.GetGroundHeight(ref pos);
		Debug.DrawLine(pos, pos + Vector3.up, Color.magenta, 20f);
		int count = list.Count;
		float a = num2;
		int num3 = 0;
		for (int j = 0; j < count; j++)
		{
			int num4 = list[j];
			float num5 = Mathf.Lerp(a, 0f, (float)(j - num3) / (float)(count - num3));
			float num6 = localHeightMapCache[num4];
			float num7 = Mathf.Lerp(-0.3f, -0.2f, (float)j / (float)count);
			float num8 = num5 - num6;
			if (num8 < num7)
			{
				num7 = num8;
			}
			else
			{
				num3 = j;
				a = num6 - num7;
			}
			int prev = list[Mathf.Clamp(j - 1, 0, count - 1)];
			int next = list[Mathf.Clamp(j + 1, 0, count - 1)];
			if (num > 0f)
			{
				PressMesh(num4, num7 * num, large, prev, next);
			}
			WaterCell value = waterGrid[num4];
			value.waterAmount = 0.5f;
			if (j < count - 1)
			{
				int num9 = list[j + 1];
				if (num9 - num4 == 1)
				{
					value.flux3 = 1f;
				}
				else if (num9 - num4 == -1)
				{
					value.flux2 = 1f;
				}
				else if (num9 - num4 == width)
				{
					value.flux1 = 1f;
				}
				else if (num9 - num4 == -width)
				{
					value.flux0 = 1f;
				}
			}
			waterGrid[num4] = value;
			pos = new Vector3((float)(num4 % width) / 2f, 0f, (float)(num4 / width) / 2f);
			TerrainGen.inst.GetGroundHeight(ref pos);
			Debug.DrawLine(pos, pos + Vector3.up, Color.magenta, 30f);
		}
		return list;
	}

	private float Hueristic(int prev, int curr)
	{
		return localHeightMapCache[curr] + localObstructionMapCache[curr] * 100f - (localHeightMapCache[prev] + localObstructionMapCache[prev]);
	}

	private float Path(int prev, int curr)
	{
		return localHeightMapCache[curr] + localObstructionMapCache[curr] * 100f - (localHeightMapCache[prev] + localObstructionMapCache[prev]);
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

	private void PressMesh(int index, float amount, bool large, int prev, int next)
	{
		int num = index % width;
		int num2 = index / width;
		if (large)
		{
			amount /= 3f;
		}
		TerrainGen.inst.SoftDepressMesh(num, num2, amount);
		if (large)
		{
			if (index - 1 != prev && index - 1 != next)
			{
				TerrainGen.inst.SoftDepressMesh(num - 1, num2, amount);
			}
			if (index + 1 != prev && index + 1 != next)
			{
				TerrainGen.inst.SoftDepressMesh(num + 1, num2, amount);
			}
			if (index + width != prev && index + width != next)
			{
				TerrainGen.inst.SoftDepressMesh(num, num2 + 1, amount);
			}
			if (index - width != prev && index - width != next)
			{
				TerrainGen.inst.SoftDepressMesh(num, num2 - 1, amount);
			}
		}
	}

	public float GetExactWaterAmount(Vector3 worldPoint)
	{
		float num = inst.currentWaterHeightMap.GetPixel((int)(worldPoint.x * 2f), (int)(worldPoint.z * 2f)).r - inst.WaterMeshExtraHeight;
		float interpolatedHeight = TerrainGen.inst.GetInterpolatedHeight(worldPoint);
		return num - interpolatedHeight;
	}

	public WaterRaycastHit RaycastWater(Ray ray, float maxDistance = 1000f)
	{
		return RaycastWater(ray.origin, ray.direction, maxDistance);
	}

	public WaterRaycastHit RaycastWater(Vector3 rayOrigin, Vector3 rayDirection, float maxDistance = 1000f)
	{
		dynamicWaterJobHandle.Complete();
		NativeArray<float3> rayOriginWS = new NativeArray<float3>(1, Allocator.TempJob);
		NativeArray<float3> rayDirWS = new NativeArray<float3>(1, Allocator.TempJob);
		NativeArray<float> tHit = new NativeArray<float>(1, Allocator.TempJob);
		NativeArray<float3> pHit = new NativeArray<float3>(1, Allocator.TempJob);
		NativeArray<float3> nHit = new NativeArray<float3>(1, Allocator.TempJob);
		rayOriginWS[0] = new float3(rayOrigin.x, rayOrigin.y, rayOrigin.z);
		rayDirWS[0] = math.normalize(new float3(rayDirection.x, rayDirection.y, rayDirection.z));
		RaycastWaterJob raycastWaterJob = new RaycastWaterJob
		{
			gridOrigin = new float3(0f, 0f, 0f),
			tileSize = 1f,
			meshSizeX = width,
			meshSizeZ = height,
			heights = localHeightMapCache,
			obstructionMap = localObstructionMapCache,
			waterGrid = waterGrid,
			tilesX = World.inst.GridWidth,
			tilesZ = World.inst.GridHeight,
			rayOriginWS = rayOriginWS,
			rayDirWS = rayDirWS,
			tHit = tHit,
			pHit = pHit,
			nHit = nHit,
			tMaxGlobal = maxDistance,
			eps = 1E-06f,
			waterMeshExtraHeight = WaterMeshExtraHeight
		};
		raycastWaterJob.Execute(0);
		WaterRaycastHit result = default;
		if (tHit[0] >= 0f)
		{
			result.hit = true;
			result.distance = tHit[0];
			result.point = new Vector3(pHit[0].x, pHit[0].y, pHit[0].z);
			result.normal = new Vector3(nHit[0].x, nHit[0].y, nHit[0].z);
			int num = Mathf.FloorToInt(result.point.x);
			int num2 = Mathf.FloorToInt(result.point.z);
			if (num >= 0 && num < World.inst.GridWidth && num2 >= 0 && num2 < World.inst.GridHeight)
			{
				int index = MapWorldPosToMeshIndex(result.point, width);
				result.waterAmount = waterGrid[index].waterAmount;
			}
		}
		rayOriginWS.Dispose();
		rayDirWS.Dispose();
		tHit.Dispose();
		pHit.Dispose();
		nHit.Dispose();
		return result;
	}

	public void DebugUpdate()
	{
		if (!Input.GetKey(KeyCode.F12))
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
			dynamicWaterJobHandle.Complete();
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
		if (clickedOnceTimer.Update(Time.unscaledDeltaTime))
		{
			clickedOnceTimer.Enabled = false;
		}
	}

	public void DrawDebug()
	{
		if (!Input.GetKey(KeyCode.F12))
		{
			return;
		}
		dynamicWaterJobHandle.Complete();
		int num = 0;
		for (int i = 0; i < waterGrid.Length; i++)
		{
			WaterCell waterCell = waterGrid[i];
			float x = (float)(waterCell.index % width) / 2f;
			float z = (float)(waterCell.index / width) / 2f;
			if (waterCell.waterProductionRate > 0f)
			{
				Vector3 pos = new Vector3(x, 0f, z);
				pos.y = localHeightMapCache[i] + localObstructionMapCache[i];
				Matrix4x4 matrix = Matrix4x4.TRS(pos, Quaternion.identity, new Vector3(0.1f, waterCell.waterAmount, 0.1f));
				Graphics.DrawMesh(CubeMesh, matrix, WaterSourceMaterial, 0);
			}
			else if (waterCell.waterAmount > 0f)
			{
				Vector3 pos2 = new Vector3(x, 0f, z);
				pos2.y = localHeightMapCache[i] + localObstructionMapCache[i];
				Matrix4x4 matrix2 = Matrix4x4.TRS(pos2, Quaternion.identity, new Vector3(0.2f, waterCell.waterAmount, 0.2f));
				Graphics.DrawMesh(CubeMesh, matrix2, WaterSourceMaterialBlue, 0);
				num++;
			}
		}
	}

	public DynamicWaterSaveData SaveState()
	{
		return new DynamicWaterSaveData().Pack(this);
	}

	public void RestoreState(DynamicWaterSaveData data)
	{
		data.doTexturePriming = false;
		data.Unpack(this);
		needPostSimulationProcessing = false;
		forceResetWaterfalls = true;
		hasGoodData = false;
		forceUpdate = true;
	}

	internal void AddWaterToCellDeferred(Cell cell, float v)
	{
		waterAddRequests.Add(new DeferWaterAdd
		{
			cell = cell,
			amt = v
		});
	}
}
