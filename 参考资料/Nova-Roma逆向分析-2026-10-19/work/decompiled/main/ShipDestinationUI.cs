using System;
using System.Collections.Generic;
using Assets.Code;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ShipDestinationUI : MonoBehaviour
{
	private class DockDropdownData : Dropdown.OptionData
	{
		public Guid buildingId;
	}

	public Button deleteButton;

	public Button moveUpButton;

	public Button moveDownButton;

	public TMP_Dropdown destinationDrop;

	public Transform resourceEntryPrefab;

	public void AddResourceEntry(bool silentAdd = false)
	{
		Transform newEntry = UnityEngine.Object.Instantiate(resourceEntryPrefab);
		newEntry.gameObject.SetActive(value: true);
		newEntry.SetParent(transform, worldPositionStays: false);
		newEntry.GetComponent<RectTransform>().anchoredPosition3D = new Vector3(0f, 0f, 0f);
		newEntry.SetSiblingIndex(transform.childCount - 2);
		ResourceEntryUI component = newEntry.GetComponent<ResourceEntryUI>();
		component.deleteButton.onClick.AddListener(() =>
		{
			newEntry.SetParent(null);
			UnityEngine.Object.Destroy(newEntry.gameObject);
			SfxSystem.PlayUiCancel();
		});
		if (!silentAdd)
		{
			SfxSystem.PlayUiSelect();
		}
		component.resourceDrop.onValueChanged.AddListener(SaveToShip);
		component.loadUnloadDrop.onValueChanged.AddListener(SaveToShip);
		component.valueTxt.onValueChanged.AddListener(SaveToShip);
		ResourceEntryUI component2 = transform.GetChild(2).GetComponent<ResourceEntryUI>();
		if ((bool)component2)
		{
			component.RefreshDropdown(component2.transform);
		}
	}

	private void SaveToShip(int i)
	{
	}

	private void SaveToShip(string i)
	{
	}

	private void RefreshDestinationDropdown()
	{
		destinationDrop.ClearOptions();
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("dock");
		List<string> list = new List<string>();
		for (int i = 0; i < buildingList.Count; i++)
		{
			list.Add(buildingList.data[i].customName);
		}
		destinationDrop.AddOptions(list);
	}

	public void OnDestinationDropdownChanged()
	{
		SfxSystem.PlayUiSelect();
	}

	private void OnEnable()
	{
		RefreshDestinationDropdown();
	}

	private void Start()
	{
		RefreshDestinationDropdown();
	}

	public void SetAmounts(ResourceAmount toLoad, ResourceAmount toUnload)
	{
		for (int i = 0; i < toLoad.resources.Count; i++)
		{
			if (toLoad.resources[i].Amount > 0)
			{
				AddResourceEntry(silentAdd: true);
				ResourceEntryUI component = transform.GetChild(transform.childCount - 2).GetComponent<ResourceEntryUI>();
				if (toLoad.resources[i].resourceID >= 4)
				{
					component.resourceDrop.value = toLoad.resources[i].resourceID - 1;
				}
				else
				{
					component.resourceDrop.value = toLoad.resources[i].resourceID;
				}
				component.loadUnloadDrop.value = 0;
				component.valueTxt.text = toLoad.resources[i].Amount.ToString();
			}
		}
		for (int j = 0; j < toUnload.resources.Count; j++)
		{
			if (toUnload.resources[j].Amount > 0)
			{
				AddResourceEntry(silentAdd: true);
				ResourceEntryUI component2 = transform.GetChild(transform.childCount - 2).GetComponent<ResourceEntryUI>();
				if (toLoad.resources[j].resourceID >= 4)
				{
					component2.resourceDrop.value = toLoad.resources[j].resourceID - 1;
				}
				else
				{
					component2.resourceDrop.value = toLoad.resources[j].resourceID;
				}
				component2.loadUnloadDrop.value = 1;
				component2.valueTxt.text = toUnload.resources[j].Amount.ToString();
			}
		}
	}

	public void SetDestination(Guid buildingGuid)
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("dock");
		for (int i = 0; i < buildingList.Count; i++)
		{
			if (buildingList.data[i].guid == buildingGuid)
			{
				destinationDrop.value = i;
				break;
			}
		}
	}

	public void OnClickedCamToDestinationSelectedValue()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("dock");
		if (buildingList.data.Length != 0 && destinationDrop.value >= 0 && destinationDrop.value < buildingList.data.Length)
		{
			Cam.inst.SetDesiredTrackingPos(buildingList.data[destinationDrop.value].Center());
		}
	}

	public void OnClickedCamToDestination(Transform curr)
	{
		int num = curr.GetSiblingIndex() - 1;
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("dock");
		Cam.inst.SetDesiredTrackingPos(buildingList.data[num].Center());
	}

	public void UpdateCameraForHighlightEnter(RectTransform t)
	{
	}

	public void UpdateCameraForHighlightExit(RectTransform t)
	{
	}

	public Guid GetDestinationGuid()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("dock");
		if (buildingList.Count > 0)
		{
			return buildingList.data[Mathff.Clamp(destinationDrop.value, 0, buildingList.Count - 1)].guid;
		}
		return Guid.Empty;
	}

	public void GetAmounts(ref ResourceAmount toLoad, ref ResourceAmount toUnload)
	{
		toLoad = new ResourceAmount();
		toUnload = new ResourceAmount();
		ResourceEntryUI component = transform.GetChild(2).GetComponent<ResourceEntryUI>();
		while ((bool)component)
		{
			component.AddAmountToLoadUnload(ref toLoad, ref toUnload);
			int siblingIndex = component.transform.GetSiblingIndex();
			siblingIndex++;
			Transform child = component.transform.parent.GetChild(siblingIndex);
			if ((bool)child)
			{
				component = child.GetComponent<ResourceEntryUI>();
				continue;
			}
			break;
		}
	}
}
