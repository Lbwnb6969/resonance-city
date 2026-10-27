using UnityEngine;

namespace Assets;

public class StreamerEffect_TimeOfPeace : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "TimeOfPeace";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\timeofpeace");
		Timer.Duration = 10f;
		TimerText.enabled = false;
		RaiderSystem.inst.ResetTimer();
		DragonSpawn.inst.ResetTimer();
	}

	public override void OnEnd()
	{
	}
}
