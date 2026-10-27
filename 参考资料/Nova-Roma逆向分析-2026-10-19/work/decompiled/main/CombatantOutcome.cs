using System;

[Serializable]
public class CombatantOutcome
{
	public ArenaFighter fighter;

	public OutcomeType type;

	public bool winner;

	public CombatantOutcome(ArenaFighter f, bool win)
	{
		fighter = f;
		winner = win;
	}
}
