using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class FightPresentationUI : MonoBehaviour
{
	[Header("Round Info")]
	public TextMeshProUGUI roundText;

	public TextMeshProUGUI riskText;

	[Header("Combatant 1")]
	public TextMeshProUGUI combatant1NameText;

	public GladiatorFame combatant1Fame;

	public GladiatorFatigue combatant1Fatigue;

	[Header("Versus")]
	public TextMeshProUGUI versusText;

	[Header("Combatant 2")]
	public TextMeshProUGUI combatant2NameText;

	public GladiatorFame combatant2Fame;

	public GladiatorFatigue combatant2Fatigue;

	[Header("Presentation Timing")]
	[SerializeField]
	private float presentationDelay = 2.5f;

	[Header("Skip")]
	public Button skipRoundButton;

	[Header("Fight")]
	public GameObject bottomBar;

	public GameObject spectacleContainer;

	public Slider spectacleSlider;

	public TextMeshProUGUI currSpectacleTxt;

	[SerializeField]
	private float spectacleDecayDelay = 0.5f;

	[SerializeField]
	private float spectacleDecayPerSecond = 2f;

	[SerializeField]
	private float spectacleBarLerpSpeed = 8f;

	private ColosseumRound currentRound;

	private Colosseum currentColosseum;

	private float timer;

	private bool isPresenting;

	private bool isFighting;

	private float spectacle;

	private float timeSinceAttack;

	public GladiatorVisual combatant1Visual;

	public GameObject beast1;

	public GladiatorVisual combatant2Visual;

	public GameObject beast2;

	private GameObject spawnedBeast2;

	public float Spectacle => spectacle;

	private void Awake()
	{
		skipRoundButton.onClick.AddListener(OnSkipClicked);
	}

	public void Show(Colosseum colosseum, ColosseumRound round)
	{
		currentColosseum = colosseum;
		currentRound = round;
		timer = presentationDelay;
		isPresenting = true;
		gameObject.SetActive(value: true);
		bottomBar.SetActive(value: true);
		spectacleContainer.SetActive(value: false);
		skipRoundButton.gameObject.SetActive(value: false);
		RefreshUI();
	}

	public void ShowFight()
	{
		bottomBar.SetActive(value: false);
		spectacleContainer.SetActive(value: true);
		skipRoundButton.gameObject.SetActive(value: true);
		isFighting = true;
		spectacle = currentRound.spectacleFinal;
		timeSinceAttack = 0f;
		spectacleSlider.value = spectacle;
	}

	public void EndFight()
	{
		isFighting = false;
		skipRoundButton.gameObject.SetActive(value: false);
	}

	public void AddSpectacle(float amount)
	{
		if (isFighting)
		{
			spectacle += amount;
			timeSinceAttack = 0f;
		}
	}

	public void AddPostFightSpectacle(float amount)
	{
		spectacle += amount;
	}

	public void Hide()
	{
		gameObject.SetActive(value: false);
		currentRound = null;
		currentColosseum = null;
		isPresenting = false;
		isFighting = false;
		if ((bool)spawnedBeast2)
		{
			Object.Destroy(spawnedBeast2);
		}
	}

	private void OnSkipClicked()
	{
		SfxSystem.PlayUiSelect();
		skipRoundButton.gameObject.SetActive(value: false);
		currentColosseum.SkipRound();
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (isFighting)
		{
			timeSinceAttack += unscaledDeltaTime;
			if (timeSinceAttack > spectacleDecayDelay)
			{
				spectacle = Mathf.Max(0f, spectacle - spectacleDecayPerSecond * unscaledDeltaTime);
			}
		}
		if (spectacleContainer.activeSelf)
		{
			spectacleSlider.value = Mathf.Lerp(spectacleSlider.value, spectacle, 1f - Mathf.Exp((0f - spectacleBarLerpSpeed) * unscaledDeltaTime));
			currSpectacleTxt.text = Mathf.RoundToInt(spectacleSlider.value).ToString();
		}
		if (isPresenting)
		{
			timer -= unscaledDeltaTime;
			if (timer <= 0f)
			{
				isPresenting = false;
			}
		}
	}

	private void RefreshUI()
	{
		if (currentRound == null)
		{
			return;
		}
		roundText.text = string.Format(LocalizationManager.GetTranslation("colosseum_round_number"), currentRound.roundIndex + 1);
		if (riskText != null)
		{
			riskText.text = "Risk: " + currentRound.GetRiskLabel();
			switch (currentRound.GetRiskLabel())
			{
			case "Safe":
				riskText.color = new Color(0.5f, 0.8f, 0.34f);
				break;
			case "Risky":
				riskText.color = new Color(0.9f, 0.7f, 0.2f);
				break;
			case "Lethal":
				riskText.color = new Color(1f, 0.45f, 0.45f);
				break;
			}
		}
		Gladiator gladiator = GladiatorSystem.inst?.GetGladiator(currentRound.combatant1Id);
		if (gladiator != null)
		{
			beast1.SetActive(value: false);
			combatant1Visual.gameObject.SetActive(value: true);
			combatant1Visual.ApplyDef(gladiator.visualDef);
			combatant1Visual.SetRole(currentRound.combatant1role);
			combatant1Visual.transform.localScale *= 600f;
			combatant1NameText.text = gladiator.name;
			combatant1Fame.SetFame(gladiator.fame);
			combatant1Fatigue.SetFatigue(gladiator.fatigueTier);
		}
		versusText.text = "VS";
		combatant2Visual.gameObject.SetActive(value: false);
		beast2.SetActive(value: false);
		if ((bool)spawnedBeast2)
		{
			Object.Destroy(spawnedBeast2);
		}
		if (combatant2NameText != null)
		{
			switch (currentRound.fightType)
			{
			case ColosseumFightType.GladiatorVsGladiator:
			{
				Gladiator gladiator2 = GladiatorSystem.inst?.GetGladiator(currentRound.opponentId);
				combatant2NameText.text = gladiator2.name;
				combatant2Visual.gameObject.SetActive(value: true);
				combatant2Visual.ApplyDef(gladiator2.visualDef);
				combatant2Visual.SetRole(currentRound.opponentrole);
				combatant2Visual.transform.localScale *= 600f;
				combatant2Fame.SetFame(gladiator2.fame);
				combatant2Fatigue.gameObject.SetActive(value: true);
				combatant2Fatigue.SetFatigue(gladiator2.fatigueTier);
				break;
			}
			case ColosseumFightType.GladiatorVsBeasts:
			{
				BeastTemplate beastDefByName = GladiatorSystem.inst.GetBeastDefByName(currentRound.beastType);
				string localizedName = beastDefByName.GetLocalizedName();
				if (currentRound.beastCount > 1)
				{
					combatant2NameText.text = $"{currentRound.beastCount}x {localizedName}";
				}
				else
				{
					combatant2NameText.text = localizedName;
				}
				Transform transform = beast2.transform;
				spawnedBeast2 = Object.Instantiate(beastDefByName.mesh, transform.parent);
				spawnedBeast2.transform.SetLocalPositionAndRotation(transform.localPosition, transform.localRotation);
				spawnedBeast2.transform.localScale = transform.localScale;
				Image[] stars = combatant2Fame.stars;
				foreach (Image image in stars)
				{
					if (image != null)
					{
						image.gameObject.SetActive(value: false);
					}
				}
				combatant2Fatigue.gameObject.SetActive(value: false);
				break;
			}
			}
		}
		int layer = LayerMask.NameToLayer("UI");
		Util.SetLayerRecursively(combatant1Visual.gameObject, layer);
		Util.SetLayerRecursively(beast1, layer);
		Util.SetLayerRecursively(combatant2Visual.gameObject, layer);
		Util.SetLayerRecursively(spawnedBeast2, layer);
	}
}
