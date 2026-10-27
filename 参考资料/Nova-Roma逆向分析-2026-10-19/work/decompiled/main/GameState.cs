using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using I2.Loc;
using UnityEngine;

public class GameState : MonoBehaviour
{
	public List<Building> internalPrefabs = new List<Building>();

	public HashSet<int> internalPrefabInstances = new HashSet<int>();

	public bool enableContinueMode = true;

	public PlayingMode playingMode;

	public MainMenuMode mainMenuMode;

	[NonSerialized]
	public GameMode CurrMode;

	public bool AlphaNumericHotkeysEnabled = true;

	public World world;

	public static GameState inst;

	public static bool IsQuitting;

	private bool firstUpdate = true;

	private int framesElapsed;

	private bool notified;

	private List<string> languages;

	private int languageIndex;

	public Building GetPlaceableByUniqueName(string uniqueName)
	{
		for (int i = 0; i < internalPrefabs.Count; i++)
		{
			if (internalPrefabs[i].UniqueName == uniqueName)
			{
				return internalPrefabs[i];
			}
		}
		if (uniqueName != null)
		{
			UnityEngine.Debug.LogWarning("GetPlaceableByTag() couldn't find unique name: " + uniqueName + ", this is probably an error");
		}
		return null;
	}

	public bool IsPersistantBuildingPrefab(GameObject obj)
	{
		return internalPrefabInstances.Contains(obj.GetInstanceID());
	}

	private void Awake()
	{
		LoadPrefabsFromResources();
		inst = this;
		IsQuitting = false;
		Application.wantsToQuit += LoadSave.OnApplicationWantsToQuit;
	}

	private void OnApplicationQuit()
	{
		IsQuitting = true;
	}

	public void ExecuteOnStartNotification()
	{
	}

	private void OnDestroy()
	{
		Application.wantsToQuit -= LoadSave.OnApplicationWantsToQuit;
		LoadSave.ClearContinueWorld();
	}

	public bool IsPlayMode()
	{
		return CurrMode == playingMode;
	}

	public bool IsMainMenuMode()
	{
		return CurrMode == mainMenuMode;
	}

	private void LoadPrefabsFromResources()
	{
		Building[] array = Resources.LoadAll<Building>("Placeables");
		foreach (Building go in array)
		{
			if (string.IsNullOrEmpty(go.gameObject.scene.name))
			{
				Building building = internalPrefabs.Where((Building b) => b.UniqueName == go.UniqueName).FirstOrDefault();
				if (building != null)
				{
					UnityEngine.Debug.LogError("Duplicate Building Placeable: " + building.UniqueName);
					continue;
				}
				internalPrefabs.Add(go);
				internalPrefabInstances.Add(go.gameObject.GetInstanceID());
			}
		}
	}

	private void Start()
	{
		playingMode.Shutdown();
		mainMenuMode.Shutdown();
		try
		{
			if (!Directory.Exists(Path.Combine(Application.persistentDataPath, Player.BannerPath)))
			{
				Directory.CreateDirectory(Path.Combine(Application.persistentDataPath, Player.BannerPath));
				File.WriteAllBytes(Path.Combine(Application.persistentDataPath, Player.BannerPath, "banner_reference.png"), Player.inst.referenceBanner.EncodeToPNG());
			}
			string path = Path.Combine(Path.Combine(Application.persistentDataPath, Player.BannerPath), "readme.txt");
			if (!File.Exists(path))
			{
				File.WriteAllText(path, "Custom Banner Directory\n-------------------------\n\nMove your custom banner files to this folder to see them in-game. \nA reference banner file 'banner_reference.png' is included to show \nwhat shape of image to use and the part of the image that is shown in-game. \nThis image is a 256x256 PNG. Your banners can be any square image of larger \nor smaller size but make sure your banners are in PNG format.");
			}
		}
		catch (Exception ex)
		{
			UnityEngine.Debug.LogError("Failed to create the custom banner directory: " + Application.persistentDataPath + Player.BannerPath);
			throw ex;
		}
	}

	public void MacCopyData()
	{
		string persistentDataPath = Application.persistentDataPath;
		string text = Path.Combine(Path.GetDirectoryName(persistentDataPath), "Kingdoms");
		if (Directory.Exists(text))
		{
			string path = Path.Combine(text, "copylock");
			if (!File.Exists(path))
			{
				CopyFolderContents(text, persistentDataPath);
				File.CreateText(path).Close();
			}
		}
	}

	private bool CopyFolderContents(string sourcePath, string destinationPath)
	{
		try
		{
			if (Directory.Exists(sourcePath))
			{
				if (!Directory.Exists(destinationPath))
				{
					Directory.CreateDirectory(destinationPath);
				}
				string[] files = Directory.GetFiles(sourcePath);
				for (int i = 0; i < files.Length; i++)
				{
					FileInfo fileInfo = new FileInfo(files[i]);
					DateTime lastWriteTimeUtc = fileInfo.LastWriteTimeUtc;
					string text = Path.Combine(destinationPath, fileInfo.Name);
					if (!File.Exists(text) || !(lastWriteTimeUtc < new FileInfo(text).LastWriteTimeUtc))
					{
						fileInfo.CopyTo(text, overwrite: true);
					}
				}
				files = Directory.GetDirectories(sourcePath);
				foreach (string text2 in files)
				{
					DirectoryInfo directoryInfo = new DirectoryInfo(text2);
					if (!CopyFolderContents(text2, Path.Combine(destinationPath, directoryInfo.Name)))
					{
						return false;
					}
				}
			}
			return true;
		}
		catch
		{
			return false;
		}
	}

	public void SetNewMode(GameMode NewMode)
	{
		if (NewMode != CurrMode)
		{
			if (CurrMode != null)
			{
				CurrMode.Shutdown();
			}
			CurrMode = NewMode;
			CurrMode.Init();
			if (CurrMode == playingMode)
			{
				MusicSystem.inst.StartDefaultMusic();
				ThoughtBubbleSystem.inst.disableUI = false;
			}
			else if (CurrMode == mainMenuMode)
			{
				ThoughtBubbleSystem.inst.disableUI = true;
			}
		}
	}

	public bool DoAutoLoadFirstMap()
	{
		return false;
	}

	public bool DoAutoVR()
	{
		return false;
	}

	public bool DoCredits()
	{
		return true;
	}

	public bool NotifyOnGameStart()
	{
		return false;
	}

	public bool DevOptionShowUIforAIs()
	{
		return false;
	}

	public bool DevOptionHideFogOfWar()
	{
		return false;
	}

	private void Update()
	{
		if (firstUpdate)
		{
			bool flag = false;
			if (!flag && DoAutoLoadFirstMap())
			{
				List<string> list = new List<string>();
				list.AddRange(LoadSave.GetSavePaths());
				if (list.Count > 0)
				{
					list.Sort((string pathA, string pathB) =>
					{
						DateTime saveLastWriteTime = LoadSave.GetSaveLastWriteTime(pathA);
						DateTime saveLastWriteTime2 = LoadSave.GetSaveLastWriteTime(pathB);
						if (saveLastWriteTime == saveLastWriteTime2)
						{
							return 0;
						}
						return (saveLastWriteTime < saveLastWriteTime2) ? 1 : (-1);
					});
					int num = 0;
					if (list[0].Contains("autosave"))
					{
						num++;
					}
					if (num < list.Count)
					{
						LoadSave.Load(LoadSave.GetSaveIdentifier(list[num]));
						SetNewMode(inst.playingMode);
						flag = true;
					}
				}
			}
			if (!flag)
			{
				if (!enableContinueMode || !LoadSave.TryPreloadContinueWorld())
				{
					ScenarioWorlds scenarioWorlds = Resources.Load<ScenarioWorlds>("ScenarioWorlds");
					if (scenarioWorlds == null)
					{
						return;
					}
					scenarioWorlds.OnLoadDemo();
				}
				SetNewMode(mainMenuMode);
			}
			firstUpdate = false;
		}
		LoadSave.Update();
		if ((bool)CurrMode)
		{
			CurrMode.UpdateManual(Time.unscaledDeltaTime);
		}
		if (Application.isEditor)
		{
			if (languages == null)
			{
				languages = LocalizationManager.GetAllLanguages();
				languageIndex = 0;
			}
			int num2 = 0;
			if (Input.GetKeyDown(KeyCode.Keypad4))
			{
				num2 = -1;
			}
			if (Input.GetKeyDown(KeyCode.Keypad6))
			{
				num2 = 1;
			}
			if (num2 != 0)
			{
				languageIndex = (languageIndex + num2 + languages.Count) % languages.Count;
				LocalizationManager.CurrentLanguage = languages[languageIndex];
				UnityEngine.Debug.Log(LocalizationManager.CurrentLanguage);
			}
		}
	}

	public void OnClickedOpenWebpage(string url)
	{
		Process.Start(url);
	}
}
