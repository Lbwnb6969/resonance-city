using I2.Loc;

public class PlaguedJob : Job
{
	public enum Status
	{
		HeadingTo,
		Healing
	}

	public Status status;

	public PlaguedJob(IEmployer e)
		: base(e)
	{
		ManualAssignment = true;
		ManualFreetime = true;
	}

	public override string GetDescription()
	{
		if (HasEmployee())
		{
			switch (status)
			{
			case Status.HeadingTo:
				return LocalizationManager.GetTranslation("plaguedjob_headingto_status_description");
			case Status.Healing:
				return LocalizationManager.GetTranslation("plaguedjob_healing_status_description");
			}
		}
		return string.Empty;
	}

	public override void OnEmployeeAssigned()
	{
		base.OnEmployeeAssigned();
		status = Status.HeadingTo;
	}

	public override void UpdateWithEmployee(float dt)
	{
		base.UpdateWithEmployee(dt);
		if (status == Status.HeadingTo && !Employee.IsMoving() && Mathff.DistSqrdXZ(Employee.Pos, Employee.GetWorkPosition().position) < 1f)
		{
			status = Status.Healing;
		}
	}
}
