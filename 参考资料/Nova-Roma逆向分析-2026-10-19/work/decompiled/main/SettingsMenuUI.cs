using System;
using System.Collections.Generic;
using Assets;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class SettingsMenuUI : MonoBehaviour
{
	private enum SettingsTab
	{
		Preferences,
		Graphics,
		Controls
	}

	public static SettingsMenuUI inst;

	[SerializeField]
	private RectTransform rootRectT;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	private float oldMusicVolume;

	private float oldSfxVolume;

	private float oldAmbientVolume;

	private bool oldInvertZoom;

	private bool oldShowClouds;

	private bool oldShowSSAO;

	private bool oldShowPostEffects;

	private bool oldShadows;

	private bool oldBirds;

	private bool oldWaves;

	private bool oldEdgeScroll;

	private bool oldAntiAliasing;

	private bool oldAdvisorNotifications;

	private bool oldVSync;

	private float oldMaxPanningSpeed;

	private float oldZoomSpeed;

	private bool oldFog;

	private float oldFogDistance;

	private float oldUIScale;

	private bool oldVikingDragonTimers;

	private bool oldStreamerMode;

	private bool oldInstancedRendering;

	private bool oldConsoleControls;

	private bool oldPauseOnLoseFocus;

	private bool oldMuteOnLoseFocus;

	private static bool isListeningToKey;

	private static ConfigurableControls.Keybind currKeybind;

	private static int lastKeyboardIndex = 319;

	private const string KeyboardLocalizePrefix = "KeyboardUI_";

	private static bool isUpdatingSettings = false;

	public Slider MusicVolume;

	public Slider SfxVolume;

	public Slider AmbientVolume;

	public Toggle InvertZoom;

	public Toggle ShowClouds;

	public Toggle ShowSSAO;

	public Toggle ShowPostEffects;

	public Toggle Shadows;

	public Toggle Birds;

	public Toggle Waves;

	public Toggle AntiAliasing;

	public Toggle EdgeScroll;

	public Toggle AdvisorNotifications;

	public Toggle VSync;

	public Slider MaxPanningSpeed;

	public Slider ZoomSpeed;

	public Toggle Fog;

	public Slider FogDistance;

	public Slider UIScale;

	public Toggle VikingDragonTimers;

	public Toggle StreamerMode;

	public Toggle InstancedRendering;

	public Toggle ConsoleControls;

	public Toggle PauseOnLoseFocus;

	public Toggle MuteOnLoseFocus;

	public Button changeDifficultyBtn;

	public TextMeshProUGUI difficultyTMP;

	public GameObject changeDifficultyObj;

	public Toggle PreferenceTabs;

	public Toggle GraphicsTab;

	public Toggle KeyboardTab;

	public GameObject consoleUILB;

	public GameObject consoleUIRB;

	public GameObject PreferenceGroup;

	public GameObject GraphicsGroup;

	public GameObject KeyboardGroup;

	public GameObject ConsoleConfirmUI;

	[SerializeField]
	private Button exitBtn;

	public ConsoleUIItem entryItem;

	public ResolutionManager ResolutionManager;

	private bool isVisible;

	private static EventInstance click;

	private bool confirmCheck;

	private SettingsTab currTab;

	[SerializeField]
	private KeybindGroupUI keybindGroupPrefab;

	[SerializeField]
	private KeybindItemUI keybindItemPrefab;

	[SerializeField]
	private RectTransform keybindGroupContainer;

	private Dictionary<string, KeybindGroupUI> groups = new Dictionary<string, KeybindGroupUI>();

	private Dictionary<string, KeybindItemUI> items = new Dictionary<string, KeybindItemUI>();

	private ConfigurableControls.KeyChord keyChord = ConfigurableControls.KeyChord.None;

	private bool anyKeyPressed;

	private Dictionary<int, ConfigurableControls.KeyChord> dirtyKeybinds = new Dictionary<int, ConfigurableControls.KeyChord>();

	private Dictionary<int, ConfigurableControls.KeyChord> modifiedKeybinds = new Dictionary<int, ConfigurableControls.KeyChord>();

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
		MusicVolume.onValueChanged.AddListener(MusicVolumeChanged);
		SfxVolume.onValueChanged.AddListener(SfxVolumeChanged);
		AmbientVolume.onValueChanged.AddListener(AmbientVolumeChanged);
		InvertZoom.onValueChanged.AddListener(InvertZoomChecked);
		ShowClouds.onValueChanged.AddListener(ShowCloudsChecked);
		ShowSSAO.onValueChanged.AddListener(ShowSSAOChecked);
		ShowPostEffects.onValueChanged.AddListener(ShowPostEffectsChecked);
		Shadows.onValueChanged.AddListener(ShadowsChecked);
		Birds.onValueChanged.AddListener(BirdsChecked);
		Waves.onValueChanged.AddListener(WavesChecked);
		AntiAliasing.onValueChanged.AddListener(AntiAliasingChecked);
		EdgeScroll.onValueChanged.AddListener(EdgeScrollChecked);
		AdvisorNotifications.onValueChanged.AddListener(AdvisorNotificationsChecked);
		VSync.onValueChanged.AddListener(VSyncChecked);
		MaxPanningSpeed.onValueChanged.AddListener(MaxPanningSpeedChanged);
		ZoomSpeed.onValueChanged.AddListener(ZoomSpeedChanged);
		Fog.onValueChanged.AddListener(FogChecked);
		FogDistance.onValueChanged.AddListener(FogDistanceChanged);
		UIScale.onValueChanged.AddListener(UIScaleChanged);
		VikingDragonTimers.onValueChanged.AddListener(VikingDragonTimersChecked);
		StreamerMode.onValueChanged.AddListener(StreamerModeChecked);
		InstancedRendering.onValueChanged.AddListener(InstanceRenderingChecked);
		ConsoleControls.onValueChanged.AddListener(ConsoleControlsChecked);
		PauseOnLoseFocus.onValueChanged.AddListener(PauseOnLoseFocusChecked);
		MuteOnLoseFocus.onValueChanged.AddListener(MuteOnLoseFocusChecked);
		changeDifficultyBtn.onClick.AddListener(OnChangeDifficulty);
		exitBtn.onClick.AddListener(RevertChanges);
		PreferenceTabs.onValueChanged.AddListener(ChangePreferenceGroup);
		GraphicsTab.onValueChanged.AddListener(ChangeGraphicsGroup);
		KeyboardTab.onValueChanged.AddListener(ChangeKeyboardGroup);
		Util.SetEnabled(canvas, active: false);
	}

	public void SetVisibility(bool v)
	{
		Util.SetEnabled(canvas, v);
		gRaycaster.enabled = v;
		if (!isVisible & v)
		{
			SfxSystem.PlayUiOpen();
			int index = DifficultyManager.DifficultiesIndexMap[DifficultyManager.inst.difficulty];
			DifficultyManager.DifficultyEntry difficultyEntry = DifficultyManager.Difficulties[index];
			difficultyTMP.text = LocalizationManager.GetTranslation("difficulty_" + difficultyEntry.name) ?? "";
		}
		if (v)
		{
			MusicVolume.value = (oldMusicVolume = Assets.Settings.inst.MasterMusicVolume);
			SfxVolume.value = (oldSfxVolume = Assets.Settings.inst.MasterSfxVolume);
			AmbientVolume.value = (oldAmbientVolume = Assets.Settings.inst.MasterAmbientVolume);
			InvertZoom.isOn = (oldInvertZoom = Assets.Settings.inst.InvertZoom);
			ShowClouds.isOn = (oldShowClouds = Assets.Settings.inst.ShowClouds);
			ShowSSAO.isOn = (oldShowSSAO = Assets.Settings.inst.SSAO);
			ShowPostEffects.isOn = (oldShowPostEffects = Assets.Settings.inst.PostEffects);
			Shadows.isOn = (oldShadows = Assets.Settings.inst.Shadows);
			Birds.isOn = (oldBirds = Assets.Settings.inst.Birds);
			Waves.isOn = (oldWaves = Assets.Settings.inst.Waves);
			EdgeScroll.isOn = (oldEdgeScroll = Assets.Settings.inst.EdgeScroll);
			AntiAliasing.isOn = (oldAntiAliasing = Assets.Settings.inst.AntiAliasing);
			AdvisorNotifications.isOn = (oldAdvisorNotifications = Assets.Settings.inst.AdvisorNotifications);
			VSync.isOn = (oldVSync = Assets.Settings.inst.VSync);
			MaxPanningSpeed.value = (oldMaxPanningSpeed = Assets.Settings.inst.MaxPanningSpeed);
			ZoomSpeed.value = (oldZoomSpeed = Assets.Settings.inst.ZoomSpeed);
			Fog.isOn = (oldFog = Assets.Settings.inst.Fog);
			FogDistance.value = (oldFogDistance = Assets.Settings.inst.FogDistance);
			UIScale.value = (oldUIScale = Assets.Settings.inst.UIScale);
			VikingDragonTimers.isOn = (oldVikingDragonTimers = Assets.Settings.inst.VikingDragonTimers);
			StreamerMode.isOn = (oldStreamerMode = Assets.Settings.inst.StreamerMode);
			InstancedRendering.isOn = (oldInstancedRendering = Assets.Settings.inst.DisableInstancedRendering);
			ConsoleControls.isOn = (oldConsoleControls = Assets.Settings.inst.ConsoleControls);
			PauseOnLoseFocus.isOn = (oldPauseOnLoseFocus = Assets.Settings.inst.PauseOnLoseFocus);
			MuteOnLoseFocus.isOn = (oldMuteOnLoseFocus = Assets.Settings.inst.MuteOnLoseFocus);
			Util.SetActive(changeDifficultyObj, GameState.inst.mainMenuMode.PreviousState != MainMenuMode.State.Menu);
			TryInitKeybinds();
			ResolutionManager.StoreResolutionInfo();
			ConfigurableControls.inst.SetControlsActive(activeIn: false);
			isUpdatingSettings = false;
			OnConsoleUpdate(GamepadControl.inst.isControllerActive);
			GamepadControl gamepadControl = GamepadControl.inst;
			gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(OnConsoleUpdate));
			ActivateInput();
			currTab = SettingsTab.Preferences;
			PreferenceTabs.isOn = true;
			GraphicsTab.isOn = false;
			KeyboardTab.isOn = false;
		}
		else
		{
			GamepadControl gamepadControl2 = GamepadControl.inst;
			gamepadControl2.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(gamepadControl2.controllerUpdate, new GamepadControl.ControllerActivity(OnConsoleUpdate));
			DeactivateInput();
		}
		isVisible = v;
	}

	private static void MusicVolumeChanged(float newVolume)
	{
		Assets.Settings.inst.MasterMusicVolume = newVolume;
		isUpdatingSettings = true;
	}

	private static void SfxVolumeChanged(float newVolume)
	{
		Assets.Settings.inst.MasterSfxVolume = newVolume;
		if (click.isValid() && click.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.STOPPED)
		{
			click = SfxSystem.SFXTestSound();
		}
		isUpdatingSettings = true;
	}

	private static void AmbientVolumeChanged(float newVolume)
	{
		Assets.Settings.inst.MasterAmbientVolume = newVolume;
		isUpdatingSettings = true;
	}

	private static void InvertZoomChecked(bool enabled)
	{
		Assets.Settings.inst.InvertZoom = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void ShowCloudsChecked(bool enabled)
	{
		Assets.Settings.inst.ShowClouds = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void ShowSSAOChecked(bool enabled)
	{
		Assets.Settings.inst.SSAO = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void ShowPostEffectsChecked(bool enabled)
	{
		Assets.Settings.inst.PostEffects = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void ShadowsChecked(bool enabled)
	{
		Assets.Settings.inst.Shadows = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void BirdsChecked(bool enabled)
	{
		Assets.Settings.inst.Birds = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void WavesChecked(bool enabled)
	{
		Assets.Settings.inst.Waves = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void AntiAliasingChecked(bool enabled)
	{
		Assets.Settings.inst.AntiAliasing = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void EdgeScrollChecked(bool enabled)
	{
		Assets.Settings.inst.EdgeScroll = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void AdvisorNotificationsChecked(bool enabled)
	{
		Assets.Settings.inst.AdvisorNotifications = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void VSyncChecked(bool enabled)
	{
		Assets.Settings.inst.VSync = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void FogChecked(bool enabled)
	{
		Assets.Settings.inst.Fog = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void FogDistanceChanged(float newDistance)
	{
		Assets.Settings.inst.FogDistance = newDistance;
		isUpdatingSettings = true;
	}

	private static void VikingDragonTimersChecked(bool enabled)
	{
		Assets.Settings.inst.VikingDragonTimers = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void StreamerModeChecked(bool enabled)
	{
		Assets.Settings.inst.StreamerMode = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void InstanceRenderingChecked(bool enabled)
	{
		Assets.Settings.inst.DisableInstancedRendering = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private void OnChangeDifficulty()
	{
		SetVisibility(v: false);
		DifficultyUI.inst.SetState(1);
		DifficultyUI.inst.SetReturnFunc(() =>
		{
			DifficultyUI.inst.SetVisibility(v: false);
			SetVisibility(v: true);
		});
		DifficultyUI.inst.SetExitFunc(() =>
		{
			DifficultyUI.inst.SetVisibility(v: false);
			SetVisibility(v: true);
		});
		DifficultyUI.inst.SetVisibility(v: true);
	}

	private static void ConsoleControlsChecked(bool enabled)
	{
		Assets.Settings.inst.ConsoleControls = enabled;
		PlayCorrectClick(enabled);
		if (GamepadControl.inst.isControllerActive)
		{
			GamepadControl.inst.PrepForKeyboard();
			GamepadControl.inst.isControllerActive = false;
		}
		isUpdatingSettings = true;
	}

	private static void PauseOnLoseFocusChecked(bool enabled)
	{
		Assets.Settings.inst.PauseOnLoseFocus = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void MuteOnLoseFocusChecked(bool enabled)
	{
		Assets.Settings.inst.MuteOnLoseFocus = enabled;
		PlayCorrectClick(enabled);
		isUpdatingSettings = true;
	}

	private static void MaxPanningSpeedChanged(float newSpeed)
	{
		Assets.Settings.inst.MaxPanningSpeed = newSpeed;
		isUpdatingSettings = true;
	}

	private static void ZoomSpeedChanged(float newSpeed)
	{
		Assets.Settings.inst.ZoomSpeed = newSpeed;
		isUpdatingSettings = true;
	}

	private static void UIScaleChanged(float newScale)
	{
		Assets.Settings.inst.UIScale = newScale;
		isUpdatingSettings = true;
	}

	private static void PlayCorrectClick(bool enabled)
	{
		if (enabled)
		{
			SfxSystem.PlayUiSelect();
		}
		else
		{
			SfxSystem.PlayUiCancel();
		}
	}

	public void SaveChanges()
	{
		foreach (KeyValuePair<int, ConfigurableControls.KeyChord> dirtyKeybind in dirtyKeybinds)
		{
			Assets.Settings.inst.OnModifiedKeybind(dirtyKeybind.Key, dirtyKeybind.Value);
		}
		dirtyKeybinds.Clear();
		Assets.Settings.inst.SaveSettings();
		GameUI.inst.UpdateCanvasScalers();
		GameState.inst.mainMenuMode.OnClickedClose();
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_SelectFromMenu_01");
		ConfigurableControls.inst.SetControlsActive(activeIn: true);
		if (ConsoleConfirmUI.activeSelf)
		{
			ConsoleConfirmUI.SetActive(value: false);
		}
		isUpdatingSettings = false;
		confirmCheck = false;
	}

	public void ReturnToSettings()
	{
		ConsoleConfirmUI.SetActive(value: false);
		confirmCheck = false;
		if (GamepadControl.inst.isControllerActive)
		{
			entryItem.Hover();
		}
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_General Click_01");
	}

	public void RevertChanges()
	{
		if (isUpdatingSettings && !confirmCheck)
		{
			ConsoleConfirmUI.SetActive(value: true);
			confirmCheck = true;
			RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_SelectFromMenu_01");
			return;
		}
		if (ConsoleConfirmUI.activeSelf)
		{
			ConsoleConfirmUI.SetActive(value: false);
		}
		Assets.Settings.inst.MasterMusicVolume = oldMusicVolume;
		Assets.Settings.inst.MasterSfxVolume = oldSfxVolume;
		Assets.Settings.inst.MasterAmbientVolume = oldAmbientVolume;
		Assets.Settings.inst.InvertZoom = oldInvertZoom;
		Assets.Settings.inst.ShowClouds = oldShowClouds;
		Assets.Settings.inst.SSAO = oldShowSSAO;
		Assets.Settings.inst.PostEffects = oldShowPostEffects;
		Assets.Settings.inst.Shadows = oldShadows;
		Assets.Settings.inst.Birds = oldBirds;
		Assets.Settings.inst.Waves = oldWaves;
		Assets.Settings.inst.AntiAliasing = oldAntiAliasing;
		Assets.Settings.inst.EdgeScroll = oldEdgeScroll;
		Assets.Settings.inst.AdvisorNotifications = oldAdvisorNotifications;
		Assets.Settings.inst.VSync = oldVSync;
		Assets.Settings.inst.MaxPanningSpeed = oldMaxPanningSpeed;
		Assets.Settings.inst.ZoomSpeed = oldZoomSpeed;
		Assets.Settings.inst.Fog = oldFog;
		Assets.Settings.inst.FogDistance = oldFogDistance;
		Assets.Settings.inst.UIScale = oldUIScale;
		Assets.Settings.inst.VikingDragonTimers = oldVikingDragonTimers;
		Assets.Settings.inst.StreamerMode = oldStreamerMode;
		Assets.Settings.inst.DisableInstancedRendering = oldInstancedRendering;
		Assets.Settings.inst.ConsoleControls = oldConsoleControls;
		Assets.Settings.inst.PauseOnLoseFocus = oldPauseOnLoseFocus;
		Assets.Settings.inst.MuteOnLoseFocus = oldMuteOnLoseFocus;
		foreach (KeyValuePair<int, ConfigurableControls.KeyChord> dirtyKeybind in dirtyKeybinds)
		{
			ConfigurableControls.Keybind keyAction = ConfigurableControls.inst.GetKeyAction(dirtyKeybind.Key);
			if (keyAction.itemUI != null)
			{
				keyAction.itemUI.input.SetTextWithoutNotify(keyAction.ToString());
			}
		}
		dirtyKeybinds.Clear();
		GameState.inst.mainMenuMode.OnClickedClose();
		ResolutionManager.RestoreResolutionInfo();
		SfxSystem.PlayUiCancel();
		ConfigurableControls.inst.SetControlsActive(activeIn: true);
		isUpdatingSettings = false;
		confirmCheck = false;
	}

	public void OnReturnToDefaults()
	{
		if (PreferenceGroup.activeSelf)
		{
			Assets.Settings.inst.SetDefaultPreferences();
		}
		if (GraphicsGroup.activeSelf)
		{
			Assets.Settings.inst.SetDefaultGraphics();
		}
		if (KeyboardGroup.activeSelf)
		{
			ResetKeyboardMenuOptions();
		}
		MusicVolume.value = Assets.Settings.inst.MasterMusicVolume;
		SfxVolume.value = Assets.Settings.inst.MasterSfxVolume;
		AmbientVolume.value = Assets.Settings.inst.MasterAmbientVolume;
		InvertZoom.isOn = Assets.Settings.inst.InvertZoom;
		ShowClouds.isOn = Assets.Settings.inst.ShowClouds;
		ShowSSAO.isOn = Assets.Settings.inst.SSAO;
		ShowPostEffects.isOn = Assets.Settings.inst.PostEffects;
		Shadows.isOn = Assets.Settings.inst.Shadows;
		Birds.isOn = Assets.Settings.inst.Birds;
		Waves.isOn = Assets.Settings.inst.Waves;
		EdgeScroll.isOn = Assets.Settings.inst.EdgeScroll;
		AntiAliasing.isOn = Assets.Settings.inst.AntiAliasing;
		AdvisorNotifications.isOn = Assets.Settings.inst.AdvisorNotifications;
		VSync.isOn = Assets.Settings.inst.VSync;
		MaxPanningSpeed.value = Assets.Settings.inst.MaxPanningSpeed;
		ZoomSpeed.value = Assets.Settings.inst.ZoomSpeed;
		Fog.isOn = Assets.Settings.inst.Fog;
		FogDistance.value = Assets.Settings.inst.FogDistance;
		UIScale.value = Assets.Settings.inst.UIScale;
		VikingDragonTimers.isOn = Assets.Settings.inst.VikingDragonTimers;
		StreamerMode.isOn = Assets.Settings.inst.StreamerMode;
		InstancedRendering.isOn = Assets.Settings.inst.DisableInstancedRendering;
		ConsoleControls.isOn = Assets.Settings.inst.ConsoleControls;
		PauseOnLoseFocus.isOn = Assets.Settings.inst.PauseOnLoseFocus;
		MuteOnLoseFocus.isOn = Assets.Settings.inst.MuteOnLoseFocus;
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_Confirm_01");
	}

	private void ChangePreferenceGroup(bool active)
	{
		if (active)
		{
			PreferenceGroup.SetActive(value: true);
			GraphicsGroup.SetActive(value: false);
			KeyboardGroup.SetActive(value: false);
			SfxSystem.PlayUiSelect();
		}
	}

	private void ChangeGraphicsGroup(bool active)
	{
		if (active)
		{
			GraphicsGroup.SetActive(value: true);
			PreferenceGroup.SetActive(value: false);
			KeyboardGroup.SetActive(value: false);
			SfxSystem.PlayUiSelect();
		}
	}

	private void ChangeKeyboardGroup(bool active)
	{
		if (active)
		{
			KeyboardGroup.SetActive(value: true);
			PreferenceGroup.SetActive(value: false);
			GraphicsGroup.SetActive(value: false);
			SfxSystem.PlayUiSelect();
		}
	}

	public void OnConsoleUpdate(bool isControllerActive)
	{
		consoleUIRB.SetActive(isControllerActive);
		consoleUILB.SetActive(isControllerActive);
	}

	public void ActivateInput()
	{
		GamepadControl.inst.UILeftBumperInput += PrevTab;
		GamepadControl.inst.UIRightBumperInput += NextTab;
	}

	public void DeactivateInput()
	{
		GamepadControl.inst.UILeftBumperInput -= PrevTab;
		GamepadControl.inst.UIRightBumperInput -= NextTab;
	}

	public void NextTab()
	{
		currTab = (SettingsTab)((int)(currTab + 1) % 2);
		SwitchToTab(currTab);
	}

	public void PrevTab()
	{
		int num = (int)currTab;
		if (num == 0)
		{
			currTab = SettingsTab.Graphics;
		}
		else
		{
			currTab = (SettingsTab)(num - 1);
		}
		SwitchToTab(currTab);
	}

	private void SwitchToTab(SettingsTab tab)
	{
		switch (tab)
		{
		case SettingsTab.Preferences:
			PreferenceTabs.isOn = true;
			break;
		case SettingsTab.Graphics:
			GraphicsTab.isOn = true;
			break;
		}
	}

	public void TryInitKeybinds()
	{
		isListeningToKey = false;
		foreach (KeyValuePair<int, ConfigurableControls.Keybind> kv in ConfigurableControls.inst.keybinds)
		{
			KeybindGroupUI value = null;
			ConfigurableControls.Keybind value2 = kv.Value;
			if (!groups.TryGetValue(kv.Value.groupName, out value))
			{
				value = UnityEngine.Object.Instantiate(keybindGroupPrefab, keybindGroupContainer, worldPositionStays: false);
				value.titleLoc.Term = "settingsui_keybind_group_" + kv.Value.groupName;
				value2.groupUI = value;
				groups.Add(kv.Value.groupName, value);
			}
			if (items.ContainsKey(kv.Value.name))
			{
				continue;
			}
			KeybindItemUI itemUI = UnityEngine.Object.Instantiate(keybindItemPrefab, value.itemContainer, worldPositionStays: false);
			itemUI.titleLoc.Term = "settingsui_keybind_name_" + value2.name;
			itemUI.input.SetTextWithoutNotify(value2.ToString());
			itemUI.input.onSelect.AddListener((string text) =>
			{
				if (currKeybind != null && currKeybind.id != kv.Value.id)
				{
					currKeybind.itemUI.input.onDeselect.Invoke(null);
				}
				isListeningToKey = true;
				currKeybind = kv.Value;
				keyChord = ConfigurableControls.KeyChord.None;
				Util.SetEnabled(itemUI.highlightRI, active: true);
			});
			itemUI.input.onDeselect.AddListener((string text) =>
			{
				isListeningToKey = false;
				Util.SetEnabled(itemUI.highlightRI, active: false);
			});
			value2.itemUI = itemUI;
			items.Add(value2.name, itemUI);
		}
	}

	private void Update()
	{
		if (!isVisible)
		{
			return;
		}
		if (GameUI.IsOnConsole())
		{
			EdgeScroll.gameObject.SetActive(value: false);
			KeyboardTab.gameObject.SetActive(value: false);
			StreamerMode.gameObject.SetActive(value: false);
		}
		if (!isListeningToKey)
		{
			return;
		}
		bool flag = true;
		if (!keyChord.ctrl && !keyChord.shift && !keyChord.alt)
		{
			for (int i = 0; i < lastKeyboardIndex; i++)
			{
				KeyCode key = (KeyCode)i;
				if (Input.GetKey(key))
				{
					keyChord.key = key;
				}
			}
		}
		for (int j = 0; j < lastKeyboardIndex; j++)
		{
			KeyCode keyCode = (KeyCode)j;
			if (Input.GetKey(keyCode))
			{
				switch (keyCode)
				{
				case KeyCode.RightControl:
				case KeyCode.LeftControl:
					keyChord.ctrl = true;
					break;
				case KeyCode.RightAlt:
				case KeyCode.LeftAlt:
					keyChord.alt = true;
					break;
				case KeyCode.RightShift:
				case KeyCode.LeftShift:
					keyChord.shift = true;
					break;
				default:
					keyChord.key = keyCode;
					break;
				case KeyCode.None:
					break;
				}
				flag = false;
				anyKeyPressed = true;
			}
		}
		if (keyChord.key == KeyCode.LeftControl || keyChord.key == KeyCode.RightControl)
		{
			keyChord.ctrl = false;
		}
		if (keyChord.key == KeyCode.LeftAlt || keyChord.key == KeyCode.RightAlt)
		{
			keyChord.alt = false;
		}
		if (keyChord.key == KeyCode.LeftShift || keyChord.key == KeyCode.RightShift)
		{
			keyChord.shift = false;
		}
		if (flag && anyKeyPressed)
		{
			anyKeyPressed = false;
			isListeningToKey = false;
			EventSystem.current.SetSelectedGameObject(null);
			SetKeybind(currKeybind, keyChord);
			currKeybind = null;
		}
	}

	public void SetKeybind(ConfigurableControls.Keybind keybind, ConfigurableControls.KeyChord keyChord)
	{
		ConfigurableControls.KeyChord keyChord2 = (dirtyKeybinds.ContainsKey(keybind.id) ? dirtyKeybinds[keybind.id] : ConfigurableControls.inst.keybinds[keybind.id].keychord);
		if (keyChord2 == keyChord)
		{
			return;
		}
		isUpdatingSettings = true;
		if (!dirtyKeybinds.TryAdd(keybind.id, keyChord))
		{
			dirtyKeybinds[keybind.id] = keyChord;
		}
		keybind.itemUI.input.SetTextWithoutNotify(keyChord.ToString());
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_Confirm_01");
		foreach (KeyValuePair<int, ConfigurableControls.KeyChord> dirtyKeybind in dirtyKeybinds)
		{
			if (dirtyKeybind.Key != keybind.id && dirtyKeybind.Value == keyChord)
			{
				dirtyKeybinds[dirtyKeybind.Key] = keyChord2;
				ConfigurableControls.inst.keybinds[dirtyKeybind.Key].itemUI.input.SetTextWithoutNotify(keyChord2.ToString());
				return;
			}
		}
		foreach (KeyValuePair<int, ConfigurableControls.Keybind> keybind2 in ConfigurableControls.inst.keybinds)
		{
			if (keybind2.Key != keybind.id && keybind2.Value.keychord == keyChord)
			{
				if (!dirtyKeybinds.TryAdd(keybind2.Key, keyChord2))
				{
					dirtyKeybinds[keybind2.Key] = keyChord2;
				}
				ConfigurableControls.inst.keybinds[keybind2.Key].itemUI.input.SetTextWithoutNotify(keyChord2.ToString());
				break;
			}
		}
	}

	public void ResetKeyboardMenuOptions()
	{
		isUpdatingSettings = Assets.Settings.inst.modifiedKeybinds.Count > 0;
		isListeningToKey = false;
		currKeybind = null;
		foreach (KeyValuePair<int, ConfigurableControls.KeyChord> dirtyKeybind in dirtyKeybinds)
		{
			ConfigurableControls.Keybind keyAction = ConfigurableControls.inst.GetKeyAction(dirtyKeybind.Key);
			if (keyAction.itemUI != null)
			{
				keyAction.itemUI.input.SetTextWithoutNotify(keyAction.ToString());
			}
		}
		dirtyKeybinds.Clear();
		foreach (KeyValuePair<int, ConfigurableControls.KeyChord> modifiedKeybind in Assets.Settings.inst.modifiedKeybinds)
		{
			ConfigurableControls.KeyChord originalKeybind = ConfigurableControls.inst.GetOriginalKeybind(modifiedKeybind.Key);
			ConfigurableControls.Keybind keyAction2 = ConfigurableControls.inst.GetKeyAction(modifiedKeybind.Key);
			if (keyAction2.itemUI != null)
			{
				keyAction2.itemUI.input.SetTextWithoutNotify(originalKeybind.ToString());
			}
			dirtyKeybinds.Add(modifiedKeybind.Key, originalKeybind);
		}
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_Cancel_01");
	}
}
