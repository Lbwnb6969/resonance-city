using System;
using UnityEngine;
using UnityEngine.UI;

public class ConsoleUIScrollItem : ConsoleUISelectable
{
	public enum ScrollType
	{
		Incremental,
		Curve,
		Page
	}

	public enum Direction
	{
		Horizontal,
		Vertical,
		both
	}

	[NonSerialized]
	public ConsoleUIItem item;

	public float scrollSpeed = 1f;

	public bool animateScroll = true;

	public int itemsPerScroll = 1;

	public RectTransform root;

	public RectTransform container;

	public ScrollRect scrollRect;

	public ScrollType scrollType;

	public Direction direction = Direction.Vertical;

	public AnimationCurve curve;

	private Transform current;

	private float result;

	private float childIdx;

	private float childCount;

	private void Start()
	{
		if (scrollRect == null)
		{
			scrollRect = GetComponentInParent<ScrollRect>();
		}
		container = root.parent.GetComponent<RectTransform>();
		item = GetComponent<ConsoleUIItem>();
		if (itemsPerScroll > 1)
		{
			scrollType = ScrollType.Page;
		}
	}

	private void Update()
	{
		if (!item.isHovered)
		{
			return;
		}
		childCount = 0f;
		for (int i = 0; i < container.childCount; i++)
		{
			current = container.GetChild(i);
			if (current == root)
			{
				childIdx = childCount;
			}
			if (current.gameObject.activeSelf)
			{
				childCount++;
			}
		}
		if (childCount > 1f)
		{
			switch (scrollType)
			{
			case ScrollType.Incremental:
				result = 1f - childIdx / (childCount - 1f);
				break;
			case ScrollType.Page:
				result = 1f - (float)Mathf.FloorToInt(childIdx / (float)itemsPerScroll) / (float)Mathf.FloorToInt((childCount - 1f) / (float)itemsPerScroll);
				break;
			case ScrollType.Curve:
				result = 1f - curve.Evaluate(childIdx / (childCount - 1f));
				break;
			}
		}
		else
		{
			result = 0f;
		}
		if (animateScroll)
		{
			if (direction == Direction.Horizontal)
			{
				scrollRect.horizontalNormalizedPosition = Mathff.Lerp(scrollRect.horizontalNormalizedPosition, 1f - result, Time.unscaledDeltaTime * scrollSpeed);
			}
			else if (direction == Direction.Vertical)
			{
				scrollRect.verticalNormalizedPosition = Mathff.Lerp(scrollRect.verticalNormalizedPosition, result, Time.unscaledDeltaTime * scrollSpeed);
			}
		}
		else if (direction == Direction.Horizontal)
		{
			scrollRect.horizontalNormalizedPosition = 1f - result;
		}
		else if (direction == Direction.Vertical)
		{
			scrollRect.verticalNormalizedPosition = result;
		}
	}
}
