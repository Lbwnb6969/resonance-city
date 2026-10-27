using System;
using System.Collections.Generic;
using UnityEngine;

public class Intention_EnoughFood : AIIntentionBase
{
	private int FOOD_TO_FARM = 5;

	private int FOOD_TO_ORCHARD = 45;

	private Vector3 lastFoodStorage;

	private EventHandler<SeasonEventData> seasonEventHandler;

	private EventHandler<OnBuildingAddRemove> buildingEventHandler;

	public bool OutOfSpaceForFarms;

	private float wheatMultiply = 1f;

	private float appleMultiply = 0.25f;

	private ArrayExt<ArrayExt<Building>> houseBuidings = new ArrayExt<ArrayExt<Building>>(5);

	private Vector3 idealPosition;

	private Intention_BuildExactBuilding buildReservoir;

	private const int MAX_RESERVOIR_DISTANCE = 128;

	private FloodFillCrawler roadCrawler = new FloodFillCrawler();

	private Vector3 roadPos;

	public bool OutOfSpaceForReservoir;

	public void Init()
	{
		seasonEventHandler = Broadcast.SeasonEvent.Listen(OnSeasonChange);
		buildingEventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		lastFoodStorage = Layout.KingdomStart;
		roadCrawler.cellsPerFrame = 32;
		idealPosition = Layout.KingdomGridStart;
	}

	private void OnDisable()
	{
		Broadcast.SeasonEvent.Unlisten(seasonEventHandler);
		Broadcast.BuildingAddRemove.UnlistenAny(buildingEventHandler);
	}

	private void Close(ArrayExt<Building> bList, int toClose)
	{
		for (int i = 0; i < bList.Count; i++)
		{
			bList.data[i].Open = true;
		}
		int houseHash = "house".GetHashCode();
		for (int j = 1; j < bList.Count; j++)
		{
			if (toClose <= 0)
			{
				break;
			}
			if (World.inst.FindMatchingSurroundingCell(bList.data[j].GetCell(), testOrigin: false, 9, (Cell c) => c.StructureCompareCategory(houseHash)) == null)
			{
				bList.data[j].Open = false;
				toClose--;
			}
		}
		for (int num = 0; num < bList.Count; num++)
		{
			if (toClose <= 0)
			{
				break;
			}
			if (bList.data[num].Open)
			{
				bList.data[num].Open = false;
				toClose--;
			}
		}
	}

	private void OnSeasonChange(object sender, SeasonEventData seasonEvent)
	{
		if (seasonEvent.SeasonDefinition.id != 0)
		{
			return;
		}
		int num = Player.inst.TotalWorkersForLandMass(LandMass);
		int num2 = Player.inst.TotalResidentialSlotsOnLandMass(LandMass);
		float num3 = 0.85f;
		float num4 = 0.8f;
		if ((float)Kingdom.CurrentResources.Get(0) <= (float)num2 * wheatMultiply)
		{
			num3 = 1f;
		}
		if ((float)Kingdom.CurrentResources.Get(9) <= (float)num2 * appleMultiply)
		{
			num4 = 1.1f;
		}
		int num5 = (int)Mathff.Max(1f, (float)(num / FOOD_TO_FARM) * num3);
		int num6 = (int)Mathff.Max(1f, (float)(num / FOOD_TO_ORCHARD) * num4);
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.farmHash);
		int count = buildingListForLandMass.Count;
		ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.orchardHash);
		int count2 = buildingListForLandMass2.Count;
		int num7 = (int)((float)num * 2.5f);
		int num8 = Player.inst.storagePerLandmass[LandMass].Get(0);
		int num9 = (int)((float)num * 2.5f);
		int num10 = Player.inst.storagePerLandmass[LandMass].Get(9);
		if (subIntentions.Count == 0 && !OutOfSpaceForFarms)
		{
			idealPosition = Layout.KingdomGridStart;
			bool flag = false;
			houseBuidings.ClearFast();
			Player.inst.GetBuildingListsByCategoryForLandMass(LandMass, World.houseCategoryHash, ref houseBuidings);
			for (int i = 0; i < houseBuidings.Count; i++)
			{
				for (int j = 0; j < houseBuidings.data[i].Count; j++)
				{
					Home component = houseBuidings.data[i].data[j].GetComponent<Home>();
					if (!component.foodExists && component.Residents.Count > 0)
					{
						idealPosition = component.transform.position;
						flag = true;
						break;
					}
				}
				if (flag)
				{
					break;
				}
			}
			int num11 = num5 - count;
			for (int k = 0; k < num11 && k < 5; k++)
			{
				AddSubIntention<Intention_BuildBuilding>("build new farm").Init(World.farmName, AIBuildingBlockType.Food, idealPosition);
			}
			int num12 = num6 - count2;
			for (int l = 0; l < num12 && l < 5; l++)
			{
				AddSubIntention<Intention_BuildBuilding>("build new orchard").Init(World.orchardName, AIBuildingBlockType.Food, idealPosition);
			}
			if (num7 > num8)
			{
				AddSubIntention<Intention_BuildBuilding>("build new granary").Init(World.smallGranaryName, AIBuildingBlockType.Food, idealPosition);
			}
			if (num9 > num10)
			{
				AddSubIntention<Intention_BuildBuilding>("build new produce stand").Init(World.produceStandName, AIBuildingBlockType.Food, idealPosition);
			}
		}
		int toClose = count - num5;
		Close(buildingListForLandMass, toClose);
		int toClose2 = count2 - num6;
		Close(buildingListForLandMass2, toClose2);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 90;
		if (OutOfSpaceForFarms && !OutOfSpaceForReservoir && buildReservoir == null && !Kingdom.manageWaterSystem.CompletelyOutOfSpaceForNoria)
		{
			TryBuildReservoir();
		}
		for (int i = 0; i < subIntentions.Count; i++)
		{
			Intention_BuildBuilding intention_BuildBuilding = subIntentions[i] as Intention_BuildBuilding;
			if (intention_BuildBuilding != null && intention_BuildBuilding.failType == FailType.LayoutBlockOutOfSpace && intention_BuildBuilding.pendingBuilding.uniqueNameHash == World.farmHash)
			{
				OutOfSpaceForFarms = true;
			}
			if (subIntentions[i].Done)
			{
				DestroyIntention(subIntentions[i]);
			}
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (!obj.added && obj.targetBuilding != null)
		{
			AICell aICell = Layout.GetAICell(obj.targetBuilding.GetCell());
			if (aICell != null && aICell.buildingMeta != null && aICell.buildingMeta.type == AIBuildingBlockType.Food)
			{
				OutOfSpaceForFarms = false;
			}
		}
	}

	public void TryBuildReservoir()
	{
		Player.inst.GetBuildingListForLandMass(LandMass, World.reservoirHash);
		OutOfSpaceForReservoir = true;
	}

	private bool RoadVisitCell(Cell cell, ref List<Cell> openSet)
	{
		if (Layout.GetAICell(cell).Road && !Layout.GetDefenceCell(cell).CastleEdge && cell.Type == TerrainType.None && !cell.StructureFind(World.noriaHash))
		{
			roadPos = cell.Position;
			openSet.Clear();
			return false;
		}
		roadCrawler.AddNonDeepWaterCardinalToOpenSet(cell);
		return true;
	}
}
