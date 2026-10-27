using System;
using System.Globalization;
using System.IO;
using System.Threading;
using Assets.Code.UI;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class TourismModalUI : MonoBehaviour
{
	private enum State
	{
		idle,
		fadeToBlack,
		fadeIn
	}

	private State state;

	public Image blackCover;

	public Button close;

	public GameObject screenshotContainer;

	public Button screenshotButton;

	public GameObject Main;

	public Toggle VisitTab;

	public Toggle UploadTab;

	public GameObject VisitContainer;

	public GameObject UploadContainer;

	public GameObject L_visibleWhenLoaded;

	public GameObject L_visibleWhenLoading;

	public SaveLoadOption L_saveLoadOption;

	public TMP_InputField L_codeInput;

	public RawImage L_screenshot;

	public Button L_getKingdom;

	public Button L_loadKingdom;

	public string downloadPath;

	public SaveLoadOption U_saveLoadOption;

	public RawImage U_screenshot;

	public TMP_InputField U_codeOutput;

	public TextMeshProUGUI L_lastUploaded;

	public Button U_refreshCode;

	public Button U_takeScreenshot;

	public Button U_uploadKingdom;

	public string uploadPath;

	public TourismPopup popup;

	private float transistionTime = 2f;

	private bool loadSuccess;

	private float startZoom;

	private float endZoom;

	private int afterLoadFrameSkip;

	private Thread uploadSaveThread;

	private bool menuMode;

	private void Start()
	{
		close.onClick.AddListener(() =>
		{
			Hide();
			SfxSystem.PlayUiCancel();
		});
		VisitTab.onValueChanged.AddListener(ChangeToVisitGroup);
		UploadTab.onValueChanged.AddListener(ChangeToUploadGroup);
		L_getKingdom.onClick.AddListener(ClickRetrieveButton);
		L_loadKingdom.onClick.AddListener(StartLoad);
		L_codeInput.onSelect.AddListener((string s) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
		});
		L_codeInput.onDeselect.AddListener((string s) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = true;
		});
		U_refreshCode.onClick.AddListener(RefreshCode);
		U_uploadKingdom.onClick.AddListener(UploadKingdom);
		U_takeScreenshot.onClick.AddListener(TakeScreenshot);
		screenshotButton.onClick.AddListener(AcceptScreenshot);
	}

	public void ChangeToVisitGroup(bool active)
	{
		VisitContainer.SetActive(active);
		if (active)
		{
			SfxSystem.PlayUiSelect();
		}
	}

	public void ChangeToUploadGroup(bool active)
	{
		UploadContainer.SetActive(active);
		if (active)
		{
			SfxSystem.PlayUiSelect();
		}
	}

	public void VerifyCode()
	{
		U_getCode();
		U_screenshot.gameObject.SetActive(value: false);
	}

	public void StartLoad()
	{
		SfxSystem.PlayUiSelect();
		state = State.fadeToBlack;
		endZoom = Cam.inst.zoomRange.Max;
		startZoom = Cam.inst.dist;
		blackCover.raycastTarget = true;
	}

	public void Update()
	{
		if (afterLoadFrameSkip > 0)
		{
			afterLoadFrameSkip--;
			return;
		}
		switch (state)
		{
		case State.fadeToBlack:
			blackCover.color = new Color(blackCover.color.r, blackCover.color.g, blackCover.color.b, blackCover.color.a + Time.unscaledDeltaTime / transistionTime);
			Cam.inst.SetDist(Mathf.Lerp(startZoom, endZoom, Util.easeInQuad(blackCover.color.a)));
			if (blackCover.color.a >= 1f)
			{
				TryLoad();
				afterLoadFrameSkip = 3;
			}
			break;
		case State.fadeIn:
			blackCover.color = new Color(blackCover.color.r, blackCover.color.g, blackCover.color.b, blackCover.color.a - Time.unscaledDeltaTime / transistionTime);
			Cam.inst.SetDist(Mathf.Lerp(startZoom, endZoom, Util.easeOutQuad(1f - blackCover.color.a)));
			if (blackCover.color.a <= 0f)
			{
				Finished();
				state = State.idle;
			}
			break;
		}
		Thread thread = uploadSaveThread;
		if (thread != null && !thread.IsAlive && !U_saveLoadOption.gameObject.activeSelf)
		{
			SetUploadDataPath(LoadSave.GetSaveDir() + "/upload");
			U_saveLoadOption.gameObject.SetActive(value: true);
		}
		U_uploadKingdom.interactable = U_saveLoadOption.gameObject.activeSelf && U_screenshot.gameObject.activeSelf;
	}

	public void Finished()
	{
		if (!loadSuccess)
		{
			if (menuMode)
			{
				ShowError("ScriptLocalization.KingdomShareErrorLoadingKingdom");
			}
			else
			{
				ShowError("ScriptLocalization.KingdomShareErrorLoadingKingdomReturn");
			}
		}
		else
		{
			Hide();
		}
		blackCover.raycastTarget = false;
	}

	public void SetUploadDataPath(string path)
	{
		uploadPath = path;
		SaveLoadUI.FillOptionData(path, ref U_saveLoadOption);
		U_saveLoadOption.cloud.SetActive(value: false);
		U_saveLoadOption.SetImage(LoadSave.LoadTextureFromSave(path, "cover"));
	}

	public void SetDownloadDataPath(string path)
	{
		downloadPath = path;
		SaveLoadUI.FillOptionData(path, ref L_saveLoadOption);
		L_saveLoadOption.cloud.SetActive(value: false);
		L_saveLoadOption.SetImage(LoadSave.LoadTextureFromSave(path, "cover"));
	}

	private void Show()
	{
		Main.SetActive(value: true);
		blackCover.gameObject.SetActive(value: true);
		blackCover.color = new Color(blackCover.color.r, blackCover.color.g, blackCover.color.b, 0f);
		blackCover.raycastTarget = false;
		if (!menuMode)
		{
			U_saveLoadOption.gameObject.SetActive(value: false);
			Player.TourismInfo tourism = Player.inst.tourism;
			Player.inst.tourism = new Player.TourismInfo();
			uploadSaveThread = LoadSave.Save(LoadSave.GetSaveDir() + "/upload");
			Player.inst.tourism = tourism;
			VerifyCode();
		}
	}

	public void Hide()
	{
		string path = LoadSave.GetSaveDir() + "/upload";
		if (uploadSaveThread != null && uploadSaveThread.IsAlive)
		{
			uploadSaveThread.Abort();
		}
		if (Directory.Exists(path))
		{
			Directory.Delete(path, recursive: true);
		}
		Main.SetActive(value: false);
		blackCover.gameObject.SetActive(value: false);
		ClearLoadUI();
		if (menuMode)
		{
			GameState.inst.mainMenuMode.OnClickedClose();
		}
		else
		{
			GameState.inst.mainMenuMode.OnClickedReturnToGame();
		}
	}

	public void ShowError(string error)
	{
		popup.Show(error);
		Debug.Log(error);
	}

	public void ClickRetrieveButton()
	{
		SfxSystem.PlayUiSelect();
		SaveRepo.CheckCodeExistence(L_codeInput.text, LCodeExistence);
	}

	public void LCodeExistence(bool exists, string code)
	{
		if (!exists)
		{
			ShowError("ScriptLocalization.KingdomShareShareCodeNotFound");
			return;
		}
		L_visibleWhenLoaded.gameObject.SetActive(value: false);
		L_visibleWhenLoading.gameObject.SetActive(value: true);
		SaveRepo.GetScreenshot(code, LRecieveScreenshotCallback);
		SaveRepo.GetSave(code, LGetSaveData);
	}

	public void LRecieveScreenshotCallback(bool success, Texture2D texture)
	{
		if (success)
		{
			L_screenshot.texture = texture;
		}
	}

	public void LGetSaveData(bool success, byte[] binary)
	{
		L_visibleWhenLoading.gameObject.SetActive(value: false);
		if (!success)
		{
			ShowError("ScriptLocalization.KingdomShareFailedToFindDataFromCode");
			return;
		}
		string downloadDataPath = SaveRepo.WriteSaveDataToDisk(binary);
		SetDownloadDataPath(downloadDataPath);
		L_visibleWhenLoaded.gameObject.SetActive(value: true);
	}

	public void TryLoad()
	{
		Main.SetActive(value: false);
		loadSuccess = SaveRepo.LoadSaveFile(downloadPath);
		if (!loadSuccess)
		{
			if (menuMode)
			{
				World.inst.Generate();
			}
			else
			{
				LoadSave.LoadAtPath(uploadPath, "world");
			}
		}
		ClearLoadUI();
		endZoom = Cam.inst.dist;
		startZoom = Cam.inst.zoomRange.Max;
		Cam.inst.SetDist(startZoom);
		state = State.fadeIn;
	}

	private void ClearLoadUI()
	{
		L_codeInput.text = "";
		L_visibleWhenLoaded.SetActive(value: false);
		L_visibleWhenLoading.SetActive(value: false);
	}

	public void U_getCode()
	{
		if (string.IsNullOrEmpty(Player.inst.tourism.code))
		{
			SaveRepo.GetUniqueCode(RecieveCodeCallback);
		}
		else
		{
			SaveRepo.CheckStillControlCode(Player.inst.tourism.code, Player.inst.tourism.editAuthCode, CodeControlResult);
		}
	}

	public void CodeControlResult(bool valid, string code, DateTime? lastUploaded)
	{
		if (valid)
		{
			U_codeOutput.text = (Player.inst.tourism.code = code);
			if (lastUploaded.HasValue)
			{
				L_lastUploaded.text = "ScriptLocalization.KingdomShareLastUploaded " + lastUploaded.Value.ToLocalTime().ToString(CultureInfo.CurrentCulture);
			}
			SaveRepo.GetScreenshot(code, URecieveScreenshotCallback);
		}
		else
		{
			SaveRepo.GetUniqueCode(RecieveCodeCallback);
		}
	}

	public void URecieveScreenshotCallback(bool success, Texture2D texture)
	{
		if (success)
		{
			U_screenshot.texture = texture;
			U_screenshot.gameObject.SetActive(value: true);
		}
	}

	public void RecieveCodeCallback(bool success, string code, string editauthcode)
	{
		if (!success)
		{
			ShowError("ScriptLocalization.KingdomShareFailedToGetCode");
			return;
		}
		L_lastUploaded.text = "";
		U_codeOutput.text = (Player.inst.tourism.code = code);
		Player.inst.tourism.editAuthCode = editauthcode;
	}

	public void RefreshCode()
	{
		SfxSystem.PlayUiSelect();
		SaveRepo.GetUniqueCode(RecieveCodeCallback);
	}

	public void UploadKingdom()
	{
		SfxSystem.PlayUiSelect();
		SaveRepo.UploadSave(uploadPath, Convert.ToBase64String((U_screenshot.texture as Texture2D).EncodeToPNG()), Player.inst.tourism.code, Player.inst.tourism.editAuthCode, UploadFinished);
	}

	public void UploadFinished(bool success)
	{
		if (success)
		{
			popup.Show("ScriptLocalization.KingdomShareKingdomUploadedSuccessfully", Player.inst.tourism.code, Hide);
		}
		else
		{
			popup.Show("ScriptLocalization.KingdomShareErrorUploadingKingdom");
		}
	}

	public void TakeScreenshot()
	{
		SfxSystem.PlayUiSelect();
		GameUI.inst.SetVisabilityGameUIAllCanvases(visible: false);
		GameUI.inst.SetVisabilityGameUICanvas("TourismModalUI", visibility: true);
		screenshotContainer.SetActive(value: true);
		Main.SetActive(value: false);
	}

	public void AcceptScreenshot()
	{
		SfxSystem.PlayUiSelect();
		GameUI.inst.SetVisabilityGameUIAllCanvases(visible: true);
		Main.SetActive(value: true);
		screenshotContainer.SetActive(value: false);
	}

	public void RecieveScreenshot(Texture2D t)
	{
		U_screenshot.texture = t;
		U_screenshot.gameObject.SetActive(value: true);
	}

	public void SetupForMenuClick()
	{
		menuMode = true;
		Show();
		VisitTab.isOn = true;
		VisitContainer.SetActive(value: true);
		UploadTab.gameObject.SetActive(value: false);
		UploadContainer.SetActive(value: false);
	}

	public void SetupForGameClick()
	{
		menuMode = false;
		Show();
		UploadTab.gameObject.SetActive(value: true);
		UploadTab.isOn = true;
		UploadContainer.SetActive(value: true);
		VisitContainer.SetActive(value: false);
	}
}
