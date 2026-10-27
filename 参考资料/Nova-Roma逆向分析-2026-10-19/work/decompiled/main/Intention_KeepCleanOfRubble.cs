public class Intention_KeepCleanOfRubble : AIIntentionBase
{
	private Timer cleanupTimer = new Timer(5f);

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 0;
		if (cleanupTimer.Update(dt))
		{
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.rubbleHash);
			if (buildingListForLandMass.Count > 0)
			{
				Layout.RemoveBuilding(buildingListForLandMass.RandomElement(), reclaimResources: false);
			}
		}
	}
}
