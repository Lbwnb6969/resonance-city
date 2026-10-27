using System.Collections.Generic;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class BuildTab : MonoBehaviour
{
	public delegate void OnButtonClicked(BuildingCostUpdater data);

	public BuildingCostUpdater buttonPrefab;

	public string title;

	public Localize unlockTooltipKey;

	public Transform ButtonPanel;

	public Transform TabButton;

	public bool isBackable;

	public Button back;

	public List<BuildingCostUpdater> buttons = new List<BuildingCostUpdater>();

	public BuildButton buildButton;

	public GameObject lockedOverlay;

	public GameObject gradient1;

	public GameObject gradient2;

	public bool Visible
	{
		get
		{
			return ButtonPanel.gameObject.activeSelf;
		}
		set
		{
			if (value)
			{
				if (title == "Maritime")
				{
					for (int i = 0; i < ButtonPanel.transform.childCount; i++)
					{
						RectTransform component = ButtonPanel.GetChild(i).GetComponent<RectTransform>();
						if (component.name == "outpost" && buttons.Count > 0)
						{
							if (Player.inst.FocusedLandMass != -1 && Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass, World.outpostHash).Count == 0 && Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass, World.keepHash).Count == 0)
							{
								if (!component.gameObject.activeSelf)
								{
									component.gameObject.SetActive(value: true);
									component.SetAsFirstSibling();
									buttons.Insert(0, component.GetComponent<BuildingCostUpdater>());
								}
							}
							else if (component.gameObject.activeSelf)
							{
								component.gameObject.SetActive(value: false);
								component.SetAsLastSibling();
								buttons.RemoveAt(i);
							}
						}
						if (!(component.name == "seedship") || buttons.Count <= 0)
						{
							continue;
						}
						if (World.inst.NumLandMasses > 1)
						{
							if (!component.gameObject.activeSelf)
							{
								component.gameObject.SetActive(value: true);
							}
						}
						else if (component.gameObject.activeSelf)
						{
							component.gameObject.SetActive(value: false);
						}
					}
				}
			}
			else
			{
				for (int j = 0; j < buttons.Count; j++)
				{
					buttons[j].ResetDisplayModelRotation();
				}
			}
			if ((buildButton != null) & value)
			{
				lockedOverlay.SetActive(!buildButton.IsUnlocked());
				ButtonPanel.gameObject.SetActive(buildButton.IsUnlocked());
			}
			else
			{
				ButtonPanel.gameObject.SetActive(value);
				lockedOverlay.SetActive(value: false);
			}
			if (GamepadControl.inst.isControllerActive)
			{
				back.gameObject.SetActive(value: false);
			}
			else if (isBackable)
			{
				back.gameObject.SetActive(value);
			}
			gameObject.SetActive(value);
		}
	}

	private void OnPointerDown()
	{
		BuildInfoFloating.inst.SetVisibility(v: false);
	}

	public virtual BuildingCostUpdater AddButton(Building prefab, Building preReq, Vector3 scaleMod, OnButtonClicked onClick = null)
	{
		if (prefab == null)
		{
			return null;
		}
		BuildingCostUpdater buildingCostUpdater = Object.Instantiate(buttonPrefab);
		buildingCostUpdater.buildingObject = prefab.gameObject;
		buildingCostUpdater.titleText.GetComponent<Localize>().SetTerm(prefab.GetFriendlyNameTerm);
		buildingCostUpdater.prefab = prefab;
		buildingCostUpdater.name = prefab.UniqueName;
		buildingCostUpdater.PreReq = preReq;
		Transform original;
		if ((bool)prefab.DisplayModel)
		{
			original = prefab.DisplayModel.transform;
		}
		else
		{
			Transform transform = prefab.transform.Find("Offset").Find("Building");
			if (!transform)
			{
				transform = prefab.transform.Find("Offset").Find("building");
			}
			if (!transform)
			{
				transform = prefab.transform.Find("Offset").GetChild(0);
			}
			original = transform;
		}
		Transform transform2 = Object.Instantiate(original);
		transform2.transform.localScale = scaleMod * 1.25f;
		transform2.transform.position = Vector3.zero;
		int layer = LayerMask.NameToLayer("UI");
		foreach (Transform item in Util.ComponentsInNodeAndAllDescendants<Transform>(transform2.gameObject))
		{
			item.gameObject.layer = layer;
		}
		transform2.SetParent(buildingCostUpdater.transform.Find("modelDisplay"), worldPositionStays: false);
		buildingCostUpdater.transform.SetParent(ButtonPanel, worldPositionStays: false);
		buttons.Add(buildingCostUpdater);
		return buildingCostUpdater;
	}
}
