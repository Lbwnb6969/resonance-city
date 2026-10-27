using System;

public class Intention_ManageDiplomacyInfrastructure : AIIntentionBase
{
	private Intention_BuildBuilding buildForeignMinistry;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Timer updateTimer = new Timer(5f);

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(OnBuildingAddRemove);
	}

	public void OnBuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (!obj.added && obj.targetBuilding.uniqueNameHash == World.hallofdiplomacyHash && buildForeignMinistry == null)
		{
			buildForeignMinistry = AddSubIntention<Intention_BuildBuilding>("build foreign ministry");
			buildForeignMinistry.Init(World.hallOfDiplomacyName, AIBuildingBlockType.Castle, Layout.KingdomStart, 16);
		}
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	public override void Tick(float dt)
	{
		if (World.inst.GetVillagersForLandMass(LandMass).Count < 75)
		{
			return;
		}
		if (updateTimer.Update(dt))
		{
			int count = AIBrainsContainer.inst.kingdoms.Count;
			int num = ArmySystem.inst.UnitCount(LandmassOwner.teamId, ArmySystem.ArmyType.Envoy);
			priority = (int)(65f + 15f * (1f - (float)num / (float)count));
			if (num < count)
			{
				ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.hallofdiplomacyHash);
				if (buildingListForLandMass.Count > 0)
				{
					Barracks component = buildingListForLandMass.data[0].GetComponent<Barracks>();
					if (!component.training)
					{
						component.AddTraining();
					}
				}
				else if (buildForeignMinistry == null && !IsBeingBuilt(World.hallofdiplomacyHash))
				{
					buildForeignMinistry = AddSubIntention<Intention_BuildBuilding>("build foreign ministry");
					buildForeignMinistry.Init(World.hallOfDiplomacyName, AIBuildingBlockType.Castle, Layout.KingdomStart, 16);
				}
			}
		}
		KillAndNullFinishedIntention(ref buildForeignMinistry);
		base.Tick(dt);
	}
}
