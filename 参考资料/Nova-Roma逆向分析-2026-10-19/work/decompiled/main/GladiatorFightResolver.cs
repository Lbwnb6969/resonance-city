using UnityEngine;

public static class GladiatorFightResolver
{
	public struct FightResolutionResultSymmetric
	{
		public CombatantOutcome combatant1;

		public CombatantOutcome combatant2;

		public bool thumbsRequired;

		public float spectacleEarned;

		public float volatilityDelta;
	}

	private const float MIN_DEATH_CHANCE = 0.01f;

	private const float MAX_DEATH_CHANCE = 0.6f;

	private const float SKILL_DELTA_CLAMP = 6f;

	private const float SKILL_DEATH_MODIFIER = 0.02f;

	private const float REMATCH_SPECTACLE_MULT = 0.5f;

	public static void CalculateRoundPreview(ColosseumRound round, Gladiator gladiator, Gladiator opponentGladiator = null, int projectedFatigueGain1 = 0, int projectedFatigueGain2 = 0, bool isRematch = false)
	{
		float baseMatchupChance = GetBaseMatchupChance(round.fightType, round.beastType, round.beastCount);
		int relevantSkill = GetRelevantSkill(gladiator, round.combatant1role, round.fightType);
		int opponentSkill = GetOpponentSkill(round, opponentGladiator);
		round.combatant1BaseDeathChance = baseMatchupChance;
		int fatigueTier = (round.combatant1ProjectedFatigueTier = Mathf.Min(5, gladiator.fatigueTier + projectedFatigueGain1));
		round.combatant1ProjectedFatigueGain = projectedFatigueGain1;
		round.combatant1FatigueMod = Gladiator.GetFatigueDeathAdd(fatigueTier);
		float num = Mathf.Clamp(relevantSkill - opponentSkill, -6f, 6f);
		round.combatant1SkillMod = -0.02f * num;
		round.combatant1DeathChanceFinal = Mathf.Clamp(baseMatchupChance + round.combatant1FatigueMod + round.combatant1SkillMod, 0.01f, 0.6f);
		if (round.fightType == ColosseumFightType.GladiatorVsGladiator && opponentGladiator != null)
		{
			int fatigueTier2 = (round.combatant2ProjectedFatigueTier = Mathf.Min(5, opponentGladiator.fatigueTier + projectedFatigueGain2));
			round.combatant2ProjectedFatigueGain = projectedFatigueGain2;
			round.combatant2FatigueMod = Gladiator.GetFatigueDeathAdd(fatigueTier2);
			float num2 = -0.02f * (0f - num);
			round.combatant2DeathChanceFinal = Mathf.Clamp(baseMatchupChance + round.combatant2FatigueMod + num2, 0.01f, 0.6f);
		}
		else
		{
			round.combatant2ProjectedFatigueTier = 0;
			round.combatant2ProjectedFatigueGain = 0;
			round.combatant2FatigueMod = 0f;
			round.combatant2DeathChanceFinal = 0f;
		}
		round.spectacleFinal = CalculateBaseSpectacle(round, gladiator, opponentGladiator);
		if (isRematch)
		{
			round.spectacleFinal *= 0.5f;
		}
		round.goldCost = CalculateRoundCost(round);
	}

	public static bool IsSameMatchup(ColosseumRound a, ColosseumRound b)
	{
		if (a.fightType != b.fightType || a.opponentType != b.opponentType)
		{
			return false;
		}
		switch (a.opponentType)
		{
		case OpponentType.School:
			if (a.combatant1Id != b.combatant1Id || a.opponentId != b.opponentId)
			{
				if (a.combatant1Id == b.opponentId)
				{
					return a.opponentId == b.combatant1Id;
				}
				return false;
			}
			return true;
		case OpponentType.Beast:
			if (a.combatant1Id == b.combatant1Id)
			{
				return a.beastType == b.beastType;
			}
			return false;
		default:
			return false;
		}
	}

	public static int CalculateRoundCost(ColosseumRound round)
	{
		switch (round.fightType)
		{
		case ColosseumFightType.GladiatorVsGladiator:
			return 50;
		case ColosseumFightType.GladiatorVsBeasts:
		{
			BeastTemplate beastDefByName = GladiatorSystem.inst.GetBeastDefByName(round.beastType);
			return 50 + beastDefByName.goldCost * round.beastCount;
		}
		default:
			return 50;
		}
	}

	private static float GetBaseMatchupChance(ColosseumFightType fightType, string beastType, int beastCount)
	{
		return fightType switch
		{
			ColosseumFightType.GladiatorVsGladiator => 0.08f, 
			ColosseumFightType.GladiatorVsBeasts => GladiatorSystem.inst.GetBeastDefByName(beastType).baseDeathChance * (1f + (float)(beastCount - 1) * 0.05f), 
			_ => 0f, 
		};
	}

	private static int GetRelevantSkill(Gladiator gladiator, ColosseumRound.Role role, ColosseumFightType fightType)
	{
		switch (role)
		{
		case ColosseumRound.Role.Bestiarius:
			return gladiator.skills.bestiarius;
		case ColosseumRound.Role.Secutor:
			return gladiator.skills.secutor;
		case ColosseumRound.Role.Retiarus:
			return gladiator.skills.retiarius;
		default:
			if (fightType != ColosseumFightType.GladiatorVsGladiator && fightType == ColosseumFightType.GladiatorVsBeasts)
			{
				return gladiator.skills.bestiarius;
			}
			return Mathf.Max(gladiator.skills.retiarius, gladiator.skills.secutor);
		}
	}

	private static int GetOpponentSkill(ColosseumRound round, Gladiator opponentGladiator)
	{
		switch (round.opponentType)
		{
		case OpponentType.School:
			if (opponentGladiator == null)
			{
				return 3;
			}
			return GetRelevantSkill(opponentGladiator, round.opponentrole, round.fightType);
		case OpponentType.Beast:
			return GladiatorSystem.inst.GetBeastDefByName(round.beastType).tier * 2;
		default:
			return 3;
		}
	}

	private static float CalculateBaseSpectacle(ColosseumRound round, Gladiator gladiator, Gladiator opponentGladiator)
	{
		float num = 5f;
		num += (float)gladiator.fame;
		switch (round.fightType)
		{
		case ColosseumFightType.GladiatorVsGladiator:
			num += 10f;
			if (opponentGladiator != null)
			{
				num += (float)opponentGladiator.fame;
			}
			break;
		case ColosseumFightType.GladiatorVsBeasts:
		{
			BeastTemplate beastDefByName = GladiatorSystem.inst.GetBeastDefByName(round.beastType);
			num += beastDefByName.spectacleBonus;
			num += (float)(round.beastCount - 1);
			break;
		}
		}
		return num;
	}

	public static float CalculateExecutionBonus(Gladiator gladiator)
	{
		return 5f + (float)gladiator.fame * 3f;
	}

	public static ThumbsScores CalculateThumbsScoresSymmetric(Gladiator gladiator, float volatility, float winnerHpFraction)
	{
		ThumbsScores result = new ThumbsScores
		{
			mercyScore = 50f,
			executionScore = 50f
		};
		float num = 0.5f;
		float num2 = 0.5f;
		int num3 = 0;
		int fame = gladiator.fame;
		GladiatorAlignment alignment = gladiator.alignment;
		num = gladiator.bravery;
		num2 = gladiator.crowdFavor;
		num3 = gladiator.fatigueTier;
		float num4 = ((float)fame - 2.5f) * 6f;
		result.mercyScore += num4;
		result.executionScore -= num4;
		switch (alignment)
		{
		case GladiatorAlignment.Hero:
			result.mercyScore += 15f;
			break;
		case GladiatorAlignment.Heel:
			result.executionScore += 15f;
			break;
		}
		if (gladiator != null && num3 >= 4)
		{
			result.executionScore += 10f;
		}
		result.executionScore += 40f * winnerHpFraction;
		result.mercyScore += 10f * (1f - winnerHpFraction);
		float num5 = (volatility - 5f) * 3f;
		result.executionScore += num5;
		if (gladiator != null)
		{
			result.mercyScore += (num - 0.5f) * 10f;
			result.mercyScore += (num2 - 0.5f) * 15f;
		}
		float num6 = result.mercyScore + result.executionScore;
		result.bias = (result.executionScore - result.mercyScore) / num6;
		return result;
	}
}
