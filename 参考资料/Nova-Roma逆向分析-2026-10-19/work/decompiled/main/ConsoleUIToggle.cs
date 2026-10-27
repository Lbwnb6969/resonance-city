using UnityEngine.UI;

public class ConsoleUIToggle : ConsoleUISelectable
{
	public Toggle toggle;

	public bool UIToggle;

	public override void Submit()
	{
		if (toggle.interactable)
		{
			toggle.isOn = !toggle.isOn;
		}
	}

	public override void Focus()
	{
		if (UIToggle && toggle.interactable)
		{
			toggle.isOn = false;
		}
	}

	public override void Reset()
	{
		if (UIToggle && toggle.interactable)
		{
			toggle.isOn = false;
		}
	}
}
