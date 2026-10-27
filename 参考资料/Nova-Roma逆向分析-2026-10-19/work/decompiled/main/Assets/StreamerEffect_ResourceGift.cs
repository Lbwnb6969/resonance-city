using System.Collections.Generic;
using UnityEngine;

namespace Assets;

public class StreamerEffect_ResourceGift : StreamerEffect, ICamTrackable
{
	private Cell targetCell;

	private Timer cameraTargetFixTimer = new Timer(1.3f);

	public new static string GetTermSegment()
	{
		return "";
	}

	protected virtual int ResType()
	{
		return -1;
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\betterbarracks");
		TimerText.enabled = false;
		Timer.Duration = 10f;
		if (Player.inst.keep == null)
		{
			Done();
			return;
		}
		Cell cell = Player.inst.keep.GetComponent<Building>().GetCell();
		int num = 10;
		List<Cell> list = new List<Cell>(100);
		for (int i = cell.z - num; i < cell.z + num; i++)
		{
			for (int j = cell.x - num; j < cell.x + num; j++)
			{
				Cell cellData = World.inst.GetCellData(j, i);
				if (cellData != null && cellData.Type == TerrainType.None && cellData.TopMostStructure == null && World.inst.treeSystem.ItemAmount(cellData) == 0)
				{
					list.Add(cellData);
				}
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
			EffectsMan.inst.RemoveStonePoof.CreateAndPlay(targetCell.Position.xz());
			EffectsMan.inst.HealthEffect.CreateAndPlay(targetCell.Center2D.xz());
			Weather.inst.LightningStrike(targetCell.Center2D.xz(), doFire: false, smallstrike: true);
			FreeResourceManager.inst.GetAutoStackFor(ResType(), 100, targetCell.Center2D);
			Done();
		}
	}

	public Vector3 GetDesiredTrackingPos()
	{
		return targetCell.Center2D;
	}
}
