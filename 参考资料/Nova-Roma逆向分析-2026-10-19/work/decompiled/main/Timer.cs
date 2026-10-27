using System;

[Serializable]
public class Timer
{
	public float CurrTime;

	public float Duration = 1f;

	public bool Enabled = true;

	public Timer(float D)
	{
		Duration = D;
	}

	public void Reset()
	{
		CurrTime = 0f;
	}

	public void ForceExpire()
	{
		CurrTime = Duration + 0.001f;
	}

	public bool Update(float dt)
	{
		if (Enabled)
		{
			CurrTime += dt;
			if (CurrTime > Duration)
			{
				CurrTime -= Duration;
				return true;
			}
		}
		return false;
	}
}
