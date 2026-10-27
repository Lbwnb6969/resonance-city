using System;
using Assets.Code;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class BuildingDemolishUI : MonoBehaviour
{
	[SerializeField]
	private Button demolishBtn;

	[SerializeField]
	private TooltipHook tooltip;

	private ISelectableBuilding building;

	private IWorkerUIDisplay iWorkerUIDisplay;

	private ResourceAmount scratchAmt = new ResourceAmount();

	private void Awake()
	{
		demolishBtn.onClick.AddListener(OnDemolishClicked);
		tooltip.tooltipTerm = "tooltipui_hotkey";
	}

	private void OnDemolishClicked()
	{
		World.inst.DemolishSelectedBuildingByPlayer();
		GameUI.inst.ClearCellSelected();
	}

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
	}

	public void OnBuildingSelected(ISelectableBuilding b)
	{
		if (b == null || GamepadControl.inst.isControllerActive || World.IsAILandmass(b.LandMass()))
		{
			SetVisibility(isVisible: false);
			return;
		}
		this.building = b;
		Building building = b as Building;
		if (b is IWorkerUIDisplay workerUIDisplay)
		{
			iWorkerUIDisplay = workerUIDisplay;
		}
		else if (building != null && building.GetComponent<IWorkerUIDisplay>() != null)
		{
			iWorkerUIDisplay = building.GetComponent<IWorkerUIDisplay>();
		}
		bool flag = true;
		if (building != null)
		{
			flag = b.CanDemolishBuilding();
		}
		if (iWorkerUIDisplay != null && !iWorkerUIDisplay.ShowDemolish())
		{
			flag = false;
		}
		if (!flag)
		{
			SetVisibility(isVisible: false);
			return;
		}
		RefreshVisuals();
		SetVisibility(isVisible: true);
	}

	private void Update()
	{
		if (this.building == null || !GameState.inst.AlphaNumericHotkeysEnabled || !ConfigurableControls.inst.GetInputActionKeyDown(304))
		{
			return;
		}
		Cell cell = null;
		if (this.building is Building building)
		{
			cell = building.GetCell();
		}
		World.inst.DemolishSelectedBuildingByPlayer();
		if (cell != null)
		{
			for (int num = cell.OccupyingStructure.Count - 1; num >= 0; num--)
			{
				if (!cell.OccupyingStructure[num].isDemolishing)
				{
					GameUI.inst.SetSelectedBuildingNew(cell.OccupyingStructure[num], forceUpdate: true);
				}
			}
		}
		else
		{
			GameUI.inst.ClearCellSelected();
		}
	}

	public void OnDeselected()
	{
		building = null;
		iWorkerUIDisplay = null;
	}

	public static string GetDemolishTooltip(ResourceAmount scratchAmt, ISelectableBuilding building)
	{
		string text = "<b>" + ScriptLocalization.Demolish + "</b>" + Environment.NewLine;
		World.inst.GetDemolishCollectionAmount(ref scratchAmt, building);
		if (!scratchAmt.IsNone())
		{
			string text2 = "";
			for (int i = 0; i < scratchAmt.resources.Count; i++)
			{
				Resource resource = scratchAmt.resources[i];
				if (resource.Amount > 0)
				{
					FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[resource.resourceID];
					text2 += $"<color=green>+{resource.Amount}</color> {resourceDef.iconName}";
				}
			}
			text = text + text2 + Environment.NewLine + Environment.NewLine;
			text += string.Format(ScriptLocalization.tooltipui_hotkey, ConfigurableControls.inst.GetKeyAction(304));
		}
		return text;
	}

	private void RefreshVisuals()
	{
		tooltip.toolTipText = GetDemolishTooltip(scratchAmt, building);
	}
}
