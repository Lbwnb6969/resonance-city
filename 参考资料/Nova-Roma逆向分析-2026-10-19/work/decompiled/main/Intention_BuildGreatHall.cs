using System;

public class Intention_BuildGreatHall : AIIntentionBase
{
	public bool CompletelyOutOfSpaceForGreatHall;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Intention_BuildPreplannedBuilding greatHallIntention;

	public void Init()
	{
		priority = 55;
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		CompletelyOutOfSpaceForGreatHall = Player.inst.GetBuildingListForLandMass(LandMass, World.greatHallHash).Count > 0;
	}

	private void OnDisable()
	{
		if (eventHandler != null)
		{
			Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == LandMass && obj.targetBuilding.uniqueNameHash == World.greatHallHash)
		{
			CompletelyOutOfSpaceForGreatHall = obj.added;
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (!CompletelyOutOfSpaceForGreatHall && SeasonManager.inst.CurrentYear() >= 100)
		{
			if (greatHallIntention == null && !IsBeingBuilt(World.greatHallHash))
			{
				greatHallIntention = AddSubIntention<Intention_BuildPreplannedBuilding>("build great hall");
				greatHallIntention.PlaceBlockIfNeeded = false;
				greatHallIntention.doRoads = false;
				greatHallIntention.InitClosest(World.greatHallName, Layout.KingdomGridStart, AIBuildingBlockType.Castle);
			}
			if (greatHallIntention != null && greatHallIntention.failType == FailType.LayoutBlockOutOfSpace)
			{
				CompletelyOutOfSpaceForGreatHall = true;
			}
			KillAndNullFinishedIntention(ref greatHallIntention);
		}
	}
}
