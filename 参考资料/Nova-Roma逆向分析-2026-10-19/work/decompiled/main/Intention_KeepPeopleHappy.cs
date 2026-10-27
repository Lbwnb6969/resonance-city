using System;
using System.Collections.Generic;
using UnityEngine;

public class Intention_KeepPeopleHappy : AIIntentionBase
{
	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Dictionary<int, Intention_BuildBuilding> buildIntention = new Dictionary<int, Intention_BuildBuilding>(64);

	private Vector3 lastResidenceMade;

	private ArrayExt<int> deferralRemoval = new ArrayExt<int>(32);

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		lastResidenceMade = Layout.KingdomStart;
	}

	private string InfoTileUICategoryToString(int tileID)
	{
		switch (tileID)
		{
		case 210:
			return "cathedral";
		case 205:
			return "church";
		case 214:
			return "";
		case 211:
			return "greatlibrary";
		case 209:
			return "joustingarena";
		case 206:
			return "library";
		case 213:
			Debug.LogError("no string for this");
			return "";
		case 204:
			return "tavern";
		case 212:
			return "townsquare";
		case 207:
			return "bathhouse";
		default:
			return "";
		}
	}

	public bool IsResidentialTileBeingBuilt(int tileID)
	{
		if (tileID == 213)
		{
			if (!IsBeingBuilt("statue_sam".GetHashCode()) && !IsBeingBuilt("statue_barbara".GetHashCode()))
			{
				return IsBeingBuilt("statue_levi".GetHashCode());
			}
			return true;
		}
		int hashCode = InfoTileUICategoryToString(tileID).GetHashCode();
		return IsBeingBuilt(hashCode);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() != LandMass || !obj.added || !(obj.targetBuilding.CategoryName == "house"))
		{
			return;
		}
		lastResidenceMade = obj.targetBuilding.transform.position;
		Player.HappinessInfo landmassHappiness = Player.inst.GetLandmassHappiness(LandMass);
		Cell cell = obj.targetBuilding.GetCell();
		CellInfluence cellInfluenceDataClamped = World.inst.GetCellInfluenceDataClamped(cell.x, cell.z);
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(LandMass);
		List<int> list = new List<int>();
		if (landmassHappiness.bathhouseNeed > 0f)
		{
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.bathhouseHash);
			bool flag = true;
			for (int i = 0; i < buildingListForLandMass.Count; i++)
			{
				IWaterSystemUser component = buildingListForLandMass.data[i].GetComponent<IWaterSystemUser>();
				if (!component.HasWater || !component.IsConnected)
				{
					flag = false;
					break;
				}
			}
			if (flag)
			{
				list.Add(207);
			}
		}
		int count = Player.inst.GetBuildingListForLandMass(LandMass, World.cathedralHash).Count;
		if (villagersForLandMass.Count > 1000 && count < 2)
		{
			list.Add(210);
		}
		if (villagersForLandMass.Count > 50)
		{
			list.Add(205);
		}
		int count2 = Player.inst.GetBuildingListForLandMass(LandMass, World.greatLibraryHash).Count;
		if (villagersForLandMass.Count > 1000 && Kingdom.allowLibraries && count2 < 2)
		{
			list.Add(211);
		}
		if (villagersForLandMass.Count > 1000)
		{
			list.Add(209);
		}
		if (villagersForLandMass.Count > 50 && Kingdom.allowLibraries)
		{
			list.Add(206);
		}
		if (villagersForLandMass.Count > 500)
		{
			list.Add(213);
		}
		list.Add(204);
		list.Add(212);
		for (int j = 0; j < cellInfluenceDataClamped.radiusBonuses.Count; j++)
		{
			list.Remove(cellInfluenceDataClamped.radiusBonuses.data[j].residentialTileID);
		}
		foreach (KeyValuePair<int, Intention_BuildBuilding> item in buildIntention)
		{
			if (item.Value != null || IsResidentialTileBeingBuilt(item.Key))
			{
				list.Remove(item.Key);
			}
		}
		for (int k = 0; k < list.Count; k++)
		{
			int num = list[k];
			if (num != 212 && num != 204 && LandmassOwner.MaxGoldStorage <= 0)
			{
				continue;
			}
			switch (num)
			{
			case 213:
			{
				string uniqueName = "statue_levi";
				int num2 = SRand.Range(0, 3);
				if (num2 == 0)
				{
					uniqueName = "statue_sam";
				}
				if (num2 == 1)
				{
					uniqueName = "statue_barbara";
				}
				if (num2 == 2)
				{
					uniqueName = "statue_levi";
				}
				Intention_BuildBuilding intention_BuildBuilding3 = AddSubIntention<Intention_BuildBuilding>("build new statue");
				intention_BuildBuilding3.Init(uniqueName, AIBuildingBlockType.Residential, lastResidenceMade, 15);
				buildIntention.Add(213, intention_BuildBuilding3);
				break;
			}
			case 207:
			{
				int rot = 0;
				Cell cell2 = null;
				Kingdom.manageWaterSystem.FindNoriaPosition(ref cell2, ref rot, lastResidenceMade);
				if (cell2 != null && Mathff.DistSqrdXZ(cell2.Position, lastResidenceMade) <= 90f)
				{
					Intention_BuildBuilding intention_BuildBuilding2 = AddSubIntention<Intention_BuildBuilding>("build new bathhouse");
					intention_BuildBuilding2.Init("bathhouse", AIBuildingBlockType.Residential, lastResidenceMade, 4);
					buildIntention.Add(num, intention_BuildBuilding2);
				}
				break;
			}
			default:
			{
				Intention_BuildBuilding intention_BuildBuilding = AddSubIntention<Intention_BuildBuilding>("build new " + InfoTileUICategoryToString(num));
				intention_BuildBuilding.Init(InfoTileUICategoryToString(num), AIBuildingBlockType.Residential, lastResidenceMade, 15);
				buildIntention.Add(num, intention_BuildBuilding);
				break;
			}
			}
		}
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private bool CheckPriority(int tileID, bool penalty, int hashCompare)
	{
		buildIntention.TryGetValue(tileID, out var value);
		if (value != null && value.pendingBuilding != null && ((value.pendingBuilding.uniqueNameHash == hashCompare) & penalty))
		{
			value.transform.SetAsFirstSibling();
			return true;
		}
		return false;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 67;
		Player.HappinessInfo landmassHappiness = Player.inst.GetLandmassHappiness(LandMass);
		priority = 65;
		if ((0u | (CheckPriority(204, landmassHappiness.shopPenalty, World.tavernHash) ? 1u : 0u) | (CheckPriority(205, landmassHappiness.libChurchPenalty, World.churchHash) ? 1u : 0u) | (CheckPriority(206, landmassHappiness.libChurchPenalty, World.libraryHash) ? 1u : 0u) | (CheckPriority(207, landmassHappiness.bathhouseNeed > 0f, World.bathhouseHash) ? 1u : 0u) | (CheckPriority(209, landmassHappiness.joustingArenaPenalty, World.joustingArenaHash) ? 1u : 0u)) != 0)
		{
			priority = 68;
		}
		deferralRemoval.ClearFast();
		foreach (KeyValuePair<int, Intention_BuildBuilding> item in buildIntention)
		{
			if (item.Value != null && item.Value.Done)
			{
				deferralRemoval.Add(item.Key);
			}
		}
		for (int i = 0; i < deferralRemoval.Count; i++)
		{
			DestroyIntention(buildIntention[deferralRemoval.data[i]]);
			buildIntention.Remove(deferralRemoval.data[i]);
		}
	}
}
