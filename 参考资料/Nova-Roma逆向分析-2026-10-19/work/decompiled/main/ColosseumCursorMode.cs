using UnityEngine;

public class ColosseumCursorMode : CursorMode
{
	private bool inited;

	internal AddFightWizardUI.GladiatorEntry hoveredEntry;

	public override void Init()
	{
		if (!inited)
		{
			SetUIVisible(v: false);
			inited = true;
		}
		InWorldExclamation.hideForCursorMode = true;
		TimeManager.inst.SetPaused(skipSfx: true);
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		TimeManager.inst.ReturnToPrevious(skipSfx: true);
		if (inited)
		{
			SetUIVisible(v: true);
			inited = false;
		}
	}

	private void SetUIVisible(bool v)
	{
		BuildUI.inst.gameObject.SetActive(v);
		GameUI.inst.islandInfoUI.gameObject.SetActive(v);
		CursorModeUI.inst.gameObject.SetActive(v);
		ProsperityUI.inst.gameObject.SetActive(v);
		SeasonViewer.inst.gameObject.SetActive(v);
		SpeedControlUI.inst.gameObject.SetActive(v);
		MiniMapUI.inst.SetVisibility(v);
	}

	public override bool DoSecondaryClick()
	{
		return true;
	}

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		return false;
	}

	public override bool ShowBuildingHighlight(ISelectableBuilding b)
	{
		return false;
	}

	public override void Tick(float dt)
	{
		AddFightWizardUI fightWizard = ColosseumPlannerUI.inst.fightWizard;
		hoveredEntry = null;
		if (fightWizard.gameObject.activeInHierarchy && !fightWizard.roleSelect && (fightWizard.currentStep == AddFightWizardUI.State.GladiatorSelect || fightWizard.currentStep == AddFightWizardUI.State.OpponentSelect))
		{
			float num = float.MaxValue;
			for (int i = 0; i < fightWizard.gladiatorVisuals.Count; i++)
			{
				AddFightWizardUI.GladiatorEntry gladiatorEntry = fightWizard.gladiatorVisuals[i];
				if (gladiatorEntry.visuals.activeInHierarchy && gladiatorEntry.visuals.GetComponent<Collider>().Raycast(PointingSystem.GetRay(), out var hitInfo, 100f) && num > hitInfo.distance)
				{
					num = hitInfo.distance;
					hoveredEntry = gladiatorEntry;
				}
			}
			if (hoveredEntry != null)
			{
				fightWizard.PopulateGladiatorInfo(hoveredEntry);
				hoveredEntry.visuals.GetComponent<GladiatorVisual>().highlight.SetOutlineImmediate(0);
			}
			else
			{
				fightWizard.gladiatorInfo.ShowInstructions();
			}
		}
		base.Tick(dt);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		AddFightWizardUI fightWizard = ColosseumPlannerUI.inst.fightWizard;
		if (fightWizard.gameObject.activeInHierarchy && !fightWizard.roleSelect && (fightWizard.currentStep == AddFightWizardUI.State.GladiatorSelect || fightWizard.currentStep == AddFightWizardUI.State.OpponentSelect) && hoveredEntry != null)
		{
			if (hoveredEntry.gladiator != null)
			{
				if (!fightWizard.IsFighterAlreadyAssigned(hoveredEntry.gladiator.gladiatorId))
				{
					fightWizard.OnGladiatorSelected(hoveredEntry.gladiator);
				}
			}
			else if (hoveredEntry.beast != null)
			{
				EffectsMan.inst.ChariotSponsorEffect.CreateAndPlay(hoveredEntry.visuals.transform.position);
				fightWizard.OnBeastSelected(hoveredEntry.beast);
			}
		}
		return true;
	}

	public override bool HideThoughtBubble()
	{
		return true;
	}
}
