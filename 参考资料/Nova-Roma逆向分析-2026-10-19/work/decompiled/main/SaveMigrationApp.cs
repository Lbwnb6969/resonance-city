using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Assets;
using UnityEngine;

public class SaveMigrationApp : MonoBehaviour
{
	private class FileEntry
	{
		public string path;

		public string label;

		public SaveMigrationCLI.Fmt format;

		public bool converted;

		public string error;
	}

	private class WorldSave
	{
		public string path;

		public string name;

		public bool isZip;

		public SaveMigrationCLI.Fmt world;

		public SaveMigrationCLI.Fmt summary;

		public bool converted;

		public string error;
	}

	private string basePath;

	private string saveDir;

	private FileEntry settings;

	private FileEntry crossGame;

	private readonly List<WorldSave> saves = new List<WorldSave>();

	private readonly List<string> logEntries = new List<string>();

	private readonly StringBuilder logSB = new StringBuilder();

	private string logText = "";

	private Vector2 mainScroll;

	private Vector2 logScroll;

	private bool logDirty;

	private static readonly Color COL_BG = new Color32(22, 22, 34, byte.MaxValue);

	private static readonly Color COL_PANEL = new Color32(32, 33, 50, byte.MaxValue);

	private static readonly Color COL_ROW_ALT = new Color32(38, 39, 58, byte.MaxValue);

	private static readonly Color COL_HEADER = new Color32(48, 48, 74, byte.MaxValue);

	private static readonly Color COL_GREEN = new Color32(56, 142, 60, byte.MaxValue);

	private static readonly Color COL_AMBER = new Color32(239, 108, 0, byte.MaxValue);

	private static readonly Color COL_RED = new Color32(211, 47, 47, byte.MaxValue);

	private static readonly Color COL_GRAY = new Color32(90, 90, 108, byte.MaxValue);

	private static readonly Color COL_TEAL = new Color32(0, 150, 136, byte.MaxValue);

	private static readonly Color COL_BLUE = new Color32(30, 136, 229, byte.MaxValue);

	private static readonly Color COL_BTN = new Color32(62, 62, 94, byte.MaxValue);

	private static readonly Color COL_TEXT = new Color32(228, 228, 232, byte.MaxValue);

	private static readonly Color COL_DIM = new Color32(135, 135, 155, byte.MaxValue);

	private static readonly Color COL_LOG_BG = new Color32(16, 16, 24, byte.MaxValue);

	private bool stylesReady;

	private Texture2D texBg;

	private GUIStyle sTitle;

	private GUIStyle sPath;

	private GUIStyle sPanel;

	private GUIStyle sHeader;

	private GUIStyle sHeaderLbl;

	private GUIStyle sBold;

	private GUIStyle sDim;

	private GUIStyle sRow;

	private GUIStyle sRowAlt;

	private GUIStyle sBadgeOdin;

	private GUIStyle sBadgeLegacy;

	private GUIStyle sBadgeError;

	private GUIStyle sBadgeMissing;

	private GUIStyle sBtn;

	private GUIStyle sBtnConvert;

	private GUIStyle sBtnConvertAll;

	private GUIStyle sGreen;

	private GUIStyle sTeal;

	private GUIStyle sRed;

	private GUIStyle sLogBox;

	private GUIStyle sLogText;

	private void Start()
	{
		Application.targetFrameRate = 30;
		basePath = Application.persistentDataPath;
		saveDir = basePath + "/Saves";
		Scan();
	}

	private void Scan()
	{
		logEntries.Clear();
		logSB.Clear();
		logText = "";
		saves.Clear();
		settings = null;
		crossGame = null;
		Log("Save directory: " + saveDir);
		Log("Scanning...");
		string path = basePath + "/settings";
		if (File.Exists(path))
		{
			settings = new FileEntry
			{
				path = path,
				label = "Settings",
				format = SaveMigrationCLI.DetectFile(path)
			};
			Log($"  Settings: {settings.format}");
		}
		else
		{
			Log("  Settings: not found");
		}
		string path2 = saveDir + "/crossgamedata.dat";
		if (File.Exists(path2))
		{
			crossGame = new FileEntry
			{
				path = path2,
				label = "Cross-Game Data",
				format = SaveMigrationCLI.DetectFile(path2)
			};
			Log($"  Cross-game data: {crossGame.format}");
		}
		else
		{
			Log("  Cross-game data: not found");
		}
		if (Directory.Exists(saveDir))
		{
			string[] files = Directory.GetFiles(saveDir, "*.zip");
			foreach (string text in files)
			{
				WorldSave worldSave = new WorldSave
				{
					path = text,
					name = Path.GetFileNameWithoutExtension(text),
					isZip = true,
					world = SaveMigrationCLI.DetectZipEntry(text, "world"),
					summary = SaveMigrationCLI.DetectZipEntry(text, "summary")
				};
				saves.Add(worldSave);
				Log($"  {worldSave.name}.zip  world:{worldSave.world}  summary:{worldSave.summary}");
			}
			files = Directory.GetDirectories(saveDir);
			foreach (string text2 in files)
			{
				if (!text2.EndsWith(".bak", StringComparison.OrdinalIgnoreCase))
				{
					string path3 = Path.Combine(text2, "world");
					if (File.Exists(path3))
					{
						WorldSave worldSave2 = new WorldSave
						{
							path = text2,
							name = Path.GetFileName(text2),
							isZip = false,
							world = SaveMigrationCLI.DetectFile(path3),
							summary = SaveMigrationCLI.DetectFile(Path.Combine(text2, "summary"))
						};
						saves.Add(worldSave2);
						Log($"  {worldSave2.name}/  world:{worldSave2.world}  summary:{worldSave2.summary}");
					}
				}
			}
		}
		else
		{
			Log("  Save directory does not exist");
		}
		int num = CountLegacy();
		Log($"Scan complete. {saves.Count} world save(s). {num} item(s) need conversion.");
	}

	private int CountLegacy()
	{
		int num = 0;
		FileEntry fileEntry = settings;
		if (fileEntry != null && fileEntry.format == SaveMigrationCLI.Fmt.Legacy)
		{
			num++;
		}
		FileEntry fileEntry2 = crossGame;
		if (fileEntry2 != null && fileEntry2.format == SaveMigrationCLI.Fmt.Legacy)
		{
			num++;
		}
		foreach (WorldSave safe in saves)
		{
			if (safe.world == SaveMigrationCLI.Fmt.Legacy || safe.summary == SaveMigrationCLI.Fmt.Legacy)
			{
				num++;
			}
		}
		return num;
	}

	private bool NeedsWork(WorldSave s)
	{
		if (s.world != SaveMigrationCLI.Fmt.Legacy)
		{
			return s.summary == SaveMigrationCLI.Fmt.Legacy;
		}
		return true;
	}

	private void ConvertFile<T>(FileEntry entry)
	{
		if (entry != null && entry.format == SaveMigrationCLI.Fmt.Legacy)
		{
			string error = null;
			if (SaveMigrationCLI.TryConvertFile<T>(entry.path, (string msg) =>
			{
				Log("  " + msg);
				if (msg.StartsWith("CONVERT_FAIL|"))
				{
					error = msg;
				}
			}, out var _))
			{
				entry.format = SaveMigrationCLI.Fmt.Odin;
				entry.converted = true;
				Log("  " + entry.label + ": converted");
			}
			else
			{
				entry.error = error ?? "Conversion failed";
				Log("  " + entry.label + ": FAILED");
			}
		}
	}

	private void ConvertWorldSave(WorldSave ws)
	{
		string error = null;
		Action<string> emit = (string msg) =>
		{
			Log("    " + msg);
			if (msg.StartsWith("CONVERT_FAIL|"))
			{
				error = msg;
			}
		};
		if ((!ws.isZip) ? SaveMigrationCLI.TryConvertDir(ws.path, ws.world == SaveMigrationCLI.Fmt.Legacy, ws.summary == SaveMigrationCLI.Fmt.Legacy, emit, out var error2) : SaveMigrationCLI.TryConvertZip(ws.path, ws.world == SaveMigrationCLI.Fmt.Legacy, ws.summary == SaveMigrationCLI.Fmt.Legacy, emit, out error2))
		{
			ws.converted = true;
			if (ws.isZip)
			{
				ws.world = SaveMigrationCLI.DetectZipEntry(ws.path, "world");
				ws.summary = SaveMigrationCLI.DetectZipEntry(ws.path, "summary");
			}
			else
			{
				ws.world = SaveMigrationCLI.DetectFile(Path.Combine(ws.path, "world"));
				ws.summary = SaveMigrationCLI.DetectFile(Path.Combine(ws.path, "summary"));
			}
			Log("  " + ws.name + ": converted");
		}
		else
		{
			ws.error = error ?? "Conversion failed";
			Log("  " + ws.name + ": FAILED");
		}
	}

	private void ConvertAll()
	{
		Log("");
		Log("--- Converting all legacy saves ---");
		FileEntry fileEntry = settings;
		if (fileEntry != null && fileEntry.format == SaveMigrationCLI.Fmt.Legacy)
		{
			ConvertFile<Settings.SettingsSaveData>(settings);
		}
		FileEntry fileEntry2 = crossGame;
		if (fileEntry2 != null && fileEntry2.format == SaveMigrationCLI.Fmt.Legacy)
		{
			ConvertFile<CrossGameData.CrossGameSaveData>(crossGame);
		}
		foreach (WorldSave safe in saves)
		{
			if (NeedsWork(safe))
			{
				ConvertWorldSave(safe);
			}
		}
		int num = CountLegacy();
		Log((num == 0) ? "All saves converted successfully!" : $"Done. {num} item(s) could not be converted.");
	}

	private void Log(string msg)
	{
		string text = (string.IsNullOrEmpty(msg) ? "" : $"[{DateTime.Now:HH:mm:ss}] {msg}");
		logEntries.Add(text);
		logSB.AppendLine(text);
		logText = logSB.ToString();
		logDirty = true;
	}

	private void OnGUI()
	{
		InitStyles();
		GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), texBg);
		float num = Mathf.Min(920f, (float)Screen.width - 40f);
		float height = (float)Screen.height - 40f;
		GUILayout.BeginArea(new Rect(((float)Screen.width - num) / 2f, 20f, num, height));
		GUILayout.Space(4f);
		GUILayout.Label("Save Format Migration", sTitle);
		GUILayout.Label(basePath, sPath);
		GUILayout.Space(12f);
		mainScroll = GUILayout.BeginScrollView(mainScroll, false, false, GUIStyle.none, GUI.skin.verticalScrollbar, GUILayout.ExpandHeight(expand: true));
		DrawSection("STANDALONE FILES", DrawStandaloneFiles);
		GUILayout.Space(6f);
		DrawSection($"WORLD SAVES  ({saves.Count})", DrawWorldSaves);
		GUILayout.EndScrollView();
		GUILayout.Space(8f);
		GUILayout.BeginHorizontal();
		if (GUILayout.Button("Rescan", sBtn, GUILayout.Width(100f), GUILayout.Height(32f)))
		{
			Scan();
		}
		GUILayout.FlexibleSpace();
		int num2 = CountLegacy();
		GUI.enabled = num2 > 0;
		if (GUILayout.Button($"Convert All Legacy  ({num2})", sBtnConvertAll, GUILayout.Width(260f), GUILayout.Height(32f)))
		{
			ConvertAll();
		}
		GUI.enabled = true;
		GUILayout.FlexibleSpace();
		if (GUILayout.Button("Quit", sBtn, GUILayout.Width(100f), GUILayout.Height(32f)))
		{
			Application.Quit();
		}
		GUILayout.EndHorizontal();
		GUILayout.Space(8f);
		DrawLog();
		GUILayout.EndArea();
	}

	private void DrawSection(string title, Action content)
	{
		GUILayout.BeginVertical(sPanel);
		GUILayout.BeginHorizontal(sHeader);
		GUILayout.Label(title, sHeaderLbl);
		GUILayout.EndHorizontal();
		GUILayout.Space(4f);
		content();
		GUILayout.Space(4f);
		GUILayout.EndVertical();
	}

	private void DrawStandaloneFiles()
	{
		if (settings != null)
		{
			DrawFileRow(settings, () =>
			{
				ConvertFile<Settings.SettingsSaveData>(settings);
			});
		}
		if (crossGame != null)
		{
			DrawFileRow(crossGame, () =>
			{
				ConvertFile<CrossGameData.CrossGameSaveData>(crossGame);
			});
		}
		if (settings == null && crossGame == null)
		{
			GUILayout.Label("  No standalone files found.", sDim);
		}
	}

	private void DrawFileRow(FileEntry entry, Action convert)
	{
		GUILayout.BeginHorizontal(sRow, GUILayout.Height(28f));
		GUILayout.Label(entry.label, sBold, GUILayout.Width(200f));
		DrawBadge(entry.format);
		GUILayout.FlexibleSpace();
		if (entry.converted)
		{
			GUILayout.Label("Converted", sTeal);
		}
		else if (entry.error != null)
		{
			GUILayout.Label(entry.error, sRed, GUILayout.MaxWidth(300f));
		}
		else if (entry.format == SaveMigrationCLI.Fmt.Legacy)
		{
			if (GUILayout.Button("Convert", sBtnConvert, GUILayout.Width(80f)))
			{
				convert();
			}
		}
		else if (entry.format == SaveMigrationCLI.Fmt.Odin)
		{
			GUILayout.Label("Up to date", sGreen);
		}
		GUILayout.EndHorizontal();
	}

	private void DrawWorldSaves()
	{
		for (int i = 0; i < saves.Count; i++)
		{
			DrawWorldSaveRow(saves[i], i);
		}
		if (saves.Count == 0)
		{
			GUILayout.Label("  No world saves found.", sDim);
		}
	}

	private void DrawWorldSaveRow(WorldSave ws, int idx)
	{
		GUILayout.BeginVertical((idx % 2 == 0) ? sRow : sRowAlt);
		GUILayout.BeginHorizontal();
		string text = (ws.isZip ? ".zip" : "/");
		GUILayout.Label(ws.name + text, sBold);
		GUILayout.FlexibleSpace();
		if (ws.converted)
		{
			GUILayout.Label("Converted", sTeal);
		}
		else if (ws.error != null)
		{
			GUILayout.Label(ws.error, sRed, GUILayout.MaxWidth(400f));
		}
		else if (NeedsWork(ws))
		{
			if (GUILayout.Button("Convert", sBtnConvert, GUILayout.Width(80f)))
			{
				ConvertWorldSave(ws);
			}
		}
		else
		{
			GUILayout.Label("Up to date", sGreen);
		}
		GUILayout.EndHorizontal();
		GUILayout.BeginHorizontal();
		GUILayout.Space(16f);
		GUILayout.Label("world", sDim, GUILayout.Width(52f));
		DrawBadge(ws.world);
		GUILayout.Space(12f);
		GUILayout.Label("summary", sDim, GUILayout.Width(62f));
		DrawBadge(ws.summary);
		GUILayout.FlexibleSpace();
		GUILayout.EndHorizontal();
		GUILayout.EndVertical();
	}

	private void DrawBadge(SaveMigrationCLI.Fmt fmt)
	{
		switch (fmt)
		{
		case SaveMigrationCLI.Fmt.Odin:
			GUILayout.Label("ODIN", sBadgeOdin);
			break;
		case SaveMigrationCLI.Fmt.Legacy:
			GUILayout.Label("LEGACY", sBadgeLegacy);
			break;
		case SaveMigrationCLI.Fmt.Missing:
			GUILayout.Label("MISSING", sBadgeMissing);
			break;
		default:
			GUILayout.Label("ERROR", sBadgeError);
			break;
		}
	}

	private void DrawLog()
	{
		GUILayout.Label("LOG", sHeaderLbl);
		if (logDirty)
		{
			logScroll.y = float.MaxValue;
			logDirty = false;
		}
		logScroll = GUILayout.BeginScrollView(logScroll, sLogBox, GUILayout.Height(160f));
		GUILayout.Label(logText, sLogText);
		GUILayout.EndScrollView();
	}

	private void InitStyles()
	{
		if (!stylesReady)
		{
			texBg = Tex(COL_BG);
			sTitle = new GUIStyle(GUI.skin.label)
			{
				fontSize = 24,
				fontStyle = FontStyle.Bold,
				alignment = TextAnchor.MiddleCenter,
				normal = 
				{
					textColor = COL_TEXT
				}
			};
			sPath = new GUIStyle(GUI.skin.label)
			{
				fontSize = 11,
				alignment = TextAnchor.MiddleCenter,
				wordWrap = true,
				normal = 
				{
					textColor = COL_DIM
				}
			};
			sPanel = new GUIStyle
			{
				normal = 
				{
					background = Tex(COL_PANEL)
				},
				padding = new RectOffset(0, 0, 0, 0),
				margin = new RectOffset(0, 0, 0, 0)
			};
			sHeader = new GUIStyle
			{
				normal = 
				{
					background = Tex(COL_HEADER)
				},
				padding = new RectOffset(10, 10, 6, 6),
				margin = new RectOffset(0, 0, 0, 0)
			};
			sHeaderLbl = new GUIStyle(GUI.skin.label)
			{
				fontSize = 12,
				fontStyle = FontStyle.Bold,
				normal = 
				{
					textColor = COL_TEXT
				}
			};
			sBold = new GUIStyle(GUI.skin.label)
			{
				fontStyle = FontStyle.Bold,
				normal = 
				{
					textColor = COL_TEXT
				}
			};
			sDim = new GUIStyle(GUI.skin.label)
			{
				normal = 
				{
					textColor = COL_DIM
				}
			};
			sRow = new GUIStyle
			{
				padding = new RectOffset(8, 8, 4, 4),
				margin = new RectOffset(0, 0, 0, 0)
			};
			sRowAlt = new GUIStyle
			{
				normal = 
				{
					background = Tex(COL_ROW_ALT)
				},
				padding = new RectOffset(8, 8, 4, 4),
				margin = new RectOffset(0, 0, 0, 0)
			};
			sBadgeOdin = Badge(COL_GREEN);
			sBadgeLegacy = Badge(COL_AMBER);
			sBadgeError = Badge(COL_RED);
			sBadgeMissing = Badge(COL_GRAY);
			sBtn = Btn(COL_BTN, Lighter(COL_BTN));
			sBtnConvert = Btn(COL_BLUE, Lighter(COL_BLUE));
			sBtnConvertAll = Btn(COL_BLUE, Lighter(COL_BLUE));
			sBtnConvertAll.fontSize = 14;
			sGreen = new GUIStyle(GUI.skin.label)
			{
				normal = 
				{
					textColor = COL_GREEN
				}
			};
			sTeal = new GUIStyle(GUI.skin.label)
			{
				normal = 
				{
					textColor = COL_TEAL
				},
				fontStyle = FontStyle.Bold
			};
			sRed = new GUIStyle(GUI.skin.label)
			{
				normal = 
				{
					textColor = COL_RED
				}
			};
			sLogBox = new GUIStyle
			{
				normal = 
				{
					background = Tex(COL_LOG_BG)
				},
				padding = new RectOffset(8, 8, 8, 8),
				margin = new RectOffset(0, 0, 0, 0)
			};
			sLogText = new GUIStyle(GUI.skin.label)
			{
				fontSize = 11,
				wordWrap = false,
				richText = false,
				normal = 
				{
					textColor = COL_DIM
				}
			};
			stylesReady = true;
		}
	}

	private static Texture2D Tex(Color c)
	{
		Texture2D texture2D = new Texture2D(1, 1, TextureFormat.RGBA32, mipChain: false);
		texture2D.SetPixel(0, 0, c);
		texture2D.Apply();
		texture2D.hideFlags = HideFlags.DontSave;
		return texture2D;
	}

	private static Color Lighter(Color c)
	{
		return Color.Lerp(c, Color.white, 0.15f);
	}

	private static Color Darker(Color c)
	{
		return Color.Lerp(c, Color.black, 0.3f);
	}

	private static GUIStyle Badge(Color bg)
	{
		return new GUIStyle(GUI.skin.label)
		{
			normal = 
			{
				background = Tex(bg),
				textColor = Color.white
			},
			padding = new RectOffset(8, 8, 2, 2),
			margin = new RectOffset(4, 4, 3, 3),
			fontStyle = FontStyle.Bold,
			fontSize = 10,
			alignment = TextAnchor.MiddleCenter
		};
	}

	private static GUIStyle Btn(Color bg, Color hover)
	{
		return new GUIStyle(GUI.skin.button)
		{
			fontSize = 12,
			fontStyle = FontStyle.Bold,
			padding = new RectOffset(14, 14, 6, 6),
			margin = new RectOffset(4, 4, 4, 4),
			border = new RectOffset(0, 0, 0, 0),
			normal = 
			{
				background = Tex(bg),
				textColor = COL_TEXT
			},
			hover = 
			{
				background = Tex(hover),
				textColor = Color.white
			},
			active = 
			{
				background = Tex(Darker(bg)),
				textColor = Color.white
			},
			focused = 
			{
				background = Tex(bg),
				textColor = COL_TEXT
			}
		};
	}
}
