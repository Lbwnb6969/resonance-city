using System.Collections.Generic;
using System.Linq;
using Assets;
using Assets.Interface;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using cakeslice;

public class BuildingLogisticsUI : MonoBehaviour
{
	public static BuildingLogisticsUI inst;

	[SerializeField]
	private BuildingLogisticsRequestItemUI requestPrefab;

	[SerializeField]
	private BuildingLogisticsSourceItemUI sourcePrefab;

	[SerializeField]
	private RectTransform resourceContainer;

	[SerializeField]
	private RectTransform sourceContainer;

	[SerializeField]
	private Button sampleBtn;

	[SerializeField]
	private Button clearAmountsBtn;

	[SerializeField]
	private GameObject logisticsObj;

	public GameObject supplierLock;

	public GameObject errorDisplay;

	public TextMeshProUGUI errorTxt;

	private int requestItemPoolCount;

	private ArrayExt<BuildingLogisticsRequestItemUI> requestItemPool = new ArrayExt<BuildingLogisticsRequestItemUI>(32);

	private int sourceItemPoolCount;

	private ArrayExt<BuildingLogisticsSourceItemUI> sourceItemPool = new ArrayExt<BuildingLogisticsSourceItemUI>(32);

	private ObjectHighlighter objHightlight;

	private int colorIdx;

	private int highlightIdx = -1;

	private Building building;

	private Stockpile stockpile;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		_ = isVisible;
		Util.SetActive(gameObject, v);
		isVisible = v;
	}

	public void ToggleLogistics(bool b)
	{
		if (!b)
		{
			Util.SetActive(logisticsObj, active: false);
			if (GameUI.inst.currCursorMode is SelectLogisticsSourceMode)
			{
				GameUI.inst.ReturnToDefaultCursorMode();
			}
			return;
		}
		RefreshVisuals();
		Util.SetActive(logisticsObj, active: true);
		SfxSystem.PlayUiSelect();
		if (building != null)
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building);
			GameUI.inst.sourceLogisticsCursorMode.currLogistic = logisticsForBuilding;
			LogisticsManager.inst.TryAnimateArrowsForLogistic(logisticsForBuilding);
		}
	}

	private void Awake()
	{
		inst = this;
		objHightlight = new ObjectHighlighter
		{
			go = gameObject
		};
		objHightlight.outlines.Add(new cakeslice.Outline());
		objHightlight.outlines.Add(new cakeslice.Outline());
		sampleBtn.onClick.AddListener(() =>
		{
			if (building != null)
			{
				GameUI.inst.SetCursorModeSelectLogisticsSource();
			}
		});
		clearAmountsBtn.onClick.AddListener(() =>
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building);
			KeyValuePair<int, int>[] array = logisticsForBuilding.requestAmt.ToArray();
			for (int i = 0; i < array.Length; i++)
			{
				logisticsForBuilding.requestAmt[array[i].Key] = 0;
			}
			RefreshVisuals();
		});
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (stockpile = b.GetComponent<Stockpile>()) == null)
		{
			SetVisibility(v: false);
			return;
		}
		building = b;
		RefreshVisuals();
		SetVisibility(v: true);
		Util.SetActive(logisticsObj, active: false);
	}

	public void OnDeselected()
	{
		building = null;
		stockpile = null;
		SetVisibility(v: false);
		if (GameUI.inst.currCursorMode == GameUI.inst.routeLogisticsCursorMode || GameUI.inst.currCursorMode == GameUI.inst.sourceLogisticsCursorMode)
		{
			GameUI.inst.ReturnToDefaultCursorMode();
		}
		else
		{
			LogisticArrow.HideArrows();
		}
	}

	private void Update()
	{
		if (!isVisible || building == null || stockpile == null)
		{
			return;
		}
		if (highlightIdx != -1)
		{
			objHightlight.SetOutlineImmediate(colorIdx);
		}
		LogisticArrow.DeferHideArrows();
		LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building);
		LogisticVehicleTracker.inst.TrackCartsForLogisticStorage(logisticsForBuilding, doHighlight: true);
		LogisticsManager.inst.TryAnimateArrowsForLogistic(logisticsForBuilding);
		string text = "";
		if (logisticsForBuilding.HasRequest())
		{
			if (logisticsForBuilding.sourceBuildings.Count <= 0)
			{
				text = LocalizationManager.GetTranslation("workerui_logistics_addsuppliersfirst");
			}
			else
			{
				bool flag = false;
				for (int i = 0; i < LogisticsManager.inst.logisticCarts.Count; i++)
				{
					if (LogisticsManager.inst.logisticCarts.data[i].vehicle.HasRouteFor(building))
					{
						flag = true;
						break;
					}
				}
				for (int j = 0; j < ShipSystem.inst.ships.Count; j++)
				{
					TransportShip component = ShipSystem.inst.ships.data[j].GetComponent<TransportShip>();
					if ((bool)component && component.vehicle.HasRouteFor(building))
					{
						flag = true;
						break;
					}
				}
				if (!flag)
				{
					text = LocalizationManager.GetTranslation("workerui_logistics_assingcart");
				}
				foreach (KeyValuePair<int, int> item in logisticsForBuilding.requestAmt)
				{
					if (((IResourceStorage)stockpile).MaxStorageFor(item.Key) < item.Value && FreeResourceSystem.inst.resourceDefMap.TryGetValue(item.Key, out var value))
					{
						text = string.Format(LocalizationManager.GetTranslation("workerui_logistics_insufficientstorage"), $"<link={value.ID}>" + value.iconName + "</link> ");
						break;
					}
				}
			}
		}
		Util.SetActive(errorDisplay, text.Length > 0);
		errorTxt.text = text;
	}

	public void RefreshVisuals()
	{
		LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(this.building);
		requestItemPoolCount = 0;
		for (int i = 0; i < stockpile.ValidResourceTypes.Length; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[stockpile.ValidResourceTypes[i]];
			BuildingLogisticsRequestItemUI requestItem = GetRequestItem();
			requestItem.rID = resourceDef.ID;
			requestItem.iconRI.sprite = resourceDef.texture;
			requestItem.amountInput.SetTextWithoutNotify(logisticsForBuilding.requestAmt.TryGetValue(resourceDef.ID, out var value) ? value.ToString() : "0");
			Util.SetActive(requestItem.gameObject, active: true);
		}
		HideAccessRequestItems();
		sourceItemPoolCount = 0;
		for (int j = 0; j < logisticsForBuilding.sourceBuildings.Count; j++)
		{
			Building building = logisticsForBuilding.sourceBuildings[j];
			BuildingLogisticsSourceItemUI sourceItem = GetSourceItem();
			sourceItem.iconRI.sprite = building.sprite;
			sourceItem.titleTMP.text = building.CustomName;
			Util.SetActive(sourceItem.gameObject, active: true);
		}
		HideAccessSourceItems();
		Util.SetActive(supplierLock, !logisticsForBuilding.HasRequest() && logisticsForBuilding.sourceBuildings.Count == 0);
	}

	private void OnRequestActiveChanged(bool isActive, BuildingLogisticsRequestItemUI itemUI)
	{
		if (isActive)
		{
			SfxSystem.PlayUiSelect();
		}
		else
		{
			SfxSystem.PlayUiCancel();
		}
		LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building);
		if (!logisticsForBuilding.isActive.TryAdd(itemUI.rID, isActive))
		{
			logisticsForBuilding.isActive[itemUI.rID] = isActive;
		}
	}

	private void OnRequestAmountChanged(string str, BuildingLogisticsRequestItemUI itemUI)
	{
		LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building);
		if (int.TryParse(str, out var result) || str == string.Empty)
		{
			result = Mathff.Max(0, result);
			if (!logisticsForBuilding.requestAmt.TryAdd(itemUI.rID, result))
			{
				logisticsForBuilding.requestAmt[itemUI.rID] = result;
			}
		}
		itemUI.amountInput.SetTextWithoutNotify(logisticsForBuilding.requestAmt.GetValueOrDefault(itemUI.rID).ToString());
		SfxSystem.PlayUiSelect();
	}

	public BuildingLogisticsRequestItemUI GetRequestItem()
	{
		if (requestItemPoolCount == requestItemPool.Count)
		{
			BuildingLogisticsRequestItemUI item = Object.Instantiate(requestPrefab, resourceContainer);
			item.amountInput.onSelect.AddListener((string str) =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = false;
			});
			item.amountInput.onEndEdit.AddListener((string str) =>
			{
				OnRequestAmountChanged(str, item);
				GameState.inst.AlphaNumericHotkeysEnabled = true;
				RefreshVisuals();
			});
			requestItemPool.Add(item);
		}
		return requestItemPool.data[requestItemPoolCount++];
	}

	private void HideAccessRequestItems()
	{
		for (int num = requestItemPool.Count - 1; num >= requestItemPoolCount; num--)
		{
			Util.SetActive(requestItemPool.data[num].gameObject, active: false);
		}
	}

	public void OnRemoveSourceClicked(int idx)
	{
		LogisticsManager.inst.RemoveSourceFromBuilding(building, idx);
		RefreshVisuals();
		if (highlightIdx == idx)
		{
			if (idx == sourceItemPoolCount)
			{
				highlightIdx = -1;
				colorIdx = 0;
			}
			else
			{
				OnSourcePointerEnter(idx);
			}
		}
		SfxSystem.PlayUiCancel();
	}

	public void OnFocusSourceClicked(int idx)
	{
		Building building = LogisticsManager.inst.GetLogisticsForBuilding(this.building).sourceBuildings[idx];
		Cam.inst.SetDesiredTrackingPos(building.Center());
	}

	public void OnSourcePointerEnter(int idx)
	{
		highlightIdx = idx;
		LogisticsManager.inst.GetLogisticsForBuilding(building);
	}

	public void OnSourcePointerExit(int pIdx)
	{
		if (pIdx == highlightIdx)
		{
			highlightIdx = -1;
		}
	}

	public BuildingLogisticsSourceItemUI GetSourceItem()
	{
		if (sourceItemPoolCount == sourceItemPool.Count)
		{
			BuildingLogisticsSourceItemUI buildingLogisticsSourceItemUI = Object.Instantiate(sourcePrefab, sourceContainer);
			int p = sourceItemPoolCount;
			buildingLogisticsSourceItemUI.removeBtn.onClick.AddListener(() =>
			{
				OnRemoveSourceClicked(p);
			});
			buildingLogisticsSourceItemUI.focusBtn.onClick.AddListener(() =>
			{
				OnFocusSourceClicked(p);
			});
			EventTrigger.Entry entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerEnter;
			entry.callback.AddListener((BaseEventData eventData) =>
			{
				OnSourcePointerEnter(p);
			});
			buildingLogisticsSourceItemUI.onHoverItemTrigger.triggers.Add(entry);
			entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerExit;
			entry.callback.AddListener((BaseEventData eventData) =>
			{
				OnSourcePointerExit(p);
			});
			buildingLogisticsSourceItemUI.onHoverItemTrigger.triggers.Add(entry);
			entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerEnter;
			entry.callback.AddListener((BaseEventData eventData) =>
			{
				colorIdx = 2;
			});
			buildingLogisticsSourceItemUI.onHoverRemoveTrigger.triggers.Add(entry);
			entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerExit;
			entry.callback.AddListener((BaseEventData eventData) =>
			{
				colorIdx = 0;
			});
			buildingLogisticsSourceItemUI.onHoverRemoveTrigger.triggers.Add(entry);
			sourceItemPool.Add(buildingLogisticsSourceItemUI);
		}
		return sourceItemPool.data[sourceItemPoolCount++];
	}

	private void HideAccessSourceItems()
	{
		for (int num = sourceItemPool.Count - 1; num >= sourceItemPoolCount; num--)
		{
			Util.SetActive(sourceItemPool.data[num].gameObject, active: false);
		}
	}
}
