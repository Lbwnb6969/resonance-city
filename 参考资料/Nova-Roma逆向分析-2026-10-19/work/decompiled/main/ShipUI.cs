using System;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ShipUI : UIWindowBase
{
	private bool deferTitleTextInteractibleFalse;

	public GameObject holdLineItem;

	public Button viewHold;

	public Button closeHold;

	public Button editTitleButton;

	public Transform destinationPrefab;

	public Transform destinationsContainer;

	public Transform resourceEntryPrefab;

	private bool ordersLocked;

	public Transform strongerSails;

	public TMP_InputField shipName;

	[NonSerialized]
	public ShipBase ship;

	public Transform holdContainer;

	public Toggle repeatToggle;

	public Toggle stopToggle;

	public Transform error;

	public TextMeshProUGUI helperText;

	public TextMeshProUGUI behaviorText;

	public TextMeshProUGUI statusText;

	public Transform pauseHighlight;

	public TextMeshProUGUI holdCurrTxt;

	public TextMeshProUGUI holdMaxTxt;

	public Toggle play;

	public Toggle pause;

	public void Awake()
	{
		viewHold.onClick.AddListener(() =>
		{
			holdContainer.gameObject.SetActive(!holdContainer.gameObject.activeSelf);
			if (holdContainer.gameObject.activeSelf)
			{
				SfxSystem.PlayUiSelect();
			}
			else
			{
				SfxSystem.PlayUiCancel();
			}
		});
		closeHold.onClick.AddListener(() =>
		{
			holdContainer.gameObject.SetActive(value: false);
			SfxSystem.PlayUiCancel();
		});
		for (int num = 0; num < FreeResourceSystem.inst.resourceDefs.Count; num++)
		{
			GameObject gameObject = UnityEngine.Object.Instantiate(holdLineItem);
			gameObject.transform.SetParent(holdContainer, worldPositionStays: false);
			gameObject.GetComponent<RectTransform>().anchoredPosition3D = new Vector3(0f, 0f, 0f);
			gameObject.gameObject.SetActive(value: false);
			gameObject.transform.SetSiblingIndex(holdContainer.transform.childCount - 2);
		}
		shipName.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
		});
		shipName.onEndEdit.AddListener((string val) =>
		{
			if ((bool)ship)
			{
				ship.GetComponent<Ship>().shipName = shipName.text;
			}
			GameState.inst.AlphaNumericHotkeysEnabled = true;
			deferTitleTextInteractibleFalse = true;
		});
		editTitleButton.onClick.AddListener(() =>
		{
			shipName.interactable = !shipName.interactable;
			if (shipName.interactable)
			{
				shipName.ActivateInputField();
			}
			else
			{
				shipName.DeactivateInputField();
			}
			SfxSystem.inst.PlayFromBank("ui_edit", Camera.main.transform.position);
		});
		resourceEntryPrefab.gameObject.SetActive(value: false);
	}

	public void OnClickedClose()
	{
		ship = null;
		SetVisible(false);
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedAddDestination()
	{
		SfxSystem.PlayUiSelect();
		Transform newDest = UnityEngine.Object.Instantiate(destinationPrefab);
		newDest.gameObject.SetActive(value: true);
		newDest.SetParent(destinationsContainer, worldPositionStays: false);
		newDest.GetComponent<RectTransform>().anchoredPosition3D = new Vector3(0f, 0f, 0f);
		newDest.GetComponent<ShipDestinationUI>().deleteButton.onClick.AddListener(() =>
		{
			newDest.SetParent(null);
			UnityEngine.Object.Destroy(newDest.gameObject);
			SaveToShip();
			SfxSystem.PlayUiCancel();
		});
		newDest.GetComponent<ShipDestinationUI>().moveUpButton.onClick.AddListener(() =>
		{
			newDest.SetSiblingIndex(newDest.GetSiblingIndex() - 1);
			SaveToShip();
		});
		newDest.GetComponent<ShipDestinationUI>().moveDownButton.onClick.AddListener(() =>
		{
			newDest.SetSiblingIndex(newDest.GetSiblingIndex() + 1);
			SaveToShip();
		});
		SaveToShip();
		newDest.GetComponent<RectTransform>().SetAsLastSibling();
	}

	public void SaveToShip()
	{
		if (!ordersLocked)
		{
			ship.GetComponent<Ship>().ClearOrders();
			for (int i = 0; i < destinationsContainer.childCount; i++)
			{
				ShipDestinationUI component = destinationsContainer.GetChild(i).GetComponent<ShipDestinationUI>();
				ResourceAmount toUnload = new ResourceAmount();
				ResourceAmount toLoad = new ResourceAmount();
				component.GetAmounts(ref toLoad, ref toUnload);
			}
		}
	}

	public void OnClickedDeleteDestination()
	{
	}

	private void ClearUI()
	{
		for (int i = 0; i < destinationsContainer.childCount; i++)
		{
			UnityEngine.Object.Destroy(destinationsContainer.GetChild(i).gameObject);
		}
	}

	private void PopulateUI()
	{
		if ((bool)ship)
		{
			strongerSails.gameObject.SetActive(World.GetLandmassOwnerByTeamId(ship.teamID).HasUpgrade(Player.UpgradeType.StrongerSails));
			Ship component = ship.GetComponent<Ship>();
			ordersLocked = true;
			for (int i = 0; i < component.orders.Count; i++)
			{
				OnClickedAddDestination();
				ShipDestinationUI component2 = destinationsContainer.GetChild(destinationsContainer.childCount - 1).GetComponent<ShipDestinationUI>();
				component2.SetDestination(component.orders[i].buildingGuid);
				component2.SetAmounts(component.orders[i].toLoad, component.orders[i].toUnload);
			}
			ordersLocked = false;
			repeatToggle.isOn = component.behavior == Ship.Behavior.Repeat;
			stopToggle.isOn = component.behavior != Ship.Behavior.Repeat;
			play.isOn = !component.Paused;
			pause.isOn = component.Paused;
			if (string.IsNullOrEmpty(component.shipName))
			{
				shipName.text = ScriptLocalization.ShipUITitle;
			}
			else
			{
				shipName.text = component.shipName;
			}
			holdContainer.gameObject.SetActive(value: false);
		}
	}

	public void SetSelectedShip(ShipBase v)
	{
		ship = v;
		ClearUI();
		PopulateUI();
	}

	public override void UpdateInternal(float dt)
	{
		base.UpdateInternal(dt);
		if (deferTitleTextInteractibleFalse)
		{
			shipName.interactable = false;
			deferTitleTextInteractibleFalse = false;
		}
		if (!ship)
		{
			return;
		}
		Ship component = ship.GetComponent<Ship>();
		helperText.gameObject.SetActive(component.orders.Count == 0);
		if (ship.pathFailed && component.orders.Count > 0)
		{
			error.gameObject.SetActive(value: true);
		}
		else
		{
			error.gameObject.SetActive(value: false);
		}
		if (component.behavior == Ship.Behavior.Repeat)
		{
			behaviorText.text = ScriptLocalization.TransportShipRepeat;
		}
		else
		{
			behaviorText.text = ScriptLocalization.TransportShipStop;
		}
		if (component.Paused)
		{
			statusText.text = ScriptLocalization.TransportShipPaused;
		}
		else
		{
			statusText.text = ScriptLocalization.TransportShipSailing;
		}
		pauseHighlight.gameObject.SetActive(component.Paused);
		if (!holdContainer.gameObject.activeSelf)
		{
			return;
		}
		int num = 1;
		for (int i = 0; i < component.hold.resources.Count; i++)
		{
			int amount = component.hold.resources[i].Amount;
			if (amount > 0)
			{
				Transform child = holdContainer.transform.GetChild(num);
				child.gameObject.SetActive(value: true);
				child.GetComponentInChildren<Image>().sprite = FreeResourceSystem.inst.resourceDefMap[component.hold.resources[i].resourceID].texture;
				child.GetComponentInChildren<TextMeshProUGUI>().SetText("{0}", amount);
				num++;
			}
		}
		for (int j = num; j < holdContainer.transform.childCount - 1; j++)
		{
			holdContainer.transform.GetChild(j).gameObject.SetActive(value: false);
		}
		int num2 = 0;
		int num3 = 0;
		holdCurrTxt.SetText("{0}", num2);
		holdMaxTxt.SetText("{0}", num3);
	}

	public void OnToggleBehavior(bool playSound)
	{
		if ((bool)ship)
		{
			if (playSound)
			{
				SfxSystem.PlayUiSelect();
			}
			Ship component = ship.GetComponent<Ship>();
			if (repeatToggle.isOn)
			{
				component.behavior = Ship.Behavior.Repeat;
			}
			else
			{
				component.behavior = Ship.Behavior.Stop;
			}
		}
	}

	public void OnTogglePlayPause(bool playSound)
	{
		if ((bool)ship)
		{
			if (playSound)
			{
				SfxSystem.PlayUiSelect();
			}
			Ship component = ship.GetComponent<Ship>();
			if (play.isOn)
			{
				component.SetPause(p: false);
			}
			else if (pause.isOn)
			{
				component.SetPause(p: true);
			}
		}
	}

	public override void SetVisible(bool newVisible)
	{
		if (Visible && !newVisible)
		{
			World.inst.HideResourceTooltipUIs();
		}
		base.SetVisible(newVisible);
		if (newVisible)
		{
			CreativeUI.inst.SetWindowVisibility(v: false);
			PlaceDockWorldNotes();
		}
	}

	public void PlaceDockWorldNotes()
	{
		int hashCode = "dock".GetHashCode();
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(hashCode);
		for (int i = 0; i < buildingList.Count; i++)
		{
			Building building = buildingList.data[i];
			Vector3 position = building.GetPos() + new Vector3(0f, 1.5f, 0f);
			GameObject gameObject = UnityEngine.Object.Instantiate(World.inst.resourceTooltipPrefab);
			ResourceTooltipUI component = gameObject.GetComponent<ResourceTooltipUI>();
			component.SetText(building.customName);
			component.EnableTextAutoSizing();
			gameObject.transform.position = position;
			gameObject.transform.SetParent(World.inst.resourceTooltipContainer.transform);
		}
	}

	public void OnDestroyShip()
	{
		if ((bool)ship)
		{
			EffectsMan.inst.BuildPuff.CreateAndPlay(ship.transform.position);
			SfxSystem.inst.PlayFromBank("DestroyTransportShip", ship.transform.position);
			UnityEngine.Object.Destroy(ship.gameObject);
			SetVisible(false);
		}
	}
}
