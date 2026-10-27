using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class TooltipHook : MonoBehaviour, IPointerEnterHandler, IEventSystemHandler, IPointerExitHandler, ISelectHandler, IDeselectHandler
{
	[NonSerialized]
	public bool isOver;

	[NonSerialized]
	public bool isValid = true;

	public bool disableForConsole;

	public RectTransform consoleAnchor;

	[TextArea]
	public string toolTipText = "";

	public string tooltipTerm;

	public static List<TooltipHook> hooks = new List<TooltipHook>();

	public void OnPointerEnter(PointerEventData eventData)
	{
		isOver = true;
	}

	public void OnPointerExit(PointerEventData eventData)
	{
		isOver = false;
	}

	public void OnSelect(BaseEventData eventData)
	{
		isOver = !disableForConsole;
	}

	public void OnDeselect(BaseEventData eventData)
	{
		isOver = false;
	}

	private void OnEnable()
	{
		hooks.Add(this);
	}

	private void OnDisable()
	{
		hooks.Remove(this);
		isOver = false;
	}
}
