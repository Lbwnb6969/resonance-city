using UnityEngine;

public class LeisureActivity : FreeTimeRoutine
{
	private Job idleJob;

	public override void Init(Villager v)
	{
		base.Init(v);
		TryFindLeisureActivity();
	}

	private void TryFindLeisureActivity()
	{
		Vector3 pos = _v.Pos;
		if (_v.Residence != null)
		{
			pos = _v.Residence.GetPosition();
		}
		idleJob = JobSystem.inst.FindIdleJob(_v.landMass, pos, 10);
		if (idleJob != null)
		{
			idleJob.ShadowAssignEmployee(_v);
		}
		else
		{
			End();
		}
	}

	public override void Update(float dt)
	{
		if (_v.job != null && _v.job.employer is Building { workStartHour: var workStartHour } && 24f - DayNightManager.inst.GameParameters._24HourTime + workStartHour < SleepAtHome.sleepRequired * 2.5f)
		{
			End();
		}
		else if (idleJob != null && idleJob.employer is Building building2 && (!building2.DuringWorkHours(0f) || (building2.WorkersForFullYield > 0 && building2.WorkersAllocated <= 0)))
		{
			ReleaseIdleJob();
			TryFindLeisureActivity();
		}
		else
		{
			base.Update(dt);
		}
	}

	public override void End()
	{
		if (idleJob != null)
		{
			ReleaseIdleJob();
		}
		base.End();
	}

	private void ReleaseIdleJob()
	{
		idleJob.OnEmployeeQuit();
		idleJob.Employee = null;
		idleJob = null;
	}
}
