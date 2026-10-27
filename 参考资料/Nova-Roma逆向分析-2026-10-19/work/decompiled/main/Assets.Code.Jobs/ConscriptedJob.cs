using System;
using I2.Loc;

namespace Assets.Code.Jobs;

public class ConscriptedJob(IEmployer e) : Job(e)
{
	[Serializable]
	public class ConscriptedJobSaveData : JobSaveData<ConscriptedJob, ConscriptedJobSaveData>
	{
		private int status;

		public override ConscriptedJobSaveData Pack(ConscriptedJob j)
		{
			status = j.status;
			return base.Pack(j);
		}

		public override ConscriptedJob Unpack(ConscriptedJob j)
		{
			base.Unpack(j);
			j.SetStatus(status);
			return j;
		}
	}

	public int status;

	public const int STATUS_MOVE_TO_EMPLOYER = 0;

	public const int STATUS_IDLE = 1;

	private TransformData targetData;

	public bool Valid = true;

	private Timer moveUpdate = new Timer(2f);

	public void SetStatus(int s)
	{
		if (s == 0)
		{
			targetData = employer.GetPositionForPerson(Employee);
			Employee.MoveToDeferred(targetData);
		}
		status = s;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		if (status == 0)
		{
			text += ScriptLocalization.jobConscriptDescriptionTraveling;
		}
		return text;
	}

	public override void OnEmployeeAssigned()
	{
		SetStatus(0);
		base.OnEmployeeAssigned();
	}

	public override void OnEmployeeQuit()
	{
		base.OnEmployeeQuit();
	}

	public override void UpdateWithEmployee(float dt)
	{
		switch (status)
		{
		case 0:
			if (Mathff.Dist(targetData.position, Employee.Pos) < 0.1f)
			{
				SetStatus(1);
			}
			else if (!Employee.IsTraveling())
			{
				Employee.MoveToDeferred(targetData);
			}
			break;
		default:
			SetStatus(0);
			break;
		case 1:
			break;
		}
		base.UpdateWithEmployee(dt);
	}
}
