using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class InfoButton : MonoBehaviour
{
	internal Timer updateExplanationTimer = new Timer(1f);

	public Slider slider;

	public Image sliderFill;

	public TextMeshProUGUI explanationText;

	public RectTransform explanationUI;

	[NonSerialized]
	public bool overlayOn;

	internal int enterCount;

	public static string GetBarColor(int happiness)
	{
		if (happiness >= 80)
		{
			return "#6cb84c";
		}
		if (happiness < 80 && happiness >= 60)
		{
			return "#90b94d";
		}
		if (happiness < 60 && happiness >= 40)
		{
			return "#b4b84c";
		}
		if (happiness < 40 && happiness >= 20)
		{
			return "#b8984c";
		}
		return "#b8744c";
	}

	public void UpdateSlider(int value)
	{
		slider.value = (float)value / 100f;
		ColorUtility.TryParseHtmlString(GetBarColor(value), out var color);
		sliderFill.color = color;
	}

	public void PointerEnter()
	{
		enterCount++;
		updateExplanationTimer.ForceExpire();
	}

	public void PointerExit()
	{
		enterCount--;
		if (enterCount < 0)
		{
			enterCount = 0;
		}
	}

	public virtual string GetExplanation()
	{
		return null;
	}

	private void OnEnable()
	{
		enterCount = 0;
		if ((bool)Player.inst)
		{
			explanationText.text = GetExplanation();
		}
	}

	private void Update()
	{
		UpdateInternal();
		if (enterCount > 0)
		{
			if (updateExplanationTimer.Update(Time.unscaledDeltaTime))
			{
				explanationText.text = GetExplanation();
			}
			Util.SetActive(explanationUI.gameObject, active: true);
		}
		else
		{
			Util.SetActive(explanationUI.gameObject, active: false);
		}
	}

	public virtual void UpdateInternal()
	{
	}
}
