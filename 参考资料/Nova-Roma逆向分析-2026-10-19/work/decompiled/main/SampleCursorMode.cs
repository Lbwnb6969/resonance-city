public class SampleCursorMode : CursorMode
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
		return GameUI.inst.TryCopyHoveredBuilding();
	}
}
