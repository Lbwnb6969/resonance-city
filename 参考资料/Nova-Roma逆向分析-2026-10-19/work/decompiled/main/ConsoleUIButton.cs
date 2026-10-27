using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class ConsoleUIButton : ConsoleUISelectable
{
	public Button btn;

	public Component ISubmit;

	public Component IPointerDown;

	public Component IPointerClick;

	public bool TriggerOnSubmit = true;

	public bool TriggerOnFocus;

	public override void Submit()
	{
		if (TriggerOnSubmit)
		{
			TriggerButton();
		}
	}

	public override void Focus()
	{
		if (TriggerOnFocus)
		{
			TriggerButton();
		}
	}

	public void TriggerButton()
	{
		if (btn != null && btn.interactable)
		{
			btn.onClick?.Invoke();
		}
		else if (ISubmit != null)
		{
			((ISubmitHandler)ISubmit).OnSubmit(null);
		}
		else if (IPointerDown != null)
		{
			((IPointerDownHandler)IPointerDown).OnPointerDown(null);
		}
		else if (IPointerClick != null)
		{
			((IPointerClickHandler)IPointerClick).OnPointerClick(null);
		}
	}
}
