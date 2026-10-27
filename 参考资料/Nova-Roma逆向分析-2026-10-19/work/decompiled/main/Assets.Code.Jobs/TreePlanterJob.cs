using System.Collections.Generic;
using I2.Loc;
using UnityEngine;

namespace Assets.Code.Jobs;

internal class TreePlanterJob : Job
{
	private enum Status
	{
		FindTile,
		GoingToTile,
		Planting,
		TimeOff
	}

	private Status status;

	private Forester forester;

	private float totalTime;

	private Vector3 oldPos;

	private Vector3 workPos;

	private Timer posUpdate = new Timer(1f);

	private Cell cellToPlant;

	private List<Cell> validTreeBuffer = new List<Cell>();

	public TreePlanterJob(IEmployer e)
		: base(e)
	{
		if (e is Building)
		{
			forester = (e as Building).GetComponent<Forester>();
		}
		ManualFreetime = true;
	}

	private void Reset()
	{
		status = Status.FindTile;
		cellToPlant = null;
		validTreeBuffer.Clear();
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.FindTile:
			text += ScriptLocalization.jobPlanterDescriptionSearching;
			break;
		case Status.GoingToTile:
			text += ScriptLocalization.jobPlanterDescriptionTraveling;
			break;
		case Status.Planting:
			text += ScriptLocalization.jobPlanterDescriptionPlanting;
			break;
		}
		return text;
	}

	public override void OnEmployeeAssigned()
	{
		Reset();
		base.OnEmployeeAssigned();
	}

	public override void OnEmployeeQuit()
	{
		Reset();
		base.OnEmployeeQuit();
	}

	public override void OnJobRemoved()
	{
		Reset();
		base.OnJobRemoved();
	}

	public void GetNonBusyCellInRadius(Vector3 s, float r, ref List<Cell> results)
	{
		results.Clear();
		int num = (int)s.x;
		int num2 = (int)s.z;
		int num3 = (int)r;
		int num4 = Mathf.Max(num - num3, 0);
		int num5 = Mathf.Max(num2 - num3, 0);
		int num6 = Mathf.Min(num + num3, World.inst.GridWidth - 1);
		int num7 = Mathf.Min(num2 + num3, World.inst.GridHeight - 1);
		for (int i = num4; i <= num6; i++)
		{
			for (int j = num5; j <= num7; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i, j);
				if (!cellDataUnsafe.Busy && !EditTerrainProjectManager.inst.IsCellPartOfProject(cellDataUnsafe, out var _) && World.inst.TileTouchingRadius(cellDataUnsafe, s, r))
				{
					results.Add(cellDataUnsafe);
				}
			}
		}
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		switch (status)
		{
		case Status.FindTile:
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
				break;
			}
			GetNonBusyCellInRadius(forester.GetComponent<Building>().Center(), forester.Radius, ref validTreeBuffer);
			if (validTreeBuffer.Count > 0)
			{
				cellToPlant = validTreeBuffer[SRand.Range(0, validTreeBuffer.Count)];
				if (World.inst.treeSystem.ItemAmount(cellToPlant) > 0 || World.inst.coppiceTreeSystem.ItemAmount(cellToPlant) > 0)
				{
					cellToPlant = validTreeBuffer[SRand.Range(0, validTreeBuffer.Count)];
				}
				if (cellToPlant != null && TreeGrowth.IsValidForTreePlanting(cellToPlant))
				{
					status = Status.GoingToTile;
					villager.MoveToDeferred(cellToPlant.Center3D);
				}
			}
			break;
		case Status.GoingToTile:
		{
			if (!(Mathff.DistSqrdXZ(villager.Pos, cellToPlant.Center3D) < 0.1f))
			{
				break;
			}
			if (TreeGrowth.IsValidForTreePlanting(cellToPlant) && !EditTerrainProjectManager.inst.IsCellPartOfProject(cellToPlant, out var _))
			{
				World.inst.treeSystem.GrowTree(cellToPlant);
				if ((bool)forester && forester.toolUsage > 0)
				{
					World.inst.treeSystem.GrowTree(cellToPlant);
				}
			}
			status = Status.Planting;
			oldPos = (workPos = villager.Pos);
			totalTime = 0f;
			break;
		}
		case Status.Planting:
		{
			totalTime += dt;
			if (posUpdate.Update(dt))
			{
				posUpdate.Duration = SRand.Range(0.5f, 4f);
				workPos = cellToPlant.Center3D;
				workPos += new Vector3(SRand.Range(-0.2f, 0.2f), 0f, SRand.Range(-0.2f, 0.2f));
				oldPos = villager.Pos;
			}
			float t = Mathf.Clamp01(posUpdate.CurrTime * 0.66f);
			villager.Pos = Vector3.Lerp(oldPos, workPos, Mathf.SmoothStep(0f, 1f, t));
			if (totalTime > 5f)
			{
				cellToPlant = null;
				status = Status.FindTile;
			}
			break;
		}
		case Status.TimeOff:
			if (employer.DuringWorkHours())
			{
				Employee.FreeTime(_freeTime: false);
				status = Status.FindTile;
			}
			else
			{
				Employee.FreeTime(_freeTime: true);
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}
}
