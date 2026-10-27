public class Intention_BuildDock : AIIntentionBase
{
	private Intention_BuildPreplannedBuilding buildDock;

	private Building Dock;

	public void Init()
	{
		priority = 75;
		Dock = Player.inst.GetBuildingListForLandMass(LandMass, World.dockHash).First();
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (Dock == null && buildDock == null && !IsBeingBuilt(World.dockHash) && SeasonManager.inst.CurrentYear() > 15)
		{
			buildDock = AddSubIntention<Intention_BuildPreplannedBuilding>("build dock");
			buildDock.doRoads = true;
			buildDock.prioritzeCornerRoads = false;
			buildDock.InitClosest(World.dockName, Layout.KingdomGridStart);
		}
		if (KillAndNullFinishedIntention(ref buildDock))
		{
			Dock = Player.inst.GetBuildingListForLandMass(LandMass, World.dockHash).First();
		}
	}
}
