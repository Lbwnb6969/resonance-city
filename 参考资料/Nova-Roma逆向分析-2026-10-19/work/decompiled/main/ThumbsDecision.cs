using System;

[Serializable]
public class ThumbsDecision
{
	public string combatantName;

	public ThumbsResult result;

	public ThumbsDecision(CombatantOutcome outcome, ThumbsResult thumbsResult)
	{
		combatantName = outcome.fighter.DisplayName;
		result = thumbsResult;
	}
}
