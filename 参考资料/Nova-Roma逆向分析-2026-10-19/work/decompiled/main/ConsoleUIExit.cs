using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class ConsoleUIExit : ConsoleUISelectable
{
	public Button exitBtn;

	public Component submitHandler;

	public bool OnFocusClose;

	public bool OnCancelClose = true;

	public bool OnSubmitClose;

	public ConsoleUIItem target;

	public bool ResetOnQuit = true;

	public override void Hover()
	{
		GamepadControl.inst.nextSelected = gameObject;
	}

	public override void Focus()
	{
		if (OnFocusClose)
		{
			Exit();
		}
	}

	public override void Submit()
	{
		if (OnSubmitClose)
		{
			Exit();
		}
	}

	public override void Cancel()
	{
		if (OnCancelClose)
		{
			Exit();
		}
	}

	public void Exit()
	{
		ConsoleUIItem component = GetComponent<ConsoleUIItem>();
		if (ResetOnQuit)
		{
			if ((bool)target)
			{
				target.GetComponent<ConsoleUIItem>().Reset();
			}
			else
			{
				component.Reset();
			}
		}
		if (component.hightlightGameObject != null && component.gameObject.activeSelf)
		{
			component.hightlightGameObject.SetActive(value: false);
		}
		GamepadControl.inst.nextSelected = null;
		if ((bool)exitBtn)
		{
			exitBtn.onClick?.Invoke();
		}
		if (submitHandler != null)
		{
			((ISubmitHandler)submitHandler).OnSubmit(null);
		}
	}
}
