using System;
using I2.Loc;

[Serializable]
public class BuildingCountTask : GodTask
{
	public static ArrayExt<ArrayExt<Building>> tempCategoryBuildings = new ArrayExt<ArrayExt<Building>>(32);

	public int buildingCount;

	public string uniqueName;

	public string categoryName;

	public bool ignoreScaling;

	public string descTerm;

	public override void AcceptTask()
	{
		base.AcceptTask();
		if (!ignoreScaling)
		{
			buildingCount += tasksComplete / 4;
		}
		TechnologyTree.inst.ShowBuildingNode(uniqueName);
	}

	public override string GetDesc()
	{
		return string.Format(LocalizationManager.GetTranslation(descTerm), buildingCount);
	}

	public override float GetProgress()
	{
		int num = 0;
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		int num2 = (string.IsNullOrEmpty(uniqueName) ? (-1) : uniqueName.GetHashCode());
		int num3 = (string.IsNullOrEmpty(categoryName) ? (-1) : categoryName.GetHashCode());
		for (int i = 0; i < playerLandmassOwner.ownedLandMasses.Count; i++)
		{
			if (num3 != -1)
			{
				Player.inst.GetBuildingListsByCategoryForLandMass(playerLandmassOwner.ownedLandMasses.data[i], num3, ref tempCategoryBuildings);
				for (int j = 0; j < tempCategoryBuildings.Count; j++)
				{
					for (int k = 0; k < tempCategoryBuildings.data[j].Count; k++)
					{
						if (tempCategoryBuildings.data[j].data[k].IsBuilt())
						{
							num++;
						}
					}
				}
				continue;
			}
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(playerLandmassOwner.ownedLandMasses.data[i], num2);
			for (int l = 0; l < buildingListForLandMass.Count; l++)
			{
				if (buildingListForLandMass.data[l].IsBuilt())
				{
					num++;
				}
			}
		}
		if (num2 == World.aqueductHash)
		{
			for (int m = 0; m < AqueductLine.allLines.Count; m++)
			{
				AqueductLine aqueductLine = AqueductLine.allLines[m];
				int landmass = aqueductLine.LandMass();
				if (Player.inst.PlayerLandmassOwner.OwnsLandMass(landmass) && aqueductLine.fullyConstructed)
				{
					num++;
				}
			}
		}
		if (num2 == World.woodcastleblockHash)
		{
			for (int n = 0; n < playerLandmassOwner.ownedLandMasses.Count; n++)
			{
				ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(playerLandmassOwner.ownedLandMasses.data[n], World.castleblockHash);
				for (int num4 = 0; num4 < buildingListForLandMass2.Count; num4++)
				{
					if (buildingListForLandMass2.data[num4].IsBuilt())
					{
						num++;
					}
				}
			}
		}
		if (!GodTask.debugFreeComplete)
		{
			return (float)num / (float)buildingCount;
		}
		return 1f;
	}
}
