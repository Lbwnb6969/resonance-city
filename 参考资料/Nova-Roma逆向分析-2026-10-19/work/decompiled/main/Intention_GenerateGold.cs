public class Intention_GenerateGold : AIIntentionBase
{
	private Intention_BuildBuilding buildTreasureRoomIntention;

	private bool startBuildingTreasureRooms;

	private Timer checkTime = new Timer(20f);

	private int lastH;

	internal GoldInfo.WageInfo wageInfo = new GoldInfo.WageInfo();

	public void Init()
	{
		transform.SetAsFirstSibling();
	}

	public void StartBuildingTreasureRooms()
	{
		startBuildingTreasureRooms = true;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 80;
		int count = Player.inst.GetBuildingListForLandMass(LandMass, World.throneRoomHash).Count;
		int gold = LandmassOwner.Gold;
		int num = Mathff.Max(LandmassOwner.MaxGoldStorage - 200, 0);
		bool flag = gold >= num;
		if (gold < 5000 && ((count == 0 && startBuildingTreasureRooms) || (flag && gold > 0)) && buildTreasureRoomIntention == null && !IsBeingBuilt(World.throneRoomHash))
		{
			buildTreasureRoomIntention = AddSubIntention<Intention_BuildBuilding>("build treaure room");
			buildTreasureRoomIntention.Init(World.throneRoomName, AIBuildingBlockType.Castle, Layout.KingdomStart, 16);
		}
		int num2 = Player.inst.TotalWorkersForLandMass(LandMass);
		int num3 = Player.inst.TotalResidentialSlotsOnLandMass(LandMass);
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.townsquareHash);
		int num4 = 50;
		if (buildingListForLandMass.Count > 0)
		{
			num4 = buildingListForLandMass.data[0].GetComponent<TownSquare>().GetFestivalCost();
		}
		if (gold > num4 + 150 || (gold >= num4 + 25 && (float)(num3 - num2) > (float)num2 * 0.3f))
		{
			int num5 = 0;
			for (int i = 0; i < buildingListForLandMass.Count; i++)
			{
				if (buildingListForLandMass.data[i].GetComponent<TownSquare>().FestivalActive())
				{
					num5++;
				}
			}
			if (num5 <= 0 && buildingListForLandMass.Count > 0)
			{
				buildingListForLandMass.RandomElement().GetComponent<TownSquare>().TryStartFestival();
			}
		}
		int currHappiness = Player.inst.GetLandmassHappiness(LandMass).currHappiness;
		if (lastH < currHappiness - 7 || lastH > currHappiness + 7 || checkTime.Update(dt))
		{
			lastH = currHappiness;
			GoldInfo.CalcTaxInfo(LandMass, ref wageInfo);
			if (wageInfo.totalWage > 0f)
			{
				startBuildingTreasureRooms = true;
			}
			if (flag)
			{
				Player.inst.SetTaxRate(LandMass, 0f);
			}
			else
			{
				float num6 = 0f;
				ArrayExt<Home> arrayExt = Player.inst.ResidentialsPerLandmass[LandMass];
				for (int j = 0; j < arrayExt.Count; j++)
				{
					Home home = arrayExt.data[j];
					num6 += home.GetEstimatedTaxYield();
				}
				float num7 = 1f;
				if (num6 > 0f)
				{
					num7 = wageInfo.totalWage / num6;
					if (gold < 200)
					{
						num7++;
					}
				}
				float num8 = 0f;
				float num9 = 0f;
				if (gold < 100 && World.inst.AvailableWorkersOnLandMass(LandMass) > 10)
				{
					num9 = 1f;
				}
				else if (gold > 1500)
				{
					num9 = -0.5f;
				}
				else if (gold > 2500)
				{
					num9 = -1f;
				}
				if (currHappiness <= 50)
				{
					num8 = 0f + num9;
				}
				else if (currHappiness > 50 && currHappiness <= 75)
				{
					num8 = 1f + num9;
				}
				else
				{
					num8 = ((currHappiness <= 75 || currHappiness >= 85) ? (3f + num9) : (2f + num9));
				}
				float b = num8;
				if (num7 > num8 && currHappiness >= 50)
				{
					b = num7;
				}
				Player.inst.SetTaxRate(LandMass, Mathff.Clamp(Mathff.Max(0f, b), 0f, 3f));
			}
		}
		KillAndNullFinishedIntention(ref buildTreasureRoomIntention);
	}
}
