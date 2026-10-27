using System;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class LogisticsUI : MonoBehaviour
{
	public static LogisticsUI inst;

	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	public Button closeBtn;

	public Button demolishButton;

	public Transform routeContainer;

	public ScrollRect scrollRect;

	public GameObject entryPrefab;

	public GameObject errorContainer;

	public Localize errorTMP;

	public Localize titleTmp;

	private bool isVisible;

	public Sprite shipSprite;

	public Sprite cartSprite;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		v &= GameUI.inst.routeLogisticsCursorMode.currVehicle != null;
		if (v && !isVisible)
		{
			RefreshRouteList();
			RefreshVisuals();
		}
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
		closeBtn.onClick.AddListener(() =>
		{
			GameUI.inst.ReturnToDefaultCursorMode();
			SetVisibility(v: false);
		});
		demolishButton.onClick.AddListener(() =>
		{
			DemolishCart();
		});
	}

	public void DemolishCart()
	{
		LogisticsVehicle currVehicle = GameUI.inst.routeLogisticsCursorMode.currVehicle;
		EffectsMan.inst.BuildPuff.CreateAndPlay(currVehicle.transform.position + new Vector3(0f, 0.1f, 0f));
		UnityEngine.Object.Destroy(currVehicle.gameObject);
		SetVisibility(v: false);
		GameUI.inst.ReturnToDefaultCursorMode();
	}

	public void RefreshRouteList()
	{
		LogisticsVehicle vehicle = GameUI.inst.routeLogisticsCursorMode.currVehicle;
		int i;
		for (i = 0; i < vehicle.routes.Count; i++)
		{
			LogisticsRouteEntryUI logisticsRouteEntryUI = null;
			logisticsRouteEntryUI = ((routeContainer.childCount > i) ? routeContainer.GetChild(i).GetComponent<LogisticsRouteEntryUI>() : UnityEngine.Object.Instantiate(entryPrefab, routeContainer, worldPositionStays: false).GetComponent<LogisticsRouteEntryUI>());
			logisticsRouteEntryUI.sourceImg.sprite = vehicle.routes[i].sourceBuilding.sprite;
			logisticsRouteEntryUI.targetImg.sprite = vehicle.routes[i].targetBuilding.sprite;
			logisticsRouteEntryUI.sourceNameTMP.text = vehicle.routes[i].sourceBuilding.CustomName;
			logisticsRouteEntryUI.targetNameTMP.text = vehicle.routes[i].targetBuilding.CustomName;
			int idx = i;
			logisticsRouteEntryUI.focusSourceBtn.onClick.RemoveAllListeners();
			logisticsRouteEntryUI.focusSourceBtn.onClick.AddListener(() =>
			{
				Cam.inst.SetDesiredTrackingPos(vehicle.routes[idx].sourceBuilding.Center());
			});
			logisticsRouteEntryUI.focusTargetBtn.onClick.RemoveAllListeners();
			logisticsRouteEntryUI.focusTargetBtn.onClick.AddListener(() =>
			{
				Cam.inst.SetDesiredTrackingPos(vehicle.routes[idx].targetBuilding.Center());
			});
			logisticsRouteEntryUI.deleteBtn.onClick.RemoveAllListeners();
			logisticsRouteEntryUI.deleteBtn.onClick.AddListener(() =>
			{
				vehicle.RemoveRoute(idx);
				RefreshRouteList();
				RefreshVisuals();
			});
			logisticsRouteEntryUI.gameObject.SetActive(value: true);
		}
		for (; i < routeContainer.childCount; i++)
		{
			routeContainer.GetChild(i).gameObject.SetActive(value: false);
		}
		scrollRect.verticalNormalizedPosition = 1f;
	}

	public void OnLogisticsSelected(LogisticsVehicle cart)
	{
	}

	private void Update()
	{
		if (isVisible && !(GameUI.inst.routeLogisticsCursorMode.currVehicle == null))
		{
			RefreshVisuals();
		}
	}

	private string GetStatusForCart()
	{
		return GameUI.inst.routeLogisticsCursorMode.currVehicle.GetStatus() switch
		{
			-1 => "I2.Paused", 
			0 => LocalizationManager.GetTranslation("Idle"), 
			1 => "", 
			2 => LocalizationManager.GetTranslation("transportui_headingtopickup"), 
			3 => LocalizationManager.GetTranslation("transportui_pickingup"), 
			4 => LocalizationManager.GetTranslation("transportui_headingtodropoff"), 
			5 => LocalizationManager.GetTranslation("transportui_droppingoff"), 
			_ => "", 
		};
	}

	private void RefreshVisuals()
	{
		LogisticsVehicle currVehicle = GameUI.inst.routeLogisticsCursorMode.currVehicle;
		titleTmp.Term = currVehicle.titleTerm;
		bool flag = currVehicle.TryGetCurrentRoute(out var _);
		Util.SetActive(errorContainer, !flag);
		if (!flag)
		{
			if ((!currVehicle.isShip && LogisticsManager.inst.AnyRoutesOnLandmass(World.inst.GetCellDataClamped(currVehicle.transform.position).landMassIdx)) || (currVehicle.isShip && LogisticsManager.inst.AnyRoutesBetweenDocks(World.inst.GetCellDataClamped(currVehicle.transform.position).landMassIdx)))
			{
				errorTMP.Term = "transportui_error_assignroutes";
			}
			else
			{
				errorTMP.Term = "transportui_error_noroutes";
			}
		}
		int status = currVehicle.GetStatus();
		for (int i = 0; i < routeContainer.childCount; i++)
		{
			LogisticsRouteEntryUI component = routeContainer.GetChild(i).GetComponent<LogisticsRouteEntryUI>();
			bool flag2 = currVehicle.routeIdx == i;
			if (flag2)
			{
				component.GetComponent<Image>().color = Color.white;
			}
			else
			{
				component.GetComponent<Image>().color = new Color(0.75f, 0.75f, 0.75f, 1f);
			}
			if (currVehicle.lastError == LogisticsVehicle.Error.NoResourcesAtSupplier)
			{
				component.statusTxt.text = LocalizationManager.GetTranslation("transportui_noresourcesatsupplier");
			}
			else if (currVehicle.lastError == LogisticsVehicle.Error.AlreadyFulfilled)
			{
				component.statusTxt.text = LocalizationManager.GetTranslation("transportui_alreadyfulfilled");
			}
			else if (currVehicle.lastError == LogisticsVehicle.Error.NoRoomAtDestination)
			{
				component.statusTxt.text = LocalizationManager.GetTranslation("transportui_noroomatdest");
			}
			else if (currVehicle.lastError == LogisticsVehicle.Error.BuildingNotBuilt)
			{
				component.statusTxt.text = LocalizationManager.GetTranslation("transportui_buildingnotbuilt");
			}
			else
			{
				component.statusTxt.text = GetStatusForCart();
			}
			component.resourceTxt.text = string.Empty;
			if (flag2)
			{
				Vector3 localScale = component.cart.transform.localScale;
				if ((bool)currVehicle.GetComponent<ShipBase>())
				{
					component.cart.sprite = shipSprite;
				}
				else
				{
					component.cart.sprite = cartSprite;
				}
				float num = 0f;
				if (currVehicle.GetComponent<LogisticCart>() != null)
				{
					num = currVehicle.GetComponent<LogisticCart>().GetPathPercentComplete();
				}
				if (currVehicle.GetComponent<TransportShip>() != null)
				{
					num = currVehicle.GetComponent<TransportShip>().GetPathPercentComplete();
				}
				switch (status)
				{
				case 4:
				case 5:
				{
					string text = string.Empty;
					string[] array = currVehicle.currStorage.ToString("~").Split("~");
					for (int j = 0; j < array.Length; j++)
					{
						text += array[j];
						if (j != 0 && j % 3 == 0)
						{
							text += Environment.NewLine;
						}
						else if (j + 1 < array.Length)
						{
							text += "  ";
						}
					}
					component.resourceTxt.text = text;
					localScale.x = -1f;
					component.SetCartProgress(1f - num);
					break;
				}
				case 2:
				case 3:
					component.SetCartProgress(num);
					localScale.x = 1f;
					break;
				}
				component.cart.transform.localScale = localScale;
			}
			Util.SetActive(component.resourceTxt.gameObject, flag2);
			Util.SetActive(component.statusTxt.gameObject, flag2);
			component.UpdateArrowColor(flag2);
			Util.SetActive(component.activeFrame, flag2);
			Util.SetActive(component.cart, flag2 && currVehicle.lastError == LogisticsVehicle.Error.Valid);
			Util.SetActive(component.path, flag2 && currVehicle.lastError == LogisticsVehicle.Error.Valid);
		}
	}
}
