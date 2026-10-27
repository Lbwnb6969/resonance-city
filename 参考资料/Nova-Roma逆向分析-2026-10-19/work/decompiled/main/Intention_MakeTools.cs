using System;
using UnityEngine;

public class Intention_MakeTools : AIIntentionBase
{
	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Intention_BuildBuilding buildBlacksmithIntention;

	private Vector3 lastBlacksmith;

	internal bool makeTools = true;

	private float timeAtLowTools = 999f;

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		lastBlacksmith = Layout.KingdomStart;
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.blacksmithHash);
		if (buildingListForLandMass.Count > 0)
		{
			lastBlacksmith = buildingListForLandMass.data[0].Center();
		}
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == LandMass && obj.added && obj.targetBuilding.uniqueNameHash == World.blacksmithHash)
		{
			obj.targetBuilding.GetComponent<Blacksmith>();
		}
	}

	public void MakeTools(bool mt)
	{
		if (mt != makeTools)
		{
			makeTools = mt;
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.blacksmithHash);
			for (int i = 0; i < buildingListForLandMass.Count; i++)
			{
				buildingListForLandMass.data[i].GetComponent<Blacksmith>();
			}
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 70;
		if (World.inst.GetVillagersForLandMass(LandMass).Count > 150)
		{
			bool flag = Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.blacksmithHash);
			if (((Kingdom.CurrentResources.Get(6) < 10 && Kingdom.CurrentResources.Get(5) > 10) & flag) && makeTools)
			{
				timeAtLowTools += dt;
			}
			if (timeAtLowTools > 300f && buildBlacksmithIntention == null && !IsBeingBuilt(World.blacksmithHash))
			{
				buildBlacksmithIntention = AddSubIntention<Intention_BuildBuilding>("build blacksmith");
				buildBlacksmithIntention.Init("blacksmith", AIBuildingBlockType.Civic, lastBlacksmith);
			}
		}
		if (KillAndNullFinishedIntention(ref buildBlacksmithIntention))
		{
			timeAtLowTools = -300f;
		}
	}
}
