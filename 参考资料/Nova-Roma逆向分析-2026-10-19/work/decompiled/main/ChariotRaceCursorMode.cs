using FMOD;
using FMOD.Studio;

public class ChariotRaceCursorMode : CursorMode
{
	public ChariotRaceTrack currTrack;

	public override void Init()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		currTrack = buildingSelected.GetComponent<ChariotRaceTrack>();
		if (currTrack == null)
		{
			GameUI.inst.ReturnToDefaultCursorMode();
			return;
		}
		GameState.inst.AlphaNumericHotkeysEnabled = false;
		Cam.inst.SetDesiredTrackingPos(buildingSelected.Center());
		TimeManager.inst.SetPaused(skipSfx: true);
		ChariotRaceTrackUI.inst.Init(currTrack);
		ChariotRaceTrackUI.inst.SetStatus(0);
		EventInstance ambience = currTrack.b.ambience;
		if (ambience.isValid() && ambience.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			ambience.setPaused(paused: true);
		}
	}

	public override void Shutdown()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = true;
		TimeManager.inst.ReturnToPrevious(skipSfx: true);
		ChariotRaceTrackUI.inst.Shutdown();
		EventInstance ambience = currTrack.b.ambience;
		if (ambience.isValid() && ambience.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			ambience.setPaused(paused: false);
		}
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
	}

	public override void HandlePrimaryUp()
	{
	}

	public override void HandlePrimaryDown()
	{
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		return true;
	}

	public override bool DoSecondaryClick()
	{
		return true;
	}

	public override void Tick(float dt)
	{
	}

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		return false;
	}

	public override bool HideThoughtBubble()
	{
		return true;
	}

	public override bool ShowBuildingHighlight(ISelectableBuilding b)
	{
		return false;
	}
}
