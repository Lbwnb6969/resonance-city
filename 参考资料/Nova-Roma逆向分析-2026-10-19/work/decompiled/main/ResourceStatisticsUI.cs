using System;
using System.Collections.Generic;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ResourceStatisticsUI : MonoBehaviour
{
	public static ResourceStatisticsUI inst;

	[SerializeField]
	public ResourceStatisticItemUI itemPrefab;

	[SerializeField]
	public RectTransform container;

	[SerializeField]
	public RectTransform edibleContainer;

	[SerializeField]
	public RectTransform inedibleContainer;

	[SerializeField]
	public RectTransform ghostPrefab;

	[SerializeField]
	public RectTransform ghostEdibleContainer;

	[SerializeField]
	public RectTransform ghostInedibleContainer;

	[SerializeField]
	private RectTransform tooltipRect;

	[SerializeField]
	private Image tooltipIcon;

	[SerializeField]
	private TextMeshProUGUI tooltipNameTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipCountTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipMaxCountTMP;

	[SerializeField]
	private GameObject tooltipMaxDivider;

	[SerializeField]
	private Localize tooltipReportTitleLocalize;

	[SerializeField]
	private TextMeshProUGUI tooltipDescriptionTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipProductionTMP;

	[SerializeField]
	private RectTransform tooltipProductionRectT;

	[SerializeField]
	private TextMeshProUGUI tooltipConsumptionTMP;

	[SerializeField]
	private RectTransform tooltipConsumptionRectT;

	[SerializeField]
	private TextMeshProUGUI tooltipTotalChangeTMP;

	[SerializeField]
	private RectTransform tooltipLastYearReportRectT;

	[SerializeField]
	private RectTransform tooltipNoReportRectT;

	[SerializeField]
	private TextMeshProUGUI tooltipStorageTMP;

	[SerializeField]
	private GameObject constructionObj;

	[SerializeField]
	private TextMeshProUGUI constructionTMP;

	[SerializeField]
	private ToggleGroup toggleGroup;

	private List<ResourceStatisticItemUI> items = new List<ResourceStatisticItemUI>(32);

	private ResourceStatisticItemUI targetItemUI;

	private int tooltipLandmass = -1;

	public List<int> edibleResources;

	public List<int> inedibleResources;

	public List<int> alwaysShowResources;

	private ResourceStatistics.Statistics GoldConsumption;

	private ResourceStatistics.Statistics GoldProduction;

	private ResourceStatistics.Statistics ConstructionConsumption;

	private string hexPositive = "#7ecd56";

	private string hexNegative = "#ff6863";

	private string hexExclamation = "#FFE12E";

	private EventHandler<NewYearEvent> newYearHandler;

	public ResourceAmount lastAmount = new ResourceAmount();

	private Vector3[] corners = new Vector3[4];

	private bool dirty;

	private void Awake()
	{
		inst = this;
		GoldConsumption = default;
		GoldConsumption.amount = new ResourceAmount();
		GoldProduction = default;
		GoldProduction.amount = new ResourceAmount();
		if ((bool)FreeResourceSystem.inst)
		{
			List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
			for (int i = 0; i < resourceDefs.Count; i++)
			{
				OnResourceAdded(resourceDefs[i]);
				lastAmount.Set(resourceDefs[i].ID, -123);
			}
		}
		FreeResourceSystem.onResourceAdded = (FreeResourceSystem.OnAddResource)Delegate.Combine(FreeResourceSystem.onResourceAdded, new FreeResourceSystem.OnAddResource(OnResourceAdded));
		Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyUnlock);
		newYearHandler = Broadcast.NewYearEvent.Listen(OnNewYear);
		Player.onPlayerReset = (Player.OnPlayerEvent)Delegate.Combine(Player.onPlayerReset, new Player.OnPlayerEvent(Reset));
	}

	private void OnTechnologyUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		if (data.unlocked && data.unlockKey == "unlockkey_taxoffice")
		{
			OnEncounteredResource(4);
		}
	}

	private void OnDestroy()
	{
		FreeResourceSystem.onResourceAdded = (FreeResourceSystem.OnAddResource)Delegate.Remove(FreeResourceSystem.onResourceAdded, new FreeResourceSystem.OnAddResource(OnResourceAdded));
		Broadcast.NewYearEvent.Unlisten(OnNewYear);
		Player.onPlayerReset = (Player.OnPlayerEvent)Delegate.Remove(Player.onPlayerReset, new Player.OnPlayerEvent(Reset));
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		ResourceAmount focusedResources = Player.inst.FocusedResources;
		int focusedLandMass = Player.inst.FocusedLandMass;
		if (GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			focusedResources -= GameUI.inst.CurrPlacementMode.GetPlacementCost();
		}
		for (int i = 0; i < items.Count; i++)
		{
			int resourceID = items[i].resourceID;
			int b = focusedResources.Get(items[i].resourceID);
			items[i].currStorage = Mathff.Max(0, b);
			if (items[i].currStorage != lastAmount.Get(resourceID))
			{
				Util.SetAbbreviateLargeNumber(items[i].currStorage, items[i].countTMP);
				lastAmount.Set(resourceID, items[i].currStorage);
			}
			if (resourceID == 4)
			{
				items[i].maxStorage = Player.inst.PlayerLandmassOwner.MaxGoldStorage;
			}
			if (resourceID == 4 && items[i].currStorage > 0 && items[i].currStorage >= items[i].maxStorage)
			{
				Util.SetActive(items[i].exclamationObj, active: true);
			}
			else
			{
				Util.SetActive(items[i].exclamationObj, active: false);
			}
		}
		if (tooltipRect.gameObject.activeSelf && targetItemUI != null)
		{
			tooltipCountTMP.text = Mathff.Max(0, Player.inst.FocusedResources.Get(targetItemUI.resourceID)).ToString();
			if (focusedLandMass != -1)
			{
				int num = Player.inst.constructionPromisedResources[focusedLandMass].Get(targetItemUI.resourceID);
				Util.SetActive(constructionObj, num > 0);
				if (num > 0)
				{
					constructionTMP.text = string.Format(LocalizationManager.GetTranslation("resourcestatistics_tooltip_construction_description"), hexNegative, num);
				}
			}
		}
		if (dirty || tooltipLandmass != Player.inst.FocusedLandMass)
		{
			dirty = false;
			if (targetItemUI != null)
			{
				ShowTooltip(targetItemUI, isOn: true);
			}
		}
	}

	private void OnResourceAdded(FreeResourceSystem.ResourceDef def)
	{
		if (def.ID == 17)
		{
			return;
		}
		for (int i = 0; i < items.Count; i++)
		{
			if (items[i].resourceID == def.ID)
			{
				return;
			}
		}
		bool flag = edibleResources.Contains(def.ID);
		RectTransform parent = (flag ? edibleContainer : inedibleContainer);
		if (!flag)
		{
			_ = ghostInedibleContainer;
		}
		else
		{
			_ = ghostEdibleContainer;
		}
		ResourceStatisticItemUI item = UnityEngine.Object.Instantiate(itemPrefab, parent, worldPositionStays: false);
		item.resourceID = def.ID;
		item.icon.sprite = def.texture;
		item.toggle.group = toggleGroup;
		item.toggle.onValueChanged.AddListener((bool isOn) =>
		{
			ShowTooltip(item, isOn);
		});
		item.gameObject.SetActive(alwaysShowResources.Contains(def.ID) || ResourceStatistics.inst.playerEncounteredResources.Contains(def.ID));
		items.Add(item);
	}

	public void ShowTooltip(ResourceStatisticItemUI itemUI, bool isOn)
	{
		if (!isOn)
		{
			HideTooltip();
			return;
		}
		targetItemUI = itemUI;
		FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[itemUI.resourceID];
		tooltipRect.position = itemUI.rectT.position;
		tooltipRect.GetWorldCorners(corners);
		Vector2 vector = GUICamera.inst.cam.ViewportToWorldPoint(new Vector2(1f, 1f));
		vector.x--;
		if (corners[2].x > vector.x)
		{
			float num = vector.x - corners[2].x;
			Vector3 position = tooltipRect.position;
			position.x += num;
			tooltipRect.position = position;
		}
		tooltipNameTMP.text = LocalizationManager.GetTranslation(resourceDef.name);
		tooltipIcon.sprite = resourceDef.texture;
		int currStorage = targetItemUI.currStorage;
		tooltipCountTMP.text = currStorage.ToString();
		tooltipDescriptionTMP.text = LocalizationManager.GetTranslation(resourceDef.name + "_info_description");
		if (resourceDef.ID == 4)
		{
			tooltipReportTitleLocalize.SetTerm("islandui_resourceui_tooltip_currentprojection");
			tooltipMaxCountTMP.text = targetItemUI.maxStorage.ToString();
			tooltipMaxDivider.SetActive(value: true);
			tooltipMaxCountTMP.gameObject.SetActive(value: true);
			if (targetItemUI.currStorage > 0 && targetItemUI.currStorage >= targetItemUI.maxStorage)
			{
				string storageIsFull = ScriptLocalization.StorageIsFull;
				storageIsFull = storageIsFull.Insert(1, "</cspace>");
				storageIsFull = "<size=90%><cspace=-.3em><sprite color=" + hexExclamation + " name=icon_exclamation><color=" + hexExclamation + "></size>" + storageIsFull;
				tooltipStorageTMP.text = storageIsFull;
				Util.SetEnabled(tooltipStorageTMP, active: true);
			}
			else
			{
				Util.SetEnabled(tooltipStorageTMP, active: false);
			}
		}
		else
		{
			tooltipReportTitleLocalize.SetTerm("LastYearsReport");
			tooltipMaxDivider.SetActive(value: false);
			tooltipMaxCountTMP.gameObject.SetActive(value: false);
		}
		int num2 = (tooltipLandmass = Player.inst.FocusedLandMass);
		LandmassOwner landmassOwner = World.GetLandmassOwner(num2);
		if (num2 == -1 || landmassOwner == null)
		{
			tooltipNoReportRectT.gameObject.SetActive(value: true);
			tooltipLastYearReportRectT.gameObject.SetActive(value: false);
			tooltipRect.gameObject.SetActive(value: true);
			Util.SetEnabled(tooltipStorageTMP, tooltipStorageTMP.enabled && resourceDef.ID == 4);
			return;
		}
		if (resourceDef.ID == 4)
		{
			GoldProduction.Reset();
			GoldConsumption.Reset();
			for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
			{
				int num3 = Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i];
				ResourceStatistics.Statistics statistics = ResourceStatistics.inst.currProduction[num3];
				if (statistics.data != null)
				{
					foreach (KeyValuePair<string, ResourceAmount> datum in statistics.data)
					{
						if (datum.Value.Get(4) > 0)
						{
							GoldProduction.Add(datum.Key, 4, datum.Value.Get(4));
						}
					}
					GoldProduction.amount.Add(4, statistics.amount.Get(4));
				}
				ResourceStatistics.Statistics statistics2 = ResourceStatistics.inst.currConsumption[num3];
				if (statistics2.data == null)
				{
					continue;
				}
				foreach (KeyValuePair<string, ResourceAmount> datum2 in statistics2.data)
				{
					if (datum2.Value.Get(4) > 0)
					{
						GoldConsumption.Add(datum2.Key, 4, datum2.Value.Get(4));
					}
				}
				GoldConsumption.amount.Add(4, statistics2.amount.Get(4));
			}
			int num4 = UpdateVisualsForProductionConsumption(resourceDef.ID, GoldProduction, GoldConsumption);
			tooltipTotalChangeTMP.text = string.Format(ScriptLocalization.islandui_resourceui_tooltip_estimatedtotal, (num4 > 0) ? $"<color={hexPositive}>+ {num4}</color>" : $"<color={hexNegative}> {num4}</color>");
		}
		else
		{
			int num5 = UpdateVisualsForProductionConsumption(resourceDef.ID, ResourceStatistics.inst.prevProduction[num2], ResourceStatistics.inst.prevConsumption[num2]);
			tooltipTotalChangeTMP.text = string.Format(ScriptLocalization.TotalChangeLastYear, (num5 > 0) ? $"<color={hexPositive}>+ {num5}</color>" : $"<color={hexNegative}> {num5}</color>");
			Util.SetEnabled(tooltipStorageTMP, active: false);
		}
		Util.SetActive(tooltipRect.gameObject, active: true);
	}

	public void HideTooltip()
	{
		targetItemUI = null;
		tooltipRect.gameObject.SetActive(value: false);
		toggleGroup.SetAllTogglesOff();
	}

	public void OnEncounteredResource(int resourceID)
	{
		for (int i = 0; i < items.Count; i++)
		{
			if (items[i].resourceID == resourceID)
			{
				items[i].gameObject.SetActive(value: true);
			}
		}
	}

	public void OnNewYear(object sender, EventArgs args)
	{
		dirty = true;
	}

	private void Reset()
	{
		if (newYearHandler != null)
		{
			Broadcast.NewYearEvent.Unlisten(newYearHandler);
		}
		newYearHandler = Broadcast.NewYearEvent.Listen(OnNewYear);
		for (int i = 0; i < items.Count; i++)
		{
			items[i].gameObject.SetActive(alwaysShowResources.Contains(items[i].resourceID));
			items[i].currStorage = 0;
			items[i].maxStorage = 0;
			items[i].prevExclamationTime = float.MinValue;
			Util.SetActive(items[i].exclamationObj, active: false);
		}
	}

	private int UpdateVisualsForProductionConsumption(int rID, ResourceStatistics.Statistics productionStats, ResourceStatistics.Statistics consumptionStats, string suffix = "")
	{
		bool flag = productionStats.data == null || !productionStats.Contains(rID);
		bool flag2 = consumptionStats.data == null || !consumptionStats.Contains(rID);
		if (flag & flag2)
		{
			Util.SetActive(tooltipNoReportRectT.gameObject, active: true);
			Util.SetActive(tooltipLastYearReportRectT.gameObject, active: false);
			return 0;
		}
		Util.SetActive(tooltipNoReportRectT.gameObject, active: false);
		Util.SetActive(tooltipLastYearReportRectT.gameObject, active: true);
		if (flag)
		{
			Util.SetActive(tooltipProductionRectT.gameObject, active: false);
		}
		else
		{
			string text = "";
			foreach (KeyValuePair<string, ResourceAmount> datum in productionStats.data)
			{
				if (datum.Value.TryGetAmount(rID, out var amount) && amount >= 0)
				{
					text = text + $"<color={hexPositive}>+ {amount} </color>" + LocalizationManager.GetTranslation(datum.Key + suffix + "_production_info_explanation") + Environment.NewLine;
				}
			}
			tooltipProductionTMP.text = text;
			Util.SetActive(tooltipProductionRectT.gameObject, active: true);
		}
		if (flag2)
		{
			Util.SetActive(tooltipConsumptionRectT.gameObject, active: false);
		}
		else
		{
			string text2 = "";
			foreach (KeyValuePair<string, ResourceAmount> datum2 in consumptionStats.data)
			{
				if (datum2.Value.TryGetAmount(rID, out var amount2) && amount2 >= 0)
				{
					text2 = text2 + $"<color={hexNegative}>- {amount2} </color>" + LocalizationManager.GetTranslation(datum2.Key + suffix + "_consumption_info_explanation") + Environment.NewLine;
				}
			}
			tooltipConsumptionTMP.text = text2;
			Util.SetActive(tooltipConsumptionRectT.gameObject, active: true);
		}
		return productionStats.amount.Get(rID) - consumptionStats.amount.Get(rID);
	}
}
