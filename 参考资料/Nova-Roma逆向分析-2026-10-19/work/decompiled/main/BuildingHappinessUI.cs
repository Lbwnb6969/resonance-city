using System;
using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingHappinessUI : MonoBehaviour
{
	[SerializeField]
	private BuildingHappinessItemUI itemPrefab;

	[SerializeField]
	private RectTransform itemContainer;

	[SerializeField]
	private TextMeshProUGUI totalHappinessTMP;

	private BuildingHappinessItemUI healthItem;

	[SerializeField]
	private Sprite healthIcon;

	private BuildingHappinessItemUI taxItem;

	[SerializeField]
	private Sprite taxIcon;

	private List<BuildingHappinessItemUI> consumableItems = new List<BuildingHappinessItemUI>();

	private List<BuildingHappinessItemUI> residentialTileItems = new List<BuildingHappinessItemUI>();

	private Building building;

	private Home home;

	public Image happinessIcon;

	public Sprite failBG;

	public Sprite normalBG;

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (home = b.GetComponent<Home>()) == null || home.Residents.Count == 0)
		{
			SetVisibility(isVisible: false);
			return;
		}
		building = b;
		home = b.GetComponent<Home>();
		if (healthItem == null)
		{
			healthItem = AddItem();
			healthItem.storageContainer.SetActive(value: false);
			healthItem.transform.SetSiblingIndex(0);
			healthItem.iconImg.sprite = healthIcon;
		}
		if (taxItem == null)
		{
			taxItem = AddItem();
			taxItem.tooltipHook.SetTerm("HomeBeingTaxed");
			taxItem.storageContainer.SetActive(value: false);
			taxItem.transform.SetSiblingIndex(1);
			taxItem.iconImg.sprite = taxIcon;
		}
		RefreshVisuals();
		SetVisibility(isVisible: true);
	}

	public void OnDeselected()
	{
		building = null;
		home = null;
	}

	private void Update()
	{
		if (!(home == null))
		{
			RefreshVisuals();
		}
	}

	private void RefreshVisuals()
	{
		int happinessFromDiet = home.GetHappinessFromDiet();
		int happinessFromWater = home.GetHappinessFromWater();
		int healthDebuffFromFilth = home.GetHealthDebuffFromFilth();
		int happinessFromClinicHealth = home.GetHappinessFromClinicHealth();
		healthItem.happinessTMP.text = FormatString(happinessFromDiet + happinessFromWater + healthDebuffFromFilth + happinessFromClinicHealth);
		string text = string.Format(ScriptLocalization.workerui_happiness_diet_tooltip, happinessFromDiet);
		if (happinessFromWater > 0)
		{
			text = text + Environment.NewLine + string.Format(ScriptLocalization.workerui_happiness_water_tooltip, happinessFromWater);
		}
		if (healthDebuffFromFilth < 0)
		{
			text = text + Environment.NewLine + healthDebuffFromFilth + " " + LocalizationManager.GetTranslation("workerui_unhealthyfilth");
		}
		if (happinessFromClinicHealth != 0)
		{
			text = text + Environment.NewLine + ((happinessFromClinicHealth > 0) ? string.Format(LocalizationManager.GetTranslation("workerui_happinessui_health_positive_clinic"), happinessFromClinicHealth) : string.Format(LocalizationManager.GetTranslation("workerui_happinessui_health_negative_clinic"), happinessFromClinicHealth));
		}
		healthItem.tooltipHook.toolTipText = text;
		int happinessFromTax = home.GetHappinessFromTax();
		taxItem.gameObject.SetActive(happinessFromTax < 0);
		taxItem.happinessTMP.text = $"<color=orange>{happinessFromTax}</color>";
		taxItem.circleBG.sprite = failBG;
		for (int i = consumableItems.Count; i < home.consumables.Length; i++)
		{
			BuildingHappinessItemUI item = AddItem();
			consumableItems.Add(item);
		}
		int num = 2;
		for (int j = 0; j < home.consumables.Length; j++)
		{
			BuildingHappinessItemUI buildingHappinessItemUI = consumableItems[j];
			Home.Consumable consumable = home.consumables[j];
			int num2 = consumable.type;
			HappinessModifierSystem.HappinessModifier happinessModifier = HappinessModifierSystem.happinessModifierMap[consumable.happinessModifierID];
			int num3 = home.ConsumableHappinessModifiers[consumable.happinessModifierID];
			if (consumable.altType != -1)
			{
				int num4 = home.ConsumableHappinessModifiers[consumable.altHappinessModifierID];
				if (num4 > num3)
				{
					num2 = consumable.altType;
					happinessModifier = HappinessModifierSystem.happinessModifierMap[consumable.altHappinessModifierID];
					num3 = num4;
				}
			}
			int a = home.resourcesStored.Get(num2);
			if (num3 > 0)
			{
				a = Mathf.Max(a, 1);
			}
			int num5 = home.resourceMaxStorage.Get(num2);
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[num2];
			buildingHappinessItemUI.iconImg.sprite = resourceDef.texture;
			buildingHappinessItemUI.storageTMP.text = $"{Mathff.Min(a, num5)} / {num5}";
			buildingHappinessItemUI.storageContainer.SetActive(value: true);
			buildingHappinessItemUI.happinessTMP.text = FormatString(num3);
			buildingHappinessItemUI.tooltipHook.SetTerm((num3 <= 0) ? happinessModifier.negativeTerm : happinessModifier.positiveTerm);
			buildingHappinessItemUI.circleBG.sprite = ((num3 <= 0) ? failBG : normalBG);
			buildingHappinessItemUI.transform.SetSiblingIndex(num++);
			if (!buildingHappinessItemUI.gameObject.activeSelf)
			{
				buildingHappinessItemUI.gameObject.SetActive(value: true);
			}
		}
		for (int num6 = consumableItems.Count - 1; num6 >= home.consumables.Length; num6--)
		{
			consumableItems[num6].gameObject.SetActive(value: false);
		}
		int num7 = 0;
		foreach (KeyValuePair<int, int> tileHappinessModifier in home.TileHappinessModifiers)
		{
			HappinessModifierSystem.HappinessModifier happinessModifier2 = HappinessModifierSystem.happinessModifierMap[tileHappinessModifier.Key];
			if (residentialTileItems.Count == num7)
			{
				BuildingHappinessItemUI item2 = AddItem();
				residentialTileItems.Add(item2);
			}
			BuildingHappinessItemUI buildingHappinessItemUI2 = residentialTileItems[num7];
			buildingHappinessItemUI2.priority = happinessModifier2.priority;
			int k;
			for (k = 0; k < num7 && residentialTileItems[k].priority <= buildingHappinessItemUI2.priority; k++)
			{
			}
			buildingHappinessItemUI2.transform.SetSiblingIndex(num + k);
			buildingHappinessItemUI2.iconImg.sprite = happinessModifier2.icon;
			buildingHappinessItemUI2.happinessTMP.text = FormatString(tileHappinessModifier.Value);
			buildingHappinessItemUI2.tooltipHook.SetTerm((tileHappinessModifier.Value <= 0) ? happinessModifier2.negativeTerm : happinessModifier2.positiveTerm);
			buildingHappinessItemUI2.circleBG.sprite = ((tileHappinessModifier.Value <= 0) ? failBG : normalBG);
			buildingHappinessItemUI2.storageContainer.SetActive(value: false);
			buildingHappinessItemUI2.gameObject.SetActive(value: true);
			num7++;
		}
		for (int num8 = residentialTileItems.Count - 1; num8 >= num7; num8--)
		{
			residentialTileItems[num8].gameObject.SetActive(value: false);
		}
		int happiness = home.GetHappiness();
		ColorUtility.TryParseHtmlString(InfoButton.GetBarColor(happiness), out var color);
		totalHappinessTMP.text = $"{happiness}";
		totalHappinessTMP.color = color;
		happinessIcon.sprite = HappinessUI.inst.GetHappinessSprite(happiness);
		happinessIcon.color = color;
	}

	public string FormatString(int value)
	{
		string text = "";
		text = ((value <= 0) ? "<color=orange>{0}</color>" : "<color=#7ecd56>+{0}</color>");
		return string.Format(text, value);
	}

	public BuildingHappinessItemUI AddItem()
	{
		return UnityEngine.Object.Instantiate(itemPrefab, itemContainer, worldPositionStays: false);
	}
}
