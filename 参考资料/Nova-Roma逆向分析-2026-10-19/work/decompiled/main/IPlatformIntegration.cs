public interface IPlatformIntegration
{
	bool UseAchievements();

	void Init();

	void Update();

	void Shutdown();

	string GetPersonaName();

	void SetAchievement(string achievement);

	bool GetAchievement(string achievement);

	void ClearAchievement(string achievement);

	string GetVersion();

	bool IsDLCInstalled(uint appID);
}
