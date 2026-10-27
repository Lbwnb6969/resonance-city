using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;

public static class AqueductFlowDiagnostics
{
	public static bool Enabled = false;

	private const int MAX_BLOCKS = 20000;

	private static int blocksWritten = 0;

	private static bool sessionStarted = false;

	private static string path;

	private static readonly StringBuilder pending = new StringBuilder(4096);

	private static readonly Dictionary<string, int> dirtyCounts = new Dictionary<string, int>(16);

	private static void EnsureSession()
	{
		if (!sessionStarted)
		{
			sessionStarted = true;
			string path = Path.Combine(Application.dataPath, "..", "Logs");
			Directory.CreateDirectory(path);
			AqueductFlowDiagnostics.path = Path.Combine(path, "aqueduct_flow_diag.log");
			File.AppendAllText(AqueductFlowDiagnostics.path, "\n===== session " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " =====\n");
		}
	}

	public static void Note(string msg)
	{
		if (Enabled && blocksWritten < 20000)
		{
			EnsureSession();
			pending.Append("  note  f").Append(Time.frameCount).Append("  ")
				.Append(msg)
				.Append('\n');
			if (pending.Length > 16384)
			{
				File.AppendAllText(path, pending.ToString() + "  (flushed without a solve)\n");
				pending.Clear();
			}
		}
	}

	public static void MarkedDirty(string kind, string caller)
	{
		if (Enabled && blocksWritten < 20000)
		{
			string key = kind + ":" + (caller ?? "?");
			dirtyCounts.TryGetValue(key, out var value);
			dirtyCounts[key] = value + 1;
		}
	}

	public static void SolveBlock(string body)
	{
		if (!Enabled || blocksWritten >= 20000)
		{
			return;
		}
		EnsureSession();
		blocksWritten++;
		StringBuilder stringBuilder = new StringBuilder(2048);
		stringBuilder.Append("solve #").Append(blocksWritten).Append("  f")
			.Append(Time.frameCount)
			.Append("  t=")
			.Append(Time.realtimeSinceStartup.ToString("F2"))
			.Append("s  timeScale=")
			.Append(Time.timeScale.ToString("F2"))
			.Append('\n');
		if (dirtyCounts.Count > 0)
		{
			stringBuilder.Append("  dirty: ");
			bool flag = true;
			foreach (KeyValuePair<string, int> dirtyCount in dirtyCounts)
			{
				if (!flag)
				{
					stringBuilder.Append(", ");
				}
				stringBuilder.Append(dirtyCount.Key).Append(" x").Append(dirtyCount.Value);
				flag = false;
			}
			stringBuilder.Append('\n');
			dirtyCounts.Clear();
		}
		if (pending.Length > 0)
		{
			stringBuilder.Append(pending);
			pending.Clear();
		}
		stringBuilder.Append(body);
		if (blocksWritten == 20000)
		{
			stringBuilder.Append("===== diagnostics cap reached - logging stopped =====\n");
		}
		File.AppendAllText(path, stringBuilder.ToString());
	}
}
