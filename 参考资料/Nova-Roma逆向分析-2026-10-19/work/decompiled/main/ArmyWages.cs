using System;
using UnityEngine;

public class ArmyWages : Tickable
{
	public delegate void MissedWageAction();

	private ThoughtBubbleSystem.ThoughtBubble warningBubble;

	public MissedWageAction missedWageFunc;

	public int wagePerYear = 5;

	[NonSerialized]
	public int teamId;

	[NonSerialized]
	public int missedWage;

	private float yearTime;

	private void Start()
	{
		warningBubble = ThoughtBubbleSystem.inst.AddThoughtBubble(transform.position);
		warningBubble.offset = new Vector3(0f, 1f, 0f);
		warningBubble.scaleMod = 1f;
		warningBubble.visible = false;
		warningBubble.thought = ThoughtBubbleSystem.Thought.Wage;
		yearTime = SRand.Range(0f, SeasonManager.inst.TimeInYear());
	}

	public override void OnDisableInternal()
	{
		if (warningBubble != null)
		{
			ThoughtBubbleSystem.inst.RemoveThoughtBubble(ref warningBubble);
		}
	}

	public int YearlyWage(LandmassOwner owner)
	{
		if (!owner.hazardPay)
		{
			return wagePerYear;
		}
		return wagePerYear * owner.hazardPayMultiplier;
	}

	public override void Tick(float dt, int currFrame)
	{
		yearTime += dt;
		if (warningBubble != null)
		{
			warningBubble.pos = transform.position;
		}
		if (!(yearTime > SeasonManager.inst.TimeInYear()) && missedWage <= 0)
		{
			return;
		}
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(teamId);
		int num = YearlyWage(landmassOwnerByTeamId);
		if (num <= 0)
		{
			return;
		}
		if (landmassOwnerByTeamId.Gold > num)
		{
			landmassOwnerByTeamId.Gold -= num;
			warningBubble.visible = false;
			missedWage = 0;
		}
		else if (yearTime > SeasonManager.inst.TimeInYear())
		{
			missedWage++;
			if (landmassOwnerByTeamId == Player.inst.PlayerLandmassOwner)
			{
				warningBubble.visible = true;
				if (missedWage >= 2)
				{
					warningBubble.thought = ThoughtBubbleSystem.Thought.WageCritical;
				}
				_ = missedWage;
				_ = 3;
			}
			if (missedWage >= 3)
			{
				missedWageFunc();
			}
		}
		if (yearTime > SeasonManager.inst.TimeInYear())
		{
			yearTime = 0f;
		}
	}
}
