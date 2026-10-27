using System;
using System.Collections.Generic;

[Serializable]
public class ColosseumEvent
{
	public List<ColosseumRound> rounds = new List<ColosseumRound>();

	public float volatilityValue;

	public List<RoundOutcome> outcomes = new List<RoundOutcome>();

	public bool isActive;

	public float totalSpectacle;

	public float volatilityChange;

	public ColosseumEvent(int numRounds)
	{
		rounds = new List<ColosseumRound>(numRounds);
		for (int i = 0; i < numRounds; i++)
		{
			rounds.Add(new ColosseumRound
			{
				roundIndex = i,
				state = RoundState.Empty
			});
		}
		outcomes = new List<RoundOutcome>();
	}

	public bool CanStart()
	{
		foreach (ColosseumRound round in rounds)
		{
			if (round.state == RoundState.Planned)
			{
				return true;
			}
		}
		return false;
	}

	public ColosseumRound GetNextPlannedRound()
	{
		foreach (ColosseumRound round in rounds)
		{
			if (round.state == RoundState.Planned)
			{
				return round;
			}
		}
		return null;
	}

	public int GetTotalCost()
	{
		int num = 0;
		foreach (ColosseumRound round in rounds)
		{
			if (round.state == RoundState.Planned)
			{
				num += round.goldCost;
			}
		}
		return num;
	}
}
