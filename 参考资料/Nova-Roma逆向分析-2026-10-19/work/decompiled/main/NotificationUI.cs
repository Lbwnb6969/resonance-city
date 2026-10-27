using System;
using System.Collections;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.UI;

public class NotificationUI : MonoBehaviour
{
	[Serializable]
	public struct NotificationGroupOptions
	{
		public int groupID;

		private static IEnumerable GroupIDs = new ValueDropdownList<int>
		{
			{ "General Group", GeneralGroup },
			{ "Home Group", HomeGroup },
			{ "Fire Group", FireGroup },
			{ "Low Food Group", LowFoodGroup },
			{ "Plague Group", PlagueGroup }
		};

		public Sprite icon;

		public Color iconColor;

		public Color btnColor;
	}

	public enum AnimationType
	{
		AdjustY,
		AdjustX
	}

	public struct NotificationMessage
	{
		public string single;

		public string multiple;

		public string individual;

		public string tail;

		public NotificationStatus status;
	}

	public static NotificationUI inst;

	public static int GeneralGroup = 0;

	public static int HomeGroup = 10;

	public static int FireGroup = 20;

	public static int LowFoodGroup = 30;

	public static int PlagueGroup = 40;

	public List<NotificationGroupOptions> groupPrefabs;

	public NotificationUIGroup notificationPrefab;

	private List<NotificationUIGroup> notificationGroups = new List<NotificationUIGroup>(32);

	public Transform notificationContainer;

	public Transform dummyNotificationContainer;

	public RectTransform dummyNotificationPrefab;

	public NotificationUILog LogUI;

	public float moveSpeed = 1f;

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

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
		NotificationUILog logUI = LogUI;
		logUI.onLogToggled = (NotificationUILog.OnLogToggled)Delegate.Combine(logUI.onLogToggled, new NotificationUILog.OnLogToggled(OnLogToggled));
		NotificationUIGroup.onGroupLeftClicked = (NotificationUIGroup.OnGroupClicked)Delegate.Combine(NotificationUIGroup.onGroupLeftClicked, new NotificationUIGroup.OnGroupClicked(OnGroupLeftClicked));
		Player.onPlayerReset = (Player.OnPlayerEvent)Delegate.Combine(Player.onPlayerReset, new Player.OnPlayerEvent(Reset));
		SetVisibility(v: true);
	}

	private void OnDestroy()
	{
		Player.onPlayerReset = (Player.OnPlayerEvent)Delegate.Remove(Player.onPlayerReset, new Player.OnPlayerEvent(Reset));
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		LogUI.Tick(unscaledDeltaTime);
		for (int i = 0; i < notificationGroups.Count; i++)
		{
			NotificationUIGroup notificationUIGroup = notificationGroups[i];
			notificationUIGroup.Tick(unscaledDeltaTime);
			int childIndex = Util.GetChildIndex(notificationUIGroup.transform, notificationContainer);
			Transform childAtIndex = Util.GetChildAtIndex(dummyNotificationContainer.childCount - 1 - childIndex, dummyNotificationContainer);
			float preferredHeight = notificationUIGroup.TargetRect.sizeDelta.y;
			if (!notificationUIGroup.isDisplayingText)
			{
				preferredHeight = 30f;
			}
			childAtIndex.GetComponent<LayoutElement>().preferredHeight = preferredHeight;
			Vector3 position = notificationUIGroup.transform.position;
			position = Vector3.Lerp(position, childAtIndex.position, unscaledDeltaTime * moveSpeed);
			notificationUIGroup.transform.position = position;
		}
	}

	public void Reset()
	{
		for (int i = 0; i < notificationGroups.Count; i++)
		{
			notificationGroups[i].SetVisibility(v: false);
		}
	}

	private void OnLogToggled(bool isVisible)
	{
		if (isVisible)
		{
			for (int i = 0; i < notificationGroups.Count; i++)
			{
				notificationGroups[i].SetTextVisibility(isDisplaying: false);
			}
		}
	}

	public void HideNotificationGroups()
	{
		for (int i = 0; i < notificationGroups.Count; i++)
		{
			notificationGroups[i].SetTextVisibility(isDisplaying: false);
		}
	}

	private void OnGroupLeftClicked(NotificationUIGroup group)
	{
		if (group.isVisible && group.isDisplayingText)
		{
			LogUI.SetVisibility(visible: false);
		}
	}

	public static void TryLog(int groupID, string id, string message, NotificationStatus status, float interval = 20f, object GameObjectOrVector3 = null, bool title = false, int landmass = -1)
	{
		if (!(inst == null))
		{
			inst.InternalTryLog(groupID, id, message, status, interval, GameObjectOrVector3, title, landmass);
		}
	}

	private void InternalTryLog(int groupID, string id, string message, NotificationStatus status, float interval, object GameObjectOrVector3, bool title, int landmass)
	{
		if (LogUI.IsEntryValid(id, interval))
		{
			LogUI.LogEntry(groupID, id, message, status, interval, GameObjectOrVector3, title);
		}
	}

	public static void TryNotify(int groupID, int instID, string id, NotificationMessage message, NotificationStatus status = NotificationStatus.Neutral, float interval = 20f, object GameObjectOrVector3 = null, bool title = false, int landmass = -1)
	{
		if (!(inst == null))
		{
			inst.InternalTryNotify(groupID, instID, id, message, status, interval, GameObjectOrVector3, title, landmass);
		}
	}

	public static void TryNotify(int groupID, int instID, string id, NotificationMessage message, float interval = 20f, object GameObjectOrVector3 = null, bool title = false, int landmass = -1)
	{
		if (!(inst == null))
		{
			inst.InternalTryNotify(groupID, instID, id, message, message.status, interval, GameObjectOrVector3, title, landmass);
		}
	}

	private void InternalTryNotify(int groupID, int instID, string id, NotificationMessage message, NotificationStatus status, float interval, object GameObjectOrVector3, bool title, int landmass)
	{
		if (!LogUI.IsEntryValid(id, interval))
		{
			return;
		}
		LogUI.LogEntry(groupID, id, message.single, status, interval, GameObjectOrVector3, title);
		NotificationUIGroup notificationUIGroup = null;
		for (int i = 0; i < notificationGroups.Count; i++)
		{
			NotificationUIGroup notificationUIGroup2 = notificationGroups[i];
			if (notificationUIGroup2.isVisible && groupID == notificationUIGroup2.groupID && notificationUIGroup2.instID == instID && instID != -1)
			{
				notificationUIGroup = notificationUIGroup2;
				break;
			}
			if (!notificationUIGroup2.isVisible && groupID == notificationUIGroup2.groupID)
			{
				notificationUIGroup = notificationUIGroup2;
				break;
			}
		}
		if (notificationUIGroup != null)
		{
			if (notificationUIGroup.isVisible)
			{
				notificationUIGroup.AppendMessage(message, GameObjectOrVector3);
			}
			else
			{
				notificationUIGroup.Init(groupID, instID, message, status, GameObjectOrVector3);
			}
			return;
		}
		UnityEngine.Object.Instantiate(dummyNotificationPrefab, dummyNotificationContainer);
		NotificationUIGroup notificationUIGroup3 = UnityEngine.Object.Instantiate(notificationPrefab, notificationContainer);
		if (GetGroupData(groupID, out var icon, out var iconColor, out var btnColor))
		{
			notificationUIGroup3.iconImage.sprite = icon;
			notificationUIGroup3.iconImage.color = iconColor;
			notificationUIGroup3.buttonImage.color = btnColor;
			notificationUIGroup3.Init(groupID, instID, message, status, GameObjectOrVector3);
		}
		else
		{
			Debug.Log("Notification Group Does Not Exist");
		}
		notificationGroups.Add(notificationUIGroup3);
	}

	public bool GetGroupData(int groupID, out Sprite icon, out Color iconColor, out Color btnColor)
	{
		for (int i = 0; i < groupPrefabs.Count; i++)
		{
			if (groupPrefabs[i].groupID == groupID)
			{
				icon = groupPrefabs[i].icon;
				iconColor = groupPrefabs[i].iconColor;
				btnColor = groupPrefabs[i].btnColor;
				return true;
			}
		}
		icon = null;
		iconColor = default;
		btnColor = default;
		return false;
	}

	public static Color GetColorOfStatus(NotificationStatus status)
	{
		return status switch
		{
			NotificationStatus.Important => Color.cyan, 
			NotificationStatus.Warning => Color.yellow, 
			NotificationStatus.Neutral => Color.white, 
			_ => Color.white, 
		};
	}
}
