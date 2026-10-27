using System;
using System.Collections.Generic;
using UnityEngine;

public class MiniMapViewer : MonoBehaviour
{
	public enum Status
	{
		Hiding,
		Hidden,
		Showing,
		Shown,
		Expanding,
		BannerBounce,
		BannerToTab,
		None
	}

	public enum NotificationGroup
	{
		Vikings,
		Dragons,
		Merchant,
		NumOfGroups
	}

	public delegate void OnFinsihedAnimation();

	private struct AnimationItem
	{
		public int idx;

		public Vector3 start;

		public RectTransform banner;

		public RectTransform tab;

		public float animTime;

		public float animOffset;

		public float holdTime;

		public Queue<Status> stages;

		public OnFinsihedAnimation OnFinsihedAnimation;
	}

	public MiniMapUI miniMapUI;

	private RectTransform miniMapRect;

	private RectTransform rect;

	public RectTransform bannerAnchorPoint;

	public RectTransform[] tabs;

	public RectTransform[] banners;

	private float mapSizeOffset;

	private float[] animationSizeOffsets = new float[3];

	private const float ExpandedSize = 160f;

	private const float ShowSize = 135f;

	private const float HideSize = 0f;

	private Queue<AnimationItem> animationQueue = new Queue<AnimationItem>(3);

	private Status status = Status.None;

	public float BounceDuration = 0.33f;

	public float HoldTime = -1f;

	public float FadeDuration = 1f;

	public float TotalClimb = 2f;

	public float StartHeight = 1f;

	public float ShiftUpSpeedMultiplier = 2f;

	public float OffsetTarget = 1f;

	public float TabExpandSpeed = 2f;

	public float BannerToTabSpeed = 2f;

	private AnimationItem animationItem;

	private void Start()
	{
		rect = GetComponent<RectTransform>();
		miniMapRect = MiniMapUI.inst.rect;
	}

	private void SetStatus(Status s)
	{
		if (s == Status.BannerBounce)
		{
			animationItem.banner.gameObject.SetActive(value: true);
			animationItem.banner.localScale = new Vector3(1f, 1f, 1f);
		}
		status = s;
	}

	private Status NextStage(ref Queue<Status> stages)
	{
		Status result = Status.None;
		if (stages.Count == 0)
		{
			animationItem.OnFinsihedAnimation?.Invoke();
		}
		else
		{
			result = stages.Dequeue();
		}
		SetStatus(result);
		return result;
	}

	private void Update()
	{
		switch (status)
		{
		case Status.None:
			if (animationQueue.Count > 0)
			{
				animationItem = animationQueue.Dequeue();
				NextStage(ref animationItem.stages);
			}
			break;
		case Status.Expanding:
			animationSizeOffsets[animationItem.idx] = Mathf.SmoothStep(animationSizeOffsets[animationItem.idx], 160f, Time.unscaledDeltaTime * TabExpandSpeed);
			if (Mathff.DistSqrd(animationSizeOffsets[animationItem.idx], 160f) < 0.005f)
			{
				animationSizeOffsets[animationItem.idx] = 160f;
				NextStage(ref animationItem.stages);
			}
			break;
		case Status.BannerBounce:
		{
			float unscaledDeltaTime = Time.unscaledDeltaTime;
			float value = Mathf.Clamp(animationItem.animTime, 0f, BounceDuration) / BounceDuration;
			value = Util.easeOutQuad(Mathf.Clamp01(value));
			float y = Mathf.SmoothStep(0f, TotalClimb + animationItem.animOffset / 2f, value) + StartHeight;
			animationItem.banner.position = animationItem.start + new Vector3(0f, y, 0f);
			animationItem.animTime += unscaledDeltaTime;
			animationItem.animOffset = Mathf.MoveTowards(animationItem.animOffset, OffsetTarget, unscaledDeltaTime * ShiftUpSpeedMultiplier);
			if (animationItem.animTime >= BounceDuration + animationItem.holdTime + FadeDuration)
			{
				NextStage(ref animationItem.stages);
			}
			break;
		}
		case Status.BannerToTab:
			if (Mathff.DistSqrd(animationItem.banner.position.y, animationItem.tab.position.y) > 0.001f)
			{
				Vector3 position = animationItem.banner.position;
				position.y = Mathf.SmoothStep(position.y, animationItem.tab.position.y, Time.unscaledDeltaTime * BannerToTabSpeed);
				animationItem.banner.position = position;
			}
			else if (Mathff.DistSqrd(animationItem.banner.position.x, animationItem.tab.position.x) > 5f)
			{
				Vector3 position2 = animationItem.banner.position;
				position2.x = Mathf.SmoothStep(position2.x, animationItem.tab.position.x, Time.unscaledDeltaTime * BannerToTabSpeed);
				animationItem.banner.position = position2;
				animationItem.banner.localScale = Vector3.Lerp(animationItem.banner.localScale, new Vector3(0f, 1f, 1f), Time.unscaledDeltaTime);
			}
			else
			{
				animationItem.banner.gameObject.SetActive(value: false);
				animationItem.banner.position = bannerAnchorPoint.position;
				NextStage(ref animationItem.stages);
			}
			break;
		case Status.Showing:
			animationSizeOffsets[animationItem.idx] = Mathf.SmoothStep(animationSizeOffsets[animationItem.idx], 135f, Time.unscaledDeltaTime * TabExpandSpeed);
			if (Mathff.DistSqrd(animationSizeOffsets[animationItem.idx], 135f) < 0.005f)
			{
				animationSizeOffsets[animationItem.idx] = 135f;
				NextStage(ref animationItem.stages);
			}
			break;
		case Status.Hiding:
			animationSizeOffsets[animationItem.idx] = Mathf.SmoothStep(animationSizeOffsets[animationItem.idx], 0f, Time.unscaledDeltaTime * TabExpandSpeed);
			if (Mathff.DistSqrd(animationSizeOffsets[animationItem.idx], 0f) < 0.005f)
			{
				animationSizeOffsets[animationItem.idx] = 0f;
				NextStage(ref animationItem.stages);
			}
			break;
		case Status.Hidden:
		case Status.Shown:
			break;
		}
	}

	private void LateUpdate()
	{
		rect.sizeDelta = miniMapRect.sizeDelta;
		rect.anchoredPosition = miniMapRect.anchoredPosition;
		mapSizeOffset = (rect.sizeDelta.x - 160f) / 2f;
		for (int i = 0; i < tabs.Length; i++)
		{
			tabs[i].sizeDelta = new Vector2(Mathff.Max(mapSizeOffset + animationSizeOffsets[i], 15f), 38f);
		}
	}

	public void DisplayBanner(NotificationGroup group)
	{
		if ((int)group < tabs.Length && (int)group < banners.Length)
		{
			AnimationItem item = CreateAnimationItem(banners[(int)group], tabs[(int)group], group);
			item.stages = new Queue<Status>(4);
			item.stages.Enqueue(Status.BannerBounce);
			item.stages.Enqueue(Status.Expanding);
			item.stages.Enqueue(Status.BannerToTab);
			item.stages.Enqueue(Status.Showing);
			animationQueue.Enqueue(item);
		}
	}

	public void HideTab(NotificationGroup group, OnFinsihedAnimation onFinsihedAnimation)
	{
		if ((int)group < tabs.Length && (int)group < banners.Length)
		{
			AnimationItem item = CreateAnimationItem(banners[(int)group], tabs[(int)group], group);
			item.stages = new Queue<Status>(4);
			item.stages.Enqueue(Status.Hiding);
			if (onFinsihedAnimation != null)
			{
				ref OnFinsihedAnimation onFinsihedAnimation2 = ref item.OnFinsihedAnimation;
				onFinsihedAnimation2 = (OnFinsihedAnimation)Delegate.Combine(onFinsihedAnimation2, onFinsihedAnimation);
			}
			animationQueue.Enqueue(item);
		}
	}

	public void ShowTab(NotificationGroup group)
	{
		if ((int)group < tabs.Length && (int)group < banners.Length)
		{
			AnimationItem item = CreateAnimationItem(banners[(int)group], tabs[(int)group], group);
			item.stages = new Queue<Status>(4);
			item.stages.Enqueue(Status.Showing);
			animationQueue.Enqueue(item);
		}
	}

	private bool InAnimationQueue(RectTransform trans)
	{
		Queue<AnimationItem>.Enumerator enumerator = animationQueue.GetEnumerator();
		while (enumerator.MoveNext())
		{
			if (!(enumerator.Current.banner != trans))
			{
				enumerator.Dispose();
				return true;
			}
		}
		return false;
	}

	private AnimationItem CreateAnimationItem(RectTransform banner, RectTransform tab, NotificationGroup group)
	{
		return new AnimationItem
		{
			start = bannerAnchorPoint.position,
			banner = banner,
			tab = tab,
			idx = (int)group,
			animTime = 0f,
			animOffset = 0f,
			holdTime = HoldTime
		};
	}

	public void Reset()
	{
		status = Status.None;
		animationQueue.Clear();
		for (int i = 0; i < animationSizeOffsets.Length; i++)
		{
			animationSizeOffsets[i] = 0f;
		}
		for (int j = 0; j < banners.Length; j++)
		{
			banners[j].gameObject.SetActive(value: false);
			banners[j].position = bannerAnchorPoint.position;
		}
	}
}
