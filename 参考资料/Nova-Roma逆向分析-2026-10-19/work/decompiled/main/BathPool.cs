using System;
using UnityEngine;

public class BathPool : MonoBehaviour
{
	[NonSerialized]
	public Building b;

	[NonSerialized]
	protected AdjacentMesh adjMesh;

	protected bool hasWater;

	public static int wConsumption = 1;

	protected bool isIdleJobsEnabled;

	public bool HasWater()
	{
		return hasWater;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		adjMesh = GetComponent<AdjacentMesh>();
		adjMesh.shouldConnect = ShouldConnect;
		AwakeInternal();
	}

	protected virtual void AwakeInternal()
	{
	}

	private void OnInit()
	{
		adjMesh.shouldConnect = ShouldConnect;
	}

	public virtual void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			if (LoadSave.Loading && b.IsBuilt())
			{
				BathManager.inst.Register(b);
			}
		}
		else if (b.IsBuilt())
		{
			BathManager.inst.Deregister(b);
		}
	}

	public virtual void OnBuilt()
	{
		BathManager.inst.Register(b);
	}

	public bool ShouldConnect(Cell c)
	{
		if (c == null)
		{
			return false;
		}
		Building building = GameUI.inst.CurrPlacementMode.buildingMap[c.index];
		if (building != null)
		{
			return b.categoryHash == building.categoryHash;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].categoryHash == b.categoryHash)
			{
				return true;
			}
		}
		return false;
	}

	public virtual void UpdateWater(bool doWater)
	{
		bool flag = hasWater != doWater;
		hasWater = doWater;
		if (flag)
		{
			TryEnableIdleJobs();
		}
	}

	public virtual void OnAddJobs()
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				IdleJob idleJob = new IdleJob(b, IdleJob.IdleBehavior.Bathing);
				idleJob.ManualAssignment = true;
				idleJob.SetWanderSettings(0.15f, 0.15f);
				b.SetAndAddJob(i, idleJob);
			}
		}
	}

	public virtual void TryEnableIdleJobs()
	{
		if (hasWater && !isIdleJobsEnabled)
		{
			for (int i = 0; i < b.attractionJobs.Count; i++)
			{
				b.attractionJobs[i].ManualAssignment = false;
			}
			isIdleJobsEnabled = true;
		}
		else
		{
			if (hasWater || !isIdleJobsEnabled)
			{
				return;
			}
			for (int j = 0; j < b.attractionJobs.Count; j++)
			{
				Job job = b.attractionJobs[j];
				job.ManualAssignment = true;
				if (job.HasEmployee())
				{
					job.ReleaseEmployee();
				}
			}
			isIdleJobsEnabled = false;
		}
	}
}
