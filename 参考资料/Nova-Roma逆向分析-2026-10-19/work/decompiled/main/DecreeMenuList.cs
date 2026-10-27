using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class DecreeMenuList : MonoBehaviour, IDropHandler, IEventSystemHandler
{
	public Transform spacer;

	private RectTransform rect;

	public ScrollRect scrollView;

	private RectTransform scrollViewRect;

	private float scrolling;

	private void Start()
	{
		if (!(Util.FindInParents<Canvas>(gameObject) == null))
		{
			EventTrigger component = GetComponent<EventTrigger>();
			EventTrigger.Entry entry = new EventTrigger.Entry
			{
				eventID = EventTriggerType.Drop
			};
			entry.callback.AddListener((BaseEventData data) =>
			{
				OnDrop((PointerEventData)data);
			});
			component.triggers.Add(entry);
			rect = GetComponent<RectTransform>();
			scrollViewRect = scrollView.GetComponent<RectTransform>();
		}
	}

	public void ItemRaycasting(bool on)
	{
		foreach (Transform item in transform)
		{
			Image component = item.GetComponent<Image>();
			if (component != null)
			{
				component.raycastTarget = on;
			}
		}
	}

	public bool HandleDragging(PointerEventData eventData)
	{
		if (RectTransformUtility.RectangleContainsScreenPoint(scrollViewRect, eventData.position, eventData.pressEventCamera))
		{
			RectTransformUtility.ScreenPointToLocalPointInRectangle(rect, eventData.position, eventData.pressEventCamera, out var localPoint);
			spacer.SetParent(base.transform);
			int num = (int)(Mathf.Abs(localPoint.y) / Mathf.Abs(spacer.GetComponent<RectTransform>().sizeDelta.y));
			int num2 = 0;
			foreach (Transform item in base.transform)
			{
				if (num == 0)
				{
					break;
				}
				if (item.gameObject.activeInHierarchy)
				{
					num--;
				}
				num2++;
			}
			spacer.SetSiblingIndex(num2);
			scrolling = 0f;
			return true;
		}
		RectTransformUtility.ScreenPointToLocalPointInRectangle(scrollViewRect, eventData.position, eventData.pressEventCamera, out var localPoint2);
		if (localPoint2.y + scrollViewRect.rect.y > 0f)
		{
			scrolling = Time.unscaledDeltaTime * Mathff.Clamp01((localPoint2.y + scrollViewRect.rect.y) / 80f) * 2f;
		}
		if (localPoint2.y < scrollViewRect.rect.y)
		{
			scrolling = Time.unscaledDeltaTime * Mathff.Clamp01((scrollViewRect.rect.y - localPoint2.y) / 80f) * -2f;
		}
		if (scrolling > 0f)
		{
			spacer.SetParent(transform);
			spacer.SetSiblingIndex(0);
			return true;
		}
		if (scrolling < 0f)
		{
			spacer.SetParent(transform);
			spacer.SetSiblingIndex(transform.childCount - 1);
			return true;
		}
		return false;
	}

	public void Update()
	{
		if (Mathf.Abs(scrolling) > 0.0001f)
		{
			scrollView.verticalNormalizedPosition = Mathf.Clamp01(scrollView.verticalNormalizedPosition + scrolling);
		}
	}

	public void DropoffItem()
	{
		scrolling = 0f;
	}

	public void OnDrop(PointerEventData eventData)
	{
		if (eventData.pointerDrag != null && (bool)eventData.pointerDrag.GetComponent<DragableDecreeItem>())
		{
			eventData.pointerDrag.transform.SetParent(transform);
			eventData.pointerDrag.transform.SetSiblingIndex(spacer.GetSiblingIndex());
			eventData.pointerDrag.GetComponent<DragableDecreeItem>().DroppedCorrectly();
		}
		scrolling = 0f;
	}
}
