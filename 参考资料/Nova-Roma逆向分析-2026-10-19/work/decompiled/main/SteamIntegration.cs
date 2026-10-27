using Steamworks;

public class SteamIntegration : IPlatformIntegration
{
	public bool UseAchievements()
	{
		return true;
	}

	public void Init()
	{
		_ = SteamManager.Initialized;
	}

	public string GetPersonaName()
	{
		return "";
	}

	public void Update()
	{
	}

	public void Shutdown()
	{
	}

	public void SetAchievement(string achievement)
	{
		if (SteamManager.Initialized)
		{
			SteamUserStats.SetAchievement(achievement);
			SteamUserStats.StoreStats();
		}
	}

	public bool GetAchievement(string achievement)
	{
		bool pbAchieved = false;
		if (SteamManager.Initialized)
		{
			SteamUserStats.GetAchievement(achievement, out pbAchieved);
		}
		return pbAchieved;
	}

	public void ClearAchievement(string achievement)
	{
		if (SteamManager.Initialized)
		{
			SteamUserStats.ClearAchievement(achievement);
			SteamUserStats.StoreStats();
		}
	}

	public string GetVersion()
	{
		return "1";
	}

	public bool IsDLCInstalled(uint appID)
	{
		if (SteamManager.Initialized)
		{
			return SteamApps.BIsDlcInstalled((AppId_t)appID);
		}
		return false;
	}
}
