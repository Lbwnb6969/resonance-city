using System;
using Assets;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class CursorModeUI : MonoBehaviour
{
	public static CursorModeUI inst;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private GameObject overlayGO;

	public CursorButtonUI ConsoleButton;

	public CursorButtonUI ChopButton;

	public CursorButtonUI ChopCancelButton;

	public CursorButtonUI EditTerrainButton;

	public CursorButtonUI RebuildButton;

	public CursorButtonUI DemolishButton;

	public CursorButtonUI SampleButton;

	private bool isVisible;

	private bool isLocalizeDirty;

	public bool IsVisible()
	{
		return isVisible;
	}

	private void Awake()
	{
		inst = this;
		ChopButton.tooltip.tooltipTerm = "cursormodeui_tooltip_clearland";
		ChopCancelButton.tooltip.tooltipTerm = "cursormodeui_tooltip_cancelclearland";
		EditTerrainButton.tooltip.tooltipTerm = "cursormodeui_tooltip_editterrain";
		RebuildButton.tooltip.tooltipTerm = "cursormodeui_tooltip_rebuild";
		DemolishButton.tooltip.tooltipTerm = "cursorModeui_tooltip_demolish";
		SampleButton.tooltip.tooltipTerm = "cursorModeui_tooltip_sample";
		SetVisibility(v: true);
	}

	private void Start()
	{
		OnLocalizeEvent();
		LocalizationManager.OnLocalizeEvent += OnLocalizeEvent;
		Settings.onKeybindChanged = (Settings.OnKeybindChanged)Delegate.Combine(Settings.onKeybindChanged, new Settings.OnKeybindChanged(OnKeybindChanged));
	}

	private void OnDestroy()
	{
		LocalizationManager.OnLocalizeEvent -= OnLocalizeEvent;
		Settings.onKeybindChanged = (Settings.OnKeybindChanged)Delegate.Remove(Settings.onKeybindChanged, new Settings.OnKeybindChanged(OnKeybindChanged));
	}

	private void OnLocalizeEvent()
	{
		OnKeybindChanged(300, ConfigurableControls.inst.GetKeyAction(300));
		OnKeybindChanged(301, ConfigurableControls.inst.GetKeyAction(301));
		OnKeybindChanged(302, ConfigurableControls.inst.GetKeyAction(302));
		OnKeybindChanged(303, ConfigurableControls.inst.GetKeyAction(303));
		OnKeybindChanged(304, ConfigurableControls.inst.GetKeyAction(304));
		OnKeybindChanged(305, ConfigurableControls.inst.GetKeyAction(305));
		isLocalizeDirty = true;
	}

	private void OnKeybindChanged(int id, ConfigurableControls.Keybind keybind)
	{
		switch (id)
		{
		case 300:
			ChopButton.tooltip.toolTipText = string.Format(ScriptLocalization.cursormodeui_tooltip_clearland, keybind);
			break;
		case 301:
			ChopCancelButton.tooltip.toolTipText = string.Format(ScriptLocalization.cursormodeui_tooltip_cancelclearland, keybind);
			break;
		case 302:
			EditTerrainButton.tooltip.toolTipText = string.Format(ScriptLocalization.cursormodeui_tooltip_editterrain, keybind);
			break;
		case 303:
			RebuildButton.tooltip.toolTipText = string.Format(ScriptLocalization.cursormodeui_tooltip_rebuild, keybind);
			break;
		case 304:
			DemolishButton.tooltip.toolTipText = string.Format(ScriptLocalization.cursorModeui_tooltip_demolish, keybind);
			break;
		case 305:
			SampleButton.tooltip.toolTipText = string.Format(ScriptLocalization.cursorModeui_tooltip_sample, keybind);
			break;
		}
	}

	public void SetVisibility(bool v)
	{
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Update()
	{
		if (!IsValidToSetVisibility())
		{
			return;
		}
		int focusedLandMass = Player.inst.FocusedLandMass;
		bool visibility = Player.inst.GetBuildingListForLandMass(focusedLandMass).Count > 0;
		SetVisibility(visibility);
		bool flag = Player.inst.GetBuildingListForLandMass(focusedLandMass, World.rubbleHash).Count > 0;
		if (RebuildButton.btn.interactable != flag || isLocalizeDirty)
		{
			string text = string.Format(ScriptLocalization.cursormodeui_tooltip_rebuild, ConfigurableControls.inst.GetKeyAction(303));
			if (flag)
			{
				RebuildButton.tooltip.toolTipText = text;
			}
			else
			{
				RebuildButton.tooltip.toolTipText = text + Environment.NewLine + LocalizationManager.GetTranslation("cursormodeui_tooltip_rebuild_inactive");
			}
		}
		RebuildButton.btn.interactable = flag;
		bool flag2 = false;
		if (focusedLandMass != -1 && JobSystem.jobCategoriesMap.TryGetValue(21, out var value))
		{
			flag2 = value.jobs.data[focusedLandMass].Count > 0;
		}
		if (ChopCancelButton.btn.interactable != flag2 || isLocalizeDirty)
		{
			string text2 = string.Format(ScriptLocalization.cursormodeui_tooltip_cancelclearland, ConfigurableControls.inst.GetKeyAction(301));
			if (flag2)
			{
				ChopCancelButton.tooltip.toolTipText = text2;
			}
			else
			{
				ChopCancelButton.tooltip.toolTipText = text2 + Environment.NewLine + LocalizationManager.GetTranslation("cursormodeui_tooltip_cancelclearland_inactive");
			}
		}
		ChopCancelButton.btn.interactable = flag2;
		EditTerrainButton.btn.interactable = TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_terrainengineering");
		isLocalizeDirty = false;
	}

	private bool IsValidToSetVisibility()
	{
		if (!(GameUI.inst.currCursorMode is DockRouteCursorMode) && !ConsoleBuildMenu.inst.Active && !MerchantUI.inst.IsVisible())
		{
			return !GameUI.inst.IsChariotRaceModeActive();
		}
		return false;
	}

	public void SetCursorChopMode()
	{
		GameUI.inst.SetCursorModeChop();
	}

	public void SetCursorConsoleMode()
	{
		GameUI.inst.SetCursorModeConsole();
	}

	public void SetCursorChopCancelMode()
	{
		GameUI.inst.SetCursorModeChopCancel();
	}

	public void SetCursorEditTerrainMode()
	{
		EditTerrainUI.inst.SetVisible(v: true);
	}

	public void SetCursorDamPlannerMode()
	{
		DamPlannerUI.inst.SetVisible(v: true);
	}

	public void SetCursorRebuildMode()
	{
		GameUI.inst.SetCursorModeRebuild();
	}

	public void SetCursorDemolishMode()
	{
		GameUI.inst.SetCursorModeDemolish();
	}

	public void SetCursorSampleMode()
	{
		GameUI.inst.SetCursorModeSample();
	}
}
