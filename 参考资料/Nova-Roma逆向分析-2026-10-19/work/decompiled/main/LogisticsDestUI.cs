using System;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class LogisticsDestUI : MonoBehaviour
{
	[NonSerialized]
	public int idxIntoPool;

	[NonSerialized]
	public int idxIntoActiveList;

	private ILogisticTransport transport;

	public TextMeshProUGUI MerchantResultsTxt;

	public GameObject PickUpContainer;

	public GameObject DropOffContainer;

	public GameObject MerchantPricesContainer;

	public GameObject PickUpConfirm;

	public GameObject DropOffConfirm;

	public Image PickUpHeaderImage;

	public Image PickUpResourceContainerImage;

	public Image DropOffHeaderImage;

	public Image DropOffResourceContainerImage;

	public GameObject ToggleContainer;

	public Toggle PickUpToggle;

	public Toggle DropOffToggle;

	public Button PickUpEditBtn;

	public Button DropOffEditBtn;

	public Button HeaderDockTrack;

	public TextMeshProUGUI HeadTitle;

	public ResourceAmountUI PickUpResourceUI;

	public ResourceAmountUI DropOffResourceUI;

	public ResourceAmountUI MerchantPricesResourceUI;

	public Image RouteColor;

	internal Ship.LogisticsOrder logisticOrder;

	private ResourceAmount defaultAmount = new ResourceAmount();

	public void Init()
	{
		ShipLogisticsUI.destActive.Add(this);
		idxIntoActiveList = ShipLogisticsUI.destActive.Count - 1;
		gameObject.SetActive(value: true);
	}

	public void Shutdown()
	{
		ShipLogisticsUI.destPool.RemoveAtSwapBoth(idxIntoPool);
		if (ShipLogisticsUI.destPool.Count > 0 && idxIntoPool < ShipLogisticsUI.destPool.Count)
		{
			ShipLogisticsUI.destPool.data[idxIntoPool].idxIntoPool = idxIntoPool;
		}
		ShipLogisticsUI.destActive.RemoveAtSwap(idxIntoActiveList);
		if (ShipLogisticsUI.destActive.Count > 0 && idxIntoActiveList < ShipLogisticsUI.destActive.Count)
		{
			ShipLogisticsUI.destActive.data[idxIntoActiveList].idxIntoActiveList = idxIntoActiveList;
		}
		gameObject.SetActive(value: false);
	}

	internal void RefreshMerchantSaleStatus()
	{
		if (logisticOrder.lastTransactionAmt == -1f)
		{
			MerchantResultsTxt.text = "<color=yellow>" + ScriptLocalization.MerchantCantAfford + "</color>";
		}
		else if (logisticOrder.lastTransactionAmt == -2f)
		{
			if (logisticOrder.want == -1)
			{
				MerchantResultsTxt.text = ScriptLocalization.MerchantDidntNeedAnything;
			}
			else
			{
				MerchantResultsTxt.text = "<color=yellow>" + string.Format(ScriptLocalization.MerchantWantedMoreResource, ResourceAmount.ResourceIcon(logisticOrder.want));
			}
		}
		else if (logisticOrder.lastTransactionAmt == 0f)
		{
			MerchantResultsTxt.text = ScriptLocalization.MerchantNotArrived;
		}
		else
		{
			MerchantResultsTxt.text = string.Format(ScriptLocalization.MerchantBoughtGoods, logisticOrder.lastTransactionAmt + ResourceAmount.ResourceIcon(4));
		}
	}

	internal void SetOrder(Ship.LogisticsOrder logisticsOrder)
	{
		PickUpContainer.SetActive(value: false);
		PickUpConfirm.SetActive(value: false);
		PickUpResourceContainerImage.enabled = false;
		PickUpHeaderImage.enabled = false;
		PickUpToggle.isOn = false;
		PickUpResourceUI.SetResourceAmount(defaultAmount);
		DropOffContainer.SetActive(value: false);
		DropOffConfirm.SetActive(value: false);
		DropOffResourceContainerImage.enabled = false;
		DropOffHeaderImage.enabled = false;
		DropOffToggle.isOn = false;
		DropOffResourceUI.SetResourceAmount(defaultAmount);
		MerchantPricesContainer.SetActive(value: false);
		HeaderDockTrack.gameObject.SetActive(value: true);
		HeadTitle.text = "";
		logisticOrder = logisticsOrder;
		if (logisticsOrder.endType == Ship.LogisticsOrderType.Position)
		{
			ToggleContainer.gameObject.SetActive(value: false);
			HeaderDockTrack.gameObject.SetActive(value: false);
			return;
		}
		Building building = logisticsOrder.GetBuilding();
		string customName = building.customName;
		HeadTitle.text = customName;
		ShipBase component = (transport as MonoBehaviour).GetComponent<ShipBase>();
		if (component != null && Ship.IsSellOrder(logisticsOrder, component))
		{
			ToggleContainer.gameObject.SetActive(value: false);
			MerchantPricesResourceUI.SetResourceAmount(World.GetLandmassOwnerByTeamId(building.TeamID()).GetPayCosts(component.teamID));
			MerchantPricesContainer.SetActive(value: true);
			RefreshMerchantSaleStatus();
			return;
		}
		ToggleContainer.gameObject.SetActive(value: true);
		if (!logisticOrder.loadFromStart.IsNone() && !PickUpConfirm.activeSelf)
		{
			PickUpContainer.SetActive(value: true);
			PickUpToggle.isOn = true;
			PickUpResourceUI.SetResourceAmount(logisticOrder.loadFromStart);
			PickUpResourceUI.HideZeros();
			PickUpEditBtn.gameObject.SetActive(GamepadControl.inst.isControllerActive);
		}
		if (!logisticOrder.unloadAtEnd.IsNone() && !DropOffConfirm.activeSelf)
		{
			DropOffContainer.SetActive(value: true);
			DropOffToggle.isOn = true;
			DropOffResourceUI.SetResourceAmount(logisticOrder.unloadAtEnd);
			DropOffResourceUI.HideZeros();
			DropOffEditBtn.gameObject.SetActive(GamepadControl.inst.isControllerActive);
		}
	}

	public Ship.LogisticsOrder GetFirstOrder()
	{
		return logisticOrder;
	}

	public void Awake()
	{
		HeaderDockTrack.onClick.AddListener(() =>
		{
			TryTrackBuilding(logisticOrder);
		});
		PickUpEditBtn.onClick.AddListener(() =>
		{
			TogglePickup(isOn: true);
		});
		DropOffEditBtn.onClick.AddListener(() =>
		{
			ToggleDropOff(isOn: true);
		});
	}

	public void OnPickupToggleClicked()
	{
		if (PickUpToggle.interactable)
		{
			TogglePickup(PickUpToggle.isOn);
		}
	}

	private void TogglePickup(bool isOn)
	{
		PickUpContainer.SetActive(isOn);
		PickUpConfirm.SetActive(isOn);
		PickUpResourceContainerImage.enabled = isOn;
		PickUpHeaderImage.enabled = isOn;
		if (!isOn)
		{
			logisticOrder.loadFromStart = new ResourceAmount();
		}
		else
		{
			PickUpResourceUI.ShowAll();
		}
		PickUpEditBtn.gameObject.SetActive(value: false);
	}

	public void OnPickUpConfirm()
	{
		logisticOrder.loadFromStart = PickUpResourceUI.GetResourceAmount();
		if (logisticOrder.loadFromStart.IsNone())
		{
			PickUpContainer.SetActive(value: false);
			PickUpToggle.isOn = false;
			return;
		}
		PickUpResourceUI.HideZeros();
		PickUpConfirm.SetActive(value: false);
		PickUpResourceContainerImage.enabled = false;
		PickUpHeaderImage.enabled = false;
		PickUpEditBtn.gameObject.SetActive(GamepadControl.inst.isControllerActive);
	}

	public void OnDropOffToggleClicked()
	{
		if (DropOffToggle.interactable)
		{
			ToggleDropOff(DropOffToggle.isOn);
		}
	}

	private void ToggleDropOff(bool isOn)
	{
		DropOffContainer.SetActive(isOn);
		DropOffConfirm.SetActive(isOn);
		DropOffResourceContainerImage.enabled = isOn;
		DropOffHeaderImage.enabled = isOn;
		if (!isOn)
		{
			logisticOrder.unloadAtEnd = new ResourceAmount();
		}
		else
		{
			DropOffResourceUI.ShowAll();
		}
		DropOffEditBtn.gameObject.SetActive(value: false);
	}

	public void OnDropOffConfirm()
	{
		logisticOrder.unloadAtEnd = DropOffResourceUI.GetResourceAmount();
		if (logisticOrder.unloadAtEnd.IsNone())
		{
			DropOffContainer.SetActive(value: false);
			DropOffToggle.isOn = false;
			return;
		}
		DropOffResourceUI.HideZeros();
		DropOffConfirm.SetActive(value: false);
		DropOffHeaderImage.enabled = false;
		DropOffResourceContainerImage.enabled = false;
		DropOffEditBtn.gameObject.SetActive(GamepadControl.inst.isControllerActive);
	}

	private void TryTrackBuilding(Ship.LogisticsOrder order)
	{
		if (order != null && order.endType == Ship.LogisticsOrderType.Building)
		{
			Building building = order.GetBuilding();
			if ((bool)building)
			{
				Cam.inst.SetDesiredTrackingPos(building.Center());
			}
		}
	}

	public void SetTransport(ILogisticTransport t)
	{
		transport = t;
	}

	public void OnPickUpEnter()
	{
		if (PickUpContainer.activeSelf && !PickUpConfirm.activeSelf)
		{
			PickUpEditBtn.gameObject.SetActive(value: true);
			PickUpHeaderImage.enabled = true;
			PickUpResourceContainerImage.enabled = true;
		}
	}

	public void OnPickUpExit()
	{
		PickUpEditBtn.gameObject.SetActive(value: false);
		if (PickUpContainer.activeSelf && !PickUpConfirm.activeSelf)
		{
			PickUpHeaderImage.enabled = false;
			PickUpResourceContainerImage.enabled = false;
		}
	}

	public void OnDropOffEnter()
	{
		if (DropOffContainer.activeSelf && !DropOffConfirm.activeSelf)
		{
			DropOffEditBtn.gameObject.SetActive(value: true);
			DropOffHeaderImage.enabled = true;
			DropOffResourceContainerImage.enabled = true;
		}
	}

	public void OnDropOffExit()
	{
		DropOffEditBtn.gameObject.SetActive(value: false);
		if (DropOffContainer.activeSelf && !DropOffConfirm.activeSelf)
		{
			DropOffHeaderImage.enabled = false;
			DropOffResourceContainerImage.enabled = false;
		}
	}

	public void UpdateAmountsFromUI()
	{
		if (PickUpToggle.isOn && !PickUpConfirm.activeSelf)
		{
			logisticOrder.loadFromStart = PickUpResourceUI.GetResourceAmount();
		}
		if (DropOffToggle.isOn && !DropOffConfirm.activeSelf)
		{
			logisticOrder.unloadAtEnd = DropOffResourceUI.GetResourceAmount();
		}
	}
}
