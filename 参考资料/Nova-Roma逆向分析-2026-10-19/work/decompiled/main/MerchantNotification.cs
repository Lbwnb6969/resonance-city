using System;
using UnityEngine;
using UnityEngine.UI;

public class MerchantNotification : MonoBehaviour, ICamTrackable
{
	public MiniMapViewer miniMapViewer;

	public Button focusBtn;

	private bool IsAnimatingHide;

	private bool IsShowing;

	public GameObject Content;

	private int merchantViewIdx;

	private void Start()
	{
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(inst.controllerUpdate, new GamepadControl.ControllerActivity(ControllerUpdate));
	}

	private void ControllerUpdate(bool isControllerActive)
	{
		focusBtn.gameObject.SetActive(!isControllerActive);
	}

	public void HideNotification()
	{
		if (!IsAnimatingHide)
		{
			IsAnimatingHide = true;
			miniMapViewer.HideTab(MiniMapViewer.NotificationGroup.Merchant, OnFinishedHideAnimation);
		}
	}

	private void OnFinishedHideAnimation()
	{
		if (IsAnimatingHide)
		{
			Content.SetActive(value: false);
		}
		IsShowing = false;
		IsAnimatingHide = false;
	}

	public void ShowNotification()
	{
		IsShowing = true;
		miniMapViewer.ShowTab(MiniMapViewer.NotificationGroup.Merchant);
		Content.SetActive(value: true);
	}

	public void ShowBanner()
	{
		miniMapViewer.DisplayBanner(MiniMapViewer.NotificationGroup.Merchant);
	}

	public void OnShipArrival()
	{
		if (!IsShowing)
		{
			ShowNotification();
			ShowBanner();
		}
	}

	public void OnShipDeparture()
	{
		if (IsShowing && !IsAnimatingHide)
		{
			HideNotification();
		}
	}

	public void OnViewClicked()
	{
		merchantViewIdx++;
		Cam.inst.Track(this);
	}

	public Vector3 GetDesiredTrackingPos()
	{
		int num = 0;
		for (int i = 0; i < ShipSystem.inst.ships.Count; i++)
		{
			if (ShipSystem.inst.ships.data[i].type == ShipBase.ShipType.Merchant && ShipSystem.inst.ships.data[i].GetComponent<MerchantShip>().isTargetPlayerDock)
			{
				num++;
			}
		}
		if (merchantViewIdx >= num)
		{
			merchantViewIdx = 0;
		}
		ShipBase shipBase = null;
		int num2 = 0;
		for (int j = 0; j < ShipSystem.inst.ships.Count; j++)
		{
			if (ShipSystem.inst.ships.data[j].type == ShipBase.ShipType.Merchant && ShipSystem.inst.ships.data[j].GetComponent<MerchantShip>().isTargetPlayerDock)
			{
				if (num2 == merchantViewIdx)
				{
					shipBase = ShipSystem.inst.ships.data[j];
					break;
				}
				num2++;
			}
		}
		if ((bool)shipBase)
		{
			return shipBase.GetPos();
		}
		return Player.inst.keep.transform.position;
	}

	public void Reset()
	{
		IsShowing = false;
		IsAnimatingHide = false;
	}
}
