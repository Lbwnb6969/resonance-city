using Assets.Code;
using Assets.Code.Interface;
using UnityEngine;

public class ResourceFilterUI : MonoBehaviour, IWorkerUIElement
{
	public ResourceToggleButton WoodToggleButton;

	public ResourceToggleButton StoneToggleButton;

	public ResourceToggleButton CharcoalToggleButton;

	public ResourceToggleButton IronToggleButton;

	public ResourceToggleButton ToolsToggleButton;

	public ResourceToggleButton ArmamentToggleButton;

	private void Start()
	{
		WoodToggleButton.OnToggle.AddListener(UpdateFilter);
		StoneToggleButton.OnToggle.AddListener(UpdateFilter);
		CharcoalToggleButton.OnToggle.AddListener(UpdateFilter);
		IronToggleButton.OnToggle.AddListener(UpdateFilter);
		ToolsToggleButton.OnToggle.AddListener(UpdateFilter);
		ArmamentToggleButton.OnToggle.AddListener(UpdateFilter);
	}

	private void UpdateFilter()
	{
		Cell cellSelected = GameUI.inst.GetCellSelected();
		if (cellSelected == null)
		{
			return;
		}
		Building topMostStructure = cellSelected.TopMostStructure;
		if (!(topMostStructure != null))
		{
			return;
		}
		IResourceFilterable component = topMostStructure.GetComponent<IResourceFilterable>();
		if (component != null)
		{
			ResourceAmount resourceAmount = new ResourceAmount();
			if (WoodToggleButton.State)
			{
				resourceAmount.Add(1, 1);
			}
			if (StoneToggleButton.State)
			{
				resourceAmount.Add(2, 1);
			}
			if (CharcoalToggleButton.State)
			{
				resourceAmount.Add(3, 1);
			}
			if (IronToggleButton.State)
			{
				resourceAmount.Add(5, 1);
			}
			if (ToolsToggleButton.State)
			{
				resourceAmount.Add(6, 1);
			}
			if (ArmamentToggleButton.State)
			{
				resourceAmount.Add(7, 1);
			}
			component.ResourceFilter = resourceAmount;
		}
	}

	public void UpdateForNewSelection()
	{
		if (GameUI.inst.SelectedBuildingIs<IResourceFilterable>())
		{
			IResourceFilterable component = GameUI.inst.GetBuildingSelected().GetComponent<IResourceFilterable>();
			if (component != null)
			{
				ResourceAmount resourceFilter = component.ResourceFilter;
				WoodToggleButton.InitTo(resourceFilter.Get(1) > 0);
				StoneToggleButton.InitTo(resourceFilter.Get(2) > 0);
				CharcoalToggleButton.InitTo(resourceFilter.Get(3) > 0);
				IronToggleButton.InitTo(resourceFilter.Get(5) > 0);
				ToolsToggleButton.InitTo(resourceFilter.Get(6) > 0);
				ArmamentToggleButton.InitTo(resourceFilter.Get(7) > 0);
			}
		}
	}

	void IWorkerUIElement.TryShow()
	{
		gameObject.SetActive(CanShow());
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs<IResourceFilterable>();
	}
}
