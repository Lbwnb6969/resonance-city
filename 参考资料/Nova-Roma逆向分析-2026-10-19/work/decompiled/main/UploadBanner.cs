using System.IO;
using Steamworks;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UploadBanner : MonoBehaviour
{
	public TMP_InputField title;

	public TMP_InputField description;

	public RawImage image;

	public GameObject uploadingModal;

	private CallResult<CreateItemResult_t> OnCreateItemResultCallResult;

	private CallResult<SubmitItemUpdateResult_t> OnSubmitItemResultCallResult;

	public Button upload;

	public Button cancel;

	private string tmpPath;

	public ChooseBannerUI bannerUI;

	private void OnEnable()
	{
		upload.interactable = true;
		cancel.interactable = true;
		title.interactable = true;
		title.text = "";
		description.interactable = true;
		description.text = "";
		uploadingModal.SetActive(value: false);
	}

	private void Upload()
	{
		upload.interactable = false;
		upload.interactable = false;
		cancel.interactable = false;
		title.interactable = false;
		description.interactable = false;
		uploadingModal.SetActive(value: true);
		tmpPath = Path.Combine(Application.persistentDataPath, "temp");
		OnCreateItemResultCallResult = CallResult<CreateItemResult_t>.Create(OnCreateItemResult);
		OnSubmitItemResultCallResult = CallResult<SubmitItemUpdateResult_t>.Create(OnSubmitItemResult);
		SteamAPICall_t steamAPICall_t = SteamUGC.CreateItem(SteamUtils.GetAppID(), EWorkshopFileType.k_EWorkshopFileTypeFirst);
		OnCreateItemResultCallResult.Set(steamAPICall_t);
		SteamAPI.RunCallbacks();
		string[] array = new string[6]
		{
			"SteamUGC.CreateItem(",
			SteamUtils.GetAppID().ToString(),
			", ",
			EWorkshopFileType.k_EWorkshopFileTypeFirst.ToString(),
			") : ",
			null
		};
		SteamAPICall_t steamAPICall_t2 = steamAPICall_t;
		array[5] = steamAPICall_t2.ToString();
		Debug.Log(string.Concat(array));
	}

	private void Start()
	{
		upload.onClick.AddListener(Upload);
		cancel.onClick.AddListener(() =>
		{
			gameObject.SetActive(value: false);
		});
	}

	private void OnSubmitItemResult(SubmitItemUpdateResult_t pCallback, bool bIOFailure)
	{
		string[] array = new string[8]
		{
			"[",
			3403.ToString(),
			" - SubmitItemResult] - ",
			pCallback.m_eResult.ToString(),
			" -- ",
			null,
			null,
			null
		};
		PublishedFileId_t nPublishedFileId = pCallback.m_nPublishedFileId;
		array[5] = nPublishedFileId.ToString();
		array[6] = " -- ";
		array[7] = pCallback.m_bUserNeedsToAcceptWorkshopLegalAgreement.ToString();
		Debug.Log(string.Concat(array));
		if (pCallback.m_eResult == EResult.k_EResultOK)
		{
			_ = pCallback.m_bUserNeedsToAcceptWorkshopLegalAgreement;
		}
		nPublishedFileId = pCallback.m_nPublishedFileId;
		string text = "steam://url/CommunityFilePage/" + nPublishedFileId.ToString();
		if (SteamUtils.IsOverlayEnabled())
		{
			SteamFriends.ActivateGameOverlayToWebPage(text);
		}
		else
		{
			Application.OpenURL(text);
		}
		Directory.Delete(tmpPath, recursive: true);
		bannerUI.Refresh();
		gameObject.SetActive(value: false);
	}

	private void OnCreateItemResult(CreateItemResult_t pCallback, bool bIOFailure)
	{
		string[] array = new string[8]
		{
			"[",
			3403.ToString(),
			" - CreateItemResult] - ",
			pCallback.m_eResult.ToString(),
			" -- ",
			null,
			null,
			null
		};
		PublishedFileId_t nPublishedFileId = pCallback.m_nPublishedFileId;
		array[5] = nPublishedFileId.ToString();
		array[6] = " -- ";
		array[7] = pCallback.m_bUserNeedsToAcceptWorkshopLegalAgreement.ToString();
		Debug.Log(string.Concat(array));
		if (pCallback.m_eResult == EResult.k_EResultOK)
		{
			_ = pCallback.m_bUserNeedsToAcceptWorkshopLegalAgreement;
			UGCUpdateHandle_t uGCUpdateHandle_t = SteamUGC.StartItemUpdate(SteamUtils.GetAppID(), pCallback.m_nPublishedFileId);
			SteamUGC.SetItemTitle(uGCUpdateHandle_t, title.text);
			SteamUGC.SetItemDescription(uGCUpdateHandle_t, description.text);
			SteamUGC.SetItemVisibility(uGCUpdateHandle_t, ERemoteStoragePublishedFileVisibility.k_ERemoteStoragePublishedFileVisibilityPublic);
			SteamUGC.SetItemMetadata(uGCUpdateHandle_t, Util.TextureHash(image.texture as Texture2D).ToString());
			SteamUGC.SetItemTags(uGCUpdateHandle_t, new string[1] { "banner" });
			string text = Path.Combine(tmpPath, "banner.png");
			Directory.CreateDirectory(tmpPath);
			byte[] bytes = ((Texture2D)image.texture).EncodeToPNG();
			File.WriteAllBytes(text, bytes);
			SteamUGC.SetItemContent(uGCUpdateHandle_t, tmpPath);
			SteamUGC.SetItemPreview(uGCUpdateHandle_t, text);
			SteamAPICall_t hAPICall = SteamUGC.SubmitItemUpdate(uGCUpdateHandle_t, "Upload from game");
			OnSubmitItemResultCallResult.Set(hAPICall);
			SteamAPI.RunCallbacks();
		}
		else
		{
			string text2 = pCallback.m_eResult.ToString();
			int eResult = (int)pCallback.m_eResult;
			Debug.LogError(text2 + "  " + eResult);
		}
	}
}
