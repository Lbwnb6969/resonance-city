using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class ResourceToggleButton : MonoBehaviour
{
	public Image yesImage;

	public Image noImage;

	public Button button;

	private bool buttonStateOn = true;

	public UnityEvent OnToggle;

	public bool State
	{
		get
		{
			return buttonStateOn;
		}
		set
		{
			buttonStateOn = value;
			yesImage.gameObject.SetActive(buttonStateOn);
			noImage.gameObject.SetActive(!buttonStateOn);
			OnToggle.Invoke();
		}
	}

	private void Awake()
	{
		button.onClick.AddListener(ButtonClick);
	}

	private void ButtonClick()
	{
		State = !State;
		if (State)
		{
			SfxSystem.PlayUiSelect();
		}
		else
		{
			SfxSystem.PlayUiCancel();
		}
	}

	public void InitTo(bool v)
	{
		buttonStateOn = v;
		yesImage.gameObject.SetActive(buttonStateOn);
		noImage.gameObject.SetActive(!buttonStateOn);
	}
}
