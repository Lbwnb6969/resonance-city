using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Code.UI;

public class SaveLoadUI : MonoBehaviour
{
	protected class LoadSaveData
	{
		public BuiltInSave builtInSave;

		public string path;

		public Guid guid;

		public DateTime modifiedTime;

		public LoadSave.WorldSummaryData worldSummaryData;

		public Texture2D coverTexture;

		public bool hasLoadedTexture;
	}

	private struct PNGLoad
	{
		public LoadSaveData data;

		public GroupOptionUI component;
	}

	protected class Group
	{
		public Guid guid;

		public DateTime latestTime = DateTime.MinValue;

		public ArrayExt<LoadSaveData> data = new ArrayExt<LoadSaveData>(32);

		public int maxItemsDisplayed;

		public bool isScrollViewDirty;

		public GroupOptionUI groupUI;

		public ArrayExt<SaveOptionUI> optionsUI = new ArrayExt<SaveOptionUI>(32);
	}

	public static SaveLoadUI inst;

	[SerializeField]
	private Canvas[] canvas;

	[SerializeField]
	private GraphicRaycaster[] gRaycaster;

	[SerializeField]
	private ScrollRect scrollRect;

	[SerializeField]
	private RectTransform scrollRectT;

	[SerializeField]
	private RectTransform contentRectT;

	[SerializeField]
	private TextMeshProUGUI titleTMP;

	[SerializeField]
	private Button exitBtn;

	[SerializeField]
	public Confirmation loadConfirmation;

	[SerializeField]
	public Confirmation saveConfirmation;

	[SerializeField]
	public Confirmation deleteConfirmation;

	[SerializeField]
	private GroupOptionUI groupPrefab;

	[SerializeField]
	private SaveOptionUI itemPrefab;

	private int groupCount;

	private ArrayExt<GroupOptionUI> groupPool = new ArrayExt<GroupOptionUI>(32);

	private int saveCount;

	private ArrayExt<SaveOptionUI> savePool = new ArrayExt<SaveOptionUI>(32);

	private bool isVisible;

	private readonly string[] SaveIgnoreList = new string[3] { "autosave", "upload", "return" };

	private readonly string[] LoadIgnoreList = new string[2] { "upload", "return" };

	private int column;

	private int row;

	private int pageOptionCount;

	private bool isDirty;

	private bool isOpenThisFrame;

	private bool isGroupExpanded;

	private SerializableGuid expandedGroupGuid;

	public int DisplayMode = -1;

	public const int SAVE_MODE = 1;

	public const int LOAD_MODE = 2;

	private ArrayExt<LoadSaveData> loadSaveData = new ArrayExt<LoadSaveData>(128);

	private ArrayExt<Guid> groupOrder = new ArrayExt<Guid>(32);

	private float animLoadingAngle;

	public float animLoadingSpeed = 1f;

	private static float itemSizeY = 15f;

	private ArrayExt<PNGLoad> deferredPNGLoad = new ArrayExt<PNGLoad>(32);

	protected Dictionary<Guid, Group> groups = new Dictionary<Guid, Group>(32);

	private int frameCount = 10;

	private int frame;

	public bool BuiltInSaves;

	public bool MapSaves;

	public bool IsVisible()
	{
		return isVisible;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		exitBtn.onClick.AddListener(() =>
		{
			GameState.inst.mainMenuMode.OnClickedClose();
			SfxSystem.PlayUiCancel();
		});
		scrollRect.verticalScrollbar.onValueChanged.AddListener(CalculatePageOptionCount);
		itemSizeY = itemPrefab.GetComponent<RectTransform>().rect.size.y;
	}

	public void SetVisibility(bool v, int mode = 2)
	{
		if (v && !isVisible)
		{
			isOpenThisFrame = true;
			for (int i = 0; i < this.loadSaveData.Count; i++)
			{
				if (this.loadSaveData.data[i].coverTexture != null)
				{
					UnityEngine.Object.Destroy(this.loadSaveData.data[i].coverTexture);
					this.loadSaveData.data[i].coverTexture = null;
				}
			}
			this.loadSaveData.ClearFast();
			groupOrder.ClearFast();
			foreach (KeyValuePair<Guid, Group> group in groups)
			{
				group.Value.data.ClearFast();
				group.Value.optionsUI.ClearFast();
				group.Value.groupUI = null;
			}
			if (BuiltInSaves)
			{
				BuiltInSave[] saves = BuiltInSaveManager.inst.saves;
				foreach (BuiltInSave builtInSave in saves)
				{
					LoadSaveData loadSaveData = new LoadSaveData();
					loadSaveData.worldSummaryData = LoadSave.LoadWorldSummaryData(builtInSave);
					loadSaveData.builtInSave = builtInSave;
					loadSaveData.guid = loadSaveData.worldSummaryData.guid;
					Texture2D texture2D = new Texture2D(2, 2);
					texture2D.name = "SaveCoverLowRes";
					texture2D.LoadImage(builtInSave.cover_low_res.bytes);
					loadSaveData.coverTexture = texture2D;
					loadSaveData.hasLoadedTexture = true;
					loadSaveData.modifiedTime = DateTime.MinValue;
					Group obj = null;
					if (!groups.ContainsKey(loadSaveData.guid))
					{
						obj = new Group();
						obj.guid = loadSaveData.guid;
						groups.Add(loadSaveData.guid, obj);
					}
					else
					{
						obj = groups[loadSaveData.guid];
					}
					if (obj.latestTime < loadSaveData.modifiedTime)
					{
						obj.latestTime = loadSaveData.modifiedTime;
					}
					obj.data.Add(loadSaveData);
					for (int k = 0; k < this.loadSaveData.Count; k++)
					{
						if (this.loadSaveData.data[k].guid == loadSaveData.guid)
						{
							this.loadSaveData.RemoveAt(k--);
						}
					}
					this.loadSaveData.Add(loadSaveData);
				}
			}
			else
			{
				string[] array = (MapSaves ? LoadSave.GetMapSavePaths() : LoadSave.GetSavePaths());
				for (int l = 0; l < array.Length; l++)
				{
					string fileName = Path.GetFileName(array[l]);
					string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(array[l]);
					bool flag = true;
					string[] array2 = ((mode == 1) ? SaveIgnoreList : LoadIgnoreList);
					for (int m = 0; m < array2.Length; m++)
					{
						if (fileName.StartsWith(array2[m], StringComparison.OrdinalIgnoreCase) || fileNameWithoutExtension.StartsWith(array2[m], StringComparison.OrdinalIgnoreCase))
						{
							flag = false;
							break;
						}
					}
					if (flag && LoadSave.TryValidateSavePreview(array[l], out var summary))
					{
						ref string guid = ref summary.guid.guid;
						if (guid == null)
						{
							guid = "00000000-0000-0000-0000-000000000000";
						}
						LoadSaveData loadSaveData2 = new LoadSaveData();
						loadSaveData2.path = array[l];
						loadSaveData2.guid = summary.guid;
						loadSaveData2.worldSummaryData = summary;
						loadSaveData2.modifiedTime = LoadSave.GetSaveLastWriteTime(array[l]);
						Group obj2 = null;
						if (!groups.ContainsKey(loadSaveData2.guid))
						{
							obj2 = new Group();
							obj2.guid = loadSaveData2.guid;
							groups.Add(loadSaveData2.guid, obj2);
						}
						else
						{
							obj2 = groups[loadSaveData2.guid];
						}
						if (obj2.latestTime < loadSaveData2.modifiedTime)
						{
							obj2.latestTime = loadSaveData2.modifiedTime;
						}
						obj2.data.Add(loadSaveData2);
						this.loadSaveData.Add(loadSaveData2);
					}
				}
			}
			this.loadSaveData.Sort(Comparator);
			for (int n = 0; n < this.loadSaveData.Count; n++)
			{
				if (!groupOrder.Contains(this.loadSaveData.data[n].worldSummaryData.guid))
				{
					groupOrder.Add(this.loadSaveData.data[n].worldSummaryData.guid);
				}
			}
			foreach (KeyValuePair<Guid, Group> group2 in groups)
			{
				group2.Value.data.Sort(Comparator);
			}
			if (mode == 1 && !groups.ContainsKey(World.inst.guid))
			{
				Group obj3 = new Group();
				obj3.guid = World.inst.guid;
				obj3.latestTime = DateTime.Now;
				groups.Add(obj3.guid, obj3);
			}
			SetDisplayMode(mode);
		}
		if (!v && isVisible)
		{
			loadConfirmation.Reset();
			saveConfirmation.Reset();
			deferredPNGLoad.ClearFast();
			for (int num = 0; num < this.loadSaveData.Count; num++)
			{
				if (this.loadSaveData.data[num].coverTexture != null)
				{
					UnityEngine.Object.Destroy(this.loadSaveData.data[num].coverTexture);
					this.loadSaveData.data[num].coverTexture = null;
				}
			}
		}
		for (int num2 = 0; num2 < canvas.Length; num2++)
		{
			Util.SetEnabled(canvas[num2], v);
		}
		for (int num3 = 0; num3 < gRaycaster.Length; num3++)
		{
			gRaycaster[num3].enabled = v;
		}
		isVisible = v;
	}

	private int Comparator(LoadSaveData curr, LoadSaveData target)
	{
		if (curr.modifiedTime == target.modifiedTime)
		{
			return 0;
		}
		if (curr.modifiedTime < target.modifiedTime)
		{
			return 1;
		}
		return -1;
	}

	public void SetDisplayMode(int mode)
	{
		DisplayMode = mode;
		groupCount = 0;
		saveCount = 0;
		switch (mode)
		{
		case 2:
		{
			if (BuiltInSaves)
			{
				titleTMP.text = LocalizationManager.GetTranslation("mainmenuui_button_developersaves");
			}
			else if (MapSaves)
			{
				titleTMP.text = LocalizationManager.GetTranslation("saveloadui_title_loadmap");
			}
			else
			{
				titleTMP.text = ScriptLocalization.Load;
			}
			for (int l = 0; l < groupOrder.Count; l++)
			{
				Group obj3 = groups[groupOrder.data[l]];
				GroupOptionUI groupOption3 = GetGroupOption();
				SetupGroupOption(obj3, groupOption3);
				groupOption3.itemContainer.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, itemSizeY * (float)obj3.data.Count);
				int num2 = CalculateSaveDisplay(groupOption3);
				for (int m = 0; m < obj3.data.Count && m < num2; m++)
				{
					SetupSaveOption(obj3, GetSaveOption(groupOption3.itemContainer), obj3.data.data[m]);
				}
				obj3.maxItemsDisplayed = num2;
				obj3.groupUI.toggleGroup.SetAllTogglesOff();
				obj3.optionsUI.data[0].toggle.isOn = true;
			}
			break;
		}
		case 1:
		{
			titleTMP.text = ScriptLocalization.Save;
			Guid guid = World.inst.guid;
			Group obj = groups[guid];
			GroupOptionUI groupOption = GetGroupOption();
			SetupGroupOption(obj, groupOption);
			SaveOptionUI saveOption = GetSaveOption(groupOption.itemContainer);
			SetupSaveOption(obj, saveOption, null);
			groupOption.itemContainer.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, itemSizeY * (float)(obj.data.Count + 1));
			int num = CalculateSaveDisplay(groupOption);
			for (int i = 0; i < obj.data.Count && i < num; i++)
			{
				SetupSaveOption(obj, GetSaveOption(groupOption.itemContainer), obj.data.data[i]);
			}
			obj.maxItemsDisplayed = num;
			obj.groupUI.toggleGroup.SetAllTogglesOff();
			saveOption.toggle.isOn = true;
			for (int j = 0; j < groupOrder.Count; j++)
			{
				Guid guid2 = groupOrder.data[j];
				if (!(guid2 == guid))
				{
					Group obj2 = groups[guid2];
					GroupOptionUI groupOption2 = GetGroupOption();
					SetupGroupOption(obj2, groupOption2, isLocked: true);
					groupOption2.itemContainer.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, itemSizeY * (float)obj2.data.Count);
					num = CalculateSaveDisplay(groupOption2);
					for (int k = 0; k < obj2.data.Count && k < num; k++)
					{
						SetupSaveOption(obj2, GetSaveOption(groupOption2.itemContainer), obj2.data.data[k]);
					}
					obj2.maxItemsDisplayed = num;
					obj2.groupUI.toggleGroup.SetAllTogglesOff();
					obj2.optionsUI.data[0].toggle.isOn = true;
				}
			}
			break;
		}
		}
		for (int num3 = groupPool.Count - 1; num3 >= groupCount; num3--)
		{
			groupPool.data[num3].gameObject.SetActive(value: false);
		}
		for (int num4 = savePool.Count - 1; num4 >= saveCount; num4--)
		{
			savePool.data[num4].gameObject.SetActive(value: false);
		}
	}

	private void Update()
	{
		if (!isVisible)
		{
			return;
		}
		if (deferredPNGLoad.Count > 0)
		{
			animLoadingAngle += Time.unscaledDeltaTime * animLoadingSpeed;
			Quaternion rotation = Quaternion.Euler(0f, 0f, 0f - Mathf.Repeat(animLoadingAngle, 360f));
			for (int i = 0; i < deferredPNGLoad.Count; i++)
			{
				deferredPNGLoad.data[i].component.loadingRaw.rectTransform.rotation = rotation;
			}
		}
		frame++;
		if (frame % frameCount == 0)
		{
			if (deferredPNGLoad.Count > 0)
			{
				PNGLoad pNGLoad = deferredPNGLoad.PopFirst();
				pNGLoad.component.pictureRaw.texture = (pNGLoad.data.coverTexture = LoadSave.LoadTextureFromSave(pNGLoad.data.path, "cover_low_res"));
				pNGLoad.component.pictureRaw.enabled = true;
				pNGLoad.component.loadingRaw.enabled = false;
			}
			foreach (KeyValuePair<Guid, Group> group in groups)
			{
				if (!group.Value.isScrollViewDirty)
				{
					continue;
				}
				group.Value.isScrollViewDirty = false;
				int num = CalculateSaveDisplay(group.Value.groupUI);
				if (num > group.Value.maxItemsDisplayed)
				{
					for (int j = group.Value.maxItemsDisplayed; j < group.Value.data.Count && j < num; j++)
					{
						SetupSaveOption(group.Value, GetSaveOption(group.Value.groupUI.itemContainer), group.Value.data.data[j]);
					}
					group.Value.maxItemsDisplayed = num;
				}
			}
		}
		isOpenThisFrame = false;
	}

	private int CalculateSaveDisplay(GroupOptionUI groupOptionUI)
	{
		float num = 1f - groupOptionUI.itemScrollRect.verticalNormalizedPosition;
		float y = groupOptionUI.itemScrollRectT.rect.size.y;
		float num2 = num * groupOptionUI.itemContainer.sizeDelta.y + y;
		return Mathff.Max(1, Mathf.CeilToInt(num2 / y)) * Mathf.CeilToInt(y / itemSizeY);
	}

	public void CalculatePageOptionCount(float normal)
	{
		isDirty = true;
	}

	private GroupOptionUI GetGroupOption()
	{
		while (groupPool.Count <= groupCount)
		{
			groupPool.Add(UnityEngine.Object.Instantiate(groupPrefab, contentRectT, worldPositionStays: false));
		}
		GroupOptionUI obj = groupPool.data[groupCount++];
		obj.gameObject.SetActive(value: true);
		return obj;
	}

	private SaveOptionUI GetSaveOption(RectTransform parent)
	{
		while (savePool.Count <= saveCount)
		{
			savePool.Add(UnityEngine.Object.Instantiate(itemPrefab, parent, worldPositionStays: false));
		}
		SaveOptionUI obj = savePool.data[saveCount++];
		obj.rectT.SetParent(parent, worldPositionStays: false);
		obj.rectT.SetAsLastSibling();
		obj.gameObject.SetActive(value: true);
		return obj;
	}

	private void SetupSaveOption(Group currGroup, SaveOptionUI optionUI, LoadSaveData data)
	{
		currGroup.optionsUI.Add(optionUI);
		TextMeshProUGUI textMeshProUGUI = optionUI.titleTMP;
		string text;
		if (data == null)
		{
			text = ScriptLocalization.EmptySave;
		}
		else
		{
			text = (MapSaves ? data.worldSummaryData.Date.ToLocalTime().ToShortDateString() : string.Format(ScriptLocalization.SaveLoadYear, data.worldSummaryData.Year));
		}
		textMeshProUGUI.text = text;
		optionUI.toggle.onValueChanged.RemoveAllListeners();
		optionUI.toggle.onValueChanged.AddListener((bool isActive) =>
		{
			if (isActive)
			{
				FocusSaveOption(currGroup, optionUI, data);
			}
		});
		optionUI.toggle.group = currGroup.groupUI.toggleGroup;
	}

	private void SetupGroupOption(Group currGroup, GroupOptionUI groupOptionUI, bool isLocked = false)
	{
		currGroup.groupUI = groupOptionUI;
		groupOptionUI.overlay.enabled = isLocked;
		groupOptionUI.hoverOverlay.SetActive(value: true);
		groupOptionUI.trashBtn.gameObject.SetActive(!isLocked);
		groupOptionUI.confirmBtn.gameObject.SetActive(!isLocked);
		groupOptionUI.itemScrollRect.onValueChanged.RemoveAllListeners();
		groupOptionUI.itemScrollRect.onValueChanged.AddListener((Vector2 norm) =>
		{
			currGroup.isScrollViewDirty = true;
		});
	}

	private void FocusSaveOption(Group currGroup, SaveOptionUI save, LoadSaveData data)
	{
		bool isEmptySave = DisplayMode == 1 && data == null;
		bool flag = false;
		string text = (isEmptySave ? "" : Path.GetFileName(data.path));
		if (!isEmptySave && data.builtInSave == null)
		{
			flag = text.Contains("autosave");
		}
		GroupOptionUI groupUI = currGroup.groupUI;
		groupUI.titleTMP.text = (isEmptySave ? ScriptLocalization.EmptySave : Util.TryEllipse(data.worldSummaryData.CityName, 20));
		groupUI.citizenTMP.text = ((isEmptySave || MapSaves) ? "" : string.Format(ScriptLocalization.SaveLoadCitizens, data.worldSummaryData.Population));
		groupUI.dateTMP.text = (isEmptySave ? "" : (data.worldSummaryData.Date.ToLocalTime().ToShortTimeString() + ", " + data.worldSummaryData.Date.ToLocalTime().ToShortDateString()));
		if (!isEmptySave && data.builtInSave != null)
		{
			groupUI.dateTMP.text = "";
		}
		groupUI.autoSaveContainer.SetActive(!isEmptySave & flag);
		groupUI.pictureRaw.enabled = !isEmptySave;
		if (!isEmptySave)
		{
			if (!data.hasLoadedTexture)
			{
				if (isOpenThisFrame)
				{
					deferredPNGLoad.Add(new PNGLoad
					{
						data = data,
						component = groupUI
					});
					groupUI.pictureRaw.enabled = false;
					groupUI.loadingRaw.enabled = true;
				}
				else
				{
					for (int i = 0; i < deferredPNGLoad.Count; i++)
					{
						if (deferredPNGLoad.data[i].data == data)
						{
							deferredPNGLoad.RemoveAt(i);
							break;
						}
					}
					groupUI.pictureRaw.texture = (data.coverTexture = LoadSave.LoadTextureFromSave(data.path, "cover_low_res"));
					groupUI.pictureRaw.enabled = true;
					groupUI.loadingRaw.enabled = false;
				}
				data.hasLoadedTexture = true;
			}
			else
			{
				groupUI.pictureRaw.texture = data.coverTexture;
			}
			groupUI.infoBtn.onClick.RemoveAllListeners();
			groupUI.infoBtn.onClick.AddListener(() =>
			{
				try
				{
					string fullPath = Path.GetFullPath(data.path);
					if (Application.platform == RuntimePlatform.WindowsPlayer || Application.platform == RuntimePlatform.WindowsEditor)
					{
						string arguments = "/select,\"" + fullPath + "\"";
						Process.Start(new ProcessStartInfo("explorer.exe", arguments)
						{
							UseShellExecute = true
						});
					}
					else if (Application.platform == RuntimePlatform.OSXPlayer || Application.platform == RuntimePlatform.OSXEditor)
					{
						string arguments2 = "-R \"" + fullPath + "\"";
						Process.Start(new ProcessStartInfo("open", arguments2)
						{
							UseShellExecute = false
						});
					}
					else if (Application.platform == RuntimePlatform.LinuxPlayer || Application.platform == RuntimePlatform.LinuxEditor)
					{
						Process.Start("xdg-open", fullPath);
					}
					else
					{
						UnityEngine.Debug.Log($"Unknown platform - {Application.platform}");
					}
				}
				catch (Exception ex)
				{
					UnityEngine.Debug.Log(ex.Message + $" : Error attempting to open folder using {Application.platform}");
				}
			});
		}
		groupUI.confirmBtn.onClick.RemoveAllListeners();
		if (DisplayMode == 2)
		{
			groupUI.confirmTMP.text = ScriptLocalization.Load;
		}
		else if (DisplayMode == 1)
		{
			groupUI.confirmTMP.text = (isEmptySave ? ScriptLocalization.Save : ScriptLocalization.Overwrite);
		}
		groupUI.confirmBtn.onClick.AddListener(() =>
		{
			if (DisplayMode == 2)
			{
				if (MapSaves)
				{
					LoadSave.currentMapName = data.worldSummaryData.CityName;
					LoadSave.loadIntoMapSelect = true;
					LoadSave.LoadAtPath(data.path, "world");
				}
				else if (GameState.inst.mainMenuMode.PreviousState == MainMenuMode.State.PauseMenu)
				{
					loadConfirmation.ShowConfirmation(() =>
					{
						if (data.builtInSave != null)
						{
							LoadSave.Load(data.builtInSave);
						}
						else
						{
							LoadSave.Load(LoadSave.GetSaveIdentifier(data.path));
						}
					}, () =>
					{
						SfxSystem.PlayUiCancel();
					});
				}
				else if (data.builtInSave != null)
				{
					LoadSave.Load(data.builtInSave);
				}
				else
				{
					LoadSave.Load(LoadSave.GetSaveIdentifier(data.path));
				}
			}
			else if (DisplayMode == 1)
			{
				if (isEmptySave)
				{
					LoadSave.Save();
					GameState.inst.mainMenuMode.OnClickedReturnToGame();
				}
				else
				{
					saveConfirmation.ShowConfirmation(() =>
					{
						LoadSave.Save(data.path);
						GameState.inst.mainMenuMode.OnClickedReturnToGame();
					}, () =>
					{
						SfxSystem.PlayUiCancel();
					});
				}
			}
		});
		groupUI.trashBtn.onClick.RemoveAllListeners();
		if (!isEmptySave)
		{
			groupUI.trashBtn.gameObject.SetActive(value: true);
			groupUI.trashBtn.onClick.AddListener(() =>
			{
				deleteConfirmation.ShowConfirmation(() =>
				{
					SfxSystem.PlayUiSelect();
					saveCount--;
					LoadSave.Delete(data.path);
					int num = currGroup.data.IndexOf(data);
					currGroup.data.RemoveAt(num);
					currGroup.optionsUI.RemoveAt(num);
					if (currGroup.data.Count == 0)
					{
						currGroup.groupUI.gameObject.SetActive(value: false);
						groups.Remove(currGroup.guid);
					}
					else
					{
						num = Mathff.Clamp(num, 0, currGroup.data.Count - 1);
						currGroup.optionsUI.data[num].toggle.isOn = true;
					}
					save.rectT.gameObject.SetActive(value: false);
				}, () =>
				{
					SfxSystem.PlayUiCancel();
				});
			});
		}
		else
		{
			groupUI.trashBtn.gameObject.SetActive(value: false);
		}
		if (BuiltInSaves)
		{
			groupUI.trashBtn.gameObject.SetActive(value: false);
		}
	}

	public static void FillOptionData(string path, ref SaveLoadOption option)
	{
		LoadSave.WorldSummaryData worldSummaryData = LoadSave.LoadWorldSummaryData(path);
		option.SetTitle(worldSummaryData.CityName);
		option.SetYear(worldSummaryData.Year);
		option.SetPopulation(worldSummaryData.Population);
		option.SetDate(worldSummaryData.Date.ToLocalTime());
		option.SetIsAutosave(path.Contains("autosave"));
		option.SetPath(path);
		option.SetCode(worldSummaryData.ShareCode);
	}

	private void FillOptionData(SaveLoadOption option, LoadSaveData data)
	{
		option.SetTitle(data.worldSummaryData.CityName);
		option.SetYear(data.worldSummaryData.Year);
		option.SetPopulation(data.worldSummaryData.Population);
		option.SetDate(data.worldSummaryData.Date.ToLocalTime());
		option.SetIsAutosave(data.path.Contains("autosave"));
		option.SetPath(data.path);
		option.SetCode(data.worldSummaryData.ShareCode);
	}

	public void OnEscapePressed()
	{
		if (isVisible)
		{
			if (loadConfirmation.gameObject.activeSelf)
			{
				loadConfirmation.Reset();
			}
			else if (saveConfirmation.gameObject.activeSelf)
			{
				saveConfirmation.Reset();
			}
			else if (deleteConfirmation.gameObject.activeSelf)
			{
				deleteConfirmation.Reset();
			}
			else
			{
				GameState.inst.mainMenuMode.OnClickedClose();
			}
		}
	}
}
