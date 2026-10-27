using Assets.Code;
using UnityEngine;

namespace Assets.Interface;

public class ResourceStorageHelper
{
	public static void Deposit(ResourceAmount resourcesStored, ResourceAmount resourceStorageMax, YieldProducer yieldProducer, ref ResourceAmount resources, Vector3 dropPos)
	{
		for (int i = 0; i < resources.resources.Count; i++)
		{
			Resource resource = resources.resources[i];
			int amount = resource.Amount;
			if (amount <= 0)
			{
				continue;
			}
			resource.Amount = 0;
			int num = Mathff.Max(0, resourceStorageMax.Get(resource.resourceID) - resourcesStored.Get(resource.resourceID));
			if (amount > num)
			{
				FreeResourceManager.inst.AddOrMakeAutoStackFor(resource.resourceID, amount - num, dropPos);
				if (num == 0)
				{
					continue;
				}
			}
			int num2 = Mathff.Min(num, amount);
			if (num2 > 0 && resource.resourceID == 6 && yieldProducer != null)
			{
				yieldProducer.ApplyToolBonus();
			}
			resourcesStored.Add(resource.resourceID, num2);
		}
	}
}
