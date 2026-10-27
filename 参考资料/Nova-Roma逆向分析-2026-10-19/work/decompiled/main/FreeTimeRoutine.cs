public class FreeTimeRoutine
{
	protected bool active;

	protected Villager _v;

	public bool IsActive()
	{
		return active;
	}

	protected FreeTimeRoutine()
	{
	}

	public virtual void Init(Villager v)
	{
		active = true;
		_v = v;
	}

	public virtual void Update(float dt)
	{
	}

	public virtual void OnFinishedPath()
	{
	}

	public virtual void End()
	{
		active = false;
	}
}
