using Assets.Code.UI;
using UnityEngine;

namespace Assets.Code;

internal class KeyboardControl : MonoBehaviour
{
	public static KeyboardControl inst;

	public float translationSpeedSlowest = 25f;

	public float translationSpeedFastest = 50f;

	public float translationSpeedShiftBoost = 50f;

	private float translationSpeed;

	private float translationAcceleration;

	private float rotationSpeed;

	private float rotationSpeedNormal = 75f;

	private float rotationSpeedFast = 125f;

	private float zoomSpeed;

	private float zoomSpeedNormal = 10f;

	private float zoomSpeedFast = 20f;

	public IKeyboardInputOverride inputOverride;

	private void Awake()
	{
		inst = this;
	}

	private void Update()
	{
		if (!GameState.inst.AlphaNumericHotkeysEnabled)
		{
			return;
		}
		if (inputOverride != null && !inputOverride.Equals(null))
		{
			inputOverride.UpdateKeyboardInput();
			return;
		}
		UpdateCameraKeys();
		if (GameState.inst.CurrMode == GameState.inst.playingMode)
		{
			UpdatePlaymodeKeys();
		}
		else if (GameState.inst.CurrMode == GameState.inst.mainMenuMode)
		{
			UpdateMainMenuKeys();
		}
	}

	private void UpdateCameraKeys()
	{
		bool inputActionKey = ConfigurableControls.inst.GetInputActionKey(104);
		bool flag = false;
		translationSpeed = ((inputActionKey ? translationSpeedShiftBoost : 0f) + Mathf.Lerp(translationSpeedSlowest, translationSpeedFastest, Settings.inst.MaxPanningSpeed)) * translationAcceleration;
		rotationSpeed = (inputActionKey ? rotationSpeedFast : rotationSpeedNormal);
		zoomSpeed = (inputActionKey ? zoomSpeedFast : zoomSpeedNormal);
		if (ConfigurableControls.inst.GetInputActionKey(105, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			Cam.inst.Rotate(Time.unscaledDeltaTime * (0f - rotationSpeed), 0f);
		}
		if (ConfigurableControls.inst.GetInputActionKey(106, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			Cam.inst.Rotate(Time.unscaledDeltaTime * rotationSpeed, 0f);
		}
		if (ConfigurableControls.inst.GetInputActionKey(109, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			Cam.inst.Rotate(0f, Time.unscaledDeltaTime * (rotationSpeed * 0.5f));
		}
		if (ConfigurableControls.inst.GetInputActionKey(110, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			Cam.inst.Rotate(0f, Time.unscaledDeltaTime * (0f - rotationSpeed * 0.5f));
		}
		if (ConfigurableControls.inst.GetInputActionKey(100, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true) || Input.GetKey(KeyCode.UpArrow))
		{
			flag = true;
			Cam.inst.MoveForward(Time.unscaledDeltaTime * translationSpeed);
		}
		if (ConfigurableControls.inst.GetInputActionKey(101, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true) || Input.GetKey(KeyCode.DownArrow))
		{
			flag = true;
			Cam.inst.MoveForward(Time.unscaledDeltaTime * (0f - translationSpeed));
		}
		if (ConfigurableControls.inst.GetInputActionKey(102, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true) || Input.GetKey(KeyCode.LeftArrow))
		{
			flag = true;
			Cam.inst.MoveRight(Time.unscaledDeltaTime * (0f - translationSpeed));
		}
		if (ConfigurableControls.inst.GetInputActionKey(103, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true) || Input.GetKey(KeyCode.RightArrow))
		{
			flag = true;
			Cam.inst.MoveRight(Time.unscaledDeltaTime * translationSpeed);
		}
		if (ConfigurableControls.inst.GetInputActionKey(108, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			Cam.inst.Zoom(Time.unscaledDeltaTime * zoomSpeed);
		}
		if (ConfigurableControls.inst.GetInputActionKey(107, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			Cam.inst.Zoom(Time.unscaledDeltaTime * (0f - zoomSpeed));
		}
		if (flag)
		{
			translationAcceleration = Mathf.Clamp01(translationAcceleration + Time.unscaledDeltaTime * 6f);
		}
		else
		{
			translationAcceleration = 0f;
		}
	}

	private void UpdatePlaymodeKeys()
	{
		if (!Input.GetKey(KeyCode.Pause))
		{
			if (ConfigurableControls.inst.GetInputActionKeyDown(200))
			{
				if (TimeManager.inst.IsPaused())
				{
					TimeManager.inst.ReturnToPrevious();
				}
				else
				{
					TimeManager.inst.SetPaused();
				}
			}
			if (!Input.GetKeyDown(KeyCode.LeftControl))
			{
				if (ConfigurableControls.inst.GetInputActionKeyDown(201))
				{
					TimeManager.inst.SetPlay1();
				}
				if (ConfigurableControls.inst.GetInputActionKeyDown(202))
				{
					TimeManager.inst.SetPlay2();
				}
				if (ConfigurableControls.inst.GetInputActionKeyDown(203))
				{
					TimeManager.inst.SetPlay3();
				}
			}
		}
		if (ConfigurableControls.inst.GetInputActionKeyDown(901))
		{
			SetGameUIVisibility(!GameUI.inst.gameObject.activeInHierarchy);
		}
		if (ConfigurableControls.inst.GetInputActionKeyDownAndConsume(903) && !GameUI.inst.InModal() && GameUI.inst.gameObject.activeInHierarchy && (TechnologyTree.inst.IsVisible() || ProsperityUI.inst.IsTechnologyUnlocked()))
		{
			TechnologyTree.inst.ToggleVisibility();
		}
		if (CursorModeUI.inst.IsVisible() && !GameUI.inst.InModal())
		{
			if (ConfigurableControls.inst.GetInputActionKeyDown(300))
			{
				GameUI.inst.SetCursorModeChop();
			}
			else if (ConfigurableControls.inst.GetInputActionKeyDown(301))
			{
				GameUI.inst.SetCursorModeChopCancel();
			}
			else if (ConfigurableControls.inst.GetInputActionKeyDown(302) && TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_terrainengineering"))
			{
				EditTerrainUI.inst.SetVisible(v: true);
			}
			else if (!GameUI.inst.CurrPlacementMode.IsPlacing() && !GameUI.inst.workerUI.rubbleUI.IsVisible() && ConfigurableControls.inst.GetInputActionKeyDown(303) && (CursorModeUI.inst.RebuildButton.btn.interactable || GameUI.inst.currCursorMode == GameUI.inst.rebuildCursorMode))
			{
				GameUI.inst.SetCursorModeRebuild();
			}
			else if (!GameUI.inst.workerUI.Visible && !ConstructUI.inst.IsVisible() && ConfigurableControls.inst.GetInputActionKeyDown(304))
			{
				GameUI.inst.SetCursorModeDemolish();
			}
			else if (ConfigurableControls.inst.GetInputActionKeyDown(305))
			{
				GameUI.inst.SetCursorModeSample();
			}
		}
		if (ConfigurableControls.inst.GetInputActionKeyDown(900) && !PhotoMode.IsActive() && !Cinematics.inst.IsCinematicRunning())
		{
			OnEscape();
		}
		if (ConfigurableControls.inst.GetInputActionKeyDown(902))
		{
			DecreeUI.inst.ToggleVisibility();
		}
		if (Input.GetKeyDown(KeyCode.R))
		{
			GameUI.inst.TryRotateHeldBuilding();
		}
		if (Input.GetKeyDown(KeyCode.C) && (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl)) && Player.inst.CheatsEnabled)
		{
			Creative.inst.SetEnabled(!Creative.inst.IsEnabled());
		}
	}

	private void OnEscape()
	{
		if (HandleEscape())
		{
			GameState.inst.playingMode.OnClickedMenu();
		}
	}

	public bool HandleEscape(bool forceClose = false)
	{
		if (QuickSaveLoadUI.inst.IsVisible())
		{
			QuickSaveLoadUI.inst.SetVisiblity(v: false);
		}
		else if (GameUI.inst.DamPlannerCursorModeActive())
		{
			if (forceClose)
			{
				DamPlannerUI.inst.CloseConfirmed();
			}
			else if (!DamPlannerUI.inst.closeConfirmation.gameObject.activeSelf)
			{
				DamPlannerUI.inst.AskToClose();
			}
			else
			{
				DamPlannerUI.inst.closeConfirmation.Reset();
				DamPlannerUI.inst.CloseCancelled();
			}
		}
		else if (GameUI.inst.EditTerrainCursorModeActive())
		{
			if (forceClose)
			{
				EditTerrainUI.inst.CloseConfirmed();
			}
			else if (!EditTerrainUI.inst.closeConfirmation.gameObject.activeSelf)
			{
				EditTerrainUI.inst.AskToClose();
			}
			else
			{
				EditTerrainUI.inst.closeConfirmation.Reset();
				EditTerrainUI.inst.CloseCancelled();
			}
		}
		else if (CreativeUI.inst.activeBrush != null)
		{
			CreativeUI.inst.SetBrushNone();
		}
		else if (CreativeUI.inst.IsWindowVisible())
		{
			CreativeUI.inst.SetWindowVisibility(v: false);
		}
		else if (GameUI.inst.demolishWarningUI.gameObject.activeSelf)
		{
			GameUI.inst.demolishWarningUI.ExitUI();
		}
		else if (HealthUI.inst.overlayOn)
		{
			HealthUI.inst.HideOverlay();
		}
		else if (HappinessUI.inst.overlayOn)
		{
			HappinessUI.inst.HideOverlay();
		}
		else if (IntegrityUI.inst.overlayOn)
		{
			IntegrityUI.inst.HideOverlay();
		}
		else if (SettlerShipUI.inst.IsVisible())
		{
			SettlerShipUI.inst.SetVisibility(v: false);
		}
		else if (EffectBanner.inst.Showing())
		{
			EffectBanner.inst.DismissBanner();
		}
		else if (AdvisorUI.inst.IsVisible())
		{
			AdvisorUI.inst.Hide();
		}
		else if (GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			GameUI.inst.CurrPlacementMode.CancelWaitToPlace();
			GameUI.inst.AbortCursorObjPlacement();
			GameUI.inst.ReturnToDefaultCursorMode();
		}
		else if (!GameUI.inst.gameObject.activeInHierarchy && GameState.inst.CurrMode == GameState.inst.playingMode)
		{
			GameUI.inst.gameObject.SetActive(value: true);
			ThoughtBubbleSystem.inst.disableUI = false;
			MiniMapUI.inst.SetVisibility(v: true);
		}
		else if (GameUI.inst.currCursorMode != null)
		{
			GameUI.inst.ReturnToDefaultCursorMode();
		}
		else if (GameUI.inst.UIShowing())
		{
			GameUI.inst.ClearCellSelected();
		}
		else if (GameUI.inst.personUI.gameObject.activeSelf)
		{
			GameUI.inst.personUI.Close();
		}
		else if (BuildUI.inst.IsGroupActive())
		{
			BuildUI.inst.HideGroups();
		}
		else if (DecreeUI.inst.IsVisible())
		{
			DecreeUI.inst.SetVisibility(v: false);
		}
		else if (GameUI.inst.diplomacyUI.gameObject.activeInHierarchy)
		{
			GameUI.inst.diplomacyUI.ReturnToMenuConvo();
			GameUI.inst.diplomacyUI.gameObject.SetActive(value: false);
		}
		else if (ProsperityUI.inst.isTasksVisible)
		{
			ProsperityUI.inst.SetMissionVisibility(v: false);
		}
		else if (MilestoneUI.inst.IsVisible())
		{
			MilestoneUI.inst.SetVisibility(v: false);
		}
		else
		{
			if (!TechnologyTree.inst.IsVisible())
			{
				return true;
			}
			TechnologyTree.inst.SetVisibility(v: false);
		}
		return false;
	}

	private void UpdateMainMenuKeys()
	{
		MainMenuMode.State state = GameState.inst.mainMenuMode.GetState();
		if (ConfigurableControls.inst.GetInputActionKeyDown(900))
		{
			switch (state)
			{
			case MainMenuMode.State.PauseMenu:
				GameState.inst.mainMenuMode.OnClickedReturnToGame();
				break;
			case MainMenuMode.State.SettingsMenu:
				GameState.inst.mainMenuMode.settingsUI.RevertChanges();
				break;
			case MainMenuMode.State.Load:
				SaveLoadUI.inst.OnEscapePressed();
				break;
			}
		}
	}

	public void SetGameUIVisibility(bool visible)
	{
		bool flag = !visible;
		GameUI.inst.gameObject.SetActive(visible);
		ThoughtBubbleSystem.inst.disableUI = flag;
		MiniMapUI.inst.SetVisibility(visible);
		InWorldExclamation.hideForScreenshots = flag;
		if (PhotoMode.IsActive())
		{
			Util.SetEnabled(PhotoMode.inst.GetComponent<Canvas>(), visible);
		}
	}
}
