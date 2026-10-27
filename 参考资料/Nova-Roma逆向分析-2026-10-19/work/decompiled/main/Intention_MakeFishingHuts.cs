using System;
using System.Collections.Generic;
using UnityEngine;

public class Intention_MakeFishingHuts : AIIntentionBase
{
	private Intention_BuildExactBuilding fishingHutIntention;

	private Intention_BuildBuilding fishMongerIntention;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Vector3 lastHut;

	private FloodFillCrawler flood = new FloodFillCrawler();

	private Cell[] cellsExtended = new Cell[4];

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		lastHut = Layout.KingdomStart;
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() != LandMass || !obj.added || World.inst.GetVillagersForLandMass(LandMass).Count < 125)
		{
			return;
		}
		if (obj.targetBuilding.uniqueNameHash == World.fishinghutHash)
		{
			lastHut = obj.targetBuilding.Center();
		}
		if (obj.targetBuilding.uniqueNameHash == World.fishinghutHash && fishMongerIntention == null && !IsBeingBuilt(World.fishMongerHash))
		{
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.fishinghutHash);
			ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.fishMongerHash);
			if (Mathff.Max(1, buildingListForLandMass.Count / 7) > buildingListForLandMass2.Count && Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.fishMongerHash))
			{
				fishMongerIntention = AddSubIntention<Intention_BuildBuilding>("build monger");
				fishMongerIntention.Init("fishmonger", AIBuildingBlockType.Civic, lastHut, 15);
			}
		}
	}

	private bool VisitCell(Cell cell, ref List<Cell> openSet)
	{
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		AICell aICell = Layout.GetAICell(cell);
		DefenseCell defenceCell = Layout.GetDefenceCell(cell);
		if (cell.Type == TerrainType.Water && cell.OccupyingStructure.Count == 0 && !cell.deepWater && !aICell.invalid && (aICell.buildingMeta == null || !aICell.buildingMeta.inDevelopment) && !defenceCell.CastleEdge)
		{
			World.inst.GetNeighborCells(cell, ref cellsExtended);
			bool flag = false;
			for (int i = 0; i < cellsExtended.Length; i++)
			{
				if (cellsExtended[i].Type == TerrainType.None)
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				bool flag2 = false;
				int num = 0;
				int num2 = 3;
				int num3 = Mathf.Clamp(cell.x - num2, 0, gridWidth - 1);
				int num4 = Mathf.Clamp(cell.z - num2, 0, gridHeight - 1);
				int num5 = Mathf.Clamp(cell.x + num2, 0, gridWidth - 1);
				int num6 = Mathf.Clamp(cell.z + num2, 0, gridHeight - 1);
				for (int j = num4; j <= num6; j++)
				{
					for (int k = num3; k <= num5; k++)
					{
						if (FishSystem.inst.fishCells[j * gridWidth + k].owners.Count > 0)
						{
							num++;
						}
						Cell cellData = World.inst.GetCellData(k, j);
						if (cellData != null && cellData.StructureGetUniqueNameHash() == World.fishinghutHash)
						{
							flag2 = true;
						}
					}
				}
				if (!flag2 && num >= 6)
				{
					if (fishingHutIntention == null && !IsBeingBuilt(World.fishinghutHash))
					{
						fishingHutIntention = AddSubIntention<Intention_BuildExactBuilding>("build " + World.fishinghutName);
						fishingHutIntention.Init(World.fishinghutName, cell.Position, 0f, demoExisting: true);
					}
					return false;
				}
			}
		}
		flood.AddNonDeepWaterCardinalToOpenSet(cell);
		return true;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 67;
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(LandMass);
		if (villagersForLandMass.Count >= 75)
		{
			int num = villagersForLandMass.Count / 75;
			if (Player.inst.GetBuildingListForLandMass(LandMass, World.fishinghutHash).Count < num && Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.fishinghutHash) && fishingHutIntention == null)
			{
				flood.Tick(Layout.KingdomStart, VisitCell);
			}
			KillAndNullFinishedIntention(ref fishingHutIntention);
		}
	}
}
