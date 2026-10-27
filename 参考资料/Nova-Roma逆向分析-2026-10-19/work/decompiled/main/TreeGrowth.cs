using System;
using System.Collections.Generic;
using UnityEngine;

public class TreeGrowth : MonoBehaviour
{
	[Serializable]
	public class TreeSplotData
	{
		public enum Rate
		{
			Absolute,
			Per1000
		}

		public int radius;

		public int rate;

		public Rate rateType;
	}

	public struct PlacedSplots
	{
		public int radius;

		public Vector3 pos;
	}

	public static TreeGrowth inst;

	private bool growTrees;

	public float updateInterval = 1f;

	[Tooltip("% to grow a tree in a cell with trees, from min-max (0-max trees)")]
	public MinMax FillTileChance = new MinMax(0.4f, 0.8f);

	[Tooltip("% to grow a tree in a new cell, from min-max (0-4 neighboring cells with trees)")]
	public MinMax GrowToNewTileChance = new MinMax(0f, 0.2f);

	[Tooltip("rough % of area that should be covered in trees after infinite time (0-1)")]
	public float desiredTreeDensity = 0.5f;

	private Cell[] neighbors = new Cell[4];

	private int tickX;

	private int tickZ;

	private float cellsPerTick;

	private void Start()
	{
		inst = this;
		growTrees = true;
	}

	public static bool IsValidForTreePlanting(Cell cell)
	{
		if (cell.IsNull())
		{
			return false;
		}
		if (cell.Busy || cell.OccupyingStructure.Count > 0 || cell.SubStructure.Count > 0 || cell.Type != TerrainType.None)
		{
			return false;
		}
		if (cell.HasAnyWater())
		{
			return false;
		}
		return true;
	}

	private void TickGrowthForCell(int x, int z)
	{
		Cell cellData = World.inst.GetCellData(x, z);
		if (!IsValidForTreePlanting(cellData))
		{
			return;
		}
		float num = 0f;
		int num2 = World.inst.treeSystem.ItemAmount(cellData);
		if (num2 > 0 && num2 < World.inst.treeSystem.itemsPerCell)
		{
			num += FillTileChance.Lerp((float)num2 / (float)World.inst.treeSystem.itemsPerCell);
		}
		else if (num2 == 0)
		{
			int num3 = 0;
			World.inst.GetNeighborCells(cellData, ref neighbors);
			for (int i = 0; i < neighbors.Length; i++)
			{
				if (IsValidForTreePlanting(neighbors[i]) && World.inst.treeSystem.ItemAmount(neighbors[i]) > 0)
				{
					num3++;
				}
			}
			num += GrowToNewTileChance.Lerp((float)num3 / 4f);
		}
		if (num > 0f)
		{
			if (TerrainGen.inst.Fertility != null)
			{
				int effectiveFertility = cellData.GetEffectiveFertility();
				if (effectiveFertility == 0)
				{
					num *= 0.33f;
				}
				if (effectiveFertility == 2)
				{
					num *= 2f;
				}
			}
			float num4 = World.inst.treeSystem.EstimateTreeDensity(cellData.x, cellData.z) / desiredTreeDensity;
			num *= 1f - num4;
		}
		if (SRand.value < num && !EditTerrainProjectManager.inst.IsCellPartOfProject(cellData, out var _))
		{
			if (growTrees)
			{
				World.inst.treeSystem.GrowTree(cellData);
			}
			else
			{
				World.inst.treeSystem.PlaceItem(cellData);
			}
		}
	}

	private void TickGrowth()
	{
		for (int i = 0; i < World.inst.GridWidth; i++)
		{
			for (int j = 0; j < World.inst.GridHeight; j++)
			{
				TickGrowthForCell(i, j);
			}
		}
	}

	private void Update()
	{
		if (GameState.inst.CurrMode != GameState.inst.playingMode)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		float num = World.inst.GridWidth * World.inst.GridHeight;
		cellsPerTick += Mathff.Clamp(num / updateInterval * deltaTime, 0f, 50f);
		tickX = Mathf.Clamp(tickX, 0, World.inst.GridWidth - 1);
		tickZ = Mathf.Clamp(tickZ, 0, World.inst.GridHeight - 1);
		while (cellsPerTick > 0f)
		{
			TickGrowthForCell(tickX, tickZ);
			cellsPerTick--;
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

	public bool ToCloseToPlacedSplots(Vector3 pos, float rad, List<PlacedSplots> splotData)
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

	public void PlaceSplots(int lm, List<TreeSplotData> splotData)
	{
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[lm];
		Vector3 vector = arrayExt.RandomElement().Center2D;
		int num = 0;
		List<PlacedSplots> list = new List<PlacedSplots>();
		for (int i = 0; i < splotData.Count; i++)
		{
			int num2 = 0;
			if (splotData[i].rateType == TreeSplotData.Rate.Absolute)
			{
				num2 = splotData[i].rate;
			}
			else
			{
				float num3 = (float)splotData[i].rate / 1000f;
				num2 = Mathf.CeilToInt((float)arrayExt.Count * num3);
			}
			int num4 = 2;
			int radius = splotData[i].radius;
			float num5 = (float)radius * 0.3f;
			int num6 = radius * num4 * (radius * num4);
			for (int j = 0; j < num2; j++)
			{
				int num7 = 3;
				float f = SRand.Range(-3.1415f, 3.1415f);
				Vector3 vector2 = vector + new Vector3(Mathf.Cos(f), 0f, Mathf.Sin(f)) * (num + radius);
				Cell cellDataClamped = World.inst.GetCellDataClamped((int)vector2.x, (int)vector2.z);
				while ((cellDataClamped.Type != TerrainType.None || World.inst.treeSystem.ItemAmount(cellDataClamped) > 0 || ToCloseToPlacedSplots(vector2, radius, list)) && num7 > 0)
				{
					f = SRand.Range(-3.1415f, 3.1415f);
					vector2 = vector + new Vector3(Mathf.Cos(f), 0f, Mathf.Sin(f)) * ((float)(num + radius) * 0.7f);
					cellDataClamped = World.inst.GetCellDataClamped((int)vector2.x, (int)vector2.z);
					num7--;
				}
				if (num7 == 0)
				{
					vector2 = arrayExt.RandomElement().Center2D;
					cellDataClamped = World.inst.GetCellDataClamped((int)vector2.x, (int)vector2.z);
				}
				num7 = 5;
				while ((cellDataClamped.Type != TerrainType.None || World.inst.treeSystem.ItemAmount(cellDataClamped) > 0) && num7 > 0)
				{
					vector2 = arrayExt.RandomElement().Center2D;
					cellDataClamped = World.inst.GetCellDataClamped((int)vector2.x, (int)vector2.z);
					num7--;
				}
				int num8 = (int)Mathff.Clamp(vector2.x - (float)(radius * num4), 0f, gridWidth - 1);
				int num9 = (int)Mathff.Clamp(vector2.x + (float)(radius * num4), 0f, gridWidth - 1);
				int num10 = (int)Mathff.Clamp(vector2.z - (float)(radius * num4), 0f, gridHeight - 1);
				int num11 = (int)Mathff.Clamp(vector2.z + (float)(radius * num4), 0f, gridHeight - 1);
				for (int k = num8; k <= num9; k++)
				{
					for (int l = num10; l <= num11; l++)
					{
						float num12 = (vector2.x - (float)k) * (vector2.x - (float)k) + (vector2.z - (float)l) * (vector2.z - (float)l);
						if (!(num12 <= (float)num6))
						{
							continue;
						}
						float num13 = Mathf.Sqrt(num12);
						float value = 1f - (num13 - num5) / ((float)(radius * num4) - num5);
						value = Mathf.Clamp01(value);
						if (!(SRand.value <= value))
						{
							continue;
						}
						int num14 = SRand.Range(1, World.inst.treeSystem.itemsPerCell);
						if (value > 0.5f)
						{
							num14 = World.inst.treeSystem.itemsPerCell;
						}
						Cell cellData = World.inst.GetCellData(k, l);
						for (int m = 0; m < num14; m++)
						{
							if (World.inst.treeSystem.ItemAmount(cellData) < World.inst.treeSystem.itemsPerCell)
							{
								World.inst.treeSystem.PlaceItem(cellData);
							}
						}
					}
				}
				list.Add(new PlacedSplots
				{
					pos = vector2,
					radius = radius
				});
				vector = vector2;
				num = radius;
			}
		}
	}

	public void GenerateTrees()
	{
		growTrees = false;
		_ = World.inst.GridWidth;
		_ = World.inst.GridHeight;
		TickGrowth();
		growTrees = true;
	}
}
