public class ConsoleUIAwaitSelection : ConsoleUISelectable
{
	public enum InputType
	{
		A,
		X,
		B,
		Y
	}

	public InputType inputType;

	public bool onFocus = true;

	public bool onSubmit;

	public bool selectByHover = true;

	public bool selectByFocus;

	private bool enableSection;

	public override void Focus()
	{
		if (onFocus)
		{
			PrepareSelection();
		}
	}

	public override void Submit()
	{
		if (onSubmit)
		{
			PrepareSelection();
		}
	}

	private void PrepareSelection()
	{
		GetComponent<ConsoleUIItem>().Dehover();
		ActivateInput();
		GamepadControl.inst.nextSelected = null;
		GamepadControl.inst.UINavigationBypass = true;
	}

	public void SelectItem()
	{
		if (selectByHover)
		{
			GetComponent<ConsoleUIItem>().Hover();
		}
		else if (selectByFocus)
		{
			GetComponent<ConsoleUIItem>().Focus();
		}
		DeactivateInput();
		GamepadControl.inst.UINavigationBypass = false;
	}

	public override void Reset()
	{
		DeactivateInput();
		GamepadControl.inst.UINavigationBypass = false;
	}

	public void OnDisable()
	{
		Reset();
	}

	public override void CustomActivate()
	{
		if (inputType == InputType.A)
		{
			GamepadControl.inst.UISubmitInput += SelectItem;
		}
		else if (inputType == InputType.X)
		{
			GamepadControl.inst.UIXInput += SelectItem;
		}
		else if (inputType == InputType.B)
		{
			GamepadControl.inst.UICancelInput += SelectItem;
		}
		else if (inputType == InputType.Y)
		{
			GamepadControl.inst.UIYInput += SelectItem;
		}
	}

	public override void CustomDeactivate()
	{
		if (inputType == InputType.A)
		{
			GamepadControl.inst.UISubmitInput -= SelectItem;
		}
		else if (inputType == InputType.X)
		{
			GamepadControl.inst.UIXInput -= SelectItem;
		}
		else if (inputType == InputType.B)
		{
			GamepadControl.inst.UICancelInput -= SelectItem;
		}
		else if (inputType == InputType.Y)
		{
			GamepadControl.inst.UIYInput -= SelectItem;
		}
	}
}
