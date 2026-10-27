using System;
using System.Collections.Generic;
using Assets.Code.Jobs;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingStockpileUI : MonoBehaviour
{
	public static BuildingStockpileUI inst;

	[SerializeField]
	private Toggle storageToggle;

	public RectTransform container;

	public GridLayoutGroup gridLayout;

	public RectTransform nodePrefab;

	[SerializeField]
	private BetterDropdown setAllDropdown;

	private TooltipHook setAllTooltip;

	[SerializeField]
	private BetterDropdown setEmptyDropdown;

	private TooltipHook setEmptyTooltip;

	[SerializeField]
	private Button purgeInventoryButton;

	[SerializeField]
	private TextMeshProUGUI workerSearchRadiusTMP;

	[SerializeField]
	private Toggle citizenWithdrawalToggle;

	[SerializeField]
	private Toggle citizenDepositToggle;

	private List<RectTransform> nodePool = new List<RectTransform>();

	private List<BetterDropdown.OptionData> optionData = new List<BetterDropdown.OptionData>();

	private Stockpile stockpile;

	private Building building;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
		isVisible = v;
	}

	public void ToggleStorage(bool b)
	{
		if (!b)
		{
			SetVisibility(v: false);
			return;
		}
		SetVisibility(v: true);
		SfxSystem.PlayUiSelect();
	}

	private void Awake()
	{
		inst = this;
		purgeInventoryButton.onClick.AddListener(OnClickPurge);
		setAllTooltip = setAllDropdown.gameObject.AddComponent<TooltipHook>();
		setEmptyTooltip = setEmptyDropdown.gameObject.AddComponent<TooltipHook>();
		citizenDepositToggle.onValueChanged.AddListener((bool isOn) =>
		{
			stockpile.allowCitizensToDeposit = isOn;
		});
		citizenWithdrawalToggle.onValueChanged.AddListener((bool isOn) =>
		{
			stockpile.allowCitizensToWithdrawal = isOn;
		});
	}

	private void OnClickPurge()
	{
		stockpile.PurgeStockpile();
		RefreshSlots();
	}

	private void ConfigureBulkDropdown(BetterDropdown dropdown, Action<int> onSelect)
	{
		if (!(dropdown == null))
		{
			dropdown.options = optionData;
			dropdown.onValueSelected.AddListener((int idx) =>
			{
				int resourceMappedIndex = GetResourceMappedIndex(idx - 1);
				onSelect?.Invoke(resourceMappedIndex);
			});
			int valueWithoutNotify = ((dropdown.placeholder != null) ? (-1) : 0);
			dropdown.SetValueWithoutNotify(valueWithoutNotify);
		}
	}

	private void SetAllNodesTo(int resourceID)
	{
		if (!(stockpile == null))
		{
			for (int i = 0; i < stockpile.stackCount; i++)
			{
				OnResourceChanged(resourceID, i);
			}
		}
	}

	private void SetEmptyNodesTo(int resourceID)
	{
		if (stockpile == null)
		{
			return;
		}
		for (int i = 0; i < stockpile.stackCount; i++)
		{
			if (stockpile.resourceGrid[i] == -1)
			{
				OnResourceChanged(resourceID, i);
			}
		}
	}

	private void RefreshSlots()
	{
		for (int i = 0; i < stockpile.stackCount; i++)
		{
			BetterDropdown component = nodePool[i].GetChild(0).GetComponent<BetterDropdown>();
			int valueWithoutNotify = GetValidMappedIndex(stockpile.resourceGrid[i]) + 1;
			component.SetValueWithoutNotify(valueWithoutNotify);
		}
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (stockpile = b.GetComponent<Stockpile>()) == null)
		{
			SetVisibility(v: false);
			return;
		}
		building = b;
		SetVisibility(v: true);
		this.optionData.Clear();
		BetterDropdown.OptionData optionData = new BetterDropdown.OptionData();
		optionData.image = null;
		optionData.term = "workerui_stockpile_node_any_dropdown";
		this.optionData.Add(optionData);
		for (int i = 0; i < stockpile.ValidResourceTypes.Length; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[stockpile.ValidResourceTypes[i]];
			BetterDropdown.OptionData optionData2 = new BetterDropdown.OptionData();
			optionData2.image = resourceDef.texture;
			optionData2.term = resourceDef.name;
			this.optionData.Add(optionData2);
		}
		new BetterDropdown.OptionData
		{
			image = null,
			term = "workerui_stockpile_node_any_dropdown"
		};
		int columnCount = stockpile.columnCount;
		int[] resourceGrid = stockpile.resourceGrid;
		gridLayout.constraintCount = columnCount;
		ConfigureBulkDropdown(setAllDropdown, SetAllNodesTo);
		ConfigureBulkDropdown(setEmptyDropdown, SetEmptyNodesTo);
		for (int j = 0; j < stockpile.stackCount; j++)
		{
			if (j == nodePool.Count)
			{
				RectTransform item = UnityEngine.Object.Instantiate(nodePrefab, container, worldPositionStays: false);
				nodePool.Add(item);
			}
			RectTransform rectTransform = nodePool[j];
			BetterDropdown component = rectTransform.GetChild(0).GetComponent<BetterDropdown>();
			component.options = this.optionData;
			int valueWithoutNotify = GetValidMappedIndex(resourceGrid[j]) + 1;
			component.SetValueWithoutNotify(valueWithoutNotify);
			int i2 = j;
			component.onValueSelected.RemoveAllListeners();
			component.onValueSelected.AddListener((int idx) =>
			{
				OnResourceChanged(GetResourceMappedIndex(idx - 1), i2);
			});
			rectTransform.gameObject.SetActive(value: true);
		}
		for (int num = nodePool.Count - 1; num >= stockpile.stackCount; num--)
		{
			nodePool[num].gameObject.SetActive(value: false);
		}
		bool active = false;
		for (int num2 = 0; num2 < b.jobs.Count; num2++)
		{
			if (b.jobs[num2] is FreeResourceGathererJob freeResourceGathererJob)
			{
				workerSearchRadiusTMP.text = string.Format(LocalizationManager.GetTranslation("workerui_stockpile_workerradius_description"), freeResourceGathererJob.searchRadius);
				active = true;
				break;
			}
		}
		Util.SetEnabled(workerSearchRadiusTMP, active);
		citizenWithdrawalToggle.SetIsOnWithoutNotify(stockpile.allowCitizensToWithdrawal);
		citizenDepositToggle.SetIsOnWithoutNotify(stockpile.allowCitizensToDeposit);
	}

	public void OnDeselected()
	{
		stockpile = null;
		building = null;
		SetVisibility(v: false);
		if (setAllDropdown != null)
		{
			setAllDropdown.onValueChanged.RemoveAllListeners();
			int valueWithoutNotify = ((setAllDropdown.placeholder != null) ? (-1) : 0);
			setAllDropdown.SetValueWithoutNotify(valueWithoutNotify);
		}
		if (setEmptyDropdown != null)
		{
			setEmptyDropdown.onValueChanged.RemoveAllListeners();
			int valueWithoutNotify2 = ((setEmptyDropdown.placeholder != null) ? (-1) : 0);
			setEmptyDropdown.SetValueWithoutNotify(valueWithoutNotify2);
		}
	}

	private void OnResourceChanged(int rID, int idx)
	{
		stockpile.OnGridResourceChanged(rID, idx);
	}

	private int GetValidMappedIndex(int resourceID)
	{
		for (int i = 0; i < stockpile.ValidResourceTypes.Length; i++)
		{
			if (stockpile.ValidResourceTypes[i] == resourceID)
			{
				return i;
			}
		}
		return -1;
	}

	private int GetResourceMappedIndex(int validIdx)
	{
		if (validIdx == -1)
		{
			return -1;
		}
		return stockpile.ValidResourceTypes[validIdx];
	}

	private void Update()
	{
		if (!isVisible || building == null || stockpile == null)
		{
			return;
		}
		if (setAllDropdown.gameObject.activeSelf != setAllDropdown.IsExpanded)
		{
			setAllTooltip.enabled = setAllDropdown.IsExpanded;
		}
		if (setEmptyDropdown.gameObject.activeSelf != setEmptyDropdown.IsExpanded)
		{
			setEmptyTooltip.enabled = setEmptyDropdown.IsExpanded;
		}
		LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building);
		LogisticVehicleTracker.inst.TrackCartsForLogisticStorage(logisticsForBuilding, doHighlight: true);
		int stackCount = stockpile.stackCount;
		for (int i = 0; i < stackCount; i++)
		{
			RectTransform rectTransform = nodePool[i];
			Image component = rectTransform.GetChild(0).GetChild(2).GetComponent<Image>();
			BetterDropdown component2 = rectTransform.GetChild(0).GetComponent<BetterDropdown>();
			TooltipHook component3 = component2.GetComponent<TooltipHook>();
			if (stockpile.resourceGrid[i] == -1)
			{
				component.sprite = null;
				if (component3 != null)
				{
					component3.tooltipTerm = "workerui_stockpileui_stack_tooltip_empty";
				}
			}
			else
			{
				FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[stockpile.resourceGrid[i]];
				component.sprite = resourceDef.texture;
				if (component3 != null)
				{
					component3.tooltipTerm = resourceDef.name;
				}
			}
			int num = GetValidMappedIndex(stockpile.resourceGrid[i]) + 1;
			if (component2.value != num)
			{
				component2.SetValueWithoutNotify(num);
			}
			rectTransform.GetChild(3).gameObject.SetActive(stockpile.playerSet[i]);
			TextMeshProUGUI component4 = nodePool[i].GetChild(2).GetComponent<TextMeshProUGUI>();
			if (stockpile.resourceGrid[i] >= 0)
			{
				component4.text = $"{stockpile.stacks[i].Count()}/{stockpile.stacks[i].MaxCapacity()}";
				nodePool[i].GetChild(1).gameObject.SetActive(value: true);
			}
			else
			{
				component4.text = "";
				nodePool[i].GetChild(1).gameObject.SetActive(value: false);
			}
		}
	}
}
