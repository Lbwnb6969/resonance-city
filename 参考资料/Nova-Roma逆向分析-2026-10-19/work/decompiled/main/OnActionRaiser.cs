using System;

public class OnActionRaiser<T>
{
	public event EventHandler<T> OnAction;

	public bool IsEmpty()
	{
		return OnAction == null;
	}

	public void Invoke(T action)
	{
		OnAction?.Invoke(this, action);
	}

	public void ClearAll()
	{
		if (OnAction != null)
		{
			Delegate[] invocationList = OnAction.GetInvocationList();
			for (int i = 0; i < invocationList.Length; i++)
			{
				EventHandler<T> value = (EventHandler<T>)invocationList[i];
				OnAction -= value;
			}
		}
	}
}
