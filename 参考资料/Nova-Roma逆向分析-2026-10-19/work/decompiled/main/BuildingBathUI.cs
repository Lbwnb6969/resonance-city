using System;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingBathUI : MonoBehaviour
{
	public BuildingBathItemUI itemPrefab;

	[SerializeField]
	private TextMeshProUGUI bGroupTMP;

	[SerializeField]
	private GameObject bGroupContainerObj;

	[SerializeField]
	private Transform bGroupItemContainer;

	[SerializeField]
	private ToggleGroup bToggleGroup;

	[SerializeField]
	private Transform individualContainer;

	[SerializeField]
	private GameObject wConsumptionObj;

	[SerializeField]
	private TextMeshProUGUI wConsumptionTMP;

	[SerializeField]
	private RawImage wConsumptionCheckmarkRI;

	[SerializeField]
	private RawImage wConsumptionAbortRI;

	[SerializeField]
	private TextMeshProUGUI poolTypeTMP;

	[SerializeField]
	private GameObject dividerObj;

	[SerializeField]
	private GameObject hotPoolProductionContainer;

	[SerializeField]
	private Image hotPoolArrowImage;

	[SerializeField]
	private BuildingProductionItemUI hotPoolCostItem;

	[SerializeField]
	private BuildingProductionItemUI hotPoolResultItem;

	[SerializeField]
	private Texture2D smallColdPoolTexture;

	[SerializeField]
	private Texture2D mediumColdPoolTexture;

	[SerializeField]
	private Texture2D largeColdPoolTexture;

	[SerializeField]
	private Texture2D smallHeatedPoolTexture;

	[SerializeField]
	private Texture2D mediumHeatedPoolTexture;

	[SerializeField]
	private Texture2D largeHeatedPoolTexture;

	[SerializeField]
	private Texture2D smallLibraryTexture;

	[SerializeField]
	private Texture2D mediumLibraryTexture;

	[SerializeField]
	private Texture2D largeLibraryTexture;

	[SerializeField]
	private Texture2D smallPalaestraTexture;

	[SerializeField]
	private Texture2D mediumPalaestraTexture;

	[SerializeField]
	private Texture2D largePalaestraTexture;

	[SerializeField]
	private Texture2D smallGardenTexture;

	[SerializeField]
	private Texture2D mediumGardenTexture;

	[SerializeField]
	private Texture2D largeGardenTexture;

	[SerializeField]
	private Texture2D firstBonusTexture;

	[SerializeField]
	private Texture2D secondBonusTexture;

	[SerializeField]
	private Texture2D thirdBonusTexture;

	public Image circleBG;

	public Sprite successBG;

	public Sprite failBG;

	[NonSerialized]
	public BuildingBathItemUI smallColdPoolItemUI;

	[NonSerialized]
	public BuildingBathItemUI mediumColdPoolItemUI;

	[NonSerialized]
	public BuildingBathItemUI largeColdPoolItemUI;

	[NonSerialized]
	public BuildingBathItemUI smallHeatedPoolItemUI;

	[NonSerialized]
	public BuildingBathItemUI mediumHeatedPoolItemUI;

	[NonSerialized]
	public BuildingBathItemUI largeHeatedPoolItemUI;

	[NonSerialized]
	public BuildingBathItemUI smallPalaestraItemUI;

	[NonSerialized]
	public BuildingBathItemUI mediumPalaestraItemUI;

	[NonSerialized]
	public BuildingBathItemUI largePalaestraItemUI;

	[NonSerialized]
	public BuildingBathItemUI smallLibraryItemUI;

	[NonSerialized]
	public BuildingBathItemUI mediumLibraryItemUI;

	[NonSerialized]
	public BuildingBathItemUI largeLibraryItemUI;

	[NonSerialized]
	public BuildingBathItemUI smallGardenItemUI;

	[NonSerialized]
	public BuildingBathItemUI mediumGardenItemUI;

	[NonSerialized]
	public BuildingBathItemUI largeGardenItemUI;

	[NonSerialized]
	public BuildingBathItemUI firstBonusItemUI;

	[NonSerialized]
	public BuildingBathItemUI secondBonusItemUI;

	[NonSerialized]
	public BuildingBathItemUI thirdBonusItemUI;

	private int currHighlight = -1;

	public const int COLD_SMALL_POOL_HIGHLIGHT = 10;

	public const int COLD_MEDIUM_POOL_HIGHLIGHT = 11;

	public const int COLD_LARGE_POOL_HIGHLIGHT = 12;

	public const int HEATED_SMALL_POOL_HIGHLIGHT = 20;

	public const int HEATED_MEDIUM_POOL_HIGHLIGHT = 21;

	public const int HEATED_LARGE_POOL_HIGHLIGHT = 22;

	public const int LIBRARY_HIGHLIGHT = 30;

	public const int PALAESTRA_HIGHLIGHT = 40;

	public const int GARDEN_HIGHLIGHT = 50;

	public TextMeshProUGUI happinessTMP;

	private Building building;

	private BathManager.BathGroup bGroup;

	private BathManager.BathGroup.PoolGroup pGroup;

	public void Awake()
	{
		smallColdPoolItemUI = CreateItem($"+{1}", "workerui_bathui_smallcoldpool_tooltip", 10, smallColdPoolTexture);
		mediumColdPoolItemUI = CreateItem($"+{4}", "workerui_bathui_mediumcoldpool_tooltip", 11, mediumColdPoolTexture);
		largeColdPoolItemUI = CreateItem($"+{6}", "workerui_bathui_largecoldpool_tooltip", 12, largeColdPoolTexture);
		smallHeatedPoolItemUI = CreateItem($"+{1}", "workerui_bathui_smallheatedpool_tooltip", 20, smallHeatedPoolTexture);
		mediumHeatedPoolItemUI = CreateItem($"+{4}", "workerui_bathui_mediumheatedpool_tooltip", 21, mediumHeatedPoolTexture);
		largeHeatedPoolItemUI = CreateItem($"+{6}", "workerui_bathui_largeheatedpool_tooltip", 22, largeHeatedPoolTexture);
		smallPalaestraItemUI = CreateItem($"+{1}", "workerui_bathui_smallpalaestra_tooltip", 40, smallPalaestraTexture);
		mediumPalaestraItemUI = CreateItem($"+{2}", "workerui_bathui_mediumpalaestra_tooltip", 40, mediumPalaestraTexture);
		largePalaestraItemUI = CreateItem($"+{3}", "workerui_bathui_largepalaestra_tooltip", 40, largePalaestraTexture);
		smallLibraryItemUI = CreateItem($"+{1}", "workerui_bathui_smalllibrary_tooltip", 30, smallLibraryTexture);
		mediumLibraryItemUI = CreateItem($"+{2}", "workerui_bathui_mediumlibrary_tooltip", 30, mediumLibraryTexture);
		largeLibraryItemUI = CreateItem($"+{3}", "workerui_bathui_largelibrary_tooltip", 30, largeLibraryTexture);
		smallGardenItemUI = CreateItem($"+{1}", "workerui_bathui_smallgarden_tooltip", 50, smallGardenTexture);
		mediumGardenItemUI = CreateItem($"+{2}", "workerui_bathui_mediumgarden_tooltip", 50, mediumGardenTexture);
		largeGardenItemUI = CreateItem($"+{3}", "workerui_bathui_largegarden_tooltip", 50, largeGardenTexture);
		firstBonusItemUI = CreateItem($"+{1}", "workerui_bathui_bonus_tooltip", -1, firstBonusTexture, (string key) => string.Format(LocalizationManager.GetTranslation(key), 3));
		secondBonusItemUI = CreateItem($"+{1}", "workerui_bathui_bonus_tooltip", -1, secondBonusTexture, (string key) => string.Format(LocalizationManager.GetTranslation(key), 6));
		thirdBonusItemUI = CreateItem($"+{2}", "workerui_bathui_bonus_tooltip", -1, thirdBonusTexture, (string key) => string.Format(LocalizationManager.GetTranslation(key), 9));
		Util.SetActive(hotPoolResultItem.successGradient.gameObject, active: false);
		hotPoolCostItem.tooltipHook.SetTerm("charcoal");
		hotPoolResultItem.tooltipHook.SetTerm("workerui_bathui_hotpool_productionui_result_heat");
	}

	private BuildingBathItemUI CreateItem(string happinessTxt, string term, int highlightType, Texture2D tex = null, StaticTooltipHook.OnLocalize onLocalize = null)
	{
		BuildingBathItemUI buildingBathItemUI = UnityEngine.Object.Instantiate(itemPrefab, bGroupItemContainer, worldPositionStays: false);
		buildingBathItemUI.happinessTMP.text = happinessTxt;
		buildingBathItemUI.iconRI.texture = tex;
		buildingBathItemUI.tooltipHook.onLocalize = onLocalize;
		buildingBathItemUI.tooltipHook.SetTerm(term);
		if (highlightType == -1)
		{
			buildingBathItemUI.selectBtn.interactable = false;
		}
		else
		{
			buildingBathItemUI.selectBtn.group = bToggleGroup;
			buildingBathItemUI.selectBtn.onValueChanged.AddListener((bool isOn) =>
			{
				if (isOn)
				{
					currHighlight = highlightType;
					SfxSystem.PlayUiSelect();
				}
			});
		}
		return buildingBathItemUI;
	}

	public void SetVisibility(bool isVisible)
	{
		Util.SetActive(gameObject, isVisible);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || b.categoryHash != World.bathCategoryHash)
		{
			SetVisibility(isVisible: false);
			return;
		}
		building = b;
		RefreshGroups();
		currHighlight = -1;
		if (bGroup == null)
		{
			SetVisibility(isVisible: false);
			return;
		}
		SetVisibility(isVisible: true);
		RefreshVisuals();
		bToggleGroup.SetAllTogglesOff(sendCallback: false);
		switch (b.UniqueName)
		{
		case "bathcoldpool":
		case "bathhotpool":
		{
			if (pGroup == null)
			{
				break;
			}
			int count2 = pGroup.pools.Count;
			if (count2 >= 1)
			{
				if (count2 < 6)
				{
					currHighlight = (pGroup.isHeated ? 20 : 10);
					(pGroup.isHeated ? smallHeatedPoolItemUI.selectBtn : smallColdPoolItemUI.selectBtn).isOn = true;
				}
				else if (count2 < 12)
				{
					currHighlight = (pGroup.isHeated ? 21 : 11);
					(pGroup.isHeated ? mediumHeatedPoolItemUI.selectBtn : mediumColdPoolItemUI.selectBtn).isOn = true;
				}
				else
				{
					currHighlight = (pGroup.isHeated ? 22 : 12);
					(pGroup.isHeated ? largeHeatedPoolItemUI.selectBtn : largeColdPoolItemUI.selectBtn).isOn = true;
				}
			}
			break;
		}
		case "bathpalestra":
		{
			int count3 = bGroup.palaestras.Count;
			if (count3 >= 1)
			{
				currHighlight = 40;
				if (count3 < 3)
				{
					smallPalaestraItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
				else if (count3 < 6)
				{
					mediumPalaestraItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
				else
				{
					largePalaestraItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
			}
			break;
		}
		case "bathgarden":
		{
			int count4 = bGroup.gardens.Count;
			if (count4 >= 1)
			{
				currHighlight = 50;
				if (count4 < 3)
				{
					smallGardenItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
				else if (count4 < 6)
				{
					mediumGardenItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
				else
				{
					largeGardenItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
			}
			break;
		}
		case "bathlibrary":
		{
			int count = bGroup.libraries.Count;
			if (count >= 1)
			{
				currHighlight = 30;
				if (count < 3)
				{
					smallLibraryItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
				else if (count < 6)
				{
					mediumLibraryItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
				else
				{
					largeLibraryItemUI.selectBtn.SetIsOnWithoutNotify(value: true);
				}
			}
			break;
		}
		}
	}

	public void OnDeselected()
	{
		building = null;
		bGroup = null;
		pGroup = null;
	}

	private void RefreshGroups()
	{
		BathManager.BathCell bathCell = BathManager.inst.bathCells[building.GetCell().index];
		bGroup = bathCell.bGroup;
		pGroup = bathCell.pGroup;
	}

	private void Update()
	{
		if (!(building == null))
		{
			RefreshGroups();
			if (bGroup != null)
			{
				RefreshVisuals();
			}
		}
	}

	private void RefreshVisuals()
	{
		TryHighlight();
		bool active = true;
		if (building.uniqueNameHash == World.bathReservoirHash && bGroup.gardens.Count <= 0 && bGroup.libraries.Count <= 0 && bGroup.palaestras.Count <= 0 && bGroup.pools.Count <= 0)
		{
			active = false;
		}
		Util.SetActive(bGroupContainerObj, active);
		if ((building.uniqueNameHash == World.bathColdPoolHash || building.uniqueNameHash == World.bathHotPoolHash) && pGroup != null)
		{
			BathPool component = building.GetComponent<BathPool>();
			string text = (pGroup.isHeated ? ScriptLocalization.workerui_bathui_pooltype_heated_description : ScriptLocalization.workerui_bathui_pooltype_cold_description);
			poolTypeTMP.text = text;
			wConsumptionTMP.text = string.Format(ScriptLocalization.workerui_waterconsumptionui_description, component.HasWater() ? ((float)BathPool.wConsumption) : 0f, BathPool.wConsumption);
			circleBG.sprite = (component.HasWater() ? successBG : failBG);
			Util.SetEnabled(wConsumptionCheckmarkRI, component.HasWater());
			Util.SetEnabled(wConsumptionAbortRI, !component.HasWater());
			BathHotPool component2 = building.GetComponent<BathHotPool>();
			Util.SetActive(hotPoolProductionContainer, component2 != null);
			if (component2 != null)
			{
				hotPoolArrowImage.fillAmount = component2.consumptionTime / SeasonManager.inst.TimeInYear();
				hotPoolCostItem.storageTMP.text = $"{component2.currCharcoalStorage} / {component2.maxCharcoalStorage}";
				hotPoolCostItem.successGradient.color = (component2.HasCharcoal() ? GameUI.inst.successColor : GameUI.inst.failColor);
				hotPoolResultItem.circleBG.sprite = (component.HasWater() ? successBG : failBG);
				Util.SetActive(hotPoolResultItem.consumeCheck, pGroup.isHeated);
				Util.SetActive(hotPoolResultItem.consumeAbort, !pGroup.isHeated);
				Util.SetActive(hotPoolCostItem.consumeCheck, component2.HasCharcoal());
				Util.SetActive(hotPoolCostItem.consumeAbort, !component2.HasCharcoal());
			}
		}
		Util.SetActive(wConsumptionObj, building.uniqueNameHash == World.bathColdPoolHash || building.uniqueNameHash == World.bathHotPoolHash);
		Util.SetActive(individualContainer, building.uniqueNameHash == World.bathColdPoolHash || building.uniqueNameHash == World.bathHotPoolHash);
		string waterWarningTerm = bGroup.GetWaterWarningTerm();
		UpdateColdPoolVisuals(smallColdPoolItemUI, bGroup.hasSmallColdPool, bGroup.isSmallColdPoolActive, "workerui_bathui_smallcoldpool_tooltip", 1, waterWarningTerm);
		UpdateColdPoolVisuals(mediumColdPoolItemUI, bGroup.hasMediumColdPool, bGroup.isMediumColdPoolActive, "workerui_bathui_mediumcoldpool_tooltip", 4, waterWarningTerm);
		UpdateColdPoolVisuals(largeColdPoolItemUI, bGroup.hasLargeColdPool, bGroup.isLargeColdPoolActive, "workerui_bathui_largecoldpool_tooltip", 6, waterWarningTerm);
		UpdateHeatedPoolVisuals(smallHeatedPoolItemUI, bGroup.hasSmallHeatedPool, bGroup.isSmallHeatedPoolActive, bGroup.hasWater, "workerui_bathui_smallheatedpool_tooltip", 1, waterWarningTerm, bGroup.hasRequiredWorkersForSmallHeatPool);
		UpdateHeatedPoolVisuals(mediumHeatedPoolItemUI, bGroup.hasMediumHeatedPool, bGroup.isMediumHeatedPoolActive, bGroup.hasWater, "workerui_bathui_mediumheatedpool_tooltip", 4, waterWarningTerm, bGroup.hasRequiredWorkersForMediumHeatPool);
		UpdateHeatedPoolVisuals(largeHeatedPoolItemUI, bGroup.hasLargeHeatedPool, bGroup.isLargeHeatedPoolActive, bGroup.hasWater, "workerui_bathui_largeheatedpool_tooltip", 6, waterWarningTerm, bGroup.hasRequiredWorkersForLargeHeatPool);
		Util.SetActive(smallPalaestraItemUI.gameObject, bGroup.hasSmallPalaestra);
		Util.SetActive(mediumPalaestraItemUI.gameObject, bGroup.hasMediumPalaestra);
		Util.SetActive(largePalaestraItemUI.gameObject, bGroup.hasLargePalaestra);
		Util.SetActive(smallLibraryItemUI.gameObject, bGroup.hasSmallLibrary);
		Util.SetActive(mediumLibraryItemUI.gameObject, bGroup.hasMediumLibrary);
		Util.SetActive(largeLibraryItemUI.gameObject, bGroup.hasLargeLibrary);
		Util.SetActive(smallGardenItemUI.gameObject, bGroup.hasSmallGarden);
		Util.SetActive(mediumGardenItemUI.gameObject, bGroup.hasMediumGarden);
		Util.SetActive(largeGardenItemUI.gameObject, bGroup.hasLargeGarden);
		Util.SetActive(firstBonusItemUI.gameObject, bGroup.bonusCount >= 3);
		Util.SetActive(secondBonusItemUI.gameObject, bGroup.bonusCount >= 6);
		Util.SetActive(thirdBonusItemUI.gameObject, bGroup.bonusCount >= 9);
		bool active2 = false;
		for (int i = 0; i < bGroupItemContainer.childCount; i++)
		{
			if (bGroupItemContainer.GetChild(i).gameObject.activeSelf)
			{
				active2 = true;
				break;
			}
		}
		Util.SetActive(dividerObj, active2);
		happinessTMP.text = $"<color=green>+{bGroup.totalBonuses}";
	}

	private void UpdateColdPoolVisuals(BuildingBathItemUI itemUI, bool hasPool, bool isPoolActive, string term, int bonus, string waterWarnTerm)
	{
		if (hasPool)
		{
			Util.SetEnabled(itemUI.abortIconRI, !isPoolActive);
			Util.SetEnabled(itemUI.checkmarkIconRI, isPoolActive);
			itemUI.happinessTMP.text = (isPoolActive ? $"+{bonus}" : "<color=red>+0</color>");
			string term2 = term;
			if (!isPoolActive && waterWarnTerm != null)
			{
				term2 = waterWarnTerm;
			}
			itemUI.tooltipHook.SetTerm(term2);
		}
		Util.SetActive(itemUI.gameObject, hasPool);
		Util.SetActive(itemUI.consumeContainerObj, active: true);
	}

	private void UpdateHeatedPoolVisuals(BuildingBathItemUI itemUI, bool hasPool, bool isPoolActive, bool hasWater, string term, int bonus, string waterWarnTerm, bool hasWorkersRequired)
	{
		if (hasPool)
		{
			Util.SetEnabled(itemUI.abortIconRI, !isPoolActive);
			Util.SetEnabled(itemUI.checkmarkIconRI, isPoolActive);
			itemUI.happinessTMP.text = (isPoolActive ? $"+{bonus}" : "<color=red>+0</color>");
			string term2 = term;
			if (!hasWater)
			{
				if (waterWarnTerm != null)
				{
					term2 = waterWarnTerm;
				}
			}
			else if (!isPoolActive)
			{
				term2 = (hasWorkersRequired ? "workerui_bathui_bathgroup_pool_heated_nocharcoal_tooltip" : "NeedsFullStaff");
			}
			itemUI.tooltipHook.SetTerm(term2);
		}
		Util.SetActive(itemUI.gameObject, hasPool);
		Util.SetActive(itemUI.consumeContainerObj, active: true);
	}

	private void TryHighlight()
	{
		switch (currHighlight)
		{
		case 10:
		{
			for (int j = 0; j < bGroup.pGroups.Count; j++)
			{
				TryHighlightPool(bGroup.pGroups.data[j], isHeated: false, 1, 6);
			}
			break;
		}
		case 11:
		{
			for (int n = 0; n < bGroup.pGroups.Count; n++)
			{
				TryHighlightPool(bGroup.pGroups.data[n], isHeated: false, 6, 12);
			}
			break;
		}
		case 12:
		{
			for (int num2 = 0; num2 < bGroup.pGroups.Count; num2++)
			{
				TryHighlightPool(bGroup.pGroups.data[num2], isHeated: false, 12, int.MaxValue);
			}
			break;
		}
		case 20:
		{
			for (int l = 0; l < bGroup.pGroups.Count; l++)
			{
				TryHighlightPool(bGroup.pGroups.data[l], isHeated: true, 1, 6);
			}
			break;
		}
		case 21:
		{
			for (int num3 = 0; num3 < bGroup.pGroups.Count; num3++)
			{
				TryHighlightPool(bGroup.pGroups.data[num3], isHeated: true, 6, 12);
			}
			break;
		}
		case 22:
		{
			for (int num = 0; num < bGroup.pGroups.Count; num++)
			{
				TryHighlightPool(bGroup.pGroups.data[num], isHeated: true, 12, int.MaxValue);
			}
			break;
		}
		case 30:
		{
			for (int m = 0; m < bGroup.libraries.Count; m++)
			{
				Building b3 = bGroup.libraries.data[m].b;
				if (!(b3 == building))
				{
					b3.SetOutlineImmediate(0);
				}
			}
			break;
		}
		case 40:
		{
			for (int k = 0; k < bGroup.palaestras.Count; k++)
			{
				Building b2 = bGroup.palaestras.data[k].b;
				if (!(b2 == building))
				{
					b2.SetOutlineImmediate(0);
				}
			}
			break;
		}
		case 50:
		{
			for (int i = 0; i < bGroup.gardens.Count; i++)
			{
				Building b = bGroup.gardens.data[i].b;
				if (!(b == building))
				{
					b.SetOutlineImmediate(0);
				}
			}
			break;
		}
		}
	}

	private void TryHighlightPool(BathManager.BathGroup.PoolGroup pg, bool isHeated, int min, int max)
	{
		if (pg.isHeated != isHeated || pg.pools.Count >= max || pg.pools.Count < min)
		{
			return;
		}
		for (int i = 0; i < pg.pools.Count; i++)
		{
			Building b = pg.pools.data[i].b;
			if (!(b == building))
			{
				b.SetOutlineImmediate(0);
			}
		}
	}
}
