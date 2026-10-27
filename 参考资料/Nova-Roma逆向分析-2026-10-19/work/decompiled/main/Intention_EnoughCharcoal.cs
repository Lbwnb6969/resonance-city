public class Intention_EnoughCharcoal : AIIntentionBase
{
	private Intention_BuildBuilding buildBuildingIntention;

	private Timer timer = new Timer(30f);

	public void Init()
	{
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 60;
		if (timer.Update(dt) && buildBuildingIntention == null && !IsBeingBuilt(World.charcoalmakerHash))
		{
			int num = Player.inst.GetBuildingListForLandMass(LandMass, World.largehouseHash).Count + Player.inst.GetBuildingListForLandMass(LandMass, World.manorhouseHash).Count;
			int count = World.inst.GetVillagersForLandMass(LandMass).Count;
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.charcoalmakerHash);
			bool flag = num > 0 && buildingListForLandMass.Count == 0;
			int num2 = 0;
			float num3 = 1f;
			if (buildingListForLandMass.Count > 0)
			{
				YieldProducer component = buildingListForLandMass.data[0].GetComponent<YieldProducer>();
				num3 = (float)component.Yield * (SeasonManager.inst.TimeInYear() / component.GetTotalYieldInterval());
				num2 = (int)(num3 * (float)buildingListForLandMass.Count);
			}
			_ = Player.inst.GetBuildingListForLandMass(LandMass, World.smallHouseHash).Count;
			_ = SeasonManager.inst.TimeInYear() / 90f;
			int previousConsumption = ResourceStatistics.GetPreviousConsumption(LandMass, 3);
			if ((flag || (num2 <= previousConsumption && count > 50)) && Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.charcoalmakerHash))
			{
				buildBuildingIntention = AddSubIntention<Intention_BuildBuilding>("build new charcoal maker");
				buildBuildingIntention.Init("charcoalmaker", AIBuildingBlockType.Civic, Layout.KingdomStart);
			}
			ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.charcoalmakerHash);
			for (int i = 0; i < buildingListForLandMass2.Count; i++)
			{
				buildingListForLandMass2.data[i].Open = true;
			}
			if ((float)num2 > (float)previousConsumption * 1.2f)
			{
				int num4 = (int)(((float)num2 - (float)previousConsumption * 1.3f) / num3);
				for (int j = 1; j < buildingListForLandMass2.Count && j < num4; j++)
				{
					buildingListForLandMass2.data[j].Open = false;
				}
			}
		}
		KillAndNullFinishedIntention(ref buildBuildingIntention);
	}
}
