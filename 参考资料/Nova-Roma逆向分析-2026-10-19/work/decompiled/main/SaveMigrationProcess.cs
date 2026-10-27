using System;
using System.Threading;
using UnityEngine;

public class SaveMigrationProcess
{
	public volatile bool ScanComplete;

	public volatile int LegacyCount;

	public volatile int TotalCount;

	public volatile int Converted;

	public volatile int Failed;

	public volatile string CurrentItem;

	public volatile string LastError;

	public volatile bool IsDone;

	public volatile int ResultCode = -1;

	private Thread thread;

	public bool Success
	{
		get
		{
			if (IsDone)
			{
				return ResultCode == 0;
			}
			return false;
		}
	}

	public float Progress
	{
		get
		{
			if (LegacyCount <= 0)
			{
				if (!ScanComplete)
				{
					return 0f;
				}
				return 1f;
			}
			return Mathf.Clamp01((float)(Converted + Failed) / (float)LegacyCount);
		}
	}

	public void Start(string persistentDataPath)
	{
		if (thread != null && thread.IsAlive)
		{
			Debug.LogWarning("[SaveMigration] Already running.");
			return;
		}
		IsDone = false;
		ResultCode = -1;
		thread = new Thread(() =>
		{
			try
			{
				ResultCode = SaveMigrationCLI.Run(persistentDataPath, convert: true, ParseLine);
			}
			catch (Exception ex)
			{
				LastError = ex.Message;
				ResultCode = 2;
				Debug.LogError($"[SaveMigration] Fatal: {ex}");
			}
			finally
			{
				IsDone = true;
			}
		});
		thread.IsBackground = true;
		thread.Start();
		Debug.Log("[SaveMigration] Background migration started.");
	}

	public void StartCheckOnly(string persistentDataPath)
	{
		if (thread != null && thread.IsAlive)
		{
			Debug.LogWarning("[SaveMigration] Already running.");
			return;
		}
		IsDone = false;
		ResultCode = -1;
		thread = new Thread(() =>
		{
			try
			{
				ResultCode = SaveMigrationCLI.Run(persistentDataPath, convert: false, ParseLine);
			}
			catch (Exception ex)
			{
				LastError = ex.Message;
				ResultCode = 2;
			}
			finally
			{
				IsDone = true;
			}
		});
		thread.IsBackground = true;
		thread.Start();
	}

	private void ParseLine(string line)
	{
		if (line.StartsWith("SCAN_DONE"))
		{
			LegacyCount = ParseInt(line, "legacy");
			TotalCount = ParseInt(line, "total");
			ScanComplete = true;
		}
		else if (line.StartsWith("CONVERTING|"))
		{
			CurrentItem = line.Substring("CONVERTING|".Length);
		}
		else if (line.StartsWith("CONVERT_OK|"))
		{
			Interlocked.Increment(ref Converted);
			CurrentItem = null;
		}
		else if (line.StartsWith("CONVERT_FAIL|"))
		{
			string text = line.Substring("CONVERT_FAIL|".Length);
			int num = text.IndexOf('|');
			LastError = ((num >= 0) ? text.Substring(num + 1) : text);
			Interlocked.Increment(ref Failed);
			CurrentItem = null;
		}
	}

	private static int ParseInt(string line, string key)
	{
		string text = key + ":";
		int num = line.IndexOf(text, StringComparison.Ordinal);
		if (num < 0)
		{
			return 0;
		}
		num += text.Length;
		int num2 = line.IndexOf('|', num);
		if (!int.TryParse((num2 >= 0) ? line.Substring(num, num2 - num) : line.Substring(num), out var result))
		{
			return 0;
		}
		return result;
	}
}
