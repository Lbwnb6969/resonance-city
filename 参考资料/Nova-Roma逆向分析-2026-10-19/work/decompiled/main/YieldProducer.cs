using System;
using System.Runtime.Serialization;
using Assets.Code;
using UnityEngine;

public class YieldProducer : Tickable
{
	public delegate void yieldFunc(int type, int amt);

	public delegate bool useTool();

	[Serializable]
	public class YieldProducerSaveData : SaveClass<YieldProducer, YieldProducerSaveData>
	{
		public float yieldTimer;

		public float toolTimer;

		public float yieldIntervalMod;

		public bool toolBonus;

		public override YieldProducerSaveData Pack(YieldProducer b)
		{
			toolBonus = b.toolBonusOn;
			yieldTimer = b.YieldTimer;
			yieldIntervalMod = b.YieldIntervalMod;
			toolTimer = b.toolBonusTime;
			return this;
		}

		public override YieldProducer Unpack(YieldProducer b)
		{
			b.YieldTimer = yieldTimer;
			b.toolBonusOn = toolBonus;
			b.YieldIntervalMod = yieldIntervalMod;
			b.toolBonusTime = toolTimer;
			return b;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			yieldIntervalMod = 1f;
		}
	}

	public Building b;

	public int Yield;

	[Header("Resource Settings")]
	[FreeResourceType]
	public int YieldType;

	public float YieldInterval = 5f;

	public float YieldIntervalMod = 1f;

	public bool PauseYield;

	private float YieldTimer;

	private const int frameSpread = 8;

	private int updateFrame = SRand.srand.Next(0, 8);

	internal const float ToolUseTime = 100f;

	private float toolBonusTime;

	internal bool toolBonusOn;

	public int requiredAtDestination;

	public event yieldFunc OnYieldResources;

	public event useTool OnUsedTool;

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	public float GetTotalYieldInterval()
	{
		return YieldInterval * YieldIntervalMod;
	}

	public float GetYieldProgress()
	{
		return YieldTimer / GetTotalYieldInterval();
	}

	public float CyclesPerYear()
	{
		return SeasonManager.inst.TimeInYear() * (b.workEndHour - b.workStartHour) / 24f / GetTotalYieldInterval();
	}

	public void ResetYield()
	{
		YieldTimer = 0f;
	}

	public void DoYield()
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
		OnYieldResources?.Invoke(YieldType, Yield + maxBonus);
		YieldTimer = 0f;
	}

	public void ApplyToolBonus()
	{
		YieldIntervalMod = 0.75f;
		if (!toolBonusOn)
		{
			toolBonusOn = true;
			toolBonusTime = 100f;
		}
	}

	private void UpdateYield(float dt, int currFrame)
	{
		if (currFrame % 8 != updateFrame)
		{
			return;
		}
		dt *= 8f;
		if (PauseYield || !b.IsOpen() || b.WorkersAllocated <= 0)
		{
			return;
		}
		float totalYieldInterval = GetTotalYieldInterval();
		if (b.DuringWorkHours(0f))
		{
			if (requiredAtDestination > 0)
			{
				int num = 0;
				for (int i = 0; i < b.jobs.Count; i++)
				{
					if (b.jobs[i].Employee != null && b.jobs[i].Employee.travelPath.Count == 0)
					{
						num++;
					}
				}
				float num2 = Mathff.Clamp01((float)num / (float)requiredAtDestination);
				YieldTimer += dt * num2 * b.GetWorkerPercent();
			}
			else
			{
				YieldTimer += dt * b.GetWorkerPercent();
			}
		}
		if (toolBonusOn)
		{
			toolBonusTime -= dt;
			if (toolBonusTime < 0f)
			{
				toolBonusTime = 100f;
				if (!OnUsedTool())
				{
					YieldIntervalMod = 1f;
					toolBonusOn = false;
				}
			}
		}
		if (YieldTimer > totalYieldInterval)
		{
			DoYield();
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b.IsBuilt() && b.WorkersForFullYield > 0)
		{
			UpdateYield(dt, currFrame);
		}
	}
}
