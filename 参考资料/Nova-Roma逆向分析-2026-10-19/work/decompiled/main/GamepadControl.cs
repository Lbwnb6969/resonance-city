using System;
using I2.Loc;
using Rewired;
using Steamworks;
using UnityEngine;
using UnityEngine.EventSystems;

public class GamepadControl : MonoBehaviour
{
	public delegate void ControllerActivity(bool isContollerActive);

	public delegate void UIInput();

	public static GamepadControl inst;

	public Rewired.Player player;

	public bool isControllerActive;

	private bool tempIsControllerActive;

	public float rotationSpeed;

	public float zoomSpeed = 10f;

	private Timer isMovingTimer = new Timer(0.5f);

	private bool demolishing;

	private Timer demolishTimer = new Timer(0.75f);

	private RaycastHit[] scratchHitResults = new RaycastHit[32];

	private BuildingCollider bCollider;

	private float waveIdx;

	private float waveAmplitude = 10f;

	private Timer holdDuration = new Timer(1f);

	private float holdAcceleration = 1f;

	public float holdAccelerationStep = 0.1f;

	public float holdAccelerationMax = 50f;

	public float logScrollSpeed = 1f;

	public bool debugMode;

	public GameObject nextSelected;

	private IPointer defaultMousePointer;

	private IPointer defaultConsolePointer;

	public AnimationCurve speedCurve;

	public AnimationCurve distSpeedCurve;

	public ControllerActivity controllerUpdate;

	internal bool ignoreInputThisFrame;

	[NonSerialized]
	public bool UINavigationBypass;

	private Vector3 startCamPos;

	private Vector2 maxStickInput;

	private bool moving;

	private float flickTime;

	private float leftX;

	private float leftY;

	private float rightX;

	private float rightY;

	private float distModifier = 1f;

	private float flickClamp = 0.65f;

	private float flickThresholdTime = 0.125f;

	private Vector3[] dirs = new Vector3[4]
	{
		new Vector3(1f, 0f, 0f).normalized,
		new Vector3(-1f, 0f, 0f).normalized,
		new Vector3(0f, 0f, 1f).normalized,
		new Vector3(0f, 0f, -1f).normalized
	};

	private bool overheadViewMode;

	public GameObject CurrentSelected { get; internal set; }

	public event UIInput UIVerticalInput;

	public event UIInput UIVerticalNegativeInput;

	public event UIInput UIHorizontalInput;

	public event UIInput UIHorizontalNegativeInput;

	public event UIInput UISubmitInput;

	public event UIInput UICancelInput;

	public event UIInput UIYInput;

	public event UIInput UIXInput;

	public event UIInput UILeftBumperInput;

	public event UIInput UIRightBumperInput;

	public bool IsNavigatingUI()
	{
		return CurrentSelected != null;
	}

	private void Awake()
	{
		inst = this;
		player = ReInput.players.GetPlayer(0);
		ResetHoldSettings();
	}

	private void Start()
	{
		CurrentSelected = null;
		nextSelected = null;
		for (int i = 0; i < player.controllers.Joysticks.Count; i++)
		{
			Debug.Log(player.controllers.Joysticks[i].hardwareTypeGuid);
		}
		defaultMousePointer = PointingSystem.GetPointer();
		defaultConsolePointer = new ConsolePointer();
		PrepForKeyboard();
	}

	private void OnControllerConnected(ControllerStatusChangedEventArgs args)
	{
	}

	private void OnControllerDisconnected(ControllerStatusChangedEventArgs args)
	{
		if (isControllerActive && (player.controllers.joystickCount == 0 || ReInput.controllers.GetLastActiveController() == args.controller))
		{
			PrepForKeyboard();
		}
		isControllerActive = false;
	}

	public static string GetPlatformLocalization(string pcTerm, string consoleTerm)
	{
		return LocalizationManager.GetTranslation(inst.isControllerActive ? consoleTerm : pcTerm);
	}

	public void PrepForKeyboard()
	{
		PointingSystem.ReplacePointer(defaultMousePointer);
		GameUI.inst.DockWorkerUI();
		GameUI.inst.DockConstructionUI();
		GameUI.inst.vignetteController.SetVisible(v: false);
		ConsoleBuildMenu.inst.PrepForKeyboard();
		ConsoleCursorMenu.inst.PrepForKeyboard();
		GameUI.inst.workerUI.UpdateConsoleUI(isControllerActive: false);
		GameUI.inst.advisorCanvas.GetComponent<AdvisorUI>().UpdateConsoleUI(isControllerActive: false);
		ConsoleTileUI.inst.SetVisible(v: false);
		CurrentSelected = null;
		nextSelected = null;
		Cam.inst.posSmoothDampTime = Cam.inst.posSmoothDampTimeDefault;
		EventSystem.current.SetSelectedGameObject(null);
	}

	public void PrepForGamepad()
	{
		PointingSystem.ReplacePointer(defaultConsolePointer);
		GameUI.inst.UndockWorkerUI();
		GameUI.inst.UndockConstructionUI();
		CurrentSelected = null;
		nextSelected = null;
		ConsoleBuildMenu.inst.PrepForGamepad();
		ConsoleCursorMenu.inst.PrepForGamepad();
		GameUI.inst.workerUI.UpdateConsoleUI(isControllerActive: true);
		GameUI.inst.advisorCanvas.GetComponent<AdvisorUI>().UpdateConsoleUI(isControllerActive: true);
		if (GameState.inst.CurrMode == GameState.inst.playingMode)
		{
			GameUI.inst.diplomacyUI.PrepForGamepad();
			GameUI.inst.workerUI.SetVisible(v: false);
			DecreeUI.inst.SetVisibility(v: false);
			AdvisorUI.inst.Hide();
		}
		else
		{
			if (!(GameState.inst.CurrMode == GameState.inst.mainMenuMode))
			{
				return;
			}
			MainMenuMode mainMenuMode = GameState.inst.mainMenuMode;
			switch (mainMenuMode.GetState())
			{
			case MainMenuMode.State.PauseMenu:
				mainMenuMode.pauseMenuUICanvas.GetComponent<ConsoleUIItem>().Hover();
				break;
			case MainMenuMode.State.QuitConfirm:
				mainMenuMode.quitConfirmation.GetComponent<ConsoleUIItem>().Hover();
				break;
			case MainMenuMode.State.Menu:
				mainMenuMode.topLevelUI.GetComponent<ConsoleUIItem>().Hover();
				break;
			case MainMenuMode.State.ChooseMode:
				mainMenuMode.chooseModeUI.GetComponent<ConsoleUIItem>().Hover();
				break;
			case MainMenuMode.State.GameWorkshopUI:
				mainMenuMode.gameWorkshopUI.GetComponent<ConsoleUIItem>().Hover();
				break;
			case MainMenuMode.State.NewMap:
			{
				NewMapUI component2 = mainMenuMode.newMapUI.GetComponent<NewMapUI>();
				if (component2.InEditMode)
				{
					component2.MapEditContainer.GetComponent<ConsoleUIItem>().Hover();
				}
				else if (component2.confirmButtonContainer.activeInHierarchy)
				{
					component2.confirmButtonContainer.GetComponent<ConsoleUIItem>().Hover();
				}
				else
				{
					component2.NewMapSettingsContainer.GetComponent<ConsoleUIItem>().Hover();
				}
				break;
			}
			case MainMenuMode.State.NameAndBanner:
				if (mainMenuMode.chooseBannerUI.activeInHierarchy)
				{
					ChooseBannerUI component = mainMenuMode.chooseBannerUI.GetComponent<ChooseBannerUI>();
					component.Show(component.pickNameUI.GetComponent<ConsoleUIItem>());
				}
				else
				{
					mainMenuMode.pickNameUI.GetComponent<ConsoleUIItem>().Hover();
				}
				break;
			case MainMenuMode.State.BannerSelect:
				mainMenuMode.chooseBannerUI.GetComponent<ChooseBannerUI>().Show(GameUI.inst.workerUI.GetComponent<ConsoleUIItem>());
				break;
			case MainMenuMode.State.SettingsMenu:
				mainMenuMode.settingsUI.entryItem?.Hover();
				break;
			case MainMenuMode.State.Save:
			case MainMenuMode.State.Load:
				mainMenuMode.saveLoadUI.GetComponent<ConsoleUIItem>().Hover();
				break;
			case MainMenuMode.State.Credits:
				mainMenuMode.creditsUI.GetComponent<CreditsUI>().backButton.GetComponent<ConsoleUIItem>().Hover();
				break;
			}
		}
	}

	private void Update()
	{
		if (player.controllers.joystickCount <= 0)
		{
			return;
		}
		Controller lastActiveController = ReInput.controllers.GetLastActiveController();
		if (lastActiveController != null)
		{
			if (!debugMode || !tempIsControllerActive)
			{
				if (lastActiveController.type == ControllerType.Joystick && !tempIsControllerActive)
				{
					tempIsControllerActive = true;
					ignoreInputThisFrame = true;
				}
				else if ((lastActiveController.type == ControllerType.Keyboard || lastActiveController.type == ControllerType.Mouse) && tempIsControllerActive)
				{
					tempIsControllerActive = false;
				}
			}
			if (ignoreInputThisFrame && ((CurrentSelected == null && nextSelected == null) || (lastActiveController.type == ControllerType.Joystick && ReInput.time.unscaledTime - lastActiveController.GetLastTimeActive() > 0.08500000089406967)))
			{
				ignoreInputThisFrame = false;
			}
		}
		if (tempIsControllerActive && !ignoreInputThisFrame)
		{
			UpdateCameraJoystick();
		}
	}

	private void UpdateMainMenuButtons()
	{
	}

	public void FocusCreativeMode()
	{
	}

	public void FocusIslandInfo()
	{
		GameUI.inst.ClearUIForClick();
		if (GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			GameUI.inst.AbortCursorObjPlacement();
		}
		ConsoleTileUI.inst.SetVisible(v: false);
		IslandInfoContainer islandInfoUI = GameUI.inst.islandInfoUI;
		ForeignIslandInfoContainer foreignIslandInfoUI = GameUI.inst.foreignIslandInfoUI;
		if (islandInfoUI.isShowing && !islandInfoUI.consoleItemEntry.isHovered)
		{
			islandInfoUI.deferGamepadToggle = true;
			islandInfoUI.consoleItemEntry.Hover();
			islandInfoUI.GetComponent<UIScaleBump>().Activate();
		}
		else if (foreignIslandInfoUI.isShowing && !foreignIslandInfoUI.consoleItemEntry.isHovered)
		{
			foreignIslandInfoUI.deferGamepadToggle = true;
			foreignIslandInfoUI.consoleItemEntry.Hover();
			foreignIslandInfoUI.GetComponent<UIScaleBump>().Activate();
		}
	}

	public void FocusBuildMenu()
	{
		if (!GameUI.inst.IsUnitSelected())
		{
			GameUI.inst.ClearSelection();
			if (GameUI.inst.CurrPlacementMode.IsPlacing())
			{
				GameUI.inst.AbortCursorObjPlacement();
			}
			ConsoleBuildMenu.inst.SelectMenu();
		}
	}

	public static void DoGameUINavigation(ConsoleUIItem consoleItemEntry)
	{
		if (consoleItemEntry.isHovered)
		{
			if ((consoleItemEntry == GameUI.inst.islandInfoUI.consoleItemEntry || consoleItemEntry == GameUI.inst.foreignIslandInfoUI.consoleItemEntry) && inst.player.GetButtonDown("RT") && Creative.inst.IsEnabled())
			{
				consoleItemEntry.Reset();
				inst.FocusCreativeMode();
			}
			if (consoleItemEntry == GameUI.inst.islandInfoUI.consoleItemEntry && (inst.player.GetButtonDown("LT") || inst.player.GetButtonDown("B")) && !GameUI.inst.islandInfoUI.deferGamepadToggle)
			{
				consoleItemEntry.Cancel();
			}
			if (consoleItemEntry == GameUI.inst.foreignIslandInfoUI.consoleItemEntry && (inst.player.GetButtonDown("LT") || inst.player.GetButtonDown("B")) && !GameUI.inst.foreignIslandInfoUI.deferGamepadToggle)
			{
				consoleItemEntry.Cancel();
			}
			if (inst.player.GetButtonDown("RB"))
			{
				CreativeUI.inst.SetWindowVisibility(v: false);
				consoleItemEntry.Reset();
				ConsoleCursorMenu.inst.UpdateSelection(1);
			}
			if (inst.player.GetButtonDown("LB"))
			{
				CreativeUI.inst.SetWindowVisibility(v: false);
				consoleItemEntry.Reset();
				ConsoleCursorMenu.inst.UpdateSelection(-1);
			}
			if (inst.player.GetButtonDown("X"))
			{
				consoleItemEntry.Reset();
				inst.FocusBuildMenu();
			}
		}
	}

	private void UpdatePlaymodeButtons()
	{
		if (player.GetButtonDown("Start"))
		{
			ConsoleBuildMenu.inst.CloseMenu();
			GameState.inst.playingMode.OnClickedMenu();
		}
		if (IsNavigatingUI() || UINavigationBypass)
		{
			return;
		}
		if (isMovingTimer.Update(Time.unscaledDeltaTime) && GameUI.inst.currCursorMode == GameUI.inst.consoleCursorMode)
		{
			if (Cam.inst.OverrideTrack != null)
			{
				return;
			}
			if (GameUI.inst.CurrPlacementMode.IsPlacing())
			{
				ConsoleTileUI.inst.UpdateBuildPlacementModeVisuals();
			}
			else
			{
				GameUI.inst.GetCellSelected();
				if (GameUI.inst.GetBuildingSelected() == null)
				{
					RaycastHit closestRayHit = PointingSystem.GetClosestRayHit(scratchHitResults);
					Building b = null;
					if (closestRayHit.collider != null && closestRayHit.collider.GetComponent<BuildingCollider>() != null)
					{
						b = closestRayHit.collider.GetComponent<BuildingCollider>().BuildingAsBuilding;
					}
					ConsoleTileUI.inst.UpdateHoverVisuals(b);
				}
			}
		}
		if (!GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			GameUI.inst.IsUnitSelected();
		}
		if (player.GetButtonDown("B"))
		{
			CreativeUI.inst.SetBrushNone();
			isMovingTimer.Reset();
			if (GameUI.inst.CurrPlacementMode.IsPlacing())
			{
				ResetUIAfterCameraMove();
			}
			if (GameUI.inst.currCursorMode != GameUI.inst.consoleCursorMode)
			{
				ConsoleCursorMenu.inst.SetConsoleMode();
			}
			if (GameUI.inst.currCursorMode == GameUI.inst.consoleCursorMode)
			{
				GameUI.inst.ClearSelection();
				GameUI.inst.ClearUIForClick();
				GameUI.inst.ClearCellSelected();
			}
			if (ConsoleTileUI.inst.Visible)
			{
				ConsoleTileUI.inst.SetVisible(v: false);
				isMovingTimer.Enabled = false;
			}
		}
		if (player.GetButtonDown("X"))
		{
			FocusBuildMenu();
		}
		if (player.GetButtonDown("LT"))
		{
			FocusIslandInfo();
		}
		if (player.GetButtonDown("RT"))
		{
			FocusCreativeMode();
		}
		if (player.GetButtonDown("D-Pad Left"))
		{
			TimeManager.inst.SetSpeed(TimeManager.inst.speedInUse - 1);
		}
		else if (player.GetButtonDown("D-Pad Right"))
		{
			TimeManager.inst.SetSpeed(Mathff.Min(TimeManager.inst.speedInUse + 1, 3));
		}
		else if (!player.GetButton("D-Pad Up"))
		{
			player.GetButton("D-Pad Down");
		}
	}

	private void UpdateConsoleUIControls()
	{
		if (IsNavigatingUI() || UINavigationBypass)
		{
			if (player.GetButtonUp("UISubmit"))
			{
				UISubmitInput?.Invoke();
			}
			else if (player.GetButtonUp("UICancel"))
			{
				UICancelInput?.Invoke();
			}
			else if (player.GetButtonUp("Y"))
			{
				UIYInput?.Invoke();
			}
			else if (player.GetButtonUp("X"))
			{
				UIXInput?.Invoke();
			}
			else if (player.GetButton("UIVertical") && UpdateHold())
			{
				UIVerticalInput?.Invoke();
			}
			else if (player.GetNegativeButton("UIVertical") && UpdateHold())
			{
				UIVerticalNegativeInput?.Invoke();
			}
			else if (player.GetButton("UIHorizontal") && UpdateHold())
			{
				UIHorizontalInput?.Invoke();
			}
			else if (player.GetNegativeButton("UIHorizontal") && UpdateHold())
			{
				UIHorizontalNegativeInput?.Invoke();
			}
			else if (player.GetButtonUp("LB"))
			{
				UILeftBumperInput?.Invoke();
			}
			else if (player.GetButtonUp("RB"))
			{
				UIRightBumperInput?.Invoke();
			}
			if (player.GetNegativeButtonUp("UIHorizontal") || player.GetButtonUp("UIHorizontal") || player.GetNegativeButtonUp("UIVertical") || player.GetButtonUp("UIVertical"))
			{
				ResetHoldSettings();
			}
		}
	}

	private bool UpdateHold()
	{
		holdAcceleration = Mathf.Clamp(holdAcceleration, 1f, holdAccelerationMax);
		float dt = holdAcceleration * Time.unscaledDeltaTime;
		bool result = holdDuration.Update(dt);
		holdAcceleration += holdAccelerationStep;
		return result;
	}

	private void ResetHoldSettings()
	{
		holdDuration.ForceExpire();
		holdAcceleration = 1f;
	}

	private float easeInSine(float number)
	{
		return (float)(1.0 - Math.Cos((double)number * Math.PI / 2.0));
	}

	private void ResetUIAfterCameraMove()
	{
		if (!isMovingTimer.Enabled)
		{
			isMovingTimer.Enabled = true;
		}
		isMovingTimer.Reset();
		ConsoleTileUI.inst.SetVisible(v: false);
		ResetDemolishing();
	}

	private float RemapStickInput(float stick)
	{
		float num = Mathf.Sign(stick);
		float num2 = Mathf.Abs(stick);
		if (num2 > flickClamp)
		{
			num2 = flickClamp;
		}
		return easeInSine(num2) * distModifier * num;
	}

	private void MoveCamera(Vector3 dir, float input)
	{
		dir.y = 0f;
		dir.Normalize();
		Vector3 vector = dir;
		if (GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			float num = float.MinValue;
			for (int i = 0; i < dirs.Length; i++)
			{
				float num2 = Vector3.Dot(dirs[i], dir);
				if (num2 > num)
				{
					num = num2;
					vector = dirs[i];
				}
			}
			if (num < 0.925f)
			{
				vector = dir;
			}
		}
		Cam.inst.SetDesiredTrackingPos(Cam.inst.DesiredTrackingPos + vector * RemapStickInput(input));
	}

	private void UpdateCameraJoystick()
	{
		bool buttonDown = player.GetButtonDown("LeftStickButton");
		bool buttonDown2 = player.GetButtonDown("RightStickButton");
		if (buttonDown | buttonDown2)
		{
			if (buttonDown2)
			{
				overheadViewMode = !overheadViewMode;
			}
			return;
		}
		Ray ray = PointingSystem.GetRay();
		new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		Cell cellDataClamped = World.inst.GetCellDataClamped(point);
		enter = Mathff.Clamp(enter, 0f, 35f);
		distModifier = enter * Time.unscaledDeltaTime;
		if (SteamUtils.IsSteamRunningOnSteamDeck())
		{
			distModifier *= 0.6f;
		}
		else
		{
			distModifier *= 0.6f;
		}
		if (cellDataClamped.deepWater)
		{
			distModifier *= 1.33f;
		}
		leftX = player.GetAxis("LeftStickX");
		leftY = player.GetAxis("LeftStickY");
		if (Mathff.Abs(leftX) > 0.001f || Mathff.Abs(leftY) > 0.001f)
		{
			if (!moving)
			{
				startCamPos = Cam.inst.DesiredTrackingPos;
				maxStickInput = Vector3.zero;
				flickTime = 0f;
				flickClamp = Mathff.Clamp(1f - Mathff.Clamp01((enter - 0f) / 60f), 0.25f, 1f);
			}
			moving = true;
			flickTime += Time.unscaledDeltaTime;
			if (flickTime > flickThresholdTime)
			{
				flickClamp += Time.unscaledDeltaTime;
			}
		}
		if (Mathff.Abs(leftX) > 0.001f)
		{
			MoveCamera(Cam.inst.transform.right, leftX);
		}
		if (Mathff.Abs(leftY) > 0.001f)
		{
			MoveCamera(Cam.inst.transform.forward, leftY);
		}
		if (new Vector2(leftX, leftY).magnitude > maxStickInput.magnitude)
		{
			maxStickInput = new Vector2(leftX, leftY);
		}
		if (Mathff.Abs(leftY) <= 0.001f && Mathff.Abs(leftX) <= 0.001f)
		{
			if (moving && GameUI.inst.CurrPlacementMode.IsPlacing() && Vector3.Distance(startCamPos, Cam.inst.DesiredTrackingPos) < 1f)
			{
				Vector2 normalized = maxStickInput.normalized;
				Vector3 right = Cam.inst.transform.right;
				right.y = 0f;
				right.Normalize();
				Vector3 forward = Cam.inst.transform.forward;
				forward.y = 0f;
				forward.Normalize();
				Vector3 desiredTrackingPos = new Vector3((float)(int)startCamPos.x + 0.5f, 0f, (float)(int)startCamPos.z + 0.5f);
				desiredTrackingPos += right * normalized.x;
				desiredTrackingPos += forward * normalized.y;
				Cam.inst.SetDesiredTrackingPos(desiredTrackingPos);
			}
			moving = false;
		}
		rightX = player.GetAxis("RightStickY");
		rightY = player.GetAxis("RightStickX");
		if (Mathff.Abs(rightX) >= 0.8f)
		{
			Cam.inst.Zoom(Time.unscaledDeltaTime * (0f - zoomSpeed) * rightX);
		}
		else if (rightY != 0f)
		{
			Cam.inst.Rotate(Time.unscaledDeltaTime * rotationSpeed * rightY, 0f);
		}
	}

	private void ResetDemolishing()
	{
		if (demolishing)
		{
			_ = bCollider.Building;
			demolishing = false;
			demolishTimer.Reset();
			ConsoleTileUI.inst.UpdateYSlider(0f);
			waveIdx = 0f;
		}
	}
}
