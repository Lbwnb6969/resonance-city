using System;
using Assets.Code;
using I2.Loc;

[Serializable]
public class DietTask : GodTask
{
	public int foodNeedsGoal = 3;

	public int homesGoal = 1;

	public override string GetDesc()
	{
		return string.Format(LocalizationManager.GetTranslation("godui_task_diettask_desc"), foodNeedsGoal, homesGoal);
	}

	public override float GetProgress()
	{
		int num = 0;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			ArrayExt<Home> arrayExt = Player.inst.ResidentialsPerLandmass[i];
			for (int j = 0; j < arrayExt.Count; j++)
			{
				Home.Consumable[] diet = arrayExt.data[j].diet;
				ResourceAmount resourcesStored = arrayExt.data[j].resourcesStored;
				int num2 = 0;
				for (int k = 0; k < diet.Length; k++)
				{
					if ((k <= 0 || diet[k - 1].type != diet[k].type) && (resourcesStored.Get(diet[k].type) > 0 || (diet[k].altType != -1 && resourcesStored.Get(diet[k].altType) > 0)))
					{
						num2++;
					}
				}
				if (num2 >= foodNeedsGoal)
				{
					num++;
					if (num >= homesGoal)
					{
						return 1f;
					}
				}
			}
		}
		return (float)num / (float)homesGoal;
	}
}
