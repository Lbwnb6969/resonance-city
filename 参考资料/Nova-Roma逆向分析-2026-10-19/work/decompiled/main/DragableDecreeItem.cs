using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class DragableDecreeItem : MonoBehaviour
{
	public delegate void LateSnapPosition();

	private RectTransform m_DraggingPlane;

	public GameObject follower;

	public ScrollRect scrollRect;

	public bool isConsoleSelected;

	private Transform startParent;

	private Transform startParentContent;

	private int startSiblingIndex;

	private Vector2 grabOffset;

	private bool dragging;

	private bool droppedCorrectly;

	private bool snapRequired;

	public LateSnapPosition CustomSnapPosition;

	private void Start()
	{
		m_DraggingPlane = transform.parent.GetComponent<RectTransform>();
		EventTrigger component = GetComponent<EventTrigger>();
		EventTrigger.Entry entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.BeginDrag
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnBeginDrag((PointerEventData)data);
		});
		component.triggers.Add(entry);
		EventTrigger.Entry entry2 = new EventTrigger.Entry
		{
			eventID = EventTriggerType.Drag
		};
		entry2.callback.AddListener((BaseEventData data) =>
		{
			OnDrag((PointerEventData)data);
		});
		component.triggers.Add(entry2);
		EventTrigger.Entry entry3 = new EventTrigger.Entry
		{
			eventID = EventTriggerType.EndDrag
		};
		entry3.callback.AddListener((BaseEventData data) =>
		{
			EndDrag((PointerEventData)data);
		});
		component.triggers.Add(entry3);
		EventTrigger.Entry entry4 = new EventTrigger.Entry
		{
			eventID = EventTriggerType.Scroll
		};
		entry4.callback.AddListener((BaseEventData data) =>
		{
			Scroll((PointerEventData)data);
		});
		component.triggers.Add(entry4);
		CustomSnapPosition = SnapFollowerPosition;
	}

	public void Scroll(PointerEventData eventData)
	{
		scrollRect.OnScroll(eventData);
	}

	public void OnBeginDrag(PointerEventData eventData)
	{
	}

	public void OnDrag(PointerEventData eventData)
	{
		if (RectTransformUtility.ScreenPointToWorldPointInRectangle(m_DraggingPlane, eventData.position - grabOffset, eventData.pressEventCamera, out var worldPoint))
		{
			transform.position = worldPoint;
		}
	}

	public void EndDrag(PointerEventData eventData)
	{
	}

	public void DroppedCorrectly()
	{
		droppedCorrectly = true;
	}

	private void Update()
	{
		if (dragging)
		{
			follower.transform.position = transform.position;
		}
		else if (!isConsoleSelected)
		{
			follower.transform.position = Vector3.MoveTowards(follower.transform.position, transform.position, Time.unscaledDeltaTime * 10f);
		}
	}

	public void SnapFollowerPosition()
	{
		follower.transform.position = transform.position;
	}

	private void LateUpdate()
	{
		if (snapRequired)
		{
			snapRequired = false;
			CustomSnapPosition();
		}
	}

	public void SnapPosition()
	{
		snapRequired = true;
	}

	private void OnEnable()
	{
		follower.transform.position = transform.position;
		follower.SetActive(value: true);
	}

	private void OnDisable()
	{
		follower.SetActive(value: false);
	}
}
