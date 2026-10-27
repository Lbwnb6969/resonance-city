public class ConsoleUICustomSelect : ConsoleUISelectable
{
	public enum CustomButton
	{
		X,
		Y
	}

	public ConsoleUIItem target;

	public CustomButton customBtn;

	public bool ActivateOnSubmit = true;

	public bool ActivateOnHover;

	public bool ResetBeforeSelection = true;

	public override void Submit()
	{
		if (ActivateOnSubmit)
		{
			ActivateInput();
		}
	}

	public override void Hover()
	{
		if (ActivateOnHover)
		{
			ActivateInput();
		}
	}

	public void CustomSubmit()
	{
		if (!GamepadControl.inst.UINavigationBypass)
		{
			ConsoleUIItem component = GetComponent<ConsoleUIItem>();
			component.DeactivateInput();
			if (ResetBeforeSelection)
			{
				component.ResetChildren();
			}
			if (component.items.data[0] != null)
			{
				target.parent = component.items.data[0];
			}
			else
			{
				target.parent = component;
			}
			target.Hover();
		}
	}

	public override void Reset()
	{
		DeactivateInput();
	}

	public override void Dehover()
	{
		DeactivateInput();
	}

	public override void CustomActivate()
	{
		if (customBtn == CustomButton.X)
		{
			GamepadControl.inst.UIXInput += CustomSubmit;
		}
		else if (customBtn == CustomButton.Y)
		{
			GamepadControl.inst.UIYInput += CustomSubmit;
		}
	}

	public override void CustomDeactivate()
	{
		if (customBtn == CustomButton.X)
		{
			GamepadControl.inst.UIXInput -= CustomSubmit;
		}
		else if (customBtn == CustomButton.Y)
		{
			GamepadControl.inst.UIYInput -= CustomSubmit;
		}
	}

	public void OnDestroy()
	{
		Reset();
	}
}
