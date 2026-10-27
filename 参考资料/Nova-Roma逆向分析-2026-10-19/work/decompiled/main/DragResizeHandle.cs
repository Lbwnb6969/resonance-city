using Rewired;
using UnityEngine;
using UnityEngine.EventSystems;

public class DragResizeHandle : MonoBehaviour
{
	public RectTransform rectTransform;

	public EventTrigger eventTrigger;

	public RectTransform arrow;

	public SlideAnim anim;

	public float minSize = 45f;

	public float maxSize = 400f;

	public float openCloseSnappiness = 20f;

	private bool shrink;

	private bool expand;

	private bool minMode;

	private Vector2 startSizeDelta;

	private Vector2 startPosition;

	private float expandTimer;

	public float gamepadMinSize = 150f;

	public float gamepadMaxSize = 300f;

	public float gamepadRestoreTime = 10f;

	private void Start()
	{
		EventTrigger.Entry entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.BeginDrag
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnBeginDrag((PointerEventData)data);
		});
		eventTrigger.triggers.Add(entry);
		EventTrigger.Entry entry2 = new EventTrigger.Entry
		{
			eventID = EventTriggerType.Drag
		};
		entry2.callback.AddListener((BaseEventData data) =>
		{
			OnDrag((PointerEventData)data);
		});
		eventTrigger.triggers.Add(entry2);
		EventTrigger.Entry entry3 = new EventTrigger.Entry
		{
			eventID = EventTriggerType.EndDrag
		};
		entry3.callback.AddListener((BaseEventData data) =>
		{
			OnEndDrag((PointerEventData)data);
		});
		eventTrigger.triggers.Add(entry3);
		EventTrigger.Entry entry4 = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerClick
		};
		entry4.callback.AddListener((BaseEventData data) =>
		{
			OnClick((PointerEventData)data);
		});
		eventTrigger.triggers.Add(entry4);
	}

	private void OnClick(PointerEventData data)
	{
		startSizeDelta = rectTransform.sizeDelta;
		shrink = rectTransform.sizeDelta.y.Remap(minSize, maxSize, 0f, 1f) > 0.5f;
		expand = !shrink;
		expand = !shrink;
		minMode = false;
	}

	private void OnBeginDrag(PointerEventData data)
	{
		startSizeDelta = rectTransform.sizeDelta;
		shrink = false;
		expand = false;
		minMode = false;
	}

	private void OnDrag(PointerEventData data)
	{
		RectTransformUtility.ScreenPointToLocalPointInRectangle(rectTransform, data.pressPosition, data.pressEventCamera, out var localPoint);
		RectTransformUtility.ScreenPointToLocalPointInRectangle(rectTransform, data.position, data.pressEventCamera, out var localPoint2);
		float num = localPoint.y - localPoint2.y;
		Vector2 sizeDelta = new Vector2(startSizeDelta.x, Mathf.Clamp(startSizeDelta.y + num, minSize, maxSize));
		rectTransform.sizeDelta = sizeDelta;
	}

	private void OnEndDrag(PointerEventData data)
	{
		shrink = false;
		expand = false;
		if (rectTransform.sizeDelta.y <= minSize + 0.001f)
		{
			minMode = true;
		}
	}

	public void MinSize(float minSize)
	{
		this.minSize = minSize + 18f;
	}

	private void Update()
	{
		if (GamepadControl.inst.isControllerActive)
		{
			Rewired.Player player = GamepadControl.inst.player;
			if (player.GetButton("D-Pad Up") || player.GetButton("D-Pad Down"))
			{
				expandTimer = gamepadRestoreTime;
			}
			else if (player.GetAnyButton())
			{
				expandTimer = 0f;
			}
			Vector2 sizeDelta = rectTransform.sizeDelta;
			if (expandTimer <= 0f)
			{
				sizeDelta.y -= (sizeDelta.y - (gamepadMinSize - 10f)) * Time.unscaledDeltaTime * openCloseSnappiness;
			}
			else
			{
				sizeDelta.y += (gamepadMaxSize + 10f - sizeDelta.y) * Time.unscaledDeltaTime * openCloseSnappiness;
			}
			sizeDelta.y = Mathf.Clamp(sizeDelta.y, gamepadMinSize, gamepadMaxSize);
			rectTransform.sizeDelta = sizeDelta;
			return;
		}
		if (minMode)
		{
			Vector2 sizeDelta2 = rectTransform.sizeDelta;
			sizeDelta2.y = Mathf.MoveTowards(sizeDelta2.y, minSize, Time.unscaledDeltaTime * 100f);
			rectTransform.sizeDelta = sizeDelta2;
		}
		if (shrink || expand)
		{
			Vector2 sizeDelta3 = rectTransform.sizeDelta;
			if (shrink)
			{
				sizeDelta3.y -= (sizeDelta3.y - (minSize - 10f)) * Time.unscaledDeltaTime * openCloseSnappiness;
			}
			else
			{
				sizeDelta3.y += (maxSize + 10f - sizeDelta3.y) * Time.unscaledDeltaTime * openCloseSnappiness;
			}
			sizeDelta3.y = Mathf.Clamp(sizeDelta3.y, minSize, maxSize);
			if (shrink && sizeDelta3.y <= minSize + 0.001f)
			{
				shrink = false;
				minMode = true;
			}
			if (expand && sizeDelta3.y >= maxSize - 0.001f)
			{
				expand = false;
			}
			rectTransform.sizeDelta = sizeDelta3;
		}
		bool flag = rectTransform.sizeDelta.y.Remap(minSize, maxSize, 0f, 1f) > 0.5f;
		anim.Play((!flag) ? SlideAnim.PlayMode.Forward : SlideAnim.PlayMode.Reverse);
		int num = (flag ? 180 : 0);
		arrow.rotation = Quaternion.RotateTowards(arrow.rotation, Quaternion.Euler(num, 0f, -90f), Time.unscaledDeltaTime * 360f * 2f);
	}
}
