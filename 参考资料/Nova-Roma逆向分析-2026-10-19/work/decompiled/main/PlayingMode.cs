using UnityEngine;

public class PlayingMode : GameMode
{
	public GameObject GameUIParent;

	private void Start()
	{
	}

	private void Update()
	{
	}

	public override void Init()
	{
		CloudSystem.inst.threshold1 = 0.55f;
		CloudSystem.inst.threshold2 = 0.675f;
		CloudSystem.inst.BaseFreq = 5f;
		GameUIParent.SetActive(value: true);
		foreach (Transform item in GameUIParent.transform)
		{
			item.gameObject.SetActive(value: true);
		}
		MiniMapUI.inst.SetVisibility(v: true);
		base.Init();
	}

	public override void UpdateManual(float dt)
	{
		base.UpdateManual(dt);
	}

	public override void Shutdown()
	{
		GameUIParent.SetActive(value: false);
		foreach (Transform item in GameUIParent.transform)
		{
			item.gameObject.SetActive(value: false);
		}
		if (MiniMapUI.inst != null)
		{
			MiniMapUI.inst.SetVisibility(v: false);
		}
		base.Shutdown();
	}

	public void OnClickedMenu()
	{
		GameUI.inst.AbortCursorObjPlacement();
		GameUI.inst.ReturnToDefaultCursorMode();
		GameUI.inst.ClearUIForClick();
		GameState component = GetComponent<GameState>();
		component.SetNewMode(component.mainMenuMode);
		component.mainMenuMode.TransitionTo(MainMenuMode.State.PauseMenu);
		TimeManager.inst.SetPaused(skipSfx: true);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedShare()
	{
		GameState component = GetComponent<GameState>();
		component.SetNewMode(component.mainMenuMode);
		component.mainMenuMode.TransitionTo(MainMenuMode.State.KingdomShareFromGame);
		TimeManager.inst.SetPaused(skipSfx: true);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedBannerChange()
	{
		GameState component = GetComponent<GameState>();
		component.SetNewMode(component.mainMenuMode);
		component.mainMenuMode.TransitionTo(MainMenuMode.State.BannerSelect);
		TimeManager.inst.SetPaused(skipSfx: true);
		SfxSystem.PlayUiSelect();
	}
}
