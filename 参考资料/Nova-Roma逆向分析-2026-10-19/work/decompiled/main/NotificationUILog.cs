using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class NotificationUILog : MonoBehaviour
{
	public delegate void OnLogToggled(bool isVisible);

	public enum AnimationType
	{
		AdjustY,
		AdjustX
	}

	private struct NotificationTimeout(string id, float interval)
	{
		public string id = id;

		public float interval = interval;

		public float maxInterval = interval;
	}

	public EventTrigger DragEventTrigger;

	public RectTransform LogMaskRectT;

	public RectTransform LogScrollViewRectT;

	public NotificationUIEntry LogEntryPrefab;

	public Transform LogEntryContainer;

	public Button LogButton;

	public bool isLogDisplaying;

	public OnLogToggled onLogToggled;

	public static AnimationType[] Expand = new AnimationType[2]
	{
		AnimationType.AdjustX,
		AnimationType.AdjustY
	};

	public static AnimationType[] Shrink = new AnimationType[2]
	{
		AnimationType.AdjustY,
		AnimationType.AdjustX
	};

	public bool isAnimating;

	private int animIdx;

	private AnimationType[] animStages = Expand;

	public float animationSpeed = 6f;

	public float moveModifier = 150f;

	private Vector2 startDragSizeDelta;

	private Vector2 targetLogSize;

	public float flashSpeedModifier = 0.75f;

	private int entryCount;

	public const int ENTRY_MAX_COUNT = 30;

	private NotificationUIEntry[] entries = new NotificationUIEntry[30];

	private ArrayExt<NotificationTimeout> timeouts = new ArrayExt<NotificationTimeout>(32);

	private void SetTimeout(string id, float interval)
	{
		for (int i = 0; i < timeouts.Count; i++)
		{
			if (!(timeouts.data[i].id != id))
			{
				timeouts.data[i].interval = interval;
				timeouts.data[i].maxInterval = interval;
				return;
			}
		}
		timeouts.Add(new NotificationTimeout(id, interval));
	}

	private void Awake()
	{
		LogButton.onClick.AddListener(ToggleLog);
		EventTrigger.Entry entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.BeginDrag
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnBeginDrag((PointerEventData)data);
		});
		DragEventTrigger.triggers.Add(entry);
		EventTrigger.Entry entry2 = new EventTrigger.Entry
		{
			eventID = EventTriggerType.Drag
		};
		entry2.callback.AddListener((BaseEventData data) =>
		{
			OnDrag((PointerEventData)data);
		});
		DragEventTrigger.triggers.Add(entry2);
		targetLogSize = new Vector2(275f, 220f);
		for (int num = 0; num < 30; num++)
		{
			entries[num] = UnityEngine.Object.Instantiate(LogEntryPrefab, LogEntryContainer);
		}
		Player.onPlayerReset = (Player.OnPlayerEvent)Delegate.Combine(Player.onPlayerReset, new Player.OnPlayerEvent(Reset));
	}

	private void OnDestroy()
	{
		Player.onPlayerReset = (Player.OnPlayerEvent)Delegate.Remove(Player.onPlayerReset, new Player.OnPlayerEvent(Reset));
	}

	public void Tick(float udt)
	{
		int num = Mathff.Min(entryCount, 30);
		for (int i = 0; i < num; i++)
		{
			NotificationUIEntry notificationUIEntry = entries[i];
			if (notificationUIEntry.flashDuration > 0f)
			{
				notificationUIEntry.flashDuration = Mathff.Clamp01(notificationUIEntry.flashDuration - udt * flashSpeedModifier);
				Color flashColor = notificationUIEntry.flashColor;
				flashColor.a = notificationUIEntry.flashDuration * 0.5f;
				notificationUIEntry.flashImage.color = flashColor;
			}
		}
		for (int num2 = timeouts.Count - 1; num2 >= 0; num2--)
		{
			if (!float.IsInfinity(timeouts.data[num2].interval))
			{
				timeouts.data[num2].interval -= udt;
			}
			if (timeouts.data[num2].interval <= 0f)
			{
				timeouts.RemoveAtSwap(num2);
			}
		}
		if (isAnimating)
		{
			Vector2 size = LogMaskRectT.sizeDelta;
			Animate(udt, isLogDisplaying ? targetLogSize.x : 0f, isLogDisplaying ? targetLogSize.y : 45f, ref size);
			LogMaskRectT.sizeDelta = size;
		}
	}

	public void LogEntry(int groupID, string id, string message, NotificationStatus status, float interval, object GameObjectOrVector3, bool title)
	{
		int num = entryCount % 30;
		NotificationUIEntry notificationUIEntry = entries[num];
		Color colorOfStatus = NotificationUI.GetColorOfStatus(status);
		Util.SetActive(notificationUIEntry.titleContainer, title);
		Util.SetActive(notificationUIEntry.messageContainer, !title);
		TextMeshProUGUI textMeshProUGUI = (title ? notificationUIEntry.titleTMP : notificationUIEntry.messageTMP);
		if (!title && GameObjectOrVector3 != null)
		{
			message = "<sprite name=icon_magglass>" + message;
		}
		textMeshProUGUI.text = message;
		notificationUIEntry.groupID = groupID;
		notificationUIEntry.id = id;
		notificationUIEntry.status = status;
		notificationUIEntry.flashDuration = 1f;
		notificationUIEntry.flashColor = colorOfStatus;
		SetTimeout(id, interval);
		if (!(GameObjectOrVector3 is ICamTrackable focusedTrackable))
		{
			if (!(GameObjectOrVector3 is GameObject focusedObj))
			{
				if (!(GameObjectOrVector3 is Vector3 focusedPos))
				{
					if (GameObjectOrVector3 is MonoBehaviour monoBehaviour)
					{
						notificationUIEntry.focusedPos = monoBehaviour.transform.position;
						notificationUIEntry.btn.interactable = true;
					}
					else
					{
						notificationUIEntry.btn.interactable = false;
					}
				}
				else
				{
					notificationUIEntry.focusedPos = focusedPos;
					notificationUIEntry.btn.interactable = true;
				}
			}
			else
			{
				notificationUIEntry.focusedObj = focusedObj;
				notificationUIEntry.btn.interactable = true;
			}
		}
		else
		{
			notificationUIEntry.focusedTrackable = focusedTrackable;
			notificationUIEntry.btn.interactable = true;
		}
		notificationUIEntry.transform.SetAsFirstSibling();
		Util.SetActive(notificationUIEntry.gameObject, active: true);
		entryCount++;
	}

	public bool IsEntryValid(string id, float interval)
	{
		for (int i = 0; i < timeouts.Count; i++)
		{
			float num = timeouts.data[i].maxInterval - timeouts.data[i].interval;
			if (timeouts.data[i].id == id && (float.IsNaN(num) || num < interval))
			{
				return false;
			}
		}
		return true;
	}

	public void ToggleLog()
	{
		SetVisibility(!isLogDisplaying);
		SfxSystem.inst.PlayFromBank3DUIOneShot(isLogDisplaying ? "event:/SFX ASITP/UI/ui_messageBoard_open" : "event:/SFX ASITP/UI/ui_messageBoard_close", LogButton.transform.position);
		onLogToggled?.Invoke(isLogDisplaying);
	}

	public void SetVisibility(bool visible)
	{
		isLogDisplaying = visible;
		SetAnimation(isLogDisplaying ? Expand : Shrink);
	}

	private void OnBeginDrag(PointerEventData data)
	{
		startDragSizeDelta = LogScrollViewRectT.sizeDelta;
	}

	private void OnDrag(PointerEventData data)
	{
		RectTransformUtility.ScreenPointToLocalPointInRectangle(LogScrollViewRectT, data.pressPosition, data.pressEventCamera, out var localPoint);
		RectTransformUtility.ScreenPointToLocalPointInRectangle(LogScrollViewRectT, data.position, data.pressEventCamera, out var localPoint2);
		float num = localPoint2.y - localPoint.y;
		Vector2 sizeDelta = new Vector2(startDragSizeDelta.x, Mathf.Clamp(startDragSizeDelta.y + num, 100f, 500f));
		LogScrollViewRectT.sizeDelta = sizeDelta;
		LogMaskRectT.sizeDelta = sizeDelta;
		targetLogSize = sizeDelta;
	}

	public void SetAnimation(AnimationType[] type)
	{
		isAnimating = true;
		animStages = type;
		animIdx = 0;
	}

	public void Animate(float udt, float targetSizeX, float targetSizeY, ref Vector2 size)
	{
		if (!isAnimating && animIdx >= animStages.Length)
		{
			return;
		}
		switch (animStages[animIdx])
		{
		case AnimationType.AdjustX:
			size.x = GetInterpolatedValue(udt, size.x, targetSizeX);
			if (Mathff.DistSqrd(size.x, targetSizeX) < 0.001f)
			{
				animIdx++;
			}
			break;
		case AnimationType.AdjustY:
			size.y = GetInterpolatedValue(udt, size.y, targetSizeY);
			if (Mathff.DistSqrd(size.y, targetSizeY) < 0.001f)
			{
				animIdx++;
			}
			break;
		}
		if (animIdx == animStages.Length)
		{
			isAnimating = false;
			animIdx = 0;
		}
	}

	private float GetInterpolatedValue(float udt, float curr, float target)
	{
		curr = ((animIdx != animStages.Length - 1) ? Mathf.MoveTowards(curr, target, udt * (animationSpeed * moveModifier)) : Mathff.Lerp(curr, target, udt * animationSpeed));
		return curr;
	}

	private void Reset()
	{
		for (int i = 0; i < entries.Length; i++)
		{
			entries[i].gameObject.SetActive(value: false);
			entries[i].flashDuration = 0f;
		}
		timeouts.ClearFast();
	}
}
