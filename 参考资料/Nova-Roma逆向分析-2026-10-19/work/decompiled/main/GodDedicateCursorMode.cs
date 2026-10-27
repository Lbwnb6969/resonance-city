public class GodDedicateCursorMode : CursorMode
{
	private int godIdx = -1;

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		return false;
	}

	public override bool DoSecondaryClick()
	{
		return true;
	}

	public override bool ShowBuildingHighlight(ISelectableBuilding b)
	{
		return false;
	}

	public override void Init()
	{
		InWorldExclamation.hideForCursorMode = true;
		MiniMapUI.inst.gameObject.SetActive(value: false);
		base.Init();
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		MiniMapUI.inst.gameObject.SetActive(value: true);
		if (godIdx != -1)
		{
			GodUI.inst.godDisplay.gods[godIdx].GetComponent<GodInfoUI>().GetComponent<GodShaderDriver>().SetHighlight(h: true);
			base.Shutdown();
		}
	}

	public override void Tick(float dt)
	{
		GodDisplay godDisplay = GodUI.inst.godDisplay;
		float num = float.MaxValue;
		godIdx = -1;
		for (int i = 0; i < godDisplay.gods.Length; i++)
		{
			godDisplay.gods[i].GetComponent<GodShaderDriver>().SetHighlight(h: false);
			if (godDisplay.gods[i].GetComponent<GodInfoUI>().Raycast(PointingSystem.GetRay(), out var hit) && num > hit.distance)
			{
				num = hit.distance;
				godIdx = i;
			}
		}
		if (godIdx != -1)
		{
			GodInfoUI component = godDisplay.gods[godIdx].GetComponent<GodInfoUI>();
			if (component.disabled)
			{
				component.highlight.SetOutlineImmediate(2);
			}
			else
			{
				component.highlight.SetOutlineImmediate(0);
			}
			component.GetComponent<GodShaderDriver>().SetHighlight(h: true);
			GodUI.inst.UpdateDedicateHoverNameDesc(component);
		}
		base.Tick(dt);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		if (godIdx != -1 && !GodUI.inst.godDisplay.gods[godIdx].GetComponent<GodInfoUI>().disabled)
		{
			GodUI.inst.confirmGodIdx = godIdx;
			GodUI.inst.TransitionTo(GodUI.Status.DedicateConfirm);
			GameUI.inst.ReturnToDefaultCursorMode();
		}
		return true;
	}
}
