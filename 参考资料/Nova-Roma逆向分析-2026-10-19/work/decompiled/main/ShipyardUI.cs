using Assets.Code;
using I2.Loc;
using UnityEngine;

public class ShipyardUI : MonoBehaviour, IWorkerUIElement
{
	public Transform builtItemContainer;

	private Building building;

	private Shipyard shipyard;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
		isVisible = v;
	}

	private void Start()
	{
		for (int i = 0; i < builtItemContainer.childCount; i++)
		{
			BuildItemShipUI component = builtItemContainer.GetChild(i).GetComponent<BuildItemShipUI>();
			int idx = i;
			component.buildBtn.onClick.AddListener(() =>
			{
				shipyard.currBuildItemIdx = idx;
				shipyard.TryStartConstruction(fromLoad: false);
			});
			component.cancelBtn.onClick.AddListener(OnCancelClicked);
		}
	}

	public void OnDeselected()
	{
		building = null;
		shipyard = null;
		SetVisibility(v: false);
	}

	private void Update()
	{
		if (isVisible && !(building == null) && !(shipyard == null))
		{
			RefreshVisuals();
		}
	}

	public void RefreshVisuals()
	{
		for (int i = 0; i < shipyard.buildItems.Count; i++)
		{
			BuildItemShipUI component = builtItemContainer.GetChild(i).GetComponent<BuildItemShipUI>();
			if (shipyard.buildItems[i].unlockKey != "" && !TechnologyTree.inst.IsTechnologyUnlocked(shipyard.buildItems[i].unlockKey))
			{
				Util.SetActive(component.gameObject, active: false);
				continue;
			}
			Util.SetActive(component.gameObject, active: true);
			bool flag = shipyard.IsConstructing() && shipyard.currBuildItemIdx == i;
			Util.SetActive(component.progressSlider.gameObject, flag);
			Util.SetEnabled(component.collectTxt, !flag);
			component.cancelBtn.interactable = flag;
			component.buildBtn.interactable = shipyard.CanConstruct(i);
			if (!shipyard.HasCostForConstruction(i))
			{
				component.recruitTMP.text = ScriptLocalization.damplanningui_cannotafforderror;
			}
			else
			{
				component.recruitTMP.text = ScriptLocalization.Build;
			}
			ResourceAmount constructCost = shipyard.buildItems[i].constructCost;
			ResourceAmount resourceAmount = Player.inst.resourcesPerLandmass[shipyard.b.LandMass()];
			if (Creative.inst.IsCreativeOptionOn(0))
			{
				component.collectTxt.text = "<color=yellow>" + LocalizationManager.GetTranslation("workerui_rubbleui_warning_creativebuildforfree") + "</color>";
			}
			else
			{
				string text = "";
				for (int j = 0; j < constructCost.resources.Count; j++)
				{
					Resource resource = constructCost.resources[j];
					if (resource.Amount > 0)
					{
						int amount = resource.Amount;
						int num = ((resource.resourceID == 4) ? building.GetLandMassOwner().Gold : resourceAmount.Get(resource.resourceID));
						FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[resource.resourceID];
						text += (string.IsNullOrEmpty(text) ? "" : "   ");
						text = text + resourceDef.iconName + ((num < amount) ? $"<color=red>{amount}</color>" : $"{amount}");
					}
				}
				component.collectTxt.text = text;
			}
			if (flag)
			{
				ResourceAmount resourceAmount2 = shipyard.currStorageMax - shipyard.currStorage;
				resourceAmount2.Set(4, 0);
				if (resourceAmount2.IsNone())
				{
					component.statusTxt.text = ScriptLocalization.ConstructUIFinishingUp;
				}
				else
				{
					component.statusTxt.text = ScriptLocalization.ConstructUIWaitingFor + "\n" + resourceAmount2.ToString(", ");
				}
				component.progressSlider.value = shipyard.GetProgress();
			}
			else
			{
				component.statusTxt.text = ScriptLocalization.Cost + ":";
			}
		}
	}

	private void OnCancelClicked()
	{
		shipyard?.TryCancelConstruction();
	}

	public void TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected == null || (shipyard = buildingSelected.GetComponent<Shipyard>()) == null)
		{
			SetVisibility(v: false);
			return;
		}
		building = buildingSelected;
		for (int i = 0; i < builtItemContainer.childCount; i++)
		{
			builtItemContainer.GetChild(i).GetComponent<BuildItemShipUI>().titleTxt.Term = shipyard.buildItems[i].titleTerm;
		}
		RefreshVisuals();
		SetVisibility(v: true);
	}

	public void UpdateForNewSelection()
	{
	}
}
