using System;

public class Intention_CollectIron : AIIntentionBase
{
	private Intention_BuildPreplannedBuilding buildIronIntention;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private float timeAtLowIron;

	private float timeToBuildMine = 300f;

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == LandMass && !obj.added && obj.targetBuilding.uniqueNameHash == World.ironMineHash)
		{
			timeAtLowIron = timeToBuildMine;
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 71;
		if (World.inst.GetVillagersForLandMass(LandMass).Count > 75)
		{
			bool flag = Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.ironMineHash);
			if (Kingdom.AtLowResources(5, 10) & flag)
			{
				timeAtLowIron += dt;
			}
			if (timeAtLowIron > timeToBuildMine && buildIronIntention == null && !IsBeingBuilt(World.ironMineHash))
			{
				buildIronIntention = AddSubIntention<Intention_BuildPreplannedBuilding>("build iron mine");
				buildIronIntention.doRoads = true;
				buildIronIntention.handlingError = true;
				buildIronIntention.PlaceBlockIfNeeded = false;
				buildIronIntention.InitClosest("ironmine", Layout.KingdomStart);
			}
		}
		if (buildIronIntention != null && !buildIronIntention.placementSuccess)
		{
			DestroyIntention(buildIronIntention);
			buildIronIntention = null;
			timeAtLowIron = -300f;
		}
		if (KillAndNullFinishedIntention(ref buildIronIntention))
		{
			timeAtLowIron = -300f;
		}
	}
}
