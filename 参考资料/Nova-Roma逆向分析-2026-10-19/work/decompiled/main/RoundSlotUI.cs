using System;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.UI;

public class RoundSlotUI : MonoBehaviour
{
	[Header("Header")]
	public TextMeshProUGUI roundNumberText;

	public GameObject inactivePanel;

	[Header("Empty State")]
	public GameObject emptyState;

	public Button addFightButton;

	[Header("Configured State")]
	public GameObject configuredState;

	[Header("Combatants")]
	[FormerlySerializedAs("gladiatorInfo")]
	public CombatantInfoUI combatant1Info;

	[FormerlySerializedAs("opponentInfo")]
	public CombatantInfoUI combatant2Info;

	[Header("Match Summary")]
	public TextMeshProUGUI spectacleEstimate;

	public TextMeshProUGUI costText;

	[Header("Buttons")]
	public Button changeButton;

	private int roundIndex;

	private Action onAddFight;

	private Action onChange;

	public void Initialize(int index, Action onAdd, Action onChg)
	{
		roundIndex = index;
		onAddFight = onAdd;
		onChange = onChg;
		addFightButton.onClick.AddListener(() =>
		{
			onAddFight?.Invoke();
		});
		changeButton.onClick.AddListener(() =>
		{
			onChange?.Invoke();
		});
		emptyState.SetActive(value: true);
		configuredState.SetActive(value: false);
		changeButton.gameObject.SetActive(value: false);
		roundNumberText.text = string.Format(LocalizationManager.GetTranslation("colosseum_round_number"), index + 1);
	}

	public void SetData(ColosseumRound round, Gladiator combatant1, Gladiator combatant2, int playerGold)
	{
		roundNumberText.text = string.Format(LocalizationManager.GetTranslation("colosseum_round_number"), roundIndex + 1);
		bool flag = round.combatant1Id == -1;
		emptyState.SetActive(flag);
		configuredState.SetActive(!flag);
		if (combatant1 != null)
		{
			combatant1Info.SetAllStatsVisible(v: true);
			combatant1Info.SetGladiator(combatant1, round.combatant1DeathChanceFinal, round.combatant1BaseDeathChance, round.combatant1SkillMod, round.combatant1FatigueMod, round.combatant1ProjectedFatigueTier);
		}
		else
		{
			combatant1Info.SetEmpty();
		}
		switch (round.fightType)
		{
		case ColosseumFightType.GladiatorVsGladiator:
			if (combatant2 != null)
			{
				combatant2Info.SetAllStatsVisible(v: true);
				combatant2Info.SetGladiator(combatant2, round.combatant2DeathChanceFinal, round.combatant1BaseDeathChance, 0f - round.combatant1SkillMod, round.combatant2FatigueMod, round.combatant2ProjectedFatigueTier);
			}
			else
			{
				combatant2Info.SetEmpty();
			}
			break;
		case ColosseumFightType.GladiatorVsBeasts:
			combatant2Info.SetBeast(round.beastType, round.beastCount);
			break;
		}
		string term;
		if (round.spectacleFinal > 30f)
		{
			term = "magnitude_high";
		}
		else
		{
			term = ((round.spectacleFinal >= 20f) ? "magnitude_medium" : "magnitude_low");
		}
		spectacleEstimate.text = LocalizationManager.GetTranslation(term);
		string text = ResourceAmount.Make(4, round.goldCost).ToString();
		costText.text = ((playerGold >= round.goldCost) ? text : ResourceAmount.MakeRed(text));
		changeButton.gameObject.SetActive(!flag);
	}
}
