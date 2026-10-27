using UnityEngine;
using UnityEngine.EventSystems;

public class TerminalResizeHandle : MonoBehaviour, IBeginDragHandler, IEventSystemHandler, IDragHandler
{
	public TerminalUI terminalUI;

	public void OnBeginDrag(PointerEventData eventData)
	{
		if (terminalUI != null)
		{
			terminalUI.OnBeginDrag(eventData);
		}
	}

	public void OnDrag(PointerEventData eventData)
	{
		if (terminalUI != null)
		{
			terminalUI.OnDrag(eventData);
		}
	}
}
