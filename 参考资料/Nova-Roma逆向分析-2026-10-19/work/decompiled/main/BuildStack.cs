public class BuildStack
{
	public Cell cell;

	public bool available = true;

	public Intention_BuildExactBuilding[] intentionStack = new Intention_BuildExactBuilding[10];

	internal bool Update(AIIntentionBase parent)
	{
		bool flag = false;
		if (!available)
		{
			flag = true;
			intentionStack[0]?.ReadyForBuilding(ready: true);
			for (int i = 0; i < intentionStack.Length; parent.KillAndNullFinishedIntention(ref intentionStack[i]), flag &= intentionStack[i] == null, i++)
			{
				if (!(intentionStack[i] == null))
				{
					Intention_BuildExactBuilding obj = intentionStack[i];
					if ((object)obj == null || obj.IsPlaced() != true)
					{
						continue;
					}
				}
				if (i < intentionStack.Length - 1)
				{
					intentionStack[i + 1]?.ReadyForBuilding(ready: true);
				}
			}
			available = flag;
			if (available)
			{
				cell = null;
			}
		}
		return flag;
	}
}
