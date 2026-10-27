using UnityEngine;
using UnityEngine.UI;

public class VignetteController : MonoBehaviour
{
	public enum Status
	{
		FadeIn,
		FadeOut,
		None
	}

	public Image vignette;

	private Status status = Status.None;

	private float fadeStrength = 4f;

	private float fadeDirection = 1f;

	private bool visible;

	private bool opaque;

	private bool transparent;

	public bool IsVisible()
	{
		return visible;
	}

	public bool IsOpaque()
	{
		return opaque;
	}

	public bool IsTransparent()
	{
		return transparent;
	}

	public void FadeIn()
	{
		SetVisible(v: true);
		if (!opaque)
		{
			SetStatus(Status.FadeIn);
		}
	}

	public void FadeOut()
	{
		if (!transparent)
		{
			SetVisible(v: true);
			SetStatus(Status.FadeOut);
		}
	}

	public void SetVisible(bool v)
	{
		gameObject.SetActive(v);
		visible = v;
		if (!v)
		{
			Color color = vignette.color;
			color.a = 0f;
			vignette.color = color;
			transparent = true;
			opaque = false;
		}
	}

	private void SetStatus(Status s)
	{
		if (status != s)
		{
			switch (s)
			{
			case Status.FadeIn:
				fadeDirection = 1f;
				break;
			case Status.FadeOut:
				fadeDirection = -1f;
				break;
			}
			status = s;
		}
	}

	private void Update()
	{
		switch (status)
		{
		case Status.FadeIn:
		{
			transparent = false;
			Color color2 = vignette.color;
			float unscaledDeltaTime2 = Time.unscaledDeltaTime;
			color2.a = Mathff.Clamp01(color2.a + fadeDirection * fadeStrength * unscaledDeltaTime2);
			vignette.color = color2;
			if (color2.a == 1f)
			{
				opaque = true;
				SetStatus(Status.None);
			}
			break;
		}
		case Status.FadeOut:
		{
			opaque = false;
			Color color = vignette.color;
			float unscaledDeltaTime = Time.unscaledDeltaTime;
			color.a = Mathff.Clamp01(color.a + fadeDirection * fadeStrength * unscaledDeltaTime);
			vignette.color = color;
			if (color.a == 0f)
			{
				gameObject.SetActive(value: false);
				visible = false;
				SetStatus(Status.None);
			}
			break;
		}
		}
	}
}
