using System;

public class YieldProducerSeason : Tickable
{
	public delegate void yieldFunc(int typeID, int amount);

	[Serializable]
	public class YieldProducerSeasonSaveData : SaveClass<YieldProducerSeason, YieldProducerSeasonSaveData>
	{
		public float actualYieldPercentage;

		public float deferredTime;

		public override YieldProducerSeasonSaveData Pack(YieldProducerSeason b)
		{
			actualYieldPercentage = b.actualYieldPercentage;
			deferredTime = b.deferredTime;
			return this;
		}

		public override YieldProducerSeason Unpack(YieldProducerSeason b)
		{
			b.actualYieldPercentage = actualYieldPercentage;
			b.deferredTime = deferredTime;
			return b;
		}
	}

	public Building b;

	public int YieldAmt;

	public int YieldType;

	public bool PauseYield;

	[NonSerialized]
	public float actualYieldPercentage;

	private const int frameSpread = 8;

	private int updateFrame = SRand.srand.Next(0, 8);

	private EventHandler<SeasonEventData> seasonEvent;

	private SeasonDefinition currentSeason;

	public float delayOnYieldDurationPercent = 0.72f;

	private float deferredTime;

	public event yieldFunc OnYieldResources;

	public void ResetYield()
	{
		actualYieldPercentage = 0f;
	}

	public override void OnEnableInternal()
	{
		seasonEvent = Broadcast.SeasonEvent.Listen(Inst_OnSeasonChange);
		currentSeason = SeasonManager.GetCurrentSeason();
		base.OnEnableInternal();
	}

	public override void OnDisableInternal()
	{
		Broadcast.SeasonEvent.Unlisten(seasonEvent);
		base.OnDisableInternal();
	}

	private void Inst_OnSeasonChange(object sender, SeasonEventData e)
	{
		if (e.SeasonDefinition.id == 1)
		{
			deferredTime = e.SeasonDefinition.duration * delayOnYieldDurationPercent;
		}
		currentSeason = e.SeasonDefinition;
	}

	public override void Tick(float dt, int currFrame)
	{
		if (currFrame % 8 != updateFrame || !b.IsBuilt() || b.WorkersForFullYield <= 0)
		{
			return;
		}
		if (currentSeason.id == 0 || currentSeason.id == 3)
		{
			if (!PauseYield && b.IsOpen())
			{
				dt *= 8f;
				actualYieldPercentage += dt / (currentSeason.duration * 2f) * b.GetWorkerPercent();
			}
		}
		else
		{
			if (currentSeason.id != 1)
			{
				return;
			}
			if (deferredTime > 0f && deferredTime - dt * 8f <= 0f)
			{
				int maxBonus = 0;
				b.ForEachTileInBounds((int x, int z, Cell cell) =>
				{
					CellProductionInfluence cellProductionInfluenceDataClamped = World.inst.GetCellProductionInfluenceDataClamped(x, z);
					for (int i = 0; i < cellProductionInfluenceDataClamped.radiusBonuses.Count; i++)
					{
						if (cellProductionInfluenceDataClamped.radiusBonuses[i].BoostsResource(YieldType) && cellProductionInfluenceDataClamped.radiusBonuses[i].GetBonus() > maxBonus)
						{
							maxBonus = cellProductionInfluenceDataClamped.radiusBonuses[i].GetBonus();
						}
					}
					for (int j = 0; j < cellProductionInfluenceDataClamped.radiusBonusesBuilding.Count; j++)
					{
						if (cellProductionInfluenceDataClamped.radiusBonusesBuilding[j].GetBonus() > maxBonus)
						{
							maxBonus = cellProductionInfluenceDataClamped.radiusBonusesBuilding[j].GetBonus();
						}
					}
				});
				OnYieldResources?.Invoke(YieldType, (int)((float)(YieldAmt + maxBonus) * actualYieldPercentage));
				actualYieldPercentage = 0f;
			}
			deferredTime -= dt * 8f;
		}
	}
}
