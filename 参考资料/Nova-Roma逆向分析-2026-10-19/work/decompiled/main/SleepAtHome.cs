using Assets.Code.Jobs;

public class SleepAtHome : FreeTimeRoutine
{
	public static float sleepRequired = 2f;

	public bool gotHome = true;

	private float timeArrived;

	public override void Init(Villager v)
	{
		base.Init(v);
		if (_v.Residence != null)
		{
			_v.MoveToDeferred(_v.Residence.GetPositionForPerson(_v));
		}
	}

	public override void OnFinishedPath()
	{
		base.OnFinishedPath();
		if (active)
		{
			gotHome = true;
			timeArrived = DayNightManager.inst.GameParameters._24HourTime;
		}
	}

	public override void End()
	{
		base.End();
		if (_v.job != null && DoTiredCheckForCategory(_v.job.jobCategory))
		{
			if (_v.Residence != null && DoTiredCheckForJob(_v.job))
			{
				if (!gotHome)
				{
					_v.AddTiredness();
				}
				else
				{
					float num = DayNightManager.inst.GameParameters._24HourTime;
					if (timeArrived > num)
					{
						num += 24f;
					}
					if (num - timeArrived >= sleepRequired)
					{
						_v.ResetTiredness();
					}
					else
					{
						_v.AddTiredness();
					}
				}
			}
			else
			{
				_v.ResetTiredness();
			}
		}
		gotHome = false;
	}

	private bool DoTiredCheckForCategory(int jobCategory)
	{
		if (jobCategory != 1 && jobCategory != 36 && jobCategory != 12)
		{
			return jobCategory != 37;
		}
		return false;
	}

	private bool DoTiredCheckForJob(Job job)
	{
		if (!(job is DeliveryJob))
		{
			return !(job is GraveWorkerJob);
		}
		return false;
	}
}
