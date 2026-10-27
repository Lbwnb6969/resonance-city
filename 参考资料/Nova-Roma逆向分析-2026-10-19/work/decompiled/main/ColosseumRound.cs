using System;
using System.Collections.Generic;
using I2.Loc;
using UnityEngine;
using UnityEngine.Serialization;

[Serializable]
public class ColosseumRound
{
	public enum Role
	{
		None,
		Bestiarius,
		Secutor,
		Retiarus
	}

	public int roundIndex;

	public RoundState state;

	public ColosseumFightType fightType;

	public Role combatant1role;

	public int combatant1Id = -1;

	public OpponentType opponentType;

	public int opponentId = -1;

	public Role opponentrole;

	public string beastType;

	public int beastCount = 1;

	public int goldCost;

	[FormerlySerializedAs("baseDeathChance")]
	public float combatant1BaseDeathChance;

	[FormerlySerializedAs("skillMod")]
	public float combatant1SkillMod;

	[FormerlySerializedAs("fatigueMod")]
	public float combatant1FatigueMod;

	[FormerlySerializedAs("deathChanceFinal")]
	public float combatant1DeathChanceFinal;

	[FormerlySerializedAs("opponentDeathChanceFinal")]
	public float combatant2DeathChanceFinal;

	public float spectacleFinal;

	[FormerlySerializedAs("projectedFatigueTier")]
	public int combatant1ProjectedFatigueTier;

	[FormerlySerializedAs("projectedFatigueGain")]
	public int combatant1ProjectedFatigueGain;

	[FormerlySerializedAs("opponentProjectedFatigueTier")]
	public int combatant2ProjectedFatigueTier;

	[FormerlySerializedAs("opponentProjectedFatigueGain")]
	public int combatant2ProjectedFatigueGain;

	[FormerlySerializedAs("opponentFatigueMod")]
	public float combatant2FatigueMod;

	public List<ThumbsDecision> thumbsDecisions = new List<ThumbsDecision>();

	public bool CanEdit()
	{
		if (state != RoundState.Empty)
		{
			return state == RoundState.Planned;
		}
		return true;
	}

	public string GetRiskLabel()
	{
		float num = Mathf.Max(combatant1DeathChanceFinal, combatant2DeathChanceFinal);
		if (num <= 0.1f)
		{
			return LocalizationManager.GetTranslation("colosseum_risk_safe");
		}
		if (num <= 0.25f)
		{
			return LocalizationManager.GetTranslation("colosseum_risk_risky");
		}
		return LocalizationManager.GetTranslation("colosseum_risk_lethal");
	}
}
