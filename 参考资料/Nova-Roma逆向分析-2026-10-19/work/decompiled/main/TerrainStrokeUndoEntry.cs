using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;

public class TerrainStrokeUndoEntry : IMapEditorUndoEntry
{
	private class BeachVegetation
	{
		public int x;

		public int z;

		public int trees;

		public int bushes;

		public int grass;

		public int dryGrass;
	}

	private readonly EditTerrainCursorMode mode;

	private readonly List<SculptCasualtyLog.DrownedDeposit> deposits;

	private readonly List<SculptCasualtyLog.DrownedSpring> springs;

	private readonly List<SculptCasualtyLog.RecarvedSpring> recarvedSprings;

	private readonly List<SculptCasualtyLog.CellFieldChange> cellChanges;

	private readonly List<KeyValuePair<int, DynamicWater.WaterCell>> waterCells;

	private readonly bool waterCaptured;

	private readonly List<BeachVegetation> beachVegetation = new List<BeachVegetation>();

	public static void RecordBeachDeletion(int x, int z, int trees, int bushes, int grass, int dryGrass)
	{
		if (MapEditorUndoStack.Peek() is TerrainStrokeUndoEntry { beachVegetation: var list })
		{
			list.Add(new BeachVegetation
			{
				x = x,
				z = z,
				trees = trees,
				bushes = bushes,
				grass = grass,
				dryGrass = dryGrass
			});
		}
	}

	public TerrainStrokeUndoEntry(EditTerrainCursorMode mode)
	{
		this.mode = mode;
		deposits = new List<SculptCasualtyLog.DrownedDeposit>(SculptCasualtyLog.deposits);
		springs = new List<SculptCasualtyLog.DrownedSpring>(SculptCasualtyLog.springs);
		recarvedSprings = new List<SculptCasualtyLog.RecarvedSpring>(SculptCasualtyLog.recarvedSprings);
		cellChanges = new List<SculptCasualtyLog.CellFieldChange>(SculptCasualtyLog.cellChanges);
		waterCells = new List<KeyValuePair<int, DynamicWater.WaterCell>>(SculptCasualtyLog.waterCells);
		waterCaptured = SculptCasualtyLog.waterCaptured;
		SculptCasualtyLog.Clear();
	}

	public void Undo()
	{
		HashSet<int> hashSet = new HashSet<int>();
		foreach (SculptCasualtyLog.CellFieldChange cellChange in cellChanges)
		{
			hashSet.Add(cellChange.index);
		}
		mode.BeginUndoCellGuard();
		foreach (SculptCasualtyLog.RecarvedSpring recarvedSpring in recarvedSprings)
		{
			DynamicWater.inst.UndoRiverCarveForEdit(recarvedSpring.index);
		}
		mode.PerformUndo();
		if (waterCaptured)
		{
			DynamicWater.inst.dynamicWaterJobHandle.Complete();
			NativeArray<DynamicWater.WaterCell> waterGrid = DynamicWater.inst.waterGrid;
			for (int i = 0; i < waterGrid.Length; i++)
			{
				waterGrid[i] = default;
			}
			foreach (KeyValuePair<int, DynamicWater.WaterCell> waterCell in waterCells)
			{
				waterGrid[waterCell.Key] = waterCell.Value;
			}
			DynamicWater.inst.PrimeTextures();
		}
		bool flag = false;
		foreach (SculptCasualtyLog.DrownedDeposit deposit in deposits)
		{
			Cell cellData = World.inst.GetCellData(deposit.x, deposit.z);
			if (cellData != null && !(cellData.terrainResource != null))
			{
				Object.Instantiate(TerrainGen.inst.GetTerrainResourcePrefabOfType(deposit.resourceID)).Init(new Vector2(deposit.sizeX, deposit.sizeZ), cellData);
				flag = true;
			}
		}
		foreach (SculptCasualtyLog.DrownedSpring spring in springs)
		{
			MapSelectionTool.RestoreSpringWithCarveRecord(spring.index, spring.rate, spring.strength, spring.record);
		}
		foreach (SculptCasualtyLog.RecarvedSpring recarvedSpring2 in recarvedSprings)
		{
			DynamicWater.inst.ReapplyCarveRecord(recarvedSpring2.index, recarvedSpring2.preRecord);
			MapSelectionTool.ReseatGeyser(recarvedSpring2.index);
		}
		if (flag)
		{
			TerrainGen.inst.UpdateTextures();
			TerrainGen.inst.UpdateTerrainDeformations();
			World.inst.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
		}
		if (springs.Count > 0)
		{
			MapSelectionTool.AfterUndoRefresh(springsChanged: true);
		}
		mode.RevertUnownedFields(hashSet);
		foreach (SculptCasualtyLog.CellFieldChange cellChange2 in cellChanges)
		{
			Cell cellData2 = World.inst.GetCellData(cellChange2.index % World.inst.GridWidth, cellChange2.index / World.inst.GridWidth);
			if (cellData2 != null)
			{
				cellData2.Type = cellChange2.type;
				cellData2.deepWater = cellChange2.deepWater;
				cellData2.partOfOcean = cellChange2.ocean;
				cellData2.StorePostGenerationType();
			}
		}
		mode.RevertUnownedItems(hashSet);
		foreach (SculptCasualtyLog.CellFieldChange cellChange3 in cellChanges)
		{
			int x = cellChange3.index % World.inst.GridWidth;
			int z = cellChange3.index / World.inst.GridWidth;
			Cell cellData3 = World.inst.GetCellData(x, z);
			if (cellData3 == null)
			{
				continue;
			}
			if (World.inst.treeSystem.ItemAmount(cellData3) != cellChange3.trees)
			{
				World.inst.treeSystem.DeleteTreesAt(cellData3);
				for (int j = 0; j < cellChange3.trees; j++)
				{
					World.inst.treeSystem.PlaceItem(cellData3, ignoreWater: true, allowOnMountains: true);
				}
			}
			if (World.inst.rockScatterSystem.ItemAmount(cellData3) != cellChange3.scatter)
			{
				World.inst.rockScatterSystem.DeleteTreesAt(cellData3);
				for (int k = 0; k < cellChange3.scatter; k++)
				{
					World.inst.rockScatterSystem.PlaceItem(cellData3, ignoreWater: true, allowOnMountains: true);
				}
			}
			FishSystem.FishCell fishCell = FishSystem.inst.fishCells[cellChange3.index];
			if ((fishCell.owners.Count > 0 || fishCell.baseProbability >= 0.99f) != cellChange3.fish)
			{
				if (cellChange3.fish)
				{
					FishSystem.inst.ForceFish(x, z);
				}
				else
				{
					FishSystem.inst.ForceClearFish(x, z);
				}
			}
		}
		foreach (BeachVegetation item in beachVegetation)
		{
			if (hashSet.Contains(item.x + item.z * World.inst.GridWidth))
			{
				continue;
			}
			Cell cellData4 = World.inst.GetCellData(item.x, item.z);
			if (cellData4 != null && cellData4.Type == TerrainType.None)
			{
				for (int l = 0; l < item.trees; l++)
				{
					World.inst.treeSystem.PlaceItem(cellData4, ignoreWater: true, allowOnMountains: true);
				}
				for (int m = 0; m < item.bushes; m++)
				{
					World.inst.bushesSystem.PlaceItem(cellData4, ignoreWater: true, allowOnMountains: true);
				}
				for (int n = 0; n < item.grass; n++)
				{
					World.inst.grassSystem.PlaceItem(cellData4, ignoreWater: true, allowOnMountains: true);
				}
				for (int num = 0; num < item.dryGrass; num++)
				{
					World.inst.dryGrassSystem.PlaceItem(cellData4, ignoreWater: true, allowOnMountains: true);
				}
			}
		}
		if (cellChanges.Count <= 0)
		{
			return;
		}
		World.inst.GenerateLandMassIds(fillInlandOceans: false, applyCleanup: false);
		mode.ReassertUnownedLandmass(hashSet);
		foreach (SculptCasualtyLog.CellFieldChange cellChange4 in cellChanges)
		{
			Cell cellData5 = World.inst.GetCellData(cellChange4.index % World.inst.GridWidth, cellChange4.index / World.inst.GridWidth);
			if (cellData5 != null)
			{
				cellData5.landMassIdx = cellChange4.landmass;
			}
		}
		TerrainGen.inst.RefreshCellLandmassCache();
		TerrainGen.inst.UpdateTextures();
		MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
	}
}
