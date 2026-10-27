using System;
using UnityEngine;

public class Intention_CleanupDeadBodies : AIIntentionBase
{
	private Intention_BuildPreplannedBuilding buildKeeper;

	private Intention_BuildPreplannedBuilding buildCemetery;

	private EventHandler<OnCemetryEvent> eventHandler;

	private EventHandler<OnBuildingAddRemove> buildingEventHandler;

	private bool CompletelyOutOfSpaceForKeeper;

	private bool CompletelyOutOfSpaceForCemetery;

	private Vector3 prevEventPosition;

	public void Init()
	{
		eventHandler = Broadcast.CemeteryEvent.Listen(OnCemeteryEvent);
		buildingEventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		prevEventPosition = Layout.KingdomStart;
		priority = 90;
		CompletelyOutOfSpaceForKeeper = false;
		CompletelyOutOfSpaceForCemetery = false;
	}

	private void OnDisable()
	{
		Broadcast.CemeteryEvent.Unlisten(eventHandler);
		Broadcast.BuildingAddRemove.UnlistenAny(buildingEventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == LandMass && obj.targetBuilding.categoryHash != World.pathHash && obj.targetBuilding.categoryHash != World.castleblockHash && !obj.added)
		{
			CompletelyOutOfSpaceForKeeper = false;
			CompletelyOutOfSpaceForCemetery = false;
		}
	}

	public void OnCemeteryEvent(object send, OnCemetryEvent cemeteryEvent)
	{
		Cell cellData = World.inst.GetCellData(cemeteryEvent.eventPosition);
		if (cellData == null || cellData.landMassIdx != LandMass)
		{
			return;
		}
		if (cemeteryEvent.eventType == OnCemetryEvent.CemeteryEventType.CemeteryFull)
		{
			if (buildCemetery == null)
			{
				buildCemetery = AddSubIntention<Intention_BuildPreplannedBuilding>("build cemetery");
				buildCemetery.PlaceBlockIfNeeded = false;
				buildCemetery.InitClosest("cemetery", cemeteryEvent.eventPosition);
			}
		}
		else if (buildKeeper == null && !IsBeingBuilt(World.cemeteryKeeperHash) && Player.inst.GetBuildingListForLandMass(LandMass, World.cemeteryKeeperHash).Count == 0)
		{
			buildKeeper = AddSubIntention<Intention_BuildPreplannedBuilding>("build cemetery keeper");
			buildKeeper.InitClosest("cemeterykeeper", cemeteryEvent.eventPosition);
		}
		prevEventPosition = cemeteryEvent.eventPosition;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (!CompletelyOutOfSpaceForKeeper && buildCemetery != null && buildCemetery.failType == FailType.LayoutBlockOutOfSpace && buildKeeper == null && !IsBeingBuilt(World.cemeteryKeeperHash))
		{
			buildKeeper = AddSubIntention<Intention_BuildPreplannedBuilding>("build cemetery keeper");
			buildKeeper.InitClosest("cemeterykeeper", prevEventPosition);
		}
		if (!CompletelyOutOfSpaceForCemetery && World.inst.GetVillagersForLandMass(LandMass).Count > 100 && buildKeeper == null && !IsBeingBuilt(World.cemeteryKeeperHash) && Player.inst.GetBuildingListForLandMass(LandMass, World.cemeteryKeeperHash).Count == 0)
		{
			buildKeeper = AddSubIntention<Intention_BuildPreplannedBuilding>("build cemetery keeper");
			buildKeeper.InitClosest("cemeterykeeper", Layout.KingdomStart);
		}
		if (buildKeeper != null && buildKeeper.failType == FailType.LayoutBlockOutOfSpace)
		{
			CompletelyOutOfSpaceForKeeper = true;
		}
		if (buildCemetery != null && buildCemetery.failType == FailType.LayoutBlockOutOfSpace)
		{
			CompletelyOutOfSpaceForCemetery = true;
		}
		KillAndNullFinishedIntention(ref buildKeeper);
		KillAndNullFinishedIntention(ref buildCemetery);
	}
}
