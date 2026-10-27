using System.Collections.Generic;
using UnityEngine;

namespace Assets;

public class StreamerEffect_DestroyAnUnusableStone : StreamerEffect, ICamTrackable
{
	private Cell targetCell;

	private Cell[] scratch4 = new Cell[4];

	private Timer cameraTargetFixTimer = new Timer(1.3f);

	public new static string GetTermSegment()
	{
		return "DestroyAnUnusableStone";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\destroyanunusablestone");
		TimerText.enabled = false;
		Timer.Duration = 10f;
		List<Cell> list = new List<Cell>(100);
		for (int i = 0; i < World.inst.GridWidth; i++)
		{
			for (int j = 0; j < World.inst.GridHeight; j++)
			{
				Debug.Log("Reminder that we disabled this behavior temporarily!");
			}
		}
		if (list.Count > 0)
		{
			targetCell = list[SRand.Range(0, list.Count)];
		}
		if (targetCell == null)
		{
			Done();
		}
		else
		{
			Cam.inst.Track(this);
		}
	}

	public override void OnEnd()
	{
	}

	public override void OnUpdate()
	{
		if (cameraTargetFixTimer.Update(Time.unscaledDeltaTime))
		{
			Debug.Log("Reminder that we disabled this behavior temporarily!");
			Done();
		}
	}

	public Vector3 GetDesiredTrackingPos()
	{
		return targetCell.Center2D;
	}
}
