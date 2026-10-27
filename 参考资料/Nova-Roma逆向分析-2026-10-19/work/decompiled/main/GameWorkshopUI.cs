using System.Collections.Generic;
using Assets.Code.UI;
using Steamworks;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class GameWorkshopUI : MonoBehaviour
{
	public class LoadedMod
	{
		public PublishedFileId_t fileId;

		public bool loaded;

		public bool validVersion;

		public int version;
	}

	public ScrollRect scrollRect;

	public Transform contentContainer;

	public WorkshopItem workShopItemPrefab;

	public GameObject localModItemPrefab;

	public Transform localModItemContainer;

	public ScrollRect localModScrollRect;

	private CallResult<SteamUGCQueryCompleted_t> OnQueryCompletedResult;

	private Callback<ItemInstalled_t> OnItemInstalled;

	private Callback<RemoteStoragePublishedFileUnsubscribed_t> OnItemUnsub;

	public Confirmation loadConfirmation;

	public Button openSteamWorkshop;

	public static List<LoadedMod> loadedMods = new List<LoadedMod>();

	private void OnEnable()
	{
		if (OnQueryCompletedResult == null)
		{
			OnQueryCompletedResult = CallResult<SteamUGCQueryCompleted_t>.Create(OnQueryCompleted);
			OnItemInstalled = Callback<ItemInstalled_t>.Create(OnItemInstalledFunc);
			OnItemUnsub = Callback<RemoteStoragePublishedFileUnsubscribed_t>.Create(OnItemUnsubFunc);
			openSteamWorkshop.onClick.AddListener(() =>
			{
				string text = "https://steamcommunity.com/app/569480/workshop/";
				if (SteamUtils.IsOverlayEnabled())
				{
					SteamFriends.ActivateGameOverlayToWebPage(text);
				}
				else
				{
					Application.OpenURL(text);
				}
			});
		}
		openSteamWorkshop.gameObject.SetActive(value: false);
		scrollRect.gameObject.SetActive(value: false);
		PopulateLocalItems();
		PopulateWorkshopItems();
	}

	public void OnItemInstalledFunc(ItemInstalled_t result)
	{
		loadConfirmation.gameObject.SetActive(value: false);
		PopulateWorkshopItems();
	}

	public void OnItemUnsubFunc(RemoteStoragePublishedFileUnsubscribed_t result)
	{
		loadConfirmation.gameObject.SetActive(value: false);
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
		item.SetHighlighted(highlighted: true);
	}

	private void OnUnsub(WorkshopItem item)
	{
		loadConfirmation.ShowConfirmation(() =>
		{
			SteamUGC.UnsubscribeItem(item.fileId);
		}, () =>
		{
		});
		if (GamepadControl.inst.isControllerActive)
		{
			loadConfirmation.GetComponent<ConsoleUIItem>().Hover();
		}
	}

	private void OnGoToItem(WorkshopItem item)
	{
	}

	private void PopulateLocalItems()
	{
		foreach (Transform item in localModItemContainer.transform)
		{
			Object.Destroy(item.gameObject);
		}
		foreach (KCModHelper.ModLoader.LocalMod item2 in KCModHelper.ModLoader.localModsLoadedAtStartup)
		{
			GameObject gameObject = Object.Instantiate(localModItemPrefab, localModItemContainer);
			gameObject.gameObject.SetActive(value: true);
			gameObject.transform.localScale = new Vector3(1f, 1f, 1f);
			gameObject.transform.Find("Title").GetComponent<TextMeshProUGUI>().text = "( " + item2.GetFolderName() + " )  " + item2.name;
			string text = item2.description;
			if (item2.infoExists && !item2.validFormat)
			{
				text = "info.json formatting error";
			}
			gameObject.transform.Find("Description").GetComponent<TextMeshProUGUI>().text = text;
			gameObject.transform.Find("FolderButton").GetComponent<Button>().onClick.AddListener(OpenPathToLocalMod(item2.path));
		}
		localModScrollRect.gameObject.SetActive(KCModHelper.ModLoader.localModsLoadedAtStartup.Count > 0);
	}

	private UnityAction OpenPathToLocalMod(string path)
	{
		return () =>
		{
			OpenInFileBrowser.Open(path);
		};
	}

	private void PopulateWorkshopItems()
	{
		foreach (Transform item in contentContainer.transform)
		{
			Object.Destroy(item.gameObject);
		}
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
			SteamUGC.GetQueryUGCResult(result.m_handle, num, out var deets);
			WorkshopItem workshopItem = Object.Instantiate(workShopItemPrefab, contentContainer);
			workshopItem.gameObject.SetActive(value: true);
			workshopItem.transform.localScale = new Vector3(1f, 1f, 1f);
			PublishedFileId_t nPublishedFileId = deets.m_nPublishedFileId;
			workshopItem.workshopItemUrl = "steam://url/CommunityFilePage/" + nPublishedFileId.ToString();
			workshopItem.fileId = deets.m_nPublishedFileId;
			workshopItem.description.text = deets.m_rgchDescription;
			workshopItem.title.text = deets.m_rgchTitle;
			workshopItem.SetClickReturn(ItemClicked, OnUnsub, OnGoToItem);
			workshopItem.SetLoaded(loadedMods.Find((LoadedMod x) => x.fileId == deets.m_nPublishedFileId));
			SteamUGC.GetQueryUGCPreviewURL(result.m_handle, num, out var pchURL, 200u);
			workshopItem.loadImageRequest = new WWW(pchURL);
		}
		scrollRect.gameObject.SetActive(result.m_unNumResultsReturned != 0 || KCModHelper.ModLoader.localModsLoadedAtStartup.Count == 0);
		openSteamWorkshop.gameObject.SetActive(scrollRect.gameObject.activeSelf);
		Invoke("SetScrollToTop", 0f);
	}

	public void SetScrollToTop()
	{
		scrollRect.verticalNormalizedPosition = 1f;
	}

	private void Update()
	{
	}
}
