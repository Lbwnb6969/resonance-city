public class Intention_ManageTransportShips : AIIntentionBase
{
	private Intention_BuildPreplannedBuilding buildTroopTransportShip;

	private float needTransportTime;

	public override void Tick(float dt)
	{
		base.Tick(dt);
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(LandMass);
		if (villagersForLandMass.Count >= 75)
		{
			priority = 67;
			if (villagersForLandMass.Count > 150 && buildTroopTransportShip != null)
			{
				priority = 90;
			}
			if (Kingdom.unitControl.noOpenTransports && buildTroopTransportShip == null)
			{
				needTransportTime += dt;
			}
			else
			{
				needTransportTime = 0f;
			}
			if (needTransportTime > 0.5f && buildTroopTransportShip == null && !IsBeingBuilt(World.troopTransportShipHash))
			{
				buildTroopTransportShip = AddSubIntention<Intention_BuildPreplannedBuilding>("build troop transport");
				buildTroopTransportShip.unZone = true;
				buildTroopTransportShip.InitClosest("trooptransportship", Layout.KingdomGridStart);
			}
			KillAndNullFinishedIntention(ref buildTroopTransportShip);
		}
	}
}
