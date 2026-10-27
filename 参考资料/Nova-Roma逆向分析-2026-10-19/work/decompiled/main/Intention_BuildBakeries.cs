public class Intention_BuildBakeries : AIIntentionBase
{
	public bool CompletelyOutOfSpaceForBakeries;

	private Intention_BuildBuilding bakeryBuildIntention;

	private const int BAKERY_RATIO = 300;

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 55;
		if (CompletelyOutOfSpaceForBakeries)
		{
			return;
		}
		if ((bool)bakeryBuildIntention)
		{
			if (bakeryBuildIntention.failType == FailType.LayoutBlockOutOfSpace)
			{
				CompletelyOutOfSpaceForBakeries = true;
			}
			KillAndNullFinishedIntention(ref bakeryBuildIntention);
			return;
		}
		int num = Player.inst.TotalWorkersForLandMass(LandMass);
		int count = Player.inst.GetBuildingListForLandMass(LandMass, World.bakerHash).Count;
		if (num / 300 - count > 0)
		{
			bakeryBuildIntention = AddSubIntention<Intention_BuildBuilding>("build bakery");
			bakeryBuildIntention.Init(World.bakerName, AIBuildingBlockType.Residential, Layout.KingdomGridStart);
		}
	}
}
