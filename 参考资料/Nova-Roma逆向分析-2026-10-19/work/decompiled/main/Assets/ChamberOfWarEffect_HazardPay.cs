using UnityEngine;

namespace Assets;

public class ChamberOfWarEffect_HazardPay : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		return true;
	}

	public new static string GetTermSegment()
	{
		return "HazardPay";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\goldicon");
		Timer = null;
		TimerText.enabled = false;
	}

	public override void OnEnd()
	{
	}
}
