using Assets.Code.UI;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class NewMapUI : MonoBehaviour
{
	public Button editButton;

	public Button doneButton;

	public Button saveMapButton;

	public Button loadMapButton;

	public Confirmation saveMapConfirmation;

	public TMP_InputField mapNameInput;

	public SlideAnim topBarSlide;

	public SlideAnim topTitleSlide;

	public SlideAnim saveLoadSlide;

	public GameSavedUI mapSavedBanner;

	public GameSavedUI editorNoteBanner;

	public GameObject MapEditContainer;

	public GameObject NewMapSettingsContainer;

	public GameObject confirmButtonContainer;

	public Toggle randomToggle;

	private float fogDistMin;

	private float fogDistMax;

	public bool InEditMode;

	private void Start()
	{
		editButton.onClick.AddListener(OnEdit);
		doneButton.onClick.AddListener(OnDone);
		if (saveMapButton != null)
		{
			saveMapButton.onClick.AddListener(OnSaveMap);
		}
		if (loadMapButton != null)
		{
			loadMapButton.onClick.AddListener(OnLoadMap);
		}
		if (mapNameInput != null)
		{
			mapNameInput.onSelect.AddListener((string s) =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = false;
			});
			mapNameInput.onDeselect.AddListener((string s) =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = true;
			});
		}
	}

	private void OnSaveMap()
	{
		if (!(saveMapConfirmation == null) && (!(MapEditorController.inst != null) || !MapEditorController.inst.FocusNextPlacementError()))
		{
			if (mapNameInput != null)
			{
				mapNameInput.text = (string.IsNullOrEmpty(LoadSave.currentMapName) ? World.inst.GetTextSeed() : LoadSave.currentMapName);
			}
			saveMapConfirmation.ShowConfirmation(DoSaveMap, () =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = true;
			});
			SfxSystem.PlayUiSelect();
		}
	}

	private void DoSaveMap()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = true;
		string text = ((mapNameInput != null) ? mapNameInput.text.Trim() : "");
		if (string.IsNullOrEmpty(text))
		{
			text = World.inst.GetTextSeed();
		}
		LoadSave.Save("", null, isAutoSave: false, isMapSave: true, text);
		LoadSave.currentMapName = text;
		if (mapSavedBanner != null)
		{
			mapSavedBanner.Show(LocalizationManager.GetTranslation("gamesavedui_title_mapsaved"));
		}
		SfxSystem.PlayUiSelect();
	}

	private void OnLoadMap()
	{
		GameState.inst.mainMenuMode.OnClickedLoadMap();
	}

	private void OnInlandOceanFilled(int cellCount)
	{
		if (editorNoteBanner != null)
		{
			editorNoteBanner.Show(LocalizationManager.GetTranslation("mapeditor_note_inlandseafilled"));
		}
	}

	private void OnSmallIslandSunk(int cellCount)
	{
		if (editorNoteBanner != null)
		{
			editorNoteBanner.Show(LocalizationManager.GetTranslation("mapeditor_note_smallislandsunk"));
		}
	}

	private void OnEnable()
	{
		World.OnInlandOceanFilled += OnInlandOceanFilled;
		World.OnSmallIslandSunk += OnSmallIslandSunk;
		editButton.gameObject.SetActive(value: true);
		if (saveMapButton != null)
		{
			saveMapButton.interactable = true;
		}
		if (loadMapButton != null)
		{
			loadMapButton.interactable = true;
		}
		GamepadControl.inst.UIYInput += OnConsoleUIYInput;
		Cam.inst.isNewMap = true;
		MiniMapUI.inst.SetNewMap(isNewMap: true);
	}

	private void OnDisable()
	{
		World.OnInlandOceanFilled -= OnInlandOceanFilled;
		World.OnSmallIslandSunk -= OnSmallIslandSunk;
		GamepadControl.inst.UIYInput -= OnConsoleUIYInput;
		if (GameState.IsQuitting)
		{
			return;
		}
		if (InEditMode)
		{
			RenderSettings.fogStartDistance = fogDistMin;
			RenderSettings.fogEndDistance = fogDistMax;
			if ((bool)Cam.inst)
			{
				Cam.inst.mapEditCameraParamsOn = false;
			}
		}
		if (saveMapConfirmation != null)
		{
			saveMapConfirmation.Reset();
		}
		ResetSlide(MapEditContainer.GetComponent<SlideAnim>());
		ResetSlide(NewMapSettingsContainer.GetComponent<SlideAnim>());
		ResetSlide(topBarSlide);
		ResetSlide(topTitleSlide);
		ResetSlide(saveLoadSlide);
		InEditMode = false;
		if (MapEditorController.inst != null)
		{
			MapEditorController.inst.Close();
		}
		Cam.inst.isNewMap = false;
		MiniMapUI.inst.SetNewMap(isNewMap: false);
	}

	private void Update()
	{
		if (Cam.inst.isGenerateZoomedOut && Cam.inst.hasZoomedIn)
		{
			Cam.inst.isGenerateZoomedOut = false;
			Cam.inst.desiredDist = 90f;
		}
	}

	public void OnEdit()
	{
		MapEdit.inst.gameObject.SetActive(value: true);
		fogDistMin = RenderSettings.fogStartDistance;
		fogDistMax = RenderSettings.fogEndDistance;
		Cam.inst.mapEditCameraParamsOn = true;
		if (GamepadControl.inst.isControllerActive)
		{
			NewMapSettingsContainer.GetComponent<ConsoleUIItem>().Reset();
			MapEditContainer.GetComponent<ConsoleUIItem>().Hover();
		}
		MapEditContainer.GetComponent<SlideAnim>().Play(SlideAnim.PlayMode.Forward);
		NewMapSettingsContainer.GetComponent<SlideAnim>().Play(SlideAnim.PlayMode.Forward);
		if (topBarSlide != null)
		{
			topBarSlide.Play(SlideAnim.PlayMode.Forward);
		}
		if (topTitleSlide != null)
		{
			topTitleSlide.Play(SlideAnim.PlayMode.Forward);
		}
		if (saveLoadSlide != null)
		{
			saveLoadSlide.Play(SlideAnim.PlayMode.Forward);
		}
		MapEditorController.Ensure().Open();
		InEditMode = true;
	}

	private void OnDone()
	{
		if (!(MapEditorController.inst != null) || !MapEditorController.inst.FocusNextPlacementError())
		{
			if (MapEditorController.inst != null)
			{
				MapEditorController.inst.Close();
			}
			MapEdit.inst.ClearBrush();
			RenderSettings.fogStartDistance = fogDistMin;
			RenderSettings.fogEndDistance = fogDistMax;
			Cam.inst.mapEditCameraParamsOn = false;
			if (GamepadControl.inst.isControllerActive)
			{
				MapEditContainer.GetComponent<ConsoleUIItem>().Reset();
				NewMapSettingsContainer.GetComponent<ConsoleUIItem>().Hover();
			}
			MapEditContainer.GetComponent<SlideAnim>().Play(SlideAnim.PlayMode.Reverse);
			NewMapSettingsContainer.GetComponent<SlideAnim>().Play(SlideAnim.PlayMode.Reverse);
			if (topBarSlide != null)
			{
				topBarSlide.Play(SlideAnim.PlayMode.Reverse);
			}
			if (topTitleSlide != null)
			{
				topTitleSlide.Play(SlideAnim.PlayMode.Reverse);
			}
			if (saveLoadSlide != null)
			{
				saveLoadSlide.Play(SlideAnim.PlayMode.Reverse);
			}
			World.inst.GenerateLandMassIds();
			TerrainGen.inst.RefreshCellLandmassCache();
			World.inst.FindValidStartLandmasses();
			Player.inst.ResetPerLandMassData();
			InEditMode = false;
		}
	}

	private static void ResetSlide(SlideAnim s)
	{
		if (!(s == null))
		{
			s.Play(SlideAnim.PlayMode.Stopped);
			s.SetInstant(SlideAnim.PlayMode.Reverse);
		}
	}

	public void OnConsoleUIYInput()
	{
		randomToggle.isOn = !randomToggle.isOn;
	}
}
