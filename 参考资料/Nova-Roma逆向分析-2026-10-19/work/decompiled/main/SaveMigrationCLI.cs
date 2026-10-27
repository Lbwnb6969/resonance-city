using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Runtime.Serialization.Formatters.Binary;
using System.Threading;
using System.Threading.Tasks;
using Assets;
using Sirenix.Serialization;
using UnityEngine;

public static class SaveMigrationCLI
{
	private struct PendingSave
	{
		public string path;

		public bool worldLegacy;

		public bool summaryLegacy;

		public bool isZip;
	}

	public enum Fmt
	{
		Odin,
		Legacy,
		Missing,
		Error
	}

	private const byte ODIN_MARKER = 79;

	private static readonly object processedLock = new object();

	public static int Run(string persistentDataPath, bool convert, Action<string> onMessage)
	{
		Action<string> emit = onMessage ?? ((Action<string>)((string _) =>
		{
		}));
		string text = persistentDataPath + "/Saves";
		string path = persistentDataPath + "/settings";
		string path2 = text + "/crossgamedata.dat";
		string processedPath = text + "/.migration_processed";
		RecoverInterrupted(path);
		RecoverInterrupted(path2);
		if (Directory.Exists(text))
		{
			string[] files = Directory.GetFiles(text, "*.tmp");
			foreach (string text2 in files)
			{
				RecoverInterrupted(text2.Substring(0, text2.Length - 4));
			}
			files = Directory.GetDirectories(text);
			foreach (string text3 in files)
			{
				if (!text3.EndsWith(".bak", StringComparison.OrdinalIgnoreCase))
				{
					RecoverInterrupted(Path.Combine(text3, "world"));
					RecoverInterrupted(Path.Combine(text3, "summary"));
				}
			}
		}
		HashSet<string> hashSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		if (File.Exists(processedPath))
		{
			string[] files = File.ReadAllLines(processedPath);
			for (int num = 0; num < files.Length; num++)
			{
				string text4 = files[num].Trim();
				if (text4.Length != 0)
				{
					int num2 = text4.IndexOf('|');
					string text5 = ((num2 >= 0) ? text4.Substring(0, num2) : text4);
					hashSet.Add(text5.TrimEnd('/'));
				}
			}
		}
		int num3 = 0;
		int num4 = 0;
		Fmt fmt = Fmt.Missing;
		if (!hashSet.Contains("settings"))
		{
			fmt = DetectFile(path);
			if (fmt != Fmt.Missing)
			{
				num4++;
				if (fmt == Fmt.Legacy)
				{
					num3++;
				}
				else
				{
					AppendProcessed(processedPath, "settings");
				}
			}
		}
		Fmt fmt2 = Fmt.Missing;
		if (!hashSet.Contains("crossgamedata.dat"))
		{
			fmt2 = DetectFile(path2);
			if (fmt2 != Fmt.Missing)
			{
				num4++;
				if (fmt2 == Fmt.Legacy)
				{
					num3++;
				}
				else
				{
					AppendProcessed(processedPath, "crossgamedata.dat");
				}
			}
		}
		List<PendingSave> list = new List<PendingSave>();
		if (Directory.Exists(text))
		{
			List<string> list2 = new List<string>();
			string[] files = Directory.GetFiles(text, "*.zip");
			foreach (string text6 in files)
			{
				if (!hashSet.Contains(Path.GetFileName(text6)))
				{
					list2.Add(text6);
				}
			}
			List<string> list3 = new List<string>();
			foreach (string item in list2)
			{
				DetectZipEntries(item, out var worldFmt, out var summaryFmt);
				num4++;
				if (worldFmt == Fmt.Legacy || summaryFmt == Fmt.Legacy)
				{
					num3++;
					list.Add(new PendingSave
					{
						path = item,
						worldLegacy = (worldFmt == Fmt.Legacy),
						summaryLegacy = (summaryFmt == Fmt.Legacy),
						isZip = true
					});
				}
				else
				{
					list3.Add(Path.GetFileName(item));
				}
			}
			if (list3.Count > 0)
			{
				AppendProcessed(processedPath, list3);
			}
			List<string> list4 = new List<string>();
			files = Directory.GetDirectories(text);
			foreach (string text7 in files)
			{
				if (!text7.EndsWith(".bak", StringComparison.OrdinalIgnoreCase) && File.Exists(Path.Combine(text7, "world")) && !hashSet.Contains(Path.GetFileName(text7)))
				{
					list4.Add(text7);
				}
			}
			List<string> list5 = new List<string>();
			foreach (string item2 in list4)
			{
				Fmt fmt3 = DetectFile(Path.Combine(item2, "world"));
				Fmt fmt4 = DetectFile(Path.Combine(item2, "summary"));
				num4++;
				if (fmt3 == Fmt.Legacy || fmt4 == Fmt.Legacy)
				{
					num3++;
					list.Add(new PendingSave
					{
						path = item2,
						worldLegacy = (fmt3 == Fmt.Legacy),
						summaryLegacy = (fmt4 == Fmt.Legacy),
						isZip = false
					});
				}
				else
				{
					list5.Add(Path.GetFileName(item2));
				}
			}
			if (list5.Count > 0)
			{
				AppendProcessed(processedPath, list5);
			}
		}
		emit($"SCAN_DONE|legacy:{num3}|total:{num4}");
		if (num3 == 0)
		{
			return 0;
		}
		if (!convert)
		{
			return 1;
		}
		int converted = 0;
		int failed = 0;
		if (fmt == Fmt.Legacy)
		{
			emit("CONVERTING|settings");
			if (TryConvertFile<Settings.SettingsSaveData>(path, emit, out var error))
			{
				converted++;
				emit("CONVERT_OK|settings");
				AppendProcessed(processedPath, "settings");
			}
			else
			{
				failed++;
				AppendProcessed(processedPath, "settings|ERROR: " + error);
			}
		}
		if (fmt2 == Fmt.Legacy)
		{
			emit("CONVERTING|crossgamedata.dat");
			if (TryConvertFile<CrossGameData.CrossGameSaveData>(path2, emit, out var error2))
			{
				converted++;
				emit("CONVERT_OK|crossgamedata.dat");
				AppendProcessed(processedPath, "crossgamedata.dat");
			}
			else
			{
				failed++;
				AppendProcessed(processedPath, "crossgamedata.dat|ERROR: " + error2);
			}
		}
		ParallelOptions parallelOptions = new ParallelOptions
		{
			MaxDegreeOfParallelism = Math.Max(1, Environment.ProcessorCount / 2)
		};
		Parallel.ForEach(list, parallelOptions, (PendingSave save) =>
		{
			string text8;
			bool flag;
			string error3;
			if (save.isZip)
			{
				text8 = Path.GetFileNameWithoutExtension(save.path) + ".zip";
				emit("CONVERTING|" + text8);
				flag = TryConvertZip(save.path, save.worldLegacy, save.summaryLegacy, emit, out error3);
			}
			else
			{
				text8 = Path.GetFileName(save.path);
				emit("CONVERTING|" + text8);
				flag = TryConvertDir(save.path, save.worldLegacy, save.summaryLegacy, emit, out error3);
			}
			if (flag)
			{
				Interlocked.Increment(ref converted);
				emit("CONVERT_OK|" + text8);
				AppendProcessed(processedPath, text8);
			}
			else
			{
				Interlocked.Increment(ref failed);
				AppendProcessed(processedPath, text8 + "|ERROR: " + error3);
			}
		});
		emit($"CONVERT_DONE|converted:{converted}|failed:{failed}");
		if (failed > 0)
		{
			Debug.LogWarning($"[SaveMigration] {failed} save(s) could not be converted. Check errors above.");
		}
		if (failed <= 0)
		{
			return 0;
		}
		return 1;
	}

	private static void AppendProcessed(string path, string entry)
	{
		lock (processedLock)
		{
			try
			{
				File.AppendAllText(path, entry + "\n");
			}
			catch (Exception ex)
			{
				Debug.LogWarning("[SaveMigration] Failed to write processed entry: " + ex.Message);
			}
		}
	}

	private static void AppendProcessed(string path, IEnumerable<string> entries)
	{
		lock (processedLock)
		{
			try
			{
				using StreamWriter streamWriter = new StreamWriter(path, append: true);
				foreach (string entry in entries)
				{
					streamWriter.WriteLine(entry);
				}
			}
			catch (Exception ex)
			{
				Debug.LogWarning("[SaveMigration] Failed to write processed entries: " + ex.Message);
			}
		}
	}

	private static void RecoverInterrupted(string path)
	{
		string path2 = path + ".tmp";
		string text = path + ".bak";
		if (File.Exists(path2))
		{
			try
			{
				File.Delete(path2);
			}
			catch
			{
			}
		}
		if (!File.Exists(path) && File.Exists(text))
		{
			try
			{
				File.Move(text, path);
				Debug.Log("[SaveMigration] Recovered interrupted conversion: " + Path.GetFileName(path));
			}
			catch
			{
			}
		}
	}

	public static Fmt DetectFile(string path)
	{
		if (!File.Exists(path))
		{
			return Fmt.Missing;
		}
		try
		{
			using FileStream fileStream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
			return (fileStream.ReadByte() != 79) ? Fmt.Legacy : Fmt.Odin;
		}
		catch (Exception arg)
		{
			Debug.LogWarning($"[SaveMigrationCLI] DetectFile error: {path}\n{arg}");
			return Fmt.Error;
		}
	}

	public static Fmt DetectZipEntry(string zipPath, string entry)
	{
		try
		{
			using ZipArchive zip = ZipFile.OpenRead(zipPath);
			ZipArchiveEntry zipArchiveEntry = FindEntry(zip, entry);
			if (zipArchiveEntry == null)
			{
				return Fmt.Missing;
			}
			using Stream stream = zipArchiveEntry.Open();
			return (stream.ReadByte() != 79) ? Fmt.Legacy : Fmt.Odin;
		}
		catch (Exception arg)
		{
			Debug.LogWarning($"[SaveMigrationCLI] DetectZipEntry error: {zipPath}/{entry}\n{arg}");
			return Fmt.Error;
		}
	}

	public static void DetectZipEntries(string zipPath, out Fmt worldFmt, out Fmt summaryFmt)
	{
		worldFmt = Fmt.Missing;
		summaryFmt = Fmt.Missing;
		try
		{
			using ZipArchive zip = ZipFile.OpenRead(zipPath);
			ZipArchiveEntry zipArchiveEntry = FindEntry(zip, "world");
			if (zipArchiveEntry != null)
			{
				using Stream stream = zipArchiveEntry.Open();
				worldFmt = ((stream.ReadByte() != 79) ? Fmt.Legacy : Fmt.Odin);
			}
			ZipArchiveEntry zipArchiveEntry2 = FindEntry(zip, "summary");
			if (zipArchiveEntry2 != null)
			{
				using (Stream stream2 = zipArchiveEntry2.Open())
				{
					summaryFmt = ((stream2.ReadByte() != 79) ? Fmt.Legacy : Fmt.Odin);
					return;
				}
			}
		}
		catch (Exception arg)
		{
			Debug.LogWarning($"[SaveMigrationCLI] DetectZipEntries error: {zipPath}\n{arg}");
			worldFmt = Fmt.Error;
			summaryFmt = Fmt.Error;
		}
	}

	private static ZipArchiveEntry FindEntry(ZipArchive zip, string name)
	{
		name = name.TrimStart('/', '\\').Replace('\\', '/');
		foreach (ZipArchiveEntry entry in zip.Entries)
		{
			if (entry.FullName.Replace('\\', '/').EndsWith(name, StringComparison.OrdinalIgnoreCase))
			{
				return entry;
			}
		}
		return null;
	}

	private static byte[] ToOdin<T>(byte[] input)
	{
		if (input == null || input.Length == 0 || input[0] == 79)
		{
			return null;
		}
		T value;
		using (MemoryStream serializationStream = new MemoryStream(input))
		{
			value = (T)new BinaryFormatter().Deserialize(serializationStream);
		}
		using MemoryStream memoryStream = new MemoryStream();
		memoryStream.WriteByte(79);
		SerializationContext serializationContext = new SerializationContext();
		serializationContext.Config.SerializationPolicy = SerializationPolicies.Everything;
		SerializationUtility.SerializeValue(value, memoryStream, DataFormat.Binary, serializationContext);
		return memoryStream.ToArray();
	}

	private static void AtomicWrite(string path, byte[] data)
	{
		DateTime lastWriteTimeUtc = File.GetLastWriteTimeUtc(path);
		string text = path + ".tmp";
		File.WriteAllBytes(text, data);
		if (File.Exists(path))
		{
			string text2 = path + ".bak";
			if (File.Exists(text2))
			{
				File.Delete(text2);
			}
			File.Move(path, text2);
		}
		File.Move(text, path);
		File.SetLastWriteTimeUtc(path, lastWriteTimeUtc);
		CleanupBak(path);
	}

	public static bool TryConvertFile<T>(string path, Action<string> emit, out string error)
	{
		error = null;
		try
		{
			byte[] array = ToOdin<T>(File.ReadAllBytes(path));
			if (array == null)
			{
				return true;
			}
			AtomicWrite(path, array);
			return true;
		}
		catch (Exception ex)
		{
			error = Flat(ex);
			Debug.LogWarning($"[SaveMigration] Failed to convert {Path.GetFileName(path)}\n{ex}");
			emit("CONVERT_FAIL|" + Path.GetFileName(path) + "|" + error);
			return false;
		}
	}

	public static bool TryConvertZip(string zipPath, bool worldLegacy, bool summaryLegacy, Action<string> emit, out string error)
	{
		error = null;
		string text = Path.GetFileNameWithoutExtension(zipPath) + ".zip";
		try
		{
			DateTime lastWriteTimeUtc = File.GetLastWriteTimeUtc(zipPath);
			string text2 = zipPath + ".tmp";
			using (ZipArchive zipArchive = ZipFile.OpenRead(zipPath))
			{
				using ZipArchive zipArchive2 = new ZipArchive(File.Create(text2), ZipArchiveMode.Create);
				foreach (ZipArchiveEntry entry in zipArchive.Entries)
				{
					string text3 = entry.FullName.Replace('\\', '/');
					ZipArchiveEntry zipArchiveEntry = zipArchive2.CreateEntry(entry.FullName, System.IO.Compression.CompressionLevel.Fastest);
					zipArchiveEntry.LastWriteTime = entry.LastWriteTime;
					using Stream stream = entry.Open();
					using Stream stream2 = zipArchiveEntry.Open();
					if ((text3 == "world") & worldLegacy)
					{
						WriteConverted<LoadSaveContainer>(stream, stream2);
					}
					else if ((text3 == "summary") & summaryLegacy)
					{
						WriteConverted<LoadSave.WorldSummaryData>(stream, stream2);
					}
					else
					{
						stream.CopyTo(stream2);
					}
				}
			}
			string text4 = zipPath + ".bak";
			if (File.Exists(text4))
			{
				File.Delete(text4);
			}
			File.Move(zipPath, text4);
			File.Move(text2, zipPath);
			File.SetLastWriteTimeUtc(zipPath, lastWriteTimeUtc);
			CleanupZipBak(zipPath);
			return true;
		}
		catch (Exception ex)
		{
			error = Flat(ex);
			Debug.LogWarning($"[SaveMigration] Failed to convert {text}\n{ex}");
			emit("CONVERT_FAIL|" + text + "|" + error);
			return false;
		}
	}

	public static bool TryConvertDir(string dir, bool worldLegacy, bool summaryLegacy, Action<string> emit, out string error)
	{
		error = null;
		string text = Path.GetFileName(dir) + "/";
		try
		{
			if (worldLegacy)
			{
				string path = Path.Combine(dir, "world");
				byte[] array = ToOdin<LoadSaveContainer>(File.ReadAllBytes(path));
				if (array != null)
				{
					AtomicWrite(path, array);
				}
			}
			if (summaryLegacy)
			{
				string path2 = Path.Combine(dir, "summary");
				if (File.Exists(path2))
				{
					byte[] array2 = ToOdin<LoadSave.WorldSummaryData>(File.ReadAllBytes(path2));
					if (array2 != null)
					{
						AtomicWrite(path2, array2);
					}
				}
			}
			return true;
		}
		catch (Exception ex)
		{
			error = Flat(ex);
			Debug.LogWarning($"[SaveMigration] Failed to convert {text}\n{ex}");
			emit("CONVERT_FAIL|" + text + "|" + error);
			return false;
		}
	}

	private static void WriteConverted<T>(Stream input, Stream output)
	{
		byte[] array = ReadAll(input);
		byte[] array2 = ToOdin<T>(array) ?? array;
		output.Write(array2, 0, array2.Length);
	}

	private static byte[] ReadAll(Stream s)
	{
		using MemoryStream memoryStream = new MemoryStream();
		s.CopyTo(memoryStream);
		return memoryStream.ToArray();
	}

	private static void CleanupZipBak(string zipPath)
	{
		string path = zipPath + ".bak";
		if (!File.Exists(path))
		{
			return;
		}
		try
		{
			using (ZipArchive zip = ZipFile.OpenRead(zipPath))
			{
				ZipArchiveEntry zipArchiveEntry = FindEntry(zip, "world");
				if (zipArchiveEntry == null)
				{
					Debug.LogWarning("[SaveMigration] Verification failed for " + Path.GetFileName(zipPath) + " — no world entry, keeping .bak");
					return;
				}
				using Stream stream = zipArchiveEntry.Open();
				if (stream.ReadByte() != 79)
				{
					Debug.LogWarning("[SaveMigration] Verification failed for " + Path.GetFileName(zipPath) + " — keeping .bak");
					return;
				}
			}
			File.Delete(path);
		}
		catch (Exception ex)
		{
			Debug.LogWarning("[SaveMigration] Could not clean up " + Path.GetFileName(path) + ": " + ex.Message);
		}
	}

	private static void CleanupBak(string path)
	{
		string path2 = path + ".bak";
		if (!File.Exists(path2))
		{
			return;
		}
		try
		{
			using (FileStream fileStream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
			{
				if (fileStream.ReadByte() != 79 || fileStream.Length < 2)
				{
					Debug.LogWarning("[SaveMigration] Verification failed for " + Path.GetFileName(path) + " — keeping .bak");
					return;
				}
			}
			File.Delete(path2);
		}
		catch (Exception ex)
		{
			Debug.LogWarning("[SaveMigration] Could not clean up " + Path.GetFileName(path2) + ": " + ex.Message);
		}
	}

	private static string Flat(Exception e)
	{
		return e.Message.Replace('\n', ' ').Replace('\r', ' ');
	}
}
