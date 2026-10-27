using System.Collections.Generic;
using Unity.Collections;

public static class SculptCasualtyLog
{
	public class DrownedDeposit
	{
		public int x;

		public int z;

		public int sizeX;

		public int sizeZ;

		public int resourceID;
	}

	public class DrownedSpring
	{
		public int index;

		public float rate;

		public int strength;

		public DynamicWater.RiverCarveRecord record;
	}

	public class RecarvedSpring
	{
		public int index;

		public DynamicWater.RiverCarveRecord preRecord;
	}

	public class CellFieldChange
	{
		public int index;

		public TerrainType type;

		public bool deepWater;

		public bool ocean;

		public int trees;

		public int scatter;

		public bool fish;

		public int landmass;
	}

	public static bool armed;

	public static readonly List<DrownedDeposit> deposits = new List<DrownedDeposit>();

	public static readonly List<DrownedSpring> springs = new List<DrownedSpring>();

	public static readonly List<RecarvedSpring> recarvedSprings = new List<RecarvedSpring>();

	public static readonly List<CellFieldChange> cellChanges = new List<CellFieldChange>();

	public static readonly List<KeyValuePair<int, DynamicWater.WaterCell>> waterCells = new List<KeyValuePair<int, DynamicWater.WaterCell>>();

	public static bool waterCaptured;

	public static void Clear()
	{
		deposits.Clear();
		springs.Clear();
		recarvedSprings.Clear();
		cellChanges.Clear();
		waterCells.Clear();
		waterCaptured = false;
	}

	public static void CaptureWater()
	{
		DynamicWater.inst.dynamicWaterJobHandle.Complete();
		NativeArray<DynamicWater.WaterCell> waterGrid = DynamicWater.inst.waterGrid;
		for (int i = 0; i < waterGrid.Length; i++)
		{
			DynamicWater.WaterCell value = waterGrid[i];
			if (value.waterAmount > 0f || value.waterProductionRate > 0f || value.flux0 != 0f || value.flux1 != 0f || value.flux2 != 0f || value.flux3 != 0f)
			{
				waterCells.Add(new KeyValuePair<int, DynamicWater.WaterCell>(i, value));
			}
		}
		waterCaptured = true;
	}
}
