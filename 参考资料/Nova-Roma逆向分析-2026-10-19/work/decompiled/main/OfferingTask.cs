using System;
using Assets.Code;
using Assets.Interface;
using I2.Loc;

[Serializable]
public class OfferingTask : GodTask
{
	public ResourceAmount offeringAmt;

	public override string GetDesc()
	{
		return string.Format(LocalizationManager.GetTranslation("godui_task_offering_desc"), offeringAmt.ToString());
	}

	public override void AcceptTask()
	{
		base.AcceptTask();
		int num = tasksComplete;
		for (int i = 0; i < num; i++)
		{
			int num2 = 5;
			num2 = ((i <= 5 || i > 10) ? 1 : 3);
			for (int j = 0; j < offeringAmt.resources.Count; j++)
			{
				offeringAmt.resources[j].Amount += num2;
			}
		}
	}

	public static float ResourceProgress(ResourceAmount amt)
	{
		ResourceAmount resourceAmount = null;
		if (Player.inst.FocusedLandMass != -1)
		{
			resourceAmount = Player.inst.resourcesPerLandmass[Player.inst.FocusedLandMass];
			int num = 0;
			int num2 = 0;
			for (int i = 0; i < amt.resources.Count; i++)
			{
				num2 += amt.resources[i].Amount;
				if (resourceAmount != null)
				{
					num += resourceAmount.Get(amt.resources[i].resourceID);
				}
			}
			return (float)num / (float)num2;
		}
		return 0f;
	}

	public override float GetProgress()
	{
		if (GodTask.debugFreeComplete)
		{
			return 1f;
		}
		return ResourceProgress(offeringAmt);
	}

	public static void RemoveResources(ResourceAmount amt)
	{
		ResourceAmount resourceAmount = new ResourceAmount(amt);
		ResourceAmount resourceAmount2 = new ResourceAmount();
		ArrayExtRef<IResourceStorage> resourceStorageListFor = FreeResourceManager.inst.GetResourceStorageListFor(Player.inst.FocusedLandMass);
		for (int i = 0; i < resourceAmount.resources.Count; i++)
		{
			if (resourceAmount.resources[i].resourceID == 4)
			{
				Player.inst.PlayerLandmassOwner.Gold -= resourceAmount.resources[i].Amount;
				resourceAmount.resources[i].Amount = 0;
				continue;
			}
			for (int j = 0; j < resourceStorageListFor.Count; j++)
			{
				IResourceStorage resourceStorage = resourceStorageListFor.data[j];
				if (resourceStorage.StoresTypePublic(resourceAmount.resources[i].resourceID))
				{
					int num = resourceStorage.StoredPublicResources(resourceAmount.resources[i].resourceID);
					int num2 = resourceAmount.resources[i].Amount;
					if (resourceAmount.resources[i].Amount > num)
					{
						num2 = num;
					}
					resourceAmount2.Clear();
					resourceAmount2.Add(resourceAmount.resources[i].resourceID, num2);
					resourceStorage.RemoveResources(resourceAmount2);
					resourceAmount.resources[i].Amount -= num2;
					if (resourceAmount.resources[i].Amount <= 0)
					{
						break;
					}
				}
			}
		}
	}

	public override void Complete()
	{
		if (!GodTask.debugFreeComplete)
		{
			RemoveResources(offeringAmt);
			ResourceStatistics.AddConsumption(Player.inst.FocusedLandMass, "godoffering", offeringAmt);
		}
		base.Complete();
	}
}
