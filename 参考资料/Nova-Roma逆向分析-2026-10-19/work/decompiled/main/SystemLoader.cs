using Assets;
using UnityEngine;

public class SystemLoader : MonoBehaviour
{
	public MusicSystem musicSystemPrefab;

	public Settings settingsSystemPrefab;

	private void Awake()
	{
		if (IntegrationManager.inst == null)
		{
			IntegrationManager.SetupIntegration();
		}
		if (ConfigurableControls.inst == null)
		{
			GameObject gameObject = new GameObject();
			gameObject.name = "Configurable Controls";
			gameObject.AddComponent<ConfigurableControls>();
			Object.DontDestroyOnLoad(gameObject);
		}
		if (Settings.inst == null)
		{
			Settings settings = Object.Instantiate(settingsSystemPrefab);
			settings.name = "Settings System";
			Object.DontDestroyOnLoad(settings);
		}
		if (MusicSystem.inst == null)
		{
			MusicSystem musicSystem = Object.Instantiate(musicSystemPrefab);
			musicSystem.name = "Audio System";
			Object.DontDestroyOnLoad(musicSystem);
		}
	}
}
