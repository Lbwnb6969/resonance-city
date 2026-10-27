using System.Collections.Generic;
using UnityEngine;

public class BuildingHealthUI : MonoBehaviour
{
	[SerializeField]
	private BuildingHealthItemUI itemPrefab;

	[SerializeField]
	private RectTransform itemContainer;

	public GameObject poopWarningContainer;

	public GameObject clinicWarningContainer;

	private List<BuildingHealthItemUI> items = new List<BuildingHealthItemUI>();

	private Building building;

	private Home home;

	public Sprite normalBG;

	public Sprite failBG;

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
		for (int i = items.Count; i < home.diet.Length; i++)
		{
			AddItem();
		}
		int num = 0;
		for (int j = 0; j < home.diet.Length; j++)
		{
			if (j <= 0 || home.diet[j - 1].type != home.diet[j].type)
			{
				Home.Consumable consumable = home.diet[j];
				BuildingHealthItemUI buildingHealthItemUI = items[num];
				buildingHealthItemUI.gameObject.SetActive(value: true);
				HappinessModifierSystem.HappinessModifier happinessModifier = HappinessModifierSystem.happinessModifierMap[consumable.happinessModifierID];
				int num2 = consumable.type;
				if (home.resourcesStored.Get(num2) <= 0 && consumable.altType != -1)
				{
					num2 = consumable.altType;
					happinessModifier = HappinessModifierSystem.happinessModifierMap[consumable.altHappinessModifierID];
				}
				int a = home.resourcesStored.Get(num2);
				int num3 = home.resourceMaxStorage.Get(num2);
				FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[num2];
				buildingHealthItemUI.iconImg.sprite = resourceDef.texture;
				buildingHealthItemUI.storageTMP.text = $"{Mathff.Min(a, num3)} / {num3}";
				bool flag = home.resourcesStored.Get(num2) > 0;
				buildingHealthItemUI.successGradient.color = (flag ? GameUI.inst.successColor : GameUI.inst.failColor);
				buildingHealthItemUI.circleBG.sprite = (flag ? normalBG : failBG);
				Util.SetActive(buildingHealthItemUI.consumeCheck, flag);
				Util.SetActive(buildingHealthItemUI.consumeAbort, !flag);
				buildingHealthItemUI.tooltipHook.SetTerm(flag ? happinessModifier.positiveTerm : happinessModifier.negativeTerm);
				num++;
			}
		}
		for (int k = num; k < items.Count; k++)
		{
			Util.SetActive(items[k].gameObject, active: false);
		}
		bool poopNearby = false;
		building.ForEachTileInBounds((int x, int z, Cell c) =>
		{
			CellInfluence cellInfluenceDataClamped = World.inst.GetCellInfluenceDataClamped(x, z);
			for (int l = 0; l < cellInfluenceDataClamped.radiusBonuses.Count; l++)
			{
				if (cellInfluenceDataClamped.radiusBonuses.data[l].residentialTileID == 235)
				{
					poopNearby = true;
				}
			}
		});
		Util.SetActive(poopWarningContainer, poopNearby);
		Util.SetActive(clinicWarningContainer, Player.inst.Workers.Count >= 200 && !home.IsFarmVilla() && !home.IsWithinClinicRadius(out var _));
	}

	public BuildingHealthItemUI AddItem()
	{
		BuildingHealthItemUI buildingHealthItemUI = Object.Instantiate(itemPrefab, itemContainer, worldPositionStays: false);
		items.Add(buildingHealthItemUI);
		return buildingHealthItemUI;
	}
}
