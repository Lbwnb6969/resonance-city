using Assets.Code;
using UnityEngine;

public class ResourceStacks : MonoBehaviour
{
	public StackTypeBinding[] Stacks;

	private ResourceAmount lastAmount;

	public void UpdateAmounts(ResourceAmount amount)
	{
		if (amount == lastAmount)
		{
			return;
		}
		lastAmount = amount;
		for (int i = 0; i < Stacks.Length; i++)
		{
			int type = Stacks[i].Type;
			int num = amount.Get(type);
			if (num <= 0)
			{
				Stacks[i].Stack.Set(0);
				continue;
			}
			Stacks[i].Stack.Set(num);
			amount.Set(type, num - Stacks[i].Stack.Count());
		}
	}
}
