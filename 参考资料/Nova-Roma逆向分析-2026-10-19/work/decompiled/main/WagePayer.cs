using System;
using UnityEngine;

public class WagePayer : Tickable
{
	[SerializeField]
	private float thoughtYOffset = 1f;

	private int missedWage;

	private Timer wageTimer = new Timer(50f);

	public bool useHazardPay;

	[NonSerialized]
	public Building bi;

	public int wageAmount;

	public float PaydaysPerYear()
	{
		return SeasonManager.inst.TimeInYear() / wageTimer.Duration;
	}

	private void Awake()
	{
		bi = GetComponent<Building>();
	}

	public override void OnEnableInternal()
	{
		bi = GetComponent<Building>();
		wageTimer.CurrTime = SRand.Range(0f, wageTimer.Duration);
		base.OnEnableInternal();
	}

	public int GetGoldWage(LandmassOwner lmo)
	{
		if (useHazardPay && lmo.hazardPay)
		{
			return wageAmount * lmo.hazardPayMultiplier;
		}
		return wageAmount;
	}

	private void OnBuildingPlacement(bool undo)
	{
		bi.thought.pos = bi.Center();
	}

	public bool CanPayWage()
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(bi.LandMass());
		return landmassOwner.Gold >= GetGoldWage(landmassOwner);
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!bi.IsBuilt())
		{
			bi.thought.visible = false;
			return;
		}
		int landmass = bi.LandMass();
		bool flag = bi.IsOpen() && bi.jobs != null && bi.jobs.Count > 0 && JobSystem.inst.IsCategoryOpen(landmass, bi.jobs[0].jobCategory);
		LandmassOwner landmassOwner = World.GetLandmassOwner(landmass);
		int goldWage = GetGoldWage(landmassOwner);
		bool flag2 = landmassOwner.Gold >= goldWage;
		if (wageTimer.Update(dt) || ((missedWage > 0 || bi.WorkersAllocated <= 0) & flag2))
		{
			if (flag && bi.WorkersAllocated > 0)
			{
				if (landmassOwner.Gold < goldWage)
				{
					missedWage++;
					if (missedWage >= 3)
					{
						for (int i = 0; i < bi.jobs.Count; i++)
						{
							if (bi.jobs[i].Employee != null)
							{
								bi.jobs[i].Employee.QuitJob();
							}
						}
						missedWage = 0;
					}
				}
				else
				{
					landmassOwner.Gold -= goldWage;
					missedWage = 0;
				}
			}
			for (int j = 0; j < bi.jobs.Count; j++)
			{
				bi.jobs[j].passesWageReq = flag2;
			}
		}
		if ((!flag2 & flag) && bi.IsVisibleForFog())
		{
			bi.thought.visible = true;
			if (missedWage > 1 || bi.GetWorkerPercent() <= 0f)
			{
				bi.thought.thought = ThoughtBubbleSystem.Thought.WageCritical;
			}
			else
			{
				bi.thought.thought = ThoughtBubbleSystem.Thought.Wage;
			}
			bi.thought.offset.y = thoughtYOffset;
		}
		else if (bi.thought.thought == ThoughtBubbleSystem.Thought.Wage || bi.thought.thought == ThoughtBubbleSystem.Thought.WageCritical)
		{
			bi.thought.visible = false;
		}
	}
}
