using System.Collections.Generic;
using I2.Loc;
using UnityEngine;

namespace Assets.Code.Jobs;

public class GraveWorkerJob : Job
{
	private enum Status
	{
		Searching,
		GoingToResource,
		TakingToDropoff,
		TimeOff
	}

	public static List<GraveWorkerJob> ActiveGraveWorkerJobs = new List<GraveWorkerJob>(20);

	private Cemetery dropoffTarget;

	private Vector3 dropoffPosition;

	private FrameUpdater pathUpdate;

	private static int searchUpdateID = 0;

	private Status status;

	private bool storageTooFarAway;

	private Cemetery tempEmployer;

	private bool forceUpdatePath;

	public DeadVillager assignedBody;

	private bool reported;

	public GraveWorkerJob(IEmployer e)
		: base(e)
	{
		pathUpdate = new FrameUpdater(ref searchUpdateID, 30);
		ManualFreetime = true;
		ActiveGraveWorkerJobs.Add(this);
	}

	public bool NoNearbyStorage()
	{
		if (storageTooFarAway && status == Status.TakingToDropoff)
		{
			return dropoffTarget == null;
		}
		return false;
	}

	private void TransitionToSearching()
	{
		assignedBody = null;
		status = Status.Searching;
		Employee.MoveToDeferred(employer.GetPositionForPerson(Employee));
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.Searching:
			text += ScriptLocalization.jobGraveDescriptionSearching;
			break;
		case Status.GoingToResource:
			text += ScriptLocalization.jobGraveDescriptionFetching;
			break;
		case Status.TakingToDropoff:
			text += ScriptLocalization.jobGraveDescriptionReturning;
			break;
		}
		return text;
	}

	private void ReleaseBody()
	{
		if (assignedBody != null)
		{
			assignedBody.Drop();
		}
		assignedBody = null;
	}

	public override void OnEmployeeAssigned()
	{
		TransitionToSearching();
		storageTooFarAway = false;
		Employee.speedBonusMultiplier = 1.5f;
		base.OnEmployeeAssigned();
	}

	public override void OnJobRemoved()
	{
		ReleaseBody();
		ActiveGraveWorkerJobs.Remove(this);
		base.OnJobRemoved();
	}

	private Cemetery GetEmployerStorage()
	{
		storageTooFarAway = false;
		if (Cemetery.CemeteriesForLandMass(employer.LandMass()).Count > 0)
		{
			CemeteryKeeper component = (employer as Building).GetComponent<CemeteryKeeper>();
			Cemetery result = null;
			int num = int.MaxValue;
			ArrayExt<Cemetery> arrayExt = Cemetery.CemeteriesForLandMass(employer.LandMass());
			for (int i = 0; i < arrayExt.Count; i++)
			{
				if (!arrayExt.data[i].b.IsBuilt() || arrayExt.data[i].GravesAvailable() <= 0 || !component.TryGetCemeteryDistance(arrayExt.data[i].b, out var distance))
				{
					continue;
				}
				if (distance < 90f)
				{
					if (distance < (float)num)
					{
						result = arrayExt.data[i];
						num = (int)distance;
					}
				}
				else
				{
					storageTooFarAway = true;
				}
			}
			return result;
		}
		return null;
	}

	public void DropOff()
	{
		status = Status.TakingToDropoff;
		forceUpdatePath = true;
	}

	public static void AssignGraveWorker(DeadVillager villager)
	{
		Vector3 pos = villager.Pos;
		GraveWorkerJob graveWorkerJob = null;
		float num = float.MaxValue;
		int i = 0;
		for (int count = ActiveGraveWorkerJobs.Count; i < count; i++)
		{
			GraveWorkerJob graveWorkerJob2 = ActiveGraveWorkerJobs[i];
			if (graveWorkerJob2.employer.LandMass() == villager.landmass && !(graveWorkerJob2.Employee == null) && graveWorkerJob2.assignedBody == null)
			{
				float num2 = Mathff.DistSqrdXZ(graveWorkerJob2.employer.GetPosition(), pos);
				if (num2 < num)
				{
					graveWorkerJob = graveWorkerJob2;
					num = num2;
				}
			}
		}
		if (graveWorkerJob != null)
		{
			graveWorkerJob.assignedBody = villager;
			villager.graveKeeper = graveWorkerJob;
		}
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		pathUpdate.Update();
		switch (status)
		{
		case Status.Searching:
			if (assignedBody != null)
			{
				status = Status.GoingToResource;
				villager.MoveToDeferred(assignedBody.Pos);
			}
			else if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
			}
			break;
		case Status.GoingToResource:
			if (assignedBody == null)
			{
				TransitionToSearching();
				break;
			}
			if (Mathff.DistSqrd(villager.Pos, assignedBody.Pos) < 0.0625f)
			{
				assignedBody.isHeld = true;
				DropOff();
				return;
			}
			if (pathUpdate.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				villager.MoveToDeferred(assignedBody.Pos);
			}
			break;
		case Status.TakingToDropoff:
			if (assignedBody == null)
			{
				Debug.LogError("Lost body some how");
				TransitionToSearching();
				break;
			}
			if (dropoffTarget == null)
			{
				dropoffTarget = GetEmployerStorage();
				if ((bool)dropoffTarget)
				{
					reported = false;
				}
			}
			if (dropoffTarget != null && dropoffTarget.GravesAvailable() <= 0)
			{
				dropoffTarget = null;
				if (!reported)
				{
					Player.inst.ReportCemeteriesFull((employer as MonoBehaviour).GetComponent<Building>());
					reported = true;
				}
			}
			if (dropoffTarget != null && Mathff.DistSqrd(villager.Pos, dropoffPosition) < 0.010000001f)
			{
				dropoffTarget.BuryPerson(assignedBody);
				dropoffTarget = null;
				assignedBody.Shutdown();
				TransitionToSearching();
			}
			else if (pathUpdate.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				if (dropoffTarget != null)
				{
					dropoffPosition = dropoffTarget.FirstOpenGravePosition();
					villager.MoveToDeferred(dropoffPosition);
				}
			}
			break;
		case Status.TimeOff:
			if (employer.DuringWorkHours() || assignedBody != null)
			{
				Employee.FreeTime(_freeTime: false);
				status = Status.Searching;
			}
			else
			{
				Employee.FreeTime(_freeTime: true);
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}

	public override void OnEmployeeQuit()
	{
		Employee.speedBonusMultiplier = 1f;
		ReleaseBody();
		base.OnEmployeeQuit();
	}
}
