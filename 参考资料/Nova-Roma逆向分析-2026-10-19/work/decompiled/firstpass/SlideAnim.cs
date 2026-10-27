using UnityEngine;

public class SlideAnim : MonoBehaviour
{
	public enum PlayMode
	{
		Stopped,
		Forward,
		Reverse
	}

	public enum AnimationBehavior
	{
		DisableOnReverseComplete,
		DisableOnForwardComplete,
		None
	}

	private Vector3 StartPosition;

	public Vector3 EndPosition;

	public float Duration = 1f;

	public float InitTime;

	public bool ControlVisibility;

	private RectTransform rXform;

	private PlayMode mode;

	public AnimationBehavior animBehavior = AnimationBehavior.None;

	private float TrackTime;

	private void Awake()
	{
		rXform = transform as RectTransform;
		StartPosition = rXform.anchoredPosition;
		TrackTime = InitTime;
		ApplyAtTime(InitTime);
	}

	public bool IsAnimComplete()
	{
		if (mode == PlayMode.Forward)
		{
			if (rXform.anchoredPosition.x == EndPosition.x && rXform.anchoredPosition.y == EndPosition.y)
			{
				return true;
			}
		}
		else if (mode == PlayMode.Reverse && rXform.anchoredPosition.x == StartPosition.x && rXform.anchoredPosition.y == StartPosition.y)
		{
			return true;
		}
		return false;
	}

	public void Play(PlayMode newMode)
	{
		if (animBehavior == AnimationBehavior.DisableOnReverseComplete && mode == PlayMode.Reverse && newMode == PlayMode.Forward)
		{
			gameObject.SetActive(value: true);
		}
		else if (animBehavior == AnimationBehavior.DisableOnForwardComplete && mode == PlayMode.Forward && newMode == PlayMode.Reverse)
		{
			gameObject.SetActive(value: true);
		}
		mode = newMode;
		if (ControlVisibility && newMode == PlayMode.Forward)
		{
			gameObject.SetActive(value: true);
		}
	}

	public void SetInstant(PlayMode newState)
	{
		switch (newState)
		{
		case PlayMode.Forward:
			TrackTime = 1f;
			break;
		case PlayMode.Reverse:
			TrackTime = 0f;
			break;
		}
		Update();
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		switch (mode)
		{
		case PlayMode.Forward:
			TrackTime += unscaledDeltaTime / Duration;
			break;
		case PlayMode.Reverse:
			TrackTime -= unscaledDeltaTime / Duration;
			break;
		}
		if (mode == PlayMode.Stopped)
		{
			return;
		}
		TrackTime = Mathf.Clamp01(TrackTime);
		ApplyAtTime(TrackTime);
		if (TrackTime <= 0f)
		{
			if (ControlVisibility)
			{
				gameObject.SetActive(value: false);
			}
			else if (mode == PlayMode.Reverse && animBehavior == AnimationBehavior.DisableOnReverseComplete && gameObject.activeSelf)
			{
				gameObject.SetActive(value: false);
			}
		}
		else if (TrackTime >= 1f && mode == PlayMode.Forward && animBehavior == AnimationBehavior.DisableOnForwardComplete && gameObject.activeSelf)
		{
			gameObject.SetActive(value: false);
		}
	}

	private void OnEnable()
	{
		ApplyAtTime(TrackTime);
	}

	private void ApplyAtTime(float T)
	{
		float t = Mathf.Clamp01(T);
		float t2 = Mathf.SmoothStep(0f, 1f, t);
		rXform.anchoredPosition = Vector3.Lerp(StartPosition, EndPosition, t2);
	}
}
