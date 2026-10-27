using System;

[Serializable]
public class GodTask
{
	public static bool debugFreeComplete;

	public bool skipIfComplete;

	public bool skipIfActive;

	public string convo;

	public int reward;

	public int tasksComplete;

	public virtual string GetDesc()
	{
		return "";
	}

	public virtual void Complete()
	{
	}

	public bool IsComplete()
	{
		return GetProgress() >= 1f;
	}

	public virtual float GetProgress()
	{
		if (!debugFreeComplete)
		{
			return 0f;
		}
		return 1f;
	}

	public virtual void AcceptTask()
	{
		if (!LoadSave.Loading)
		{
			tasksComplete = GodManager.inst.tasksComplete;
		}
	}
}
