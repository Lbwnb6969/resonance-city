using System;
using UnityEngine;

public class Intention_EnoughResidential : AIIntentionBase
{
	public bool completelyOutOfSpace;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Timer hovelPurgeTimer = new Timer(60f);

	private Vector2[] cardinalPositions = new Vector2[3]
	{
		new Vector2(0f, 1f),
		new Vector2(1f, 0f),
		new Vector2(1f, 1f)
	};

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		hovelPurgeTimer.ForceExpire();
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 85;
		int num = Player.inst.TotalWorkersForLandMass(LandMass);
		int num2 = Player.inst.TotalResidentialSlotsOnLandMass(LandMass);
		int num3 = World.inst.AvailableWorkersOnLandMass(LandMass);
		if ((float)num3 > (float)num * 0.15f || num3 > 25)
		{
			priority = 67;
		}
		if (num < 10 || (float)num * 0.65f > (float)num2)
		{
			priority = 89;
		}
		float num4 = num2;
		if (Kingdom.skillLevel == AIKingdom.SkillLevel.Low)
		{
			num4 = num2 - 1;
		}
		else if (Kingdom.skillLevel == AIKingdom.SkillLevel.Medium)
		{
			num4 = Mathff.Min((float)num2 * 0.9f, num2 - 5);
			if (num >= 50)
			{
				num4 = Mathff.Min((float)num2 * 0.9f, num2 - 10);
			}
			if (num >= 150)
			{
				num4 = Mathff.Min((float)num2 * 0.9f, num2 - 15);
			}
			if (num >= 300)
			{
				num4 = Mathff.Min((float)num2 * 0.95f, num2 - 15);
			}
		}
		else
		{
			num4 = Mathff.Min((float)num2 * 0.8f, num2 - 5);
			if (num >= 50)
			{
				num4 = Mathff.Min((float)num2 * 0.8f, num2 - 10);
			}
			if (num >= 150)
			{
				num4 = Mathff.Min((float)num2 * 0.8f, num2 - 20);
			}
			if (num >= 300)
			{
				num4 = Mathff.Min((float)num2 * 0.9f, num2 - 25);
			}
		}
		if (completelyOutOfSpace && hovelPurgeTimer.Update(dt))
		{
			DoHovelPurge();
		}
		if ((float)num >= num4 && !completelyOutOfSpace)
		{
			float num5 = (float)num - num4;
			int num6 = 3;
			int num7 = 0;
			if (num >= 50)
			{
				num7++;
			}
			if (num >= 150)
			{
				num7++;
			}
			Intention_BuildBuilding intention_BuildBuilding = null;
			for (int i = 0; i < subIntentions.Count; i++)
			{
				intention_BuildBuilding = (Intention_BuildBuilding)subIntentions[i];
				if (!intention_BuildBuilding)
				{
					continue;
				}
				if (intention_BuildBuilding.failType == FailType.LayoutBlockOutOfSpace)
				{
					switch (intention_BuildBuilding.pendingBuilding.UniqueName)
					{
					case "manorhouse":
						if (num7 > 1)
						{
							num7 = 1;
						}
						break;
					case "largehouse":
						if (num7 > 0)
						{
							num7 = 0;
						}
						break;
					case "smallhouse":
						num6 = 0;
						completelyOutOfSpace = !Kingdom.avoidPlacingResidentialOnFertile;
						break;
					}
				}
				else
				{
					if (intention_BuildBuilding.initSuccess)
					{
						completelyOutOfSpace = false;
					}
					num6--;
				}
			}
			while (num5 > 0f && num6 > 0)
			{
				string text = "";
				switch (num7)
				{
				case 0:
					text = "smallhouse";
					num5 -= 5f;
					break;
				case 1:
					text = "largehouse";
					num5 -= 12f;
					break;
				case 2:
					text = "manorhouse";
					num5 -= 25f;
					break;
				}
				Intention_BuildBuilding intention_BuildBuilding2 = AddSubIntention<Intention_BuildBuilding>("build new house");
				intention_BuildBuilding2.PlaceNewBlockIfNeeded = text == World.smallHouseName;
				intention_BuildBuilding2.Init(text, AIBuildingBlockType.Residential, Layout.KingdomStart);
				num6--;
			}
		}
		for (int j = 0; j < subIntentions.Count; j++)
		{
			if (subIntentions[j] != null && subIntentions[j].Done)
			{
				DestroyIntention(subIntentions[j]);
			}
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (completelyOutOfSpace)
		{
			Cell cell = obj.targetBuilding.GetCell();
			AIBuildingMeta buildingMeta = Layout.GetAICell(cell).buildingMeta;
			if (buildingMeta != null && buildingMeta.type == AIBuildingBlockType.Residential && (!obj.added || obj.targetBuilding.uniqueNameHash == World.pierHash))
			{
				completelyOutOfSpace = false;
			}
		}
	}

	private void DoHovelPurge()
	{
		Building building = null;
		Building building2 = null;
		bool flag = false;
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.smallHouseHash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			if (buildingListForLandMass.data[i] == null)
			{
				continue;
			}
			flag = false;
			building2 = buildingListForLandMass.data[i];
			Vector3 pos = building2.GetPos();
			for (int j = 0; j < 3; j++)
			{
				building = World.inst.GetCellData((int)(pos.x + cardinalPositions[j].x), (int)(pos.z + cardinalPositions[j].y))?.StructureFind(World.smallHouseHash);
				if (building != null)
				{
					flag = true;
					Layout.RemoveBuilding(building, reclaimResources: true);
				}
			}
			if (flag)
			{
				Layout.RemoveBuilding(building2, reclaimResources: true);
				completelyOutOfSpace = false;
			}
		}
	}
}
