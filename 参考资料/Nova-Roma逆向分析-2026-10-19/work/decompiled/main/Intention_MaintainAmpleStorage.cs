using System;

public class Intention_MaintainAmpleStorage : AIIntentionBase
{
	private Intention_BuildBuilding buildIntention;

	private EventHandler<OnStorageFullEvent> eventHandler;

	public void Init()
	{
		eventHandler = Broadcast.StorageFullEvent.Listen(OnStorageFullEvent);
		transform.SetAsFirstSibling();
	}

	private void OnDisable()
	{
		Broadcast.StorageFullEvent.Unlisten(eventHandler);
	}

	public void OnStorageFullEvent(object send, OnStorageFullEvent storageFullEvent)
	{
		if (storageFullEvent.b.LandMass() == LandMass && World.inst.FindMatchingSurroundingCell(storageFullEvent.b.GetCell(), testOrigin: false, 7, (Cell c) => c.StructureFind(World.smallstockpileHash) != null) == null && buildIntention == null && Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.smallstockpileHash) && !IsBeingBuilt(World.smallstockpileHash))
		{
			buildIntention = AddSubIntention<Intention_BuildBuilding>("build smallstockpile");
			buildIntention.Init("smallstockpile", AIBuildingBlockType.Civic, storageFullEvent.b.transform.position, 7);
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 80;
		KillAndNullFinishedIntention(ref buildIntention);
	}
}
