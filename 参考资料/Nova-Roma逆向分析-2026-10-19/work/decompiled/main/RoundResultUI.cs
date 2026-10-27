using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class RoundResultUI : MonoBehaviour
{
	private enum Phase
	{
		Waiting,
		ShowVictor,
		ShowEverythingElse,
		ShowOutcome
	}

	public GameObject winnerInfo;

	[Header("Winner Section — Always Visible")]
	public TextMeshProUGUI winnerText;

	[Header("Thumbs Decision Section — Shown During Decision")]
	public GameObject thumbsDecisionSection;

	public TextMeshProUGUI fallenText;

	public Slider biasMeter;

	public TextMeshProUGUI biasLabelText;

	public TextMeshProUGUI biasReasonText;

	public Button mercyButton;

	public Button executeButton;

	public Button letCrowdDecideButton;

	public TextMeshProUGUI deathFeeText;

	[Header("Outcome Section — Shown After Decision or For Non-Thumbs")]
	public GameObject outcomeSection;

	public TextMeshProUGUI outcomeTitleText;

	public TextMeshProUGUI overruledText;

	[Header("Buttons")]
	public Button continueButton;

	private Colosseum currentColosseum;

	public GladiatorFame fame;

	public GladiatorFatigue fatigue;

	private Phase phase;

	private Colosseum currColosseum;

	private float crowdBias;

	private int deathFee;

	public GameObject fameGain;

	public GameObject fatigueGain;

	public SlideAnim decisionAnim;

	private float showVictorTimer;

	private void Awake()
	{
	}

	public void ShowWithThumbsDecision(Colosseum colosseum, float bias)
	{
		currColosseum = colosseum;
		crowdBias = bias;
		SetPhase(Phase.ShowVictor);
		currentColosseum = colosseum;
		gameObject.SetActive(value: true);
		ArenaFightManager.FightResult winnerResults = colosseum.arenaFightManager.GetWinnerResults();
		if (winnerResults.gladiator != null)
		{
			fame.SetFame(winnerResults.fameGain);
			fatigue.SetFatigue(winnerResults.fatigueGain);
			winnerText.text = string.Format(LocalizationManager.GetTranslation("colosseum_victorious"), winnerResults.gladiator.name);
		}
		else
		{
			winnerText.text = string.Format(LocalizationManager.GetTranslation("colosseum_victorious"), winnerResults.beast.GetLocalizedName());
		}
		ArenaFightManager.FightResult loserResults = colosseum.arenaFightManager.GetLoserResults();
		if (loserResults.gladiator != null)
		{
			fallenText.text = string.Format(LocalizationManager.GetTranslation("round_result_fallen"), loserResults.gladiator.name);
		}
		biasMeter.value = biasMeter.minValue + biasMeter.maxValue * 0.5f;
		if (bias < -0.2f)
		{
			biasLabelText.text = LocalizationManager.GetTranslation("round_result_bias_mercy");
		}
		else if (bias > 0.2f)
		{
			biasLabelText.text = LocalizationManager.GetTranslation("round_result_bias_execution");
		}
		else
		{
			biasLabelText.text = LocalizationManager.GetTranslation("round_result_bias_divided");
		}
		biasReasonText.text = colosseum.arenaFightManager.GetLoserResults().mercyBiasText;
		outcomeSection.SetActive(value: false);
		continueButton.gameObject.SetActive(value: false);
		deathFee = loserResults.gladiator.skills.bestiarius + loserResults.gladiator.skills.retiarius + loserResults.gladiator.skills.secutor;
		deathFee *= 100 + SRand.Range(0, 5) * 5;
		deathFeeText.SetText(LocalizationManager.GetTranslation("colosseum_deathfee"), deathFee);
		executeButton.interactable = Player.inst.PlayerLandmassOwner.Gold >= deathFee;
	}

	public void ShowOutcome(Colosseum colosseum, GladiatorFightResolver.FightResolutionResultSymmetric result, List<ThumbsDecision> thumbsDecisions)
	{
		string overruled = "";
		currColosseum = colosseum;
		string detail;
		if (result.combatant1.type == OutcomeType.TragicAccident || result.combatant2.type == OutcomeType.TragicAccident)
		{
			CombatantOutcome combatantOutcome = ((result.combatant1.type == OutcomeType.TragicAccident) ? result.combatant1 : result.combatant2);
			overruled = LocalizationManager.GetTranslation("colosseum_slain_in_combat_desc");
			detail = string.Format(LocalizationManager.GetTranslation("colosseum_is_slain"), combatantOutcome.fighter.DisplayName);
		}
		else if (thumbsDecisions.Count > 0)
		{
			ThumbsDecision thumbsDecision = thumbsDecisions[0];
			detail = string.Format(arg0: thumbsDecision.combatantName ?? LocalizationManager.GetTranslation("colosseum_fighter_fallback"), format: LocalizationManager.GetTranslation((thumbsDecision.result == ThumbsResult.Mercy) ? "colosseum_survives" : "colosseum_is_slain"));
		}
		else
		{
			ArenaFightManager.FightResult loserResults = colosseum.arenaFightManager.GetLoserResults();
			string arg = "";
			if (loserResults.gladiator != null)
			{
				arg = loserResults.gladiator.name;
			}
			else if (loserResults.beast != null)
			{
				arg = loserResults.beast.GetLocalizedName();
			}
			detail = string.Format(LocalizationManager.GetTranslation("colosseum_defeated"), arg);
		}
		ShowResult(colosseum, result.spectacleEarned, detail, overruled);
	}

	public void ShowResult(Colosseum colosseum, float spectacle, string detail, string overruled)
	{
		SetPhase(Phase.ShowOutcome);
		currentColosseum = colosseum;
		gameObject.SetActive(value: true);
		outcomeSection.SetActive(value: true);
		outcomeTitleText.text = detail;
		overruledText.text = overruled;
		overruledText.gameObject.SetActive(!string.IsNullOrEmpty(overruled));
		continueButton.gameObject.SetActive(value: true);
	}

	private void SetPhase(Phase nextPhase)
	{
		switch (nextPhase)
		{
		case Phase.ShowVictor:
			decisionAnim.SetInstant(SlideAnim.PlayMode.Forward);
			showVictorTimer = 1.75f;
			Util.SetActive(fameGain, active: false);
			Util.SetActive(fatigueGain, active: false);
			Util.SetActive(thumbsDecisionSection, active: false);
			Util.SetActive(outcomeSection, active: false);
			Util.SetActive(winnerInfo, active: true);
			break;
		case Phase.ShowEverythingElse:
			decisionAnim.Play(SlideAnim.PlayMode.Reverse);
			Util.SetActive(thumbsDecisionSection, active: true);
			break;
		case Phase.ShowOutcome:
			Util.SetActive(winnerInfo, active: false);
			Util.SetActive(thumbsDecisionSection, active: false);
			break;
		}
		phase = nextPhase;
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (Input.GetKeyDown(KeyCode.M))
		{
			SetPhase(Phase.ShowVictor);
		}
		switch (phase)
		{
		case Phase.ShowVictor:
			showVictorTimer -= unscaledDeltaTime;
			if (currColosseum.arenaFightManager.GetWinnerResults().gladiator != null)
			{
				if (showVictorTimer < 0.75f)
				{
					Util.SetActive(fameGain, active: true);
				}
				if (showVictorTimer < 0.5f)
				{
					Util.SetActive(fatigueGain, active: true);
				}
			}
			if (showVictorTimer < 0f)
			{
				SetPhase(Phase.ShowEverythingElse);
			}
			break;
		case Phase.ShowEverythingElse:
			if (thumbsDecisionSection.activeInHierarchy)
			{
				biasMeter.value = Mathf.Lerp(biasMeter.value, (crowdBias + 1f) / 2f, unscaledDeltaTime);
			}
			break;
		}
	}

	public void OnMercyClicked()
	{
		SfxSystem.PlayUiSelect();
		currentColosseum.MakeThumbsDecision(chooseMercy: true);
	}

	public void OnExecuteClicked()
	{
		SfxSystem.PlayUiSelect();
		Player.inst.PlayerLandmassOwner.Gold -= deathFee;
		currentColosseum.MakeThumbsDecision(chooseMercy: false);
	}

	public void OnContinueClicked()
	{
		SfxSystem.PlayUiSelect();
		gameObject.SetActive(value: false);
		currentColosseum.AcknowledgeRoundResult();
	}
}
