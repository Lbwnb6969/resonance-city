using I2.Loc;
using UnityEngine;

public class ConsoleUI : MonoBehaviour
{
	protected bool hasActivated;

	public string LocalizationString = "";

	public virtual void Reset()
	{
	}

	public virtual void Submit()
	{
	}

	public virtual void Cancel()
	{
	}

	public virtual void Hover()
	{
	}

	public virtual void Dehover()
	{
	}

	public virtual void Focus()
	{
	}

	public virtual void CustomActivate()
	{
	}

	public void ActivateInput()
	{
		if (!hasActivated)
		{
			CustomActivate();
			hasActivated = true;
		}
	}

	public virtual void CustomDeactivate()
	{
	}

	public void DeactivateInput()
	{
		if (hasActivated)
		{
			CustomDeactivate();
			hasActivated = false;
		}
	}

	public virtual string GetTooltip()
	{
		string text = "";
		ConsoleUISelectable[] components = GetComponents<ConsoleUISelectable>();
		for (int i = 0; i < components.Length; i++)
		{
			text += components[i].GetTooltip();
		}
		if (!string.IsNullOrEmpty(LocalizationString))
		{
			text += LocalizationManager.GetTranslation(LocalizationString);
		}
		return text;
	}
}
