using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;
using RoslynCSharp;
using Steamworks;
using UnityEngine;

public class KCModHelper
{
	public class ModLoader : MonoBehaviour
	{
		public class LocalMod
		{
			[Serializable]
			public class ModInfo
			{
				public string name;

				public string description;
			}

			public string name;

			public string description;

			public string path;

			public bool infoExists;

			public bool validFormat;

			public LocalMod(string path)
			{
				this.path = path;
				string text = Path.Combine(path, "info.json");
				infoExists = File.Exists(text);
				if (infoExists)
				{
					string json = File.ReadAllText(text);
					ModInfo modInfo = null;
					try
					{
						modInfo = JsonUtility.FromJson<ModInfo>(json);
					}
					catch (Exception ex)
					{
						validFormat = false;
						Debug.LogError("Problem with info.json:\n" + ex.Message);
						return;
					}
					validFormat = true;
					if (modInfo != null)
					{
						name = modInfo.name;
						description = modInfo.description;
					}
				}
			}

			public string GetFolderName()
			{
				return Path.GetFileName(path.TrimEnd(Path.DirectorySeparatorChar));
			}
		}

		public class ModAssembly
		{
			public ScriptAssembly assembly;

			public List<ScriptProxy> instances = new List<ScriptProxy>();

			public string modPath;
		}

		public static List<LocalMod> localModsLoadedAtStartup = new List<LocalMod>();

		private CallResult<SteamUGCQueryCompleted_t> OnQueryCompletedResult;

		private string localModsPath;

		public List<ModAssembly> loadedAssemblies = new List<ModAssembly>();

		public bool localModsLoaded;

		public bool workshopModsLoaded;

		private bool init;

		private void Start()
		{
			OnQueryCompletedResult = CallResult<SteamUGCQueryCompleted_t>.Create(OnQueryCompleted);
			Debug.LogError("We are in STEAM_MODE");
			localModsLoaded = false;
			workshopModsLoaded = false;
			UnityEngine.Object.DontDestroyOnLoad(gameObject);
		}

		private void Update()
		{
			if (!init && SteamManager.Initialized)
			{
				init = true;
				SetupLogging();
				GetWorkshopMods();
				LoadLocalMods();
			}
		}

		private void SetupLogging()
		{
			localModsPath = Path.Combine(Application.dataPath, "mods");
			Path.Combine(localModsPath, "log.txt");
			Debug.Log(localModsPath);
			if (!Directory.Exists(localModsPath))
			{
				Directory.CreateDirectory(localModsPath);
			}
		}

		public void Log(string text)
		{
			using StreamWriter streamWriter = new StreamWriter(Path.Combine(localModsPath, "log.txt"), append: true, Encoding.UTF8);
			streamWriter.WriteLine(DateTime.Now.ToString("s", CultureInfo.CurrentCulture) + ":" + text);
			streamWriter.Close();
		}

		private void LoadLocalMods()
		{
			foreach (string item in Directory.EnumerateDirectories(localModsPath, "*", SearchOption.TopDirectoryOnly))
			{
				try
				{
					Debug.Log(item);
					if (LoadMod(item, null))
					{
						localModsLoadedAtStartup.Add(new LocalMod(item));
					}
				}
				catch (Exception ex)
				{
					Log("Unhandled exception: " + ex.Message + "\n" + ex.Source + "\n" + ex.StackTrace);
				}
			}
			localModsLoaded = true;
		}

		private void GetWorkshopMods()
		{
			UGCQueryHandle_t handle = SteamUGC.CreateQueryUserUGCRequest(SteamUser.GetSteamID().GetAccountID(), EUserUGCList.k_EUserUGCList_Subscribed, EUGCMatchingUGCType.k_EUGCMatchingUGCType_All, EUserUGCListSortOrder.k_EUserUGCListSortOrder_CreationOrderAsc, (AppId_t)1199380u, SteamUtils.GetAppID(), 1u);
			SteamUGC.AddRequiredTag(handle, "kcmod");
			SteamUGC.SetReturnMetadata(handle, bReturnMetadata: true);
			SteamAPICall_t hAPICall = SteamUGC.SendQueryUGCRequest(handle);
			OnQueryCompletedResult.Set(hAPICall);
			SteamAPI.RunCallbacks();
		}

		private void OnQueryCompleted(SteamUGCQueryCompleted_t result, bool ioFailure)
		{
			string[] array = new string[8]
			{
				"[OnQueryCompletedFunction] - ",
				result.m_eResult.ToString(),
				" -- ",
				null,
				null,
				null,
				null,
				null
			};
			UGCQueryHandle_t handle = result.m_handle;
			array[3] = handle.ToString();
			array[4] = " -- ";
			array[5] = result.m_unNumResultsReturned.ToString();
			array[6] = " -- ";
			array[7] = result.m_unTotalMatchingResults.ToString();
			Debug.Log(string.Concat(array));
			for (uint num = 0u; num < result.m_unNumResultsReturned; num++)
			{
				SteamUGC.GetQueryUGCResult(result.m_handle, num, out var pDetails);
				if ((SteamUGC.GetItemState(pDetails.m_nPublishedFileId) & 4) != 0)
				{
					ulong punSizeOnDisk = 0uL;
					string pchFolder = "";
					uint cchFolderSize = 2000u;
					uint punTimeStamp = 0u;
					SteamUGC.GetItemInstallInfo(pDetails.m_nPublishedFileId, out punSizeOnDisk, out pchFolder, cchFolderSize, out punTimeStamp);
					SteamUGC.GetQueryUGCMetadata(result.m_handle, num, out var pchMetadata, 300u);
					WorkshopUI.WorkshopMetadata workshopMetadata = JsonUtility.FromJson<WorkshopUI.WorkshopMetadata>(pchMetadata);
					if (workshopMetadata == null)
					{
						workshopMetadata = new WorkshopUI.WorkshopMetadata(1);
					}
					bool flag = workshopMetadata.version == modVersion;
					bool loaded = false;
					if (flag)
					{
						loaded = LoadMod(pchFolder, workshopMetadata);
					}
					GameWorkshopUI.loadedMods.Add(new GameWorkshopUI.LoadedMod
					{
						fileId = pDetails.m_nPublishedFileId,
						loaded = loaded,
						validVersion = flag,
						version = workshopMetadata.version
					});
				}
			}
			workshopModsLoaded = true;
		}

		public bool ReadyToMakeInstances()
		{
			if (localModsLoaded)
			{
				return workshopModsLoaded;
			}
			return false;
		}

		public void CreateModInstances()
		{
			foreach (ModAssembly loadedAssembly in loadedAssemblies)
			{
				ScriptType[] array = loadedAssembly.assembly.FindAllTypes();
				foreach (ScriptType scriptType in array)
				{
					bool num = TypeTakesKCModHelper(scriptType, "OnScriptLoad") || TypeTakesNothing(scriptType, "OnScriptLoad") || TypeTakesKCModHelper(scriptType, "SceneLoaded") || TypeTakesNothing(scriptType, "SceneLoaded");
					bool flag = TypeTakesKCModHelper(scriptType, "PreScriptLoad") || TypeTakesNothing(scriptType, "PreScriptLoad") || TypeTakesKCModHelper(scriptType, "Preload") || TypeTakesNothing(scriptType, "Preload");
					if (num | flag)
					{
						ScriptProxy scriptProxy = scriptType.CreateInstance(gameObject);
						if (scriptProxy.IsMonoBehaviour)
						{
							(scriptProxy.Instance as MonoBehaviour).enabled = false;
						}
						loadedAssembly.instances.Add(scriptProxy);
					}
				}
			}
		}

		public bool TypeTakesKCModHelper(ScriptType scriptType, string functionName)
		{
			MethodInfo methodInfo = scriptType.FindCachedMethod(functionName, isStatic: false);
			if (methodInfo != null)
			{
				ParameterInfo[] parameters = methodInfo.GetParameters();
				if (parameters != null && parameters.Length == 1)
				{
					return parameters[0].ParameterType == typeof(KCModHelper);
				}
				return false;
			}
			return false;
		}

		public bool TypeTakesNothing(ScriptType scriptType, string functionName)
		{
			MethodInfo methodInfo = scriptType.FindCachedMethod(functionName, isStatic: false);
			if (methodInfo != null)
			{
				ParameterInfo[] parameters = methodInfo.GetParameters();
				if (parameters != null)
				{
					return parameters.Length == 0;
				}
				return true;
			}
			return false;
		}

		public void SendSceneLoadSignal()
		{
			SendSignal("SceneLoaded");
			SendSignal("OnScriptLoad");
			ActivateMonoBehaviours();
		}

		public void SendScenePreloadSignal()
		{
			SendSignal("Preload");
			SendSignal("PreScriptLoad");
		}

		public void SendSignal(string functionName)
		{
			foreach (ModAssembly loadedAssembly in loadedAssemblies)
			{
				foreach (ScriptProxy instance in loadedAssembly.instances)
				{
					if (TypeTakesKCModHelper(instance.ScriptType, functionName))
					{
						Log("Calling " + instance.ScriptType.FullName + " with param");
						KCModHelper kCModHelper = new KCModHelper(loadedAssembly.modPath);
						try
						{
							object[] arguments = new KCModHelper[1] { kCModHelper };
							instance.Call(functionName, ProxyCallConvention.Any, arguments);
						}
						catch (Exception ex)
						{
							Log("On error has occured:");
							Log(ex.ToString());
						}
					}
					if (TypeTakesNothing(instance.ScriptType, functionName))
					{
						Log("Calling " + instance.ScriptType.FullName + " with no param");
						try
						{
							instance.Call(functionName);
						}
						catch (Exception ex2)
						{
							Log("On error has occured:");
							Log(ex2.ToString());
						}
					}
				}
			}
		}

		public void ActivateMonoBehaviours()
		{
			foreach (ModAssembly loadedAssembly in loadedAssemblies)
			{
				foreach (ScriptProxy instance in loadedAssembly.instances)
				{
					if (instance.IsMonoBehaviour)
					{
						(instance.Instance as MonoBehaviour).enabled = true;
					}
				}
			}
		}

		private bool LoadMod(string mod, WorkshopUI.WorkshopMetadata metadata)
		{
			bool validAndLoadable = false;
			ScriptAssembly assembly = null;
			try
			{
				assembly = ModCompiler.LoadMod(mod, Log, out validAndLoadable);
			}
			catch (Exception ex)
			{
				Log("Exception encountered loading mod: " + ex.Message);
			}
			if (validAndLoadable)
			{
				loadedAssemblies.Add(new ModAssembly
				{
					modPath = mod,
					assembly = assembly
				});
			}
			return validAndLoadable;
		}

		public void LogModEvent(string str, string filePath)
		{
			using StreamWriter streamWriter = new StreamWriter(filePath, append: true, Encoding.UTF8);
			streamWriter.WriteLine(str);
			streamWriter.Close();
		}
	}

	public readonly string modPath;

	public static readonly int modVersion = 2;

	public static AssetBundle LoadAssetBundle(string modPath, string bundlename)
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
		string text2 = modPath + "/" + text + "/";
		AssetBundle assetBundle = AssetBundle.LoadFromFile(text2 + "/" + text);
		AssetBundleManifest assetBundleManifest = assetBundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
		string[] allAssetBundles = assetBundleManifest.GetAllAssetBundles();
		foreach (string text3 in allAssetBundles)
		{
			if (text3.Contains(bundlename))
			{
				string[] allDependencies = assetBundleManifest.GetAllDependencies(text3);
				foreach (string text4 in allDependencies)
				{
					AssetBundle.LoadFromFile(text2 + "/" + text4);
				}
				assetBundle.Unload(unloadAllLoadedObjects: false);
				return AssetBundle.LoadFromFile(text2 + "/" + text3);
			}
		}
		assetBundle.Unload(unloadAllLoadedObjects: false);
		return null;
	}

	private KCModHelper(string modPath)
	{
		this.modPath = modPath;
	}

	public void Log(string msg)
	{
		using StreamWriter streamWriter = new StreamWriter(Path.Combine(modPath, "output.txt"), append: true, Encoding.UTF8);
		streamWriter.WriteLine(DateTime.Now.ToString("s", CultureInfo.CurrentCulture) + ":" + msg);
		streamWriter.Close();
	}
}
