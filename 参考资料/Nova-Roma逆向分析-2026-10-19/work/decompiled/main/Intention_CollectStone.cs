using System;

public class Intention_CollectStone : AIIntentionBase
{
	private Intention_BuildPreplannedBuilding buildQuarryIntention;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private float timeAtLowStone = 999f;

	private float timeToBuildQuarry = 600f;

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
		if (obj.targetBuilding.LandMass() == LandMass && !obj.added && obj.targetBuilding.uniqueNameHash == World.quarryHash)
		{
			timeAtLowStone = timeToBuildQuarry;
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 100;
		if (World.inst.GetVillagersForLandMass(LandMass).Count > 15)
		{
			bool flag = Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.quarryHash);
			if (Kingdom.AtLowResources(2, 10) & flag)
			{
				timeAtLowStone += dt;
			}
			if (timeAtLowStone > timeToBuildQuarry && buildQuarryIntention == null && !IsBeingBuilt(World.quarryHash))
			{
				buildQuarryIntention = AddSubIntention<Intention_BuildPreplannedBuilding>("build quarry");
				buildQuarryIntention.doRoads = true;
				buildQuarryIntention.handlingError = true;
				buildQuarryIntention.PlaceBlockIfNeeded = false;
				buildQuarryIntention.InitClosest("quarry", Layout.KingdomStart);
			}
		}
		if (buildQuarryIntention != null && !buildQuarryIntention.placementSuccess)
		{
			DestroyIntention(buildQuarryIntention);
			buildQuarryIntention = null;
			timeAtLowStone = -300f;
		}
		if (KillAndNullFinishedIntention(ref buildQuarryIntention))
		{
			timeAtLowStone = -300f;
		}
	}
}
