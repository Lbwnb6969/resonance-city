using UnityEngine;
using UnityEngine.UI;

public class ConsoleUIScroll : ConsoleUISelectable
{
	public float scrollSpeed = 1f;

	public RectTransform root;

	public RectTransform container;

	public ScrollRect scrollRect;

	public ConsoleUIItem item;

	private void Start()
	{
		if (scrollRect == null)
		{
			scrollRect = GetComponentInParent<ScrollRect>();
		}
		container = root.parent.GetComponent<RectTransform>();
		item = GetComponent<ConsoleUIItem>();
	}

	public override void Submit()
	{
		item.DeactivateInput();
		ActivateInput();
	}

	public void ExitScroll()
	{
		item.Focus();
		DeactivateInput();
	}

	public override void Reset()
	{
		DeactivateInput();
	}

	public void ScrollUp()
	{
		scrollRect.verticalScrollbar.value += Time.unscaledDeltaTime * scrollSpeed;
	}

	public void ScrollDown()
	{
		scrollRect.verticalScrollbar.value -= Time.unscaledDeltaTime * scrollSpeed;
	}

	public override void CustomActivate()
	{
		GamepadControl.inst.UIVerticalInput += ScrollUp;
		GamepadControl.inst.UIVerticalNegativeInput += ScrollDown;
		GamepadControl.inst.UICancelInput += ExitScroll;
		GamepadControl.inst.UISubmitInput += ExitScroll;
	}

	public override void CustomDeactivate()
	{
		GamepadControl.inst.UIVerticalInput -= ScrollUp;
		GamepadControl.inst.UIVerticalNegativeInput -= ScrollDown;
		GamepadControl.inst.UICancelInput -= ExitScroll;
		GamepadControl.inst.UISubmitInput -= ExitScroll;
	}
}
