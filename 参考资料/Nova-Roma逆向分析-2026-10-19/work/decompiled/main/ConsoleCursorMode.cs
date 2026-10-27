public class ConsoleCursorMode : CursorMode
{
	public override void Init()
	{
		InWorldExclamation.hideForCursorMode = true;
		base.Init();
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		base.Shutdown();
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		if (clickedCell != null && (World.inst.treeSystem.ItemAmount(clickedCell) > 0 || World.inst.rockScatterSystem.ItemAmount(clickedCell) > 0))
		{
			GameUI.inst.SetSelectedBuildingNew(clickedBuilding);
			if (GameUI.inst.GetClearCutterJob(clickedCell) != null)
			{
				GameUI.inst.RemoveChopJobFromCell(clickedCell);
			}
			else
			{
				GameUI.inst.AddChopJobToCell(clickedCell);
			}
		}
		if (!GameUI.inst.CurrPlacementMode.IsPlacing() && clickedBuilding != null)
		{
			ConsoleTileUI.inst.SetVisible(v: false);
		}
		else if (clickedCell != null)
		{
			ConsoleTileUI.inst.UpdateSelectedCellVisuals(null, clickedCell);
		}
		return false;
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
	}
}
