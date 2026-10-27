using System.Collections.Generic;
using Assets.Code;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using LeTai.Asset.TranslucentImage;
using PixelCrushers.DialogueSystem;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GodUI : MonoBehaviour, IKeyboardInputOverride
{
	public class GodBonusDesc
	{
		public string descTerm;

		public int cost;

		public int godIdx;

		public string GetFormattedDesc(bool on, Temple temple0)
		{
			string translation = LocalizationManager.GetTranslation(descTerm);
			if (godIdx == 2)
			{
				RadiusBonus component = temple0.GetComponent<RadiusBonus>();
				if ((bool)component)
				{
					if (!on)
					{
						return string.Format(translation, "<b><color=red>+ 0</color></b>", "<b>" + component.radiusMax + "</b>");
					}
					return string.Format(translation, "<b><color=green>+" + component.GetMaxHappiness() + "</color></b>", "<b>" + component.radiusMax + "</b>");
				}
			}
			else if (godIdx == 5 || godIdx == 1 || godIdx == 7)
			{
				RadiusBonusBuildingProduction component2 = temple0.GetComponent<RadiusBonusBuildingProduction>();
				if ((bool)component2)
				{
					if (!on)
					{
						return string.Format(translation, "<b><color=red>+ 0</color></b>", "<b>" + component2.buildingCount + "</b>");
					}
					return string.Format(translation, "<b><color=green>+" + component2.Bonus + "</color></b>", "<b>" + component2.buildingCount + "</b>");
				}
			}
			else if (godIdx == 4)
			{
				RadiusBonusBuildingProduction component3 = temple0.GetComponent<RadiusBonusBuildingProduction>();
				if ((bool)component3)
				{
					if (!on)
					{
						return string.Format(translation, "<b><color=red>+ 0%</color></b>", "<b>" + component3.buildingCount + "</b>");
					}
					return string.Format(translation, "<b><color=green>+" + component3.Bonus + "%</color></b>", "<b>" + component3.buildingCount + "</b>");
				}
			}
			else if (godIdx == 3)
			{
				return string.Format(translation, "<b>" + 20 + "</b>");
			}
			return "";
		}
	}

	public enum Status
	{
		Appearing,
		Intro,
		DedicateSelection,
		DedicateComplete,
		DedicateConfirm,
		ShowGodInfo,
		TaskComplete,
		ShowDialogOnly
	}

	public delegate void OnConversationEvent(string convoKey);

	private struct SubId
	{
		public int entryId;

		public int convoId;
	}

	private delegate void nextAnimDelegate();

	public GameObject godDisplayIndividualPrefab;

	public GameObject godEnvironmentPrefab;

	internal GodDisplay godDisplay;

	public ParticleSystem chamFollowFX;

	public static GodUI inst;

	public TextMeshProUGUI standingTxt;

	public TextMeshProUGUI godNameTMP;

	public TextMeshProUGUI godDescriptionTMP;

	public GameObject nameTitle;

	private EventInstance ambGods;

	private float oldPhi;

	private float oldTheta;

	private float oldDist;

	private Vector3 oldTrack;

	internal GodBonusDesc[] bonuses = new GodBonusDesc[GodManager.numGods];

	private bool inited;

	private Dictionary<string, int> convoCompleted = new Dictionary<string, int>();

	private bool doExit;

	private float animTime;

	public Slider statusProgress;

	public float sliderAdjustSpeed = 1f;

	private float currProgress;

	public Color[] favorColors;

	public Image sliderBackground;

	public Image sliderFill;

	public ParticleSystem confettiEffect;

	public float lightIntensity = 1f;

	private Status status = Status.Intro;

	public float dedicateCamPhi = 25f;

	public float dedicateCamDist = 20f;

	public float dedicateCompleteCamPhi = 35f;

	public float introCamPhi = 35f;

	public GameObject dedicateContainer;

	public GameObject godInfoContainer;

	private bool wasGodAngry;

	private int selectedGod = -1;

	public int confirmGodIdx = -1;

	public Button CompleteTaskButton;

	public TextMeshProUGUI CompleteTaskButtonTxt;

	private int maxBonusRings;

	public Button unlockBonusButton;

	public GameObject bonusUnlockedContainer;

	public TextMeshProUGUI bonusDescTxt;

	public TextMeshProUGUI bonusCostTxt;

	public TextMeshProUGUI unlockBonusDescTxt;

	public float bonusRingEffectInterval = 0.1f;

	public Image taskCompletableCallout;

	public Light mainLight;

	public float minLightIntensity = 0.2f;

	private float ringTimer;

	private int ringCount = -1;

	private float totalTime;

	private ArrayExt<Vector3> viewPoints = new ArrayExt<Vector3>(10);

	public GameObject favorPointsGainedContainer;

	public TextMeshProUGUI favorPointsGainedTxt;

	public TextMeshProUGUI newTaskDesc;

	public TextMeshProUGUI newTaskRewardTxt;

	public GameObject currBonusContainer;

	public GameObject currTaskContainer;

	public GameObject currActiveTaskContainer;

	public GameObject tasksCompleteContainer;

	public TextMeshProUGUI currTaskDesc;

	public TextMeshProUGUI currTaskRewardTxt;

	public Slider currTaskProgress;

	public GameObject honorLevelContainer;

	public Slider honorSlider;

	public Image honorFace;

	public GameObject honorExpected;

	public GameObject honorCurrent;

	public GameObject festivalContainer;

	public GameObject festivalCostError;

	public Transform festivalTileContainer;

	public TextMeshProUGUI festivalCostTxt;

	public TextMeshProUGUI festivalRewardTxt;

	public TextMeshProUGUI festivalHappinessBonusTxt;

	public TextMeshProUGUI festivalBonusTMP;

	public Button festivalButton;

	public GameObject festivalInProgress;

	public Slider festivalProgressSlider;

	public GameObject spellsContainer;

	public TextMeshProUGUI spellDescTMP;

	public Slider spellCooldownSlider;

	public GameObject spellWarningContainer;

	public TextMeshProUGUI spellWarningTMP;

	public GameObject spellCooldownContainer;

	public TextMeshProUGUI spellCooldownTMP;

	public TextMeshProUGUI spellCostTMP;

	public Button spellActivateBtn;

	public TooltipHook spellActivateTooltip;

	public TranslucentImage bgImage;

	public GameObject uiContainer;

	public string testAnim;

	public float testAnimTime = 0.5f;

	private bool suppressContinueButton;

	public GameObject convoContinueButton;

	private string lastPlayed = "";

	private bool inTaskDesc;

	private bool deferSpell;

	private GodSpell.CastSpell onDeferCast;

	public OnConversationEvent onConversationEnd;

	public OnConversationEvent onConversationStart;

	private int oldSpeed = -1;

	public TextMeshProUGUI dedicateName;

	public TextMeshProUGUI dedicateDesc;

	public TextMeshProUGUI dedicateBonusDesc;

	public GameObject dedicateConfirmContainer;

	private Vector3 trackPos;

	internal Building temple;

	private Animator animator;

	private List<SubId> entries = new List<SubId>();

	public ConsoleUIItem consoleContainer;

	public ConsoleUIItem consoleSubtitleBtn;

	public ConsoleUIItem consoleResponseMenu;

	public ConsoleUIItem consoleLeave;

	public ConsoleUIItem consoleRequest;

	public GameObject consoleYIcon;

	public GameObject consoleXIcon;

	private bool prevFrameConversationActive;

	private nextAnimDelegate nextAnim;

	public GameObject dialoguePanel;

	private string currConvo;

	private string prevConvo;

	private int returnNode;

	private void Awake()
	{
		inst = this;
		TryInit();
	}

	internal void TryInit()
	{
		if (inited)
		{
			return;
		}
		bonuses[2] = new GodBonusDesc
		{
			descTerm = "godui_jupiter_bonus1_desc",
			cost = 1,
			godIdx = 2
		};
		bonuses[5] = new GodBonusDesc
		{
			descTerm = "godui_ceres_bonus1_desc",
			cost = 1,
			godIdx = 5
		};
		bonuses[1] = new GodBonusDesc
		{
			descTerm = "godui_vulcan_bonus1_desc",
			cost = 1,
			godIdx = 1
		};
		bonuses[7] = new GodBonusDesc
		{
			descTerm = "godui_neptune_bonus1_desc",
			cost = 1,
			godIdx = 7
		};
		bonuses[4] = new GodBonusDesc
		{
			descTerm = "godui_mars_bonus1_desc",
			cost = 1,
			godIdx = 4
		};
		bonuses[3] = new GodBonusDesc
		{
			descTerm = "godui_apollo_bonus1_desc",
			cost = 1,
			godIdx = 3
		};
		godDisplay = Object.Instantiate(godEnvironmentPrefab).GetComponent<GodDisplay>();
		godDisplay.gameObject.SetActive(value: false);
		spellActivateBtn.onClick.AddListener(() =>
		{
			Temple component = temple.GetComponent<Temple>();
			GodSpell godSpell = GodManager.inst.spells[component.GetDedicateIdx()];
			if (Player.inst.ProsperityPoints >= godSpell.cost)
			{
				deferSpell = true;
				onDeferCast = godSpell.castSpell;
				godSpell.cooldown = godSpell.maxCooldown;
				Util.SetActive(spellCooldownContainer, active: true);
				spellCooldownTMP.text = string.Format(LocalizationManager.GetTranslation("YearsRemain"), (godSpell.cooldown / SeasonManager.inst.TimeInYear()).ToString("0.0"));
				Util.SetActive(spellWarningContainer, active: false);
				spellActivateBtn.interactable = false;
				spellCooldownSlider.value = 0f;
				spellActivateTooltip.tooltipTerm = "godui_spells_cooldown_tooltip";
				Player.inst.TakeProsperityPoints(godSpell.cost);
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_favourGained", temple.Center());
			}
		});
		inited = true;
	}

	public void OnConversationEnd()
	{
		if (DialogueManager.lastConversationStarted == "")
		{
			return;
		}
		if (prevConvo != null && prevConvo != DialogueManager.lastConversationStarted)
		{
			DialogueManager.StopConversation();
			DialogueManager.StartConversation(prevConvo, null, null, returnNode);
			prevConvo = null;
			returnNode = -1;
			return;
		}
		string lastConversationStarted = DialogueManager.lastConversationStarted;
		if (!convoCompleted.ContainsKey(lastConversationStarted))
		{
			convoCompleted.Add(lastConversationStarted, 0);
		}
		convoCompleted[lastConversationStarted] += 1;
		switch (lastConversationStarted)
		{
		case "GodIntro":
			GodManager.inst.playerSawIntro = true;
			TransitionTo(Status.DedicateSelection);
			break;
		case "GodDedicateAccept":
		case "GodTaskComplete":
			if (lastConversationStarted == "GodTaskComplete")
			{
				GodManager.inst.CompleteCurrTask(temple.GetComponent<Temple>().GetDedicateIdx());
			}
			TransitionTo(Status.ShowGodInfo);
			break;
		default:
			Cinematics.inst.ShowBars(show: false);
			RestoreOldCamera();
			Hide();
			break;
		}
		if (inTaskDesc)
		{
			dialoguePanel.SetActive(value: false);
			godInfoContainer.SetActive(value: true);
			inTaskDesc = false;
		}
		onConversationEnd?.Invoke(lastConversationStarted);
	}

	public void PlayDedicateEffect(int godIdx)
	{
		OneOffEffect oneOffEffect = temple.GetComponent<Temple>().dedicateEffect.Create(temple.Center());
		switch (godIdx)
		{
		case 2:
			oneOffEffect.Color = Color.yellow;
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_jupiter", temple.Center());
			break;
		case 1:
			oneOffEffect.Color = Color.red;
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_vulcan", temple.Center());
			break;
		case 5:
			oneOffEffect.Color = Color.green;
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_ceres", temple.Center());
			break;
		case 7:
			oneOffEffect.Color = Color.cyan;
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_neptune", temple.Center());
			break;
		case 4:
			oneOffEffect.Color = new Color(0.7f, 0f, 0f);
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_mars", temple.Center());
			break;
		case 3:
			oneOffEffect.Color = Color.gold;
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_select_apollo", temple.Center());
			break;
		}
		oneOffEffect.Play();
		Cam.inst.Shake(new Vector3(0f, -2f, 0f));
	}

	public void UpdateDedicateHoverNameDesc(GodInfoUI info)
	{
		if (info.nameId == "minerva")
		{
			dedicateName.GetComponent<Localize>().Term = "newfeature_comingsoon";
		}
		else
		{
			dedicateName.GetComponent<Localize>().Term = info.GetLocalizedName();
		}
		dedicateDesc.GetComponent<Localize>().Term = info.GetLocalizedDescription();
		if (temple.UniqueName == "temple")
		{
			dedicateBonusDesc.SetText(LocalizationManager.GetTranslation("godui_dedicationbonus_" + info.nameId.ToLower()));
		}
		else if (temple.UniqueName == "temple2")
		{
			dedicateBonusDesc.text = LocalizationManager.GetTranslation("godui_festival_desc");
		}
		else
		{
			string text = LocalizationManager.GetTranslation("godui_spells_desc") + "\n\n";
			text = text + "<b>- " + LocalizationManager.GetTranslation("godui_" + info.nameId.ToLower() + "_spell_desc") + " -</b>";
			dedicateBonusDesc.text = text;
		}
		if (info.disabled)
		{
			dedicateDesc.color = new Color(0.6f, 0.6f, 0.6f, 1f);
		}
		else
		{
			dedicateDesc.color = Color.white;
		}
	}

	public void SetSelectedGod(int i)
	{
		selectedGod = i;
		godDisplay.SelectGod(i);
		temple.GetComponent<Temple>().SetDedicateIdx(i);
		wasGodAngry = Player.inst.IsGodAngry(World.GetLandmassOwner(temple.LandMass()), i);
	}

	public bool WasGodAngry()
	{
		return wasGodAngry;
	}

	public void OnClickedFestival()
	{
		int dedicateIdx = temple.GetComponent<Temple>().GetDedicateIdx();
		OfferingTask.RemoveResources(GodManager.inst.GetFestivalCost(dedicateIdx, temple.LandMass()));
		int num = 5;
		ProsperityUI.inst.AnimateReward(festivalRewardTxt.transform.position, num);
		Player.inst.GiveProsperityPoints(num);
		GodManager.inst.ThrowFestival(dedicateIdx);
		temple.GetComponent<Temple>().StartFestival();
	}

	public void TransitionTo(Status newStatus)
	{
		godInfoContainer.gameObject.SetActive(value: false);
		dedicateContainer.gameObject.SetActive(value: false);
		dialoguePanel.gameObject.SetActive(value: false);
		nameTitle.gameObject.SetActive(value: false);
		gameObject.GetComponent<Image>().enabled = true;
		if (status == Status.DedicateSelection)
		{
			ProsperityUI.inst.gameObject.SetActive(value: true);
		}
		status = newStatus;
		switch (status)
		{
		case Status.ShowDialogOnly:
			Cinematics.inst.ShowBars(show: true);
			dialoguePanel.gameObject.SetActive(value: true);
			break;
		case Status.Appearing:
			ProsperityUI.inst.gameObject.SetActive(value: false);
			break;
		case Status.Intro:
		{
			Cinematics.inst.ShowBars(show: true);
			dialoguePanel.gameObject.SetActive(value: true);
			ProsperityUI.inst.gameObject.SetActive(value: false);
			GodInfoUI component2 = godDisplay.gods[2].GetComponent<GodInfoUI>();
			godNameTMP.GetComponent<Localize>().Term = component2.GetLocalizedName();
			godDescriptionTMP.GetComponent<Localize>().Term = component2.GetLocalizedDescription();
			godInfoContainer.gameObject.SetActive(value: false);
			break;
		}
		case Status.DedicateSelection:
			Cinematics.inst.ShowBars(show: false);
			dedicateContainer.gameObject.SetActive(value: true);
			dedicateBonusDesc.gameObject.SetActive(value: true);
			dedicateConfirmContainer.SetActive(value: false);
			GameUI.inst.SetCursorMode(GameUI.inst.dedicateGodCursorMode);
			gameObject.GetComponent<Image>().enabled = false;
			break;
		case Status.DedicateConfirm:
			dedicateContainer.gameObject.SetActive(value: true);
			dedicateBonusDesc.gameObject.SetActive(value: false);
			dedicateConfirmContainer.SetActive(value: true);
			break;
		case Status.DedicateComplete:
		{
			dialoguePanel.gameObject.SetActive(value: true);
			godInfoContainer.gameObject.SetActive(value: false);
			if (temple.UniqueName == "temple")
			{
				DialogueLua.SetVariable("Var1", "2");
			}
			if (temple.UniqueName == "temple2")
			{
				DialogueLua.SetVariable("Var1", "4");
			}
			DialogueManager.StartConversation("GodDedicateAccept");
			int dedicateIdx2 = temple.GetComponent<Temple>().GetDedicateIdx();
			GodInfoUI component2 = godDisplay.gods[dedicateIdx2].GetComponent<GodInfoUI>();
			godNameTMP.GetComponent<Localize>().Term = component2.GetLocalizedName();
			godDescriptionTMP.GetComponent<Localize>().Term = component2.GetLocalizedDescription();
			nameTitle.gameObject.SetActive(value: true);
			godDisplay.CompleteTaskAnim(dedicateIdx2);
			break;
		}
		case Status.TaskComplete:
			Cinematics.inst.ShowBars(show: false);
			dialoguePanel.gameObject.SetActive(value: true);
			nameTitle.gameObject.SetActive(value: true);
			godInfoContainer.gameObject.SetActive(value: false);
			DialogueLua.SetVariable("Var1", GodManager.inst.GetCurrTask(temple.GetComponent<Temple>().GetDedicateIdx()).reward);
			DialogueManager.StartConversation("GodTaskComplete");
			break;
		case Status.ShowGodInfo:
		{
			Cinematics.inst.ShowBars(show: false);
			dialoguePanel.gameObject.SetActive(value: false);
			nameTitle.gameObject.SetActive(value: true);
			godInfoContainer.gameObject.SetActive(value: true);
			int dedicateIdx = temple.GetComponent<Temple>().GetDedicateIdx();
			if (GodManager.inst.GetNextTask(dedicateIdx) != null && GodManager.inst.GetCurrTask(dedicateIdx) == null)
			{
				AcceptNewTask();
			}
			currBonusContainer.SetActive(value: false);
			currTaskContainer.gameObject.SetActive(value: false);
			honorLevelContainer.SetActive(value: false);
			festivalContainer.SetActive(value: false);
			Util.SetActive(spellsContainer, active: false);
			if (temple.UniqueName == "temple")
			{
				currTaskContainer.SetActive(value: true);
				GodTask currTask = GodManager.inst.GetCurrTask(dedicateIdx);
				if (currTask != null)
				{
					currTaskDesc.text = currTask.GetDesc();
				}
				currActiveTaskContainer.SetActive(currTask != null);
				tasksCompleteContainer.SetActive(currTask == null);
				currBonusContainer.gameObject.SetActive(value: true);
			}
			else if (temple.UniqueName == "temple2")
			{
				honorLevelContainer.SetActive(value: true);
				festivalContainer.SetActive(value: true);
				ResourceAmount festivalCost = GodManager.inst.GetFestivalCost(dedicateIdx, temple.LandMass());
				festivalButton.interactable = Player.inst.FocusedResources.HasCost(festivalCost);
				festivalCostTxt.text = festivalCost.NeedCost(Player.inst.FocusedResources, "    ");
				Util.SetActive(festivalCostError, !festivalButton.interactable);
				temple.GetComponent<Temple>().EvalFestivalForumHappinessBonus(out var okTiles, out var occupied, out var _);
				for (int i = 0; i < festivalTileContainer.childCount; i++)
				{
					Transform child = festivalTileContainer.GetChild(i);
					child.GetChild(0).gameObject.SetActive(value: false);
					child.GetChild(1).gameObject.SetActive(value: false);
					child.GetChild(2).gameObject.SetActive(value: false);
					if (i < okTiles)
					{
						child.GetChild(0).gameObject.SetActive(value: true);
						child.GetChild(1).gameObject.SetActive(value: true);
					}
					if (i >= okTiles && i < okTiles + occupied)
					{
						child.GetChild(0).gameObject.SetActive(value: true);
						child.GetChild(2).gameObject.SetActive(value: true);
					}
					if (i >= okTiles + occupied)
					{
						child.GetChild(2).gameObject.SetActive(value: true);
					}
				}
				okTiles = Mathff.Min(okTiles, 6);
				festivalHappinessBonusTxt.text = string.Format(LocalizationManager.GetTranslation("godui_festival_happinessbonus_value"), "<size=16><b>+" + okTiles * 2 + "/12</b></size>");
				festivalBonusTMP.text = string.Format(LocalizationManager.GetTranslation("godui_festival_happinessbonus_desc"), "<color=green>+2</color>");
			}
			else if (temple.UniqueName == "temple3")
			{
				Util.SetActive(spellsContainer, active: true);
				Util.SetActive(honorLevelContainer, active: true);
				Temple component = temple.GetComponent<Temple>();
				GodSpell godSpell = GodManager.inst.spells[component.GetDedicateIdx()];
				bool flag = godSpell.isValid();
				spellActivateBtn.interactable = flag && godSpell.cooldown <= 0f && Player.inst.ProsperityPoints >= godSpell.cost;
				spellCooldownSlider.value = 1f - godSpell.cooldown / godSpell.maxCooldown;
				spellCooldownTMP.text = string.Format(LocalizationManager.GetTranslation("YearsRemain"), (godSpell.cooldown / SeasonManager.inst.TimeInYear()).ToString("0.0"));
				Util.SetActive(spellCooldownContainer, godSpell.cooldown > 0f);
				Util.SetActive(spellWarningContainer, !flag && !spellCooldownContainer.activeSelf);
				spellCostTMP.text = godSpell.cost.ToString();
				spellDescTMP.text = LocalizationManager.GetTranslation(godSpell.descTerm);
				if (godSpell.cooldown > 0f)
				{
					spellWarningTMP.text = LocalizationManager.GetTranslation("godui_spells_cooldown_tooltip");
					spellActivateTooltip.tooltipTerm = "godui_spells_cooldown_tooltip";
				}
				else if (Player.inst.ProsperityPoints < godSpell.cost)
				{
					spellWarningTMP.text = LocalizationManager.GetTranslation("Insufficient Points");
					spellActivateTooltip.tooltipTerm = "Insufficient Points";
				}
				else if (!flag)
				{
					spellWarningTMP.text = LocalizationManager.GetTranslation(godSpell.invalidTerm);
					spellActivateTooltip.tooltipTerm = string.Empty;
				}
				else
				{
					spellActivateTooltip.tooltipTerm = string.Empty;
				}
			}
			break;
		}
		}
	}

	public void OnDedicateConfirm()
	{
		PlayDedicateEffect(confirmGodIdx);
		SetSelectedGod(confirmGodIdx);
		int lm = temple.LandMass();
		GodManager.inst.RefreshGodAngerAfterTempleDedication(lm, confirmGodIdx);
		TransitionTo(Status.DedicateComplete);
	}

	public void OnDedicateBack()
	{
		confirmGodIdx = -1;
		TransitionTo(Status.DedicateSelection);
	}

	public void CompleteTask()
	{
		TransitionTo(Status.TaskComplete);
		godDisplay.CompleteTaskAnim();
		PlayDedicateEffect(temple.GetComponent<Temple>().GetDedicateIdx());
	}

	public void UnlockBonus()
	{
		Temple component = temple.GetComponent<Temple>();
		component.UnlockBonus();
		Cam.inst.Shake(new Vector3(0f, -2f, 0f));
		int dedicateIdx = component.GetDedicateIdx();
		Player.inst.TakeProsperityPoints(bonuses[dedicateIdx].cost);
		if (dedicateIdx == 3)
		{
			OneOffEffect oneOffEffect = component.dedicateEffect.Create(temple.Center());
			oneOffEffect.Color = Color.gold;
			oneOffEffect.Play();
		}
		GameUI.inst.RefreshOverlay();
		ringCount = 0;
		ringTimer = 1f;
		maxBonusRings = 0;
		RadiusBonus component2 = component.GetComponent<RadiusBonus>();
		if ((bool)component2 && component2.applied)
		{
			maxBonusRings = (int)component2.radiusMax;
		}
		RadiusBonusProduction component3 = component.GetComponent<RadiusBonusProduction>();
		if ((bool)component3 && component3.applied)
		{
			maxBonusRings = (int)component3.radiusMax;
		}
		RadiusBonusBuildingProduction component4 = component.GetComponent<RadiusBonusBuildingProduction>();
		if ((bool)component4 && component4.applied)
		{
			OneOffEffect oneOffEffect2 = EffectsMan.inst.TileGodBonusRingEffect.Create(temple.Center());
			oneOffEffect2.transform.localScale = new Vector3(component4.radius + 0.5f, component4.radius + 0.5f, component4.radius + 0.5f);
			oneOffEffect2.Color = Player.inst.FullProductionInfluence;
			oneOffEffect2.Play();
		}
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_favourGained", temple.Center());
	}

	private void BonusEffectRing(float r)
	{
		World.inst.ForEachTileTouchingRadius(temple.Center(), r, (int x, int z, Cell cell) =>
		{
			Vector3 center3D = cell.Center3D;
			if (center3D.y < -0.1f)
			{
				center3D.y = 0.1f;
			}
			OneOffEffect oneOffEffect = EffectsMan.inst.TileGodBonusEffect.Create(center3D);
			temple.GetComponent<Temple>().GetDedicateIdx();
			oneOffEffect.Color = Player.inst.FullProductionInfluence;
			oneOffEffect.Play();
		});
	}

	private void Update()
	{
		totalTime += Time.unscaledDeltaTime;
		mainLight.intensity -= Time.unscaledDeltaTime;
		if (mainLight.intensity < minLightIntensity)
		{
			mainLight.intensity = minLightIntensity;
		}
		if (temple != null)
		{
			if (ringCount != -1)
			{
				ringTimer += Time.unscaledDeltaTime;
				if (ringTimer > bonusRingEffectInterval)
				{
					BonusEffectRing(ringCount);
					ringTimer = 0f;
					ringCount++;
					if (ringCount > maxBonusRings)
					{
						ringCount = -1;
					}
				}
			}
			GodTask currTask = GodManager.inst.GetCurrTask(temple.GetComponent<Temple>().GetDedicateIdx());
			if (currTask != null)
			{
				currTaskProgress.value = currTask.GetProgress();
				currTaskDesc.text = currTask.GetDesc();
				currTaskRewardTxt.SetText("{0}", currTask.reward);
			}
			currActiveTaskContainer.SetActive(currTask != null);
			tasksCompleteContainer.SetActive(currTask == null);
			bool flag = currTask?.IsComplete() ?? false;
			CompleteTaskButton.interactable = flag;
			if (flag)
			{
				Color color = taskCompletableCallout.color;
				color.a = Mathf.Lerp(0.2f, 0.5f, (Mathf.Sin(totalTime * 1.5f) + 1f) * 0.5f);
				taskCompletableCallout.color = color;
			}
			Util.SetEnabled(taskCompletableCallout, flag);
			if (currTask is OfferingTask)
			{
				CompleteTaskButtonTxt.GetComponent<Localize>().Term = "godui_makeoffering_button";
			}
			else
			{
				CompleteTaskButtonTxt.GetComponent<Localize>().Term = "godui_completetask_button";
			}
		}
		else
		{
			ringCount = 0;
			ringTimer = 0f;
		}
		viewPoints.Clear();
		switch (status)
		{
		case Status.Appearing:
		{
			if (godDisplay.Status == GodDisplay.State.Appeared)
			{
				if (!GodManager.inst.playerSawIntro)
				{
					DialogueManager.StartConversation("GodIntro");
					TransitionTo(Status.Intro);
				}
				else if (temple.GetComponent<Temple>().GetDedicateIdx() == -1)
				{
					TransitionTo(Status.DedicateSelection);
				}
				else
				{
					TransitionTo(Status.ShowGodInfo);
				}
				Cam.inst.desiredPhi = dedicateCamPhi;
			}
			for (int k = 0; k < godDisplay.gods.Length; k++)
			{
				viewPoints.Add(godDisplay.gods[k].GetComponent<GodShaderDriver>().chamStart.position);
			}
			break;
		}
		case Status.Intro:
		case Status.DedicateSelection:
		{
			Cam.inst.desiredPhi = dedicateCamPhi;
			for (int i = 0; i < godDisplay.gods.Length; i++)
			{
				viewPoints.Add(godDisplay.gods[i].GetComponent<GodShaderDriver>().chamStart.position);
			}
			break;
		}
		case Status.DedicateConfirm:
			godDisplay.gods[confirmGodIdx].GetComponent<GodInfoUI>().highlight.SetOutlineImmediate(0);
			viewPoints.Add(godDisplay.gods[confirmGodIdx].GetComponent<GodShaderDriver>().chamStart.position);
			Cam.inst.desiredPhi = dedicateCamPhi - 5f;
			break;
		case Status.DedicateComplete:
		case Status.ShowGodInfo:
		case Status.TaskComplete:
		{
			viewPoints.Add(temple.Center());
			viewPoints.Add(godDisplay.gods[GetDedicationIdx()].GetComponent<GodShaderDriver>().chamStart.position);
			Cam.inst.desiredPhi = dedicateCompleteCamPhi;
			Temple component = temple.GetComponent<Temple>();
			int dedicateIdx2 = component.GetDedicateIdx();
			if (dedicateIdx2 != -1)
			{
				bonusDescTxt.text = bonuses[dedicateIdx2].GetFormattedDesc(on: true, temple.GetComponent<Temple>());
				bonusCostTxt.SetText("{0}", bonuses[dedicateIdx2].cost);
			}
			bool flag2 = component.bonusLevel > 0;
			bool interactable = Player.inst.ProsperityPoints >= bonuses[dedicateIdx2].cost;
			unlockBonusButton.interactable = interactable;
			unlockBonusButton.gameObject.SetActive(!flag2);
			bonusUnlockedContainer.SetActive(flag2);
			unlockBonusDescTxt.gameObject.SetActive(!flag2);
			if (!(temple.UniqueName == "temple2") && !(temple.UniqueName == "temple3"))
			{
				break;
			}
			Util.SetActive(festivalInProgress, component.GetFestivalProgress() < 0.99f);
			festivalProgressSlider.value = Mathff.Max(component.GetFestivalProgress(), 0.05f);
			Player.GodHonorInfo[] godHonor = Player.inst.PlayerLandmassOwner.godHonor;
			for (int j = 0; j < godHonor.Length; j++)
			{
				if (j == dedicateIdx2)
				{
					honorSlider.value = (float)godHonor[j].honor / (float)Player.inst.GodHonorMax;
					Player.GodStanding standing = godHonor[j].GetStanding(Player.inst.PlayerLandmassOwner);
					honorFace.sprite = GodHonorUI.inst.GetTextureForHonor(standing);
					int honorGoal = Player.inst.GetHonorGoal(Player.inst.PlayerLandmassOwner);
					Vector2 anchoredPosition = honorExpected.GetComponent<RectTransform>().anchoredPosition;
					anchoredPosition.y = (float)honorGoal / (float)Player.inst.GodHonorMax * honorSlider.GetComponent<RectTransform>().sizeDelta.x;
					honorExpected.GetComponent<RectTransform>().anchoredPosition = anchoredPosition;
					Vector2 anchoredPosition2 = honorCurrent.GetComponent<RectTransform>().anchoredPosition;
					anchoredPosition2.y = honorSlider.value * honorSlider.GetComponent<RectTransform>().sizeDelta.x;
					honorCurrent.GetComponent<RectTransform>().anchoredPosition = anchoredPosition2;
				}
			}
			break;
		}
		case Status.ShowDialogOnly:
			if ((bool)temple)
			{
				int dedicateIdx = temple.GetComponent<Temple>().GetDedicateIdx();
				viewPoints.Add(temple.Center());
				viewPoints.Add(godDisplay.gods[dedicateIdx].GetComponent<GodShaderDriver>().chamStart.position);
			}
			else
			{
				viewPoints.Add(trackPos);
			}
			break;
		}
		Cam.inst.BringIntoView(viewPoints);
		if (status == Status.Appearing || status == Status.Intro)
		{
			if ((bool)temple && temple.GetComponent<Temple>().GetDedicateIdx() == -1)
			{
				Cam.inst.desiredDist = dedicateCamDist;
			}
			else if (Cam.inst.desiredDist > oldDist)
			{
				Cam.inst.desiredDist = oldDist;
			}
		}
		if (status == Status.DedicateSelection)
		{
			Cam.inst.desiredDist = dedicateCamDist;
		}
		if (status == Status.DedicateConfirm)
		{
			Cam.inst.desiredDist = dedicateCamDist * 0.85f;
		}
		if (suppressContinueButton)
		{
			convoContinueButton.SetActive(value: false);
		}
		if (gameObject.activeSelf)
		{
			statusProgress.value = currProgress;
		}
		if (GamepadControl.inst.isControllerActive)
		{
			if (DialogueManager.instance.IsConversationActive)
			{
				if (!prevFrameConversationActive)
				{
					consoleRequest.Reset();
					GamepadControl.inst.nextSelected = gameObject;
				}
				else if (!IsConsoleFocused())
				{
					if (consoleSubtitleBtn.gameObject.activeSelf)
					{
						consoleSubtitleBtn.Hover();
					}
					else if (consoleResponseMenu.IsItemAutoSelectable())
					{
						consoleResponseMenu.Hover();
					}
					else
					{
						GamepadControl.inst.nextSelected = gameObject;
					}
				}
			}
			else if (!IsConsoleFocused())
			{
				if (prevFrameConversationActive)
				{
					consoleLeave.Hover();
				}
				else
				{
					consoleRequest.Hover();
				}
			}
		}
		prevFrameConversationActive = DialogueManager.instance.IsConversationActive;
		MiniMapUI.inst.SetVisibility(v: false);
	}

	internal void ShowFavorPointsGained()
	{
		Lua.Result variable = DialogueLua.GetVariable("Var1");
		favorPointsGainedTxt.SetText("+" + variable.asString);
		favorPointsGainedContainer.gameObject.SetActive(value: true);
		ProsperityUI.inst.AnimateReward(favorPointsGainedTxt.transform.position, variable.asInt);
		Player.inst.GiveProsperityPoints(variable.asInt);
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_favourGained", temple.Center());
	}

	public void AcceptNewTask()
	{
		int dedicateIdx = temple.GetComponent<Temple>().GetDedicateIdx();
		GodManager.inst.AcceptNextTask(dedicateIdx);
		GodTask currTask = GodManager.inst.GetCurrTask(dedicateIdx);
		currTaskRewardTxt.SetText("{0}", currTask.reward);
		currTaskDesc.SetText(currTask.GetDesc());
		currTaskContainer.gameObject.SetActive(value: true);
	}

	private bool IsConsoleFocused()
	{
		if (GamepadControl.inst.nextSelected != null && GamepadControl.inst.CurrentSelected != null && GamepadControl.inst.CurrentSelected != gameObject)
		{
			return GamepadControl.inst.CurrentSelected.activeInHierarchy;
		}
		return false;
	}

	public void PlayEmote(string name, int id)
	{
		string text = "AiHeadEmote" + name + id;
		if (text != lastPlayed)
		{
			SfxSystem.inst.PlayFromBankOneShot(text, Cam.inst.CamPos);
			lastPlayed = text;
		}
	}

	public void RequestTask()
	{
		dialoguePanel.SetActive(value: true);
		godInfoContainer.SetActive(value: false);
		int dedicateIdx = temple.GetComponent<Temple>().GetDedicateIdx();
		DialogueManager.StartConversation(GodManager.inst.GetNextTask(dedicateIdx).convo);
		inTaskDesc = true;
	}

	private void RestoreOldCamera()
	{
		Cam.inst.desiredPhi = oldPhi;
		Cam.inst.desiredTheta = oldTheta;
		Cam.inst.desiredDist = oldDist;
		Cam.inst.SetDesiredTrackingPos(oldTrack);
	}

	public void Hide()
	{
		if (godDisplay != null)
		{
			godDisplay.Hide();
		}
		if (temple != null)
		{
			Cinematics.inst.ShowBars(show: false);
			RestoreOldCamera();
			GameUI.inst.ReturnToDefaultCursorMode();
			gameObject.GetComponent<Image>().enabled = true;
			int dedicateIdx = temple.GetComponent<Temple>().GetDedicateIdx();
			if (dedicateIdx != -1 && GodManager.inst.GetNextTask(dedicateIdx) != null && GodManager.inst.GetCurrTask(dedicateIdx) == null)
			{
				temple.GetComponent<Temple>().issueButton.gameObject.SetActive(value: true);
			}
		}
		if (gameObject.activeSelf)
		{
			ProsperityUI.inst.gameObject.SetActive(value: true);
			MiniMapUI.inst.SetVisibility(v: true);
			DialogueManager.StopConversation();
			gameObject.SetActive(value: false);
			if (oldSpeed != -1)
			{
				TimeManager.inst.SetSpeed(oldSpeed, skipSfx: true);
			}
			if (ambGods.isValid() && ambGods.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
			{
				ambGods.stop(STOP_MODE.IMMEDIATE);
			}
			MusicSystem.inst.StartDefaultMusic();
			KeyboardControl.inst.inputOverride = null;
			GamepadControl.inst.nextSelected = null;
			temple = null;
			if (deferSpell)
			{
				onDeferCast?.Invoke();
				deferSpell = false;
			}
		}
	}

	public void Show(Building newTemple, Vector3 sfxpos)
	{
		wasGodAngry = false;
		trackPos = sfxpos;
		oldPhi = Cam.inst.desiredPhi;
		oldTheta = Cam.inst.desiredTheta;
		oldDist = Cam.inst.desiredDist;
		oldTrack = Cam.inst.DesiredTrackingPos;
		favorPointsGainedContainer.SetActive(value: false);
		dedicateContainer.gameObject.SetActive(value: false);
		nameTitle.gameObject.SetActive(value: false);
		dialoguePanel.gameObject.SetActive(value: false);
		unlockBonusButton.gameObject.SetActive(value: true);
		bonusUnlockedContainer.SetActive(value: false);
		TryInit();
		temple = newTemple;
		Cam.inst.desiredDist = dedicateCamDist;
		Cam.inst.desiredPhi = dedicateCamPhi;
		Cinematics.inst.ShowBars(show: true);
		if (temple != null)
		{
			int dedicateIdx = temple.GetComponent<Temple>().GetDedicateIdx();
			if (dedicateIdx == -1)
			{
				TransitionTo(Status.Appearing);
			}
			else
			{
				GodInfoUI component = godDisplay.gods[dedicateIdx].GetComponent<GodInfoUI>();
				godNameTMP.GetComponent<Localize>().Term = component.GetLocalizedName();
				godDescriptionTMP.GetComponent<Localize>().Term = component.GetLocalizedDescription();
				if (Player.inst.IsGodAngry(World.GetLandmassOwner(temple.LandMass()), dedicateIdx))
				{
					StartConvo(GodManager.inst.GetConvoForWarning(dedicateIdx, temple.LandMass()));
					TransitionTo(Status.ShowDialogOnly);
				}
				else
				{
					TransitionTo(Status.ShowGodInfo);
				}
			}
			godDisplay.ShowAt(temple.Center(), dedicateIdx);
		}
		else
		{
			TransitionTo(Status.ShowDialogOnly);
		}
		suppressContinueButton = false;
		entries.Clear();
		prevConvo = null;
		returnNode = -1;
		oldSpeed = TimeManager.inst.speedInUse;
		TimeManager.inst.SetPaused(skipSfx: true);
		gameObject.SetActive(value: true);
		prevFrameConversationActive = false;
		GamepadControl.inst.nextSelected = gameObject;
		if (GamepadControl.inst.isControllerActive)
		{
			ConsoleTileUI.inst.SetVisible(v: false);
		}
		convoCompleted.Clear();
		currProgress = 67f;
		KeyboardControl.inst.inputOverride = this;
		MiniMapUI.inst.SetVisibility(v: false);
		ProsperityUI.inst.SetMissionVisibility(v: false);
		ambGods = RuntimeManager.CreateInstance("event:/SFX ASITP/sfx_gods_lp");
		ambGods.set3DAttributes(sfxpos.To3DAttributes());
		ambGods.start();
		ambGods.release();
		MusicSystem.inst.StartGodMusic();
	}

	public int GetDedicationIdx()
	{
		if (!(temple != null))
		{
			return -1;
		}
		return temple.GetComponent<Temple>().GetDedicateIdx();
	}

	private bool HasVisitedConvoNode(int dialogId, int convoId)
	{
		for (int i = 0; i < entries.Count; i++)
		{
			if (entries[i].convoId == convoId && entries[i].entryId == dialogId)
			{
				return true;
			}
		}
		return false;
	}

	public void OnConversationLineEnd(Subtitle sub)
	{
		if (!HasVisitedConvoNode(sub.dialogueEntry.id, sub.dialogueEntry.conversationID))
		{
			entries.Add(new SubId
			{
				entryId = sub.dialogueEntry.id,
				convoId = sub.dialogueEntry.conversationID
			});
		}
		favorPointsGainedContainer.gameObject.SetActive(value: false);
	}

	public void OnPressedContinue()
	{
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_SelectFromMenu_01");
	}

	public bool DidDialogNodeAlready(int id)
	{
		return HasVisitedConvoNode(id, DialogueManager.lastConversationID);
	}

	public void StartConvo(string convo)
	{
		DialogueManager.StopConversation();
		DialogueManager.StartConversation(convo, null, null, -1);
	}

	public void StartSubConvo(string convo, int returnNode)
	{
		prevConvo = DialogueManager.lastConversationStarted;
		DialogueManager.StopConversation();
		DialogueManager.StartConversation(convo);
		this.returnNode = returnNode;
	}

	public bool Visible()
	{
		return gameObject.activeSelf;
	}

	void IKeyboardInputOverride.UpdateKeyboardInput()
	{
		if (ConfigurableControls.inst.GetInputActionKeyDown(900))
		{
			if (DialogueManager.instance.IsConversationActive)
			{
				convoContinueButton.GetComponent<StandardUIContinueButtonFastForward>().OnFastForward();
				CompleteTaskButton.interactable = !CompleteTaskButton.interactable;
				CompleteTaskButton.interactable = !CompleteTaskButton.interactable;
			}
			else
			{
				Hide();
			}
		}
	}
}
