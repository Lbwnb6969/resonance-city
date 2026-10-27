using UnityEngine;
using UnityEngine.EventSystems;

public class LogisticsDestUIHover : MonoBehaviour, IPointerEnterHandler, IEventSystemHandler, IPointerExitHandler
{
	public enum ContainerType
	{
		Pickup,
		Dropoff
	}

	public LogisticsDestUI parent;

	public ContainerType type;

	private void Awake()
	{
		if (parent == null)
		{
			parent = GetComponentInParent<LogisticsDestUI>();
		}
	}

	public void OnPointerEnter(PointerEventData eventData)
	{
		if (type == ContainerType.Pickup)
		{
			parent.OnPickUpEnter();
		}
		else
		{
			parent.OnDropOffEnter();
		}
	}

	public void OnPointerExit(PointerEventData eventData)
	{
		if (type == ContainerType.Pickup)
		{
			parent.OnPickUpExit();
		}
		else
		{
			parent.OnDropOffExit();
		}
	}
}
