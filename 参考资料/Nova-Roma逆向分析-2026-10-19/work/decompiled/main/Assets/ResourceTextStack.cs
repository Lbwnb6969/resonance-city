using System.Collections.Generic;
using Assets.Code;
using UnityEngine;

namespace Assets;

public class ResourceTextStack
{
	private class ResourceTextContainer
	{
		public int type;

		public int amount;

		public ResourceText text;

		public Vector3 start;

		public float animTime;

		public float animOffset;

		public float holdTime;
	}

	public float BounceDuration = 1.5f;

	public float HoldDurationDefault = 1f;

	public float FadeDuration = 1f;

	public float TotalClimb = 1f;

	public float StartHeight = 1f;

	public float ShiftUpSpeedMultiplier = 2f;

	private List<ResourceTextContainer> displayedTexts = new List<ResourceTextContainer>(4);

	public int GetShowingTexts()
	{
		return displayedTexts.Count;
	}

	private void UpdateTextDisplay(int i, float unscaledDt)
	{
		ResourceTextContainer resourceTextContainer = displayedTexts[i];
		float num = Util.EaseOutBounce(Mathf.Clamp(resourceTextContainer.animTime, 0f, BounceDuration), 0f, TotalClimb + resourceTextContainer.animOffset / 2f, BounceDuration) + StartHeight;
		resourceTextContainer.text.transform.position = resourceTextContainer.start.xz() + new Vector3(0f, resourceTextContainer.start.y + num, 0f);
		resourceTextContainer.animTime += unscaledDt;
		resourceTextContainer.animOffset = Mathf.MoveTowards(resourceTextContainer.animOffset, i, unscaledDt * ShiftUpSpeedMultiplier);
		if (resourceTextContainer.animTime >= BounceDuration + resourceTextContainer.holdTime)
		{
			resourceTextContainer.text.SetAlpha(1f - Mathf.Clamp01(resourceTextContainer.animTime - BounceDuration - resourceTextContainer.holdTime) / FadeDuration);
		}
		if (resourceTextContainer.animTime >= BounceDuration + resourceTextContainer.holdTime + FadeDuration)
		{
			resourceTextContainer.text.Release();
			displayedTexts.RemoveAt(i--);
		}
	}

	public void Tick(float unscaledDt)
	{
		for (int i = 0; i < displayedTexts.Count; i++)
		{
			UpdateTextDisplay(i, unscaledDt);
		}
	}

	public void ShowResourceAmount(int type, int amount, Vector3 start, float holdDuration = -1f)
	{
		if (!GameUI.inst.gameObject.activeSelf)
		{
			return;
		}
		if (holdDuration == -1f)
		{
			holdDuration = HoldDurationDefault;
		}
		for (int i = 0; i < displayedTexts.Count; i++)
		{
			if (displayedTexts[i].type == type && Mathf.Sign(displayedTexts[i].amount) == Mathf.Sin(amount) && displayedTexts[i].animTime < BounceDuration + displayedTexts[i].holdTime * 0.5f)
			{
				displayedTexts[i].amount += amount;
				displayedTexts[i].text.SetText(GetText(type, displayedTexts[i].amount));
				return;
			}
		}
		displayedTexts.Insert(0, new ResourceTextContainer
		{
			text = GameUI.inst.ResourceText.Create(GetText(type, amount)),
			amount = amount,
			type = type,
			animTime = 0f,
			animOffset = 0f,
			start = start,
			holdTime = holdDuration
		});
		UpdateTextDisplay(0, Time.unscaledDeltaTime);
	}

	public void ShowText(string text, Vector3 start, float holdDuration = -1f)
	{
		if (GameUI.inst.gameObject.activeSelf)
		{
			if (holdDuration == -1f)
			{
				holdDuration = HoldDurationDefault;
			}
			ResourceText resourceText = GameUI.inst.ResourceText.Create(text);
			resourceText.SetText(text);
			displayedTexts.Insert(0, new ResourceTextContainer
			{
				text = resourceText,
				amount = 0,
				type = -1,
				animTime = 0f,
				animOffset = 0f,
				start = start,
				holdTime = holdDuration
			});
		}
	}

	private string GetText(int type, int amount)
	{
		return ((amount > 0) ? "+" : "") + amount + " " + ResourceAmount.ResourceIcon(type);
	}
}
