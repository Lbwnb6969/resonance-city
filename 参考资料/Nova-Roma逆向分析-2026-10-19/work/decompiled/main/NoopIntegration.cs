public class NoopIntegration : IPlatformIntegration
{
	public bool UseAchievements()
	{
		return false;
	}

	public void Init()
	{
	}

	public void Update()
	{
	}

	public void Shutdown()
	{
	}

	public string GetPersonaName()
	{
		return "Player";
	}

	public void SetAchievement(string achievement)
	{
	}

	public bool GetAchievement(string achievement)
	{
		return false;
	}

	public void ClearAchievement(string achievement)
	{
	}

	public string GetVersion()
	{
		return "0";
	}

	public bool IsDLCInstalled(uint appID)
	{
		return false;
	}
}
