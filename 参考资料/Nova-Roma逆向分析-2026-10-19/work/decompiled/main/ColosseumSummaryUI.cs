using System.Collections.Generic;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ColosseumSummaryUI : MonoBehaviour
{
	private enum AnimStage
	{
		CardFlyIn,
		Show1stOutcome,
		Show2ndOutcome,
		ShowSpectacle,
		AnimateSpectacleBar
	}

	[Header("Header")]
	public TextMeshProUGUI titleText;

	public Slider spectacleSlider;

	public GameObject starContainer;

	public TextMeshProUGUI happinesssBonusText;

	[Header("Totals")]
	public TextMeshProUGUI totalSpectacleText;

	public TextMeshProUGUI volatilityChangeText;

	public TextMeshProUGUI volatilityReasonText;

	public Transform outcomesListContent;

	public GladiatorRoundResultUI outcomeItemPrefab;

	[Header("Buttons")]
	public Button continueButton;

	private ColosseumEvent currentEvent;

	private Colosseum currentColosseum;

	private List<GladiatorRoundResultUI> outcomeItems = new List<GladiatorRoundResultUI>();

	[Header("Animation")]
	public float revealDelay = 0.4f;

	public float spectacleBarDuration = 0.6f;

	private int animIdx;

	private float animTime;

	private float spectacleShown;

	private AnimStage animStage;

	private const float SpectacleTier2 = 30f;

	private const float SpectacleTier3 = 60f;

	private const float SpectacleTier4 = 100f;

	private static readonly float[] starThresholds = new float[4] { 0f, 30f, 60f, 100f };

	public Image face;

	private void Awake()
	{
		continueButton.onClick.AddListener(OnContinueClicked);
	}

	public void Show(Colosseum colosseum, ColosseumEvent colosseumEvent)
	{
		currentColosseum = colosseum;
		currentEvent = colosseumEvent;
		gameObject.SetActive(value: true);
		titleText.text = LocalizationManager.GetTranslation("colosseum_games_concluded");
		foreach (GladiatorRoundResultUI outcomeItem in outcomeItems)
		{
			if (outcomeItem != null)
			{
				Object.Destroy(outcomeItem.gameObject);
			}
		}
		outcomeItems.Clear();
		outcomeItemPrefab.gameObject.SetActive(value: false);
		int num = 0;
		foreach (RoundOutcome outcome in currentEvent.outcomes)
		{
			GladiatorRoundResultUI gladiatorRoundResultUI = Object.Instantiate(outcomeItemPrefab, outcomesListContent);
			gladiatorRoundResultUI.gameObject.SetActive(value: true);
			outcomeItems.Add(gladiatorRoundResultUI);
			gladiatorRoundResultUI.roundTxt.text = string.Format(LocalizationManager.GetTranslation("colosseum_round_number"), num + 1);
			gladiatorRoundResultUI.name1.text = outcome.combatant1Outcome.fighter.DisplayName;
			gladiatorRoundResultUI.dead1Txt.text = GetDeathReason(outcome.combatant1Outcome);
			gladiatorRoundResultUI.name2.text = outcome.combatant2Outcome.fighter.DisplayName;
			gladiatorRoundResultUI.dead2Txt.text = GetDeathReason(outcome.combatant2Outcome);
			gladiatorRoundResultUI.spectacleTxt.text = $"+{Mathf.RoundToInt(outcome.spectacleEarned)}";
			gladiatorRoundResultUI.winner1.SetActive(value: false);
			gladiatorRoundResultUI.dead1.SetActive(value: false);
			gladiatorRoundResultUI.winner2.SetActive(value: false);
			gladiatorRoundResultUI.dead2.SetActive(value: false);
			gladiatorRoundResultUI.spectacleTxt.gameObject.SetActive(value: false);
			num++;
		}
		spectacleShown = 0f;
		spectacleSlider.value = 0f;
		UpdateStars();
		animIdx = 0;
		if (outcomeItems.Count > 0)
		{
			EnterStage(AnimStage.CardFlyIn);
		}
	}

	public string GetDeathReason(CombatantOutcome outcome)
	{
		if (outcome.type == OutcomeType.Alive && !outcome.winner)
		{
			return "Shown Mercy";
		}
		if (outcome.type == OutcomeType.TragicAccident)
		{
			return "Accidental Death";
		}
		if (outcome.type == OutcomeType.Execution)
		{
			return "Executed";
		}
		return "";
	}

	private void UpdateStars()
	{
		float value = spectacleSlider.value;
		Transform transform = starContainer.transform;
		for (int i = 0; i < transform.childCount; i++)
		{
			GameObject gameObject = transform.GetChild(i).gameObject;
			bool flag = value > 0f && value >= starThresholds[i];
			if (flag && !gameObject.activeSelf)
			{
				RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_upgrade_unlock");
			}
			gameObject.SetActive(flag);
		}
		GetSpectacleHappiness(value, out var happiness, out var seasons, out var sprite, out var _);
		string term = ((seasons == 1) ? "colosseum_summary_happiness_season" : "colosseum_summary_happiness_seasons");
		happinesssBonusText.text = string.Format(LocalizationManager.GetTranslation(term), happiness, seasons);
		face.sprite = sprite;
	}

	private void EnterStage(AnimStage stage)
	{
		animStage = stage;
		animTime = 0f;
		GladiatorRoundResultUI gladiatorRoundResultUI = outcomeItems[animIdx];
		RoundOutcome roundOutcome = currentEvent.outcomes[animIdx];
		switch (stage)
		{
		case AnimStage.CardFlyIn:
			gladiatorRoundResultUI.GetComponentInChildren<SlideAnim>().Play(SlideAnim.PlayMode.Forward);
			break;
		case AnimStage.Show1stOutcome:
			gladiatorRoundResultUI.winner1.SetActive(roundOutcome.combatant1Outcome.winner);
			gladiatorRoundResultUI.dead1.SetActive(!roundOutcome.combatant1Outcome.winner);
			break;
		case AnimStage.Show2ndOutcome:
			gladiatorRoundResultUI.winner2.SetActive(roundOutcome.combatant2Outcome.winner);
			gladiatorRoundResultUI.dead2.SetActive(!roundOutcome.combatant2Outcome.winner);
			break;
		case AnimStage.ShowSpectacle:
			gladiatorRoundResultUI.spectacleTxt.gameObject.SetActive(value: true);
			break;
		}
	}

	public void Update()
	{
		if (currentEvent == null || animIdx >= outcomeItems.Count)
		{
			return;
		}
		animTime += Time.unscaledDeltaTime;
		switch (animStage)
		{
		case AnimStage.CardFlyIn:
			if (animTime >= outcomeItems[animIdx].GetComponentInChildren<SlideAnim>().Duration)
			{
				EnterStage(AnimStage.Show1stOutcome);
			}
			break;
		case AnimStage.Show1stOutcome:
			if (animTime >= revealDelay)
			{
				EnterStage(AnimStage.Show2ndOutcome);
			}
			break;
		case AnimStage.Show2ndOutcome:
			if (animTime >= revealDelay)
			{
				EnterStage(AnimStage.ShowSpectacle);
			}
			break;
		case AnimStage.ShowSpectacle:
			if (animTime >= revealDelay)
			{
				EnterStage(AnimStage.AnimateSpectacleBar);
			}
			break;
		case AnimStage.AnimateSpectacleBar:
		{
			float spectacleEarned = currentEvent.outcomes[animIdx].spectacleEarned;
			float num = Mathf.Clamp01(animTime / spectacleBarDuration);
			spectacleSlider.value = spectacleShown + spectacleEarned * Mathf.SmoothStep(0f, 1f, num);
			UpdateStars();
			if (num >= 1f)
			{
				spectacleShown += spectacleEarned;
				animIdx++;
				if (animIdx < outcomeItems.Count)
				{
					EnterStage(AnimStage.CardFlyIn);
				}
			}
			break;
		}
		}
	}

	public void Hide()
	{
		gameObject.SetActive(value: false);
		currentEvent = null;
		currentColosseum = null;
	}

	private static void GetSpectacleHappiness(float spectacle, out int happiness, out int seasons, out Sprite face, out string locString)
	{
		if (spectacle >= 100f)
		{
			happiness = 20;
			seasons = 4;
			face = HappinessUI.inst.veryHappy;
			locString = "happinessmod_colosseum_games_legendary";
		}
		else if (spectacle >= 60f)
		{
			happiness = 15;
			seasons = 3;
			face = HappinessUI.inst.happy;
			locString = "happinessmod_colosseum_games_great";
		}
		else if (spectacle >= 30f)
		{
			happiness = 10;
			seasons = 2;
			face = HappinessUI.inst.happy;
			locString = "happinessmod_colosseum_games";
		}
		else
		{
			happiness = 5;
			seasons = 1;
			face = HappinessUI.inst.neutral;
			locString = "happinessmod_colosseum_games";
		}
	}

	private void OnContinueClicked()
	{
		SfxSystem.PlayUiSelect();
		GetSpectacleHappiness(currentEvent.totalSpectacle, out var happiness, out var seasons, out var _, out var locString);
		float time = SeasonManager.inst.TimeInYear() * (float)seasons / 4f;
		Player.inst.AddHappinessMod("colosseumgames", time, happiness, LocalizationManager.GetTranslation(locString), currentColosseum.GetComponent<Building>().LandMass());
		currentColosseum.AcknowledgeSummary();
		Hide();
	}
}
