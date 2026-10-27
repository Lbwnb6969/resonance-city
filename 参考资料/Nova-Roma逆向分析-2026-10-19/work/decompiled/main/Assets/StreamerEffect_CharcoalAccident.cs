using Assets.Code;
using UnityEngine;

namespace Assets;

public class StreamerEffect_CharcoalAccident : StreamerEffect, ICamTrackable
{
	private Cell targetCell;

	private Timer cameraTargetFixTimer = new Timer(1.3f);

	private Cell[] scratchCells = new Cell[8];

	public new static bool PrereqSatisfied()
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("charcoalmaker", mustBeBuilt: true);
	}

	public new static string GetTermSegment()
	{
		return "CharcoalAccident";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\charcoalaccident");
		Timer.Enabled = false;
		TimerText.enabled = false;
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("charcoalmaker");
		if (buildingList.Count == 0)
		{
			Done();
			return;
		}
		targetCell = buildingList.RandomElement().GetCell();
		Cam.inst.Track(this);
	}

	public override void OnUpdate()
	{
		if (!cameraTargetFixTimer.Update(Time.unscaledDeltaTime))
		{
			return;
		}
		FireManager.inst.StartFireAt(targetCell);
		World.inst.GetNeighborCellsExtended(targetCell, ref scratchCells);
		for (int i = 0; i < scratchCells.Length; i++)
		{
			if (scratchCells[i] != null)
			{
				FireManager.inst.StartFireAt(scratchCells[i]);
			}
		}
		Done();
	}

	public override void OnEnd()
	{
	}

	public Vector3 GetDesiredTrackingPos()
	{
		return targetCell.Center2D;
	}
}
