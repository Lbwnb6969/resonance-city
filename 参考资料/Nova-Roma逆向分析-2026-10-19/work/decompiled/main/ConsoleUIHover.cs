using UnityEngine;
using UnityEngine.EventSystems;

public class ConsoleUIHover : ConsoleUISelectable
{
	[SerializeField]
	public Component enterEvent;

	[SerializeField]
	public Component selectEvent;

	[SerializeField]
	public Component exitEvent;

	[SerializeField]
	public Component deselectEvent;

	[SerializeField]
	public EventTrigger eventTrigger;

	public override void Hover()
	{
		if (enterEvent != null)
		{
			enterEvent.GetComponent<IPointerEnterHandler>().OnPointerEnter(null);
		}
		if (selectEvent != null)
		{
			selectEvent.GetComponent<ISelectHandler>().OnSelect(null);
		}
		if ((bool)eventTrigger)
		{
			eventTrigger.OnPointerEnter(null);
			eventTrigger.OnSelect(null);
		}
	}

	public override void Dehover()
	{
		if (exitEvent != null)
		{
			exitEvent.GetComponent<IPointerExitHandler>().OnPointerExit(null);
		}
		if (deselectEvent != null)
		{
			deselectEvent.GetComponent<IDeselectHandler>().OnDeselect(null);
		}
		if ((bool)eventTrigger)
		{
			eventTrigger.OnPointerExit(null);
			eventTrigger.OnDeselect(null);
		}
	}

	public override void Reset()
	{
		ConsoleUIItem component = GetComponent<ConsoleUIItem>();
		if (component != null && component.isHovered)
		{
			Dehover();
		}
	}
}
