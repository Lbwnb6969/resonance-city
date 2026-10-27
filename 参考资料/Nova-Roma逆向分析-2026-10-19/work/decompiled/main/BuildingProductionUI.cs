using System;
using System.Collections.Generic;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingProductionUI : MonoBehaviour
{
	public struct CustomProductionItem
	{
		public enum CustomType
		{
			TerrainResource,
			Infinite,
			Resource
		}

		public Sprite icon;

		public CustomType type;

		public int amount;

		public int maxStorage;

		public int currentStorage;

		public string locTerm;

		public bool hideBottom;

		public bool hideConsumption;
	}

	[SerializeField]
	private Image fillBar;

	[SerializeField]
	private RectTransform noStaffDisable;

	[SerializeField]
	private RectTransform costContainer;

	[SerializeField]
	private RectTransform resultContainer;

	[SerializeField]
	private RectTransform infoContainer;

	[SerializeField]
	private TextMeshProUGUI bonusTMP;

	[SerializeField]
	private TextMeshProUGUI producingTMP;

	[SerializeField]
	private TextMeshProUGUI efficiencyTMP;

	[SerializeField]
	private TextMeshProUGUI consumingTMP;

	[SerializeField]
	private BuildingProductionItemUI itemPrefab;

	private List<BuildingProductionItemUI> costItems = new List<BuildingProductionItemUI>(32);

	private int resultPoolCount;

	private List<BuildingProductionItemUI> resultItemPool = new List<BuildingProductionItemUI>(32);

	private Building building;

	private IProductionInfo productionInfo;

	private Dictionary<string, RadiusBonusProduction> bonusMap = new Dictionary<string, RadiusBonusProduction>();

	private Dictionary<string, RadiusBonusBuildingProduction> bonusBuildingMap = new Dictionary<string, RadiusBonusBuildingProduction>();

	public Sprite successBG;

	public Sprite failBG;

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (productionInfo = b.GetComponent<IProductionInfo>()) == null || b.categoryHash == World.taxOfficeHash)
		{
			SetVisibility(isVisible: false);
			return;
		}
		building = b;
		RefreshVisuals();
		SetVisibility(isVisible: true);
	}

	public void OnDeselected()
	{
		building = null;
		productionInfo = null;
	}

	private void Update()
	{
		if (!productionInfo.IsNull() && !(building == null))
		{
			RefreshVisuals();
		}
	}

	public static void UpdateBonusMapForCell(Dictionary<string, RadiusBonusProduction> _bonusMap, Dictionary<string, RadiusBonusBuildingProduction> _bonusBuildingMap, int x, int z)
	{
		CellProductionInfluence cellProductionInfluenceDataClamped = World.inst.GetCellProductionInfluenceDataClamped(x, z);
		for (int i = 0; i < cellProductionInfluenceDataClamped.radiusBonuses.Count; i++)
		{
			if (!cellProductionInfluenceDataClamped.radiusBonuses[i].applied)
			{
				continue;
			}
			string uniqueName = cellProductionInfluenceDataClamped.radiusBonuses[i].b.UniqueName;
			if (_bonusMap.TryGetValue(uniqueName, out var value))
			{
				if (value.GetBonus() < cellProductionInfluenceDataClamped.radiusBonuses[i].GetBonus())
				{
					_bonusMap.Remove(uniqueName);
					_bonusMap.Add(uniqueName, cellProductionInfluenceDataClamped.radiusBonuses[i]);
				}
			}
			else
			{
				_bonusMap.Add(uniqueName, cellProductionInfluenceDataClamped.radiusBonuses[i]);
			}
		}
		for (int j = 0; j < cellProductionInfluenceDataClamped.radiusBonusesBuilding.Count; j++)
		{
			if (!cellProductionInfluenceDataClamped.radiusBonusesBuilding[j].applied)
			{
				continue;
			}
			string uniqueName2 = cellProductionInfluenceDataClamped.radiusBonusesBuilding[j].b.UniqueName;
			if (_bonusBuildingMap.TryGetValue(uniqueName2, out var value2))
			{
				if (value2.GetBonus() < cellProductionInfluenceDataClamped.radiusBonusesBuilding[j].GetBonus())
				{
					_bonusBuildingMap.Remove(uniqueName2);
					_bonusBuildingMap.Add(uniqueName2, cellProductionInfluenceDataClamped.radiusBonusesBuilding[j]);
				}
			}
			else
			{
				_bonusBuildingMap.Add(uniqueName2, cellProductionInfluenceDataClamped.radiusBonusesBuilding[j]);
			}
		}
	}

	private void RefreshVisuals()
	{
		Util.SetActive(noStaffDisable, building.WorkersAllocated <= 0);
		ResourceAmount cost = productionInfo.GetCost();
		CustomProductionItem[] customCost = productionInfo.GetCustomCost();
		CustomProductionItem[] customResult = productionInfo.GetCustomResult();
		bonusMap.Clear();
		bonusBuildingMap.Clear();
		building.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			UpdateBonusMapForCell(bonusMap, bonusBuildingMap, x, z);
		});
		YieldProducer component = building.GetComponent<YieldProducer>();
		YieldProducerSeason component2 = building.GetComponent<YieldProducerSeason>();
		int rID = -1;
		if (component != null)
		{
			rID = component.YieldType;
		}
		if (component2 != null)
		{
			rID = component2.YieldType;
		}
		if ((bool)building.GetComponent<FishingHut>())
		{
			rID = 8;
		}
		string text = productionInfo.GetCustomText();
		int num = productionInfo.GetTotalBonus();
		foreach (KeyValuePair<string, RadiusBonusProduction> item in bonusMap)
		{
			RadiusBonusProduction value = item.Value;
			if (value.b.CategoryName == "temple" && value.BoostsResource(rID))
			{
				text = text + Environment.NewLine + string.Format(ScriptLocalization.workerui_productionui_templebonus, (value.GetBonus() > 0) ? value.Bonus.ToString() : ("<color=red>" + value.GetBonus() + "</color>"));
				num += value.GetBonus();
			}
		}
		foreach (KeyValuePair<string, RadiusBonusBuildingProduction> item2 in bonusBuildingMap)
		{
			RadiusBonusBuildingProduction value2 = item2.Value;
			if (!string.IsNullOrEmpty(value2.descTerm))
			{
				text = text + Environment.NewLine + string.Format(LocalizationManager.GetTranslation(value2.descTerm), (value2.GetBonus() > 0) ? value2.Bonus.ToString() : ("<color=red>" + value2.GetBonus() + "</color>"));
				num += value2.GetBonus();
			}
		}
		bonusTMP.text = text;
		bonusTMP.enabled = !string.IsNullOrEmpty(text);
		int num2 = 0;
		if (customCost != null)
		{
			for (int num3 = 0; num3 < customCost.Length; num3++)
			{
				while (num2 >= costItems.Count)
				{
					AddCostItem();
				}
				BuildingProductionItemUI buildingProductionItemUI = costItems[num2];
				buildingProductionItemUI.gameObject.SetActive(value: true);
				CustomProductionItem customProductionItem = customCost[num3];
				buildingProductionItemUI.icon.sprite = customProductionItem.icon;
				bool flag = customProductionItem.type != CustomProductionItem.CustomType.Resource || customProductionItem.currentStorage >= customProductionItem.amount;
				buildingProductionItemUI.consumeContainer.SetActive(!customProductionItem.hideConsumption);
				if (!customProductionItem.hideConsumption)
				{
					buildingProductionItemUI.consumeCheck.SetActive(flag);
					buildingProductionItemUI.consumeAbort.SetActive(!flag);
					buildingProductionItemUI.circleBG.sprite = (flag ? successBG : failBG);
					buildingProductionItemUI.successGradient.color = (flag ? GameUI.inst.successColor : GameUI.inst.failColor);
				}
				buildingProductionItemUI.amtTMP.text = ((customProductionItem.type != CustomProductionItem.CustomType.Resource) ? "" : (customProductionItem.amount + "x")) ?? "";
				buildingProductionItemUI.quantityContainer.SetActive(customProductionItem.type == CustomProductionItem.CustomType.Resource && customProductionItem.amount > 0);
				string text2 = $"{customProductionItem.currentStorage}/{customProductionItem.maxStorage}";
				if (customProductionItem.type != CustomProductionItem.CustomType.Resource)
				{
					text2 = ((customProductionItem.type != CustomProductionItem.CustomType.Infinite && customProductionItem.maxStorage != int.MaxValue) ? $"{customProductionItem.maxStorage}" : "<size=200%>∞");
				}
				buildingProductionItemUI.storageTMP.text = text2;
				buildingProductionItemUI.storageContainer.SetActive(!customCost[num3].hideBottom);
				buildingProductionItemUI.tooltipHook.SetTerm(customProductionItem.locTerm);
				num2++;
			}
		}
		if ((object)cost != null)
		{
			for (int num4 = 0; num4 < cost.resources.Count; num4++)
			{
				while (num2 >= costItems.Count)
				{
					AddCostItem();
				}
				Resource resource = cost.resources[num4];
				FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[resource.resourceID];
				BuildingProductionItemUI buildingProductionItemUI2 = costItems[num2];
				buildingProductionItemUI2.gameObject.SetActive(value: true);
				buildingProductionItemUI2.icon.sprite = resourceDef.texture;
				buildingProductionItemUI2.amtTMP.text = $"{resource.Amount}x";
				int inputStorage = productionInfo.GetInputStorage(resource.resourceID);
				bool flag2 = inputStorage >= cost.Get(resource.resourceID);
				if (flag2)
				{
					buildingProductionItemUI2.storageTMP.text = $"{inputStorage} / {productionInfo.GetInputMaxStorage(resource.resourceID)}";
				}
				else
				{
					buildingProductionItemUI2.storageTMP.text = $"<color=red>{inputStorage}</color> / {productionInfo.GetInputMaxStorage(resource.resourceID)}";
				}
				buildingProductionItemUI2.consumeCheck.SetActive(flag2);
				buildingProductionItemUI2.consumeAbort.SetActive(!flag2);
				buildingProductionItemUI2.circleBG.sprite = (flag2 ? successBG : failBG);
				buildingProductionItemUI2.successGradient.color = (flag2 ? GameUI.inst.successColor : GameUI.inst.failColor);
				buildingProductionItemUI2.consumeContainer.SetActive(value: true);
				buildingProductionItemUI2.storageContainer.SetActive(value: true);
				buildingProductionItemUI2.quantityContainer.SetActive(value: true);
				buildingProductionItemUI2.tooltipHook.SetTerm(resourceDef.name);
				num2++;
			}
		}
		for (; num2 < costItems.Count; num2++)
		{
			costItems[num2].gameObject.SetActive(value: false);
		}
		resultPoolCount = 0;
		if (customResult != null)
		{
			for (int num5 = 0; num5 < customResult.Length; num5++)
			{
				CustomProductionItem customProductionItem2 = customResult[num5];
				BuildingProductionItemUI resultItem = GetResultItem();
				resultItem.gameObject.SetActive(value: true);
				resultItem.icon.sprite = customProductionItem2.icon;
				resultItem.amtTMP.text = string.Format((num > 0) ? "<color=green>{0}</color>" : "{0}", $"{customProductionItem2.amount + num}x");
				resultItem.quantityContainer.SetActive(customProductionItem2.type == CustomProductionItem.CustomType.Resource && customProductionItem2.amount > 0);
				resultItem.storageContainer.SetActive(productionInfo.ShowResultStorage() && !customProductionItem2.hideBottom);
				resultItem.storageTMP.text = $"{customProductionItem2.currentStorage} / {customProductionItem2.maxStorage}";
				resultItem.tooltipHook.SetTerm(customProductionItem2.locTerm);
			}
		}
		for (int num6 = 0; num6 < FreeResourceSystem.inst.resourceDefs.Count; num6++)
		{
			FreeResourceSystem.ResourceDef resourceDef2 = FreeResourceSystem.inst.resourceDefs[num6];
			int result = productionInfo.GetResult(resourceDef2.ID);
			if (result > 0)
			{
				BuildingProductionItemUI resultItem2 = GetResultItem();
				resultItem2.gameObject.SetActive(value: true);
				resultItem2.icon.sprite = resourceDef2.texture;
				string format = "{0}x";
				if (result + num <= 0)
				{
					format = "<color=#773C00>{0}x</color>";
				}
				else if (num > 0)
				{
					format = "<color=green>{0}x</color>";
				}
				resultItem2.amtTMP.text = string.Format(format, Mathff.Max(0, result + num));
				resultItem2.quantityContainer.SetActive(value: true);
				resultItem2.storageContainer.SetActive(productionInfo.ShowResultStorage());
				resultItem2.storageTMP.text = $"{productionInfo.GetOutputStorage(resourceDef2.ID)} / {productionInfo.GetOutputMaxStorage(resourceDef2.ID)}";
				Util.SetActive(resultItem2.successGradient.gameObject, active: false);
				resultItem2.circleBG.sprite = successBG;
				resultItem2.tooltipHook.SetTerm(resourceDef2.name);
			}
		}
		for (int num7 = resultItemPool.Count - 1; num7 >= resultPoolCount; num7--)
		{
			Util.SetActive(resultItemPool[num7].gameObject, active: false);
		}
		float progress = productionInfo.GetProgress();
		progress = Mathf.Lerp(0f, 0.95f, progress);
		progress = (float)(int)(progress * 10f) / 10f;
		fillBar.fillAmount = progress;
		float num8 = 0.85f;
		float num9 = WorkerUI.inst.commuteUI.GetCommuteFactor(building);
		if (num9 == -1f)
		{
			num9 = num8;
		}
		if (component2 != null)
		{
			num9 = (num8 = 1f);
		}
		float workerPercent = building.GetWorkerPercent();
		bool flag3 = ShowProductionDetails();
		if ((component != null || component2 != null) & flag3)
		{
			float num10 = ((component != null) ? component.CyclesPerYear() : 1f);
			float num11 = num10 * workerPercent;
			string text3 = "";
			text3 = text3 + "<size=12>" + ScriptLocalization.workerui_productionui_producing_heading + "</size> ";
			for (int num12 = 0; num12 < FreeResourceSystem.inst.resourceDefs.Count; num12++)
			{
				FreeResourceSystem.ResourceDef resourceDef3 = FreeResourceSystem.inst.resourceDefs[num12];
				int result2 = productionInfo.GetResult(resourceDef3.ID);
				if (result2 > 0)
				{
					text3 += Environment.NewLine;
					int num13 = (int)((float)(result2 + num) * num10 * num8);
					int a = (int)((float)(result2 + num) * num11 * num9);
					text3 += string.Format(" {2} <color=#b5cbdb>{0} / {1}</color>", Mathff.Min(a, num13), num13, $"<link={resourceDef3.ID}>{FreeResourceSystem.inst.resourceDefMap[resourceDef3.ID].iconName}</link>");
				}
			}
			if (component != null && component.toolBonusOn)
			{
				text3 = text3 + "\n" + string.Format(ScriptLocalization.workerui_productionui_toolbonus, "<color=green><b>+25%</b></color>") + "\n";
			}
			producingTMP.text = text3;
			producingTMP.enabled = true;
			bool flag4 = false;
			string text4 = "<size=12>" + ScriptLocalization.workerui_productionui_consuming_heading + "</size> ";
			if ((object)cost != null)
			{
				for (int num14 = 0; num14 < cost.resources.Count; num14++)
				{
					text4 += Environment.NewLine;
					flag4 = true;
					int resourceID = cost.resources[num14].resourceID;
					int a2 = (int)((float)cost.resources[num14].Amount * num11 * num9);
					int num15 = (int)((float)cost.resources[num14].Amount * num10 * num8);
					text4 += string.Format(" {2} <color=#b5cbdb>{0} / {1}</color>", Mathff.Min(a2, num15), num15, $"<link={resourceID}>{FreeResourceSystem.inst.resourceDefMap[resourceID].iconName}</link>");
				}
			}
			if (customCost != null)
			{
				for (int num16 = 0; num16 < customCost.Length; num16++)
				{
					if (customCost[num16].type == CustomProductionItem.CustomType.Resource)
					{
						flag4 = true;
						int a3 = (int)((float)customCost[num16].amount * num11 * num9);
						int num17 = (int)((float)customCost[num16].amount * num10 * num8);
						text4 += Environment.NewLine;
						text4 += string.Format(" {2} <color=#b5cbdb>{0} / {1}</color>", Mathff.Min(a3, num17), num17, LocalizationManager.GetTranslation(customCost[num16].locTerm));
					}
				}
			}
			text4 += "\n \n";
			consumingTMP.text = text4;
			consumingTMP.enabled = flag4;
		}
		else
		{
			producingTMP.enabled = false;
			consumingTMP.enabled = false;
		}
		if (flag3)
		{
			efficiencyTMP.enabled = false;
			infoContainer.gameObject.SetActive(value: true);
		}
		else
		{
			infoContainer.gameObject.SetActive(value: false);
		}
	}

	private bool ShowProductionDetails()
	{
		Field component = building.GetComponent<Field>();
		if (component != null)
		{
			return component.fertilityBonus > 0;
		}
		Orchard component2 = building.GetComponent<Orchard>();
		if (component2 != null)
		{
			return component2.fertilityBonus > 0;
		}
		return true;
	}

	public BuildingProductionItemUI AddCostItem()
	{
		BuildingProductionItemUI buildingProductionItemUI = UnityEngine.Object.Instantiate(itemPrefab, costContainer, worldPositionStays: false);
		costItems.Add(buildingProductionItemUI);
		return buildingProductionItemUI;
	}

	public BuildingProductionItemUI GetResultItem()
	{
		if (resultPoolCount >= resultItemPool.Count)
		{
			BuildingProductionItemUI buildingProductionItemUI = UnityEngine.Object.Instantiate(itemPrefab, resultContainer, worldPositionStays: false);
			buildingProductionItemUI.consumeContainer.SetActive(value: false);
			resultItemPool.Add(buildingProductionItemUI);
		}
		return resultItemPool[resultPoolCount++];
	}
}
