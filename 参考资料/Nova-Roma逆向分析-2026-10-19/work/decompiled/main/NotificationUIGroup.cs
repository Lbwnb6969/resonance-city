using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class NotificationUIGroup : MonoBehaviour, ICamTrackable
{
	public enum AnimationType
	{
		AdjustY,
		AdjustX
	}

	public delegate void OnGroupClicked(NotificationUIGroup group);

	public RectTransform FollowerRect;

	public RectTransform TargetRect;

	public GameObject subCount;

	public TextMeshProUGUI subCountText;

	public TextMeshProUGUI TMP_Text;

	public Button TMP_Button;

	public Image buttonImage;

	public Image iconImage;

	public Button iconBtn;

	public EventTrigger btnTrigger;

	public EventTrigger groupTrigger;

	public Button focusBtn;

	public Button closeBtn;

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

	public int groupID;

	public int instID = -1;

	public bool isVisible = true;

	public bool isDisplayingText;

	public bool isHovered;

	public Timer hideDisplayingTextTimer = new Timer(30f);

	public Timer hideGroupTimer = new Timer(15f);

	private List<string> individuals = new List<string>(32);

	private List<object> trackingObjs = new List<object>(32);

	public static OnGroupClicked onGroupLeftClicked;

	public static OnGroupClicked onGroupRightClicked;

	private GameObject currTrackingObj;

	private Vector3 currTrackingPos;

	private ICamTrackable currTrackable;

	private void Awake()
	{
		iconBtn.onClick.AddListener(OnGroupLeftClicked);
		TMP_Button.onClick.AddListener(OnTextClicked);
		closeBtn.onClick.AddListener(OnGroupLeftClicked);
		focusBtn.onClick.AddListener(() =>
		{
			TryTrackObject(trackingObjs[0]);
		});
		EventTrigger.Entry entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerClick;
		entry.callback.AddListener((BaseEventData eventData) =>
		{
			OnGroupRightClicked((PointerEventData)eventData);
		});
		btnTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerEnter;
		entry.callback.AddListener((BaseEventData eventData) =>
		{
			isHovered = true;
		});
		groupTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerExit;
		entry.callback.AddListener((BaseEventData eventData) =>
		{
			isHovered = false;
		});
		groupTrigger.triggers.Add(entry);
	}

	public void Init(int gID, int iID, NotificationUI.NotificationMessage message, NotificationStatus status, object GameObjectOrVector3)
	{
		groupID = gID;
		instID = iID;
		string text = message.single;
		if (!string.IsNullOrEmpty(message.tail))
		{
			text = text + " " + message.tail;
		}
		TMP_Text.text = text;
		TMP_Text.color = NotificationUI.GetColorOfStatus(status);
		individuals.Clear();
		individuals.Add(message.individual);
		trackingObjs.Clear();
		if (GameObjectOrVector3 != null)
		{
			trackingObjs.Add(GameObjectOrVector3);
		}
		focusBtn.gameObject.SetActive(trackingObjs.Count > 0);
		transform.SetAsFirstSibling();
		SetVisibility(v: true, !NotificationUI.inst.LogUI.isLogDisplaying);
	}

	public void AppendMessage(NotificationUI.NotificationMessage message, object gameObjectOrVector3)
	{
		if (message.individual == string.Empty)
		{
			return;
		}
		individuals.Add(message.individual);
		trackingObjs.Add(gameObjectOrVector3);
		subCountText.text = individuals.Count.ToString();
		subCount.SetActive(individuals.Count > 1);
		string text = message.multiple;
		for (int num = individuals.Count - 1; num >= 0; num--)
		{
			if (num != individuals.Count - 1)
			{
				text += ", ";
			}
			text += ((trackingObjs[num] != null) ? $"<link={num}><color=#00FFFF><u>{individuals[num]}</u></color></link>" : (individuals[num] ?? ""));
			if (num == individuals.Count - 1)
			{
				text += ".";
			}
		}
		if (!string.IsNullOrEmpty(message.tail))
		{
			text = text + " " + message.tail;
		}
		TMP_Text.text = text;
	}

	public void Tick(float udt)
	{
		if (isAnimating)
		{
			float targetSizeX = (isDisplayingText ? TargetRect.sizeDelta.x : 0f);
			float targetSizeY = (isDisplayingText ? TargetRect.sizeDelta.y : 30f);
			Vector2 size = FollowerRect.sizeDelta;
			Animate(udt, targetSizeX, targetSizeY, ref size);
			FollowerRect.sizeDelta = size;
		}
		if (isDisplayingText)
		{
			if (!isAnimating)
			{
				FollowerRect.sizeDelta = TargetRect.sizeDelta;
			}
			if (!isHovered && hideDisplayingTextTimer.Update(udt))
			{
				SetTextVisibility(isDisplaying: false);
			}
		}
		if (isVisible && !isDisplayingText && hideGroupTimer.Update(udt))
		{
			SetVisibility(v: false);
		}
	}

	public void SetVisibility(bool v, bool displayText = false)
	{
		isVisible = v;
		SetAnimation(displayText ? Expand : Shrink);
		isDisplayingText = displayText;
		hideDisplayingTextTimer.Reset();
		hideGroupTimer.Reset();
		gameObject.SetActive(v);
	}

	public void SetTextVisibility(bool isDisplaying)
	{
		if (isDisplaying != isDisplayingText)
		{
			isDisplayingText = isDisplaying;
			hideDisplayingTextTimer.Reset();
			SetAnimation(isDisplayingText ? Expand : Shrink);
		}
	}

	public void ToggleTextVisibility()
	{
		isDisplayingText = !isDisplayingText;
		hideDisplayingTextTimer.Reset();
		if (isDisplayingText)
		{
			SfxSystem.PlayUiSelect();
		}
		else
		{
			SfxSystem.PlayUiCancel();
		}
		SetAnimation(isDisplayingText ? Expand : Shrink);
	}

	private void OnGroupLeftClicked()
	{
		ToggleTextVisibility();
		onGroupLeftClicked?.Invoke(this);
	}

	private void OnGroupRightClicked(PointerEventData eventData)
	{
		if (eventData.button == PointerEventData.InputButton.Right)
		{
			gameObject.SetActive(value: false);
			SfxSystem.PlayUiCancel();
			onGroupRightClicked?.Invoke(this);
		}
	}

	private void OnTextClicked()
	{
		int num = TMP_TextUtilities.FindIntersectingLink(TMP_Text, Input.mousePosition, GUICamera.inst.cam);
		if (num == -1)
		{
			for (int num2 = trackingObjs.Count - 1; num2 >= 0; num2--)
			{
				if (trackingObjs[num2] != null)
				{
					TryTrackObject(trackingObjs[0]);
					break;
				}
			}
		}
		else
		{
			TMP_LinkInfo tMP_LinkInfo = TMP_Text.textInfo.linkInfo[num];
			if (int.TryParse(tMP_LinkInfo.GetLinkID(), out var result) && trackingObjs.Count > result)
			{
				TryTrackObject(trackingObjs[result]);
			}
		}
	}

	private void TryTrackObject(object obj)
	{
		if (obj != null)
		{
			if (obj is Vector3 vector)
			{
				currTrackingPos = vector;
				Cam.inst.Track(this);
			}
			else if (obj is ICamTrackable track)
			{
				currTrackable = track;
				Cam.inst.Track(track);
			}
			else if (obj is GameObject gameObject)
			{
				currTrackingObj = gameObject;
				Cam.inst.Track(this);
			}
			else if (obj is MonoBehaviour monoBehaviour)
			{
				currTrackingPos = monoBehaviour.transform.position;
				Cam.inst.Track(this);
			}
		}
	}

	public Vector3 GetDesiredTrackingPos()
	{
		if (currTrackingObj != null)
		{
			currTrackingPos = currTrackingObj.transform.position;
		}
		return currTrackingPos;
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
}
