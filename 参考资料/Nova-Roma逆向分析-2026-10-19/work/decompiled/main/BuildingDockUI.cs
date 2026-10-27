using System;
using System.Collections.Generic;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class BuildingDockUI : MonoBehaviour
{
	public static BuildingDockUI inst;

	[SerializeField]
	private GameObject allowDockObj;

	[SerializeField]
	private Toggle allowDockToggle;

	[SerializeField]
	private Toggle designateTradingPostToggle;

	[SerializeField]
	private GameObject tradingPostObj;

	[SerializeField]
	private GameObject ordersContainer;

	[SerializeField]
	private Button addOrderBtn;

	[SerializeField]
	private RectTransform itemsContainerRectT;

	[SerializeField]
	private MerchantOrderItemUI orderItemPrefab;

	private int orderUIPoolCount;

	private ArrayExt<MerchantOrderItemUI> orderUIPool = new ArrayExt<MerchantOrderItemUI>(32);

	[NonSerialized]
	private List<int> rIDLookup;

	private Dock dock;

	private Building building;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(allowDockObj, v);
		Util.SetActive(gameObject, v);
		if (v)
		{
			Util.SetActive(tradingPostObj, TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_tradingpost"));
		}
	}

	public void ToggleOrders(bool b)
	{
		if (!b)
		{
			Util.SetActive(ordersContainer, active: false);
			return;
		}
		Util.SetActive(ordersContainer, active: true);
		RefreshOrdersWindow();
		SfxSystem.PlayUiSelect();
	}

	private void Awake()
	{
		inst = this;
		addOrderBtn.onClick.AddListener(OnAddOrderClicked);
		allowDockToggle.onValueChanged.AddListener((bool b) =>
		{
			dock.disallowForeignMerchants = !b;
			if (dock.disallowForeignMerchants)
			{
				ArrayExt<ShipBase> ships = ShipSystem.inst.ships;
				for (int i = 0; i < ships.Count; i++)
				{
					MerchantShip merchantShip = ships.data[i] as MerchantShip;
					if (merchantShip != null && merchantShip.GetCurrentDock() == dock && merchantShip.status != MerchantShip.Status.Leaving)
					{
						merchantShip.Leave();
					}
				}
			}
		});
		designateTradingPostToggle.onValueChanged.AddListener((bool b) =>
		{
			dock.SetTradingPost(b);
		});
		allowDockToggle.onValueChanged.AddListener((bool b) =>
		{
			dock.disallowForeignMerchants = !b;
		});
	}

	private void Start()
	{
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		rIDLookup = new List<int>(resourceDefs.Count);
		for (int i = 0; i < resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			if (resourceDef.ID != 4 && resourceDef.ID != 17)
			{
				rIDLookup.Add(resourceDef.ID);
			}
		}
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || b.categoryHash != World.dockHash)
		{
			SetVisibility(v: false);
			return;
		}
		dock = b.GetComponent<Dock>();
		building = b;
		SetVisibility(v: true);
		Util.SetActive(ordersContainer, active: false);
		allowDockToggle.SetIsOnWithoutNotify(!dock.disallowForeignMerchants);
		designateTradingPostToggle.SetIsOnWithoutNotify(dock.IsTradingPost());
		Util.SetActive(ordersContainer, active: false);
	}

	public void OnDeselected()
	{
		building = null;
		dock = null;
	}

	private void Update()
	{
		if (building == null || dock == null)
		{
			SetVisibility(v: false);
		}
	}

	private void OnAddOrderClicked()
	{
		MerchantOrdersManager.inst.AddNewOrder(dock.bi.guid).resourceID = rIDLookup[0];
		RefreshOrdersWindow();
	}

	public void RemoveOrder(MerchantOrderItemUI itemUI)
	{
		int childIndex = Util.GetChildIndex(itemUI.transform, itemUI.transform.parent);
		MerchantOrdersManager.inst.RemoveOrderEntry(dock.bi.guid, childIndex);
		RefreshOrdersWindow();
	}

	private MerchantOrderItemUI GetOrderItemUI()
	{
		if (orderUIPoolCount == orderUIPool.Count)
		{
			MerchantOrderItemUI item = UnityEngine.Object.Instantiate(orderItemPrefab, itemsContainerRectT, worldPositionStays: false);
			item.transform.SetSiblingIndex(itemsContainerRectT.childCount - 2);
			orderUIPool.Add(item);
			item.orderType.onValueChanged.AddListener((int idx) =>
			{
				OnOrderTypeChanged(idx, item);
			});
			item.resourceType.onValueChanged.AddListener((int idx) =>
			{
				OnResourceTypeChanged(idx, item);
			});
			item.amtInput.onSelect.AddListener((string str) =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = false;
			});
			item.amtInput.onEndEdit.AddListener((string str) =>
			{
				OnDesiredAmountChanged(str, item);
				GameState.inst.AlphaNumericHotkeysEnabled = true;
			});
			item.cancelOrderBtn.onClick.AddListener(() =>
			{
				RemoveOrder(item);
			});
			List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
			List<BetterDropdown.OptionData> list = new List<BetterDropdown.OptionData>(rIDLookup.Count);
			for (int num = 0; num < resourceDefs.Count; num++)
			{
				FreeResourceSystem.ResourceDef resourceDef = resourceDefs[num];
				if (resourceDef.ID != 4 && resourceDef.ID != 17)
				{
					BetterDropdown.OptionData item2 = new BetterDropdown.OptionData
					{
						text = LocalizationManager.GetTranslation(resourceDef.name),
						term = resourceDef.name,
						image = resourceDef.texture
					};
					list.Add(item2);
				}
			}
			item.resourceType.options = list;
		}
		return orderUIPool.data[orderUIPoolCount++];
	}

	private void OnOrderTypeChanged(int idx, MerchantOrderItemUI itemUI)
	{
		int childIndex = Util.GetChildIndex(itemUI.transform, itemsContainerRectT);
		MerchantOrdersManager.inst.GetOrderEntry(dock.bi.guid, childIndex).type = idx;
		itemUI.conditionLocalize.SetTerm((idx == 0) ? "workerui_dockui_orders_conditional_lessthan" : "workerui_dockui_orders_conditional_greaterthan");
		SfxSystem.PlayUiSelect();
	}

	private void OnResourceTypeChanged(int idx, MerchantOrderItemUI itemUI)
	{
		int resourceID = rIDLookup[idx];
		int childIndex = Util.GetChildIndex(itemUI.transform, itemsContainerRectT);
		MerchantOrdersManager.inst.GetOrderEntry(dock.bi.guid, childIndex).resourceID = resourceID;
		SfxSystem.PlayUiSelect();
	}

	private void OnDesiredAmountChanged(string amt, MerchantOrderItemUI itemUI)
	{
		int childIndex = Util.GetChildIndex(itemUI.transform, itemsContainerRectT);
		MerchantOrdersManager.OrderEntry orderEntry = MerchantOrdersManager.inst.GetOrderEntry(dock.bi.guid, childIndex);
		if (int.TryParse(amt, out var result) || amt == string.Empty)
		{
			orderEntry.amount = Mathff.Max(0, result);
		}
		itemUI.amtInput.SetTextWithoutNotify(orderEntry.amount.ToString());
		SfxSystem.PlayUiSelect();
	}

	private void RefreshOrdersWindow()
	{
		orderUIPoolCount = 0;
		if (!MerchantOrdersManager.inst.orders.TryGetValue(dock.bi.guid, out var value))
		{
			HideAccessOrderItems();
			return;
		}
		for (int i = 0; i < value.Count; i++)
		{
			MerchantOrdersManager.OrderEntry orderEntry = value.data[i];
			MerchantOrderItemUI orderItemUI = GetOrderItemUI();
			orderItemUI.orderType.SetValueWithoutNotify(orderEntry.type);
			orderItemUI.resourceType.SetValueWithoutNotify(rIDLookup.IndexOf(orderEntry.resourceID));
			orderItemUI.conditionLocalize.SetTerm((orderEntry.type == 0) ? "workerui_dockui_orders_conditional_lessthan" : "workerui_dockui_orders_conditional_greaterthan");
			orderItemUI.amtInput.SetTextWithoutNotify(orderEntry.amount.ToString());
			Util.SetActive(orderItemUI.gameObject, active: true);
		}
		HideAccessOrderItems();
	}

	private void HideAccessOrderItems()
	{
		for (int num = orderUIPool.Count - 1; num >= orderUIPoolCount; num--)
		{
			Util.SetActive(orderUIPool.data[num].gameObject, active: false);
		}
	}
}
