using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ForeignIslandInfoContainer : MonoBehaviour
{
	public SlideAnim slideAnim;

	public GameObject missionRoot;

	public TextMeshProUGUI missionDescTxt;

	public TextMeshProUGUI missionConditionTxt;

	public GameObject missionResultRoot;

	public TextMeshProUGUI missionResult;

	public TextMeshProUGUI relationStatusTxt;

	public TextMeshProUGUI relationButtonTxt;

	public Button hostilityButton;

	public TextMeshProUGUI opinionStatusTxt;

	public TextMeshProUGUI relationExplanationText;

	public RectTransform explanationUI;

	public ConsoleUIItem consoleItemEntry;

	public bool isShowing;

	public GameObject consoleLTIcon;

	public bool deferGamepadToggle;

	public GameObject allyStatus;

	public GameObject opinionStatus;

	private int enterCount;

	private void OnDestroy()
	{
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(inst.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
	}

	private void Start()
	{
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(inst.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
	}

	public void UpdateConsoleUI(bool isControllerActive)
	{
		consoleLTIcon.SetActive(isControllerActive);
	}

	private void Update()
	{
		bool flag = !GameState.inst.DevOptionShowUIforAIs() && Player.inst.FocusedLandMass != -1 && World.GetLandmassOwner(Player.inst.FocusedLandMass) != Player.inst.PlayerLandmassOwner && (bool)Player.inst.keep && !GameUI.inst.diplomacyUI.gameObject.activeSelf;
		slideAnim.Play(flag ? SlideAnim.PlayMode.Forward : SlideAnim.PlayMode.Reverse);
		if (consoleItemEntry.isHovered && isShowing && !flag)
		{
			consoleItemEntry.Reset();
		}
		isShowing = flag;
		GamepadControl.DoGameUINavigation(consoleItemEntry);
		if (flag)
		{
			RefreshMissionUI();
			RefreshHostility();
			AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(Player.inst.FocusedLandMass);
			bool flag2 = kingdomByLandmass != null && kingdomByLandmass.hasPlayerVisitedKeep;
			if (hostilityButton.gameObject.activeSelf != flag2)
			{
				hostilityButton.gameObject.SetActive(flag2);
			}
			RefreshOpinion();
		}
		else
		{
			enterCount = 0;
		}
		bool flag3 = enterCount > 0;
		if (explanationUI.gameObject.activeSelf != flag3)
		{
			explanationUI.gameObject.SetActive(flag3);
		}
	}

	public void OnClickedHostility()
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(Player.inst.FocusedLandMass);
		switch (World.inst.RelationBetween(Player.inst.PlayerLandmassOwner.teamId, landmassOwner.teamId))
		{
		case World.Relations.Allies:
			landmassOwner.ModifyStandingFor(0, -100);
			World.inst.SetRelations(Player.inst.PlayerLandmassOwner.teamId, landmassOwner.teamId, World.Relations.Neutral);
			break;
		case World.Relations.Neutral:
			landmassOwner.ModifyStandingFor(0, -100);
			World.inst.SetRelations(Player.inst.PlayerLandmassOwner.teamId, landmassOwner.teamId, World.Relations.Enemy);
			break;
		}
		RefreshHostility();
	}

	public void RefreshHostility()
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(Player.inst.FocusedLandMass);
		if (landmassOwner != null)
		{
			if (!hostilityButton.gameObject.activeSelf)
			{
				hostilityButton.gameObject.SetActive(value: true);
			}
			switch (World.inst.RelationBetween(Player.inst.PlayerLandmassOwner.teamId, landmassOwner.teamId))
			{
			case World.Relations.Allies:
				relationExplanationText.text = "I2.Loc.ScriptLocalization.RelationAllyDesc";
				relationButtonTxt.text = "I2.Loc.ScriptLocalization.BreakAlliance";
				relationStatusTxt.text = "I2.Loc.ScriptLocalization.RelationAlly";
				relationStatusTxt.color = Color.green;
				hostilityButton.interactable = true;
				break;
			case World.Relations.Neutral:
				relationExplanationText.text = "I2.Loc.ScriptLocalization.RelationNeutralDesc";
				relationButtonTxt.text = "I2.Loc.ScriptLocalization.DeclareWar";
				relationStatusTxt.text = "I2.Loc.ScriptLocalization.OpinionNeutral";
				relationStatusTxt.color = Color.white;
				hostilityButton.interactable = true;
				break;
			default:
				relationExplanationText.text = "I2.Loc.ScriptLocalization.RelationEnemyDesc";
				relationStatusTxt.text = "I2.Loc.ScriptLocalization.RelationEnemy";
				relationStatusTxt.color = Color.red;
				hostilityButton.interactable = false;
				break;
			}
		}
		else if (hostilityButton.gameObject.activeSelf)
		{
			hostilityButton.gameObject.SetActive(value: false);
			relationStatusTxt.text = "I2.Loc.ScriptLocalization.OpinionNeutral";
			relationStatusTxt.color = Color.white;
		}
	}

	private void RefreshOpinion()
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(Player.inst.FocusedLandMass);
		allyStatus.gameObject.SetActive(landmassOwner != null);
		opinionStatus.gameObject.SetActive(landmassOwner != null);
		if (landmassOwner != null)
		{
			LandmassOwner.Standing standingFor = landmassOwner.GetStandingFor(0);
			opinionStatusTxt.text = DiplomacyUI.GetStringForStanding(standingFor);
			switch (standingFor)
			{
			case LandmassOwner.Standing.VeryUnfavorable:
				opinionStatusTxt.color = Color.red;
				break;
			case LandmassOwner.Standing.Unfavorable:
				opinionStatusTxt.color = Color.yellow;
				break;
			case LandmassOwner.Standing.Neutral:
				opinionStatusTxt.color = Color.white;
				break;
			case LandmassOwner.Standing.Favorable:
				opinionStatusTxt.color = Color.green;
				break;
			case LandmassOwner.Standing.VeryFavorable:
				opinionStatusTxt.color = Color.green;
				break;
			}
		}
	}

	public void PointerEnter()
	{
		enterCount = 1;
	}

	public void PointerExit()
	{
		enterCount = 0;
	}

	private void RefreshMissionUI()
	{
		AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(Player.inst.FocusedLandMass);
		if (kingdomByLandmass != null)
		{
			if (kingdomByLandmass.currMission != null)
			{
				missionRoot.SetActive(value: true);
				missionDescTxt.text = kingdomByLandmass.currMission.GetDescription();
				missionConditionTxt.text = kingdomByLandmass.currMission.GetCondition();
				if (kingdomByLandmass.currMission.status == Mission.Status.Complete)
				{
					missionResultRoot.SetActive(value: true);
					missionResult.color = Color.green;
					missionResult.text = "I2.Loc.ScriptLocalization.MissionSuccess";
				}
				else if (kingdomByLandmass.currMission.status == Mission.Status.Failed)
				{
					missionResultRoot.SetActive(value: true);
					missionResult.color = Color.red;
					missionResult.text = "I2.Loc.ScriptLocalization.MissionFailure";
				}
				else
				{
					missionResultRoot.SetActive(value: false);
				}
			}
			else
			{
				missionRoot.SetActive(value: false);
			}
		}
		else if (missionRoot.activeSelf)
		{
			missionRoot.SetActive(value: false);
		}
	}
}
