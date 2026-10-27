using Assets.Code;

public class Intention_CaptureResource : AIIntentionBase
{
	public ResourceAmount amountToCollect;

	public bool Ignore;

	public bool ResourceCollected;

	public void Init(ResourceAmount amountToCollect)
	{
		this.amountToCollect = amountToCollect;
	}
}
