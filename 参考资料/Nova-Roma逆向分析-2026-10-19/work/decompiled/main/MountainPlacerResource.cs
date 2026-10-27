using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

public class MountainPlacerResource : MonoBehaviour
{
	[Serializable]
	public struct ResourceVariant
	{
		public int resourceID;

		[NonSerialized]
		public Transform[] resourcePos;

		public Transform container;
	}

	public static int[] ResourcePriorityOrder = new int[3] { 2, 5, 14 };

	public static int DesiredStone = 3;

	public static int DesiredIron = 1;

	public static int DesiredMarble = 1;

	public static float Density = 1f;

	[NonSerialized]
	public Dictionary<int, ResourceVariant> resourcVariantDict;

	[SerializeField]
	public List<ResourceVariant> resourceVariants;

	public static ValueDropdownList<int> ValidResourceTypes = new ValueDropdownList<int>
	{
		{ "Any", -1 },
		{ "Stone", 2 },
		{ "Marble", 14 },
		{ "Iron", 5 }
	};

	private static List<int> scratchResourcePosOrder = new List<int>(16);

	private const int GrowAttempts = 4;

	private static readonly RectangleFinder.ValidCell IsFreeCell = (int x, int z) =>
	{
		Cell cellData = World.inst.GetCellData(x, z);
		return cellData != null && cellData.Type == TerrainType.None;
	};

	public static int GetDesired(int rID)
	{
		return rID switch
		{
			14 => DesiredMarble, 
			2 => DesiredStone, 
			_ => DesiredIron, 
		};
	}

	private void Awake()
	{
		resourcVariantDict = new Dictionary<int, ResourceVariant>(8);
		for (int i = 0; i < resourceVariants.Count; i++)
		{
			ResourceVariant value = resourceVariants[i];
			if (value.container != null)
			{
				value.resourcePos = new Transform[value.container.childCount];
				for (int j = 0; j < value.container.childCount; j++)
				{
					value.resourcePos[j] = value.container.GetChild(j);
				}
			}
			resourcVariantDict.TryAdd(value.resourceID, value);
		}
	}

	private static int RoundStochastic(float v)
	{
		int num = (int)v;
		float num2 = v - (float)num;
		if (!(num2 > 0f) || !(SRand.value < num2))
		{
			return num;
		}
		return num + 1;
	}

	private static Cell CalculateCellForResourcePosition(Transform block, out int sizeX, out int sizeZ)
	{
		sizeX = (int)block.localScale.x;
		sizeZ = (int)block.localScale.z;
		float num = Mathf.RoundToInt((block.position.x - (float)sizeX / 2f) / 0.5f);
		float num2 = Mathf.RoundToInt((block.position.z - (float)sizeZ / 2f) / 0.5f);
		return World.inst.GetCellData(new Vector3(num * 0.5f, 0f, num2 * 0.5f));
	}

	public static bool TryPlaceResource(ResourceVariant rVariant, int rID)
	{
		bool result = false;
		if (rVariant.resourcePos == null)
		{
			_ = 0;
		}
		int num = rVariant.resourcePos.Length;
		int num2 = Mathf.Clamp(RoundStochastic((float)num * Mathf.Min(Density, 1f)), 1, num);
		scratchResourcePosOrder.Clear();
		for (int i = 0; i < num; i++)
		{
			scratchResourcePosOrder.Add(i);
		}
		if (num2 < num)
		{
			for (int j = 0; j < num2; j++)
			{
				int num3 = SRand.Range(j, num);
				List<int> list = scratchResourcePosOrder;
				int index = j;
				List<int> list2 = scratchResourcePosOrder;
				int index2 = num3;
				int num4 = scratchResourcePosOrder[num3];
				int num5 = scratchResourcePosOrder[j];
				int num6 = (list[index] = num4);
				num6 = (list2[index2] = num5);
			}
		}
		for (int k = 0; k < num2; k++)
		{
			Cell cell = CalculateCellForResourcePosition(rVariant.resourcePos[scratchResourcePosOrder[k]], out var sizeX, out var sizeZ);
			if (cell == null)
			{
				continue;
			}
			if (sizeX == 1 && sizeZ == 1)
			{
				if (cell.Type == TerrainType.None)
				{
					PlaceResource(cell, Vector2.one, rID);
					result = true;
				}
				continue;
			}
			for (RectangleFinder.RectangleCoordinates rectangleCoordinates = RectangleFinder.FindLargestRectangle(cell.x, cell.x + sizeX, cell.z, cell.z + sizeZ - 1, IsFreeCell); rectangleCoordinates != null; rectangleCoordinates = RectangleFinder.FindLargestRectangle(cell.x, cell.x + sizeX, cell.z, cell.z + sizeZ - 1, IsFreeCell))
			{
				if (rectangleCoordinates.upperX - rectangleCoordinates.lowerX > sizeX || rectangleCoordinates.upperZ - rectangleCoordinates.lowerZ > sizeZ)
				{
					Debug.Log("Placed Oversized Resource");
				}
				PlaceResource(World.inst.GetCellData(rectangleCoordinates.lowerX, rectangleCoordinates.lowerZ), new Vector2(rectangleCoordinates.upperX - rectangleCoordinates.lowerX, rectangleCoordinates.upperZ - rectangleCoordinates.lowerZ), rID);
				result = true;
			}
		}
		int num9 = ((Density > 1f) ? RoundStochastic((float)num * (Density - 1f)) : 0);
		for (int l = 0; l < num9; l++)
		{
			for (int m = 0; m < 4; m++)
			{
				Cell cell2 = CalculateCellForResourcePosition(rVariant.resourcePos[scratchResourcePosOrder[SRand.Range(0, num2)]], out var sizeX2, out var sizeZ2);
				if (cell2 != null)
				{
					int num10 = SRand.Range(0, 4);
					bool flag = num10 < 2;
					int x;
					if (flag)
					{
						x = ((num10 == 0) ? (cell2.x - 1) : (cell2.x + sizeX2));
					}
					else
					{
						x = cell2.x + SRand.Range(0, sizeX2);
					}
					int z;
					if (flag)
					{
						z = cell2.z + SRand.Range(0, sizeZ2);
					}
					else
					{
						z = ((num10 == 2) ? (cell2.z - 1) : (cell2.z + sizeZ2));
					}
					Cell cellData = World.inst.GetCellData(x, z);
					if (cellData != null && cellData.Type == TerrainType.None)
					{
						PlaceResource(cellData, Vector2.one, rID);
						result = true;
						break;
					}
				}
			}
		}
		return result;
	}

	public static void PlaceResource(Cell c, Vector2 size, int rID)
	{
		UnityEngine.Object.Instantiate(TerrainGen.inst.GetTerrainResourcePrefabOfType(rID)).Init(size, c, Vector3.zero);
	}
}
