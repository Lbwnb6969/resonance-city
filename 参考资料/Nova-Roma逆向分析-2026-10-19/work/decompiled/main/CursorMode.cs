public class CursorMode
{
	public virtual void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
	}

	public virtual void HandlePrimaryUp()
	{
	}

	public virtual void HandlePrimaryDown()
	{
	}

	public virtual bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		return false;
	}

	public virtual bool DoSecondaryClick()
	{
		return false;
	}

	public virtual void Tick(float dt)
	{
	}

	public virtual void LateTick()
	{
	}

	public virtual void Shutdown()
	{
	}

	public virtual void Init()
	{
	}

	public virtual bool ShowDragSelectBounds()
	{
		return true;
	}

	public virtual bool ShowCellHighlighter()
	{
		return true;
	}

	public virtual bool ShowBuildingHighlight(ISelectableBuilding b)
	{
		return true;
	}

	public virtual bool DoClearSelectedCellOnInit()
	{
		return true;
	}

	public virtual bool HideThoughtBubble()
	{
		return false;
	}
}
