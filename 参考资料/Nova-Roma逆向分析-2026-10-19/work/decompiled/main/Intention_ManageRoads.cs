using System.Collections.Generic;
using UnityEngine;

public class Intention_ManageRoads : AIIntentionBase
{
	private Intention_BuildExactBuilding upgradeRoadIntention;

	private Intention_BuildExactBuilding gardenIntention;

	private FloodFillCrawler upgradeRoadFlood = new FloodFillCrawler();

	private Building stoneRoad;

	private Building stoneBridge;

	private Building garden;

	private FloodFillCrawler cleanupRoadFlood = new FloodFillCrawler();

	private Cell startCell;

	public int[] ignoreList = new int[4]
	{
		World.aqueductHash,
		World.woodengateHash,
		World.gateHash,
		World.pierHash
	};

	internal GoldInfo.WageInfo wageInfo;

	public void Init()
	{
		stoneRoad = GameState.inst.GetPlaceableByUniqueName(World.stoneRoadName);
		stoneBridge = GameState.inst.GetPlaceableByUniqueName(World.stoneBridgeName);
		garden = GameState.inst.GetPlaceableByUniqueName(World.gardenName);
		startCell = World.inst.FindMatchingSurroundingCell(World.inst.GetCellDataClamped(Layout.KingdomStart), testOrigin: false, 100, (Cell c) => Layout.GetAICell(c)?.Road ?? false);
		wageInfo = Kingdom.generateGoldIntention.wageInfo;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 64;
		if (startCell == null || !Layout.GetAICell(startCell).Road)
		{
			startCell = World.inst.FindMatchingSurroundingCell(World.inst.GetCellDataClamped(Layout.KingdomStart), testOrigin: false, 10, (Cell c) => Layout.GetAICell(c)?.Road ?? false);
		}
		else
		{
			cleanupRoadFlood.Tick(startCell.Position, CleanupRoadVisitCell);
			if (upgradeRoadIntention == null && wageInfo.taxIncome - wageInfo.totalWage > -5f && Kingdom.CurrentResources.Get(4) > 150 && Layout.kingdom.CurrentResources >= stoneRoad.GetCost(LandMass))
			{
				upgradeRoadFlood.Tick(startCell.Position, UpgradeRoadVisitCell);
			}
		}
		KillAndNullFinishedIntention(ref gardenIntention);
		KillAndNullFinishedIntention(ref upgradeRoadIntention);
		KillFinishedIntentions();
	}

	private bool UpgradeRoadVisitCell(Cell cell, ref List<Cell> openSet)
	{
		if (Layout.GetAICell(cell).Road)
		{
			if (cell.Type == TerrainType.Water)
			{
				if (cell.StructureFind(World.woodBridgeHash) != null)
				{
					if (Kingdom.CurrentResources >= stoneBridge.GetCost(LandMass))
					{
						upgradeRoadIntention = AddSubIntention<Intention_BuildExactBuilding>("build stone bridge");
						upgradeRoadIntention.Init(World.stoneBridgeName, cell.Position, 0f, demoExisting: true, skipPlacementValidation: false, ignoreList);
						upgradeRoadFlood.AddNonDeepWaterCardinalToOpenSet(cell);
					}
					else
					{
						openSet.Insert(0, cell);
						upgradeRoadFlood.visited[cell.z * World.inst.GridWidth + cell.x] = false;
					}
					return false;
				}
			}
			else if (cell.StructureFind(World.roadHash) != null)
			{
				if (Kingdom.CurrentResources >= stoneRoad.GetCost(LandMass))
				{
					upgradeRoadIntention = AddSubIntention<Intention_BuildExactBuilding>("build stone road");
					upgradeRoadIntention.Init(World.stoneRoadName, cell.Position, 0f, demoExisting: true, skipPlacementValidation: false, ignoreList);
					upgradeRoadFlood.AddNonDeepWaterCardinalToOpenSet(cell);
				}
				else
				{
					openSet.Insert(0, cell);
					upgradeRoadFlood.visited[cell.z * World.inst.GridWidth + cell.x] = false;
				}
				return false;
			}
			upgradeRoadFlood.AddNonDeepWaterCardinalToOpenSet(cell);
			return true;
		}
		return false;
	}

	private bool CleanupRoadVisitCell(Cell cell, ref List<Cell> openSet)
	{
		if (Layout.GetAICell(cell).Road)
		{
			if (cell.BottomStructureIsCategory(World.pathHash))
			{
				Vector3 position = cell.Position;
				if (!Layout.GetAICell((int)position.x, (int)position.z + 1).Road)
				{
					Cell cellDataClamped = World.inst.GetCellDataClamped((int)position.x, (int)position.z - 1);
					if (Layout.GetAICell(cellDataClamped).Road && !Layout.GetAICell((int)position.x, (int)position.z - 2).Road)
					{
						int num = 0;
						if (Layout.GetAICell((int)position.x + 1, (int)position.z).Road)
						{
							num++;
						}
						if (Layout.GetAICell((int)position.x - 1, (int)position.z).Road)
						{
							num++;
						}
						int num2 = 0;
						if (Layout.GetAICell((int)position.x + 1, (int)position.z - 1).Road)
						{
							num2++;
						}
						if (Layout.GetAICell((int)position.x - 1, (int)position.z - 1).Road)
						{
							num2++;
						}
						if ((num != 1 || num2 != 1) && (num != 0 || num2 < 1) && (num < 1 || num2 != 0))
						{
							Cell cell2 = ((num >= num2) ? cellDataClamped : cell);
							if (!cell2.BottomStructureIs(World.gardenHash) && cell2.BottomStructureIsCategory(World.pathHash))
							{
								World.inst.DemolishBuildingByAI(cell2.BottomStructure);
								AddToNearbyLayoutBlock(cell2);
							}
						}
					}
				}
				if (!Layout.GetAICell((int)position.x - 1, (int)position.z).Road)
				{
					Cell cellDataClamped2 = World.inst.GetCellDataClamped((int)position.x + 1, (int)position.z);
					if (Layout.GetAICell(cellDataClamped2).Road && !Layout.GetAICell((int)position.x + 2, (int)position.z).Road)
					{
						int num3 = 0;
						if (Layout.GetAICell((int)position.x, (int)position.z + 1).Road)
						{
							num3++;
						}
						if (Layout.GetAICell((int)position.x, (int)position.z - 1).Road)
						{
							num3++;
						}
						int num4 = 0;
						if (Layout.GetAICell((int)position.x + 1, (int)position.z + 1).Road)
						{
							num4++;
						}
						if (Layout.GetAICell((int)position.x + 1, (int)position.z - 1).Road)
						{
							num4++;
						}
						if ((num3 != 1 || num4 != 1) && (num3 != 0 || num4 < 1) && (num3 < 1 || num4 != 0))
						{
							Cell cell3 = ((num3 >= num4) ? cellDataClamped2 : cell);
							if (!cell3.BottomStructureIs(World.gardenHash) && cell3.BottomStructureIsCategory(World.pathHash))
							{
								World.inst.DemolishBuildingByAI(cell3.BottomStructure);
								AddToNearbyLayoutBlock(cell3);
							}
						}
					}
				}
			}
			else if (ValidForRoad(cell))
			{
				AICell aICell = Layout.GetAICell(cell);
				if (aICell?.buildingMeta != null && aICell.buildingMeta.uniqueName == World.gardenName && cell.Type != TerrainType.Water)
				{
					if (gardenIntention == null)
					{
						gardenIntention = AddSubIntention<Intention_BuildExactBuilding>("build garden");
						gardenIntention.Init(World.gardenName, cell.Position);
					}
				}
				else
				{
					Layout.AddDeferredRoad(cell);
				}
			}
			cleanupRoadFlood.AddNonDeepWaterCardinalToOpenSet(cell);
			return true;
		}
		return false;
	}

	public bool ValidForRoad(Cell cell)
	{
		if (cell.OccupyingStructure.Count > 0)
		{
			float angle = 0f;
			if (cell.TopStructureIs(World.aqueductHash) || (cell.BottomStructureIsCategory(World.castleblockHash) && !IsBeingBuilt(World.woodengateHash) && Layout.CellNeedsGate(cell, out angle)))
			{
				return true;
			}
			return false;
		}
		if (cell.Type == TerrainType.Water && !cell.deepWater)
		{
			return true;
		}
		if (cell.Type != TerrainType.None)
		{
			return false;
		}
		return true;
	}

	public void AddToNearbyLayoutBlock(Cell cell)
	{
		AICell aICell = Layout.GetAICell(cell);
		if (aICell == null)
		{
			return;
		}
		aICell.Road = false;
		aICell.buildingMeta = null;
		aICell.blockReference = null;
		Cell[] array = new Cell[4];
		World.inst.GetNeighborCells(cell, ref array);
		for (int i = 0; i < array.Length; i++)
		{
			AICell aICell2 = Layout.GetAICell(array[i]);
			if (aICell2 != null && aICell2.buildingMeta != null && aICell2.buildingMeta.type != AIBuildingBlockType.None && aICell2.buildingMeta.type != AIBuildingBlockType.Road)
			{
				AILayoutBlock aILayoutBlock = new AILayoutBlock();
				aILayoutBlock.GenerateTypeRectangle(1, 1, aICell2.buildingMeta.type);
				Layout.PlaceBlock(aICell.x, aICell.z, aILayoutBlock);
				if (aICell2.buildingMeta.type == AIBuildingBlockType.Food)
				{
					Kingdom.enoughFoodIntention.OutOfSpaceForFarms = false;
				}
				else if (aICell2.buildingMeta.type == AIBuildingBlockType.Residential)
				{
					Kingdom.enoughFoodResidential.completelyOutOfSpace = false;
				}
				break;
			}
		}
	}
}
