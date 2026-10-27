using UnityEngine.UI;

public class ConsoleUISlider : ConsoleUISelectable
{
	public enum Direction
	{
		Vertical,
		Horizontal
	}

	public Slider slider;

	public Direction direction = Direction.Horizontal;

	private ConsoleUIItem item;

	public bool closeOnSubmit = true;

	public float valueSteps = 0.1f;

	public override void Hover()
	{
		item = GetComponent<ConsoleUIItem>();
		item.DeactivateInput();
		ActivateInput();
	}

	public override void Dehover()
	{
		DeactivateInput();
	}

	public override void Reset()
	{
		DeactivateInput();
	}

	public void Increment()
	{
		slider.value += valueSteps;
	}

	public void Decrement()
	{
		slider.value -= valueSteps;
	}

	public override void CustomActivate()
	{
		if (direction == Direction.Horizontal)
		{
			GamepadControl.inst.UIHorizontalInput += Increment;
			GamepadControl.inst.UIHorizontalNegativeInput += Decrement;
			GamepadControl.inst.UIVerticalInput += item.NavigateUp;
			GamepadControl.inst.UIVerticalNegativeInput += item.NavigateDown;
		}
		else if (direction == Direction.Vertical)
		{
			GamepadControl.inst.UIVerticalInput += Increment;
			GamepadControl.inst.UIVerticalNegativeInput += Decrement;
			GamepadControl.inst.UIHorizontalInput += item.NavigateRight;
			GamepadControl.inst.UIHorizontalNegativeInput += item.NavigateLeft;
		}
		if (closeOnSubmit)
		{
			GamepadControl.inst.UISubmitInput += item.Cancel;
		}
		GamepadControl.inst.UICancelInput += item.Cancel;
	}

	public override void CustomDeactivate()
	{
		if (direction == Direction.Horizontal)
		{
			GamepadControl.inst.UIHorizontalInput -= Increment;
			GamepadControl.inst.UIHorizontalNegativeInput -= Decrement;
			GamepadControl.inst.UIVerticalInput -= item.NavigateUp;
			GamepadControl.inst.UIVerticalNegativeInput -= item.NavigateDown;
		}
		else if (direction == Direction.Vertical)
		{
			GamepadControl.inst.UIVerticalInput -= Increment;
			GamepadControl.inst.UIVerticalNegativeInput -= Decrement;
			GamepadControl.inst.UIHorizontalInput -= item.NavigateRight;
			GamepadControl.inst.UIHorizontalNegativeInput -= item.NavigateLeft;
		}
		if (closeOnSubmit)
		{
			GamepadControl.inst.UISubmitInput -= item.Cancel;
		}
		GamepadControl.inst.UICancelInput -= item.Cancel;
	}
}
