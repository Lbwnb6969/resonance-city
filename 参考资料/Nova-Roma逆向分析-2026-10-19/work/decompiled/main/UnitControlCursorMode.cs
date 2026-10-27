using System.Collections.Generic;
using UnityEngine;

public class UnitControlCursorMode : CursorMode
{
	public static List<ISelectable> scratchSelectables = new List<ISelectable>(32);

	public override void Init()
	{
		InWorldExclamation.hideForCursorMode = true;
		base.Init();
		UnitUI.inst.SetVisibility(v: true);
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		base.Shutdown();
		UnitControlSystem.inst.ClearSelection();
		UnitUI.inst.SetVisibility(v: false);
	}

	public override bool ShowCellHighlighter()
	{
		if (GameUI.inst.highlightedObjs.Count > 0)
		{
			return false;
		}
		return true;
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		if (UnitControlSystem.inst.TrySelectHighlightObjects(GameUI.inst.highlightedObjs))
		{
			return true;
		}
		GameUI.inst.ReturnToDefaultCursorMode();
		return false;
	}

	public override bool DoSecondaryClick()
	{
		if (GameUI.inst.PointerOverUI())
		{
			return true;
		}
		Vector3 vector = GameUI.inst.GridPointerIntersection();
		Cell targetCell = World.inst.GetCellData(vector);
		ISelectableBuilding highlightedBuilding = GameUI.inst.GetHighlightedBuilding();
		if (highlightedBuilding != null)
		{
			vector = highlightedBuilding.Center();
			targetCell = World.inst.GetCellDataClamped(vector);
		}
		UnitControlSystem.inst.DoPlayerMoveTo(vector, targetCell);
		return true;
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		scratchSelectables.Clear();
		UnitControlSystem.inst.TryAddHighlights(minX, minZ, maxX, maxZ, ref scratchSelectables);
		if (!UnitControlSystem.inst.TrySelectHighlightObjects(scratchSelectables))
		{
			GameUI.inst.ReturnToDefaultCursorMode();
		}
	}

	public override void Tick(float dt)
	{
		if (UnitControlSystem.inst.currSelection.Count > 0)
		{
			ArrayExt<IUnitControllable> customCurrSelection = UnitControlSystem.inst.customCurrSelection;
			ArrayExt<IUnitControllable> currSelection = UnitControlSystem.inst.currSelection;
			for (int i = 0; i < currSelection.Count; i++)
			{
				IUnitControllable unitControllable = currSelection.data[i];
				if (UnitControlSystem.inst.isCustomSelection)
				{
					((ISelectable)unitControllable).SetHighlightImmediate(customCurrSelection.Contains(unitControllable) ? 1 : 0);
				}
				else if (UnitUI.inst.IsGroupSelected(0) && unitControllable == UnitAllGroupUI.inst.currHoveredUnit)
				{
					((ISelectable)unitControllable).SetHighlightImmediate(0);
				}
				else
				{
					((ISelectable)unitControllable).SetHighlightImmediate(1);
				}
			}
		}
		else
		{
			GameUI.inst.ReturnToDefaultCursorMode();
		}
	}
}
