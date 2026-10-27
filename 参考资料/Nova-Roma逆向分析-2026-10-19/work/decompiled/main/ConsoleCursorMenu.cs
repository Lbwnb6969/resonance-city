using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ConsoleCursorMenu : MonoBehaviour
{
	public enum Status
	{
		Showing,
		Hiding,
		None
	}

	public static ConsoleCursorMenu inst;

	private bool isActive;

	public RectTransform xRoot;

	[SerializeField]
	public List<Button> cursorButtons;

	private int currentSelected;

	private BuildButton buildButton;

	public GameObject LB;

	public GameObject RB;

	private GameObject previousCursorSelected;

	public bool Active => isActive;

	private void Awake()
	{
		inst = this;
		buildButton = GetComponent<BuildButton>();
	}

	private void Update()
	{
		if (isActive && !GamepadControl.inst.CurrentSelected)
		{
			if (GamepadControl.inst.player.GetButtonDown("RB"))
			{
				UpdateSelection(1);
			}
			if (GamepadControl.inst.player.GetButtonDown("LB"))
			{
				UpdateSelection(-1);
			}
		}
	}

	public void UpdateSelection(int direction)
	{
		CreativeUI.inst.SetBrushNone();
		if (!buildButton.IsUnlocked())
		{
			currentSelected = 0;
			cursorButtons[currentSelected].onClick.Invoke();
			return;
		}
		if (currentSelected + direction < 0)
		{
			currentSelected = cursorButtons.Count - 1;
		}
		else if (currentSelected + direction > cursorButtons.Count - 1)
		{
			currentSelected = 0;
		}
		else
		{
			currentSelected += direction;
		}
		cursorButtons[currentSelected].onClick.Invoke();
		cursorButtons[currentSelected].GetComponent<UIScaleBump>().Activate();
		if (currentSelected != 0)
		{
			ConsoleTileUI.inst.UpdateDefaultCursorModeVisuals();
		}
	}

	public void SetConsoleModeVisibilty(bool visible)
	{
		cursorButtons[0].gameObject.SetActive(visible);
		LB.SetActive(visible);
		RB.SetActive(visible);
		LayoutRebuilder.ForceRebuildLayoutImmediate(xRoot);
	}

	public void SetConsoleMode()
	{
		if (GamepadControl.inst.isControllerActive && GameUI.inst.currCursorMode != GameUI.inst.consoleCursorMode)
		{
			GameUI.inst.SetCursorModeConsole();
			currentSelected = 0;
		}
	}

	public void PrepForGamepad()
	{
		SetConsoleMode();
		isActive = true;
		xRoot.anchoredPosition = new Vector3(70f, 0f, 0f);
		if (GameUI.IsOnConsole())
		{
			xRoot.localScale = new Vector3(1f, 1f, 1f);
		}
		else
		{
			xRoot.localScale = new Vector3(1f, 1f, 1f);
		}
		SetConsoleModeVisibilty(visible: true);
	}

	public void PrepForKeyboard()
	{
		GameUI.inst.ReturnToDefaultCursorMode();
		isActive = false;
		xRoot.anchoredPosition = new Vector3(240f, 1f, 0f);
		xRoot.localScale = new Vector3(1f, 1f, 1f);
		SetConsoleModeVisibilty(visible: false);
	}
}
