using System;
using UnityEngine;
using UnityEngine.UI;

public class ConsoleHighlightUI : MonoBehaviour
{
	public CanvasScaler[] mainMenuScalers;

	public CanvasScaler[] playmodeScalers;

	public CanvasScaler[] bothScalers;

	private GameMode previousMode;

	private Vector3 refMainMenuRes = new Vector3(1280f, 720f);

	private Vector3 refInGameRes = new Vector3(1200f, 1200f);

	public void Start()
	{
		UpdateUIScaling();
		GameUI inst = GameUI.inst;
		inst.ResolutionChanged = (Action)Delegate.Combine(inst.ResolutionChanged, new Action(UpdateUIScaling));
	}

	public void OnDestroy()
	{
		GameUI inst = GameUI.inst;
		inst.ResolutionChanged = (Action)Delegate.Remove(inst.ResolutionChanged, new Action(UpdateUIScaling));
	}

	private void Update()
	{
		if (previousMode != GameState.inst.CurrMode)
		{
			UpdateUIScaling();
		}
		previousMode = GameState.inst.CurrMode;
	}

	public void UpdateUIScaling()
	{
		for (int i = 0; i < bothScalers.Length; i++)
		{
			if (GameState.inst.IsPlayMode())
			{
				UpdatePlayModeScaler(bothScalers[i]);
			}
			else if (GameState.inst.IsMainMenuMode())
			{
				UpdateMainMenuScaler(bothScalers[i]);
			}
		}
		for (int j = 0; j < mainMenuScalers.Length; j++)
		{
			UpdateMainMenuScaler(mainMenuScalers[j]);
		}
		for (int k = 0; k < playmodeScalers.Length; k++)
		{
			UpdatePlayModeScaler(playmodeScalers[k]);
		}
	}

	public void UpdateMainMenuScaler(CanvasScaler scaler)
	{
		scaler.referenceResolution = refMainMenuRes;
		scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.Expand;
	}

	public void UpdatePlayModeScaler(CanvasScaler scaler)
	{
		scaler.referenceResolution = refInGameRes;
		scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
		scaler.matchWidthOrHeight = GameUI.inst.matchValue;
	}
}
