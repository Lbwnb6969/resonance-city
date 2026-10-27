using System.Collections.Generic;
using UnityEngine;

namespace Assets;

public class StreamerEffect_PopulationBoost : StreamerEffect, ICamTrackable
{
	private Cell targetCell;

	private Timer cameraTargetFixTimer = new Timer(1.3f);

	public new static string GetTermSegment()
	{
		return "PopulationBoost";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\populationboost");
		Timer.Enabled = false;
		TimerText.enabled = false;
		if (Player.inst.keep == null)
		{
			Done();
			return;
		}
		Cell cell = Player.inst.keep.GetComponent<Building>().GetCell();
		int num = 15;
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

	public override void OnUpdate()
	{
		if (cameraTargetFixTimer.Update(Time.unscaledDeltaTime))
		{
			EffectsMan.inst.HealthEffect.CreateAndPlay(targetCell.Center2D.xz());
			SfxSystem.inst.PlayFromBank("StreamerEffectPopulationBoost", targetCell.Center2D);
			int b = Mathf.CeilToInt((float)Player.inst.TotalWorkers() * 0.5f);
			int num = Mathf.Min(50, b);
			int num2 = Mathf.CeilToInt(Mathf.Sqrt(num));
			float num3 = 0.1125f;
			List<Vector3> list = new List<Vector3>();
			Vector3 vector = default;
			for (int i = 0; i < num; i++)
			{
				float num4 = i % num2;
				float num5 = i / num2;
				Vector3 vector2 = new Vector3(num5 * num3, 0f, num4 * num3);
				Vector3 item = targetCell.Position + vector2;
				vector += vector2;
				list.Add(item);
			}
			vector /= (float)list.Count;
			for (int j = 0; j < list.Count; j++)
			{
				Player.inst.AddVillager(list[j] + new Vector3(0.5f, 0f, 0.5f) - vector);
			}
			Done();
		}
	}

	public override void OnEnd()
	{
	}

	public Vector3 GetDesiredTrackingPos()
	{
		return targetCell.Center2D;
	}
}
