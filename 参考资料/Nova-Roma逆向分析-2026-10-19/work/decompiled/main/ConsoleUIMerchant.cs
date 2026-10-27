using UnityEngine;
using UnityEngine.UI;

public class ConsoleUIMerchant : ConsoleUISelectable
{
	public Transform tabContainer;

	private int currIdx;

	public override void Hover()
	{
		ActivateInput();
		currIdx = 0;
	}

	public override void Dehover()
	{
		DeactivateInput();
	}

	private void NavigateRight()
	{
		if (currIdx != tabContainer.childCount - 1 && tabContainer.GetChild(currIdx + 1).gameObject.activeInHierarchy)
		{
			currIdx++;
			tabContainer.GetChild(currIdx).GetComponent<Toggle>().OnSubmit(null);
		}
	}

	public void NavigateLeft()
	{
		if (currIdx != 0 && tabContainer.GetChild(currIdx - 1).gameObject.activeInHierarchy)
		{
			currIdx--;
			tabContainer.GetChild(currIdx).GetComponent<Toggle>().OnSubmit(null);
		}
	}

	public override void Reset()
	{
		DeactivateInput();
	}

	public override void CustomActivate()
	{
		GamepadControl.inst.UIHorizontalInput += NavigateRight;
		GamepadControl.inst.UIHorizontalNegativeInput += NavigateLeft;
	}

	public override void CustomDeactivate()
	{
		GamepadControl.inst.UIHorizontalInput -= NavigateRight;
		GamepadControl.inst.UIHorizontalNegativeInput -= NavigateLeft;
	}
}
