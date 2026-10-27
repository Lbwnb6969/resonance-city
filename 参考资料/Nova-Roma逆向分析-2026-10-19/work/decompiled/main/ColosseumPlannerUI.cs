using System.Collections.Generic;
using Assets.Code;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ColosseumPlannerUI : MonoBehaviour
{
	public static ColosseumPlannerUI inst;

	public TextMeshProUGUI titleText;

	public GameObject gladiatorInfo;

	[Header("Round Slots")]
	public Transform roundSlotsContainer;

	public GameObject roundSlotPrefab;

	[Header("Cost")]
	public TextMeshProUGUI totalCostText;

	[Header("Buttons")]
	public Button startGamesButton;

	public TooltipHook startGamesButtonTooltip;

	public Button cancelButton;

	[Header("Wizard")]
	public AddFightWizardUI fightWizard;

	private Colosseum currentColosseum;

	private ColosseumEvent currentEvent;

	internal List<RoundSlotUI> roundSlots = new List<RoundSlotUI>();

	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	private bool isVisible;

	private Cam.TransformCapture oldCam;

	private void Awake()
	{
		inst = this;
		startGamesButton.onClick.AddListener(OnStartGamesClicked);
		cancelButton.onClick.AddListener(OnCancelClicked);
		roundSlotPrefab.gameObject.SetActive(value: false);
		SetVisible(v: false);
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	private void SetVisible(bool v)
	{
		isVisible = v;
		Util.SetEnabled(canvas, isVisible);
		Util.SetEnabled(gRaycaster, isVisible);
		canvas.renderMode = RenderMode.ScreenSpaceCamera;
		canvas.worldCamera = (v ? GUICamera.inst.cam : null);
		if (!v)
		{
			gladiatorInfo.GetComponent<GladiatorSelectItemUI>().gladiatorVisual.gameObject.SetActive(value: false);
			gladiatorInfo.GetComponent<GladiatorSelectItemUI>().beastVisual.SetActive(value: false);
		}
	}

	public void Show(Colosseum colosseum, ColosseumEvent colosseumEvent)
	{
		if (!isVisible)
		{
			SetVisible(v: true);
			GameUI.SetUIForModalHelper(v: false);
			oldCam = Cam.inst.CaptureCameraTransform();
			Cam.inst.SetDesiredTrackingPos(colosseum.GetComponent<Building>().Center());
			Cam.inst.desiredDist = 15f;
			Cam.inst.desiredPhi = 45f;
			gladiatorInfo.gameObject.SetActive(value: false);
		}
		GameUI.inst.ClearUIForClick();
		currentColosseum = colosseum;
		currentEvent = colosseumEvent;
		CreateRoundSlots();
		RefreshUI();
	}

	public void Hide()
	{
		if (isVisible)
		{
			SetVisible(v: false);
			if (currentColosseum.GetState() == ColosseumState.Idle)
			{
				GameUI.SetUIForModalHelper(v: true);
				GameUI.inst.SetSelectedBuildingNew(currentColosseum.GetComponent<Building>(), forceUpdate: true);
			}
			if (oldCam != null)
			{
				Cam.inst.ApplyTransformCapture(oldCam);
			}
		}
		fightWizard.Hide();
		fightWizard.ClearGladiatorVisuals();
		currentColosseum = null;
		currentEvent = null;
	}

	private void Update()
	{
		if (canvas.enabled)
		{
			RefreshUI();
		}
	}

	private void CreateRoundSlots()
	{
		foreach (RoundSlotUI roundSlot in roundSlots)
		{
			if (roundSlot != null)
			{
				Object.Destroy(roundSlot.gameObject);
			}
		}
		roundSlots.Clear();
		if (currentEvent == null)
		{
			return;
		}
		for (int i = 0; i < currentEvent.rounds.Count; i++)
		{
			GameObject gameObject = Object.Instantiate(roundSlotPrefab, roundSlotsContainer);
			gameObject.SetActive(i == 0);
			RoundSlotUI component = gameObject.GetComponent<RoundSlotUI>();
			if (component != null)
			{
				int roundIndex = i;
				component.Initialize(i, () =>
				{
					OnAddFightClicked(roundIndex);
				}, () =>
				{
					OnChangeClicked(roundIndex);
				});
				roundSlots.Add(component);
			}
		}
	}

	private void RefreshUI()
	{
		if (currentEvent == null || currentColosseum == null)
		{
			return;
		}
		int num = currentColosseum.GetLandmassOwner()?.Gold ?? 0;
		for (int i = 0; i < roundSlots.Count && i < currentEvent.rounds.Count; i++)
		{
			ColosseumRound colosseumRound = currentEvent.rounds[i];
			Gladiator combatant = GladiatorSystem.inst?.GetGladiator(colosseumRound.combatant1Id);
			Gladiator combatant2 = null;
			if (colosseumRound.opponentType == OpponentType.School && colosseumRound.opponentId >= 0)
			{
				combatant2 = GladiatorSystem.inst?.GetGladiator(colosseumRound.opponentId);
			}
			roundSlots[i].SetData(colosseumRound, combatant, combatant2, num);
		}
		for (int j = 0; j < roundSlots.Count; j++)
		{
			Util.SetActive(roundSlots[j].inactivePanel, fightWizard.gameObject.activeInHierarchy && fightWizard.currRoundIdx != j);
		}
		int totalCost = currentEvent.GetTotalCost();
		bool flag = num >= totalCost;
		string text = ResourceAmount.Make(4, totalCost).ToString();
		totalCostText.text = (flag ? text : ResourceAmount.MakeRed(text));
		bool flag2 = currentEvent.CanStart();
		bool interactable = flag2 & flag;
		startGamesButton.interactable = interactable;
		if (startGamesButtonTooltip != null)
		{
			if (!flag2)
			{
				startGamesButtonTooltip.isValid = true;
				startGamesButtonTooltip.tooltipTerm = "colosseum_no_rounds_planned";
			}
			else if (!flag)
			{
				startGamesButtonTooltip.isValid = true;
				startGamesButtonTooltip.tooltipTerm = "colosseum_not_enough_gold";
			}
			else
			{
				startGamesButtonTooltip.isValid = false;
			}
		}
		titleText.text = LocalizationManager.GetTranslation("colosseum_plan_games_button");
		if (fightWizard.gameObject.activeInHierarchy)
		{
			string text2 = fightWizard.GetTitleText();
			if (text2 != null)
			{
				titleText.text = text2;
			}
		}
	}

	private void ShowFightWizardFor(int roundIndex)
	{
		SfxSystem.PlayUiSelect();
		fightWizard.Show(currentColosseum, currentEvent, roundIndex);
		fightWizard.transform.position = roundSlots[roundIndex].transform.position;
	}

	private void OnAddFightClicked(int roundIndex)
	{
		ShowFightWizardFor(roundIndex);
	}

	private void OnChangeClicked(int roundIndex)
	{
		ShowFightWizardFor(roundIndex);
	}

	private void OnStartGamesClicked()
	{
		SfxSystem.PlayUiSelect();
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_chariotrace_start_horn");
		RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_merchant_sellto");
		if (currentColosseum != null && currentColosseum.StartGames())
		{
			Hide();
		}
	}

	private void OnCancelClicked()
	{
		if (fightWizard.isActiveAndEnabled && (fightWizard.currentStep == AddFightWizardUI.State.OpponentSelect || fightWizard.roleSelect))
		{
			fightWizard.OnBackClicked();
			return;
		}
		SfxSystem.PlayUiSelect();
		currentColosseum?.CancelEvent();
		Hide();
	}
}
