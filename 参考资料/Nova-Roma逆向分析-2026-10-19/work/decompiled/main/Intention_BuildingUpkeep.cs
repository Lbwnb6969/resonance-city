using System;
using UnityEngine;

public class Intention_BuildingUpkeep : AIIntentionBase
{
	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Intention_BuildBuilding buildIntention;

	private float timeAtLoweringIntegrity;

	private int previousYearIntegrity = 100;

	private Vector3 nextMasonLocation;

	private bool addedNewMason;

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		Broadcast.SeasonEvent.Listen(OnSeasonEvent);
		nextMasonLocation = Layout.KingdomStart;
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
		Broadcast.SeasonEvent.Unlisten(OnSeasonEvent);
	}

	private void OnSeasonEvent(object sender, SeasonEventData seasonEvent)
	{
		if (seasonEvent.SeasonDefinition.id == 0)
		{
			previousYearIntegrity = Player.inst.GetLandmassIntegrity(LandMass).currentIntegrity;
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 70;
		if (World.inst.GetVillagersForLandMass(LandMass).Count >= 350)
		{
			int count = Player.inst.GetBuildingListForLandMass(LandMass).Count;
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.masonHash);
			Player.IntegrityInfo landmassIntegrity = Player.inst.GetLandmassIntegrity(LandMass);
			bool flag = Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.masonHash);
			bool flag2 = previousYearIntegrity > landmassIntegrity.currentIntegrity;
			int num = count / 200;
			if (flag2 & flag)
			{
				timeAtLoweringIntegrity += dt;
			}
			else
			{
				timeAtLoweringIntegrity = 0f;
			}
			if ((timeAtLoweringIntegrity > 300f || num > buildingListForLandMass.Count) && buildIntention == null && !IsBeingBuilt(World.masonHash))
			{
				buildIntention = AddSubIntention<Intention_BuildBuilding>("build mason");
				buildIntention.Init("Mason", AIBuildingBlockType.Civic, nextMasonLocation, 15);
				nextMasonLocation = Layout.KingdomStart;
				addedNewMason = true;
			}
			if (KillAndNullFinishedIntention(ref buildIntention))
			{
				timeAtLoweringIntegrity = -300f;
			}
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() != LandMass || !obj.added)
		{
			return;
		}
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.masonHash);
		if (!addedNewMason)
		{
			return;
		}
		Vector3 b = obj.targetBuilding.Center();
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			if (Mathff.DistSqrdXZ(buildingListForLandMass.data[i].cachedPos, b) > 169f)
			{
				nextMasonLocation = obj.targetBuilding.GetCell().Center2D;
				addedNewMason = false;
				break;
			}
		}
	}
}
