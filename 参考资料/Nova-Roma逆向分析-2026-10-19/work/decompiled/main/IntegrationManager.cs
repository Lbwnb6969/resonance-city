using UnityEngine;

public class IntegrationManager : MonoBehaviour
{
	public static IPlatformIntegration inst;

	public static void SetupIntegration()
	{
		inst = new SteamIntegration();
		try
		{
			inst.Init();
		}
		catch
		{
			inst = new NoopIntegration();
			throw;
		}
	}

	private void Awake()
	{
		Object.DontDestroyOnLoad(gameObject);
	}

	private void FixedUpdate()
	{
		try
		{
			inst.Update();
		}
		catch
		{
			inst = new NoopIntegration();
			throw;
		}
	}

	private void OnDestroy()
	{
		inst.Shutdown();
	}
}
