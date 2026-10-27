using System;
using System.Collections.Generic;
using Assets.Code;
using PixelCrushers.DialogueSystem;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class DiplomacyUI : MonoBehaviour
{
	private struct SubId
	{
		public int entryId;

		public int convoId;
	}

	private delegate void nextAnimDelegate();

	public TextMeshProUGUI standingTxt;

	public TextMeshProUGUI nameTxt;

	public GameObject missionRoot;

	public TextMeshProUGUI missionDescTxt;

	public TextMeshProUGUI missionConditionTxt;

	public GameObject missionResultRoot;

	public TextMeshProUGUI missionResult;

	public Button missionInfoToggle;

	public Button resourceInfoToggle;

	public Slider busyBar;

	public GameObject resourceCostRoot;

	public AINegotiationUI negotiationUI;

	public ResourceCostUI resourceCostUI;

	public GameObject EffectMount;

	public ParticleSystem delightParticle;

	public ParticleSystem sadParticle;

	public ParticleSystem angryParticle;

	public ParticleSystem surpriseParticle;

	public ParticleSystem interestedParticle;

	public ParticleSystem intriguedParticle;

	public ParticleSystem ohwellParticle;

	public ParticleSystem upsetParticle;

	public ParticleSystem mischiefParticle;

	public ParticleSystem skepticalParticle;

	public ParticleSystem scaredParticle;

	public ParticleSystem happyParticle;

	private bool inited;

	private string[] veryBadMoods = new string[4] { "devastated", "depressed", "enraged", "angry" };

	private string[] badMoods = new string[8] { "confused", "upset", "annoyed", "tense", "cold", "grumpy", "disappointed", "defensive" };

	private string[] neutralMoods = new string[3] { "fine", "calm", "bored" };

	private string[] goodMoods = new string[4] { "happy", "relaxed", "pleased", "good" };

	private string[] veryGoodMoods = new string[4] { "elated", "thankful", "excited", "delighted" };

	private Dictionary<string, int> convoCompleted = new Dictionary<string, int>();

	internal bool doInquire;

	public Button inquireButton;

	private float animTime;

	public Slider statusProgress;

	public float sliderAdjustSpeed = 1f;

	private float currProgress;

	private LandmassOwner.Standing currStanding;

	public Color[] favorColors;

	public Image sliderBackground;

	public Image sliderFill;

	public ParticleSystem confettiEffect;

	private int lastFavor = -1;

	public string testAnim;

	public float testAnimTime = 0.5f;

	public GameObject feastMenu;

	private bool suppressContinueButton;

	public GameObject convoContinueButton;

	private string feastType;

	public GameObject eatUI;

	public EatMeal eatBread;

	public EatMeal eatApples;

	public EatMeal eatPork;

	public EatMeal eatFish;

	private EatMeal currMeal;

	public float neutralFadeTime = 0.6f;

	public float neutralGrumpyFadeTime = 0.6f;

	public float neutralAngryFadeTime = 0.6f;

	public float neutralHappyFadeTime = 0.6f;

	public float lookAtSideFadeTime = 0.6f;

	private float crossFadeTime = 0.6f;

	private string lastPlayed = "";

	internal bool deferDisbandEnvoy;

	private int oldSpeed = -1;

	private LandmassOwner landmassOwner;

	[NonSerialized]
	public AIKingdom kingdom;

	private Envoy foreignEnvoy;

	private GameObject[] heads;

	public Light portraitLight;

	private bool showRulerPortrait;

	private float showRulerPortraitTime;

	private static List<Renderer> headRenderers = new List<Renderer>();

	private Animator animator;

	private bool deferDestroyKingdom;

	public TextMeshProUGUI dockStatusTxt;

	private List<SubId> entries = new List<SubId>();

	public ConsoleUIItem consoleContainer;

	public ConsoleUIItem consoleSubtitleBtn;

	public ConsoleUIItem consoleResponseMenu;

	public ConsoleUIItem consoleNegotiation;

	public ConsoleUIItem consoleFeast;

	public ConsoleUIItem consoleLeave;

	public ConsoleUIItem consoleRequest;

	public GameObject consoleYIcon;

	public GameObject consoleXIcon;

	private bool prevFrameConversationActive;

	private nextAnimDelegate nextAnim;

	public GameObject busyContainer;

	public GameObject requestBtn;

	public GameObject dialoguePanel;

	public GameObject envoyPortrait;

	public GameObject rulerPortrait;

	public GameObject speakOnBehalf;

	private AIObjectiveType aiObjective;

	private bool didRulerMessage;

	private bool didChat;

	private string currConvo;

	private string prevConvo;

	private int returnNode;

	private void TryInit()
	{
		if (inited)
		{
			return;
		}
		heads = new GameObject[World.inst.kingdomHeadInfo.Length];
		for (int i = 0; i < heads.Length; i++)
		{
			heads[i] = UnityEngine.Object.Instantiate(World.inst.kingdomHeadInfo[i].headPrefabs);
			heads[i].transform.SetParent(rulerPortrait.transform);
			switch (i)
			{
			case 0:
				heads[i].transform.localPosition = new Vector3(0f, -21.91f, -109f);
				break;
			case 1:
				heads[i].transform.localPosition = new Vector3(0f, -92.8f, -109f);
				break;
			default:
				heads[i].transform.localPosition = new Vector3(0f, -50.24f, -109f);
				break;
			}
			heads[i].transform.localRotation = Quaternion.Euler(0f, 180f, 0f);
			heads[i].SetActive(value: false);
		}
		negotiationUI.Init();
		negotiationUI.SetVisible(visible: false);
		feastMenu.gameObject.SetActive(value: false);
		eatUI.gameObject.SetActive(value: false);
		inited = true;
	}

	private bool Contains(string key, string[] list)
	{
		for (int i = 0; i < list.Length; i++)
		{
			if (list[i] == key)
			{
				return true;
			}
		}
		return false;
	}

	internal void ChangeMood(string mood)
	{
		LandmassOwner.Mood mood2 = LandmassOwner.Mood.Neutral;
		if (Contains(mood, veryBadMoods))
		{
			mood2 = LandmassOwner.Mood.VeryBad;
			GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, -10);
		}
		else if (Contains(mood, badMoods))
		{
			mood2 = LandmassOwner.Mood.Bad;
			GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, -5);
		}
		else if (Contains(mood, neutralMoods))
		{
			mood2 = LandmassOwner.Mood.Neutral;
		}
		else if (Contains(mood, goodMoods))
		{
			mood2 = LandmassOwner.Mood.Good;
			GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, 5);
		}
		else if (Contains(mood, veryGoodMoods))
		{
			mood2 = LandmassOwner.Mood.VeryGood;
			GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, 10);
		}
		else
		{
			Debug.LogError("missing mood association");
		}
		GetAILMO().mood = mood2;
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
		if (doInquire)
		{
			StartMissionConvo();
			doInquire = false;
		}
		else
		{
			if (kingdom.currMission == null || !(lastConversationStarted == kingdom.currMission.convo) || (kingdom.currMission.status != Mission.Status.Failed && kingdom.currMission.status != Mission.Status.Complete))
			{
				return;
			}
			if (kingdom.currMission.status == Mission.Status.Failed)
			{
				float num = -50f;
				if (landmassOwner.mood == LandmassOwner.Mood.VeryBad)
				{
					num *= 2f;
				}
				else if (landmassOwner.mood == LandmassOwner.Mood.Bad)
				{
					num *= 1.5f;
				}
				if (landmassOwner.mood == LandmassOwner.Mood.Good)
				{
					num *= 0.9f;
				}
				else if (landmassOwner.mood == LandmassOwner.Mood.VeryGood)
				{
					num *= 0.75f;
				}
				GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, (int)num);
			}
			if (kingdom.currMission.status == Mission.Status.Complete)
			{
				float num2 = 60f;
				if (landmassOwner.mood == LandmassOwner.Mood.VeryBad)
				{
					num2 *= 0.5f;
				}
				else if (landmassOwner.mood == LandmassOwner.Mood.Bad)
				{
					num2 *= 0.75f;
				}
				if (landmassOwner.mood == LandmassOwner.Mood.Good)
				{
					num2 *= 1.2f;
				}
				else if (landmassOwner.mood == LandmassOwner.Mood.VeryGood)
				{
					num2 *= 1.5f;
				}
				GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, (int)num2);
			}
			CancelMission();
		}
	}

	internal void DeclareWar()
	{
		World.inst.SetRelations(0, GetAILMO().teamId, World.Relations.Enemy);
	}

	internal void EndWar()
	{
		World.inst.SetRelations(0, GetAILMO().teamId, World.Relations.Neutral);
		for (int i = 0; i < AIBrainsContainer.inst.kingdoms.Count; i++)
		{
			AIKingdom aIKingdom = AIBrainsContainer.inst.kingdoms[i];
			if (World.inst.RelationBetween(0, aIKingdom.LandmassOwner.teamId) == World.Relations.Allies)
			{
				World.inst.SetRelations(GetAILMO().teamId, aIKingdom.LandmassOwner.teamId, World.Relations.Neutral);
			}
		}
	}

	internal void GrantControlToPlayer()
	{
		kingdom.GrantControlTo(Player.inst.PlayerLandmassOwner);
		deferDestroyKingdom = true;
	}

	internal void RebuildKeep()
	{
		kingdom.Layout.ReplaceKeep();
	}

	internal double GetStanding()
	{
		return (double)GetAILMO().GetStandingFor(Player.inst.PlayerLandmassOwner.teamId);
	}

	internal bool AITroopsOnPlayerLand()
	{
		ArrayExt<IMoveableUnit> arrayExt = OrdersManager.inst.unitsByTeamID[kingdom.LandmassOwner.teamId];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			int landMassIdx = World.inst.GetCellDataClamped(arrayExt.data[i].GetPos()).landMassIdx;
			if (Player.inst.LandMassIsAPlayerLandMass(landMassIdx))
			{
				return true;
			}
		}
		return false;
	}

	internal bool PlayerTroopsOnAILand()
	{
		return OrdersManager.inst.TroopsOnLandmass(0, kingdom.Layout.LandMass) > 0;
	}

	internal bool IsAIBuildingUpTroops()
	{
		return kingdom.GetInvasionIntentionForTeamID(0).currWave == null;
	}

	internal int GetPlayerHappiness()
	{
		return Player.inst.GetLandmassHappiness(Player.inst.keep.LandMass()).currHappiness;
	}

	internal bool IsAIWinning()
	{
		if (kingdom.rulerPersonality == AIKingdom.RulerPersonality.Anxious)
		{
			return kingdom.GetInvasionIntentionForTeamID(0).successfulWaves > 0;
		}
		if (kingdom.rulerPersonality == AIKingdom.RulerPersonality.Playful)
		{
			return kingdom.GetInvasionIntentionForTeamID(0).successfulWaves > 1;
		}
		return kingdom.GetInvasionIntentionForTeamID(0).successfulWaves > 2;
	}

	public bool FoughtOffLastWave()
	{
		return kingdom.GetInvasionIntentionForTeamID(0).successfulWaves == 0;
	}

	internal string GetPersonality()
	{
		return kingdom.rulerPersonality.ToString();
	}

	private void Awake()
	{
		missionRoot.SetActive(value: false);
		inquireButton.onClick.AddListener(Test);
	}

	public static string GetStringForStanding(LandmassOwner.Standing s)
	{
		return s switch
		{
			LandmassOwner.Standing.VeryUnfavorable => "ScriptLocalization.OpinionVeryUnfavorable", 
			LandmassOwner.Standing.Unfavorable => "ScriptLocalization.OpinionUnfavorable", 
			LandmassOwner.Standing.Neutral => "ScriptLocalization.OpinionNeutral", 
			LandmassOwner.Standing.Favorable => "ScriptLocalization.OpinionFavorable", 
			LandmassOwner.Standing.VeryFavorable => "ScriptLocalization.OpinionVeryFavorable", 
			_ => "", 
		};
	}

	public void CancelMission()
	{
		kingdom.ClearMission();
		RefreshMissionUI();
	}

	private void RefreshMissionUI()
	{
		if (kingdom.currMission != null)
		{
			missionInfoToggle.gameObject.SetActive(value: true);
			missionDescTxt.text = kingdom.currMission.GetDescription();
			missionConditionTxt.text = kingdom.currMission.GetCondition();
		}
		else
		{
			missionInfoToggle.gameObject.SetActive(value: false);
			missionRoot.gameObject.SetActive(value: false);
		}
	}

	public void ToggleMissionUI()
	{
		SetMissionUIVisibility(!missionRoot.gameObject.activeSelf);
	}

	public void ToggleResourceInfoUI()
	{
		SetResourceInfoUIVisibility(!resourceCostRoot.gameObject.activeSelf);
	}

	public void SetMissionUIVisibility(bool v)
	{
		SfxSystem.PlayUiSelect();
		resourceCostRoot.gameObject.SetActive(value: false);
		missionRoot.gameObject.SetActive(v);
	}

	internal bool DoAIDocksExist()
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnLandMass(World.dockName, kingdom.Layout.LandMass, mustBeBuilt: true);
	}

	internal bool DoPlayerDocksExist()
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.dockName, mustBeBuilt: false);
	}

	internal bool DoPlayerHallOfDiplomacyExist()
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.hallOfDiplomacyName, mustBeBuilt: false);
	}

	public void SetResourceInfoUIVisibility(bool v)
	{
		SfxSystem.PlayUiSelect();
		missionRoot.gameObject.SetActive(value: false);
		resourceCostRoot.gameObject.SetActive(v);
	}

	private void Update()
	{
		for (int i = 0; i < heads.Length; i++)
		{
			switch (i)
			{
			case 0:
				heads[i].transform.localScale = (GameUI.IsOnConsole() ? new Vector3(47f, 47f, 47f) : new Vector3(65f, 65f, 65f));
				break;
			case 1:
				heads[i].transform.localScale = (GameUI.IsOnConsole() ? new Vector3(55f, 55f, 55f) : new Vector3(70f, 70f, 70f));
				break;
			default:
				heads[i].transform.localScale = (GameUI.IsOnConsole() ? new Vector3(55f, 55f, 55f) : new Vector3(70f, 70f, 70f));
				break;
			}
		}
		if (currMeal != null && currMeal.IsDone())
		{
			currMeal = null;
			suppressContinueButton = false;
			convoContinueButton.GetComponent<StandardUIContinueButtonFastForward>().OnFastForward();
			eatUI.SetActive(value: false);
		}
		if (negotiationUI.gameObject.activeSelf)
		{
			int num = negotiationUI.CalculateFavor();
			if (lastFavor != num)
			{
				lastFavor = num;
				if (num <= -60)
				{
					Skeptical();
				}
				else if (num > -60 && num < 0)
				{
					NeutralGrumpy();
				}
				else if (num >= 0 && num < 20)
				{
					Neutral();
				}
				else if (num >= 20 && num < 60)
				{
					NeutralHappy();
				}
				else
				{
					Delight();
				}
			}
		}
		if (suppressContinueButton)
		{
			convoContinueButton.SetActive(value: false);
		}
		showRulerPortraitTime += Time.unscaledDeltaTime * 2f * (float)(showRulerPortrait ? 1 : (-1));
		showRulerPortraitTime = Mathff.Clamp01(showRulerPortraitTime);
		portraitLight.intensity = Mathf.SmoothStep(0f, 1f, showRulerPortraitTime) * 0.6f;
		if (busyContainer.gameObject.activeSelf)
		{
			busyBar.value = 1f - Mathf.Clamp01(kingdom.audienceTimer / SeasonManager.inst.TimeInYear());
		}
		if (gameObject.activeSelf)
		{
			if (GetAILMO().GetStandingFor(Player.inst.PlayerLandmassOwner.teamId) < currStanding)
			{
				currProgress = Mathff.Lerp(currProgress, GetAILMO().GetPointsStandingFor(Player.inst.PlayerLandmassOwner.teamId) / 100 - 1, Time.unscaledDeltaTime * sliderAdjustSpeed);
				if (currProgress <= 0.05f)
				{
					currStanding = GetAILMO().GetStandingFor(Player.inst.PlayerLandmassOwner.teamId);
					currProgress = 1f;
					standingTxt.text = GetStringForStanding(currStanding);
				}
			}
			else if (GetAILMO().GetStandingFor(Player.inst.PlayerLandmassOwner.teamId) > currStanding)
			{
				currProgress = Mathff.Lerp(currProgress, GetAILMO().GetPointsStandingFor(Player.inst.PlayerLandmassOwner.teamId) / 100 + 1, Time.unscaledDeltaTime * sliderAdjustSpeed);
				if (currProgress >= 0.95f)
				{
					confettiEffect.Play();
					currStanding = GetAILMO().GetStandingFor(Player.inst.PlayerLandmassOwner.teamId);
					currProgress = 0f;
					standingTxt.text = GetStringForStanding(currStanding);
				}
			}
			else
			{
				currProgress = Mathff.Lerp(currProgress, (float)GetAILMO().GetPointsStandingFor(Player.inst.PlayerLandmassOwner.teamId) / 100f, Time.unscaledDeltaTime * sliderAdjustSpeed);
				standingTxt.text = GetStringForStanding(GetAILMO().GetStandingFor(Player.inst.PlayerLandmassOwner.teamId));
			}
			statusProgress.value = currProgress;
			sliderBackground.color = favorColors[(int)currStanding % favorColors.Length];
			sliderFill.color = favorColors[(int)(currStanding + 1) % favorColors.Length];
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
				if (prevFrameConversationActive || !requestBtn.activeSelf)
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
	}

	internal void PayDemandGold()
	{
		int num = GetGoldDemandAmount();
		if (num > Player.inst.PlayerLandmassOwner.Gold)
		{
			num = Player.inst.PlayerLandmassOwner.Gold;
		}
		Player.inst.PlayerLandmassOwner.Gold -= num;
		GetAILMO().Gold += num;
	}

	internal int GetDenyPeaceAmount()
	{
		return kingdom.manageDiplomacyIntention.denyPeace;
	}

	internal void DenyPeace()
	{
		kingdom.manageDiplomacyIntention.denyPeace++;
	}

	internal bool IsPlayerAtPeace()
	{
		bool result = true;
		for (int i = 0; i < 5; i++)
		{
			if (i != 1 && i != 0 && World.inst.RelationBetween(0, i) == World.Relations.Enemy)
			{
				result = false;
			}
		}
		return result;
	}

	internal string NeedResource()
	{
		if (kingdom.AtLowResourcesExtended(2))
		{
			return "stone";
		}
		if (kingdom.AtLowResourcesExtended(1))
		{
			return "wood";
		}
		if (kingdom.AtLowResourcesExtended(5))
		{
			return "iron";
		}
		if (kingdom.AtLowResourcesExtended(7))
		{
			return "armaments";
		}
		if (kingdom.AtLowResourcesExtended(6))
		{
			return "tools";
		}
		if (kingdom.AtLowResourcesExtended(9))
		{
			return "apples";
		}
		if (kingdom.AtLowResourcesExtended(0))
		{
			return "wheat";
		}
		if (kingdom.AtLowResourcesExtended(8))
		{
			return "fish";
		}
		return "none";
	}

	internal bool ShouldSurrender()
	{
		if (kingdom.rulerPersonality == AIKingdom.RulerPersonality.Aggressive)
		{
			if (kingdom.damagePoints > 100 || kingdom.GetHappinessRollingAvg() < 40)
			{
				return true;
			}
		}
		else if (kingdom.rulerPersonality == AIKingdom.RulerPersonality.Playful)
		{
			if (kingdom.damagePoints > 80 || kingdom.GetHappinessRollingAvg() < 50)
			{
				return true;
			}
		}
		else if (kingdom.rulerPersonality == AIKingdom.RulerPersonality.Anxious && (kingdom.damagePoints > 50 || kingdom.GetHappinessRollingAvg() < 50))
		{
			return true;
		}
		return false;
	}

	internal void DoEnemyWarning()
	{
		kingdom.didEnemyWarning = true;
		kingdom.enemyPoints = kingdom.GetEnemyPointsForWarning();
	}

	internal bool DidEnemyWarning()
	{
		return kingdom.didEnemyWarning;
	}

	internal bool PlayerHasEnemies()
	{
		for (int i = 0; i < AIBrainsContainer.inst.kingdoms.Count; i++)
		{
			AIKingdom aIKingdom = AIBrainsContainer.inst.kingdoms[i];
			if (World.inst.RelationBetween(aIKingdom.LandmassOwner.teamId, 0) == World.Relations.Enemy)
			{
				return true;
			}
		}
		return false;
	}

	internal int RemoveTroopCount()
	{
		return kingdom.manageDiplomacyIntention.removeTroopCount;
	}

	internal void DoEventTavern()
	{
		if (SRand.Range(0, 100) > 50)
		{
			Player.inst.AddHappinessMod("eventtavern", 90f, -20, "ScriptLocalization.TavernEventNegative", Player.inst.keep.LandMass());
		}
		else
		{
			Player.inst.AddHappinessMod("eventtavern", 90f, 10, "ScriptLocalization.TavernEventPositive", Player.inst.keep.LandMass());
		}
	}

	internal void DestroyAllBuildingsForPlayer(string name)
	{
		ArrayExt<Building> buildingListForLandMassOwner = Player.inst.GetBuildingListForLandMassOwner(Player.inst.PlayerLandmassOwner, name.GetHashCode());
		for (int i = 0; i < buildingListForLandMassOwner.Count; i++)
		{
			World.inst.DemolishBuilding(buildingListForLandMassOwner.data[i]);
		}
	}

	public void DoEventSickDiplomat(int outcome)
	{
		if (outcome == 0 || outcome == 1)
		{
			Vector3 position = foreignEnvoy.transform.position;
			if (foreignEnvoy.general.army.units.Count > 0)
			{
				position = foreignEnvoy.general.army.units.Last().pos;
				ArmySystem.inst.ReleaseUnit(foreignEnvoy.general.army.units.Last());
			}
			Player.inst.AddVillager(position);
		}
		if (outcome == 1)
		{
			SRand.Range(0, 100);
			_ = 70;
		}
	}

	public void DoEventJoustingMatch(int outcome)
	{
	}

	internal bool PlayerHasNoMerchants()
	{
		for (int i = 0; i < ShipSystem.inst.ships.Count; i++)
		{
			ShipBase shipBase = ShipSystem.inst.ships.data[i];
			if (shipBase.type == ShipBase.ShipType.PlayerMerchant && shipBase.teamID == 0)
			{
				return false;
			}
		}
		return true;
	}

	public void PrepForGamepad()
	{
		if (negotiationUI.gameObject.activeSelf)
		{
			consoleNegotiation.Hover();
		}
		else if (feastMenu.activeSelf)
		{
			consoleFeast.Hover();
		}
	}

	private bool IsConsoleFocused()
	{
		if (GamepadControl.inst.nextSelected != null && GamepadControl.inst.CurrentSelected != null && GamepadControl.inst.CurrentSelected != gameObject)
		{
			return GamepadControl.inst.CurrentSelected.activeInHierarchy;
		}
		return false;
	}

	public void ResetConsoleFocus()
	{
		if (IsConsoleFocused())
		{
			GamepadControl.inst.CurrentSelected.GetComponent<ConsoleUIItem>().Dehover();
		}
		GamepadControl.inst.nextSelected = gameObject;
	}

	public void OnControllerUpdate(bool isControllerActive)
	{
		consoleYIcon.SetActive(isControllerActive);
		consoleXIcon.SetActive(isControllerActive);
	}

	public void ConsoleUIXInput()
	{
		if (resourceInfoToggle.gameObject.activeInHierarchy)
		{
			resourceInfoToggle.onClick.Invoke();
		}
	}

	public void ConsoleUIYInput()
	{
		if (missionInfoToggle.gameObject.activeInHierarchy)
		{
			missionInfoToggle.onClick.Invoke();
		}
	}

	internal void ShowPortrait()
	{
		showRulerPortrait = true;
	}

	internal bool PlayerHasGreatHall()
	{
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(Player.inst.keep.LandMass(), World.greatHallHash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			if (buildingListForLandMass.data[i].IsBuilt())
			{
				return true;
			}
		}
		return false;
	}

	internal void PayFeast(string feast)
	{
	}

	private void SetUpFeastButton(int i, string f)
	{
		feastMenu.transform.GetChild(i).GetChild(0).GetComponent<Button>()
			.interactable = CanAffordFeast(f);
		feastMenu.transform.GetChild(i).GetChild(0).GetChild(0)
			.GetComponent<TextMeshProUGUI>()
			.text = GetFeastCost(f).ToString();
	}

	internal int IdleWorkerCountAI()
	{
		return World.inst.AvailableWorkersOnLandMass(kingdom.Layout.LandMass);
	}

	internal void SetImmigrateObjective()
	{
		kingdom.manageDiplomacyIntention.SetNextObjective(AIObjectiveType.ImmigrateDiplomat);
	}

	internal void ShowFoodMenu()
	{
		suppressContinueButton = true;
		feastMenu.gameObject.SetActive(value: true);
		SetUpFeastButton(0, "bread");
		SetUpFeastButton(1, "apples");
		SetUpFeastButton(2, "fish");
		SetUpFeastButton(3, "pork");
		if (GamepadControl.inst.isControllerActive)
		{
			ResetConsoleFocus();
			consoleFeast.Hover();
		}
	}

	public void SetFeastType(string ftype)
	{
		suppressContinueButton = false;
		feastType = ftype;
		feastMenu.gameObject.SetActive(value: false);
		convoContinueButton.GetComponent<StandardUIContinueButtonFastForward>().OnFastForward();
		convoContinueButton.GetComponent<StandardUIContinueButtonFastForward>().OnFastForward();
	}

	private void StartSequence(EatMeal meal, int foodType)
	{
		if (kingdom.FavoriteFood == foodType)
		{
			meal.Eat(EatMeal.EatType.Full);
		}
		else if (kingdom.LeastFavoriteFood == foodType)
		{
			meal.Eat(EatMeal.EatType.None);
		}
		else
		{
			meal.Eat(EatMeal.EatType.Half);
		}
		currMeal = meal;
	}

	public void DoFoodAnim()
	{
		suppressContinueButton = true;
		eatUI.gameObject.SetActive(value: true);
		eatBread.gameObject.SetActive(feastType == "bread");
		eatApples.gameObject.SetActive(feastType == "apples");
		eatPork.gameObject.SetActive(feastType == "pork");
		eatFish.gameObject.SetActive(feastType == "fish");
		if (feastType == "bread")
		{
			StartSequence(eatBread, 0);
		}
		if (feastType == "apples")
		{
			StartSequence(eatApples, 9);
		}
		if (feastType == "pork")
		{
			StartSequence(eatPork, 10);
		}
		if (feastType == "fish")
		{
			StartSequence(eatFish, 8);
		}
	}

	public bool IsFeast(string ftype)
	{
		return feastType == ftype;
	}

	private ResourceAmount GetFeastCost(string feast)
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		switch (feast)
		{
		case "bread":
			resourceAmount.Set(0, 50);
			break;
		case "apples":
			resourceAmount.Set(9, 50);
			break;
		case "fish":
			resourceAmount.Set(8, 50);
			break;
		case "pork":
			resourceAmount.Set(10, 50);
			break;
		}
		return resourceAmount;
	}

	internal bool CanAffordFeast(string feast)
	{
		ResourceAmount feastCost = GetFeastCost(feast);
		ResourceAmount resourceAmount = Player.inst.resourcesPerLandmass[Player.inst.keep.LandMass()];
		if (resourceAmount.Get(0) >= feastCost.Get(0) && resourceAmount.Get(9) >= feastCost.Get(9) && resourceAmount.Get(8) >= feastCost.Get(8) && resourceAmount.Get(10) >= feastCost.Get(10))
		{
			return true;
		}
		return false;
	}

	internal bool IsLeastFavoriteFood(string food)
	{
		if (food == "bread" && kingdom.LeastFavoriteFood == 0)
		{
			return true;
		}
		if (food == "apples" && kingdom.LeastFavoriteFood == 9)
		{
			return true;
		}
		if (food == "pork" && kingdom.LeastFavoriteFood == 10)
		{
			return true;
		}
		if (food == "fish" && kingdom.LeastFavoriteFood == 8)
		{
			return true;
		}
		return false;
	}

	internal bool HasMoreArcherTowersThanPlayer()
	{
		ArrayExt<Building> buildingListForLandMassOwner = Player.inst.GetBuildingListForLandMassOwner(Player.inst.PlayerLandmassOwner, World.archerTowerHash);
		if (Player.inst.GetBuildingListForLandMassOwner(kingdom.LandmassOwner, World.archerTowerHash).Count >= buildingListForLandMassOwner.Count + 5 && buildingListForLandMassOwner.Count < 5)
		{
			return true;
		}
		return false;
	}

	private void ResetAdditiveAnims()
	{
		if ((bool)animator)
		{
			animator.SetFloat("breatheSpeed", 1f);
			animator.SetFloat("noiseSpeed", 1f);
		}
	}

	public void Neutral()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("neutral", neutralFadeTime);
			ResetAdditiveAnims();
		}
	}

	public void NeutralGrumpy()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("neutral_grumpy", neutralGrumpyFadeTime);
			ResetAdditiveAnims();
		}
	}

	public void NeutralHappy()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("neutral_happy", neutralHappyFadeTime);
			ResetAdditiveAnims();
		}
	}

	public void NeutralAngry()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("neutral_angry", 1.5f);
			ResetAdditiveAnims();
		}
	}

	public void LookAtSide()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("lookatside", lookAtSideFadeTime);
			ResetAdditiveAnims();
			animTime = 2f;
			nextAnim = Neutral;
		}
	}

	public void Intrigued()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("intrigued", crossFadeTime);
			animator.SetFloat("breatheSpeed", 1.5f);
			animator.SetFloat("noiseSpeed", 1f);
			animTime = 2f;
			nextAnim = Neutral;
			PlayEmote("Intrigued", kingdom.headIdx);
		}
	}

	public void Interested()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("interested", crossFadeTime);
			animator.SetFloat("breatheSpeed", 2.5f);
			animator.SetFloat("noiseSpeed", 1.75f);
			animTime = 2f;
			nextAnim = Neutral;
			PlayEmote("Intrigued", kingdom.headIdx);
		}
	}

	public void OhWell()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("ohwell", crossFadeTime);
			animator.SetFloat("breatheSpeed", 1.75f);
			animator.SetFloat("noiseSpeed", 1.75f);
			animTime = 2f;
			nextAnim = Neutral;
			PlayEmote("Sad", kingdom.headIdx);
			ohwellParticle.Play(withChildren: true);
		}
	}

	public void Surprise()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("surprise", crossFadeTime);
			animator.SetFloat("breatheSpeed", 2f);
			animator.SetFloat("noiseSpeed", 2f);
			animTime = 2f;
			PlayEmote("Surprised", kingdom.headIdx);
			surpriseParticle.Play(withChildren: true);
		}
	}

	public void Upset()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("upset", crossFadeTime);
			animator.SetFloat("breatheSpeed", 2f);
			animator.SetFloat("noiseSpeed", 2f);
			animTime = 2f;
			nextAnim = NeutralGrumpy;
			PlayEmote("Sad", kingdom.headIdx);
			upsetParticle.Play(withChildren: true);
		}
	}

	public void Sad()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("upset", crossFadeTime);
			animator.SetFloat("breatheSpeed", 2f);
			animator.SetFloat("noiseSpeed", 1f);
			animTime = 2f;
			PlayEmote("Sad", kingdom.headIdx);
			sadParticle.Play(withChildren: true);
		}
	}

	public void Mischief()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("mischief", crossFadeTime);
			animator.SetFloat("breatheSpeed", 1f);
			animator.SetFloat("noiseSpeed", 1f);
			animTime = 2f;
			PlayEmote("Mischief", kingdom.headIdx);
			mischiefParticle.Play(withChildren: true);
		}
	}

	public void Delight()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("delight", crossFadeTime);
			animator.SetFloat("breatheSpeed", 2f);
			animator.SetFloat("noiseSpeed", 1f);
			nextAnim = NeutralHappy;
			animTime = 2f;
			PlayEmote("Happy", kingdom.headIdx);
			delightParticle.Play(withChildren: true);
		}
	}

	public void Happy()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("happy", crossFadeTime);
			animator.SetFloat("breatheSpeed", 1f);
			animator.SetFloat("noiseSpeed", 1f);
			nextAnim = NeutralHappy;
			animTime = 2f;
			PlayEmote("Happy", kingdom.headIdx);
			happyParticle.Play(withChildren: true);
		}
	}

	public void Angry()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("angry", crossFadeTime);
			animator.SetFloat("breatheSpeed", 3f);
			animator.SetFloat("noiseSpeed", 3f);
			nextAnim = NeutralAngry;
			animTime = 2f;
			PlayEmote("Angry", kingdom.headIdx);
			angryParticle.Play(withChildren: true);
		}
	}

	public void Skeptical()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("skeptical", crossFadeTime);
			animator.SetFloat("breatheSpeed", 1f);
			animator.SetFloat("noiseSpeed", 2f);
			nextAnim = NeutralAngry;
			animTime = 2f;
			PlayEmote("Skeptical", kingdom.headIdx);
		}
	}

	public void Scared()
	{
		if ((bool)animator)
		{
			animator.CrossFadeInFixedTime("scared", crossFadeTime);
			animator.SetFloat("breatheSpeed", 3f);
			animator.SetFloat("noiseSpeed", 2f);
			nextAnim = NeutralGrumpy;
			animTime = 2f;
			PlayEmote("Skeptical", kingdom.headIdx);
			scaredParticle.Play(withChildren: true);
		}
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

	internal bool IsMissionNotStarted()
	{
		return kingdom.currMission.status == Mission.Status.NotStarted;
	}

	internal bool IsMissionInProgress()
	{
		return kingdom.currMission.status == Mission.Status.InProgress;
	}

	internal bool IsMissionComplete()
	{
		return kingdom.currMission.status == Mission.Status.Complete;
	}

	internal bool IsFavoriteFood(string s)
	{
		if (s == "bread" && kingdom.FavoriteFood == 0)
		{
			return true;
		}
		if (s == "fish" && kingdom.FavoriteFood == 8)
		{
			return true;
		}
		if (s == "pork" && kingdom.FavoriteFood == 10)
		{
			return true;
		}
		if (s == "apples" && kingdom.FavoriteFood == 9)
		{
			return true;
		}
		return false;
	}

	internal bool IsMissionFailed()
	{
		return kingdom.currMission.status == Mission.Status.Failed;
	}

	internal void AcceptMission()
	{
		kingdom.currMission.status = Mission.Status.InProgress;
		GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, 10);
	}

	public void HideMissionUI()
	{
		missionRoot.gameObject.SetActive(value: false);
	}

	public void DeferDisbandEnvoy()
	{
		deferDisbandEnvoy = true;
	}

	public void Hide()
	{
		if (!gameObject.activeSelf)
		{
			return;
		}
		DialogueManager.StopConversation();
		landmassOwner = null;
		if (gameObject.activeSelf)
		{
			gameObject.SetActive(value: false);
			if (oldSpeed != -1)
			{
				TimeManager.inst.SetSpeed(oldSpeed, skipSfx: true);
			}
		}
		missionRoot.gameObject.SetActive(value: false);
		resourceCostRoot.gameObject.SetActive(value: false);
		if (deferDestroyKingdom)
		{
			kingdom.ShutdownKingdom();
			UnityEngine.Object.Destroy(kingdom.gameObject);
			deferDestroyKingdom = false;
		}
		if (deferDisbandEnvoy)
		{
			foreignEnvoy.GetComponent<General>().Disband();
			foreignEnvoy = null;
			deferDisbandEnvoy = false;
		}
		confettiEffect.Stop();
		confettiEffect.Clear();
		if (GameUI.inst.selectedObjs.Count > 0)
		{
			for (int i = 0; i < GameUI.inst.selectedObjs.Count; i++)
			{
				ISelectable selectable = GameUI.inst.selectedObjs[i];
				if (selectable is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy, teamId: 0 })
				{
					GameUI.inst.RemoveFromSelection(selectable);
					GameUI.inst.TrySelect(selectable);
				}
			}
		}
		GameState.inst.AlphaNumericHotkeysEnabled = true;
		portraitLight.intensity = 0f;
		showRulerPortraitTime = 0f;
		GamepadControl.inst.nextSelected = null;
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(inst.controllerUpdate, new GamepadControl.ControllerActivity(OnControllerUpdate));
		GamepadControl.inst.UIXInput -= ConsoleUIXInput;
		GamepadControl.inst.UIYInput -= ConsoleUIYInput;
	}

	private void UpdateDockStatus()
	{
		bool active = Player.inst.DocksOpen(GetAILMO(), Player.inst.PlayerLandmassOwner);
		resourceInfoToggle.gameObject.SetActive(active);
	}

	internal void MakeAlliance()
	{
		World.inst.SetRelations(GetAILMO().teamId, 0, World.Relations.Allies);
	}

	internal bool HasAlliance()
	{
		return World.inst.RelationBetween(GetAILMO().teamId, 0) == World.Relations.Allies;
	}

	internal void BreakAlliance()
	{
		World.inst.SetRelations(GetAILMO().teamId, 0, World.Relations.Neutral);
	}

	internal void DeclareWarOnPlayerEnemies()
	{
		string value = "";
		for (int i = 0; i < AIBrainsContainer.inst.kingdoms.Count; i++)
		{
			AIKingdom aIKingdom = AIBrainsContainer.inst.kingdoms[i];
			if (!(aIKingdom == kingdom) && World.inst.RelationBetween(aIKingdom.LandmassOwner.teamId, 0) == World.Relations.Enemy)
			{
				World.inst.SetRelations(kingdom.LandmassOwner.teamId, aIKingdom.LandmassOwner.teamId, World.Relations.Enemy);
				value = Player.inst.LandMassNames[aIKingdom.Layout.LandMass];
			}
		}
		DialogueLua.SetVariable("Var1", value);
	}

	public void Show(Envoy envoy, LandmassOwner lmo, int landmassIdx, AIKingdom k)
	{
		currMeal = null;
		suppressContinueButton = false;
		TryInit();
		entries.Clear();
		Cam.inst.ClearTrack();
		GameUI.inst.ClearUIForClick();
		prevConvo = null;
		returnNode = -1;
		didRulerMessage = false;
		foreignEnvoy = envoy;
		oldSpeed = TimeManager.inst.speedInUse;
		TimeManager.inst.SetPaused(skipSfx: true);
		kingdom = k;
		landmassOwner = lmo;
		gameObject.SetActive(value: true);
		prevFrameConversationActive = false;
		GamepadControl.inst.nextSelected = gameObject;
		if (GamepadControl.inst.isControllerActive)
		{
			ConsoleTileUI.inst.SetVisible(v: false);
		}
		UpdateDockStatus();
		RefreshMissionUI();
		nameTxt.text = kingdom.GetLocalizedName();
		convoCompleted.Clear();
		didChat = false;
		envoyPortrait.SetActive(value: false);
		speakOnBehalf.SetActive(value: false);
		portraitLight.intensity = 0f;
		showRulerPortraitTime = 0f;
		showRulerPortrait = true;
		busyContainer.SetActive(kingdom.audienceTimer > 0f);
		requestBtn.SetActive(!busyContainer.activeSelf);
		for (int i = 0; i < heads.Length; i++)
		{
			if (i == kingdom.headIdx)
			{
				heads[i].SetActive(value: true);
				SetHeadMaterials(kingdom, heads[i]);
				animator = heads[i].GetComponent<Animator>();
			}
			else
			{
				heads[i].SetActive(value: false);
			}
		}
		if (foreignEnvoy != null)
		{
			resourceCostUI.UpdateUI(GetAILMO().GetPayCosts(0));
		}
		else
		{
			missionInfoToggle.gameObject.SetActive(value: false);
			resourceInfoToggle.gameObject.SetActive(value: false);
		}
		currProgress = (float)GetAILMO().GetPointsStandingFor(Player.inst.PlayerLandmassOwner.teamId) / 100f;
		currStanding = GetAILMO().GetStandingFor(Player.inst.PlayerLandmassOwner.teamId);
		resourceCostRoot.gameObject.SetActive(value: false);
		missionRoot.gameObject.SetActive(value: false);
		GameState.inst.AlphaNumericHotkeysEnabled = false;
		OnControllerUpdate(GamepadControl.inst.isControllerActive);
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(inst.controllerUpdate, new GamepadControl.ControllerActivity(OnControllerUpdate));
		GamepadControl.inst.UIXInput += ConsoleUIXInput;
		GamepadControl.inst.UIYInput += ConsoleUIYInput;
	}

	public static void SetHeadMaterials(AIKingdom kingdom, GameObject headContainer)
	{
		headContainer.GetComponentsInChildren(includeInactive: true, headRenderers);
		for (int i = 0; i < headRenderers.Count; i++)
		{
			Material material = World.inst.liverySets[kingdom.LandmassOwner.bannerIdx].headMaterials[kingdom.headIdx];
			if (material != null)
			{
				if (kingdom.headIdx == 2 && headRenderers[i].name.Contains("Mouth"))
				{
					headRenderers[i].material = World.inst.liverySets[kingdom.LandmassOwner.bannerIdx].headMaterials[0];
				}
				else
				{
					headRenderers[i].material = material;
				}
			}
		}
	}

	internal bool CanLowerPrices()
	{
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(foreignEnvoy.TeamID());
		if (landmassOwner.GetStandingFor(landmassOwnerByTeamId.teamId) >= LandmassOwner.Standing.Favorable)
		{
			return true;
		}
		return false;
	}

	internal void DisplayNegotiationUI()
	{
		negotiationUI.SetVisible(visible: true);
		negotiationUI.PopulateUI(kingdom.LandmassOwner, 0);
		suppressContinueButton = true;
		lastFavor = -1;
		if (GamepadControl.inst.isControllerActive)
		{
			ResetConsoleFocus();
			consoleNegotiation.Hover();
		}
	}

	internal bool WasPreviousNegotationsFavorable()
	{
		return kingdom.LandmassOwner.GetTradeFavor(0) >= 0;
	}

	internal bool IsNegotationsFavorable()
	{
		return negotiationUI.CalculateFavor() >= 0;
	}

	internal void UpdateAISellPriceUI()
	{
		resourceCostUI.UpdateUI(Player.inst.PlayerLandmassOwner.GetPayCosts(kingdom.LandmassOwner.teamId));
	}

	public void ProposePrices()
	{
		negotiationUI.SetVisible(visible: false);
		suppressContinueButton = false;
		convoContinueButton.GetComponent<StandardUIContinueButtonFastForward>().OnFastForward();
		convoContinueButton.GetComponent<StandardUIContinueButtonFastForward>().OnFastForward();
	}

	public void ConfirmProposedPrices()
	{
		ApplyFavor(kingdom.LandmassOwner, 0);
		kingdom.LandmassOwner.SetPayCosts(0, negotiationUI.GatherValues());
	}

	internal void LowerPrices()
	{
		kingdom.GetTradeIntentionOfForeignTeamID(0).LowerPriceMod();
	}

	internal void ApplyFavor(LandmassOwner lmo, int teamId)
	{
		int num = negotiationUI.CalculateFavor();
		if (!kingdom.LandmassOwner.tradeFavor.ContainsKey(teamId))
		{
			kingdom.LandmassOwner.tradeFavor.Add(teamId, num);
			return;
		}
		kingdom.LandmassOwner.ModifyStandingFor(teamId, num - kingdom.LandmassOwner.tradeFavor[teamId]);
		kingdom.LandmassOwner.tradeFavor[teamId] = num;
	}

	public void StartDefeatConvo()
	{
		DialogueManager.StartConversation("AIDefeat", null, null, -1);
	}

	internal void KickOut()
	{
		busyContainer.gameObject.SetActive(value: true);
		requestBtn.gameObject.SetActive(value: false);
		ChangeMood("Annoyed");
	}

	public void DeclineAbdicate()
	{
		kingdom.didAbdicate = true;
		kingdom.diplomacyPoints /= 4;
	}

	public void Abdicate()
	{
		int landMassIdx = World.inst.GetCellDataClamped(kingdom.Layout.KingdomStart).landMassIdx;
		Cam.inst.SetDesiredTrackingPos(kingdom.Layout.KingdomStart);
		Player.inst.AddHappinessMod("abdicatebonus", SeasonManager.inst.TimeInYear() * 10f, 10, "ScriptLocalization.HappinessUIAbdicateBonus", landMassIdx);
		kingdom.GrantControlTo(Player.inst.PlayerLandmassOwner);
		deferDestroyKingdom = true;
	}

	public int GetHappinessRollingAvg()
	{
		return kingdom.GetHappinessRollingAvg();
	}

	private LandmassOwner GetAILMO()
	{
		return kingdom.LandmassOwner;
	}

	public void AttemptOpenDocks()
	{
		bool flag = false;
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(foreignEnvoy.GetComponent<General>().army.teamId);
		if (landmassOwner == Player.inst.PlayerLandmassOwner)
		{
			flag = true;
		}
		else if (landmassOwner.trait == LandmassOwner.Trait.Friendly)
		{
			flag = landmassOwner.GetStandingFor(landmassOwnerByTeamId.teamId) >= LandmassOwner.Standing.Neutral;
		}
		else if (landmassOwner.trait == LandmassOwner.Trait.Suspicious)
		{
			flag = landmassOwner.GetStandingFor(landmassOwnerByTeamId.teamId) >= LandmassOwner.Standing.Favorable;
		}
		if (flag)
		{
			Player.inst.OpenDocks(landmassOwnerByTeamId, landmassOwner);
		}
		UpdateDockStatus();
	}

	public void CloseDocks()
	{
		Player.inst.CloseDocks(Player.inst.PlayerLandmassOwner, GetAILMO());
	}

	public void RefreshMerchantOrders()
	{
		kingdom.GetTradeIntentionOfForeignTeamID(0).RefreshMerchantOrders();
	}

	public bool AreDocksOpen()
	{
		return Player.inst.DocksOpen(Player.inst.PlayerLandmassOwner, GetAILMO());
	}

	public int GetAudienceEndAmount()
	{
		int value = 0;
		convoCompleted.TryGetValue("AudienceEnd", out value);
		return value;
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
		if (nextAnim == null)
		{
			return;
		}
		if (animTime > 0f)
		{
			animTime = 0f;
			return;
		}
		if (nextAnim != null)
		{
			nextAnim();
		}
		else
		{
			Neutral();
		}
		nextAnim = null;
	}

	public bool DidDialogNodeAlready(int id)
	{
		return HasVisitedConvoNode(id, DialogueManager.lastConversationID);
	}

	public void StartEnvoyConvo(AIObjectiveType obj)
	{
		aiObjective = obj;
		envoyPortrait.SetActive(value: true);
		envoyPortrait.GetComponent<Image>().sprite = World.inst.liverySets[kingdom.LandmassOwner.bannerIdx].envoySprite;
		speakOnBehalf.SetActive(value: true);
		showRulerPortrait = false;
		DialogueManager.StartConversation("EnvoyVisit");
	}

	public void HidePortrait()
	{
		showRulerPortrait = false;
	}

	public void ModifyStanding(int amt)
	{
		GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, amt);
	}

	public bool DidRulerMessage()
	{
		return didRulerMessage;
	}

	public bool TryIntroConvo()
	{
		if (!kingdom.doneIntroConvo)
		{
			DialogueManager.StartConversation("Intro", null, null, -1);
			kingdom.doneIntroConvo = true;
			return true;
		}
		return false;
	}

	public bool PlayerNeedsToCallTroopsHome()
	{
		return kingdom.manageDiplomacyIntention.PlayerNeedsToCallTroopsHome();
	}

	private bool ShouldDoCallTroopsHomeOverride()
	{
		if ((aiObjective == AIObjectiveType.Chat || aiObjective == AIObjectiveType.AskForMissionHelp || aiObjective == AIObjectiveType.AskTradeRouteOpen) && PlayerNeedsToCallTroopsHome())
		{
			return true;
		}
		return false;
	}

	public void StartRulerMessage()
	{
		didRulerMessage = true;
		showRulerPortrait = true;
		DialogueManager.StopConversation();
		if (ShouldDoCallTroopsHomeOverride())
		{
			aiObjective = AIObjectiveType.AskForTroopDrawDown;
		}
		switch (aiObjective)
		{
		case AIObjectiveType.Chat:
			if (!TryIntroConvo())
			{
				StartFlavorConvo();
			}
			break;
		case AIObjectiveType.DiscussBadBlood:
			DialogueManager.StartConversation("DiscussBadBlood", null, null);
			break;
		case AIObjectiveType.ImmigrateDiplomat:
			DialogueManager.StartConversation("ImmigrateDiplomat", null, null);
			break;
		case AIObjectiveType.AskTradeRouteOpen:
			DialogueManager.StartConversation("TradeMenuAI", null, null);
			break;
		case AIObjectiveType.AskForTroopDrawDown:
			DialogueManager.StartConversation("RemoveTroops", null, null);
			kingdom.manageDiplomacyIntention.removeTroopCount++;
			break;
		case AIObjectiveType.GiveGift:
			DialogueLua.SetVariable("Var1", foreignEnvoy.giftAmount.ToString());
			DialogueManager.StartConversation("AIGift", null, null);
			break;
		case AIObjectiveType.DiscussSurrender:
			DialogueLua.SetVariable("Var1", GetGoldDemandAmount() + "<sprite name=icon_gold>");
			DialogueManager.StartConversation("EnemyMenuAI", null, null);
			break;
		case AIObjectiveType.DemandGold:
			DialogueLua.SetVariable("Var1", GetGoldDemandAmount() + "<sprite name=icon_gold>");
			DialogueManager.StartConversation("GoldDemand", null, null);
			break;
		case AIObjectiveType.AskForMissionHelp:
			if (!TryIntroConvo())
			{
				StartMissionConvo();
			}
			break;
		case AIObjectiveType.Abdicate:
			DialogueManager.StartConversation("PeacefulAbdication", null, null, -1);
			break;
		}
	}

	public int GetGoldDemandAmount()
	{
		if (World.inst.RelationBetween(kingdom.LandmassOwner.teamId, 0) == World.Relations.Enemy)
		{
			return (int)Mathff.Max((float)Player.inst.PlayerLandmassOwner.Gold * 0.5f, 250f) + SeasonManager.inst.CurrentYear() / 10 + kingdom.manageDiplomacyIntention.denyPeace * 50;
		}
		int num = SeasonManager.inst.CurrentYear();
		if (SeasonManager.inst.CurrentYear() > 50)
		{
			num = SeasonManager.inst.CurrentYear() * 2;
		}
		if (SeasonManager.inst.CurrentYear() > 100)
		{
			num = SeasonManager.inst.CurrentYear() * 3;
		}
		num /= 10;
		return num * 10;
	}

	public bool DidFirstGoldDemand()
	{
		return kingdom.manageDiplomacyIntention.didFirstGoldDemand;
	}

	public void StartFlavorConvo()
	{
		DialogueManager.StartConversation(kingdom.GetFlavorConvo(foreignEnvoy.TeamID() != 0));
		kingdom.flavorChatTimer = SeasonManager.inst.TimeInYear() * 10f;
	}

	public void StartChat()
	{
		DialogueManager.StopConversation();
		if (kingdom.currMission != null)
		{
			StartMissionConvo();
			kingdom.didFlavor = false;
		}
		else
		{
			if (kingdom.didFlavor)
			{
				if (kingdom.potentialMission != null)
				{
					StartMissionConvo();
				}
				else
				{
					DialogueManager.StartConversation("NoFlavorAvailable");
				}
			}
			else if (kingdom.flavorChatTimer <= 0f && kingdom.HasValidFlavor(foreignEnvoy.TeamID() != 0))
			{
				StartFlavorConvo();
			}
			else
			{
				DialogueManager.StartConversation("NoFlavorAvailable");
			}
			kingdom.didFlavor = !kingdom.didFlavor;
		}
		didChat = true;
	}

	public bool DidChat()
	{
		return didChat;
	}

	public void StartMissionConvo()
	{
		kingdom.TryAcceptPotentialMission();
		RefreshMissionUI();
		if (kingdom.currMission is BuildingResourceRequest)
		{
			string friendlyName = (kingdom.currMission as BuildingResourceRequest).friendlyName;
			DialogueLua.SetVariable("Var1", friendlyName);
		}
		DialogueManager.StartConversation(kingdom.currMission.convo, null, null, -1);
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

	public void ReturnToMenuConvo()
	{
		if (foreignEnvoy.GetComponent<General>().army.teamId == 0)
		{
			if (World.inst.RelationBetween(0, kingdom.LandmassOwner.teamId) != World.Relations.Enemy)
			{
				StartConvo("Menu");
			}
			return;
		}
		if (aiObjective == AIObjectiveType.DemandGold)
		{
			kingdom.manageDiplomacyIntention.didFirstGoldDemand = true;
		}
		StartConvo("EnvoyVisit");
	}

	public bool GiftMissionActive()
	{
		if (kingdom.currMission != null)
		{
			return kingdom.currMission is BuildingResourceRequest;
		}
		return false;
	}

	public bool HasGift()
	{
		return !foreignEnvoy.giftAmount.IsNone();
	}

	public void DoDeliverGift()
	{
		if (kingdom.currMission != null && kingdom.currMission.TryCompleteWithGift(foreignEnvoy.giftAmount))
		{
			foreignEnvoy.TryDropGift();
			StartMissionConvo();
		}
		else
		{
			DialogueManager.StartConversation("GiftThanks");
		}
	}

	public bool IsPlayerAnEnemy()
	{
		return World.inst.RelationBetween(0, GetAILMO().teamId) == World.Relations.Enemy;
	}

	public void Test()
	{
		kingdom.hasPlayerVisitedKeep = true;
		if (!TryIntroConvo())
		{
			if (World.inst.RelationBetween(0, GetAILMO().teamId) == World.Relations.Enemy)
			{
				if (!foreignEnvoy.giftAmount.IsNone())
				{
					DialogueManager.StartConversation("GiftThanks");
				}
				else
				{
					DialogueManager.StartConversation("EnemyMenu", null, null, -1);
				}
			}
			else
			{
				bool flag = false;
				if (kingdom.currMission != null && kingdom.currMission.TryCompleteWithGift(foreignEnvoy.giftAmount))
				{
					foreignEnvoy.TryDropGift();
					StartMissionConvo();
					flag = true;
				}
				else if (kingdom.currMission != null && kingdom.currMission.status != Mission.Status.InProgress)
				{
					StartMissionConvo();
					flag = true;
				}
				else if (kingdom.manageDiplomacyIntention.objective == AIObjectiveType.AskForTroopDrawDown || ShouldDoCallTroopsHomeOverride())
				{
					DialogueManager.StartConversation("RemoveTroops", null, null);
					kingdom.manageDiplomacyIntention.removeTroopCount++;
					kingdom.manageDiplomacyIntention.ResetObjective();
					flag = true;
				}
				else if (!flag)
				{
					DialogueManager.StartConversation("Menu");
				}
			}
		}
		kingdom.audienceTimer = SeasonManager.inst.TimeInYear() * 0.3f;
	}

	public int GetGiftReaction()
	{
		int num = SeasonManager.inst.CurrentYear() - kingdom.lastGiftGivenYear;
		if (num >= 5)
		{
			if (GiftPts() > 50f)
			{
				return 0;
			}
			return 1;
		}
		if (num < 5 && num > 1)
		{
			if (GiftPts() > 75f)
			{
				return 1;
			}
			return 2;
		}
		return 3;
	}

	private float GiftPts()
	{
		float num = 0f;
		for (int i = 0; i < foreignEnvoy.giftAmount.resources.Count; i++)
		{
			num += (float)foreignEnvoy.giftAmount.resources[i].Amount;
		}
		float num2 = Mathf.Lerp(2.5f, 0.1f, Mathff.Clamp01(SeasonManager.inst.CurrentYear() / 125));
		num *= num2;
		float num3 = SeasonManager.inst.CurrentYear() - kingdom.lastGiftGivenYear;
		float num4 = Mathf.Lerp(0.25f, 1f, Mathf.Clamp01(num3 / 7f));
		num *= num4;
		if (IsPlayerAnEnemy())
		{
			num *= 0.7f;
		}
		if (num > 100f)
		{
			num = 100f;
		}
		return num;
	}

	public void GiveGiftToPlayer()
	{
		foreignEnvoy.TryDropGift();
	}

	public void GiveGift()
	{
		if (!foreignEnvoy.giftAmount.IsNone())
		{
			float num = GiftPts();
			GetAILMO().ModifyStandingFor(Player.inst.PlayerLandmassOwner.teamId, (int)num);
			kingdom.lastGiftGivenYear = SeasonManager.inst.CurrentYear();
			foreignEnvoy.TryDropGift();
		}
	}

	public bool Visible()
	{
		return gameObject.activeSelf;
	}

	public bool DidAbdicateConvoAlready()
	{
		return kingdom.didAbdicate;
	}
}
