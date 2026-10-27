using System;
using UnityEngine;

public class ButterflyManager : MonoBehaviour
{
	public enum BugType
	{
		Butterflies,
		Fireflies
	}

	private enum Status
	{
		Init,
		Spawning
	}

	public BugType bugType;

	public ParticleSystem butterflyPrefab;

	private ParticleSystem butterflies;

	private Status status;

	private Vector3 start;

	private Vector3 end;

	private Cell[] neighbors = new Cell[8];

	private float totalTime;

	public bool debugDraw;

	private void Start()
	{
		butterflies = UnityEngine.Object.Instantiate(butterflyPrefab.gameObject).GetComponent<ParticleSystem>();
	}

	private void Update()
	{
		if (LoadSave.Loading || !World.inst.Inited)
		{
			return;
		}
		totalTime += Time.deltaTime;
		switch (status)
		{
		case Status.Init:
		{
			Vector3 trackingPos = Cam.inst.TrackingPos;
			Ray ray = Cam.inst.cam.ScreenPointToRay(Cam.inst.cam.ViewportToScreenPoint(new Vector3(0f, 0.5f)));
			Ray ray2 = Cam.inst.cam.ScreenPointToRay(Cam.inst.cam.ViewportToScreenPoint(new Vector3(0.5f, 0.5f)));
			Vector3 vector = Vector3.zero;
			Vector3 vector2 = Vector3.zero;
			if (TerrainGen.inst.Raycast(ray, out var hitInfo))
			{
				vector = hitInfo.point;
			}
			if (debugDraw)
			{
				DebugEx.DrawSphere(vector, 2.5f, Color.red);
			}
			if (TerrainGen.inst.Raycast(ray2, out hitInfo))
			{
				vector2 = hitInfo.point;
			}
			if (debugDraw)
			{
				DebugEx.DrawSphere(vector2, 2.5f, Color.red);
			}
			int num3 = 20;
			float num4 = Mathff.Dist(vector, vector2) * 1.5f;
			do
			{
				num3--;
				float num5 = SRand.Range(num4 / 2f, num4);
				float f = SRand.Range(0f, MathF.PI * 2f);
				start = trackingPos + new Vector3(Mathf.Cos(f) * num5, 0f, Mathf.Sin(f) * num5);
				TerrainGen.inst.GetGroundHeight(ref start);
				num5 = SRand.Range(1f, num4 / 4f);
				f = SRand.Range(0f, MathF.PI * 2f);
				end = trackingPos + new Vector3(Mathf.Cos(f) * num5, 0f, Mathf.Sin(f) * num5);
				TerrainGen.inst.GetGroundHeight(ref end);
				butterflies.transform.position = start;
			}
			while ((World.inst.GetCellDataClamped(start).HasAnyWater() || World.inst.GetCellDataClamped(end).HasAnyWater()) && num3 > 0);
			ParticleSystem.EmissionModule emission2 = butterflies.emission;
			emission2.rateOverTime = 10f;
			totalTime = 0f;
			status = Status.Spawning;
			break;
		}
		case Status.Spawning:
		{
			if (debugDraw)
			{
				DebugEx.DrawSphere(start, 1.5f, Color.red);
				DebugEx.DrawSphere(end, 1.5f, Color.yellow);
				Debug.DrawLine(start, end, Color.red);
			}
			float num = Vector3.Distance(start, end);
			Vector3 curr = Vector3.Lerp(start, end, totalTime / num);
			curr = Mathff.MoveTowards(curr, end, 2f * Time.deltaTime);
			curr += new Vector3(Mathf.Cos(totalTime * 0.5f), 0f, Mathf.Sin(totalTime * 0.5f)) * 3f;
			if (debugDraw)
			{
				DebugEx.DrawSphere(curr, 0.5f, Color.red);
			}
			Vector3 pos = curr;
			TerrainGen.inst.GetGroundHeight(ref pos);
			if (bugType == BugType.Fireflies)
			{
				pos.y += 0.5f;
			}
			else
			{
				pos.y++;
			}
			butterflies.transform.position = pos;
			ParticleSystem.EmissionModule emission = butterflies.emission;
			Cell cellDataClamped = World.inst.GetCellDataClamped(curr);
			bool flag = false;
			bool flag2 = false;
			World.inst.GetNeighborCellsExtended(cellDataClamped, ref neighbors);
			for (int i = 0; i < neighbors.Length; i++)
			{
				if (neighbors[i] != null)
				{
					if (neighbors[i].OccupyingStructure.Count > 0)
					{
						flag2 = true;
					}
					if (World.inst.treeSystem.ItemAmount(neighbors[i]) > 0)
					{
						flag = true;
					}
				}
			}
			float num2 = 10f;
			bool flag3 = false;
			if (bugType == BugType.Butterflies)
			{
				flag3 = DayNightManager.inst.GameParameters.isDay;
				if (SeasonManager.inst.CurrentSeason.id == 1)
				{
					emission.rateOverTime = 5f;
				}
			}
			else if (bugType == BugType.Fireflies)
			{
				flag3 = !DayNightManager.inst.GameParameters.isDay & flag;
				if (SeasonManager.inst.CurrentSeason.id == 1 || SeasonManager.inst.CurrentSeason.id == 3)
				{
					emission.rateOverTime = 5f;
				}
			}
			if (flag2 || cellDataClamped.HasAnyWater() || cellDataClamped.Type == TerrainType.Obstruction || cellDataClamped.OccupyingStructure.Count > 0 || SeasonManager.inst.CurrentSeason.id == 2 || !flag3)
			{
				emission.rateOverTime = 0f;
			}
			else
			{
				emission.rateOverTime = num2;
			}
			if (debugDraw)
			{
				DebugEx.DrawSphere(pos, 0.25f, (emission.rateOverTime.constant > 0f) ? Color.green : Color.red);
			}
			if (totalTime > num)
			{
				status = Status.Init;
				emission.rateOverTime = 0f;
			}
			break;
		}
		}
	}
}
