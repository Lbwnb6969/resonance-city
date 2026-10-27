using System;
using TMPro;
using UnityEngine;

public class DifficultySelectUI : MonoBehaviour
{
	public TextMeshProUGUI title;

	public TextMeshProUGUI desc;

	public GameObject survivalDecoration;

	public GameObject consoleUIContainer;

	public GameObject buttonUIContainer;

	private void Start()
	{
	}

	public void OnNextClicked()
	{
		Player.inst.difficulty++;
		if (Player.inst.difficulty == Player.Difficulty.NumSettings)
		{
			Player.inst.difficulty = Player.Difficulty.Peaceful;
		}
		RefreshDisplay();
	}

	public void OnPrevClicked()
	{
		if (Player.inst.difficulty == Player.Difficulty.Peaceful)
		{
			Player.inst.difficulty = Player.Difficulty.Survival;
		}
		else
		{
			Player.inst.difficulty--;
		}
		RefreshDisplay();
	}

	private void RefreshDisplay()
	{
		SfxSystem.PlayUiSelect();
		switch (Player.inst.difficulty)
		{
		case Player.Difficulty.Peaceful:
			title.text = "ScriptLocalization.Paxlon_no_threats";
			desc.text = "ScriptLocalization.paxlon_instructions";
			break;
		case Player.Difficulty.Easy:
			title.text = "ScriptLocalization.Sommern_easy";
			desc.text = "ScriptLocalization.sommern_instructions";
			break;
		case Player.Difficulty.Hard:
			title.text = "ScriptLocalization.Vintar_hard";
			desc.text = "ScriptLocalization.vintar_instructions";
			break;
		case Player.Difficulty.Survival:
			title.text = "ScriptLocalization.Falle_survival";
			desc.text = "ScriptLocalization.Falle_instructions";
			break;
		}
		survivalDecoration.gameObject.SetActive(Player.inst.difficulty == Player.Difficulty.Survival);
	}

	private void OnEnable()
	{
		Player.inst.difficulty = Player.Difficulty.Easy;
		RefreshDisplay();
		OnConsoleUpdate(GamepadControl.inst.isControllerActive);
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(inst.controllerUpdate, new GamepadControl.ControllerActivity(OnConsoleUpdate));
		ActivateInput();
	}

	public void OnConsoleUpdate(bool isControllerActive)
	{
		consoleUIContainer.SetActive(isControllerActive);
		buttonUIContainer.SetActive(!isControllerActive);
	}

	private void OnDisable()
	{
		DeactivateInput();
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(inst.controllerUpdate, new GamepadControl.ControllerActivity(OnConsoleUpdate));
	}

	public void ActivateInput()
	{
		if (!gameObject.activeSelf)
		{
			DeactivateInput();
			return;
		}
		GamepadControl.inst.UIRightBumperInput += OnNextClicked;
		GamepadControl.inst.UILeftBumperInput += OnPrevClicked;
	}

	public void DeactivateInput()
	{
		GamepadControl.inst.UIRightBumperInput -= OnNextClicked;
		GamepadControl.inst.UILeftBumperInput -= OnPrevClicked;
	}
}
