using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Assets.Code.UI;
using Crosstales.FB;
using Steamworks;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class WorkshopUI : MonoBehaviour
{
	[Serializable]
	public class WorkshopMetadata
	{
		public int version = 1;

		public WorkshopMetadata(int version)
		{
			this.version = version;
		}
	}

	public TMP_InputField title;

	public TMP_InputField description;

	public TMP_InputField workshopItemPath;

	public TMP_InputField tags;

	public TMP_InputField changeNotes;

	public TMP_Dropdown visibiltyType;

	public Button newItemButton;

	public Button openFileBrowser;

	public Button uploadItemToWorkshop;

	public Button updateItemInWorkshop;

	public Button testCompile;

	public Button exit;

	public PublishedFileId_t currentEdit;

	private CallResult<CreateItemResult_t> OnCreateItemResultCallResult;

	private CallResult<SubmitItemUpdateResult_t> OnSubmitItemResultCallResult;

	private CallResult<SteamUGCQueryCompleted_t> OnQueryCompletedResult;

	public ScrollRect scrollRect;

	public Button imgBG;

	public RawImage img;

	public GameObject uploadingDialog;

	public Transform contentContainer;

	public WorkshopItem workShopItemPrefab;

	public WorkshopConsole console;

	public Confirmation publicConfirmation;

	public Confirmation deleteConfirmation;

	public static WorkshopUI inst;

	private string imagePath = "";

	private string[] extensionsWhitelist = new string[11]
	{
		".cs", ".png", ".jpg", ".jpeg", ".fbx", ".obj", ".txt", ".py", ".json", ".xml",
		""
	};

	public string filterModPath;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		openFileBrowser.onClick.AddListener(() =>
		{
			string directory = Path.Combine(Application.dataPath, "mods");
			if (Directory.Exists(workshopItemPath.text))
			{
				directory = workshopItemPath.text;
			}
			string text = FileBrowser.OpenSingleFolder("Locate Workshop Item Data Folder", directory);
			if (!string.IsNullOrEmpty(text))
			{
				workshopItemPath.text = text;
			}
		});
		uploadItemToWorkshop.onClick.AddListener(() =>
		{
			ConfirmPublic(OnUploadItem);
		});
		updateItemInWorkshop.onClick.AddListener(() =>
		{
			ConfirmPublic(OnUpdateItem);
		});
		newItemButton.onClick.AddListener(ClearForNew);
		testCompile.onClick.AddListener(TestCompile);
		exit.onClick.AddListener(() =>
		{
			Application.Quit();
		});
		OnCreateItemResultCallResult = CallResult<CreateItemResult_t>.Create(OnCreateItemResult);
		OnSubmitItemResultCallResult = CallResult<SubmitItemUpdateResult_t>.Create(OnSubmitItemResult);
		OnQueryCompletedResult = CallResult<SteamUGCQueryCompleted_t>.Create(OnQueryCompleted);
		imgBG.onClick.AddListener(OnImageSelect);
		ClearForNew();
		uploadingDialog.SetActive(value: false);
		PopulateWorkshopItems();
	}

	public void ItemClicked(WorkshopItem item)
	{
		foreach (Transform item2 in contentContainer)
		{
			WorkshopItem component = item2.GetComponent<WorkshopItem>();
			if (component != null)
			{
				component.SetHighlighted(highlighted: false);
			}
		}
		if (item == null)
		{
			return;
		}
		currentEdit = item.fileId;
		title.text = item.title.text;
		description.text = item.description.text;
		if (item.tags.Length != 0)
		{
			tags.text = item.tags.Aggregate((string s, string s1) => s + ", " + s1);
		}
		workshopItemPath.text = LoadModSourcePath(item.fileId);
		changeNotes.text = "";
		if (item.image.texture != null)
		{
			img.texture = item.image.texture;
			img.GetComponent<AspectRatioFitter>().aspectRatio = (float)img.texture.width / (float)img.texture.height;
		}
		switch (item.visibility)
		{
		case ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityPrivate:
			visibiltyType.value = 0;
			break;
		case ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityFriendsOnly:
			visibiltyType.value = 1;
			break;
		case ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityPublic:
			visibiltyType.value = 2;
			break;
		}
		imagePath = "";
		item.SetHighlighted(highlighted: true);
	}

	private void OnUnsub(WorkshopItem item)
	{
		deleteConfirmation.ShowConfirmation(() =>
		{
			SteamUGC.DeleteItem(item.fileId);
			PopulateWorkshopItems();
		}, () =>
		{
		});
	}

	private void OnGoToItem(WorkshopItem item)
	{
		OpenURLForFileID(item.fileId);
	}

	private void ClearForNew()
	{
		title.text = "";
		description.text = "";
		workshopItemPath.text = "";
		tags.text = "";
		img.texture = null;
		currentEdit = PublishedFileId_t.Invalid;
		visibiltyType.value = 0;
		changeNotes.text = "";
		ItemClicked(null);
	}

	private void Update()
	{
		uploadItemToWorkshop.gameObject.SetActive(currentEdit == PublishedFileId_t.Invalid);
		updateItemInWorkshop.gameObject.SetActive(currentEdit != PublishedFileId_t.Invalid);
		bool flag = !string.IsNullOrEmpty(title.text) && !string.IsNullOrEmpty(description.text);
		if (currentEdit == PublishedFileId_t.Invalid)
		{
			flag &= !string.IsNullOrEmpty(imagePath);
		}
		uploadItemToWorkshop.interactable = flag;
		updateItemInWorkshop.interactable = flag;
	}

	private void OnImageSelect()
	{
		ExtensionFilter extensionFilter = new ExtensionFilter("Images (png, jpg, jpeg)", "png", "jpg", "jpeg");
		imagePath = FileBrowser.OpenSingleFile("Image path", null, extensionFilter);
		if (File.Exists(imagePath))
		{
			if (new FileInfo(imagePath).Length < 1000000)
			{
				Texture2D texture = Util.LoadPNG(imagePath);
				img.texture = texture;
				img.GetComponent<AspectRatioFitter>().aspectRatio = (float)img.texture.width / (float)img.texture.height;
			}
			else
			{
				console.Writeline("<color=red>Image preview files must be less than 1MB</color>");
			}
		}
	}

	private void OnUploadItem()
	{
		if (ValidateData())
		{
			uploadingDialog.SetActive(value: true);
			SteamAPICall_t hAPICall = SteamUGC.CreateItem((AppId_t)569480u, EWorkshopFileType.k_EWorkshopFileTypeFirst);
			OnCreateItemResultCallResult.Set(hAPICall);
			SteamAPI.RunCallbacks();
		}
	}

	private void OnUpdateItem()
	{
		if (ValidateData())
		{
			uploadingDialog.SetActive(value: true);
			RunItemUpdate();
		}
	}

	private void ConfirmPublic(UnityAction action)
	{
		if (visibiltyType.value == 2)
		{
			publicConfirmation.ShowConfirmation(() =>
			{
				action();
			}, () =>
			{
			});
		}
		else
		{
			action();
		}
	}

	private void OnCreateItemResult(CreateItemResult_t result, bool ioFailure)
	{
		if (result.m_eResult != EResult.k_EResultOK)
		{
			Debug.Log($"<color=red>Error result on creating item: {result.m_eResult}. Aborting.</color>");
			SteamUGC.DeleteItem(result.m_nPublishedFileId);
			uploadingDialog.SetActive(value: false);
		}
		else
		{
			currentEdit = result.m_nPublishedFileId;
			RunItemUpdate();
		}
	}

	public bool ValidateData()
	{
		if (workshopItemPath.text != null)
		{
			if (!Directory.Exists(workshopItemPath.text))
			{
				console.Writeline("Item path doesn't exist.");
				return false;
			}
			CreateFilterMod(workshopItemPath.text);
			if (!ValidateWorkshopMod(filterModPath))
			{
				return false;
			}
			return true;
		}
		return true;
	}

	public void CreateFilterMod(string modPath)
	{
		GC.Collect();
		GC.WaitForPendingFinalizers();
		filterModPath = Path.GetFullPath(Path.Combine(Application.persistentDataPath, "workshop/tmp")).Replace("\\", "/");
		if (Directory.Exists(filterModPath))
		{
			Directory.Delete(filterModPath, recursive: true);
		}
		Directory.CreateDirectory(filterModPath);
		string text = "";
		string fullPath = Path.GetFullPath(modPath);
		string[] files = Directory.GetFiles(fullPath, "*", SearchOption.AllDirectories);
		foreach (string text2 in files)
		{
			string text3 = text2.Substring(fullPath.Length + 1);
			if (extensionsWhitelist.Contains(Path.GetExtension(text2)))
			{
				string text4 = Path.Combine(filterModPath, text3);
				string directoryName = Path.GetDirectoryName(text4);
				if (!Directory.Exists(directoryName))
				{
					Directory.CreateDirectory(directoryName);
				}
				File.Copy(text2, text4, overwrite: true);
			}
			else
			{
				text = text + text3 + "\n";
			}
		}
		console.Writeline("Files filtered from mod folder:\n" + text);
	}

	private void RunItemUpdate()
	{
		UGCUpdateHandle_t uGCUpdateHandle_t = SteamUGC.StartItemUpdate((AppId_t)569480u, currentEdit);
		SteamUGC.SetItemTitle(uGCUpdateHandle_t, title.text);
		SteamUGC.SetItemDescription(uGCUpdateHandle_t, description.text);
		SteamUGC.SetItemVisibility(uGCUpdateHandle_t, visibiltyType.value switch
		{
			0 => ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityPrivate, 
			1 => ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityFriendsOnly, 
			2 => ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityPublic, 
			_ => ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityPrivate, 
		});
		string pchMetaData = JsonUtility.ToJson(new WorkshopMetadata(KCModHelper.modVersion));
		SteamUGC.SetItemMetadata(uGCUpdateHandle_t, pchMetaData);
		IEnumerable<string> source = (from s in tags.text.Split(new char[1] { ',' }, StringSplitOptions.RemoveEmptyEntries)
			select s.Trim()).Concat(new string[2] { "kcmod", "v2" });
		SteamUGC.SetItemTags(uGCUpdateHandle_t, source.ToArray());
		if (!string.IsNullOrEmpty(filterModPath))
		{
			SteamUGC.SetItemContent(uGCUpdateHandle_t, filterModPath);
		}
		if (!string.IsNullOrEmpty(imagePath))
		{
			SteamUGC.SetItemPreview(uGCUpdateHandle_t, imagePath);
		}
		string text = changeNotes.text;
		if (text == "")
		{
			text = "Upload from workshop UI";
		}
		SteamAPICall_t hAPICall = SteamUGC.SubmitItemUpdate(uGCUpdateHandle_t, text);
		OnSubmitItemResultCallResult.Set(hAPICall);
		SteamAPI.RunCallbacks();
	}

	private void OnSubmitItemResult(SubmitItemUpdateResult_t result, bool ioFailure)
	{
		if (result.m_eResult != EResult.k_EResultOK)
		{
			Debug.Log($"<color=red>Error result on uploading item: {result.m_eResult}. Aborting.</color>");
			SteamUGC.DeleteItem(result.m_nPublishedFileId);
			return;
		}
		SaveModSourcePath(result.m_nPublishedFileId, workshopItemPath.text);
		PopulateWorkshopItems();
		uploadingDialog.SetActive(value: false);
		OpenURLForFileID(currentEdit);
	}

	private string LoadModSourcePath(PublishedFileId_t id)
	{
		string result = "";
		string path = Path.Combine(Application.persistentDataPath, "workshop", id.ToString(), "lastfolder.txt");
		if (File.Exists(path))
		{
			using StreamReader streamReader = new StreamReader(path, Encoding.UTF8);
			result = streamReader.ReadLine().Trim();
			streamReader.Close();
		}
		return result;
	}

	private void SaveModSourcePath(PublishedFileId_t id, string path)
	{
		string text = Path.Combine(Application.persistentDataPath, "workshop", id.ToString());
		if (!Directory.Exists(text))
		{
			Directory.CreateDirectory(text);
		}
		using StreamWriter streamWriter = new StreamWriter(Path.Combine(text, "lastfolder.txt"), append: false, Encoding.UTF8);
		streamWriter.WriteLine(path);
		streamWriter.Close();
	}

	private void OpenURLForFileID(PublishedFileId_t id)
	{
		PublishedFileId_t publishedFileId_t = id;
		string text = "steam://url/CommunityFilePage/" + publishedFileId_t.ToString();
		if (SteamUtils.IsOverlayEnabled())
		{
			SteamFriends.ActivateGameOverlayToWebPage(text);
		}
		else
		{
			Application.OpenURL(text);
		}
	}

	private void PopulateWorkshopItems()
	{
		foreach (Transform item in contentContainer.transform)
		{
			UnityEngine.Object.Destroy(item.gameObject);
		}
		UGCQueryHandle_t handle = SteamUGC.CreateQueryUserUGCRequest(SteamUser.GetSteamID().GetAccountID(), EUserUGCList.k_EUserUGCList_Published, EUGCMatchingUGCType.k_EUGCMatchingUGCType_Items, EUserUGCListSortOrder.k_EUserUGCListSortOrder_CreationOrderAsc, (AppId_t)1199380u, (AppId_t)569480u, 1u);
		SteamUGC.AddRequiredTag(handle, "kcmod");
		SteamUGC.SetReturnKeyValueTags(handle, bReturnKeyValueTags: true);
		SteamUGC.SetReturnLongDescription(handle, bReturnLongDescription: true);
		SteamUGC.SetReturnMetadata(handle, bReturnMetadata: true);
		SteamAPICall_t hAPICall = SteamUGC.SendQueryUGCRequest(handle);
		OnQueryCompletedResult.Set(hAPICall);
		SteamAPI.RunCallbacks();
	}

	private void OnQueryCompleted(SteamUGCQueryCompleted_t result, bool ioFailure)
	{
		console.Writeline($"Workshop query status: {result.m_eResult}, Found {result.m_unTotalMatchingResults} mods.");
		for (uint num = 0u; num < result.m_unNumResultsReturned; num++)
		{
			SteamUGC.GetQueryUGCResult(result.m_handle, num, out var pDetails);
			WorkshopItem workshopItem = UnityEngine.Object.Instantiate(workShopItemPrefab);
			workshopItem.gameObject.SetActive(value: true);
			workshopItem.transform.SetParent(contentContainer);
			workshopItem.transform.localScale = new Vector3(1f, 1f, 1f);
			PublishedFileId_t nPublishedFileId = pDetails.m_nPublishedFileId;
			workshopItem.workshopItemUrl = "steam://url/CommunityFilePage/" + nPublishedFileId.ToString();
			workshopItem.fileId = pDetails.m_nPublishedFileId;
			workshopItem.description.text = pDetails.m_rgchDescription;
			workshopItem.title.text = pDetails.m_rgchTitle;
			workshopItem.SetClickReturn(ItemClicked, OnUnsub, OnGoToItem);
			string[] source = pDetails.m_rgchTags.Split(new string[1] { "," }, StringSplitOptions.RemoveEmptyEntries);
			workshopItem.SetTags(source.Where((string s) => s != "kcmod" || s != "v2").ToArray());
			workshopItem.SetVisibility(pDetails.m_eVisibility);
			SteamUGC.GetQueryUGCPreviewURL(result.m_handle, num, out var pchURL, 200u);
			SteamUGC.GetQueryUGCMetadata(result.m_handle, num, out var pchMetadata, 300u);
			WorkshopMetadata workshopMetadata = JsonUtility.FromJson<WorkshopMetadata>(pchMetadata);
			if (workshopMetadata == null)
			{
				workshopMetadata = new WorkshopMetadata(1);
			}
			workshopItem.version = workshopMetadata.version;
			workshopItem.loadImageRequest = new WWW(pchURL);
		}
		Invoke("SetScrollToTop", 0f);
	}

	public void SetScrollToTop()
	{
		scrollRect.verticalNormalizedPosition = 1f;
	}

	public bool ValidateWorkshopMod(string path)
	{
		console.Writeline("<color=blue>Testing mod...</color>");
		bool validAndLoadable = false;
		ModCompiler.LoadMod(path, (string s) =>
		{
			console.Writeline(s);
		}, out validAndLoadable);
		if (!validAndLoadable)
		{
			console.Writeline("<color=red>Workshop item doesn't compile or pass security check or is otherwise invalid.</color>");
		}
		else
		{
			console.Writeline("<color=green>Pass compile and security test</color>");
		}
		return validAndLoadable;
	}

	public void TestCompile()
	{
		ValidateData();
	}
}
