using System;
using Assets;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class SpeedControlUI : MonoBehaviour
{
	public static SpeedControlUI inst;

	[SerializeField]
	public Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	public Toggle pauseButton;

	[SerializeField]
	private TooltipHook pauseTooltip;

	[SerializeField]
	public Toggle playButton1;

	[SerializeField]
	private TooltipHook play1Tooltip;

	[SerializeField]
	public Toggle playButton2;

	[SerializeField]
	private TooltipHook play2Tooltip;

	[SerializeField]
	public Toggle playButton3;

	[SerializeField]
	private TooltipHook play3Tooltip;

	[SerializeField]
	private GameObject consoleControls;

	public bool isLocked;

	[SerializeField]
	private RawImage isLockedOverlay;

	private bool isVisible;

	public GameObject pauseNotify;

	public void SetLocked(bool val)
	{
		if (val != isLocked)
		{
			Util.SetEnabled(isLockedOverlay, val);
		}
		isLocked = val;
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
		SetVisibility(v: true);
	}

	private void OnEnable()
	{
		if (TimeManager.inst != null)
		{
			SetSpeedVisuals(TimeManager.inst.speedInUse);
		}
	}

	private void Start()
	{
		pauseTooltip.tooltipTerm = ScriptLocalization.TooltipTimeButtonPause;
		play1Tooltip.tooltipTerm = ScriptLocalization.TooltipTimeButtonSpeed1;
		play2Tooltip.tooltipTerm = ScriptLocalization.TooltipTimeButtonSpeed2;
		play3Tooltip.tooltipTerm = ScriptLocalization.TooltipTimeButtonSpeed3;
		OnLocalizeEvent();
		LocalizationManager.OnLocalizeEvent += OnLocalizeEvent;
		Settings.onKeybindChanged = (Settings.OnKeybindChanged)Delegate.Combine(Settings.onKeybindChanged, new Settings.OnKeybindChanged(OnKeybindChanged));
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(OnControllerUpdate));
	}

	public void Reset()
	{
		SetLocked(val: false);
	}

	private void OnControllerUpdate(bool isActive)
	{
		Util.SetActive(consoleControls, isActive);
	}

	private void OnDestroy()
	{
		LocalizationManager.OnLocalizeEvent -= OnLocalizeEvent;
		Settings.onKeybindChanged = (Settings.OnKeybindChanged)Delegate.Remove(Settings.onKeybindChanged, new Settings.OnKeybindChanged(OnKeybindChanged));
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(OnControllerUpdate));
	}

	public void OnLocalizeEvent()
	{
		pauseTooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonPause, ConfigurableControls.inst.GetKeyAction(200));
		play1Tooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonSpeed1, ConfigurableControls.inst.GetKeyAction(201));
		play2Tooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonSpeed2, ConfigurableControls.inst.GetKeyAction(202));
		play3Tooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonSpeed3, ConfigurableControls.inst.GetKeyAction(203));
	}

	public void OnKeybindChanged(int id, ConfigurableControls.Keybind keybind)
	{
		switch (id)
		{
		case 200:
			pauseTooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonPause, keybind);
			break;
		case 201:
			play1Tooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonSpeed1, keybind);
			break;
		case 202:
			play2Tooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonSpeed2, keybind);
			break;
		case 203:
			play3Tooltip.toolTipText = string.Format(ScriptLocalization.TooltipTimeButtonSpeed3, keybind);
			break;
		}
	}

	private void Update()
	{
		Util.SetEnabled(isLockedOverlay, StreamerEffects.Flag_SuperSpeedTroll);
		if (IsValidToSetVisibility())
		{
			bool visibility = false;
			for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
			{
				int landMass = Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i];
				if (Player.inst.GetBuildingListForLandMass(landMass).Count > 0)
				{
					visibility = true;
					break;
				}
			}
			SetVisibility(visibility);
		}
		bool flag = TimeManager.inst.IsPaused();
		Util.SetActive(pauseNotify, flag && !GodUI.inst.Visible() && !AdvisorUI.inst.IsVisible());
	}

	private bool IsValidToSetVisibility()
	{
		if (!(GameUI.inst.currCursorMode is DockRouteCursorMode) && !ConsoleBuildMenu.inst.Active && !MerchantUI.inst.IsVisible())
		{
			return !GameUI.inst.IsChariotRaceModeActive();
		}
		return false;
	}

	public void OnPaused(bool isActive)
	{
		if (isActive && !StreamerEffects.Flag_SuperSpeedTroll)
		{
			TimeManager.inst.SetPaused();
		}
	}

	public void OnPlayNormal(bool isActive)
	{
		if (isActive && !StreamerEffects.Flag_SuperSpeedTroll)
		{
			TimeManager.inst.SetPlay1();
		}
	}

	public void OnPlayFast(bool isActive)
	{
		if (isActive && !StreamerEffects.Flag_SuperSpeedTroll)
		{
			TimeManager.inst.SetPlay2();
		}
	}

	public void OnPlayFastest(bool isActive)
	{
		if (isActive && !StreamerEffects.Flag_SuperSpeedTroll)
		{
			TimeManager.inst.SetPlay3();
		}
	}

	public void SetSpeedVisuals(int idx)
	{
		pauseButton.SetIsOnWithoutNotify(idx == 0);
		playButton1.SetIsOnWithoutNotify(idx == 1);
		playButton2.SetIsOnWithoutNotify(idx == 2);
		playButton3.SetIsOnWithoutNotify(idx >= 3);
	}
}
