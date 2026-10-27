using System;
using Assets.Code;
using UnityEngine;

public class Intention_FoodDistribution : AIIntentionBase
{
	private EventHandler<SeasonEventData> eventHandle;

	private Intention_BuildExactBuilding buildIntention;

	private bool needMarket;

	private Vector3 targetPos;

	public void Init()
	{
		eventHandle = Broadcast.SeasonEvent.Listen(OnSeasonChange);
	}

	private void OnDisable()
	{
		Broadcast.SeasonEvent.Unlisten(eventHandle);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 69;
		if (buildIntention == null && needMarket)
		{
			AILayoutBlock aILayoutBlock = Layout.FindLayoutBlockOfTypeClosest(AIBuildingBlockType.Residential, targetPos, 2, 2);
			if (aILayoutBlock != null)
			{
				int minX = Mathf.Clamp(aILayoutBlock.posX, 0, World.inst.GridWidth - 1);
				int maxX = Mathf.Clamp(aILayoutBlock.posX + aILayoutBlock.SizeX, 0, World.inst.GridWidth - 1);
				int minZ = Mathf.Clamp(aILayoutBlock.posZ, 0, World.inst.GridWidth - 1);
				int maxZ = Mathf.Clamp(aILayoutBlock.posZ + aILayoutBlock.SizeZ, 0, World.inst.GridWidth - 1);
				RectangleFinder.RectangleCoordinates rectangleCoordinates = RectangleFinder.FindFirstRectangle(minX, maxX, minZ, maxZ, 2, 2, IsCellValid);
				if (rectangleCoordinates != null && rectangleCoordinates.area == 4)
				{
					buildIntention = AddSubIntention<Intention_BuildExactBuilding>("build new market");
					buildIntention.Init(World.marketName, new Vector3(rectangleCoordinates.lowerX, 0f, rectangleCoordinates.lowerZ), 0f, demoExisting: true);
					needMarket = false;
				}
			}
		}
		KillAndNullFinishedIntention(ref buildIntention);
	}

	private bool IsCellValid(int x, int z)
	{
		Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(x, z);
		if (cellDataUnsafe.Type == TerrainType.None)
		{
			if (cellDataUnsafe.OccupyingStructure.Count != 0)
			{
				return cellDataUnsafe.BottomStructureIsCategory(World.houseCategoryHash);
			}
			return true;
		}
		return false;
	}

	private void OnSeasonChange(object sender, SeasonEventData seasonEvent)
	{
		if (SeasonManager.inst.CurrentYear() <= 15 || seasonEvent.SeasonDefinition.id != 2)
		{
			return;
		}
		ResourceAmount previousConsumption = ResourceStatistics.GetPreviousConsumption(LandMass);
		ResourceAmount previousConsumption2 = ResourceStatistics.GetPreviousConsumption(LandMass);
		float num = previousConsumption.Get(0) + previousConsumption.Get(9) + previousConsumption.Get(11) + previousConsumption.Get(8) + previousConsumption.Get(10);
		float num2 = previousConsumption2.Get(0) + previousConsumption2.Get(9) + previousConsumption2.Get(11) + previousConsumption2.Get(8) + previousConsumption2.Get(10);
		if (!(num - num2 > 0f) || !(buildIntention == null))
		{
			return;
		}
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(LandMass);
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.marketHash);
		for (int i = 0; i < villagersForLandMass.Count; i++)
		{
			Villager villager = villagersForLandMass.data[i];
			if (villager.Residence == null || villager.Residence.Equals(null))
			{
				continue;
			}
			Building component = (villager.Residence as MonoBehaviour).GetComponent<Building>();
			if (component == null)
			{
				continue;
			}
			Vector3 pos = component.GetPos();
			bool flag = false;
			for (int j = 0; j < buildingListForLandMass.Count; j++)
			{
				if (Mathff.DistSqrdXZ(pos, buildingListForLandMass.data[j].GetPos()) < 400f)
				{
					flag = true;
					break;
				}
			}
			if (!flag)
			{
				targetPos = pos;
				needMarket = true;
				break;
			}
		}
	}
}
