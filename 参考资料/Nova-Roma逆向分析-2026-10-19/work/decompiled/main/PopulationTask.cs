using System;
using I2.Loc;

[Serializable]
public class PopulationTask : GodTask
{
	public int populationGoal;

	public override bool Equals(object obj)
	{
		if (!(obj is PopulationTask))
		{
			return false;
		}
		if (populationGoal + tasksComplete * 5 == (obj as PopulationTask).populationGoal)
		{
			return true;
		}
		return base.Equals(obj);
	}

	public override void AcceptTask()
	{
		base.AcceptTask();
		populationGoal += tasksComplete * 5;
	}

	public override string GetDesc()
	{
		return string.Format(LocalizationManager.GetTranslation("godui_task_populationgoal_desc"), populationGoal);
	}

	public override float GetProgress()
	{
		if (GodTask.debugFreeComplete)
		{
			return 1f;
		}
		float num = 0f;
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		for (int i = 0; i < playerLandmassOwner.ownedLandMasses.Count; i++)
		{
			num += (float)World.inst.GetVillagersForLandMass(playerLandmassOwner.ownedLandMasses.data[i]).Count;
		}
		return num / (float)populationGoal;
	}
}
