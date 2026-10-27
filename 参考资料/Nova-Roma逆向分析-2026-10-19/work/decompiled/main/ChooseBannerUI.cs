using System.Collections.Generic;
using System.IO;
using System.Linq;
using Steamworks;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ChooseBannerUI : MonoBehaviour
{
	public BannerTile bannerTilePrefab;

	public RawImage bigBannerImage;

	public Transform normalBannerContainer;

	public Transform swatchContainer;

	public Transform customBannerContainer;

	public Transform workshopBannerContainer;

	public GameObject customBannerScrollView;

	public GameObject workshopBannerScrollView;

	public TextMeshProUGUI normalBannerTitle;

	public TextMeshProUGUI customBannerTitle;

	public TextMeshProUGUI workshopBannerTitle;

	public PickNameUI pickNameUI;

	public UploadBanner uploadBannerUI;

	public Button acceptButton;

	public Button cancelButton;

	public Button uploadBanner;

	public Button viewInWorkshop;

	public Button openBannerLocation;

	public GameObject noBannersFoundUI;

	public GameObject noWorkshopBannersFoundUI;

	public GameObject NoCustomBannersParent;

	public GameObject CustomBannersParent;

	public GameObject CustomBannersTitleParent;

	private UGCQueryHandle_t qh;

	private CallResult<ItemInstalled_t> OnItemInstalledCallResult;

	private CallResult<SteamUGCQueryCompleted_t> OnQueryCompleted;

	private Callback<RemoteStoragePublishedFileSubscribed_t> OnFileSubscribed;

	private Callback<RemoteStoragePublishedFileUnsubscribed_t> OnFileUnsubscribed;

	private Callback<ItemInstalled_t> OnItemInstalled;

	private Callback<RemoteStoragePublishedFileDeleted_t> OnItemDeleted;

	private uint processedQueryItems;

	private uint page = 1u;

	private List<string> madeBannerHashes = new List<string>();

	private Dictionary<string, string> bannerUrls = new Dictionary<string, string>();

	public BannerTile highlightedTile;

	private BannerSwatch highlightedSwatch;

	private int bannerIdx;

	private ConsoleUIItem itemCallback;

	private int dirHash;

	private Timer dirChangeCheckTimer = new Timer(1f);

	private void Start()
	{
		foreach (Transform item in normalBannerContainer)
		{
			item.GetComponent<BannerTile>().GiveBannerUIRef(this);
		}
		foreach (Transform item2 in swatchContainer)
		{
			item2.GetComponent<BannerSwatch>().GiveBannerUIRef(this);
		}
		uploadBannerUI.bannerUI = this;
		acceptButton.onClick.AddListener(OnAccept);
		cancelButton.onClick.AddListener(OnCancel);
		uploadBanner.onClick.AddListener(() =>
		{
			uploadBannerUI.gameObject.SetActive(value: true);
		});
		viewInWorkshop.onClick.AddListener(() =>
		{
			FindTextureInWorkshop();
		});
		openBannerLocation.onClick.AddListener(() =>
		{
			OpenInFileBrowser.Open(Path.Combine(Application.persistentDataPath, Player.BannerPath));
		});
	}

	private void FindTextureInWorkshop()
	{
		if (!(highlightedTile == null))
		{
			string workshopUrl = highlightedTile.workshopUrl;
			if (SteamUtils.IsOverlayEnabled())
			{
				SteamFriends.ActivateGameOverlayToWebPage(workshopUrl);
			}
			else
			{
				Application.OpenURL(workshopUrl);
			}
		}
	}

	private void GetUserMadeBanners()
	{
		if (OnQueryCompleted == null)
		{
			OnQueryCompleted = CallResult<SteamUGCQueryCompleted_t>.Create(OnQueryCompletedFunction);
		}
		if (page == 1)
		{
			bannerUrls.Clear();
			madeBannerHashes.Clear();
		}
		UGCQueryHandle_t handle = SteamUGC.CreateQueryUserUGCRequest(SteamUser.GetSteamID().GetAccountID(), EUserUGCList.k_EUserUGCList_Published, EUGCMatchingUGCType.k_EUGCMatchingUGCType_Items, EUserUGCListSortOrder.k_EUserUGCListSortOrder_CreationOrderAsc, SteamUtils.GetAppID(), SteamUtils.GetAppID(), page);
		SteamUGC.AddRequiredTag(handle, "banner");
		SteamUGC.SetReturnMetadata(handle, bReturnMetadata: true);
		SteamAPICall_t hAPICall = SteamUGC.SendQueryUGCRequest(handle);
		OnQueryCompleted.Set(hAPICall);
		SteamAPI.RunCallbacks();
	}

	private void OnQueryCompletedFunction(SteamUGCQueryCompleted_t result, bool failure)
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
			SteamUGC.GetQueryUGCMetadata(result.m_handle, num, out var pchMetadata, 200u);
			madeBannerHashes.Add(pchMetadata);
			Dictionary<string, string> dictionary = bannerUrls;
			string key = pchMetadata;
			PublishedFileId_t nPublishedFileId = pDetails.m_nPublishedFileId;
			dictionary[key] = "steam://url/CommunityFilePage/" + nPublishedFileId.ToString();
		}
		processedQueryItems += result.m_unNumResultsReturned;
		if (processedQueryItems < result.m_unTotalMatchingResults)
		{
			page++;
			GetUserMadeBanners();
		}
		else
		{
			processedQueryItems = 0u;
			page = 1u;
			UpdateLocalBannersWithUpload();
		}
	}

	private void UpdateLocalBannersWithUpload()
	{
		foreach (string madeBannerHash in madeBannerHashes)
		{
			Debug.Log("hash: " + madeBannerHash);
		}
		Debug.Log("[UpdateLocalBannersWithUpload]");
		BannerTile[] componentsInChildren = customBannerContainer.GetComponentsInChildren<BannerTile>();
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			BannerTile component = componentsInChildren[i].GetComponent<BannerTile>();
			string text = Util.TextureHash(component.image.texture as Texture2D).ToString();
			bool flag = false;
			for (int j = 0; j < madeBannerHashes.Count; j++)
			{
				if (madeBannerHashes[j] == text)
				{
					flag = true;
				}
			}
			string workshopUrl = "";
			if (flag)
			{
				workshopUrl = bannerUrls[text];
			}
			component.SetWorkshopState(isWorkshopReady: true, !flag, showIcon: true, workshopUrl);
		}
	}

	private void OnDisable()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = true;
	}

	private void ClearSwatchSelection()
	{
		for (int i = 0; i < swatchContainer.childCount; i++)
		{
			swatchContainer.GetChild(i).GetChild(0).gameObject.SetActive(value: false);
		}
	}

	private void OnEnable()
	{
		bannerIdx = 0;
		GameState.inst.AlphaNumericHotkeysEnabled = false;
		swatchContainer.gameObject.SetActive(value: false);
		ClearSwatchSelection();
		if (highlightedSwatch == null)
		{
			highlightedSwatch = swatchContainer.GetChild(0).GetComponent<BannerSwatch>();
		}
		highlightedSwatch.transform.GetChild(0).gameObject.SetActive(value: true);
		Refresh();
		if (GameUI.IsOnConsole())
		{
			NoCustomBannersParent.SetActive(value: false);
			CustomBannersParent.SetActive(value: false);
			CustomBannersTitleParent.SetActive(value: false);
		}
	}

	private void OnSubscribed(RemoteStoragePublishedFileSubscribed_t callback)
	{
		Debug.Log("OnSubscribed");
	}

	private void OnUnsubscribed(RemoteStoragePublishedFileUnsubscribed_t callback)
	{
		Debug.Log("OnUnsubscribed");
		Refresh();
	}

	private void OnItemInstalledFunc(ItemInstalled_t callback)
	{
		Debug.Log("On Install");
		Refresh();
	}

	private void OnItemDeletedFunc(RemoteStoragePublishedFileDeleted_t callback)
	{
		Debug.Log("On Install");
		Refresh();
	}

	public void Refresh()
	{
		if (OnFileSubscribed == null)
		{
			OnFileSubscribed = new Callback<RemoteStoragePublishedFileSubscribed_t>(OnSubscribed);
			OnFileUnsubscribed = new Callback<RemoteStoragePublishedFileUnsubscribed_t>(OnUnsubscribed);
			OnItemInstalled = new Callback<ItemInstalled_t>(OnItemInstalledFunc);
			OnItemDeleted = new Callback<RemoteStoragePublishedFileDeleted_t>(OnItemDeletedFunc);
		}
		uploadBanner.gameObject.SetActive(value: false);
		viewInWorkshop.gameObject.SetActive(value: false);
		highlightedTile = null;
		foreach (Transform item in customBannerContainer)
		{
			Object.Destroy(item.gameObject);
		}
		foreach (Transform item2 in workshopBannerContainer)
		{
			Object.Destroy(item2.gameObject);
		}
		string[] array = (from s in Directory.GetFiles(Path.Combine(Application.persistentDataPath, Player.BannerPath), "*.png", SearchOption.TopDirectoryOnly)
			where !s.Contains("banner_reference.png")
			select s).ToArray();
		for (int num = 0; num < array.Length; num++)
		{
			Texture2D texture = Util.LoadPNG(array[num]);
			BannerTile bannerTile = Object.Instantiate(bannerTilePrefab, customBannerContainer);
			bannerTile.gameObject.SetActive(value: true);
			bannerTile.GiveBannerUIRef(this);
			bannerTile.SetTexture(texture);
		}
		noBannersFoundUI.gameObject.SetActive(array.Length == 0);
		customBannerScrollView.gameObject.SetActive(array.Length != 0);
		if (SteamManager.Initialized)
		{
			GetUserMadeBanners();
			uint numSubscribedItems = SteamUGC.GetNumSubscribedItems();
			if (numSubscribedItems != 0)
			{
				noWorkshopBannersFoundUI.SetActive(value: false);
				workshopBannerScrollView.gameObject.SetActive(value: true);
				PublishedFileId_t[] array2 = new PublishedFileId_t[numSubscribedItems];
				SteamUGC.GetSubscribedItems(array2, numSubscribedItems);
				for (int num2 = 0; num2 < array2.Length; num2++)
				{
					if ((SteamUGC.GetItemState(array2[num2]) & 4) != 0)
					{
						ulong punSizeOnDisk = 0uL;
						string pchFolder = "";
						uint cchFolderSize = 2000u;
						uint punTimeStamp = 0u;
						SteamUGC.GetItemInstallInfo(array2[num2], out punSizeOnDisk, out pchFolder, cchFolderSize, out punTimeStamp);
						Debug.LogError(pchFolder);
						string text = Path.Combine(pchFolder, "banner.png");
						if (File.Exists(text))
						{
							Texture2D texture2 = Util.LoadPNG(text);
							BannerTile bannerTile2 = Object.Instantiate(bannerTilePrefab, workshopBannerContainer);
							bannerTile2.gameObject.SetActive(value: true);
							bannerTile2.GiveBannerUIRef(this);
							bannerTile2.SetTexture(texture2);
							bannerTile2.SetWorkshopState(isWorkshopReady: true, canUpload: false, showIcon: false, "steam://url/CommunityFilePage/" + array2[num2].m_PublishedFileId);
						}
					}
				}
			}
			else
			{
				noWorkshopBannersFoundUI.SetActive(value: true);
				workshopBannerScrollView.gameObject.SetActive(value: false);
			}
		}
		dirHash = GetLocalBannerDirHash();
	}

	public void HighlightBannerTile(BannerTile tile)
	{
		if (highlightedTile != null)
		{
			highlightedTile.SetHighlight(show: false);
		}
		tile.SetHighlight(show: true);
		highlightedTile = tile;
		if (tile.transform.parent == normalBannerContainer)
		{
			bannerIdx = tile.transform.GetSiblingIndex();
			swatchContainer.gameObject.SetActive(value: false);
		}
		else
		{
			bannerIdx = -1;
			swatchContainer.gameObject.SetActive(value: true);
		}
		bigBannerImage.texture = tile.image.texture;
		if (tile.isWorkshopReady && tile.canUpload)
		{
			uploadBannerUI.image.texture = tile.image.texture as Texture2D;
		}
		uploadBanner.gameObject.SetActive(tile.isWorkshopReady && tile.canUpload);
		viewInWorkshop.gameObject.SetActive(tile.isWorkshopReady && !tile.canUpload);
	}

	public void HighlightBannerSwatch(BannerSwatch swatch)
	{
		if (highlightedSwatch != null)
		{
			highlightedSwatch.transform.GetChild(0).gameObject.SetActive(value: false);
		}
		highlightedSwatch = swatch;
		highlightedSwatch.transform.GetChild(0).gameObject.SetActive(value: true);
	}

	public void OnAccept()
	{
		pickNameUI.OnUpdateBanner(bigBannerImage.texture as Texture2D);
		if (bannerIdx == -1)
		{
			Player.inst.SetIndexedBanner(highlightedSwatch.transform.GetSiblingIndex());
			Player.inst.SetCustomBannerTexture(bigBannerImage.texture as Texture2D);
		}
		else
		{
			Player.inst.SetIndexedBanner(bannerIdx);
		}
		SfxSystem.inst.PlayFromBank("RenameThing", Camera.main.transform.position);
		Close();
	}

	public void OnCancel()
	{
		SfxSystem.PlayUiCancel();
		Close();
	}

	public void Close()
	{
		if (highlightedTile != null)
		{
			highlightedTile.SetHighlight(show: false);
		}
		gameObject.SetActive(value: false);
		if (!pickNameUI.isActiveAndEnabled)
		{
			GameState.inst.mainMenuMode.OnClickedReturnToGame();
		}
		if (GamepadControl.inst.isControllerActive && itemCallback != null)
		{
			itemCallback.Hover();
		}
	}

	public void Show(ConsoleUIItem item)
	{
		itemCallback = item;
		gameObject.SetActive(value: true);
		if (GamepadControl.inst.isControllerActive)
		{
			GetComponent<ConsoleUIItem>().Hover();
		}
	}

	public int GetLocalBannerDirHash()
	{
		string text = "";
		string[] files = Directory.GetFiles(Path.Combine(Application.persistentDataPath, "CustomBanners"));
		for (int i = 0; i < files.Length; i++)
		{
			text += File.GetLastWriteTimeUtc(files[i]).GetHashCode();
		}
		return text.GetHashCode();
	}

	private void Update()
	{
		if (dirChangeCheckTimer.Update(Time.unscaledDeltaTime))
		{
			SteamAPI.RunCallbacks();
			if (GetLocalBannerDirHash() != dirHash)
			{
				Refresh();
			}
		}
	}
}
