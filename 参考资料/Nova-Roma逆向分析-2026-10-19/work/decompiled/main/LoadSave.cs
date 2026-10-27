using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Runtime.Serialization;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using I2.Loc;
using UnityEngine;
using UnityEngine.Events;

[Serializable]
public class LoadSave
{
	[Serializable]
	public class WorldSummaryData
	{
		public string CityName;

		public DateTime Date;

		public int Population;

		public int Year;

		[OptionalField(VersionAdded = 2)]
		public string ShareCode;

		public SerializableGuid guid;
	}

	private class OutData
	{
		public string Path;

		public LoadSaveContainer LoadSaveContainer;
	}

	private struct ZipSaveContext
	{
		public string StagingPath;

		public string OutputZipPath;

		public Thread SaveThread;
	}

	private sealed class ZipArchiveStream : Stream
	{
		private readonly ZipArchive archive;

		private readonly Stream inner;

		public override bool CanRead => inner.CanRead;

		public override bool CanSeek => inner.CanSeek;

		public override bool CanWrite => false;

		public override long Length
		{
			get
			{
				if (!inner.CanSeek)
				{
					throw new NotSupportedException();
				}
				return inner.Length;
			}
		}

		public override long Position
		{
			get
			{
				if (!inner.CanSeek)
				{
					throw new NotSupportedException();
				}
				return inner.Position;
			}
			set
			{
				if (!inner.CanSeek)
				{
					throw new NotSupportedException();
				}
				inner.Position = value;
			}
		}

		public ZipArchiveStream(ZipArchive archive, Stream inner)
		{
			this.archive = archive;
			this.inner = inner;
		}

		public override void Flush()
		{
			inner.Flush();
		}

		public override int Read(byte[] buffer, int offset, int count)
		{
			return inner.Read(buffer, offset, count);
		}

		public override long Seek(long offset, SeekOrigin origin)
		{
			if (!inner.CanSeek)
			{
				throw new NotSupportedException();
			}
			return inner.Seek(offset, origin);
		}

		public override void SetLength(long value)
		{
			throw new NotSupportedException();
		}

		public override void Write(byte[] buffer, int offset, int count)
		{
			throw new NotSupportedException();
		}

		protected override void Dispose(bool disposing)
		{
			if (disposing)
			{
				inner.Dispose();
				archive.Dispose();
			}
			base.Dispose(disposing);
		}
	}

	private class MyEncoder : UTF8Encoding
	{
		public MyEncoder()
			: base(encoderShouldEmitUTF8Identifier: true)
		{
		}

		public override byte[] GetBytes(string s)
		{
			s = s.Replace("\\", "/");
			return base.GetBytes(s);
		}
	}

	public delegate void OnLoadFinished(string name = "");

	public static ConcurrentQueue<Action> actionQueue = new ConcurrentQueue<Action>();

	public static SerializableDictionary<string, string> CustomSaveData_DontAccessDirectly = new SerializableDictionary<string, string>();

	public static bool Loading;

	public const string customBannerFilename = "/custombanner.png";

	public const string ZipExtension = ".zip";

	private static readonly char[] TrimChars = new char[2] { '\\', '/' };

	private static string cachedPersistentDataPath = Application.persistentDataPath;

	public static Thread thread;

	public static bool loadIntoMapSelect;

	private static Creative.CreativeSaveData preMapLoadCreativeState;

	public static string currentMapName;

	public static OnLoadFinished onLoadFinished;

	public static OnLoadFinished onLoadStart;

	public static bool continueWorldReady = false;

	private static string failedContinuePath;

	private static DateTime failedContinueWriteTime;

	private static WorldSummaryData continueSummary;

	private static string continuePath;

	private static bool continueWorldFailed;

	public static string LastLoadDirectory;

	public static string loadThreadedPath;

	public static string loadThreadedRelativeFile;

	public static bool loadThreadedIsZip;

	public static bool loadThreadedSuccess;

	public static bool loadThreadedFinished;

	public static bool continueLoadFailed
	{
		get
		{
			if (!string.IsNullOrEmpty(failedContinuePath) && GetMostRecentSavePath() == failedContinuePath)
			{
				return GetSaveLastWriteTime(failedContinuePath) == failedContinueWriteTime;
			}
			return false;
		}
	}

	public static void RunOnMainThreadLater(Action action)
	{
		actionQueue.Enqueue(action);
	}

	public static string ConvertStringToBase64(string str)
	{
		if (str == null)
		{
			return null;
		}
		return Convert.ToBase64String(Encoding.UTF8.GetBytes(str));
	}

	public static string ConvertBase64ToString(string base64)
	{
		if (base64 == null)
		{
			return null;
		}
		byte[] bytes = Convert.FromBase64String(base64);
		return Encoding.UTF8.GetString(bytes);
	}

	public static string BuildBuildingKey(string modName, Building building)
	{
		return modName + building.guid.ToString();
	}

	public static void SaveDataBuilding(string modName, Building building, string data)
	{
		CustomSaveData_DontAccessDirectly[BuildBuildingKey(modName, building)] = ConvertStringToBase64(data);
	}

	public static string ReadDataBuilding(string modName, Building building)
	{
		if (CustomSaveData_DontAccessDirectly.ContainsKey(BuildBuildingKey(modName, building)))
		{
			return ConvertBase64ToString(CustomSaveData_DontAccessDirectly[BuildBuildingKey(modName, building)]);
		}
		return null;
	}

	public static void SaveDataGeneric(string modName, string identifier, string data)
	{
		CustomSaveData_DontAccessDirectly[modName + identifier] = ConvertStringToBase64(data);
	}

	public static string ReadDataGeneric(string modName, string identifier)
	{
		if (CustomSaveData_DontAccessDirectly.ContainsKey(modName + identifier))
		{
			return ConvertBase64ToString(CustomSaveData_DontAccessDirectly[modName + identifier]);
		}
		return null;
	}

	public static bool IsZipSavePath(string path)
	{
		if (string.IsNullOrEmpty(path))
		{
			return false;
		}
		return string.Equals(Path.GetExtension(path), ".zip", StringComparison.OrdinalIgnoreCase);
	}

	private static string CombineSavePath(string basePath, string relativePath)
	{
		relativePath = NormalizeRelativePath(relativePath);
		return Path.Combine(basePath, relativePath);
	}

	private static string NormalizeRelativePath(string relativePath)
	{
		if (string.IsNullOrEmpty(relativePath))
		{
			return relativePath;
		}
		return relativePath.TrimStart(TrimChars);
	}

	private static ZipArchiveEntry FindZipEntry(ZipArchive archive, string relativePath)
	{
		relativePath = NormalizeRelativePath(relativePath).Replace('\\', '/');
		foreach (ZipArchiveEntry entry in archive.Entries)
		{
			if (entry.FullName.Replace('\\', '/').EndsWith(relativePath, StringComparison.OrdinalIgnoreCase))
			{
				return entry;
			}
		}
		return null;
	}

	private static bool SaveFileExists(string basePath, string relativePath)
	{
		if (IsZipSavePath(basePath))
		{
			using (ZipArchive archive = ZipFile.OpenRead(basePath))
			{
				return FindZipEntry(archive, relativePath) != null;
			}
		}
		return File.Exists(CombineSavePath(basePath, relativePath));
	}

	private static bool ValidateZipEntry(ZipArchive archive, string relativePath, bool ensureLength)
	{
		ZipArchiveEntry zipArchiveEntry = FindZipEntry(archive, relativePath);
		if (zipArchiveEntry == null)
		{
			return false;
		}
		if (!ensureLength)
		{
			return true;
		}
		try
		{
			return zipArchiveEntry.Length > 0;
		}
		catch
		{
			return false;
		}
	}

	private static bool ValidateFilesystemEntry(string basePath, string relativePath, bool ensureLength)
	{
		string text = CombineSavePath(basePath, relativePath);
		if (!File.Exists(text))
		{
			return false;
		}
		if (!ensureLength)
		{
			return true;
		}
		try
		{
			return new FileInfo(text).Length > 0;
		}
		catch
		{
			return false;
		}
	}

	private static Stream OpenSaveReadStream(string basePath, string relativePath)
	{
		if (IsZipSavePath(basePath))
		{
			ZipArchive zipArchive = ZipFile.OpenRead(basePath);
			ZipArchiveEntry zipArchiveEntry = FindZipEntry(zipArchive, relativePath);
			if (zipArchiveEntry == null)
			{
				zipArchive.Dispose();
				throw new FileNotFoundException("Could not find " + relativePath + " in zip save " + basePath);
			}
			return new ZipArchiveStream(zipArchive, zipArchiveEntry.Open());
		}
		return new FileStream(CombineSavePath(basePath, relativePath), FileMode.Open, FileAccess.Read, FileShare.Read);
	}

	public static DateTime GetSaveLastWriteTime(string basePath)
	{
		try
		{
			if (IsZipSavePath(basePath))
			{
				if (!File.Exists(basePath))
				{
					return DateTime.MinValue;
				}
				using (ZipArchive archive = ZipFile.OpenRead(basePath))
				{
					ZipArchiveEntry zipArchiveEntry = FindZipEntry(archive, "world");
					if (zipArchiveEntry != null)
					{
						return zipArchiveEntry.LastWriteTime.ToLocalTime().DateTime;
					}
				}
				return File.GetLastWriteTime(basePath);
			}
			string path = CombineSavePath(basePath, "world");
			if (File.Exists(path))
			{
				return File.GetLastWriteTime(path);
			}
			if (Directory.Exists(basePath))
			{
				return Directory.GetLastWriteTime(basePath);
			}
		}
		catch
		{
		}
		return DateTime.MinValue;
	}

	public static string GetSaveIdentifier(string path)
	{
		if (string.IsNullOrEmpty(path))
		{
			return string.Empty;
		}
		string text = path.Replace('\\', '/');
		text = text.TrimEnd('/');
		int num = text.LastIndexOf('/');
		string text2 = ((num >= 0) ? text.Substring(num + 1) : text);
		if (string.IsNullOrEmpty(text2))
		{
			return string.Empty;
		}
		return "/" + text2;
	}

	private static bool TryReadSaveFileBytes(string basePath, string relativePath, out byte[] data)
	{
		data = null;
		if (IsZipSavePath(basePath))
		{
			using (ZipArchive archive = ZipFile.OpenRead(basePath))
			{
				ZipArchiveEntry zipArchiveEntry = FindZipEntry(archive, relativePath);
				if (zipArchiveEntry != null)
				{
					using Stream stream = zipArchiveEntry.Open();
					using MemoryStream memoryStream = new MemoryStream();
					stream.CopyTo(memoryStream);
					data = memoryStream.ToArray();
					return true;
				}
				return false;
			}
		}
		string path = CombineSavePath(basePath, relativePath);
		if (!File.Exists(path))
		{
			return false;
		}
		data = File.ReadAllBytes(path);
		return true;
	}

	public static bool TryValidateSavePreview(string path, out WorldSummaryData summary)
	{
		summary = null;
		if (string.IsNullOrEmpty(path))
		{
			return false;
		}
		try
		{
			if (IsZipSavePath(path))
			{
				if (!File.Exists(path))
				{
					return false;
				}
				using ZipArchive archive = ZipFile.OpenRead(path);
				if (!ValidateZipEntry(archive, "world", ensureLength: false))
				{
					return false;
				}
				if (!ValidateZipEntry(archive, "summary", ensureLength: true))
				{
					return false;
				}
				if (!ValidateZipEntry(archive, "cover", ensureLength: true))
				{
					return false;
				}
				if (!ValidateZipEntry(archive, "cover_low_res", ensureLength: true))
				{
					return false;
				}
			}
			else
			{
				if (!Directory.Exists(path))
				{
					return false;
				}
				if (!ValidateFilesystemEntry(path, "world", ensureLength: false))
				{
					return false;
				}
				if (!ValidateFilesystemEntry(path, "summary", ensureLength: true))
				{
					return false;
				}
				if (!ValidateFilesystemEntry(path, "cover", ensureLength: true))
				{
					return false;
				}
				if (!ValidateFilesystemEntry(path, "cover_low_res", ensureLength: true))
				{
					return false;
				}
			}
			if (!TryLoadWorldSummaryData(path, out summary) || summary == null)
			{
				Debug.LogWarning("[SaveSerializer] TryValidateSavePreview — summary load failed for: " + path);
				return false;
			}
			return true;
		}
		catch (Exception arg)
		{
			Debug.LogWarning($"[SaveSerializer] TryValidateSavePreview — exception for: {path}\n{arg}");
			return false;
		}
	}

	private static void FinalizeZipSave(ZipSaveContext context)
	{
		try
		{
			if (context.SaveThread != null && context.SaveThread.IsAlive)
			{
				context.SaveThread.Join();
			}
			if (string.IsNullOrEmpty(context.StagingPath) || string.IsNullOrEmpty(context.OutputZipPath) || !Directory.Exists(context.StagingPath))
			{
				return;
			}
			try
			{
				if (File.Exists(context.OutputZipPath))
				{
					File.Delete(context.OutputZipPath);
				}
			}
			catch (Exception ex)
			{
				Debug.LogError("Unable to replace existing zip save " + context.OutputZipPath + ": " + ex.Message);
				AppendToLocalErrorLog("Zip finalize delete failure" + Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace);
				return;
			}
			ZipFile.CreateFromDirectory(context.StagingPath, context.OutputZipPath, System.IO.Compression.CompressionLevel.Fastest, includeBaseDirectory: false, new MyEncoder());
		}
		catch (Exception ex2)
		{
			Debug.LogError("Failed to finalize zip save " + context.OutputZipPath + ": " + ex2.Message);
			AppendToLocalErrorLog("Problem finalizing zip save" + Environment.NewLine + ex2.Message + Environment.NewLine + ex2.StackTrace);
		}
		finally
		{
			if (!string.IsNullOrEmpty(context.StagingPath) && Directory.Exists(context.StagingPath))
			{
				try
				{
					Directory.Delete(context.StagingPath, recursive: true);
				}
				catch (Exception ex3)
				{
					Debug.LogWarning("Failed to clean up zip staging directory " + context.StagingPath + ": " + ex3.Message);
				}
			}
		}
	}

	private static Texture2D LoadTextureFromBytes(byte[] data)
	{
		if (data == null || data.Length == 0)
		{
			return null;
		}
		Texture2D texture2D = new Texture2D(2, 2)
		{
			name = "SaveImageTexture"
		};
		texture2D.LoadImage(data);
		return texture2D;
	}

	public static Texture2D LoadTextureFromSave(string basePath, string relativePath)
	{
		if (!TryReadSaveFileBytes(basePath, relativePath, out var data))
		{
			return null;
		}
		return LoadTextureFromBytes(data);
	}

	public static string GetSaveDir()
	{
		return Application.persistentDataPath + "/Saves";
	}

	public static string GetMapSaveDir()
	{
		return GetSaveDir() + "/Maps";
	}

	public static string[] GetMapSavePaths()
	{
		Directory.CreateDirectory(GetMapSaveDir());
		return Directory.GetFiles(GetMapSaveDir(), "*.zip");
	}

	private static string GetErrorLog()
	{
		return cachedPersistentDataPath + "/errorlog.txt";
	}

	public static string MakeSaveSummary(string path, string note)
	{
		WorldSummaryData worldSummaryData = LoadWorldSummaryData(path);
		string text = "";
		if (IntegrationManager.inst != null)
		{
			text = string.Format(ScriptLocalization.Version, Application.version + IntegrationManager.inst.GetVersion());
		}
		return string.Format("{1}{0}==============================={0}{7}{0}{2}{0}{3}{0}{4}{0}{5}{0}{6}{0}", Environment.NewLine, note, worldSummaryData.CityName, worldSummaryData.Year, worldSummaryData.Population, worldSummaryData.Date.ToLocalTime().ToShortTimeString(), worldSummaryData.Date.ToLocalTime().ToShortDateString(), text);
	}

	public static string PackageSave(string savePath, string saveFile)
	{
		ZipFile.CreateFromDirectory(savePath, saveFile, System.IO.Compression.CompressionLevel.Fastest, includeBaseDirectory: false, new MyEncoder());
		FileStream fileStream = new FileStream(saveFile, FileMode.Open);
		byte[] array = new byte[fileStream.Length];
		fileStream.Read(array, 0, (int)fileStream.Length);
		fileStream.Close();
		File.Delete(saveFile);
		return Convert.ToBase64String(array);
	}

	public static bool OpenSaveFromRepo(string path)
	{
		bool result = false;
		Loading = true;
		try
		{
			LoadAtPath(path, "world", visitedWorld: true);
			GameState.inst.SetNewMode(GameState.inst.playingMode);
			result = true;
		}
		catch (Exception)
		{
		}
		finally
		{
			Loading = false;
			AqueductFlowController.Reset();
		}
		return result;
	}

	public static void AppendToLocalErrorLog(string str)
	{
		StreamWriter streamWriter = new StreamWriter(GetErrorLog(), append: true);
		streamWriter.WriteLine("");
		streamWriter.WriteLine("====================[" + DateTime.Now.ToShortTimeString() + " " + DateTime.Now.ToShortDateString() + "]====================");
		streamWriter.WriteLine(str);
		streamWriter.WriteLine("");
		streamWriter.WriteLine("");
		streamWriter.Close();
		streamWriter.Dispose();
	}

	private static void ErrorToKingdomLog(Exception e)
	{
		AppendToLocalErrorLog("Problem during save" + Environment.NewLine + e.Message + Environment.NewLine + e.StackTrace);
	}

	public static void AutoSave(Guid groupGuid)
	{
		Save(string.Empty, null, isAutoSave: true);
	}

	public static void LoadAutoSave()
	{
		if (!TryLoadLatestSaveContaining("autosave"))
		{
			string path = GetSaveDir() + "/autosave";
			LoadAtPath(path, "world");
			TryLoadCustomBanner(path);
		}
	}

	public static void ReturnSave()
	{
		string path = Path.Combine(GetSaveDir(), "return");
		if (Directory.Exists(path))
		{
			try
			{
				Directory.Delete(path, recursive: true);
			}
			catch (Exception ex)
			{
				Debug.LogWarning("Failed to remove legacy return directory: " + ex.Message);
			}
		}
		Save(Path.Combine(GetSaveDir(), "return.zip"));
	}

	public static void LoadReturnSave()
	{
		string path = Path.Combine(GetSaveDir(), "return.zip");
		if (File.Exists(path))
		{
			LoadAtPath(path, "world");
			TryLoadCustomBanner(path);
		}
		else
		{
			string path2 = GetSaveDir() + "/return";
			LoadAtPath(path2, "world");
			TryLoadCustomBanner(path2);
		}
	}

	private static bool TryLoadLatestSaveContaining(string marker)
	{
		if (string.IsNullOrEmpty(marker))
		{
			return false;
		}
		string[] savePaths = GetSavePaths();
		string text = null;
		DateTime dateTime = DateTime.MinValue;
		for (int i = 0; i < savePaths.Length; i++)
		{
			string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(savePaths[i]);
			if (fileNameWithoutExtension != null && fileNameWithoutExtension.IndexOf(marker, StringComparison.OrdinalIgnoreCase) >= 0)
			{
				DateTime saveLastWriteTime = GetSaveLastWriteTime(savePaths[i]);
				if (!(saveLastWriteTime <= dateTime))
				{
					dateTime = saveLastWriteTime;
					text = savePaths[i];
				}
			}
		}
		if (string.IsNullOrEmpty(text))
		{
			return false;
		}
		if (!SaveFileExists(text, "world"))
		{
			return false;
		}
		LoadAtPath(text, "world");
		TryLoadCustomBanner(text);
		return true;
	}

	private static string CleanInput(string strIn)
	{
		try
		{
			return Regex.Replace(strIn, "[^\\w\\.@-]", "", RegexOptions.None, TimeSpan.FromSeconds(1.5));
		}
		catch (RegexMatchTimeoutException)
		{
			return string.Empty;
		}
	}

	private static string SeasonName(int seasonId)
	{
		return seasonId switch
		{
			3 => "spring", 
			0 => "summer", 
			1 => "autumn", 
			2 => "winter", 
			_ => "?", 
		};
	}

	public static Thread Save(string pathOverride = "", UnityAction onCompleteCallback = null, bool isAutoSave = false, bool isMapSave = false, string mapName = null)
	{
		if (thread != null && thread.IsAlive)
		{
			thread.Join();
		}
		Directory.CreateDirectory(GetSaveDir());
		string text = "UntitledCity";
		if (TownNameUI.inst != null)
		{
			string townName = TownNameUI.inst.townName;
			townName = CleanInput(townName);
			if (!string.IsNullOrEmpty(townName))
			{
				text = townName;
			}
		}
		string empty = string.Empty;
		string text2 = SeasonName(SeasonManager.inst.CurrentSeason?.id ?? (-1));
		if (isMapSave)
		{
			string text3 = CleanInput(mapName ?? string.Empty);
			if (string.IsNullOrEmpty(text3))
			{
				text3 = World.inst.GetTextSeed();
			}
			empty = $"{text3}-{DateTime.Now:yyyy-MM-dd-HH-mm-ss}";
		}
		else if (isAutoSave)
		{
			empty = $"{text}-{SeasonManager.inst.CurrentYear()}-{text2}-autosave-{World.inst.guid}";
			string[] directories = Directory.GetDirectories(GetSaveDir());
			foreach (string text4 in directories)
			{
				if (text4.Contains(World.inst.guid.ToString()))
				{
					Directory.Delete(text4, recursive: true);
				}
			}
			string[] files = Directory.GetFiles(GetSaveDir(), "*.zip");
			foreach (string text5 in files)
			{
				if (text5.Contains(World.inst.guid.ToString()))
				{
					File.Delete(text5);
				}
			}
		}
		else
		{
			empty = $"{text}-{SeasonManager.inst.CurrentYear()}-{text2}-{DateTime.Now:yyyy-MM-dd-HH-mm-ss}";
		}
		string text6 = (string.IsNullOrEmpty(pathOverride) ? Path.Combine(isMapSave ? GetMapSaveDir() : GetSaveDir(), empty + ".zip") : pathOverride);
		bool flag = IsZipSavePath(text6);
		string text7 = text6;
		string text8 = null;
		ZipSaveContext zipSaveContext = default;
		bool flag2 = false;
		if (flag)
		{
			text8 = text6;
			string text9 = Path.GetDirectoryName(text8);
			if (string.IsNullOrEmpty(text9))
			{
				text9 = GetSaveDir();
			}
			Directory.CreateDirectory(text9);
			text7 = Path.Combine(Path.GetTempPath(), "RomaZetaZipSave_" + Guid.NewGuid().ToString("N"));
		}
		Directory.CreateDirectory(text7);
		try
		{
			thread = new Thread(OutToFile);
			LoadSaveContainer loadSaveContainer = new LoadSaveContainer().Pack(null);
			Broadcast.OnSaveEvent.Broadcast(new OnSaveEvent());
			thread.Start(new OutData
			{
				LoadSaveContainer = loadSaveContainer,
				Path = text7 + "/world"
			});
			if (flag)
			{
				zipSaveContext = new ZipSaveContext
				{
					StagingPath = text7,
					OutputZipPath = text8,
					SaveThread = thread
				};
				flag2 = true;
			}
		}
		catch (Exception e)
		{
			ErrorToKingdomLog(e);
			throw;
		}
		finally
		{
			SaveWorldSummaryData(text7, isMapSave, mapName);
		}
		try
		{
			if (Player.inst.usingCustomBanner)
			{
				File.WriteAllBytes(text7 + "/custombanner.png", Player.inst.customBannerTexture2D.EncodeToPNG());
			}
		}
		catch (Exception ex)
		{
			Debug.LogError(ex.Message);
		}
		ScreenshotManager.inst.MakeScreenshotOfCamera(text7 + "/cover_low_res", 640, 360, () =>
		{
		});
		UnityAction completionCallback = onCompleteCallback;
		if (flag & flag2)
		{
			ZipSaveContext context = zipSaveContext;
			completionCallback = () =>
			{
				Task.Run(() =>
				{
					FinalizeZipSave(context);
					if (onCompleteCallback != null)
					{
						RunOnMainThreadLater(() =>
						{
							onCompleteCallback();
						});
					}
				});
			};
		}
		ScreenshotManager.inst.MakeScreenshotOfWorld(text7 + "/cover", 3840, 2160, () =>
		{
			completionCallback?.Invoke();
		});
		if (onCompleteCallback != null && thread != null && thread.IsAlive)
		{
			thread.Join();
		}
		return thread;
	}

	internal static bool OnApplicationWantsToQuit()
	{
		if (thread != null && thread.IsAlive)
		{
			thread.Join();
		}
		if (!World.inst.triedQuittingAlready && (GameState.inst.CurrMode == GameState.inst.playingMode || (GameState.inst.CurrMode == GameState.inst.mainMenuMode && GameState.inst.mainMenuMode.pauseMenuUICanvas.enabled)))
		{
			GameState.inst.SetNewMode(GameState.inst.mainMenuMode);
			GameState.inst.mainMenuMode.OnExitFromGame();
			World.inst.triedQuittingAlready = true;
			return false;
		}
		return true;
	}

	private static void OutToFile(object data)
	{
		OutData outData = (OutData)data;
		Stream stream = null;
		try
		{
			stream = new FileStream(outData.Path, FileMode.Create, FileAccess.Write);
			SaveSerializer.SerializeToStream(outData.LoadSaveContainer, stream);
		}
		catch (Exception ex)
		{
			Debug.LogError($"[SaveSerializer] OutToFile FAILED: {ex}");
			AppendToLocalErrorLog("Problem during save" + Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace);
		}
		finally
		{
			stream?.Dispose();
		}
	}

	public static void SaveWorldSummaryData(string path, bool isMapSave = false, string mapName = null)
	{
		WorldSummaryData worldSummaryData = new WorldSummaryData
		{
			CityName = TownNameUI.inst.townName,
			Date = DateTime.UtcNow,
			Population = Player.inst.PlayerOwnerWorkersCount(),
			Year = SeasonManager.inst.CurrentYear(),
			ShareCode = Player.inst.tourism.code,
			guid = World.inst.guid
		};
		if (isMapSave)
		{
			worldSummaryData.CityName = (string.IsNullOrEmpty(mapName) ? World.inst.GetTextSeed() : mapName);
			worldSummaryData.Population = 0;
			worldSummaryData.Year = 0;
			worldSummaryData.ShareCode = null;
		}
		Stream stream = null;
		try
		{
			stream = new FileStream(path + "/summary", FileMode.Create, FileAccess.Write);
			SaveSerializer.SerializeToStream(worldSummaryData, stream);
		}
		catch (Exception e)
		{
			ErrorToKingdomLog(e);
			throw;
		}
		finally
		{
			stream?.Dispose();
		}
	}

	public static WorldSummaryData LoadWorldSummaryData(string path)
	{
		if (TryLoadWorldSummaryDataInternal(path, out var summary, out var error) && summary != null)
		{
			return summary;
		}
		if (error != null)
		{
			ErrorToKingdomLog(error);
		}
		return new WorldSummaryData
		{
			CityName = ScriptLocalization.LoadSaveProblemLoadingStats
		};
	}

	public static WorldSummaryData LoadWorldSummaryData(BuiltInSave path)
	{
		WorldSummaryData worldSummaryData = null;
		MemoryStream memoryStream = new MemoryStream(path.summary.bytes);
		worldSummaryData = SaveSerializer.DeserializeFromStream<WorldSummaryData>(memoryStream);
		memoryStream.Close();
		memoryStream.Dispose();
		return worldSummaryData;
	}

	public static bool TryLoadWorldSummaryData(string path, out WorldSummaryData summary)
	{
		Exception error;
		return TryLoadWorldSummaryDataInternal(path, out summary, out error);
	}

	private static bool TryLoadWorldSummaryDataInternal(string path, out WorldSummaryData summary, out Exception error)
	{
		summary = null;
		error = null;
		if (!SaveFileExists(path, "summary"))
		{
			return false;
		}
		Stream stream = null;
		try
		{
			stream = OpenSaveReadStream(path, "summary");
			summary = SaveSerializer.DeserializeFromStream<WorldSummaryData>(stream);
			return summary != null;
		}
		catch (LegacyFormatException ex)
		{
			Debug.LogWarning("[SaveSerializer] " + ex.Message);
			error = ex;
			return false;
		}
		catch (Exception ex2)
		{
			Debug.LogWarning($"[SaveSerializer] TryLoadWorldSummaryDataInternal FAILED for: {path}\n{ex2}");
			error = ex2;
			return false;
		}
		finally
		{
			stream?.Dispose();
		}
	}

	public static void Load(string guid = "")
	{
		string[] savePaths = GetSavePaths();
		if (savePaths.Length == 0)
		{
			return;
		}
		DateTime dateTime = DateTime.MinValue;
		string text = string.Empty;
		string text2 = (string.IsNullOrEmpty(guid) ? string.Empty : guid);
		string b = text2.TrimStart('/', '\\');
		string[] array = savePaths;
		foreach (string text3 in array)
		{
			string saveIdentifier = GetSaveIdentifier(text3);
			if (!string.IsNullOrEmpty(text2))
			{
				string a = saveIdentifier.TrimStart('/');
				if (string.Equals(saveIdentifier, text2, StringComparison.OrdinalIgnoreCase) || string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
				{
					LoadAtPath(text3, "world");
					TryLoadCustomBanner(text3);
					return;
				}
			}
			DateTime saveLastWriteTime = GetSaveLastWriteTime(text3);
			if (!(saveLastWriteTime <= dateTime))
			{
				dateTime = saveLastWriteTime;
				text = text3;
			}
		}
		if (!string.IsNullOrEmpty(text))
		{
			LoadAtPath(text, "world");
			TryLoadCustomBanner(text);
		}
	}

	public static WorldSummaryData GetContinueSummary()
	{
		if (!continueWorldReady)
		{
			return null;
		}
		return continueSummary;
	}

	public static bool HasAnySaves()
	{
		return GetSavePaths().Length != 0;
	}

	public static string GetMostRecentSavePath()
	{
		List<KeyValuePair<DateTime, string>> list = new List<KeyValuePair<DateTime, string>>();
		string[] savePaths = GetSavePaths();
		foreach (string text in savePaths)
		{
			list.Add(new KeyValuePair<DateTime, string>(GetSaveLastWriteTime(text), text));
		}
		list.Sort((KeyValuePair<DateTime, string> a, KeyValuePair<DateTime, string> b) => b.Key.CompareTo(a.Key));
		foreach (KeyValuePair<DateTime, string> item in list)
		{
			try
			{
				if (SaveFileExists(item.Value, "world"))
				{
					return item.Value;
				}
			}
			catch
			{
			}
		}
		return string.Empty;
	}

	public static bool TryPreloadContinueWorld()
	{
		ClearContinueWorld();
		failedContinuePath = null;
		string text = string.Empty;
		bool loadFailed = false;
		Application.logMessageReceived += OnLoadLog;
		try
		{
			text = GetMostRecentSavePath();
			if (string.IsNullOrEmpty(text))
			{
				return false;
			}
			LoadSaveContainer loadSaveContainer;
			using (Stream stream = OpenSaveReadStream(text, "world"))
			{
				loadSaveContainer = SaveSerializer.DeserializeFromStream<LoadSaveContainer>(stream);
			}
			LastLoadDirectory = text;
			Loading = true;
			loadSaveContainer.Unpack(null);
			if (loadFailed)
			{
				return false;
			}
			Broadcast.OnLoadedEvent.Broadcast(new OnLoadedEvent());
			Loading = false;
			if (onLoadFinished != null)
			{
				onLoadFinished("continue");
			}
			TryLoadCustomBanner(text);
			TryLoadWorldSummaryData(text, out continueSummary);
			if (loadFailed)
			{
				return false;
			}
			continuePath = text;
			continueWorldReady = true;
			Application.logMessageReceived += OnContinueWorldLog;
			return true;
		}
		catch (Exception arg)
		{
			Debug.LogWarning($"[Continue] Failed to preload most recent save '{text}' behind menu, falling back to demo: {arg}");
			return false;
		}
		finally
		{
			Application.logMessageReceived -= OnLoadLog;
			Loading = false;
			if (!continueWorldReady)
			{
				ClearContinueWorld();
				MarkContinueLoadFailed(text);
			}
		}
		void OnLoadLog(string message, string stackTrace, LogType type)
		{
			if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert)
			{
				loadFailed = true;
			}
		}
	}

	public static void ClearContinueWorld()
	{
		Application.logMessageReceived -= OnContinueWorldLog;
		continueWorldReady = false;
		continueWorldFailed = false;
		continueSummary = null;
		continuePath = null;
	}

	private static void MarkContinueLoadFailed(string path)
	{
		failedContinuePath = path;
		if (!string.IsNullOrEmpty(path))
		{
			failedContinueWriteTime = GetSaveLastWriteTime(path);
		}
	}

	private static void OnContinueWorldLog(string message, string stackTrace, LogType type)
	{
		if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert)
		{
			continueWorldReady = false;
			continueWorldFailed = true;
			MarkContinueLoadFailed(continuePath);
		}
	}

	public static void Load(BuiltInSave save)
	{
		ClearContinueWorld();
		WorldSummaryData worldSummary = LoadWorldSummaryData(save);
		Texture2D texture2D = new Texture2D(2, 2);
		texture2D.name = "BuiltInSaveCover";
		texture2D.LoadImage(save.cover.bytes);
		Loading = true;
		loadThreadedFinished = false;
		loadThreadedSuccess = false;
		SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_loadingsave");
		SaveGameLoadingScreen.inst.Show(show: true, worldSummary, texture2D);
		onLoadStart?.Invoke();
		LoadThreadedBuiltIn(save);
	}

	public static void TryLoadCustomBanner(string path)
	{
		try
		{
			Texture2D texture2D = null;
			if (IsZipSavePath(path))
			{
				texture2D = LoadTextureFromSave(path, "/custombanner.png");
			}
			else
			{
				string text = path + "/custombanner.png";
				if (File.Exists(text))
				{
					texture2D = Util.LoadPNG(text);
				}
			}
			if (texture2D != null)
			{
				Player.inst.SetCustomBannerTexture(texture2D);
				Player.inst.usingCustomBanner = true;
			}
		}
		catch (Exception ex)
		{
			Debug.LogError("Failed loading custom banner: " + path + ", " + ex.Message);
		}
	}

	public static void Delete(string path)
	{
		try
		{
			if (IsZipSavePath(path))
			{
				if (File.Exists(path))
				{
					File.Delete(path);
				}
			}
			else if (Directory.Exists(path))
			{
				Directory.Delete(path, recursive: true);
			}
		}
		catch (Exception ex)
		{
			Debug.LogError("Failed to delete save at " + path + ": " + ex.Message);
		}
	}

	public static string[] GetSavePaths()
	{
		if (!Directory.Exists(GetSaveDir()))
		{
			Directory.CreateDirectory(GetSaveDir());
		}
		string[] directories = Directory.GetDirectories(GetSaveDir());
		string[] files = Directory.GetFiles(GetSaveDir(), "*.zip");
		List<string> list = new List<string>(directories);
		list.AddRange(files);
		return list.ToArray();
	}

	public static void LoadAtPath(string path, string filename, bool visitedWorld = false)
	{
		if (loadIntoMapSelect)
		{
			preMapLoadCreativeState = new Creative.CreativeSaveData().Pack(Creative.inst);
		}
		LastLoadDirectory = path;
		Debug.Log("Loading saved game.");
		if (IsZipSavePath(path))
		{
			if (!SaveFileExists(path, filename))
			{
				return;
			}
			loadThreadedIsZip = true;
			loadThreadedRelativeFile = filename;
			loadThreadedPath = path;
		}
		else
		{
			string path2 = Path.Combine(path, filename);
			if (!File.Exists(path2))
			{
				return;
			}
			loadThreadedIsZip = false;
			loadThreadedRelativeFile = null;
			loadThreadedPath = path2;
		}
		ClearContinueWorld();
		WorldSummaryData worldSummary = LoadWorldSummaryData(LastLoadDirectory);
		Texture2D cover = LoadTextureFromSave(LastLoadDirectory, "cover");
		Loading = true;
		loadThreadedFinished = false;
		loadThreadedSuccess = false;
		SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_loadingsave");
		SaveGameLoadingScreen.inst.Show(show: true, worldSummary, cover);
		onLoadStart?.Invoke();
		LoadThreaded();
	}

	public static void LoadThreaded()
	{
		if (thread != null && thread.IsAlive)
		{
			thread.Join();
		}
		Stream stream = null;
		try
		{
			stream = (loadThreadedIsZip ? OpenSaveReadStream(loadThreadedPath, loadThreadedRelativeFile) : new FileStream(loadThreadedPath, FileMode.Open, FileAccess.Read, FileShare.Read));
			SaveSerializer.DeserializeFromStream<LoadSaveContainer>(stream).UnpackThreaded(null);
			RunOnMainThreadLater(() =>
			{
				SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_complete");
				Broadcast.OnLoadedEvent.Broadcast(new OnLoadedEvent());
				loadThreadedSuccess = true;
				GC.Collect();
			});
		}
		catch (LegacyFormatException ex)
		{
			loadThreadedSuccess = false;
			Debug.LogWarning("[LoadSave] " + ex.Message);
		}
		catch (Exception ex2)
		{
			loadThreadedSuccess = false;
			Debug.LogError(ex2.ToString());
		}
		finally
		{
			stream?.Dispose();
			RunOnMainThreadLater(() =>
			{
				loadThreadedFinished = true;
			});
		}
	}

	public static void LoadThreadedBuiltIn(BuiltInSave save)
	{
		if (thread != null && thread.IsAlive)
		{
			thread.Join();
		}
		Stream stream = null;
		try
		{
			stream = new MemoryStream(save.world.bytes);
			SaveSerializer.DeserializeFromStream<LoadSaveContainer>(stream).UnpackThreaded(null);
			RunOnMainThreadLater(() =>
			{
				SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_complete");
				Broadcast.OnLoadedEvent.Broadcast(new OnLoadedEvent());
				loadThreadedSuccess = true;
			});
		}
		catch (LegacyFormatException ex)
		{
			loadThreadedSuccess = false;
			Debug.LogWarning("[LoadSave] " + ex.Message);
		}
		catch (Exception ex2)
		{
			loadThreadedSuccess = false;
			Debug.LogError(ex2.ToString());
		}
		finally
		{
			stream?.Dispose();
			RunOnMainThreadLater(() =>
			{
				loadThreadedFinished = true;
			});
		}
	}

	public static void Update()
	{
		if (continueWorldFailed)
		{
			ClearContinueWorld();
			Debug.LogWarning("[Continue] Preloaded world reported an error; falling back to demo.");
			Resources.Load<ScenarioWorlds>("ScenarioWorlds").OnLoadDemo();
			GameState.inst.mainMenuMode.RefreshMenuBackdrop();
		}
		if (!actionQueue.IsEmpty)
		{
			actionQueue.TryDequeue(out var result);
			try
			{
				result();
			}
			catch (Exception)
			{
				loadThreadedSuccess = false;
				loadThreadedFinished = true;
				actionQueue.Clear();
				throw;
			}
		}
		if (loadThreadedFinished && Loading && actionQueue.IsEmpty)
		{
			Loading = false;
			AqueductFlowController.Reset();
			bool flag = loadIntoMapSelect;
			SaveGameLoadingScreen.inst.Show(show: false);
			loadIntoMapSelect = false;
			if (!loadThreadedSuccess)
			{
				GameState.inst.SetNewMode(GameState.inst.mainMenuMode);
				GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.LoadError);
			}
			else if (flag)
			{
				preMapLoadCreativeState.Unpack(Creative.inst);
				GameState.inst.mainMenuMode.OnMapLoadedIntoMapSelect();
			}
			onLoadFinished?.Invoke();
		}
	}
}
