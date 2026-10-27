using UnityEngine;

namespace Assets;

public class StreamerEffect_SuperSpeedTroll : StreamerEffect
{
	private int lastSpeed;

	public new static string GetTermSegment()
	{
		return "SuperSpeedTroll";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\superspeedtroll");
		Timer.Duration = 10f;
		lastSpeed = TimeManager.inst.speedInUse;
		StreamerEffects.Flag_SuperSpeedTroll = true;
		TimeManager.inst.SetPlay4();
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_SuperSpeedTroll = false;
		TimeManager.inst.SetSpeed(lastSpeed);
	}
}
