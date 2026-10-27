using TMPro;
using UnityEngine;

public class ConsoleTextInput : MonoBehaviour
{
	public static ConsoleTextInput inst;

	public TMP_InputField inputField;

	public RectTransform xRoot;

	private RectTransform currentTarget;

	private string initText = "";

	private bool isActive;

	private void Awake()
	{
		inst = this;
		xRoot = GetComponent<RectTransform>();
	}

	private void Update()
	{
		if (isActive)
		{
			if (GamepadControl.inst.player.GetButtonDown("X"))
			{
				Backspace();
			}
			if (GamepadControl.inst.player.GetButtonDown("Y"))
			{
				KeyPressed(" ");
			}
		}
	}

	public void KeyPressed(string text)
	{
		if (inputField != null)
		{
			inputField.text += text;
		}
	}

	public void Backspace()
	{
		if (inputField != null)
		{
			string text = inputField.text;
			text = ((text.Length <= 1) ? "" : text.Substring(0, text.Length - 1));
			inputField.text = text;
		}
	}

	public void Show(RectTransform target, TMP_InputField input)
	{
		inputField = input;
		isActive = true;
		initText = inputField.text;
		inputField.interactable = true;
		currentTarget = target;
		xRoot.position = currentTarget.position;
		Vector2 anchoredPosition = xRoot.anchoredPosition;
		anchoredPosition.y += xRoot.sizeDelta.y / 2f + 25f;
		xRoot.anchoredPosition = anchoredPosition;
		GamepadControl.inst.nextSelected = transform.GetChild(1).GetChild(0).gameObject;
	}

	public void Hide()
	{
		bool flag = (inputField.interactable = false);
		isActive = flag;
		if (inputField.text.Length == 0)
		{
			inputField.text = initText;
		}
		inputField.onEndEdit.Invoke(inputField.text);
		xRoot.anchoredPosition = new Vector2(-735f, 478f);
		currentTarget = null;
	}
}
