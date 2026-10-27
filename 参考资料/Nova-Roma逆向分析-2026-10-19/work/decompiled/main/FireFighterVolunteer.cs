using Assets.Code.Jobs;
using I2.Loc;

public class FireFighterVolunteer : FireFighter
{
	public FireFighterVolunteer(Fire Owner)
		: base(Owner)
	{
		ManualAssignment = true;
		doSuppress = true;
	}

	public override string GetDescription()
	{
		return LocalizationManager.GetTranslation("jobDescriptionVolunteerFirefighter");
	}

	public override void UpdateAlways(float dt)
	{
		fireTarget = employer as Fire;
		if (!HasEmployee() && ManualAssignment)
		{
			TryGrabEmployee();
			SetCurrTask(Task.NotWorried);
		}
		base.UpdateAlways(dt);
	}

	private void TryGrabEmployee()
	{
		Villager villager = null;
		float num = float.MaxValue;
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(fireTarget.LandMass());
		int i = 0;
		for (int count = villagersForLandMass.Count; i < count; i++)
		{
			Villager villager2 = villagersForLandMass.data[i];
			if (villager2.job is FireFighter || villager2.job is ConscriptedJob)
			{
				continue;
			}
			if (villager2.job != null)
			{
				Building building = villager2.job.employer as Building;
				if (building != null && (building.categoryHash == FireFighter.projectiletopperHash || building.uniqueNameHash == FireFighter.noriaHash))
				{
					continue;
				}
			}
			float num2 = Mathff.DistSqrdXZ(villager2.Pos, employer.GetPositionForPerson(villager2).position);
			if (num2 < num)
			{
				num = num2;
				villager = villager2;
			}
		}
		if (villager != null)
		{
			if (villager.job != null)
			{
				villager.QuitJob(updateplacement: false);
			}
			Employee = villager;
			Employee.job = this;
			employer.OnAssigned(Employee);
			OnEmployeeAssigned();
		}
	}
}
