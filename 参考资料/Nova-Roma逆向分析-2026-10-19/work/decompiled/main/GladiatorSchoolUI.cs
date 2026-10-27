using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GladiatorSchoolUI : MonoBehaviour, IWorkerUIElement
{
	[Header("Header")]
	public TextMeshProUGUI slotsText;

	[Header("Header")]
	public TextMeshProUGUI barracksBonusText;

	public Button upgradeButton;

	[Header("Gladiator List")]
	public Transform gladiatorListContent;

	public GameObject gladiatorRowPrefab;

	[Header("Footer")]
	public Button recruitButton;

	public TooltipHook recruitButtonToolTip;

	[Header("Modals")]
	public GladiatorTrainingModal trainingModal;

	private GladiatorSchool currentSchool;

	private List<GladiatorRowUI> activeRows = new List<GladiatorRowUI>();

	private Queue<GladiatorRowUI> rowPool = new Queue<GladiatorRowUI>();

	private void Awake()
	{
		if (upgradeButton != null)
		{
			upgradeButton.onClick.AddListener(OnUpgradeClicked);
		}
		if (recruitButton != null)
		{
			recruitButton.onClick.AddListener(OnRecruitClicked);
		}
	}

	public void TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null)
		{
			currentSchool = buildingSelected.GetComponent<GladiatorSchool>();
			if (currentSchool != null)
			{
				gameObject.SetActive(value: true);
				RefreshUI();
				return;
			}
		}
		gameObject.SetActive(value: false);
		currentSchool = null;
	}

	public void UpdateForNewSelection()
	{
	}

	private void Update()
	{
		if (!(currentSchool == null) && gameObject.activeSelf)
		{
			RefreshUI();
		}
	}

	private void RefreshUI()
	{
		if (!(currentSchool == null))
		{
			int gladiatorCount = currentSchool.GetGladiatorCount();
			int slotCount = currentSchool.GetSlotCount();
			slotsText.SetText("{0}/{1}", gladiatorCount, slotCount);
			if (!currentSchool.TrainingBonusAvailable())
			{
				barracksBonusText.SetText(LocalizationManager.GetTranslation("gladiatorschoolui_trainingbonusnotavailable"), currentSchool.barracksBonusSkillReq);
			}
			else
			{
				barracksBonusText.text = "<color=#D6FF8E>+" + string.Format(LocalizationManager.GetTranslation("gladiatorschoolui_trainingbonus"), 1) + "</color>";
			}
			if (upgradeButton != null)
			{
				upgradeButton.interactable = currentSchool.CanUpgradeSlots();
			}
			bool flag = currentSchool.GetComponent<Building>().GetWorkerPercent() > 0.9f;
			bool interactable = currentSchool.HasEmptySlot() & flag;
			recruitButton.interactable = interactable;
			if (flag && recruitButtonToolTip.tooltipTerm == "NeedsFullStaff")
			{
				recruitButtonToolTip.tooltipTerm = string.Empty;
			}
			else if (!flag && recruitButtonToolTip.tooltipTerm == string.Empty)
			{
				recruitButtonToolTip.tooltipTerm = "NeedsFullStaff";
			}
			RefreshGladiatorList();
		}
	}

	private void RefreshGladiatorList()
	{
		while (activeRows.Count > currentSchool.GetGladiatorCount())
		{
			GladiatorRowUI gladiatorRowUI = activeRows[activeRows.Count - 1];
			activeRows.RemoveAt(activeRows.Count - 1);
			gladiatorRowUI.gameObject.SetActive(value: false);
			rowPool.Enqueue(gladiatorRowUI);
		}
		for (int i = 0; i < currentSchool.GetGladiatorCount(); i++)
		{
			GladiatorRowUI gladiatorRowUI2;
			if (i < activeRows.Count)
			{
				gladiatorRowUI2 = activeRows[i];
			}
			else
			{
				gladiatorRowUI2 = GetOrCreateRow();
				activeRows.Add(gladiatorRowUI2);
			}
			Gladiator gladiator = currentSchool.GetGladiator(i);
			TrainingAssignment trainingAssignment = currentSchool.GetTrainingAssignment(gladiator.gladiatorId);
			gladiatorRowUI2.SetData(gladiator, trainingAssignment, OnTrainClicked, OnFireClicked, currentSchool);
			gladiatorRowUI2.gameObject.SetActive(value: true);
		}
		if (currentSchool.GetGladiatorCount() == 0)
		{
			currentSchool.HasEmptySlot();
		}
	}

	private GladiatorRowUI GetOrCreateRow()
	{
		if (rowPool.Count > 0)
		{
			return rowPool.Dequeue();
		}
		if (gladiatorRowPrefab == null || gladiatorListContent == null)
		{
			return null;
		}
		return Object.Instantiate(gladiatorRowPrefab, gladiatorListContent).GetComponent<GladiatorRowUI>();
	}

	private void OnTrainClicked(Gladiator gladiator)
	{
		if (gladiator.CanTrain())
		{
			trainingModal.Show(currentSchool, gladiator);
		}
	}

	private void OnFireClicked(Gladiator gladiator)
	{
		if (!(currentSchool == null) && gladiator != null)
		{
			GladiatorSystem.inst?.RemoveGladiator(gladiator.gladiatorId);
			RefreshUI();
		}
	}

	private void OnUpgradeClicked()
	{
		SfxSystem.PlayUiSelect();
		if (currentSchool != null && currentSchool.UpgradeSlots())
		{
			RefreshUI();
		}
	}

	private void OnRecruitClicked()
	{
		SfxSystem.PlayUiSelect();
		if (currentSchool != null)
		{
			GladiatorRecruitModal.inst.Show(currentSchool);
		}
	}
}
