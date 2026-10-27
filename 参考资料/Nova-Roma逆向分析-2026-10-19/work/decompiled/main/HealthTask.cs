using System;
using I2.Loc;

[Serializable]
public class HealthTask : GodTask
{
	public float healthGoal;

	public override string GetDesc()
	{
		return string.Format(LocalizationManager.GetTranslation("godui_task_healthgoal_desc"), healthGoal);
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
			float currHealthForLandmass = Player.inst.GetCurrHealthForLandmass(playerLandmassOwner.ownedLandMasses.data[i]);
			if (currHealthForLandmass > num)
			{
				num = currHealthForLandmass;
			}
		}
		return num / healthGoal;
	}

	public override bool Equals(object obj)
	{
		if (!(obj is HealthTask))
		{
			return false;
		}
		if (healthGoal == (obj as HealthTask).healthGoal)
		{
			return true;
		}
		return base.Equals(obj);
	}
}
