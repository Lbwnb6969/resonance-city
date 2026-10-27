using System;
using UnityEngine;

public class Intention_KeepPeopleHealthy : AIIntentionBase
{
	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Intention_BuildBuilding buildIntention;

	private Vector3 lastResidenceMade;

	private bool IsCompletelyOutOfSpaceForClinic;

	private bool IsCompletelyOutOfSpaceForHospital;

	private Timer timer = new Timer(5f);

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		lastResidenceMade = Layout.KingdomStart;
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() != LandMass)
		{
			return;
		}
		if (obj.added)
		{
			if (obj.targetBuilding.CategoryName == "house")
			{
				lastResidenceMade = obj.targetBuilding.transform.position;
			}
		}
		else if (!obj.added)
		{
			int uniqueNameHash = obj.targetBuilding.uniqueNameHash;
			int categoryHash = obj.targetBuilding.categoryHash;
			if (uniqueNameHash == World.clinicHash || uniqueNameHash == World.hospitalHash || categoryHash == World.houseCategoryHash || uniqueNameHash == World.tavernHash || uniqueNameHash == World.townsquareHash || uniqueNameHash == World.bakerHash || uniqueNameHash == World.churchHash)
			{
				IsCompletelyOutOfSpaceForHospital = false;
				IsCompletelyOutOfSpaceForClinic = false;
			}
		}
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 70;
		if (timer.Update(dt) && buildIntention == null)
		{
			int num = Player.inst.TotalWorkersForLandMass(LandMass);
			if (!IsCompletelyOutOfSpaceForClinic)
			{
				ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.clinicHash);
				int num2 = num / 100;
				if (num > 50)
				{
					num2 = Mathff.Max(1, num2);
				}
				if (num2 > buildingListForLandMass.Count && !IsBeingBuilt(World.clinicHash) && buildIntention == null)
				{
					buildIntention = AddSubIntention<Intention_BuildBuilding>("build new clinic");
					buildIntention.Init("clinic", AIBuildingBlockType.Residential, lastResidenceMade);
				}
			}
			if (!IsCompletelyOutOfSpaceForHospital)
			{
				ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.hospitalHash);
				if (num / 400 > buildingListForLandMass2.Count && !IsBeingBuilt(World.hospitalHash) && buildIntention == null)
				{
					buildIntention = AddSubIntention<Intention_BuildBuilding>("build new hospital");
					buildIntention.Init("hospital", AIBuildingBlockType.Residential, lastResidenceMade);
				}
			}
		}
		if (buildIntention != null && buildIntention.failType == FailType.LayoutBlockOutOfSpace)
		{
			if (buildIntention.pendingBuilding.uniqueNameHash == World.clinicHash)
			{
				IsCompletelyOutOfSpaceForClinic = true;
			}
			else if (buildIntention.pendingBuilding.uniqueNameHash == World.hospitalHash)
			{
				IsCompletelyOutOfSpaceForHospital = true;
			}
		}
		KillAndNullFinishedIntention(ref buildIntention);
	}
}
