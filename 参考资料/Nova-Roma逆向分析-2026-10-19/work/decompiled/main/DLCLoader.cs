using UnityEngine;

public class DLCLoader : MonoBehaviour
{
	private DecorationsManager decorationsManager;

	private void Start()
	{
		Object.DontDestroyOnLoad(this);
	}

	private void Update()
	{
		if (IntegrationManager.inst.IsDLCInstalled(1764300u))
		{
			decorationsManager = new DecorationsManager();
			string text = "/../DLC/decorationspack";
			if (Application.platform == RuntimePlatform.OSXPlayer)
			{
				text = "/.." + text;
			}
			AssetBundle assetBundle = LoadDLCBundle(Application.dataPath + text, "decorations");
			decorationsManager.assets = assetBundle.LoadAllAssets();
			enabled = false;
		}
	}

	public static AssetBundle LoadDLCBundle(string path, string bundlename)
	{
		string text = "win64";
		if (Application.platform == RuntimePlatform.LinuxPlayer)
		{
			text = "linux";
		}
		if (Application.platform == RuntimePlatform.OSXPlayer)
		{
			text = "osx";
		}
		if (Application.platform == RuntimePlatform.WindowsPlayer)
		{
			text = ((!SystemInfo.operatingSystem.Contains("64")) ? "win32" : "win64");
		}
		return AssetBundle.LoadFromFile(path + "/" + bundlename + "_" + text);
	}
}
